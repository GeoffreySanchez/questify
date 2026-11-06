local addonName, Q = ...

-- Journal principal (spec § 5.8), ouvert par /questify, /qf ou le compartiment d'addons.
-- Deux onglets :
--   « Route » : chapitres de la faction à gauche, étapes du chapitre à droite (icône d'état,
--               clic = étape courante) ;
--   « Quêtes de classe » : une ligne par chaîne avec son état et Ajouter / Ignorer / Réactiver,
--                          puis la section « Donjons » (même principe, Engine/Dungeons.lua).
-- Le bouton « Options… » en bas à droite ouvre la fenêtre d'options (UI/Options.lua).
Q.UI = Q.UI or {}
local Journal = { tab = "route", panels = {}, tabs = {}, chapterRows = {}, stepRows = {}, classRows = {} }
Q.UI.Journal = Journal

local L = Q.L

local FRAME_NAME = "QuestifyJournal"
local WIDTH, HEIGHT = 520, 560
local TAB_NAMES = { "route", "class" }
local TAB_INDEX = { route = 1, class = 2 }

local CHAPTER_W, CHAPTER_ROW_H = 150, 20
local STEP_W, STEP_ROW_H = 290, 18
local CLASS_W, CLASS_ROW_H = 456, 46
local CLASS_ITEMS = 3
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
local CQ_LATE_COLOR = "|cffff5050"   -- couleur d'alerte : chaîne en retard
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

  local labels = { L.UI_TAB_ROUTE, L.UI_TAB_CLASS }
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
  -- Options : fenêtre à part (UI/Options.lua)
  local opt = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  opt:SetSize(120, 22)
  opt:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)
  opt:SetText(L.OPT_JOURNAL_OPTIONS)
  opt:SetScript("OnClick", safe(function()
    playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    if Q.UI.Options then Q.UI.Options:Open() end
  end))
  self.optionsButton = opt
  -- Choix de suite (UI/RouteChoicePopup.lua) : rouvre le choix du chapitre courant ou du dernier choisi
  local route = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  route:SetSize(130, 22)
  route:SetPoint("RIGHT", opt, "LEFT", -6, 0)
  route:SetText(L.UI_ROUTECHOICE_JOURNAL)
  route:SetScript("OnClick", safe(function()
    playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    local P = Q.UI.RouteChoicePopup
    if P then P:OpenForPlayer() end
  end))
  self.routeButton = route
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

-- ShowTab("route" | "class") : ouvre le journal sur cet onglet. "options" ouvre la fenêtre
-- d'options (l'ancien onglet Options).
function Journal:ShowTab(name)
  if name == "options" then
    if Q.UI.Options then Q.UI.Options:Open() end
    return
  end
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

  local chScroll, chChild = newScroll(panel, "QuestifyJournalChapterScroll", CHAPTER_W, LIST_H)
  chScroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -24)
  self.chapterScroll, self.chapterChild = chScroll, chChild

  local stScroll, stChild = newScroll(panel, "QuestifyJournalStepScroll", STEP_W, LIST_H)
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
      -- true : un chapitre déjà fini reste affiché, pour y rouvrir une étape passée par erreur
      Q.Progress:SetGuide(self.guide.id, true)
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
  local scroll, child = newScroll(panel, "QuestifyJournalClassScroll", CLASS_W, LIST_H + 20)
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -4)
  self.classScroll, self.classChild = scroll, child
  local empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  empty:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -10)
  empty:SetWidth(CLASS_W - 16)
  empty:SetJustifyH("LEFT")
  empty:Hide()
  self.classEmpty = empty
end

local CQ_CONFIRM = { Add = "UI_CQ_ADDED_MSG", Track = "UI_CQ_TRACKED_MSG" }

