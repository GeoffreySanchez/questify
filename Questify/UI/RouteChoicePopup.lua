local addonName, Q = ...

-- Choix de suite : popup au milieu de l'écran quand un chapitre fini a plusieurs suites
-- (ROUTE_CHOICE_NEEDED de Engine/Progress.lua), ou à la demande (/qf route, bouton du journal, clic sur
-- la ligne du suivi). Une carte par suite possible (Q.RouteChoice:Rank) : zone, niveaux, quêtes et XP des
-- remises, durée et XP/h simulées, trajet, avertissement de niveau ; la carte conseillée a un liseré doré,
-- le badge « Conseillé » et sa raison en toutes lettres (jamais la couleur seule). Bouton « Y aller » sur
-- chaque carte ; en bas « Garder la route prévue » (suite par défaut) et « Plus tard » (Échap aussi) :
-- le chapitre reste en attente, le suivi le rappelle et /qf route rouvre le choix.
-- Jamais affichée ni créée en combat : remise à PLAYER_REGEN_ENABLED (celle à l'écran au début d'un
-- combat est cachée puis rouverte à la fin). Option route.choicePopup : sans elle, aucune demande
-- automatique (la route par défaut est suivie) ; /qf route reste possible.
Q.UI = Q.UI or {}
local Popup = { cardFrames = {} }
Q.UI.RouteChoicePopup = Popup

local L = Q.L

local CARD_W, CARD_H, GAP, PAD = 190, 214, 10, 16
local HEADER_H, FOOTER_H = 64, 46
local BUTTON_W, BUTTON_H = 150, 22
local GOLD = { 1, 0.82, 0 }
local GREY = { 0.45, 0.45, 0.45 }
local HOVER = { 1, 1, 1 }

local function inCombat() return InCombatLockdown and InCombatLockdown() end
local function automatic() return Q.Settings:Get("route.choicePopup") ~= false end

-- 26898 -> « 26 898 » (séparateur du jeu quand il existe).
local function bigNumber(n)
  n = math.floor((tonumber(n) or 0) + 0.5)
  if type(BreakUpLargeNumbers) == "function" then
    local ok, s = pcall(BreakUpLargeNumbers, n)
    if ok and type(s) == "string" then return s end
  end
  return tostring(n)
end

-- 158 -> « 2 h 38 », 45 -> « 45 min ».
local function duration(minutes)
  minutes = math.floor((tonumber(minutes) or 0) + 0.5)
  if minutes < 60 then return minutes .. " min" end
  return string.format("%d h %02d", math.floor(minutes / 60), minutes % 60)
end

local function setBorder(frame, color)
  if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(color[1], color[2], color[3], 1) end
end

local function backdrop(frame, alpha)
  if not frame.SetBackdrop then return end
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, alpha)
end

local function makeButton(parent, label, width, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or BUTTON_W, BUTTON_H)
  b:SetText(label)
  b:SetScript("OnClick", function() Q.SafeCall(onClick) end)
  return b
end

---------------------------------------------------------------------------
-- Cadre
---------------------------------------------------------------------------
local function line(card, template, anchor, gap)
  local fs = card:CreateFontString(nil, "OVERLAY", template)
  fs:SetPoint("TOP", anchor, anchor == card and "TOP" or "BOTTOM", 0, -(gap or 4))
  fs:SetWidth(CARD_W - 20)
  fs:SetJustifyH("CENTER")
  return fs
end

