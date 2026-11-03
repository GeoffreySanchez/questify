-- Tests du garde-fou des étapes impossibles (Q.StepGuard).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
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
}
