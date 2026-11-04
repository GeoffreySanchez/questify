local addonName, Q = ...

-- Fenêtre d'une quête de classe (spec § 5.7), ouverte depuis l'alerte du suivi :
-- titre, niveau, PNJ de départ et zone, objectifs de la première quête à faire (QuestieDB),
-- récompenses (boutons d'objets avec infobulle), XP de la chaîne, puis deux choix :
-- « Ajouter à la route » et « Ignorer ». Les deux marquent la chaîne comme vue.
Q.UI = Q.UI or {}
local Popup = { items = {} }
Q.UI.ClassQuestPopup = Popup

local L = Q.L

local WIDTH, HEIGHT = 360, 420
local INNER = WIDTH - 40
local ITEM_SIZE = 32
local ITEMS_PER_ROW = 7
local MAX_ITEMS = 14
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

---------------------------------------------------------------------------
-- Données de la chaîne
---------------------------------------------------------------------------
-- Titre dans la langue du client : nom de la première quête (QuestieDB, puis le client),
-- sinon le titre anglais des données générées.
function Popup.ChainTitle(chain)
  if type(chain) ~= "table" then return "?" end
  local id = type(chain.quests) == "table" and chain.quests[1] or nil
  if id then
    local name = Q.QDB:QuestName(id)
    if type(name) == "string" and name ~= "" and name:sub(1, 1) ~= "#" then return name end
  end
  return tostring(chain.title or chain.key or "?")
end

local function firstQuest(chain)
  if Q.ClassQuests and Q.ClassQuests.FirstQuest then return Q.ClassQuests:FirstQuest(chain) end
  local quests = type(chain.quests) == "table" and chain.quests or {}
  for _, id in ipairs(quests) do
    if not Q.Progress:IsTurnedIn(id) then return id end
  end
  return quests[1]
end

-- Texte des objectifs : objectivesText de QuestieDB (API publique), sinon les cibles connues.
local function objectivesOf(questId)
  if not questId then return "" end
  local db = QuestDB or (LibQuestieDB and LibQuestieDB.Quest)
  if type(db) == "table" and type(db.Get) == "function" then
    local ok, texts = pcall(db.Get, questId, "objectivesText")
    if ok and type(texts) == "table" then
      local lines = {}
      for _, s in ipairs(texts) do
        if type(s) == "string" and s ~= "" then lines[#lines + 1] = s end
      end
      if #lines > 0 then return table.concat(lines, "\n") end
    end
  end
  local q = Q.QDB:Quest(questId)
  if not q then return "" end
  local lines = {}
  for _, o in ipairs(q.objectives.ordered) do
    if o.kind == "creature" then
      lines[#lines + 1] = string.format(L.OBJ_KILL, Q.QDB:NpcName(o.ids[1]))
    elseif o.kind == "object" then
      lines[#lines + 1] = string.format(L.OBJ_USE, Q.QDB:ObjectName(o.ids[1]))
    elseif o.kind == "item" then
      lines[#lines + 1] = string.format(L.OBJ_LOOT, Q.QDB:ItemName(o.ids[1]))
    elseif o.kind == "killCredit" and o.text then
      lines[#lines + 1] = string.format(L.OBJ_KILL, o.text)
    end
  end
  return table.concat(lines, "\n")
end

-- Donneur (PNJ, objet du monde ou objet) le plus proche du joueur parmi ceux de la quête, et sa
-- zone (Q.ClassQuests:Starter).
local function starterOf(questId)
  if not questId or not (Q.ClassQuests and Q.ClassQuests.Starter) then return nil end
  local s = Q.ClassQuests:Starter(questId)
  if not s then return nil end
  local zone = s.mapId and Q.Maps:MapName(s.mapId) or nil
  return s.name, zone
end

local function rewardsOf(chain)
  local items, seen, xp = {}, {}, 0
  local rewards = type(chain.rewards) == "table" and chain.rewards or {}
  for _, id in ipairs(chain.quests or {}) do
    local r = rewards[id]
    if type(r) == "table" then
      for _, itemId in ipairs(r.items or {}) do
        if type(itemId) == "number" and not seen[itemId] then
          seen[itemId] = true
          items[#items + 1] = itemId
        end
      end
      if type(r.xp) == "number" then xp = xp + r.xp end
    end
  end
  return items, xp
end

local function itemIcon(itemId)
  if C_Item and C_Item.GetItemIconByID then
    local ok, icon = pcall(C_Item.GetItemIconByID, itemId)
    if ok and icon then return icon end
  end
  return FALLBACK_ICON
end

---------------------------------------------------------------------------
-- Boutons d'objets (aussi utilisés par l'onglet « Quêtes de classe » du journal)
---------------------------------------------------------------------------
local function itemOnEnter(btn)
  if not (btn.itemId and GameTooltip) then return end
  GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
  GameTooltip:SetItemByID(btn.itemId)
  GameTooltip:Show()
end

function Popup.CreateItemButton(parent, size)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints(b)
  b.icon = icon
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  b:SetScript("OnEnter", function(self) Q.SafeCall(itemOnEnter, self) end)
  b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  b:Hide()
  return b
end

function Popup.SetItemButton(b, itemId)
  b.itemId = itemId
  if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, itemId) end
  b.icon:SetTexture(itemIcon(itemId))
  b:Show()
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", "QuestifyClassQuestPopup", UIParent, "ButtonFrameTemplate")
  if not ok or not f then
    f = CreateFrame("Frame", "QuestifyClassQuestPopup", UIParent, "BackdropTemplate")
  end
  return f
end

local function header(parent, text)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  return fs
end

function Popup:Create()
  if self.frame then return self.frame end
  local f = newFrame()
  self.frame = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  if f.SetTitle then f:SetTitle(L.UI_TAB_CLASS) end
  if f.SetPortraitToClassIcon and Q.Player and Q.Player.classFile then
    pcall(f.SetPortraitToClassIcon, f, Q.Player.classFile)
  end
  if UISpecialFrames then tinsert(UISpecialFrames, "QuestifyClassQuestPopup") end

  -- Contenu, dans le cadre intérieur du modèle (60 px en haut, barre de boutons en bas)
  local c = CreateFrame("Frame", nil, f)
  c:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -68)
  c:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 32)
  self.content = c

  local title = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetJustifyH("LEFT")
  title:SetWidth(INNER - 70)
  self.title = title
  local counter = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  counter:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, -2)
  counter:SetJustifyH("RIGHT")
  self.counter = counter
  local level = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  level:SetJustifyH("LEFT")
  self.level = level
  local start = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  start:SetJustifyH("LEFT")
  start:SetWidth(INNER)
  self.start = start
  self.objectivesHeader = header(c, L.UI_POPUP_OBJECTIVES)
  local objectives = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  objectives:SetJustifyH("LEFT")
  objectives:SetJustifyV("TOP")
  objectives:SetWidth(INNER)
  objectives:SetWordWrap(true)
  self.objectives = objectives
  self.rewardsHeader = header(c, L.UI_POPUP_REWARDS)
  local noRewards = c:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  noRewards:SetText(L.UI_POPUP_NO_REWARDS)
  self.noRewards = noRewards
  for i = 1, MAX_ITEMS do self.items[i] = Popup.CreateItemButton(c, ITEM_SIZE) end
  local xp = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  xp:SetJustifyH("LEFT")
  self.xp = xp

  -- Boutons de la barre du bas
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

-- Empile les éléments de haut en bas selon leur hauteur réelle.
local function place(region, y, x)
  region:ClearAllPoints()
  region:SetPoint("TOPLEFT", Popup.content, "TOPLEFT", x or 0, -y)
end

---------------------------------------------------------------------------
-- Affichage
---------------------------------------------------------------------------
-- Show(chain, index, total) : accepte aussi une ligne { chain, state } de Q.ClassQuests:List().
-- index/total (facultatifs) : position parmi les alertes, affichée « 1 sur 3 ».
function Popup:Show(chain, index, total)
  if type(chain) == "table" and type(chain.chain) == "table" then chain = chain.chain end
  if type(chain) ~= "table" then return end
  self:Create()
  self.chain = chain
  local y = 0

  if tonumber(total) and total > 1 then
    self.counter:SetFormattedText(L.UI_POPUP_COUNTER, tonumber(index) or 1, total)
    self.counter:Show()
  else
    self.counter:SetText("")
    self.counter:Hide()
  end
  self.title:SetText(Popup.ChainTitle(chain))
  place(self.title, y)
  y = y + (self.title:GetStringHeight() or 16) + 4
  self.level:SetFormattedText(L.UI_POPUP_LEVEL, tonumber(chain.level) or 1)
  place(self.level, y)
  y = y + 18

  local qid = firstQuest(chain)
  local who, zone = starterOf(qid)
  if who then
    if zone then
      self.start:SetFormattedText(L.UI_POPUP_START, "|cff00ff96" .. who .. "|r", zone)
    else
      self.start:SetFormattedText(L.UI_POPUP_START_NOZONE, "|cff00ff96" .. who .. "|r")
    end
    place(self.start, y)
    self.start:Show()
    y = y + (self.start:GetStringHeight() or 14) + 10
  else
    self.start:Hide()
  end

  local objText = objectivesOf(qid)
  if objText ~= "" then
    place(self.objectivesHeader, y)
    self.objectivesHeader:Show()
    y = y + 18
    self.objectives:SetText(objText)
    place(self.objectives, y)
    self.objectives:Show()
    y = y + (self.objectives:GetStringHeight() or 14) + 10
  else
    self.objectivesHeader:Hide()
    self.objectives:SetText("")
    self.objectives:Hide()
  end

  place(self.rewardsHeader, y)
  y = y + 20
  local items, xp = rewardsOf(chain)
  local shown = math.min(#items, MAX_ITEMS)
  for i = 1, MAX_ITEMS do
    local b = self.items[i]
    if i <= shown then
      local col, row = (i - 1) % ITEMS_PER_ROW, math.floor((i - 1) / ITEMS_PER_ROW)
      place(b, y + row * (ITEM_SIZE + 4), col * (ITEM_SIZE + 4))
      Popup.SetItemButton(b, items[i])
    else
      b.itemId = nil
      b:Hide()
    end
  end
  if shown > 0 then
    self.noRewards:Hide()
    y = y + math.ceil(shown / ITEMS_PER_ROW) * (ITEM_SIZE + 4) + 4
  else
    place(self.noRewards, y)
    self.noRewards:Show()
    y = y + 18
  end
  if xp > 0 then
    self.xp:SetFormattedText(L.UI_POPUP_XP, xp)
    place(self.xp, y)
    self.xp:Show()
    y = y + 18
  else
    self.xp:SetText("")
    self.xp:Hide()
  end

  self.frame:SetHeight(math.max(240, y + 68 + 40))
  self.frame:Show()
  self.frame:Raise()
end

function Popup:Hide()
  if self.frame then self.frame:Hide() end
end

-- Choix du joueur : la chaîne est d'abord marquée vue (l'alerte disparaît), puis ajoutée ou
-- ignorée (le module envoie CLASSQUESTS_CHANGED), puis la fenêtre se ferme.
function Popup:Choose(action)
  local chain = self.chain
  local cq = Q.ClassQuests
  if chain and cq then
    if cq.MarkSeen then cq:MarkSeen(chain.key) end
    if cq[action] then cq[action](cq, chain.key) end
  end
  self:Hide()
  if Q.UI.Tracker and Q.UI.Tracker.Refresh then Q.UI.Tracker:Refresh() end
end
