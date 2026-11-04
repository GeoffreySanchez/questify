local addonName, Q = ...

-- Cartes : passage AreaID -> uiMapID (données ZoneDB de QuestieDB), position du joueur,
-- distances en yards via les coordonnées monde. Toutes les coordonnées sont en 0-100.
local Maps = {}
Q.Maps = Maps

local sqrt = math.sqrt

---------------------------------------------------------------------------
-- ZoneDB : tables fournies sous forme de chaînes Lua, lues avec loadstring dans un
-- environnement vide, puis mises en cache.
---------------------------------------------------------------------------
local parsed = {}

-- -> table|nil, failed. Une absence de table est mise en cache (fait permanent du fournisseur) ;
-- une erreur de lecture est signalée une fois et n'est pas mise en cache.
local function support(name)
  local cached = parsed[name]
  if cached ~= nil then return cached or nil, false end
  local result, err = false, nil
  local ok, perr = pcall(function()
    if type(LibQuestieDB) ~= "table" or type(LibQuestieDB.Support) ~= "table" then return end
    local zdb = LibQuestieDB.Support.Get("ZoneDB")
    local src = zdb and zdb.private and zdb.private[name]
    if type(src) == "table" then
      result = src
    elseif type(src) == "string" then
      local fn, lerr = loadstring(src, "=ZoneDB." .. name)
      if not fn then err = lerr; return end
      setfenv(fn, {})
      local t = fn()
      if type(t) ~= "table" then err = "ZoneDB." .. name .. " is not a table"; return end
      result = t
    end
  end)
  if not ok then err = perr end
  if err then
    Q:ReportError("QuestieDB ZoneDB." .. name .. ": " .. tostring(err))
    return nil, true
  end
  parsed[name] = result
  return result or nil, false
end

local areaCache = {}

-- -> uiMapId|nil, failed
local function resolve(areaId, depth)
  if depth > 10 then return nil, false end
  local override, f1 = support("areaIdToUiMapIdOverride")
  if override and override[areaId] ~= nil then
    local v = override[areaId]
    if type(v) == "number" and v ~= 0 then return v, f1 end
    return nil, f1  -- 0 = affichage supprimé volontairement
  end
  local base, f2 = support("areaIdToUiMapId")
  local v = base and base[areaId]
  if type(v) == "number" and v ~= 0 then return v, f1 or f2 end
  local subOverride, f3 = support("subZoneToParentZoneOverride")
  local sub, f4 = support("subZoneToParentZone")
  local failed = f1 or f2 or f3 or f4
  local parent = (subOverride and subOverride[areaId]) or (sub and sub[areaId])
  if type(parent) == "number" and parent ~= 0 and parent ~= areaId then
    local m, f5 = resolve(parent, depth + 1)
    return m, failed or f5
  end
  return nil, failed
end

function Maps:AreaToUiMap(areaId)
  if type(areaId) ~= "number" then return nil end
  local c = areaCache[areaId]
  if c ~= nil then return c or nil end
  if not (Q.QDB and Q.QDB:IsAvailable()) then return nil end
  local m, failed = resolve(areaId, 0)
  if not failed then areaCache[areaId] = m or false end
  return m
end

---------------------------------------------------------------------------
-- Position du joueur
---------------------------------------------------------------------------
-- -> uiMapId, x, y (0-100), ou nil (instance, position inconnue ou secrète).
function Maps:PlayerPos()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local map = Maps:PlayerMap()
  if not map then return nil end
  local pos = C_Map.GetPlayerMapPosition(map, "player")
  if Q.Util.IsSecret(pos) or not pos then return nil end
  local x, y
  if pos.GetXY then x, y = pos:GetXY() else x, y = pos.x, pos.y end
  -- IsSecret avant tout test sur les coordonnées
  if Q.Util.IsSecret(x) or Q.Util.IsSecret(y) then return nil end
  if type(x) ~= "number" or type(y) ~= "number" then return nil end
  if x == 0 and y == 0 then return nil end
  return map, x * 100, y * 100
end

-- uiMapID du joueur, ou nil s'il est inconnu ou secret (testé avant toute comparaison).
function Maps:PlayerMap()
  if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
  local map = C_Map.GetBestMapForUnit("player")
  if Q.Util.IsSecret(map) or type(map) ~= "number" then return nil end
  return map
end

---------------------------------------------------------------------------
-- Distances. Attention aux axes du client : GetWorldPosFromMapPos renvoie (X, Y) monde avec X
-- qui croît vers le nord et Y vers l'ouest, alors que x carte croît vers l'est et y vers le sud.
-- La conversion est affine par carte : on l'ajuste une fois à partir de trois points
-- ((0,0), (1,0), (0,1)), ce qui couvre toute orientation des axes, puis on la met en cache.
-- Un échec (données de carte pas encore chargées, instance) n'est gardé que FAIL_RETRY secondes :
-- une carte sans position monde ne coûte plus trois appels à chaque WorldPos, et un échec
-- passager est retenté ensuite.
---------------------------------------------------------------------------
local transforms = {}
local failedUntil = {}    -- [uiMapID] = instant (GetTime) avant lequel on ne retente pas
local FAIL_RETRY = 30
Maps.FAIL_RETRY = FAIL_RETRY

