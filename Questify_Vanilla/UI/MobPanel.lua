local addonName, Q = ...

-- Liste des monstres d'objectif sous le suivi (spec § 5.5).
-- Chaque ligne est un bouton sécurisé (SecureActionButtonTemplate, type « macro ») : un clic
-- cible le monstre le plus proche du nom indiqué et pose un crâne (/tm !8). SetRaidTarget et
-- TargetUnit sont protégées : on ne les appelle jamais.
-- Règle du combat : aucun attribut, aucune ancre, aucune taille et aucun affichage de ces
-- boutons (ni de leur cadre parent) ne change pendant InCombatLockdown(). La liste est alors
-- marquée « en attente » et reconstruite sur PLAYER_REGEN_ENABLED ; seuls les textes de
-- progression des lignes déjà affichées suivent en combat.
-- Le cadre n'est jamais ancré au suivi : il est placé sur l'écran sous celui-ci, hors combat,
-- pour que le suivi reste un cadre normal (redimensionnable en combat).
Q.UI = Q.UI or {}
local MobPanel = { rows = {}, pending = false }
Q.UI.MobPanel = MobPanel

local L = Q.L

local MAX_ROWS = 6
local WIDTH = 260
local ROW_H = 30
local HEADER = 22
local MODEL_SIZE = 160
local MODEL_CHECK_DELAY = 0.3
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local SKULL_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"

local MOB_COLOR = "|cffff6060"
local DONE_COLOR = "|cff808080"
local LEVEL_COLOR = "|cffaaaaaa"

local function setting(path) return Q.Settings:Get(path) end
local function inCombat() return InCombatLockdown and InCombatLockdown() end

-- Macro du bouton : la seule façon autorisée de cibler et de marquer.
local function buildMacro(name)
  return "/cleartarget\n/targetexact " .. name .. "\n/tm !8"
end
MobPanel.BuildMacro = function(_, name) return buildMacro(name) end

---------------------------------------------------------------------------
-- Données
---------------------------------------------------------------------------
local function cleanName(name)
  if type(name) ~= "string" then return nil end
  name = name:gsub("[\r\n]", " ")
  if name == "" or name:sub(1, 1) == "#" then return nil end   -- nom inconnu : inutile à cibler
  return name
end

-- Copie d'une ligne de Q.Targets:ObjectiveMobs() : ces lignes sont partagées (cache du moteur),
-- on ne les modifie jamais.
local function copyMob(src, name)
  local mob = {}
  for k, v in pairs(src) do mob[k] = v end
  mob.name = name
  return mob
end

-- Monstres d'objectif : non terminés d'abord (ordre d'origine conservé), 6 au plus.
local function collectMobs()
  if not (Q.QDB and Q.QDB:IsAvailable() and Q.Progress:IsEnabled()) then return {} end
  local todo, done = {}, {}
  for _, src in ipairs(Q.Targets:ObjectiveMobs()) do
    local name = cleanName(src.name)
    if name then
      local mob = copyMob(src, name)
      if mob.done then done[#done + 1] = mob else todo[#todo + 1] = mob end
    end
  end
  local out = {}
  for _, list in ipairs({ todo, done }) do
    for _, mob in ipairs(list) do
      if #out >= MAX_ROWS then return out end
      out[#out + 1] = mob
    end
  end
  return out
end

local function levelText(mob)
  local lo, hi = mob.minLevel, mob.maxLevel
  if not lo and not hi then return "" end
  local range
  if lo and hi and lo ~= hi then range = lo .. "-" .. hi else range = tostring(lo or hi) end
  return string.format(L.UI_MOB_LEVEL, range)
end

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
  local holder = CreateFrame("Frame", "QuestifyVanillaMobModelHolder", UIParent, "BackdropTemplate")
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
  local model = CreateFrame("PlayerModel", "QuestifyVanillaMobModel", holder)
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
-- Cadre et lignes
---------------------------------------------------------------------------
function MobPanel:Create()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", "QuestifyVanillaMobPanel", UIParent, "BackdropTemplate")
  self.frame = f
  f:SetSize(WIDTH, HEADER + ROW_H)
  f:SetFrameStrata("LOW")
  f:SetClampedToScreen(true)
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.55)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
  end
  local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  header:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -7)
  header:SetText(L.UI_MOBS_TITLE)
  self.header = header
  local wait = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  wait:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -7)
  wait:SetText("")
  self.waitText = wait
  f:Hide()
  return f
end

