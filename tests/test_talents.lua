-- Tests des talents (Q.Talents, alerte du suivi, Q.UI.TalentPicker).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

-- Deux arbres de test : { [tab] = { { name, tier, column, maxRank } } }, rangs dans `ranks`.
local TREES = {
  { name = "Arms", talents = { { "Improved Heroic Strike", 1, 1, 3 }, { "Deflection", 1, 2, 5 }, { "Tactical Mastery", 2, 2, 5 } } },
  { name = "Fury", talents = { { "Cruelty", 1, 2, 5 } } },
}
local ranks, opened

local function install()
  ranks = {}
  opened = 0
  GetNumTalentTabs = function() return #TREES end
  GetTalentTabInfo = function(tab) return TREES[tab] and TREES[tab].name end
  GetNumTalents = function(tab) return TREES[tab] and #TREES[tab].talents or 0 end
  GetTalentInfo = function(tab, i)
    local t = TREES[tab] and TREES[tab].talents[i]
    if not t then return nil end
    return t[1], 132000 + i, t[2], t[3], ranks[tab .. ":" .. i] or 0, t[4]
  end
  UnitCharacterPoints = nil
  ToggleTalentFrame = function() opened = opened + 1 end
end

local function load()
  Ext.install()
  install()
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  Q.TalentBuildData.WARRIOR = {
    { key = "W_TEST", kind = "leveling", title = { enUS = "Arms leveling", frFR = "Armes montée" },
      order = { { 1, 1, 2 }, { 1, 1, 2 }, { 1, 2, 2 } } },
    { key = "W_DUNGEON", kind = "dungeon", title = { enUS = "Protection dungeons" }, order = { { 1, 1, 1 } } },
  }
  return Q
end

local function levelUp(lvl)
  Mock.player.level = lvl
  Mock.fire("PLAYER_LEVEL_UP", lvl)
  Mock.advance(0.6)
end

return {
  no_alert_before_level_10 = function(t)
    local Q = load()
    levelUp(9)
    t.eq(Q.Talents:Unspent(), 0)
    t.eq(Q.Talents:Alert(), nil)
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
  end,

  level_10_announces_and_asks_for_a_preset = function(t)
    local Q = load()
    levelUp(10)
    t.eq(Q.Talents:Unspent(), 1, "computed from level and spent points")
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(Mock.countPrinted(Q.L.TALENT_FIRST), 1)
    local P = Q.UI.TalentPicker
    t.ok(P.frame and P.frame:IsShown(), "preset asked at level 10")
    t.eq(#P.shownCards, 2, "one card per preset")
    t.eq(P.shownCards[1].kind, "leveling"); t.eq(P.shownCards[2].kind, "dungeon")
    t.eq(#P.shownCards[1].tiles, 8, "rotating planet: world map tiles behind a round mask")
    P.frame:GetScript("OnUpdate")(P.frame, 1)
    t.ok(P.shownCards[2].anims[1]:IsPlaying(), "portal swirls")
    P.shownCards[1]:GetScript("OnClick")(P.shownCards[1])
    t.ok(not P.frame:IsShown())
    t.eq(Q.char.talentPreset, "W_TEST")
    local nxt = Q.Talents:Next()
    t.eq(nxt.name, "Deflection"); t.eq(nxt.rank, 0); t.eq(nxt.tabName, "Arms")
    t.eq(Q.UI.Tracker.talentText:GetText(), string.format(Q.L.UI_TALENT_ALERT_NEXT, "Deflection"))
    t.eq(#Mock.errors, 0)
  end,

  advice_follows_ranks_and_each_level = function(t)
    local Q = load()
    Q.Talents:Choose("W_TEST")
    levelUp(10)
    ranks["1:2"] = 1
    Mock.fire("CHARACTER_POINTS_CHANGED")
    t.eq(Q.Talents:Alert(), nil, "point spent")
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
    levelUp(11)
    t.eq(Q.Talents:Next().name, "Deflection", "second rank")
    t.eq(Mock.countPrinted(string.format(Q.L.TALENT_LEVEL_ADVICE, "Deflection (Arms, rank 2/5)")), 1)
    ranks["1:2"] = 2
    levelUp(12)
    t.eq(Q.Talents:Next().name, "Tactical Mastery")
  end,

  client_points_api_wins = function(t)
    local Q = load()
    levelUp(12)
    UnitCharacterPoints = function() return 0 end
    t.eq(Q.Talents:Unspent(), 0, "client says no point left")
  end,

  click_opens_talent_frame_not_in_combat = function(t)
    local Q = load()
    levelUp(10)
    local A = Q.UI.Tracker.talentAlert
    A:GetScript("OnClick")(A)
    t.eq(opened, 1)
    Mock.player.combat = true
    A:GetScript("OnClick")(A)
    t.eq(opened, 1, "not in combat")
    Mock.player.combat = false
  end,

  unknown_tree_gives_no_advice = function(t)
    local Q = load()
    Q.TalentBuildData.WARRIOR[1].order = { { 3, 5, 1 } }
    Q.Talents:Choose("W_TEST")
    levelUp(10)
    t.eq(Q.Talents:Next(), nil, "tree of another game version: no wrong advice")
    t.ok(Q.UI.Tracker.talentAlert:IsShown(), "reminder still there")
  end,

  option_off = function(t)
    local Q = load()
    Q.Settings:Set("talentAlert", false)
    levelUp(10)
    t.eq(Q.Talents:Alert(), nil)
    t.eq(Mock.countPrinted(Q.L.TALENT_FIRST), 0)
  end,

  cards_wait_for_end_of_combat = function(t)
    local Q = load()
    Mock.player.combat = true
    levelUp(10)
    local P = Q.UI.TalentPicker
    t.ok(not (P.frame and P.frame:IsShown()), "not in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(P.frame:IsShown(), "after combat")
    Mock.player.combat = true
    Mock.fire("PLAYER_REGEN_DISABLED")
    t.ok(not P.frame:IsShown(), "closed when a fight starts")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(P.frame:IsShown(), "back after the fight")
    P.noneButton:GetScript("OnClick")(P.noneButton)
    t.eq(Q.char.talentPreset, false)
  end,
}