function Popup:CardFrame(i)
  local c = self.cardFrames[i]
  if c then return c end
  local card = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
  card:SetSize(CARD_W, CARD_H)
  backdrop(card, 0.6)
  card:EnableMouse(true)
  card:SetScript("OnEnter", function(f) if f.qfData then setBorder(f, HOVER) end end)
  card:SetScript("OnLeave", function(f)
    if f.qfData then setBorder(f, f.qfData.recommended and GOLD or GREY) end
  end)
  c = { frame = card }
  c.badge = line(card, "GameFontNormalSmall", card, 10)
  c.name = line(card, "GameFontNormalLarge", c.badge, 4)
  c.levels = line(card, "GameFontHighlightSmall", c.name, 6)
  c.quests = line(card, "GameFontHighlightSmall", c.levels, 6)
  c.time = line(card, "GameFontHighlightSmall", c.quests, 4)
  c.xph = line(card, "GameFontHighlightSmall", c.time, 4)
  c.travel = line(card, "GameFontHighlightSmall", c.xph, 4)
  c.warning = line(card, "GameFontNormalSmall", c.travel, 6)
  c.warning:SetTextColor(1, 0.35, 0.3)
  c.reason = line(card, "GameFontNormalSmall", c.warning, 6)
  c.button = makeButton(card, L.UI_ROUTECHOICE_CHOOSE, CARD_W - 40, function()
    if card.qfData then Popup:Choose(card.qfData.id) end
  end)
  c.button:SetPoint("BOTTOM", card, "BOTTOM", 0, 12)
  self.cardFrames[i] = c
  return c
end

function Popup:Create()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", "QuestifyRouteChoicePopup", UIParent, "BackdropTemplate")
  f:SetSize(PAD * 2 + CARD_W * 2 + GAP, HEADER_H + CARD_H + FOOTER_H)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
  f:SetFrameStrata("DIALOG")
  if f.SetClampedToScreen then f:SetClampedToScreen(true) end
  backdrop(f, 0.9)
  setBorder(f, GOLD)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
  f:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)
  -- Échap ferme la popup comme « Plus tard » : le choix reste en attente
  if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "QuestifyRouteChoicePopup") end

  self.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  self.title:SetPoint("TOP", f, "TOP", 0, -14)
  self.title:SetText(L.UI_ROUTECHOICE_TITLE)
  self.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.subtitle:SetPoint("TOP", self.title, "BOTTOM", 0, -6)

  self.keepButton = makeButton(f, L.UI_ROUTECHOICE_KEEP, BUTTON_W + 30, function() Popup:Keep() end)
  self.laterButton = makeButton(f, L.UI_ROUTECHOICE_LATER, BUTTON_W - 30, function() Popup:Hide() end)
  self.keepButton:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -GAP / 2, 14)
  self.laterButton:SetPoint("BOTTOMLEFT", f, "BOTTOM", GAP / 2, 14)

  f:Hide()
  self.frame = f
  return f
end

---------------------------------------------------------------------------
-- Contenu
---------------------------------------------------------------------------
local function travelText(card)
  local t = card.travel
  if not t then return "" end
  local kind = L["UI_ROUTECHOICE_KIND_" .. tostring(t.kind)] or tostring(t.kind)
  if type(t.minutes) == "number" then return string.format(L.UI_ROUTECHOICE_TRAVEL_MIN, kind, t.minutes) end
  return string.format(L.UI_ROUTECHOICE_TRAVEL, kind)
end

local function fillCard(c, data)
  c.frame.qfData = data
  setBorder(c.frame, data.recommended and GOLD or GREY)
  if data.recommended then
    c.badge:SetText("|TInterface\\Common\\ReputationStar:12:12:0:0:32:32:0:16:0:16|t "
      .. L.UI_ROUTECHOICE_RECOMMENDED)
  elseif data.default then
    c.badge:SetText(L.UI_ROUTECHOICE_DEFAULT)
  else
    c.badge:SetText("")
  end
  c.name:SetText(data.title)
  c.levels:SetText(string.format(L.UI_ROUTECHOICE_LEVELS, data.minLevel, data.maxLevel))
  c.quests:SetText(string.format(L.UI_ROUTECHOICE_QUESTS, data.quests, bigNumber(data.xp)))
  c.time:SetText(data.minutes and string.format(L.UI_ROUTECHOICE_TIME, duration(data.minutes)) or "")
  c.xph:SetText(data.xpPerHour and string.format(L.UI_ROUTECHOICE_XPH, bigNumber(data.xpPerHour)) or "")
  c.travel:SetText(travelText(data))
  if data.warning == "low" then
    c.warning:SetText(string.format(L.UI_ROUTECHOICE_WARN_low, data.minLevel))
  elseif data.warning == "high" then
    c.warning:SetText(L.UI_ROUTECHOICE_WARN_high)
  else
    c.warning:SetText("")
  end
  c.reason:SetText(data.recommended and (L["UI_ROUTECHOICE_REASON_" .. tostring(data.reason)] or "") or "")
  c.frame:Show()
