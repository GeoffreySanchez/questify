local addonName, Q = ...

-- Journal principal (spec § 5.8), ouvert par /questify, /qf ou le compartiment d'addons.
-- Trois onglets :
--   « Route » : chapitres de la faction à gauche, étapes du chapitre à droite (icône d'état,
--               clic = étape courante) ;
--   « Quêtes de classe » : une ligne par chaîne avec son état et Ajouter / Ignorer / Réactiver ;
--   « Options » : réglages, taille du suivi, assistant, réinitialisation, export des mesures.
Q.UI = Q.UI or {}
local Journal = { tab = "route", panels = {}, tabs = {}, chapterRows = {}, stepRows = {}, classRows = {}, checks = {} }
Q.UI.Journal = Journal

local L = Q.L

local FRAME_NAME = "QuestifyVanillaJournal"
local WIDTH, HEIGHT = 520, 560
local TAB_NAMES = { "route", "class", "options" }
local TAB_INDEX = { route = 1, class = 2, options = 3 }

local CHAPTER_W, CHAPTER_ROW_H = 150, 20
local STEP_W, STEP_ROW_H = 290, 18
local CLASS_W, CLASS_ROW_H = 456, 46
local CLASS_ITEMS = 5
local LIST_H = 432

Journal.STATE_ICONS = {
  done = "Interface\\RaidFrame\\ReadyCheck-Ready",
  skipped = "Interface\\RaidFrame\\ReadyCheck-NotReady",
  current = "Interface\\ChatFrame\\ChatFrameExpandArrow",
  blocked = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK",
}
local ICONS = Journal.STATE_ICONS

local CQ_STATE_TEXT = {
  available = "UI_CQ_AVAILABLE", upcoming = "UI_CQ_UPCOMING", added = "UI_CQ_ADDED",
  ignored = "UI_CQ_IGNORED", inprogress = "UI_CQ_INPROGRESS", done = "UI_CQ_DONE",
}
local CQ_STATE_COLOR = {
  available = "|cff40ff40", upcoming = "|cffaaaaaa", added = "|cffffd100",
  ignored = "|cff808080", inprogress = "|cff66bbff", done = "|cff808080",
}

local function playSound(kit)
  if PlaySound and SOUNDKIT and SOUNDKIT[kit] then pcall(PlaySound, SOUNDKIT[kit]) end
end

local function safe(fn)
  return function(...) return Q.SafeCall(fn, ...) end
end

local function showTooltip(owner, lines, anchor)
  if not GameTooltip then return end
  GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  for i, line in ipairs(lines) do
    if i == 1 then GameTooltip:AddLine(line, 1, 0.82, 0, true) else GameTooltip:AddLine(line, 1, 1, 1, true) end
  end
  GameTooltip:Show()
end
local function hideTooltip() if GameTooltip then GameTooltip:Hide() end end

-- Liste défilante (modèle natif UIPanelScrollFrameTemplate) : -> scrollFrame, enfant.
local function newScroll(parent, name, width, height)
  local scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
  scroll:SetSize(width, height)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(width, 1)
  scroll:SetScrollChild(child)
  return scroll, child
end

-- Fait défiler la liste pour que la ligne `index` soit visible.
local function ensureVisible(scroll, index, rowH, total)
  if not index then return end
  local viewH = scroll:GetHeight() or LIST_H
  local offset = scroll:GetVerticalScroll() or 0
  local top, bottom = (index - 1) * rowH, index * rowH
  if top >= offset and bottom <= offset + viewH then return end
  local maxOffset = math.max(0, total * rowH - viewH)
  local wanted = math.max(0, math.min(maxOffset, top - math.floor(viewH / 3)))
  scroll:SetVerticalScroll(wanted)
end

---------------------------------------------------------------------------
-- Cadre et onglets
---------------------------------------------------------------------------
local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
  if ok and f then return f end
  ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "BasicFrameTemplateWithInset")
  if ok and f then return f end
  return CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
