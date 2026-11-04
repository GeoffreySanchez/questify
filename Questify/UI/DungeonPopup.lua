local addonName, Q = ...

-- Fenêtre d'un donjon conseillé, ouverte depuis l'alerte du suivi (ou le journal) : nom, plage de
-- niveaux, zone de l'entrée, quêtes avec leur donneur, puis deux choix : « Ajouter à la route » et
-- « Ignorer ». Les deux marquent le donjon comme vu. Même modèle que UI/ClassQuestPopup.lua.
Q.UI = Q.UI or {}
local Popup = { lines = {} }
Q.UI.DungeonPopup = Popup

local L = Q.L

local FRAME_NAME = "QuestifyDungeonPopup"
local WIDTH = 380
local INNER = WIDTH - 40
local MAX_LINES = 10
local OK_COLOR = "|cffffffff"
local LOCKED_COLOR = "|cff909090"
local GIVER_COLOR = "|cff00ff96"

---------------------------------------------------------------------------
-- Textes
---------------------------------------------------------------------------
function Popup.DungeonName(d)
  local D = Q.Dungeons
  if D and D.Name then return D:Name(d) end
  return tostring(type(d) == "table" and (d.name or d.key) or "?")
end

local function giverName(row)
  if row.giver then return Q.QDB:NpcName(row.giver) end
  if row.obj then return Q.QDB:ObjectName(row.obj) end
  return nil
end

-- Ligne d'une quête : « Nom - Donneur (Zone) », grisée avec la raison quand elle n'est pas à prendre.
function Popup.QuestLine(row)
  local name = Q.QDB:QuestName(row.id)
  local who = giverName(row)
  -- donneur en couleur seulement pour une quête à prendre (une ligne grisée reste grise)
  if who and row.ok then who = GIVER_COLOR .. who .. OK_COLOR end
  local text
  if who and type(row.at) == "table" and type(row.at[1]) == "number" then
    text = string.format(L.DUNGEON_QUEST_GIVER, name, who, Q.Maps:MapName(row.at[1]))
  elseif who then
    text = string.format(L.DUNGEON_QUEST_GIVER_NOZONE, name, who)
  else
    text = name
  end
  if row.ok and row.reason ~= "log" then return OK_COLOR .. text .. "|r" end
  local why
  if row.reason == "log" then
    why = L.DUNGEON_IN_LOG
  elseif row.reason == "level" then
    why = string.format(L.DUNGEON_LOCKED_LEVEL, tonumber(row.level) or 1)
  else
    why = L.DUNGEON_LOCKED_PREREQ
  end
  if row.ok then return OK_COLOR .. text .. "|r |cffaaaaaa(" .. why .. ")|r" end
  return LOCKED_COLOR .. text .. " (" .. why .. ")|r"
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
  if not ok or not f then
    f = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
  end
  return f
end

local function text(parent, font, width)
  local fs = parent:CreateFontString(nil, "OVERLAY", font)
  fs:SetJustifyH("LEFT")
  if width then fs:SetWidth(width) end
  return fs
end

function Popup:Create()
  if self.frame then return self.frame end
  local f = newFrame()
  self.frame = f
  f:SetSize(WIDTH, 300)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  if f.SetTitle then f:SetTitle(L.DUNGEON_POPUP_TITLE) end
  if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01") end
  if UISpecialFrames then tinsert(UISpecialFrames, FRAME_NAME) end

  local c = CreateFrame("Frame", nil, f)
  c:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -68)
  c:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 32)
  self.content = c

  self.title = text(c, "GameFontNormalLarge", INNER - 70)
  local counter = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  counter:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, -2)
  counter:SetJustifyH("RIGHT")
  self.counter = counter
  self.level = text(c, "GameFontHighlightSmall")
  self.entrance = text(c, "GameFontHighlight", INNER)
  self.questsHeader = text(c, "GameFontNormal")
  self.questsHeader:SetText(L.DUNGEON_QUESTS)
  self.empty = text(c, "GameFontDisable", INNER)
  self.empty:SetText(L.DUNGEON_NO_QUEST)
  self.more = text(c, "GameFontDisableSmall", INNER)

  local add = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  add:SetSize(150, 22)
  add:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)
  add:SetText(L.UI_BTN_ADD_ROUTE)
  add:SetScript("OnClick", function() Q.SafeCall(function() Popup:Choose("Add") end) end)
  self.addButton = add
  local ignore = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  ignore:SetSize(110, 22)
  ignore:SetPoint("RIGHT", add, "LEFT", -6, 0)
  ignore:SetText(L.UI_BTN_IGNORE)
  ignore:SetScript("OnClick", function() Q.SafeCall(function() Popup:Choose("Ignore") end) end)
  self.ignoreButton = ignore

  f:Hide()
  return f
