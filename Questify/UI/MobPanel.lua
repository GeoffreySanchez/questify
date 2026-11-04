local addonName, Q = ...

-- Monstres à tuer de l'étape courante (spec § 5.5).
-- Ils sont affichés dans le suivi, sous la ligne d'objectif de l'étape « Faire » (UI/Tracker.lua,
-- qui demande la liste ici avec MobPanel:MobsFor). Ce module pose par-dessus chaque ligne un
-- bouton sécurisé invisible (SecureActionButtonTemplate, type « macro ») : un clic cible le
-- monstre le plus proche du nom indiqué et pose un crâne (/tm !8). SetRaidTarget et TargetUnit
-- sont protégées : on ne les appelle jamais.
-- Les boutons ne sont pas enfants du suivi : un enfant sécurisé le rendrait protégé (impossible à
-- déplacer ou à redimensionner en combat). Ils sont placés sur l'écran par coordonnées, hors combat.
-- Règle du combat : aucun attribut, aucune ancre, aucune taille et aucun affichage de ces boutons
-- ne change pendant InCombatLockdown(). Si les lignes du suivi bougent ou changent en combat, les
-- boutons sont marqués « en attente » (surbrillance coupée, infobulle qui le dit) et replacés sur
-- PLAYER_REGEN_ENABLED.
-- Ciblage auto (option tracker.autoTarget) : un raccourci clavier (Bindings.xml) clique un bouton
-- sécurisé caché dont la macro cible le plus proche des monstres de l'étape courante et lui pose
-- un crâne. Le client interdit tout ciblage sans touche ni clic du joueur : sans raccourci, rien
-- ne se passe. La macro s'arrête en combat ([combat]) pour ne pas voler la cible du joueur.
Q.UI = Q.UI or {}
local MobPanel = { rows = {}, slots = {}, pending = false }
Q.UI.MobPanel = MobPanel

local L = Q.L

local MAX_ROWS = 6
local MODEL_SIZE = 160
local MODEL_CHECK_DELAY = 0.3
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local HIGHLIGHT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"
local AUTO_BUTTON = "QuestifyAutoTarget"
local AUTO_BINDING = "CLICK " .. AUTO_BUTTON .. ":LeftButton"
local MACRO_MAX = 255       -- longueur maximale d'une macro

-- Textes de la fenêtre des raccourcis du jeu
BINDING_HEADER_QUESTIFY = "Questify"
_G["BINDING_NAME_" .. AUTO_BINDING] = L.UI_AUTOTARGET_BINDING

local function setting(path) return Q.Settings:Get(path) end
local function inCombat() return InCombatLockdown and InCombatLockdown() end

-- Macro du bouton : la seule façon autorisée de cibler et de marquer.
local function buildMacro(name)
  return "/cleartarget\n/targetexact " .. name .. "\n/tm !8"
end
MobPanel.BuildMacro = function(_, name) return buildMacro(name) end

