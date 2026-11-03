local addonName, Q = ...

-- Suivi sous la minimap (spec § 5.8) :
--   en-tête : titre du chapitre, niveaux, barre de progression « faites/total » ;
--   alerte de quête de classe (lueur pulsée) quand une chaîne devient disponible ;
--   étape courante en gros : icône d'action, texte coloré, distance (mise à jour toutes les 0,5 s),
--   et sous chaque ligne d'objectif les monstres à tuer (crâne, nom, niveau) ;
--   les étapes suivantes en petit et en gris.
-- Le clic sur un monstre passe par les boutons sécurisés d'UI/MobPanel.lua, posés par-dessus ses
-- lignes sans s'ancrer au suivi : un enfant sécurisé rendrait le suivi protégé (impossible à
-- redimensionner en combat). Ici, les lignes de monstres ne sont que du texte et des textures.
Q.UI = Q.UI or {}
local Tracker = {}
Q.UI.Tracker = Tracker

local L = Q.L

local WIDTH = 260
local PAD = 8
local ICON = 22             -- icône de l'action courante
local ICON_COL = 38         -- colonne de l'icône et de la distance
local NEXT_HEIGHT = 15
local MAX_NEXT = 10
local DIST_INTERVAL = 0.5   -- secondes entre deux calculs de distance
local TARGET_INTERVAL = 2   -- secondes entre deux recherches du point le plus proche

local TEXT_W = WIDTH - 2 * PAD - ICON_COL - 2   -- largeur du texte de l'étape courante
local MOB_ROW_H = 16
local MOB_INDENT = 10       -- retrait des lignes de monstres sous leur objectif
local MOB_LEVEL_W = 62
local SKULL_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"

local REASON_COLOR = "|cffff5555"
local MOB_COLOR = "|cffff6060"
local MOB_DONE_COLOR = "|cff808080"
local LEVEL_COLOR = "|cffaaaaaa"

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function setting(path) return Q.Settings:Get(path) end

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
  elseif QuestWatchFrame then
    -- Classic Era : suivi de quêtes de Blizzard (QuestWatchFrame) sous la minimap, on se met à sa gauche
    f:SetPoint("TOPRIGHT", QuestWatchFrame, "TOPLEFT", -8, 0)
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

local function stopMoving()
  local f = Tracker.frame
  if not f then return end
  local wasMoving = Tracker.moving
  Tracker.moving = false
  f:StopMovingOrSizing()
  if setting("tracker.locked") and not wasMoving then return end
  -- Coin haut gauche en unités d'UIParent : la position ne dépend ni de l'ancre d'origine ni de
  -- la taille du suivi, et survit au /reload.
  local left, top = f:GetLeft(), f:GetTop()
  if not (left and top) then return end
  local k = scaleRatio(f)
  Q.Settings:Set("tracker.point", { "TOPLEFT", "BOTTOMLEFT", Q.Util.Round(left * k, 1), Q.Util.Round(top * k, 1) })
end

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
  line.text:SetWidth(WIDTH - 2 * PAD - 16)
  line.icon:Hide()
  line.text:Hide()
  return line
end

function Tracker:Create()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", "QuestifyVanillaTracker", UIParent, "BackdropTemplate")
  self.frame = f
  f:SetSize(WIDTH, 60)
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
  msg:SetWidth(WIDTH - 2 * PAD)
  msg:SetJustifyH("LEFT")
  msg:Hide()
  self.message = msg

  -- En-tête
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", PAD, -PAD)
  title:SetWidth(WIDTH - 2 * PAD - 48)
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
  chunk:SetWidth(TEXT_W)
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
  row.name:SetWidth(TEXT_W - MOB_INDENT - 16 - MOB_LEVEL_W)
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
-- Rafraîchissement
---------------------------------------------------------------------------
local function setShown(region, shown)
  if shown then region:Show() else region:Hide() end
end

-- Seul message (QuestieDB absent, aucun chapitre) : le reste du cadre est caché.
function Tracker:ShowMessage(text)
  local f = self.frame
  self.entry, self.target = nil, nil
  for _, r in ipairs({ self.title, self.levels, self.bar, self.alert, self.current }) do r:Hide() end
  self.mobSlots = {}
  for _, line in ipairs(self.nextLines) do line.icon:Hide(); line.text:Hide() end
  self.alertPulse:Stop()
  self.message:SetText(text)
  self.message:Show()
  f:SetHeight(PAD * 2 + (self.message:GetStringHeight() or 12))
end

local function applyLock(f)
  local locked = setting("tracker.locked") and true or false
  f:SetMovable(not locked)
  f:EnableMouse(not locked)
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
  local state, reason = Q.Progress:State(entry)
  if state == "blocked" and reason then
    buf[#buf + 1] = REASON_COLOR .. Q.Format:Reason(reason) .. "|r"
  end
  flush()
  return segs
end

-- Met en page l'étape courante dans son bouton ; yTop = haut du bouton dans le suivi.
-- -> hauteur du contenu ; remplit self.mobSlots pour les boutons de ciblage.
function Tracker:LayoutCurrent(cur, yTop)
  local segs
  if cur then
    local mobs = Q.UI.MobPanel and Q.UI.MobPanel:MobsFor(cur) or {}
    segs = stepSegments(cur, mobs)
  else
    segs = { { text = L.UI_TRACKER_DONE } }
  end
  local slots = {}
  local nText, nMob, yy = 0, 0, 0
  for _, seg in ipairs(segs) do
    if seg.text then
      nText = nText + 1
      local chunk = self:TextChunk(nText)
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
      slots[#slots + 1] = { mob = mob, x = PAD + x - 2, y = yTop + yy, w = TEXT_W - MOB_INDENT + 2, h = MOB_ROW_H }
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
  f:Show()

  local status = qdbStatus()
  if status ~= "ok" then
    self:ShowMessage(status == "old" and L.QUESTIEDB_TOO_OLD or L.NEED_QUESTIEDB)
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
  self.bar:Show()
  local y = PAD + 18 + 12 + 6

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

  -- Étape courante
  local entries = Q.Progress:Entries()
  local cur = Q.Progress:Current()
  local changed = cur ~= self.entry
  self.entry = cur
  local cur_ = self.current
  cur_:ClearAllPoints()
  cur_:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y)
  cur_:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y)
  if cur then
    self.currentIcon:SetTexture(Q.Format:ActionIcon(cur.step.action))
    self.currentIcon:Show()
    if changed or not self.target then self.target = Q.Targets:ForEntry(cur) end
  else
    self.currentIcon:Hide()
    self.target = nil
  end
  self:UpdateDistance(false)
  local textH = self:LayoutCurrent(cur, y)
  local h = math.max(textH, cur and (ICON + 14) or 14)
  cur_:SetHeight(h)
  cur_:Show()
  y = y + h + 6

  -- Étapes suivantes
  local wanted = math.min(math.max(math.floor(tonumber(setting("tracker.nextSteps")) or 3), 0), MAX_NEXT)
  local n = 0
  if cur and wanted > 0 then
    local started = false
    for _, e in ipairs(entries) do
      if started then
        local s = Q.Progress:State(e)
        if s ~= "done" and s ~= "skipped" then
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
Q:On("SETTINGS_CHANGED", function(path)
  if not Tracker.frame then return end
  if path == "tracker.point" and not Tracker.moving then applyPosition(Tracker.frame) end
  Tracker:Refresh()
end)
