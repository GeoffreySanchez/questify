local addonName, Q = ...

-- Automatisation (spec § 5.6) : accepter et rendre les quêtes de la route, choisir la récompense.
-- Rien ne tourne si l'option `autoQuest` est coupée, si Maj est maintenu, ni sans QuestieDB.
local AutoQuest = {}
Q.AutoQuest = AutoQuest

local RETRY_DELAY = 0.5   -- secondes : objets de récompense pas encore en cache

local routeSet            -- { [questId] = true } ; nil = à reconstruire

---------------------------------------------------------------------------
-- Quêtes de la route
---------------------------------------------------------------------------
-- Même filtrage que le moteur de progression : une étape qui ne concerne pas ce personnage
-- (race, classe, quêtes de donjon coupées) ne rend pas sa quête « de la route ».
local function stepApplies(step)
  local P = Q.Player
  if step.race and not Q.Util.Contains(step.race, P.raceKey) then return false end
  if step.class and not Q.Util.Contains(step.class, P.classFile) then return false end
  if step.optional and Q.Settings:Get("dungeonQuests") == false then return false end
  return true
end

local function addSteps(set, steps)
  if type(steps) ~= "table" then return end
  for _, step in ipairs(steps) do
    local a = step.action
    if (a == "accept" or a == "turnin") and type(step.questId) == "number" and stepApplies(step) then
      set[step.questId] = true
    end
  end
end

local function rebuild()
  local set = {}
  local faction = Q.Player and Q.Player.faction
  local raceKey = Q.Player and Q.Player.raceKey
  for _, guide in ipairs(Q.Guides:All()) do
    -- même règle que Q.Guides:ForPlayer : un chapitre réservé à d'autres races n'est pas la route
    local racesOk = guide.races == nil or Q.Util.Contains(guide.races, raceKey)
    if (guide.faction == nil or guide.faction == faction) and racesOk then addSteps(set, guide.steps) end
  end
  local inserted = Q.char and Q.char.inserted
  if type(inserted) == "table" then
    for _, group in ipairs(inserted) do
      if type(group) == "table" then addSteps(set, group.steps) end
    end
  end
  routeSet = set
  return set
end

-- IsRouteQuest(id) : une étape accept/turnin d'un chapitre de la faction, ou d'une chaîne
-- insérée, mentionne cette quête.
function AutoQuest:IsRouteQuest(id)
  if type(id) ~= "number" then return false end
  local set = routeSet or rebuild()
  return set[id] == true
end

-- L'ensemble est reconstruit à la prochaine question après ces évènements.
local function invalidate() routeSet = nil end
Q:On("GUIDE_CHANGED", invalidate)
Q:On("CLASSQUESTS_CHANGED", invalidate)
Q:On("LOGIN", invalidate)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "dungeonQuests" then invalidate() end
end)

---------------------------------------------------------------------------
-- Garde-fous
---------------------------------------------------------------------------
local function active()
  if not Q.Progress:IsEnabled() then return false end
  if Q.Settings:Get("autoQuest") == false then return false end
  if IsShiftKeyDown and IsShiftKeyDown() then return false end
  return true
end

---------------------------------------------------------------------------
-- Gestionnaires
---------------------------------------------------------------------------
Q:RegisterEvent("QUEST_DETAIL", function()
  if not active() then return end
  if AutoQuest:IsRouteQuest(GetQuestID()) then AcceptQuest() end
end)

