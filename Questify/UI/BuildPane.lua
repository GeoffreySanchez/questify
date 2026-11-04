local addonName, Q = ...

-- Onglet « Build » (spec 2.5, 2.6, 7.1, 7.2, 7.6, 7.12, 7.13) : l'éditeur de build, posé dans le volet
-- « build » de BuildWindow. Rendu de la maquette : liste des builds, sélecteur de groupe de spécialisation,
-- nom, boutons, bandeau « obsolète », trois arbres (vraies icônes, infobulles du jeu), liste « Niv. N »
-- avec ✕, curseur de niveau, roue dentée (rappel de talents, build tiré de l'arbre).
--   * Jamais de modification d'un build fourni : toute modification passe par une copie (Q.BuildEditor),
--     l'enregistrement par Builds:Save (copie personnelle d'un build fourni).
--   * Arbre dessiné : la lecture réelle (TalentTree:Read) quand elle est possible, sinon la forme fournie
--     (TalentTree:FromShape sur Q.TalentShapeData[classe]).
--   * Cadres créés hors combat seulement, à la première apparition du volet (à PLAYER_REGEN_ENABLED si
--     le volet est apparu en combat).
Q.UI = Q.UI or {}
local Pane = { state = { level = 60 }, ui = nil }
Q.UI.BuildPane = Pane

local L = Q.L

local FIRST_LEVEL, MAX_POINTS, MAX_LEVEL = 10, 51, 60
local CELL, ICON, GROUP_W = 40, 34, 166
local ROW_H = 16
local MENU_ROW_H = 20
local GROUP_COLORS = { { 0.35, 0.6, 1 }, { 1, 0.45, 0.35 }, { 0.4, 0.85, 0.45 } }
local GREY = { 0.5, 0.5, 0.5 }
local GOLD = { 1, 0.82, 0.2 }
local WHITE = { 1, 1, 1 }

local SOURCES = { icyveins = "Icy Veins", wowhead = "Wowhead", questify = "Questify" }

local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function Builds() return Q.Builds end

local function trim(s)
  s = tostring(s or "")
  s = s:gsub("^%s+", "")
  s = s:gsub("%s+$", "")
  return s
end

-- Nom de source présenté : « Icy Veins », « Wowhead », « Questify » ; autre : première lettre en capitale.
local function sourceName(src)
  if type(src) ~= "string" or src == "" then return nil end
  local key = src:lower():gsub("[%s_%-]", "")
  return SOURCES[key] or (src:sub(1, 1):upper() .. src:sub(2))
end

local function plainCall(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, ...)
  if not ok or Q.Util.IsSecret(v) then return nil end
  return v
end

local function spellName(id)
  local v = C_Spell and plainCall(C_Spell.GetSpellName, id)
  if type(v) == "string" and v ~= "" then return v end
  return nil
end

local function spellIcon(id)
  local v = C_Spell and plainCall(C_Spell.GetSpellTexture, id)
  if type(v) == "number" or type(v) == "string" then return v end
  return nil
end

local function playerLevel()
  local v = plainCall(UnitLevel, "player")
  return type(v) == "number" and v or 0
end

local function playerClass() return Q.Player and Q.Player.classFile end

-- Raison de refus (BuildEditor, Builds:SetActive) -> texte.
local REASON_KEYS = {
  missing = "TALENT_REASON_MISSING", maxrank = "TALENT_REASON_MAXRANK", tier = "TALENT_REASON_TIER",
  requires = "TALENT_REASON_REQUIRES", toolong = "TALENT_REASON_TOOLONG",
}
local function reasonText(reason)
  return L[REASON_KEYS[reason] or "TALENT_REASON_UNKNOWN"]
end

-- Raison d'obsolescence -> texte (toute raison de Builds:Validate, « index » comprise).
local function obsoleteText(reason)
  local text = L["BUILD_OBSOLETE_" .. tostring(reason)]
  if type(text) ~= "string" or text:find("BUILD_OBSOLETE_", 1, true) then return L.TALENT_REASON_UNKNOWN end
  return text
end

---------------------------------------------------------------------------
-- Données : arbre, entrées de la liste
---------------------------------------------------------------------------
function Pane:LoadTree()
  local s = self.state
  local tree = Q.TalentTree:Read()
  if not tree then
    local class = playerClass()
    local shape = class and type(Q.TalentShapeData) == "table" and Q.TalentShapeData[class]
    if type(shape) == "table" then tree = Q.TalentTree:FromShape(shape) end
  end
  s.tree = tree
end

function Pane:Group()
  local s = self.state
  if not s.group then s.group = Builds():ActiveGroup() end
  return s.group
end

-- Builds de la classe, classés : spécialisation du groupe affiché d'abord, fournis avant perso.
-- -> { { key, build, label, name, source, obsolete, reason, official, personal, active, index } }
function Pane:Entries()
  local s = self.state
  local class = playerClass()
  local group = self:Group()
  local spec = Builds():SpecID(group)
  local active = Builds():Active(group)
  local out = {}
  for i, b in ipairs(Builds():List(class)) do
    local obsolete, reason = false, nil
    if s.tree then
      local ok, why = Builds():Validate(b, s.tree)
      obsolete, reason = not ok, why
    end
    local official = b.official == true
    local name = Builds():Name(b)
    local label
    if obsolete then
      label = string.format(L.BUILD_OBSOLETE_NAME, name) .. (official and (" " .. L.BUILD_OFFICIAL_TAG) or "")
    else
      label = name .. (official and (" " .. L.BUILD_OFFICIAL_TAG) or "")
    end
    local isActive = active ~= nil and active.key == b.key
    if isActive then label = "★ " .. label end
    out[#out + 1] = { key = b.key, build = b, name = name, label = label, obsolete = obsolete, reason = reason,
      official = official, personal = not official, active = isActive,
      source = official and sourceName(b.source) or nil, seq = i,
      rank = ((spec ~= nil and b.specID == spec) and 0 or 2) + (official and 0 or 1) }
  end
  table.sort(out, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.seq < b.seq
  end)
  for i, e in ipairs(out) do e.index = i end
  s.entries = out
  return out
