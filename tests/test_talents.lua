-- Tests des talents (Q.Talents : alerte du suivi sur les builds, relevé /qf talents, ouverture de la fenêtre).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")
local Spec = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")
local Traits = dofile(Mock.root .. "/tests/mock_ext_traits.lua")
local PS = dofile(Mock.root .. "/tests/mock_ext_playerspells.lua")

-- Arbre du relevé (numéroté par arbre et position) ; ranks[tab .. ":" .. i].
local TREES = {
  { name = "Arms", talents = { { "Improved Heroic Strike", 1, 1, 3 }, { "Deflection", 1, 2, 5 }, { "Tactical Mastery", 2, 2, 5 } } },
  { name = "Fury", talents = { { "Cruelty", 1, 2, 5 } } },
}
local CONFIG, TREE, CURRENCY = Traits.CONFIG, Traits.TREE, Traits.CURRENCY
local ranks, traits

-- Arbre Chaman par spellID : Concussion (5 rangs, palier 1), Elemental Fury (3 rangs, palier 1).
local CONCUSSION, FURY = 16035, 16039
local NAMES = { [CONCUSSION] = "Concussion", [FURY] = "Elemental Fury" }
local SHAMAN_GROUPS = { { name = "Élémentaire", talents = { { CONCUSSION, 1, 3, 5 }, { FURY, 1, 2, 3 } } } }

local function installSpells()
  C_Spell = { GetSpellName = function(id) return NAMES[id] end,
    GetSpellTexture = function(id) return 900000 + id end }
end

-- Chaman niveau `level`, spé Élémentaire (262), talents Forever par spellID.
local function loadShaman(level, opts)
  opts = opts or {}
  Ext.install()
  Mock.player.classFile = "SHAMAN"; Mock.player.level = level
  Spec.install()
  Mock.spec.index = 1
  ranks = {}
  traits = Traits.install({ groups = SHAMAN_GROUPS, ranks = ranks, unspent = opts.unspent or math.max(0, level - 9) })
  if opts.noConfig then traits.configID = nil end
  installSpells()
  traits.opened = 0
  PlayerSpellsUtil = nil
  if not opts.legacyFrame then
    PlayerSpellsUtil = { ToggleClassTalentFrame = function() traits.opened = traits.opened + 1 end }
  end
  ToggleTalentFrame = function() traits.opened = traits.opened + 10 end
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  if not opts.noData then
    Q.TalentBuildData = { SHAMAN = {
      { key = "ele1", class = "SHAMAN", specID = 262, name = { enUS = "Elemental leveling" }, official = true,
        order = { CONCUSSION, CONCUSSION, FURY, CONCUSSION } },
    } }
  end
  return Q
end

local function load()
  Ext.install()
  ranks = {}
  traits = Traits.installTabs(TREES, ranks)
  return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
end

local function levelUp(lvl)
  Mock.player.level = lvl
  Mock.fire("PLAYER_LEVEL_UP", lvl)
  Mock.advance(0.6)
end

