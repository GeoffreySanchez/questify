-- tools/routebuilder/sim.lua : simulation d'un chapitre de route.
--
-- sim.chapter(D, W, plan, state, opts) -> steps, report
--   Choisit les quêtes du chapitre (rendement XP / temps, bonus stratégique), construit les tâches
--   (prendre, faire, rendre) avec leurs contraintes, les ordonne (order.lua), insère les étapes
--   logistiques (fp, sethearth, hearth, fly, level) et simule l'XP. `state` est mis à jour sur place
--   pour que le chapitre suivant reparte de là.

local xpm = require("xp")
local orderm = require("order")
local qdb = require("qdb")
local quality = require("quality")
local transport = require("transport")

local sim = {}

-- Seuils (documentés dans tools/routebuilder/README.md)
sim.CONST = {
  WALK = 7,               -- yards/s à pied
  KILL_TIME = 20,         -- s par mob tué, repos compris
  DEFAULT_KILLS = 8,      -- mobs à tuer quand le texte ne donne pas de nombre
  DEFAULT_ITEMS = 6,      -- objets à looter quand le texte ne donne pas de nombre
  DEFAULT_RATE = 0.5,     -- taux de loot par défaut
  DEFAULT_OBJECTS = 5,    -- objets du monde à utiliser quand le texte ne donne pas de nombre
  OBJECT_TIME = 6,        -- s par objet du monde
  TALK_TIME = 10,         -- s pour un objectif « parler à » / exploration
  QUEST_ACTION = 5,       -- s pour prendre ou rendre une quête
  VENDOR_TIME = 15,       -- s pour acheter un objet chez un marchand
  GRID = 60,              -- yards, grille de regroupement des spawns
  HUB_RADIUS = 120,       -- yards, regroupement des donneurs en hubs
  MERGE_SITES = 150,      -- yards, objectifs d'une même quête fusionnés en une seule tâche
  FAR = 900,              -- yards, objectif trop loin de tout hub
  LOW_RATIO = 0.35,       -- fraction de la médiane des rendements sous laquelle on écarte
  CHAIN_DISCOUNT = 0.7,   -- valeur actualisée des suites d'une chaîne
  FP_RADIUS = 150,        -- yards, passage près d'un maître de vol inconnu
  FP_SAVE = 300,          -- s gagnées plus tard par un point de vol découvert
  SETHEARTH_LEAVE = 800,  -- yards, fin du premier passage à une auberge (lieu de la liaison)
  HEARTH_NEAR = 120,      -- yards, auberge déjà liée : pas de nouvelle liaison si la candidate est aussi près
  HEARTH_INN = 200,       -- yards, auberges candidates à la liaison : à cette distance d'un hub du chapitre
  HEARTH_BUNDLE = 250,    -- yards, tâches ramenées en paquet après un retour par la pierre (autour de l'auberge)
  HEARTH_BINDS = 2,       -- liaisons au plus par chapitre (deuxième liaison quand le hub change)
  HEARTH_CD = 3600,       -- s de recharge de la pierre de foyer
  HEARTH_CAST = 10,       -- s d'incantation
  FLY_RATIO = 0.7,        -- vol retenu s'il coûte moins de 70 % de la marche
  LEVEL_RANGE = 3,        -- niveaux de quête acceptés autour de la tranche du chapitre
  LEVEL_WIDE = 6,         -- niveaux au-dessus de maxLevel acceptés quand la tranche ne suffit pas
  WIDEN_GRIND = 25,       -- mobs à farmer au-delà desquels la tranche est élargie
  GATE_GRIND = 15,        -- mobs à farmer au-delà desquels une prise bloquée par le niveau est sautée
  TRIVIAL_GRIND = 3,      -- mobs de fin de chapitre en dessous desquels on n'écrit pas d'étape `level`
  CARRY_BONUS = 0,        -- s de bonus d'une quête rendue dans un chapitre suivant (aucun : XP comptée)
  LOG_CAP = 20,           -- quêtes dans le journal
  LEVEL_SLACK = 1,        -- niveaux de dépassement tolérés au-delà de maxLevel (budget d'XP)
  FAR_PENALTY = 1e6,      -- coût d'ordonnancement d'un trajet impossible à pied (autre région)
  TRANSIT = 900,          -- s forfaitaires quand aucun trajet n'est connu (ni marche, ni vol, ni liaison)
  FP_DETOUR = 300,        -- yards, détour accepté pour prendre un point de vol inconnu en marchant
  FLY_PENALTY = 30,       -- s ajoutées au choix d'un vol (descendre, remonter, file d'attente)
  HEARTH_PENALTY = 120,   -- s de coût d'opportunité de la pierre (60 min de recharge ; 300 n'était jamais rentable)
  HEARTH_LOAD = 15,       -- s d'écran de chargement / téléportation
  SAFE_QUEST_ABOVE = 1,   -- niveaux : objectifs faits au plus tôt au niveau de la quête - 1 (jamais orange)
  SAFE_GATE_GRIND = 60,   -- mobs à farmer acceptés pour atteindre le niveau « sûr » d'un objectif (au lieu de le sauter)
  SAFE_MOB_ABOVE = 1,     -- niveaux : monstres à tuer (niveau moyen) au plus 1 niveau au-dessus du personnage
  SWEEP_HUB = 40,         -- yards : prises et points de vol faits au premier passage à moins de cette distance
  SWEEP_TURNIN = 60,      -- yards : rendu au passage d'une quête terminée
  SWEEP_AREA = 120,       -- yards : objectifs d'une même zone faits en un seul passage
  ROUTE_MIN = 90,         -- s : en dessous, marche directe sans chercher de vol ni de liaison
  BONUS_CAP = 900,        -- s, plafond du bonus « quête de transport »
}
local C = sim.CONST

------------------------------------------------------------------------------
-- Géométrie
------------------------------------------------------------------------------
local function mkPos(W, m, x, y)
  local c, wx, wy = W.toWorld(m, x, y)
  if not c then return nil end
  return { m = m, x = x, y = y, c = c, wx = wx, wy = wy }
end
sim.mkPos = mkPos

local function yards(a, b)
  if not a or not b or a.c ~= b.c then return math.huge end
  return math.sqrt((a.wx - b.wx) ^ 2 + (a.wy - b.wy) ^ 2)
end
sim.yards = yards

-- Graine du recuit : somme pondérée des octets de l'identifiant du plan (reproductible).
function sim.seedOf(id)
  local h = 7
  for i = 1, #(id or "") do h = (h * 31 + id:byte(i)) % 2147483647 end
  return h
end

-- Région de marche d'une position (transport.lua) ; à défaut, le continent.
local function regionOf(p)
  if p.r == nil then p.r = transport.regionOf(p.m, p.x, p.y) or ("c" .. tostring(p.c)) end
  return p.r
end
sim.regionOf = regionOf

-- Temps de marche ; FAR_PENALTY entre deux régions (autre continent, montagnes, tronc de Teldrassil).
local function walk(a, b)
  local d = yards(a, b)
  if d == math.huge or regionOf(a) ~= regionOf(b) then return C.FAR_PENALTY end
  return d / C.WALK
end
sim.walk = walk

-- Position monde -> position carte (sur la carte donnée).
local function worldToPos(W, m, c, wx, wy)
  local x, y = W.fromWorld(m, wx, wy)
  return { m = m, x = x, y = y, c = c, wx = wx, wy = wy }
end

-- Distance d'un point au segment [a, b] et paramètre de projection (0-1).
local function segDist(p, a, b)
  if p.c ~= a.c or a.c ~= b.c then return math.huge, 0 end
  local vx, vy = b.wx - a.wx, b.wy - a.wy
  local len2 = vx * vx + vy * vy
  local tt = 0
  if len2 > 0 then tt = math.max(0, math.min(1, ((p.wx - a.wx) * vx + (p.wy - a.wy) * vy) / len2)) end
  local px, py = a.wx + vx * tt, a.wy + vy * tt
  return math.sqrt((p.wx - px) ^ 2 + (p.wy - py) ^ 2), tt
end

local function round2(v) return math.floor(v * 100 + 0.5) / 100 end

------------------------------------------------------------------------------
-- Contexte du chapitre
------------------------------------------------------------------------------
local function asSet(list)
  local s = {}
  for _, v in ipairs(list or {}) do s[v] = true end
  return s
end

local function raceBit(race, faction)
  if race == "Skyborne" then
    return faction == "Horde" and qdb.RACE_BITS.SkyborneH or qdb.RACE_BITS.SkyborneA
  end
  return qdb.RACE_BITS[race]
end

local function factionRaces(faction)
  if faction == "Horde" then return { "Orc", "Undead", "Tauren", "Troll", "Skyborne" } end
  return { "Human", "Dwarf", "NightElf", "Gnome", "Skyborne" }
end

