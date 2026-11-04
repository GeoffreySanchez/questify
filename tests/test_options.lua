-- Tests de la fenêtre d'options (UI/Options.lua), du schéma (Core/OptionsSchema.lua) et des
-- profils (Core/Profiles.lua) : couverture des réglages, recherche, contrôles, thèmes, profils,
-- migration, export et import.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

local function load(opts)
  Ext.install()
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end
  return Mock.loadAddon(TOC, opts)
end

local function noErrors(t)
  t.eq(#Mock.errors, 0, "no errors: " .. tostring(Mock.errors[1]))
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

local function ids(list)
  local out = {}
  for i, e in ipairs(list) do out[i] = e.id end
  return out
end

local function contains(list, v)
  for _, x in ipairs(list) do if x == v then return true end end
  return false
end

-- Chemins des feuilles d'un arbre de valeurs par défaut.
local function leafPaths(t, prefix, out)
  out = out or {}
  for k, v in pairs(t) do
    local path = prefix and (prefix .. "." .. k) or k
    if type(v) == "table" then leafPaths(v, path, out) else out[#out + 1] = path end
  end
  return out
end

-- En-têtes affichés dans la liste (texte).
local function shownHeaders(O)
  local out = {}
  for _, h in ipairs(O.headers) do
    if h:IsShown() then out[#out + 1] = h.text:GetText() end
  end
  return out
end

local function shownWidgets(O)
  local out = {}
  for _, w in ipairs(O.shown or {}) do out[#out + 1] = w.entry.id end
  return out
end

local function confirm()
  StaticPopupDialogs.QUESTIFY_OPTIONS_CONFIRM.OnAccept()
end

-- Charge le fichier de textes avec une fausse RegisterStrings.
local function stringTables()
  local captured
  local fake = { RegisterStrings = function(_, tables) captured = tables end }
  assert(loadfile(Mock.root .. "/Questify/Locales/StringsOptions.lua"))("Questify", fake)
  return captured
end

return {
  ---------------------------------------------------------------------------
  -- Schéma
  ---------------------------------------------------------------------------
  schema_covers_every_setting_default = function(t)
    local Q = load()
    local S = Q.OptionsSchema
    local paths = S:Paths()
    local missing = {}
    for _, path in ipairs(leafPaths(Q.Settings.defaults)) do
      if not paths[path] and not S.ELSEWHERE[path] then missing[#missing + 1] = path end
    end
    table.sort(missing)
    t.eq(missing, {}, "every default needs a schema entry")
    -- l'inverse : chaque chemin du schéma est un réglage connu (la position n'a pas de défaut)
    for path, e in pairs(paths) do
      local d = Q.Settings.defaults
      for p in path:gmatch("[^%.]+") do
        if type(d) == "table" then d = d[p] else d = nil end
      end
      t.ok(d ~= nil or e.type == "hidden", "schema path without default: " .. path)
    end
    -- champs du personnage : une option du schéma, ou l'état de progression (hors profils)
    for key in pairs(Q.charDefaults) do
      t.ok(S.CHAR_STATE[key] or S:Entry(key), "char default not covered: " .. key)
    end
    t.ok(S:Entry("rewardRole"), "loot profile has an entry")
    t.eq(S:Entry("rewardRole").path, nil, "loot profile is not a profile setting (Q.char)")
    t.eq(paths.rewardRole, nil)
  end,

  schema_entries_are_well_formed = function(t)
    local Q = load()
    local S = Q.OptionsSchema
    local tables = stringTables()
    local order = {}
    for _, s in ipairs(S.SECTIONS) do
      order[#order + 1] = s.id
      t.ok(tables.enUS[s.label] and tables.frFR[s.label], "section label " .. s.label)
      for _, c in ipairs(s.categories) do
        t.ok(Q.L[c.label] ~= c.label, "category label " .. c.label)
      end
    end
    t.eq(order, { "route", "navigation", "automation", "loot", "class", "map", "tracker", "theme", "comfort",
      "tools", "profiles" })
    local seen = {}
    for _, e in ipairs(S.entries) do
      t.ok(not seen[e.id], "unique id " .. e.id)
      seen[e.id] = true
      local s = S:Section(e.section)
      t.ok(s, "section of " .. e.id)
      t.ok(s.categoryIndex[e.category], "category of " .. e.id)
      if e.type ~= "hidden" then
        t.ok(e.label and Q.L[e.label] ~= e.label, "label of " .. e.id)
        t.ok(type(e.keywords) == "string" and e.keywords ~= "", "keywords of " .. e.id)
        if e.type ~= "info" then t.ok(e.tip and Q.L[e.tip] ~= e.tip, "tip of " .. e.id) end
      end
      if e.type == "slider" then t.ok(e.min < e.max and e.step > 0, "slider bounds " .. e.id) end
      if e.type == "select" then t.ok(e.choices, "choices of " .. e.id) end
      t.ok(e.path or e.get or e.type == "action" or e.type == "info" or e.type == "keybind", "get/set of " .. e.id)
    end
    -- catégories demandées
    t.ok(S:Entry("tracker.scale").category == "layout" and S:Entry("tracker.nextSteps").category == "layout")
    t.eq(S:Entry("tracker.showMobs").category, "content")
    t.eq(S:Entry("showXPRate").category, "content")
    t.eq(S:Entry("autoReward").category, "auto")
    t.eq(S:Entry("rewardRole").category, "profile")
    t.eq(S:Entry("specRolePrompt").category, "profile")
    t.eq(S:Entry("nav.routing").category, "routing")
    t.eq(S:Entry("nav.display").category, "display")
    t.eq(S:Entry("autoFly").category, "flights")
  end,

  strings_complete_in_both_languages = function(t)
    local tables = stringTables()
    for k in pairs(tables.enUS) do t.ok(tables.frFR[k], "frFR has " .. k) end
    for k in pairs(tables.frFR) do t.ok(tables.enUS[k], "enUS has " .. k) end
    Mock.locale = "frFR"
    local Q = load()
    t.eq(Q.L.OPT_SEC_LOOT, "Butin")
    t.eq(Q.L.OPT_PROFILE_COPY, "Copier depuis…")
    t.eq(Q.Profiles:DisplayName("Default"), "Par défaut")
  end,

  ---------------------------------------------------------------------------
  -- Recherche
  ---------------------------------------------------------------------------
  search_finds_loot_and_theme_options_ignoring_accents_and_case = function(t)
    local Q = load()
    local S = Q.OptionsSchema
    local loot = ids(S:Search("butin", Q.Player))
    t.ok(contains(loot, "autoReward"), "autoReward for « butin »")
    t.ok(contains(loot, "rewardRole"), "reward role for « butin »")
    t.ok(contains(loot, "specRolePrompt"), "spec proposal for « butin »")
    t.eq(ids(S:Search("BUTIN", Q.Player)), loot, "case ignored")
    t.eq(ids(S:Search("loot", Q.Player))[1], loot[1], "English keywords")
    local theme = ids(S:Search("thème", Q.Player))
    t.ok(contains(theme, "tracker.theme") and contains(theme, "tracker.opacity"), "theme and opacity")
    t.eq(ids(S:Search("theme", Q.Player)), theme, "accent ignored")
    t.eq(ids(S:Search("THÈME", Q.Player)), theme, "accented capital")
    t.ok(contains(ids(S:Search("opacité", Q.Player)), "tracker.opacity"))
    t.ok(contains(ids(S:Search("recompense", Q.Player)), "autoReward"), "« récompense » without accent")
    t.ok(contains(ids(S:Search("parchemin", Q.Player)), "tracker.theme"), "choice labels are searched")
    t.ok(contains(ids(S:Search("vols bateaux", Q.Player)), "nav.routing"), "every word must match")
    t.eq(#S:Search("zzzz", Q.Player), 0)
    t.eq(#S:Search("   ", Q.Player), 0, "blank search")
    -- les entrées invisibles pour la classe ne sortent pas
    Q.Player.classFile = "MAGE"
    t.ok(not contains(ids(S:Search("butin", Q.Player)), "rewardRole"), "no loot profile choice for a mage")
    t.eq(S.Normalize("Élites et Œuvre à côté"), "elites et oeuvre a cote")
  end,

  search_box_shows_results_grouped_by_section_then_returns = function(t)
    local Q = load()
    local O = Q.UI.Options
    O:Open("tracker")
    t.ok(O:Widget("tracker.locked"):IsShown())
    O:SetSearch("butin")
    t.eq(O.query, "butin")
    t.ok(O:Widget("autoReward"):IsShown(), "result shown")
    t.ok(O:Widget("rewardRole"):IsShown(), "result shown")
    t.ok(not O:Widget("tracker.locked"):IsShown(), "section hidden while searching")
    local headers = shownHeaders(O)
    t.ok(contains(headers, Q.L.OPT_SEC_LOOT), "section header")
    t.ok(contains(headers, Q.L.OPT_CAT_LOOT_AUTO), "category header")
    t.ok(plain(O.countText:GetText()):find(tostring(#O.results), 1, true), "result count")
    -- plusieurs sections : dans l'ordre de la barre latérale
    O:SetSearch("donjon")
    local secs = {}
    for _, e in ipairs(O.results) do if secs[#secs] ~= e.section then secs[#secs + 1] = e.section end end
    t.eq(secs[1], "class")
    O:SetSearch("qwertyuiop")
    t.ok(O.emptyText:IsShown(), "no result message")
    t.ok(plain(O.emptyText:GetText()):find("qwertyuiop", 1, true))
    -- recherche vidée : retour à la section choisie
    O:SetSearch("")
    t.ok(O:Widget("tracker.locked"):IsShown(), "back to the section")
    t.ok(not O:Widget("autoReward"):IsShown())
    t.ok(not O.emptyText:IsShown())
    -- clic sur une section pendant une recherche : la recherche est vidée
    O:SetSearch("butin")
    Mock.click(O.sectionButtons[3], "LeftButton")
    t.eq(O.query, "")
    t.eq(O.section, "automation")
    t.ok(O:Widget("autoQuest"):IsShown())
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Fenêtre
  ---------------------------------------------------------------------------
  window_layout_and_sidebar = function(t)
    local Q = load()
    local O = Q.UI.Options
    O:Open()
    local f = QuestifyOptions
    t.ok(f and f:IsShown())
    t.eq(f._template, "ButtonFrameTemplate")
    t.eq({ f:GetSize() }, { 760, 560 })
    t.ok(f:IsMovable(), "movable")
    t.ok(contains(UISpecialFrames, "QuestifyOptions"), "closes with Escape")
    t.eq(O.searchBox._template, "SearchBoxTemplate")
    t.eq(#O.sectionButtons, 11)
    t.eq(O.sectionButtons[1].text:GetText(), Q.L.OPT_SEC_ROUTE)
    t.eq(O.sectionButtons[11].text:GetText(), Q.L.OPT_SEC_PROFILES)
    t.ok(O.sectionButtons[1].selected:IsShown(), "selected highlight")
    Mock.click(O.sectionButtons[4], "LeftButton")
    t.eq(O.section, "loot")
    t.ok(O.sectionButtons[4].selected:IsShown() and not O.sectionButtons[1].selected:IsShown())
    -- catégories de la section, dans l'ordre
    local headers = shownHeaders(O)
    t.eq(headers, { Q.L.OPT_SEC_LOOT, Q.L.OPT_CAT_LOOT_AUTO, Q.L.OPT_CAT_LOOT_PROFILE })
    -- chaque section s'affiche sans erreur
    for _, s in ipairs(Q.OptionsSchema.SECTIONS) do O:SelectSection(s.id) end
    O:Toggle()
    t.ok(not f:IsShown())
    noErrors(t)
  end,

  every_control_has_an_info_icon_with_its_tooltip = function(t)
    local Q = load()
    local O = Q.UI.Options
    for _, s in ipairs(Q.OptionsSchema.SECTIONS) do
      O:Open(s.id)
      for _, w in ipairs(O.shown) do
        local e = w.entry
        if e.type ~= "info" then
          t.ok(w.info, "info icon for " .. e.id)
          t.eq(w.info.texture:GetTexture(), "Interface\\common\\help-i")
        end
      end
    end
    O:Open("loot")
    local icon = O:Widget("autoReward").info
    icon:GetScript("OnEnter")(icon)
    t.ok(Mock.tooltip.shown, "tooltip shown")
    t.ok(Ext.tooltipHas(Q.L.UI_OPT_AUTOREWARD), "title")
    t.ok(Ext.tooltipHas(Q.L.OPT_TIP_AUTOREWARD), "help text")
    icon:GetScript("OnLeave")(icon)
    t.ok(not Mock.tooltip.shown)
    noErrors(t)
  end,

  toggle_sets_its_setting_and_follows_outside_changes = function(t)
    local Q = load()
    local O = Q.UI.Options
    O:Open("automation")
    local cb = O:Widget("autoQuest").check
    t.eq(cb._template, "UICheckButtonTemplate")
    t.eq(cb:GetChecked(), true)
    cb:SetChecked(false)
    Mock.click(cb, "LeftButton")
    t.eq(Q.Settings:Get("autoQuest"), false)
    Q.Settings:Set("autoQuest", true)
    t.eq(cb:GetChecked(), true, "synced from outside")
    O:Open("tracker")
    cb = O:Widget("tracker.locked").check
    cb:SetChecked(true)
    Mock.click(cb, "LeftButton")
    t.eq(Q.Settings:Get("tracker.locked"), true)
    t.ok(not Q.UI.Tracker.frame:IsMovable(), "tracker follows")
    -- addon facultatif absent : case grisée
    O:Open("navigation")
    local routing = O:Widget("nav.routing")
    t.ok(not routing.check:IsEnabled(), "routing needs ShortestPath")
    t.ok(plain(routing.label:GetText()):find(Q.L.OPT_NOT_INSTALLED, 1, true))
    noErrors(t)
  end,

  radio_select_sets_value_and_disables_missing_addons = function(t)
    Mock.addons.TomTom = true
    local Q = load()
    local O = Q.UI.Options
    O:Open("navigation")
    local w = O:Widget("nav.display")
    local byValue = {}
    for _, r in ipairs(w.radios) do byValue[r.value] = r end
    t.eq(byValue.native._template, "UIRadioButtonTemplate")
    t.ok(byValue.native:GetChecked(), "current value checked")
    t.ok(byValue.tomtom:IsEnabled(), "TomTom installed")
    t.ok(not byValue.waypointui:IsEnabled(), "WaypointUI missing")
    t.ok(plain(byValue.waypointui.label:GetText()):find(Q.L.OPT_NOT_INSTALLED, 1, true))
    Mock.click(byValue.tomtom, "LeftButton")
    t.eq(Q.Settings:Get("nav.display"), "tomtom")
    t.ok(byValue.tomtom:GetChecked() and not byValue.native:GetChecked())
    t.ok(not Q.OptionsSchema:Set(Q.OptionsSchema:Entry("nav.display"), "waypointui"), "missing addon refused")
    t.eq(Q.Settings:Get("nav.display"), "tomtom")
    noErrors(t)
  end,

  dropdown_select_uses_the_blizzard_menu_when_available = function(t)
    -- WowStyle1DropdownTemplate factice : SetupMenu garde le générateur, GenerateMenu le relance
    local generator
    MenuUtil = { CreateContextMenu = function() end }
    local create = CreateFrame
    CreateFrame = function(kind, name, parent, template, ...)
      local f = create(kind, name, parent, template, ...)
      if template == "WowStyle1DropdownTemplate" then
        rawset(f, "SetupMenu", function(self, fn) generator = fn end)
        rawset(f, "GenerateMenu", function(self) Mock.record("GenerateMenu") end)
      end
      return f
    end
    Mock.player.classFile = "SHAMAN"
    local Q = load()
    local O = Q.UI.Options
    O:Open("loot")
    local w = O:Widget("rewardRole")
    t.ok(w.dropdown, "dropdown used")
    t.eq(w.dropdown._type, "DropdownButton")
    local radios = {}
    local root = { CreateRadio = function(_, text, isSelected, setSelected, data)
      local r = { text = text, isSelected = isSelected, setSelected = setSelected, data = data }
      radios[#radios + 1] = r
      return r
    end }
    generator(w.dropdown, root)
    t.eq(#radios, 4, "shaman profiles")
    t.ok(radios[1].isSelected(radios[1].data), "auto selected")
    radios[4].setSelected(radios[4].data)
    t.eq(Q.Rewards:Role(), "healer")
    t.ok(Mock.countCalls("GenerateMenu") > 0, "selection text refreshed")
    noErrors(t)
  end,

  slider_sets_clamped_values_and_shows_them = function(t)
    local Q = load()
    local O = Q.UI.Options
    O:Open("tracker")
    local w = O:Widget("tracker.scale")
    t.eq(w.sliderFrame._template, "MinimalSliderWithSteppersTemplate")
    t.eq(plain(w.value:GetText()), "100 %")
    w.slider:SetValue(1.25)
    t.near(Q.Settings:Get("tracker.scale"), 1.25, 1e-9)
    t.eq(plain(w.value:GetText()), "125 %")
    w.slider:SetValue(9)
    t.near(Q.Settings:Get("tracker.scale"), 1.6, 1e-9, "clamped to the max")
    local width = O:Widget("tracker.width")
    width.slider:SetValue(333.4)
    t.eq(Q.Settings:Get("tracker.width"), 333, "whole pixels")
    t.eq(plain(width.value:GetText()), "333 px")
    local steps = O:Widget("tracker.nextSteps")
    steps.slider:SetValue(-3)
    t.eq(Q.Settings:Get("tracker.nextSteps"), 0)
    -- changement venu d'ailleurs : le curseur suit, sans réécrire le réglage
    local writes = 0
    Q:On("SETTINGS_CHANGED", function() writes = writes + 1 end)
    Q.Settings:Set("tracker.scale", 0.8)
    t.eq(writes, 1, "no echo from the slider")
    t.near(w.slider:GetValue(), 0.8, 1e-9)
    t.eq(plain(w.value:GetText()), "80 %")
    noErrors(t)
  end,

  actions_reset_chapter_export_measures_and_open_tools = function(t)
    local Q = load()
    local O = Q.UI.Options
    O:Open("route")
    Q.char.manual["g:A_DwarfGnome_01:13"] = true
    Q.char.skipped["g:A_DwarfGnome_01:2"] = true
    Q.char.skipped["g:A_DwarfGnome_02:1"] = true
    Q.char.manual["i:cq:WARLOCK_1598:1"] = true
    local reset = O:Widget("resetChapter").button
    t.eq(reset._template, "UIPanelButtonTemplate")
    Mock.click(reset, "LeftButton")
    t.eq(Q.char.manual["g:A_DwarfGnome_01:13"], nil)
    t.eq(Q.char.skipped["g:A_DwarfGnome_01:2"], nil)
    t.eq(Q.char.skipped["g:A_DwarfGnome_02:1"], true, "other chapter kept")
    t.eq(Q.char.manual["i:cq:WARLOCK_1598:1"], true, "inserted steps kept")
    t.ok(Mock.printed("Coldridge Valley"), "confirmation in chat")
    -- export des mesures
    O:Open("tools")
    Ext.fakeTelemetry(Q, "QV1;A_DwarfGnome_01:1=42")
    local ex = O:Widget("exportTelemetry")
    t.ok(not ex.box:IsShown(), "closed at first")
    Mock.click(ex.button, "LeftButton")
    t.ok(ex.box:IsShown() and ex.hint:IsShown())
    t.eq(ex.box:GetText(), "QV1;A_DwarfGnome_01:1=42")
    t.eq(ex.hint:GetText(), Q.L.OPT_COPY_HINT)
    Q.Telemetry = nil
    Mock.click(ex.button, "LeftButton")
    t.eq(ex.box:GetText(), Q.L.UI_TELEMETRY_UNAVAILABLE)
    -- assistant
    Mock.click(O:Widget("wizard").button, "LeftButton")
    t.ok(QuestifyWizard and QuestifyWizard:IsShown(), "wizard opened")
    -- position du suivi remise à sa place
    O:Open("tracker")
    Q.Settings:Set("tracker.point", { "TOPLEFT", "BOTTOMLEFT", 100, 200 })
    Mock.click(O:Widget("trackerResetPosition").button, "LeftButton")
    t.eq(Q.Settings:Get("tracker.point"), nil)
    noErrors(t)
  end,

  keybind_hint_shows_the_bound_key = function(t)
    local Q = load()
    local O = Q.UI.Options
    O:Open("automation")
    local w = O:Widget("keyAutoTarget")
    t.ok(plain(w.label:GetText()):find(Q.L.OPT_KEY_NONE, 1, true), "not bound")
    GetBindingKey = function(action) if action == "CLICK QuestifyAutoTarget:LeftButton" then return "SHIFT-F" end end
    GetBindingText = function(key) return "Shift-F" end
    O:Open("automation")
    t.ok(plain(w.label:GetText()):find("Shift-F", 1, true), "bound key shown")
    GetBindingKey, GetBindingText = nil, nil
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Thème
  ---------------------------------------------------------------------------
  theme_section_previews_every_theme_and_applies_live = function(t)
    local Q = load()
    local O = Q.UI.Options
    O:Open("theme")
    local w = O:Widget("tracker.theme")
    local list = Q.Themes:List()
    t.eq(#w.tiles, #list)
    for i, th in ipairs(list) do
      local tile = w.tiles[i]
      t.eq(tile.value, th.key)
      t.eq({ tile.swatch:GetSize() }, { 80, 40 }, "80 x 40 preview")
      t.eq(tile.swatch.qvThemeKey, th.key, "theme applied on the preview")
      t.eq(tile.name:GetText(), th.label)
    end
    t.ok(w.tiles[1].selected:IsShown(), "parchment selected")
    Mock.click(w.tiles[2], "LeftButton")
    t.eq(Q.Settings:Get("tracker.theme"), "dark")
    t.eq(Q.UI.Tracker.themeKey, "dark", "tracker restyled at once")
    t.ok(w.tiles[2].selected:IsShown() and not w.tiles[1].selected:IsShown())
    -- opacité 0 à 100 % sur tracker.opacity, aperçus compris
    local op = O:Widget("tracker.opacity")
    t.eq(plain(op.value:GetText()), "90 %")
    op.slider:SetValue(0.5)
    t.near(Q.Settings:Get("tracker.opacity"), 0.5, 1e-9)
    t.near(Q.UI.Tracker.themeOpacity, 0.5, 1e-9, "tracker background follows")
    t.near(w.tiles[1].swatch.qvThemeOpacity, 0.5, 1e-9, "previews follow")
    t.eq(plain(op.value:GetText()), "50 %")
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Profils
  ---------------------------------------------------------------------------
  profiles_create_switch_copy_delete_reset_apply_live = function(t)
    local Q = load()
    local P = Q.Profiles
    t.eq(P:Active(), "Default")
    t.eq(P:Mode(), "account")
    t.eq(QuestifyDB.profileKeys["Testeur - Testrealm"], "Default")
    Q.Settings:Set("tracker.theme", "dark")
    Q.Settings:Set("tracker.point", { "TOPLEFT", "BOTTOMLEFT", 50, 60 })
    t.eq(Q.UI.Tracker.themeKey, "dark")
    t.eq(P:Create("Raid"), "Raid")
    t.eq(select(2, P:Create("Raid")), Q.L.PROFILE_ERR_EXISTS)
    t.eq(select(2, P:Create("  ")), Q.L.PROFILE_ERR_NAME)
    t.eq(select(2, P:Create("a|cffff0000b")), Q.L.PROFILE_ERR_NAME)
    t.eq(P:List(), { "Default", "Raid" })
    local fired = {}
    Q:On("SETTINGS_CHANGED", function(path) fired[#fired + 1] = path end)
    local changed
    Q:On("PROFILE_CHANGED", function(name) changed = name end)
    t.ok(P:SetActive("Raid"))
    t.eq(changed, "Raid")
    t.eq(Q.Settings:Get("tracker.theme"), "parchment", "new profile has the defaults")
    t.eq(Q.UI.Tracker.themeKey, "parchment", "tracker theme re-applied live")
    t.ok(contains(fired, "tracker.theme") and contains(fired, "tracker.point"), "changed paths fired")
    t.ok(not contains(fired, "autoQuest"), "unchanged paths not fired")
    t.eq(QuestifyDB.profileKeys["Testeur - Testrealm"], "Raid", "mapping saved")
    t.eq(P:Mode(), "custom")
    -- copie : le profil actif prend les valeurs de l'autre
    t.ok(P:CopyFrom("Default"))
    t.eq(Q.UI.Tracker.themeKey, "dark")
    t.eq(Q.Settings:Get("tracker.point")[3], 50)
    t.eq(select(2, P:CopyFrom("Raid")), Q.L.PROFILE_ERR_SAME)
    Q.Settings:Set("autoQuest", false)
    t.eq(QuestifyDB.profiles.Default.settings.autoQuest, nil, "copy is independent")
    -- suppression : ni l'actif, ni « Default »
    t.eq(select(2, P:Delete("Raid")), Q.L.PROFILE_ERR_ACTIVE)
    t.eq(select(2, P:Delete("Default")), Q.L.PROFILE_ERR_DEFAULT)
    t.ok(P:SetActive("Default"))
    t.eq(Q.Settings:Get("autoQuest"), true)
    t.ok(P:Delete("Raid"))
    t.eq(P:List(), { "Default" })
    t.eq(QuestifyDB.profileKeys["Testeur - Testrealm"], "Default")
    -- remise à zéro : valeurs par défaut, position comprise
    t.ok(P:Reset())
    t.eq(Q.Settings:Get("tracker.theme"), "parchment")
    t.eq(Q.Settings:Get("tracker.point"), nil)
    t.eq(Q.UI.Tracker.themeKey, "parchment")
    -- après /reload, le profil actif et ses valeurs restent
    P:Create("Solo")
    P:SetActive("Solo")
    Q.Settings:Set("tracker.width", 300)
    local Q2 = Mock.reload()
    t.eq(Q2.Profiles:Active(), "Solo")
    t.eq(Q2.Settings:Get("tracker.width"), 300)
    t.ok(Q2.Diagnostics:Report():find("Profile: Solo (custom)", 1, true), "bug report names the profile")
    noErrors(t)
  end,

  reward_role_is_per_character_and_survives_profile_switch = function(t)
    Mock.player.classFile = "SHAMAN"
    local Q = load()
    local P = Q.Profiles
    Q.Rewards:SetRole("healer")
    t.eq(Q.char.rewardRole, "healer", "stored for this character")
    P:Create("Other")
    local fired
    Q:On("SETTINGS_CHANGED", function(path, v) if path == "rewardRole" then fired = v end end)
    P:SetActive("Other")
    t.eq(Q.Rewards:Role(), "healer", "switching profiles keeps the loot profile")
    t.eq(fired, nil, "no rewardRole change fired")
    t.eq(Q.UI.MinimapButton.icon:GetTexture(), Q.UI.MinimapButton.ICONS.healer, "minimap icon unchanged")
    P:CopyFrom("Default")
    P:Reset()
    t.eq(Q.Rewards:Role(), "healer", "copy and reset keep it too")
    for name, prof in pairs(QuestifyDB.profiles) do t.eq(prof.rewardRole, nil, "no loot data in " .. name) end
    -- la fenêtre écrit dans Q.char
    local O = Q.UI.Options
    O:Open("loot")
    local w = O:Widget("rewardRole")
    for _, r in ipairs(w.radios) do if r.value == "caster" then Mock.click(r, "LeftButton") end end
    t.eq(Q.char.rewardRole, "caster")
    t.eq(QuestifyDB.profiles.Other.rewardRole, nil)
    t.ok(Q.L.OPT_TIP_REWARD_ROLE:find("outside profiles", 1, true), "tooltip says it is per character")
    noErrors(t)
  end,

  same_class_characters_keep_their_own_loot_profile_in_account_mode = function(t)
    Mock.player.classFile = "SHAMAN"
    Mock.player.name = "Premier"
    local Q = load()
    t.eq(Q.Profiles:Mode(), "account")
    Q.Rewards:SetRole("healer")
    local first = QuestifyCharDB
    -- deuxième chaman sur le même compte (ses propres SavedVariables de personnage)
    Mock.player.name = "Second"
    QuestifyCharDB = { wizardDone = true }
    local Q2 = Mock.reload()
    t.eq(Q2.Profiles:Active(), "Default", "same shared profile")
    t.eq(Q2.Rewards:Role(), "auto", "not shared with the other shaman")
    Q2.Rewards:SetRole("caster")
    local second = QuestifyCharDB
    -- retour au premier
    Mock.player.name = "Premier"
    QuestifyCharDB = first
    local Q3 = Mock.reload()
    t.eq(Q3.Rewards:Role(), "healer")
    t.eq(second.rewardRole, "caster")
    noErrors(t)
  end,

  legacy_profile_roles_are_taken_once_then_removed = function(t)
    -- profils d'une version de développement : une table de profils de butin par classe
    local Q = load({ savedVariables = {
      QuestifyDB = {
        profiles = {
          Default = { settings = { autoQuest = false }, rewardRole = { WARRIOR = "tank", SHAMAN = "healer" } },
          Raid = { settings = {}, rewardRole = { WARRIOR = "melee" } },
        },
        profileKeys = { ["Testeur - Testrealm"] = "Default" }, profileMode = "account",
      },
      QuestifyCharDB = { wizardDone = true },
    } })
    t.eq(Q.char.rewardRole, "tank", "taken for this character's class from the active profile")
    t.eq(Q.Rewards:Role(), "tank")
    t.eq(QuestifyDB.profiles.Default.rewardRole, nil, "removed from every profile")
    t.eq(QuestifyDB.profiles.Raid.rewardRole, nil)
    t.eq(Q.Settings:Get("autoQuest"), false, "options kept")
    -- un autre personnage ensuite : plus rien à reprendre
    Mock.player.name = "Shamy"
    Mock.player.classFile = "SHAMAN"
    QuestifyCharDB = { wizardDone = true }
    local Q2 = Mock.reload()
    t.eq(Q2.Rewards:Role(), "auto", "taken once only")
    -- un personnage qui a déjà son profil de butin le garde
    Mock.player.name = "Garde"
    Mock.player.classFile = "WARRIOR"
    QuestifyDB.profiles.Default.rewardRole = { WARRIOR = "tank" }
    QuestifyCharDB = { wizardDone = true, rewardRole = "melee" }
    local Q3 = Mock.reload()
    t.eq(Q3.Rewards:Role(), "melee")
    t.eq(QuestifyDB.profiles.Default.rewardRole, nil)
    noErrors(t)
  end,

  per_character_mode = function(t)
    local Q = load()
    local P = Q.Profiles
    Q.Settings:Set("tracker.theme", "gradient")
    t.ok(P:SetMode("character"))
    t.eq(P:Active(), "Testeur - Testrealm", "profile named after the character")
    t.eq(P:Mode(), "character")
    t.eq(QuestifyDB.profileMode, "character")
    t.eq(Q.Settings:Get("tracker.theme"), "gradient", "copied from the current profile")
    Q.Settings:Set("tracker.theme", "dark")
    t.eq(QuestifyDB.profiles.Default.settings.tracker.theme, "gradient", "shared profile untouched")
    -- un autre personnage, vu pour la première fois : son propre profil, copié de « Default »
    Mock.player.name = "Autre"
    local Q2 = Mock.reload()
    t.eq(Q2.Profiles:Active(), "Autre - Testrealm")
    t.eq(Q2.Settings:Get("tracker.theme"), "gradient")
    t.eq(QuestifyDB.profileKeys["Testeur - Testrealm"], "Testeur - Testrealm", "first character kept")
    -- retour au profil partagé
    t.ok(Q2.Profiles:SetMode("account"))
    t.eq(Q2.Profiles:Active(), "Default")
    t.eq(QuestifyDB.profileMode, "account")
    Mock.player.name = "Troisieme"
    local Q3 = Mock.reload()
    t.eq(Q3.Profiles:Active(), "Default", "new characters follow the account mode again")
    noErrors(t)
  end,

  migration_from_old_settings_keeps_everything = function(t)
    local old = {
      settings = { autoQuest = false, nav = { display = "tomtom", routing = false },
        tracker = { theme = "dark", opacity = 0.4, scale = 1.2, width = 300, point = { "TOPLEFT", "BOTTOMLEFT", 10, 20 },
          locked = true, nextSteps = 3, showMobs = true, autoTarget = false } },
      debug = false, minimapAngle = 123,
    }
    local Q = load({ savedVariables = {
      QuestifyDB = old,
      QuestifyCharDB = { rewardRole = "tank", wizardDone = true, manual = { ["g:x:1"] = true } },
    } })
    local d = QuestifyDB
    t.eq(d.settings, nil, "old table moved")
    t.eq(d.profiles.Default.settings.autoQuest, false)
    t.eq(Q.Settings:Get("autoQuest"), false)
    t.eq(Q.Settings:Get("nav.display"), "tomtom")
    t.eq(Q.Settings:Get("tracker.theme"), "dark")
    t.near(Q.Settings:Get("tracker.opacity"), 0.4, 1e-9)
    t.eq(Q.Settings:Get("tracker.point")[4], 20)
    t.eq(Q.Settings:Get("tracker.locked"), true)
    t.eq(Q.UI.Tracker.themeKey, "dark", "tracker starts with the migrated theme")
    t.eq(Q.Rewards:Role(), "tank", "loot profile kept for this character")
    t.eq(Q.char.rewardRole, "tank", "still in the character data")
    t.eq(d.profiles.Default.rewardRole, nil, "never in a profile")
    t.eq(Q.char.manual["g:x:1"], true, "progress stays in the character data")
    t.eq(Q.char.wizardDone, true)
    t.eq(d.minimapAngle, 123, "account data kept")
    t.eq(d.profileKeys["Testeur - Testrealm"], "Default")
    -- un deuxième personnage (chaman) garde aussi son profil de butin
    Mock.player.name = "Shamy"
    Mock.player.classFile = "SHAMAN"
    QuestifyCharDB = { rewardRole = "caster", wizardDone = true }
    local Q2 = Mock.reload()
    t.eq(Q2.Rewards:Role(), "caster")
    t.eq(QuestifyDB.profiles.Default.rewardRole, nil)
    -- une migration ne se refait pas
    local Q3 = Mock.reload()
    t.eq(Q3.Settings:Get("autoQuest"), false)
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Export et import
  ---------------------------------------------------------------------------
  serializer_and_base64_round_trip = function(t)
    local Q = load()
    local P = Q.Profiles
    for n = 0, 6 do
      local s = ""
      for i = 1, n do s = s .. string.char((i * 37) % 256) end
      t.eq(P.Base64Decode(P.Base64Encode(s)), s, "length " .. n)
    end
    local all = {}
    for i = 0, 255 do all[#all + 1] = string.char(i) end
    all = table.concat(all)
    t.eq(P.Base64Decode(P.Base64Encode(all)), all)
    t.eq(P.Base64Encode("Man"), "TWFu")
    t.eq(P.Base64Encode("Ma"), "TWE=")
    t.eq(P.Base64Decode("TWE"), nil, "bad length")
    t.eq(P.Base64Decode("TW=u"), nil, "padding in the middle")
    t.eq(P.Base64Decode("T*E="), nil, "bad character")
    local v = { a = "x:{}S3:", b = { 1, 2.5, -3, 1e-5, true, false }, [3] = "three", nested = { deep = { yes = true } },
      big = 123456789, neg = -0.125, third = 1 / 3 }
    local s = P.Serialize(v)
    t.eq(P.Serialize(v), s, "deterministic")
    local back = P.Deserialize(s)
    t.eq(back, v)
    t.eq(P.Deserialize(s .. "T"), nil, "trailing data")
    t.eq(P.Deserialize("{S1:a"), nil, "truncated")
    t.eq(P.Deserialize("S99999999:x"), nil, "length past the end")
    t.eq(P.Deserialize("{TT}"), nil, "boolean key")
    t.eq(P.Deserialize("{S1:aTS1:aF}"), nil, "duplicate key")
    t.eq(P.Deserialize("N1e999;"), nil, "infinite number")
    t.eq(P.Deserialize("X"), nil)
    t.eq(P.Deserialize(string.rep("{S1:a", 50) .. "T" .. string.rep("}", 50)), nil, "too deep")
    t.fails(function() P.Serialize({ f = function() end }) end, "functions refused")
    -- jamais loadstring dans l'import
    local f = io.open(Mock.root .. "/Questify/Core/Profiles.lua", "rb")
    local src = f:read("*a")
    f:close()
    t.ok(not src:find("loadstring%s*%(") and not src:find("RunScript%s*%(") and not src:find("[^%w_%.:]load%s*%("),
      "strict parser only")
  end,

  export_then_import_round_trips = function(t)
    Mock.player.classFile = "SHAMAN"
    local Q = load()
    local P = Q.Profiles
    Q.Settings:Set("tracker.theme", "transparent")
    Q.Settings:Set("tracker.opacity", 0.35)
    Q.Settings:Set("tracker.scale", 1.15)
    Q.Settings:Set("tracker.width", 312)
    Q.Settings:Set("tracker.point", { "TOPLEFT", "BOTTOMLEFT", 12.5, -40 })
    Q.Settings:Set("autoQuest", false)
    Q.Settings:Set("nav.display", "tomtom")
    Q.Rewards:SetRole("healer")
    local s = P:Export()
    t.eq(s:sub(1, 5), "QFY1:")
    t.eq(P:Export(), s, "same export twice")
    local raw = P.Base64Decode(s:sub(6))
    t.ok(not raw:find("manual", 1, true), "no progress inside")
    t.ok(not raw:find("rewardRole", 1, true) and not raw:find("healer", 1, true), "no loot profile inside")
    t.eq(P:Payload().rewardRole, nil)
    Q.Rewards:SetRole("caster")   -- changé après l'export : l'import n'y touche pas
    -- dans un nouveau profil
    local ok, msg = P:Import(s, "Copie")
    t.ok(ok, msg)
    t.eq(P:Active(), "Copie")
    t.eq(P:Payload("Copie"), P:Payload("Default"), "identical values")
    t.eq(Q.Settings:Get("tracker.theme"), "transparent")
    t.eq(Q.UI.Tracker.themeKey, "transparent", "applied live")
    t.eq(Q.Rewards:Role(), "caster", "import never sets the loot profile")
    t.ok(plain(msg):find("Copie", 1, true))
    -- dans le profil actuel
    P:Create("Vide")
    P:SetActive("Vide")
    t.eq(Q.Settings:Get("autoQuest"), true)
    t.ok(P:Import(s, ""))
    t.eq(P:Active(), "Vide")
    t.eq(Q.Settings:Get("autoQuest"), false)
    t.eq(Q.Settings:Get("tracker.point")[3], 12.5)
    -- chaîne recopiée avec des retours à la ligne et des espaces
    local wrapped = s:sub(1, 20) .. "\n  " .. s:sub(21, 60) .. " \r\n" .. s:sub(61)
    t.ok(P:Decode(wrapped), "whitespace ignored")
    noErrors(t)
  end,

  import_rejects_bad_strings_without_errors = function(t)
    local Q = load()
    local P = Q.Profiles
    local L = Q.L
    local before = P:Payload()
    local function encode(tbl) return "QFY1:" .. P.Base64Encode(P.Serialize(tbl)) end
    local function err(text)
      local clean, e = P:Decode(text)
      t.eq(clean, nil, "rejected: " .. tostring(text):sub(1, 40))
      return e
    end
    t.eq(err(nil), L.PROFILE_ERR_EMPTY)
    t.eq(err("   "), L.PROFILE_ERR_EMPTY)
    t.eq(err("hello"), L.PROFILE_ERR_PREFIX)
    t.eq(err("QFY1:!!!!"), L.PROFILE_ERR_CORRUPT)
    t.eq(err("QFY1:" .. P.Base64Encode("not a table")), L.PROFILE_ERR_CORRUPT)
    local good = P:Export()
    t.eq(err(good:sub(1, #good - 8)), L.PROFILE_ERR_CORRUPT, "truncated")
    t.eq(err(encode({ v = 2, settings = {} })), L.PROFILE_ERR_VERSION)
    t.eq(err(encode({ v = 1, settings = { unknown = true } })), L.PROFILE_ERR_NOTHING)
    t.eq(err("QFY1:" .. string.rep("A", 20001)), string.format(L.PROFILE_ERR_TOO_LONG, 20000), "oversize")
    local ok, e = P:Import(string.rep("x", 30000))
    t.eq(ok, false)
    t.eq(e, string.format(L.PROFILE_ERR_TOO_LONG, 20000))
    -- valeurs contrôlées une à une
    local clean, kept, dropped = P:Decode(encode({ v = 1, extra = "x",
      settings = {
        autoQuest = "yes",                                   -- type faux : ignoré
        autoReward = false,                                  -- gardé
        nav = { display = "evil", routing = true, junk = 1 }, -- choix inconnu ignoré, clé inconnue ignorée
        tracker = { scale = 99, nextSteps = -5, width = 250.6, theme = "neon", opacity = "0.5",
          point = { "TOPLEFT", "NOWHERE", 1, 2 } },
        unknownOption = true,
      },
      rewardRole = { WARRIOR = "healer", PALADIN = "tank", MARTIAN = "auto" } }))
    t.ok(clean, "partially valid string accepted")
    t.eq(clean.settings.autoQuest, nil)
    t.eq(clean.settings.autoReward, false)
    t.eq(clean.settings.nav.display, nil)
    t.eq(clean.settings.nav.routing, true)
    t.eq(clean.settings.nav.junk, nil)
    t.eq(clean.settings.tracker.scale, 1.6, "clamped to max")
    t.eq(clean.settings.tracker.nextSteps, 0, "clamped to min")
    t.eq(clean.settings.tracker.width, 251, "rounded")
    t.eq(clean.settings.tracker.theme, nil)
    t.eq(clean.settings.tracker.opacity, nil)
    t.eq(clean.settings.tracker.point, nil)
    t.eq(clean.settings.unknownOption, nil)
    t.eq(clean.rewardRole, nil, "a loot profile in the string is ignored")
    t.eq(kept, 5)
    t.eq(dropped, 9, "dropped values counted (each bad value, unknown key and the loot profile)")
    -- rien n'a changé dans le profil actif ; l'import d'une chaîne avec un profil de butin n'y touche pas
    t.eq(P:Payload(), before)
    Q.Rewards:SetRole("melee")
    t.ok(P:Import(encode({ v = 1, settings = { autoReward = false }, rewardRole = { WARRIOR = "tank" } })))
    t.eq(Q.Rewards:Role(), "melee")
    t.eq(QuestifyDB.profiles.Default.rewardRole, nil)
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Section Profils
  ---------------------------------------------------------------------------
  profiles_section_buttons = function(t)
    local Q = load()
    local O = Q.UI.Options
    local P = Q.Profiles
    O:Open("profiles")
    t.eq(shownHeaders(O), { Q.L.OPT_SEC_PROFILES, Q.L.OPT_CAT_PROFILES_ACTIVE, Q.L.OPT_CAT_PROFILES_MANAGE,
      Q.L.OPT_CAT_PROFILES_SHARE })
    -- Nouveau : nom saisi, profil créé et actif
    local new = O:Widget("profile.new")
    Mock.click(new.button, "LeftButton")
    t.ok(plain(O.statusText:GetText()) == Q.L.PROFILE_ERR_NAME, "empty name refused")
    new.input:SetText("Raid")
    Mock.click(new.button, "LeftButton")
    t.eq(P:Active(), "Raid")
    t.ok(Mock.printed(string.format(Q.L.PROFILE_CREATED, "Raid")))
    -- sélecteur du profil actif (radios sans MenuUtil)
    local active = O:Widget("profile.active")
    local names = {}
    for _, r in ipairs(active.radios) do if r:IsShown() then names[#names + 1] = r.value end end
    t.eq(names, { "Default", "Raid" })
    t.eq(active.radios[1].label:GetText(), Q.L.PROFILE_DEFAULT_NAME)
    t.ok(active.radios[2]:GetChecked())
    Q.Settings:Set("tracker.theme", "dark")
    Mock.click(active.radios[1], "LeftButton")
    t.eq(P:Active(), "Default")
    t.eq(Q.UI.Tracker.themeKey, "parchment")
    -- Copier depuis… : liste des autres profils, puis confirmation
    t.eq(O:RunAction(Q.OptionsSchema:Entry("profile.copy"), O:Widget("profile.copy").button,
      O:Widget("profile.copy")), "fallback")
    local picker = QuestifyOptionsPicker
    t.ok(picker:IsShown())
    t.eq(picker.buttons[1]:GetText(), "Raid")
    Mock.click(picker.buttons[1], "LeftButton")
    t.ok(not picker:IsShown())
    t.eq(Mock.lastCall("StaticPopup_Show").args[1], "QUESTIFY_OPTIONS_CONFIRM")
    t.eq(Q.Settings:Get("tracker.theme"), "parchment", "nothing before confirmation")
    confirm()
    t.eq(Q.Settings:Get("tracker.theme"), "dark")
    -- Supprimer… : jamais le profil actif ni « Default »
    Mock.click(O:Widget("profile.delete").button, "LeftButton")
    t.ok(picker:IsShown())
    t.eq(picker.buttons[1]:GetText(), "Raid")
    t.ok(not picker.buttons[2] or not picker.buttons[2]:IsShown(), "only Raid")
    Mock.click(picker.buttons[1], "LeftButton")
    confirm()
    t.eq(P:List(), { "Default" })
    Mock.click(O:Widget("profile.delete").button, "LeftButton")
    t.eq(plain(O.statusText:GetText()), Q.L.OPT_PICK_NONE)
    -- Réinitialiser, après confirmation
    Mock.click(O:Widget("profile.reset").button, "LeftButton")
    t.eq(Q.Settings:Get("tracker.theme"), "dark")
    confirm()
    t.eq(Q.Settings:Get("tracker.theme"), "parchment")
    -- type de profil : par personnage
    local mode = O:Widget("profile.mode")
    t.ok(mode.radios[1]:GetChecked(), "per account")
    Mock.click(mode.radios[2], "LeftButton")
    t.eq(P:Active(), "Testeur - Testrealm")
    t.ok(mode.radios[2]:GetChecked() and not mode.radios[1]:GetChecked())
    noErrors(t)
  end,

  profiles_section_with_menuutil_lists_profiles_in_a_menu = function(t)
    local elements = {}
    MenuUtil = { CreateContextMenu = function(owner, gen)
      local root = {
        CreateTitle = function(_, text) elements[#elements + 1] = { kind = "title", text = text } end,
        CreateButton = function(_, text, fn, data) elements[#elements + 1] = { kind = "button", text = text, fn = fn, data = data } end,
      }
      gen(owner, root)
    end }
    local Q = load()
    local O = Q.UI.Options
    Q.Profiles:Create("Raid")
    O:Open("profiles")
    Mock.click(O:Widget("profile.copy").button, "LeftButton")
    t.eq(elements[1].text, Q.L.OPT_PICK_COPY)
    t.eq(elements[2].data, "Raid")
    elements[2].fn()
    t.eq(Mock.lastCall("StaticPopup_Show").args[1], "QUESTIFY_OPTIONS_CONFIRM")
    noErrors(t)
  end,

  export_and_import_panels = function(t)
    local Q = load()
    local O = Q.UI.Options
    local P = Q.Profiles
    Q.Settings:Set("tracker.theme", "gradient")
    O:Open("profiles")
    local ex = O:Widget("profile.export")
    Mock.click(ex.button, "LeftButton")
    t.ok(ex.box:IsShown())
    t.eq(ex.box:GetText(), P:Export())
    t.eq(ex.hint:GetText(), Q.L.OPT_COPY_HINT)
    -- lecture seule : une frappe remet le texte
    ex.box:SetText("changed")
    ex.box:GetScript("OnTextChanged")(ex.box, true)
    t.eq(ex.box:GetText(), P:Export())
    local s = ex.box:GetText()
    -- import : chaîne abîmée -> message, pas de confirmation
    local im = O:Widget("profile.import")
    t.ok(not im.box:IsShown())
    Mock.click(im.button, "LeftButton")
    t.ok(im.box:IsShown() and im.target:IsShown() and im.apply:IsShown())
    local popups = Mock.countCalls("StaticPopup_Show")
    im.box:SetText("QFY1:broken")
    Mock.click(im.apply, "LeftButton")
    t.eq(im.status:GetText(), Q.L.PROFILE_ERR_CORRUPT)
    t.eq(Mock.countCalls("StaticPopup_Show"), popups, "no confirmation for a bad string")
    -- chaîne valide dans un nouveau profil, après confirmation
    Q.Settings:Set("tracker.theme", "parchment")
    im.box:SetText(s)
    im.target:SetText("Partage")
    Mock.click(im.apply, "LeftButton")
    t.eq(Mock.lastCall("StaticPopup_Show").args[1], "QUESTIFY_OPTIONS_CONFIRM")
    t.ok(plain(Mock.lastCall("StaticPopup_Show").args[2]):find("Partage", 1, true))
    t.eq(P:Active(), "Default", "nothing before confirmation")
    confirm()
    t.eq(P:Active(), "Partage")
    t.eq(Q.Settings:Get("tracker.theme"), "gradient")
    t.eq(Q.UI.Tracker.themeKey, "gradient")
    t.ok(plain(im.status:GetText()):find("Partage", 1, true))
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Ouverture
  ---------------------------------------------------------------------------
  window_opens_from_minimap_menu_slash_and_game_settings = function(t)
    local Q = load()
    -- menu de la minicarte (menu maison, sans MenuUtil)
    local B = Q.UI.MinimapButton
    t.eq(B:OpenMenu(), "fallback")
    local row
    for _, r in ipairs(B.fallback.rows) do if r.entry and r.entry.key == "options" then row = r end end
    Mock.click(row, "LeftButton")
    t.ok(QuestifyOptions:IsShown(), "from the minimap menu")
    QuestifyOptions:Hide()
    SlashCmdList.QUESTIFY("options")
    t.ok(QuestifyOptions:IsShown(), "from /qf options")
    QuestifyOptions:Hide()
    -- Échap > Options > AddOns : page enregistrée avec un bouton
    local reg = Mock.lastCall("Settings.RegisterCanvasLayoutCategory")
    t.ok(reg, "canvas registered")
    t.eq(reg.args[2], "Questify")
    t.eq(Mock.countCalls("Settings.RegisterAddOnCategory"), 1)
    local closed = 0
    SettingsPanel = Mock.newObject("Frame", "SettingsPanel")
    rawset(SettingsPanel, "Close", function() closed = closed + 1 end)
    Mock.click(Q.UI.Options.canvas.openButton, "LeftButton")
    t.ok(QuestifyOptions:IsShown(), "from the game settings")
    t.eq(closed, 1, "game settings closed first")
    noErrors(t)
  end,
}
