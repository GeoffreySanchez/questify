local addonName, Q = ...

-- Fenêtre « Quels métiers veux-tu apprendre ? » : métiers principaux (deux au plus) et secondaires.
-- S'ouvre tant que le choix n'est pas fait, une fois par session au plus, après l'assistant de
-- démarrage (terminé, ou fermé pendant la session), et depuis le journal (onglet Options).
-- « Valider » enregistre le choix (Q.Professions:SetChosen) ; « Plus tard » referme sans rien
-- enregistrer : la question revient à la prochaine connexion.
Q.UI = Q.UI or {}
local Picker = { checks = {} }
Q.UI.ProfessionPicker = Picker

local L = Q.L

local FRAME_NAME = "QuestifyProfessionPicker"
local WIDTH, HEIGHT = 420, 400
local AUTO_DELAY = 4
local ROW_H = 24

local function safe(fn)
  return function(...) return Q.SafeCall(fn, ...) end
end

local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "BasicFrameTemplateWithInset")
  if ok and f then return f end
  return CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
end

local function primaryCount(self)
  local n = 0
  for key, cb in pairs(self.checks) do
    if Q.Professions.BY_KEY[key].primary and cb:GetChecked() then n = n + 1 end
  end
  return n
end

function Picker:Create()
  if self.frame then return self.frame end
  local f = newFrame()
  self.frame = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  if f.SetBackdrop and not f.TitleText then
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 24,
      insets = { left = 6, right = 6, top = 6, bottom = 6 } })
  end
  local title = f.TitleText or f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  if not f.TitleText then title:SetPoint("TOP", f, "TOP", 0, -8) end
  title:SetText(L.UI_PROF_TITLE)

  local intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -34)
  intro:SetWidth(WIDTH - 36)
  intro:SetJustifyH("LEFT")
  intro:SetWordWrap(true)
  intro:SetText(L.UI_PROF_INTRO)

  local colPrimary = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  colPrimary:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -84)
  colPrimary:SetText(L.UI_PROF_PRIMARY)
  local colSecondary = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  colSecondary:SetPoint("TOPLEFT", f, "TOPLEFT", WIDTH / 2 + 10, -84)
  colSecondary:SetText(L.UI_PROF_SECONDARY)

  local warn = f:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
  warn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 44)
  warn:SetText("")
  self.warn = warn

  local yP, yS, seq = 104, 104, 0
  for _, p in ipairs(Q.Professions.LIST) do
    seq = seq + 1
    local cb = CreateFrame("CheckButton", FRAME_NAME .. "Check" .. seq, f, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local x = p.primary and 18 or (WIDTH / 2 + 10)
    local y = p.primary and yP or yS
    cb:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    label:SetText(Q.Professions:Name(p.key))
    cb.key, cb.label = p.key, label
    cb:SetScript("OnClick", safe(function(self)
      if self:GetChecked() and Q.Professions.BY_KEY[self.key].primary and primaryCount(Picker) > Q.Professions.MAX_PRIMARY then
        self:SetChecked(false)
        Picker.warn:SetText(L.UI_PROF_MAX)
        return
      end
      Picker.warn:SetText("")
    end))
    self.checks[p.key] = cb
    if p.primary then yP = yP + ROW_H else yS = yS + ROW_H end
  end

  local ok = CreateFrame("Button", FRAME_NAME .. "OK", f, "UIPanelButtonTemplate")
  ok:SetSize(120, 24)
  ok:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 14)
  ok:SetText(L.UI_PROF_OK)
  ok:SetScript("OnClick", safe(function() Picker:Validate() end))
  local later = CreateFrame("Button", FRAME_NAME .. "Later", f, "UIPanelButtonTemplate")
  later:SetSize(120, 24)
  later:SetPoint("RIGHT", ok, "LEFT", -8, 0)
  later:SetText(L.UI_PROF_LATER)
  later:SetScript("OnClick", safe(function() Picker.frame:Hide() end))
  self.okButton, self.laterButton = ok, later
  f:Hide()
  return f
end

function Picker:Show()
  if inCombat() then
    self.pendingShow = true
    return
  end
  self:Create()
  local chosen = Q.Professions:Chosen() or {}
  for key, cb in pairs(self.checks) do cb:SetChecked(chosen[key] == true) end
  self.warn:SetText("")
  self.frame:Show()
end

function Picker:Validate()
  local set = {}
  for key, cb in pairs(self.checks) do
    if cb:GetChecked() then set[key] = true end
  end
  Q.Professions:SetChosen(set)
  self.frame:Hide()
  local names = {}
  for _, p in ipairs(Q.Professions.LIST) do
    if set[p.key] then names[#names + 1] = Q.Professions:Name(p.key) end
  end
  if #names > 0 then
    Q:Print(L.UI_PROF_SAVED, table.concat(names, ", "))
  else
    Q:Print(L.UI_PROF_NONE)
  end
end

-- Tant que le choix n'est pas fait, au plus une fois par session, quand l'assistant de démarrage
-- est terminé ou a été fermé pendant cette session (jamais pendant qu'il est ouvert).
local function autoShow()
  if not Q.char or Q.Professions:HasAnswered() or Picker.autoShown then return end
  local W = Q.UI.Wizard
  local wizardPassed = Q.char.wizardDone or (W and W.ClosedThisSession and W:ClosedThisSession())
  if not wizardPassed then return end
  if W and W:IsShown() then return end
  Picker.autoShown = true
  Picker:Show()
end
Picker.AutoShow = autoShow

Q:On("LOGIN", function()
  Q:After(AUTO_DELAY, autoShow)
end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if Picker.pendingShow then
    Picker.pendingShow = false
    Picker:Show()
  end
end)
