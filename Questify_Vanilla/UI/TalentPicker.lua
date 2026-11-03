local addonName, Q = ...

-- Fenêtre « Quel build de talents ? » : un bouton par preset de la classe (montée en niveau,
-- donjon…) et « Aucun ». S'ouvre au niveau 10 (message TALENTS_ASK) et depuis le journal.
Q.UI = Q.UI or {}
local Picker = { buttons = {} }
Q.UI.TalentPicker = Picker

local L = Q.L

local FRAME_NAME = "QuestifyVanillaTalentPicker"
local WIDTH = 380
local ROW_H = 30

local function safe(fn)
  return function(...) return Q.SafeCall(fn, ...) end
end

local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "BasicFrameTemplateWithInset")
  if ok and f then return f end
  return CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
end

function Picker:Create()
  if self.frame then return self.frame end
  local f = newFrame()
  self.frame = f
  f:SetSize(WIDTH, 200)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  local title = f.TitleText or f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  if not f.TitleText then title:SetPoint("TOP", f, "TOP", 0, -8) end
  title:SetText(L.UI_TALENT_PICK_TITLE)
  local intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -34)
  intro:SetWidth(WIDTH - 36)
  intro:SetJustifyH("LEFT")
  intro:SetWordWrap(true)
  intro:SetText(L.UI_TALENT_PICK_INTRO)
  self.intro = intro
  f:Hide()
  return f
end

local function button(i)
  local b = Picker.buttons[i]
  if b then return b end
  b = CreateFrame("Button", FRAME_NAME .. "Option" .. i, Picker.frame, "UIPanelButtonTemplate")
  b:SetSize(WIDTH - 36, 24)
  b:SetScript("OnClick", safe(function(self)
    Q.Talents:Choose(self.key)
    Picker.frame:Hide()
    if self.key then
      Q:Print(L.UI_TALENT_PICKED, self:GetText() or "")
      local nxt = Q.Talents:Next()
      if nxt and Q.Talents:Unspent() > 0 then Q:Print(L.TALENT_LEVEL_ADVICE, Q.Talents:Advice(nxt)) end
    else
      Q:Print(L.UI_TALENT_PICKED_NONE)
    end
  end))
  Picker.buttons[i] = b
  return b
end

function Picker:Show()
  local presets = Q.Talents:Presets()
  if #presets == 0 then
    Q:Print(L.UI_TALENT_NO_DATA)
    return
  end
  if inCombat() then
    self.pendingShow = true
    return
  end
  self:Create()
  local y = 34 + (self.intro:GetStringHeight() or 30) + 12
  local chosen = Q.char and Q.char.talentPreset
  local n = 0
  for _, p in ipairs(presets) do
    n = n + 1
    local b = button(n)
    b.key = p.key
    b:SetText((chosen == p.key and "> " or "") .. Q.Talents:PresetTitle(p))
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 18, -y)
    b:Show()
    y = y + ROW_H
  end
  n = n + 1
  local none = button(n)
  none.key = false
  none:SetText(L.UI_TALENT_PICK_NONE)
  none:ClearAllPoints()
  none:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 18, -y)
  none:Show()
  y = y + ROW_H
  for i = n + 1, #self.buttons do self.buttons[i]:Hide() end
  self.frame:SetHeight(y + 14)
  self.frame:Show()
end

Q:On("TALENTS_ASK", function()
  if Q.Talents:HasAnswered() then return end
  Picker:Show()
end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if Picker.pendingShow then
    Picker.pendingShow = false
    Picker:Show()
  end
end)
