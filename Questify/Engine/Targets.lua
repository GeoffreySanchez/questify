local addonName, Q = ...

-- Cibles : où aller pour une étape, et quels monstres tuer pour les objectifs en cours.
-- Coordonnées en 0-100 avec uiMapID, comme partout dans l'addon.
local Targets = {}
Q.Targets = Targets

local MOB_WINDOW = 15   -- nombre d'étapes non faites examinées pour la liste des monstres
local SITE_RADIUS = 200 -- yards : dans la zone d'objectif, la cible suit le monstre le plus proche
local SPAWN_MIN = 25    -- yards : points d'apparition trop proches ignorés (monstre déjà tué, TomTom
                        -- efface sa flèche à l'arrivée)
local POINT_ACTIONS = { ["goto"] = true, fp = true, sethearth = true, boat = true }

---------------------------------------------------------------------------
-- Association objectif QuestieDB <-> objectif du journal
---------------------------------------------------------------------------
-- Index de l'objectif du journal dont le texte contient `name` (minuscules, recherche simple).
-- Si plusieurs lignes correspondent, on préfère celle qui commence par le nom.
function Targets:MatchObjective(questId, name)
  if type(questId) ~= "number" or type(name) ~= "string" or name == "" then return nil end
  local objs = C_QuestLog.GetQuestObjectives(questId)
  if type(objs) ~= "table" then return nil end
  local needle = name:lower()
  local first
  for i, o in ipairs(objs) do
    local text = type(o.text) == "string" and o.text:lower() or nil
    if text then
      local pos = text:find(needle, 1, true)
      if pos == 1 then return i end
      if pos and not first then first = i end
    end
  end
  return first
end

