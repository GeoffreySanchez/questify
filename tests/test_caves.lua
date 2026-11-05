-- Tests des grottes (Data/Caves.lua, Nav/Caves.lua) et du détour par l'entrée dans Q.Nav.
-- Les données de grotte sont injectées (les tests ne dépendent pas des grottes livrées dans
-- Data/Caves.lua, vérifiées à part) : une grotte en U dont le contour est calculé depuis les
-- apparitions de PNJ et d'objets d'un faux QuestieDB.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local MAP = 1426
local E = { 30, 50 }          -- entrée de la grotte d'essai (0-100)

-- Apparitions (yards à l'est, yards au sud de l'entrée) : un U dont les deux bras sont loin l'un de
-- l'autre à vol d'oiseau mais qui part d'une seule entrée.
local NPC_A = { { 60, 0 }, { 140, -10 }, { 190, 40 }, { 200, 100 } }
local NPC_B = { { 40, 120 }, { 110, 150 }, { 190, 150 }, { 900, 900 } }   -- le dernier : très loin, écarté
local OBJ_A = { { 120, 90 } }
local DEEP = { 185, 145 }     -- bout du U, tout au fond : la cible de la quête
local MIDDLE = { 130, 80 }    -- dedans (au milieu du contour)
local WEST = { -300, 0 }      -- joueur sur la montagne de l'autre côté

local function cave()
  return { key = "test_den", name = "Test Den", mapId = MAP, entrance = { E[1], E[2] },
    npcs = { 9001, 9002 }, objects = { 9101 }, source = "https://example.test/den" }
end

