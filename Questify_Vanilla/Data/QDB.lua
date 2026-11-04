local addonName, Q = ...

-- Façade de lecture QuestieDB (API publique, contrat 4).
-- Rien n'est copié dans l'addon : chaque lecture passe par LibQuestieDB à l'exécution.
-- Rappels de sémantique QuestieDB : les nombres absents valent 0, les tables vides valent nil
-- (sauf startedBy/finishedBy/objectives), chaque table lue est une copie, un ID inconnu vaut nil.
local QDB = {}
Q.QDB = QDB

local REQUIRED_CONTRACT = 4

local questCache, npcCache, objectCache, itemCache = {}, {}, {}, {}

local QUEST_FIELDS = {
  "name", "questLevel", "requiredLevel", "requiredRaces", "requiredClasses",
  "startedBy", "finishedBy", "objectives", "preQuestSingle", "preQuestGroup", "exclusiveTo",
  "nextQuestInChain", "breadcrumbForQuestId", "specialFlags", "requiredSkill",
  "sourceItemId", "requiredSourceItems",
}
local NPC_FIELDS = { "name", "minLevel", "maxLevel", "spawns", "subName", "npcFlags" }
local OBJECT_FIELDS = { "name", "spawns" }
local ITEM_FIELDS = { "name", "npcDrops", "objectDrops" }

-- 0 (nombre absent chez QuestieDB) devient nil.
local function nz(v)
  if v == 0 then return nil end
  return v
end