end

local function sameOrder(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do if a[i] ~= b[i] then return false end end
  return true
end

function Pane:IsDirty()
  local s = self.state
  if not s.editor then return false end
  return not sameOrder(s.editor:Order(), (s.build and s.build.order) or {})
end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
function Pane:Say(text, ok)
  local s = self.state
  s.msg, s.msgOk = text, ok
  local ui = self.ui
  if not ui then return end
  ui.msg:SetText(text or "")
  if ok then ui.msg:SetTextColor(0.35, 0.72, 0.36) else ui.msg:SetTextColor(1, 0.4, 0.35) end
end

---------------------------------------------------------------------------
-- Sélection et actions
---------------------------------------------------------------------------
function Pane:DefaultKey()
  local active = Builds():Active(self:Group())
  if active then return active.key end
  local e = self:Entries()[1]
  return e and e.key or nil
end

-- Choisit le build édité : copie de travail neuve (curseur au niveau 60), nom du build dans le champ.
function Pane:Select(key)
  local s = self.state
  s.key = key
  s.build = key and Builds():Get(key) or nil
  s.level = MAX_LEVEL
  s.editor = nil
  if s.tree then s.editor = Q.BuildEditor.new(s.build or { order = {} }, s.tree) end
  s.msg = nil
  local ui = self.ui
  if ui then
    ui.nameBox:SetText(s.build and Builds():Name(s.build) or L.BUILD_NEW_NAME)
    s.updating = true
    ui.slider:SetValue(MAX_LEVEL)
    s.updating = nil
    ui.menu:Hide()
  end
  self:Refresh()
end

function Pane:SetGroup(group)
  self.state.group = group
  self:Refresh()
end

-- Enregistre la copie de travail sous le nom du champ -> clé | nil. Un build fourni devient une copie perso.
function Pane:Commit()
  local s = self.state
  if not s.editor then return nil end
  local base = s.build
  local name = trim(self.ui.nameBox:GetText())
  if name == "" or (base and base.official and name == Builds():Name(base)) then name = L.BUILD_NEW_NAME end
  local build = { key = base and base.key, class = playerClass(), specID = base and base.specID or Builds():SpecID(self:Group()),
    name = name, source = (base and not base.official) and base.source or nil,
    date = type(time) == "function" and time() or 0, official = base and base.official or false,
    order = s.editor:Order() }
  return Builds():Save(build)
end

function Pane:Save()
  local s = self.state
  if not s.editor or s.obsolete then return end
  local key = self:Commit()
  if not key then return end
  self:Select(key)
  self:Say(string.format(L.BUILD_SAVED, Builds():Name(s.build)), true)
end

function Pane:Duplicate()
  local s = self.state
  if not (s.editor and s.tree) then return end
  local order, dropped = {}, false
  for _, id in ipairs(s.editor:Order()) do
    if s.tree.nodes[id] then order[#order + 1] = id else dropped = true end
  end
  -- la copie doit être valide (donc modifiable) : plus long préfixe valide de l'ordre
  local cut = false
  local ok, _, index = Builds():Validate({ order = order }, s.tree)
  if not ok then
    for i = #order, index, -1 do order[i] = nil end
    cut = true
  end
  local base = s.build
  local name = base and Builds():Name(base) or trim(self.ui.nameBox:GetText())
  local key = Builds():Save({ class = playerClass(), specID = base and base.specID or Builds():SpecID(self:Group()),
    name = string.format(L.BUILD_COPY_NAME, name), source = "copy", official = false,
    date = type(time) == "function" and time() or 0, order = order })
  if not key then return end
  self:Select(key)
  if cut then
    self:Say(string.format(L.BUILD_DUPLICATED_CUT, FIRST_LEVEL + #order), true)
  else
    self:Say(dropped and L.BUILD_DUPLICATED_DROPPED or L.BUILD_DUPLICATED, true)
  end
end

function Pane:Use()
  local s = self.state
  if not s.editor or s.obsolete then return end
  local key = s.key
  local typed = trim(self.ui.nameBox:GetText())
  local renamed = s.build and not s.build.official and typed ~= "" and typed ~= Builds():Name(s.build)
  if self:IsDirty() or not s.build or renamed then
    key = self:Commit()
    if not key then return end
  end
  local ok, reason = Builds():SetActive(self:Group(), key)
  if key ~= s.key then self:Select(key) end
  if ok then
    self:Say(string.format(L.BUILD_USED, Builds():Name(Builds():Get(key))), true)
  else
    self:Say(string.format(L.BUILD_USE_FAILED, reasonText(reason)))
  end
end

function Pane:Import()
  if type(self.onImport) == "function" then self.onImport(self) end
end

function Pane:Export()
  if type(self.onExport) == "function" then self.onExport(self) end
end

local function treeBuildName(class)
  local stamp = type(date) == "function" and date("%Y-%m-%d %H:%M") or "?"
  local taken = {}
  for _, b in ipairs(Builds():List(class)) do taken[Builds():Name(b)] = true end
  local name, n = string.format(L.TALENT_TREE_BUILD_NAME, stamp), 1
  while taken[name] do
    n = n + 1
    name = string.format(L.TALENT_TREE_BUILD_NAME, stamp .. " #" .. n)
  end
  return name
end

-- « Créer un build à partir de mon arbre » : même démarche que TalentFrameHook:CreateFromTree.
function Pane:CreateFromTree()
  local tree = Q.TalentTree:Read()
  if not tree then
    self:Say(L.BUILD_NO_LIVE_TREE)
    return
  end
  local class = playerClass()
  local group = self:Group()
  local build = Builds():FromTree(tree, class, Builds():SpecID(group))
  build.name = treeBuildName(class)
  local key = Builds():Save(build)
  if not key then return end
  local ok, reason = Builds():SetActive(group, key)
  if not ok then
    Builds():Delete(key)
    Q:Print(L.TALENT_TREE_BUILD_FAILED, reasonText(reason))
    self:Say(string.format(L.BUILD_USE_FAILED, reasonText(reason)))
    return
  end
  if self.ui then self.ui.gearMenu:Hide() end
  self:Select(key)
  self:Say(string.format(L.BUILD_USED, Builds():Name(Builds():Get(key))), true)
end

-- Clic sur un talent de l'arbre : gauche = Add, droit = RemoveLast.
function Pane:OnNodeClick(spellID, button)
  local s = self.state
  if not s.editor then return end
  if s.obsolete then self:Say(L.BUILD_OBSOLETE_EDIT); return end
  if s.level < MAX_LEVEL then self:Say(L.BUILD_NEED_LEVEL_60); return end
  local ok, reason
  if button == "RightButton" then
    ok, reason = s.editor:RemoveLast(spellID)
    if not ok and reason == "missing" then return end
  else
    ok, reason = s.editor:Add(spellID)
  end
  if ok then
    self:Say(nil)
  else
    self:Say(string.format(L.BUILD_REFUSED, reasonText(reason)))
  end
  self:Refresh()
end

-- ✕ d'une ligne : retire ce point, les suivants remontent.
function Pane:OnRowRemove(index)
  local s = self.state
  if not s.editor then return end
  if s.obsolete then self:Say(L.BUILD_OBSOLETE_EDIT); return end
  local ok, reason = s.editor:RemoveAt(index)
  if ok then
    self:Say(nil)
  else
    self:Say(string.format(L.BUILD_REFUSED, reasonText(reason)))
  end
  self:Refresh()
end

function Pane:OnLevel(value)
  local s = self.state
  if s.updating then return end
  s.level = math.max(FIRST_LEVEL, math.min(MAX_LEVEL, math.floor((tonumber(value) or MAX_LEVEL) + 0.5)))
  self:Refresh()
end

---------------------------------------------------------------------------
-- Rendu
---------------------------------------------------------------------------
local function setColor(fs, c) fs:SetTextColor(c[1], c[2], c[3]) end

function Pane:RefreshMenu(entries)
  local ui = self.ui
  local s = self.state
  for i, e in ipairs(entries) do
    local row = ui.menuRows[i]
    if not row and not inCombat() then row = self:NewMenuRow(i) end
    if row then
      row.entry = e
      row.label:SetText(e.label)
      setColor(row.label, e.obsolete and GREY or e.active and GOLD or WHITE)
      row.sub:SetText(e.source and string.format(L.BUILD_SOURCE, e.source) or "")
      row:Show()
    end
  end
  for i = #entries + 1, #ui.menuRows do ui.menuRows[i]:Hide() end
  ui.menu:SetHeight(math.max(1, #entries) * MENU_ROW_H + 8)
  local sel
  for _, e in ipairs(entries) do if e.key == s.key then sel = e end end
  ui.listText:SetText(sel and sel.label or L.UI_TALENT_NO_BUILD)
  setColor(ui.listText, sel and sel.obsolete and GREY or WHITE)
end

function Pane:RefreshTrees()
  local ui, s = self.ui, self.state
  local tree = s.tree
  for _, f in pairs(ui.groupFrames) do f:Hide() end
  for _, n in pairs(ui.nodes) do n:Hide() end
  if not (tree and s.editor) then return end
  local ranks, spent = s.editor:RanksAt(s.level)
  local rules = Q.TalentTree:Rules(tree, ranks)
  for g, group in ipairs(tree.groups) do
    local frame = ui.groupFrames[g]
    if not frame and not inCombat() then frame = self:NewGroup(g) end
    if frame then
      frame:Show()
      local name = tostring(group.name or "")
      if name == "" or name:match("^%d+$") then name = string.format(L.BUILD_TREE_NAME, g) end
      frame.title:SetText(name)
      frame.points:SetText(tostring(spent[g] or 0))
    end
  end
  local editable = not s.obsolete and s.level >= MAX_LEVEL
  for spellID, node in pairs(tree.nodes) do
    local btn = ui.nodes[spellID]
    if not btn and ui.groupFrames[node.group] and not inCombat() then btn = self:NewNode(spellID, node) end
    if btn then
      local r = ranks[spellID] or 0
      local open = rules(node)
      btn.rankNow, btn.maxNow, btn.editable = r, node.maxRanks, editable
      btn.rank:SetText(r .. "/" .. node.maxRanks)
      if r >= node.maxRanks then
        btn.border:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
        btn.icon:SetVertexColor(1, 1, 1)
      elseif open then
        btn.border:SetVertexColor(0.45, 0.8, 0.45, 1)
        btn.icon:SetVertexColor(r > 0 and 1 or 0.85, r > 0 and 1 or 0.85, r > 0 and 1 or 0.85)
      else
        btn.border:SetVertexColor(0.3, 0.3, 0.3, 1)
        btn.icon:SetVertexColor(0.4, 0.4, 0.4)
      end
      btn.icon:SetDesaturated(not open and r == 0)
      btn:Show()
    end
  end
  local list = {}
  for g = 1, #tree.groups do list[g] = tostring(spent[g] or 0) end
  local valid = 0
  for _, id in ipairs(s.editor:Order()) do if tree.nodes[id] then valid = valid + 1 end end
  ui.count:SetText(string.format(L.BUILD_COUNT, valid, table.concat(list, " / "), s.level))
  ui.levelText:SetText(string.format(L.BUILD_VIEW_LEVEL, s.level))
end

local function paintRow(row, text, count, color)
  row.name:SetText(text)
  setColor(row.name, color)
  row.count:SetText(count)
end

function Pane:RefreshRows()
  local ui, s = self.ui, self.state
  local order = s.editor and s.editor:Order() or {}
  local tree = s.tree
  local level = playerLevel()
  local nextIndex
  for i = 1, MAX_POINTS do
    if FIRST_LEVEL + i - 1 > level then nextIndex = i; break end
  end
  local seen = {}
  for i = 1, MAX_POINTS do
    local row = ui.rows[i]
    if row then
      local id = order[i]
      local lv = FIRST_LEVEL + i - 1
      row.level:SetText(string.format(L.BUILD_LEVEL_ROW, lv))
      row.done:SetShown(id ~= nil and lv <= level)
      row.next:SetShown(i == nextIndex)
      row.swatch:Hide()
      local removable = false
      if not id then
        paintRow(row, L.BUILD_ROW_FREE, "", GREY)
      elseif not (tree and tree.nodes[id]) then
        paintRow(row, string.format(L.BUILD_ROW_GONE, id), "—", { 1, 0.4, 0.35 })
      else
        local node = tree.nodes[id]
        seen[id] = (seen[id] or 0) + 1
        paintRow(row, spellName(id) or ("#" .. id), seen[id] .. "/" .. node.maxRanks, WHITE)
        local c = GROUP_COLORS[node.group] or WHITE
        row.swatch:SetColorTexture(c[1], c[2], c[3], 1)
        row.swatch:Show()
        removable = not s.obsolete
      end
      row.remove:SetShown(removable)
    end
  end
end

function Pane:Refresh()
  local ui, s = self.ui, self.state
  if not ui then return end
  local entries = self:Entries()
  local sel
  for _, e in ipairs(entries) do if e.key == s.key then sel = e end end
  s.obsolete, s.reason = sel ~= nil and sel.obsolete, sel and sel.reason
  s.noTree = s.tree == nil

  self:RefreshMenu(entries)

  -- groupes de spécialisation : sélecteur seulement quand le personnage en a deux
  local two = #Builds():Groups() >= 2
  ui.groupMain:SetShown(two)
  ui.groupAlt:SetShown(two)
  local group = self:Group()
  if group == 1 then ui.groupMain:LockHighlight() else ui.groupMain:UnlockHighlight() end
  if group == 2 then ui.groupAlt:LockHighlight() else ui.groupAlt:UnlockHighlight() end

  ui.source:SetText(sel and sel.source and string.format(L.BUILD_SOURCE, sel.source) or "")
  local active = Builds():Active(group)
  ui.badge:SetText(active and s.key and active.key == s.key and L.BUILD_ACTIVE_BADGE or "")

  if s.obsolete then
    ui.banner:SetText(string.format(L.BUILD_OBSOLETE_BANNER, obsoleteText(s.reason)))
    ui.banner:Show()
  else
    ui.banner:SetText("")
    ui.banner:Hide()
  end
  local usable = s.editor ~= nil and not s.obsolete
  ui.save:SetEnabled(usable)
  ui.use:SetEnabled(usable)
  ui.duplicate:SetEnabled(s.editor ~= nil)
  ui.export:SetEnabled(s.build ~= nil)

  if s.noTree then self:Say(L.BUILD_NO_TREE) else self:Say(s.msg, s.msgOk) end
  ui.alertCheck:SetChecked(Q.Settings:Get("talentAlert") ~= false)
  self:RefreshTrees()
  self:RefreshRows()
end

---------------------------------------------------------------------------
-- Création des cadres (hors combat)
---------------------------------------------------------------------------
local function newButton(parent, text, width, height)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, height or 22)
  b:SetText(text)
  return b
end

local function newText(parent, template, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  fs:SetJustifyH(justify or "LEFT")
  return fs
end

function Pane:NewMenuRow(i)
  local ui = self.ui
  local row = CreateFrame("Button", nil, ui.menu)
  row:SetHeight(MENU_ROW_H)
  row:SetPoint("TOPLEFT", ui.menu, "TOPLEFT", 4, -4 - (i - 1) * MENU_ROW_H)
  row:SetPoint("TOPRIGHT", ui.menu, "TOPRIGHT", -4, -4 - (i - 1) * MENU_ROW_H)
  local hl = row:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(row)
  hl:SetColorTexture(1, 1, 1, 0.12)
  row.label = newText(row, "GameFontHighlight")
  row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
  row.sub = newText(row, "GameFontDisableSmall", "RIGHT")
  row.sub:SetPoint("RIGHT", row, "RIGHT", -4, 0)
  row:SetScript("OnClick", function(self)
    if self.entry then Pane:Select(self.entry.key) end
  end)
  ui.menuRows[i] = row
  return row
end

function Pane:NewGroup(g)
  local ui = self.ui
  local frame = CreateFrame("Frame", nil, ui.treeArea)
  frame:SetSize(GROUP_W, 7 * CELL + 22)
  frame:SetPoint("TOPLEFT", ui.treeArea, "TOPLEFT", (g - 1) * (GROUP_W + 4), 0)
  frame.title = newText(frame, "GameFontNormal")
  frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, 0)
  frame.points = newText(frame, "GameFontNormal", "RIGHT")
  frame.points:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, 0)
  frame.grid = CreateFrame("Frame", nil, frame)
  frame.grid:SetSize(GROUP_W, 7 * CELL)
  frame.grid:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -20)
  ui.groupFrames[g] = frame
  return frame
end

function Pane:NewNode(spellID, node)
  local ui = self.ui
  local grid = ui.groupFrames[node.group].grid
  local btn = CreateFrame("Button", nil, grid)
  btn:SetSize(ICON, ICON)
  btn:SetPoint("TOPLEFT", grid, "TOPLEFT", (node.col - 1) * CELL + 3, -((node.tier - 1) * CELL + 3))
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn.border = btn:CreateTexture(nil, "BACKGROUND")
  btn.border:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
  btn.border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
  btn.border:SetColorTexture(1, 1, 1, 1)
  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetAllPoints(btn)
  local tex = spellIcon(spellID)
  if tex then btn.icon:SetTexture(tex) end
  btn.rank = newText(btn, "GameFontNormalSmall", "RIGHT")
  btn.rank:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, -1)
  btn.spellID = spellID
  btn:SetScript("OnClick", function(self, button) Pane:OnNodeClick(self.spellID, button) end)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellID)
    GameTooltip:AddLine(string.format(L.BUILD_TIP_RANK, self.rankNow or 0, self.maxNow or 0), 1, 0.82, 0.2)
    if self.editable then
      GameTooltip:AddLine(string.format(L.BUILD_TIP_CLICK, FIRST_LEVEL + #(Pane.state.editor and Pane.state.editor:Order() or {})),
        0.6, 0.9, 0.6, true)
    end
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  ui.nodes[spellID] = btn
  return btn
end

function Pane:NewRow(i, parent)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(ROW_H)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i - 1) * ROW_H)
  row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(i - 1) * ROW_H)
  row.next = row:CreateTexture(nil, "BACKGROUND")
  row.next:SetAllPoints(row)
  row.next:SetColorTexture(1, 0.82, 0.2, 0.18)
  row.next:Hide()
  row.done = newText(row, "GameFontNormalSmall")
  row.done:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.done:SetText("✓")
  row.done:Hide()
  row.level = newText(row, "GameFontDisableSmall")
  row.level:SetPoint("LEFT", row, "LEFT", 12, 0)
  row.swatch = row:CreateTexture(nil, "ARTWORK")
  row.swatch:SetSize(4, 10)
  row.swatch:SetPoint("LEFT", row, "LEFT", 62, 0)
  row.name = newText(row)
  row.name:SetPoint("LEFT", row, "LEFT", 70, 0)
  row.name:SetWidth(80)
  row.count = newText(row, "GameFontDisableSmall", "RIGHT")
  row.count:SetPoint("RIGHT", row, "RIGHT", -20, 0)
  row.remove = CreateFrame("Button", nil, row)
  row.remove:SetSize(16, ROW_H)
  row.remove:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  row.removeText = newText(row.remove, "GameFontNormalSmall", "CENTER")
  row.removeText:SetAllPoints(row.remove)
  row.removeText:SetText("✕")
  row.remove:SetScript("OnClick", function() Pane:OnRowRemove(i) end)
  row.remove:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.BUILD_REMOVE_TIP)
    GameTooltip:Show()
  end)
  row.remove:SetScript("OnLeave", function() GameTooltip:Hide() end)
  row.remove:Hide()
  return row