local function load(settings, opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  opts.beforeLogin = function(Q)
    for path, value in pairs(settings or {}) do Q.Settings:Set(path, value) end
  end
  return Mock.loadAddon(TOC, opts)
end

-- Faux QuestieDB + données de grotte injectées.
local function setup(Q, caveData, npcs, objects)
  local function spawnsOf(list)
    if not list then return nil end
    local pts = {}
    for i, p in ipairs(list) do pts[i] = { p[1], p[2] } end   -- remplacés par `place` plus bas
    return pts
  end
  Q.QDB.Npc = function(_, id) return npcs and npcs[id] or nil end
  Q.QDB.Object = function(_, id) return objects and objects[id] or nil end
  Q.CaveData = caveData or { cave() }
  Q.Caves:Reset()
end

-- yards -> unités de carte (0-100), mesuré avec Q.Maps (les échelles x et y diffèrent)
local function units(Q)
  local dx = Q.Maps:Distance(MAP, 30, 50, MAP, 31, 50)
  local dy = Q.Maps:Distance(MAP, 30, 50, MAP, 30, 51)
  return dx, dy
end

local function at(Q, off)
  local dx, dy = units(Q)
  return { E[1] + off[1] / dx, E[2] + off[2] / dy }
end

local function spawnsList(Q, offs)
  local pts = {}
  for i, o in ipairs(offs) do pts[i] = at(Q, o) end
  return { [MAP] = pts }
end

local function worldWithDen(Q)
  local npcs = {
    [9001] = { id = 9001, spawns = spawnsList(Q, NPC_A) },
    [9002] = { id = 9002, spawns = spawnsList(Q, NPC_B) },
  }
  local objects = { [9101] = { id = 9101, spawns = spawnsList(Q, OBJ_A) } }
  setup(Q, nil, npcs, objects)
end

local function placePlayer(p)
  Mock.player.map, Mock.player.x, Mock.player.y = MAP, p[1], p[2]
end

local function lastWaypoint()
  local call = Mock.lastCall("C_Map.SetUserWaypoint")
  return call and call.args[1]
end

local function noErrors(t)
  for _, e in ipairs(Mock.errors) do
    local s = tostring(e)
    t.ok(not (s:find("Navigation.lua", 1, true) or s:find("Caves.lua", 1, true)), "error: " .. s)
  end
end

local function nearE(t, x, y, msg)
  t.near(x, E[1], 0.0001, msg); t.near(y, E[2], 0.0001, msg)
end

return {
  shipped_cave_data_is_valid = function(t)
    local Q = load()
    t.ok(type(Q.CaveData) == "table", "Q.CaveData is a table")
    local keys = {}
    for _, c in ipairs(Q.CaveData) do
      t.ok(type(c.key) == "string" and not keys[c.key], "unique key " .. tostring(c.key))
      keys[c.key] = true
      t.ok(type(c.mapId) == "number" and type(c.entrance) == "table", c.key .. ": map and entrance")
      t.ok(type(c.source) == "string" and c.source:find("^https?://"), c.key .. ": public source")
      t.ok(c.inside == nil, c.key .. ": no copied outline")
      t.ok(not tostring(c.source):lower():find("restedxp", 1, true), c.key .. ": no RestedXP data")
    end
  end,

  -- Contour calculé depuis les apparitions des PNJ et objets de la grotte.
  outline_computed_from_spawns = function(t)
    local Q = load()
    worldWithDen(Q)
    local c = Q.CaveData[1]
    t.eq(Q.Caves:At(MAP, at(Q, MIDDLE)[1], at(Q, MIDDLE)[2]), c, "middle of the den is inside")
    t.eq(Q.Caves:At(MAP, at(Q, DEEP)[1], at(Q, DEEP)[2]), c, "deepest spawn is inside")
    t.eq(Q.Caves:At(MAP, at(Q, WEST)[1], at(Q, WEST)[2]), nil, "mountain on the other side is outside")
    t.eq(Q.Caves:At(MAP, at(Q, { 900, 900 })[1], at(Q, { 900, 900 })[2]), nil, "far spawn of the same NPC ignored")
    t.eq(Q.Caves:At(MAP, at(Q, { 400, 400 })[1], at(Q, { 400, 400 })[2]), nil, "nowhere near the outline")
  end,

  outline_needs_three_points_and_a_database = function(t)
    local Q = load()
    setup(Q, nil, nil, nil)
    t.eq(Q.Caves:At(MAP, at(Q, MIDDLE)[1], at(Q, MIDDLE)[2]), nil, "no QuestieDB data: nothing")
    t.eq(Q.Caves:Plan(MAP, at(Q, DEEP)[1], at(Q, DEEP)[2]), nil, "no plan")
    -- un seul PNJ à une apparition : entrée + 1 point, moins de 3
    setup(Q, nil, { [9001] = { id = 9001, spawns = spawnsList(Q, { { 60, 0 } }) } }, nil)
    t.eq(Q.Caves:At(MAP, E[1], E[2]), nil, "fewer than three points")
    -- l'explicite `inside` reste accepté
    local c = cave()
    local a, b, d = at(Q, { 50, 0 }), at(Q, { 150, 100 }), at(Q, { 50, 200 })
    c.inside = { a, b, d }; c.npcs, c.objects = nil, nil
    setup(Q, { c }, nil, nil)
    local mid = at(Q, { 90, 100 })
    t.eq(Q.Caves:At(MAP, mid[1], mid[2]), c, "explicit inside accepted")
  end,

  -- Grizzled Den : cible au bout du U, joueur sur la montagne de l'autre côté -> l'entrée.
  u_shaped_cave_target_shows_the_entrance = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local p = lastWaypoint()
    nearE(t, p.position.x * 100, p.position.y * 100, "entrance first")
    t.eq(Q.Nav:Status().cave, true)
    noErrors(t)
  end,

  -- Premier point montré = l'entrée, avec son titre, pour chaque affichage.
  native_display_shows_the_entrance_first = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local p = lastWaypoint()
    nearE(t, p.position.x * 100, p.position.y * 100)
    -- puis la flèche directe une fois à l'entrée
    placePlayer(E)
    Mock.advance(1)
    t.near(lastWaypoint().position.x * 100, d[1], 0.01, "then the target")
    placePlayer(at(Q, MIDDLE))
    Mock.advance(1)
    t.near(lastWaypoint().position.x * 100, d[1], 0.01, "still the target inside")
    noErrors(t)
  end,

  waypointui_display_shows_the_entrance_first = function(t)
    Mock.addons.WaypointUI = true
    local Q = load({ ["nav.display"] = "waypointui" })
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local call = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation")
    t.ok(call, "WaypointUI called")
    nearE(t, call.args[1].x, call.args[1].y)
    t.ok(call.args[1].name:find("Cave entrance", 1, true) and call.args[1].name:find("wendigos", 1, true),
      tostring(call.args[1].name))
    noErrors(t)
  end,

  tomtom_display_shows_the_entrance_first = function(t)
    Mock.addons.TomTom = true
    local Q = load({ ["nav.display"] = "tomtom" })
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local call = Mock.lastCall("TomTom:AddWaypoint")
    t.ok(call, "TomTom called")
    nearE(t, call.args[2] * 100, call.args[3] * 100)
    t.ok(call.args[4].title:find("Cave entrance", 1, true) and call.args[4].title:find("wendigos", 1, true),
      tostring(call.args[4].title))
    noErrors(t)
  end,

  shortestpath_display_shows_the_entrance_first = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    local Q = load({ ["nav.routing"] = true, ["nav.display"] = "waypointui" })
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local call = Mock.lastCall("ShortestPathForever.API.NavigateRoute")
    t.ok(call, "NavigateRoute")
    local stops = call.args[2]
    t.eq(#stops, 2, "entrance then target")
    nearE(t, stops[1].x * 100, stops[1].y * 100)
    t.ok(stops[1].title:find("Cave entrance", 1, true) and stops[1].title:find("wendigos", 1, true), stops[1].title)
    t.near(stops[2].x * 100, d[1], 0.01); t.eq(stops[2].kind, "quest")
    -- le repère nommé de WaypointUI montre aussi l'entrée
    local seed = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation")
    t.ok(seed and seed.args[1].name:find("Cave entrance", 1, true), "WaypointUI seeded with the entrance")
    -- à l'entrée : la flèche directe remplace le calcul d'itinéraire
    placePlayer(E)
    Mock.advance(1)
    t.eq(Mock.countCalls("ShortestPathForever.API.Cancel"), 1, "route cancelled")
    t.eq(Q.Nav:Status().provider, "waypointui")
    noErrors(t)
  end,

  -- ShortestPath sans NavigateRoute : c'est quand même l'entrée qu'on lui demande.
  shortestpath_without_navigate_route_goes_to_the_entrance = function(t)
    Mock.addons.ShortestPathForever = true
    local Q = load({ ["nav.routing"] = true })
    ShortestPathForever.API.NavigateRoute = nil
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local call = Mock.lastCall("ShortestPathForever.API.Navigate")
    t.near(call.args[3] * 100, E[1], 0.0001, "entrance, not the target")
    noErrors(t)
  end,

  -- Constat 1 : position du joueur inconnue -> l'entrée quand même.
  unknown_player_position_still_enters_by_the_entrance = function(t)
    local Q = load()
    worldWithDen(Q)
    Mock.player.map = nil
    local d = at(Q, DEEP)
    local plan = Q.Caves:Plan(MAP, d[1], d[2])
    t.ok(plan, "plan despite unknown position")
    t.eq(#plan.stops, 1); t.eq(plan.stops[1].kind, "enter")
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local p = lastWaypoint()
    t.ok(p, "waypoint set")
    nearE(t, p.position.x * 100, p.position.y * 100, "entrance")
    noErrors(t)

    Mock.addons.ShortestPathForever = true
    local Q2 = load({ ["nav.routing"] = true })
    worldWithDen(Q2)
    Mock.player.map = nil
    Q2.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local call = Mock.lastCall("ShortestPathForever.API.NavigateRoute")
    t.ok(call, "route through the entrance")
    nearE(t, call.args[2][1].x * 100, call.args[2][1].y * 100)
  end,

  -- Constat 2 : une cible devant l'entrée n'est pas dans la grotte.
  target_in_front_of_the_entrance_is_not_inside = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local front = at(Q, { -5, 0 })
    t.eq(Q.Caves:At(MAP, front[1], front[2]), nil, "in front of the mouth")
    t.eq(Q.Caves:Plan(MAP, front[1], front[2]), nil, "no detour")
    Q.Nav:SetTarget(MAP, front[1], front[2], "Talk to the guard")
    t.near(lastWaypoint().position.x * 100, front[1], 0.0001, "the target itself")
    t.eq(Q.Nav:Status().cave, false)
    noErrors(t)
  end,

  -- Le joueur sort de la grotte : l'entrée d'abord, puis la cible dehors.
  arrow_leaves_through_the_entrance = function(t)
    local Q = load()
    worldWithDen(Q)
    IsIndoors = function() return true end   -- le joueur s'est connecté dans la grotte
    placePlayer(at(Q, MIDDLE))
    local out = at(Q, { -200, 100 })
    Q.Nav:SetTarget(MAP, out[1], out[2], "Turn in")
    nearE(t, lastWaypoint().position.x * 100, lastWaypoint().position.y * 100, "exit first")
    IsIndoors = nil
    placePlayer(E)
    Mock.advance(1)
    t.near(lastWaypoint().position.x * 100, out[1], 0.01, "out: the target")
    placePlayer(at(Q, { -30, 0 }))   -- dehors, à 30 yd : pas de retour vers la sortie
    Mock.advance(1)
    t.near(lastWaypoint().position.x * 100, out[1], 0.01, "no exit once outside")
    noErrors(t)
  end,

  -- Constat 3 : changer d'affichage efface la navigation WaypointUI nommée posée avant.
  switching_display_clears_the_orphan_waypointui_navigation = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    Mock.addons.TomTom = true
    local Q = load({ ["nav.routing"] = true, ["nav.display"] = "waypointui" })
    Q.Nav:SetTarget(MAP, 29.93, 71.2, "Talk")
    t.ok(Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation"), "seeded")
    local cleared = Mock.countCalls("WaypointUIAPI.Navigation.ClearUserNavigation")
    Q.Settings:Set("nav.display", "tomtom")
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.ClearUserNavigation"), cleared + 1, "orphan cleared")
    noErrors(t)
  end,

  -- Constat 4 : la minuterie ne recalcule rien quand le joueur ne bouge pas.
  ticker_does_not_recompute_while_the_player_stands_still = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    local calls = 0
    local plan = Q.Caves.Plan
    Q.Caves.Plan = function(...) calls = calls + 1; return plan(...) end
    Mock.advance(10)
    t.eq(calls, 0, "no recompute without movement")
    placePlayer(at(Q, { WEST[1] + 1, WEST[2] }))   -- un yard de plus
    Mock.advance(1)
    t.eq(calls, 0, "a step or two is not enough")
    placePlayer(E)
    Mock.advance(1)
    t.ok(calls >= 1, "recomputed after real movement")
    noErrors(t)
  end,

  -- Constat 5 + Mineur 3 : une autre cible dans la même grotte (même titre) ne repose pas le point
  -- (TomTom retirerait et rajouterait, WaypointUI jouerait un son) mais la dernière est mémorisée :
  -- à l'entrée, la flèche va vers elle. Un titre différent repose le point.
  target_change_in_the_same_cave_does_not_reset_the_point = function(t)
    Mock.addons.TomTom = true
    local Q = load({ ["nav.display"] = "tomtom" })
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local a, b = at(Q, DEEP), at(Q, { 110, 145 })
    Q.Nav:SetTarget(MAP, a[1], a[2], "Kill the wendigos")
    local adds = Mock.countCalls("TomTom:AddWaypoint")
    local removes = Mock.countCalls("TomTom:RemoveWaypoint")
    Q.Nav:SetTarget(MAP, b[1], b[2], "Kill the wendigos")
    t.eq(Mock.countCalls("TomTom:AddWaypoint"), adds, "same entrance, same title: no new set")
    t.eq(Mock.countCalls("TomTom:RemoveWaypoint"), removes, "no remove either")
    t.eq(Q.Nav:Status().target.x, b[1], "latest target remembered")
    Q.Nav:SetTarget(MAP, a[1], a[2], "Kill Edan")
    t.eq(Mock.countCalls("TomTom:AddWaypoint"), adds + 1, "new title: reset")
    Q.Nav:SetTarget(MAP, b[1], b[2], "Kill Edan")
    placePlayer(E)
    Mock.advance(1)
    local last = Mock.lastCall("TomTom:AddWaypoint")
    t.near(last.args[2] * 100, b[1], 0.01, "at the entrance: the LAST target")
    noErrors(t)
  end,

  waypointui_navigation_is_silent = function(t)
    Mock.addons.WaypointUI = true
    local Q = load({ ["nav.display"] = "waypointui" })
    Q.Nav:SetTarget(MAP, 29.93, 71.2, "Talk")
    t.eq(Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation").args[1].suppressAudio, true)
  end,

  -- Mineur 4 : repère natif avec WaypointUI chargé : l'entrée, avec son titre.
  native_with_waypointui_shows_the_entrance_title = function(t)
    Mock.addons.WaypointUI = true
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill the wendigos")
    local call = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation")
    t.ok(call, "WaypointUI places the pin")
    nearE(t, call.args[1].x, call.args[1].y)
    t.ok(call.args[1].name:find("Cave entrance — Kill the wendigos", 1, true), tostring(call.args[1].name))
    noErrors(t)
  end,

  -- Critique 1 : une fois entré, couloir hors de l'axe et bord extérieur d'un bras : flèche directe.
  corridor_off_axis_keeps_the_direct_arrow = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    placePlayer(E)
    Mock.advance(1)
    for _, off in ipairs({ { 18, -2 }, { 40, -8 }, { 215, 60 } }) do
      placePlayer(at(Q, off))
      Mock.advance(1)
      t.near(lastWaypoint().position.x * 100, d[1], 0.01, "direct arrow at " .. off[1] .. "," .. off[2])
    end
    -- vraiment sorti (loin de toute arête) : l'entrée de nouveau
    placePlayer(at(Q, WEST))
    Mock.advance(1)
    nearE(t, lastWaypoint().position.x * 100, lastWaypoint().position.y * 100, "left: entrance again")
    noErrors(t)
  end,

  -- Important 1 : sur la montagne au-dessus de la grotte, sans être passé par l'entrée : l'entrée.
  player_above_the_cave_is_not_inside = function(t)
    local Q = load()
    worldWithDen(Q)
    local d = at(Q, DEEP)
    placePlayer(at(Q, { 150, 60 }))
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    nearE(t, lastWaypoint().position.x * 100, lastWaypoint().position.y * 100, "entrance, not the target")
    -- IsIndoors() vrai (connexion dans la grotte) : flèche directe
    IsIndoors = function() return true end
    Q.Caves:Reset()
    Mock.advance(1)
    placePlayer(at(Q, { 151, 60 }))
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    IsIndoors = nil
    t.near(lastWaypoint().position.x * 100, d[1], 0.01, "indoors: direct arrow")
    noErrors(t)
  end,

  -- Mineur 1 : position inconnue, la minuterie ne recalcule pas chaque seconde.
  unknown_position_plans_once = function(t)
    local Q = load()
    worldWithDen(Q)
    Mock.player.map = nil
    local calls = 0
    local plan = Q.Caves.Plan
    Q.Caves.Plan = function(...) calls = calls + 1; return plan(...) end
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    Mock.advance(10)
    t.eq(calls, 1, "one plan for ten ticks")
  end,

  -- Mineur 2 : cible à 20 yd devant l'entrée : pas de détour.
  target_20_yards_in_front_of_the_entrance_has_no_detour = function(t)
    local Q = load()
    worldWithDen(Q)
    local front = at(Q, { -20, 0 })
    t.eq(Q.Caves:Plan(MAP, front[1], front[2]), nil)
  end,

  -- Rayon par grotte : le fond d'une grande grotte (> 250 yd) entre dans le contour.
  cave_radius_field = function(t)
    local Q = load()
    local far = { 330, 150 }
    local function run(radius)
      local c = cave(); c.radius = radius
      local npcs = { [9001] = { id = 9001, spawns = spawnsList(Q, { { 60, 0 }, { 200, 100 }, far }) } }
      setup(Q, { c }, npcs, nil)
      local p = at(Q, { 320, 145 })
      return Q.Caves:At(MAP, p[1], p[2])
    end
    t.eq(run(nil), nil, "default 250 yd: the far end is cut")
    t.ok(run(400) ~= nil, "radius = 400: the far end is inside")
  end,

  -- Données livrées (ruling F2-quinquies) : 5 grottes dont l'entrée est la bouche.
  shipped_caves_are_the_vetted_set = function(t)
    local Q = load()
    local want = { "Grizzled Den", "Echo Ridge", "Dustwind", "Skull Rock", "Night Web" }
    t.eq(#Q.CaveData, #want)
    for _, w in ipairs(want) do
      local found
      for _, c in ipairs(Q.CaveData) do if c.name:find(w, 1, true) then found = c end end
      t.ok(found, "shipped: " .. w)
      t.ok(found and found.entrance and #(found.npcs or {}) + #(found.objects or {}) > 0, w .. ": entrance and ids")
    end
    for _, c in ipairs(Q.CaveData) do
      for _, no in ipairs({ "Boulderslide", "Fargodeep", "Jasperlode", "Venture Co", "Shadowthread" }) do
        t.ok(not c.name:find(no, 1, true), "not shipped: " .. no)
      end
    end
    local den
    for _, c in ipairs(Q.CaveData) do if c.name:find("Grizzled", 1, true) then den = c end end
    t.eq(den.radius, 400); t.eq(den.npcs, { 1135, 1137, 1271 })
  end,

  -- Liste exacte des clés livrées, et même liste que les grottes marquées "shipped": true dans
  -- tools/caves/caves.json (les autres y sont marquées false).
  shipped_cave_keys_are_exact = function(t)
    local Q = load()
    local keys = {}
    for i, c in ipairs(Q.CaveData) do keys[i] = c.key end
    t.eq(keys, { "dunmorogh_grizzled_den", "elwynn_echo_ridge_mine", "durotar_dustwind_cave",
      "durotar_skull_rock", "tirisfal_night_webs_hollow" })
    local f = assert(io.open(Mock.root .. "/tools/caves/caves.json", "rb"))
    local json = f:read("*a")
    f:close()
    local shipped, entries = {}, 0
    for line in json:gmatch("[^\n]+") do
      local key = line:match('"key"%s*:%s*"([^"]+)"')
      if key then
        entries = entries + 1
        local flag = line:match('"shipped"%s*:%s*(%a+)')
        t.ok(flag == "true" or flag == "false", key .. ": shipped flag in caves.json")
        if flag == "true" then shipped[#shipped + 1] = key end
      end
    end
    t.ok(entries > #keys, "caves.json lists the researched caves")
    table.sort(shipped)
    table.sort(keys)
    t.eq(shipped, keys, "caves.json shipped = Data/Caves.lua")
  end,

  -- Mine dont les PNJ ont aussi des camps à ciel ouvert (cas de la Venture Co. Mine, plus livrée) :
  -- les camps, loin de l'entrée, sont écartés du contour (rayon par défaut).
  open_air_camps_far_from_the_entrance_are_ignored = function(t)
    local Q = load()
    Mock.maps[1412] = { name = "Mulgore", continent = 1, left = -3000, top = -1000, width = 4000,
      height = 2700, parent = 1414 }
    Mock.advance(120)   -- une carte inconnue au chargement n'est retentée qu'après un délai
    local mine = { key = "test_mine", name = "Test Mine", mapId = 1412, entrance = { 61, 47 },
      npcs = { 9301, 9302 }, objects = {}, source = "https://example.test/mine" }
    Q.CaveData = { mine }
    local ex, ey = mine.entrance[1], mine.entrance[2]
    local dx = Q.Maps:Distance(1412, 50, 50, 1412, 51, 50)
    local dy = Q.Maps:Distance(1412, 50, 50, 1412, 50, 51)
    local function pt(a, b) return { ex + a / dx, ey + b / dy } end
    local function sp(list) local o = {} for i, p in ipairs(list) do o[i] = pt(p[1], p[2]) end return { [1412] = o } end
    Q.QDB.Npc = function(_, id)
      if id == mine.npcs[1] then return { id = id, spawns = sp({ { 40, 10 }, { 90, 60 }, { 60, 120 }, { 700, -500 } }) } end
      if id == mine.npcs[2] then return { id = id, spawns = sp({ { 20, 90 }, { 800, 600 } }) } end
      return nil
    end
    Q.QDB.Object = function() return nil end
    Q.Caves:Reset()
    local inside, camp = pt(60, 60), pt(750, -450)
    t.eq(Q.Caves:At(1412, inside[1], inside[2]), mine, "mine interior inside")
    t.eq(Q.Caves:At(1412, camp[1], camp[2]), nil, "far open-air camp outside")
    local between = pt(400, 0)
    t.eq(Q.Caves:At(1412, between[1], between[2]), nil, "nothing between the mine and the camp")
  end,

  -- Tour 2, scénario 1 (quête 313) : Young Wendigo devant l'entrée, puis un Wendigo du fond. Sans
  -- IsIndoors : le passage par l'entrée est retenu même si la cible du moment n'est pas « dans ».
  entering_with_a_target_in_front_keeps_the_pass_when_the_target_goes_deep = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local front, d = at(Q, { -10, 5 }), at(Q, DEEP)
    Q.Nav:SetTarget(MAP, front[1], front[2], "Kill Young Wendigo")
    placePlayer(E)
    Mock.advance(1)
    for _, off in ipairs({ { 40, 0 }, { 80, 20 } }) do
      placePlayer(at(Q, off))
      Mock.advance(1)
      Q.Nav:SetTarget(MAP, d[1], d[2], "Kill Wendigo")
      t.near(lastWaypoint().position.x * 100, d[1], 0.01, "direct arrow at " .. off[1])
    end
    noErrors(t)
  end,

  -- Scénario 2 : entré, au fond ; la cible sort (sortie juste), puis revient au fond : flèche directe.
  target_going_out_and_back_keeps_the_player_inside = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local d, out = at(Q, DEEP), at(Q, { -200, 100 })
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    placePlayer(E)
    Mock.advance(1)
    placePlayer(at(Q, { 120, 60 }))
    Mock.advance(1)
    Q.Nav:SetTarget(MAP, out[1], out[2], "Turn in")
    nearE(t, lastWaypoint().position.x * 100, lastWaypoint().position.y * 100, "out: exit first")
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    t.near(lastWaypoint().position.x * 100, d[1], 0.01, "back to the deep target: direct arrow")
    noErrors(t)
  end,

  -- Passer devant la bouche sans entrer ne marque pas le joueur « entré ».
  passing_the_mouth_without_entering_is_not_entering = function(t)
    local Q = load()
    worldWithDen(Q)
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    placePlayer(E)
    Mock.advance(1)
    placePlayer(at(Q, WEST))
    Mock.advance(1)
    placePlayer(at(Q, { 150, 60 }))   -- sur la montagne, au-dessus
    Mock.advance(1)
    nearE(t, lastWaypoint().position.x * 100, lastWaypoint().position.y * 100, "entrance, not the target")
  end,

  -- Passage le long de la bouche (pas une téléportation), on s'éloigne, puis la montagne au-dessus :
  -- jamais « entré ». Limite connue (2D) : sans s'éloigner, monter sur la montagne juste après la bouche,
  -- dans le contour et côté grotte, ne se distingue pas du couloir.
  walking_past_the_mouth_is_not_entering = function(t)
    local Q = load()
    worldWithDen(Q)
    local d = at(Q, DEEP)
    Q.Nav:SetTarget(MAP, d[1], d[2], "Kill")
    for _, p in ipairs({ { 10, -20 }, { 4, -10 }, { 0, 0 }, { -4, 9 }, { -10, 18 }, { -60, 30 }, { 150, 60 } }) do
      placePlayer(at(Q, p))
      Mock.advance(1)
      if p[1] == -10 then
        nearE(t, lastWaypoint().position.x * 100, lastWaypoint().position.y * 100, "past the mouth: entrance")
      end
    end
    nearE(t, lastWaypoint().position.x * 100, lastWaypoint().position.y * 100, "entrance, not the target")
  end,

  -- Cible dehors (rendre une quête) : le joueur entre quand même dans la grotte ; l'arrêt « sortie »
  -- (l'entrée) doit s'afficher sans attendre un autre recalcul.
  entering_with_an_outside_target_shows_the_exit = function(t)
    local Q = load()
    worldWithDen(Q)
    local far = at(Q, { -400, -400 })
    placePlayer(at(Q, WEST))
    Q.Nav:SetTarget(MAP, far[1], far[2], "Turn in")
    t.near(lastWaypoint().position.x * 100, far[1], 0.0001, "target outside: direct")
    placePlayer(E)
    Mock.advance(1)
    for _, p in ipairs({ { 30, 2 }, { 100, 40 } }) do
      placePlayer(at(Q, p))
      Mock.advance(1)
    end
    nearE(t, lastWaypoint().position.x * 100, lastWaypoint().position.y * 100, "exit stop shown")
  end,

  -- Mineur 1 : 20 yd devant l'entrée : dehors ; 20 yd derrière (vers le cœur) : dedans.
  target_behind_the_entrance_is_inside_in_front_is_not = function(t)
    local Q = load()
    worldWithDen(Q)
    local front, behind = at(Q, { -20, 0 }), at(Q, { 14, 14 })
    t.eq(Q.Caves:At(MAP, front[1], front[2]), nil, "20 yd in front")
    t.eq(Q.Caves:At(MAP, behind[1], behind[2]), Q.CaveData[1], "20 yd behind")
  end,

  -- PlayerCave() : clé de la grotte où le joueur est entré (passé par l'entrée), sinon nil.
  player_cave_is_the_entered_cave = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    Q.Caves:Track()
    t.eq(Q.Caves:PlayerCave(), nil, "outside")
    placePlayer(E)
    Q.Caves:Track()
    t.eq(Q.Caves:PlayerCave(), nil, "at the mouth: not inside yet")
    placePlayer(at(Q, { 120, 60 }))
    Q.Caves:Track()
    t.eq(Q.Caves:PlayerCave(), "test_den", "inside")
    placePlayer(at(Q, { -400, -400 }))
    Q.Caves:Track()
    t.eq(Q.Caves:PlayerCave(), nil, "left the cave")
    placePlayer(at(Q, { 150, 60 }))   -- sur la montagne, au-dessus, sans passer par l'entrée
    Q.Caves:Track()
    t.eq(Q.Caves:PlayerCave(), nil, "above the cave is not inside")
  end,

  -- Sans cible, Nav ne suit plus le joueur (Track) : PlayerCave ne garde pas un « entré » périmé.
  player_cave_without_tracking_after_leaving = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(E)
    Q.Caves:Track()
    placePlayer(at(Q, { 120, 60 }))
    Q.Caves:Track()
    t.eq(Q.Caves:PlayerCave(), "test_den")
    placePlayer(at(Q, { -400, -400 }))   -- sorti, sans Track
    t.eq(Q.Caves:PlayerCave(), nil, "far from the cave: not inside")
    placePlayer(at(Q, { 120, 60 }))
    t.eq(Q.Caves:PlayerCave(), "test_den", "the state itself is untouched (Track decides)")
  end,

  no_detour_outside_caves = function(t)
    local Q = load()
    worldWithDen(Q)
    placePlayer(at(Q, WEST))
    local far = at(Q, { -400, -400 })
    Q.Nav:SetTarget(MAP, far[1], far[2], "Talk")
    t.near(lastWaypoint().position.x * 100, far[1], 0.0001)
    t.eq(Q.Nav:Status().cave, false)
    noErrors(t)
  end,
}