end

function Journal:Create()
  if self.frame then return self.frame end
  local f = newFrame()
  self.frame = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetFrameStrata("MEDIUM")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  if f.SetTitle then f:SetTitle(L.UI_JOURNAL_TITLE) end
  if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, "Interface\\Icons\\INV_Misc_Book_09") end
  if UISpecialFrames then tinsert(UISpecialFrames, FRAME_NAME) end

  -- Zone de contenu : intérieur du cadre « Inset » du modèle (60 px en haut, 26 px en bas).
  local content = CreateFrame("Frame", nil, f)
  content:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -64)
  content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 30)
  self.content = content

  local labels = { L.UI_TAB_ROUTE, L.UI_TAB_CLASS, L.UI_TAB_OPTIONS }
  for i, name in ipairs(TAB_NAMES) do
    local tab = CreateFrame("Button", FRAME_NAME .. "Tab" .. i, f, "PanelTabButtonTemplate")
    tab:SetID(i)
    tab:SetText(labels[i])
    if i == 1 then
      tab:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 12, 2)
    else
      -- même ancre que PanelTemplates_AnchorTabs : l'appel suivant la remplace sans conflit
      tab:SetPoint("TOPLEFT", self.tabs[i - 1], "TOPRIGHT", 3, 0)
    end
    tab:SetScript("OnClick", safe(function()
      playSound("IG_CHARACTER_INFO_TAB")
      Journal:ShowTab(name)
    end))
    if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 0) end
    self.tabs[i] = tab

    local panel = CreateFrame("Frame", nil, content)
    panel:SetAllPoints(content)
    panel:Hide()
    self.panels[name] = panel
  end
  if PanelTemplates_SetNumTabs then pcall(PanelTemplates_SetNumTabs, f, #TAB_NAMES) end

  self:BuildRoute(self.panels.route)
  self:BuildClass(self.panels.class)
  self:BuildOptions(self.panels.options)
  f:Hide()
  -- Sons d'ouverture et de fermeture branchés après le Hide() initial (pas de son à la création).
  f:HookScript("OnShow", function() playSound("IG_CHARACTER_INFO_OPEN") end)
  f:HookScript("OnHide", function() playSound("IG_CHARACTER_INFO_CLOSE") end)
  return f
end

function Journal:IsShown()
  return self.frame ~= nil and self.frame:IsShown()
end

function Journal:Toggle()
  self:Create()
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self:ShowTab(self.tab or "route")
  end
end

-- ShowTab("route" | "class" | "options") : ouvre le journal sur cet onglet.
function Journal:ShowTab(name)
  if not TAB_INDEX[name] then name = "route" end
  self:Create()
  self.tab = name
  if PanelTemplates_SetTab then pcall(PanelTemplates_SetTab, self.frame, TAB_INDEX[name]) end
  for n, panel in pairs(self.panels) do
    if n == name then panel:Show() else panel:Hide() end
  end
  self.frame:Show()
  self:RefreshTab(name, true)
end

function Journal:RefreshTab(name, scroll)
  if name == "route" then
    self:RefreshRoute(scroll)
  elseif name == "class" then
    self:RefreshClass()
  elseif name == "options" then
    self:RefreshOptions()
  end
end

-- Rafraîchit l'onglet visible, si le journal est ouvert.
local function refreshIfShown(name, scroll)
  if Journal:IsShown() and Journal.tab == name then Journal:RefreshTab(name, scroll) end
end

---------------------------------------------------------------------------
-- Onglet Route
---------------------------------------------------------------------------
function Journal:BuildRoute(panel)
  local chHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  chHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
  chHeader:SetText(L.UI_ROUTE_CHAPTERS)
  local stHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  stHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", CHAPTER_W + 34, -4)
  stHeader:SetWidth(STEP_W)
  stHeader:SetJustifyH("LEFT")
  stHeader:SetWordWrap(false)
  stHeader:SetText(L.UI_ROUTE_STEPS)
  self.stepHeader = stHeader

  local chScroll, chChild = newScroll(panel, "QuestifyVanillaJournalChapterScroll", CHAPTER_W, LIST_H)
  chScroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -24)
  self.chapterScroll, self.chapterChild = chScroll, chChild

  local stScroll, stChild = newScroll(panel, "QuestifyVanillaJournalStepScroll", STEP_W, LIST_H)
  stScroll:SetPoint("TOPLEFT", panel, "TOPLEFT", CHAPTER_W + 32, -24)
  self.stepScroll, self.stepChild = stScroll, stChild

  local msg = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  msg:SetPoint("TOPLEFT", stScroll, "TOPLEFT", 4, -4)
  msg:SetWidth(STEP_W - 8)
  msg:SetJustifyH("LEFT")
  msg:Hide()
  self.routeMessage = msg
