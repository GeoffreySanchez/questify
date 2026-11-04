local addonName, Q = ...

-- Suivi sous la minimap (spec § 5.8) :
--   en-tête : titre du chapitre, niveaux, barre de progression « faites/total » ;
--   alerte de quête de classe (lueur pulsée) quand une chaîne devient disponible ;
--   alerte de donjon conseillé (Engine/Dungeons.lua), clic = fenêtre du donjon ;
--   étape courante en gros : icône d'action, texte coloré, distance (mise à jour toutes les 0,5 s),
--   et sous chaque ligne d'objectif les monstres à tuer (crâne, nom, niveau) ;
--   les étapes suivantes en petit et en gris.
-- Mode zone (Engine/ZoneMode.lua) : l'étape qui porte la zone est remplacée par la zone (pastille
-- verte). Hors de la zone : « Zone : <nom> — N objectifs (Q quêtes) » et les quêtes concernées ;
-- dedans : tous les objectifs de la zone groupés par priorité (objets, élites et nommés,
-- monstres), chacun avec son avancement, les monstres sous forme de lignes ciblables (nommés
-- d'abord). Les étapes regroupées dans la zone ne sont pas répétées dans les étapes suivantes.
-- Confort de jeu (Engine/XPRate, Hearth, Danger, Supplies) : ligne XP/h sous la barre, XP restante
-- du chapitre dans la barre, lignes de la pierre de foyer sous l'étape, avertissements (danger,
-- sacs, réparation) sous l'étape courante. Chaque module est lu sous pcall : absent ou en erreur,
-- il n'affiche rien.
-- Le clic sur un monstre passe par les boutons sécurisés d'UI/MobPanel.lua, posés par-dessus ses
-- lignes sans s'ancrer au suivi : un enfant sécurisé rendrait le suivi protégé (impossible à
-- redimensionner en combat). Ici, les lignes de monstres ne sont que du texte et des textures.
Q.UI = Q.UI or {}
local Tracker = {}
Q.UI.Tracker = Tracker

local L = Q.L

local WIDTH = 260           -- largeur par défaut (réglage tracker.width, poignée en bas à droite)
local MIN_WIDTH, MAX_WIDTH = 220, 480
local PAD = 8
local ICON = 22             -- icône de l'action courante
local ICON_COL = 38         -- colonne de l'icône et de la distance
local NEXT_HEIGHT = 15
local MAX_NEXT = 10
local DIST_INTERVAL = 0.5   -- secondes entre deux calculs de distance
local TARGET_INTERVAL = 2   -- secondes entre deux recherches du point le plus proche

local XP_LINE_H = 13        -- ligne XP/h sous la barre
local WARN_LINE_H = 14      -- avertissements de confort sous l'étape courante
local MAX_WARN = 4

local MOB_ROW_H = 16
local MOB_INDENT = 10       -- retrait des lignes de monstres sous leur objectif
local MOB_LEVEL_W = 62
local SKULL_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"

local REASON_COLOR = "|cffff5555"
local ZONE_ICON = "Interface\\COMMON\\Indicator-Green"   -- pastille verte du mode zone
local ZONE_COLOR = "|cff40e050"
local ZONE_GROUP_COLOR = "|cffffd100"
local ZONE_LEAD_COLOR = "|cffffffff"      -- objectif suivi par la flèche
local ZONE_TODO_COLOR = "|cffc8c8c8"
local ZONE_NOTE_COLOR = "|cff999999"
local ZONE_QUEST_COLOR = "|cffffd100"
Tracker.ZONE_ICON = ZONE_ICON
local MOB_COLOR = "|cffff6060"
local MOB_DONE_COLOR = "|cff808080"
local LEVEL_COLOR = "|cffaaaaaa"

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function setting(path) return Q.Settings:Get(path) end

-- Largeur courante : celle de la poignée pendant un redimensionnement, sinon le réglage.
local function curWidth()
  local w = Tracker.liveWidth or tonumber(setting("tracker.width")) or WIDTH
  return math.max(MIN_WIDTH, math.min(MAX_WIDTH, w))
end
-- Largeur du texte de l'étape courante.
local function textWidth() return curWidth() - 2 * PAD - ICON_COL - 2 end
Tracker.Width = function() return curWidth() end

local function qdbStatus()
  if not Q.QDB then return "missing" end
  if Q.QDB.Status then return Q.QDB:Status() end
  return Q.QDB:IsAvailable() and "ok" or "missing"
end

-- Rapport entre l'échelle du suivi et celle d'UIParent (les décalages d'ancre sont exprimés
-- dans l'échelle du cadre lui-même).
local function scaleRatio(f)
  local ui = UIParent and UIParent:GetEffectiveScale() or 1
  local own = f:GetEffectiveScale() or 1
  if not ui or ui == 0 or not own or own == 0 then return 1 end
  return own / ui
end

-- Position :
--   settings.tracker.point = { point, relativePoint, x, y } par rapport à UIParent, x et y en
--   unités d'UIParent (indépendants de la taille du suivi) ;
--   sinon à gauche du suivi d'objectifs de Blizzard (placé sous la minimap) ;
--   sinon sous la minimap.
local function applyPosition(f)
  f:ClearAllPoints()
  local p = setting("tracker.point")
  if type(p) == "table" and type(p[1]) == "string" then
    local k = scaleRatio(f)
    f:SetPoint(p[1], UIParent, type(p[2]) == "string" and p[2] or p[1], (tonumber(p[3]) or 0) / k,
      (tonumber(p[4]) or 0) / k)
  elseif ObjectiveTrackerFrame then
    f:SetPoint("TOPRIGHT", ObjectiveTrackerFrame, "TOPLEFT", -8, 0)
  elseif MinimapCluster then
    f:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", 0, -10)
  else
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -240)
  end
end

local function showTooltip(owner, lines)
  if not GameTooltip then return end
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:ClearLines()
  for i, line in ipairs(lines) do
    if i == 1 then
      GameTooltip:AddLine(line, 1, 0.82, 0, true)
    else
      GameTooltip:AddLine(line, 1, 1, 1, true)
    end
  end
  GameTooltip:Show()
end

local function hideTooltip()
  if GameTooltip then GameTooltip:Hide() end
end

-- Appel protégé d'un module de confort (Q.XPRate, Q.Hearth, Q.Danger, Q.Supplies) : nil si le
-- module ou la méthode manque, ou en cas d'erreur (signalée une fois).
local function comfort(module, method, ...)
  local m = Q[module]
  local fn = type(m) == "table" and m[method]
  if type(fn) ~= "function" then return nil end
  local ok, res = pcall(fn, m, ...)
  if not ok then
    Q:ReportError(res)
    return nil
  end
  return res
end
Tracker.Comfort = comfort