end

function Popup:Fill(fromId, cards)
  local f = self.frame
  local n = #cards
  f:SetWidth(PAD * 2 + CARD_W * n + GAP * (n - 1))
  local from = Q.Guides:Get(fromId)
  self.subtitle:SetText(string.format(L.UI_ROUTECHOICE_SUBTITLE, from and from.title or tostring(fromId)))
  for i = 1, math.max(n, #self.cardFrames) do
    local c = (i <= n) and self:CardFrame(i) or self.cardFrames[i]
    if i <= n then
      c.frame:ClearAllPoints()
      c.frame:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + (i - 1) * (CARD_W + GAP), -HEADER_H)
      fillCard(c, cards[i])
    else
      c.frame.qfData = nil
      c.frame:Hide()
    end
  end
end

---------------------------------------------------------------------------
-- Affichage
---------------------------------------------------------------------------
-- Ouvre le choix pour le chapitre fromId. manual = demandé par le joueur (/qf route, journal, suivi) :
-- s'affiche même avec l'option coupée et dit pourquoi rien ne s'ouvre. -> true si la popup est montrée.
function Popup:Open(fromId, manual)
  if not manual and not automatic() then return false end
  if not Q.Guides:Get(fromId) then return false end
  local options = Q.Progress:RouteOptions(fromId)
  if #options < 2 then
    if manual then Q:Print(L.UI_ROUTECHOICE_NONE) end
    return false
  end
  if inCombat() then
    self.pending = fromId
    return false
  end
  self.pending = nil
  self.fromId = fromId
  self.cards = Q.RouteChoice:Rank(options)
  local f = self:Create()
  self:Fill(fromId, self.cards)
  f:Show()
  if type(UIFrameFadeIn) == "function" then pcall(UIFrameFadeIn, f, 0.2, 0, 1) end
  return true
end

function Popup:IsShown()
  return self.frame ~= nil and self.frame:IsShown()
end

-- Ferme sans choisir (« Plus tard », Échap) : le chapitre reste en attente (Progress:PendingChoice).
function Popup:Hide()
  self.pending = nil
  if self.frame then self.frame:Hide() end
end

function Popup:Choose(id)
  local fromId = self.fromId
  self:Hide()
  if fromId and id then Q.Progress:ChooseRoute(fromId, id) end
end

-- « Garder la route prévue » : la suite par défaut (Guides:Next).
function Popup:Keep()
  for _, c in ipairs(self.cards or {}) do
    if c.default then return self:Choose(c.id) end
  end
  self:Hide()
end

function Popup:Suspend()
  if self.frame and self.frame:IsShown() then
    self.frame:Hide()
    self.pending = self.fromId
  end
end

function Popup:Resume()
  if self.pending and not inCombat() then self:Open(self.pending, true) end
end

-- Choix demandé par le joueur : le chapitre en attente, sinon celui de Progress:ChoiceNode.
function Popup:OpenForPlayer()
  local node = Q.Progress:PendingChoice() or Q.Progress:ChoiceNode()
  if not node then
    Q:Print(L.UI_ROUTECHOICE_NONE)
    return false
  end
  return self:Open(node, true)
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
Q:On("ROUTE_CHOICE_NEEDED", function(fromId) Popup:Open(fromId) end)
Q:RegisterEvent("PLAYER_REGEN_DISABLED", function() Q.SafeCall(Popup.Suspend, Popup) end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function() Q.SafeCall(Popup.Resume, Popup) end)
Q:On("SETTINGS_CHANGED", function(path)
  if (path == "route" or path == "route.choicePopup") and not automatic() then Popup:Hide() end
end)
