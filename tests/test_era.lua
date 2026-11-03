-- Tests Classic Era : saveur Era du mock (tests/mock_era.lua) et TOC Questify_Vanilla_Vanilla.toc.
-- 1. Les suites existantes sont rejouées telles quelles sous Era (Mock.loadAddon redirigé vers la
--    TOC Era), sauf les tests qui vérifient une API propre à Forever (liste SKIP, avec la raison).
-- 2. Scénarios propres à Era (fin du fichier).
local Era = dofile(Mock.root .. "/tests/mock_era.lua")

local REPLAY = { "test_boot", "test_progress", "test_targets", "test_format", "test_guides", "test_autoquest",
  "test_rewards", "test_nav", "test_tracker", "test_mobpanel", "test_nameplates", "test_journal", "test_wizard",
  "test_slash", "test_classquests", "test_telemetry", "test_qdb", "test_util" }

-- Tests qui vérifient une API propre à Forever : leur équivalent Era est testé plus bas.
local NATIVE_PIN = "asserts C_Map.SetUserWaypoint (no map pin on Era: era.nav_* below)"
local SKIP = {
  ["test_boot.loads_and_fires_login"] = "asserts Q.IsForever() (era.boot_* below)",
  ["test_autoquest.greeting_uses_indexes"] = "greeting IDs (Era gives titles only: era.greeting_* below)",
  ["test_tracker.tracker_default_anchor_minimap_without_objective_tracker"] =
    "Era has QuestWatchFrame: the tracker sits left of it (era.tracker_shows_first_step)",
  ["test_wizard.wizard_disables_missing_providers"] = "asserts the game map pin is enabled (disabled on Era: era.wizard_* below)",
  ["test_wizard.wizard_shows_once_and_saves"] = "clicks the game map pin radio (disabled on Era: era.wizard_* below)",
  ["test_rewards.missing_item_stats_api_is_survived"] = "removes C_Item.GetItemStats only (Era has GetItemStats)",
  ["test_progress.player_context_ignores_secret_values"] = "secret values do not exist on Era",
  ["test_util.is_secret"] = "secret values do not exist on Era",
  ["test_util.is_secret_asks_client_first"] = "secret values do not exist on Era",
  ["test_nav.clear_clears_the_provider_in_use"] = NATIVE_PIN,
  ["test_nav.clears_when_there_is_no_current_step"] = NATIVE_PIN,
  ["test_nav.complete_target_is_recomputed_every_5s"] = NATIVE_PIN,
  ["test_nav.dedupe_same_target"] = NATIVE_PIN,
  ["test_nav.invalid_target_clears"] = NATIVE_PIN,
  ["test_nav.missing_provider_falls_back_native"] = NATIVE_PIN,
  ["test_nav.native_by_default"] = NATIVE_PIN,
  ["test_nav.native_skips_maps_without_waypoints"] = NATIVE_PIN,
  ["test_nav.routing_without_shortestpath_uses_display"] = NATIVE_PIN,
  ["test_nav.settings_change_enables_routing"] = NATIVE_PIN,
  ["test_nav.settings_change_switches_provider"] = NATIVE_PIN,
  ["test_nav.step_target_follows_the_current_step"] = NATIVE_PIN,
  ["test_nav.step_without_target_clears"] = NATIVE_PIN,
}

local tests = {}

for _, file in ipairs(REPLAY) do
  local chunk = assert(loadfile(Mock.root .. "/tests/" .. file .. ".lua"))
  local suite = chunk()
  for name, fn in pairs(suite) do
    local key = file .. "." .. name
    if not SKIP[key] then
      tests["replay." .. key] = function(t)
        Era.install()
        Era.withEraToc(fn, t)
      end
    end
  end
end

---------------------------------------------------------------------------
-- Scénarios propres à Era
---------------------------------------------------------------------------
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- Saveur Era + TOC Era. fixture = true : seules les fixtures (pas les guides Era générés).
local function load(opts, fixture)
  Era.install()
  Ext.install()
  opts = opts or {}
  if fixture then
    opts.extraFiles = opts.extraFiles or { GUIDES }
    opts.skipGuides = true
  end
  return Era.load(opts)
