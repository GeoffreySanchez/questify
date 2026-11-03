-- tools/routebuilder/world.lua : géométrie du monde et réseau de vols, d'après les tables DB2 du
-- client Forever 1.60.1.70707 (exports CSV de wago.tools dans tools/routebuilder/data/).
--
-- Repère : sur une carte, x (0-100) croît vers le -Y du monde et y (0-100) vers le -X du monde.
-- Bornes : UiMapAssignment.Region_0..5 = min X, min Y, min Z, max X, max Y, max Z (yards), lignes
-- OrderIndex 0 avec UiMin = 0 et UiMax = 1 (la carte entière couvre la zone).

local world = {}

world.FLIGHT_SPEED = 32      -- yards par seconde en vol
world.FLIGHT_OVERHEAD = 20   -- secondes de décollage + atterrissage par vol
world.FLIGHT_DETOUR = 1.2    -- TaxiPath ne donne pas les points de passage : longueur = ligne droite × 1.2

-- Analyse CSV (champs entre guillemets possibles, virgules incluses).
local function parseLine(line)
  local out, i, n = {}, 1, #line
  while i <= n + 1 do
    local c = line:sub(i, i)
    if c == '"' then
      local buf, j = {}, i + 1
      while j <= n do
        local d = line:sub(j, j)
        if d == '"' then
          if line:sub(j + 1, j + 1) == '"' then buf[#buf + 1] = '"'; j = j + 2
          else j = j + 1; break end
        else buf[#buf + 1] = d; j = j + 1 end
      end
      out[#out + 1] = table.concat(buf)
      i = j + 1 -- saute la virgule
    else
      local j = line:find(",", i, true) or (n + 1)
      out[#out + 1] = line:sub(i, j - 1)
      i = j + 1
    end
  end
  return out
end

function world.readCSV(path)
  local f = assert(io.open(path, "rb"), "cannot open " .. path)
  local text = f:read("*a"); f:close()
  local rows, header = {}, nil
  for line in text:gmatch("[^\r\n]+") do
    local cells = parseLine(line)
    if not header then header = cells
    else
      local row = {}
      for k, name in ipairs(header) do row[name] = cells[k] end
      rows[#rows + 1] = row
    end
  end
  return rows
end

local function num(v) return tonumber(v) or 0 end

-- Charge les tables DB2 (CSV) de dataDir et construit l'objet monde.
function world.load(dataDir)
  local maps, nodes, paths = {}, {}, {}
  -- Cartes : nom, parent, type
  for _, r in ipairs(world.readCSV(dataDir .. "/UiMap.csv")) do
    local id = num(r.ID)
    maps[id] = { id = id, name = r.Name_lang, parent = num(r.ParentUiMapID), type = num(r.Type) }
  end
  -- Bornes monde
  for _, r in ipairs(world.readCSV(dataDir .. "/UiMapAssignment.csv")) do
    local id = num(r.UiMapID)
    if num(r.OrderIndex) == 0 and num(r.UiMin_0) == 0 and num(r.UiMin_1) == 0
       and num(r.UiMax_0) == 1 and num(r.UiMax_1) == 1 then
      local m = maps[id] or { id = id }
      maps[id] = m
      if not m.continent then
        m.continent = num(r.MapID)
        m.minX, m.minY = num(r.Region_0), num(r.Region_1)
        m.maxX, m.maxY = num(r.Region_3), num(r.Region_4)
        m.areaId = num(r.AreaID)
      end
    end
  end
  -- Nœuds de vol. MountCreatureID_0 = monture Horde, MountCreatureID_1 = monture Alliance.
  local SKIP = { "^Quest Path", "^Transport", "^Generic", "^zzOLD", "^Programmer Isle" }
  for _, r in ipairs(world.readCSV(dataDir .. "/TaxiNodes.csv")) do
    local id, name = num(r.ID), r.Name_lang or ""
    local skip = name == ""
    for _, p in ipairs(SKIP) do if name:find(p) then skip = true end end
    local horde, alliance = num(r.MountCreatureID_0) ~= 0, num(r.MountCreatureID_1) ~= 0
    if not skip and (horde or alliance) then
      nodes[#nodes + 1] = {
        id = id, name = name, continent = num(r.ContinentID), wx = num(r.Pos_0), wy = num(r.Pos_1),
        faction = (horde and alliance) and "Both" or (alliance and "Alliance" or "Horde"),
      }
    end
  end
  for _, r in ipairs(world.readCSV(dataDir .. "/TaxiPath.csv")) do
    paths[#paths + 1] = { num(r.FromTaxiNode), num(r.ToTaxiNode) }
  end
  return world.new(maps, nodes, paths)
end

-- Construit l'objet monde à partir de tables déjà prêtes (utilisé aussi par les tests).
--   maps  = { [uiMapId] = { id, name, continent, minX, minY, maxX, maxY, type } }
--   nodes = { { id, name, continent, wx, wy, faction }, ... } ; paths = { { fromId, toId }, ... }
function world.new(maps, nodes, paths)
  local W = { maps = maps, taxi = { nodes = {}, edges = {} } }
  for _, n in ipairs(nodes) do W.taxi.nodes[n.id] = n end
  for _, p in ipairs(paths) do
    local a, b = W.taxi.nodes[p[1]], W.taxi.nodes[p[2]]
    if a and b and a.continent == b.continent then
      local len = math.sqrt((a.wx - b.wx) ^ 2 + (a.wy - b.wy) ^ 2) * world.FLIGHT_DETOUR
      W.taxi.edges[a.id] = W.taxi.edges[a.id] or {}
      W.taxi.edges[a.id][b.id] = len / world.FLIGHT_SPEED
    end
  end

  function W.toWorld(uiMapId, x, y)
    local m = W.maps[uiMapId]
    if not m or not m.continent or not x or not y then return nil end
    local wy = m.maxY - (x / 100) * (m.maxY - m.minY)
    local wx = m.maxX - (y / 100) * (m.maxX - m.minX)
    return m.continent, wx, wy
  end

  function W.fromWorld(uiMapId, wx, wy)
    local m = W.maps[uiMapId]
    if not m or not m.continent then return nil end
    local x = (m.maxY - wy) / (m.maxY - m.minY) * 100
    local y = (m.maxX - wx) / (m.maxX - m.minX) * 100
    return x, y
  end

  -- Carte de zone (Type 3) du continent qui contient le point monde, la plus petite d'abord.
  function W.mapAt(continent, wx, wy, preferred)
    if preferred then
      local m = W.maps[preferred]
      if m and m.continent == continent and wx >= m.minX and wx <= m.maxX and wy >= m.minY and wy <= m.maxY then
        return preferred
      end
    end
    local best, bestArea
    for id, m in pairs(W.maps) do
      if m.continent == continent and m.type == 3 and wx >= m.minX and wx <= m.maxX and wy >= m.minY and wy <= m.maxY then
        local area = (m.maxX - m.minX) * (m.maxY - m.minY)
        if not best or area < bestArea or (area == bestArea and id < best) then best, bestArea = id, area end
      end
    end
    return best
  end

  function W.dist(m1, x1, y1, m2, x2, y2)
    local c1, a1, b1 = W.toWorld(m1, x1, y1)
    local c2, a2, b2 = W.toWorld(m2, x2, y2)
    if not c1 or not c2 or c1 ~= c2 then return math.huge end
    return math.sqrt((a1 - a2) ^ 2 + (b1 - b2) ^ 2)
  end

  function W.nodeAllowed(node, faction)
    return not faction or node.faction == "Both" or node.faction == faction
  end

  -- Durée de vol entre deux nœuds (Dijkstra). `known` limite les nœuds traversés (nil = tous).
  function W.flightTime(a, b, known)
    if a == b then return 0 end
    if not W.taxi.nodes[a] or not W.taxi.nodes[b] then return nil end
    local distTo, done = { [a] = 0 }, {}
    while true do
      local cur, best
      for id, d in pairs(distTo) do
        if not done[id] and (not best or d < best or (d == best and id < cur)) then cur, best = id, d end
      end
      if not cur then return nil end
      if cur == b then return best + world.FLIGHT_OVERHEAD end
      done[cur] = true
      for nb, cost in pairs(W.taxi.edges[cur] or {}) do
        if not known or known[nb] then
          local nd = best + cost
          if not distTo[nb] or nd < distTo[nb] then distTo[nb] = nd end
        end
      end
    end
  end

  function W.nearestTaxi(continent, wx, wy, faction)
    local best, bestD
    for id, n in pairs(W.taxi.nodes) do
      if n.continent == continent and W.nodeAllowed(n, faction) then
        local d = math.sqrt((n.wx - wx) ^ 2 + (n.wy - wy) ^ 2)
        if not best or d < bestD or (d == bestD and id < best.id) then best, bestD = n, d end
      end
    end
    return best, bestD
  end

  return W
end

return world
