local addonName, Q = ...

-- Onglet « Sorts à apprendre » (spec 2.8, 2.9, 7.10, 7.11) : posé dans le volet « spells » de BuildWindow.
-- Rendu de la maquette (onglet Sorts) : bandeau du maître le plus proche + résumé + bouton de route,
-- filtres Tous / À apprendre / Appris / À venir, lignes groupées par niveau (icône, nom, rang, niveau,
-- prix ou « — », état), ligne de quête avec son bouton.
--   * Les données viennent de Q.SpellList (Rows, Summary) ; le volet se redessine à SPELLS_CHANGED.
--   * Le cache de SpellList est invalidé à chaque apparition du volet (distance au maître à jour).
--   * Cadres créés hors combat seulement (à PLAYER_REGEN_ENABLED sinon) ; les boutons qui changent la
--     route ne font rien en combat.
Q.UI = Q.UI or {}
local Pane = { state = { filter = "all" }, ui = nil }
Q.UI.SpellsPane = Pane

local L = Q.L

local LINE_H, ICON = 26, 20
local FILTERS = { "all", "now", "known", "soon" }
local FILTER_KEYS = { all = "SPELLS_FILTER_ALL", now = "SPELLS_FILTER_NOW", known = "SPELLS_FILTER_KNOWN",
  soon = "SPELLS_FILTER_SOON" }
local STATE_COLORS = { known = { 0.4, 0.85, 0.45 }, now = { 1, 0.82, 0.2 }, soon = { 0.6, 0.6, 0.6 },
  quest = { 0.55, 0.75, 1 } }
local WHITE, GREY = { 1, 1, 1 }, { 0.6, 0.6, 0.6 }

local function color(fs, c) fs:SetTextColor(c[1], c[2], c[3]) end

local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function plainCall(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, ...)
  if not ok or Q.Util.IsSecret(v) then return nil end
  return v
end

local function spellIcon(id)
  local v = C_Spell and plainCall(C_Spell.GetSpellTexture, id)
  if type(v) == "number" or type(v) == "string" then return v end
  return nil
end

local function money(copper)
  copper = tonumber(copper) or 0
  if type(GetCoinTextureString) == "function" then
    local ok, v = pcall(GetCoinTextureString, copper)
    if ok and type(v) == "string" then return v end
  end
  return Q.Rewards.FormatMoney(copper)
end

local function playerLevel() return Q.Player.level or 1 end

-- Niveau de la chaîne de quêtes de classe `key` (Q.ClassQuestData).
local function chainLevel(key)
  local byClass = type(Q.ClassQuestData) == "table" and Q.ClassQuestData[Q.Player.classFile]
  for _, chain in ipairs(type(byClass) == "table" and byClass or {}) do
    if chain.key == key then return chain.level or 1 end
  end
  return 1
end

local function matches(filter, state)
  if filter == "all" then return true end
  if filter == "soon" then return state == "soon" or state == "quest" end
  return state == filter
end