local function makeCtx(D, W, plan, state, opts)
  local ctx = { D = D, W = W, plan = plan, state = state, opts = opts or {} }
  ctx.faction = plan.faction
  ctx.letter = plan.faction == "Horde" and "H" or "A"
  ctx.races = plan.races or factionRaces(plan.faction)
  ctx.raceBits = {}
  for _, r in ipairs(ctx.races) do ctx.raceBits[#ctx.raceBits + 1] = { race = r, bit = raceBit(r, plan.faction) } end
  ctx.zoneSet = asSet(plan.zones)
  ctx.endSet = asSet(plan.endZones)
  ctx.bounds = {}
  for m, b in pairs(plan.bounds or {}) do
    ctx.bounds[m] = type(b[1]) == "number" and { b } or b
  end
  local ov = ctx.opts.overrides or {}
  ctx.force = {}
  for q in pairs(plan.force or {}) do ctx.force[q] = true end
  for q in pairs(ov.force or {}) do ctx.force[q] = true end
  ctx.optional = {}
  for q, name in pairs(plan.optional or {}) do ctx.optional[q] = name; ctx.force[q] = true end
  ctx.drop = {}
  for q, r in pairs(plan.drop or {}) do ctx.drop[q] = r end
  for q, r in pairs(ov.drop or {}) do ctx.drop[q] = r end
  ctx.pin = ov.pin or {}
  ctx.dungeonNames = asSet(plan.dungeons)
  ctx.logCap = ctx.opts.logCap or plan.logCap or C.LOG_CAP
  -- cartes des chapitres suivants du parcours (build.lua) : rendus reportés possibles
  if ctx.opts.carryZones then ctx.carrySet = asSet(ctx.opts.carryZones) end
  return ctx
end

-- Le point (carte, x, y) est-il dans la région du chapitre (cartes `zones`, limitées par `bounds`) ?
local function inRegion(ctx, m, x, y)
  if not ctx.zoneSet[m] then return false end
  local rects = ctx.bounds[m]
  if not rects then return true end
  for _, r in ipairs(rects) do
    if x >= r[1] and x <= r[3] and y >= r[2] and y <= r[4] then return true end
  end
  return false
end

local function entitySpawns(D, kind, id)
  local e = (kind == "npc" and D.npcs or D.objects)[id]
  return e and e.spawns or {}
end

-- Spawns d'une entité dans la région (ou, si allowEnd, dans les zones de fin).
local function spawnsIn(ctx, kind, id, allowEnd)
  local out = {}
  local sp = entitySpawns(ctx.D, kind, id)
  for _, m in ipairs(qdb.sortedKeys(sp)) do
    for _, p in ipairs(sp[m]) do
      local inside = inRegion(ctx, m, p[1], p[2])
      if inside or (allowEnd and ctx.endSet[m]) then
        local pos = mkPos(ctx.W, m, p[1], p[2])
        if pos then pos.exit = not inside; out[#out + 1] = pos end
      end
    end
  end
  return out
end

local function nearest(list, ref)
  local best, bd
  for _, p in ipairs(list) do
    local d = ref and yards(p, ref) or 0
    if not best or d < bd then best, bd = p, d end
  end
  return best, bd
end

------------------------------------------------------------------------------
-- Éligibilité
------------------------------------------------------------------------------
local function eligibleRaces(ctx, q)
  local list = {}
  for _, rb in ipairs(ctx.raceBits) do
    if not q.races or q.races == 0 or qdb.hasBit(q.races, rb.bit) then list[#list + 1] = rb.race end
  end
  return list
end

local function simulatedEligible(ctx, q)
  local cb = ctx.state.classBit
  if cb and (q.classes or 0) ~= 0 and not qdb.hasBit(q.classes, cb) then return false end
  local bits = ctx.state.raceBits
  if not bits or bits == 0 or not q.races or q.races == 0 then return true end
  -- le personnage simulé a un seul bit de race
  return qdb.hasBit(q.races, bits)
end

------------------------------------------------------------------------------
-- Nombre d'objectifs, lu dans le texte de la quête (« Kill 6 Rockjaw Troggs and 6 ... »)
------------------------------------------------------------------------------
local STOP = { ["of"] = true, ["the"] = true, ["a"] = true, ["an"] = true, ["and"] = true, ["to"] = true, ["from"] = true }

local function stem(w)
  w = w:lower():gsub("[^%a]", "")
  if #w > 3 then
    if w:sub(-3) == "ies" then w = w:sub(1, -4) .. "y"
    elseif w:sub(-3) == "ves" then w = w:sub(1, -4) .. "f"
    elseif w:sub(-2) == "es" and not w:match("[aeiou]es$") then w = w:sub(1, -3)
    elseif w:sub(-1) == "s" and w:sub(-2) ~= "ss" then w = w:sub(1, -2) end
  end
  return w
end

local function words(text)
  local out = {}
  for w in text:gmatch("[%a']+") do
    local s = stem(w)
    if s ~= "" and not STOP[s] then out[#out + 1] = s end
  end
  return out
end

local function objectiveName(D, o)
  if o.text and o.text ~= "" then return o.text end
  if o.kind == "kill" then return D.npcs[o.id] and D.npcs[o.id].name
  elseif o.kind == "killCredit" then return D.npcs[o.id] and D.npcs[o.id].name
  elseif o.kind == "object" then return D.objects[o.id] and D.objects[o.id].name
  elseif o.kind == "item" then return D.items[o.id] and D.items[o.id].name end
  return nil
end

function sim.parseCounts(D, q)
  local counts = {}
  local text = table.concat(q.objectivesText or {}, " ")
  if text == "" then return counts end
  local nameWords = {}
  for i, o in ipairs(q.objectives.list) do
    local n = objectiveName(D, o)
    nameWords[i] = n and words(n) or {}
  end
  -- chaque nombre est rattaché à l'objectif dont le nom ressemble le plus aux mots qui le suivent
  for num, rest in text:gmatch("(%d+)%s+([^%d]*)") do
    local n = tonumber(num)
    if n and n >= 1 and n <= 40 then
      local follow = words(rest)
      local window = {}
      for k = 1, math.min(#follow, 8) do window[follow[k]] = true end
      local best, bestScore = nil, 0
      for i, nw in ipairs(nameWords) do
        if not counts[i] then
          local score = 0
          for _, w in ipairs(nw) do if window[w] then score = score + 1 end end
          if score > bestScore then best, bestScore = i, score end
        end
      end
      if best then counts[best] = n end
    end
  end
  return counts
end

------------------------------------------------------------------------------
-- Sites d'objectif
------------------------------------------------------------------------------
-- Regroupe des points pondérés sur une grille de 60 yd ; renvoie le centre de la fenêtre 3 × 3
-- la plus lourde (égalité : la plus proche de ref), sa dispersion et les points retenus.
local function bestCluster(ctx, points, ref, nearRef)
  if #points == 0 then return nil end
  local cells = {}
  for _, p in ipairs(points) do
    local cx, cy = math.floor(p.wx / C.GRID), math.floor(p.wy / C.GRID)
    local key = p.c .. ":" .. cx .. ":" .. cy
    local cell = cells[key]
    if not cell then cell = { c = p.c, cx = cx, cy = cy, pts = {} }; cells[key] = cell end
    table.insert(cell.pts, p)
  end
  local keys = qdb.sortedKeys(cells)
  local best, bestW, bestD, bestPts
  local windows = {}
  for _, key in ipairs(keys) do
    local cell = cells[key]
    local pts, w = {}, 0
    for dx = -1, 1 do
      for dy = -1, 1 do
        local nb = cells[cell.c .. ":" .. (cell.cx + dx) .. ":" .. (cell.cy + dy)]
        if nb then for _, p in ipairs(nb.pts) do pts[#pts + 1] = p; w = w + p.w end end
      end
    end
    local sx, sy, sw = 0, 0, 0
    for _, p in ipairs(pts) do sx = sx + p.wx * p.w; sy = sy + p.wy * p.w; sw = sw + p.w end
    local center = { c = cell.c, wx = sx / sw, wy = sy / sw }
    local d = ref and yards(center, ref) or 0
    windows[#windows + 1] = { center = center, w = w, d = d, pts = pts }
    if not best or w > bestW + 1e-9 or (math.abs(w - bestW) <= 1e-9 and d < bestD) then
      best, bestW, bestD, bestPts = center, w, d, pts
    end
  end
  if nearRef and ref then
    -- objectif secondaire : la fenêtre la plus proche de ref parmi celles d'au moins 50 % du poids max
    local maxW = bestW
    for _, win in ipairs(windows) do
      if win.w >= 0.5 * maxW and win.d < bestD - 1e-9 then best, bestW, bestD, bestPts = win.center, win.w, win.d, win.pts end
    end
  end
  -- carte d'affichage : celle du point retenu le plus fréquent
  local mapCount, mapBest = {}, nil
  for _, p in ipairs(bestPts) do
    mapCount[p.m] = (mapCount[p.m] or 0) + 1
    if not mapBest or mapCount[p.m] > mapCount[mapBest] or (mapCount[p.m] == mapCount[mapBest] and p.m < mapBest) then mapBest = p.m end
  end
  local pos = worldToPos(ctx.W, mapBest, best.c, best.wx, best.wy)
  local spread = 0
  for _, p in ipairs(bestPts) do spread = spread + yards(p, pos) end
  spread = spread / #bestPts
  return pos, spread, bestPts, bestW
end

local function pointsOf(ctx, kind, id, w)
  local pts = {}
  for _, p in ipairs(spawnsIn(ctx, kind, id, false)) do p.w = w or 1; pts[#pts + 1] = p end
  return pts
end

-- PNJ amical à qui l'on parle (objectif « parler à ») plutôt qu'un mob à tuer. Le champ
-- friendlyToFaction vaut aussi "AH" pour des bêtes neutres : on exige en plus un rôle de PNJ.
local function isTalkTarget(ctx, npcId)
  local n = ctx.D.npcs[npcId]
  local f = n and n.friendly
  if not f or not f:find(ctx.letter, 1, true) then return false end
  if f == ctx.letter then return true end
  return (n.npcFlags or 0) > 0 or #(n.questStarts or {}) > 0 or #(n.questEnds or {}) > 0 or n.subName ~= nil
end

-- Clé d'un coffre : objet « <Nom>'s Chest » (Box, Strongbox, Footlocker...) ouvert par l'objet
-- « <Nom>'s Key » qui tombe de PNJ (QuestieDB n'a pas les serrures : rapprochement par les noms).
-- Renvoie { item = id, name = nom, npcs = {ids} } ou nil.
local CONTAINERS = { Chest = true, Box = true, Strongbox = true, Footlocker = true, Coffer = true, Lockbox = true,
                     Trunk = true, Cache = true, Crate = true, Safe = true }
function sim.keyFor(D, objId)
  local o = D.objects[objId]
  local owner, kind = (o and o.name or ""):match("^(.-)'s%s+(%a+)$")
  if not owner or not CONTAINERS[kind] then return nil end
  if not D._itemByName then
    D._itemByName = {}
    for _, id in ipairs(qdb.sortedKeys(D.items)) do
      local it = D.items[id]
      if it.name and not D._itemByName[it.name] then D._itemByName[it.name] = id end
    end
  end
  local keyId = D._itemByName[owner .. "'s Key"]
  local key = keyId and D.items[keyId]
  if not key or #(key.npcDrops or {}) == 0 then return nil end
  return { item = keyId, name = key.name, npcs = key.npcDrops }
end

local function npcLevel(D, id)
  local n = D.npcs[id]
  if not n then return 1 end
  return math.floor(((n.minLevel or 1) + (n.maxLevel or n.minLevel or 1)) / 2)
end

local function totalSpawns(D, kind, id)
  local n = 0
  for _, list in pairs(entitySpawns(D, kind, id)) do n = n + #list end
  return n
end

-- Calcule un site par objectif : { pos, dur, kills = { {level, n} }, objs = {entrée}, spread }
local function objectiveSite(ctx, q, o, count, ref, warnings, nearRef)
  local D = ctx.D
  local pin = ctx.pin[q.id]
  if o.kind == "kill" or o.kind == "killCredit" then
    local ids = o.kind == "kill" and { o.id } or (#(o.npcIds or {}) > 0 and o.npcIds or { o.id })
    local pts = {}
    for _, id in ipairs(ids) do for _, p in ipairs(pointsOf(ctx, "npc", id)) do pts[#pts + 1] = p end end
    local pos, spread = bestCluster(ctx, pts, ref, nearRef)
    if not pos then return nil, "objective npc not in zone" end
    if isTalkTarget(ctx, o.id or ids[1]) then
      return { pos = pos, dur = C.TALK_TIME, kills = {}, objs = { o }, talk = true }
    end
    local single = (totalSpawns(D, "npc", ids[1]) <= 3) or ((D.npcs[ids[1]] or {}).rank or 0) >= 1
    local n = count or (single and 1 or C.DEFAULT_KILLS)
    return { pos = pos, dur = n * C.KILL_TIME, kills = { { npcLevel(D, ids[1]), n } }, objs = { o }, spread = spread,
             single = single or nil }
  elseif o.kind == "object" then
    local pos, spread, pts = bestCluster(ctx, pointsOf(ctx, "object", o.id), ref, nearRef)
    if not pos then return nil, "objective object not in zone" end
    local n = count or math.min(C.DEFAULT_OBJECTS, #pts)
    return { pos = pos, dur = n * C.OBJECT_TIME + n * spread / C.WALK, kills = {}, objs = { o }, spread = spread }
  elseif o.kind == "item" then
    local it = D.items[o.id]
    if not it then return nil, "objective item unknown" end
    local pts = {}
    for _, npcId in ipairs(it.npcDrops) do
      if not isTalkTarget(ctx, npcId) then
        local rate = (D.drops[o.id] and D.drops[o.id][npcId]) or C.DEFAULT_RATE
        if rate >= 0.02 then
          for _, p in ipairs(pointsOf(ctx, "npc", npcId, rate)) do p.npc = npcId; p.rate = rate; pts[#pts + 1] = p end
        end
      end
    end
    for _, objId in ipairs(it.objectDrops) do
      for _, p in ipairs(pointsOf(ctx, "object", objId, 1)) do p.obj = objId; pts[#pts + 1] = p end
    end
    local pos, spread, chosen = bestCluster(ctx, pts, ref, nearRef)
    if not pos then
      -- marchand dans la zone
      for _, v in ipairs(it.vendors) do
        local vp = nearest(spawnsIn(ctx, "npc", v, false), ref)
        if vp then return { pos = vp, dur = C.VENDOR_TIME, kills = {}, objs = { o }, vendor = v } end
      end
      return nil, "objective item source not in zone"
    end
    -- part des sources mobs / objets dans la fenêtre retenue
    local rateSum, nMob, nObj, mobLevelSum, uniqueMob = 0, 0, 0, 0, nil
    for _, p in ipairs(chosen) do
      if p.npc then
        rateSum = rateSum + p.rate; nMob = nMob + 1; mobLevelSum = mobLevelSum + npcLevel(D, p.npc)
        uniqueMob = uniqueMob == nil and p.npc or (uniqueMob == p.npc and p.npc or false)
      else nObj = nObj + 1 end
    end
    if nMob >= nObj then
      local rate = rateSum / nMob
      local single = uniqueMob and (totalSpawns(D, "npc", uniqueMob) <= 3 or ((D.npcs[uniqueMob] or {}).rank or 0) >= 1)
      local n = count or (single and 1 or C.DEFAULT_ITEMS)
      local kills = single and n or math.ceil(n / rate)
      return { pos = pos, dur = kills * C.KILL_TIME, kills = { { math.floor(mobLevelSum / nMob), kills } },
               objs = { o }, spread = spread, rate = rate, single = single or nil }
    end
    local n = count or (nObj <= 2 and 1 or C.DEFAULT_ITEMS)
    return { pos = pos, dur = n * C.OBJECT_TIME + n * spread / C.WALK, kills = {}, objs = { o }, spread = spread }
  elseif o.kind == "event" then
    local te = q.triggerEnd
    local pts = {}
    for _, m in ipairs(qdb.sortedKeys(te and te.spawns or {})) do
      for _, p in ipairs(te.spawns[m]) do
        if inRegion(ctx, m, p[1], p[2]) then
          local pp = mkPos(ctx.W, m, p[1], p[2])
          if pp then pp.w = 1; pts[#pts + 1] = pp end
        end
      end
    end
    local pos = nearest(pts, ref)
    if not pos then return nil, "exploration point not in zone" end
    return { pos = pos, dur = C.TALK_TIME, kills = {}, objs = { o } }
  elseif o.kind == "spell" then
    local pts = {}
    for _, x in ipairs(q.extraObjectives or {}) do
      for _, m in ipairs(qdb.sortedKeys(x.spawns)) do
        for _, p in ipairs(x.spawns[m]) do
          if inRegion(ctx, m, p[1], p[2]) then
            local pp = mkPos(ctx.W, m, p[1], p[2]); if pp then pp.w = 1; pts[#pts + 1] = pp end
          end
        end
      end
    end
    local pos = bestCluster(ctx, pts, ref)
    if not pos and not pin then
      warnings[#warnings + 1] = ("quest %d %s: spell objective without position, placed at the starter"):format(q.id, q.name)
      pos = ref
    end
    return { pos = pos, dur = 30, kills = {}, objs = { o } }
  elseif o.kind == "reputation" then
    return nil, "reputation objective"
  end
  return nil, "unknown objective"
end

------------------------------------------------------------------------------
-- Analyse d'une quête candidate
------------------------------------------------------------------------------
local function isDungeonQuest(ctx, q)
  local z = q.zoneOrSort or 0
  return z > 0 and ctx.D.dungeonAreas[z] or nil
end

-- Catégories de quêtes (zoneOrSort négatif) d'évènements saisonniers ou temporaires : jamais dans la
-- route (Fête des lanternes, Sanssaint, invasion du Fléau, champs de bataille...). Valeurs de
-- QuestieDB/src/corrections/enum/quests.lua (sortKeys).
sim.EVENT_SORTS = {
  [-404] = true, [-402] = true, [-378] = true, [-376] = true, [-375] = true, [-374] = true, [-370] = true,
  [-369] = true, [-366] = true, [-364] = true, [-41] = true, [-22] = true, [-21] = true, [-368] = true,
  [-365] = true, [-241] = true, [-25] = true, [-662] = true, [-644] = true,
}

-- Renvoie info ou nil, raison (raison nil = ignorée sans la signaler).
local function analyse(ctx, q)
  local D, plan, state = ctx.D, ctx.plan, ctx.state
  local forced = ctx.force[q.id]
  if state.done[q.id] then return nil end
  local races = eligibleRaces(ctx, q)
  if #races == 0 then return nil end
  -- départ : PNJ / objet dans la région, ou objet qui tombe de mobs de la région
  local starters, itemStart = {}, nil
  for _, id in ipairs(q.starters.npcs) do for _, p in ipairs(spawnsIn(ctx, "npc", id, false)) do starters[#starters + 1] = p end end
  for _, id in ipairs(q.starters.objects) do for _, p in ipairs(spawnsIn(ctx, "object", id, false)) do starters[#starters + 1] = p end end
  if #starters == 0 then
    for _, itemId in ipairs(q.starters.items) do
      local it = D.items[itemId]
      if it then
        local pts = {}
        for _, npcId in ipairs(it.npcDrops) do
          local rate = (D.drops[itemId] and D.drops[itemId][npcId]) or 0.2
          for _, p in ipairs(pointsOf(ctx, "npc", npcId, rate)) do p.npc = npcId; p.rate = rate; pts[#pts + 1] = p end
        end
        for _, objId in ipairs(it.objectDrops) do
          for _, p in ipairs(pointsOf(ctx, "object", objId, 1)) do p.rate = 1; pts[#pts + 1] = p end
        end
        local pos, _, chosen = bestCluster(ctx, pts, plan.entry and mkPos(ctx.W, plan.entry[1], plan.entry[2], plan.entry[3]))
        if pos then
          local rate, lvl = 0, 0
          for _, p in ipairs(chosen) do rate = rate + p.rate; lvl = lvl + (p.npc and npcLevel(D, p.npc) or 0) end
          itemStart = { item = itemId, pos = pos, rate = rate / #chosen, level = math.floor(lvl / #chosen) }
          -- objet de départ dans un coffre fermé à clé : la clé tombe d'un PNJ à tuer avant
          for _, p in ipairs(chosen) do
            if not p.npc then
              for _, objId in ipairs(it.objectDrops) do
                local key = sim.keyFor(D, objId)
                if key then itemStart.key, itemStart.container = key, D.objects[objId].name; break end
              end
              break
            end
          end
          break
        end
      end
    end
  end
  if #starters == 0 and not itemStart then return nil end

  -- La quête démarre dans la région : chaque exclusion est signalée dans le rapport (spec § 7.8).
  if qdb.isClassQuest(q) then return nil, "class quest (ClassQuestData.lua)" end
  if q.blacklisted and not forced then return nil, "Questie blacklist" end
  if sim.EVENT_SORTS[q.zoneOrSort or 0] and not forced then return nil, "seasonal or event quest" end
  -- tranche de niveaux
  if not forced then
    if q.level <= 0 or q.level < plan.minLevel - (plan.levelBelow or C.LEVEL_RANGE) then return nil, ("quest level %d below the band"):format(q.level) end
    local high = ctx.opts.levelHigh or C.LEVEL_RANGE
    if plan.dungeonLevelHigh and isDungeonQuest(ctx, q) then high = math.max(high, plan.dungeonLevelHigh) end
    if q.level > plan.maxLevel + high then return nil, ("quest level %d above the band"):format(q.level) end
    local reqMax = plan.maxLevel
    if isDungeonQuest(ctx, q) then reqMax = reqMax + (plan.dungeonReqSlack or 0) end
    if (q.reqLevel or 0) > reqMax then return nil, ("required level %d above the band"):format(q.reqLevel) end
  end
  -- filtres de données et de règles
  local dungeon = isDungeonQuest(ctx, q)
  if dungeon and not ctx.dungeonNames[dungeon] and not ctx.optional[q.id] then
    return nil, ("dungeon quest (%s not picked up in this chapter)"):format(dungeon)
  end
  if q.requiredSkill then return nil, "requires a profession" end
  if q.requiredSpell or q.requiredSpecialization then return nil, "requires a spell or specialization" end
  local sf = q.specialFlags or 0
  if qdb.hasBit(sf, 1) and not forced then return nil, "repeatable" end
  if qdb.hasBit(sf, 2) and not q.triggerEnd and not forced then return nil, "event" end
  if q.requiredMinRep and not forced then return nil, "requires reputation" end
  if q.requiredMaxLevel and q.requiredMaxLevel < state.level then return nil, "maximum level exceeded" end
  if ctx.drop[q.id] then return nil, ctx.drop[q.id] end
  if ctx.opts.preDrop and ctx.opts.preDrop[q.id] then return nil, ctx.opts.preDrop[q.id] end
  if q.next and state.done[q.next] then return nil, "follow-up already done" end

  local info = { q = q, races = races, itemStart = itemStart, forced = forced, optional = ctx.optional[q.id] }
  if (q.classes or 0) ~= 0 then info.classes = qdb.classList(q.classes) end
  -- quête chronométrée (« within 15 minutes », « before it gets cold in five minutes ») : faite d'une traite
  info.timed = table.concat(q.objectivesText or {}, " "):lower():find("minute", 1, true) ~= nil
  local entry = plan.entry and mkPos(ctx.W, plan.entry[1], plan.entry[2], plan.entry[3]) or nil
  if itemStart then info.A = itemStart.pos else info.A = nearest(starters, entry) end

  -- quête de donjon : on ne fait que la prendre au passage (optional), l'objectif est dans l'instance
  if dungeon then
    info.dungeonOnly = ctx.optional[q.id] or dungeon
    info.optional = nil
    return info
  end

  -- rendu : dans la région, ou dans les zones de fin
  local finishers = {}
  for _, id in ipairs(q.finishers.npcs) do for _, p in ipairs(spawnsIn(ctx, "npc", id, true)) do finishers[#finishers + 1] = p end end
  for _, id in ipairs(q.finishers.objects) do for _, p in ipairs(spawnsIn(ctx, "object", id, true)) do finishers[#finishers + 1] = p end end
  if #finishers == 0 and ctx.carrySet and not info.timed then
    -- rendu dans un des chapitres suivants du parcours : prise et objectifs ici, rendu plus tard
    for _, id in ipairs(q.finishers.npcs) do
      for m in pairs(entitySpawns(D, "npc", id)) do if ctx.carrySet[m] then info.carry = m end end
    end
    for _, id in ipairs(q.finishers.objects) do
      for m in pairs(entitySpawns(D, "object", id)) do if ctx.carrySet[m] then info.carry = m end end
    end
  end
  if #finishers == 0 and not info.carry then
    local anywhere = false
    for _, id in ipairs(q.finishers.npcs) do if next(entitySpawns(D, "npc", id)) then anywhere = true end end
    for _, id in ipairs(q.finishers.objects) do if next(entitySpawns(D, "object", id)) then anywhere = true end end
    if not anywhere then return nil, "finisher unknown (no spawn)" end
    return nil, "finisher outside the chapter zones"
  end
  -- on préfère un rendu dans la région à un rendu en zone de fin
  local inside = {}
  for _, p in ipairs(finishers) do if not p.exit then inside[#inside + 1] = p end end

  -- objectifs
  local counts = sim.parseCounts(D, q)
  local sites, warnings = {}, ctx.warnings
  local ref = info.A
  for i, o in ipairs(q.objectives.list) do
    -- les objectifs suivants se placent près du premier site trouvé (zone commune)
    local site, err = objectiveSite(ctx, q, o, counts[i], sites[1] and sites[1].pos or ref, warnings, sites[1] ~= nil)
    if not site then
      if not ctx.pin[q.id] then return nil, err end
    else
      site.count = counts[i]
      sites[#sites + 1] = site
    end
  end
  if ctx.pin[q.id] then
    local p = ctx.pin[q.id]
    local pos = mkPos(ctx.W, p[1], p[2], p[3])
    if pos then
      local dur, kills = 0, {}
      for _, s in ipairs(sites) do dur = dur + s.dur; for _, k in ipairs(s.kills) do kills[#kills + 1] = k end end
      sites = { { pos = pos, dur = math.max(dur, C.TALK_TIME), kills = kills, objs = q.objectives.list } }
    end
  end
  -- fusion des sites proches (même quête) en une seule tâche
  local groups = {}
  for _, s in ipairs(sites) do
    local merged = false
    for _, g in ipairs(groups) do
      if yards(g.pos, s.pos) <= C.MERGE_SITES then
        g.dur = g.dur + s.dur + yards(g.pos, s.pos) / C.WALK
        for _, k in ipairs(s.kills) do g.kills[#g.kills + 1] = k end
        for _, o in ipairs(s.objs) do g.objs[#g.objs + 1] = o end
        merged = true
        break
      end
    end
    if not merged then
      groups[#groups + 1] = { pos = s.pos, dur = s.dur, kills = { unpack(s.kills) }, objs = { unpack(s.objs) },
                              spread = s.spread or 0 }
    end
  end
  info.sites = groups
  if info.carry then return info end
  local last = groups[#groups] and groups[#groups].pos or info.A
  info.T = nearest(#inside > 0 and inside or finishers, last)
  info.exit = info.T.exit
  return info
end

------------------------------------------------------------------------------
-- Hubs
------------------------------------------------------------------------------
local function buildHubs(infos)
  local pts = {}
  for _, info in ipairs(infos) do
    if info.A and not info.itemStart then pts[#pts + 1] = { pos = info.A, q = info.q.id, kind = "A" } end
    if info.T and not info.exit then pts[#pts + 1] = { pos = info.T, q = info.q.id, kind = "T" } end
  end
  local hubs = {}
  for _, p in ipairs(pts) do
    local hub
    for _, h in ipairs(hubs) do
      for _, m in ipairs(h.members) do
        if yards(m.pos, p.pos) <= C.HUB_RADIUS then hub = h; break end
      end
      if hub then break end
    end
    if not hub then hub = { members = {}, quests = {} }; hubs[#hubs + 1] = hub end
    table.insert(hub.members, p)
    hub.quests[p.q] = true
  end
  local out = {}
  for _, h in ipairs(hubs) do
    local n = 0
    for _ in pairs(h.quests) do n = n + 1 end
    h.nQuests = n
    h.count = #h.members
    local sx, sy = 0, 0
    for _, m in ipairs(h.members) do sx = sx + m.pos.wx; sy = sy + m.pos.wy end
    local ref = h.members[1].pos
    h.pos = { m = ref.m, c = ref.c, wx = sx / #h.members, wy = sy / #h.members, r = regionOf(ref) }
    h.rep = ref
  end
  for _, h in ipairs(hubs) do if h.nQuests >= 2 then out[#out + 1] = h end end
  if #out == 0 then out = hubs end
  return out
end

local function nearestHub(hubs, pos)
  local best, bd
  for _, h in ipairs(hubs) do
    local d = yards(h.pos, pos)
    if not best or d < bd then best, bd = h, d end
  end
  return best, bd or math.huge
end

------------------------------------------------------------------------------
-- Valeur et temps isolé
------------------------------------------------------------------------------
local function killXP(level, kills)
  local total = 0
  for _, k in ipairs(kills) do total = total + xpm.mobXP(level, k[1]) * k[2] end
  return total
end

local function isolated(info, hubs)
  local t = 0
  local hs = nearestHub(hubs, info.A)
  local pos = hs and hs.pos or info.A
  t = t + walk(pos, info.A) + C.QUEST_ACTION
  if info.itemStart then t = t + (1 / math.max(info.itemStart.rate, 0.05)) * C.KILL_TIME end
  pos = info.A
  for _, s in ipairs(info.sites or {}) do
    t = t + walk(pos, s.pos) + s.dur
    pos = s.pos
  end
  if info.T then
    t = t + walk(pos, info.T) + C.QUEST_ACTION
    if not info.exit then
      local ht = nearestHub(hubs, info.T)
      if ht then t = t + walk(info.T, ht.pos) end
    end
  end
  return t
end

local function median(list)
  local s = {}
  for _, v in ipairs(list) do s[#s + 1] = v end
  table.sort(s)
  local n = #s
  if n == 0 then return 0 end
  if n % 2 == 1 then return s[(n + 1) / 2] end
  return (s[n / 2] + s[n / 2 + 1]) / 2
end

------------------------------------------------------------------------------
-- Chapitre
------------------------------------------------------------------------------
-- Copie d'un état (tables du premier niveau copiées) et restauration en place.
local function snapshot(st)
  local o = {}
  for k, v in pairs(st) do
    if type(v) == "table" then local t = {}; for a, b in pairs(v) do t[a] = b end; o[k] = t else o[k] = v end
  end
  return o
end
local function restore(st, snap)
  for k in pairs(st) do st[k] = nil end
  for k, v in pairs(snapshot(snap)) do st[k] = v end
end

function sim.chapter(D, W, plan, state, opts)
  opts = opts or {}
  -- Si les quêtes de la tranche ne suffisent pas à atteindre le niveau visé, le chapitre est refait
  -- en acceptant des quêtes plus hautes (LEVEL_WIDE niveaux au-dessus de maxLevel) plutôt que de farmer.
  if not opts.levelHigh and not opts._noWiden then
    local snap = snapshot(state)
    local o2 = {}
    for k, v in pairs(opts) do o2[k] = v end
    o2._noWiden = true
    local steps, report = sim.chapter(D, W, plan, state, o2)
    local widened
    if (report.grindMobs or 0) > C.WIDEN_GRIND then
      restore(state, snap)
      o2.levelHigh = C.LEVEL_WIDE
      widened = ("grinding %d mobs with quests up to level %d: band widened to level %d"):format(
        report.grindMobs, plan.maxLevel + C.LEVEL_RANGE, plan.maxLevel + C.LEVEL_WIDE)
      steps, report = sim.chapter(D, W, plan, state, o2)
    end
    -- Quêtes sautées faute de niveau : écartées d'emblée et chapitre refait, pour que le budget d'XP
    -- garde d'autres quêtes à leur place (au plus 2 fois).
    for _ = 1, 2 do
      if not next(report.levelSkipped or {}) or (report.grindMobs or 0) <= C.TRIVIAL_GRIND then break end
      o2.preDrop = o2.preDrop or {}
      for id, why in pairs(report.levelSkipped) do o2.preDrop[id] = why end
      restore(state, snap)
      steps, report = sim.chapter(D, W, plan, state, o2)
    end
    report.widened = widened
    return steps, report
  end
  state.done = state.done or {}
  state.log = state.log or {}
  state.knownTaxi = state.knownTaxi or {}
  state.time = state.time or 0
  state.hearthReadyAt = state.hearthReadyAt or 0
  state.level = state.level or 1
  state.xp = state.xp or 0
  local ctx = makeCtx(D, W, plan, state, opts)
  ctx.warnings = {}
  local report = { planId = plan.id, quests = {}, dropped = {}, warnings = ctx.warnings, startLevel = state.level }
  local startTime, startLevel, startXP = state.time, state.level, state.xp

  local entryPos = plan.entry and mkPos(W, plan.entry[1], plan.entry[2], plan.entry[3])
  local cur = state.pos and mkPos(W, state.pos[1], state.pos[2], state.pos[3]) or entryPos
  local steps = {}

  -- arrivée dans le chapitre (bateau, tram, vol...) quand on vient d'un autre continent ou de loin :
  -- étapes `arrive` du plan si elles existent, sinon trajet calculé (sim.route) jusqu'au point d'entrée.
  -- arrive.via = { mapId, x, y } : trajet calculé jusqu'à ce point (quai), puis les étapes fixes.
  if plan.arrive and cur and entryPos and (cur.c ~= entryPos.c or yards(cur, entryPos) > 1500) then
    local via = plan.arrive.via and mkPos(W, plan.arrive.via[1], plan.arrive.via[2], plan.arrive.via[3])
    if via then cur = sim.travel(ctx, steps, cur, via, sim.flightMasters(ctx)) end
    for _, s in ipairs(plan.arrive.steps or {}) do
      local step = {}
      for k, v in pairs(s) do step[k] = v end
      -- vol écrit à la main : nœud de destination retrouvé par son nom (TaxiNodes)
      if step[1] == "fly" and not step.node and step.note then
        for _, id in ipairs(qdb.sortedKeys(W.taxi.nodes)) do
          if W.taxi.nodes[id].name == step.note then step.node = id; break end
        end
        if not step.node then
          ctx.warnings[#ctx.warnings + 1] = ("arrive: no flight node named %q"):format(step.note)
        end
      end
      steps[#steps + 1] = step
    end
    state.time = state.time + (plan.arrive.time or 300)
    cur = entryPos
  elseif cur and entryPos and regionOf(cur) ~= regionOf(entryPos) then
    cur = sim.travel(ctx, steps, cur, entryPos, sim.flightMasters(ctx))
  end
  cur = cur or entryPos

  -- 1. Candidats
  local infos, byId = {}, {}
  for _, id in ipairs(qdb.sortedKeys(D.quests)) do
    local q = D.quests[id]
    if not state.log[id] then
      local info, reason = analyse(ctx, q)
      if info then
        infos[#infos + 1] = info; byId[id] = info
      elseif reason then
        report.dropped[#report.dropped + 1] = { id, reason, id = id, reason = reason }
        if D.newQuests and D.newQuests[id] and reason:find("finisher unknown", 1, true) then
          ctx.warnings[#ctx.warnings + 1] = ("new Forever quest %d %s: no finisher spawn"):format(id, q.name)
        end
      end
    end
  end

  -- 2. Pré-requis réalisables (point fixe)
  local function dropInfo(info, reason)
    if info.dropped then return end
    info.dropped = reason
    report.dropped[#report.dropped + 1] = { info.q.id, reason, id = info.q.id, reason = reason }
  end
  -- quêtes du journal (chapitre précédent) rendues dans ce chapitre : leur rendu débloque leurs suites
  -- (ex. 967 The Tower of Althalaxx, faite à Sombrivage et rendue en Orneval, ouvre 970)
  local turnedInHere = {}
  for _, id in ipairs(qdb.sortedKeys(state.log)) do
    local q = D.quests[id]
    if q and state.log[id] ~= "dungeon" then
      local found = false
      for _, n in ipairs(q.finishers.npcs) do if #spawnsIn(ctx, "npc", n, true) > 0 then found = true end end
      for _, n in ipairs(q.finishers.objects) do if #spawnsIn(ctx, "object", n, true) > 0 then found = true end end
      turnedInHere[id] = found or nil
    end
  end
  local function have(p)
    return state.done[p] or turnedInHere[p] or (byId[p] and not byId[p].dropped and not byId[p].carry)
  end
  local function prereqOk(info)
    local q = info.q
    if #q.preSingle > 0 then
      local ok = false
      for _, p in ipairs(q.preSingle) do
        if have(p) then ok = true end
      end
      if not ok then return false end
    end
    -- (une quête rendue dans un chapitre suivant ne débloque rien dans celui-ci)
    for _, p in ipairs(q.preGroup) do
      if not have(p) then return false end
    end
    for _, x in ipairs(q.exclusiveTo) do if state.done[x] or state.log[x] then return false end end
    return true
  end
  local changed = true
  while changed do
    changed = false
    for _, info in ipairs(infos) do
      if not info.dropped and not prereqOk(info) then dropInfo(info, "prerequisite unavailable"); changed = true end
    end
  end

  -- 3. Hubs, valeurs, rendements
  local live = {}
  for _, info in ipairs(infos) do if not info.dropped and not info.dungeonOnly then live[#live + 1] = info end end
  local hubs = buildHubs(live)
  local fms = sim.flightMasters(ctx)
  local raw = {}
  for _, info in ipairs(live) do
    local q = info.q
    local kills = {}
    for _, s in ipairs(info.sites or {}) do for _, k in ipairs(s.kills) do kills[#kills + 1] = k end end
    if info.itemStart then kills[#kills + 1] = { info.itemStart.level, math.ceil(1 / math.max(info.itemStart.rate, 0.05)) } end
    info.kills = kills
    info.value = xpm.questXP(D, q, state.level) + killXP(state.level, kills)
    info.time = isolated(info, hubs)
    info.isolatedTime = info.time
    raw[#raw + 1] = info.value / math.max(info.time, 1)
  end
  local baseRate = median(raw)
  report.baseRate = baseRate
  -- Temps marginal : un point (départ par objet, site d'objectif, rendu) proche d'un lieu que la
  -- route visite de toute façon (hub, ou site d'une quête au rendement isolé >= médiane) ne coûte
  -- qu'un aller-retour jusqu'à ce lieu. temps retenu = min(temps isolé, temps marginal).
  -- Un site de mobs couvre une aire : son rayon (1,5 × dispersion moyenne) est déjà parcouru.
  local anchors = {}
  for _, h in ipairs(hubs) do anchors[#anchors + 1] = { pos = h.pos, r = 0 } end
  for k, info in ipairs(live) do
    if raw[k] >= baseRate then
      for _, s in ipairs(info.sites or {}) do
        anchors[#anchors + 1] = { pos = s.pos, q = info.q.id, r = 1.5 * (s.spread or 0) }
      end
    end
  end
  for _, info in ipairs(live) do
    local function detour(p)
      local best = math.huge
      for _, a in ipairs(anchors) do
        if a.q ~= info.q.id then
          local d = math.max(0, yards(a.pos, p) - a.r)
          if d < best then best = d end
        end
      end
      return best == math.huge and 0 or 2 * best / C.WALK
    end
    local m = 2 * C.QUEST_ACTION
    if info.itemStart then m = m + (1 / math.max(info.itemStart.rate, 0.05)) * C.KILL_TIME end
    m = m + detour(info.A)
    for _, s in ipairs(info.sites or {}) do m = m + s.dur + detour(s.pos) end
    if info.T and not info.exit then m = m + detour(info.T) end
    info.isolatedTime = info.time
    info.marginalTime = math.min(m, info.time)
  end
  for _, info in ipairs(live) do
    local q = info.q
    local bonusSec = 0
    if (q.breadcrumbFor or info.exit) and info.T then bonusSec = bonusSec + math.min(walk(info.A, info.T), C.BONUS_CAP) end
    if info.carry then bonusSec = bonusSec + C.CARRY_BONUS end
    -- mène près d'un maître de vol inconnu
    for _, fm in ipairs(fms) do
      if not state.knownTaxi[fm.node] then
        local near = info.T and yards(info.T, fm.pos) <= C.FP_RADIUS
        for _, s in ipairs(info.sites or {}) do if yards(s.pos, fm.pos) <= C.FP_RADIUS then near = true end end
        if near then bonusSec = bonusSec + C.FP_SAVE; break end
      end
    end
    info.bonus = bonusSec * baseRate
    info.value = info.value + info.bonus
  end
  -- chaînes : valeur et temps actualisés des suites
  local children = {}
  for _, info in ipairs(live) do
    local q = info.q
    local list = {}
    local seen = {}
    local function add(id)
      if byId[id] and not byId[id].dropped and not byId[id].dungeonOnly and not seen[id] and id ~= q.id then
        seen[id] = true; list[#list + 1] = byId[id]
      end
    end
    for _, c in ipairs(D.unlocks and D.unlocks[q.id] or {}) do add(c) end
    if q.next then add(q.next) end
    if q.breadcrumbFor then add(q.breadcrumbFor) end
    children[q.id] = list
  end
  local function chainWith(field)
    local memo = {}
    local function chain(info, depth)
      local id = info.q.id
      if memo[id] then return memo[id][1], memo[id][2] end
      local v, t = info.value, info[field]
      if depth < 8 then
        for _, c in ipairs(children[id]) do
          local cv, ct = chain(c, depth + 1)
          v = v + C.CHAIN_DISCOUNT * cv
          t = t + C.CHAIN_DISCOUNT * ct
        end
      end
      memo[id] = { v, t }
      return v, t
    end
    return chain
  end
  local chainIso, chainMarg = chainWith("isolatedTime"), chainWith("marginalTime")
  local ratios = {}
  for _, info in ipairs(live) do
    local v, t = chainIso(info, 0)
    local _, tm = chainMarg(info, 0)
    info.chainValue, info.chainTime = v, t
    info.ratio = v / math.max(t, 1)
    info.marginalRatio = v / math.max(tm, 1)
    ratios[#ratios + 1] = info.ratio
  end
  local med = median(ratios)
  report.medianRatio = med

  -- 4. Écarts : trop loin, rendement trop faible, puis dépendances
  for _, info in ipairs(live) do
    if not info.forced then
      local far = false
      local targets = {}
      for _, s in ipairs(info.sites or {}) do targets[#targets + 1] = s.pos end
      if #targets == 0 and info.T and not info.exit then targets[1] = info.T end
      for _, p in ipairs(targets) do
        local _, d = nearestHub(hubs, p)
        if d > (plan.far or C.FAR) then far = true end
      end
      -- écartée si le rendement isolé ET le rendement marginal sont sous 0.35 × la médiane
      if far then dropInfo(info, "far")
      elseif info.ratio < C.LOW_RATIO * med and info.marginalRatio < C.LOW_RATIO * med then
        dropInfo(info, "low ratio")
      end
    end
  end
  changed = true
  while changed do
    changed = false
    for _, info in ipairs(infos) do
      if not info.dropped and not prereqOk(info) then dropInfo(info, "prerequisite dropped"); changed = true end
    end
  end
  -- Budget d'XP : au-delà de maxLevel + levelSlack, les quêtes au plus faible rendement marginal sont
  -- laissées (« level band reached ») ; les quêtes forcées ou optionnelles comptent d'abord.
  do
    local slack = plan.levelSlack or C.LEVEL_SLACK
    local target = math.min(plan.maxLevel + slack, xpm.MAX_LEVEL)
    local need = -state.xp
    for l = state.level, math.floor(target) - 1 do need = need + (xpm.LEVEL_XP[l] or 0) end
    local frac = target - math.floor(target)
    if frac > 0 then need = need + frac * (xpm.LEVEL_XP[math.floor(target)] or 0) end
    local order = {}
    for _, info in ipairs(live) do if not info.dropped then order[#order + 1] = info end end
    table.sort(order, function(a, b)
      local fa, fb = (a.forced or a.optional) and 1 or 0, (b.forced or b.optional) and 1 or 0
      if fa ~= fb then return fa > fb end
      -- rang : rendement marginal (ce que l'on gagne vraiment à garder la quête sur la route)
      if a.marginalRatio ~= b.marginalRatio then return a.marginalRatio > b.marginalRatio end
      return a.q.id < b.q.id
    end)
    -- garder une quête garde aussi ses pré-requis (comptés dans le budget)
    local acc, kept
    local function keep(info, depth)
      if kept[info.q.id] or depth > 200 then return end
      kept[info.q.id] = true
      acc = acc + (info.value - (info.bonus or 0))
      local q = info.q
      for _, p in ipairs(q.preGroup) do
        if byId[p] and not byId[p].dropped then keep(byId[p], depth + 1) end
      end
      if #q.preSingle > 0 then
        local done = false
        for _, p in ipairs(q.preSingle) do if state.done[p] or kept[p] then done = true end end
        if not done then
          for _, p in ipairs(q.preSingle) do
            if byId[p] and not byId[p].dropped then keep(byId[p], depth + 1); break end
          end
        end
      end
    end
    -- XP des quêtes gardées qui restent faisables (pré-requis gardés eux aussi, rendus dans ce chapitre)
    local inOrder = {}
    for _, info in ipairs(order) do inOrder[info.q.id] = true end
    local function survivingXP()
      local alive = {}
      for id in pairs(kept) do alive[id] = true end
      -- pré-requis hors budget (déjà dans le journal, ou candidat non soumis au budget) : acquis
      local function have(p)
        if state.done[p] or state.log[p] then return true end
        local b = byId[p]
        if not b or b.carry then return false end
        if not inOrder[p] then return not b.dropped end
        return alive[p] == true
      end
      local again = true
      while again do
        again = false
        for _, info in ipairs(order) do
          local q = info.q
          if alive[q.id] then
            local ok = true
            for _, p in ipairs(q.preGroup) do if not have(p) then ok = false end end
            if ok and #q.preSingle > 0 then
              ok = false
              for _, p in ipairs(q.preSingle) do if have(p) then ok = true end end
            end
            if not ok then alive[q.id] = nil; again = true end
          end
        end
      end
      local x = 0
      for _, info in ipairs(order) do if alive[info.q.id] then x = x + (info.value - (info.bonus or 0)) end end
      return x
    end
    -- Le budget est relevé tant que des quêtes gardées tombent faute de pré-requis (au plus 6 fois),
    -- sinon le chapitre finirait sous son niveau visé avec des quêtes laissées de côté.
    local extra = 0
    for _ = 1, 6 do
      acc, kept = 0, {}
      for _, info in ipairs(order) do
        if acc < need + extra or info.forced or info.optional then keep(info, 0) end
      end
      local alive = survivingXP()
      if alive >= need or acc < need + extra then break end
      extra = extra + (need - alive)
    end
    for _, info in ipairs(order) do
      if not kept[info.q.id] then dropInfo(info, "level band reached") end
    end
    report.xpBudget = need
  end
  changed = true
  while changed do
    changed = false
    for _, info in ipairs(infos) do
      if not info.dropped and not prereqOk(info) then dropInfo(info, "prerequisite dropped"); changed = true end
    end
  end
  -- quêtes exclusives : on garde le meilleur rendement
  for _, info in ipairs(live) do
    if not info.dropped then
      for _, x in ipairs(info.q.exclusiveTo) do
        local other = byId[x]
        if other and not other.dropped and other ~= info then
          if (other.ratio or 0) > (info.ratio or 0) or ((other.ratio or 0) == (info.ratio or 0) and other.q.id < info.q.id) then
            dropInfo(info, "exclusive with " .. x)
          else
            dropInfo(other, "exclusive with " .. info.q.id)
          end
        end
      end
    end
  end

  -- table de diagnostic pour le rapport
  report.candidates = {}
  for _, info in ipairs(live) do
    report.candidates[#report.candidates + 1] = {
      id = info.q.id, name = info.q.name, level = info.q.level, value = info.value, bonus = info.bonus,
      isolatedTime = info.isolatedTime, marginalTime = info.marginalTime, ratio = info.ratio,
      marginalRatio = info.marginalRatio, dropped = info.dropped, sites = #(info.sites or {}),
    }
  end

  -- 5. Tâches
  local tasks, taskOf = {}, {}
  local function addTask(t)
    tasks[#tasks + 1] = t
    taskOf[t.id] = t
    return t
  end
  local selected = {}
  for _, info in ipairs(infos) do if not info.dropped then selected[#selected + 1] = info end end
  for _, info in ipairs(selected) do
    local q = info.q
    if info.timed and not info.dungeonOnly and not info.itemStart then
      -- prise, objectifs et rendu d'une traite : une seule tâche de A à T
      local dur, pos = 2 * C.QUEST_ACTION, info.A
      for _, s in ipairs(info.sites or {}) do dur = dur + walk(pos, s.pos) + s.dur; pos = s.pos end
      dur = dur + walk(pos, info.T)
      local c = addTask({ id = "C" .. q.id, kind = "C", q = q.id, pos = info.A, endPos = info.T, dur = dur,
        info = info, after = {}, final = info.exit or nil })
      taskOf["A" .. q.id], taskOf["T" .. q.id] = c, c
    else
      local a = addTask({ id = "A" .. q.id, kind = "A", q = q.id, pos = info.A, info = info, after = {},
        dur = C.QUEST_ACTION + (info.itemStart and (1 / math.max(info.itemStart.rate, 0.05)) * C.KILL_TIME or 0),
        -- prise par un objet ramassé : tâche de zone d'objectifs (objet d'un coffre : catégorie 1)
        itemStart = info.itemStart and true or nil,
        cat = info.itemStart and (info.itemStart.level == 0 and 1 or 3) or nil })
      if not info.dungeonOnly then
        local prev = { a.id }
        for k, s in ipairs(info.sites or {}) do
          -- ordre dans une zone : objets (1), mobs nommés ou élites (2), mobs ordinaires (3)
          local cat = (#(s.kills or {}) == 0 and not s.talk and not s.vendor) and 1 or (s.single and 2 or 3)
          local o = addTask({ id = "O" .. q.id .. "_" .. k, kind = "O", q = q.id, pos = s.pos, dur = s.dur,
            info = info, site = s, after = { a.id }, cat = cat })
          prev[#prev + 1] = o.id
        end
        if not info.carry then
          addTask({ id = "T" .. q.id, kind = "T", q = q.id, pos = info.T, dur = C.QUEST_ACTION, info = info,
            after = prev, final = info.exit or nil })
        end
      end
    end
  end
  -- quêtes déjà dans le journal (chapitre précédent) qu'on peut rendre ici
  for _, id in ipairs(qdb.sortedKeys(state.log)) do
    local q = D.quests[id]
    if q and state.log[id] ~= "dungeon" then
      local finishers = {}
      for _, n in ipairs(q.finishers.npcs) do for _, p in ipairs(spawnsIn(ctx, "npc", n, true)) do finishers[#finishers + 1] = p end end
      for _, n in ipairs(q.finishers.objects) do for _, p in ipairs(spawnsIn(ctx, "object", n, true)) do finishers[#finishers + 1] = p end end
      local tpos = nearest(finishers, cur)
      if tpos then
        local info = { q = q, races = eligibleRaces(ctx, q), carried = true, T = tpos, exit = tpos.exit, kills = {} }
        addTask({ id = "T" .. id, kind = "T", q = id, pos = tpos, dur = C.QUEST_ACTION, info = info, after = {}, final = tpos.exit or nil })
      end
    end
  end
  -- points de vol imposés par le plan (noms TaxiNodes) : tâches « F » placées par l'ordonnancement
  for _, name in ipairs(plan.flightPaths or {}) do
    local found
    for _, fm in ipairs(fms) do
      local node = W.taxi.nodes[fm.node]
      if node and node.name == name then found = fm end
    end
    if not found then
      ctx.warnings[#ctx.warnings + 1] = ("flight path %q: no flight master found"):format(name)
    elseif not state.knownTaxi[found.node] then
      addTask({ id = "F" .. found.node, kind = "F", pos = found.pos, dur = C.QUEST_ACTION, fm = found, after = {} })
    end
  end
  -- contraintes de chaîne : rendre le pré-requis avant de prendre la suite
  local function addAfter(t, id)
    if not id or id == t.id then return end
    for _, a in ipairs(t.after) do if a == id then return end end
    table.insert(t.after, id)
  end
  local function tId(q) return taskOf["T" .. q] and taskOf["T" .. q].id end
  for _, t in ipairs(tasks) do
    if t.kind == "A" or t.kind == "C" then
      local q = t.info.q
      for _, p in ipairs(q.preGroup) do addAfter(t, tId(p)) end
      for _, p in ipairs(q.preSingle) do
        if tId(p) and not state.done[p] then addAfter(t, tId(p)); break end
      end
      for _, b in ipairs(q.breadcrumbs or {}) do addAfter(t, tId(b)) end
    end
  end
  for _, t in ipairs(tasks) do
    if t.kind == "T" or t.kind == "C" then
      local q = t.info.q
      local nxt = q.next and taskOf["A" .. q.next]
      if nxt and nxt ~= t then addAfter(nxt, t.id) end
    end
  end
  -- coffre fermé à clé : la prise (objet de départ dans le coffre) attend l'objectif d'une autre quête
  -- qui tue le porteur de la clé (ex. 830 « The Admiral's Orders » après Lieutenant Benedict, de 784)
  for _, t in ipairs(tasks) do
    local key = t.kind == "A" and t.info and t.info.itemStart and t.info.itemStart.key
    if key then
      local holder = {}
      for _, n in ipairs(key.npcs) do holder[n] = true end
      for _, o in ipairs(tasks) do
        if (o.kind == "O" or o.kind == "C") and o.q ~= t.q then
          local sites = o.kind == "O" and { o.site } or o.info.sites or {}
          for _, site in ipairs(sites) do
            for _, obj in ipairs(site.objs or {}) do
              local ids = (obj.kind == "kill" and { obj.id }) or obj.npcIds or {}
              for _, n in ipairs(ids) do
                if holder[n] then addAfter(t, o.id); t.info.itemStart.keyTask = o.id end
              end
            end
          end
        end
      end
    end
  end

  -- ordre imposé par le plan : plan.precede = { { "A3376", "O757" }, ... } (la première tâche avant la
  -- seconde ; "O<q>" désigne tous les objectifs de la quête q). Une paire dont une tâche manque est ignorée.
  for _, pair in ipairs(plan.precede or {}) do
    local function resolve(key)
      local out = {}
      if taskOf[key] then out[1] = taskOf[key]; return out end
      for _, t in ipairs(tasks) do
        if t.id:sub(1, #key + 1) == key .. "_" then out[#out + 1] = t end
      end
      return out
    end
    local firsts, seconds = resolve(pair[1]), resolve(pair[2])
    if #firsts == 0 or #seconds == 0 then
      ctx.warnings[#ctx.warnings + 1] = ("precede %s < %s: task not in the chapter"):format(pair[1], pair[2])
    end
    for _, b in ipairs(seconds) do
      for _, a in ipairs(firsts) do if a ~= b then addAfter(b, a.id) end end
    end
  end

  -- 6. Ordonnancement (avec le niveau simulé : une quête n'est prise qu'au niveau requis)
  for _, t in ipairs(tasks) do
    local info = t.info
    if info then
      local q = info.q
      local counted = simulatedEligible(ctx, q)
      if (t.kind == "A" or t.kind == "C") and (q.reqLevel or 0) > 1 then t.reqLevel = q.reqLevel end
      -- Difficulté : les objectifs attendent un niveau « sûr » (quête jaune facile, monstres pas plus
      -- hauts que le personnage) ; l'ordonnancement fait d'abord le plus facile.
      if (t.kind == "C" or t.kind == "O") and C.SAFE_QUEST_ABOVE and C.SAFE_MOB_ABOVE then
        local safe = (q.level or 0) - C.SAFE_QUEST_ABOVE
        local sites = t.kind == "O" and { t.site } or info.sites or {}
        for _, s in ipairs(sites) do
          for _, k in ipairs(s.kills or {}) do safe = math.max(safe, k[1] - C.SAFE_MOB_ABOVE) end
        end
        -- niveau « sûr » donné par le plan (objectif sans danger réel, fait dès la prise)
        if plan.safeLevel and plan.safeLevel[q.id] then safe = plan.safeLevel[q.id] end
        if safe > (t.reqLevel or 1) then t.reqLevel, t.safeLevel = safe, true end
      end
      if counted then
        if t.kind == "O" then
          local kills = t.site.kills
          t.gain = function(level) return killXP(level, kills) end
        elseif t.kind == "T" then
          t.gain = function(level) return xpm.questXP(D, q, level) end
        elseif t.kind == "C" then
          local kills = {}
          for _, s in ipairs(info.sites or {}) do for _, k in ipairs(s.kills) do kills[#kills + 1] = k end end
          t.gain = function(level) return killXP(level, kills) + xpm.questXP(D, q, level) end
        elseif t.kind == "A" and info.itemStart then
          local lvl, n = info.itemStart.level, math.ceil(1 / math.max(info.itemStart.rate, 0.05))
          t.gain = function(level) return xpm.mobXP(level, lvl) * n end
        end
      end
    end
  end
  local initialLog = 0
  for _ in pairs(state.log) do initialLog = initialLog + 1 end
  initialLog = initialLog + (state.logPad or 0) -- journal plus chargé sur un autre parcours de race (tronc)
  local finish = plan.exit and mkPos(W, plan.exit[1], plan.exit[2], plan.exit[3]) or nil
  -- plan.strictLevel : le farm avant une tâche bloquée par le niveau (needLevel) compte dans le coût de
  -- l'ordonnancement (mobs du niveau du personnage, KILL_TIME chacun, comme sim.grindTo) ; sinon
  -- or-opt et recuit la déplacent librement, au risque de la faire 2 à 4 niveaux trop tôt.
  local grindCost
  if plan.strictLevel then
    grindCost = function(level, xp, target)
      local sec, l, x = 0, level, xp
      while l < target and xpm.LEVEL_XP[l] do
        sec = sec + math.max(xpm.LEVEL_XP[l] - x, 0) / math.max(xpm.mobXP(l, l), 1) * C.KILL_TIME
        l, x = l + 1, 0
      end
      return sec
    end
  end
  local ordered, orderIssues = orderm.build(tasks, cur, walk, { logCap = ctx.logCap, initialLog = initialLog, finish = finish,
    levelXP = xpm.LEVEL_XP, level = state.level, xp = state.xp, maxSegment = 6, grindCost = grindCost,
    -- ROUTEBUILDER_NO_SWEEP=1 : sans balayage (comparaison avant / après dans les rapports)
    sweep = not os.getenv("ROUTEBUILDER_NO_SWEEP")
      and { hub = C.SWEEP_HUB / C.WALK, turnin = C.SWEEP_TURNIN / C.WALK, area = C.SWEEP_AREA / C.WALK } or nil,
    anneal = ctx.opts.anneal ~= false, seed = sim.seedOf(plan.id), T0 = 200, annealIters = 100 * #tasks * #tasks, annealMax = 1500000 })
  for _, msg in ipairs(orderIssues or {}) do ctx.warnings[#ctx.warnings + 1] = "ordering: " .. msg end
  -- contraintes de l'ordonnancement, pour expliquer les éléments du contrôle qualité
  local orderIds = {}
  for _, t in ipairs(tasks) do orderIds[t.id] = true end
  local orderOpts = { logCap = ctx.logCap, initialLog = initialLog, ids = orderIds, levelXP = xpm.LEVEL_XP,
                      level = state.level, xp = state.xp }

  -- 7. Pierre de foyer : liaisons (au plus HEARTH_BINDS) choisies sur le coût réel du trajet avec la
  -- pierre, puis retours en paquet (tâches de l'auberge ramenées après un retour par la pierre)
  local hearthBinds
  ordered, hearthBinds = sim.planHearth(ctx, ordered, hubs, cur, finish, {
    logCap = ctx.logCap, initialLog = initialLog, ids = orderIds, levelXP = xpm.LEVEL_XP,
    level = state.level, xp = state.xp, grindCost = grindCost and function(l, x, target)
      return math.floor(grindCost(l, x, target) * 100 + 0.5) end or nil })
  report.hearthPlan = hearthBinds.summary

  -- 8. Marche de la route : logistique + XP
  local lastSite
  local multiSite = {}
  for _, t in ipairs(ordered) do
    if t.kind == "O" then multiSite[t.q] = (multiSite[t.q] or 0) + 1 end
  end
  local seenO = {}
  report.legs = {}
  -- Quêtes sautées pendant la marche : prise qui demanderait de farmer plus de GATE_GRIND mobs pour
  -- atteindre son niveau requis, et ses suites (le farm de fin de chapitre compense, s'il le faut).
  local skipQ = {}
  local function mobsTo(target, pos)
    local g = sim.grindSite(ctx, pos, state.level)
    local mobLevel = g and g.level or state.level
    local lvl, x, n = state.level, state.xp, 0
    while lvl < target and n < 2000 do
      x = x + math.max(xpm.mobXP(lvl, math.max(mobLevel, xpm.grayLevel(lvl) + 1, lvl - 1)), 1)
      while xpm.LEVEL_XP[lvl] and x >= xpm.LEVEL_XP[lvl] do x = x - xpm.LEVEL_XP[lvl]; lvl = lvl + 1 end
      n = n + 1
    end
    return n
  end
  local carryBind -- liaison d'une tâche sautée : faite à la tâche suivante
  for _, t in ipairs(ordered) do repeat
    if t.q and skipQ[t.q] then carryBind = carryBind or hearthBinds[t.id]; break end
    if (t.kind == "A" or t.kind == "C" or t.kind == "O") and t.info and not t.info.carried then
      local q = t.info.q
      local skip
      for _, p in ipairs(q.preGroup) do if skipQ[p] then skip = "prerequisite skipped" end end
      if #q.preSingle > 0 then
        local any = false
        for _, p in ipairs(q.preSingle) do if not skipQ[p] then any = true end end
        if not any then skip = "prerequisite skipped" end
      end
      -- seulement une quête qui n'ouvre aucune autre quête du chapitre (sinon on farme : chaîne de zone)
      local opensMore = false
      for _, c in ipairs(D.unlocks and D.unlocks[q.id] or {}) do
        if byId[c] and not byId[c].dropped then opensMore = true end
      end
      if q.next and byId[q.next] and not byId[q.next].dropped then opensMore = true end
      if not skip and t.safeLevel and t.reqLevel and state.level < t.reqLevel then
        -- niveau « sûr » trop loin : la quête est faite quand même (jamais sautée pour ça)
        t.unsafe = mobsTo(t.reqLevel, cur) > C.SAFE_GATE_GRIND
      elseif not skip and not opensMore and t.reqLevel and state.level < t.reqLevel then
        local n = mobsTo(t.reqLevel, cur)
        if n > C.GATE_GRIND then
          skip = ("required level %d not reached in time (~%d mobs to farm)"):format(t.reqLevel, n)
        end
      end
      if skip then
        skipQ[q.id] = true
        report.dropped[#report.dropped + 1] = { q.id, skip, id = q.id, reason = skip }
        report.levelSkipped = report.levelSkipped or {}
        report.levelSkipped[q.id] = skip
        carryBind = carryBind or hearthBinds[t.id]
        break
      end
    end
    -- itinéraire du rapport : tâche, position, distance depuis la tâche précédente (même région)
    local from = cur
    local legYards = (from and regionOf(from) == regionOf(t.pos)) and yards(from, t.pos) or nil
    local logNow = state.logPad or 0
    for _ in pairs(state.log) do logNow = logNow + 1 end
    report.legs[#report.legs + 1] = { kind = t.kind, q = t.q, pos = t.pos, yards = legYards,
      name = t.info and t.info.q and t.info.q.name or (t.fm and "flight path") or "",
      id = t.id, task = t, level = state.level, log = logNow }
    cur = sim.travel(ctx, steps, cur, t.pos, fms)
    if t.kind == "F" then
      if not state.knownTaxi[t.fm.node] then
        steps[#steps + 1] = { "fp", t.pos.m, round2(t.pos.x), round2(t.pos.y) }
        state.knownTaxi[t.fm.node] = true
        state.time = state.time + t.dur
      end
    else
      local info, q = t.info, t.info.q
      local counted = simulatedEligible(ctx, q)
      local function decorate(step)
        if #info.races < #ctx.races then step.race = info.races end
        if info.classes then step.class = info.classes end
        if info.optional then step.optional = true; step.dungeon = info.optional end
        if info.dungeonOnly then step.optional = true; step.dungeon = info.dungeonOnly end
        step._c = { name = q.name, level = q.level, simLevel = state.level }
        return step
      end
      if (t.kind == "A" or t.kind == "C" or t.kind == "O") and t.reqLevel and state.level < t.reqLevel and not t.unsafe then
        cur = sim.grindTo(ctx, steps, cur, t.reqLevel, fms)
        cur = sim.travel(ctx, steps, cur, t.pos, fms)
      end
      if counted then state.time = state.time + t.dur end
      if t.kind == "A" then
        local step = { "accept", q.id }
        if info.itemStart then
          step.at = { t.pos.m, round2(t.pos.x), round2(t.pos.y) }
          local it = D.items[info.itemStart.item]
          step.note = ("Loot %s to start the quest"):format(it and it.name or ("item " .. info.itemStart.item))
          local key = info.itemStart.key
          if key then
            local holder = D.npcs[key.npcs[1]]
            step.note = ("Open %s with %s (dropped by %s) and loot %s to start the quest"):format(
              info.itemStart.container or "the chest", key.name, holder and holder.name or "a nearby mob",
              it and it.name or ("item " .. info.itemStart.item))
          end
          if counted then for _, k in ipairs(info.kills or {}) do
            if k[1] == info.itemStart.level then for _ = 1, k[2] do xpm.addXP(state, xpm.mobXP(state.level, k[1])) end; break end
          end end
        end
        steps[#steps + 1] = decorate(step)
        state.log[q.id] = info.dungeonOnly and "dungeon" or true
      elseif t.kind == "O" then
        local step = { "complete", q.id, at = { t.pos.m, round2(t.pos.x), round2(t.pos.y) } }
        seenO[q.id] = (seenO[q.id] or 0) + 1
        -- plusieurs sites : objectif précis sauf pour le dernier site parcouru
        -- (un site qui regroupe plusieurs objectifs n'a pas d'obj : l'étape attend la quête entière)
        if multiSite[q.id] > 1 and seenO[q.id] < multiSite[q.id] and #t.site.objs == 1 and t.site.objs[1].index then
          step.obj = t.site.objs[1].index
        end
        steps[#steps + 1] = decorate(step)
        if counted then
          for _, k in ipairs(t.site.kills) do
            for _ = 1, k[2] do xpm.addXP(state, xpm.mobXP(state.level, k[1])) end
          end
        end
        if t.site.kills[1] then lastSite = t.site end
      elseif t.kind == "C" then
        steps[#steps + 1] = decorate({ "accept", q.id, note = "Timed quest: do it right away" })
        for _, s in ipairs(info.sites or {}) do
          steps[#steps + 1] = decorate({ "complete", q.id, at = { s.pos.m, round2(s.pos.x), round2(s.pos.y) } })
          if counted then for _, k in ipairs(s.kills) do for _ = 1, k[2] do xpm.addXP(state, xpm.mobXP(state.level, k[1])) end end end
        end
        -- XP affichée : celle du rendu au niveau simulé, même pour une quête d'une autre race (non comptée)
        local gained = xpm.questXP(D, q, state.level)
        local step = decorate({ "turnin", q.id, xp = gained > 0 and gained or nil })
        step._c.xp = gained
        steps[#steps + 1] = step
        if counted then
          xpm.addXP(state, gained)
          report.quests[#report.quests + 1] = { id = q.id, name = q.name, level = q.level, xp = gained, simLevel = state.level,
          estimated = not (D.xp and D.xp[q.id]) }
        end
        state.done[q.id] = true
        cur = t.endPos
      elseif t.kind == "T" then
        local gained = xpm.questXP(D, q, state.level)
        local step = { "turnin", q.id, xp = gained > 0 and gained or nil }
        decorate(step)
        step._c.xp = gained
        steps[#steps + 1] = step
        if counted then
          xpm.addXP(state, gained)
          report.quests[#report.quests + 1] = { id = q.id, name = q.name, level = q.level, xp = gained, simLevel = state.level,
          estimated = not (D.xp and D.xp[q.id]) }
        end
        state.log[q.id] = nil
        state.done[q.id] = true
      end
    end
    local inn = hearthBinds[t.id] or carryBind
    carryBind = nil
    if inn then
      cur = sim.travel(ctx, steps, cur, inn, fms)
      steps[#steps + 1] = { "sethearth", inn.m, round2(inn.x), round2(inn.y) }
      state.time = state.time + C.QUEST_ACTION
      state.hearth = { inn.m, inn.x, inn.y }
    end
  until true end
  if finish then cur = sim.travel(ctx, steps, cur, finish, fms) end

  -- 9. Niveau manquant : tuer des mobs au dernier site d'objectif
  if state.level < plan.maxLevel then
    local mobLevel = state.level
    if lastSite and lastSite.kills[1] then mobLevel = lastSite.kills[1][1] end
    local grind = sim.grindSite(ctx, cur, state.level)
    if grind then
      cur = sim.travel(ctx, steps, cur, grind.pos, fms)
      lastSite = { pos = grind.pos, kills = { { grind.level, 0 } } }
      mobLevel = grind.level
    end
    local n = 0
    while state.level < plan.maxLevel and n < 2000 do
      local gain = xpm.mobXP(state.level, math.max(mobLevel, xpm.grayLevel(state.level) + 1, state.level - 1))
      xpm.addXP(state, math.max(gain, 1))
      n = n + 1
    end
    state.time = state.time + n * C.KILL_TIME
    local step = { "level", plan.maxLevel }
    -- (quelques mobs seulement : ils seront tués en chemin au début du chapitre suivant, pas d'étape)
    if n <= C.TRIVIAL_GRIND then step = nil end
    if not step then
      -- rien
    elseif grind then
      step.at = { grind.pos.m, round2(grind.pos.x), round2(grind.pos.y) }
      step.note = ("About %d more mobs here (%s, level %d)"):format(n, grind.name, grind.level)
    elseif lastSite then
      step.at = { lastSite.pos.m, round2(lastSite.pos.x), round2(lastSite.pos.y) }
      step.note = ("About %d more mobs near the last objective"):format(n)
    else
      step.note = ("About %d more mobs"):format(n)
    end
    steps[#steps + 1] = step
    ctx.grindMobs = (ctx.grindMobs or 0) + n
  end
  report.grindMobs = ctx.grindMobs

  -- contrôle qualité de l'itinéraire (allers-retours évitables)
  report.quality = quality.check(report.legs, {
    yards = yards, hub = C.SWEEP_HUB, turnin = C.SWEEP_TURNIN, area = C.SWEEP_AREA, logCap = ctx.logCap,
    feasible = function(seq, relax)
      local o = {}
      for k, v in pairs(orderOpts) do o[k] = v end
      if relax == "logCap" then o.logCap = (o.logCap or 20) + 100 end
      if relax == "level" then o.levelXP = nil end
      return orderm.feasible(seq, o)
    end,
  })

  -- fin d'un chapitre de départ qui rejoint le tronc ailleurs (autre région : zeppelin, bateau...)
  if opts.exitTo and cur then
    local dest = mkPos(W, opts.exitTo[1], opts.exitTo[2], opts.exitTo[3])
    if dest and regionOf(cur) ~= regionOf(dest) then cur = sim.travel(ctx, steps, cur, dest, fms) end
  end

  state.pos = { cur.m, cur.x, cur.y }
  local gainedXP = 0
  do
    -- XP totale gagnée depuis le début du chapitre
    local lvl, x = startLevel, startXP
    while lvl < state.level do gainedXP = gainedXP + (xpm.LEVEL_XP[lvl] - x); x = 0; lvl = lvl + 1 end
    gainedXP = gainedXP + state.xp - x
  end
  local elapsed = state.time - startTime
  report.time = elapsed
  report.xp = gainedXP
  report.xpPerHour = elapsed > 0 and gainedXP / elapsed * 3600 or 0
  report.endLevel = xpm.fractional(state)
  report.steps = #steps
  report.hubs = #hubs
  return steps, report
end

------------------------------------------------------------------------------
-- Logistique
------------------------------------------------------------------------------
-- Farm jusqu'au niveau `target` près de la position courante ; ajoute l'étape `level`.
function sim.grindTo(ctx, steps, cur, target, fms)
  local state = ctx.state
  local grind = sim.grindSite(ctx, cur, state.level)
  local mobLevel = grind and grind.level or state.level
  if grind then cur = sim.travel(ctx, steps, cur, grind.pos, fms) end
  local n = 0
  while state.level < target and n < 2000 do
    local gain = xpm.mobXP(state.level, math.max(mobLevel, xpm.grayLevel(state.level) + 1, state.level - 1))
    xpm.addXP(state, math.max(gain, 1))
    n = n + 1
  end
  state.time = state.time + n * C.KILL_TIME
  local step = { "level", target }
  if grind then
    step.at = { grind.pos.m, round2(grind.pos.x), round2(grind.pos.y) }
    step.note = ("About %d mobs here (%s, level %d)"):format(n, grind.name, grind.level)
  else
    step.note = ("About %d mobs"):format(n)
  end
  steps[#steps + 1] = step
  ctx.grindMobs = (ctx.grindMobs or 0) + n
  return cur
end

-- PNJ cible unique d'une quête (« Kill Isha Awak », sans nombre) : un mob nommé, souvent rare ou en
-- patrouille, jamais un lieu de farm. Calculé une fois par jeu de données.
local function uniqueTargets(D)
  if D._uniqueTargets then return D._uniqueTargets end
  local set = {}
  for _, id in ipairs(qdb.sortedKeys(D.quests)) do
    local q = D.quests[id]
    local counts = sim.parseCounts(D, q)
    for i, o in ipairs(q.objectives and q.objectives.list or {}) do
      if o.kind == "kill" and not counts[i] then set[o.id] = true end
      -- objet unique (« Isha Awak's Heart ») lâché par un ou deux PNJ seulement
      local it = o.kind == "item" and not counts[i] and D.items[o.id]
      if it and #it.npcDrops >= 1 and #it.npcDrops <= 2 then
        for _, n in ipairs(it.npcDrops) do set[n] = true end
      end
    end
  end
  D._uniqueTargets = set
  return set
end

-- Lieu de farm : le groupe de mobs hostiles de niveau adapté le plus dense à moins de 600 yd
-- (ni PNJ de quête, ni mob nommé cible unique d'une quête).
function sim.grindSite(ctx, pos, level)
  if not pos then return nil end
  local D = ctx.D
  local unique = uniqueTargets(D)
  local pts = {}
  for _, id in ipairs(qdb.sortedKeys(D.npcs)) do
    local n = D.npcs[id]
    local lvl = npcLevel(D, id)
    if lvl >= level - 1 and lvl <= level + 1 and (n.rank or 0) == 0 and (n.npcFlags or 0) == 0
       and #(n.questStarts or {}) == 0 and #(n.questEnds or {}) == 0
       and not (n.friendly and n.friendly:find(ctx.letter, 1, true)) and not n.subName and not unique[id] then
      local list = n.spawns[pos.m]
      if list and #list >= 3 then
        for _, p in ipairs(list) do
          local pp = mkPos(ctx.W, pos.m, p[1], p[2])
          if pp and yards(pp, pos) <= 600 then pp.w = 1; pp.npc = id; pts[#pts + 1] = pp end
        end
      end
    end
  end
  if #pts < 5 then return nil end
  local site, _, chosen = bestCluster(ctx, pts, pos)
  if not site then return nil end
  -- mob le plus représenté dans la fenêtre
  local count, best = {}, nil
  for _, p in ipairs(chosen) do
    count[p.npc] = (count[p.npc] or 0) + 1
    if not best or count[p.npc] > count[best] or (count[p.npc] == count[best] and p.npc < best) then best = p.npc end
  end
  return { pos = site, level = npcLevel(D, best), name = D.npcs[best].name, npc = best }
end

-- Maîtres de vol de la faction, reliés à leur nœud de vol.
function sim.flightMasters(ctx)
  if ctx._fms then return ctx._fms end
  local out = {}
  for _, id in ipairs(ctx.D.flightMasters or {}) do
    local n = ctx.D.npcs[id]
    if n and n.friendly and n.friendly:find(ctx.letter, 1, true) then
      for _, m in ipairs(qdb.sortedKeys(n.spawns)) do
        local p = n.spawns[m][1]
        local pos = mkPos(ctx.W, m, p[1], p[2])
        if pos then
          local node, d = ctx.W.nearestTaxi(pos.c, pos.wx, pos.wy, ctx.faction)
          if node and d <= 100 then out[#out + 1] = { npc = id, pos = pos, node = node.id } end
          break
        end
      end
    end
  end
  ctx._fms = out
  return out
end

-- Auberges de la faction à moins de HEARTH_INN yards d'un hub du chapitre (une par lieu).
function sim.hearthInns(ctx, hubs)
  local out = {}
  for _, id in ipairs(ctx.D.innkeepers or {}) do
    local n = ctx.D.npcs[id]
    if n and (not n.friendly or n.friendly:find(ctx.letter, 1, true)) then
      for _, m in ipairs(qdb.sortedKeys(n.spawns)) do
        for _, p in ipairs(n.spawns[m]) do
          local pos = mkPos(ctx.W, m, p[1], p[2])
          local near = false
          for _, h in ipairs(pos and hubs or {}) do
            if yards(pos, h.pos) <= C.HEARTH_INN then near = true; break end
          end
          if near then
            for _, o in ipairs(out) do if yards(o, pos) <= C.HEARTH_NEAR then near = false; break end end
          end
          if near then pos.npc = id; out[#out + 1] = pos end
        end
      end
    end
  end
  return out
end

-- Tâche après laquelle la pierre est liée à l'auberge `inn` : premier passage à moins de HEARTH_INN
-- yards à partir de l'indice `from`, puis, tant que la route reste à moins de SETHEARTH_LEAVE yards,
-- la tâche la plus proche de l'aubergiste (détour minimal). Renvoie l'indice ou nil.
local function bindIndex(seq, inn, from)
  local pick, pickD
  for i = from or 1, #seq do
    local t = seq[i]
    local d = yards(t.endPos or t.pos, inn)
    if not pick then
      if d <= C.HEARTH_INN then pick, pickD = i, d end
    else
      if d > C.SETHEARTH_LEAVE then break end
      if d < pickD - 1e-9 then pick, pickD = i, d end
    end
  end
  return pick
end

-- Pierre de foyer du chapitre. Plans comparés sur le coût réel du trajet (order.hearthCost : marche,
-- retours par la pierre avec sa recharge, détours pour la lier) : aucune liaison, une liaison à une
-- auberge proche d'un hub (premier passage), ou deux (la seconde au premier passage à une autre auberge
-- après la première : le hub du chapitre change). Puis retours en paquet (order.hearthBundles) : les
-- tâches faites près de l'auberge sont ramenées juste après un retour par la pierre quand le coût baisse,
-- et le plan est choisi à nouveau. Renvoie la séquence et { [taskId] = auberge } (liaison après la tâche),
-- avec `summary` (texte du rapport).
function sim.planHearth(ctx, ordered, hubs, start, finish, fopts)
  local state = ctx.state
  local function cs(a, b) return math.floor(walk(a, b) * 100 + 0.5) end
  local bound = state.hearth and mkPos(ctx.W, state.hearth[1], state.hearth[2], state.hearth[3])
  local o = { start = start, finish = finish, dist = cs, inn = bound,
    ready = math.floor(((state.hearthReadyAt or 0) - (state.time or 0)) * 100 + 0.5),
    cd = C.HEARTH_CD * 100, use = (C.HEARTH_CAST + C.HEARTH_PENALTY) * 100,
    real = (C.HEARTH_CAST + C.HEARTH_LOAD) * 100, bindDur = C.QUEST_ACTION * 100,
    dur = function(t) return math.floor((t.dur or 0) * 100 + 0.5) end,
    radius = math.floor(C.HEARTH_BUNDLE / C.WALK * 100 + 0.5) }
  local inns = {}
  for _, p in ipairs(sim.hearthInns(ctx, hubs)) do
    if not (bound and yards(bound, p) <= C.HEARTH_NEAR) then inns[#inns + 1] = p end
  end
  -- trajet vers le chapitre suivant (opts.nextEntry) depuis la fin du chapitre, avec la pierre liée et
  -- disponible ou non à ce moment : une liaison sert aussi au départ du chapitre suivant (sim.route)
  local nextPos = ctx.opts.nextEntry and mkPos(ctx.W, ctx.opts.nextEntry[1], ctx.opts.nextEntry[2], ctx.opts.nextEntry[3])
  local fms = sim.flightMasters(ctx)
  local function endTravel(seq, fin)
    if not nextPos or not fin.pos then return 0 end
    if regionOf(fin.pos) == regionOf(nextPos) and yards(fin.pos, nextPos) <= 1500 then return 0 end
    local saved = { state.hearth, state.hearthReadyAt, state.time, state.knownTaxi }
    local taxi = {}
    for node in pairs(state.knownTaxi or {}) do taxi[node] = true end
    for _, t in ipairs(seq) do if t.kind == "F" and t.fm then taxi[t.fm.node] = true end end
    state.hearth = fin.inn and { fin.inn.m, fin.inn.x, fin.inn.y } or nil
    state.time, state.hearthReadyAt, state.knownTaxi = 0, fin.time >= fin.ready and 0 or 1, taxi
    local legs = sim.route(ctx, fin.pos, nextPos, fms)
    state.hearth, state.hearthReadyAt, state.time, state.knownTaxi = saved[1], saved[2], saved[3], saved[4]
    if not legs then return C.TRANSIT * 100 end
    local sec = 0
    for _, l in ipairs(legs) do sec = sec + (l.time or 0) end
    return math.floor(sec * 100 + 0.5)
  end
  -- meilleur plan sur une séquence ; `keep` : plan déjà retenu (liaisons par tâche), comparé aussi
  local function best(seq, keep)
    local plans = { { binds = {}, n = 0 } }
    if keep then plans[#plans + 1] = keep end
    for _, a in ipairs(inns) do
      local ia = bindIndex(seq, a)
      if ia then
        plans[#plans + 1] = { binds = { [seq[ia].id] = a }, n = 1 }
        if C.HEARTH_BINDS >= 2 then
          for _, b in ipairs(inns) do
            local ib = b ~= a and bindIndex(seq, b, ia + 1)
            if ib and seq[ib].id ~= seq[ia].id then
              plans[#plans + 1] = { binds = { [seq[ia].id] = a, [seq[ib].id] = b }, n = 2 }
            end
          end
        end
      end
    end
    local pick, pickCost, pickUses
    for _, pl in ipairs(plans) do
      o.binds = pl.binds
      local c, uses, _, fin = orderm.hearthCost(seq, o)
      c = c + endTravel(seq, fin)
      if not pickCost or c < pickCost or (c == pickCost and pl.n < pick.n) then pick, pickCost, pickUses = pl, c, uses end
    end
    return pick, pickCost, pickUses
  end
  local plan, cost, uses = best(ordered)
  local bundles = 0
  if C.HEARTH_BUNDLE > 0 and not os.getenv("ROUTEBUILDER_NO_BUNDLE") then
    for _ = 1, 2 do
      o.binds = plan.binds
      local seq2, n = orderm.hearthBundles(ordered, o, fopts)
      if n == 0 then break end
      local plan2, cost2, uses2 = best(seq2, plan)
      ordered, plan, cost, uses, bundles = seq2, plan2, cost2, uses2, bundles + n
    end
  end
  local out = {}
  local names = {}
  for k, t in ipairs(ordered) do
    local inn = plan.binds[t.id]
    if inn then
      out[t.id] = inn
      local n = ctx.D.npcs[inn.npc]
      names[#names + 1] = ("%s after task %d"):format(n and n.name or "inn", k)
    end
  end
  out.summary = ("%s; %d return(s) planned, %d bundle(s)"):format(
    #names > 0 and ("bound to " .. table.concat(names, ", then ")) or "no new bind", uses or 0, bundles)
  return ordered, out
end

-- Ramassage des points de vol inconnus sur une marche de a à b : maître de vol à moins de
-- FP_RADIUS du segment, ou détour total inférieur à FP_DETOUR yards. Renvoie la position atteinte.
local function walkLeg(ctx, steps, a, b, fms)
  local state = ctx.state
  local passing = {}
  local direct = yards(a, b)
  for _, fm in ipairs(fms) do
    if not state.knownTaxi[fm.node] and regionOf(fm.pos) == regionOf(a) then
      local sd, tt = segDist(fm.pos, a, b)
      local detour = yards(a, fm.pos) + yards(fm.pos, b) - direct
      if sd <= C.FP_RADIUS or detour <= C.FP_DETOUR then passing[#passing + 1] = { fm = fm, t = tt } end
    end
  end
  table.sort(passing, function(x, y) return x.t < y.t or (x.t == y.t and x.fm.npc < y.fm.npc) end)
  local pos = a
  for _, p in ipairs(passing) do
    if not state.knownTaxi[p.fm.node] then
      state.time = state.time + yards(pos, p.fm.pos) / C.WALK + C.QUEST_ACTION
      steps[#steps + 1] = { "fp", p.fm.pos.m, round2(p.fm.pos.x), round2(p.fm.pos.y) }
      state.knownTaxi[p.fm.node] = true
      pos = p.fm.pos
    end
  end
  state.time = state.time + yards(pos, b) / C.WALK
  return b
end

-- Liaisons de transport du chapitre (faction, race simulée), positions résolues une fois.
local function chapterLinks(ctx)
  if ctx._links then return ctx._links end
  local out = {}
  for _, l in ipairs(transport.linksFor(ctx.faction, ctx.state.race)) do
    local a = mkPos(ctx.W, l.from[1], l.from[2], l.from[3])
    local b = mkPos(ctx.W, l.to[1], l.to[2], l.to[3])
    if a and b then out[#out + 1] = { link = l, from = a, to = b } end
  end
  ctx._links = out
  return out
end
sim.chapterLinks = chapterLinks

-- Plus court trajet (Dijkstra) de cur à dest : marche dans une même région, vols entre points de
-- vol connus, liaisons de transport, pierre de foyer. Renvoie la liste des tronçons
-- { kind = "walk"|"fly"|"link"|"hearth", from, to, time, fm/link } ou nil si aucun trajet.
function sim.route(ctx, cur, dest, fms)
  local state, W = ctx.state, ctx.W
  local nodes = { { pos = cur, kind = "start" }, { pos = dest, kind = "dest" } }
  for _, fm in ipairs(fms) do
    if state.knownTaxi[fm.node] then nodes[#nodes + 1] = { pos = fm.pos, kind = "fm", fm = fm } end
  end
  for _, l in ipairs(chapterLinks(ctx)) do
    local arrive = { pos = l.to, kind = "arrive" }
    nodes[#nodes + 1] = arrive
    nodes[#nodes + 1] = { pos = l.from, kind = "dock", l = l, arrive = arrive }
  end
  local inn
  if state.hearth and state.time >= (state.hearthReadyAt or 0) then
    local h = mkPos(W, state.hearth[1], state.hearth[2], state.hearth[3])
    if h then inn = { pos = h, kind = "inn" }; nodes[#nodes + 1] = inn end
  end
  local dist, prev, done = {}, {}, {}
  dist[1] = 0
  while true do
    local u, best
    for i = 1, #nodes do
      if not done[i] and dist[i] and (not best or dist[i] < best) then u, best = i, dist[i] end
    end
    if not u or u == 2 then break end
    done[u] = true
    local nu = nodes[u]
    local function relax(v, cost, leg)
      local nd = best + cost
      if not dist[v] or nd < dist[v] - 1e-9 then dist[v] = nd; prev[v] = { u = u, leg = leg } end
    end
    for v = 2, #nodes do
      if not done[v] then
        local nv = nodes[v]
        if regionOf(nu.pos) == regionOf(nv.pos) then
          local d = yards(nu.pos, nv.pos)
          if d < math.huge then relax(v, d / C.WALK, { kind = "walk", time = d / C.WALK }) end
        end
        if nu.kind == "fm" and nv.kind == "fm" and nu.fm.node ~= nv.fm.node and nu.pos.c == nv.pos.c then
          local ft = W.flightTime(nu.fm.node, nv.fm.node, state.knownTaxi)
          if ft then relax(v, ft + C.FLY_PENALTY, { kind = "fly", time = ft, fm = nv.fm }) end
        end
        if nu.kind == "dock" and nv == nu.arrive then
          relax(v, nu.l.link.time, { kind = "link", time = nu.l.link.time, link = nu.l.link })
        end
        if u == 1 and nv == inn then
          relax(v, C.HEARTH_CAST + C.HEARTH_PENALTY, { kind = "hearth", time = C.HEARTH_CAST + C.HEARTH_LOAD })
        end
      end
    end
  end
  if not dist[2] then return nil end
  local legs, v = {}, 2
  while prev[v] do
    local p = prev[v]
    local leg = p.leg
    leg.from, leg.to = nodes[p.u].pos, nodes[v].pos
    table.insert(legs, 1, leg)
    v = p.u
  end
  return legs, dist[2]
end

-- Trajet de cur à dest : écrit les étapes logistiques (fp, goto + fly, boat, hearth) et compte le temps.
function sim.travel(ctx, steps, cur, dest, fms)
  local state, W = ctx.state, ctx.W
  if not dest or not cur then return dest or cur end
  if regionOf(cur) == regionOf(dest) and yards(cur, dest) / C.WALK <= C.ROUTE_MIN then
    return walkLeg(ctx, steps, cur, dest, fms)
  end
  local legs = sim.route(ctx, cur, dest, fms)
  if not legs then
    -- aucun trajet connu : étape manuelle + temps forfaitaire
    local m = W.maps[dest.m]
    steps[#steps + 1] = { "note", ("Travel to %s"):format(m and m.name or ("map " .. dest.m)) }
    state.time = state.time + C.TRANSIT
    if not ctx._transitWarned then
      ctx._transitWarned = true
      ctx.warnings[#ctx.warnings + 1] = ("no route to %s (map %s): add a link to transport.lua or `arrive` to the plan"):format(
        m and m.name or "?", tostring(dest.m))
    end
    return dest
  end
  local pos = cur
  for i, leg in ipairs(legs) do
    if leg.kind == "walk" then
      pos = walkLeg(ctx, steps, pos, leg.to, fms)
    elseif leg.kind == "fly" then
      local prevLeg = legs[i - 1]
      if prevLeg and prevLeg.kind == "walk" and yards(prevLeg.from, prevLeg.to) > 30 then
        steps[#steps + 1] = { "goto", leg.from.m, round2(leg.from.x), round2(leg.from.y), note = "Flight master" }
      end
      local node = W.taxi.nodes[leg.fm.node]
      steps[#steps + 1] = { "fly", leg.to.m, node = leg.fm.node, note = node and node.name or nil }
      state.time = state.time + leg.time
      pos = leg.to
    elseif leg.kind == "link" then
      local l = leg.link
      steps[#steps + 1] = { l.kind == "portal" and "goto" or "boat", leg.from.m, round2(leg.from.x), round2(leg.from.y), note = l.note }
      state.time = state.time + leg.time
      pos = leg.to
    elseif leg.kind == "hearth" then
      steps[#steps + 1] = { "hearth", leg.to.m }
      state.time = state.time + leg.time
      state.hearthReadyAt = state.time + C.HEARTH_CD
      pos = leg.to
    end
  end
  return dest
end

return sim
