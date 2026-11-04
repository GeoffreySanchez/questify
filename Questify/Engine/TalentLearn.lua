local addonName, Q = ...

-- Apprendre les talents dus d'un build, en un clic. Même séquence que le bouton « Appliquer » de
-- Blizzard (branche forever de wow-ui-source, Blizzard_SharedTalentUI : TalentFrameBaseMixin:PurchaseRank
-- appelle C_Traits.PurchaseRank(configID, nodeID) et traite un retour faux comme un échec ;
-- Camelot/ClassTalents : ClassTalentsFrameMixin:CommitConfigInternal appelle
-- C_ClassTalents.CommitConfig(savedConfigID)) :
--   1. un C_Traits.PurchaseRank par entrée de la liste Builds:Due ;
--   2. une seule C_ClassTalents.CommitConfig(savedConfigID), savedConfigID =
--      C_ClassTalents.GetLastSelectedSavedConfigID(specID) (peut être nil).
-- Un achat ou la validation qui renvoie faux ou lève une erreur : C_Traits.RollbackConfig(configID),
-- et l'apprentissage est coupé jusqu'à la fin de la session (available = false).
-- Des points déjà en attente (C_Traits.ConfigHasStagedChanges) : rien n'est acheté (on achèterait par-dessus
-- les choix du joueur, et un échec les effacerait) -> "staged", l'apprentissage reste possible.
-- CommitConfig vrai ne fait que lancer l'incantation d'application : la fin arrive par évènement, relayée
-- par le message interne TALENT_COMMIT(résultat, due) :
--   * TRAIT_CONFIG_UPDATED(configID de l'arbre) -> "done" ;
--   * CONFIG_COMMIT_FAILED(configID) (évènement de Forever, SharedTraitsDocumentation) -> "failed", sans
--     couper l'apprentissage (incantation interrompue : le joueur peut réessayer ou valider lui-même).
-- Learn(tree, due) -> "ok" (validation lancée) | "combat" | "staged" | "unavailable" | "failed". Rien n'est
-- protégé ici, mais rien ne part en combat (InCombatLockdown).
local TalentLearn = {}
Q.TalentLearn = TalentLearn

TalentLearn.available = true

local function plain(v)
  if Q.Util.IsSecret(v) then return nil end
  return v
end

local function apiReady()
  return type(C_Traits) == "table" and type(C_Traits.PurchaseRank) == "function"
    and type(C_Traits.RollbackConfig) == "function"
    and type(C_ClassTalents) == "table" and type(C_ClassTalents.CommitConfig) == "function"
end

function TalentLearn:IsAvailable()
  return self.available == true and apiReady()
end

-- Identifiant de la spécialisation active, ou nil.
local function specID()
  local S = C_SpecializationInfo
  if type(S) ~= "table" or type(S.GetSpecialization) ~= "function" or type(S.GetSpecializationInfo) ~= "function" then
    return nil
  end
  local ok, index = pcall(S.GetSpecialization)
  index = ok and plain(index) or nil
  if type(index) ~= "number" or index <= 0 then return nil end
  local ok2, id = pcall(S.GetSpecializationInfo, index)
  id = ok2 and plain(id) or nil
  if type(id) == "number" and id > 0 then return id end
  return nil
end

-- Dernière configuration enregistrée choisie pour la spécialisation, ou nil.
local function savedConfigID()
  local id = specID()
  if not id or type(C_ClassTalents.GetLastSelectedSavedConfigID) ~= "function" then return nil end
  local ok, saved = pcall(C_ClassTalents.GetLastSelectedSavedConfigID, id)
  saved = ok and plain(saved) or nil
  if type(saved) == "number" then return saved end
  return nil
end

-- Raison du dernier échec (courte chaîne), reprise par le rapport /qf bug.
TalentLearn.lastError = nil

local function fail(self, configID, reason)
  self.available = false
  self.lastError = reason
  local ok, err = pcall(C_Traits.RollbackConfig, configID)
  if not ok then self.lastError = reason .. "; RollbackConfig: " .. tostring(err) end
  return "failed"
end

-- Points en attente dans la configuration (posés par le joueur, pas encore validés) ; fonction absente ou
-- valeur illisible : aucun.
local function hasStaged(configID)
  if type(C_Traits.ConfigHasStagedChanges) ~= "function" then return false end
  local ok, v = pcall(C_Traits.ConfigHasStagedChanges, configID)
  return ok and plain(v) == true
end

-- Validation lancée et pas encore terminée : { configID, due }.
TalentLearn.committing = nil

function TalentLearn:Learn(tree, due)
  if not self:IsAvailable() then return "unavailable" end
  if InCombatLockdown and InCombatLockdown() then return "combat" end
  if type(tree) ~= "table" or not tree.configID or type(due) ~= "table" or #due == 0 then return "ok" end
  local configID = tree.configID
  if hasStaged(configID) then return "staged" end
  for _, entry in ipairs(due) do
    local nodeID = entry.node and entry.node.nodeID
    if not nodeID then return fail(self, configID, "PurchaseRank: no nodeID") end
    local ok, done = pcall(C_Traits.PurchaseRank, configID, nodeID)
    if not ok then return fail(self, configID, "PurchaseRank " .. nodeID .. ": " .. tostring(done)) end
    if not plain(done) then return fail(self, configID, "PurchaseRank " .. nodeID .. ": " .. tostring(done)) end
  end
  -- posé avant l'appel : l'évènement de fin ne doit pas pouvoir précéder notre attente
  self.committing = { configID = configID, due = due }
  local ok, done = pcall(C_ClassTalents.CommitConfig, savedConfigID())
  if not ok or not plain(done) then
    self.committing = nil
    return fail(self, configID, "CommitConfig: " .. tostring(done))
  end
  return "ok"
end

-- Fin de la validation lancée par Learn (évènement du jeu) -> TALENT_COMMIT("done" | "failed", due).
local function finish(result, configID)
  local c = TalentLearn.committing
  if not c then return end
  configID = plain(configID)
  if type(configID) == "number" and configID ~= c.configID then return end
  TalentLearn.committing = nil
  if result == "failed" then TalentLearn.lastError = "CONFIG_COMMIT_FAILED " .. tostring(c.configID) end
  Q:Fire("TALENT_COMMIT", result, c.due)
end

Q:RegisterEvent("TRAIT_CONFIG_UPDATED", function(_, configID) finish("done", configID) end)
Q:RegisterEvent("CONFIG_COMMIT_FAILED", function(_, configID) finish("failed", configID) end)