return {
  alert_lists_due_from_active_build = function(t)
    local Q = loadShaman(12)
    ranks[CONCUSSION] = 1
    local a = Q.Talents:Alert()
    t.eq(a.unspent, 3)
    t.eq(a.build.key, "ele1")
    t.eq(#a.due, 3)
    t.eq(a.due[1].spellID, CONCUSSION); t.eq(a.due[1].rank, 2)
    t.eq(a.due[2].spellID, FURY); t.eq(a.due[3].spellID, CONCUSSION); t.eq(a.due[3].rank, 3)
    t.ok(a.tree and a.tree.nodes[CONCUSSION])
    t.eq(a.deviates, false)
    t.eq(Q.Talents:Advice(a.due[1], a.tree), "Concussion (Élémentaire, rank 2/5)")
    t.eq(#Mock.errors, 0)
  end,

  alert_follows_provided_build_without_choosing = function(t)
    local Q = loadShaman(10)
    t.eq(Q.Builds:Active(), nil, "nothing chosen")
    local a = Q.Talents:Alert()
    t.eq(a.build.key, "ele1", "auto-picked from the spec")
    t.eq(Q.Builds:Active().key, "ele1")
    t.eq(Mock.countPrinted(string.format(Q.L.TALENT_AUTOPICK, "Elemental leveling")), 1)
    t.eq(a.due[1].spellID, CONCUSSION)
  end,

  alert_without_build_offers_choose = function(t)
    local Q = loadShaman(10, { noData = true })
    local a = Q.Talents:Alert()
    t.eq(a.unspent, 1)
    t.eq(a.build, nil)
    t.eq(a.due, {})
    Q.UI.Tracker:TalentTooltip(Q.UI.Tracker.talentAlert)
    local lines = Mock.tooltip.lines
    t.eq(lines[2], Q.L.UI_TALENT_NO_BUILD)
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(Q.UI.Tracker.talentText:GetText(), string.format(Q.L.UI_TALENT_ALERT, 1))
  end,

  tracker_shows_next_due_talent_with_icon = function(t)
    local Q = loadShaman(10)
    Q.UI.Tracker:Refresh()
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(Q.UI.Tracker.talentText:GetText(), string.format(Q.L.UI_TALENT_ALERT_NEXT, "Concussion"))
    t.eq(Q.UI.Tracker.talentIcon:GetTexture(), 900000 + CONCUSSION)
    Q.UI.Tracker:TalentTooltip(Q.UI.Tracker.talentAlert)
    t.eq(Mock.tooltip.lines[2], string.format(Q.L.UI_TALENT_NEXT, "Concussion (Élémentaire, rank 1/5)"))
    t.eq(#Mock.errors, 0)
  end,

  no_alert_before_level_10 = function(t)
    local Q = loadShaman(9)
    t.eq(Q.Talents:Unspent(), 0)
    t.eq(Q.Talents:Alert(), nil)
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
  end,

  -- Talents pas encore chargés à la connexion : aucune erreur, l'alerte arrive avec la configuration.
  waits_for_config = function(t)
    local Q = loadShaman(10, { noConfig = true })
    t.eq(Q.Talents:Alert(), nil)
    t.eq(Q.Talents:Unspent(), 0)
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
    traits.configID = CONFIG
    Mock.fire("TRAIT_CONFIG_UPDATED", CONFIG)
    t.eq(Q.Talents:Alert().unspent, 1)
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(#Mock.errors, 0)
  end,

  talents_due_fires_when_due_appears_or_unspent_grows = function(t)
    local Q = loadShaman(10, { unspent = 0 })
    local fired = 0
    Q:On("TALENTS_DUE", function() fired = fired + 1 end)
    t.eq(Q.Talents:Alert(), nil)
    t.eq(fired, 0)
    traits.quantity = 1
    Q.Talents:Alert()
    t.eq(fired, 1, "empty -> due")
    Q.Talents:Alert()
    t.eq(fired, 1, "unchanged")
    traits.quantity = 2
    Q.Talents:Alert()
    t.eq(fired, 2, "unspent increased")
    traits.quantity = 1
    Q.Talents:Alert()
    t.eq(fired, 2, "decreased")
    traits.quantity = 0
    Q.Talents:Alert()
    traits.quantity = 1
    Q.Talents:Alert()
    t.eq(fired, 3, "due again after none")
  end,

  old_picker_gone = function(t)
    local Q = loadShaman(10)
    t.eq(Q.UI.TalentPicker, nil)
    for _, o in ipairs(Q.OptionsSchema.entries) do t.ok(o.id ~= "talentBuild") end
    t.eq(Q.Talents.Presets, nil); t.eq(Q.Talents.Choose, nil); t.eq(Q.Talents.Next, nil)
  end,

  option_off = function(t)
    local Q = loadShaman(10)
    Q.Settings:Set("talentAlert", false)
    t.eq(Q.Talents:Alert(), nil)
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
  end,

  level_10_announces = function(t)
    local Q = loadShaman(9)
    traits.quantity = 1
    levelUp(10)
    t.eq(Mock.countPrinted(Q.L.TALENT_FIRST), 1)
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
  end,

  -- I6 : la ligne talents du suivi rouvre la popup ; la fenêtre des talents seulement si la popup ne peut pas
  -- s'afficher ; rien en combat (la popup attend la fin du combat).
  tracker_talent_line_reopens_the_popup = function(t)
    local Q = loadShaman(10)
    PS.install({})
    local P = Q.UI.TalentPopup
    P:Hide()
    Q.UI.Tracker:Refresh()
    local A = Q.UI.Tracker.talentAlert
    t.ok(A:IsShown())
    A:GetScript("OnClick")(A)
    t.ok(P.frame and P.frame:IsShown(), "popup shown")
    t.eq(traits.opened, 0, "talent window not toggled")
    P:Hide()
    local read = Q.TalentTree.Read
    Q.TalentTree.Read = function() return nil, "empty" end
    A:GetScript("OnClick")(A)
    t.ok(not P.frame:IsShown(), "popup cannot show without a tree")
    t.eq(traits.opened, 1, "talent window instead")
    Q.TalentTree.Read = read
    Mock.player.combat = true
    A:GetScript("OnClick")(A)
    t.eq(traits.opened, 1, "not in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(P.frame:IsShown(), "popup after combat")
    t.eq(Q.L.UI_TALENT_HINT ~= nil, true)
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I10 : l'addon ne charge jamais Blizzard_PlayerSpells (ToggleClassTalentFrame le chargerait) ; sans la
  -- fenêtre du jeu, message avec la touche des talents.
  open_frame_only_when_the_game_loaded_it = function(t)
    local Q = loadShaman(10)
    local loads = 0
    LoadAddOn = function() loads = loads + 1 end
    C_AddOns.LoadAddOn = function() loads = loads + 1 end
    PlayerSpellsFrame = nil
    GetBindingKey = function(cmd) if cmd == "TOGGLETALENTS" then return "SHIFT-T" end end
    Mock.prints = {}
    t.eq(Q.Talents:OpenFrame(), false)
    t.eq(traits.opened, 0, "not toggled: it would load the addon")
    t.ok(Mock.printed(string.format(Q.L.TALENT_OPEN_KEY, "SHIFT-T")), "key read from the bindings")
    GetBindingKey = function() return nil end
    Q.Talents:OpenFrame()
    t.ok(Mock.printed(string.format(Q.L.TALENT_OPEN_KEY, "N")), "default key")
    GetBindingKey = function() return Mock.secret("X") end
    Mock.prints = {}
    Q.Talents:OpenFrame()
    t.ok(Mock.printed(string.format(Q.L.TALENT_OPEN_KEY, "N")), "secret key ignored")
    -- chargée par le jeu et cachée : ouverte
    local w = PS.install({})
    t.eq(Q.Talents:OpenFrame(), true)
    t.eq(traits.opened, 1)
    -- déjà montrée sur les talents : rien (la bascule la fermerait)
    PS.open(w)
    t.eq(Q.Talents:OpenFrame(), true)
    t.eq(traits.opened, 1, "no toggle when already open")
    -- montrée sur le grimoire : message, pas de bascule
    w.talents:Hide()
    Mock.prints = {}
    t.eq(Q.Talents:OpenFrame(), false)
    t.eq(traits.opened, 1)
    t.ok(Mock.printed(string.format(Q.L.TALENT_OPEN_KEY, "N")))
    -- en combat : rien
    PS.close(w)
    Mock.player.combat = true
    t.eq(Q.Talents:OpenFrame(), false)
    t.eq(traits.opened, 1)
    Mock.player.combat = false
    t.eq(loads, 0, "LoadAddOn never called")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I10 : ancienne fenêtre seulement si le jeu l'a déjà chargée ; TalentFrame_LoadUI jamais appelée.
  open_frame_legacy_frame_only_when_loaded = function(t)
    local Q = loadShaman(10, { legacyFrame = true })
    local loadUI = 0
    TalentFrame_LoadUI = function() loadUI = loadUI + 1 end
    PlayerTalentFrame = nil
    t.eq(Q.Talents:OpenFrame(), false)
    t.eq(traits.opened, 0)
    PlayerTalentFrame = CreateFrame("Frame", "PlayerTalentFrame", UIParent)
    PlayerTalentFrame:Hide()
    t.eq(Q.Talents:OpenFrame(), true)
    t.eq(traits.opened, 10)
    t.eq(loadUI, 0)
  end,

  unspent_prefers_tree_over_client_points = function(t)
    local Q = loadShaman(12)
    t.eq(Q.Talents:Unspent(), 3)
    UnitCharacterPoints = function() return 9 end
    t.eq(Q.Talents:Unspent(), 3, "tree wins")
    C_Traits = nil
    t.eq(Q.Talents:Unspent(), 9, "client API as fallback")
  end,

  -- Forever : points à dépenser lus dans la monnaie de l'arbre C_Traits (pas d'API Classic).
  unspent_from_forever_tree_currency = function(t)
    local Q = load()
    t.eq(GetNumTalentTabs, nil); t.eq(UnitCharacterPoints, nil)
    levelUp(9)
    t.eq(Q.Talents:Unspent(), 0, "before level 10")
    levelUp(10)
    t.eq(Q.Talents:Unspent(), 1)
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(Q.UI.Tracker.talentText:GetText(), string.format(Q.L.UI_TALENT_ALERT, 1))
    ranks["1:2"] = 1
    Mock.fire("TRAIT_TREE_CURRENCY_INFO_UPDATED", TREE)
    t.eq(Q.Talents:Alert(), nil, "point spent")
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
    traits.quantity = 3
    Mock.fire("TRAIT_CONFIG_UPDATED", CONFIG)
    t.eq(Q.Talents:Unspent(), 3, "quantity from the client")
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(#Mock.errors, 0)
  end,

  -- /qf talents : relevé des vrais arbres Forever (nœuds, positions, rangs, sorts, monnaie, groupes).
  dump_records_forever_trees = function(t)
    local Q = load()
    levelUp(12)
    ranks["1:2"] = 2
    SlashCmdList.QUESTIFY("talents")
    t.eq(Mock.countPrinted(string.format(Q.L.UI_SLASH_TALENTS_DUMPED, 4)), 1)
    local d = QuestifyDB.talentDump.forever.WARRIOR
    t.ok(d, "talentDump[forever][WARRIOR]")
    t.eq(d.configID, CONFIG); t.eq(d.locale, "enUS"); t.eq(d.interface, 16001)
    t.eq(#d.nodes, 4)
    local node = d.nodes[2]
    t.eq(node.nodeID, 102); t.eq(node.treeID, TREE)
    t.eq(node.posX, 1200); t.eq(node.posY, 600)
    t.eq(node.maxRanks, 5); t.eq(node.currentRank, 2)
    t.eq(node.groupIDs, { 51 })
    t.eq(node.entries, { { entryID = 10102, definitionID = 20102, spellID = 30102, name = "Deflection", maxRanks = 5 } })
    t.eq(#d.trees, 1)
    t.eq(d.trees[1].currencies, { { traitCurrencyID = CURRENCY, quantity = 1, spent = 2 } })
    t.eq(d.trees[1].groups[1].displayName, "Arms"); t.eq(d.trees[1].groups[2].displayName, "Fury")
    -- diagnostic : l'arbre tel que Questify le lit, et chaque build de la classe validé contre lui
    t.ok(d.read and d.read.nodes, "read tree recorded")
    t.eq(#d.read.nodes, 4)
    t.eq(d.read.nodes[2].spellID, 30102); t.eq(d.read.nodes[2].rank, 2)
    t.ok(d.read.nodes[2].group and d.read.nodes[2].tier, "group and tier")
    t.ok(type(d.builds) == "table", "build validation recorded")
    for _, b in ipairs(d.builds) do
      t.ok(b.key, "build key")
      if not b.ok then t.ok(b.reason, b.key .. ": reason") end
    end
    t.eq(#Mock.errors, 0)
  end,

  -- Sans C_Traits.GetTreeCurrencyInfo, le relevé se fait quand même (sans les monnaies) : la lecture de
  -- l'arbre n'en a pas besoin, et c'est elle qui marque les builds obsolètes.
  dump_without_tree_currency_api = function(t)
    local Q = load()
    levelUp(12)
    C_Traits.GetTreeCurrencyInfo = nil
    SlashCmdList.QUESTIFY("talents")
    t.eq(Mock.countPrinted(Q.L.TALENT_DUMP_NO_API), 0)
    local d = QuestifyDB.talentDump.forever.WARRIOR
    t.eq(#d.nodes, 4)
    t.eq(d.trees[1].currencies, {})
    t.ok(d.read and #d.read.nodes == 4, "read tree recorded")
    t.eq(#Mock.errors, 0)
  end,

  -- API absente ou sans configuration : 0 avec un message clair, rien d'écrit, rappel muet.
  dump_and_reminder_guarded_without_api = function(t)
    local Q = load()
    levelUp(12)
    C_Traits = nil
    t.eq(Q.Talents:Dump(), 0)
    t.eq(Mock.countPrinted(Q.L.TALENT_DUMP_NO_API), 1)
    t.eq(Q.Talents:Unspent(), 0, "reminder silent")
    t.eq(Q.Talents:Alert(), nil)
    Mock.fire("TRAIT_CONFIG_UPDATED")
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
    traits = Traits.installTabs(TREES, ranks)
    traits.configID = nil                              -- talents pas encore chargés
    SlashCmdList.QUESTIFY("talents")
    t.eq(Mock.countPrinted(Q.L.TALENT_DUMP_NO_CONFIG), 1)
    t.eq(Mock.countPrinted(string.format(Q.L.UI_SLASH_TALENTS_DUMPED, 0)), 0, "no misleading count")
    t.eq(Q.Talents:Unspent(), 0)
    t.eq(QuestifyDB.talentDump, nil, "nothing recorded")
    t.eq(#Mock.errors, 0)
  end,

  -- I2 : build actif devenu obsolète : rien n'est conseillé, l'état le dit, le suivi affiche « Build obsolète ».
  obsolete_active_build_is_reported_not_followed = function(t)
    local Q = loadShaman(12, { noData = true })
    Q.TalentBuildData = { SHAMAN = {} }
    Q.db.builds = { SHAMAN = { { key = "u1", class = "SHAMAN", name = "Mine", official = false,
      order = { 51505, CONCUSSION, FURY } } } }
    Q.char.builds = { active = { [1] = "u1" }, picked = {} }
    local s = Q.Talents:State()
    t.eq(s.build.key, "u1", "still the player's build")
    t.eq(s.obsolete, "missing")
    t.eq(s.due, {}, "nothing advised")
    local a = Q.Talents:Alert()
    t.eq(a.obsolete, "missing")
    t.eq(a.due, {})
    Q.UI.Tracker:Refresh()
    t.eq(Q.UI.Tracker.talentText:GetText(), Q.L.UI_TALENT_ALERT_OBSOLETE)
    Q.UI.Tracker:TalentTooltip(Q.UI.Tracker.talentAlert)
    t.eq(Mock.tooltip.lines[2], string.format(Q.L.TALENT_BAND_OBSOLETE, Q.L.BUILD_OBSOLETE_missing))
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- M1 : à 0 point, ni l'alerte ni Unspent ne lisent l'arbre (seulement la monnaie).
  alert_reads_the_tree_only_with_points_to_spend = function(t)
    local Q = loadShaman(12, { unspent = 0 })
    local reads = 0
    local read = Q.TalentTree.Read
    Q.TalentTree.Read = function(...) reads = reads + 1; return read(...) end
    t.eq(Q.Talents:Alert(), nil)
    t.eq(Q.Talents:Unspent(), 0)
    Q.UI.Tracker:Refresh()
    t.eq(reads, 0, "no tree read at 0 point")
    traits.quantity = 2
    t.eq(Q.Talents:Unspent(), 2)
    t.eq(reads, 0, "Unspent reads the currency only")
    t.eq(Q.Talents:Alert().unspent, 2)
    t.eq(reads, 1, "tree read once a point is to spend")
  end,

  -- I7 : Talents annonce lui-même les points (TALENTS_DUE) sur TALENTS_CHANGED, sans le suivi (qui sort tôt
  -- sans QuestieDB ou sans guide), au plus une fois par 0,5 s.
  talents_due_fires_without_the_tracker = function(t)
    local Q = loadShaman(12, { unspent = 0 })
    Q.UI.Tracker.LayoutTalentAlert = function(_, y) return y end
    Mock.advance(1)
    local due = {}
    Q:On("TALENTS_DUE", function(a) due[#due + 1] = a end)
    local alerts = 0
    local alert = Q.Talents.Alert
    Q.Talents.Alert = function(self) alerts = alerts + 1; return alert(self) end
    traits.quantity = 1
    Mock.fire("TRAIT_TREE_CURRENCY_INFO_UPDATED", TREE)
    t.eq(#due, 1, "TALENTS_DUE from Talents itself")
    t.ok(Q.UI.TalentPopup.frame and Q.UI.TalentPopup.frame:IsShown(), "popup shown")
    Mock.fire("TRAIT_CONFIG_UPDATED", CONFIG)
    Mock.fire("SPELLS_CHANGED")
    t.eq(alerts, 1, "throttled")
    Mock.advance(0.5)
    t.eq(alerts, 2, "one trailing call")
    Mock.advance(1)
    t.eq(alerts, 2)
    t.eq(#due, 1, "emission stays idempotent")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,
}