-- Liste des cibles d'objectifs d'une quête : { kind, id, objIndex, viaItem }.
-- objIndex vient du texte du journal, sinon de l'ordre QuestieDB (créature, objet, objet de
-- quête, réputation, crédit, sort).
local function objectiveTargets(questId)
  local q = Q.QDB:Quest(questId)
  if not q then return {} end
  local inLog = Q.Progress:InLog(questId)
  local rows = {}
  for ordinal, o in ipairs(q.objectives.ordered) do
    local matchName
    if o.kind == "creature" then
      matchName = Q.QDB:NpcName(o.ids[1])
    elseif o.kind == "object" then
      matchName = Q.QDB:ObjectName(o.ids[1])
    elseif o.kind == "item" then
      matchName = Q.QDB:ItemName(o.ids[1])
    elseif o.kind == "killCredit" then
      matchName = o.text or (o.base and Q.QDB:NpcName(o.base))
    end
    local objIndex = (inLog and matchName and Targets:MatchObjective(questId, matchName))
      or (inLog and o.text and Targets:MatchObjective(questId, o.text)) or ordinal
    if o.kind == "creature" or o.kind == "killCredit" then
      for _, npcId in ipairs(o.ids) do
        rows[#rows + 1] = { kind = "npc", id = npcId, objIndex = objIndex }
      end
    elseif o.kind == "object" then
      rows[#rows + 1] = { kind = "object", id = o.ids[1], objIndex = objIndex }
    elseif o.kind == "item" then
      local itemId = o.ids[1]
      local item = Q.QDB:Item(itemId)
      if item then
        for _, npcId in ipairs(item.npcDrops) do
          rows[#rows + 1] = { kind = "npc", id = npcId, objIndex = objIndex, viaItem = itemId }
        end
        for _, objId in ipairs(item.objectDrops) do
          rows[#rows + 1] = { kind = "object", id = objId, objIndex = objIndex, viaItem = itemId }
        end
      end
    end
  end
  return rows
end
Targets.ObjectiveTargets = function(_, questId) return objectiveTargets(questId) end

---------------------------------------------------------------------------
-- Cible d'une étape
---------------------------------------------------------------------------
local function spawnsOf(kind, id)
  local data
  if kind == "npc" then data = Q.QDB:Npc(id) else data = Q.QDB:Object(id) end
  return data and data.spawns
end

-- Plus proche spawn parmi des candidats { kind, id } : -> mapId, x, y, kind, id.
local function nearest(cands)
  local pm, px, py = Q.Maps:PlayerPos()
  local best, bestD, first
  for _, c in ipairs(cands) do
    local spawns = spawnsOf(c.kind, c.id)
    if spawns then
      local m, x, y, d = Q.Maps:Nearest(spawns, pm, px, py)
      if m then
        if d and (not bestD or d < bestD) then
          best, bestD = { m, x, y, c.kind, c.id }, d
        elseif not first then
          first = { m, x, y, c.kind, c.id }
        end
      end
    end
  end
  local r = best or first
  if not r then return nil end
  return r[1], r[2], r[3], r[4], r[5]
end

-- Plus proche point d'apparition à plus de minD yards du joueur parmi des candidats { kind, id } :
-- -> mapId, x, y, kind, id, distance ; nil si aucun sur le continent du joueur.
local function nearestAway(cands, minD)
  local pm, px, py = Q.Maps:PlayerPos()
  if not pm then return nil end
  local best, bestD
  for _, c in ipairs(cands) do
    for m, list in pairs(spawnsOf(c.kind, c.id) or {}) do
      if type(m) == "number" and type(list) == "table" then
        for _, p in ipairs(list) do
          local d = Q.Maps:Distance(pm, px, py, m, p[1], p[2])
          if d and d >= minD and (not bestD or d < bestD) then best, bestD = { m, p[1], p[2], c.kind, c.id }, d end
        end
      end
    end
  end
  if not best then return nil end
  return best[1], best[2], best[3], best[4], best[5], bestD
end

-- Cibles des objectifs encore à faire d'une étape « complete ».
local function completeCands(step)
  local rows = objectiveTargets(step.questId)
  local cands = {}
  if step.obj then
    for _, r in ipairs(rows) do if r.objIndex == step.obj then cands[#cands + 1] = r end end
  elseif Q.Progress:InLog(step.questId) then
    for _, r in ipairs(rows) do
      if not Q.Progress:ObjectiveDone(step.questId, r.objIndex) then cands[#cands + 1] = r end
    end
  end
  if #cands == 0 then cands = rows end
  return cands
end

local function givers(list)
  local cands = {}
  for _, id in ipairs(list.npcs or {}) do cands[#cands + 1] = { kind = "npc", id = id } end
  for _, id in ipairs(list.objects or {}) do cands[#cands + 1] = { kind = "object", id = id } end
  return cands
end

local function title(entry)
  if Q.Format and Q.Format.StepTitle then
    local ok, t = pcall(Q.Format.StepTitle, Q.Format, entry)
    if ok and type(t) == "string" then return t end
  end
  local step = entry.step
  if step.questId then return Q.QDB:QuestName(step.questId) end
  return step.text or step.note or step.action
end

local function compute(entry)
  local step = entry.step
  local a = step.action
  local mapId, x, y, kind, id
  if a == "accept" or a == "turnin" then
    local q = Q.QDB:Quest(step.questId)
    if not q then return nil end
    mapId, x, y, kind, id = nearest(givers(a == "accept" and q.starters or q.finishers))
    -- donneur sans position connue : le point choisi par le générateur, s'il existe
    if not mapId and step.at then
      mapId, x, y, kind = step.at[1], step.at[2], step.at[3], "area"
    end
  elseif a == "complete" then
    if step.at then
      mapId, x, y, kind = step.at[1], step.at[2], step.at[3], "area"
      -- dans la zone d'objectif : le monstre (ou l'objet) le plus proche, pas le centre de la zone
      local d = Q.Maps:DistanceFromPlayer(mapId, x, y)
      if d and d <= SITE_RADIUS then
        local m2, x2, y2, k2, id2, d2 = nearestAway(completeCands(step), SPAWN_MIN)
        if m2 and d2 <= SITE_RADIUS * 1.5 then mapId, x, y, kind, id = m2, x2, y2, k2, id2 end
      end
    else
      local cands = completeCands(step)
      mapId, x, y, kind, id = nearestAway(cands, SPAWN_MIN)
      if not mapId then mapId, x, y, kind, id = nearest(cands) end
    end
  elseif a == "train" or a == "trainprof" then
    local ids
    if a == "train" then
      ids = Q.Trainer and Q.Trainer:TrainerIds() or {}
    else
      ids = Q.Professions and Q.Professions:TrainerIds(step.prof) or {}
    end
    local cands = {}
    for _, id in ipairs(ids) do cands[#cands + 1] = { kind = "npc", id = id } end
    mapId, x, y, kind, id = nearest(cands)
  elseif a == "classquest" then
    -- donneur le plus proche de la première quête restante de la chaîne
    local CQ = Q.ClassQuests
    local chain = CQ and CQ:FindChain(step.key)
    local s = chain and CQ:Starter(CQ:FirstQuest(chain))
    if s and s.mapId and (s.kind == "npc" or s.kind == "object") then
      mapId, x, y, kind, id = s.mapId, s.x, s.y, s.kind, s.id
    end
  elseif POINT_ACTIONS[a] then
    mapId, x, y, kind = step.mapId, step.x, step.y, "point"
  elseif step.at then
    mapId, x, y, kind = step.at[1], step.at[2], step.at[3], "area"
  end
  if not mapId then return nil end
  return { mapId = mapId, x = x, y = y, kind = kind, id = id, title = title(entry) }
end

-- Q.Targets:ForEntry(entry) -> { mapId, x, y, title, kind = "npc"|"object"|"area"|"point"|"zone", id } | nil
-- Étape qui porte une zone (Engine/ZoneMode.lua, option zoneMode) : centre de la zone hors de
-- celle-ci, objectif prioritaire le plus proche dedans (kind = "zone"). Sinon, calcul habituel.
function Targets:ForEntry(entry)
  if type(entry) ~= "table" or type(entry.step) ~= "table" then return nil end
  local Z = Q.ZoneMode
  if Z and Z.TargetFor then
    local okZ, zt = Q.SafeCall(Z.TargetFor, Z, entry)
    if okZ and zt then return zt end
  end
  local ok, target = Q.SafeCall(compute, entry)
  if ok then return target end
  return nil
end

---------------------------------------------------------------------------
-- Monstres d'objectif
---------------------------------------------------------------------------
-- Liste des monstres des quêtes en cours dans les 15 prochaines étapes non faites :
-- { npcId, name, minLevel, maxLevel, questId, objIndex, done, viaItem }, sans doublon.
local function collectMobs()
  local rows, byNpc = {}, {}
  local count = 0
  for _, e in ipairs(Q.Progress:Entries()) do
    local state = Q.Progress:State(e)
    if state ~= "done" and state ~= "skipped" then
      count = count + 1
      if count > MOB_WINDOW then break end
      local step = e.step
      if step.action == "complete" and Q.Progress:InLog(step.questId) then
        local questId = step.questId
        local complete = Q.Progress:IsComplete(questId)
        for _, r in ipairs(objectiveTargets(questId)) do
          if r.kind == "npc" and (not step.obj or r.objIndex == step.obj) then
            local done = complete or Q.Progress:ObjectiveDone(questId, r.objIndex)
            local existing = byNpc[r.id]
            if not existing or (existing.done and not done) then
              local npc = Q.QDB:Npc(r.id)
              local row = {
                npcId = r.id,
                name = Q.QDB:NpcName(r.id),
                minLevel = npc and npc.minLevel,
                maxLevel = npc and npc.maxLevel,
                questId = questId,
                objIndex = r.objIndex,
                done = done,
                viaItem = r.viaItem,
              }
              if existing then
                for k in pairs(existing) do existing[k] = nil end
                for k, v in pairs(row) do existing[k] = v end
              else
                byNpc[r.id] = row
                rows[#rows + 1] = row
              end
            end
          end
        end
      end
    end
  end
  return rows
end

-- Monstres d'une seule étape « complete » (affichés sous ses objectifs dans le suivi) :
-- { npcId, name, minLevel, maxLevel, questId, objIndex, done, viaItem }, un par monstre, dans
-- l'ordre des objectifs. Quête absente du journal : objectifs QuestieDB, aucun n'est terminé.
local function stepMobs(entry)
  local step = type(entry) == "table" and entry.step
  if type(step) ~= "table" or step.action ~= "complete" or not step.questId then return {} end
  local questId = step.questId
  local inLog = Q.Progress:InLog(questId)
  local complete = inLog and Q.Progress:IsComplete(questId)
  local rows, seen = {}, {}
  for _, r in ipairs(objectiveTargets(questId)) do
    if r.kind == "npc" and not seen[r.id] and (not step.obj or r.objIndex == step.obj) then
      seen[r.id] = true
      local npc = Q.QDB:Npc(r.id)
      rows[#rows + 1] = {
        npcId = r.id,
        name = Q.QDB:NpcName(r.id),
        minLevel = npc and npc.minLevel,
        maxLevel = npc and npc.maxLevel,
        questId = questId,
        objIndex = r.objIndex,
        done = (inLog and (complete or Q.Progress:ObjectiveDone(questId, r.objIndex))) and true or false,
        viaItem = r.viaItem,
      }
    end
  end
  return rows
end

-- Q.Targets:MobsForEntry(entry) -> liste neuve (jamais en cache), vide hors étape « complete ».
function Targets:MobsForEntry(entry)
  local ok, rows = Q.SafeCall(stepMobs, entry)
  return (ok and rows) or {}
end

-- Cache recalculé au plus une fois entre deux recalculs de la progression : les barres de nom
-- interrogent ces listes à chaque apparition de barre. Il est vidé à chaque PROGRESS_UPDATED,
-- GUIDE_CHANGED et évènement du journal de quêtes (objectif terminé visible tout de suite).
local mobsCache, setCache

local function invalidateMobs()
  mobsCache, setCache = nil, nil
end
Targets.InvalidateCache = function() invalidateMobs() end

-- Les appelants reçoivent des copies : trier ou modifier le résultat ne touche pas le cache.
function Targets:ObjectiveMobs()
  if not mobsCache then
    local ok, rows = Q.SafeCall(collectMobs)
    mobsCache = (ok and rows) or {}
  end
  local out = {}
  for i, r in ipairs(mobsCache) do out[i] = r end
  return out
end

-- { [npcId] = true } des monstres dont l'objectif n'est pas terminé.
function Targets:ObjectiveNpcSet()
  if not setCache then
    setCache = {}
    for _, r in ipairs(self:ObjectiveMobs()) do
      if not r.done then setCache[r.npcId] = true end
    end
  end
  local out = {}
  for k, v in pairs(setCache) do out[k] = v end
  return out
end

Q:On("PROGRESS_UPDATED", invalidateMobs)
Q:On("GUIDE_CHANGED", invalidateMobs)
for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN" }) do
  Q:RegisterEvent(event, invalidateMobs)
end