-- Liste d'IDs numériques non nuls (ignore les trous et les valeurs invalides).
local function ids(t)
  local out = {}
  if type(t) ~= "table" then return out end
  for _, v in ipairs(t) do
    if type(v) == "number" and v ~= 0 then out[#out + 1] = v end
  end
  return out
end

---------------------------------------------------------------------------
-- Disponibilité
---------------------------------------------------------------------------
local status

-- "ok" | "missing" (addon absent) | "old" (contrat 4 non supporté)
function QDB:Status()
  if status then return status end
  local ok, res = pcall(function()
    if type(LibQuestieDB) ~= "table" then return "missing" end
    if type(LibQuestieDB.Quest) ~= "table" or type(LibQuestieDB.Npc) ~= "table"
      or type(LibQuestieDB.Object) ~= "table" or type(LibQuestieDB.Item) ~= "table" then
      return "missing"
    end
    if type(LibQuestieDB.RequireContract) ~= "function" then return "old" end
    if LibQuestieDB.RequireContract(REQUIRED_CONTRACT) == true then return "ok" end
    return "old"
  end)
  status = ok and res or "missing"
  return status
end

function QDB:IsAvailable()
  return self:Status() == "ok"
end

-- -> valeurs | nil, failed. Une erreur de lecture est signalée (une fois par message) et
-- l'appelant ne met rien en cache : la lecture sera retentée.
local function getAll(entity, id, fields)
  if type(id) ~= "number" or not QDB:IsAvailable() then return nil, false end
  local e = LibQuestieDB[entity]
  local ok, v = pcall(e.GetAll, id, fields)
  if not ok then
    Q:ReportError("QuestieDB " .. entity .. ".GetAll: " .. tostring(v))
    return nil, true
  end
  return v, false
end

---------------------------------------------------------------------------
-- Conversion des spawns {[areaId] = {{x,y},...}} vers {[uiMapId] = {{x,y},...}}
---------------------------------------------------------------------------
local function convertSpawns(raw)
  local out = {}
  if type(raw) ~= "table" then return out end
  local areas = {}
  for areaId in pairs(raw) do
    if type(areaId) == "number" then areas[#areas + 1] = areaId end
  end
  table.sort(areas)
  for _, areaId in ipairs(areas) do
    local uiMap = Q.Maps and Q.Maps:AreaToUiMap(areaId)
    local points = raw[areaId]
    if uiMap and type(points) == "table" then
      local list = out[uiMap]
      for _, p in ipairs(points) do
        local x, y = p[1], p[2]
        -- {-1,-1} = présence en instance, sans coordonnées utilisables
        if type(x) == "number" and type(y) == "number" and x >= 0 and y >= 0 then
          if not list then list = {}; out[uiMap] = list end
          list[#list + 1] = { x, y }
        end
      end
    end
  end
  return out
end
QDB.ConvertSpawns = convertSpawns

---------------------------------------------------------------------------
-- Quêtes
---------------------------------------------------------------------------
local function buildObjectives(raw)
  local o = {
    creatures = {}, objects = {}, items = {}, killCredit = {}, spells = {},
    reputation = nil,
    -- Liste ordonnée façon Questie (créature, objet, objet de quête, réputation, crédit, sort) :
    -- sert de repli quand le texte du journal ne permet pas d'associer un objectif.
    ordered = {},
  }
  if type(raw) ~= "table" then return o end
  for _, e in ipairs(raw[1] or {}) do
    if type(e) == "table" and type(e[1]) == "number" then
      o.creatures[#o.creatures + 1] = e[1]
      o.ordered[#o.ordered + 1] = { kind = "creature", ids = { e[1] }, text = e[2] }
    end
  end
  for _, e in ipairs(raw[2] or {}) do
    if type(e) == "table" and type(e[1]) == "number" then
      o.objects[#o.objects + 1] = e[1]
      o.ordered[#o.ordered + 1] = { kind = "object", ids = { e[1] }, text = e[2] }
    end
  end
  for _, e in ipairs(raw[3] or {}) do
    if type(e) == "table" and type(e[1]) == "number" then
      o.items[#o.items + 1] = e[1]
      o.ordered[#o.ordered + 1] = { kind = "item", ids = { e[1] }, text = e[2] }
    end
  end
  local rep = raw[4]
  if type(rep) == "table" and type(rep[1]) == "number" and rep[1] ~= 0 then
    o.reputation = { rep[1], rep[2] }
    o.ordered[#o.ordered + 1] = { kind = "reputation", ids = { rep[1] } }
  end
  for _, e in ipairs(raw[5] or {}) do
    if type(e) == "table" then
      local kc = { npcIds = ids(e[1]), base = nz(e[2]), text = e[3] }
      if #kc.npcIds == 0 and kc.base then kc.npcIds = { kc.base } end
      o.killCredit[#o.killCredit + 1] = kc
      o.ordered[#o.ordered + 1] = { kind = "killCredit", ids = kc.npcIds, base = kc.base, text = kc.text }
    end
  end
  for _, e in ipairs(raw[6] or {}) do
    if type(e) == "table" and type(e[1]) == "number" then
      o.spells[#o.spells + 1] = { spellId = e[1], text = e[2], itemId = nz(e[3]) }
      o.ordered[#o.ordered + 1] = { kind = "spell", ids = { e[1] }, text = e[2] }
    end
  end
  return o
end

-- Q.QDB:Quest(id) -> table|nil (mise en cache, à ne pas modifier).
function QDB:Quest(id)
  if type(id) ~= "number" then return nil end
  local c = questCache[id]
  if c ~= nil then return c or nil end
  if not self:IsAvailable() then return nil end
  local v, failed = getAll("Quest", id, QUEST_FIELDS)
  if not v then
    if not failed then questCache[id] = false end
    return nil
  end
  local startedBy = type(v[6]) == "table" and v[6] or {}
  local finishedBy = type(v[7]) == "table" and v[7] or {}
  local skill = v[15]
  local q = {
    id = id,
    name = v[1],
    level = nz(v[2]),
    reqLevel = nz(v[3]),
    races = nz(v[4]),
    classes = nz(v[5]),
    starters = { npcs = ids(startedBy[1]), objects = ids(startedBy[2]), items = ids(startedBy[3]) },
    finishers = { npcs = ids(finishedBy[1]), objects = ids(finishedBy[2]) },
    objectives = buildObjectives(v[8]),
    preSingle = ids(v[9]),
    preGroup = ids(v[10]),
    exclusiveTo = ids(v[11]),
    next = nz(v[12]),
    breadcrumbFor = nz(v[13]),
    specialFlags = type(v[14]) == "number" and v[14] or 0,
    requiredSkill = type(skill) == "table" and nz(skill[1]) or nil,
    sourceItem = type(v[16]) == "number" and nz(v[16]) or nil,   -- objet donné à la prise
    sourceItems = ids(v[17]),                                      -- objets requis (non ramassés)
  }
  questCache[id] = q
  return q
end

---------------------------------------------------------------------------
-- PNJ, objets du monde, objets
---------------------------------------------------------------------------
function QDB:Npc(id)
  if type(id) ~= "number" then return nil end
  local c = npcCache[id]
  if c ~= nil then return c or nil end
  local v, failed = getAll("Npc", id, NPC_FIELDS)
  if not v then
    if self:IsAvailable() and not failed then npcCache[id] = false end
    return nil
  end
  local n = {
    id = id,
    name = v[1],
    minLevel = nz(v[2]),
    maxLevel = nz(v[3]),
    spawns = convertSpawns(v[4]),
    subName = v[5],
    npcFlags = type(v[6]) == "number" and v[6] or 0,
  }
  npcCache[id] = n
  return n
end

function QDB:Object(id)
  if type(id) ~= "number" then return nil end
  local c = objectCache[id]
  if c ~= nil then return c or nil end
  local v, failed = getAll("Object", id, OBJECT_FIELDS)
  if not v then
    if self:IsAvailable() and not failed then objectCache[id] = false end
    return nil
  end
  local o = { id = id, name = v[1], spawns = convertSpawns(v[2]) }
  objectCache[id] = o
  return o
end

function QDB:Item(id)
  if type(id) ~= "number" then return nil end
  local c = itemCache[id]
  if c ~= nil then return c or nil end
  local v, failed = getAll("Item", id, ITEM_FIELDS)
  if not v then
    if self:IsAvailable() and not failed then itemCache[id] = false end
    return nil
  end
  local i = { id = id, name = v[1], npcDrops = ids(v[2]), objectDrops = ids(v[3]) }
  itemCache[id] = i
  return i
end

---------------------------------------------------------------------------
-- Noms (QuestieDB d'abord, puis le client, puis l'ID)
---------------------------------------------------------------------------
function QDB:QuestName(id)
  local q = self:Quest(id)
  if q and type(q.name) == "string" and q.name ~= "" then return q.name end
  -- Q.API.QuestTitle : C_QuestLog.GetTitleForQuestID
  local title = Q.API and Q.API.QuestTitle(id)
  if title then return title end
  return "#" .. tostring(id)
end

function QDB:NpcName(id)
  local n = self:Npc(id)
  if n and type(n.name) == "string" and n.name ~= "" then return n.name end
  return "#" .. tostring(id)
end

function QDB:ObjectName(id)
  local o = self:Object(id)
  if o and type(o.name) == "string" and o.name ~= "" then return o.name end
  return "#" .. tostring(id)
end

function QDB:ItemName(id)
  local i = self:Item(id)
  if i and type(i.name) == "string" and i.name ~= "" then return i.name end
  if type(id) == "number" and C_Item and C_Item.GetItemNameByID then
    local ok, name = pcall(C_Item.GetItemNameByID, id)
    if ok and type(name) == "string" and name ~= "" then return name end
  end
  return "#" .. tostring(id)
end

---------------------------------------------------------------------------
-- Éligibilité et prérequis
---------------------------------------------------------------------------
-- Race et classe (masques QuestieDB). Une quête inconnue n'est jamais bloquée.
function QDB:IsEligible(id, raceBit, classBit)
  local q = self:Quest(id)
  if not q then return true end
  return Q.Util.MaskAllows(q.races, raceBit) and Q.Util.MaskAllows(q.classes, classBit)
end

-- Une quête exclusive « sœur » rendue compte comme le prérequis lui-même (règle de Questie).
local function doneOrSibling(self, p, isDone)
  if isDone(p) then return true end
  local pq = self:Quest(p)
  if pq then
    for _, x in ipairs(pq.exclusiveTo) do
      if isDone(x) then return true end
    end
  end
  return false
end

-- preQuestSingle : au moins une faite ; preQuestGroup : toutes faites ; exclusiveTo : aucune faite.
function QDB:PrereqsMet(id, isDone)
  local q = self:Quest(id)
  if not q then return true end
  if #q.preSingle > 0 then
    local any = false
    for _, p in ipairs(q.preSingle) do
      if isDone(p) then any = true; break end
    end
    if not any then return false end
  end
  for _, p in ipairs(q.preGroup) do
    if not doneOrSibling(self, p, isDone) then return false end
  end
  for _, x in ipairs(q.exclusiveTo) do
    if isDone(x) then return false end
  end
  return true
end