end

local function tip(frame, text)
  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(text)
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------------------
-- Import / export : fenêtre à zone de texte (spec 2.7, 7.9), posée sur le volet. Créée hors combat,
-- à la première demande. Export : texte sélectionné pour Ctrl+C. Import : texte collé, « OK » lit le
-- texte (BuildCodec:Decode) ; en cas d'erreur rien n'est écrit et BUILD_IMPORT_ERR_<raison> s'affiche.
---------------------------------------------------------------------------
function Pane:BuildCodecDialog()
  local ui, root = self.ui, self.pane
  if ui.codec then return ui.codec end
  if inCombat() or not root then return nil end
  local f = CreateFrame("Frame", nil, root, "BackdropTemplate")
  f:SetFrameLevel(root:GetFrameLevel() + 80)
  f:SetSize(520, 150)
  f:SetPoint("CENTER", root, "CENTER", 0, 0)
  if f.SetBackdrop then
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
    f:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
  end
  f:EnableMouse(true)
  f:Hide()
  ui.codec = f
  ui.codecTitle = newText(f, "GameFontNormal")
  ui.codecTitle:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
  ui.codecHint = newText(f, "GameFontDisableSmall")
  ui.codecHint:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -34)
  ui.codecHint:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -34)
  local box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  box:SetSize(480, 22)
  box:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -66)
  box:SetAutoFocus(false)
  if box.SetMaxLetters then box:SetMaxLetters(0) end
  box:SetScript("OnEscapePressed", function() f:Hide() end)
  box:SetScript("OnEditFocusGained", function(self) if f.mode == "export" then self:HighlightText() end end)
  box:SetScript("OnTextChanged", function(self, userInput)
    if userInput and f.mode == "export" and f.value then   -- l'export reste en lecture seule
      self:SetText(f.value)
      self:HighlightText()
    end
  end)
  ui.codecBox = box
  ui.codecMsg = newText(f, "GameFontNormalSmall")
  ui.codecMsg:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -94)
  ui.codecMsg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -94)
  ui.codecMsg:SetTextColor(1, 0.4, 0.35)
  ui.codecOk = newButton(f, L.BUILD_IMPORT_OK, 90)
  ui.codecOk:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -4, 12)
  ui.codecOk:SetScript("OnClick", function() Pane:ApplyImport() end)
  ui.codecClose = newButton(f, L.BUILD_CODEC_CLOSE, 90)
  ui.codecClose:SetPoint("BOTTOMLEFT", f, "BOTTOM", 4, 12)
  ui.codecClose:SetScript("OnClick", function() f:Hide() end)
  return f