local function classAction(method, key, chain)
  local cq = Q.ClassQuests
  if not (cq and cq[method]) then return end
  playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
  local done = cq[method](cq, key)
  -- confirmation dans la discussion (un échec explicite, retour faux, n'en donne pas)
  if done ~= false and chain and CQ_CONFIRM[method] then
    Q:Print(L[CQ_CONFIRM[method]], Q.UI.ClassQuestPopup.ChainTitle(chain))
  end
  Journal:RefreshClass()
end

local function isLate(chain, state)
  local cq = Q.ClassQuests
  return cq and cq.IsLate and cq.IsLate(chain, state) or false
end

-- Ordre d'affichage : en retard, disponibles, ajoutées, en cours, à venir, faites, ignorées.
local CQ_RANK = { available = 2, added = 3, inprogress = 4, upcoming = 5, done = 6, ignored = 7 }

-- Tri stable : à rang égal l'ordre du moteur est conservé.
local function sortedClassRows(list)
  local rows = {}
  for _, item in ipairs(list or {}) do
    if type(item) == "table" and type(item.chain) == "table" then
      rows[#rows + 1] = { item = item, rank = isLate(item.chain, item.state) and 1 or CQ_RANK[item.state] or 8,
        index = #rows + 1 }
    end
  end
  table.sort(rows, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.index < b.index
  end)
  local out = {}
  for i, r in ipairs(rows) do out[i] = r.item end
  return out
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
  title:SetWidth(150)
  title:SetJustifyH("LEFT")
  title:SetWordWrap(false)
  local info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  info:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  info:SetWidth(150)
  info:SetJustifyH("LEFT")
  info:SetWordWrap(false)
  row.title, row.info, row.items = title, info, {}
  for j = 1, CLASS_ITEMS do
    local b = Q.UI.ClassQuestPopup.CreateItemButton(row, 24)
    b:SetPoint("LEFT", row, "LEFT", 160 + (j - 1) * 26, 0)
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
  row.addButton = button(L.UI_BTN_ADD_ROUTE, 118)
  row.trackButton = button(L.UI_BTN_TRACK, 118)
  row.ignoreButton:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  row.unignoreButton:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  -- Ignorer et Réactiver occupent la même place (jamais affichés ensemble) : Ajouter à leur gauche.
  row.addButton:SetPoint("RIGHT", row, "RIGHT", -90, 0)
  row.trackButton:SetPoint("RIGHT", row, "RIGHT", -90, 0)   -- Ajouter et Suivre : jamais ensemble
  row.addButton:SetScript("OnClick", safe(function()
    if row.chain then classAction("Add", row.chain.key, row.chain) end
  end))
  row.trackButton:SetScript("OnClick", safe(function()
    if row.chain then classAction("Track", row.chain.key, row.chain) end
  end))
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
  if isLate(chain, state) then
    row.info:SetText(CQ_LATE_COLOR .. string.format(L.UI_CQ_LATE, tonumber(chain.level) or 1) .. "|r")
  else
    row.info:SetText(string.format(L.UI_CLASS_ROW_INFO, tonumber(chain.level) or 1,
      (CQ_STATE_COLOR[state] or "|cffffffff") .. stateText .. "|r"))
  end
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
  if state == "added" then row.trackButton:Show() else row.trackButton:Hide() end
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
  for _, item in ipairs(sortedClassRows(list)) do
    n = n + 1
    setClassRow(classRow(n), item)
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
  -- Section « Donjons » sous les chaînes de classe (protégée : une erreur n'efface pas les chaînes)
  local top = n * CLASS_ROW_H + (self.classEmpty:IsShown() and 30 or 0)
  local ok, err = pcall(self.RefreshDungeons, self, top, qdbOk)
  if not ok then Q:ReportError(err) end
end

---------------------------------------------------------------------------
-- Section Donjons (onglet Quêtes de classe) : une ligne par donjon proposé à la faction, avec son
-- état et Ajouter / Ignorer / Réactiver (Engine/Dungeons.lua).
---------------------------------------------------------------------------
local DG_ROW_H = 40
local DG_STATE_TEXT = {
  available = "DUNGEON_STATE_AVAILABLE", upcoming = "DUNGEON_STATE_UPCOMING", added = "DUNGEON_STATE_ADDED",
  ignored = "DUNGEON_STATE_IGNORED", done = "DUNGEON_STATE_DONE", past = "DUNGEON_STATE_PAST",
}
local DG_STATE_COLOR = {
  available = "|cff40ff40", upcoming = "|cffaaaaaa", added = "|cffffd100",
  ignored = "|cff808080", done = "|cff808080", past = "|cff808080",
}

local function dungeonAction(method, key)
  local D = Q.Dungeons
  if not (D and D[method]) then return end
  playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
  D[method](D, key)
  Journal:RefreshClass()
end

local function dungeonTooltip(row)
  local d = row.dungeon
  if not d then return end
  local P = Q.UI.DungeonPopup
  local lines = { P.DungeonName(d), string.format(L.DUNGEON_LEVELS, d.minLevel or 1, d.maxLevel or 60) }
  if type(d.entrance) == "table" and type(d.entrance[1]) == "number" then
    lines[#lines + 1] = string.format(L.DUNGEON_ENTRANCE, Q.Maps:MapName(d.entrance[1]))
  end
  local rows = Q.Dungeons and Q.Dungeons.Details and Q.Dungeons:Details(d) or {}
  for _, r in ipairs(rows) do lines[#lines + 1] = "- " .. P.QuestLine(r) end
  showTooltip(row, lines)
end

local function dungeonRow(i)
  Journal.dungeonRows = Journal.dungeonRows or {}
  local row = Journal.dungeonRows[i]
  if row then return row end
  local parent = Journal.classChild
  row = CreateFrame("Button", nil, parent)
  row:SetSize(CLASS_W, DG_ROW_H)
  if i % 2 == 0 then
    local stripe = row:CreateTexture(nil, "BACKGROUND")
    stripe:SetAllPoints(row)
    stripe:SetColorTexture(1, 1, 1, 0.04)
  end
  local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -5)
  title:SetWidth(260)
  title:SetJustifyH("LEFT")
  title:SetWordWrap(false)
  local info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  info:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  info:SetWidth(260)
  info:SetJustifyH("LEFT")
  info:SetWordWrap(false)
  row.title, row.info = title, info
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
  row.addButton:SetPoint("RIGHT", row, "RIGHT", -90, 0)
  row.addButton:SetScript("OnClick", safe(function() if row.dungeon then dungeonAction("Add", row.dungeon.key) end end))
  row.ignoreButton:SetScript("OnClick", safe(function() if row.dungeon then dungeonAction("Ignore", row.dungeon.key) end end))
  row.unignoreButton:SetScript("OnClick", safe(function() if row.dungeon then dungeonAction("Unignore", row.dungeon.key) end end))
  row:SetScript("OnEnter", safe(dungeonTooltip))
  row:SetScript("OnLeave", hideTooltip)
  Journal.dungeonRows[i] = row
  return row
end

-- top = hauteur déjà occupée par les chaînes de classe dans la liste défilante.
function Journal:RefreshDungeons(top, qdbOk)
  local child = self.classChild
  if not self.dungeonHeader then
    local h = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h:SetJustifyH("LEFT")
    h:SetText(L.DUNGEON_SECTION)
    self.dungeonHeader = h
    local empty = child:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetJustifyH("LEFT")
    empty:SetWidth(CLASS_W - 16)
    empty:SetText(L.DUNGEON_EMPTY)
    self.dungeonEmpty = empty
  end
  local rows = self.dungeonRows or {}
  local D = Q.Dungeons
  local list
  if qdbOk and D and D.List then
    local ok, res = pcall(D.List, D)
    if ok and type(res) == "table" then list = res elseif not ok then Q:ReportError(res) end
  end
  if not list then
    -- QuestieDB absent ou module en erreur : la section disparaît (le message des chaînes suffit)
    self.dungeonHeader:Hide()
    self.dungeonEmpty:Hide()
    for _, r in ipairs(rows) do r.dungeon = nil; r:Hide() end
    return
  end
  local y = top + 10
  self.dungeonHeader:ClearAllPoints()
  self.dungeonHeader:SetPoint("TOPLEFT", child, "TOPLEFT", 6, -y)
  self.dungeonHeader:Show()
  y = y + 20
  local n = 0
  for _, item in ipairs(list) do
    if type(item) == "table" and type(item.dungeon) == "table" then
      n = n + 1
      local row = dungeonRow(n)
      local d, state = item.dungeon, item.state
      row.dungeon, row.dgState = d, state
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(y + (n - 1) * DG_ROW_H))
      row.title:SetText(Q.UI.DungeonPopup.DungeonName(d))
      local key = DG_STATE_TEXT[state]
      row.info:SetText(string.format(L.DUNGEON_ROW_INFO, tonumber(d.minLevel) or 1, tonumber(d.maxLevel) or 60,
        (DG_STATE_COLOR[state] or "|cffffffff") .. (key and L[key] or tostring(state)) .. "|r"))
      local canAdd = state == "available" or state == "upcoming" or state == "past" or state == "ignored"
      local canIgnore = state == "available" or state == "upcoming" or state == "past" or state == "added"
      if canAdd then row.addButton:Show() else row.addButton:Hide() end
      if canIgnore then row.ignoreButton:Show() else row.ignoreButton:Hide() end
      if state == "ignored" then row.unignoreButton:Show() else row.unignoreButton:Hide() end
      row:Show()
    end
  end
  self.dungeonRows = self.dungeonRows or {}
  for i = n + 1, #self.dungeonRows do
    self.dungeonRows[i].dungeon = nil
    self.dungeonRows[i]:Hide()
  end
  if n == 0 then
    self.dungeonEmpty:ClearAllPoints()
    self.dungeonEmpty:SetPoint("TOPLEFT", child, "TOPLEFT", 8, -y)
    self.dungeonEmpty:Show()
    y = y + 20
  else
    self.dungeonEmpty:Hide()
    y = y + n * DG_ROW_H
  end
  child:SetHeight(math.max(1, y))
end

---------------------------------------------------------------------------
-- Export des mesures (ancien onglet Options) : dans la fenêtre d'options, section Outils.
---------------------------------------------------------------------------
function Journal:ShowExport()
  if Q.UI.Options then return Q.UI.Options:ShowTelemetryExport() end
end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
Q:On("PROGRESS_UPDATED", function() refreshIfShown("route", false) end)
Q:On("GUIDE_CHANGED", function() refreshIfShown("route", true) end)
Q:On("STEP_CHANGED", function() refreshIfShown("route", true) end)
Q:On("CLASSQUESTS_CHANGED", function() refreshIfShown("class") end)
Q:On("DUNGEONS_CHANGED", function() refreshIfShown("class") end)
