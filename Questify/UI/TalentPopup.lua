local addonName, Q = ...

-- Popup au milieu de l'écran quand un point de talent est à dépenser : niveau gagné (ou nombre de
-- points), jusqu'à 5 talents du build suivi avec leur icône (infobulle du sort) et leur rang, « +N » s'il y
-- en a plus, et trois boutons : « Apprendre » (Q.TalentLearn, un clic), « Ouvrir les talents », « Plus
-- tard ». Sans build, un seul bouton « Choisir un build » (fenêtre des builds si elle existe, sinon les
-- talents du jeu).
-- Build actif obsolète ou arbre qui ne suit plus le build (R33) : aucun talent proposé, aucun bouton,
-- seulement « Tu as N point(s) de talent à dépenser » ; un clic sur la popup ou 10 s la ferment.
-- « Apprendre » relit l'état au clic (Talents:State) ; validation lancée : « Talent appris » à la fin de
-- l'incantation (TALENT_COMMIT de Q.TalentLearn) ; points déjà en attente : la popup demande de les valider.
-- Option talentAlert (la même que l'alerte du suivi).
-- Une seule fois par point : Q.char.talentPopup = { seen, level } garde le nombre de points déjà
-- annoncé et le niveau ; on n'affiche que si unspent > seen ou si le niveau a monté. Quand des points
-- sont dépensés, seen redescend (TALENTS_CHANGED) : le point suivant s'annonce de nouveau.
-- « Plus tard » fixe seen au nombre de points à dépenser du moment (Talents:Unspent).
-- Rien ne s'affiche tant que Q.char n'existe pas, que le niveau est inférieur à 10, que l'arbre n'est
-- pas lisible ou qu'un build suivi n'a encore aucun talent dû : l'état n'est alors pas touché, et le
-- TALENTS_DUE suivant (ou LOGIN) réessaie. Une popup déjà affichée est remplie de nouveau par un
-- TALENTS_DUE dont la liste due n'est plus vide.
-- Jamais affichée ni créée en combat : l'affichage est remis à PLAYER_REGEN_ENABLED (celle à l'écran
-- au début d'un combat est cachée puis rouverte à la fin).
Q.UI = Q.UI or {}
local Popup = { pending = false, icons = {} }
Q.UI.TalentPopup = Popup

local L = Q.L

local WIDTH, HEIGHT = 380, 250
local MESSAGE_HEIGHT = 90
local ICON_SIZE, ICON_GAP = 44, 8
local MAX_ICONS = 5
local BUTTON_W, BUTTON_H = 110, 24
local AUTO_CLOSE = 10          -- secondes : popup à message seul (R33)

local function setting(path) return Q.Settings:Get(path) end
local function inCombat() return InCombatLockdown and InCombatLockdown() end
local function playerLevel() return (Q.Player and Q.Player.level) or 0 end

local FIRST_LEVEL = 10

-- Q.char posé (ADDON_LOADED) et talents débloqués : sinon rien ne s'affiche ni ne s'enregistre.
local function ready()
  return type(Q.char) == "table" and playerLevel() >= FIRST_LEVEL
end

local function state()
  local c = Q.char
  if type(c.talentPopup) ~= "table" then c.talentPopup = { seen = 0, level = 0 } end
  local s = c.talentPopup
  s.seen = tonumber(s.seen) or 0
  s.level = tonumber(s.level) or 0
  return s
end

local function plain(v)
  if Q.Util.IsSecret(v) then return nil end
  return v
end

local function spellName(id)
  if type(C_Spell) == "table" and type(C_Spell.GetSpellName) == "function" then
    local ok, v = pcall(C_Spell.GetSpellName, id)
    if ok then return plain(v) end
  end
  return nil
end

local function spellTexture(id)
  if type(C_Spell) == "table" and type(C_Spell.GetSpellTexture) == "function" then
    local ok, v = pcall(C_Spell.GetSpellTexture, id)
    if ok then return plain(v) end
  end
  return nil
end

---------------------------------------------------------------------------
-- Cadre
---------------------------------------------------------------------------
local function makeButton(f, label, onClick)
  local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  b:SetSize(BUTTON_W, BUTTON_H)
  b:SetText(label)
  b:SetScript("OnClick", function() Q.SafeCall(onClick) end)
  return b
end

function Popup:Create()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", "QuestifyTalentPopup", UIParent, "BackdropTemplate")
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  f:SetFrameStrata("HIGH")
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 14,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(1, 0.82, 0, 1)
  end

  self.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  self.title:SetPoint("TOP", f, "TOP", 0, -14)

  for i = 1, MAX_ICONS do
    local holder = CreateFrame("Frame", nil, f)
    holder:SetSize(ICON_SIZE, ICON_SIZE)
    local tex = holder:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(holder)
    local rank = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rank:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -2, 2)
    holder:EnableMouse(true)
    holder:SetScript("OnEnter", function(h) Q.SafeCall(Popup.IconTooltip, Popup, h) end)
    holder:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    holder:Hide()
    self.icons[i] = { holder = holder, tex = tex, rank = rank }
  end
  self.more = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  self.more:Hide()

  self.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  self.name:SetPoint("TOP", f, "TOP", 0, -108)
  self.treeLine = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  self.treeLine:SetPoint("TOP", self.name, "BOTTOM", 0, -4)
  self.buildLine = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.buildLine:SetPoint("TOP", self.treeLine, "BOTTOM", 0, -8)
  -- avertissement au-dessus des boutons (points en attente à valider)
  self.notice = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.notice:SetPoint("BOTTOM", f, "BOTTOM", 0, 46)
  self.notice:SetWidth(WIDTH - 30)
  self.notice:SetTextColor(1, 0.35, 0.3)
  self.notice:Hide()
  -- message seul (R33) et zone de clic qui ferme la popup
  self.message = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  self.message:SetPoint("CENTER", f, "CENTER", 0, 0)
  self.message:SetWidth(WIDTH - 40)
  self.message:Hide()
  self.dismiss = CreateFrame("Button", nil, f)
  self.dismiss:SetAllPoints(f)
  self.dismiss:SetScript("OnClick", function() Q.SafeCall(Popup.Hide, Popup) end)
  self.dismiss:Hide()

  self.learnButton = makeButton(f, L.TALENT_POPUP_LEARN, function() Popup:Learn() end)
  self.openButton = makeButton(f, L.TALENT_POPUP_OPEN, function() Popup:OpenTalents() end)
  self.laterButton = makeButton(f, L.TALENT_POPUP_LATER, function() Popup:Snooze() end)
  self.chooseButton = makeButton(f, L.UI_TALENT_NO_BUILD, function() Popup:ChooseBuild() end)
  self.chooseButton:SetWidth(BUTTON_W + 40)

  f:Hide()
  self.frame = f
  return f
