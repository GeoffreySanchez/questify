local addonName, Q = ...

-- Liste des sorts de classe à apprendre (Q.ClassSpellData), avec leur état pour le joueur :
--   known  : déjà appris ;
--   now    : niveau atteint, pas encore appris (chez le maître) ;
--   quest  : le sort exige une chaîne de quêtes de classe pas encore rendue (Q.SpellQuestData) ;
--   soon   : niveau pas encore atteint.
-- Le coût vient du relevé du maître (Q.char.trainer, Engine/Trainer.lua), nil tant qu'inconnu.
local SpellList = {}
Q.SpellList = SpellList

local MAX_LEVEL = 60

local function playerLevel() return Q.Player.level or 1 end

-- Valeur du jeu utilisable : ni secrète ni du mauvais type.
local function clean(v, kind)
  if Q.Util.IsSecret(v) then return nil end
  if type(v) ~= kind then return nil end
  return v
end

local function spellName(id)
  if not (C_Spell and C_Spell.GetSpellName) then return nil end
  local ok, v = pcall(C_Spell.GetSpellName, id)
  return ok and clean(v, "string") or nil
end

local function spellSubtext(id)
  if not (C_Spell and C_Spell.GetSpellSubtext) then return nil end
  local ok, v = pcall(C_Spell.GetSpellSubtext, id)
  v = ok and clean(v, "string") or nil
  if v == "" then return nil end
  return v
end

local function isKnown(id)
  for _, fn in ipairs({ IsPlayerSpell, IsSpellKnown }) do
    if type(fn) == "function" then
      local ok, v = pcall(fn, id)
      if ok and not Q.Util.IsSecret(v) and v == true then return true end
    end
  end
  return false
end

local function money()
  if type(GetMoney) ~= "function" then return 0 end
  local ok, m = pcall(GetMoney)
  if not ok or Q.Util.IsSecret(m) then return 0 end
  return tonumber(m) or 0
end

---------------------------------------------------------------------------
-- Chaînes de rangs
---------------------------------------------------------------------------
-- Rang de chaque sort : position dans la chaîne `supersedes` (1 = premier rang), chaîne = racine.
local function rankPositions(list)
  local byId = {}
  for _, s in ipairs(list) do byId[s.spellID] = s end
  local pos, root = {}, {}
  for _, s in ipairs(list) do
    local n, cur, guard = 1, s, 0
    while cur.supersedes and byId[cur.supersedes] and guard < 100 do
      cur = byId[cur.supersedes]
      n = n + 1
      guard = guard + 1
    end
    pos[s.spellID], root[s.spellID] = n, cur.spellID
  end
  return pos, root
end

---------------------------------------------------------------------------
-- Sorts liés à une chaîne de quêtes
---------------------------------------------------------------------------
local QUEST_STATE = { inprogress = "inlog", available = "available", added = "available",
  upcoming = "upcoming", ignored = "upcoming", done = "done" }

-- Clé et état de la chaîne de quêtes qui convient au joueur (faction, race) : { key, state } ou nil.
local function questFor(spellID, chainStates)
  local keys = type(Q.SpellQuestChains) == "table" and Q.SpellQuestChains[spellID]
  if type(keys) ~= "table" then
    local one = type(Q.SpellQuestData) == "table" and Q.SpellQuestData[spellID]
    keys = one and { one } or nil
  end
  for _, key in ipairs(keys or {}) do
    if chainStates[key] then return key, QUEST_STATE[chainStates[key]] or "upcoming" end
  end
  return nil
end