-- Fenêtre de dialogue : d'abord rendre une quête terminée, sinon en prendre une. Un seul
-- choix par évènement (le dialogue se rouvre ensuite et relance l'évènement).
Q:RegisterEvent("GOSSIP_SHOW", function()
  if not active() then return end
  for _, q in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
    if q.isComplete and AutoQuest:IsRouteQuest(q.questID) then
      C_GossipInfo.SelectActiveQuest(q.questID)
      return
    end
  end
  for _, q in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
    if AutoQuest:IsRouteQuest(q.questID) then
      C_GossipInfo.SelectAvailableQuest(q.questID)
      return
    end
  end
end)

---------------------------------------------------------------------------
-- Fenêtre sans dialogue sur Classic Era : titres seulement
---------------------------------------------------------------------------
-- PNJ (ou objet) qui a ouvert la fenêtre : { kind = "npc"|"object", id } d'après le 6e champ du
-- GUID de l'unité « npc ». nil si le GUID est absent, secret ou d'un autre type.
local function greetingSource()
  if type(UnitGUID) ~= "function" then return nil end
  local guid = UnitGUID("npc")
  if Q.Util.IsSecret(guid) or type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  id = tonumber(id)
  if not id then return nil end
  if kind == "Creature" or kind == "Vehicle" then return { kind = "npc", id = id } end
  if kind == "GameObject" then return { kind = "object", id = id } end
  return nil
end

-- Vrai si ce PNJ ou objet donne (wantLog = false) ou reçoit (wantLog = true) la quête (QuestieDB).
local function boundTo(id, source, wantLog)
  local q = Q.QDB:Quest(id)
  if not q then return false end
  local side = wantLog and q.finishers or q.starters
  local list = side and (source.kind == "npc" and side.npcs or side.objects)
  return Q.Util.Contains(list or {}, source.id)
end

-- Distance (en étapes) entre l'étape courante et la prochaine étape accept/turnin de la quête,
-- en avançant puis en reprenant au début. nil si aucune étape ne la mentionne.
local function stepDistance(id, action)
  local list = Q.Progress:Entries()
  local n = #list
  if n == 0 then return nil end
  local cur, start = Q.Progress:Current(), 1
  if cur then
    for i, e in ipairs(list) do
      if e.key == cur.key then start = i; break end
    end
  end
  for k = 0, n - 1 do
    local s = list[(start - 1 + k) % n + 1].step
    if s.action == action and s.questId == id then return k end
  end
  return nil
end

-- Quête de la route qui correspond au titre, pour ce PNJ. Sur Classic Era, la fenêtre sans dialogue
-- ne donne que le titre (pas de GetActiveQuestID, GetAvailableQuestInfo sans ID). Candidates :
--   - liées au PNJ ou à l'objet (QuestieDB : donneur pour la liste disponible, receveur pour la liste
--     en cours), et de même titre (titre du client, puis nom QuestieDB) ;
--   - en cours (wantLog) : dans le journal ; disponible : ni dans le journal ni rendue, éligible,
--     prérequis rendus.
-- Plusieurs quêtes de même titre (233/234, 282/420) : la plus proche de l'étape courante. Égalité
-- ou aucune étape : on ne choisit pas (le joueur clique).
local function routeQuestByTitle(title, wantLog, source)
  if type(title) ~= "string" or not source then return nil end
  local set = routeSet or rebuild()
  local isDone = function(x) return Q.Progress:IsTurnedIn(x) end
  local P = Q.Player or {}
  local best, bestDist, tie
  for id in pairs(set) do
    local ok
    if wantLog then
      ok = Q.API.IsOnQuest(id)
    else
      ok = not Q.API.IsOnQuest(id) and not isDone(id) and Q.QDB:IsEligible(id, P.raceBit, P.classBit)
        and Q.QDB:PrereqsMet(id, isDone)
    end
    if ok and boundTo(id, source, wantLog) and (Q.API.QuestTitle(id) == title or Q.QDB:QuestName(id) == title) then
      local d = stepDistance(id, wantLog and "turnin" or "accept") or math.huge
      if not best or d < bestDist then
        best, bestDist, tie = id, d, false
      elseif d == bestDist then
        tie = true
      end
    end
  end
  if tie then return nil end
  return best
end

-- MatchGreetingTitle(title, wantLog) -> questId | nil : la quête de la route que désigne ce titre
-- pour le PNJ de la fenêtre ouverte (UnitGUID("npc")). Publique pour le journal de débogage et les tests.
function AutoQuest:MatchGreetingTitle(title, wantLog)
  return routeQuestByTitle(title, wantLog and true or false, greetingSource())
end

