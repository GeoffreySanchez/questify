local addonName, Q = ...

-- Offre de quête de classe : quand le joueur passe près du donneur d'une chaîne de quêtes de classe
-- (Engine/ClassQuests.lua) encore « disponible », une étape « classquest » s'insère avant la route,
-- sur le modèle de l'étape de métier (Engine/Professions.lua). Un clic sur la ligne du suivi ouvre la
-- fenêtre de la chaîne (« Ajouter à la route » / « Ignorer ») ; ajoutée ou ignorée, l'offre disparaît.
-- Passée (clic droit, /qf skip), elle reste passée jusqu'à ce que le joueur s'éloigne.
-- Hystérésis : l'offre s'insère à OFFER_NEAR yards du donneur ou moins, et ne part qu'au-delà de
-- OFFER_FAR yards, ou au changement de zone si le joueur est alors à plus de OFFER_NEAR. Elle revient
-- au passage suivant. Rien en combat, rien dans une grotte (Q.Caves:PlayerCave), au plus MAX_OFFERS
-- offres à la fois (les chaînes de plus bas niveau, donc les plus en retard, d'abord).
-- Aucune étape « classquest » n'est écrite dans les guides : elles n'existent qu'à l'exécution.
local Offer = {}
Q.ClassQuestOffer = Offer

local TAG_PREFIX = "cqo:"
local CHECK_INTERVAL = 5   -- secondes entre deux contrôles
local OFFER_NEAR = 250     -- yards : un donneur à cette distance ou moins, l'offre s'insère
local OFFER_FAR = 600      -- yards : au-delà, l'offre insérée part (et son « passer » est oublié)
local MAX_OFFERS = 2

local function char() return Q.char end

local function enabled()
  return Q.Settings and Q.Settings:Get("classQuestOffer") ~= false
end

-- Titre d'une chaîne dans la langue du client (comme la fenêtre des quêtes de classe).
function Offer:ChainTitle(key)
  local chain = Q.ClassQuests and Q.ClassQuests:FindChain(key)
  if not chain then return tostring(key) end
  local P = Q.UI and Q.UI.ClassQuestPopup
  if P and P.ChainTitle then return P.ChainTitle(chain) end
  return tostring(chain.title or chain.key)
end

-- Tags des offres insérées : { [clé] = true }.
local function offered()
  local out = {}
  local c = char()
  for _, group in ipairs(c and c.inserted or {}) do
    if type(group) == "table" and type(group.tag) == "string" and group.tag:sub(1, #TAG_PREFIX) == TAG_PREFIX then
      out[group.tag:sub(#TAG_PREFIX + 1)] = true
    end
  end
  return out
end

function Offer:Has(key)
  local c = char()
  for _, group in ipairs(c and c.inserted or {}) do
    if type(group) == "table" and group.tag == TAG_PREFIX .. tostring(key) then return true end
  end
  return false
end

function Offer:Remove(key)
  if self:Has(key) then Q.Progress:RemoveInserted(TAG_PREFIX .. key) end
end

-- Le joueur est-il dans une grotte (passé par l'entrée) ?
local function inCave()
  local C = Q.Caves
  return C ~= nil and type(C.PlayerCave) == "function" and C:PlayerCave() ~= nil
end

-- Distance (yards) au donneur de la première quête restante de la chaîne, ou nil si inconnue.
local function giverDistance(chain)
  local CQ = Q.ClassQuests
  local ok, s = pcall(function() return CQ:Starter(CQ:FirstQuest(chain)) end)
  if ok and s and type(s.dist) == "number" then return s.dist end
  return nil
end

-- Changement de zone pas encore pris en compte par Check (vu en combat, par exemple).
local zoneChanged = false

function Offer:Check()
  local zone = zoneChanged
  zoneChanged = false
  if not (Q.Progress and Q.Progress:IsEnabled() and Q.ClassQuests and char()) then return end
  local have = offered()
  if not enabled() then
    for key in pairs(have) do self:Remove(key) end
    return
  end
  local rows = {}
  for i, row in ipairs(Q.ClassQuests:List()) do
    if row.state == "available" then
      rows[#rows + 1] = { chain = row.chain, index = i, dist = giverDistance(row.chain) }
    end
  end
  local byKey = {}
  for _, r in ipairs(rows) do byKey[r.chain.key] = r end
  -- offres à retirer : chaîne plus disponible, donneur loin ou inconnu, changement de zone hors de OFFER_NEAR
  local kept = 0
  for key in pairs(have) do
    local r = byKey[key]
    if not r or not r.dist or r.dist > OFFER_FAR or (zone and r.dist > OFFER_NEAR) then
      self:Remove(key)
    else
      kept = kept + 1
    end
  end
  if kept >= MAX_OFFERS or inCave() then return end
  -- nouvelles offres : les plus en retard (niveau le plus bas) d'abord
  local cands = {}
  for _, r in ipairs(rows) do
    if not have[r.chain.key] and r.dist and r.dist <= OFFER_NEAR and not self:Has(r.chain.key) then
      cands[#cands + 1] = r
    end
  end
  table.sort(cands, function(a, b)
    local la, lb = tonumber(a.chain.level) or 1, tonumber(b.chain.level) or 1
    if la ~= lb then return la < lb end
    return a.index < b.index
  end)
  for _, r in ipairs(cands) do
    if kept >= MAX_OFFERS then break end
    Q.Progress:InsertSteps(TAG_PREFIX .. r.chain.key, { { "classquest", key = r.chain.key } })
    kept = kept + 1
  end
end

local function check()
  if InCombatLockdown and InCombatLockdown() then return end
  Q.SafeCall(Offer.Check, Offer)
end

Q:On("LOGIN", function()
  Q:NewTicker(CHECK_INTERVAL, check)
end)
-- Changement de zone : retenu même en combat, appliqué au prochain contrôle.
for _, event in ipairs({ "ZONE_CHANGED_NEW_AREA", "PLAYER_LEVEL_UP" }) do
  Q:RegisterEvent(event, function(ev)
    if ev == "ZONE_CHANGED_NEW_AREA" then zoneChanged = true end
    check()
  end)
end
Q:On("SETTINGS_CHANGED", function(path)
  if path == "classQuestOffer" then check() end
end)
