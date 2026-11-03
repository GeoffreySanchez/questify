-- Tests du bouton d'objet de quête (Q.UI.QuestItemButton).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

local counts, spells

local function load(qdb)
  Ext.install()
  counts, spells = {}, {}
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true, qdb = qdb })
  C_Item.GetItemCount = function(id) return counts[id] or 0 end
  C_Item.GetItemSpell = function(id) return spells[id] end
  GetQuestLogSpecialItemInfo = nil
  return Q
end

-- Quête de test 99100 : donne l'objet 7001 (fiole utilisable) ; objectif « rapporter » 7002.
local QDB = {
  quests = { [99100] = { name = "Use The Vial", startedBy = { { 658 } }, finishedBy = { { 658 } },
    requiredLevel = 1, questLevel = 1, sourceItemId = 7001, objectives = { nil, nil, { { 7002 } } } } },
  items = { [7001] = { name = "Vial" }, [7002] = { name = "Sample" } },
}

local function startQuest(Q)
  Q:RegisterGuide({ id = "T_item", faction = "Alliance", steps = { { "complete", 99100 } } })
  Mock.quests.log[99100] = { objectives = { { text = "Sample: 0/1", finished = false } } }
  Q.Progress:SetGuide("T_item")
  Mock.fire("QUEST_ACCEPTED", 99100)
end

return {
  button_for_usable_source_item = function(t)
    local Q = load(QDB)
    counts[7001], spells[7001] = 1, "Throw Vial"
    startQuest(Q)
    local B = Q.UI.QuestItemButton
    t.eq(B.itemId, 7001)
    t.ok(B.button:IsShown())
    t.eq(B.button._template, "SecureActionButtonTemplate")
    t.eq(B.button:GetAttribute("type"), "item")
    t.eq(B.button:GetAttribute("item"), "item:7001")
    local _, rel = B.button:GetPoint(1)
    t.ok(rel == UIParent, "never anchored to the tracker")
    t.eq(#Mock.errors, 0)
  end,

  nothing_without_usable_item = function(t)
    local Q = load(QDB)
    counts[7001] = 1                       -- dans les sacs mais sans effet « Utiliser »
    startQuest(Q)
    t.eq(Q.UI.QuestItemButton.itemId, nil)
    t.ok(not Q.UI.QuestItemButton.button:IsShown())
  end,

  quest_log_special_item_first = function(t)
    local Q = load(QDB)
    counts[7003] = 1
    GetQuestLogSpecialItemInfo = function() return "item:7003", 132000, 1 end
    startQuest(Q)
    t.eq(Q.UI.QuestItemButton.itemId, 7003)
  end,

  no_secure_change_in_combat = function(t)
    local Q = load(QDB)
    counts[7001], spells[7001] = 1, "Throw Vial"
    startQuest(Q)
    local B = Q.UI.QuestItemButton
    local calls = Ext.spyCombat({ B.button })
    Mock.player.combat = true
    counts[7001] = 0
    Mock.fire("BAG_UPDATE_DELAYED")
    t.eq(calls, {})
    t.eq(B.pending, true)
    t.ok(B.button:IsShown(), "still there until the fight ends")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(not B.button:IsShown())
  end,

  option_off = function(t)
    local Q = load(QDB)
    counts[7001], spells[7001] = 1, "Throw Vial"
    startQuest(Q)
    Q.Settings:Set("questItemButton", false)
    t.ok(not Q.UI.QuestItemButton.button:IsShown())
  end,
}
