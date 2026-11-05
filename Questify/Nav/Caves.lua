local addonName, Q = ...

-- Grottes (données : Data/Caves.lua ; contour calculé à l'exécution depuis QuestieDB) : par où mener
-- le joueur quand la cible ou le joueur est dans une grotte connue.
--   Caves:Plan(mapId, x, y) -> plan | nil      (x et y en 0-100)
--     plan.stops  points à rejoindre avant la cible, dans l'ordre :
--                 { mapId, x, y, kind = "exit"|"enter", cave } (sortir d'une grotte, puis entrer
--                 dans celle de la cible)
--     plan.direct vrai quand le joueur est dans la grotte de la cible ou à son entrée : un calcul
--                 d'itinéraire n'y sait pas à quel étage est la cible, la flèche directe suffit
--     plan.key    texte qui change avec le plan (déduplication de Nav)
--   nil : aucune grotte en jeu, ou position de la cible inconnue. Position du joueur inconnue : il est
--         supposé dehors (la cible dans une grotte passe quand même par l'entrée).
-- Tout se calcule en coordonnées monde (Q.Maps:WorldPos, yards) : une cible peut venir d'une autre
-- carte que celle des données.
local Caves = {}
Q.Caves = Caves

local VERTEX_MARGIN = 10    -- yards : un point aussi près d'un sommet relevé est dans la grotte
local MOUTH_RADIUS = 15     -- yards autour du point d'entrée : le joueur est à l'entrée
local LEAVE_DISTANCE = 40   -- yards : plus loin que ça de l'entrée et de chaque sommet, il est sorti
Caves.MOUTH_RADIUS = MOUTH_RADIUS

-- État du JOUEUR, indépendant de la cible (le monstre visé change tout le temps) :
--   doorSeen  clé de la grotte dont il a atteint l'entrée (<= MOUTH_RADIUS)
--   entered   clé de la grotte où il est entré : passé par l'entrée puis dans le contour, ou
--             IsIndoors() dans le contour (connexion, pierre de foyer). Il reste « dedans » tant qu'il
--             est dans le contour ou à moins de LEAVE_DISTANCE d'une arête ou de l'entrée ; le seul
--             contour ne suffit pas, il couvre aussi la roche au-dessus de la grotte.
local entered, doorSeen
local function num(v) return type(v) == "number" and v == v end

local function isPoint(p) return type(p) == "table" and num(p[1]) and num(p[2]) end

-- Grotte en coordonnées monde :
--   { continent, entrance = { X, Y }, ring = { { X, Y }, ... } }, ou nil (données
--   invalides, carte ou QuestieDB pas encore prêts : on retentera au prochain appel).
-- `ring` est l'enveloppe élargie de HULL_MARGIN (ou le contour explicite).
local cache = {}

local HULL_MARGIN = 12       -- yards dont le contour calculé est élargi (apparitions en bordure)
local SPAWN_RADIUS = 250     -- yards : une apparition plus loin que ça de l'entrée n'est pas dans la grotte

-- Enveloppe convexe (chaîne monotone d'Andrew) de points { X, Y } : sommets dans l'ordre.
local function hull(pts)
  table.sort(pts, function(a, b)
    if a[1] ~= b[1] then return a[1] < b[1] end
    return a[2] < b[2]
  end)
  local function cross(o, a, b) return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1]) end
  local lower, upper = {}, {}
  for _, p in ipairs(pts) do
    while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], p) <= 0 do lower[#lower] = nil end
    lower[#lower + 1] = p
  end
  for i = #pts, 1, -1 do
    local p = pts[i]
    while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], p) <= 0 do upper[#upper] = nil end
    upper[#upper + 1] = p
  end
  lower[#lower] = nil
  upper[#upper] = nil
  for _, p in ipairs(upper) do lower[#lower + 1] = p end
  return lower
end

-- Points monde des apparitions QuestieDB (PNJ et objets listés) sur la carte de la grotte, à moins
-- de `cave.radius` (défaut SPAWN_RADIUS) yards de l'entrée. nil si QuestieDB est absent.
local function spawnPoints(cave, continent, ex, ey)
  local QDB = Q.QDB
  if not QDB or (QDB.IsAvailable and not QDB:IsAvailable()) then return nil end
  local pts = {}
  local radius = num(cave.radius) and cave.radius or SPAWN_RADIUS
  local function collect(entity)
    local list = entity and entity.spawns and entity.spawns[cave.mapId]
    if type(list) ~= "table" then return end
    for _, p in ipairs(list) do
      if isPoint(p) then
        local c, X, Y = Q.Maps:WorldPos(cave.mapId, p[1], p[2])
        if c == continent and math.sqrt((X - ex) ^ 2 + (Y - ey) ^ 2) <= radius then
          pts[#pts + 1] = { X, Y }
        end
      end
    end
  end
  for _, id in ipairs(cave.npcs or {}) do collect(QDB:Npc(id)) end
  for _, id in ipairs(cave.objects or {}) do collect(QDB:Object(id)) end
  return pts
end

-- Contour élargi : chaque sommet repoussé de `margin` yards à l'opposé du centre.
local function grow(core, margin)
  local cx, cy = 0, 0
  for _, p in ipairs(core) do cx, cy = cx + p[1], cy + p[2] end
  cx, cy = cx / #core, cy / #core
  local out = {}
  for i, p in ipairs(core) do
    local dx, dy = p[1] - cx, p[2] - cy
    local d = math.sqrt(dx * dx + dy * dy)
    if d == 0 then out[i] = { p[1], p[2] } else out[i] = { p[1] + dx / d * margin, p[2] + dy / d * margin } end
  end
  return out
end

local function worldOf(cave)
  local w = cache[cave]
  if w then return w end
  if type(cave) ~= "table" or not num(cave.mapId) or not isPoint(cave.entrance) then return nil end
  local c, ex, ey = Q.Maps:WorldPos(cave.mapId, cave.entrance[1], cave.entrance[2])
  if not c then return nil end
  local ring
  if type(cave.inside) == "table" then
    -- contour explicite (repli : tests, grotte sans PNJ)
    if #cave.inside < 3 then return nil end
    ring = {}
    for i, p in ipairs(cave.inside) do
      if not isPoint(p) then return nil end
      local c2, X, Y = Q.Maps:WorldPos(cave.mapId, p[1], p[2])
      if c2 ~= c then return nil end
      ring[i] = { X, Y }
    end
  else
    local pts = spawnPoints(cave, c, ex, ey)
    if not pts then return nil end
    pts[#pts + 1] = { ex, ey }
    local core = hull(pts)
    if #core < 3 then return nil end
    ring = grow(core, HULL_MARGIN)
  end
  -- direction entrée -> centre du contour : sépare le devant de l'entrée du côté de la grotte
  local cx, cy = 0, 0
  for _, p in ipairs(ring) do cx, cy = cx + p[1], cy + p[2] end
  cx, cy = cx / #ring - ex, cy / #ring - ey
  local l = math.sqrt(cx * cx + cy * cy)
  if l == 0 then return nil end
  w = { continent = c, entrance = { ex, ey }, ring = ring, dir = { cx / l, cy / l } }
  cache[cave] = w
  return w
end

local function dist(p, X, Y)
  local dx, dy = p[1] - X, p[2] - Y
  return math.sqrt(dx * dx + dy * dy)
end

local function inPoly(poly, X, Y)
  local hit, j = false, #poly
  for i = 1, #poly do
    local xi, yi, xj, yj = poly[i][1], poly[i][2], poly[j][1], poly[j][2]
    if (yi > Y) ~= (yj > Y) and X < (xj - xi) * (Y - yi) / (yj - yi) + xi then hit = not hit end
    j = i
  end
  return hit
end

-- Dans le contour élargi (règle pair-impair), ou tout près d'un de ses sommets.
local function contains(w, X, Y)
  if inPoly(w.ring, X, Y) then return true end
  for _, v in ipairs(w.ring) do
    if dist(v, X, Y) <= VERTEX_MARGIN then return true end
  end
  return false
end

-- Yards au-delà de l'entrée, vers le cœur de la grotte (négatif : devant l'entrée, dehors).
local function depth(w, X, Y)
  return (X - w.entrance[1]) * w.dir[1] + (Y - w.entrance[2]) * w.dir[2]
end

-- Une cible est « dans la grotte » dans le contour, mais pas devant l'entrée : le sommet d'entrée est
-- élargi de HULL_MARGIN, donc un point à moins de MOUTH_RADIUS + HULL_MARGIN de l'entrée n'en est
-- que si c'est du côté de la grotte (derrière l'entrée) et hors du rayon de l'entrée.
local function targetInside(w, X, Y)
  local d = dist(w.entrance, X, Y)
  if d <= MOUTH_RADIUS or not contains(w, X, Y) then return false end
  return d > MOUTH_RADIUS + HULL_MARGIN or depth(w, X, Y) > 0
end

-- Distance d'un point au segment [a, b].
local function segDist(a, b, X, Y)
  local dx, dy = b[1] - a[1], b[2] - a[2]
  local l2 = dx * dx + dy * dy
  local u = l2 > 0 and ((X - a[1]) * dx + (Y - a[2]) * dy) / l2 or 0
  if u < 0 then u = 0 elseif u > 1 then u = 1 end
  return dist({ a[1] + u * dx, a[2] + u * dy }, X, Y)
end

-- Encore autour de la grotte : dans le contour, ou à moins de LEAVE_DISTANCE d'une arête ou de l'entrée.
local function nearCave(w, X, Y)
  if dist(w.entrance, X, Y) <= LEAVE_DISTANCE or inPoly(w.ring, X, Y) then return true end
  local ring, j = w.ring, #w.ring
  for i = 1, #ring do
    if segDist(ring[j], ring[i], X, Y) <= LEAVE_DISTANCE then return true end
    j = i
  end
  return false
end

local function indoors()
  if type(IsIndoors) ~= "function" then return false end
  local ok, v = pcall(IsIndoors)
  return ok and v == true
end

-- Où est le joueur par rapport à une grotte : "mouth" (à l'entrée), "inside" ou "outside".
-- À l'entrée : il n'est ni entré ni sorti (la porte compte pour les deux sens) mais il l'a atteinte.
-- Ensuite, dans la grotte (dans le contour, côté grotte, hors du rayon de l'entrée) : entré. Entré, il
-- reste dedans tant qu'il est près de la grotte. Sans être passé par l'entrée : dedans seulement si le
-- jeu le dit (IsIndoors) et qu'il est dans le contour.
local function playerState(cave, w, pc, PX, PY)
  local key = cave.key
  if pc ~= w.continent then
    if entered == key then entered = nil end
    if doorSeen == key then doorSeen = nil end
    return "outside"
  end
  if dist(w.entrance, PX, PY) <= MOUTH_RADIUS then
    if entered == key then entered = nil end
    doorSeen = key
    return "mouth"
  end
  if entered == key then
    if nearCave(w, PX, PY) then return "inside" end
    entered = nil
    if doorSeen == key then doorSeen = nil end
    return "outside"
  end
  -- porte vue : il faut s'enfoncer d'au moins HULL_MARGIN dans l'axe de la grotte (un joueur qui longe
  -- la falaise en passant devant la bouche reste dehors) ; IsIndoors : côté grotte suffit
  local dp = depth(w, PX, PY)
  if inPoly(w.ring, PX, PY) and ((doorSeen == key and dp > HULL_MARGIN) or (dp > 0 and indoors())) then
    entered = key
    return "inside"
  end
  if doorSeen == key and not nearCave(w, PX, PY) then doorSeen = nil end
  return "outside"
end

function Caves:Plan(mapId, x, y)
  local data = Q.CaveData
  if type(data) ~= "table" or #data == 0 then return nil end
  if not (num(mapId) and num(x) and num(y)) then return nil end
  local tc, TX, TY = Q.Maps:WorldPos(mapId, x, y)
  if not tc then return nil end
  -- position du joueur inconnue (instance, carte secrète) : on le suppose dehors, la cible dans une
  -- grotte passe quand même par l'entrée
  local pc, PX, PY
  local pm, px, py = Q.Maps:PlayerPos()
  if pm then pc, PX, PY = Q.Maps:WorldPos(pm, px, py) end

  local targetCave, playerCave, playerAt
  for _, cave in ipairs(data) do
    local w = worldOf(cave)
    if w and w.continent == tc and targetInside(w, TX, TY) then targetCave = cave; break end
  end
  if pc then
    for _, cave in ipairs(data) do
      local w = worldOf(cave)
      if w then
        local st = playerState(cave, w, pc, PX, PY)
        if st ~= "outside" and not playerCave then playerCave, playerAt = cave, st end
      end
    end
  end

  local stops = {}
  if playerCave and playerAt == "inside" and playerCave ~= targetCave then
    stops[#stops + 1] = { mapId = playerCave.mapId, x = playerCave.entrance[1], y = playerCave.entrance[2],
      kind = "exit", cave = playerCave }
  end
  if targetCave and targetCave ~= playerCave then
    stops[#stops + 1] = { mapId = targetCave.mapId, x = targetCave.entrance[1], y = targetCave.entrance[2],
      kind = "enter", cave = targetCave }
  end
  local direct = targetCave ~= nil and targetCave == playerCave
  if #stops == 0 and not direct then return nil end
  local parts = { direct and "direct" or "route" }
  for _, s in ipairs(stops) do parts[#parts + 1] = s.kind .. ":" .. tostring(s.cave.key) end
  return { stops = stops, direct = direct, key = table.concat(parts, ","), cave = targetCave or playerCave }
end

-- Des grottes sont-elles connues ? (Nav : la minuterie ne tourne que dans ce cas.)
function Caves:HasData()
  return type(Q.CaveData) == "table" and #Q.CaveData > 0
end

-- Suit le joueur par rapport aux grottes (passage par l'entrée, entrée, sortie), sans plan : appelé
-- chaque seconde par Nav, y compris quand la cible du moment n'est pas dans une grotte (un monstre
-- devant l'entrée, puis un autre au fond : le passage par l'entrée ne doit pas être perdu).
-- -> true quand l'état « entré » a changé (Nav recalcule alors le plan : arrêt « sortie » à montrer).
function Caves:Track()
  if not self:HasData() then return false end
  local pm, px, py = Q.Maps:PlayerPos()
  if not pm then return false end
  local pc, PX, PY = Q.Maps:WorldPos(pm, px, py)
  if not pc then return false end
  local before = entered
  for _, cave in ipairs(Q.CaveData) do
    -- seules les grottes de la carte du joueur comptent (et pas d'appel client pour les autres cartes)
    -- À vérifier en jeu : dans une grotte, la carte du joueur reste-t-elle celle de la zone (pas de
    -- sous-carte) ? Sinon le passage par l'entrée ne serait vu qu'au calcul du plan.
    local w = cave.mapId == pm and worldOf(cave)
    if w then playerState(cave, w, pc, PX, PY) end
  end
  return entered ~= before
end

-- Clé de la grotte où le joueur est « entré » (état suivi par Track et Plan), sinon nil. Métiers : pas
-- de nouvelle étape chez un maître tant qu'il est dans une grotte.
-- Lecture seule : Track ne tourne qu'avec une cible de navigation ; sans elle l'état peut être resté
-- « entré ». On revérifie donc que le joueur est encore autour de la grotte (hors de l'entrée), sans
-- toucher à l'état (c'est Track qui signale le changement à Nav).
function Caves:PlayerCave()
  if not entered or type(Q.CaveData) ~= "table" then return nil end
  local pm, px, py = Q.Maps:PlayerPos()
  if not pm then return nil end
  local pc, PX, PY = Q.Maps:WorldPos(pm, px, py)
  if not pc then return nil end
  for _, cave in ipairs(Q.CaveData) do
    if cave.key == entered then
      local w = worldOf(cave)
      if w and w.continent == pc and dist(w.entrance, PX, PY) > MOUTH_RADIUS and nearCave(w, PX, PY) then
        return entered
      end
      return nil
    end
  end
  return nil
end

-- Grotte (données) qui contient ce point comme cible (pas devant l'entrée), ou nil (tests, diagnostic).
function Caves:At(mapId, x, y)
  local data = Q.CaveData
  if type(data) ~= "table" then return nil end
  local c, X, Y = Q.Maps:WorldPos(mapId, x, y)
  if not c then return nil end
  for _, cave in ipairs(data) do
    local w = worldOf(cave)
    if w and w.continent == c and targetInside(w, X, Y) then return cave end
  end
  return nil
end

-- Oublie l'état « joueur entré » et les positions calculées (tests, rechargement des données).
function Caves:Reset()
  entered, doorSeen = nil, nil
  cache = {}
end
