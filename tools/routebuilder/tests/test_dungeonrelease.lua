-- Quêtes de donjon prises au passage : abandon quand elles deviennent basses (lot H, chapitres 30-60).
-- Même règle dans sim.releaseDungeonQuests (simulation) et paths.replay (validateur) ; données fictives.
local sim = require("sim")
local paths = require("paths")
local H = require("helpers")

local function D()
  local function q(id, level, zone)
    return { id = id, name = "Q" .. id, level = level, reqLevel = 1, races = 0, zoneOrSort = zone,
             preSingle = {}, preGroup = {}, exclusiveTo = {}, objectives = { list = {} } }
  end
  return {
    quests = { [1] = q(1, 20, 900), [2] = q(2, 28, 900), [3] = q(3, 20, 12), [4] = q(4, 26, 901) },
    dungeonAreas = { [900] = "Test Deeps", [901] = "Other Vault" },
  }
end

return {
  sim_releases_low_dungeon_quests_from_level_30 = function(t)
    local d = D()
    local state = { log = { [1] = "dungeon", [2] = "dungeon", [3] = true, [4] = "dungeon" }, logPad = 3 }
    -- chapitre sous DUNGEON_RELEASE_FROM : rien ne change (routes 1-30 inchangées)
    local steps = {}
    sim.releaseDungeonQuests(d, { minLevel = 29 }, state, steps)
    t.eq(#steps, 0); t.eq(state.log[1], "dungeon"); t.eq(state.logPad, 3)
    -- 30 : quêtes de donjon de niveau <= 26 abandonnées, une note optionnelle par donjon
    sim.releaseDungeonQuests(d, { minLevel = 30 }, state, steps)
    t.eq(state.log[1], nil, "level 20 dungeon quest released")
    t.eq(state.log[4], nil, "level 26 dungeon quest released")
    t.eq(state.log[2], "dungeon", "level 28 kept (30 - 4 = 26)")
    t.eq(state.log[3], true, "ordinary quest kept")
    t.ok(state.abandoned[1] and state.abandoned[4], "abandoned set")
    t.eq(state.logPad, 0, "log padding of the other race paths released")
    t.eq(#steps, 2)
    t.eq(steps[1][1], "note"); t.eq(steps[1].optional, true); t.eq(steps[1].dungeon, "Other Vault")
    t.ok(steps[1][2]:find("Q4", 1, true), steps[1][2])
    t.eq(steps[2].dungeon, "Test Deeps")
    -- 32 : la quête de niveau 28 part à son tour
    local more = {}
    sim.releaseDungeonQuests(d, { minLevel = 32 }, state, more)
    t.eq(state.log[2], nil); t.eq(#more, 1)
  end,

  replay_releases_the_same_quests = function(t)
    local d = D()
    local W = { taxi = { nodes = {} } }
    local accepts = {}
    for i = 1, 18 do
      d.quests[100 + i] = { id = 100 + i, level = 30, races = 0, zoneOrSort = 12, preSingle = {}, preGroup = {},
                            exclusiveTo = {}, objectives = { list = {} } }
    end
    local issues = {}
    local function run(minLevel)
      issues = {}
      local first = { { "accept", 1, optional = true, dungeon = "Test Deeps" },
                      { "accept", 4, optional = true, dungeon = "Other Vault" },
                      { "accept", 3, optional = true, dungeon = "Group quest" } } -- pas une quête de donjon
      local second = {}
      for i = 1, 18 do second[#second + 1] = { "accept", 100 + i } end
      paths.replay(d, W, "Alliance", "Human",
        { { id = "C1", steps = first, minLevel = 26 }, { id = "C2", steps = second, minLevel = minLevel } },
        function(ci, si, msg) issues[#issues + 1] = ci .. ":" .. si .. ":" .. msg end)
      return issues
    end
    -- 29 : 3 + 18 = 21 quêtes, journal plein à la 18e prise
    t.eq(#run(29), 1, "log full below level 30")
    t.ok(issues[1]:find("quest log full", 1, true), issues[1])
    -- 30 : les quêtes de donjon 1 et 4 (niveau <= 26) quittent le journal ; 3 reste (zone ordinaire)
    t.eq(#run(30), 0, table.concat(issues, " | "))
  end,
  -- Lot L : à la jonction du tronc, une quête ordinaire d'un autre parcours (rendu reporté) entre dans le journal
  -- du tronc ("foreign") ; une quête de donjon de ce parcours garde sa place (logPad) jusqu'à son abandon.
  merge_foreign_quests_and_dungeon_padding = function(t)
    local build = assert(loadfile(H.ROOT .. "/build.lua"))("--as-module")
    local base = { level = 12, xp = 0, log = { [3] = true }, knownTaxi = {}, hearthReadyAt = 0 }
    local other = { level = 13, xp = 0, log = { [3] = true, [50] = true, [1] = "dungeon", [2] = "dungeon" },
                    knownTaxi = {}, hearthReadyAt = 0 }
    local m = build.mergeStates(base, { other })
    t.eq(m.log[50], "foreign", "carried quest of the other path turned in by the trunk")
    t.eq(m.log[1], nil); t.eq(m.log[2], nil)
    t.eq(m.logPad, 2, "two dungeon quests of the other path")
    t.eq(base.log[50], nil, "base state untouched")
    local d = D()
    local steps = {}
    sim.releaseDungeonQuests(d, { minLevel = 30 }, m, steps)
    t.eq(m.logPad, 1, "level 20 quest released, level 28 quest still held")
    sim.releaseDungeonQuests(d, { minLevel = 32 }, m, steps)
    t.eq(m.logPad, 0)
    t.eq(m.log[50], "foreign", "ordinary quest never released")
    -- le parcours principal a plus de quêtes que l'autre n'en a en propre : aucune place réservée
    local base2 = { level = 12, xp = 0, log = { [3] = true, [60] = "dungeon", [61] = true }, knownTaxi = {}, hearthReadyAt = 0 }
    local m2 = build.mergeStates(base2, { other })
    t.eq(m2.logPad, 0, "2 dungeon quests of the other path, 2 base quests it does not have")
    -- abandon à 30 : la quête de donjon 60 (inconnue ici) reste, 61 reste ; l'autre parcours garde la 2
    sim.releaseDungeonQuests(d, { minLevel = 30 }, m2, {})
    t.eq(m2.logPad, 0)
  end,
}
