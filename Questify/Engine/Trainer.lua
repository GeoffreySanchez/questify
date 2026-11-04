local addonName, Q = ...

-- Sorts de classe à apprendre et maître de classe le plus proche.
-- Le client ne donne la liste des sorts de classe (niveau requis, coût) qu'en parlant à un maître
-- de classe : elle est relevée à chaque visite (TRAINER_SHOW, TRAINER_UPDATE) et gardée par
-- personnage dans Q.char.trainer. Avant la première visite, on suppose de nouveaux sorts à chaque
-- niveau pair (règle de Classic).
-- Tant qu'il reste des sorts apprenables à ce niveau, le suivi affiche une alerte ; un clic insère
-- une étape « train » vers le maître de classe le plus proche (IDs de Data/ClassTrainers.lua,
-- positions lues dans QuestieDB). L'étape disparaît à la visite du maître ou quand plus rien n'est
-- à apprendre.
local Trainer = {}
Q.Trainer = Trainer

local TAG = "trainer"

local function setting(path) return Q.Settings:Get(path) end

local function state()
  if not Q.char then return nil end
  local t = Q.char.trainer
  if type(t) ~= "table" then
    t = {}
    Q.char.trainer = t
  end
  return t
end

local function playerLevel() return Q.Player.level or 1 end

---------------------------------------------------------------------------
-- Maîtres de classe
---------------------------------------------------------------------------
-- IDs des maîtres de la classe et de la faction du joueur.
function Trainer:TrainerIds()
  local data = Q.ClassTrainerData
  local P = Q.Player
  local byClass = type(data) == "table" and P.classFile and data[P.classFile]
  if type(byClass) ~= "table" then return {} end
  local fac = (P.faction == "Alliance" and "A") or (P.faction == "Horde" and "H") or nil
  if not fac then return {} end
  local out = {}
  for i, id in ipairs(byClass[fac] or {}) do out[i] = id end
  return out
end

function Trainer:IsClassTrainer(npcId)
  if type(npcId) ~= "number" then return false end
  for _, id in ipairs(self:TrainerIds()) do
    if id == npcId then return true end
  end
  return false
end

-- PNJ de la fenêtre de maître ouverte (champ 6 du GUID), nil si inconnu ou secret.
local function trainerNpcId()
  if type(UnitGUID) ~= "function" then return nil end
  local ok, guid = pcall(UnitGUID, "npc")
  if not ok or Q.Util.IsSecret(guid) or type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind ~= "Creature" then return nil end
  return tonumber(id)
end

---------------------------------------------------------------------------
-- Lecture de la fenêtre du maître
---------------------------------------------------------------------------
-- Les filtres de la fenêtre (disponible / indisponible / déjà appris) ne sont jamais touchés :
-- les changer relance TRAINER_UPDATE, donc une nouvelle lecture, et la fenêtre se redessinait
-- sans fin. On lit ce que le joueur voit (par défaut : disponibles et indisponibles).
local reading = false     -- lecture en cours : les TRAINER_UPDATE qu'elle causerait sont ignorés
local open = false        -- fenêtre du maître ouverte (TRAINER_SHOW -> TRAINER_CLOSED)
local pending = false     -- relecture déjà programmée (TRAINER_UPDATE regroupés)
local UPDATE_DELAY = 0.2  -- secondes : plusieurs TRAINER_UPDATE rapprochés -> une seule lecture
Trainer.UPDATE_DELAY = UPDATE_DELAY