end

-- Infobulle du jeu sur une icône de la popup (M4).
function Popup:IconTooltip(holder)
  local tip = GameTooltip
  local id = holder and holder.qfSpellID
  if type(tip) ~= "table" or type(id) ~= "number" then return end
  tip:SetOwner(holder, "ANCHOR_RIGHT")
  if type(tip.SetSpellByID) == "function" then pcall(tip.SetSpellByID, tip, id) end
  tip:Show()
end

-- Contenu de la popup pour l'alerte : "message" (build obsolète ou arbre qui ne suit plus le build, R33),
-- "choose" (aucun build), "learn" (talents dus) ; nil : pas encore prête (arbre illisible, build sans
-- talent dû), rien n'est affiché.
local function modeOf(alert)
  if not alert.tree then return nil end
  if alert.build == nil then return "choose" end
  if alert.obsolete or alert.deviates then return "message" end
  if #(alert.due or {}) > 0 then return "learn" end
  return nil
end

local function layoutButtons(self, mode)
  local f = self.frame
  for _, b in ipairs({ self.learnButton, self.openButton, self.laterButton, self.chooseButton }) do
    b:ClearAllPoints(); b:Hide()
  end
  local row = {}
  if mode == "choose" then
    row = { self.chooseButton, self.laterButton }
  elseif mode == "learn" then
    row = { self.learnButton, self.openButton, self.laterButton }
  end
  local total = -ICON_GAP
  for _, b in ipairs(row) do total = total + b:GetWidth() + ICON_GAP end
  local x = -total / 2
  for _, b in ipairs(row) do
    b:SetPoint("BOTTOMLEFT", f, "BOTTOM", x, 16)
    b:Show()
    x = x + b:GetWidth() + ICON_GAP
  end