end

-- Ouvre la fenêtre : mode "import" (zone vide) ou "export" (text, titre). Refusé en combat.
function Pane:ShowCodec(mode, text, title)
  if inCombat() then
    self:Say(L.BUILD_CODEC_COMBAT)
    return false
  end
  if not self.ui then return false end
  local f = self:BuildCodecDialog()
  if not f then return false end
  local ui = self.ui
  f.mode = mode
  ui.codecMsg:SetText("")
  if mode == "export" then
    f.value = text or ""
    ui.codecTitle:SetText(title or L.BUILD_EXPORT_TITLE)
    ui.codecHint:SetText(L.BUILD_EXPORT_HINT)
    ui.codecOk:Hide()
  else
    f.value = nil
    ui.codecTitle:SetText(L.BUILD_IMPORT_TITLE)
    ui.codecHint:SetText(L.BUILD_IMPORT_HINT)
    ui.codecOk:Show()
  end
  ui.codecBox:SetText(f.value or "")
  ui.menu:Hide()
  ui.gearMenu:Hide()
  f:Show()
  ui.codecBox:SetFocus()
  if mode == "export" then ui.codecBox:HighlightText() end
  return true
end

-- Build montré : le build choisi, avec l'ordre et le nom de la copie de travail s'ils ont changé.
function Pane:ShownBuild()
  local s = self.state
  local base = s.build
  if not base and not s.editor then return nil end
  local b = {}
  for k, v in pairs(base or {}) do b[k] = v end
  b.class = b.class or playerClass()
  if s.editor then b.order = s.editor:Order() end
  local typed = self.ui and trim(self.ui.nameBox:GetText()) or ""
  if typed ~= "" then b.name = typed end
  return b
