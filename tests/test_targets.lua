-- Tests des cibles de navigation et des monstres d'objectif (Q.Targets).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end   -- fixtures seules, pas les guides livrés
  return Mock.loadAddon(TOC, opts)
end

local function useGuide(Q, id, steps)
  Q:RegisterGuide({ id = id, faction = "Alliance", minLevel = 1, maxLevel = 60, steps = steps })
  Q.Progress:SetGuide(id)
  return Q.Progress:Entries()
end

local function findMob(rows, npcId)
  for _, r in ipairs(rows) do if r.npcId == npcId then return r end end
end

return {
  accept_targets_starter_npc = function(t)
    local Q = load()
    local tg = Q.Targets:ForEntry(Q.Progress:Entries()[1])
    t.eq(tg.kind, "npc"); t.eq(tg.id, 658); t.near(tg.x, 29.93, 0.001)
    t.eq(tg.mapId, 1426); t.near(tg.y, 71.2, 0.001)
    t.ok(type(tg.title) == "string" and tg.title:find("Dwarven Outfitters", 1, true), "title from Format")
  end,

  turnin_targets_finisher = function(t)
    local Q = load()
    local list = Q.Progress:Entries()
    local tg = Q.Targets:ForEntry(list[14])   -- turnin 233 -> Talin Keeneye
    t.eq(tg.kind, "npc"); t.eq(tg.id, 714); t.near(tg.x, 22.6, 0.001)
  end,

  complete_uses_item_drop_mobs = function(t)
    local Q = load()
    Mock.quests.log[179] = { complete = false, objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
    Mock.fire("QUEST_ACCEPTED", 179)
    local rows = Q.Targets:ObjectiveMobs()
    local wolf = findMob(rows, 705)
    t.ok(wolf, "Ragged Young Wolf listed")
    t.eq(wolf.viaItem, 750); t.eq(wolf.questId, 179); t.eq(wolf.objIndex, 1)
    t.eq(wolf.name, "Ragged Young Wolf"); t.eq(wolf.minLevel, 1); t.eq(wolf.maxLevel, 1)
    t.eq(wolf.done, false)
    t.ok(Q.Targets:ObjectiveNpcSet()[705])
    local tg = Q.Targets:ForEntry(Q.Progress:Current())
    t.eq(tg.kind, "npc"); t.eq(tg.id, 705, "complete targets the nearest wolf")
  end,

  complete_prefers_at = function(t)
    local Q = load()
    local tg = Q.Targets:ForEntry(Q.Progress:Entries()[7])   -- complete 170 at {1426, 26.1, 74.3}
    t.eq(tg.x, 26.1); t.eq(tg.y, 74.3); t.eq(tg.mapId, 1426); t.eq(tg.kind, "area")
  end,

  complete_with_obj_targets_that_objective = function(t)
    local Q = load()
    Mock.quests.log[3361] = { complete = false, objectives = {
      { text = "Felix's Box: 0/1", finished = false },
      { text = "Felix's Chest: 0/1", finished = false },
      { text = "Felix's Bucket of Bolts: 0/1", finished = false },
    } }
    local tg = Q.Targets:ForEntry(Q.Progress:Entries()[10])   -- complete 3361, obj = 2
    t.eq(tg.kind, "object"); t.eq(tg.id, 178084, "Felix's Chest object")
    t.near(tg.x, 22.78, 0.001)
  end,

  complete_skips_finished_objectives = function(t)
    local Q = load()
    Mock.quests.log[3361] = { complete = false, objectives = {
      { text = "Felix's Box: 1/1", finished = true },
      { text = "Felix's Chest: 1/1", finished = true },
      { text = "Felix's Bucket of Bolts: 0/1", finished = false },
    } }
    local tg = Q.Targets:ForEntry(Q.Progress:Entries()[11])   -- complete 3361 sans obj
    t.eq(tg.id, 178085, "only the unfinished objective remains")
  end,

  done_objective_excluded = function(t)
    local Q = load()
    Mock.quests.completed[179] = true
    Mock.quests.log[170] = { complete = false, objectives = {
      { text = "Rockjaw Trogg slain: 6/6", finished = true },
      { text = "Burly Rockjaw Trogg slain: 0/6", finished = false },
    } }
    Mock.fire("QUEST_ACCEPTED", 170)
    local set = Q.Targets:ObjectiveNpcSet()
    t.ok(not set[707], "finished objective creature excluded")
    t.ok(set[724], "unfinished objective creature included")
    local rows = Q.Targets:ObjectiveMobs()
    t.eq(findMob(rows, 707).done, true)
    t.eq(findMob(rows, 724).objIndex, 2)
  end,

  objective_mobs_deduplicated_and_ordered = function(t)
    local Q = load({ qdb = { quests = {
      [90020] = { name = "Wolves again", startedBy = { { 658 } }, finishedBy = { { 658 } },
        objectives = { { { 705 }, { 946 } } } },
    } } })
    Mock.quests.log[179] = { complete = false, objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
    Mock.quests.log[90020] = { complete = false, objectives = {
      { text = "Ragged Young Wolf slain: 0/5", finished = false },
      { text = "Frostmane Novice slain: 0/5", finished = false },
    } }
    useGuide(Q, "T_Mobs", { { "complete", 179 }, { "complete", 90020 } })
    local rows = Q.Targets:ObjectiveMobs()
    t.eq(#rows, 2, "wolf listed once")
    t.eq(rows[1].npcId, 705); t.eq(rows[1].questId, 179)
    t.eq(rows[2].npcId, 946)
  end,

  objective_mobs_only_in_log_and_next_15 = function(t)
    local Q = load()
    local steps = { { "complete", 179 } }
    for i = 1, 15 do steps[#steps + 1] = { "note", "n" .. i } end
    steps[#steps + 1] = { "complete", 170 }
    Mock.quests.log[170] = { complete = false, objectives = {
      { text = "Rockjaw Trogg slain: 0/6", finished = false },
      { text = "Burly Rockjaw Trogg slain: 0/6", finished = false },
    } }
    useGuide(Q, "T_Window", steps)
    -- 179 n'est pas dans le journal : son étape est sautée ; 170 est au-delà des 15 étapes suivantes
    t.eq(#Q.Targets:ObjectiveMobs(), 0)
  end,

  objective_mobs_cached_until_progress_update = function(t)
    local Q = load()
    Mock.quests.log[179] = { complete = false, objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
    Mock.fire("QUEST_ACCEPTED", 179)
    local calls = 0
    local real = Q.Progress.Entries
    Q.Progress.Entries = function(self) calls = calls + 1; return real(self) end
    for _ = 1, 5 do Q.Targets:ObjectiveNpcSet(); Q.Targets:ObjectiveMobs() end
    t.eq(calls, 1, "computed once for repeated calls (nameplates)")
    local rows = Q.Targets:ObjectiveMobs()
    table.remove(rows, 1)
    t.eq(#Q.Targets:ObjectiveMobs(), 1, "callers get a copy of the list")
    local set = Q.Targets:ObjectiveNpcSet()
    set[705] = nil
    t.ok(Q.Targets:ObjectiveNpcSet()[705], "callers get a copy of the set")
    -- l'objectif se termine : visible dès QUEST_LOG_UPDATE, sans attendre le recalcul différé
    Mock.quests.log[179].objectives[1].finished = true
    Mock.fire("QUEST_LOG_UPDATE")
    t.ok(not Q.Targets:ObjectiveNpcSet()[705], "invalidated by the quest log event")
    Q.Progress.Entries = real
  end,

  kill_credit_npcs = function(t)
    local Q = load({ qdb = { quests = {
      [90030] = { name = "Credit", startedBy = { { 658 } }, finishedBy = { { 658 } },
        objectives = { nil, nil, nil, nil, { { { 707, 724 }, 707, "Troggs routed" } } } },
    } } })
    Mock.quests.log[90030] = { complete = false, objectives = { { text = "Troggs routed: 0/1", finished = false } } }
    useGuide(Q, "T_Credit", { { "complete", 90030 } })
    local set = Q.Targets:ObjectiveNpcSet()
    t.ok(set[707] and set[724])
    t.eq(findMob(Q.Targets:ObjectiveMobs(), 724).objIndex, 1)
  end,

  point_steps_use_their_point = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Points", {
      { "goto", 1426, 22.6, 71.4 }, { "fp", 1455, 55.5, 47.7 }, { "sethearth", 1426, 47.4, 52.5 },
      { "boat", 1437, 4.6, 57.1 }, { "hearth", 1426 }, { "fly", 1432 }, { "level", 6 }, { "note", "x" },
      { "note", "with at", at = { 1426, 10, 20 } },
    })
    local g = Q.Targets:ForEntry(list[1])
    t.eq(g.kind, "point"); t.eq(g.mapId, 1426); t.eq(g.x, 22.6); t.eq(g.y, 71.4)
    t.eq(Q.Targets:ForEntry(list[2]).mapId, 1455)
    t.eq(Q.Targets:ForEntry(list[3]).x, 47.4)
    t.eq(Q.Targets:ForEntry(list[4]).mapId, 1437)
    t.eq(Q.Targets:ForEntry(list[5]), nil, "hearth has no point")
    t.eq(Q.Targets:ForEntry(list[6]), nil, "fly has no point")
    t.eq(Q.Targets:ForEntry(list[7]), nil)
    t.eq(Q.Targets:ForEntry(list[8]), nil)
    t.eq(Q.Targets:ForEntry(list[9]).x, 10)
  end,

  no_spawns_returns_nil = function(t)
    local Q = load({ qdb = { quests = { [90040] = { name = "Nobody", startedBy = { { 999998 } } } } } })
    local list = useGuide(Q, "T_None", { { "accept", 999999 }, { "complete", 999999 }, { "accept", 90040 } })
    t.eq(Q.Targets:ForEntry(list[1]), nil)
    t.eq(Q.Targets:ForEntry(list[2]), nil)
    t.eq(Q.Targets:ForEntry(list[3]), nil, "starter without spawns")
    t.eq(Q.Targets:ForEntry(nil), nil)
    list = useGuide(Q, "T_NoneAt", { { "accept", 90040, at = { 1426, 12, 34 } } })
    local tg = Q.Targets:ForEntry(list[1])
    t.eq(tg.kind, "area", "falls back to at"); t.eq(tg.x, 12)
    t.eq(#Mock.errors, 0)
  end,

  match_objective = function(t)
    local Q = load()
    Mock.quests.log[170] = { complete = false, objectives = {
      { text = "Burly Rockjaw Trogg slain: 0/6", finished = false },
      { text = "Rockjaw Trogg slain: 0/6", finished = false },
    } }
    t.eq(Q.Targets:MatchObjective(170, "Rockjaw Trogg"), 2, "prefers the line that starts with the name")
    t.eq(Q.Targets:MatchObjective(170, "burly rockjaw trogg"), 1, "case-insensitive")
    t.eq(Q.Targets:MatchObjective(170, "Wolf"), nil)
    t.eq(Q.Targets:MatchObjective(170, "Trogg (%d"), nil, "plain search, no pattern error")
    t.eq(Q.Targets:MatchObjective(179, "Wolf"), nil, "not in log")
  end,

  other_continent_target_still_returned = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Far", { { "accept", 1598 } })   -- Drusilla, Elwynn (même continent)
    Mock.player.map = 1411; Mock.player.x = 50; Mock.player.y = 50  -- Durotar, autre continent
    local tg = Q.Targets:ForEntry(list[1])
    t.eq(tg.mapId, 1429); t.eq(tg.id, 459)
  end,
}
