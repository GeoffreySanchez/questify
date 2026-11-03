-- Tests du chargeur QuestieDB (qdb.lua) et de la géométrie du monde (world.lua).
local H = require("helpers")

local function near(a, b, tol) return math.abs(a - b) <= tol end

return {
  ironforge_taxi_matches_map = function(t)
    local W = H.W()
    local node
    for _, n in pairs(W.taxi.nodes) do if n.name == "Ironforge, Dun Morogh" then node = n end end
    t.ok(node, "taxi node Ironforge")
    t.ok(near(node.wx, -4821.78, 0.1) and near(node.wy, -1155.44, 0.1), "node world position")
    local x, y = W.fromWorld(1426, node.wx, node.wy)
    t.ok(x and x > 0 and x < 100 and y > 0 and y < 100, "inside Dun Morogh map")
    local c, wx, wy = W.toWorld(1426, x, y)
    t.eq(c, 0, "Eastern Kingdoms")
    t.ok(math.sqrt((wx - node.wx) ^ 2 + (wy - node.wy) ^ 2) < 5, "round trip within 5 yd")
  end,

  -- Vérifie l'orientation des axes : le maître de vol d'Ironforge (Gryth Thurden, 1573), placé par
  -- QuestieDB sur la carte 1455, doit tomber à quelques mètres du nœud de vol des tables DB2.
  ironforge_flightmaster_orientation = function(t)
    local W, D = H.W(), H.D()
    local npc = D.npcs[1573]
    t.ok(npc and npc.spawns[1455], "Gryth Thurden spawn on Ironforge map")
    local p = npc.spawns[1455][1]
    local c, wx, wy = W.toWorld(1455, p[1], p[2])
    t.eq(c, 0)
    t.ok(math.sqrt((wx - -4821.78) ^ 2 + (wy - -1155.44) ^ 2) < 30, "flight master within 30 yd of taxi node")
    local node, yd = W.nearestTaxi(0, wx, wy)
    t.eq(node.name, "Ironforge, Dun Morogh")
    t.ok(yd < 30)
  end,

  distance_coldridge = function(t)
    local W = H.W()
    local d = W.dist(1426, 29.93, 71.20, 1426, 22.60, 71.43)
    t.ok(d >= 250 and d <= 450, "Sten -> Talin = " .. tostring(d))
    t.eq(W.dist(1426, 50, 50, 1439, 50, 50), math.huge, "different continents")
  end,

  flight_time_ironforge_thelsamar = function(t)
    local W = H.W()
    local ifn, th
    for id, n in pairs(W.taxi.nodes) do
      if n.name == "Ironforge, Dun Morogh" then ifn = id end
      if n.name == "Thelsamar, Loch Modan" then th = id end
    end
    local s = W.flightTime(ifn, th)
    t.ok(s and s > 20 and s < 300, "IF -> Thelsamar flight " .. tostring(s))
  end,

  loader_quest_179 = function(t)
    local D = H.D()
    t.eq(D.quests[179].name, "Dwarven Outfitters")
    t.eq(D.xp[179][2], 80)
    t.eq(D.quests[179].starters.npcs[1], 658)
    t.eq(D.quests[179].objectives.items[1], 750)
    t.ok(D.drops[750][705] > 0.5 and D.drops[750][705] < 0.8, "Ragged Young Wolf drop rate")
    local sten = D.npcs[658].spawns[1426][1]
    t.ok(near(sten[1], 29.93, 0.01) and near(sten[2], 71.20, 0.01))
  end,

  loader_has_forever_quest = function(t)
    local D = H.D()
    t.ok(D.quests[97277], "quest 97277")
    t.eq(D.quests[97277].name, "Grund and Gozwin")
    t.ok(D.newQuests[97277], "flagged as a new Forever quest")
  end,

  loader_flight_masters = function(t)
    local D = H.D()
    local found = false
    for _, id in ipairs(D.flightMasters) do if id == 1573 then found = true end end
    t.ok(found, "Gryth Thurden is a flight master")
    t.ok(#D.innkeepers > 10, "innkeepers")
  end,

  loader_sandbox = function(t)
    local qdb = require("qdb")
    local path = H.tmpdir() .. "/evil_data.lua"
    local f = assert(io.open(path, "wb"))
    f:write("os.exit(3)\n")
    f:close()
    local ok, err = pcall(qdb.runFile, path, qdb.makeEnv(nil, "test"))
    t.ok(not ok, "os.exit must not run")
    t.ok(tostring(err):find("unknown global 'os'", 1, true), tostring(err))
    -- Les chaînes de données sont exécutées dans un environnement vide.
    t.fails(function() qdb.decodeData("return { [1] = os.exit(4) }", "evil") end)
  end,
}