end

local function acceptWolves()
  Mock.quests.log[179] = { title = "Dwarven Outfitters", objectives = { { text = "Tough Wolf Meat: 3/8",
    finished = false, numFulfilled = 3, numRequired = 8 } } }
  Mock.fire("QUEST_ACCEPTED", 1, 179)   -- Era : QUEST_ACCEPTED(questLogIndex, questID)
end

local STR, STA, INT = "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_INTELLECT_SHORT"

tests["era.boot_loads_era_toc_and_route"] = function(t)
  local Q = load()
  t.eq(#Mock.errors, 0, "no Lua error")
  t.eq(Mock.missingFiles, {}, "every TOC file exists")
  t.ok(Q.IsClassicEra(), "Classic Era detected")
  t.ok(not Q.IsForever(), "not Forever")
  t.ok(Q.Guides:Get("ERA_A_DwarfGnome_01") and Q.Guides:Get("ERA_A_DwarfGnome_02"), "Era guides registered")
  t.eq(Q.Guides:Get("A_DwarfGnome_01"), nil, "no Forever guide on Era")
  t.eq(type(Q.ClassQuestData), "table", "Era class quest data loaded")
  t.eq(Q.Progress:Guide().id, "ERA_A_DwarfGnome_01", "Dwarf level 1 starts in Coldridge Valley")
  t.eq(Q.Guides:Get("ERA_A_DwarfGnome_01").next, "ERA_A_DwarfGnome_02")
  Mock.reset()
  Mock.player.level = 7
  Q = load()
  t.eq(Q.Progress:Guide().id, "ERA_A_DwarfGnome_02", "level 7 starts in Dun Morogh")
  t.eq(#Mock.errors, 0)
end

tests["era.forever_toc_does_not_load_era_files"] = function(t)
  local Q = Mock.loadAddon(Era.FOREVER_TOC)
  t.ok(not Q.IsClassicEra())
  t.eq(Q.Guides:Get("ERA_A_DwarfGnome_01"), nil, "Era guides are not in the Forever build")
  t.ok(Q.Guides:Get("A_DwarfGnome_01") ~= nil, "Forever guides still load")
  t.eq(#Mock.errors, 0)
end

tests["era.tracker_shows_first_step"] = function(t)
  local Q = load()
  local T = Q.UI.Tracker
  t.ok(T.frame:IsShown(), "tracker shown")
  t.ok(plain(T.currentText:GetText()):find("Dwarven Outfitters", 1, true), "first step: " .. plain(T.currentText:GetText()))
  t.eq(T.title:GetText(), "Coldridge Valley")
  t.eq(T.levels:GetText(), "1-6")
  local point, rel, relPoint = T.frame:GetPoint(1)
  t.ok(point == "TOPRIGHT" and rel == QuestWatchFrame and relPoint == "TOPLEFT", "left of Blizzard's QuestWatchFrame")
  t.eq(#Mock.errors, 0)
end

tests["era.progress_follows_the_quest_log"] = function(t)
  local Q = load(nil, true)
  t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:1")
  acceptWolves()
  t.ok(Q.Progress:InLog(179), "GetQuestLogIndexByID sees 179")
  t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:2")
  Mock.quests.log[179].complete = true
  Mock.quests.log[179].objectives[1].finished = true
  Mock.fire("QUEST_LOG_UPDATE")
  Mock.advance(0.3)
  t.ok(Q.Progress:IsComplete(179), "GetQuestLogTitle isComplete = 1")
  t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:3", "complete step done")
  Mock.quests.completed[179] = true
  Mock.quests.log[179] = nil
  Mock.fire("QUEST_TURNED_IN", 179, 100, 0)
  t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:4")
  t.eq(#Mock.errors, 0)
end

tests["era.quest_log_wrappers"] = function(t)
  local Q = load(nil, true)
  local A = Q.API
  Mock.quests.log[179] = { title = "Dwarven Outfitters", complete = true, objectives = { { text = "x", finished = true } } }
  Mock.quests.log[233] = { title = "Coldridge Valley Mail Delivery", objectives = {} }   -- « va parler à »
  Mock.quests.log[170] = { title = "A New Threat", failed = true, objectives = { { text = "y", finished = false } } }
  t.eq(A.QuestLogEntries, nil, "no unused log iterator")
  t.eq(A.QuestLogIndex(233), 3)
  t.eq(A.QuestLogIndex(424242), nil, "0 from GetQuestLogIndexByID becomes nil")
  t.ok(A.IsQuestComplete(179), "complete")
  t.ok(A.IsQuestComplete(233), "no objective: can be turned in")
  t.ok(not A.IsQuestComplete(170), "failed")
  t.ok(not A.IsQuestComplete(424242), "not in log")
  t.eq(A.QuestTitle(233), "Coldridge Valley Mail Delivery", "C_QuestLog.GetQuestInfo")
  t.eq(#Mock.errors, 0)
end

-- En-tête de zone replié : GetQuestLogIndexByID ne voit plus la quête, C_QuestLog.IsOnQuest si.
tests["era.collapsed_log_header_keeps_tracking"] = function(t)
  local Q = load(nil, true)
  local A = Q.API
  acceptWolves()
  GetQuestLogIndexByID = function() return 0 end   -- toutes les lignes sous un en-tête replié
  t.ok(A.IsOnQuest(179), "IsOnQuest does not depend on collapsed headers")
  t.ok(not A.IsQuestComplete(179), "objectives not finished")
  Mock.quests.log[179].objectives[1].finished = true
  t.ok(A.IsQuestComplete(179), "complete from objectives when the row is hidden")
  Mock.fire("QUEST_LOG_UPDATE")
  Mock.advance(0.3)
  t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:3", "the complete step still ticks")
  t.eq(#Mock.errors, 0)
end

tests["era.auto_accept_and_turn_in"] = function(t)
  local Q = load(nil, true)
  Mock.questFrame.questId = 179
  Mock.fire("QUEST_DETAIL")
  t.eq(Mock.countCalls("AcceptQuest"), 1, "route quest accepted")
  Mock.questFrame.completable = true
  Mock.fire("QUEST_PROGRESS")
  t.eq(Mock.countCalls("CompleteQuest"), 1)
  Mock.gossip.available = { { questID = 233, title = "Coldridge Valley Mail Delivery", questLevel = 3 } }
  Mock.fire("GOSSIP_SHOW")
  t.eq(Mock.lastCall("C_GossipInfo.SelectAvailableQuest").args[1], 233, "gossip uses questID on Era too")
  t.eq(#Mock.errors, 0)
end

local function greetingNpc(npcId)
  Mock.units.npc = { guid = ("Creature-0-1-0-1-%d-00004A1B2C"):format(npcId), name = "NPC", level = 5 }
end

tests["era.greeting_matches_titles"] = function(t)
  local Q = load(nil, true)
  -- 179 dans le journal et terminée ; Sten Stoutarm (658) la reçoit et donne 233
  greetingNpc(658)
  Mock.quests.log[179] = { title = "Dwarven Outfitters", complete = true, objectives = { { text = "x", finished = true } } }
  Mock.greeting.active = { { title = "Some Other Quest", isComplete = true },
    { title = "Dwarven Outfitters", isComplete = true } }
  Mock.greeting.available = { { title = "Coldridge Valley Mail Delivery" } }
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectActiveQuest"), 1)
  t.eq(Mock.lastCall("SelectActiveQuest").args[1], 2, "matched by title, selected by index")
  t.eq(Mock.countCalls("SelectAvailableQuest"), 0)
  -- rendue : il ne reste que la quête disponible
  Mock.quests.log[179] = nil
  Mock.quests.completed[179] = true
  Mock.greeting.active = {}
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectAvailableQuest"), 1)
  t.eq(Mock.lastCall("SelectAvailableQuest").args[1], 1)
  -- titre inconnu de la route : rien
  Mock.greeting.available = { { title = "Not On The Route" } }
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectAvailableQuest"), 1, "unknown title ignored")
  -- état « terminée » absent (nil) : le journal fait foi (Balir Frosthammer, 713, reçoit 170)
  greetingNpc(713)
  Mock.quests.log[170] = { title = "A New Threat", objectives = { { text = "y", finished = false } } }
  Mock.greeting.active = { { title = "A New Threat" } }
  Mock.greeting.available = {}
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectActiveQuest"), 1, "unfinished quest not selected")
  -- GUID inconnu : pas de correspondance par titre
  Mock.units.npc = nil
  Mock.quests.log[170].objectives[1].finished = true
  Mock.quests.log[170].complete = true
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectActiveQuest"), 1, "no NPC, no title match")
  t.eq(#Mock.errors, 0)
end

-- Titres en double sur la vraie route Era (233 / 234 « Coldridge Valley Mail Delivery ») : données
-- réelles de QuestieDB (vue Era), sauf 234 aussi donnée par Sten (658) pour forcer un doublon chez lui.
local MAIL = "Coldridge Valley Mail Delivery"
local ERA_QDB = { quests = {
  [233] = { name = MAIL, startedBy = { { 658 } }, finishedBy = { { 714 } }, preQuestSingle = { 179 },
    requiredLevel = 1, questLevel = 3, requiredRaces = 77 },
  [234] = { name = MAIL, startedBy = { { 714, 658 } }, finishedBy = { { 786 } }, preQuestSingle = { 233 },
    requiredLevel = 1, questLevel = 4, requiredRaces = 77 },
  [183] = { name = "The Boar Hunter", startedBy = { { 714 } }, finishedBy = { { 714 } },
    requiredLevel = 1, questLevel = 3, requiredRaces = 77 },
} }

tests["era.greeting_same_title_real_route"] = function(t)
  Mock.player.level = 4
  local Q = load({ qdb = ERA_QDB })
  t.eq(Q.Progress:Guide().id, "ERA_A_DwarfGnome_01")
  t.ok(Q.AutoQuest:IsRouteQuest(233) and Q.AutoQuest:IsRouteQuest(234), "both mail quests are on the Era route")
  Mock.quests.completed[179] = true
  -- Sten : 233 (prérequis 179 rendu) et 234 (prérequis 233 non rendu) ont le même titre
  greetingNpc(658)
  t.eq(Q.AutoQuest:MatchGreetingTitle(MAIL, false), 233, "prerequisites decide between 233 and 234")
  Mock.greeting.available = { { title = MAIL } }
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectAvailableQuest"), 1)
  -- Talin (714) : 233 dans le journal (sans objectif, donc terminée) ; 234 pas encore proposée
  Mock.quests.log[233] = { title = MAIL, objectives = {} }
  greetingNpc(714)
  t.eq(Q.AutoQuest:MatchGreetingTitle(MAIL, true), 233, "in the log, handed in to Talin")
  t.eq(Q.AutoQuest:MatchGreetingTitle(MAIL, false), nil, "234 needs 233 turned in")
  Mock.greeting.active = { { title = MAIL } }
  Mock.greeting.available = { { title = "The Boar Hunter" } }
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectActiveQuest"), 1, "233 handed in to Talin")
  t.eq(Mock.lastCall("SelectActiveQuest").args[1], 1)
  -- 233 rendue, 183 déjà rendue : Talin propose 234 (même titre) et une Boar Hunter hors route
  Mock.quests.log[233] = nil
  Mock.quests.completed[233] = true
  Mock.quests.completed[183] = true
  Mock.greeting.active = {}
  Mock.greeting.available = { { title = "The Boar Hunter" }, { title = MAIL } }
  t.eq(Q.AutoQuest:MatchGreetingTitle(MAIL, false), 234)
  t.eq(Q.AutoQuest:MatchGreetingTitle("The Boar Hunter", false), nil, "turned-in route quest: the offered one is another")
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectAvailableQuest"), 2)
  t.eq(Mock.lastCall("SelectAvailableQuest").args[1], 2, "234, not the turned-in Boar Hunter title")
  -- Grelin (786) ne donne pas 234 : une quête de même titre chez lui n'est pas la nôtre
  greetingNpc(786)
  t.eq(Q.AutoQuest:MatchGreetingTitle(MAIL, false), nil, "Grelin does not give 234")
  Mock.greeting.available = { { title = MAIL } }
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectAvailableQuest"), 2, "same title at another NPC: not selected")
  t.eq(#Mock.errors, 0)
end

-- Deux quêtes de la route, même titre, même PNJ, prérequis remplis : l'étape la plus proche gagne.
tests["era.greeting_same_title_nearest_step"] = function(t)
  local qdb = { quests = {
    [880501] = { name = "Twin Errand", startedBy = { { 658 } }, finishedBy = { { 658 } }, requiredLevel = 1, questLevel = 1 },
    [880502] = { name = "Twin Errand", startedBy = { { 658 } }, finishedBy = { { 658 } }, requiredLevel = 1, questLevel = 1 },
  } }
  local Q = load({ qdb = qdb, savedVariables = { QuestifyVanillaCharDB = { guideId = "T_Twins" } },
    beforeLogin = function(Q)
      Q:RegisterGuide({ id = "T_Twins", faction = "Alliance", races = { "Dwarf" }, minLevel = 1, maxLevel = 10,
        steps = { { "accept", 880502 }, { "accept", 880501 } } })
    end }, true)
  t.eq(Q.Progress:Guide().id, "T_Twins")
  greetingNpc(658)
  t.eq(Q.AutoQuest:MatchGreetingTitle("Twin Errand", false), 880502, "current step wins")
  Mock.greeting.available = { { title = "Twin Errand" } }
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectAvailableQuest"), 1)
  Mock.quests.log[880502] = { title = "Twin Errand", objectives = {} }
  Mock.fire("QUEST_ACCEPTED", 1, 880502)
  t.eq(Q.AutoQuest:MatchGreetingTitle("Twin Errand", false), 880501, "next pending step")
  t.eq(Q.AutoQuest:MatchGreetingTitle("Twin Errand", true), 880502, "the one in the log")
  Mock.fire("QUEST_GREETING")
  t.eq(Mock.countCalls("SelectAvailableQuest"), 2, "then 880501 (880502 is in the log)")
  t.eq(#Mock.errors, 0)
end

tests["era.reward_pick_uses_global_item_stats"] = function(t)
  local Q = load(nil, true)
  t.eq(C_Item.GetItemStats, nil, "Era mock: no C_Item.GetItemStats")
  Mock.items[9001] = { name = "Linen Cowl", link = "item:9001", equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 1,
    minLevel = 1, sellPrice = 30, stats = { [INT] = 4 } }
  Mock.items[9002] = { name = "Ringmail Coif", link = "item:9002", equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 3,
    minLevel = 1, sellPrice = 60, stats = { [STR] = 5, [STA] = 2 } }
  Mock.questFrame = { questId = 179, completable = true, choices = { { link = "item:9001" }, { link = "item:9002" } } }
  Mock.fire("QUEST_COMPLETE")
  t.eq(Mock.countCalls("GetQuestReward"), 1)
  t.eq(Mock.lastCall("GetQuestReward").args[1], 2, "warrior takes the mail coif (stats from GetItemStats)")
  t.ok(Mock.printed("upgrade"), "reason printed")
  t.eq(#Mock.errors, 0)
end

tests["era.item_info_falls_back_to_globals"] = function(t)
  local Q = load(nil, true)
  Mock.items[9002] = { name = "Ringmail Coif", link = "item:9002", equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 3,
    minLevel = 1, sellPrice = 60, stats = { [STR] = 5 } }
  local modern = C_Item.GetItemInfo
  C_Item.GetItemInfo = nil   -- 1.15 plus ancien : seule la globale existe
  GetItemInfo = modern
  t.eq((Q.API.GetItemInfo("item:9002")), "Ringmail Coif")
  t.eq(Q.API.GetItemStats("item:9002"), { [STR] = 5 })
  local choices = Q.Rewards:CollectChoices()
  t.eq(#choices, 0, "no reward window open")
  t.eq(#Mock.errors, 0)
end

tests["era.nav_without_map_pin_degrades_cleanly"] = function(t)
  local Q = load(nil, true)
  t.ok(not Q.API.HasNativeWaypoint(), "no map pin API on Era")
  t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 0)
  t.eq(Mock.countPrinted("TomTom"), 1, "one hint to install TomTom")
  acceptWolves()
  Mock.advance(6)
  Q.Nav:SetTarget(1426, 30, 70, "Elsewhere")
  t.eq(Mock.countPrinted("TomTom"), 1, "hint only once")
  Q.Nav:Clear()
  t.eq(#Mock.errors, 0, "no Lua error")
end

tests["era.nav_uses_tomtom"] = function(t)
  Mock.addons.TomTom = true
  local Q = load({ savedVariables = { QuestifyVanillaDB = { settings = { nav = { display = "tomtom" } } } } }, true)
  t.ok(Mock.countCalls("TomTom:AddWaypoint") >= 1, "TomTom waypoint set")
  local args = Mock.lastCall("TomTom:AddWaypoint").args
  t.eq(args[1], 1426)
  t.ok(args[2] > 0 and args[2] < 1 and args[3] > 0 and args[3] < 1, "TomTom gets 0-1 coordinates")
  t.eq(Mock.countPrinted("TomTom"), 0, "no hint when TomTom is used")
  t.eq(#Mock.errors, 0)
end

tests["era.mob_panel_macro_and_nameplate_from_guid"] = function(t)
  local Q = load(nil, true)
  acceptWolves()
  local row = Q.UI.MobPanel.rows[1]
  t.ok(row and row:IsShown(), "mob row shown")
  t.eq(row:GetAttribute("type"), "macro")
  t.eq(row:GetAttribute("macrotext"), "/cleartarget\n/targetexact Ragged Young Wolf\n/tm !8")
  -- UnitCreatureID absent : l'ID vient du GUID
  t.eq(UnitCreatureID, nil)
  Mock.units.nameplate1 = { guid = "Creature-0-1-0-1-705-00004A1B2C", name = "Ragged Young Wolf", level = 1, hostile = true }
  local plate = CreateFrame("Frame", nil, WorldFrame)
  Mock.nameplates.nameplate1 = plate
  Mock.fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
  local icon = Q.UI.Nameplates.icons.nameplate1
  t.ok(icon and icon:IsShown(), "quest icon over the wolf nameplate")
  t.eq(#Mock.errors, 0)
end

tests["era.wizard_disables_game_pin_and_prefers_tomtom"] = function(t)
  Mock.addons.TomTom = true
  local Q = load({ savedVariables = { QuestifyVanillaCharDB = { wizardDone = true } } }, true)
  local W = Q.UI.Wizard
  W:Show()
  t.ok(not W.radios.native:IsEnabled(), "no game map pin on Era")
  t.ok(W.radios.tomtom:IsEnabled())
  t.eq(W.choice.display, "tomtom", "saved native setting becomes TomTom on Era")
  t.ok(W.radios.tomtom:GetChecked())
  t.eq(#Mock.errors, 0)
end

tests["era.forever_without_pin_api_prints_no_era_hint"] = function(t)
  local Q = Mock.loadAddon(Era.FOREVER_TOC, { skipGuides = true, extraFiles = { GUIDES },
    beforeLogin = function() C_Map.SetUserWaypoint = nil end })
  t.ok(not Q.IsClassicEra())
  t.eq(Mock.countPrinted(Q.L.NAV_NO_NATIVE_ERA), 0, "the Era hint is for Era only")
  t.eq(#Mock.errors, 0)
end

tests["era.journal_options_wizard_and_slash"] = function(t)
  local Q = load()
  SlashCmdList.QUESTIFYVANILLA("")
  t.ok(QuestifyVanillaJournal and QuestifyVanillaJournal:IsShown(), "/qf opens the journal")
  Q.UI.Journal:ShowTab("route")
  Q.UI.Journal:ShowTab("options")
  Q.UI.Journal:ShowTab("class")
  Q.UI.Wizard:Show()
  t.ok(QuestifyVanillaWizard and QuestifyVanillaWizard:IsShown(), "wizard opens")
  t.eq(#Mock.errors, 0, "no Lua error")
end

return tests
