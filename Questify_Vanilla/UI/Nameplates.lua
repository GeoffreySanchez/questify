local addonName, Q = ...

-- Icône animée au-dessus des barres de nom des monstres d'objectif (spec § 5.5).
-- Le npcID vient de UnitCreatureID, sinon du champ 6 du GUID. Toute valeur secrète
-- (restrictions Midnight) est ignorée sans erreur.
-- Mode zone (Engine/ZoneMode.lua) : tous les monstres de la zone ont une icône ; les élites et
-- nommés ont la leur (crâne).
Q.UI = Q.UI or {}
local Nameplates = { icons = {} }
Q.UI.Nameplates = Nameplates

local ICON_TEXTURE = "Interface\\GossipFrame\\AvailableQuestIcon"
local NAMED_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"   -- élite ou nommé de la zone
local ICON_SIZE = 24
local BOUNCE_HEIGHT = 6
local BOUNCE_TIME = 0.45

local icons = Nameplates.icons
local pool = {}
local tracked = {}       -- unités dont la barre de nom est affichée : [unit] = true
local npcSet             -- cache : Q.Targets:ObjectiveNpcSet() et monstres de la zone ([npcId] = true
                         -- ou "named"), vidé à chaque PROGRESS_UPDATED et ZONEMODE_CHANGED

---------------------------------------------------------------------------
-- Lecture du npcID
---------------------------------------------------------------------------
local function readNpcId(unit)
  local isSecret = Q.Util.IsSecret
  if type(UnitCreatureID) == "function" then
    local id = UnitCreatureID(unit)
    if isSecret(id) then return nil end
    if id ~= nil then return tonumber(id) end
  end
  if type(UnitGUID) ~= "function" then return nil end
  local guid = UnitGUID(unit)
  if isSecret(guid) or type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, id = strsplit("-", guid)
  if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
  return tonumber(id)
end

-- Toute erreur liée à une valeur protégée revient à « pas de npcID ».
function Nameplates:NpcId(unit)
  if type(unit) ~= "string" then return nil end
  local ok, id = pcall(readNpcId, unit)
  if ok then return id end
  return nil
end

---------------------------------------------------------------------------
-- Icônes (réutilisées)
---------------------------------------------------------------------------
local function acquire()
  local f = table.remove(pool)
  if f then return f end
  f = CreateFrame("Frame", nil, UIParent)
  f:SetSize(ICON_SIZE, ICON_SIZE)
  local tex = f:CreateTexture(nil, "OVERLAY")
  tex:SetAllPoints(f)
  tex:SetTexture(ICON_TEXTURE)
  local bounce = tex:CreateAnimationGroup()
  bounce:SetLooping("BOUNCE")
  local move = bounce:CreateAnimation("Translation")
  move:SetOffset(0, BOUNCE_HEIGHT)
  move:SetDuration(BOUNCE_TIME)
  if move.SetSmoothing then move:SetSmoothing("IN_OUT") end
  f.texture, f.bounce, f.translation = tex, bounce, move
  f:Hide()
  return f
end

local function attach(unit, plate, named)
  local f = icons[unit]
  if not f then
    f = acquire()
    icons[unit] = f
  end
  -- GetTexture() renvoie un fileID en jeu : on garde l'état de l'icône sur le cadre
  named = named and true or false
  if f.isNamed ~= named then
    f.texture:SetTexture(named and NAMED_TEXTURE or ICON_TEXTURE)
    f.isNamed = named
  end
  if f:GetParent() ~= plate then f:SetParent(plate) end
  f:ClearAllPoints()
  f:SetPoint("BOTTOM", plate, "TOP", 0, 0)
  f:Show()
  if not f.bounce:IsPlaying() then f.bounce:Play() end
end

local function release(unit)
  local f = icons[unit]
  if not f then return end
  icons[unit] = nil
  f.bounce:Stop()
  f:Hide()
  f:ClearAllPoints()
  f:SetParent(UIParent)
  pool[#pool + 1] = f
end

---------------------------------------------------------------------------
-- Mise à jour
---------------------------------------------------------------------------
local function enabled()
  return Q.Settings:Get("nameplates") ~= false and Q.Progress:IsEnabled()
end

local function objectiveSet()
  if not npcSet then
    local set = Q.Targets:ObjectiveNpcSet()
    local Z = Q.ZoneMode
    if Z and Z.NpcKinds then
      local ok, kinds = pcall(Z.NpcKinds, Z)
      if ok and type(kinds) == "table" then
        for id, kind in pairs(kinds) do
          if kind == "named" then set[id] = "named" elseif not set[id] then set[id] = true end
        end
      end
    end
    npcSet = set
  end
  return npcSet
end

local function plateFor(unit)
  if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
  local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
  if not ok or not plate then return nil end
  if plate.IsForbidden and plate:IsForbidden() then return nil end
  return plate
end

function Nameplates:Update(unit)
  if not enabled() then return release(unit) end
  local plate = plateFor(unit)
  local id = plate and self:NpcId(unit)
  local mark = id and objectiveSet()[id]
  if mark then
    attach(unit, plate, mark == "named")
  else
    release(unit)
  end
end

-- Relit toutes les barres visibles (après un changement d'objectifs ou de réglage).
function Nameplates:Rescan()
  npcSet = nil
  local units = {}
  for unit in pairs(tracked) do units[unit] = true end
  for unit in pairs(icons) do units[unit] = true end
  if C_NamePlate and C_NamePlate.GetNamePlates then
    local ok, plates = pcall(C_NamePlate.GetNamePlates)
    if ok and type(plates) == "table" then
      for _, plate in ipairs(plates) do
        local u = plate.namePlateUnitToken or plate.unitToken
        if type(u) == "string" then units[u] = true end
      end
    end
  end
  for unit in pairs(units) do self:Update(unit) end
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
Q:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, unit)
  if type(unit) ~= "string" then return end
  tracked[unit] = true
  Nameplates:Update(unit)
end)

Q:RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(_, unit)
  if type(unit) ~= "string" then return end
  tracked[unit] = nil
  release(unit)
end)

Q:On("PROGRESS_UPDATED", function() Nameplates:Rescan() end)
Q:On("ZONEMODE_CHANGED", function() Nameplates:Rescan() end)
Q:On("GUIDE_CHANGED", function() npcSet = nil end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "nameplates" or path == "dungeonQuests" then Nameplates:Rescan() end
end)
