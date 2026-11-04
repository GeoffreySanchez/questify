local addonName, Q = ...

-- Assistant de navigation (spec § 4 : un seul fournisseur actif), en quatre pages :
--   1. fournisseurs détectés (Q.Nav:Detect()), une phrase chacun ;
--   2. itinéraire par ShortestPath Forever (case active seulement s'il est installé) ;
--   3. repère : WaypointUI, TomTom ou repère du jeu (les absents sont désactivés) ;
--   4. automatisation (accepter/rendre, choix de la récompense).
-- « Terminer » enregistre tout par Q.Settings:Set et pose Q.char.wizardDone.
-- Ouverture automatique une seule fois, 3 s après « LOGIN », tant que wizardDone n'est pas posé.
Q.UI = Q.UI or {}
local Wizard = { page = 1, pages = {}, radios = {}, checks = {}, providerRows = {} }
Q.UI.Wizard = Wizard

local L = Q.L

local FRAME_NAME = "QuestifyVanillaWizard"
local WIDTH, HEIGHT = 460, 380
local INNER = WIDTH - 48
local NUM_PAGES = 4
local AUTO_DELAY = 3

local PROVIDERS = { "shortestpath", "waypointui", "tomtom", "native" }
local DISPLAYS = { "waypointui", "tomtom", "native" }
local PROVIDER_TEXT = {
  shortestpath = { "UI_NAV_SHORTESTPATH", "UI_NAV_SHORTESTPATH_DESC" },
  waypointui = { "UI_NAV_WAYPOINTUI", "UI_NAV_WAYPOINTUI_DESC" },
  tomtom = { "UI_NAV_TOMTOM", "UI_NAV_TOMTOM_DESC" },
  native = { "UI_NAV_NATIVE", "UI_NAV_NATIVE_DESC" },
}
local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
local NOT_READY = "Interface\\RaidFrame\\ReadyCheck-NotReady"

local function safe(fn)
  return function(...) return Q.SafeCall(fn, ...) end
end

local function playSound(kit)
  if PlaySound and SOUNDKIT and SOUNDKIT[kit] then pcall(PlaySound, SOUNDKIT[kit]) end
end

-- Détection : Q.Nav:Detect() (flux C) ; à défaut, les mêmes règles sur les globales.
-- Le repère du jeu (native) est toujours disponible.
function Wizard:Detect()
  if Q.Nav and Q.Nav.Detect then
    local ok, d = pcall(Q.Nav.Detect, Q.Nav)
    if ok and type(d) == "table" then
      d.native = true
      return d
    end
  end
  return {
    shortestpath = type(ShortestPathForever) == "table" and ShortestPathForever.API ~= nil,
    waypointui = type(WaypointUIAPI) == "table" and WaypointUIAPI.Navigation ~= nil,
    tomtom = type(TomTom) == "table" and TomTom.AddWaypoint ~= nil,
    native = true,
  }
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
  if ok and f then return f end
  return CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
end

local function pageTitle(page, key)
  local t = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  t:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
  t:SetWidth(INNER)
  t:SetJustifyH("LEFT")
  t:SetText(L[key])
  return t
end

local function paragraph(page, text, anchor, gap)
  local p = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  p:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -(gap or 8))
  p:SetWidth(INNER)
  p:SetJustifyH("LEFT")
  p:SetWordWrap(true)
  p:SetText(text)
  return p
end

local widgetSeq = 0
local function newButton(kind, parent, template)
  widgetSeq = widgetSeq + 1
  return CreateFrame(kind, FRAME_NAME .. "Widget" .. widgetSeq, parent, template)
end

local function labelFor(widget, text, font)
  local fs = widget:GetParent():CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
  fs:SetPoint("LEFT", widget, "RIGHT", 4, 1)
  fs:SetWidth(INNER - 40)
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  return fs
end

function Wizard:BuildPage1(page)
  local title = pageTitle(page, "UI_WIZ_P1_TITLE")
  local y = (title:GetStringHeight() or 18) + 14
  for _, id in ipairs(PROVIDERS) do
    local row = {}
    row.icon = page:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -y)
    row.name = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.name:SetText(L[PROVIDER_TEXT[id][1]])
    row.status = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.status:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
    row.desc = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.desc:SetPoint("TOPLEFT", row.icon, "BOTTOMLEFT", 22, -2)
    row.desc:SetWidth(INNER - 22)
    row.desc:SetJustifyH("LEFT")
    row.desc:SetText(L[PROVIDER_TEXT[id][2]])
    self.providerRows[id] = row
    y = y + 44
  end
end