end

local function chapterRow(i)
  local row = Journal.chapterRows[i]
  if row then return row end
  row = CreateFrame("Button", nil, Journal.chapterChild)
  row:SetSize(CHAPTER_W, CHAPTER_ROW_H)
  row:SetPoint("TOPLEFT", Journal.chapterChild, "TOPLEFT", 0, -(i - 1) * CHAPTER_ROW_H)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
  local sel = row:CreateTexture(nil, "BACKGROUND")
  sel:SetAllPoints(row)
  sel:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
  sel:SetBlendMode("ADD")
  sel:SetVertexColor(1, 0.82, 0, 0.5)
  sel:Hide()
  local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", row, "LEFT", 4, 0)
  text:SetWidth(CHAPTER_W - 40)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(false)
  local lvl = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  lvl:SetPoint("RIGHT", row, "RIGHT", -4, 0)
  lvl:SetJustifyH("RIGHT")
  row.text, row.levels, row.selected = text, lvl, sel
  row:SetScript("OnClick", safe(function(self)
    if self.guide then
      playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
      Q.Progress:SetGuide(self.guide.id)
      Journal:RefreshRoute(true)
    end
  end))
  row:SetScript("OnEnter", safe(function(self)
    if self.guide then
      showTooltip(self, { self.guide.title or self.guide.id,
        string.format(L.UI_TRACKER_LEVELS, self.guide.minLevel or 1, self.guide.maxLevel or 60),
        L.UI_ROUTE_CHAPTER_HINT })
    end
  end))
  row:SetScript("OnLeave", hideTooltip)
  Journal.chapterRows[i] = row
  return row
end

-- Rend une étape courante : les étapes non faites avant elle sont passées, celles passées
-- après elle sont rouvertes (Q.Progress:JumpTo fait tout en un seul recalcul).
local function jumpTo(entry)
  if Q.Progress.JumpTo then
    Q.Progress:JumpTo(entry.key)
    return
  end
  local c = Q.char
  local before = true
  for _, e in ipairs(Q.Progress:Entries()) do
    if e.key == entry.key then
      before = false
      c.skipped[e.key], c.manual[e.key] = nil, nil
    elseif before then
      local s = Q.Progress:State(e)
      if s == "active" or s == "blocked" then c.skipped[e.key] = true end
    else
      c.skipped[e.key] = nil
    end
  end
  Q.Progress:Update()
end

