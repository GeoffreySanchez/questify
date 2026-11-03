local addonName, Q = ...

-- Annonce au milieu de l'écran quand un objet qui arrive dans les sacs (butin, récompense de quête,
-- achat) améliore l'équipement : icône de l'objet et « Équipez <objet> pour gagner en puissance ».
-- Détection : les sacs sont relus après chaque BAG_UPDATE_DELAYED et comparés au relevé précédent
-- (pas de lecture du chat, dont le texte peut être secret en combat). Le gain vient des poids de
-- stats par classe de Q.Rewards (le moins bon des emplacements comparés).
-- Clic : équiper l'objet (hors combat) ; clic droit : fermer. Option upgradePopup.
Q.UI = Q.UI or {}
local Popup = { queue = {}, snapshot = nil, pendingItems = {} }
Q.UI.UpgradePopup = Popup

local L = Q.L

local SHOW_TIME = 8          -- secondes avant de disparaître
local FADE_TIME = 0.4
local RETRY_DELAY = 0.5      -- objet pas encore en cache : nouvel essai
local MAX_RETRIES = 6
local ICON_SIZE = 48
local WIDTH = 420
local BAGS = { 0, 1, 2, 3, 4 }

local function setting(path) return Q.Settings:Get(path) end
local function inCombat() return InCombatLockdown and InCombatLockdown() end

---------------------------------------------------------------------------
-- Sacs
---------------------------------------------------------------------------
local function numSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
  if GetContainerNumSlots then return GetContainerNumSlots(bag) or 0 end
  return 0
end

local function slotLink(bag, slot)
  if C_Container and C_Container.GetContainerItemLink then return C_Container.GetContainerItemLink(bag, slot) end
  if GetContainerItemLink then return GetContainerItemLink(bag, slot) end
  return nil
end

local function itemId(link)
  return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