-- Sorts listés par le maître : { name, rank, level, cost } pour ceux qui ne sont pas encore appris.
-- Ordre Mainline de GetTrainerServiceInfo (Blizzard_TrainerUI/Mainline) : nom, type
-- ("available", "unavailable", "used", "header"), icône, niveau requis, sous-texte (rang).
local function readServices()
  if type(GetNumTrainerServices) ~= "function" or type(GetTrainerServiceInfo) ~= "function" then return nil end
  local list = {}
  local ok, err = pcall(function()
    for i = 1, (GetNumTrainerServices() or 0) do
      local name, serviceType, _, reqLevel, subText = GetTrainerServiceInfo(i)
      if type(name) == "string" and name ~= "" and serviceType ~= "header" and serviceType ~= "used" then
        local level = tonumber(reqLevel)
        if serviceType == "available" and not level then level = 0 end
        local cost = type(GetTrainerServiceCost) == "function" and tonumber((GetTrainerServiceCost(i))) or 0
        local rank = type(subText) == "string" and subText ~= "" and subText or nil
        list[#list + 1] = { name = name, rank = rank, level = level, cost = cost or 0 }
      end
    end
  end)
  if not ok then
    Q:ReportError(err)
    return nil
  end
  return list
end

local function sameList(a, b)
  if type(a) ~= "table" or type(b) ~= "table" or #a ~= #b then return false end
  for i, s in ipairs(a) do
    local o = b[i]
    if type(o) ~= "table" or o.name ~= s.name or o.rank ~= s.rank or o.level ~= s.level or o.cost ~= s.cost then
      return false
    end
  end
  return true
end

-- Visite d'un maître : la liste est relevée si c'est un maître de classe du joueur.
-- -> true si la liste a été relevée.
function Trainer:OnTrainer()
  if reading then return false end
  local t = state()
  if not t then return false end
  if type(IsTradeskillTrainer) == "function" and IsTradeskillTrainer() then return false end
  local npcId = trainerNpcId()
  if npcId and not self:IsClassTrainer(npcId) then return false end   -- autre maître (familiers, autre classe)
  reading = true
  local list = readServices()
  reading = false
  if not list then return false end
  local changed = not sameList(list, t.services) or t.visitLevel ~= playerLevel()
  t.services = list
  t.visitLevel = playerLevel()
  if changed then
    self:Sync()
    Q:Fire("TRAINER_CHANGED")
  end
  return true
end

-- TRAINER_UPDATE (sort appris, filtre changé par le joueur) : une seule relecture différée, et
-- seulement fenêtre ouverte (fermée, la liste du client est vide).
function Trainer:OnUpdateEvent()
  if reading or pending or not open then return end
  pending = true
  Q:After(UPDATE_DELAY, function()
    pending = false
    if open then Trainer:OnTrainer() end
  end)
end

---------------------------------------------------------------------------
-- Sorts à apprendre
---------------------------------------------------------------------------
local function serviceLabel(s)
  if s.rank and s.rank ~= "" then return s.name .. " (" .. s.rank .. ")" end
  return s.name
end

-- Coût estimé du sort le moins cher par niveau pair (cuivre, ordre de grandeur de Classic) :
-- avant la première visite, l'alerte attend au moins cette somme.
local GUESS_COST = { [2] = 10, [4] = 100, [6] = 100, [8] = 200, [10] = 300, [12] = 800, [14] = 900, [16] = 1500,
  [18] = 1800, [20] = 2000, [22] = 3000, [24] = 4000, [26] = 5000, [28] = 6000, [30] = 7000 }

local function playerMoney()
  if type(GetMoney) ~= "function" then return math.huge end
  local ok, m = pcall(GetMoney)
  if not ok or Q.Util.IsSecret(m) then return math.huge end
  return tonumber(m) or math.huge
end
Trainer.GUESS_COST = GUESS_COST

-- Learnable() -> { count, total, cost, missing, names, known, since } ou nil si rien d'apprenable
-- et payable à ce niveau.
--   count / cost / names : sorts que l'or du joueur permet de payer (les moins chers d'abord) ;
--   total : sorts disponibles à ce niveau ; missing : coût des sorts restants (or manquant).
--   since : niveau où le dernier sort payable est devenu disponible (une annonce par vague).
--   known = faux : pas encore de visite, supposition des niveaux pairs (coût estimé).
function Trainer:Learnable()
  local t = state()
  if not t then return nil end
  local lvl = playerLevel()
  local money = playerMoney()
  if type(t.services) == "table" then
    local avail = {}
    for _, s in ipairs(t.services) do
      if type(s) == "table" and s.level and s.level <= lvl then avail[#avail + 1] = s end
    end
    table.sort(avail, function(a, b)
      if (a.cost or 0) ~= (b.cost or 0) then return (a.cost or 0) < (b.cost or 0) end
      return (a.level or 0) < (b.level or 0)
    end)
    local out = { count = 0, total = #avail, cost = 0, missing = 0, names = {}, known = true, since = 0 }
    for _, s in ipairs(avail) do
      local c = s.cost or 0
      if out.cost + c <= money then
        out.count = out.count + 1
        out.cost = out.cost + c
        out.since = math.max(out.since, s.level)
        out.names[#out.names + 1] = serviceLabel(s)
      else
        out.missing = out.missing + c
      end
    end
    if out.count == 0 then return nil end
    return out
  end
  local lastEven = lvl - lvl % 2
  if lastEven >= 2 and lastEven > (t.visitLevel or 1) then
    local need = GUESS_COST[lastEven] or 0
    if money < need then return nil end
    return { count = 0, total = 0, cost = 0, missing = 0, names = {}, known = false, since = lastEven }
  end
  return nil
end

function Trainer:HasStep()
  local c = Q.char
  for _, group in ipairs(c and c.inserted or {}) do
    if type(group) == "table" and group.tag == TAG then return true end
  end
  return false
end

-- Alert() -> même table que Learnable() quand l'alerte doit s'afficher, sinon nil.
function Trainer:Alert()
  if setting("trainerAlert") == false then return nil end
  if not (Q.Progress and Q.Progress:IsEnabled()) then return nil end
  if #self:TrainerIds() == 0 then return nil end
  local t = state()
  if not t or t.snooze == playerLevel() then return nil end
  if self:HasStep() then return nil end
  return self:Learnable()
end

-- Clic sur l'alerte : étape vers le maître de classe le plus proche, avant la route.
function Trainer:Go()
  if not self:Learnable() then return false end
  Q.Progress:InsertSteps(TAG, { { "train" } })
  Q:Fire("TRAINER_CHANGED")
  return true
end

-- Clic droit : plus d'alerte avant le prochain niveau.
function Trainer:Snooze()
  local t = state()
  if not t then return end
  t.snooze = playerLevel()
  Q:Fire("TRAINER_CHANGED")
end

-- Étape retirée quand il n'y a plus rien à apprendre ; un message au premier passage à un niveau
-- où de nouveaux sorts arrivent. Appelé après chaque recalcul de la progression (avant le suivi).
function Trainer:Sync()
  local t = state()
  if not t then return end
  if self:HasStep() and not self:Learnable() then
    Q.Progress:RemoveInserted(TAG)
    return   -- RemoveInserted relance la progression, donc Sync
  end
  local alert = self:Alert()
  if alert and (t.announced or 0) < alert.since then
    t.announced = alert.since
    if alert.known then
      Q:Print(Q.L.TRAINER_NEW_SPELLS, alert.count)
    else
      Q:Print(Q.L.TRAINER_MAYBE_SPELLS)
    end
  end
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
Q:RegisterEvent("TRAINER_SHOW", function()
  open = true
  -- la visite d'un maître de classe valide l'étape, même s'il reste des sorts trop chers
  if Trainer:OnTrainer() and Trainer:HasStep() then
    Q.Progress:RemoveInserted(TAG)
    Q:Fire("TRAINER_CHANGED")
  end
end)
Q:RegisterEvent("TRAINER_UPDATE", function() Trainer:OnUpdateEvent() end)
Q:RegisterEvent("TRAINER_CLOSED", function() open = false end)
-- l'or change : l'alerte apparaît ou disparaît
Q:RegisterEvent("PLAYER_MONEY", function()
  Trainer:Sync()
  Q:Fire("TRAINER_CHANGED")
end)
Q:On("PROGRESS_UPDATED", function() Trainer:Sync() end)
Q:On("LOGIN", function() Trainer:Sync() end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "trainerAlert" then Q:Fire("TRAINER_CHANGED") end
end)
