local addonName, Q = ...

-- Mode zone (option zoneMode) : quand l'étape courante et les suivantes ont leurs objectifs au
-- même endroit (monstres à tuer, objet à ramasser, monstre nommé, coffre…), elles forment une
-- zone faite en une seule visite, pour tuer le moins possible et ne jamais nettoyer deux fois le
-- même endroit.
--   Hors de la zone : la navigation vise son centre, le suivi l'annonce (pastille verte) et la
--   carte montre un repère vert.
--   Dans la zone : le suivi liste tous ses objectifs, de toutes les quêtes, par priorité (objets
--   à utiliser ou à ramasser, puis élites et nommés, puis monstres ; le plus proche d'abord à
--   priorité égale) et la flèche suit le premier. Un objet fermé par une clé qui tombe sur un
--   monstre de la zone passe après ce monstre.
-- La zone se termine quand tous ses objectifs sont faits (l'étape suivante reprend). S'éloigner
-- à plus de 2 × rayon renvoie la flèche vers le centre.
-- Tout vient de QuestieDB et du journal de quêtes. Donnée absente (position, carte, base) : nil,
-- et le comportement habituel reste en place. Rien ici n'est protégé ; aucune erreur ne sort
-- (chaque calcul passe par Q.SafeCall).
local ZoneMode = {}
Q.ZoneMode = ZoneMode

local LOOKAHEAD = 8          -- étapes non faites examinées après l'étape courante
local OVERLAP = 120          -- yards : un point d'apparition aussi proche du site courant le chevauche
local SITE_SPAN = 250        -- yards : points retenus autour de l'ancre de l'étape courante
local RADIUS_MIN, RADIUS_MAX = 60, 250
local ENTER_MARGIN = 20      -- yards : on entre dans la zone à rayon + 20
local LEAVE_FACTOR = 2       -- on en sort au-delà de 2 × rayon
local NAMED_MAX_SPAWNS = 2   -- monstre unique (2 points d'apparition au plus) : traité comme nommé
local SPAWN_MIN = 25         -- yards : point trop proche ignoré par la flèche (monstre déjà tué)
local MAX_REF = 40           -- points de référence du site courant (coût des distances)
local MAX_SPAWNS = 800       -- points examinés au plus par cible
local TICK = 1               -- secondes : entrée et sortie de la zone, changement d'objectif en tête
local NAME_SPAN = 0.6        -- nom de sous-zone appris seulement près du centre (fraction du rayon)

local PRIORITY = { object = 1, named = 2, mob = 3, item = 3 }

-- Objets du monde fermés par une clé : [objet QuestieDB] = objet-clé (ou liste). Données
-- seulement : le monstre qui porte la clé vient de QuestieDB (npcDrops de l'objet-clé) et passe
-- avant l'objet du monde tant que la clé n'est pas dans les sacs.
ZoneMode.KEYS = {
  [3239] = 4882,   -- Coffre de Benedict (fort de Tiragarde, Durotar) : clé de Benedict
}

local zone            -- dernière zone calculée (nil : pas de zone)
local dirty = true    -- recalcul à faire au prochain Current()
local lastSig = ""    -- signature de la dernière zone annoncée (ZONEMODE_CHANGED)
local learned = {}    -- noms de sous-zone appris sur place : { { mapId, x, y, radius, name } }
local rankCache = {}
local ticker

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function enabled()
  return Q.Settings:Get("zoneMode") ~= false and Q.Progress:IsEnabled()
end

local function isSecret(v) return Q.Util.IsSecret(v) end

local function fmt(template, ...)
  local ok, s = pcall(string.format, template, ...)
  if ok then return s end
  return tostring(template)
end

local function strip(s) return Q.Util.StripColors(tostring(s or "")) end

-- Exemplaires d'un objet dans les sacs (0 si inconnu ou secret).
local function itemCount(id)
  local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
  if type(fn) ~= "function" or type(id) ~= "number" then return 0 end
  local ok, n = pcall(fn, id)
  if not ok or isSecret(n) then return 0 end
  return tonumber(n) or 0
end

-- Rang QuestieDB du PNJ (1 élite, 2 rare élite, 3 boss, 4 rare ; 0 normal). Le champ n'est pas lu
-- par Q.QDB : lecture directe, protégée, mise en cache.
local function npcRank(id)
  local c = rankCache[id]
  if c ~= nil then return c end
  local rank = 0
  local lib = LibQuestieDB
  if type(id) == "number" and Q.QDB:IsAvailable() and type(lib) == "table" and type(lib.Npc) == "table"
    and type(lib.Npc.GetAll) == "function" then
    local ok, v = pcall(lib.Npc.GetAll, id, { "rank" })
    if ok and type(v) == "table" and type(v[1]) == "number" then rank = v[1] end
  end
  rankCache[id] = rank
  return rank
end
ZoneMode.NpcRank = function(_, id) return npcRank(id) end

local function spawnsOf(kind, id)
  local data
  if kind == "npc" then data = Q.QDB:Npc(id) else data = Q.QDB:Object(id) end
  return data and data.spawns
end

local function spawnCount(spawns)
  local n = 0
  for _, list in pairs(spawns or {}) do
    if type(list) == "table" then n = n + #list end
  end
  return n
end

-- Monstre nommé : rang QuestieDB > 0, ou apparition unique (2 points au plus).
local function isNamed(npcId)
  if npcRank(npcId) > 0 then return true end
  local n = spawnCount(spawnsOf("npc", npcId))
  return n > 0 and n <= NAMED_MAX_SPAWNS
end

-- PNJ des crédits de mise à mort dont la créature de base est un élite ou un nommé (rang > 0).
local function killCreditNamed(questId)
  local set = {}
  local q = Q.QDB:Quest(questId)
  for _, kc in ipairs(q and q.objectives.killCredit or {}) do
    if kc.base and npcRank(kc.base) > 0 then
      for _, id in ipairs(kc.npcIds) do set[id] = true end
    end
  end
  return set
end

-- Quête lancée par un objet ramassé (sur un monstre ou un objet du monde) : -> liste d'objets.
local function startItems(questId)
  local q = Q.QDB:Quest(questId)
  if not q or #q.starters.items == 0 then return nil end
  if #q.starters.npcs > 0 or #q.starters.objects > 0 then return nil end
  return q.starters.items
end

-- Position monde du joueur : continent, X, Y (nil si inconnue).
local function playerWorld()
  local pm, px, py = Q.Maps:PlayerPos()
  if not pm then return nil end
  return Q.Maps:WorldPos(pm, px, py)
end

local function dist2(ax, ay, bx, by)
  local dx, dy = ax - bx, ay - by
  return dx * dx + dy * dy
end

---------------------------------------------------------------------------
-- Étapes et cibles
---------------------------------------------------------------------------
-- Étape qui peut entrer dans une zone : « complete », ou « accept » d'une quête lancée par un objet.
local function zoneable(entry)
  local step = entry.step
  if type(step.questId) ~= "number" then return false end
  if step.action == "complete" then return true end
  return step.action == "accept" and startItems(step.questId) ~= nil
end

-- Cibles d'une étape : { { kind = "npc"|"object", id, questId, objIndex, viaItem, done, start, forceNamed } },
-- ou nil si l'étape ne peut pas entrer dans une zone.
local function entryTargets(entry)
  local step = entry.step
  local questId = step.questId
  if type(questId) ~= "number" then return nil end
  local out = {}
  if step.action == "complete" then
    if not Q.Progress:InLog(questId) then return nil end
    local complete = Q.Progress:IsComplete(questId)
    local kcNamed = killCreditNamed(questId)
    for _, r in ipairs(Q.Targets:ObjectiveTargets(questId)) do
      if not step.obj or r.objIndex == step.obj then
        out[#out + 1] = { kind = r.kind, id = r.id, questId = questId, objIndex = r.objIndex, viaItem = r.viaItem,
          done = complete or Q.Progress:ObjectiveDone(questId, r.objIndex), forceNamed = kcNamed[r.id] }
      end
    end
    return out
  elseif step.action == "accept" then
    local items = startItems(questId)
    if not items then return nil end
    for _, itemId in ipairs(items) do
      local item = Q.QDB:Item(itemId)
      -- objet déjà dans les sacs : il reste à l'utiliser, rien à chercher dans la zone
      local done = itemCount(itemId) > 0
      if item then
        for _, npcId in ipairs(item.npcDrops) do
          out[#out + 1] = { kind = "npc", id = npcId, questId = questId, objIndex = 0, viaItem = itemId, done = done,
            start = true }
        end
        for _, objId in ipairs(item.objectDrops) do
          out[#out + 1] = { kind = "object", id = objId, questId = questId, objIndex = 0, viaItem = itemId, done = done,
            start = true }
        end
      end
    end
    if #out == 0 then return nil end
    return out
  end
  return nil
end

-- L'étape courante puis les suivantes non faites qui peuvent entrer dans la zone, jusqu'à la
-- première qui ne le peut pas, LOOKAHEAD au plus.
local function candidates(cur)
  local list = { cur }
  local started, seen = false, 0
  for _, e in ipairs(Q.Progress:Entries()) do
    if started then
      local s = Q.Progress:State(e)
      if s ~= "done" and s ~= "skipped" then
        seen = seen + 1
        if seen > LOOKAHEAD then break end
        if s ~= "active" or not zoneable(e) then break end
        list[#list + 1] = e
      end
    elseif e == cur then
      started = true
    end
  end
  return list
end

-- Points d'apparition d'une cible sur la carte m : { { mapId, x, y, wx, wy } } (monde en cache).
local function worldPoints(kind, id, m, cont)
  local out = {}
  local list = (spawnsOf(kind, id) or {})[m]
  if type(list) ~= "table" then return out end
  for i, p in ipairs(list) do
    if i > MAX_SPAWNS then break end
    local x, y = p[1], p[2]
    if type(x) == "number" and type(y) == "number" then
      local c, wx, wy = Q.Maps:WorldPos(m, x, y)
      if c ~= nil and c == cont then out[#out + 1] = { mapId = m, x = x, y = y, wx = wx, wy = wy } end
    end
  end
  return out
end

-- Ancre de l'étape courante : son point `at`, sinon le point d'apparition non fait le plus proche
-- du joueur (sinon le premier connu).
local function anchorOf(entry, targets)
  local at = entry.step.at
  if type(at) == "table" and type(at[1]) == "number" and type(at[2]) == "number" and type(at[3]) == "number" then
    return at[1], at[2], at[3]
  end
  local pm, px, py = Q.Maps:PlayerPos()
  local bm, bx, by, bd
  for _, t in ipairs(targets) do
    if not t.done then
      local m, x, y, d = Q.Maps:Nearest(spawnsOf(t.kind, t.id), pm, px, py)
      if m and (not bm or (d and (not bd or d < bd))) then bm, bx, by, bd = m, x, y, d end
    end
  end
  return bm, bx, by
end

local function newObjective(entry, t, points)
  local kind
  if t.kind == "object" then
    kind = "object"
  elseif t.forceNamed or isNamed(t.id) then
    kind = "named"
  elseif t.viaItem then
    kind = "item"
  else
    kind = "mob"
  end
  local npc = t.kind == "npc" and Q.QDB:Npc(t.id) or nil
  return {
    kind = kind, targetKind = t.kind, id = t.id,
    name = t.kind == "npc" and Q.QDB:NpcName(t.id) or Q.QDB:ObjectName(t.id),
    questId = t.questId, objIndex = t.objIndex, viaItem = t.viaItem,
    done = false, priority = PRIORITY[kind], points = points,
    entryKey = entry.key, start = t.start, key = t.key,
    minLevel = npc and npc.minLevel, maxLevel = npc and npc.maxLevel,
  }
end

local function objectiveKey(o)
  return o.questId .. ":" .. o.objIndex .. ":" .. o.targetKind .. ":" .. o.id
end

-- Objets-clés d'un objet du monde : table KEYS, puis objets requis par sa quête (QuestieDB).
local function keyItemsFor(o)
  local out = {}
  local k = ZoneMode.KEYS[o.id]
  if type(k) == "number" then
    out[#out + 1] = k
  elseif type(k) == "table" then
    for _, v in ipairs(k) do if type(v) == "number" then out[#out + 1] = v end end
  end
  local q = Q.QDB:Quest(o.questId)
  for _, v in ipairs(q and q.sourceItems or {}) do out[#out + 1] = v end
  return out
end

---------------------------------------------------------------------------
-- Nom de la zone
---------------------------------------------------------------------------
local function learnedName(m, x, y)
  for _, n in ipairs(learned) do
    if n.mapId == m then
      local d = Q.Maps:Distance(m, x, y, n.mapId, n.x, n.y)
      if d and d <= n.radius then return n.name end
    end
  end
  return nil
end

-- Sous-carte du client à cet endroit (grotte, ville), sinon nil.
local function childMapName(m, x, y)
  local fn = C_Map and C_Map.GetMapInfoAtPosition
  if type(fn) ~= "function" then return nil end
  local ok, info = pcall(fn, m, x / 100, y / 100)
  if not ok or type(info) ~= "table" or info.mapID == m then return nil end
  if type(info.name) == "string" and info.name ~= "" and not isSecret(info.name) then return info.name end
  return nil
end

local function zoneName(m, x, y)
  return learnedName(m, x, y) or childMapName(m, x, y) or Q.Maps:MapName(m)
end

-- Sur place, le nom de la sous-zone du jeu (fort de Tiragarde…) remplace le nom de la carte.
local function learnName(z, d)
  if z.subName or not d or d > z.radius * NAME_SPAN then return false end
  if type(GetSubZoneText) ~= "function" then return false end
  local ok, sub = pcall(GetSubZoneText)
  if not ok or isSecret(sub) or type(sub) ~= "string" or sub == "" then return false end
  z.subName, z.name = sub, sub
  learned[#learned + 1] = { mapId = z.center.mapId, x = z.center.x, y = z.center.y, radius = z.radius, name = sub }
  return true
end

---------------------------------------------------------------------------
-- Calcul de la zone
---------------------------------------------------------------------------
local function playerDistance(z)
  local pm, px, py = Q.Maps:PlayerPos()
  if not pm then return nil end
  return Q.Maps:Distance(pm, px, py, z.center.mapId, z.center.x, z.center.y)
end

-- Entrée à rayon + 20, sortie au-delà de 2 × rayon. -> vrai si l'état a changé.
local function updateInside(z)
  local d = playerDistance(z)
  if not d then return false end
  local was = z.inside
  if was then
    if d > z.radius * LEAVE_FACTOR then z.inside = false end
  elseif d <= z.radius + ENTER_MARGIN then
    z.inside = true
  end
  if z.inside then learnName(z, d) end
  return z.inside ~= was
end

local function build(prev)
  local cur = Q.Progress:Current()
  if not cur or Q.Progress:State(cur) ~= "active" or not zoneable(cur) then return nil end
  local first = entryTargets(cur)
  if not first then return nil end
  local am, ax, ay = anchorOf(cur, first)
  if type(am) ~= "number" then return nil end
  local cont, awx, awy = Q.Maps:WorldPos(am, ax, ay)
  if cont == nil then return nil end
  local span2, over2 = SITE_SPAN * SITE_SPAN, OVERLAP * OVERLAP
  local reach2 = (SITE_SPAN + OVERLAP) * (SITE_SPAN + OVERLAP)
  -- points d'apparition lus une seule fois par calcul
  local pointCache = {}
  local function pointsOf(kind, id)
    local k = kind .. ":" .. tostring(id)
    local pts = pointCache[k]
    if not pts then
      pts = worldPoints(kind, id, am, cont)
      pointCache[k] = pts
    end
    return pts
  end

  local objectives, byKey, entries, entryKeys = {}, {}, {}, {}
  local function add(e, t, pts)
    local o = newObjective(e, t, pts)
    local k = objectiveKey(o)
    if byKey[k] then return byKey[k] end
    byKey[k] = o
    objectives[#objectives + 1] = o
    if not entryKeys[e.key] then
      entryKeys[e.key] = true
      entries[#entries + 1] = e
    end
    return o
  end

  -- Site de l'étape courante : ses points d'apparition non faits à moins de SITE_SPAN de l'ancre.
  local ref = {}
  for _, t in ipairs(first) do
    if not t.done then
      local pts = {}
      for _, p in ipairs(pointsOf(t.kind, t.id)) do
        if dist2(p.wx, p.wy, awx, awy) <= span2 then pts[#pts + 1] = p end
      end
      if #pts > 0 then
        add(cur, t, pts)
        for _, p in ipairs(pts) do ref[#ref + 1] = p end
      end
    end
  end
  if #ref == 0 then return nil end
  if #ref > MAX_REF then
    table.sort(ref, function(a, b) return dist2(a.wx, a.wy, awx, awy) < dist2(b.wx, b.wy, awx, awy) end)
    for i = #ref, MAX_REF + 1, -1 do ref[i] = nil end
  end
  local function nearRef(p)
    for _, r in ipairs(ref) do
      if dist2(p.wx, p.wy, r.wx, r.wy) <= over2 then return true end
    end
    return false
  end
  -- Points retenus pour une autre cible : près de l'ancre, ou près du site courant.
  local function localPoints(kind, id)
    local pts, overlaps = {}, false
    for _, p in ipairs(pointsOf(kind, id)) do
      local da = dist2(p.wx, p.wy, awx, awy)
      if da <= reach2 then
        local near = nearRef(p)
        if near then overlaps = true end
        if near or da <= span2 then pts[#pts + 1] = p end
      end
    end
    return pts, overlaps
  end

  -- Étapes suivantes : gardées si un de leurs points chevauche le site courant.
  local list = candidates(cur)
  for i = 2, #list do
    local e = list[i]
    for _, t in ipairs(entryTargets(e) or {}) do
      if not t.done then
        local pts, overlaps = localPoints(t.kind, t.id)
        if overlaps then add(e, t, pts) end
      end
    end
  end

  -- Clés : un objet du monde fermé dont la clé tombe sur un monstre proche passe après ce monstre.
  local count = #objectives
  for i = 1, count do
    local o = objectives[i]
    if o.targetKind == "object" then
      for _, keyId in ipairs(keyItemsFor(o)) do
        if itemCount(keyId) == 0 then
          local item = Q.QDB:Item(keyId)
          for _, npcId in ipairs(item and item.npcDrops or {}) do
            local blocker
            for _, b in ipairs(objectives) do
              if b.targetKind == "npc" and b.id == npcId then blocker = b; break end
            end
            if not blocker then
              -- monstre hors des objectifs (quête absente de la route) : ajouté pour la clé
              local pts, overlaps = localPoints("npc", npcId)
              if overlaps then
                local entry
                for _, e in ipairs(entries) do if e.key == o.entryKey then entry = e; break end end
                blocker = add(entry or cur, { kind = "npc", id = npcId, questId = o.questId, objIndex = o.objIndex,
                  viaItem = keyId, key = true }, pts)
              end
            end
            if blocker then
              o.needs = o.needs or {}
              o.needs[#o.needs + 1] = { item = keyId, by = blocker }
            end
          end
        end
      end
    end
  end
  if #objectives == 0 then return nil end

  -- Une zone nouvelle demande au moins deux objectifs, et un objet ou un nommé si une seule quête
  -- est concernée. Une zone déjà en cours (un objectif en commun) continue jusqu'au dernier.
  local quests, nq, special = {}, 0, false
  for _, o in ipairs(objectives) do
    if not quests[o.questId] then quests[o.questId] = true; nq = nq + 1 end
    if o.kind == "object" or o.kind == "named" then special = true end
  end
  local continuing = false
  if prev then
    for _, o in ipairs(prev.objectives) do
      if byKey[objectiveKey(o)] then continuing = true; break end
    end
  end
  if not continuing and (#objectives < 2 or (nq == 1 and not special)) then return nil end

  -- Centre (moyenne des points) et rayon (point le plus éloigné, borné).
  local sx, sy, n = 0, 0, 0
  for _, o in ipairs(objectives) do
    for _, p in ipairs(o.points) do sx, sy, n = sx + p.x, sy + p.y, n + 1 end
  end
  local cx, cy = sx / n, sy / n
  local _, cwx, cwy = Q.Maps:WorldPos(am, cx, cy)
  if not cwx then return nil end
  local r2 = 0
  for _, o in ipairs(objectives) do
    for _, p in ipairs(o.points) do
      local d = dist2(p.wx, p.wy, cwx, cwy)
      if d > r2 then r2 = d end
    end
  end
  local radius = math.max(RADIUS_MIN, math.min(RADIUS_MAX, math.sqrt(r2)))
  -- tri stable : à priorité égale, l'ordre des étapes et des objectifs est conservé
  for i, o in ipairs(objectives) do o.seq = i end
  table.sort(objectives, function(a, b)
    if a.priority ~= b.priority then return a.priority < b.priority end
    return a.seq < b.seq
  end)

  local z = {
    ownerKey = cur.key,
    entries = entries,
    entryKeys = entryKeys,
    center = { am, cx, cy, mapId = am, x = cx, y = cy },
    radius = radius,
    continent = cont,
    objectives = objectives,
    questCount = nq,
  }
  if continuing and prev then
    z.inside, z.subName = prev.inside, prev.subName
  end
  z.name = z.subName or zoneName(am, cx, cy)
  if z.inside == nil then
    local d = playerDistance(z)
    z.inside = d ~= nil and d <= radius + ENTER_MARGIN
    if z.inside then learnName(z, d) end
  else
    updateInside(z)
  end
  return z
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
-- Q.ZoneMode:Current() -> zone | nil :
-- { center = { mapId, x, y }, radius (yards), name, entries, objectives = { { kind =
--   "object"|"named"|"mob"|"item", id, name, questId, objIndex, done, priority, points } }, inside }
function ZoneMode:Current()
  if not enabled() then
    zone, dirty = nil, true
    return nil
  end
  if dirty then
    dirty = false
    local prev = zone
    local ok, z = Q.SafeCall(build, prev)
    zone = (ok and z) or nil
  end
  return zone
end

-- Vrai quand l'étape donnée porte la zone (étape courante qui l'a formée).
function ZoneMode:IsOwner(entry)
  local z = self:Current()
  return z ~= nil and type(entry) == "table" and entry.key == z.ownerKey
end

-- Point le plus proche d'un objectif ; parmi plusieurs points, ceux à moins de SPAWN_MIN yards
-- sont ignorés (monstre sans doute déjà tué). -> point, yards (nil si position inconnue).
local function nearestPoint(o, pc, pwx, pwy)
  if not pc then return o.points[1], nil end
  local best, bestD, close, closeD
  for _, p in ipairs(o.points) do
    local d = math.sqrt(dist2(p.wx, p.wy, pwx, pwy))
    if d >= SPAWN_MIN or #o.points == 1 then
      if not bestD or d < bestD then best, bestD = p, d end
    elseif not closeD or d < closeD then
      close, closeD = p, d
    end
  end
  if best then return best, bestD end
  return close, closeD
end

-- Objectifs de la zone dans l'ordre à suivre : priorité (objet 1, nommé 2, monstre 3 ; un objet
-- qui attend sa clé passe juste après le monstre qui la porte), puis le plus proche.
-- Chaque objectif reçoit `distance`, `nearest` (point visé) et `blocked` ({ item, by } ou nil).
function ZoneMode:Objectives(z)
  z = z or self:Current()
  if not z then return {} end
  local pc, pwx, pwy = playerWorld()
  if pc ~= z.continent then pc = nil end
  local list = {}
  for i, o in ipairs(z.objectives) do
    o.seq = i
    o.nearest, o.distance = nearestPoint(o, pc, pwx, pwy)
    o.order = o.priority
    o.blocked = nil
    for _, need in ipairs(o.needs or {}) do
      if itemCount(need.item) == 0 then
        o.blocked = need
        o.order = math.max(o.order, (need.by.priority or 3) + 0.5)
      end
    end
    list[i] = o
  end
  table.sort(list, function(a, b)
    if a.order ~= b.order then return a.order < b.order end
    if a.distance and b.distance then
      if a.distance ~= b.distance then return a.distance < b.distance end
    elseif a.distance then
      return true
    elseif b.distance then
      return false
    end
    return a.seq < b.seq
  end)
  return list
end

-- Nom court de la zone, pour la navigation : « Zone : <nom> ».
function ZoneMode:Title(z)
  z = z or self:Current()
  if not z then return "" end
  return strip(fmt(Q.L.ZONE_TITLE, z.name or "?"))
end

-- « Zone : <nom> — N objectifs (Q quêtes) »
function ZoneMode:Headline(z)
  z = z or self:Current()
  if not z then return "" end
  local L = Q.L
  local no, nq = #z.objectives, z.questCount or 1
  return fmt(L.ZONE_HEAD, z.name or "?", fmt(no == 1 and L.ZONE_N_OBJ_ONE or L.ZONE_N_OBJ, no),
    fmt(nq == 1 and L.ZONE_N_QUEST_ONE or L.ZONE_N_QUEST, nq))
end

-- Texte d'avancement d'un objectif (ligne du journal, sinon texte QuestieDB), sans couleur.
function ZoneMode:ProgressText(o)
  local L = Q.L
  if o.start or o.key then
    return strip(fmt(L.ZONE_LOOT_FROM, Q.QDB:ItemName(o.viaItem), o.name))
  end
  local fn = C_QuestLog and C_QuestLog.GetQuestObjectives
  local ok, objs = false, nil
  if type(fn) == "function" then ok, objs = pcall(fn, o.questId) end
  local ob = ok and type(objs) == "table" and objs[o.objIndex] or nil
  local text = type(ob) == "table" and ob.text or nil
  if not isSecret(text) and type(text) == "string" and text ~= "" then return text end
  if o.viaItem then return strip(fmt(L.OBJ_LOOT, Q.QDB:ItemName(o.viaItem))) end
  if o.targetKind == "object" then return strip(fmt(L.OBJ_USE, o.name)) end
  return strip(fmt(L.OBJ_KILL, o.name))
end

-- Cible de navigation de l'étape qui porte la zone (nil pour toute autre étape) :
-- hors de la zone, son centre ; dedans, le point le plus proche du premier objectif.
function ZoneMode:TargetFor(entry)
  local z = self:Current()
  if not z or type(entry) ~= "table" or entry.key ~= z.ownerKey then return nil end
  if z.inside then
    local o = self:Objectives(z)[1]
    local p = o and o.nearest
    if p then
      return { mapId = p.mapId, x = p.x, y = p.y, kind = "zone", zoneKind = o.kind, id = o.id,
        title = o.name .. " (" .. Q.QDB:QuestName(o.questId) .. ")" }
    end
  end
  local c = z.center
  return { mapId = c.mapId, x = c.x, y = c.y, kind = "zone", title = self:Title(z) }
end

-- { [npcId] = "named"|"mob" } des monstres de la zone encore à faire (barres de nom).
function ZoneMode:NpcKinds()
  local out = {}
  local z = self:Current()
  if not z then return out end
  for _, o in ipairs(z.objectives) do
    if o.targetKind == "npc" then
      if o.kind == "named" then out[o.id] = "named" elseif not out[o.id] then out[o.id] = "mob" end
    end
  end
  return out
end

-- Lignes de résumé (infobulle du repère de zone) : titre puis une ligne par quête.
function ZoneMode:SummaryLines(z)
  z = z or self:Current()
  if not z then return {} end
  local lines, seen = { self:Headline(z) }, {}
  for _, o in ipairs(z.objectives) do
    if not seen[o.questId] then
      seen[o.questId] = true
      lines[#lines + 1] = "- " .. Q.QDB:QuestName(o.questId)
    end
  end
  return lines
end

---------------------------------------------------------------------------
-- Annonce des changements (ZONEMODE_CHANGED) : zone formée ou finie, entrée ou sortie, nom
-- appris, objectif en tête changé.
---------------------------------------------------------------------------
local function signature(z)
  if not z then return "" end
  local parts = { z.ownerKey, z.inside and "in" or "out", z.name or "", #z.objectives }
  if z.inside then
    local o = ZoneMode:Objectives(z)[1]
    if o then parts[#parts + 1] = objectiveKey(o) end
  end
  return table.concat(parts, "|")
end

local function notify()
  local sig = signature(ZoneMode:Current())
  if sig ~= lastSig then
    lastSig = sig
    Q:Fire("ZONEMODE_CHANGED", zone)
  end
end

-- Toutes les secondes : entrée ou sortie de la zone, puis annonce si quelque chose a changé.
local function tick()
  if not enabled() then
    if lastSig ~= "" then notify() end
    return
  end
  local z = ZoneMode:Current()
  if z then updateInside(z) end
  notify()
end

local function invalidate() dirty = true end

Q:On("PROGRESS_UPDATED", invalidate)
-- autre chapitre : pas de suite possible avec la zone précédente
Q:On("GUIDE_CHANGED", function()
  zone, dirty = nil, true
end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "zoneMode" then
    dirty = true
    notify()
  end
end)
-- objet de départ ou clé ramassés
Q:RegisterEvent("BAG_UPDATE_DELAYED", invalidate)
Q:On("LOGIN", function()
  dirty = true
  if not ticker then ticker = Q:NewTicker(TICK, tick) end
end)
