local addonName, Q = ...

-- Garde-fou contre les étapes impossibles (quête retirée ou modifiée par un correctif) : quand le
-- joueur parle au donneur d'une étape « prendre » et que celui-ci ne propose pas la quête attendue
-- (liste de quêtes avec identifiants : dialogue ou fenêtre de quêtes), l'étape est passée avec un
-- message, au lieu de bloquer la route. /qf back la rouvre. Rien n'est fait si la quête n'est pas
-- encore prenable selon l'addon (niveau), ni si la liste n'a pas d'identifiants.
-- Pas de saut non plus (une ligne d'aide à la place, une fois par étape) quand l'absence a une
-- autre explication : quête grise pour le joueur (cachée des dialogues sans le suivi des quêtes
-- de bas niveau), ou prérequis pas encore faits (Q.QDB:PrereqsMet).
local Guard = {}
Q.StepGuard = Guard

local hinted = {}   -- [clé d'étape] = true : aide déjà affichée pendant cette session

local function npcId()
  if type(UnitGUID) ~= "function" then return nil end
  local ok, guid = pcall(UnitGUID, "npc")
  if not ok or Q.Util.IsSecret(guid) or type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind ~= "Creature" then return nil end
  return tonumber(id)
end

local function contains(list, v)
  for _, x in ipairs(list or {}) do if x == v then return true end end
  return false
end

local function plainValue(v)
  if Q.Util.IsSecret(v) then return nil end
  return v
end

-- Quête grise (triviale) pour le joueur : C_QuestLog.IsQuestTrivial, ou niveau de la quête plus
-- bas que le niveau du joueur moins UnitQuestTrivialLevelRange (règle de DifficultyUtil).
function Guard:IsTrivial(qid, q)
  if type(C_QuestLog) == "table" and type(C_QuestLog.IsQuestTrivial) == "function" then
    local ok, v = pcall(C_QuestLog.IsQuestTrivial, qid)
    if ok and plainValue(v) == true then return true end
  end
  local qLevel, pLevel = q and q.level, Q.Player and Q.Player.level
  if type(qLevel) ~= "number" or qLevel <= 0 or type(pLevel) ~= "number" then return false end
  if type(UnitQuestTrivialLevelRange) ~= "function" then return false end
  local ok, range = pcall(UnitQuestTrivialLevelRange, "player")
  range = ok and plainValue(range) or nil
  if type(range) ~= "number" then return false end
  return pLevel - qLevel > range
end

local function isTurnedIn(id) return Q.Progress:IsTurnedIn(id) end

local function hint(key, fmt, ...)
  if hinted[key] then return end
  hinted[key] = true
  Q:Print(fmt, ...)
end

-- Vérifie l'étape courante contre la liste des quêtes proposées (identifiants).
function Guard:Check(offered)
  if not (Q.Progress and Q.Progress:IsEnabled()) or type(offered) ~= "table" then return false end
  local cur = Q.Progress:Current()
  if not cur or cur.step.action ~= "accept" then return false end
  local qid = cur.step.questId
  local state = Q.Progress:State(cur)
  if state ~= "active" or Q.Progress:InLog(qid) or Q.Progress:IsTurnedIn(qid) then return false end
  local q = Q.QDB:Quest(qid)
  local id = npcId()
  if not (q and id and contains(q.starters.npcs, id)) then return false end
  if contains(offered, qid) then return false end
  local L = Q.L
  if self:IsTrivial(qid, q) then
    hint(cur.key, L.GUARD_HINT_TRIVIAL, Q.QDB:QuestName(qid), Q.QDB:NpcName(id))
    return false
  end
  if not Q.QDB:PrereqsMet(qid, isTurnedIn) then
    hint(cur.key, L.GUARD_HINT_PREREQ, Q.QDB:QuestName(qid), Q.QDB:NpcName(id))
    return false
  end
  Q.Progress:Skip(cur.key)
  Q:Print(Q.L.GUARD_UNAVAILABLE, Q.QDB:QuestName(qid), Q.QDB:NpcName(id))
  return true
end

Q:RegisterEvent("GOSSIP_SHOW", function()
  if not (C_GossipInfo and C_GossipInfo.GetAvailableQuests) then return end
  local offered = {}
  for _, q in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do offered[#offered + 1] = q.questID end
  for _, q in ipairs(C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or {}) do offered[#offered + 1] = q.questID end
  Q.SafeCall(Guard.Check, Guard, offered)
end)

Q:RegisterEvent("QUEST_GREETING", function()
  if not (GetNumAvailableQuests and GetAvailableQuestInfo) then return end
  local offered = {}
  for i = 1, GetNumAvailableQuests() or 0 do
    local questId = select(5, GetAvailableQuestInfo(i))
    if type(questId) ~= "number" or questId == 0 then return end   -- ID inconnu : on ne juge pas
    offered[#offered + 1] = questId
  end
  Q.SafeCall(Guard.Check, Guard, offered)
end)
