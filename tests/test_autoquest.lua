-- Tests de l'automatisation des quêtes (Q.AutoQuest) : accepter, rendre, récompense.
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load(opts, setup)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if setup then opts.beforeLogin = setup end
  return Mock.loadAddon(TOC, opts)
end

-- Chapitres de test réservés à une race, plus un chapitre ouvert à tous.
local function raceGuides(Q)
  Q:RegisterGuide({ id = "T_NightElf", faction = "Alliance", races = { "NightElf" }, minLevel = 1, maxLevel = 10,
    steps = { { "accept", 456 }, { "turnin", 880301 } } })
  Q:RegisterGuide({ id = "T_Dwarf", faction = "Alliance", races = { "Dwarf", "Gnome" }, minLevel = 1, maxLevel = 10,
    steps = { { "accept", 880302 } } })
  Q:RegisterGuide({ id = "T_Everyone", faction = "Alliance", minLevel = 1, maxLevel = 10,
    steps = { { "accept", 880303 } } })
end

local function noAutoErrors(t)
  for _, e in ipairs(Mock.errors) do
    local s = tostring(e)
    t.ok(not (s:find("AutoQuest.lua", 1, true) or s:find("Rewards.lua", 1, true)), "automation error: " .. s)
  end
end

-- Appels déclenchés par l'automatisation (le reste, comme le marqueur de navigation, ne compte pas).
local AUTO = { "AcceptQuest", "CompleteQuest", "GetQuestReward", "C_GossipInfo.SelectAvailableQuest",
  "C_GossipInfo.SelectActiveQuest", "SelectActiveQuest", "SelectAvailableQuest" }
local function autoCalls()
  local n = 0
  for _, name in ipairs(AUTO) do n = n + Mock.countCalls(name) end
  return n
end

local STR, STA, INT = "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_INTELLECT_SHORT"
local ARMOR = "RESISTANCE0_NAME"

local function threeChoices()
  Mock.items[9001] = { name = "Linen Cowl", link = "item:9001", equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 1,
    minLevel = 1, sellPrice = 30, stats = { [INT] = 4 } }
  Mock.items[9002] = { name = "Ringmail Coif", link = "item:9002", equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 3,
    minLevel = 1, sellPrice = 60, stats = { [STR] = 5, [STA] = 2, [ARMOR] = 40 } }
  Mock.items[9003] = { name = "Gold Ring", link = "item:9003", equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0,
    minLevel = 1, sellPrice = 200, stats = { [STA] = 1 } }
  Mock.questFrame = { questId = 179, completable = true, choices = { { link = "item:9001" }, { link = "item:9002" },
    { link = "item:9003" } } }
end