end

local function fillIcons(self, due)
  local n = math.min(#due, MAX_ICONS)
  local x = -(n * ICON_SIZE + (n - 1) * ICON_GAP) / 2
  for i = 1, MAX_ICONS do
    local slot, entry = self.icons[i], due[i]
    slot.holder:ClearAllPoints()
    if i <= n and entry then
      slot.tex:SetTexture(spellTexture(entry.spellID) or "Interface\\Icons\\INV_Misc_QuestionMark")
      slot.rank:SetText(tostring(entry.rank or 1))
      slot.holder.qfSpellID = entry.spellID
      slot.holder:SetPoint("TOPLEFT", self.frame, "TOP", x, -52)
      slot.holder:Show()
      x = x + ICON_SIZE + ICON_GAP
    else
      slot.holder.qfSpellID = nil
      slot.holder:Hide()
    end
  end
  self.more:ClearAllPoints()
  if #due > MAX_ICONS then
    self.more:SetText(string.format(L.TALENT_POPUP_MORE, #due - MAX_ICONS))
    self.more:SetPoint("LEFT", self.icons[MAX_ICONS].holder, "RIGHT", 6, 0)
    self.more:Show()
  else
    self.more:Hide()
  end
end

local function fill(self, alert, mode)
  self.mode = mode
  local f = self.frame
  self.notice:SetText("")
  self.notice:Hide()
  if mode == "message" then
    f:SetHeight(MESSAGE_HEIGHT)
    self.title:SetText("")
    self.title:Hide()
    fillIcons(self, {})
    self.name:SetText("")
    self.treeLine:SetText("")
    self.buildLine:SetText("")
    self.message:SetText(alert.unspent <= 1 and L.TALENT_POPUP_MESSAGE_ONE
      or string.format(L.TALENT_POPUP_MESSAGE_MANY, alert.unspent))
    self.message:Show()
    self.dismiss:Show()
    layoutButtons(self, mode)
    return
  end
  f:SetHeight(HEIGHT)
  self.message:Hide()
  self.dismiss:Hide()
  self.title:Show()
  local due = alert.due or {}
  local level = playerLevel()
  if alert.unspent <= 1 then
    self.title:SetText(string.format(L.TALENT_POPUP_LEVEL, level))
  else
    self.title:SetText(string.format(L.TALENT_POPUP_POINTS, alert.unspent))
  end
  fillIcons(self, due)

  local first = due[1]
  if first then
    local node = first.node
    local group = node and alert.tree and alert.tree.groups and alert.tree.groups[node.group]
    self.name:SetText(spellName(first.spellID) or "?")
    self.treeLine:SetText(string.format(L.TALENT_POPUP_TREE, group and group.name or "?",
      first.rank or 1, node and node.maxRanks or 1))
  else
    self.name:SetText("")
    self.treeLine:SetText("")
  end
  if alert.build then
    self.buildLine:SetText(string.format(L.TALENT_POPUP_BUILD, Q.Builds:Name(alert.build)))
  else
    self.buildLine:SetText("")
  end
  layoutButtons(self, mode)
end

-- Popup à message seul : fermée au bout de AUTO_CLOSE secondes (celle de ce dernier affichage seulement).
local function armAutoClose(self)
  self.serial = (self.serial or 0) + 1
  local serial = self.serial
  Q:After(AUTO_CLOSE, function()
    if Popup.serial == serial and Popup.mode == "message" and Popup.frame and Popup.frame:IsShown() then
      Popup:Hide()
    end
  end)
end

---------------------------------------------------------------------------
-- Affichage
---------------------------------------------------------------------------
-- Montre la popup pour l'alerte courante. En combat : remise à PLAYER_REGEN_ENABLED, sans créer de cadre.
function Popup:Show(given)
  if setting("talentAlert") == false then return false end
  if not ready() then return false end
  if inCombat() then self.pending = true; return false end
  local alert = given or Q.Talents:Alert()
  if not alert then self.pending = false; return false end
  local mode = modeOf(alert)
  if not mode then return false end   -- pas encore prête
  self.pending = false
  self.alert = alert
  local f = self:Create()
  fill(self, alert, mode)
  local s = state()
  s.seen, s.level = alert.unspent, playerLevel()
  f:Show()
  if mode == "message" then armAutoClose(self) end
  return true
end

function Popup:Hide()
  self.pending = false
  self.serial = (self.serial or 0) + 1
  if self.frame then self.frame:Hide() end
end

-- « Plus tard » : plus d'annonce avant un nouveau point (seen = unspent) ; ferme la popup.
function Popup:Snooze()
  local s = state()
  s.seen = Q.Talents:Unspent()
  s.level = playerLevel()
  self:Hide()
end

function Popup:OpenTalents()
  self:Hide()
  Q.Talents:OpenFrame()
end

function Popup:ChooseBuild()
  self:Hide()
  local W = Q.UI.BuildWindow
  if W and type(W.Open) == "function" then W:Open("build") else Q.Talents:OpenFrame() end
end

local function dueNames(due)
  local names = {}
  for _, entry in ipairs(due or {}) do names[#names + 1] = spellName(entry.spellID) or "?" end
  return table.concat(names, ", ")
end

-- « Apprendre » : l'état est relu au clic (I5) ; plus rien de dû (points dépensés ailleurs, build devenu
-- obsolète, arbre qui ne suit plus le build) : la popup se ferme sans rien acheter.
function Popup:Learn()
  local s = Q.Talents:State()
  local due = s and not s.obsolete and not s.deviates and s.due or {}
  if #due == 0 then
    self:Hide()
    return
  end
  self.alert = s
  local result = Q.TalentLearn:Learn(s.tree, due)
  if result == "ok" then
    self:Hide()          -- « Talent appris » à la fin de l'incantation (TALENT_COMMIT)
  elseif result == "combat" then
    if self.frame then self.frame:Hide() end
    self.pending = true
  elseif result == "staged" then
    self.notice:SetText(L.TALENT_POPUP_STAGED)
    self.notice:Show()
  else
    self:Hide()
    if Q.Talents:OpenFrame(true) then
      Q:Print(L.TALENT_LEARN_FALLBACK)
    else
      Q:Print(L.TALENT_LEARN_FALLBACK_KEY, Q.Talents:TalentKey())
    end
  end
end

-- Fin de la validation lancée par « Apprendre » (Q.TalentLearn) : réussite ou échec annoncés maintenant.
function Popup:OnCommit(result, due)
  if result == "done" then
    Q:Print(L.TALENT_LEARNED, dueNames(due))
  else
    Q:Print(L.TALENT_LEARN_COMMIT_FAILED)
  end
end

-- TALENTS_DUE : une seule annonce par point (ou par niveau gagné).
function Popup:OnDue(alert)
  if type(alert) ~= "table" or setting("talentAlert") == false or not ready() then return end
  local mode = modeOf(alert)
  if self.frame and self.frame:IsShown() and mode then
    local was = self.mode
    self.alert = alert
    fill(self, alert, mode)
    if mode == "message" and was ~= "message" then armAutoClose(self) end
    return
  end
  local s = state()
  if alert.unspent < s.seen then s.seen = alert.unspent end
  if alert.unspent > s.seen or playerLevel() > s.level then self:Show(alert) end
end

-- Points dépensés : seen redescend pour que le point suivant s'annonce ; plus aucun point : la popup se
-- ferme (I5), même remise à la fin du combat.
function Popup:Sync()
  if type(Q.char) ~= "table" then return end
  local n = Q.Talents:Unspent()
  local s = state()
  if n < s.seen then s.seen = n end
  if n <= 0 then self:Hide() end
end

function Popup:Suspend()
  if self.frame and self.frame:IsShown() then
    self.frame:Hide()
    self.pending = true
  end
end

function Popup:Resume()
  if self.pending and not inCombat() then self:Show() end
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
Q:On("TALENTS_DUE", function(alert) Popup:OnDue(alert) end)
Q:On("LOGIN", function() Popup:OnDue(Q.Talents:Alert()) end)
Q:On("TALENTS_CHANGED", function() Popup:Sync() end)
Q:On("TALENT_COMMIT", function(result, due) Popup:OnCommit(result, due) end)
Q:RegisterEvent("PLAYER_REGEN_DISABLED", function() Q.SafeCall(Popup.Suspend, Popup) end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function() Q.SafeCall(Popup.Resume, Popup) end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "talentAlert" and setting("talentAlert") == false then Popup:Hide() end
end)
