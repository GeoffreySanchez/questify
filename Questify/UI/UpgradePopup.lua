local addonName, Q = ...

-- Annonce au milieu de l'écran quand un objet qui arrive dans les sacs (butin, récompense de quête,
-- achat) améliore l'équipement : icône de l'objet et « Équipez <objet> pour gagner en puissance ».
-- Détection : les sacs sont relus après chaque BAG_UPDATE_DELAYED et comparés au relevé précédent
-- (pas de lecture du chat, dont le texte peut être secret en combat). Le gain vient des poids de
-- stats par classe de Q.Rewards (le moins bon des emplacements comparés).
-- Arme à deux mains portée : une arme à une main ou une main gauche qui ne la bat qu'avec l'autre
-- moitié prise dans les sacs est annoncée avec elle (« Équipez <masse> et <bouclier> »), et le clic
-- équipe les deux : la main droite, puis la main gauche une fois la main droite en place (vue par
-- PLAYER_EQUIPMENT_CHANGED ou par un regard régulier ; plus long si le jeu demande de confirmer la
-- liaison). Les deux objets sont cherchés dans les sacs par ID d'objet.
-- Clic : équiper l'objet (hors combat) ; clic droit : fermer. Option upgradePopup.
-- Les objets annoncés sont retenus un moment (Q.Rewards:Recommend) : la vente automatique les garde.
-- Jamais affichée en combat : l'annonce attend PLAYER_REGEN_ENABLED (celle à l'écran au début d'un
-- combat est remise en tête de file). Un clic gauche en combat ne la ferme pas (rien n'est équipé).
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
local PAIR_EXTRA = 24        -- hauteur en plus pour une annonce à deux objets (texte plus long)
local TEXT_X = 14 + ICON_SIZE + 12   -- texte et rappel à droite de l'icône
local HINT_Y = 14            -- bas du rappel « Clic : équiper »
local HINT_ROOM = 12         -- hauteur réservée au rappel, sous le texte
local EQUIP_CHECK = 0.2      -- paire : délai entre deux regards sur la main droite
local EQUIP_TRIES = 15       -- paire : 3 s au plus pour voir la main droite en place (latence)
local EQUIP_BIND_WAIT = 30   -- paire : secondes d'attente au plus tant que la confirmation de liaison est ouverte
-- Confirmations que le jeu ouvre avant d'équiper un objet lié quand équipé (StaticPopup).
local BIND_POPUPS = { "EQUIP_BIND", "EQUIP_BIND_TRADEABLE", "EQUIP_BIND_REFUNDABLE" }
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

-- -> "upgrade" (gain, objet, paire), "no", ou "wait" si l'objet n'est pas encore en cache.
-- paire = { main = objet, off = objet } quand le gain demande aussi l'autre moitié, prise dans les
-- sacs (arme à deux mains portée).
function Popup:Evaluate(link)
  local item = Q.Rewards:ReadItem(link)
  if not item.equipLoc and not item.loaded then return "wait" end   -- objet encore inconnu du client
  if not item.equipLoc or item.equipLoc == "" then return "no" end   -- pas un équipement
  if not item.loaded then return "wait" end
  local gain, pair = Q.Rewards:UpgradeGain(item, Q.Player)
  if gain and gain > Q.Rewards.EPSILON then return "upgrade", gain, item, pair end
  return "no"
end

local function consider(link, tries)
  local verdict, gain, item, pair = Popup:Evaluate(link)
  if verdict == "wait" then
    if tries >= MAX_RETRIES then return end
    local id = itemId(link)
    if id and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    Q:After(RETRY_DELAY, function() consider(link, tries + 1) end)
    return
  end
  if verdict == "upgrade" then
    local entry = { link = link, name = item.name, gain = gain }
    if pair then entry.pair = { main = pair.main.link, off = pair.off.link } end
    Popup:Push(entry)
  end
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
  local f = CreateFrame("Button", "QuestifyUpgradePopup", UIParent, "BackdropTemplate")
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

  -- texte borné : du haut du cadre jusqu'au-dessus du rappel ; un texte trop long est tronqué par
  -- le jeu au lieu de déborder sur le rappel (le cadre d'une paire est plus haut)
  local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  text:SetPoint("TOPLEFT", f, "TOPLEFT", TEXT_X, -12)
  text:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, HINT_Y + HINT_ROOM)
  text:SetJustifyH("LEFT")
  text:SetJustifyV("MIDDLE")
  text:SetWordWrap(true)
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  -- en bas du cadre (même place que sous l'icône pour une annonce simple)
  hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", TEXT_X, HINT_Y)
  hint:SetText(L.UI_UPGRADE_HINT)

  f:SetScript("OnClick", function(_, button)
    Q.SafeCall(function()
      if button == "LeftButton" then
        -- en combat le jeu refuse d'équiper : l'annonce reste, rien n'est perdu
        if inCombat() then return end
        Popup:EquipCurrent()
      end
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

-- Même paire (main droite et main gauche de mêmes ID d'objet) ?
local function samePair(a, b)
  if not (a and b) then return false end
  local am, ao = itemId(a.main), itemId(a.off)
  return am ~= nil and ao ~= nil and am == itemId(b.main) and ao == itemId(b.off)
end

-- Ajoute une annonce : un même objet, ou une même paire (masse et bouclier arrivés ensemble donnent
-- deux évaluations), n'est annoncé qu'une fois dans la file. L'objet, et l'autre moitié d'une paire,
-- sont retenus comme recommandés.
function Popup:Push(entry)
  Q.Rewards:Recommend(entry.link, entry.pair and entry.pair.main, entry.pair and entry.pair.off)
  local function dup(e)
    return e.link == entry.link or samePair(e.pair, entry.pair)
  end
  for _, e in ipairs(self.queue) do
    if dup(e) then return end
  end
  if self.current and dup(self.current) then return end
  self.queue[#self.queue + 1] = entry
  if not self.current then self:Next() end
end

function Popup:ShowEntry(entry)
  local f = self:Create()
  self.current = entry
  self.icon:SetTexture(itemIcon(entry.link))
  if entry.pair then
    f:SetHeight(ICON_SIZE + 24 + PAIR_EXTRA)
    self.text:SetText(string.format(L.UI_UPGRADE_TEXT_PAIR, entry.pair.main, entry.pair.off))
  else
    f:SetHeight(ICON_SIZE + 24)
    self.text:SetText(string.format(L.UI_UPGRADE_TEXT, entry.link or entry.name or "?"))
  end
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

local function hideFrame()
  if Popup.frame then
    Popup.pulse:Stop()
    Popup.frame:SetAlpha(0)
    Popup.frame:Hide()
  end
end

-- Annonce suivante, ou fermeture. En combat : rien ne s'affiche, la file attend la fin du combat.
function Popup:Next()
  self.serial = (self.serial or 0) + 1
  local entry = table.remove(self.queue, 1)
  if entry and inCombat() then
    table.insert(self.queue, 1, entry)
    entry = nil
  end
  if entry then return self:ShowEntry(entry) end
  self.current = nil
  hideFrame()
end

-- Début de combat : l'annonce affichée repart en tête de file, sans être perdue.
function Popup:Suspend()
  local cur = self.current
  if not cur then return end
  self.serial = (self.serial or 0) + 1
  self.current = nil
  table.insert(self.queue, 1, cur)
  hideFrame()
end

-- Fin de combat : reprise de la file.
function Popup:Resume()
  if self.current or #self.queue == 0 or inCombat() then return end
  self:Next()
end

-- Lien de l'objet dans les sacs : le même lien de préférence, sinon un objet de même ID (le lien
-- retenu par l'annonce peut différer de celui du sac) ; nil s'il n'y est plus.
local function findInBags(link)
  local inBags = readBags()
  if inBags[link] then return link end
  local id = itemId(link)
  if not id then return nil end
  for l in pairs(inBags) do
    if itemId(l) == id then return l end
  end
  return nil
end

-- Confirmation de liaison ouverte (objet lié quand équipé) : le jeu n'équipe qu'après le clic du joueur.
local function bindConfirmOpen()
  if type(StaticPopup_Visible) ~= "function" then return false end
  for _, which in ipairs(BIND_POPUPS) do
    local ok, shown = pcall(StaticPopup_Visible, which)
    if ok and shown then return true end
  end
  return false
end

-- Paire : les deux objets doivent être dans les sacs, sinon rien n'est équipé. La main droite
-- d'abord (elle remplace l'arme à deux mains) ; la main gauche seulement quand l'emplacement 16
-- porte la main droite (sinon le bouclier retirerait l'arme à deux mains et laisserait la main
-- droite vide), hors combat et si elle est toujours dans les sacs. La main droite en place se voit à
-- PLAYER_EQUIPMENT_CHANGED (emplacement 16) ou à un regard toutes les EQUIP_CHECK secondes : au plus
-- EQUIP_TRIES regards, ou jusqu'à EQUIP_BIND_WAIT secondes tant que la confirmation de liaison est
-- ouverte. Un message dit ce qui bloque.
local function equipPair(equip, main, off)
  for _, link in ipairs({ main, off }) do
    if not findInBags(link) then
      Q:Print(L.UI_UPGRADE_PAIR_MISSING, link)
      return false
    end
  end
  equip(findInBags(main), 16)
  local job = { done = false }
  Popup.pairJob = job
  local function finish()
    job.done = true
    if Popup.pairJob == job then Popup.pairJob = nil end
  end
  -- main droite en place ? alors la main gauche (une seule fois) ; -> vrai quand c'est réglé
  function job.mainInPlace()
    if job.done then return true end
    if itemId(GetInventoryItemLink("player", 16)) ~= itemId(main) then return false end
    finish()
    if inCombat() then
      Q:Print(L.UI_UPGRADE_PAIR_COMBAT, off)
      return true
    end
    local offLink = findInBags(off)
    if not offLink then
      Q:Print(L.UI_UPGRADE_PAIR_MISSING, off)
      return true
    end
    equip(offLink, 17)
    return true
  end
  local tries, waited = 0, 0
  local function check()
    if job.done or job.mainInPlace() then return end
    tries, waited = tries + 1, waited + EQUIP_CHECK
    if bindConfirmOpen() then
      if waited < EQUIP_BIND_WAIT then
        tries = 0   -- la latence se compte depuis la fermeture de la confirmation
        return Q:After(EQUIP_CHECK, check)
      end
    elseif tries < EQUIP_TRIES then
      return Q:After(EQUIP_CHECK, check)
    end
    finish()
    Q:Print(L.UI_UPGRADE_PAIR_FAILED, off)
  end
  Q:After(EQUIP_CHECK, check)
  return true
end

-- Équipe l'objet affiché (hors combat : le jeu refuse d'équiper en combat). Une paire : voir
-- equipPair.
function Popup:EquipCurrent()
  local cur = self.current
  if not cur or inCombat() or cur.demo then return false end   -- annonce de démo (UI/Demo.lua) : rien n'est équipé
  local equip = (C_Item and C_Item.EquipItemByName) or EquipItemByName
  if not equip then return false end
  if cur.pair then return equipPair(equip, cur.pair.main, cur.pair.off) end
  equip(cur.link)
  return true
end

-- Recommended(link) : objet annoncé il y a peu (seul ou dans une paire) ; voir Q.Rewards:Recommended.
function Popup:Recommended(link)
  return Q.Rewards:Recommended(link)
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
-- Paire en cours : la main droite vient d'arriver, la main gauche suit sans attendre le regard suivant.
Q:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function(_, slot)
  local job = Popup.pairJob
  if slot == 16 and job and not job.done then job.mainInPlace() end
end)
Q:RegisterEvent("PLAYER_REGEN_DISABLED", function()
  Q.SafeCall(Popup.Suspend, Popup)
end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  Q.SafeCall(Popup.Resume, Popup)
end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "upgradePopup" and setting("upgradePopup") == false then
    Popup.queue = {}
    Popup:Next()
  end
end)
