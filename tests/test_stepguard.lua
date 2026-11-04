-- Tests du garde-fou des étapes impossibles (Q.StepGuard).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load()
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  Q.Settings:Set("autoQuest", false)
  Mock.units.npc = { guid = "Creature-0-1-0-1-658-0000ABCD", name = "Sten Stoutarm" }
  return Q
end

return {
  quest_not_offered_by_its_giver_is_skipped = function(t)
    local Q = load()
    local cur = Q.Progress:Current()
    t.eq(cur.step.questId, 179)
    Mock.gossip.available = { { questID = 233, title = "Coldridge Valley Mail Delivery" } }
    Mock.fire("GOSSIP_SHOW")
    t.eq(Q.Progress:State(cur), "skipped", "179 not offered by Sten")
    t.ok(Q.Progress:Current() ~= cur)
    t.ok(Mock.countPrinted("step skipped") >= 1 or Mock.countPrinted("étape passée") >= 1)
  end,

  offered_quest_kept = function(t)
    local Q = load()
    local cur = Q.Progress:Current()
    Mock.gossip.available = { { questID = 179, title = "Dwarven Outfitters" } }
    Mock.fire("GOSSIP_SHOW")
    t.eq(Q.Progress:State(cur), "active")
  end,

  other_npc_ignored = function(t)
    local Q = load()
    local cur = Q.Progress:Current()
    Mock.units.npc = { guid = "Creature-0-1-0-1-713-0000ABCD", name = "Balir Frosthammer" }
    Mock.gossip.available = { { questID = 170, title = "A New Threat" } }
    Mock.fire("GOSSIP_SHOW")
    t.eq(Q.Progress:State(cur), "active", "not the giver of the current step")
  end,

  -- Quête grise pour le joueur (C_QuestLog.IsQuestTrivial) : pas de saut, une ligne d'aide.
  trivial_quest_not_skipped_hint_instead = function(t)
    local Q = load()
    C_QuestLog.IsQuestTrivial = function(id) return id == 179 end
    local cur = Q.Progress:Current()
    Mock.gossip.available = { { questID = 233, title = "Coldridge Valley Mail Delivery" } }
    Mock.fire("GOSSIP_SHOW")
    t.eq(Q.Progress:State(cur), "active", "gray quest hidden from gossip: not skipped")
    local msg = string.format(Q.L.GUARD_HINT_TRIVIAL, "Dwarven Outfitters", "Sten Stoutarm")
    t.eq(Mock.countPrinted(msg), 1)
    Mock.fire("GOSSIP_SHOW")
    t.eq(Mock.countPrinted(msg), 1, "hint once per step")
    t.eq(#Mock.errors, 0)
  end,

  -- Sans IsQuestTrivial : niveau de la quête contre UnitQuestTrivialLevelRange (DifficultyUtil).
  trivial_by_level_range = function(t)
    local Q = load()
    UnitQuestTrivialLevelRange = function() return 5 end
    Mock.player.level = 10
    Mock.fire("PLAYER_LEVEL_UP", 10)
    local cur = Q.Progress:Current()
    t.eq(cur.step.questId, 179)
    t.ok(Q.StepGuard:IsTrivial(179, Q.QDB:Quest(179)), "level 1 quest at level 10, range 5")
    Mock.gossip.available = {}
    Mock.fire("GOSSIP_SHOW")
    t.eq(Q.Progress:State(cur), "active")
    t.eq(Mock.countPrinted(string.format(Q.L.GUARD_HINT_TRIVIAL, "Dwarven Outfitters", "Sten Stoutarm")), 1)
    Mock.player.level = 6
    Mock.fire("PLAYER_LEVEL_UP", 6)
    t.ok(not Q.StepGuard:IsTrivial(179, Q.QDB:Quest(179)), "within the range: not gray")
  end,

  -- Prérequis pas encore faits (Q.QDB:PrereqsMet) : pas de saut, une ligne d'aide.
  prereqs_not_met_not_skipped_hint_instead = function(t)
    local Q = load()
    -- 233 (Sten) demande 179, encore à faire plus loin dans la route
    Q:RegisterGuide({ id = "T_prereq", faction = "Alliance", steps = {
      { "accept", 233 }, { "accept", 179 }, { "turnin", 179 } } })
    Q.Progress:SetGuide("T_prereq")
    local cur = Q.Progress:Current()
    t.eq(cur.step.questId, 233)
    t.eq(Q.Progress:State(cur), "active")
    Mock.gossip.available = { { questID = 179, title = "Dwarven Outfitters" } }
    Mock.fire("GOSSIP_SHOW")
    t.eq(Q.Progress:State(cur), "active", "prerequisite 179 not done: not skipped")
    t.eq(Mock.countPrinted(string.format(Q.L.GUARD_HINT_PREREQ, "Coldridge Valley Mail Delivery", "Sten Stoutarm")), 1)
    t.eq(#Mock.errors, 0)
  end,
}
