-- Tests de l'onglet Build (UI/BuildPane.lua) : liste des builds, éditeur, builds obsolètes, roue dentée.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")
local Traits = dofile(Mock.root .. "/tests/mock_ext_traits.lua")

local A, ALAC, C, OVER, OTHER = 100, 101, 102, 103, 200
local GONE = 999

local SHAPE = {
  [A] = { group = 1, tier = 1, col = 1, maxRanks = 5, requires = {} },
  [C] = { group = 1, tier = 1, col = 2, maxRanks = 5, requires = {} },
  [ALAC] = { group = 1, tier = 2, col = 1, maxRanks = 3, requires = {} },
  [OVER] = { group = 1, tier = 3, col = 1, maxRanks = 3, requires = { ALAC } },
  [OTHER] = { group = 2, tier = 1, col = 1, maxRanks = 1, requires = {} },
}
local NAMES = { [A] = "Alpha", [ALAC] = "Alacrity", [C] = "Charlie", [OVER] = "Overload", [OTHER] = "Other" }

local function rep(id, n, into)
  into = into or {}
  for _ = 1, n do into[#into + 1] = id end
  return into
end

-- opts : combat, groups (1 ou 2), noShape, level
local function load(opts)
  opts = opts or {}
  Mock.player.classFile = "SHAMAN"; Mock.player.level = opts.level or 20
  Mock.player.combat = opts.combat == true
  Ext.install()
  Mock.spec.index = 1
  C_SpecializationInfo.GetNumSpecGroups = function() return opts.groups or 1 end
  C_SpecializationInfo.GetActiveSpecGroup = function() return 1 end
  C_Spell = { GetSpellName = function(id) return NAMES[id] end,
    GetSpellTexture = function(id) return 900000 + id end }
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  Q.TalentShapeData = { SHAMAN = not opts.noShape and SHAPE or nil }
  Q.TalentBuildData = { SHAMAN = {
    { key = "off1", class = "SHAMAN", specID = 262, name = { enUS = "Elemental leveling", frFR = "Élémentaire" },
      source = "icy veins", official = true, order = rep(A, 5) },
    { key = "off2", class = "SHAMAN", specID = 263, name = { enUS = "Enhancement" }, source = "wowhead",
      official = true, order = { C } },
    { key = "old", class = "SHAMAN", specID = 262, name = { enUS = "Old one" }, source = "icy veins",
      official = true, order = { A, GONE, A } },
  } }
  return Q
end

local function open(Q)
  SlashCmdList.QUESTIFY("build")
  return Q.UI.BuildPane
end

local function entry(P, key)
  for _, e in ipairs(P:Entries()) do
    if e.key == key then return e end
  end
end

local function Builds_last(Q)
  local l = Q.db.builds.SHAMAN
  return l[#l]
end

local function keys(P)
  local out = {}
  for _, e in ipairs(P:Entries()) do out[#out + 1] = e.key end
  return out
end

return {
  obsolete_build_greyed_and_not_usable = function(t)
    local Q = load()
    local P = open(Q)
    local e = entry(P, "old")
    t.ok(e.obsolete, "flagged")
    t.ok(e.label:find("⚠", 1, true), "warning sign")
    t.ok(e.label:find(string.format(Q.L.BUILD_OBSOLETE_NAME, "Old one"), 1, true), e.label)
    t.ok(not entry(P, "off1").obsolete)
    local r, g = P.ui.menuRows[e.index].label:GetTextColor()
    t.ok(r == g and r < 0.7, "grey")
    P:Select("old")
    t.ok(P.ui.banner:IsShown(), "banner")
    t.ok(P.ui.banner:GetText():find(Q.L.BUILD_OBSOLETE_missing, 1, true), P.ui.banner:GetText())
    t.ok(not P.ui.use:IsEnabled(), "use disabled")
    t.ok(not P.ui.save:IsEnabled(), "save disabled")
    Mock.click(P.ui.use)
    t.eq(Q.Builds:Active(1), nil, "not made active")
    -- on ne le modifie pas
    local before = #P.state.editor:Order()
    Mock.click(P.ui.nodes[A], "LeftButton")
    t.eq(#P.state.editor:Order(), before, "locked")
    P:Select("off1")
    t.ok(not P.ui.banner:IsShown())
    t.ok(P.ui.use:IsEnabled() and P.ui.save:IsEnabled())
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  every_obsolete_reason_has_a_string = function(t)
    local Q = load()
    for _, r in ipairs({ "missing", "maxrank", "tier", "requires", "toolong", "index" }) do
      t.ok(Q.L["BUILD_OBSOLETE_" .. r] and not Q.L["BUILD_OBSOLETE_" .. r]:find("BUILD_OBSOLETE", 1, true), r)
    end
  end,

  edit_official_then_save_creates_copy = function(t)
    local Q = load()
    local P = open(Q)
    P:Select("off1")
    Mock.click(P.ui.nodes[OVER], "LeftButton")      -- palier 3 sans 10 points : refusé
    t.eq(#P.state.editor:Order(), 5)
    t.ok(P.ui.msg:GetText():find(Q.L.TALENT_REASON_TIER, 1, true), tostring(P.ui.msg:GetText()))
    Mock.click(P.ui.nodes[C], "LeftButton")
    t.eq(#P.state.editor:Order(), 6)
    t.eq(#Q.TalentBuildData.SHAMAN[1].order, 5, "official untouched")
    P.ui.nameBox:SetText("Mon essai")
    Mock.click(P.ui.save)
    t.eq(#Q.TalentBuildData.SHAMAN[1].order, 5, "official still untouched")
    t.eq(#Q.db.builds.SHAMAN, 1, "one personal copy")
    local saved = Q.db.builds.SHAMAN[1]
    t.eq(saved.name, "Mon essai"); t.eq(#saved.order, 6); t.eq(saved.official, false); t.eq(saved.specID, 262)
    t.eq(P.state.key, saved.key, "copy selected")
    -- right click removes the last point of that talent
    Mock.click(P.ui.nodes[C], "RightButton")
    t.eq(#P.state.editor:Order(), 5)
    Mock.click(P.ui.save)
    t.eq(#Q.db.builds.SHAMAN, 1, "personal build updated in place")
    t.eq(#Q.db.builds.SHAMAN[1].order, 5)
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  save_official_with_same_name_gets_default_name = function(t)
    local Q = load()
    local P = open(Q)
    P:Select("off1")
    Mock.click(P.ui.save)
    t.eq(Q.db.builds.SHAMAN[1].name, Q.L.BUILD_NEW_NAME)
  end,

  duplicate_obsolete_drops_missing = function(t)
    local Q = load()
    local P = open(Q)
    P:Select("old")
    Mock.click(P.ui.duplicate)
    t.eq(#Q.db.builds.SHAMAN, 1)
    local copy = Q.db.builds.SHAMAN[1]
    t.eq(copy.order, { A, A }, "missing spellID dropped")
    t.eq(copy.official, false)
    t.eq(P.state.key, copy.key)
    t.ok(not P.ui.banner:IsShown(), "copy is a valid personal build")
    t.ok(P.ui.msg:GetText():find(Q.L.BUILD_DUPLICATED_DROPPED, 1, true), tostring(P.ui.msg:GetText()))
    t.eq(#Q.TalentBuildData.SHAMAN[3].order, 3, "official untouched")
    Mock.click(P.ui.nodes[A], "LeftButton")
    t.eq(#P.state.editor:Order(), 3, "completed by the user")
  end,

  duplicate_cuts_to_valid_prefix = function(t)
    local Q = load()
    local P = open(Q)
    local data = Q.TalentBuildData.SHAMAN
    local cases = {
      { key = "tierbad", order = { A, OVER } },                       -- tier
      { key = "maxbad", order = rep(A, 6) },                           -- maxrank
      { key = "gonebad", order = { A, A, GONE, A, A, A, ALAC } },     -- valid once GONE is dropped? A x5 then ALAC ok
      { key = "gonecut", order = { GONE, ALAC, A } },                  -- invalid after dropping GONE (tier)
    }
    for _, c in ipairs(cases) do
      data[#data + 1] = { key = c.key, class = "SHAMAN", specID = 262, name = { enUS = c.key }, official = true,
        source = "x", order = c.order }
    end
    for _, c in ipairs(cases) do
      P:Select(c.key)
      t.ok(P.state.obsolete, c.key .. " obsolete")
      Mock.click(P.ui.duplicate)
      local copy = Builds_last(Q)
      t.ok(Q.Builds:Validate(copy, P.state.tree), c.key .. " copy validates")
      t.ok(not P.state.obsolete, c.key .. " editable")
      t.ok(P.ui.save:IsEnabled() and P.ui.use:IsEnabled())
    end
    P:Select("tierbad"); Mock.click(P.ui.duplicate)
    t.eq(Builds_last(Q).order, { A })
    t.eq(P.ui.msg:GetText(), string.format(Q.L.BUILD_DUPLICATED_CUT, 11))
    P:Select("gonecut"); Mock.click(P.ui.duplicate)
    t.eq(Builds_last(Q).order, {}, "ALAC at tier 2 without points cut")
    P:Select("maxbad"); Mock.click(P.ui.duplicate)
    t.eq(#Builds_last(Q).order, 5)
    -- the copy can be edited
    Mock.click(P.ui.nodes[C], "LeftButton")
    t.eq(#P.state.editor:Order(), 6)
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  obsolete_official_keeps_official_tag = function(t)
    local Q = load()
    local P = open(Q)
    t.ok(entry(P, "old").label:find(Q.L.BUILD_OFFICIAL_TAG, 1, true))
  end,

  use_applies_changed_name_on_personal = function(t)
    local Q = load()
    local key = Q.Builds:Save({ class = "SHAMAN", specID = 262, name = "Avant", order = { A } })
    local P = open(Q)
    P:Select(key)
    P.ui.nameBox:SetText("Après")
    Mock.click(P.ui.use)
    t.eq(Q.Builds:Get(key).name, "Après")
    t.eq(Q.Builds:Active(1).key, key)
  end,

  group_selector_hidden_when_single = function(t)
    local Q = load({ groups = 1 })
    local P = open(Q)
    t.ok(not P.ui.groupMain:IsShown() and not P.ui.groupAlt:IsShown())
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  group_selector_shown_with_two_groups = function(t)
    local Q = load({ groups = 2 })
    local P = open(Q)
    t.ok(P.ui.groupMain:IsShown() and P.ui.groupAlt:IsShown())
    t.eq(P.ui.groupMain:GetText(), Q.L.BUILD_GROUP_PRIMARY)
    t.eq(P.ui.groupAlt:GetText(), Q.L.BUILD_GROUP_SECONDARY)
    P:Select("off1")
    Mock.click(P.ui.groupAlt)
    Mock.click(P.ui.use)
    t.eq(Q.Builds:Active(2).key, "off1", "second group gets its build")
    t.eq(Q.Builds:Active(1), nil, "first group untouched")
  end,

  list_puts_group_spec_first_then_official = function(t)
    local Q = load()
    Q.Builds:Save({ class = "SHAMAN", specID = 262, name = "Perso", order = {} })
    local P = open(Q)
    t.eq(keys(P)[1], "off1")
    t.eq(keys(P)[2], "old")
    t.eq(P:Entries()[3].personal, true, "personal build of the spec after the official ones of the spec")
    t.eq(keys(P)[4], "off2", "other spec last")
  end,

  list_marks_active_official_and_source = function(t)
    local Q = load()
    Q.Builds:SetActive(1, "off1")
    local P = open(Q)
    local e = entry(P, "off1")
    t.ok(e.label:find("★", 1, true), e.label)
    t.ok(e.label:find(Q.L.BUILD_OFFICIAL_TAG, 1, true), e.label)
    t.eq(e.source, "Icy Veins")
    t.eq(entry(P, "off2").source, "Wowhead")
    t.ok(not entry(P, "off2").label:find("★", 1, true))
    P:Select("off1")
    t.eq(P.ui.source:GetText(), string.format(Q.L.BUILD_SOURCE, "Icy Veins"))
    t.ok(P.ui.badge:GetText() and P.ui.badge:GetText() ~= "", "active badge")
    P:Select("off2")
    t.eq(P.ui.source:GetText(), string.format(Q.L.BUILD_SOURCE, "Wowhead"))
  end,

  use_build_sets_active = function(t)
    local Q = load()
    local P = open(Q)
    P:Select("off1")
    Mock.click(P.ui.use)
    t.eq(Q.Builds:Active(1).key, "off1")
  end,

  trees_show_icons_ranks_and_tooltips = function(t)
    local Q = load()
    local shown
    local oldSet = rawget(GameTooltip, "SetSpellByID")
    GameTooltip.SetSpellByID = function(_, id) shown = id end
    local P = open(Q)
    P:Select("off1")
    local node = P.ui.nodes[A]
    t.ok(node:IsShown())
    t.eq(node.icon:GetTexture(), 900000 + A)
    t.eq(node.rank:GetText(), "5/5")
    t.eq(P.ui.nodes[C].rank:GetText(), "0/5")
    node:GetScript("OnEnter")(node)
    t.eq(shown, A, "game tooltip by spellID")
    node:GetScript("OnLeave")(node)
    rawset(GameTooltip, "SetSpellByID", oldSet)
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  level_slider_changes_view_and_blocks_edit = function(t)
    local Q = load()
    local P = open(Q)
    P:Select("off1")
    t.eq({ P.ui.slider:GetMinMaxValues() }, { 10, 60 })
    P.ui.slider:SetValue(12)
    t.eq(P.ui.nodes[A].rank:GetText(), "3/5", "ranks at level 12")
    Mock.click(P.ui.nodes[C], "LeftButton")
    t.eq(#P.state.editor:Order(), 5, "no edit away from level 60")
    P.ui.slider:SetValue(60)
    t.eq(P.ui.nodes[A].rank:GetText(), "5/5")
  end,

  order_list_and_remove = function(t)
    local Q = load({ level = 11 })
    local P = open(Q)
    P:Select("off1")
    t.eq(#P.ui.rows, 51)
    local r1 = P.ui.rows[1]
    t.ok(r1.level:GetText():find("10", 1, true))
    t.ok(r1.name:GetText():find("Alpha", 1, true))
    t.eq(r1.count:GetText(), "1/5")
    t.ok(r1.done:IsShown(), "level passed")
    t.ok(P.ui.rows[2].done:IsShown(), "level 11 passed")
    t.ok(not P.ui.rows[3].done:IsShown())
    t.ok(P.ui.rows[3].next:IsShown(), "next level highlighted")
    t.ok(P.ui.rows[6].remove and not P.ui.rows[6].remove:IsShown(), "free row: no remove")
    Mock.click(P.ui.rows[2].remove)
    t.eq(#P.state.editor:Order(), 4)
    t.ok(P.ui.rows[1].count:GetText() == "1/5")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  remove_refused_keeps_order_and_says_why = function(t)
    local Q = load()
    local P = open(Q)
    -- build with a dependency: A x5 then Alacrity then Overload cannot lose Alacrity
    Q.TalentBuildData.SHAMAN[1].order = { A, A, A, A, A, ALAC, ALAC, ALAC, OVER }
    P:Select("off1")
    Mock.click(P.ui.rows[6].remove)
    t.eq(#P.state.editor:Order(), 9, "order unchanged")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  gear_menu_toggles_talentAlert = function(t)
    local Q = load()
    local P = open(Q)
    t.ok(Q.Settings:Get("talentAlert") ~= false)
    Mock.click(P.ui.gear)
    t.ok(P.ui.gearMenu:IsShown())
    t.ok(P.ui.alertCheck:GetChecked(), "checkbox mirrors setting")
    P.ui.alertCheck:SetChecked(false)
    Mock.click(P.ui.alertCheck)
    t.eq(Q.Settings:Get("talentAlert"), false)
    P.ui.alertCheck:SetChecked(true)
    Mock.click(P.ui.alertCheck)
    t.eq(Q.Settings:Get("talentAlert"), true)
  end,

  talentAlert_not_in_options = function(t)
    local Q = load()
    t.eq(Q.OptionsSchema:Entry("talentAlert"), nil, "no options entry")
    t.eq(Q.OptionsSchema:EntryForPath("talentAlert"), nil)
    t.eq(Q.Settings:Get("talentAlert"), true, "setting kept")
  end,

  from_tree_creates_build = function(t)
    Traits.install({ groups = { { name = "Elem", talents = { { A, 1, 1, 5 }, { C, 1, 2, 5 } } } },
      ranks = { [A] = 3, [C] = 2 }, unspent = 0 })
    local Q = load()
    local P = open(Q)
    Mock.click(P.ui.gear)
    Mock.click(P.ui.fromTree)
    t.eq(#Q.db.builds.SHAMAN, 1)
    local b = Q.db.builds.SHAMAN[1]
    t.eq(#b.order, 5)
    t.eq(b.official, false)
    local active = Q.Builds:Active(1)
    t.ok(active and active.key == b.key, "followed")
    t.eq(P.state.key, b.key, "selected in the editor")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  from_tree_without_tree_says_so = function(t)
    local Q = load()
    local P = open(Q)
    Mock.click(P.ui.gear)
    Mock.click(P.ui.fromTree)
    t.eq(Q.db.builds and Q.db.builds.SHAMAN and #Q.db.builds.SHAMAN or 0, 0)
    t.ok(Mock.printed(Q.L.BUILD_NO_LIVE_TREE) or P.ui.msg:GetText() == Q.L.BUILD_NO_LIVE_TREE)
  end,

  no_shape_shows_message_without_error = function(t)
    local Q = load({ noShape = true })
    local P = open(Q)
    t.ok(P.ui.msg:GetText():find(Q.L.BUILD_NO_TREE, 1, true), tostring(P.ui.msg:GetText()))
    t.ok(not P.ui.save:IsEnabled())
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  built_after_combat = function(t)
    local Q = load({ combat = true })
    local before = #Mock.frames
    t.eq(Q.UI.BuildWindow:Open("build"), false)
    t.eq(#Mock.frames, before, "no frame created in combat")
    t.ok(not Q.UI.BuildPane.ui, "content not built")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    local P = Q.UI.BuildPane
    t.ok(P.ui and P.ui.save, "built at regen")
    t.ok(Q.UI.BuildWindow:Pane("build"):IsShown())
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  never_mutates_official_tables = function(t)
    local Q = load()
    local P = open(Q)
    P:Select("off1")
    local order = Q.TalentBuildData.SHAMAN[1].order
    Mock.click(P.ui.nodes[C], "LeftButton")
    Mock.click(P.ui.nodes[A], "RightButton")
    Mock.click(P.ui.rows[1].remove)
    t.eq(#order, 5)
    t.ok(Q.TalentBuildData.SHAMAN[1].order == order)
  end,
}
