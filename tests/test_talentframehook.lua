-- Tests de l'accroche à la fenêtre des talents du jeu (Q.UI.TalentFrameHook) : onglets, bande, halo,
-- ligne d'infobulle, et règles d'intégration (rien sur les cadres de Blizzard, rien en combat).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")
local Spec = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")
local Traits = dofile(Mock.root .. "/tests/mock_ext_traits.lua")
local PS = dofile(Mock.root .. "/tests/mock_ext_playerspells.lua")

local CONCUSSION, FURY = 16035, 16039
-- Traits.install : nœud n° = spellID + 1000
local NODE_CONC, NODE_FURY = CONCUSSION + 1000, FURY + 1000
local NAMES = { [CONCUSSION] = "Concussion", [FURY] = "Elemental Fury" }
local GROUPS = { { name = "Élémentaire", talents = { { CONCUSSION, 1, 3, 5 }, { FURY, 1, 2, 3 } } } }
local BUILD_NAME = "Elemental leveling"
local traits

-- opts : combat, ranks, unspent, noBuild, noFrame (pas de PlayerSpellsFrame au chargement), ps (options du mock),
-- settings (réglages posés après le chargement)
local function load(level, opts)
  opts = opts or {}
  Ext.install()
  Mock.player.classFile = "SHAMAN"; Mock.player.level = level
  Mock.player.combat = opts.combat == true
  Spec.install()
  Mock.spec.index = 1
  traits = Traits.install({ groups = GROUPS, ranks = opts.ranks or {},
    unspent = opts.unspent or math.max(0, level - 9) })
  C_Spell = { GetSpellName = function(id) return NAMES[id] end,
    GetSpellTexture = function(id) return 900000 + id end }
  PlayerSpellsUtil = { ToggleClassTalentFrame = function() end }
  local w
  if not opts.noFrame then
    local ps = opts.ps or {}
    ps.nodes = ps.nodes or { NODE_CONC, NODE_FURY }
    w = PS.install(ps)
  end
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  if opts.noBuild then
    Q.TalentBuildData = {}
    Q.Builds:SetActive(nil, nil)
  else
    Q.TalentBuildData = { SHAMAN = {
      { key = "ele1", class = "SHAMAN", specID = 262, name = { enUS = BUILD_NAME }, official = true,
        order = { CONCUSSION, CONCUSSION, FURY, CONCUSSION } },
    } }
  end
  if opts.settings then for k, v in pairs(opts.settings) do Q.Settings:Set(k, v) end end
  Q.UI.TalentPopup:Hide()
  return Q, w
end

local function H(Q) return Q.UI.TalentFrameHook end

local function hasLine(text)
  for _, l in ipairs(Mock.tooltip.lines) do
    if l == text then return true end
  end
  return false
end

local function countLines(text)
  local n = 0
  for _, l in ipairs(Mock.tooltip.lines) do
    if l == text then n = n + 1 end
  end
  return n
end

local function tipLine(Q, level, rank, max)
  return string.format(Q.L.TALENT_TIP_NEXT, level, rank, max)
end