-- { [lien] = nombre d'exemplaires } de tous les sacs.
local function readBags()
  local counts = {}
  for _, bag in ipairs(BAGS) do
    for slot = 1, numSlots(bag) do
      local link = slotLink(bag, slot)
      if type(link) == "string" and not Q.Util.IsSecret(link) then counts[link] = (counts[link] or 0) + 1 end
    end
  end
  return counts
end
Popup.ReadBags = function() return readBags() end

---------------------------------------------------------------------------
-- Évaluation
---------------------------------------------------------------------------
local function itemIcon(link)
  local id = itemId(link)
  if C_Item and C_Item.GetItemIconByID and id then return C_Item.GetItemIconByID(id) end
  if GetItemIcon and id then return GetItemIcon(id) end
  return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- -> "upgrade" (gain), "no", ou "wait" si l'objet n'est pas encore en cache.
function Popup:Evaluate(link)
  local item = Q.Rewards:ReadItem(link)
  if not item.equipLoc and not item.loaded then return "wait" end   -- objet encore inconnu du client
  if not item.equipLoc or item.equipLoc == "" then return "no" end   -- pas un équipement
  if not item.loaded then return "wait" end
  local gain = Q.Rewards:UpgradeGain(item, Q.Player)
  if gain and gain > Q.Rewards.EPSILON then return "upgrade", gain, item end
  return "no"
end

local function consider(link, tries)
  local verdict, gain, item = Popup:Evaluate(link)
  if verdict == "wait" then
    if tries >= MAX_RETRIES then return end
    local id = itemId(link)
    if id and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    Q:After(RETRY_DELAY, function() consider(link, tries + 1) end)
    return
  end
  if verdict == "upgrade" then Popup:Push({ link = link, name = item.name, gain = gain }) end
end

-- Nouveaux objets depuis le relevé précédent (le premier relevé, à la connexion, n'annonce rien).
function Popup:ScanBags()
  local now = readBags()
  local before = self.snapshot
  self.snapshot = now
  if not before or setting("upgradePopup") == false then return end
  for link, n in pairs(now) do
    if n > (before[link] or 0) then consider(link, 0) end
  end
end

---------------------------------------------------------------------------
-- Cadre
---------------------------------------------------------------------------
function Popup:Create()
  if self.frame then return self.frame end
  local f = CreateFrame("Button", "QuestifyVanillaUpgradePopup", UIParent, "BackdropTemplate")
  f:SetSize(WIDTH, ICON_SIZE + 24)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
  f:SetFrameStrata("HIGH")
  f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 14,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetBackdropBorderColor(1, 0.82, 0, 1)
  end

  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetPoint("LEFT", f, "LEFT", 14, 0)
  -- lueur dorée qui pulse autour de l'icône
  local glow = f:CreateTexture(nil, "OVERLAY")
  glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(1, 0.82, 0)
  glow:SetPoint("CENTER", icon, "CENTER", 0, 0)
  glow:SetSize(ICON_SIZE * 1.9, ICON_SIZE * 1.9)
  local pulse = glow:CreateAnimationGroup()
  pulse:SetLooping("BOUNCE")
  local fade = pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(0.3)
  fade:SetToAlpha(1)
  fade:SetDuration(0.6)

  local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  text:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
  text:SetPoint("RIGHT", f, "RIGHT", -12, 0)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(true)
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 12, 2)
  hint:SetText(L.UI_UPGRADE_HINT)

  f:SetScript("OnClick", function(_, button)
    Q.SafeCall(function()
      if button == "LeftButton" then Popup:EquipCurrent() end
      Popup:Next()
    end)
  end)
  f:SetScript("OnEnter", function(self)
    local cur = Popup.current
    if cur and GameTooltip then
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:SetHyperlink(cur.link)
      GameTooltip:Show()
    end
  end)
  f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  f:SetAlpha(0)
  f:Hide()
  self.frame, self.icon, self.text, self.hint, self.pulse = f, icon, text, hint, pulse
  return f
end

-- Ajoute une annonce (un même objet n'est annoncé qu'une fois dans la file).
function Popup:Push(entry)
  for _, e in ipairs(self.queue) do
    if e.link == entry.link then return end
  end
  if self.current and self.current.link == entry.link then return end
  self.queue[#self.queue + 1] = entry
  if not self.current then self:Next() end
end

function Popup:ShowEntry(entry)
  local f = self:Create()
  self.current = entry
  self.icon:SetTexture(itemIcon(entry.link))
  self.text:SetText(string.format(L.UI_UPGRADE_TEXT, entry.link or entry.name or "?"))
  f:Show()
  f:SetAlpha(1)
  self.pulse:Play()
  if PlaySound and SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST then pcall(PlaySound, SOUNDKIT.UI_EPICLOOT_TOAST) end
  self.serial = (self.serial or 0) + 1
  local mine = self.serial
  Q:After(SHOW_TIME, function()
    if mine == Popup.serial then Popup:Next() end
  end)
end

-- Annonce suivante, ou fermeture.
function Popup:Next()
  self.serial = (self.serial or 0) + 1
  local entry = table.remove(self.queue, 1)
  if entry then return self:ShowEntry(entry) end
  self.current = nil
  if self.frame then
    self.pulse:Stop()
    self.frame:SetAlpha(0)
    self.frame:Hide()
  end
end

-- Équipe l'objet affiché (hors combat : le jeu refuse d'équiper en combat).
function Popup:EquipCurrent()
  local cur = self.current
  if not cur or inCombat() then return false end
  local equip = (C_Item and C_Item.EquipItemByName) or EquipItemByName
  if not equip then return false end
  equip(cur.link)
  return true
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
Q:On("LOGIN", function()
  Popup.snapshot = readBags()
end)
Q:RegisterEvent("BAG_UPDATE_DELAYED", function()
  Q.SafeCall(Popup.ScanBags, Popup)
end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "upgradePopup" and setting("upgradePopup") == false then
    Popup.queue = {}
    Popup:Next()
  end
end)