function Wizard:BuildPage2(page)
  local title = pageTitle(page, "UI_WIZ_P2_TITLE")
  local text = paragraph(page, L.UI_WIZ_P2_TEXT, title, 10)
  local cb = newButton("CheckButton", page, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  cb:SetPoint("TOPLEFT", text, "BOTTOMLEFT", -4, -14)
  cb.label = labelFor(cb, L.UI_WIZ_ROUTING)
  cb:SetScript("OnClick", safe(function(self)
    if not self:IsEnabled() then return end
    Wizard.choice.routing = self:GetChecked() and true or false
  end))
  self.checks.routing = cb
  local missing = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  missing:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 30, -2)
  missing:SetWidth(INNER - 30)
  missing:SetJustifyH("LEFT")
  missing:SetText(L.UI_WIZ_ROUTING_MISSING)
  self.routingMissing = missing
end

function Wizard:BuildPage3(page)
  local title = pageTitle(page, "UI_WIZ_P3_TITLE")
  local anchor = paragraph(page, L.UI_WIZ_P3_TEXT, title, 10)
  local gap = 14
  for _, id in ipairs(DISPLAYS) do
    local r = newButton("CheckButton", page, "UIRadioButtonTemplate")
    r:SetSize(16, 16)
    r:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
    r.id = id
    r.label = labelFor(r, L[PROVIDER_TEXT[id][1]])
    r.desc = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.desc:SetPoint("TOPLEFT", r, "BOTTOMLEFT", 20, -2)
    r.desc:SetWidth(INNER - 20)
    r.desc:SetJustifyH("LEFT")
    r.desc:SetText(L[PROVIDER_TEXT[id][2]])
    r:SetScript("OnClick", safe(function(self)
      if not self:IsEnabled() then return end
      playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
      Wizard:SelectDisplay(self.id)
    end))
    self.radios[id] = r
    anchor = r.desc
    gap = 12
  end
end

function Wizard:BuildPage4(page)
  local title = pageTitle(page, "UI_WIZ_P4_TITLE")
  local anchor = paragraph(page, L.UI_WIZ_P4_TEXT, title, 10)
  local defs = { { "autoQuest", "UI_OPT_AUTOQUEST" }, { "autoReward", "UI_OPT_AUTOREWARD" } }
  local x = -4   -- la première case s'aligne sur le texte, les suivantes sur la case précédente
  for _, def in ipairs(defs) do
    local cb = newButton("CheckButton", page, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, -10)
    x = 0
    cb.label = labelFor(cb, L[def[2]])
    cb.path = def[1]
    cb:SetScript("OnClick", safe(function(self)
      Wizard.choice[self.path] = self:GetChecked() and true or false
    end))
    self.checks[def[1]] = cb
    anchor = cb
  end
end

function Wizard:Create()
  if self.frame then return self.frame end
  local f = newFrame()
  self.frame = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  if f.SetTitle then f:SetTitle(L.UI_WIZ_TITLE) end
  if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, "Interface\\Icons\\INV_Misc_Map_01") end
  if UISpecialFrames then tinsert(UISpecialFrames, FRAME_NAME) end

  local content = CreateFrame("Frame", nil, f)
  content:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -70)
  content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 34)
  for i = 1, NUM_PAGES do
    local page = CreateFrame("Frame", nil, content)
    page:SetAllPoints(content)
    page:Hide()
    self.pages[i] = page
  end
  self:BuildPage1(self.pages[1])
  self:BuildPage2(self.pages[2])
  self:BuildPage3(self.pages[3])
  self:BuildPage4(self.pages[4])

  local step = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  step:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
  self.stepText = step

  local function bottomButton(label, onClick)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(110, 22)
    b:SetText(label)
    b:SetScript("OnClick", safe(onClick))
    return b
  end
  self.prevButton = bottomButton(L.UI_WIZ_PREV, function() Wizard:SetPage(Wizard.page - 1) end)
  self.prevButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 4)
  self.nextButton = bottomButton(L.UI_WIZ_NEXT, function() Wizard:SetPage(Wizard.page + 1) end)
  self.nextButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)
  self.finishButton = bottomButton(L.UI_WIZ_FINISH, function() Wizard:Finish() end)
  self.finishButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)

  f:Hide()
  -- Branché après le Hide() initial : fermer sans terminer vaut refus, l'assistant ne s'ouvre
  -- plus tout seul (/qf wizard le relance). Un parent caché (Alt+Z) ne compte pas.
  f:HookScript("OnHide", function(self)
    if not self:IsShown() and Q.char then Q.char.wizardDone = true end
  end)
  return f
end