local function createRow(i)
  local f = MobPanel.frame
  local row = CreateFrame("Button", "QuestifyVanillaMobRow" .. i, f, "SecureActionButtonTemplate")
  row:SetSize(WIDTH - 12, ROW_H)
  row:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -(HEADER + (i - 1) * ROW_H))
  row:RegisterForClicks("AnyUp", "AnyDown")
  row:SetAttribute("type", "macro")
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

  local skull = row:CreateTexture(nil, "ARTWORK")
  skull:SetTexture(SKULL_ICON)
  skull:SetSize(14, 14)
  skull:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
  local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  name:SetPoint("TOPLEFT", skull, "TOPRIGHT", 4, 0)
  name:SetJustifyH("LEFT")
  name:SetWordWrap(false)
  name:SetWidth(WIDTH - 12 - 24 - 70)
  local level = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  level:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -3)
  level:SetJustifyH("RIGHT")
  local objective = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  objective:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
  objective:SetWidth(WIDTH - 12 - 24)
  objective:SetJustifyH("LEFT")
  objective:SetWordWrap(false)
  row.skull, row.name, row.level, row.objective = skull, name, level, objective

  -- Scripts non sécurisés de survol seulement : le clic reste celui du modèle sécurisé.
  row:SetScript("OnEnter", function(self) Q.SafeCall(MobPanel.ShowModel, MobPanel, self) end)
  row:SetScript("OnLeave", function() Q.SafeCall(MobPanel.HideModel, MobPanel) end)
  row:Hide()
  MobPanel.rows[i] = row
  return row
end

local function setRowTexts(row, mob)
  local done = mob.done
  row.name:SetText((done and DONE_COLOR or MOB_COLOR) .. mob.name .. "|r")
  local lvl = levelText(mob)
  row.level:SetText(lvl ~= "" and (LEVEL_COLOR .. lvl .. "|r") or "")
  row.objective:SetText(done and (DONE_COLOR .. L.UI_MOB_DONE .. "|r") or objectiveText(mob))
  row.skull:SetDesaturated(done and true or false)
  row.skull:SetAlpha(done and 0.5 or 1)
end

-- En combat : seuls les textes des lignes affichées suivent (même monstre, même macro).
function MobPanel:UpdateTexts()
  local byNpc = {}
  for _, mob in ipairs(Q.Targets:ObjectiveMobs()) do
    if not byNpc[mob.npcId] then byNpc[mob.npcId] = mob end
  end
  for _, row in ipairs(self.rows) do
    if row:IsShown() and row.mob then
      local fresh = byNpc[row.mob.npcId]
      local mob
      if fresh then
        mob = copyMob(fresh, row.mob.name)   -- même nom : la macro du bouton ne change pas
      else
        mob = copyMob(row.mob, row.mob.name)
        mob.done = true                       -- plus dans les objectifs : affichée comme terminée
      end
      row.mob = mob
      setRowTexts(row, mob)
    end
  end
  if self.waitText then self.waitText:SetText(self.pending and L.UI_MOB_PENDING or "") end
end

-- Place la liste sous le suivi, par coordonnées d'écran (hors combat seulement).
function MobPanel:Reposition()
  local f = self.frame
  if not f then return end
  if inCombat() then
    self.pending = true
    return
  end
  f:SetScale(tonumber(setting("tracker.scale")) or 1)
  f:ClearAllPoints()
  local T = Q.UI.Tracker and Q.UI.Tracker.frame
  local left, bottom
  if T and T:IsShown() then left, bottom = T:GetLeft(), T:GetBottom() end
  if left and bottom then
    local k = T:GetEffectiveScale() / f:GetEffectiveScale()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * k, bottom * k - 4)
  else
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -420)
    -- rectangle du suivi pas encore calculé (juste après sa création) : nouvel essai à l'image suivante
    if T and T:IsShown() and not self.retryPending then
      self.retryPending = true
      Q:After(0, function()
        MobPanel.retryPending = false
        local l, b = T:GetLeft(), T:GetBottom()
        if l and b then MobPanel:Reposition() end
      end)
    end
  end
end

function MobPanel:Refresh()
  local f = self.frame
  if not f then return end
  if inCombat() then
    self.pending = true
    self:UpdateTexts()
    return
  end
  self.pending = false
  self.waitText:SetText("")
  local mobs = {}
  if setting("tracker.showMobs") ~= false then mobs = collectMobs() end
  if #mobs == 0 then
    for _, row in ipairs(self.rows) do
      row.mob = nil
      row:Hide()
    end
    f:Hide()
    self:HideModel()
    return
  end
  for i, mob in ipairs(mobs) do
    local row = self.rows[i] or createRow(i)
    local macro = buildMacro(mob.name)
    if row:GetAttribute("macrotext") ~= macro then row:SetAttribute("macrotext", macro) end
    row.mob = mob
    setRowTexts(row, mob)
    row:Show()
  end
  for i = #mobs + 1, #self.rows do
    self.rows[i].mob = nil
    self.rows[i]:Hide()
  end
  f:SetHeight(HEADER + #mobs * ROW_H + 6)
  f:Show()
  self:Reposition()
end

---------------------------------------------------------------------------
-- Messages et évènements
---------------------------------------------------------------------------
local function refresh() MobPanel:Refresh() end

Q:On("LOGIN", function()
  MobPanel:Create()
  MobPanel:Refresh()
end)
Q:On("PROGRESS_UPDATED", refresh)
Q:On("STEP_CHANGED", refresh)
Q:On("GUIDE_CHANGED", refresh)
Q:On("SETTINGS_CHANGED", function(path)
  if type(path) == "string" and path:sub(1, 8) == "tracker." then refresh() end
end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if MobPanel.pending then MobPanel:Refresh() end
end)
