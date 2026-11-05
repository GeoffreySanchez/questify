local addonName, Q = ...

-- Métiers choisis par le joueur et étapes chez les maîtres de métier.
-- Le joueur choisit ses métiers une fois par personnage (UI/ProfessionPicker.lua) : deux métiers
-- principaux au plus, et les métiers secondaires qu'il veut. Quand un maître d'un métier choisi et
-- pas encore appris est proche (PROF_NEAR yards), une étape « trainprof » s'insère avant la route :
-- c'est l'étape réelle, au moment où l'on passe en ville. Elle ne s'insère que si le joueur a l'argent
-- du rang, et disparaît quand le jeu confirme le rang (sort d'Apprenti connu, compétence présente
-- dans GetProfessionInfo). Une simple visite chez le maître ne compte pas : sans argent on repart
-- les mains vides et l'étape doit revenir. Une fois le métier appris, une étape pour le rang suivant
-- (Compagnon, Expert, Artisan) s'insère quand la compétence, le niveau et l'argent le permettent.
-- Hystérésis : l'étape (et son état « passée ») ne part qu'au-delà de PROF_FAR yards du maître ou au
-- changement de zone (si l'on est alors à plus de PROF_NEAR), pour ne pas clignoter quand le joueur
-- va et vient autour de PROF_NEAR. Elle part aussitôt quand l'argent manque. Pas de nouvelle étape
-- tant que le joueur est dans une grotte (Q.Caves:PlayerCave) : le prochain contrôle, dehors, l'insère.
local Professions = {}
Q.Professions = Professions

local TAG_PREFIX = "prof:"
local CHECK_INTERVAL = 5    -- secondes entre deux recherches de maître proche
local PROF_NEAR = 400       -- yards : un maître à cette distance ou moins, l'étape s'insère
local PROF_FAR = 800        -- yards : au-delà, l'étape insérée part (et son « passer » est oublié)

-- clé, sort d'Apprenti (Classic), ID de ligne de compétence (7e retour de GetProfessionInfo), principal ?
Professions.LIST = {
  { key = "ALCHEMY", spell = 2259, skillLine = 171, primary = true },
  { key = "BLACKSMITHING", spell = 2018, skillLine = 164, primary = true },
  { key = "ENCHANTING", spell = 7411, skillLine = 333, primary = true },
  { key = "ENGINEERING", spell = 4036, skillLine = 202, primary = true },
  { key = "HERBALISM", spell = 2366, skillLine = 182, primary = true },
  { key = "LEATHERWORKING", spell = 2108, skillLine = 165, primary = true },
  { key = "MINING", spell = 2575, skillLine = 186, primary = true },
  { key = "SKINNING", spell = 8613, skillLine = 393, primary = true },
  { key = "TAILORING", spell = 3908, skillLine = 197, primary = true },
  { key = "COOKING", spell = 2550, skillLine = 185 },
  { key = "FIRSTAID", spell = 3273, skillLine = 129 },
  { key = "FISHING", spell = 7620, skillLine = 356 },
}

-- Règle W4-R1 : on ne propose que le rang 2 (Compagnon) pour tous les métiers et le rang 3 (Expert) pour
-- les principaux seulement. Expert/Artisan des secondaires (cuisine, secourisme, pêche) s'obtiennent par
-- livre ou quête, pas chez un maître ; l'Artisan des principaux demande un maître précis, pas le plus proche.
-- Rangs d'un métier : coût au maître (en cuivre), niveau du personnage et compétence requis.
-- VALEURS PAR DÉFAUT À VÉRIFIER EN JEU (aucun relevé chez le maître pour l'instant) : Apprenti 10 pc ;
-- Compagnon 5 pa (niveau 10, compétence 50) ; Expert 1 po (niveau 20, compétence 125) ;
-- Artisan 5 po (niveau 35, compétence 200). Le seuil de compétence vaut « maximum du rang précédent - 25 ».
Professions.RANKS = {
  { cost = 10, level = 1, skill = 0, cap = 75 },
  { cost = 500, level = 10, skill = 50, cap = 150 },
  { cost = 10000, level = 20, skill = 125, cap = 225 },
  { cost = 50000, level = 35, skill = 200, cap = 300 },
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
-- SkillInfo(key) -> compétence, maximum du rang, ou nil si le métier n'est pas dans la liste du joueur.
function Professions:SkillInfo(key)
  local p = BY_KEY[key]
  if not p or type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then return nil end
  local ok, a, b, c2, d, e = pcall(GetProfessions)
  if not ok then return nil end
  local list = { a, b, c2, d, e }
  for i = 1, 5 do   -- les trous (nil) sont permis : ipairs s'arrêterait au premier
    local idx = list[i]
    if type(idx) == "number" then
      local ok2, _, _, skill, max, _, _, line = pcall(GetProfessionInfo, idx)
      if ok2 and line == p.skillLine and type(skill) == "number" then
        return skill, type(max) == "number" and max or 75
      end
    end
  end
  return nil
end

-- Rang à proposer : 1 si le métier n'est pas connu, sinon le rang suivant si la compétence et le niveau
-- le permettent, sinon nil.
function Professions:WantedRank(key)
  if not self:Known(key) then return 1 end
  local skill, max = self:SkillInfo(key)
  if not skill then return nil end
  local cur = math.floor(max / 75 + 0.5)
  if cur < 1 then return nil end   -- maximum sous le premier rang : rien à proposer
  local nxt = self.RANKS[cur + 1]
  if not nxt or cur + 1 > (BY_KEY[key].primary and 3 or 2) then return nil end
  local level = type(UnitLevel) == "function" and UnitLevel("player") or 0
  if skill >= nxt.skill and skill >= max - 25 and level >= nxt.level then return cur + 1 end
  return nil
end

-- Coût relevé chez le maître (mémorisé par métier et rang) de préférence, sinon la table par défaut.
function Professions:RankCost(rank, key)
  local c = char()
  local seen = key and c and c.profCosts and c.profCosts[key]
  if seen and type(seen[rank]) == "number" then return seen[rank] end
  local r = self.RANKS[rank]
  return r and r.cost or nil
end

-- Relève les coûts des services du maître ouvert : seulement si le nom du service contient à la fois le
-- nom du métier et celui du rang (correspondance sûre) ; sinon rien, la table fait foi.
function Professions:RecordTrainerCosts(key)
  if type(GetNumTrainerServices) ~= "function" or type(GetTrainerServiceInfo) ~= "function"
    or type(GetTrainerServiceCost) ~= "function" then return end
  local c = char()
  if not c then return end
  local ok, n = pcall(GetNumTrainerServices)
  if not ok or type(n) ~= "number" then return end
  local profName = self:Name(key):lower()
  for i = 1, n do
    -- Ordre Mainline (cf. Trainer.lua) : nom, type, icône, niveau requis, sous-texte (le rang, p. ex.
    -- « Compagnon ») ; le rang peut aussi figurer dans le nom selon la version.
    local ok1, name, _, _, _, subText = pcall(GetTrainerServiceInfo, i)
    local ok2, cost = pcall(GetTrainerServiceCost, i)
    if ok1 and ok2 and type(name) == "string" and type(cost) == "number" and cost > 0 then
      local low = (name .. " " .. (type(subText) == "string" and subText or "")):lower()
      if low:find(profName, 1, true) then
        for rank = 1, #self.RANKS do
          local word = Q.L["PROF_RANK_" .. rank]
          if word and low:find(word:lower(), 1, true) then
            c.profCosts = c.profCosts or {}
            c.profCosts[key] = c.profCosts[key] or {}
            c.profCosts[key][rank] = cost
          end
        end
      end
    end
  end
end

function Professions:Known(key)
  local p = BY_KEY[key]
  if not p then return false end
  -- Appris = confirmé par le jeu : l'ancien c.profLearned (posé à la simple visite) est ignoré.
  if self:SkillInfo(key) then return true end
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

-- Rang de l'étape insérée pour ce métier, ou nil.
local function stepRank(key)
  local c = char()
  for _, group in ipairs(c and c.inserted or {}) do
    if type(group) == "table" and group.tag == TAG_PREFIX .. key then
      local st = group.steps and group.steps[1]
      return st and st.rank or 1
    end
  end
  return nil
end

local function canAfford(key, rank)
  if type(GetMoney) ~= "function" then return true end
  local cost = Professions:RankCost(rank, key)
  return cost ~= nil and (GetMoney() or 0) >= cost
end

-- Le joueur est-il dans une grotte (passé par l'entrée) ?
local function inCave()
  local C = Q.Caves
  return C ~= nil and type(C.PlayerCave) == "function" and C:PlayerCave() ~= nil
end

-- Changement de zone pas encore pris en compte par Check (vu en combat, par exemple).
local zoneChanged = false

-- Métiers choisis : étape (Apprenti, ou rang suivant d'un métier appris) insérée si un maître est à
-- PROF_NEAR yards ou moins, que l'argent du rang suffit et que le joueur n'est pas dans une grotte.
-- Étape retirée quand le jeu confirme le rang, aussitôt que l'argent manque, ou quand le joueur
-- s'éloigne : au-delà de PROF_FAR, ou au-delà de PROF_NEAR au changement de zone. Entre PROF_NEAR et
-- PROF_FAR rien ne bouge (une étape passée le reste). Retirée, elle revient au passage suivant.
function Professions:Check()
  local zone = zoneChanged
  zoneChanged = false
  if not (Q.Progress and Q.Progress:IsEnabled()) then return end
  local chosen = self:Chosen()
  if not chosen then return end
  for _, p in ipairs(self.LIST) do
    if chosen[p.key] then
      local want = self:WantedRank(p.key)
      local have = stepRank(p.key)
      if not want or not canAfford(p.key, want) then
        -- rang appris (ou rien à proposer), ou plus d'argent : l'étape ne doit pas bloquer la route
        if have then self:RemoveStep(p.key) end
      else
        local d = nearestTrainer(p.key)
        if d and d <= PROF_NEAR then
          if have ~= want and not inCave() then
            Q.Progress:InsertSteps(TAG_PREFIX .. p.key, { { "trainprof", prof = p.key, rank = want } })
          end
        elseif have and (have ~= want or not d or d > PROF_FAR or zone) then
          -- loin du maître (ou distance inconnue), changement de zone hors de PROF_NEAR, ou étape d'un
          -- autre rang : elle part, son état « passée » avec elle ; elle revient au prochain passage
          self:RemoveStep(p.key)
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

-- Visite d'un maître de métier choisi : relève les coûts réels. Le métier n'est PAS appris pour autant
-- (le joueur peut ne pas avoir l'argent) : c'est le jeu qui le confirme, par Check().
Q:RegisterEvent("TRAINER_SHOW", function()
  if InCombatLockdown and InCombatLockdown() then return end
  if type(IsTradeskillTrainer) == "function" and not IsTradeskillTrainer() then return end
  local key = Professions:ProfOfTrainer(trainerNpcId())
  local chosen = Professions:Chosen()
  if not (key and chosen and chosen[key]) then return end
  Professions:RecordTrainerCosts(key)
  Q.SafeCall(Professions.Check, Professions)
end)

Q:On("LOGIN", function()
  Q:NewTicker(CHECK_INTERVAL, function()
    if InCombatLockdown and InCombatLockdown() then return end
    Q.SafeCall(Professions.Check, Professions)
  end)
end)
-- LEARNED_SPELL_IN_TAB n'existe plus en 12.x : LEARNED_SPELL_IN_SKILL_LINE (SpellBookDocumentation).
-- Changement de zone : retenu même en combat, appliqué au prochain contrôle.
for _, event in ipairs({ "SKILL_LINES_CHANGED", "LEARNED_SPELL_IN_SKILL_LINE", "ZONE_CHANGED_NEW_AREA", "PLAYER_MONEY" }) do
  Q:RegisterEvent(event, function(ev)
    if ev == "ZONE_CHANGED_NEW_AREA" then zoneChanged = true end
    if InCombatLockdown and InCombatLockdown() then return end
    Q.SafeCall(Professions.Check, Professions)
  end)
end
