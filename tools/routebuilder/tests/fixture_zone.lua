-- Zone synthétique pour les tests de la simulation : carte 9001 de 2000 × 2000 yards (1 % = 20 yd).
--   hub 1 en (20, 20) : quêtes 101, 102, 103 -> 104 (chaîne), 105 (transport vers le hub 2), 106 (lointaine)
--   hub 2 en (60, 60) : quêtes 107 et 108
--   maître de vol 3001 en (40, 40), sur le trajet entre les deux hubs ; aubergiste 1003 au hub 1.
local world = require("world")

local F = {}
local MAP = 9001
local ALLIANCE = 77 -- Humain + Nain + Elfe de la nuit + Gnome

local function spawns(cx, cy, n, spread)
  local list = {}
  for i = 1, n do
    local a = i * 2.399963 -- angle d'or : points déterministes autour du centre
    local r = spread * math.sqrt(i / n)
    list[#list + 1] = { cx + r * math.cos(a), cy + r * math.sin(a) }
  end
  return { [MAP] = list }
end

local function npc(id, name, x, y, opts)
  opts = opts or {}
  return { id = id, name = name, minLevel = opts.level or 5, maxLevel = opts.level or 5, rank = 0,
    spawns = opts.spawns or { [MAP] = { { x, y } } }, friendly = opts.friendly, npcFlags = opts.flags or 0,
    questStarts = {}, questEnds = {} }
end

local function quest(id, name, level, giver, finisher, objectives, text, extra)
  local q = {
    id = id, name = name, level = level, reqLevel = 1, races = ALLIANCE, classes = 0,
    starters = { npcs = { giver }, objects = {}, items = {} }, finishers = { npcs = { finisher }, objects = {} },
    objectives = objectives or { creatures = {}, killCredit = {}, objects = {}, items = {}, list = {} },
    objectivesText = text and { text } or nil, preSingle = {}, preGroup = {}, exclusiveTo = {},
    childQuests = {}, breadcrumbs = {}, specialFlags = 0, questFlags = 0, zoneOrSort = 9001,
    requiredSourceItems = {}, extraObjectives = {}, blacklisted = false,
  }
  for k, v in pairs(extra or {}) do q[k] = v end
  return q
end

local function kill(npcId)
  return { creatures = { npcId }, killCredit = {}, objects = {}, items = {},
           list = { { kind = "kill", id = npcId, index = 1 } } }
end

function F.D()
  local D = { quests = {}, npcs = {}, objects = {}, items = {}, xp = {}, drops = {}, npcFlags = {},
              flightMasters = { 3001 }, innkeepers = { 1003 }, blacklist = {}, newQuests = {},
              dungeonAreas = {}, areaName = {}, unlocks = {}, faction = "Alliance", commit = "fixture" }
  local N = D.npcs
  N[1001] = npc(1001, "Giver One", 20, 20, { friendly = "A" })
  N[1003] = npc(1003, "Innkeeper One", 20.4, 20.2, { friendly = "A", flags = 128 })
  N[2001] = npc(2001, "Giver Two", 60, 60, { friendly = "A" })
  N[2002] = npc(2002, "Giver Three", 60.4, 60.2, { friendly = "A" })
  N[3001] = npc(3001, "Flight Master", 40, 40, { friendly = "A", flags = 8 })
  N[2101] = npc(2101, "Fixture Wolf", 0, 0, { level = 2, spawns = spawns(25, 28, 12, 2) })
  N[2102] = npc(2102, "Fixture Boar", 0, 0, { level = 3, spawns = spawns(14, 26, 12, 2) })
  N[2103] = npc(2103, "Fixture Trogg", 0, 0, { level = 3, spawns = spawns(28, 14, 12, 2) })
  N[2104] = npc(2104, "Trogg Chief", 31, 11, { level = 4 })
  N[2106] = npc(2106, "Distant Crab", 0, 0, { level = 3, spawns = spawns(95, 5, 6, 1) })
  N[2107] = npc(2107, "Grey Wolf", 0, 0, { level = 4, spawns = spawns(66, 64, 12, 2) })
  for id in pairs(N) do D.npcFlags[id] = N[id].npcFlags end
  D.objects[4108] = { id = 4108, name = "Supply Crate", spawns = spawns(55, 66, 8, 2), questStarts = {}, questEnds = {} }
  D.items[3102] = { id = 3102, name = "Boar Tusk", npcDrops = { 2102 }, objectDrops = {}, itemDrops = {}, questRewards = {}, vendors = {} }
  D.drops[3102] = { [2102] = 0.6 }

  local Q = D.quests
  Q[101] = quest(101, "Wolf Hunt", 2, 1001, 1001, kill(2101), "Kill 8 Fixture Wolves.")
  Q[102] = quest(102, "Boar Parts", 3, 1001, 1001,
    { creatures = {}, killCredit = {}, objects = {}, items = { 3102 }, list = { { kind = "item", id = 3102, index = 1 } } },
    "Bring 6 Boar Tusks to Giver One.")
  Q[103] = quest(103, "Trogg Trouble", 3, 1001, 1001, kill(2103), "Kill 10 Fixture Troggs.")
  Q[104] = quest(104, "Trogg Leader", 4, 1001, 1001, kill(2104), "Kill the Trogg Chief.", { preSingle = { 103 } })
  Q[105] = quest(105, "Letter to Hub Two", 3, 1001, 2001, nil, "Deliver the letter to Giver Two.", { breadcrumbFor = 107 })
  Q[106] = quest(106, "Far Errand", 3, 1001, 1001, kill(2106), "Kill 5 Distant Crabs.")
  Q[107] = quest(107, "Hub Two Wolves", 4, 2001, 2001, kill(2107), "Kill 10 Grey Wolves.", { breadcrumbs = { 105 } })
  Q[108] = quest(108, "Crates", 4, 2002, 2002,
    { creatures = {}, killCredit = {}, objects = { 4108 }, items = {}, list = { { kind = "object", id = 4108, index = 1 } } },
    "Search 5 Supply Crates.")
  D.xp = { [101] = { 2, 170 }, [102] = { 3, 250 }, [103] = { 3, 250 }, [104] = { 4, 355 }, [105] = { 3, 40 },
           [106] = { 3, 100 }, [107] = { 4, 355 }, [108] = { 4, 355 } }
  D.unlocks = { [103] = { 104 } }
  return D
end

function F.W()
  local maps = { [MAP] = { id = MAP, name = "Fixture Vale", continent = 99, type = 3,
                           minX = 0, minY = 0, maxX = 2000, maxY = 2000 } }
  -- nœud 501 sous le maître de vol (40, 40) ; nœud 502 au loin
  local function wpos(x, y) return 2000 - y / 100 * 2000, 2000 - x / 100 * 2000 end
  local ax, ay = wpos(40, 40)
  local bx, by = wpos(90, 90)
  local nodes = {
    { id = 501, name = "Fixture Roost", continent = 99, wx = ax, wy = ay, faction = "Alliance" },
    { id = 502, name = "Far Roost", continent = 99, wx = bx, wy = by, faction = "Alliance" },
  }
  return world.new(maps, nodes, { { 501, 502 }, { 502, 501 } })
end

function F.plan()
  return { id = "T_Fixture_01", title = "Fixture Vale", faction = "Alliance", races = { "Dwarf" },
           zones = { MAP }, minLevel = 1, maxLevel = 6, entry = { MAP, 20, 20 } }
end

function F.state()
  return { level = 1, xp = 0, pos = { MAP, 20, 20 }, done = {}, log = {}, knownTaxi = {}, hearth = nil,
           hearthReadyAt = 0, time = 0, raceBits = 4, classBit = nil }
end

F.MAP = MAP
return F