---------------------------------------------------------------------------
-- Lignes à afficher
---------------------------------------------------------------------------
-- Lines() -> { { kind = "header", level }, { kind = "row", row } } : lignes filtrées, un en-tête par niveau.
function Pane:Lines()
  local out, last = {}, nil
  for _, r in ipairs(Q.SpellList:Rows()) do
    if matches(self.state.filter, r.state) then
      if r.level ~= last then
        last = r.level
        out[#out + 1] = { kind = "header", level = r.level }
      end
      out[#out + 1] = { kind = "row", row = r }
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
function Pane:Say(text, failed)
  self.state.msg, self.state.msgFailed = text, failed
  local ui = self.ui
  if not ui then return end
  ui.msg:SetText(text or "")
  if failed then color(ui.msg, { 1, 0.4, 0.35 }) else color(ui.msg, { 0.35, 0.72, 0.36 }) end
end

function Pane:Route()
  if inCombat() then return end
  if Q.Trainer:GoNearest() then
    self:Say(L.SPELLS_ROUTE_DONE)
  else
    self:Say(L.SPELLS_TRAINER_NONE, true)
  end
end

function Pane:QuestClick(row)
  if inCombat() or type(row) ~= "table" or not row.chainKey then return end
  local C = Q.ClassQuests
  if row.questState == "inlog" then
    if C:Track(row.chainKey) then self:Say(L.SPELLS_QUEST_TRACKED) else self:Say(L.SPELLS_QUEST_FAILED, true) end
  elseif row.questState == "available" then
    if C:Add(row.chainKey) and C:Track(row.chainKey) then   -- en tête : la flèche mène au donneur
      self:Say(L.SPELLS_QUEST_ADDED)
    else
      self:Say(L.SPELLS_QUEST_FAILED, true)
    end
  end
end

function Pane:SetFilter(filter)
  if not FILTER_KEYS[filter] then return end
  self.state.filter = filter
  self:Refresh()
end

---------------------------------------------------------------------------
-- Création des cadres (hors combat)
---------------------------------------------------------------------------
local function newText(parent, template, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  fs:SetJustifyH(justify or "LEFT")
  return fs
end

local function newButton(parent, text, width, height)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, height or 22)
  b:SetText(text)
  return b
end


function Pane:NewLine(i)
  local ui = self.ui
  local f = CreateFrame("Frame", nil, ui.scrollChild)
  f:SetSize(680, LINE_H)
  f:SetPoint("TOPLEFT", ui.scrollChild, "TOPLEFT", 0, -(i - 1) * LINE_H)
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetSize(ICON, ICON)
  f.icon:SetPoint("LEFT", f, "LEFT", 6, 0)
  f.name = newText(f, "GameFontHighlight")
  f.name:SetPoint("LEFT", f, "LEFT", 34, 0)
  f.name:SetWidth(180)
  f.rank = newText(f, "GameFontDisableSmall")
  f.rank:SetPoint("LEFT", f, "LEFT", 218, 0)
  f.rank:SetWidth(70)
  f.level = newText(f, "GameFontDisableSmall")
  f.level:SetPoint("LEFT", f, "LEFT", 292, 0)
  f.level:SetWidth(50)
  f.cost = newText(f, "GameFontHighlightSmall")
  f.cost:SetPoint("LEFT", f, "LEFT", 344, 0)
  f.cost:SetWidth(110)
  f.state = newText(f, "GameFontHighlightSmall")
  f.state:SetPoint("LEFT", f, "LEFT", 458, 0)
  f.state:SetWidth(120)
  f.action = newButton(f, "", 96, 20)
  f.action:SetPoint("RIGHT", f, "RIGHT", -4, 0)
  f.action:SetScript("OnClick", function() Pane:QuestClick(f.row) end)
  f.action:Hide()
  f.header = newText(f, "GameFontNormal")
  f.header:SetPoint("LEFT", f, "LEFT", 6, 0)
  f.header:SetWidth(600)
  return f
end

function Pane:Build()
  if self.ui or inCombat() then return end
  local root = self.pane
  local ui = { lines = {}, chips = {} }
  self.ui = ui

  ui.trainer = newText(root, "GameFontNormal")
  ui.trainer:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -12)
  ui.trainer:SetWidth(470)
  ui.summary = newText(root, "GameFontDisableSmall")
  ui.summary:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -34)
  ui.summary:SetWidth(470)
  ui.route = newButton(root, L.SPELLS_ROUTE, 230)
  ui.route:SetPoint("TOPRIGHT", root, "TOPRIGHT", -14, -16)
  ui.route:SetScript("OnClick", function() Pane:Route() end)
  ui.msg = newText(root, "GameFontNormalSmall")
  ui.msg:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -56)
  ui.msg:SetPoint("TOPRIGHT", root, "TOPRIGHT", -14, -56)
  color(ui.msg, { 0.35, 0.72, 0.36 })

  local prev
  for _, key in ipairs(FILTERS) do
    local chip = newButton(root, L[FILTER_KEYS[key]], 96, 22)
    if prev then chip:SetPoint("LEFT", prev, "RIGHT", 4, 0) else chip:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -76) end
    chip:SetScript("OnClick", function() Pane:SetFilter(key) end)
    ui.chips[key] = chip
    prev = chip
  end

  ui.empty = newText(root, "GameFontDisable")
  ui.empty:SetPoint("TOPLEFT", root, "TOPLEFT", 20, -118)
  ui.empty:SetText(L.SPELLS_EMPTY)
  ui.empty:Hide()

  ui.scroll = CreateFrame("ScrollFrame", nil, root, "UIPanelScrollFrameTemplate")
  ui.scroll:SetPoint("TOPLEFT", root, "TOPLEFT", 10, -106)
  ui.scroll:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -30, 10)
  ui.scrollChild = CreateFrame("Frame", nil, ui.scroll)
  ui.scrollChild:SetSize(690, LINE_H)
  ui.scroll:SetScrollChild(ui.scrollChild)
end

