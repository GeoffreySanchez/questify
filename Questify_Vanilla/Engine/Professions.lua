local addonName, Q = ...

-- Métiers choisis par le joueur et étapes chez les maîtres de métier.
-- Le joueur choisit ses métiers une fois par personnage (UI/ProfessionPicker.lua) : deux métiers
-- principaux au plus, et les métiers secondaires qu'il veut. Quand un maître d'un métier choisi et
-- pas encore appris est proche (PROF_NEAR yards), une étape « trainprof » s'insère avant la route :
-- c'est l'étape réelle, au moment où l'on passe en ville. Elle disparaît quand le métier est connu
-- (sort d'Apprenti) ou après la visite d'un maître de ce métier.
local Professions = {}
Q.Professions = Professions

local TAG_PREFIX = "prof:"
local CHECK_INTERVAL = 5    -- secondes entre deux recherches de maître proche
local PROF_NEAR = 400       -- yards

-- clé, sort d'Apprenti (Classic), principal ?
Professions.LIST = {
  { key = "ALCHEMY", spell = 2259, primary = true },
  { key = "BLACKSMITHING", spell = 2018, primary = true },
  { key = "ENCHANTING", spell = 7411, primary = true },
  { key = "ENGINEERING", spell = 4036, primary = true },
  { key = "HERBALISM", spell = 2366, primary = true },
  { key = "LEATHERWORKING", spell = 2108, primary = true },
  { key = "MINING", spell = 2575, primary = true },
  { key = "SKINNING", spell = 8613, primary = true },
  { key = "TAILORING", spell = 3908, primary = true },
  { key = "COOKING", spell = 2550 },
  { key = "FIRSTAID", spell = 3273 },
  { key = "FISHING", spell = 7620 },
}
Professions.MAX_PRIMARY = 2

local BY_KEY = {}
for _, p in ipairs(Professions.LIST) do BY_KEY[p.key] = p end
Professions.BY_KEY = BY_KEY

local function char()
  return Q.char
end

function Professions:Name(key)
  return Q.L["PROF_" .. tostring(key)] or tostring(key)
end

---------------------------------------------------------------------------
-- Choix
---------------------------------------------------------------------------
-- Chosen() -> { [key] = true } ou nil si le joueur n'a pas encore répondu.
function Professions:Chosen()
  local c = char()
  return c and c.professions or nil
end

function Professions:HasAnswered()
  return self:Chosen() ~= nil
end

-- SetChosen({ [key] = true }) : garde au plus MAX_PRIMARY métiers principaux (dans l'ordre de LIST).
function Professions:SetChosen(set)
  local c = char()
  if not c then return false end
  local out, primaries = {}, 0
  for _, p in ipairs(self.LIST) do
    if type(set) == "table" and set[p.key] then
      if not p.primary or primaries < self.MAX_PRIMARY then
        out[p.key] = true
        if p.primary then primaries = primaries + 1 end
      end
    end
  end
  c.professions = out
  -- métiers retirés : leurs étapes partent
  for _, p in ipairs(self.LIST) do
    if not out[p.key] then self:RemoveStep(p.key) end
  end
  Q:Fire("PROFESSIONS_CHANGED")
  self:Check()
  return true
end

---------------------------------------------------------------------------
-- Métiers connus
---------------------------------------------------------------------------
function Professions:Known(key)
  local p = BY_KEY[key]
  if not p then return false end
  local c = char()
  if c and c.profLearned and c.profLearned[key] then return true end
  for _, fn in ipairs({ IsPlayerSpell, IsSpellKnown }) do
    if type(fn) == "function" then
      local ok, known = pcall(fn, p.spell)
      if ok and known == true then return true end
    end
  end
  return false
end

-- Maîtres du métier pour la faction du joueur.
function Professions:TrainerIds(key)
  local data = Q.ProfTrainerData
  local byProf = type(data) == "table" and data[key]
  local fac = (Q.Player.faction == "Alliance" and "A") or (Q.Player.faction == "Horde" and "H") or nil
  if type(byProf) ~= "table" or not fac then return {} end
  local out = {}
  for i, id in ipairs(byProf[fac] or {}) do out[i] = id end
  return out
end

-- Métier enseigné par ce PNJ parmi ceux choisis, sinon nil.
function Professions:ProfOfTrainer(npcId)
  if type(npcId) ~= "number" then return nil end
  for _, p in ipairs(self.LIST) do
    for _, id in ipairs(self:TrainerIds(p.key)) do
      if id == npcId then return p.key end
    end
  end
  return nil
end

---------------------------------------------------------------------------
-- Étapes
---------------------------------------------------------------------------
function Professions:HasStep(key)
  local c = char()
  for _, group in ipairs(c and c.inserted or {}) do
    if type(group) == "table" and group.tag == TAG_PREFIX .. key then return true end
  end
  return false
end

function Professions:RemoveStep(key)
  if self:HasStep(key) then Q.Progress:RemoveInserted(TAG_PREFIX .. key) end
end

-- Plus proche maître du métier : -> distance (yards) ou nil.
local function nearestTrainer(key)
  local pm, px, py = Q.Maps:PlayerPos()
  if not pm then return nil end
  local best
  for _, id in ipairs(Professions:TrainerIds(key)) do
    local npc = Q.QDB:Npc(id)
    if npc and npc.spawns then
      local _, _, _, d = Q.Maps:Nearest(npc.spawns, pm, px, py)
      if d and (not best or d < best) then best = d end
    end
  end
  return best
end

-- Métiers choisis, pas encore appris, sans étape : étape insérée si un maître est proche ;
-- étapes des métiers appris retirées.
function Professions:Check()
  if not (Q.Progress and Q.Progress:IsEnabled()) then return end
  local chosen = self:Chosen()
  if not chosen then return end
  for _, p in ipairs(self.LIST) do
    if chosen[p.key] then
      if self:Known(p.key) then
        self:RemoveStep(p.key)
      elseif not self:HasStep(p.key) then
        local d = nearestTrainer(p.key)
        if d and d <= PROF_NEAR then
          Q.Progress:InsertSteps(TAG_PREFIX .. p.key, { { "trainprof", prof = p.key } })
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
local function trainerNpcId()
  if type(UnitGUID) ~= "function" then return nil end
  local ok, guid = pcall(UnitGUID, "npc")
  if not ok or Q.Util.IsSecret(guid) or type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind ~= "Creature" then return nil end
  return tonumber(id)
end

-- Visite d'un maître de métier choisi : le métier compte comme appris.
Q:RegisterEvent("TRAINER_SHOW", function()
  if type(IsTradeskillTrainer) == "function" and not IsTradeskillTrainer() then return end
  local key = Professions:ProfOfTrainer(trainerNpcId())
  local chosen = Professions:Chosen()
  if not (key and chosen and chosen[key]) then return end
  local c = char()
  c.profLearned = c.profLearned or {}
  c.profLearned[key] = true
  Professions:RemoveStep(key)
  Q:Fire("PROFESSIONS_CHANGED")
end)

Q:On("LOGIN", function()
  Q:NewTicker(CHECK_INTERVAL, function()
    if InCombatLockdown and InCombatLockdown() then return end
    Q.SafeCall(Professions.Check, Professions)
  end)
end)
-- LEARNED_SPELL_IN_TAB n'existe plus en 12.x : LEARNED_SPELL_IN_SKILL_LINE (SpellBookDocumentation).
for _, event in ipairs({ "SKILL_LINES_CHANGED", "LEARNED_SPELL_IN_SKILL_LINE", "ZONE_CHANGED_NEW_AREA" }) do
  Q:RegisterEvent(event, function() Q.SafeCall(Professions.Check, Professions) end)
end