end

function Pane.onExport(self)
  local b = self:ShownBuild()
  if not b then
    self:Say(L.BUILD_EXPORT_NOTHING)
    return
  end
  self:ShowCodec("export", Q.BuildCodec:Encode(b), L.BUILD_EXPORT_TITLE)
end

function Pane.onImport(self)
  self:ShowCodec("import")
end

-- Exporte les builds personnels de la classe.
function Pane:ExportAll()
  local list = {}
  for _, b in ipairs(Builds():List(playerClass())) do
    if not b.official then list[#list + 1] = b end
  end
  if #list == 0 then
    self:Say(L.BUILD_EXPORT_NONE)
    return
  end
  self:ShowCodec("export", Q.BuildCodec:EncodeAll(list), L.BUILD_EXPORT_ALL_TITLE)
end

function Pane:ApplyImport()
  local ui = self.ui
  if not (ui and ui.codec) then return end
  local list, reason = Q.BuildCodec:Decode(ui.codecBox:GetText(), playerClass())
  if not list then
    local text = L["BUILD_IMPORT_ERR_" .. tostring(reason)]
    ui.codecMsg:SetText(type(text) == "string" and text or L.BUILD_IMPORT_ERR_format)
    return
  end
  local count, last = 0, nil
  for _, b in ipairs(list) do
    local key = Builds():Save(b)
    if key then count, last = count + 1, key end
  end
  ui.codec:Hide()
  if last then self:Select(last) end
  local msg = string.format(L.BUILD_IMPORT_DONE, count)
  self:Say(msg, true)
  Q:Print(msg)
end

function Pane:Build()
  if self.ui or inCombat() or not self.pane then return end
  local root = self.pane
  local ui = { menuRows = {}, groupFrames = {}, nodes = {}, rows = {} }
  self.ui = ui

  -- ligne 1 : liste des builds, groupe, roue dentée
  ui.list = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  ui.list:SetSize(290, 24)
  ui.list:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -8)
  ui.listText = newText(ui.list, "GameFontHighlight")
  ui.listText:SetPoint("LEFT", ui.list, "LEFT", 10, 0)
  ui.listText:SetPoint("RIGHT", ui.list, "RIGHT", -18, 0)
  ui.listArrow = newText(ui.list, "GameFontNormalSmall", "RIGHT")
  ui.listArrow:SetPoint("RIGHT", ui.list, "RIGHT", -8, 0)
  ui.listArrow:SetText("v")
  ui.menu = CreateFrame("Frame", nil, root, "BackdropTemplate")
  ui.menu:SetFrameLevel(root:GetFrameLevel() + 50)   -- au-dessus des arbres, même strate que la fenêtre
  ui.menu:SetWidth(380)
  ui.menu:SetPoint("TOPLEFT", ui.list, "BOTTOMLEFT", 0, -2)
  if ui.menu.SetBackdrop then
    ui.menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    ui.menu:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
    ui.menu:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  end
  ui.menu:EnableMouse(true)
  ui.menu:Hide()
  ui.list:SetScript("OnClick", function()
    if ui.menu:IsShown() then ui.menu:Hide() else ui.menu:Show() end
  end)

  ui.groupMain = newButton(root, L.BUILD_GROUP_PRIMARY, 110)
  ui.groupMain:SetPoint("LEFT", ui.list, "RIGHT", 10, 0)
  ui.groupMain:SetScript("OnClick", function() Pane:SetGroup(1) end)
  ui.groupAlt = newButton(root, L.BUILD_GROUP_SECONDARY, 110)
  ui.groupAlt:SetPoint("LEFT", ui.groupMain, "RIGHT", 4, 0)
  ui.groupAlt:SetScript("OnClick", function() Pane:SetGroup(2) end)

  ui.gear = CreateFrame("Button", nil, root)
  ui.gear:SetSize(24, 24)
  ui.gear:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -8)
  ui.gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
  ui.gear:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  tip(ui.gear, L.BUILD_GEAR_TIP)
  ui.gearMenu = CreateFrame("Frame", nil, root, "BackdropTemplate")
  ui.gearMenu:SetFrameLevel(root:GetFrameLevel() + 50)
  ui.gearMenu:SetSize(300, 96)
  ui.gearMenu:SetPoint("TOPRIGHT", ui.gear, "BOTTOMRIGHT", 0, -2)
  if ui.gearMenu.SetBackdrop then
    ui.gearMenu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    ui.gearMenu:SetBackdropColor(0.05, 0.05, 0.05, 0.97)
    ui.gearMenu:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  end
  ui.gearMenu:EnableMouse(true)
  ui.gearMenu:Hide()
  ui.alertCheck = CreateFrame("CheckButton", nil, ui.gearMenu, "UICheckButtonTemplate")
  ui.alertCheck:SetSize(24, 24)
  ui.alertCheck:SetPoint("TOPLEFT", ui.gearMenu, "TOPLEFT", 6, -6)
  ui.alertLabel = newText(ui.gearMenu, "GameFontHighlightSmall")
  ui.alertLabel:SetPoint("LEFT", ui.alertCheck, "RIGHT", 4, 0)
  ui.alertLabel:SetPoint("RIGHT", ui.gearMenu, "RIGHT", -6, 0)
  ui.alertLabel:SetText(L.UI_OPT_TALENTS)
  ui.alertCheck:SetScript("OnClick", function(self) Q.Settings:Set("talentAlert", self:GetChecked() and true or false) end)
  ui.fromTree = newButton(ui.gearMenu, L.TALENT_BAND_FROM_TREE, 280)
  ui.fromTree:SetPoint("TOPLEFT", ui.gearMenu, "TOPLEFT", 10, -36)
  ui.fromTree:SetScript("OnClick", function() Pane:CreateFromTree() end)
  ui.exportAll = newButton(ui.gearMenu, L.BUILD_EXPORT_ALL, 280)
  ui.exportAll:SetPoint("TOPLEFT", ui.gearMenu, "TOPLEFT", 10, -62)
  ui.exportAll:SetScript("OnClick", function() Pane:ExportAll() end)
  ui.gear:SetScript("OnClick", function()
    if ui.gearMenu:IsShown() then ui.gearMenu:Hide() else ui.gearMenu:Show() end
  end)

  -- ligne 2 : nom et actions
  ui.nameBox = CreateFrame("EditBox", nil, root, "InputBoxTemplate")
  ui.nameBox:SetSize(206, 22)
  ui.nameBox:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -38)
  ui.nameBox:SetAutoFocus(false)
  ui.nameBox:SetMaxLetters(40)
  ui.nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  ui.nameBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  ui.save = newButton(root, L.BUILD_SAVE, 80)
  ui.save:SetPoint("LEFT", ui.nameBox, "RIGHT", 6, 0)
  ui.save:SetScript("OnClick", function() Pane:Save() end)
  ui.duplicate = newButton(root, L.BUILD_DUPLICATE, 80)
  ui.duplicate:SetPoint("LEFT", ui.save, "RIGHT", 4, 0)
  ui.duplicate:SetScript("OnClick", function() Pane:Duplicate() end)
  ui.use = newButton(root, L.BUILD_USE, 120)
  ui.use:SetPoint("LEFT", ui.duplicate, "RIGHT", 4, 0)
  ui.use:SetScript("OnClick", function() Pane:Use() end)
  ui.import = newButton(root, L.BUILD_IMPORT, 76)
  ui.import:SetPoint("LEFT", ui.use, "RIGHT", 4, 0)
  ui.import:SetScript("OnClick", function() Pane:Import() end)
  tip(ui.import, L.BUILD_IMPORT_TIP)
  ui.export = newButton(root, L.BUILD_EXPORT, 76)
  ui.export:SetPoint("LEFT", ui.import, "RIGHT", 4, 0)
  ui.export:SetScript("OnClick", function() Pane:Export() end)
  tip(ui.export, L.BUILD_EXPORT_TIP)

  -- ligne 3 : source, badge ; bandeau obsolète ; message
  ui.source = newText(root, "GameFontDisableSmall")
  ui.source:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -66)
  ui.badge = newText(root, "GameFontNormalSmall")
  ui.badge:SetPoint("TOPLEFT", root, "TOPLEFT", 260, -66)
  ui.banner = newText(root, "GameFontNormal")
  ui.banner:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -80)
  ui.banner:SetPoint("TOPRIGHT", root, "TOPRIGHT", -14, -80)
  ui.banner:SetTextColor(1, 0.4, 0.35)
  ui.banner:Hide()
  ui.msg = newText(root, "GameFontNormalSmall")
  ui.msg:SetPoint("TOPLEFT", root, "TOPLEFT", 14, -110)
  ui.msg:SetPoint("TOPRIGHT", root, "TOPRIGHT", -14, -110)

  -- arbres
  ui.treeArea = CreateFrame("Frame", nil, root)
  ui.treeArea:SetSize(3 * (GROUP_W + 4), 7 * CELL + 24)
  ui.treeArea:SetPoint("TOPLEFT", root, "TOPLEFT", 10, -128)

  -- curseur de niveau et total
  ui.levelText = newText(root, "GameFontHighlightSmall")
  ui.levelText:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 14, 52)
  local okSlider, slider = pcall(CreateFrame, "Slider", nil, root, "OptionsSliderTemplate")
  if not (okSlider and slider) then slider = CreateFrame("Slider", nil, root) end
  ui.slider = slider
  slider:SetOrientation("HORIZONTAL")
  slider:SetSize(300, 16)
  slider:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 16, 30)
  slider:SetMinMaxValues(FIRST_LEVEL, MAX_LEVEL)
  slider:SetValueStep(1)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  if slider.Low then slider.Low:SetText(tostring(FIRST_LEVEL)) end
  if slider.High then slider.High:SetText(tostring(MAX_LEVEL)) end
  if slider.Text then slider.Text:SetText("") end
  slider:SetValue(MAX_LEVEL)
  slider:SetScript("OnValueChanged", function(_, v) Pane:OnLevel(v) end)
  ui.count = newText(root, "GameFontHighlightSmall")
  ui.count:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 14, 10)

  -- liste des points « Niv. N »
  ui.scroll = CreateFrame("ScrollFrame", nil, root, "UIPanelScrollFrameTemplate")
  ui.scroll:SetPoint("TOPLEFT", root, "TOPLEFT", 530, -128)
  ui.scroll:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -30, 10)
  ui.scrollChild = CreateFrame("Frame", nil, ui.scroll)
  ui.scrollChild:SetSize(180, MAX_POINTS * ROW_H)
  ui.scroll:SetScrollChild(ui.scrollChild)
  for i = 1, MAX_POINTS do ui.rows[i] = self:NewRow(i, ui.scrollChild) end

  self.state.group = nil