local function clock() return (GetTime and GetTime()) or 0 end

local function makeVector(x, y)
  if CreateVector2D then return CreateVector2D(x, y) end
  return { x = x, y = y, GetXY = function(self) return self.x, self.y end }
end

local function sample(m, x01, y01)
  local cont, pos = C_Map.GetWorldPosFromMapPos(m, makeVector(x01, y01))
  if cont == nil or not pos then return nil end
  local wx, wy
  if pos.GetXY then wx, wy = pos:GetXY() else wx, wy = pos.x, pos.y end
  if type(wx) ~= "number" or type(wy) ~= "number" then return nil end
  return cont, wx, wy
end

local function transform(m)
  local t = transforms[m]
  if t then return t end
  if type(m) ~= "number" or not (C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
  local now = clock()
  local untilT = failedUntil[m]
  if untilT and now < untilT then return nil end
  local ok, c0, ox, oy, c1, ax, ay, c2, bx, by = pcall(function()
    local a, b, c = sample(m, 0, 0)
    if a == nil then return nil end           -- premier point absent : inutile d'appeler les deux autres
    local d, e, f = sample(m, 1, 0)
    local g, h, i = sample(m, 0, 1)
    return a, b, c, d, e, f, g, h, i
  end)
  if not ok then
    failedUntil[m] = now + FAIL_RETRY
    Q:ReportError(c0)
    return nil
  end
  if c0 == nil or c0 ~= c1 or c0 ~= c2 then
    failedUntil[m] = now + FAIL_RETRY
    return nil
  end
  failedUntil[m] = nil
  t = {
    continent = c0,
    ox = ox, oy = oy,              -- monde du coin (0,0)
    xX = ax - ox, xY = ay - oy,    -- variation monde pour x carte de 0 à 1 (vers l'est)
    yX = bx - ox, yY = by - oy,    -- variation monde pour y carte de 0 à 1 (vers le sud)
  }
  transforms[m] = t
  return t
end

-- Coordonnées monde (yards) d'un point de carte en 0-100 : continent, X monde, Y monde
-- (mêmes axes que C_Map.GetWorldPosFromMapPos).
function Maps:WorldPos(m, x, y)
  if type(x) ~= "number" or type(y) ~= "number" then return nil end
  local t = transform(m)
  if not t then return nil end
  local u, v = x / 100, y / 100
  return t.continent, t.ox + u * t.xX + v * t.yX, t.oy + u * t.xY + v * t.yY
end

-- Distance en yards, nil si les points sont sur des continents différents.
function Maps:Distance(m1, x1, y1, m2, x2, y2)
  local c1, ax, ay = self:WorldPos(m1, x1, y1)
  local c2, bx, by = self:WorldPos(m2, x2, y2)
  if not c1 or not c2 or c1 ~= c2 then return nil end
  local dx, dy = ax - bx, ay - by
  return sqrt(dx * dx + dy * dy)
end

-- Distance entre le joueur et un point, nil si inconnue.
function Maps:DistanceFromPlayer(m, x, y)
  local pm, px, py = self:PlayerPos()
  if not pm then return nil end
  return self:Distance(pm, px, py, m, x, y)
end

-- Spawn le plus proche : -> mapId, x, y, yards.
-- Sans spawn sur le continent du joueur : premier spawn (carte du joueur d'abord), yards nil.
function Maps:Nearest(spawnsByMap, fromMap, fromX, fromY)
  if type(spawnsByMap) ~= "table" then return nil end
  local mapIds = {}
  for m in pairs(spawnsByMap) do
    if type(m) == "number" then mapIds[#mapIds + 1] = m end
  end
  table.sort(mapIds, function(a, b)
    if a == fromMap then return b ~= fromMap end
    if b == fromMap then return false end
    return a < b
  end)
  local bestM, bestX, bestY, bestD
  local firstM, firstX, firstY
  for _, m in ipairs(mapIds) do
    for _, p in ipairs(spawnsByMap[m]) do
      local x, y = p[1], p[2]
      if type(x) == "number" and type(y) == "number" then
        if not firstM then firstM, firstX, firstY = m, x, y end
        if fromMap then
          local d = self:Distance(fromMap, fromX, fromY, m, x, y)
          if d and (not bestD or d < bestD) then
            bestM, bestX, bestY, bestD = m, x, y, d
          end
        end
      end
    end
  end
  if bestM then return bestM, bestX, bestY, bestD end
  if firstM then return firstM, firstX, firstY, nil end
  return nil
end

-- Nom de carte lisible (client), sinon "#id".
function Maps:MapName(m)
  if C_Map and C_Map.GetMapInfo and type(m) == "number" then
    local ok, info = pcall(C_Map.GetMapInfo, m)
    if ok and info and type(info.name) == "string" and info.name ~= "" then return info.name end
  end
  return "#" .. tostring(m)
end