local function stepTooltip(row)
  local e = row.entry
  if not e then return end
  local state, reason = Q.Progress:State(e)
  local lines = { Q.Format:StepTitle(e), Q.Format:StepText(e) }
  local label = ({ done = L.UI_STATE_DONE, skipped = L.UI_STATE_SKIPPED, blocked = L.UI_STATE_BLOCKED,
    active = L.UI_STATE_ACTIVE })[state] or ""
  if row.isCurrent then label = L.UI_STATE_CURRENT end
  if reason and reason ~= "" then label = label .. " - " .. Q.Format:Reason(reason) end
  lines[#lines + 1] = "|cffaaaaaa" .. label .. "|r"
  lines[#lines + 1] = "|cff66bbff" .. L.UI_ROUTE_STEP_HINT .. "|r"
  showTooltip(row, lines)
end

local function stepRow(i)
  local row = Journal.stepRows[i]
  if row then return row end
  row = CreateFrame("Button", nil, Journal.stepChild)
  row:SetSize(STEP_W, STEP_ROW_H)
  row:SetPoint("TOPLEFT", Journal.stepChild, "TOPLEFT", 0, -(i - 1) * STEP_ROW_H)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
  bg:SetBlendMode("ADD")
  bg:SetVertexColor(1, 0.82, 0, 0.45)
  bg:Hide()
  local state = row:CreateTexture(nil, "ARTWORK")
  state:SetSize(14, 14)
  state:SetPoint("LEFT", row, "LEFT", 2, 0)
  local action = row:CreateTexture(nil, "ARTWORK")
  action:SetSize(14, 14)
  action:SetPoint("LEFT", row, "LEFT", 18, 0)
  local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", row, "LEFT", 36, 0)
  text:SetWidth(STEP_W - 38)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(false)
  row.state, row.action, row.text, row.currentBg = state, action, text, bg
  row:SetScript("OnClick", safe(function(self)
    if self.entry then
      playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
      jumpTo(self.entry)
      Journal:RefreshRoute(false)
    end
  end))
  row:SetScript("OnEnter", safe(stepTooltip))
  row:SetScript("OnLeave", hideTooltip)
  Journal.stepRows[i] = row
  return row
end

local function factionChapters()
  local faction = Q.Player and Q.Player.faction
  local list = {}
  for _, g in ipairs(Q.Guides:All()) do
    if g.faction == nil or g.faction == faction then list[#list + 1] = g end
  end
  table.sort(list, function(a, b)
    if (a.minLevel or 1) ~= (b.minLevel or 1) then return (a.minLevel or 1) < (b.minLevel or 1) end
    return a.id < b.id
  end)
  return list
end

local function setStepRow(row, e, cur)
  local state, reason = Q.Progress:State(e)
  local isCurrent = cur ~= nil and e.key == cur.key
  row.entry, row.isCurrent = e, isCurrent
  row.action:SetTexture(Q.Format:ActionIcon(e.step.action))
  local text = Q.Util.StripColors(Q.Format:StepTitle(e))
  local icon
  if isCurrent then
    icon = ICONS.current
  elseif state == "done" then
    icon = ICONS.done
  elseif state == "skipped" then
    icon = ICONS.skipped
  elseif state == "blocked" then
    icon = ICONS.blocked
  end
  if state == "blocked" and reason then
    text = text .. " |cffff5555(" .. Q.Format:Reason(reason) .. ")|r"
  end
  row.state:SetTexture(icon)
  row.state:SetDesaturated(state == "skipped")
  if icon then row.state:Show() else row.state:Hide() end
  row.action:SetDesaturated(state == "done" or state == "skipped")
  row.text:SetText(text)
  if isCurrent then
    row.text:SetTextColor(1, 0.82, 0)
  elseif state == "skipped" then
    row.text:SetTextColor(0.5, 0.5, 0.5)
  elseif state == "done" then
    row.text:SetTextColor(0.75, 0.75, 0.75)
  else
    row.text:SetTextColor(1, 1, 1)
  end
  if isCurrent then row.currentBg:Show() else row.currentBg:Hide() end
  row:Show()
end

function Journal:RefreshRoute(scrollToCurrent)
  if not self.frame then return end
  local available = Q.QDB and Q.QDB:IsAvailable()
  -- Chapitres
  local chapters = available and factionChapters() or {}
  local guide = available and Q.Progress:Guide() or nil
  for i, g in ipairs(chapters) do
    local row = chapterRow(i)
    row.guide = g
    row.text:SetText(g.title or g.id)
    row.levels:SetFormattedText(L.UI_TRACKER_LEVELS, g.minLevel or 1, g.maxLevel or 60)
    local selected = guide ~= nil and guide.id == g.id
    if selected then row.selected:Show() else row.selected:Hide() end
    if selected then row.text:SetTextColor(1, 0.82, 0) else row.text:SetTextColor(1, 1, 1) end
    row:Show()
  end
  for i = #chapters + 1, #self.chapterRows do
    self.chapterRows[i].guide = nil
    self.chapterRows[i]:Hide()
  end
  self.chapterChild:SetHeight(math.max(1, #chapters * CHAPTER_ROW_H))

  -- Étapes
  local entries = guide and Q.Progress:Entries() or {}
  if not available then
    self.routeMessage:SetText(Q.QDB and Q.QDB.Status and Q.QDB:Status() == "old" and L.QUESTIEDB_TOO_OLD
      or L.NEED_QUESTIEDB)
    self.routeMessage:Show()
  elseif not guide then
    self.routeMessage:SetText(L.UI_ROUTE_NO_GUIDE)
    self.routeMessage:Show()
  else
    self.routeMessage:Hide()
  end
  self.stepHeader:SetText(guide and (L.UI_ROUTE_STEPS .. " - " .. (guide.title or guide.id)) or L.UI_ROUTE_STEPS)
  local cur = guide and Q.Progress:Current() or nil
  local curIndex
  for i, e in ipairs(entries) do
    setStepRow(stepRow(i), e, cur)
    if cur and e.key == cur.key then curIndex = i end
  end
  for i = #entries + 1, #self.stepRows do
    self.stepRows[i].entry = nil
    self.stepRows[i]:Hide()
  end
  self.stepChild:SetHeight(math.max(1, #entries * STEP_ROW_H))
  if scrollToCurrent then ensureVisible(self.stepScroll, curIndex, STEP_ROW_H, #entries) end
end

---------------------------------------------------------------------------
-- Onglet Quêtes de classe
---------------------------------------------------------------------------
function Journal:BuildClass(panel)
  local scroll, child = newScroll(panel, "QuestifyVanillaJournalClassScroll", CLASS_W, LIST_H + 20)
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -4)
  self.classScroll, self.classChild = scroll, child
  local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -10)
  empty:SetWidth(CLASS_W - 16)
  empty:SetJustifyH("LEFT")
  empty:Hide()
  self.classEmpty = empty
end

local function classAction(method, key)
  local cq = Q.ClassQuests
  if not (cq and cq[method]) then return end
  playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
  cq[method](cq, key)
  Journal:RefreshClass()
end

local function classTooltip(row)
  local chain = row.chain
  if not chain then return end
  local lines = { Q.UI.ClassQuestPopup.ChainTitle(chain), L.UI_CLASS_QUESTS }
  for _, id in ipairs(chain.quests or {}) do
    local q = Q.QDB:Quest(id)
    local lvl = q and q.level and (" |cffaaaaaa(" .. q.level .. ")|r") or ""
    lines[#lines + 1] = "- " .. Q.QDB:QuestName(id) .. lvl
  end
  local xp = 0
  for _, r in pairs(type(chain.rewards) == "table" and chain.rewards or {}) do
    if type(r) == "table" and type(r.xp) == "number" then xp = xp + r.xp end
  end
  if xp > 0 then lines[#lines + 1] = string.format(L.UI_POPUP_XP, xp) end
  showTooltip(row, lines)
end

local function classRow(i)
  local row = Journal.classRows[i]
  if row then return row end
  local parent = Journal.classChild
  row = CreateFrame("Button", nil, parent)
  row:SetSize(CLASS_W, CLASS_ROW_H)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i - 1) * CLASS_ROW_H)
  if i % 2 == 0 then
    local stripe = row:CreateTexture(nil, "BACKGROUND")
    stripe:SetAllPoints(row)
    stripe:SetColorTexture(1, 1, 1, 0.04)
  end
  local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -7)
  title:SetWidth(200)
  title:SetJustifyH("LEFT")
  title:SetWordWrap(false)
  local info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  info:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  info:SetWidth(200)
  info:SetJustifyH("LEFT")
  info:SetWordWrap(false)
  row.title, row.info, row.items = title, info, {}
  for j = 1, CLASS_ITEMS do
    local b = Q.UI.ClassQuestPopup.CreateItemButton(row, 24)
    b:SetPoint("LEFT", row, "LEFT", 214 + (j - 1) * 26, 0)
    row.items[j] = b
  end
  local function button(label, width)
    local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(label)
    b:Hide()
    return b
  end
  row.ignoreButton = button(L.UI_BTN_IGNORE, 80)
  row.unignoreButton = button(L.UI_BTN_UNIGNORE, 80)
  row.addButton = button(L.UI_BTN_ADD, 80)
  row.ignoreButton:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  row.unignoreButton:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  -- Ignorer et Réactiver occupent la même place (jamais affichés ensemble) : Ajouter à leur gauche.
  row.addButton:SetPoint("RIGHT", row, "RIGHT", -90, 0)
  row.addButton:SetScript("OnClick", safe(function() if row.chain then classAction("Add", row.chain.key) end end))
  row.ignoreButton:SetScript("OnClick", safe(function() if row.chain then classAction("Ignore", row.chain.key) end end))
  row.unignoreButton:SetScript("OnClick", safe(function() if row.chain then classAction("Unignore", row.chain.key) end end))
  row:SetScript("OnEnter", safe(classTooltip))
  row:SetScript("OnLeave", hideTooltip)
  Journal.classRows[i] = row
  return row
end

local function setClassRow(row, item)
  local chain, state = item.chain, item.state
  row.chain, row.cqState = chain, state
  row.title:SetText(Q.UI.ClassQuestPopup.ChainTitle(chain))
  local stateKey = CQ_STATE_TEXT[state]
  local stateText = stateKey and L[stateKey] or tostring(state)
  row.info:SetText(string.format(L.UI_CLASS_ROW_INFO, tonumber(chain.level) or 1,
    (CQ_STATE_COLOR[state] or "|cffffffff") .. stateText .. "|r"))
  local items, n = {}, 0
  local rewards = type(chain.rewards) == "table" and chain.rewards or {}
  for _, id in ipairs(chain.quests or {}) do
    local r = rewards[id]
    for _, itemId in ipairs(type(r) == "table" and r.items or {}) do
      if n < CLASS_ITEMS then
        n = n + 1
        items[n] = itemId
      end
    end
  end
  for j = 1, CLASS_ITEMS do
    if items[j] then Q.UI.ClassQuestPopup.SetItemButton(row.items[j], items[j]) else row.items[j]:Hide() end
  end
  -- Une chaîne ignorée se rajoute directement (Add efface l'état « ignorée ») ou se réactive.
  local canAdd = state == "available" or state == "upcoming" or state == "inprogress" or state == "ignored"
  local canIgnore = state == "available" or state == "upcoming" or state == "inprogress" or state == "added"
  if canAdd then row.addButton:Show() else row.addButton:Hide() end
  if canIgnore then row.ignoreButton:Show() else row.ignoreButton:Hide() end
  if state == "ignored" then row.unignoreButton:Show() else row.unignoreButton:Hide() end
  row:Show()
end

function Journal:RefreshClass()
  if not self.frame then return end
  local cq = Q.ClassQuests
  local list
  local qdbOk = Q.QDB and Q.QDB:IsAvailable()
  if qdbOk and cq and cq.List then
    local ok, res = pcall(cq.List, cq)
    if ok and type(res) == "table" then list = res elseif not ok then Q:ReportError(res) end
  end
  local n = 0
  for _, item in ipairs(list or {}) do
    if type(item) == "table" and type(item.chain) == "table" then
      n = n + 1
      setClassRow(classRow(n), item)
    end
  end
  for i = n + 1, #self.classRows do
    self.classRows[i].chain = nil
    self.classRows[i]:Hide()
  end
  self.classChild:SetHeight(math.max(1, n * CLASS_ROW_H))
  if not qdbOk then
    self.classEmpty:SetText(Q.QDB and Q.QDB.Status and Q.QDB:Status() == "old" and L.QUESTIEDB_TOO_OLD
      or L.NEED_QUESTIEDB)
    self.classEmpty:Show()
  elseif not list then
    self.classEmpty:SetText(L.UI_CLASS_UNAVAILABLE)
    self.classEmpty:Show()
  elseif n == 0 then
    self.classEmpty:SetText(L.UI_CLASS_EMPTY)
    self.classEmpty:Show()
  else
    self.classEmpty:Hide()
  end
end

---------------------------------------------------------------------------
-- Onglet Options
---------------------------------------------------------------------------
local OPTION_GROUPS = {
  { title = "UI_OPT_AUTOMATION", checks = { { "autoQuest", "UI_OPT_AUTOQUEST" }, { "autoReward", "UI_OPT_AUTOREWARD" },
    { "tracker.autoTarget", "UI_OPT_AUTOTARGET" } } },
  { title = "UI_OPT_ROUTE", checks = { { "dungeonQuests", "UI_OPT_DUNGEON" } } },
  { title = "UI_OPT_DISPLAY", checks = { { "nameplates", "UI_OPT_NAMEPLATES" },
    { "objectGlow", "UI_OPT_OBJECTGLOW" }, { "tracker.locked", "UI_OPT_LOCKED" },
    { "tracker.showMobs", "UI_OPT_SHOWMOBS" } }, scale = true },
  { title = "UI_OPT_TOOLS", checks = { { "telemetry", "UI_OPT_TELEMETRY" } }, tools = true },
}
local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.6, 1.6, 0.1

local checkSeq = 0
local function newCheck(parent, path, label)
  checkSeq = checkSeq + 1
  local cb = CreateFrame("CheckButton", "QuestifyVanillaJournalCheck" .. checkSeq, parent, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("LEFT", cb, "RIGHT", 2, 1)
  text:SetWidth(CLASS_W - 40)
  text:SetJustifyH("LEFT")
  text:SetText(label)
  cb.label, cb.path = text, path
  cb:SetScript("OnClick", safe(function(self)
    local on = self:GetChecked() and true or false
    playSound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    Q.Settings:Set(self.path, on)
  end))
  return cb
end

local function scaleValue()
  return tonumber(Q.Settings:Get("tracker.scale")) or 1
end

local function changeScale(delta)
  local v = Q.Util.Round(scaleValue() + delta, 2)
  v = math.max(SCALE_MIN, math.min(SCALE_MAX, v))
  Q.Settings:Set("tracker.scale", v)
end

local function resetChapter()
  local guide = Q.Progress:Guide()
  if not (guide and Q.char) then return end
  -- ResetGuide (flux A) efface aussi les validations de position de la session.
  if Q.Progress.ResetGuide then
    Q.Progress:ResetGuide(guide.id)
    Q:Print(L.UI_OPT_RESET_DONE, guide.title or guide.id)
    return
  end
  local prefix = "g:" .. guide.id .. ":"
  for _, t in ipairs({ Q.char.manual or {}, Q.char.skipped or {} }) do
    local keys = {}
    for k in pairs(t) do
      if type(k) == "string" and k:sub(1, #prefix) == prefix then keys[#keys + 1] = k end
    end
    for _, k in ipairs(keys) do t[k] = nil end
  end
  if Q.Progress.Invalidate then Q.Progress.Invalidate() end
  Q.Progress:Update()
  Q:Print(L.UI_OPT_RESET_DONE, guide.title or guide.id)
end

-- Texte des mesures, ou un message si le module n'est pas là.
local function exportText()
  local tm = Q.Telemetry
  if tm and tm.Export then
    local ok, s = pcall(tm.Export, tm)
    if ok and type(s) == "string" then return s end
    if not ok then Q:ReportError(s) end
  end
  return L.UI_TELEMETRY_UNAVAILABLE
end

function Journal:ShowExport()
  self:ShowTab("options")
  local box = self.exportBox
  box.value = exportText()
  box:SetText(box.value)
  box:Show()
  self.exportHint:Show()
  box:SetFocus()
  box:HighlightText()
end

function Journal:BuildOptions(panel)
  local y = 4
  for _, group in ipairs(OPTION_GROUPS) do
    local h = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -y)
    h:SetText(L[group.title])
    y = y + 18
    for _, def in ipairs(group.checks) do
      local cb = newCheck(panel, def[1], L[def[2]])
      cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -y)
      self.checks[def[1]] = cb
      y = y + 24
    end
    if group.scale then
      local down = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
      down:SetSize(26, 22)
      down:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -y - 2)
      down:SetText("-")
      down:SetScript("OnClick", safe(function() changeScale(-SCALE_STEP) end))
      local up = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
      up:SetSize(26, 22)
      up:SetPoint("LEFT", down, "RIGHT", 4, 0)
      up:SetText("+")
      up:SetScript("OnClick", safe(function() changeScale(SCALE_STEP) end))
      local txt = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      txt:SetPoint("LEFT", up, "RIGHT", 8, 0)
      self.scaleDown, self.scaleUp, self.scaleText = down, up, txt
      y = y + 28
    end
    if group.tools then
      y = y + 4
      local function toolButton(label, width, onClick)
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(width, 22)
        b:SetText(label)
        b:SetScript("OnClick", safe(onClick))
        return b
      end
      self.wizardButton = toolButton(L.UI_OPT_WIZARD, 200, function()
        if Q.UI.Wizard then Q.UI.Wizard:Show() end
      end)
      self.wizardButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -y)
      self.resetButton = toolButton(L.UI_OPT_RESET_CHAPTER, 250, resetChapter)
      self.resetButton:SetPoint("LEFT", self.wizardButton, "RIGHT", 8, 0)
      y = y + 28
      self.exportButton = toolButton(L.UI_OPT_EXPORT, 200, function() Journal:ShowExport() end)
      self.exportButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -y)
      y = y + 30
      local box = CreateFrame("EditBox", "QuestifyVanillaJournalExportBox", panel, "InputBoxTemplate")
      box:SetSize(CLASS_W - 20, 20)
      box:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -y)
      box:SetAutoFocus(false)
      box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
      box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
      -- Texte en lecture seule : toute frappe remet le texte exporté.
      box:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self.value then self:SetText(self.value); self:HighlightText() end
      end)
      box:Hide()
      self.exportBox = box
      local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      hint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -4, -4)
      hint:SetText(L.UI_OPT_EXPORT_HINT)
      hint:Hide()
      self.exportHint = hint
      y = y + 40
    end
    y = y + 8
  end
end

function Journal:RefreshOptions()
  if not self.frame then return end
  for path, cb in pairs(self.checks) do
    cb:SetChecked(Q.Settings:Get(path) == true)
  end
  if self.scaleText then
    self.scaleText:SetFormattedText(L.UI_OPT_SCALE, math.floor(scaleValue() * 100 + 0.5))
  end
end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
Q:On("PROGRESS_UPDATED", function() refreshIfShown("route", false) end)
Q:On("GUIDE_CHANGED", function() refreshIfShown("route", true) end)
Q:On("STEP_CHANGED", function() refreshIfShown("route", true) end)
Q:On("CLASSQUESTS_CHANGED", function() refreshIfShown("class") end)
Q:On("SETTINGS_CHANGED", function() refreshIfShown("options") end)