end

---------------------------------------------------------------------------
-- Affichage du volet
---------------------------------------------------------------------------
function Pane:OnShow()
  if not self.ui then
    if inCombat() then self.wantBuild = true; return end
    self:Build()
    if not self.ui then return end
  end
  self.wantBuild = nil
  local s = self.state
  self:LoadTree()
  if s.key and Builds():Get(s.key) then
    if s.tree and not s.editor then
      s.editor = Q.BuildEditor.new(s.build or Builds():Get(s.key), s.tree)
    elseif not s.tree then
      s.editor = nil
    end
    self:Refresh()
  else
    self:Select(self:DefaultKey())
  end
end

function Pane:OnHide()
  if self.ui then
    self.ui.menu:Hide()
    self.ui.gearMenu:Hide()
    if self.ui.codec then self.ui.codec:Hide() end
  end
end

-- Accroche au volet « build » de BuildWindow (nil avant sa création hors combat).
function Pane:Attach()
  if self.pane then return true end
  local W = Q.UI.BuildWindow
  local pane = W and W:Pane("build")
  if not pane then return false end
  self.pane = pane
  pane:SetScript("OnShow", function() Pane:OnShow() end)
  pane:SetScript("OnHide", function() Pane:OnHide() end)
  if pane:IsShown() then self:OnShow() end
  return true
end

Q:On("BUILDS_CHANGED", function()
  if not (Pane.ui and Pane.pane and Pane.pane:IsShown()) then return end
  local s = Pane.state
  if s.key and not Builds():Get(s.key) then
    Pane:Select(Pane:DefaultKey())
  else
    Pane:Refresh()
  end
end)

Q:On("SETTINGS_CHANGED", function()
  if Pane.ui and Pane.pane and Pane.pane:IsShown() then
    Pane.ui.alertCheck:SetChecked(Q.Settings:Get("talentAlert") ~= false)
  end
end)

Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if not Pane.pane then Pane:Attach() end
  if Pane.wantBuild and Pane.pane and Pane.pane:IsShown() then Pane:OnShow() end
end)

Pane:Attach()