---------------------------------------------------------------------------
-- Coût du maître
---------------------------------------------------------------------------
local function serviceIndex()
  local byId, byName = {}, {}
  local t = Q.char and Q.char.trainer
  for _, s in ipairs(type(t) == "table" and type(t.services) == "table" and t.services or {}) do
    if type(s) == "table" then
      if s.spellID then byId[s.spellID] = s end
      if type(s.name) == "string" then
        local key = s.name .. "\1" .. ((s.rank ~= "" and s.rank) or "")
        if not byName[key] then byName[key] = s end
      end
    end
  end
  return byId, byName
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
-- Rows() -> { { spellID, name, rank (texte du jeu), rankNum (numéro de rang | nil), level, cost | nil, state, chainKey | nil, questState | nil } }
-- Par chaîne de rangs : le plus haut rang connu, puis chaque rang inconnu au-dessus (jusqu'au niveau 60).
-- Triées par niveau.
local cache = { dirty = true }

-- Invalidate() : le prochain Rows()/Summary() recalcule (appelé à chaque évènement qui change la liste).
function SpellList:Invalidate() cache.dirty = true end

local function buildRows()
  local P = Q.Player
  local all = type(Q.ClassSpellData) == "table" and P.classFile and Q.ClassSpellData[P.classFile]
  if type(all) ~= "table" then return {} end
  local pos, root = rankPositions(all)

  local chainStates = {}
  if Q.ClassQuests then
    for _, r in ipairs(Q.ClassQuests:List()) do chainStates[r.chain.key] = r.state end
  end
  local byId, byName = serviceIndex()
  local lvl = playerLevel()

  -- rang connu le plus haut de chaque chaîne
  local top = {}
  local knownById = {}
  for _, s in ipairs(all) do
    if Q.Util.MaskAllows(s.races, P.raceBit) and isKnown(s.spellID) then
      knownById[s.spellID] = true
      local r = root[s.spellID]
      if not top[r] or pos[s.spellID] > top[r] then top[r] = pos[s.spellID] end
    end
  end

  local chainLen = {}
  for _, s in ipairs(all) do chainLen[root[s.spellID]] = (chainLen[root[s.spellID]] or 0) + 1 end

  local rows = {}
  for index, s in ipairs(all) do
    local id = s.spellID
    if Q.Util.MaskAllows(s.races, P.raceBit) and (s.level or 1) <= MAX_LEVEL then
      local isKnownSpell = knownById[id] == true
      local keep
      if isKnownSpell then keep = pos[id] == top[root[id]]
      else keep = not top[root[id]] or pos[id] > top[root[id]] end
      if keep then
        local name = spellName(id) or ("#" .. id)
        local rawRank = spellSubtext(id)
        local rank = rawRank
        local rankNum
        if chainLen[root[id]] > 1 then rankNum = pos[id]
        elseif rawRank then rankNum = tonumber(rawRank:match("(%d+)")) end
        if not rank and chainLen[root[id]] > 1 then rank = (type(RANK) == "string" and RANK or "Rank") .. " " .. pos[id] end
        local level = s.level or 1
        local cost
        if not isKnownSpell then
          local svc = byId[id] or byName[name .. "\1" .. (rawRank or "")]
          if svc then
            cost = tonumber(svc.cost)
            -- la liste du maître l'emporte sur la donnée générée
            local svcLevel = tonumber(svc.level)
            if svcLevel and svcLevel > 0 then level = svcLevel end
          end
        end
        local chainKey, questState = questFor(id, chainStates)
        local state
        if isKnownSpell then state = "known"
        elseif chainKey and questState ~= "done" then state = "quest"
        elseif level <= lvl then state = "now"
        else state = "soon" end
        rows[#rows + 1] = { spellID = id, name = name, rank = rank, rankNum = rankNum, level = level, cost = cost, state = state,
          chainKey = chainKey, questState = questState, order = index }
      end
    end
  end
  table.sort(rows, function(a, b)
    if a.level ~= b.level then return a.level < b.level end
    return a.order < b.order
  end)
  for _, r in ipairs(rows) do r.order = nil end
  return rows
end

function SpellList:Rows()
  if cache.dirty or not cache.rows then
    cache.rows, cache.summary, cache.dirty = buildRows(), nil, false
  end
  return cache.rows
end

-- Maître de classe le plus proche (même calcul que l'étape « train » : Targets) : { name, zone, distance } ou nil.
local function nearestTrainer()
  if not (Q.Targets and Q.Trainer and #Q.Trainer:TrainerIds() > 0) then return nil end
  local target = Q.Targets:ForEntry({ step = { action = "train" } })
  if not target or not target.id then return nil end
  local name = Q.QDB:NpcName(target.id)
  if type(name) ~= "string" then return nil end
  return { name = name, zone = Q.Maps:MapName(target.mapId),
    distance = Q.Maps:DistanceFromPlayer(target.mapId, target.x, target.y) }
end

-- Summary() -> { now, cost, money, trainer }
--   now : sorts à apprendre maintenant ; cost : somme de leurs coûts connus (cuivre).
function SpellList:Summary()
  local rows = self:Rows()
  if cache.summary then return cache.summary end
  local now, cost = 0, 0
  for _, r in ipairs(rows) do
    if r.state == "now" then
      now = now + 1
      cost = cost + (r.cost or 0)
    end
  end
  cache.summary = { now = now, cost = cost, money = money(), trainer = nearestTrainer() }
  return cache.summary
end

---------------------------------------------------------------------------
-- Évènement interne SPELLS_CHANGED (Q:On), distinct de l'évènement du jeu (Q:RegisterEvent)
---------------------------------------------------------------------------
local pending = false
local function changed()
  cache.dirty = true
  if pending then return end
  pending = true
  Q:After(Q.Trainer and Q.Trainer.UPDATE_DELAY or 0.2, function()
    pending = false
    -- une lecture faite pendant le délai a pu garder l'état d'avant la mise à jour du jeu (M6)
    cache.dirty = true
    Q:Fire("SPELLS_CHANGED")
  end)
end

for _, event in ipairs({ "SPELLS_CHANGED", "LEARNED_SPELL_IN_SKILL_LINE", "TRAINER_UPDATE", "PLAYER_LEVEL_UP",
  "PLAYER_MONEY" }) do
  Q:RegisterEvent(event, changed)
end
Q:On("TRAINER_CHANGED", changed)
Q:On("CLASSQUESTS_CHANGED", changed)