end

local function line(i)
  local fs = Popup.lines[i]
  if fs then return fs end
  fs = text(Popup.content, "GameFontHighlightSmall", INNER)
  fs:SetWordWrap(true)
  Popup.lines[i] = fs
  return fs
end

local function place(region, y)
  region:ClearAllPoints()
  region:SetPoint("TOPLEFT", Popup.content, "TOPLEFT", 0, -y)
end

---------------------------------------------------------------------------
-- Affichage
---------------------------------------------------------------------------
-- Show(d, index, total) : accepte aussi une ligne { dungeon, state } de Q.Dungeons:List().
function Popup:Show(d, index, total)
  if type(d) == "table" and type(d.dungeon) == "table" then d = d.dungeon end
  if type(d) ~= "table" then return end
  self:Create()
  self.dungeon = d
  local y = 0
  if tonumber(total) and total > 1 then
    self.counter:SetFormattedText(L.UI_POPUP_COUNTER, tonumber(index) or 1, total)
    self.counter:Show()
  else
    self.counter:SetText("")
    self.counter:Hide()
  end
  self.title:SetText(Popup.DungeonName(d))
  place(self.title, y)
  y = y + (self.title:GetStringHeight() or 16) + 4
  self.level:SetFormattedText(L.DUNGEON_LEVELS, tonumber(d.minLevel) or 1, tonumber(d.maxLevel) or 60)
  place(self.level, y)
  y = y + 18
  local ent = type(d.entrance) == "table" and d.entrance[1]
  if type(ent) == "number" then
    self.entrance:SetFormattedText(L.DUNGEON_ENTRANCE, Q.Maps:MapName(ent))
    place(self.entrance, y)
    self.entrance:Show()
    y = y + (self.entrance:GetStringHeight() or 14) + 10
  else
    self.entrance:Hide()
  end

  place(self.questsHeader, y)
  y = y + 18
  local rows = {}
  if Q.Dungeons and Q.Dungeons.Details then
    local ok, res = pcall(Q.Dungeons.Details, Q.Dungeons, d)
    if ok and type(res) == "table" then rows = res elseif not ok then Q:ReportError(res) end
  end
  -- quêtes à prendre d'abord, puis les autres
  local sorted = {}
  for _, r in ipairs(rows) do if r.ok then sorted[#sorted + 1] = r end end
  for _, r in ipairs(rows) do if not r.ok then sorted[#sorted + 1] = r end end
  local shown = math.min(#sorted, MAX_LINES)
  for i = 1, shown do
    local fs = line(i)
    fs:SetText("- " .. Popup.QuestLine(sorted[i]))
    place(fs, y)
    fs:Show()
    y = y + (fs:GetStringHeight() or 13) + 3
  end
  for i = shown + 1, #self.lines do self.lines[i]:Hide() end
  if #sorted > shown then
    self.more:SetFormattedText(L.DUNGEON_MORE, #sorted - shown)
    place(self.more, y)
    self.more:Show()
    y = y + 16
  else
    self.more:Hide()
  end
  local any = false
  for _, r in ipairs(rows) do if r.ok then any = true end end
  if any then
    self.empty:Hide()
    self.addButton:Enable()
  else
    place(self.empty, y)
    self.empty:Show()
    y = y + 18
    self.addButton:Disable()
  end

  self.frame:SetHeight(math.max(220, y + 68 + 40))
  self.frame:Show()
  self.frame:Raise()
end

function Popup:Hide()
  if self.frame then self.frame:Hide() end
end

-- Choix du joueur : le donjon est marqué vu (l'alerte disparaît), puis ajouté ou ignoré (le module
-- envoie DUNGEONS_CHANGED), puis la fenêtre se ferme.
function Popup:Choose(action)
  local d = self.dungeon
  local D = Q.Dungeons
  if d and D then
    if D.MarkSeen then D:MarkSeen(d.key) end
    if D[action] then D[action](D, d.key) end
  end
  self:Hide()
  if Q.UI.Tracker and Q.UI.Tracker.Refresh then Q.UI.Tracker:Refresh() end
end