-- Macro du ciblage auto : rien en combat ; sinon le plus proche du premier nom présent (objectifs
-- non terminés d'abord), puis le crâne. Les noms qui dépassent la longueur maximale sont omis.
local function buildAutoMacro(mobs)
  local names, seen = {}, {}
  for _, wantDone in ipairs({ false, true }) do
    for _, mob in ipairs(mobs) do
      if (mob.done and true or false) == wantDone and not seen[mob.name] then
        seen[mob.name] = true
        names[#names + 1] = mob.name
      end
    end
  end
  if #names == 0 then return "" end
  local head, tail = "/stopmacro [combat]\n/cleartarget\n", "/tm !8"
  local lines = {}
  local size = #head + #tail
  for i, name in ipairs(names) do
    local line = (i == 1 and "/targetexact " or "/targetexact [noexists] ") .. name .. "\n"
    if size + #line > MACRO_MAX then break end
    lines[#lines + 1] = line
    size = size + #line
  end
  if #lines == 0 then return "" end
  return head .. table.concat(lines) .. tail
end
MobPanel.BuildAutoMacro = function(_, mobs) return buildAutoMacro(mobs) end

---------------------------------------------------------------------------
-- Données
---------------------------------------------------------------------------
local function cleanName(name)
  if type(name) ~= "string" then return nil end
  name = name:gsub("[\r\n]", " ")
  if name == "" or name:sub(1, 1) == "#" then return nil end   -- nom inconnu : inutile à cibler
  return name
end

-- Monstres de l'étape à afficher sous ses objectifs : 6 au plus. S'il y en a trop, les objectifs
-- non terminés passent d'abord ; l'ordre d'affichage (celui des objectifs) est conservé.
function MobPanel:MobsFor(entry)
  if not (Q.QDB and Q.QDB:IsAvailable() and Q.Progress:IsEnabled()) then return {} end
  if setting("tracker.showMobs") == false then return {} end
  local all = {}
  for _, mob in ipairs(Q.Targets:MobsForEntry(entry)) do
    mob.name = cleanName(mob.name)
    if mob.name then all[#all + 1] = mob end
  end
  if #all <= MAX_ROWS then return all end
  local keep, n = {}, 0
  for _, wantDone in ipairs({ false, true }) do
    for _, mob in ipairs(all) do
      if n < MAX_ROWS and mob.done == wantDone then
        keep[mob] = true
        n = n + 1
      end
    end
  end
  local out = {}
  for _, mob in ipairs(all) do if keep[mob] then out[#out + 1] = mob end end
  return out
end

local function levelText(mob)
  local lo, hi = mob.minLevel, mob.maxLevel
  if not lo and not hi then return "" end
  local range
  if lo and hi and lo ~= hi then range = lo .. "-" .. hi else range = tostring(lo or hi) end
  return string.format(L.UI_MOB_LEVEL, range)
end
MobPanel.LevelText = function(_, mob) return levelText(mob) end

local function objectiveText(mob)
  local objs = C_QuestLog.GetQuestObjectives(mob.questId)
  local o = type(objs) == "table" and objs[mob.objIndex] or nil
  if o and type(o.text) == "string" and o.text ~= "" then return o.text end
  if mob.viaItem then return Q.Util.StripColors(string.format(L.OBJ_LOOT, Q.QDB:ItemName(mob.viaItem))) end
  return Q.QDB:QuestName(mob.questId)
end

---------------------------------------------------------------------------
-- Modèle 3D partagé (survol)
---------------------------------------------------------------------------
local modelSeq = 0

function MobPanel:CreateModel()
  if self.modelHolder then return end
  local holder = CreateFrame("Frame", "QuestifyMobModelHolder", UIParent, "BackdropTemplate")
  holder:SetSize(MODEL_SIZE + 10, MODEL_SIZE + 10)
  holder:SetFrameStrata("TOOLTIP")
  holder:SetClampedToScreen(true)
  if holder.SetBackdrop then
    holder:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    holder:SetBackdropColor(0, 0, 0, 0.85)
  end
  holder:Hide()
  local model = CreateFrame("PlayerModel", "QuestifyMobModel", holder)
  model:SetSize(MODEL_SIZE, MODEL_SIZE)
  model:SetPoint("CENTER", holder, "CENTER", 0, 0)
  model:SetScript("OnModelLoaded", function()
    Q.SafeCall(function()
      model:Show()
      MobPanel.modelFallback:Hide()
    end)
  end)
  local fallback = holder:CreateTexture(nil, "ARTWORK")
  fallback:SetSize(64, 64)
  fallback:SetPoint("CENTER", holder, "CENTER", 0, 0)
  fallback:SetTexture(FALLBACK_ICON)
  fallback:Hide()
  self.modelHolder, self.model, self.modelFallback = holder, model, fallback
end

-- Place un cadre de UIParent à gauche d'un autre cadre, par coordonnées d'écran (sans ancre).
local function placeLeftOf(frame, other, gap)
  frame:ClearAllPoints()
  local left, top = other:GetLeft(), other:GetTop()
  if left and top then
    local k = other:GetEffectiveScale() / frame:GetEffectiveScale()
    frame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", left * k - gap, top * k)
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
end

local function mobTooltip(row, mob)
  if not GameTooltip then return end
  GameTooltip:SetOwner(row, "ANCHOR_NONE")
  GameTooltip:ClearAllPoints()
  if MobPanel.modelHolder and MobPanel.modelHolder:IsShown() then
    GameTooltip:SetPoint("TOPRIGHT", MobPanel.modelHolder, "BOTTOMRIGHT", 0, -2)
  else
    GameTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT", -6, 0)
  end
  GameTooltip:ClearLines()
  GameTooltip:AddLine(mob.name, 1, 0.38, 0.38)
  local lvl = levelText(mob)
  if lvl ~= "" then GameTooltip:AddLine(lvl, 0.8, 0.8, 0.8) end
  GameTooltip:AddLine(objectiveText(mob), 1, 1, 1, true)
  GameTooltip:AddLine(L.UI_MOB_HINT, 0.6, 0.8, 1, true)
  if MobPanel.pending then GameTooltip:AddLine(L.UI_MOB_PENDING, 1, 0.5, 0.25, true) end
  GameTooltip:Show()
end

function MobPanel:ShowModel(row)
  local mob = row and row.mob
  if not mob then return end
  self:CreateModel()
  local holder, model, fallback = self.modelHolder, self.model, self.modelFallback
  placeLeftOf(holder, row, 6)
  fallback:Hide()
  model:Show()
  if model.ClearModel then model:ClearModel() end
  pcall(model.SetCreature, model, mob.npcId)
  holder:Show()
  modelSeq = modelSeq + 1
  local mine = modelSeq
  -- Modèle encore vide après 0,3 s : icône de secours.
  Q:After(MODEL_CHECK_DELAY, function()
    if mine ~= modelSeq or not holder:IsShown() then return end
    local ok, fileId = pcall(model.GetModelFileID, model)
    if not ok or not fileId or fileId == 0 then
      model:Hide()
      fallback:Show()
    end
  end)
  mobTooltip(row, mob)
end

function MobPanel:HideModel()
  modelSeq = modelSeq + 1
  if self.modelHolder then self.modelHolder:Hide() end
  if GameTooltip then GameTooltip:Hide() end
end

---------------------------------------------------------------------------
-- Boutons sécurisés posés sur les lignes du suivi
---------------------------------------------------------------------------
local function createRow(i)
  local row = CreateFrame("Button", "QuestifyMobRow" .. i, UIParent, "SecureActionButtonTemplate")
  row:SetFrameStrata("MEDIUM")   -- au-dessus du suivi (LOW)
  row:RegisterForClicks("AnyUp", "AnyDown")
  row:SetAttribute("type", "macro")
  local hl = row:CreateTexture(nil, "HIGHLIGHT")
  hl:SetTexture(HIGHLIGHT)
  hl:SetBlendMode("ADD")
  hl:SetAllPoints(row)
  row.highlight = hl
  -- Scripts non sécurisés de survol seulement : le clic reste celui du modèle sécurisé.
  row:SetScript("OnEnter", function(self) Q.SafeCall(MobPanel.ShowModel, MobPanel, self) end)
  row:SetScript("OnLeave", function() Q.SafeCall(MobPanel.HideModel, MobPanel) end)
  row:Hide()
  MobPanel.rows[i] = row
  return row
end

-- Bouton caché du raccourci : seule sa macro change, hors combat.
local function autoButton()
  if MobPanel.auto then return MobPanel.auto end
  local b = CreateFrame("Button", AUTO_BUTTON, UIParent, "SecureActionButtonTemplate")
  b:RegisterForClicks("AnyUp", "AnyDown")
  b:SetAttribute("type", "macro")
  b:SetAttribute("macrotext", "")
  b:Hide()
  MobPanel.auto = b
  return b
end

local function autoMacro(self)
  if setting("tracker.autoTarget") ~= true then return "" end
  local mobs = {}
  for i, s in ipairs(self.slots) do mobs[i] = s.mob end
  return buildAutoMacro(mobs)
end

-- Option activée sans touche : un rappel, une fois par session.
local function bindingHint()
  if MobPanel.hinted or setting("tracker.autoTarget") ~= true then return end
  if GetBindingKey and GetBindingKey(AUTO_BINDING) then return end
  MobPanel.hinted = true
  Q:Print(L.UI_AUTOTARGET_NOKEY)
end

local function trackerFrame()
  local T = Q.UI.Tracker
  return T and T.frame
end

-- Boutons voulus d'après les lignes du suivi : { mob, macro, x, y, w, h, scale }, coordonnées
-- d'écran dans l'échelle du suivi. nil si le rectangle du suivi n'est pas encore calculé.
local function wanted(self)
  local list = {}
  local T = trackerFrame()
  if #self.slots == 0 or not (T and T:IsShown()) then return list end
  local left, top = T:GetLeft(), T:GetTop()
  if not (left and top) then return nil end
  local scale = T:GetScale() or 1
  for i, s in ipairs(self.slots) do
    list[i] = { mob = s.mob, macro = buildMacro(s.mob.name), x = left + s.x, y = top - s.y,
      w = s.w, h = s.h, scale = scale, tracker = T }
  end
  return list
end

local function signature(list)
  local parts = {}
  for i, w in ipairs(list) do
    parts[i] = string.format("%s|%.1f|%.1f|%.1f|%.1f|%.3f", w.macro, w.x, w.y, w.w, w.h, w.scale)
  end
  return table.concat(parts, "\n")
end

local function markStale(stale)
  MobPanel.pending = stale and true or false
  for _, row in ipairs(MobPanel.rows) do row.highlight:SetAlpha(stale and 0 or 1) end
end

-- Pose les boutons sur les lignes voulues (hors combat) ; en combat, les marque seulement « en
-- attente » si elles ont changé.
function MobPanel:Apply()
  local list = wanted(self)
  if not list then
    -- rectangle du suivi pas encore calculé (juste après sa création) : nouvel essai à l'image suivante
    if not self.retryPending then
      self.retryPending = true
      Q:After(0, function()
        MobPanel.retryPending = false
        MobPanel:Apply()
      end)
    end
    return
  end
  local auto = autoMacro(self)
  local sig = signature(list) .. "\n#auto\n" .. auto
  if inCombat() then
    if sig ~= self.appliedSig then
      markStale(true)
    elseif not self.pending then
      for i, w in ipairs(list) do self.rows[i].mob = w.mob end   -- même ligne, même monstre : infos à jour
    end
    return
  end
  for i, w in ipairs(list) do
    local row = self.rows[i] or createRow(i)
    if row:GetAttribute("macrotext") ~= w.macro then row:SetAttribute("macrotext", w.macro) end
    row:SetScale(w.scale)
    local k = w.tracker:GetEffectiveScale() / row:GetEffectiveScale()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", w.x * k, w.y * k)
    row:SetSize(w.w, w.h)
    row.mob = w.mob
    row:Show()
  end
  for i = #list + 1, #self.rows do
    self.rows[i].mob = nil
    self.rows[i]:Hide()
  end
  if #list == 0 then self:HideModel() end
  local b = autoButton()
  if b:GetAttribute("macrotext") ~= auto then b:SetAttribute("macrotext", auto) end
  self.appliedSig = sig
  markStale(false)
end

-- Appelé par le suivi après chaque mise en page : slots = { { mob, x, y, w, h } }, position de
-- chaque ligne de monstre depuis le coin haut gauche du suivi, dans son échelle.
function MobPanel:Attach(slots)
  self.slots = type(slots) == "table" and slots or {}
  self:Apply()
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if MobPanel.pending then MobPanel:Apply() end
end)
Q:On("LOGIN", function()
  if not inCombat() then autoButton() end   -- le raccourci trouve son bouton dès la connexion
  bindingHint()
end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "tracker.autoTarget" then bindingHint() end
end)
