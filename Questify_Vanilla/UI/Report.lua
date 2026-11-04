local addonName, Q = ...

-- Fenêtre du rapport de bug (/qf report, bouton des options) : texte multi-ligne en lecture
-- seule, sélectionné à l'ouverture pour Ctrl + C. Aucun bouton sécurisé : elle s'ouvre aussi
-- en combat. Le texte est recalculé à chaque ouverture (Q.Diagnostics:Report()).
Q.UI = Q.UI or {}
local Report = {}
Q.UI.Report = Report

local L = Q.L

local FRAME_NAME = "QuestifyVanillaReport"
local WIDTH, HEIGHT = 640, 460

local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "BasicFrameTemplateWithInset")
  if ok and f then return f, true end
  f = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  end
  return f, false
end

function Report:Create()
  if self.frame then return self.frame end
  local f, templated = newFrame()
  self.frame = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  if UISpecialFrames then tinsert(UISpecialFrames, FRAME_NAME) end

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", f, "TOP", 0, templated and -5 or -16)
  title:SetText(L.REPORT_TITLE)
  self.title = title

  if not templated then
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  end

  local scroll = CreateFrame("ScrollFrame", FRAME_NAME .. "Scroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -32)
  scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -34, 44)
  self.scroll = scroll

  local box = CreateFrame("EditBox", FRAME_NAME .. "Text", scroll)
  box:SetMultiLine(true)
  box:SetAutoFocus(false)
  if box.SetMaxLetters then box:SetMaxLetters(0) end
  if box.SetMaxBytes then box:SetMaxBytes(0) end
  box:SetFontObject(GameFontHighlightSmall)
  box:SetWidth(WIDTH - 54)
  box:SetHeight(HEIGHT - 80)
  box:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    f:Hide()
  end)
  -- Lecture seule : toute frappe remet le rapport et le resélectionne.
  box:SetScript("OnTextChanged", function(self, userInput)
    if userInput and Report.text then
      self:SetText(Report.text)
      self:HighlightText()
    end
  end)
  -- Le défilement suit le curseur (fonctions des modèles du jeu).
  if ScrollingEdit_OnCursorChanged then box:SetScript("OnCursorChanged", ScrollingEdit_OnCursorChanged) end
  if ScrollingEdit_OnUpdate then
    box:SetScript("OnUpdate", function(self, elapsed) ScrollingEdit_OnUpdate(self, elapsed, scroll) end)
  end
  scroll:SetScrollChild(box)
  -- Un clic dans la zone vide donne aussi le focus à la zone de texte.
  scroll:EnableMouse(true)
  scroll:SetScript("OnMouseDown", function() box:SetFocus() end)
  self.box = box

  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 16)
  hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
  hint:SetJustifyH("LEFT")
  hint:SetText(L.REPORT_HINT)
  self.hint = hint

  f:Hide()
  return f
end

-- Texte du rapport ; une erreur du diagnostic donne un rapport réduit qui la contient.
local function buildText()
  local D = Q.Diagnostics
  local ok, text = pcall(D.Report, D)
  if ok and type(text) == "string" then return text end
  Q:ReportError(text)
  return "Questify Vanilla " .. tostring(Q.version) .. " - bug report failed:\n" .. tostring(text)
end

function Report:Show()
  local f = self:Create()
  self.text = buildText()
  self.box:SetText(self.text)
  f:Show()
  self.box:SetFocus()
  self.box:HighlightText()
end

function Report:Hide()
  if self.frame then self.frame:Hide() end
end

function Report:IsShown()
  return self.frame ~= nil and self.frame:IsShown()
end