return {
  accepts_route_quest = function(t)
    local Q = load()
    Mock.questFrame.questId = 179
    Mock.fire("QUEST_DETAIL")
    t.eq(Mock.countCalls("AcceptQuest"), 1)
    t.eq(Q.AutoQuest:IsRouteQuest(179), true)
    noAutoErrors(t)
  end,

  ignores_non_route_quest = function(t)
    local Q = load()
    Mock.questFrame.questId = 424242
    Mock.fire("QUEST_DETAIL")
    t.eq(Mock.countCalls("AcceptQuest"), 0)
    t.eq(Q.AutoQuest:IsRouteQuest(424242), false)
    t.eq(Q.AutoQuest:IsRouteQuest(nil), false)
    t.eq(Q.AutoQuest:IsRouteQuest("x"), false)
  end,

  respects_shift_and_settings = function(t)
    local Q = load()
    Mock.questFrame.questId = 179
    Mock.player.shift = true
    Mock.fire("QUEST_DETAIL")
    Mock.fire("QUEST_PROGRESS")
    Mock.gossip.active = { { questID = 179, isComplete = true } }
    Mock.fire("GOSSIP_SHOW")
    t.eq(autoCalls(), 0, "shift suspends everything")
    Mock.player.shift = false

    Q.Settings:Set("autoQuest", false)
    Mock.questFrame.completable = true
    Mock.fire("QUEST_DETAIL")
    Mock.fire("QUEST_PROGRESS")
    Mock.fire("GOSSIP_SHOW")
    Mock.fire("QUEST_COMPLETE")
    t.eq(autoCalls(), 0, "autoQuest off")
    Q.Settings:Set("autoQuest", true)

    -- autoReward désactivé : plusieurs choix, on laisse le joueur choisir
    threeChoices()
    Q.Settings:Set("autoReward", false)
    Mock.fire("QUEST_COMPLETE")
    t.eq(Mock.countCalls("GetQuestReward"), 0)
    Q.Settings:Set("autoReward", true)
    Mock.fire("QUEST_COMPLETE")
    t.eq(Mock.countCalls("GetQuestReward"), 1)
  end,

  gossip_turnin_before_accept = function(t)
    local Q = load()
    Mock.gossip.active = { { questID = 424242, isComplete = true }, { questID = 179, isComplete = true } }
    Mock.gossip.available = { { questID = 233 } }
    Mock.fire("GOSSIP_SHOW")
    t.eq(Mock.countCalls("C_GossipInfo.SelectActiveQuest"), 1, "one selection per event")
    t.eq(Mock.lastCall("C_GossipInfo.SelectActiveQuest").args[1], 179)
    t.eq(Mock.countCalls("C_GossipInfo.SelectAvailableQuest"), 0, "turn-in first")
    -- plus rien à rendre : on prend la quête de la route
    Mock.gossip.active = { { questID = 179, isComplete = false } }   -- pas terminée : ignorée
    Mock.fire("GOSSIP_SHOW")
    t.eq(Mock.countCalls("C_GossipInfo.SelectActiveQuest"), 1)
    t.eq(Mock.countCalls("C_GossipInfo.SelectAvailableQuest"), 1)
    t.eq(Mock.lastCall("C_GossipInfo.SelectAvailableQuest").args[1], 233)
    -- quêtes hors route : aucune sélection
    Mock.gossip.available = { { questID = 424242 } }
    Mock.gossip.active = {}
    Mock.fire("GOSSIP_SHOW")
    t.eq(Mock.countCalls("C_GossipInfo.SelectAvailableQuest"), 1)
    noAutoErrors(t)
  end,

  greeting_uses_indexes = function(t)
    local Q = load()
    Mock.greeting.active = { { questID = 424242, isComplete = true, title = "Other" },
      { questID = 179, isComplete = true, title = "Dwarven Outfitters" } }
    Mock.greeting.available = { { questID = 233, title = "Mail" } }
    Mock.fire("QUEST_GREETING")
    t.eq(Mock.countCalls("SelectActiveQuest"), 1)
    t.eq(Mock.lastCall("SelectActiveQuest").args[1], 2, "index, not quest id")
    t.eq(Mock.countCalls("SelectAvailableQuest"), 0)
    Mock.greeting.active = { { questID = 179, isComplete = false, title = "Dwarven Outfitters" } }
    Mock.fire("QUEST_GREETING")
    t.eq(Mock.countCalls("SelectActiveQuest"), 1, "an unfinished quest is not selected")
    t.eq(Mock.countCalls("SelectAvailableQuest"), 1)
    t.eq(Mock.lastCall("SelectAvailableQuest").args[1], 1)
    noAutoErrors(t)
  end,

  greeting_survives_missing_api = function(t)
    local Q = load()
    GetNumActiveQuests, GetActiveQuestID, GetNumAvailableQuests, GetAvailableQuestInfo = nil, nil, nil, nil
    Mock.fire("QUEST_GREETING")
    t.eq(autoCalls(), 0)
    noAutoErrors(t)
  end,

  quest_progress_completes_route_quests = function(t)
    local Q = load()
    Mock.questFrame.questId = 179
    Mock.questFrame.completable = false
    Mock.fire("QUEST_PROGRESS")
    t.eq(Mock.countCalls("CompleteQuest"), 0, "not completable yet")
    Mock.questFrame.completable = true
    Mock.fire("QUEST_PROGRESS")
    t.eq(Mock.countCalls("CompleteQuest"), 1)
    Mock.questFrame.questId = 424242
    Mock.fire("QUEST_PROGRESS")
    t.eq(Mock.countCalls("CompleteQuest"), 1, "not a route quest")
  end,

  quest_complete_single_choice = function(t)
    local Q = load()
    Mock.questFrame = { questId = 179, choices = { { link = "item:1" } } }
    Mock.fire("QUEST_COMPLETE")
    t.eq(Mock.countCalls("GetQuestReward"), 1)
    t.eq(Mock.lastCall("GetQuestReward").args[1], 1)
  end,

  quest_complete_no_choice = function(t)
    local Q = load()
    Mock.questFrame = { questId = 179, choices = {} }
    Mock.fire("QUEST_COMPLETE")
    t.eq(Mock.lastCall("GetQuestReward").args[1], 0)
  end,

  quest_complete_ignores_non_route_quest = function(t)
    local Q = load()
    Mock.questFrame = { questId = 424242, choices = {} }
    Mock.fire("QUEST_COMPLETE")
    t.eq(Mock.countCalls("GetQuestReward"), 0)
  end,

  quest_complete_picks_the_best_choice_and_says_why = function(t)
    local Q = load()
    threeChoices()
    Mock.fire("QUEST_COMPLETE")
    local call = Mock.lastCall("GetQuestReward")
    t.eq(call.args[1], 2, "the mail coif is the upgrade for a warrior")
    t.ok(Mock.printed("Ringmail Coif") or Mock.printed("item:9002"), "the reason is printed")
    t.ok(Mock.printed("upgrade"), "reason text")
    noAutoErrors(t)
  end,

  quest_complete_vendor_reason_is_printed = function(t)
    local Q = load()
    threeChoices()
    Mock.player.classFile = "MAGE"
    Mock.fire("PLAYER_LEVEL_UP", 1)   -- rafraîchit Q.Player
    Mock.items[9001].stats = {}       -- plus d'amélioration : même la coiffe de lin ne vaut rien
    Mock.items[9002].subclassID = 4   -- plaque : inutilisable
    Mock.items[9003].stats = {}
    Mock.fire("QUEST_COMPLETE")
    t.eq(Mock.lastCall("GetQuestReward").args[1], 3, "highest vendor price")
    t.ok(Mock.printed("vendor"), "vendor reason")
  end,

  quest_complete_waits_for_uncached_items = function(t)
    local Q = load()
    threeChoices()
    local saved = {}
    for id = 9001, 9003 do saved[id] = Mock.items[id]; Mock.items[id] = nil end
    Mock.fire("QUEST_COMPLETE")
    t.eq(Mock.countCalls("GetQuestReward"), 0, "item data not loaded yet")
    for id, def in pairs(saved) do Mock.items[id] = def end
    Mock.advance(1)
    t.eq(Mock.countCalls("GetQuestReward"), 1, "second look once the cache is warm")
    t.eq(Mock.lastCall("GetQuestReward").args[1], 2)
  end,

  quest_complete_retry_is_cancelled_when_the_frame_closes = function(t)
    local Q = load()
    threeChoices()
    for id = 9001, 9003 do Mock.items[id] = nil end
    Mock.fire("QUEST_COMPLETE")
    Mock.fire("QUEST_FINISHED")
    Mock.advance(1)
    t.eq(Mock.countCalls("GetQuestReward"), 0)
  end,

  route_set_follows_the_guide_and_faction = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "H_Test", faction = "Horde", minLevel = 1, maxLevel = 10, steps = { { "accept", 880001 } } })
    Q:RegisterGuide({ id = "A_Test", faction = "Alliance", minLevel = 1, maxLevel = 10,
      steps = { { "accept", 880002 }, { "complete", 880003 }, { "turnin", 880004 } } })
    Q.Progress:SetGuide("A_Test")   -- GUIDE_CHANGED reconstruit l'ensemble
    t.eq(Q.AutoQuest:IsRouteQuest(880001), false, "Horde guide")
    t.eq(Q.AutoQuest:IsRouteQuest(880002), true, "accept")
    t.eq(Q.AutoQuest:IsRouteQuest(880003), false, "complete steps do not count")
    t.eq(Q.AutoQuest:IsRouteQuest(880004), true, "turnin")
  end,

  route_set_honours_step_filters = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "A_Filters", faction = "Alliance", minLevel = 1, maxLevel = 10, steps = {
      { "accept", 880101, class = { "WARLOCK" } },
      { "accept", 880102, race = { "Human" } },
      { "accept", 880103, race = { "Dwarf" } },
      { "accept", 880104, optional = true, dungeon = "Deadmines" },
    } })
    Q.Progress:SetGuide("A_Filters")
    t.eq(Q.AutoQuest:IsRouteQuest(880101), false, "class filter")
    t.eq(Q.AutoQuest:IsRouteQuest(880102), false, "race filter")
    t.eq(Q.AutoQuest:IsRouteQuest(880103), true)
    t.eq(Q.AutoQuest:IsRouteQuest(880104), true)
    Q.Settings:Set("dungeonQuests", false)
    t.eq(Q.AutoQuest:IsRouteQuest(880104), false, "dungeon quests turned off")
  end,

  route_set_includes_inserted_steps = function(t)
    local Q = load()
    t.eq(Q.AutoQuest:IsRouteQuest(880201), false)
    Q.Progress:InsertSteps("cq:TEST_880201", { { "accept", 880201 }, { "complete", 880201 }, { "turnin", 880201 } })
    Q:Fire("CLASSQUESTS_CHANGED")
    t.eq(Q.AutoQuest:IsRouteQuest(880201), true)
    Q.Progress:RemoveInserted("cq:TEST_880201")
    Q:Fire("CLASSQUESTS_CHANGED")
    t.eq(Q.AutoQuest:IsRouteQuest(880201), false)
    -- un accept automatique d'une quête de classe ajoutée
    Q.Progress:InsertSteps("cq:TEST_880201", { { "accept", 880201 } })
    Q:Fire("CLASSQUESTS_CHANGED")
    Mock.questFrame.questId = 880201
    Mock.fire("QUEST_DETAIL")
    t.eq(Mock.countCalls("AcceptQuest"), 1)
  end,

  route_set_skips_chapters_of_other_races = function(t)
    local Q = load(nil, raceGuides)   -- joueur : Nain
    t.eq(Q.Player.raceKey, "Dwarf")
    t.eq(Q.AutoQuest:IsRouteQuest(456), false, "Night Elf only")
    t.eq(Q.AutoQuest:IsRouteQuest(880301), false, "Night Elf only")
    t.eq(Q.AutoQuest:IsRouteQuest(880302), true, "Dwarf chapter")
    t.eq(Q.AutoQuest:IsRouteQuest(880303), true, "chapter open to every race")
    Mock.questFrame.questId = 456
    Mock.fire("QUEST_DETAIL")
    t.eq(Mock.countCalls("AcceptQuest"), 0, "never auto-accepts another race's quest")
    Mock.questFrame.questId = 880302
    Mock.fire("QUEST_DETAIL")
    t.eq(Mock.countCalls("AcceptQuest"), 1)

    Mock.reset()
    Mock.player.raceId = 4   -- Elfe de la nuit
    local Q2 = load(nil, raceGuides)
    t.eq(Q2.Player.raceKey, "NightElf")
    t.eq(Q2.AutoQuest:IsRouteQuest(456), true)
    t.eq(Q2.AutoQuest:IsRouteQuest(880301), true)
    t.eq(Q2.AutoQuest:IsRouteQuest(880302), false)
    t.eq(Q2.AutoQuest:IsRouteQuest(880303), true)
  end,

  reward_is_left_to_the_player_when_items_never_load = function(t)
    local Q = load()
    threeChoices()
    for id = 9001, 9003 do Mock.items[id] = nil end
    Mock.fire("QUEST_COMPLETE")
    Mock.advance(1)
    t.eq(Mock.countCalls("GetQuestReward"), 0, "no blind pick")
    t.ok(Mock.printed("not loaded"), "the player is told")
    -- une relecture ne recommence pas toute seule
    Mock.advance(5)
    t.eq(Mock.countCalls("GetQuestReward"), 0)
    noAutoErrors(t)
  end,

  reward_is_not_picked_when_a_single_item_is_missing = function(t)
    local Q = load()
    threeChoices()
    Mock.items[9003] = nil   -- un seul objet absent du cache : pas de choix partiel
    Mock.fire("QUEST_COMPLETE")
    Mock.advance(1)
    t.eq(Mock.countCalls("GetQuestReward"), 0)
  end,

  reward_retry_respects_autoreward_turned_off = function(t)
    local Q = load()
    threeChoices()
    local saved = {}
    for id = 9001, 9003 do saved[id] = Mock.items[id]; Mock.items[id] = nil end
    Mock.fire("QUEST_COMPLETE")
    Q.Settings:Set("autoReward", false)
    for id, def in pairs(saved) do Mock.items[id] = def end
    Mock.advance(1)
    t.eq(Mock.countCalls("GetQuestReward"), 0, "autoReward was turned off during the wait")
  end,

  reward_retry_respects_route_changes = function(t)
    local Q = load(nil, function(q)
      q:RegisterGuide({ id = "T_Dungeon", faction = "Alliance", minLevel = 1, maxLevel = 10,
        steps = { { "accept", 880401, optional = true, dungeon = "Deadmines" } } })
    end)
    threeChoices()
    Mock.questFrame.questId = 880401
    t.eq(Q.AutoQuest:IsRouteQuest(880401), true)
    local saved = {}
    for id = 9001, 9003 do saved[id] = Mock.items[id]; Mock.items[id] = nil end
    Mock.fire("QUEST_COMPLETE")
    Q.Settings:Set("dungeonQuests", false)   -- la quête ne fait plus partie de la route
    for id, def in pairs(saved) do Mock.items[id] = def end
    Mock.advance(1)
    t.eq(Q.AutoQuest:IsRouteQuest(880401), false)
    t.eq(Mock.countCalls("GetQuestReward"), 0, "no longer a route quest")
  end,

  reward_retry_stops_when_the_shift_key_is_held = function(t)
    local Q = load()
    threeChoices()
    local saved = {}
    for id = 9001, 9003 do saved[id] = Mock.items[id]; Mock.items[id] = nil end
    Mock.fire("QUEST_COMPLETE")
    Mock.player.shift = true
    for id, def in pairs(saved) do Mock.items[id] = def end
    Mock.advance(1)
    t.eq(Mock.countCalls("GetQuestReward"), 0)
  end,

  inactive_without_questiedb = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    Mock.questFrame.questId = 179
    Mock.fire("QUEST_DETAIL")
    t.eq(Mock.countCalls("AcceptQuest"), 0, "the engine is off without QuestieDB")
    noAutoErrors(t)
  end,
}