---------------------------------------------------------------------------
-- État et pages
---------------------------------------------------------------------------
local function setEnabled(widget, enabled, label)
  if enabled then widget:Enable() else widget:Disable() end
  if label then
    if enabled then label:SetTextColor(1, 1, 1) else label:SetTextColor(0.5, 0.5, 0.5) end
  end
end

function Wizard:SelectDisplay(id)
  if not (self.detected and self.detected[id]) then id = "native" end
  self.choice.display = id
  for rid, r in pairs(self.radios) do r:SetChecked(rid == id) end
end

-- Lit la détection et les réglages actuels, puis prépare chaque page.
function Wizard:Load()
  local d = self:Detect()
  self.detected = d
  local display = Q.Settings:Get("nav.display")
  -- Premier passage : le meilleur repère installé (WaypointUI, puis TomTom, puis le jeu).
  if not (Q.char and Q.char.wizardDone) then
    display = (d.waypointui and "waypointui") or (d.tomtom and "tomtom") or "native"
  end
  self.choice = {
    routing = d.shortestpath and Q.Settings:Get("nav.routing") == true or false,
    display = display,
    autoQuest = Q.Settings:Get("autoQuest") ~= false,
    autoReward = Q.Settings:Get("autoReward") ~= false,
  }
  for _, id in ipairs(PROVIDERS) do
    local row = self.providerRows[id]
    local found = d[id] and true or false
    row.icon:SetTexture(found and READY or NOT_READY)
    row.status:SetText(found and ("|cff40ff40(" .. L.UI_WIZ_FOUND .. ")|r") or ("|cff999999(" .. L.UI_WIZ_MISSING .. ")|r"))
  end
  local routing = self.checks.routing
  setEnabled(routing, d.shortestpath, routing.label)
  routing:SetChecked(self.choice.routing)
  if d.shortestpath then self.routingMissing:Hide() else self.routingMissing:Show() end
  for _, id in ipairs(DISPLAYS) do
    local r = self.radios[id]
    setEnabled(r, d[id] and true or false, r.label)
  end
  self:SelectDisplay(display)
  self.checks.autoQuest:SetChecked(self.choice.autoQuest)
  self.checks.autoReward:SetChecked(self.choice.autoReward)
end

function Wizard:SetPage(n)
  n = math.max(1, math.min(NUM_PAGES, n or 1))
  self.page = n
  for i, page in ipairs(self.pages) do
    if i == n then page:Show() else page:Hide() end
  end
  if n > 1 then self.prevButton:Show() else self.prevButton:Hide() end
  if n < NUM_PAGES then
    self.nextButton:Show()
    self.finishButton:Hide()
  else
    self.nextButton:Hide()
    self.finishButton:Show()
  end
  self.stepText:SetFormattedText(L.UI_WIZ_STEP, n, NUM_PAGES)
end

function Wizard:Show()
  self:Create()
  self:Load()
  self:SetPage(1)
  self.frame:Show()
  self.frame:Raise()
end

function Wizard:IsShown()
  return self.frame ~= nil and self.frame:IsShown()
end

-- Les cases sont relues au moment de terminer : leur état affiché fait foi.
function Wizard:Finish()
  local c = self.choice
  local routing = self.checks.routing
  c.routing = self.detected.shortestpath and routing:IsEnabled() and routing:GetChecked() and true or false
  c.autoQuest = self.checks.autoQuest:GetChecked() and true or false
  c.autoReward = self.checks.autoReward:GetChecked() and true or false
  Q.Settings:Set("nav.routing", c.routing)
  Q.Settings:Set("nav.display", c.display or "native")
  Q.Settings:Set("autoQuest", c.autoQuest)
  Q.Settings:Set("autoReward", c.autoReward)
  if Q.char then Q.char.wizardDone = true end
  -- étape suivante de l'accueil : le choix des métiers
  if Q.UI.ProfessionPicker then Q:After(0.5, Q.UI.ProfessionPicker.AutoShow) end
  self.frame:Hide()
  playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
  Q:Print(L.UI_WIZ_SAVED)
end

---------------------------------------------------------------------------
-- Ouverture automatique (une fois, 3 s après la connexion, jamais en combat)
---------------------------------------------------------------------------
local waitingCombat = false

local function autoShow()
  if not Q.char or Q.char.wizardDone or Wizard:IsShown() then return end
  if InCombatLockdown and InCombatLockdown() then
    waitingCombat = true
    return
  end
  Wizard:Show()
end

Q:On("LOGIN", function()
  if Q.char and not Q.char.wizardDone then Q:After(AUTO_DELAY, autoShow) end
end)

Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if waitingCombat then
    waitingCombat = false
    autoShow()
  end
end)