-- Appels de l'addon qui modifient un cadre de Blizzard (voir tests/mock_ext_playerspells.lua).
local function blizzardTouches()
  local out = {}
  for _, c in ipairs(Mock.calls) do
    if c.name:find("^Blizzard:") and c.name ~= "Blizzard:HookScript" and c.name ~= "Blizzard:TalentClick" then
      out[#out + 1] = c.name .. "(" .. tostring(c.args[1]) .. ")"
    end
  end
  return out
end

local function stubWindow()
  local W = { calls = {} }
  function W:SetHost(f) self.calls[#self.calls + 1] = { "SetHost", f } end
  function W:Open(tab) self.calls[#self.calls + 1] = { "Open", tab } end
  function W:Close() self.calls[#self.calls + 1] = { "Close" } end
  return W
end

return {
  tabs_created_out_of_combat_only = function(t)
    local Q, w = load(10, { combat = true })
    local hook = H(Q)
    t.eq(hook:IsHooked(), false, "not hooked in combat")
    t.eq(#hook.tabs, 0, "no tab created in combat")
    t.eq(#PS.childrenCreatedIn({ w.host, w.talents }), 0, "no frame created on the game window in combat")
    Mock.fire("ADDON_LOADED", "Blizzard_PlayerSpells")
    t.eq(hook:IsHooked(), false, "still waiting for the end of combat")
    t.eq(#PS.childrenCreatedIn({ w.host, w.talents }), 0)
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(hook:IsHooked(), "hooked when combat ends")
    t.eq(#hook.tabs, 3)
    t.eq(hook.tabs[1]:GetText(), Q.L.TALENT_TAB_TALENTS)
    t.eq(hook.tabs[2]:GetText(), Q.L.TALENT_TAB_BUILD)
    t.eq(hook.tabs[3]:GetText(), Q.L.TALENT_TAB_SPELLS)
    for _, tab in ipairs(hook.tabs) do
      t.eq(rawget(tab, "_template"), "PanelTabButtonTemplate")
      t.eq(tab:GetParent(), hook.tabFrame)
    end
    t.eq(hook.tabFrame:GetParent(), w.host, "tab holder on PlayerSpellsFrame")
    t.eq({ hook.tabFrame:GetPoint(1) }, { "TOPLEFT", w.host, "BOTTOMLEFT", 22, 2 })
    t.ok(hook.tabs[2].qfBadge ~= nil and hook.tabs[3].qfBadge ~= nil, "Questify tabs marked Q")
    -- visibles seulement avec l'affichage des talents
    t.ok(not hook.tabFrame:IsShown(), "hidden while the talents are hidden")
    PS.open(w)
    t.ok(hook.tabFrame:IsShown(), "shown with the talents")
    PS.close(w)
    t.ok(not hook.tabFrame:IsShown(), "hidden again")
    t.eq(#Mock.errors, 0)
  end,

  hooks_on_addon_loaded_or_at_login = function(t)
    -- fenêtre chargée à la demande, après l'addon
    local Q = load(10, { noFrame = true })
    t.eq(H(Q):IsHooked(), false)
    local w = PS.install({ nodes = { NODE_CONC, NODE_FURY } })
    Mock.fire("ADDON_LOADED", "SomeOtherAddon")
    t.eq(H(Q):IsHooked(), false)
    Mock.fire("ADDON_LOADED", "Blizzard_PlayerSpells")
    t.ok(H(Q):IsHooked(), "hooked on ADDON_LOADED")
    Mock.fire("ADDON_LOADED", "Blizzard_PlayerSpells")
    t.eq(#H(Q).tabs, 3, "hooked once")
    t.eq(#Mock.callsTo("Blizzard:HookScript"), 2, "OnShow and OnHide hooked once")
    -- fenêtre déjà là avant la connexion
    Mock.reset()
    local Q2 = load(10)
    t.ok(H(Q2):IsHooked(), "hooked at LOGIN")
    -- affichage des talents déjà ouvert à l'accroche : tout se montre tout de suite
    Mock.reset()
    local Q3 = load(10, { noFrame = true })
    local w4 = PS.install({ nodes = { NODE_CONC, NODE_FURY } })
    PS.open(w4)
    Mock.fire("ADDON_LOADED", "Blizzard_PlayerSpells")
    t.ok(H(Q3).tabFrame:IsShown())
    t.ok(H(Q3).band:IsShown())
    t.eq(#Mock.errors, 0)
  end,

  missing_frame_no_error = function(t)
    local Q = load(10, { noFrame = true })
    t.eq(H(Q):IsHooked(), false)
    Mock.fire("ADDON_LOADED", "Blizzard_PlayerSpells")
    Q:Fire("TALENTS_CHANGED")
    Mock.fire("TRAIT_CONFIG_UPDATED", 1)
    Q:Fire("BUILDS_CHANGED")
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(H(Q):IsHooked(), false)
    t.eq(#Mock.errors, 0)
    -- fenêtre sans affichage des talents, ou affichage sans GetTalentButtonByNodeID
    for _, ps in ipairs({ { noTalentsFrame = true }, { noButtonApi = true } }) do
      Mock.reset()
      local Q2, w = load(10, { ps = ps })
      t.eq(H(Q2):IsHooked(), false)
      Mock.fire("ADDON_LOADED", "Blizzard_PlayerSpells")
      t.eq(H(Q2):IsHooked(), false)
      t.eq(#PS.childrenCreatedIn({ w.host }), 0, "nothing created")
      t.eq(#Mock.callsTo("Blizzard:HookScript"), 0, "nothing hooked")
      t.eq(#Mock.errors, 0)
    end
  end,

  halo_on_next_talent_button = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    PS.open(w)
    local halo = hook.halo
    t.ok(halo:IsShown(), "halo shown")
    t.eq(halo:GetParent(), w.buttons[NODE_CONC], "on the Concussion button")
    t.ok(halo.qfBadge ~= nil, "Q corner")
    t.ok(#rawget(halo.qfGlow, "_anims") > 0, "animated glow")
    -- le jeu recycle ses boutons : le halo suit le nœud
    PS.layout(w, { NODE_FURY, NODE_CONC })
    t.ok(w.buttons[NODE_CONC] ~= halo:GetParent(), "pool gave Concussion another button")
    Mock.fire("TRAIT_CONFIG_UPDATED", 1)
    t.eq(halo:GetParent(), w.buttons[NODE_CONC], "re-resolved on TRAIT_CONFIG_UPDATED")
    -- recyclage sans évènement : le contrôle périodique retrouve le bouton
    PS.layout(w, { NODE_CONC, NODE_FURY })
    Mock.advance(0.5)
    t.eq(halo:GetParent(), w.buttons[NODE_CONC], "re-resolved by the periodic check")
    -- réouverture (le jeu repose tous les boutons)
    PS.close(w)
    PS.open(w)
    t.eq(halo:GetParent(), w.buttons[NODE_CONC])
    t.ok(halo:IsShown())
    -- plus de point à dépenser : plus de halo
    traits.quantity = 0
    Q:Fire("TALENTS_CHANGED")
    t.ok(not halo:IsShown(), "no due talent: halo hidden")
    t.eq(halo:GetParent(), H(Q).band, "no longer a child of a game button")
    traits.quantity = 1
    Q:Fire("BUILDS_CHANGED")
    t.ok(halo:IsShown(), "shown again on BUILDS_CHANGED")
    t.eq(#Mock.errors, 0)
  end,

  tooltip_line_added = function(t)
    local Q, w = load(10)
    PS.open(w)
    local line = tipLine(Q, 10, 1, 5)
    PS.enter(w.buttons[NODE_CONC])
    t.ok(hasLine("talent " .. NODE_CONC), "game tooltip kept")
    t.ok(hasLine(line), "Questify line added")
    t.ok(Mock.tooltip.shown)
    t.eq(Mock.tooltip.lines[#Mock.tooltip.lines], line, "after the game's lines")
    PS.enter(w.buttons[NODE_FURY])
    t.ok(not hasLine(line), "not on another talent")
    -- rafraîchissements répétés : un seul crochet par bouton
    for _ = 1, 3 do Q:Fire("TALENTS_CHANGED") end
    Mock.advance(1)
    PS.enter(w.buttons[NODE_CONC])
    t.eq(countLines(line), 1, "one line only")
    local hooks = {}
    for _, c in ipairs(Mock.callsTo("Blizzard:HookScript")) do
      if c.args[1] == "TalentButton" then
        local b = c.args[3]
        hooks[b] = (hooks[b] or 0) + 1
        t.eq(c.args[2], "OnEnter")
      end
    end
    for _, n in pairs(hooks) do t.eq(n, 1, "HookScript once per button") end
    -- bouton recyclé pour un autre talent : le crochet vérifie le nœud au survol
    local old = w.buttons[NODE_CONC]
    PS.layout(w, { NODE_FURY, NODE_CONC })
    t.eq(w.buttons[NODE_FURY], old, "Fury now uses the hooked button")
    PS.enter(old)
    t.ok(not hasLine(line), "recycled button: no line")
    -- infobulle pas encore à ce bouton (sort pas encore chargé par le jeu) : rien ajouté
    Mock.tooltip.owner = nil
    Mock.tooltip.lines = {}
    Q.UI.TalentFrameHook:OnButtonEnter(w.buttons[NODE_CONC])
    t.eq(#Mock.tooltip.lines, 0, "tooltip not owned by the button: untouched")
    t.eq(#Mock.errors, 0)
  end,

  real_build_window_integration = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    local W = Q.UI.BuildWindow
    t.ok(W and W.Open, "real BuildWindow loaded")
    PS.open(w)
    Mock.click(hook.tabs[2])
    t.eq(hook.selected, "build")
    t.eq(W.host, w.host, "host set")
    t.ok(W:IsShown(), "window shown over the talents")
    t.eq(W.root:GetParent(), w.host)
    t.ok(W:Pane("build"):IsShown())
    Mock.click(hook.tabs[3])
    t.ok(W:Pane("spells"):IsShown() and not W:Pane("build"):IsShown())
    Mock.click(hook.tabs[1])
    t.eq(hook.selected, "talents")
    t.ok(not W:IsShown(), "closed")
    t.eq(#blizzardTouches(), 0, "no write to Blizzard frames")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  no_blizzard_tab_api_called = function(t)
    local Q, w = load(10)
    local W = stubWindow()
    Q.UI.BuildWindow = W
    local hook = H(Q)
    PS.open(w)
    for _, tab in ipairs({ hook.tabs[2], hook.tabs[3], hook.tabs[1] }) do Mock.click(tab) end
    Mock.click(hook.band.button)
    PS.enter(w.buttons[NODE_CONC])
    Q:Fire("TALENTS_CHANGED")
    Mock.advance(1)
    PS.close(w)
    PS.open(w)
    t.eq(Mock.countCalls("AddNamedTab"), 0, "no AddNamedTab")
    t.eq(Mock.countCalls("AddTab"), 0, "no AddTab")
    t.eq(blizzardTouches(), {}, "no Blizzard frame modified (no SetScript, Show, Hide, SetPoint, SetParent...)")
    for _, c in ipairs(Mock.callsTo("Blizzard:HookScript")) do
      t.ok(c.args[2] == "OnShow" or c.args[2] == "OnHide" or c.args[2] == "OnEnter", "only HookScript")
    end
    t.eq(#Mock.errors, 0)
  end,

  halo_does_not_intercept_click = function(t)
    local Q, w = load(10)
    PS.open(w)
    local button = w.buttons[NODE_CONC]
    local halo = H(Q).halo
    t.eq(halo:GetParent(), button)
    t.eq(rawget(halo, "_mouse"), false, "halo EnableMouse(false)")
    t.eq(rawget(halo.qfBadge, "_mouse"), false, "Q corner EnableMouse(false)")
    t.eq(Mock.countCalls("Blizzard:SetScript"), 0, "no SetScript on Blizzard frames")
    Mock.click(button)
    t.eq(Mock.countCalls("Blizzard:TalentClick"), 1, "the game's own click")
    t.eq(Mock.lastCall("Blizzard:TalentClick").args[1], NODE_CONC)
    t.eq(#Mock.callsTo("PurchaseRank"), 0, "nothing spent by the halo")
    t.eq(#Mock.errors, 0)
  end,

  band_shows_build_and_next_point = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    PS.open(w)
    local band = hook.band
    t.ok(band:IsShown())
    t.eq(band:GetParent(), w.talents, "band on the talents display")
    t.eq(({ band:GetPoint(1) })[2], w.talents)
    t.eq(rawget(band, "_mouse"), false, "band itself takes no click")
    t.eq(band.text:GetText(), string.format(Q.L.TALENT_BAND_BUILD, BUILD_NAME,
      string.format(Q.L.TALENT_BAND_NEXT, "Concussion", 1, 5)))
    t.eq(band.button:GetText(), Q.L.TALENT_BAND_EDIT)
    -- « Modifier le build » : rien sans fenêtre des builds, sinon l'onglet Build
    Q.UI.BuildWindow = nil
    Mock.click(band.button)
    t.eq(hook.selected, "talents")
    local W = stubWindow()
    Q.UI.BuildWindow = W
    Mock.click(band.button)
    t.eq(W.calls, { { "SetHost", w.host }, { "Open", "build" } })
    t.eq(hook.selected, "build")
    -- aucun point à dépenser : prochain point du build avec son niveau
    traits.ranks[CONCUSSION] = 1
    traits.quantity = 0
    Q:Fire("TALENTS_CHANGED")
    t.eq(band.text:GetText(), string.format(Q.L.TALENT_BAND_BUILD, BUILD_NAME,
      string.format(Q.L.TALENT_BAND_NEXT_AT, string.format(Q.L.TALENT_BAND_NEXT, "Concussion", 2, 5), 11)))
    t.ok(not hook.halo:IsShown())
    t.eq(#Mock.errors, 0)
  end,

  band_shows_deviation_and_from_tree_button = function(t)
    -- un point dans Fureur élémentaire, alors que le build commence par Concussion
    local Q, w = load(11, { ranks = { [FURY] = 1 }, unspent = 1 })
    local hook = H(Q)
    PS.open(w)
    local band = hook.band
    t.eq(band.text:GetText(), string.format(Q.L.TALENT_BAND_DEVIATES, BUILD_NAME))
    t.eq(band.button:GetText(), Q.L.TALENT_BAND_FROM_TREE)
    t.ok(band.button:IsShown())
    Mock.click(band.button)
    local mine
    for _, b in ipairs(Q.Builds:List("SHAMAN")) do
      if not b.official then mine = b end
    end
    t.ok(mine ~= nil, "personal build created")
    t.eq(mine.order, { FURY }, "from the real tree")
    t.eq(mine.specID, 262)
    t.ok(mine.name:match("^My tree %(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d%)$") ~= nil, "named after date and time: " .. mine.name)
    t.eq(Q.Builds:Active().key, mine.key, "now followed")
    t.eq(band.text:GetText(), string.format(Q.L.TALENT_BAND_BUILD, mine.name, Q.L.TALENT_BAND_DONE))
    t.eq(band.button:GetText(), Q.L.TALENT_BAND_EDIT)
    t.eq(#Mock.errors, 0)
  end,

  band_without_build = function(t)
    local Q, w = load(10, { noBuild = true })
    local hook = H(Q)
    PS.open(w)
    t.eq(hook.band.text:GetText(), Q.L.TALENT_BAND_NONE)
    t.eq(hook.band.button:GetText(), Q.L.UI_TALENT_NO_BUILD)
    t.ok(not hook.halo:IsShown(), "no build: no halo")
    local W = stubWindow()
    Q.UI.BuildWindow = W
    Mock.click(hook.band.button)
    t.eq(W.calls, { { "SetHost", w.host }, { "Open", "build" } })
    t.eq(#Mock.errors, 0)
  end,

  tab_clicks_drive_build_window = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    PS.open(w)
    -- sans fenêtre des builds (tâche 9) : rien
    Mock.click(hook.tabs[2])
    Mock.click(hook.tabs[3])
    Mock.click(hook.tabs[1])
    t.eq(hook.selected, "talents")
    t.eq(#Mock.errors, 0)
    local W = stubWindow()
    Q.UI.BuildWindow = W
    Mock.click(hook.tabs[2])
    t.eq(W.calls, { { "SetHost", w.host }, { "Open", "build" } })
    t.eq(hook.selected, "build")
    W.calls = {}
    Mock.click(hook.tabs[3])
    t.eq(W.calls, { { "SetHost", w.host }, { "Open", "spells" } })
    t.eq(hook.selected, "spells")
    W.calls = {}
    Mock.click(hook.tabs[1])
    t.eq(W.calls, { { "Close" }, { "SetHost", nil } }, "closed and back to standalone (I1)")
    t.eq(hook.selected, "talents")
    -- affichage des talents caché (grimoire, fermeture) avec un onglet Questify ouvert : on le ferme
    Mock.click(hook.tabs[2])
    W.calls = {}
    PS.close(w)
    t.eq(W.calls, { { "Close" }, { "SetHost", nil } })
    PS.open(w)
    t.eq(hook.selected, "talents")
    t.eq(#Mock.errors, 0)
  end,

  spells_tab_pill = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    PS.open(w)
    local pill = hook.tabs[3].qfPill
    t.ok(pill ~= nil)
    Q.SpellList = nil   -- le vrai module (Engine/SpellList.lua) existe : on simule son absence
    Q:Fire("TALENTS_CHANGED")
    t.ok(not pill:IsShown(), "no spell list module: no pill")
    Q.SpellList = { Summary = function() return { now = 3 } end }
    Q:Fire("TALENTS_CHANGED")
    t.ok(pill:IsShown())
    t.eq(pill.text:GetText(), "3")
    Q.SpellList = { Summary = function() return { now = 0 } end }
    PS.close(w); PS.open(w)
    t.ok(not pill:IsShown(), "nothing to learn: no pill")
    t.eq(#Mock.errors, 0)
  end,

  tab_template_fallback = function(t)
    local Q = load(10, { ps = { missingTemplates = { PanelTabButtonTemplate = true } } })
    local hook = H(Q)
    t.ok(hook:IsHooked())
    t.eq(#hook.tabs, 3)
    for _, tab in ipairs(hook.tabs) do t.eq(rawget(tab, "_template"), "UIPanelButtonTemplate") end
    t.eq(#Mock.errors, 0)
  end,

  nothing_refreshed_while_closed = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    t.ok(hook:IsHooked())
    Q:Fire("TALENTS_CHANGED")
    Q:Fire("BUILDS_CHANGED")
    Mock.fire("TRAIT_CONFIG_UPDATED", 1)
    t.eq(hook.state, nil, "talents hidden: nothing computed")
    t.ok(not hook.band:IsShown())
    PS.open(w)
    t.ok(hook.state ~= nil, "computed on show")
    PS.close(w)
    t.ok(not hook.band:IsShown(), "band hidden with the talents")
    t.ok(not hook.halo:IsShown(), "halo hidden with the talents")
    t.eq(#Mock.errors, 0)
  end,
  -- R19 : halo, ligne d'infobulle et bande ne dépendent pas du réglage de la popup (talentAlert).
  talent_alert_off_keeps_halo_tooltip_and_band = function(t)
    local Q, w = load(10, { settings = { talentAlert = false } })
    t.eq(Q.Talents:Alert(), nil, "popup alert off")
    local hook = H(Q)
    PS.open(w)
    t.ok(hook.halo:IsShown(), "halo kept")
    t.eq(hook.halo:GetParent(), w.buttons[NODE_CONC])
    PS.enter(w.buttons[NODE_CONC])
    t.ok(hasLine(tipLine(Q, 10, 1, 5)), "tooltip line kept")
    t.ok(hook.band:IsShown())
    t.eq(hook.band.text:GetText(), string.format(Q.L.TALENT_BAND_BUILD, BUILD_NAME,
      string.format(Q.L.TALENT_BAND_NEXT, "Concussion", 1, 5)), "band kept")
    t.eq(#Mock.errors, 0)
  end,

  band_auto_picks_build_with_no_point_to_spend = function(t)
    local Q, w = load(10, { ranks = { [CONCUSSION] = 1 }, unspent = 0 })
    Q.Builds:SetActive(nil, nil)
    t.eq(Q.Builds:Active(), nil, "no build followed yet")
    local hook = H(Q)
    PS.open(w)
    t.eq(Q.Builds:Active().key, "ele1", "auto-picked")
    t.eq(hook.band.text:GetText(), string.format(Q.L.TALENT_BAND_BUILD, BUILD_NAME,
      string.format(Q.L.TALENT_BAND_NEXT_AT, string.format(Q.L.TALENT_BAND_NEXT, "Concussion", 2, 5), 11)))
    t.ok(not hook.halo:IsShown(), "nothing to spend: no halo")
    t.eq(#Mock.errors, 0)
  end,

  inspect_or_other_spec_tab_hides_everything = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    local line = tipLine(Q, 10, 1, 5)
    for _, flag in ipairs({ "inspecting", "otherSpecTab" }) do
      PS.open(w)
      t.ok(hook.tabFrame:IsShown() and hook.band:IsShown() and hook.halo:IsShown(), flag .. ": shown first")
      w[flag] = true
      PS.enter(w.buttons[NODE_CONC])
      t.ok(not hasLine(line), flag .. ": no tooltip line, even before the next check")
      Mock.advance(0.3)
      t.ok(not hook.tabFrame:IsShown(), flag .. ": tabs hidden")
      t.ok(not hook.band:IsShown(), flag .. ": band hidden")
      t.ok(not hook.halo:IsShown(), flag .. ": halo hidden")
      PS.enter(w.buttons[NODE_CONC])
      t.ok(not hasLine(line), flag .. ": no tooltip line")
      -- rouvert dans cet état : rien non plus
      PS.close(w); PS.open(w)
      t.ok(not hook.tabFrame:IsShown() and not hook.band:IsShown() and not hook.halo:IsShown(), flag .. ": reopened")
      w[flag] = nil
      Mock.advance(0.3)
      t.ok(hook.tabFrame:IsShown() and hook.band:IsShown() and hook.halo:IsShown(), flag .. ": back")
      PS.enter(w.buttons[NODE_CONC])
      t.ok(hasLine(line), flag .. ": tooltip line back")
      PS.close(w)
    end
    -- inspection pendant qu'un onglet Questify est ouvert : la fenêtre des builds se ferme
    local W = stubWindow()
    Q.UI.BuildWindow = W
    PS.open(w)
    Mock.click(hook.tabs[2])
    W.calls = {}
    w.inspecting = true
    Mock.advance(0.3)
    t.eq(W.calls, { { "Close" } })
    t.eq(hook.selected, "talents")
    w.inspecting = nil
    -- méthodes absentes : pas d'inspection, onglet actif
    Mock.reset()
    local Q2, w2 = load(10, { ps = { noInspectApi = true } })
    PS.open(w2)
    t.ok(H(Q2).tabFrame:IsShown() and H(Q2).band:IsShown() and H(Q2).halo:IsShown(), "no inspect API: shown")
    t.eq(#Mock.errors, 0)
  end,

  from_tree_refused_is_deleted_and_names_unique = function(t)
    local Q, w = load(11, { ranks = { [FURY] = 1 }, unspent = 1 })
    local hook = H(Q)
    PS.open(w)
    local function personal()
      local out = {}
      for _, b in ipairs(Q.Builds:List("SHAMAN")) do
        if not b.official then out[#out + 1] = b end
      end
      return out
    end
    -- refusé comme build suivi : supprimé, raison dite, pas de copie à chaque clic
    local setActive = Q.Builds.SetActive
    Q.Builds.SetActive = function(self, group, key)
      if key ~= nil then return false, "tier" end
      return setActive(self, group, key)
    end
    Mock.click(hook.band.button)
    Mock.click(hook.band.button)
    t.eq(#personal(), 0, "refused build deleted")
    t.eq(Mock.countPrinted(string.format(Q.L.TALENT_TREE_BUILD_FAILED, Q.L.TALENT_REASON_TIER)), 2, "reason printed")
    t.eq(hook.band.mode, "tree", "still deviating")
    Q.Builds.SetActive = setActive
    -- accepté, puis nouvel écart et nouveau build : deux noms distincts
    Mock.click(hook.band.button)
    t.eq(#personal(), 1)
    t.eq(hook.band.mode, "edit")
    traits.ranks[CONCUSSION] = 1
    Mock.player.level = 12; Q.Player.level = 12
    Q:Fire("TALENTS_CHANGED")
    t.eq(hook.band.mode, "tree", "deviates again")
    Mock.click(hook.band.button)
    local list = personal()
    t.eq(#list, 2)
    t.ok(Q.Builds:Name(list[1]) ~= Q.Builds:Name(list[2]), "unique names")
    t.eq(Q.Builds:Active().key, list[2].key)
    t.eq(#Mock.errors, 0)
  end,

  questify_tab_hides_band_and_halo = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    local W = stubWindow()
    Q.UI.BuildWindow = W
    PS.open(w)
    Mock.click(hook.tabs[2])
    t.ok(hook.tabFrame:IsShown(), "tabs stay")
    t.ok(not hook.band:IsShown(), "band hidden")
    t.ok(not hook.halo:IsShown(), "halo hidden")
    PS.enter(w.buttons[NODE_CONC])
    t.ok(not hasLine(tipLine(Q, 10, 1, 5)), "no tooltip line while a Questify tab is open")
    -- recyclage par le jeu : le contrôle périodique ne repose pas le halo
    PS.layout(w, { NODE_FURY, NODE_CONC })
    Mock.advance(1)
    Q:Fire("TALENTS_CHANGED")
    t.ok(not hook.halo:IsShown(), "no halo while a Questify tab is open")
    PS.enter(w.buttons[NODE_CONC])
    t.ok(not hasLine(tipLine(Q, 10, 1, 5)), "no tooltip line either")
    Mock.click(hook.tabs[1])
    t.ok(hook.band:IsShown(), "band back")
    t.ok(hook.halo:IsShown(), "halo back")
    t.eq(hook.halo:GetParent(), w.buttons[NODE_CONC])
    t.eq(#Mock.errors, 0)
  end,

  no_build_window_in_combat = function(t)
    local Q, w = load(10)
    local hook = H(Q)
    local W = stubWindow()
    Q.UI.BuildWindow = W
    PS.open(w)
    Mock.player.combat = true
    local prints = #Mock.prints
    Mock.click(hook.tabs[2])
    Mock.click(hook.tabs[3])
    Mock.click(hook.band.button)
    t.eq(W.calls, {}, "clicks ignored in combat")
    t.eq(hook.selected, "talents")
    t.ok(hook.band:IsShown())
    t.eq(#Mock.prints, prints, "nothing printed")
    Mock.player.combat = false
    Mock.click(hook.tabs[2])
    t.eq(W.calls, { { "SetHost", w.host }, { "Open", "build" } })
    t.eq(#Mock.errors, 0)
  end,

  -- I1 : l'onglet Build de la fenêtre du jeu ne garde pas la fenêtre des builds posée dessus une fois
  -- les talents fermés ; /qf build ouvre alors la fenêtre autonome, visible.
  standalone_build_window_after_using_the_game_tab = function(t)
    local Q, w = load(12)
    local hook = H(Q)
    local W = Q.UI.BuildWindow
    PS.open(w)
    t.ok(hook:IsHooked(), "hooked")
    hook:SelectTab("build")
    t.eq(W.host, w.host, "content on the game window")
    PS.close(w)
    t.eq(W.host, nil, "host released when the talents close")
    SlashCmdList.QUESTIFY("build")
    t.ok(QuestifyBuildWindow and QuestifyBuildWindow:IsShown(), "standalone shell shown")
    t.ok(W:IsShown(), "content visible")
    t.eq(#blizzardTouches(), 0, "no write to Blizzard frames")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I1 : « Talents » (retour au jeu) rend aussi la fenêtre des builds à l'autonome.
  talents_tab_releases_the_host = function(t)
    local Q, w = load(12)
    local hook = H(Q)
    local W = Q.UI.BuildWindow
    PS.open(w)
    hook:SelectTab("spells")
    hook:SelectTab("talents")
    t.eq(W.host, nil)
    t.ok(not W:IsShown())
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I4 : un point posé en attente (pas encore « Appliquer ») fait avancer le halo et la bande.
  halo_moves_after_a_staged_point = function(t)
    local Q, w = load(12, { unspent = 3 })
    local hook = H(Q)
    PS.open(w)
    t.eq(hook.halo:GetParent(), w.buttons[NODE_CONC])
    traits.staged[CONCUSSION] = 2     -- Concussion 2/5 posé par le joueur, en attente
    Q:Fire("TALENTS_CHANGED")
    t.eq(hook.halo:GetParent(), w.buttons[NODE_FURY], "next talent of the build")
    t.eq(hook.band.text:GetText(), string.format(Q.L.TALENT_BAND_BUILD, BUILD_NAME,
      string.format(Q.L.TALENT_BAND_NEXT, "Elemental Fury", 1, 3)))
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I2 : build actif obsolète : « ⚠ Build obsolète : <raison> » et « Choisir un build » ; ni halo ni
  -- prochain point, même sans point à dépenser.
  band_shows_obsolete_build = function(t)
    for _, unspent in ipairs({ 2, 0 }) do
      Mock.reset()
      local Q, w = load(12, { unspent = unspent })
      Q.db.builds = { SHAMAN = { { key = "u1", class = "SHAMAN", name = "Mine", official = false,
        order = { 51505, CONCUSSION } } } }
      Q.char.builds = { active = { [1] = "u1" }, picked = {} }
      local hook = H(Q)
      PS.open(w)
      t.eq(hook.band.text:GetText(), string.format(Q.L.TALENT_BAND_OBSOLETE, Q.L.BUILD_OBSOLETE_missing), unspent)
      t.eq(hook.band.button:GetText(), Q.L.UI_TALENT_NO_BUILD)
      t.ok(not hook.halo:IsShown(), "no halo")
      local W = stubWindow()
      Q.UI.BuildWindow = W
      Mock.click(hook.band.button)
      t.eq(W.calls, { { "SetHost", w.host }, { "Open", "build" } })
      t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
    end
  end,
}