-- Classic Era (pas de GetActiveQuestID) : ID quand le client le donne, sinon le titre lié au PNJ ;
-- l'état « terminée » de GetActiveTitle peut valoir 1 ou manquer : le journal fait alors foi.
local function eraGreeting()
  local source = greetingSource()
  if GetNumActiveQuests and SelectActiveQuest then
    for i = 1, GetNumActiveQuests() or 0 do
      local id, title = Q.API.GreetingQuest(i, true)
      id = id or routeQuestByTitle(title, true, source)
      local complete = false
      if id then
        local done
        if GetActiveTitle then done = select(2, GetActiveTitle(i)) end
        if done ~= nil then complete = done == true or done == 1 else complete = Q.API.IsQuestComplete(id) end
      end
      if complete and AutoQuest:IsRouteQuest(id) then
        SelectActiveQuest(i)
        return
      end
    end
  end
  if GetNumAvailableQuests and SelectAvailableQuest then
    for i = 1, GetNumAvailableQuests() or 0 do
      local id, title = Q.API.GreetingQuest(i, false)
      id = id or routeQuestByTitle(title, false, source)
      if AutoQuest:IsRouteQuest(id) then
        SelectAvailableQuest(i)
        return
      end
    end
  end
end

-- PNJ sans dialogue : mêmes règles, mais la sélection se fait par position dans la liste.
Q:RegisterEvent("QUEST_GREETING", function()
  if not active() then return end
  if not GetActiveQuestID then return eraGreeting() end
  if GetNumActiveQuests and GetActiveQuestID and SelectActiveQuest then
    for i = 1, GetNumActiveQuests() or 0 do
      local complete = true
      if GetActiveTitle then
        local _, done = GetActiveTitle(i)
        complete = done == true
      end
      if complete and AutoQuest:IsRouteQuest(GetActiveQuestID(i)) then
        SelectActiveQuest(i)
        return
      end
    end
  end
  if GetNumAvailableQuests and GetAvailableQuestInfo and SelectAvailableQuest then
    for i = 1, GetNumAvailableQuests() or 0 do
      local _, _, _, _, questId = GetAvailableQuestInfo(i)
      if AutoQuest:IsRouteQuest(questId) then
        SelectAvailableQuest(i)
        return
      end
    end
  end
end)

Q:RegisterEvent("QUEST_PROGRESS", function()
  if not active() then return end
  if IsQuestCompletable() and AutoQuest:IsRouteQuest(GetQuestID()) then CompleteQuest() end
end)

-- Récompense : un seul choix, ou le meilleur selon Q.Rewards.
local pending = 0   -- jeton de la relecture différée ; changé à chaque nouvelle fenêtre

-- La fenêtre de récompense montre toujours la quête attendue, et l'automatisation reste voulue.
local function stillWanted(questId, n)
  if not active() or Q.Settings:Get("autoReward") == false then return false end
  if GetQuestID() ~= questId or not AutoQuest:IsRouteQuest(questId) then return false end
  return (GetNumQuestChoices() or 0) == n
end

local function chooseReward(questId, n, retried)
  local choices = Q.Rewards:CollectChoices()
  if not Q.Rewards:AllLoaded(choices) then
    if retried then
      -- un choix à l'aveugle est irréversible : on laisse le joueur choisir
      Q:Print(Q.L.REWARD_NOT_LOADED)
      return
    end
    -- objets pas encore en cache : le client les charge, on regarde une seconde fois
    Q.Rewards:RequestLoad(choices)
    local token = pending
    Q:After(RETRY_DELAY, function()
      if token ~= pending or not stillWanted(questId, n) then return end
      chooseReward(questId, n, true)
    end)
    return
  end
  local index, reason, detail = Q.Rewards:Pick(choices, Q.Player)
  if not index then return end
  local link
  for _, c in ipairs(choices) do
    if c.index == index then link = c.link; break end
  end
  GetQuestReward(index)
  Q:Print(Q.Rewards:Describe(reason, link, detail))
end

Q:RegisterEvent("QUEST_COMPLETE", function()
  pending = pending + 1
  if not active() then return end
  local questId = GetQuestID()
  if not AutoQuest:IsRouteQuest(questId) then return end
  local n = GetNumQuestChoices() or 0
  if n <= 1 then
    GetQuestReward(n)
  elseif Q.Settings:Get("autoReward") ~= false then
    chooseReward(questId, n, false)
  end
end)

-- Fenêtre fermée : on annule une relecture en attente.
Q:RegisterEvent("QUEST_FINISHED", function()
  pending = pending + 1
end)