---------------------------------------------------------------------------
-- Actions de la souris sur l'étape courante
---------------------------------------------------------------------------
local MANUAL_DONE = { note = true, ["goto"] = true }

local function onCurrentClick(button)
  local cur = Q.Progress:Current()
  if button == "RightButton" then
    if IsShiftKeyDown and IsShiftKeyDown() then
      Q.Progress:Back()
    elseif cur then
      Q.Progress:Skip(cur.key)
    end
  elseif button == "LeftButton" and cur and MANUAL_DONE[cur.step.action] then
    Q.Progress:MarkDone(cur.key)
  end
end

local function currentTooltip(owner)
  local lines = {}
  local cur = Tracker.entry
  if cur then
    lines[#lines + 1] = Q.Format:StepTitle(cur)
    if MANUAL_DONE[cur.step.action] then lines[#lines + 1] = L.UI_TRACKER_HINT_DONE end
  end
  lines[#lines + 1] = L.UI_TRACKER_HINT_SKIP
  lines[#lines + 1] = L.UI_TRACKER_HINT_BACK
  if not setting("tracker.locked") then lines[#lines + 1] = L.UI_TRACKER_HINT_MOVE end
  showTooltip(owner, lines)
end

---------------------------------------------------------------------------
-- Déplacement
---------------------------------------------------------------------------
local function startMoving()
  local f = Tracker.frame
  if not f or setting("tracker.locked") then return end
  Tracker.moving = true
  f:StartMoving()
end

-- Coin haut gauche en unités d'UIParent : la position ne dépend ni de l'ancre d'origine ni de
-- la taille du suivi, et survit au /reload.
local function saveTopLeft(f)
  local left, top = f:GetLeft(), f:GetTop()
  if not (left and top) then return end
  local k = scaleRatio(f)
  Q.Settings:Set("tracker.point", { "TOPLEFT", "BOTTOMLEFT", Q.Util.Round(left * k, 1), Q.Util.Round(top * k, 1) })
end

local function stopMoving()
  local f = Tracker.frame
  if not f then return end
  local wasMoving = Tracker.moving
  Tracker.moving = false
  f:StopMovingOrSizing()
  if setting("tracker.locked") and not wasMoving then return end
  saveTopLeft(f)
end

---------------------------------------------------------------------------
-- Redimensionnement (poignée en bas à droite) : largeur seulement, le texte se réorganise
---------------------------------------------------------------------------
local function cursorX(f)
  local x = GetCursorPosition and GetCursorPosition() or 0
  return x / (f:GetEffectiveScale() or 1)
end

local function startSizing()
  local f = Tracker.frame
  if not f or setting("tracker.locked") then return end
  -- le coin haut gauche est fixé d'abord : la largeur grandit vers la droite
  saveTopLeft(f)
  Tracker.sizing = { x = cursorX(f), w = curWidth() }
  Tracker.liveWidth = curWidth()
end

local function updateSizing()
  local sz, f = Tracker.sizing, Tracker.frame
  if not sz or not f then return end
  local w = math.max(MIN_WIDTH, math.min(MAX_WIDTH, sz.w + cursorX(f) - sz.x))
  if math.abs(w - (Tracker.liveWidth or 0)) >= 1 then
    Tracker.liveWidth = w
    Tracker:Refresh()
  end
end

local function stopSizing()
  if not Tracker.sizing then return end
  local w = Q.Util.Round(curWidth(), 0)
  Tracker.sizing = nil
  Tracker.liveWidth = nil
  Q.Settings:Set("tracker.width", w)
end
Tracker.StartSizing, Tracker.UpdateSizing, Tracker.StopSizing = startSizing, updateSizing, stopSizing

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
local function newNextLine(f)
  local line = {}
  line.icon = f:CreateTexture(nil, "ARTWORK")
  line.icon:SetSize(12, 12)
  line.text = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  line.text:SetJustifyH("LEFT")
  line.text:SetWordWrap(false)
  line.icon:Hide()
  line.text:Hide()
  return line
end

function Tracker:Create()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", "QuestifyVanillaTracker", UIParent, "BackdropTemplate")
  self.frame = f
  f:SetSize(curWidth(), 60)
  f:SetFrameStrata("LOW")
  f:SetClampedToScreen(true)
  if f.SetDontSavePosition then f:SetDontSavePosition(true) end
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
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() Q.SafeCall(startMoving) end)
  f:SetScript("OnDragStop", function() Q.SafeCall(stopMoving) end)

  -- Message seul (QuestieDB absent, aucun chapitre)
  local msg = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  msg:SetPoint("TOPLEFT", PAD, -PAD)
  msg:SetJustifyH("LEFT")
  msg:Hide()
  self.message = msg

  -- En-tête
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", PAD, -PAD)
  title:SetJustifyH("LEFT")
  title:SetWordWrap(false)
  self.title = title

  local levels = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  levels:SetPoint("TOPRIGHT", -PAD, -PAD - 1)
  levels:SetJustifyH("RIGHT")
  self.levels = levels

  local bar = CreateFrame("StatusBar", nil, f)
  bar:SetHeight(12)
  bar:SetPoint("TOPLEFT", PAD, -PAD - 18)
  bar:SetPoint("TOPRIGHT", -PAD, -PAD - 18)
  bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  bar:SetStatusBarColor(0.26, 0.56, 0.95)
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(0)
  local barBg = bar:CreateTexture(nil, "BACKGROUND")
  barBg:SetAllPoints(bar)
  barBg:SetColorTexture(0, 0, 0, 0.5)
  local barText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  barText:SetPoint("CENTER", bar, "CENTER", 0, 0)
  self.bar, self.barText = bar, barText

  -- XP/h et temps avant le prochain niveau (Engine/XPRate.lua)
  local xpLine = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  xpLine:SetJustifyH("LEFT")
  xpLine:SetWordWrap(false)
  xpLine:SetTextColor(0.75, 0.85, 1)
  xpLine:Hide()
  self.xpLine = xpLine

  -- Avertissements de confort (danger, sacs, réparation), créés à la demande
  self.warnLines = {}

  -- Alerte de quête de classe
  local alert = CreateFrame("Button", nil, f)
  alert:SetHeight(20)
  alert:RegisterForClicks("LeftButtonUp")
  local glow = alert:CreateTexture(nil, "BACKGROUND")
  glow:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(1, 0.82, 0)
  glow:SetAllPoints(alert)
  local pulse = glow:CreateAnimationGroup()
  pulse:SetLooping("BOUNCE")
  local fade = pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(0.15)
  fade:SetToAlpha(0.9)
  fade:SetDuration(0.8)
  local alertIcon = alert:CreateTexture(nil, "ARTWORK")
  alertIcon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
  alertIcon:SetSize(16, 16)
  alertIcon:SetPoint("LEFT", alert, "LEFT", 2, 0)
  local alertText = alert:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  alertText:SetPoint("LEFT", alertIcon, "RIGHT", 4, 0)
  alertText:SetPoint("RIGHT", alert, "RIGHT", -2, 0)
  alertText:SetJustifyH("LEFT")
  alertText:SetWordWrap(false)
  alert:SetScript("OnClick", function() Q.SafeCall(function() Tracker:OpenAlert() end) end)
  alert:SetScript("OnEnter", function(btn) Q.SafeCall(showTooltip, btn, { alertText:GetText() or "", L.UI_CLASS_ALERT_HINT }) end)
  alert:SetScript("OnLeave", hideTooltip)
  alert:Hide()
  self.alert, self.alertText, self.alertPulse, self.alertGlow = alert, alertText, pulse, glow

  -- Alerte de donjon conseillé (Engine/Dungeons.lua) : clic = fenêtre du donjon
  local dg = CreateFrame("Button", nil, f)
  dg:SetHeight(20)
  dg:RegisterForClicks("LeftButtonUp")
  local dgGlow = dg:CreateTexture(nil, "BACKGROUND")
  dgGlow:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  dgGlow:SetBlendMode("ADD")
  dgGlow:SetVertexColor(1, 0.5, 0.2)
  dgGlow:SetAllPoints(dg)
  local dgPulse = dgGlow:CreateAnimationGroup()
  dgPulse:SetLooping("BOUNCE")
  local dgFade = dgPulse:CreateAnimation("Alpha")
  dgFade:SetFromAlpha(0.15)
  dgFade:SetToAlpha(0.9)
  dgFade:SetDuration(0.8)
  local dgIcon = dg:CreateTexture(nil, "ARTWORK")
  dgIcon:SetTexture("Interface\\Icons\\INV_Misc_Bone_HumanSkull_01")
  dgIcon:SetSize(16, 16)
  dgIcon:SetPoint("LEFT", dg, "LEFT", 2, 0)
  local dgText = dg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  dgText:SetPoint("LEFT", dgIcon, "RIGHT", 4, 0)
  dgText:SetPoint("RIGHT", dg, "RIGHT", -2, 0)
  dgText:SetJustifyH("LEFT")
  dgText:SetWordWrap(false)
  dgText:SetTextColor(1, 0.7, 0.4)
  dg:SetScript("OnClick", function() Q.SafeCall(function() Tracker:OpenDungeonAlert() end) end)
  dg:SetScript("OnEnter", function(btn) Q.SafeCall(showTooltip, btn, { dgText:GetText() or "", L.DUNGEON_ALERT_HINT }) end)
  dg:SetScript("OnLeave", hideTooltip)
  dg:Hide()
  self.dungeonAlert, self.dungeonText, self.dungeonPulse = dg, dgText, dgPulse

  -- Alerte du maître de classe (nouveaux sorts) : clic = étape vers le plus proche
  local tr = CreateFrame("Button", nil, f)
  tr:SetHeight(20)
  tr:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local trGlow = tr:CreateTexture(nil, "BACKGROUND")
  trGlow:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  trGlow:SetBlendMode("ADD")
  trGlow:SetVertexColor(0.4, 0.8, 1)
  trGlow:SetAllPoints(tr)
  local trPulse = trGlow:CreateAnimationGroup()
  trPulse:SetLooping("BOUNCE")
  local trFade = trPulse:CreateAnimation("Alpha")
  trFade:SetFromAlpha(0.15)
  trFade:SetToAlpha(0.9)
  trFade:SetDuration(0.8)
  local trIcon = tr:CreateTexture(nil, "ARTWORK")
  trIcon:SetTexture(Q.Format:ActionIcon("train"))
  trIcon:SetSize(16, 16)
  trIcon:SetPoint("LEFT", tr, "LEFT", 2, 0)
  local trText = tr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  trText:SetPoint("LEFT", trIcon, "RIGHT", 4, 0)
  trText:SetPoint("RIGHT", tr, "RIGHT", -2, 0)
  trText:SetJustifyH("LEFT")
  trText:SetWordWrap(false)
  trText:SetTextColor(0.5, 0.85, 1)
  tr:SetScript("OnClick", function(_, button)
    Q.SafeCall(function()
      if button == "RightButton" then Q.Trainer:Snooze() else Q.Trainer:Go() end
    end)
  end)
  tr:SetScript("OnEnter", function(btn) Q.SafeCall(Tracker.TrainerTooltip, Tracker, btn) end)
  tr:SetScript("OnLeave", hideTooltip)
  tr:Hide()
  self.trainerAlert, self.trainerText, self.trainerPulse = tr, trText, trPulse

  -- Alerte des talents (point à dépenser, talent conseillé) : clic = fenêtre des talents
  local ta = CreateFrame("Button", nil, f)
  ta:SetHeight(20)
  ta:RegisterForClicks("LeftButtonUp")
  local taGlow = ta:CreateTexture(nil, "BACKGROUND")
  taGlow:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  taGlow:SetBlendMode("ADD")
  taGlow:SetVertexColor(0.3, 1, 0.4)
  taGlow:SetAllPoints(ta)
  local taPulse = taGlow:CreateAnimationGroup()
  taPulse:SetLooping("BOUNCE")
  local taFade = taPulse:CreateAnimation("Alpha")
  taFade:SetFromAlpha(0.15)
  taFade:SetToAlpha(0.9)
  taFade:SetDuration(0.8)
  local taIcon = ta:CreateTexture(nil, "ARTWORK")
  taIcon:SetSize(16, 16)
  taIcon:SetPoint("LEFT", ta, "LEFT", 2, 0)
  local taText = ta:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  taText:SetPoint("LEFT", taIcon, "RIGHT", 4, 0)
  taText:SetPoint("RIGHT", ta, "RIGHT", -2, 0)
  taText:SetJustifyH("LEFT")
  taText:SetWordWrap(false)
  taText:SetTextColor(0.45, 1, 0.5)
  ta:SetScript("OnClick", function() Q.SafeCall(function() Q.Talents:OpenFrame() end) end)
  ta:SetScript("OnEnter", function(btn) Q.SafeCall(Tracker.TalentTooltip, Tracker, btn) end)
  ta:SetScript("OnLeave", hideTooltip)
  ta:Hide()
  self.talentAlert, self.talentText, self.talentIcon, self.talentPulse = ta, taText, taIcon, taPulse

  -- Étape courante
  local cur = CreateFrame("Button", nil, f)
  cur:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  cur:RegisterForDrag("LeftButton")
  cur:SetScript("OnDragStart", function() Q.SafeCall(startMoving) end)
  cur:SetScript("OnDragStop", function() Q.SafeCall(stopMoving) end)
  cur:SetScript("OnClick", function(_, button) Q.SafeCall(onCurrentClick, button) end)
  cur:SetScript("OnEnter", function(btn) Q.SafeCall(currentTooltip, btn) end)
  cur:SetScript("OnLeave", hideTooltip)
  local icon = cur:CreateTexture(nil, "ARTWORK")
  icon:SetSize(ICON, ICON)
  icon:SetPoint("TOP", cur, "TOPLEFT", ICON_COL / 2, 0)
  local dist = cur:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  dist:SetPoint("TOP", icon, "BOTTOM", 0, -2)
  dist:SetWidth(ICON_COL + 4)
  dist:SetJustifyH("CENTER")
  dist:SetWordWrap(false)
  self.current, self.currentIcon, self.distance = cur, icon, dist
  -- Texte de l'étape en morceaux, entrecoupés des lignes de monstres : le premier morceau
  -- (titre et premiers objectifs) est currentText.
  self.textChunks, self.mobRows, self.mobSlots = {}, {}, {}
  self.currentText = self:TextChunk(1)

  self.nextLines = {}
  for i = 1, MAX_NEXT do self.nextLines[i] = newNextLine(f) end

  -- Poignée de redimensionnement (cachée quand le suivi est verrouillé)
  local grip = CreateFrame("Button", nil, f)
  grip:SetSize(16, 16)
  grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  grip:SetFrameLevel((f:GetFrameLevel() or 1) + 5)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then Q.SafeCall(startSizing) end
  end)
  grip:SetScript("OnMouseUp", function() Q.SafeCall(stopSizing) end)
  grip:SetScript("OnUpdate", function() if Tracker.sizing then Q.SafeCall(updateSizing) end end)
  grip:SetScript("OnEnter", function(btn) Q.SafeCall(showTooltip, btn, { L.UI_TRACKER_HINT_RESIZE }) end)
  grip:SetScript("OnLeave", hideTooltip)
  self.grip = grip

  -- Distance toutes les 0,5 s, recherche du point le plus proche toutes les 2 s.
  local sinceDist, sinceTarget = 0, 0
  f:SetScript("OnUpdate", function(_, elapsed)
    -- pendant un déplacement, la liste des monstres suit le suivi
    if Tracker.moving then Q.SafeCall(Tracker.AfterLayout, Tracker) end
    sinceDist = sinceDist + (elapsed or 0)
    sinceTarget = sinceTarget + (elapsed or 0)
    if sinceDist < DIST_INTERVAL then return end
    sinceDist = 0
    local retarget = sinceTarget >= TARGET_INTERVAL
    if retarget then sinceTarget = 0 end
    Q.SafeCall(function() Tracker:UpdateDistance(retarget) end)
  end)

  applyPosition(f)
  return f
end

-- Morceau de texte de l'étape courante (créé à la demande).
function Tracker:TextChunk(i)
  local chunk = self.textChunks[i]
  if chunk then return chunk end
  chunk = self.current:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  chunk:SetJustifyH("LEFT")
  chunk:SetJustifyV("TOP")
  chunk:SetWordWrap(true)
  chunk:Hide()
  self.textChunks[i] = chunk
  return chunk
end

-- Ligne de monstre sous un objectif : crâne, nom, niveau (créée à la demande).
function Tracker:MobRow(i)
  local row = self.mobRows[i]
  if row then return row end
  local cur = self.current
  row = {}
  row.skull = cur:CreateTexture(nil, "ARTWORK")
  row.skull:SetTexture(SKULL_ICON)
  row.skull:SetSize(12, 12)
  row.name = cur:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.name:SetJustifyH("LEFT")
  row.name:SetWordWrap(false)
  row.level = cur:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  row.level:SetJustifyH("RIGHT")
  row.level:SetWordWrap(false)
  row.level:SetWidth(MOB_LEVEL_W)
  row.skull:Hide(); row.name:Hide(); row.level:Hide()
  self.mobRows[i] = row
  return row
end

---------------------------------------------------------------------------
-- Distance
---------------------------------------------------------------------------
function Tracker:UpdateDistance(retarget)
  if not self.frame then return end
  local entry = self.entry
  if retarget and entry then self.target = Q.Targets:ForEntry(entry) end
  local tg = self.target
  local text = ""
  if entry and tg and tg.mapId then
    local d = Q.Maps:DistanceFromPlayer(tg.mapId, tg.x, tg.y)
    if d then text = Q.Util.FormatDistance(d) end
  end
  self.distance:SetText(text)
end

---------------------------------------------------------------------------
-- Alerte de quête de classe
---------------------------------------------------------------------------
-- Chaînes en alerte. Alerts() peut renvoyer des chaînes ou des lignes { chain, state } :
-- on accepte les deux formes.
local function classAlerts()
  local cq = Q.ClassQuests
  if not (cq and cq.Alerts) then return {} end
  local ok, list = pcall(cq.Alerts, cq)
  if not ok then
    Q:ReportError(list)
    return {}
  end
  local out = {}
  if type(list) == "table" then
    for _, item in ipairs(list) do
      local chain = type(item) == "table" and (item.chain or item) or nil
      if type(chain) == "table" and chain.key then out[#out + 1] = chain end
    end
  end
  return out
end
Tracker.ClassAlerts = function() return classAlerts() end

-- Titre d'une chaîne dans la langue du client (nom de sa première quête), sinon son titre.
local function chainTitle(chain)
  local P = Q.UI.ClassQuestPopup
  if P and P.ChainTitle then return P.ChainTitle(chain) end
  return tostring(chain.title or chain.key or "?")
end

-- Ouvre la chaîne suivante parmi les alertes : chaque clic passe à la suivante (en boucle),
-- tant que le joueur n'a pas choisi.
function Tracker:OpenAlert()
  local list = classAlerts()
  if #list == 0 or not Q.UI.ClassQuestPopup then return end
  local index = 1
  if self.lastAlertKey then
    for i, chain in ipairs(list) do
      if chain.key == self.lastAlertKey then
        index = i % #list + 1
        break
      end
    end
  end
  local chain = list[index]
  self.lastAlertKey = chain.key
  Q.UI.ClassQuestPopup:Show(chain, index, #list)
end

---------------------------------------------------------------------------
-- Alerte de donjon conseillé
---------------------------------------------------------------------------
-- Donjons en alerte (lignes { dungeon, state } ou donjons seuls) : liste vide si le module manque,
-- échoue ou si l'option dungeonSuggest est coupée.
local function dungeonAlerts()
  local D = Q.Dungeons
  if not (D and D.Alerts) then return {} end
  local ok, list = pcall(D.Alerts, D)
  if not ok then
    Q:ReportError(list)
    return {}
  end
  local out = {}
  if type(list) == "table" then
    for _, item in ipairs(list) do
      local d = type(item) == "table" and (item.dungeon or item) or nil
      if type(d) == "table" and type(d.key) == "string" then out[#out + 1] = d end
    end
  end
  return out
end
Tracker.DungeonAlerts = function() return dungeonAlerts() end

local function dungeonName(d)
  local P = Q.UI.DungeonPopup
  if P and P.DungeonName then return P.DungeonName(d) end
  return tostring(d.name or d.key or "?")
end

-- Ouvre le donjon suivant parmi les alertes (chaque clic passe au suivant, en boucle).
function Tracker:OpenDungeonAlert()
  local list = dungeonAlerts()
  if #list == 0 or not Q.UI.DungeonPopup then return end
  local index = 1
  if self.lastDungeonKey then
    for i, d in ipairs(list) do
      if d.key == self.lastDungeonKey then
        index = i % #list + 1
        break
      end
    end
  end
  local d = list[index]
  self.lastDungeonKey = d.key
  Q.UI.DungeonPopup:Show(d, index, #list)
end

-- Place l'alerte de donjon à la hauteur y si un donjon est conseillé ; -> nouvelle hauteur.
function Tracker:LayoutDungeonAlert(y)
  local btn = self.dungeonAlert
  if not btn then return y end
  local alerts = dungeonAlerts()
  if #alerts == 0 then
    btn:Hide()
    self.dungeonPulse:Stop()
    return y
  end
  if #alerts == 1 then
    local d = alerts[1]
    self.dungeonText:SetFormattedText(L.DUNGEON_ALERT_ONE, dungeonName(d), tonumber(d.minLevel) or 1,
      tonumber(d.maxLevel) or 60)
  else
    self.dungeonText:SetFormattedText(L.DUNGEON_ALERT_MANY, #alerts)
  end
  local f = self.frame
  btn:ClearAllPoints()
  btn:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
  btn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y)
  btn:Show()
  if not self.dungeonPulse:IsPlaying() then self.dungeonPulse:Play() end
  return y + 20 + 4
end

---------------------------------------------------------------------------
-- Alerte du maître de classe
---------------------------------------------------------------------------
local MAX_TOOLTIP_SPELLS = 10

local function money(copper)
  if type(GetCoinTextureString) == "function" then return GetCoinTextureString(copper) end
  return tostring(copper)
end

function Tracker:TrainerTooltip(owner)
  local alert = Q.Trainer and Q.Trainer:Alert()
  if not alert then return end
  local lines = { self.trainerText:GetText() or "" }
  for i, name in ipairs(alert.names) do
    if i > MAX_TOOLTIP_SPELLS then
      lines[#lines + 1] = "..."
      break
    end
    lines[#lines + 1] = "- " .. name
  end
  if alert.known and alert.cost > 0 then lines[#lines + 1] = string.format(L.UI_TRAINER_COST, money(alert.cost)) end
  if alert.known and alert.missing > 0 then
    lines[#lines + 1] = string.format(L.UI_TRAINER_MISSING, alert.total - alert.count, money(alert.missing))
  end
  if not alert.known then lines[#lines + 1] = L.UI_TRAINER_HINT_MAYBE end
  lines[#lines + 1] = L.UI_TRAINER_HINT_GO
  lines[#lines + 1] = L.UI_TRAINER_HINT_SNOOZE
  showTooltip(owner, lines)
end

local TALENT_ICON = "Interface\\Icons\\Ability_Marksmanship"

function Tracker:TalentTooltip(owner)
  local alert = Q.Talents and Q.Talents:Alert()
  if not alert then return end
  local lines = { string.format(L.UI_TALENT_ALERT, alert.unspent) }
  local advice = Q.Talents:Advice(alert.next)
  if advice then
    lines[#lines + 1] = string.format(L.UI_TALENT_NEXT, advice)
  elseif not Q.Talents:Chosen() then
    lines[#lines + 1] = L.UI_TALENT_NO_PRESET
  end
  lines[#lines + 1] = L.UI_TALENT_HINT
  showTooltip(owner, lines)
end

function Tracker:LayoutTalentAlert(y)
  local alert = Q.Talents and Q.Talents:Alert()
  if not alert then
    self.talentAlert:Hide()
    self.talentPulse:Stop()
    return y
  end
  local nxt = alert.next
  if nxt and nxt.name then
    self.talentText:SetFormattedText(L.UI_TALENT_ALERT_NEXT, nxt.name)
    self.talentIcon:SetTexture(nxt.icon or TALENT_ICON)
  else
    self.talentText:SetFormattedText(L.UI_TALENT_ALERT, alert.unspent)
    self.talentIcon:SetTexture(TALENT_ICON)
  end
  local f = self.frame
  self.talentAlert:ClearAllPoints()
  self.talentAlert:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
  self.talentAlert:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y)
  self.talentAlert:Show()
  if not self.talentPulse:IsPlaying() then self.talentPulse:Play() end
  return y + 20 + 4
end

-- Place l'alerte à la hauteur y si elle doit s'afficher ; -> nouvelle hauteur.
function Tracker:LayoutTrainerAlert(y)
  local alert = Q.Trainer and Q.Trainer:Alert()
  if not alert then
    self.trainerAlert:Hide()
    self.trainerPulse:Stop()
    return y
  end
  if alert.known then
    self.trainerText:SetFormattedText(L.UI_TRAINER_ALERT, alert.count)
  else
    self.trainerText:SetText(L.UI_TRAINER_ALERT_MAYBE)
  end
  local f = self.frame
  self.trainerAlert:ClearAllPoints()
  self.trainerAlert:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
  self.trainerAlert:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y)
  self.trainerAlert:Show()
  if not self.trainerPulse:IsPlaying() then self.trainerPulse:Play() end
  return y + 20 + 4
end

---------------------------------------------------------------------------
-- Rafraîchissement
---------------------------------------------------------------------------
local function setShown(region, shown)
  if shown then region:Show() else region:Hide() end
end

-- Seul message (QuestieDB absent, aucun chapitre) : le reste du cadre est caché.
function Tracker:ShowMessage(text)
  local f = self.frame
  self.entry, self.target = nil, nil
  for _, r in ipairs({ self.title, self.levels, self.bar, self.alert, self.trainerAlert, self.talentAlert, self.current }) do r:Hide() end
  self.trainerPulse:Stop()
  self.talentPulse:Stop()
  if self.dungeonAlert then
    self.dungeonAlert:Hide()
    self.dungeonPulse:Stop()
  end
  self.mobSlots = {}
  for _, line in ipairs(self.nextLines) do line.icon:Hide(); line.text:Hide() end
  self.xpLine:Hide()
  for _, line in ipairs(self.warnLines) do line:Hide() end
  self.alertPulse:Stop()
  self.message:SetText(text)
  self.message:Show()
  f:SetHeight(PAD * 2 + (self.message:GetStringHeight() or 12))
end

local function applyLock(f)
  local locked = setting("tracker.locked") and true or false
  f:SetMovable(not locked)
  f:EnableMouse(not locked)
  if Tracker.grip then
    if locked then Tracker.grip:Hide() else Tracker.grip:Show() end
  end
end

-- Compte des étapes du chapitre (hors étapes insérées et étapes passées) : faites, total.
local function chapterProgress()
  local done, total = 0, 0
  for _, e in ipairs(Q.Progress:Entries()) do
    if e.source == "guide" then
      local s = Q.Progress:State(e)
      if s ~= "skipped" then
        total = total + 1
        if s == "done" then done = done + 1 end
      end
    end
  end
  return done, total
end

-- Morceaux de l'étape courante : { text = "..." } ou { mob = ligne de MobPanel:MobsFor }.
-- Les monstres d'un objectif suivent sa ligne ; ceux dont l'objectif n'est pas affiché viennent
-- après le dernier objectif. Notes et raison du blocage ferment la liste.
local function stepSegments(entry, mobs)
  local parts = Q.Format:StepParts(entry)
  local segs, buf = {}, { parts.head }
  local function flush()
    if #buf > 0 then segs[#segs + 1] = { text = table.concat(buf, "\n") } end
    buf = {}
  end
  local function addMobs(list)
    flush()
    for _, mob in ipairs(list) do segs[#segs + 1] = { mob = mob } end
  end
  local byIndex, placed = {}, {}
  for _, mob in ipairs(mobs) do
    local k = mob.objIndex or 0
    byIndex[k] = byIndex[k] or {}
    table.insert(byIndex[k], mob)
  end
  for _, o in ipairs(parts.objectives) do
    buf[#buf + 1] = Q.Format:ObjectiveLine(o.text)
    if byIndex[o.index] and not placed[o.index] then
      placed[o.index] = true
      addMobs(byIndex[o.index])
    end
  end
  local rest = {}
  for _, mob in ipairs(mobs) do
    if not placed[mob.objIndex or 0] then rest[#rest + 1] = mob end
  end
  if #rest > 0 then addMobs(rest) end
  for _, line in ipairs(parts.tail) do buf[#buf + 1] = line end
  local hearth = comfort("Hearth", "Lines", entry)
  if type(hearth) == "table" then
    for _, line in ipairs(hearth) do
      if type(line) == "string" then buf[#buf + 1] = line end
    end
  end
  local state, reason = Q.Progress:State(entry)
  if state == "blocked" and reason then
    buf[#buf + 1] = REASON_COLOR .. Q.Format:Reason(reason) .. "|r"
  end
  flush()
  return segs
end

---------------------------------------------------------------------------
-- Mode zone
---------------------------------------------------------------------------
-- Zone portée par l'étape courante, ou nil (option coupée, pas de zone, erreur).
local function zoneFor(cur)
  local Z = Q.ZoneMode
  if not (cur and Z and Z.Current and Z.IsOwner) then return nil end
  local ok, z = pcall(Z.Current, Z)
  if not ok or type(z) ~= "table" then return nil end
  local ok2, owner = pcall(Z.IsOwner, Z, cur)
  if ok2 and owner then return z end
  return nil
end
Tracker.ZoneFor = function(_, cur) return zoneFor(cur) end

local ZONE_GROUPS = { object = "ZONE_GROUP_OBJECTS", named = "ZONE_GROUP_NAMED", mob = "ZONE_GROUP_MOBS",
  item = "ZONE_GROUP_MOBS" }
local MAX_ZONE_ROWS = 6     -- lignes de monstres ciblables au plus (comme MobPanel), le reste en texte

local function mobName(name)
  if type(name) ~= "string" or name == "" or name:sub(1, 1) == "#" then return nil end
  return (name:gsub("[\r\n]", " "))
end

-- Morceaux de la zone (même forme que stepSegments) : titre, puis hors de la zone les quêtes
-- concernées, dedans les objectifs par priorité. Sous un monstre, l'avancement de son objectif.
local function zoneSegments(z)
  local Z = Q.ZoneMode
  local F = Q.Format
  local segs, buf = {}, { ZONE_COLOR .. Z:Headline(z) .. "|r" }
  local function flush()
    if #buf > 0 then segs[#segs + 1] = { text = table.concat(buf, "\n") } end
    buf = {}
  end
  if not z.inside then
    local seen = {}
    for _, o in ipairs(z.objectives) do
      if not seen[o.questId] then
        seen[o.questId] = true
        buf[#buf + 1] = F:ObjectiveLine(ZONE_QUEST_COLOR .. Q.QDB:QuestName(o.questId) .. "|r")
      end
    end
    buf[#buf + 1] = ZONE_NOTE_COLOR .. L.ZONE_HINT_OUTSIDE .. "|r"
    flush()
    return segs
  end
  local rows = Q.UI.MobPanel and setting("tracker.showMobs") ~= false
  -- Groupes dans l'ordre à suivre (celui de la flèche) ; dans un groupe, ordre stable (étapes puis
  -- objectifs) : les lignes ciblables ne bougent pas à chaque pas du joueur, même en combat.
  local ordered = Z:Objectives(z)
  local lead = ordered[1]
  local groupRank, list = {}, {}
  for i, o in ipairs(ordered) do
    local group = ZONE_GROUPS[o.kind] or "ZONE_GROUP_MOBS"
    if not groupRank[group] then groupRank[group] = i end
    list[i] = o
  end
  table.sort(list, function(a, b)
    local ga = groupRank[ZONE_GROUPS[a.kind] or "ZONE_GROUP_MOBS"]
    local gb = groupRank[ZONE_GROUPS[b.kind] or "ZONE_GROUP_MOBS"]
    if ga ~= gb then return ga < gb end
    return (a.seq or 0) < (b.seq or 0)
  end)
  local lastGroup
  local shownMob, shownText, nRows = {}, {}, 0
  for _, o in ipairs(list) do
    local group = ZONE_GROUPS[o.kind] or "ZONE_GROUP_MOBS"
    if group ~= lastGroup then
      lastGroup = group
      buf[#buf + 1] = ZONE_GROUP_COLOR .. L[group] .. "|r"
    end
    local color = o == lead and ZONE_LEAD_COLOR or ZONE_TODO_COLOR
    local text = Z:ProgressText(o)
    if o.blocked then
      text = text .. " (" .. string.format(L.ZONE_NEEDS, Q.QDB:ItemName(o.blocked.item)) .. ")"
    end
    local name = o.targetKind == "npc" and mobName(o.name)
    if rows and name and (shownMob[o.id] or nRows < MAX_ZONE_ROWS) then
      -- ligne ciblable (bouton sécurisé de MobPanel), une par monstre
      if not shownMob[o.id] then
        shownMob[o.id] = true
        nRows = nRows + 1
        flush()
        segs[#segs + 1] = { mob = { npcId = o.id, name = name, minLevel = o.minLevel, maxLevel = o.maxLevel,
          questId = o.questId, objIndex = o.objIndex, done = false, viaItem = o.viaItem } }
      end
      local tk = o.questId .. ":" .. o.objIndex
      if not shownText[tk] then
        shownText[tk] = true
        buf[#buf + 1] = F:ObjectiveLine(F:ObjectiveLine(color .. text .. "|r"))
      end
    else
      if o.targetKind == "object" and not o.start and not text:find(o.name, 1, true) then
        text = o.name .. " — " .. text
      elseif o.targetKind == "npc" and not o.start and not o.key and not text:find(o.name, 1, true) then
        text = o.name .. " — " .. text
      end
      buf[#buf + 1] = F:ObjectiveLine(color .. text .. "|r")
    end
  end
  flush()
  return segs
end

-- Met en page l'étape courante dans son bouton ; yTop = haut du bouton dans le suivi.
-- -> hauteur du contenu ; remplit self.mobSlots pour les boutons de ciblage.
function Tracker:LayoutCurrent(cur, yTop, zone)
  local segs
  if zone then
    -- erreur dans la zone : signalée, puis l'étape s'affiche comme d'habitude
    local ok, res = pcall(zoneSegments, zone)
    if ok then segs = res else Q:ReportError(res) end
  end
  if not segs and cur then
    local mobs = Q.UI.MobPanel and Q.UI.MobPanel:MobsFor(cur) or {}
    segs = stepSegments(cur, mobs)
  elseif not segs then
    segs = { { text = L.UI_TRACKER_DONE } }
  end
  local slots = {}
  local nText, nMob, yy = 0, 0, 0
  for _, seg in ipairs(segs) do
    if seg.text then
      nText = nText + 1
      local chunk = self:TextChunk(nText)
      chunk:SetWidth(textWidth())
      chunk:ClearAllPoints()
      chunk:SetPoint("TOPLEFT", self.current, "TOPLEFT", ICON_COL + 2, -yy)
      chunk:SetText(seg.text)
      chunk:Show()
      yy = yy + (chunk:GetStringHeight() or 14)
    else
      nMob = nMob + 1
      local mob, row = seg.mob, self:MobRow(nMob)
      local x = ICON_COL + 2 + MOB_INDENT
      row.skull:ClearAllPoints()
      row.skull:SetPoint("TOPLEFT", self.current, "TOPLEFT", x, -yy - 2)
      row.skull:SetDesaturated(mob.done and true or false)
      row.skull:SetAlpha(mob.done and 0.5 or 1)
      row.skull:Show()
      row.name:SetWidth(textWidth() - MOB_INDENT - 16 - MOB_LEVEL_W)
      row.name:ClearAllPoints()
      row.name:SetPoint("TOPLEFT", self.current, "TOPLEFT", x + 16, -yy - 2)
      row.name:SetText((mob.done and MOB_DONE_COLOR or MOB_COLOR) .. mob.name .. "|r")
      row.name:Show()
      local lvl = Q.UI.MobPanel:LevelText(mob)
      row.level:ClearAllPoints()
      row.level:SetPoint("TOPRIGHT", self.current, "TOPRIGHT", 0, -yy - 2)
      row.level:SetText(lvl ~= "" and (LEVEL_COLOR .. lvl .. "|r") or "")
      row.level:Show()
      row.mob = mob
      -- zone du bouton de ciblage, depuis le coin haut gauche du suivi
      slots[#slots + 1] = { mob = mob, x = PAD + x - 2, y = yTop + yy, w = textWidth() - MOB_INDENT + 2, h = MOB_ROW_H }
      yy = yy + MOB_ROW_H
    end
  end
  for i = nText + 1, #self.textChunks do self.textChunks[i]:Hide() end
  for i = nMob + 1, #self.mobRows do
    local row = self.mobRows[i]
    row.mob = nil
    row.skull:Hide(); row.name:Hide(); row.level:Hide()
  end
  self.mobSlots = slots
  return yy
end

---------------------------------------------------------------------------
-- Confort : ligne XP/h et avertissements
---------------------------------------------------------------------------
-- Place la ligne XP/h à la hauteur y si elle a un texte ; -> nouvelle hauteur.
function Tracker:LayoutXPLine(y)
  local text = comfort("XPRate", "Text")
  local line = self.xpLine
  if type(text) ~= "string" or text == "" then
    line:Hide()
    return y
  end
  local f = self.frame
  line:ClearAllPoints()
  line:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
  line:SetWidth(curWidth() - 2 * PAD)
  line:SetText(text)
  line:Show()
  return y + XP_LINE_H
end

-- Nouveau texte XP/h sans refaire toute la mise en page ; faux si la ligne doit apparaître ou
-- disparaître (il faut alors tout redessiner).
function Tracker:UpdateXPLine()
  local line = self.xpLine
  if not line or not self.title:IsShown() then return false end
  local text = comfort("XPRate", "Text")
  local has = type(text) == "string" and text ~= ""
  if has ~= line:IsShown() then return false end
  if has then line:SetText(text) end
  return true
end

local function warnLine(self, i)
  local line = self.warnLines[i]
  if line then return line end
  line = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  line:SetJustifyH("LEFT")
  line:SetWordWrap(false)
  line:Hide()
  self.warnLines[i] = line
  return line
end

-- Textes des avertissements : danger, puis sacs et réparation.
local function warnings()
  local out = {}
  local danger = comfort("Danger", "Line")
  if type(danger) == "string" and danger ~= "" then out[#out + 1] = danger end
  local supplies = comfort("Supplies", "Lines")
  if type(supplies) == "table" then
    for _, line in ipairs(supplies) do
      if type(line) == "string" and line ~= "" then out[#out + 1] = line end
    end
  end
  return out
end

-- Place les avertissements à la hauteur y ; -> nouvelle hauteur.
function Tracker:LayoutWarnings(y)
  local list = warnings()
  local f = self.frame
  local n = 0
  for _, text in ipairs(list) do
    if n >= MAX_WARN then break end
    n = n + 1
    local line = warnLine(self, n)
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -y)
    line:SetWidth(curWidth() - 2 * PAD - 4)
    line:SetText(text)
    line:Show()
    y = y + WARN_LINE_H
  end
  for i = n + 1, #self.warnLines do self.warnLines[i]:Hide() end
  if n > 0 then y = y + 2 end
  return y
end

function Tracker:Refresh()
  local f = self.frame
  if not f then return end
  -- Nouvelle taille : la position est réappliquée pour que le coin enregistré ne bouge pas.
  local scale = tonumber(setting("tracker.scale")) or 1
  if scale ~= self.appliedScale then
    f:SetScale(scale)
    self.appliedScale = scale
    if not self.moving then applyPosition(f) end
  end
  applyLock(f)
  local W = curWidth()
  f:SetWidth(W)
  self.message:SetWidth(W - 2 * PAD)
  self.title:SetWidth(W - 2 * PAD - 48)
  for _, line in ipairs(self.nextLines) do line.text:SetWidth(W - 2 * PAD - 16) end
  f:Show()

  local status = qdbStatus()
  if status ~= "ok" then
    self:ShowMessage(status == "old" and L.QUESTIEDB_TOO_OLD or L.NEED_QUESTIEDB)
    -- Bouton « Lien » : assistant sur la page des addons (lien CurseForge de QuestieDB à copier).
    -- L'état de QuestieDB est fixé pour la session (Q.QDB:Status en cache) : jamais caché.
    if not self.qdbLink and Q.UI.Wizard then
      local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
      b:SetSize(80, 20)
      b:SetText(L.UI_WIZ_LINK_BUTTON)
      b:SetPoint("TOPLEFT", self.message, "BOTTOMLEFT", 0, -6)
      b:SetScript("OnClick", function() Q.SafeCall(Q.UI.Wizard.Show, Q.UI.Wizard, 1) end)
      self.qdbLink = b
    end
    if self.qdbLink then f:SetHeight(f:GetHeight() + 26) end
    return self:AfterLayout()
  end
  local guide = Q.Progress:Guide()
  if not guide then
    self:ShowMessage(L.UI_TRACKER_NO_GUIDE)
    return self:AfterLayout()
  end
  self.message:Hide()

  -- En-tête
  self.title:SetText(guide.title or guide.id)
  self.title:Show()
  self.levels:SetFormattedText(L.UI_TRACKER_LEVELS, guide.minLevel or 1, guide.maxLevel or 60)
  self.levels:Show()
  local done, total = chapterProgress()
  self.bar:SetMinMaxValues(0, math.max(total, 1))
  self.bar:SetValue(done)
  self.barText:SetFormattedText(L.UI_TRACKER_PROGRESS, done, total)
  local chapterXP = comfort("XPRate", "ChapterText")
  if type(chapterXP) == "string" and chapterXP ~= "" then
    self.barText:SetText((self.barText:GetText() or "") .. "  ·  " .. chapterXP)
  end
  self.bar:Show()
  local y = PAD + 18 + 12 + 6
  y = self:LayoutXPLine(y)

  -- Alerte de quête de classe
  local alerts = classAlerts()
  if #alerts > 0 then
    if #alerts == 1 then
      self.alertText:SetFormattedText(L.UI_CLASS_ALERT_ONE, chainTitle(alerts[1]))
    else
      self.alertText:SetFormattedText(L.UI_CLASS_ALERT_MANY, #alerts)
    end
    self.alert:ClearAllPoints()
    self.alert:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
    self.alert:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y)
    self.alert:Show()
    if not self.alertPulse:IsPlaying() then self.alertPulse:Play() end
    y = y + 20 + 4
  else
    self.alert:Hide()
    self.alertPulse:Stop()
  end
  y = self:LayoutDungeonAlert(y)
  y = self:LayoutTrainerAlert(y)
  y = self:LayoutTalentAlert(y)

  -- Étape courante
  local entries = Q.Progress:Entries()
  local cur = Q.Progress:Current()
  local changed = cur ~= self.entry
  self.entry = cur
  local cur_ = self.current
  cur_:ClearAllPoints()
  cur_:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
  cur_:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y)
  local zone = zoneFor(cur)
  self.zone = zone
  if cur then
    self.currentIcon:SetTexture(zone and ZONE_ICON or Q.Format:ActionIcon(cur.step.action))
    self.currentIcon:Show()
    if changed or not self.target then self.target = Q.Targets:ForEntry(cur) end
  else
    self.currentIcon:Hide()
    self.target = nil
  end
  self:UpdateDistance(false)
  local textH = self:LayoutCurrent(cur, y, zone)
  local h = math.max(textH, cur and (ICON + 14) or 14)
  cur_:SetHeight(h)
  cur_:Show()
  y = y + h + 6
  y = self:LayoutWarnings(y)

  -- Étapes suivantes
  local wanted = math.min(math.max(math.floor(tonumber(setting("tracker.nextSteps")) or 3), 0), MAX_NEXT)
  local n = 0
  if cur and wanted > 0 then
    local started = false
    for _, e in ipairs(entries) do
      if started then
        local s = Q.Progress:State(e)
        if s ~= "done" and s ~= "skipped" and not (zone and zone.entryKeys[e.key]) then
          n = n + 1
          local line = self.nextLines[n]
          line.icon:SetTexture(Q.Format:ActionIcon(e.step.action))
          line.icon:ClearAllPoints()
          line.icon:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 2, -y - 1)
          line.icon:SetDesaturated(true)
          line.icon:SetAlpha(0.7)
          line.icon:Show()
          line.text:ClearAllPoints()
          line.text:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 18, -y)
          line.text:SetText(Q.Util.StripColors(Q.Format:StepTitle(e)))
          line.text:Show()
          y = y + NEXT_HEIGHT
          if n >= wanted then break end
        end
      elseif e == cur then
        started = true
      end
    end
  end
  for i = n + 1, MAX_NEXT do
    self.nextLines[i].icon:Hide()
    self.nextLines[i].text:Hide()
  end

  f:SetHeight(y + PAD - 2)
  return self:AfterLayout()
end

-- Après chaque mise en page (et pendant un déplacement) : les boutons de ciblage se replacent
-- sur les lignes de monstres.
function Tracker:AfterLayout()
  local P = Q.UI.MobPanel
  if P and P.Attach then P:Attach(self.mobSlots) end
  local B = Q.UI.QuestItemButton
  if B and B.Reposition then B:Reposition() end
end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
local function refresh() Tracker:Refresh() end

Q:On("LOGIN", function()
  Tracker:Create()
  Tracker:Refresh()
end)
Q:On("PROGRESS_UPDATED", refresh)
Q:On("STEP_CHANGED", refresh)
Q:On("GUIDE_CHANGED", refresh)
Q:On("CLASSQUESTS_CHANGED", refresh)
Q:On("DUNGEONS_CHANGED", refresh)
Q:On("TRAINER_CHANGED", refresh)
Q:On("TALENTS_CHANGED", refresh)
-- Mode zone : entrée ou sortie, objectif en tête changé : nouvelle cible, nouvelle liste.
Q:On("ZONEMODE_CHANGED", function()
  if not Tracker.frame then return end
  Tracker.target = nil
  Tracker:Refresh()
end)
-- Confort : un nouveau texte XP/h se met à jour sur place ; le reste redessine le suivi.
Q:On("COMFORT_CHANGED", function(kind)
  if not Tracker.frame then return end
  if kind == "xp" and Tracker:UpdateXPLine() then return end
  Tracker:Refresh()
end)
Q:On("SETTINGS_CHANGED", function(path)
  if not Tracker.frame then return end
  if path == "tracker.point" and not Tracker.moving then applyPosition(Tracker.frame) end
  Tracker:Refresh()
end)
