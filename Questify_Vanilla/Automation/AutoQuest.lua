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

-- PNJ sans dialogue : mêmes règles, mais la sélection se fait par position dans la liste.
Q:RegisterEvent("QUEST_GREETING", function()
  if not active() then return end
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