---------------------------------------------------------------------------
-- Affichage
---------------------------------------------------------------------------
local function paintRow(f, r)
  f.row, f.spellID, f.kind = r, r.spellID, "row"
  f.header:Hide()
  f.icon:Show(); f.name:Show(); f.rank:Show(); f.level:Show(); f.cost:Show(); f.state:Show()
  local tex = spellIcon(r.spellID)
  if tex then f.icon:SetTexture(tex) end
  f.name:SetText(r.name or "")
  f.rank:SetText(r.rankNum and string.format(L.SPELLS_RANK, r.rankNum) or "")
  f.level:SetText(string.format(L.SPELLS_LEVEL, r.level))
  if r.cost and r.cost > 0 and r.state ~= "known" then
    f.cost:SetText(money(r.cost))
  else
    f.cost:SetText(L.SPELLS_NO_COST)
  end
  color(f.name, r.state == "soon" and GREY or WHITE)
  color(f.state, STATE_COLORS[r.state] or WHITE)
  if r.state == "known" then f.state:SetText(L.SPELLS_STATE_KNOWN)
  elseif r.state == "now" then f.state:SetText(L.SPELLS_STATE_NOW)
  elseif r.state == "quest" then f.state:SetText(L.SPELLS_STATE_QUEST)
  else f.state:SetText(string.format(L.SPELLS_STATE_SOON, r.level)) end
  if r.state == "quest" and r.chainKey then
    f.action:Show()
    if r.questState == "inlog" then
      f.action:SetText(L.SPELLS_QUEST_TRACK); f.action:Enable()
    elseif r.questState == "available" then
      f.action:SetText(L.SPELLS_QUEST_GET); f.action:Enable()
    else
      f.action:SetText(string.format(L.SPELLS_QUEST_UPCOMING, chainLevel(r.chainKey))); f.action:Disable()
    end
  else
    f.action:Hide()
  end
end

local function paintHeader(f, level)
  f.row, f.spellID, f.kind = nil, nil, "header"
  f.icon:Hide(); f.name:Hide(); f.rank:Hide(); f.level:Hide(); f.cost:Hide(); f.state:Hide()
  f.action:Hide()
  local diff = level - playerLevel()
  if diff > 0 then
    f.header:SetText(string.format(L.SPELLS_LEVEL_HEADER_IN, level, diff))
  else
    f.header:SetText(string.format(L.SPELLS_LEVEL_HEADER, level))
  end
  f.header:Show()
end

function Pane:Refresh()
  local ui = self.ui
  if not ui then return end
  local lines = self:Lines()
  if #lines > #ui.lines and inCombat() then
    self.wantRefresh = true          -- pas de nouveau cadre en combat
    return
  end
  self.wantRefresh = nil
  for i = #ui.lines + 1, #lines do ui.lines[i] = self:NewLine(i) end
  for i, f in ipairs(ui.lines) do
    local l = lines[i]
    if not l then
      f:Hide()
      f.row, f.spellID, f.kind = nil, nil, nil
    else
      if l.kind == "header" then paintHeader(f, l.level) else paintRow(f, l.row) end
      f:Show()
    end
  end
  ui.scrollChild:SetHeight(math.max(LINE_H, #lines * LINE_H))
  ui.empty:SetShown(#lines == 0)

  local sum = Q.SpellList:Summary()
  local tr = sum.trainer
  if tr then
    local parts = { tr.name }
    if tr.zone then parts[#parts + 1] = tr.zone end
    if tr.distance then parts[#parts + 1] = Q.Util.FormatDistance(tr.distance) end
    ui.trainer:SetText(string.format(L.SPELLS_TRAINER, table.concat(parts, " · ")))
    ui.route:Enable()
  else
    ui.trainer:SetText(L.SPELLS_TRAINER_NONE)
    ui.route:SetEnabled(#Q.Trainer:TrainerIds() > 0)
  end
  if sum.now > 0 then
    ui.summary:SetText(string.format(L.SPELLS_SUMMARY, sum.now, money(sum.cost), money(sum.money)))
  else
    ui.summary:SetText(string.format(L.SPELLS_SUMMARY_NONE, money(sum.money)))
  end
  self:Say(self.state.msg, self.state.msgFailed)
end

function Pane:OnShow()
  Q.SpellList:Invalidate()           -- distance au maître à jour
  if not self.ui then
    if inCombat() then self.wantRefresh = true; return end
    self:Build()
    if not self.ui then return end
  end
  self.state.msg = nil
  self:Refresh()
end

-- Accroche au volet « spells » de BuildWindow (nil avant sa création hors combat).
function Pane:Attach()
  if self.pane then return true end
  local W = Q.UI.BuildWindow
  local pane = W and W:Pane("spells")
  if not pane then return false end
  self.pane = pane
  pane:SetScript("OnShow", function() Pane:OnShow() end)
  if pane:IsShown() then self:OnShow() end
  return true
end

Q:On("SPELLS_CHANGED", function()
  if Pane.ui and Pane.pane and Pane.pane:IsShown() then Pane:Refresh() end
end)

Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if not Pane.pane then Pane:Attach() end
  if Pane.wantRefresh and Pane.pane and Pane.pane:IsShown() then Pane:OnShow() end
end)

Pane:Attach()
