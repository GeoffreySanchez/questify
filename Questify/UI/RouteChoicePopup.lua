local addonName, Q = ...

-- Choix de suite : grande fenêtre au milieu de l'écran quand un chapitre fini a plusieurs suites
-- (ROUTE_CHOICE_NEEDED de Engine/Progress.lua), ou à la demande (/qf route, bouton du journal, clic
-- sur la ligne du suivi).
--
-- Mise en page : voile sombre plein écran (un clic à côté ne fait rien), fenêtre d'environ 70 % de la
-- hauteur de l'écran aux couleurs du thème du suivi (UI/Themes.lua), titre « Choisis la suite de ta
-- route » et chapitre fini. Une carte haute par suite (2 à 4, Q.RouteChoice:Rank), côte à côte :
--   image de la zone en fond (Q.ZoneArt, sinon la carte du monde de la zone, sinon un fond uni du
--   thème), recadrée pour remplir la carte et assombrie vers le bas ; nom de la zone en gros (langue
--   du client), tranche de niveaux en badge ; quêtes et XP des remises, durée et XP/h simulées,
--   trajet, chacun avec son icône ; « Points forts » (Q.RouteChoice:Highlights) quand il y en a.
-- La carte conseillée a un liseré doré, un halo qui pulse doucement, le badge « Conseillé » et sa
-- raison en toutes lettres (jamais la couleur seule). Survol ou carte active au clavier : liseré
-- éclairci, image plus lumineuse. Clic sur une carte = « Y aller » ; en bas « Garder la route
-- prévue » (suite par défaut) et « Plus tard » (Échap et la croix aussi) : le chapitre reste en
-- attente, le suivi le rappelle et /qf route rouvre le choix.
-- Clavier (fenêtre ouverte, hors combat) : flèches gauche / droite passent d'une carte à l'autre ; après
-- une flèche seulement, Tab (Maj+Tab) aussi et Entrée choisit la carte active (sinon Entrée et Tab
-- passent au jeu : le joueur qui tape Entrée pour écrire ne choisit rien sans avoir lu ; la carte
-- active par défaut et le survol ne valent pas accord). Échap = « Plus tard » ; toutes les autres
-- touches passent au jeu, et chaque relâchement de touche aussi.
--
-- Combat : jamais ouverte ni créée en combat ; une demande en combat attend PLAYER_REGEN_ENABLED.
-- Ouverte au début d'un combat (PLAYER_REGEN_DISABLED) : fermée, puis rouverte à la fin si le choix
-- n'est toujours pas fait. Fermée par le joueur : plus de réouverture automatique de ce choix (ni après
-- un combat, ni au /reload) jusqu'à la prochaine connexion (Q.char.routeChoiceDismissed, vidé à
-- PLAYER_ENTERING_WORLD d'une connexion) ; le suivi et /qf route la rouvrent. Choix fait : plus rien.
-- Option route.choicePopup : sans elle, aucune demande automatique ; /qf route reste possible.
-- Aucun cadre de Blizzard n'est modifié : seule la fenêtre est ajoutée à UISpecialFrames (Échap).
Q.UI = Q.UI or {}
local Popup = { cardFrames = {}, keyboard = false }
Q.UI.RouteChoicePopup = Popup

local L = Q.L

---------------------------------------------------------------------------
-- Mise en page (unités de UIParent) et couleurs
---------------------------------------------------------------------------
local WINDOW_SHARE = 0.70          -- hauteur visée de la fenêtre / hauteur de l'écran
local WIDTH_SHARE = 0.94           -- largeur maximale de la fenêtre / largeur de l'écran
local CARD_H_MIN, CARD_H_MAX = 340, 480
local CARD_W_MIN, CARD_W_MAX = 180, 340
local CARD_RATIO = 0.70            -- largeur / hauteur d'une carte
local HEADER_H, FOOTER_H = 76, 64
local PAD, GAP = 22, 18            -- marge de la fenêtre, écart entre les cartes
local INNER = 14                   -- marge intérieure des cartes
local ART_INSET = 3                -- l'image s'arrête sous le liseré
local BUTTON_H = 24
local HALO = 12                    -- débord du halo de la carte conseillée
local ICON, SMALL_ICON = 16, 14
local LINE_H, HL_H = 21, 18        -- lignes de chiffres, puces des points forts
local TOP_BAND = 64                -- bande assombrie du haut (badges)

local GOLD = { 1, 0.82, 0 }
local GOLD_LIGHT = { 1, 0.94, 0.55 }
local EDGE = { 0.42, 0.42, 0.47 }
local EDGE_LIGHT = { 0.92, 0.92, 0.98 }
local NAME_COLOR = { 1, 0.96, 0.86 }
local TEXT = { 0.95, 0.95, 0.95 }
local WARN = { 1, 0.47, 0.36 }
local VEIL_ALPHA = 0.6
local ART_REST, ART_LIT = 0.78, 1  -- luminosité de l'image : au repos, survolée ou active
local SHADE_BOTTOM, SHADE_TOP = { 0, 0, 0, 0.94 }, { 0, 0, 0, 0.08 }

-- Fond uni des cartes sans image : teinte sombre du thème actif (le texte reste clair).
local CARD_FILL = { parchment = { 0.22, 0.15, 0.08 }, default = { 0.09, 0.09, 0.11 } }

local ICONS = {
  quests = "Interface\\GossipFrame\\AvailableQuestIcon",
  time = "Interface\\Icons\\INV_Misc_PocketWatch_01",
  dungeon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
  class = "Interface\\GossipFrame\\AvailableQuestIcon",
  fp = "Interface\\Minimap\\Tracking\\FlightMaster",
  star = "Interface\\Common\\ReputationStar",
}
local TRAVEL_ICONS = {
  walk = "Interface\\Icons\\Ability_Rogue_Sprint",
  fly = "Interface\\Minimap\\Tracking\\FlightMaster",
  boat = "Interface\\Icons\\INV_Misc_Map_01",
  zeppelin = "Interface\\Icons\\INV_Misc_Map_01",
  tram = "Interface\\Icons\\INV_Misc_Map_01",
  portal = "Interface\\Icons\\Spell_Arcane_PortalStormWind",
  hearth = "Interface\\Icons\\INV_Misc_Rune_01",
}
Popup.ICONS, Popup.TRAVEL_ICONS = ICONS, TRAVEL_ICONS

local function inCombat() return InCombatLockdown and InCombatLockdown() end
local function automatic() return Q.Settings:Get("route.choicePopup") ~= false end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function num(v)
  if Q.Util and Q.Util.IsSecret and Q.Util.IsSecret(v) then return nil end
  if type(v) == "number" and v == v then return v end
  return nil
end

-- 26898 -> « 26 898 » (séparateur du jeu quand il existe).
local function bigNumber(n)
  n = math.floor((tonumber(n) or 0) + 0.5)
  if type(BreakUpLargeNumbers) == "function" then
    local ok, s = pcall(BreakUpLargeNumbers, n)
    if ok and type(s) == "string" then return s end
  end
  return tostring(n)
end

-- 158 -> « 2 h 38 », 45 -> « 45 min ».
local function duration(minutes)
  minutes = math.floor((tonumber(minutes) or 0) + 0.5)
  if minutes < 60 then return minutes .. " min" end
  return string.format("%d h %02d", math.floor(minutes / 60), minutes % 60)
end

---------------------------------------------------------------------------
-- Choix fermés par le joueur (gardés au /reload, vidés à la connexion)
---------------------------------------------------------------------------
local function dismissedSet(create)
  local c = Q.char
  if type(c) ~= "table" then return nil end
  if type(c.routeChoiceDismissed) ~= "table" then
    if not create then return nil end
    c.routeChoiceDismissed = {}
  end
  return c.routeChoiceDismissed
end

local function isDismissed(id)
  local set = dismissedSet(false)
  return set ~= nil and set[id] == true
end

---------------------------------------------------------------------------
-- Taille
---------------------------------------------------------------------------
-- Taille de l'écran dans les unités de UIParent (repli : GetScreenWidth / GetScreenHeight).
local function screenSize()
  local w = UIParent and UIParent.GetWidth and UIParent:GetWidth()
  local h = UIParent and UIParent.GetHeight and UIParent:GetHeight()
  if not (type(w) == "number" and w > 0) then w = (GetScreenWidth and GetScreenWidth()) or 1024 end
  if not (type(h) == "number" and h > 0) then h = (GetScreenHeight and GetScreenHeight()) or 768 end
  return w, h
end

-- Popup.Layout(n) -> largeur et hauteur d'une carte, largeur et hauteur de la fenêtre, pour n cartes.
-- Cartes de 340 × 480 au plus, réduites pour tenir dans 70 % de la hauteur et 94 % de la largeur.
function Popup.Layout(n)
  n = math.max(1, n or 1)
  local sw, sh = screenSize()
  local cardH = clamp(math.floor(sh * WINDOW_SHARE) - HEADER_H - FOOTER_H, CARD_H_MIN, CARD_H_MAX)
  local cardW = clamp(math.floor(cardH * CARD_RATIO + 0.5), CARD_W_MIN, CARD_W_MAX)
  local avail = math.floor((sw * WIDTH_SHARE - 2 * PAD - (n - 1) * GAP) / n)
  if cardW > avail then cardW = math.max(CARD_W_MIN, avail) end
  return cardW, cardH, 2 * PAD + n * cardW + (n - 1) * GAP, HEADER_H + cardH + FOOTER_H
end

---------------------------------------------------------------------------
-- Petits outils de dessin
---------------------------------------------------------------------------
local function fontString(parent, template)
  local fs = parent:CreateFontString(nil, "OVERLAY", template)
  fs:SetJustifyH("LEFT")
  fs:SetJustifyV("TOP")
  return fs
end

local function setColor(fs, c) fs:SetTextColor(c[1], c[2], c[3], 1) end

-- Icône : texture (les icônes de sorts et d'objets sont rognées de leur bord), coordonnées facultatives.
local function setIcon(tx, path, coords)
  tx:SetTexture(path)
  if coords then
    tx:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
  elseif type(path) == "string" and path:find("Interface\\Icons\\", 1, true) == 1 then
    tx:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  else
    tx:SetTexCoord(0, 1, 0, 1)
  end
end

-- Dégradé (from = bas ou gauche, to = haut ou droite, comme Texture:SetGradient). Sans l'API :
-- couleur moyenne.
local function gradient(tx, orientation, from, to)
  tx:SetColorTexture(1, 1, 1, 1)
  if type(CreateColor) == "function" and tx.SetGradient then
    local ok = pcall(tx.SetGradient, tx, orientation, CreateColor(from[1], from[2], from[3], from[4]),
      CreateColor(to[1], to[2], to[3], to[4]))
    if ok then return end
  end
  tx:SetColorTexture((from[1] + to[1]) / 2, (from[2] + to[2]) / 2, (from[3] + to[3]) / 2, (from[4] + to[4]) / 2)
end

local EDGE_BACKDROP = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 14,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- Pastille : fond uni, icône facultative, texte.
local function pill(parent, template)
  local p = CreateFrame("Frame", nil, parent)
  p.bg = p:CreateTexture(nil, "BACKGROUND")
  p.bg:SetAllPoints(p)
  p.icon = p:CreateTexture(nil, "ARTWORK")
  p.icon:SetSize(12, 12)
  p.icon:SetPoint("LEFT", p, "LEFT", 6, 0)
  p.text = p:CreateFontString(nil, "OVERLAY", template)
  p:SetHeight(20)
  return p
end

local function setPill(p, text, bg, fg, icon)
  p.text:SetText(text)
  p.bg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
  setColor(p.text, fg)
  p.text:ClearAllPoints()
  if icon then
    setIcon(p.icon, icon, { 0, 0.5, 0, 0.5 })
    p.icon:Show()
    p.text:SetPoint("LEFT", p.icon, "RIGHT", 4, 0)
  else
    p.icon:Hide()
    p.text:SetPoint("LEFT", p, "LEFT", 8, 0)
  end
  p:SetWidth((p.text:GetStringWidth() or 40) + 16 + (icon and 16 or 0))
  p:Show()
end

---------------------------------------------------------------------------
-- Cadre
---------------------------------------------------------------------------
-- Halo de la carte conseillée : quatre bandes dorées qui s'effacent vers l'extérieur, pulsation douce.
local function makeHalo(window, card)
  local halo = CreateFrame("Frame", nil, window)
  halo:SetPoint("TOPLEFT", card, "TOPLEFT", -HALO, HALO)
  halo:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", HALO, -HALO)
  local inner, outer = { GOLD[1], GOLD[2], GOLD[3], 0.6 }, { GOLD[1], GOLD[2], GOLD[3], 0 }
  local top = halo:CreateTexture(nil, "BACKGROUND")
  top:SetPoint("TOPLEFT", halo, "TOPLEFT", HALO, 0)
  top:SetPoint("TOPRIGHT", halo, "TOPRIGHT", -HALO, 0)
  top:SetHeight(HALO)
  gradient(top, "VERTICAL", inner, outer)
  local bottom = halo:CreateTexture(nil, "BACKGROUND")
  bottom:SetPoint("BOTTOMLEFT", halo, "BOTTOMLEFT", HALO, 0)
  bottom:SetPoint("BOTTOMRIGHT", halo, "BOTTOMRIGHT", -HALO, 0)
  bottom:SetHeight(HALO)
  gradient(bottom, "VERTICAL", outer, inner)
  local left = halo:CreateTexture(nil, "BACKGROUND")
  left:SetPoint("TOPLEFT", halo, "TOPLEFT", 0, -HALO)
  left:SetPoint("BOTTOMLEFT", halo, "BOTTOMLEFT", 0, HALO)
  left:SetWidth(HALO)
  gradient(left, "HORIZONTAL", outer, inner)
  local right = halo:CreateTexture(nil, "BACKGROUND")
  right:SetPoint("TOPRIGHT", halo, "TOPRIGHT", 0, -HALO)
  right:SetPoint("BOTTOMRIGHT", halo, "BOTTOMRIGHT", 0, HALO)
  right:SetWidth(HALO)
  gradient(right, "HORIZONTAL", inner, outer)
  local pulse = halo:CreateAnimationGroup()
  pulse:SetLooping("BOUNCE")
  local fade = pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(0.35)
  fade:SetToAlpha(1)
  fade:SetDuration(1.2)
  if fade.SetSmoothing then fade:SetSmoothing("IN_OUT") end
  halo:Hide()
  return halo, pulse
end

local function iconLine(parent, template, size)
  local icon = parent:CreateTexture(nil, "ARTWORK")
  icon:SetSize(size, size)
  local text = fontString(parent, template)
  text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  if text.SetWordWrap then text:SetWordWrap(false) end
  icon:Hide()
  text:Hide()
  return { icon = icon, text = text }
end

function Popup:CardFrame(i)
  local c = self.cardFrames[i]
  if c then return c end
  local win = self.window
  local card = CreateFrame("Button", nil, win)
  card:RegisterForClicks("LeftButtonUp")
  local base = (win:GetFrameLevel() or 1) + 3
  card:SetFrameLevel(base)
  c = { frame = card, index = i, tiles = {}, tileCount = 0, lines = {}, highlights = {} }

  c.halo, c.pulse = makeHalo(win, card)
  c.halo:SetFrameLevel(base - 1)

  -- Image : cadre qui rogne ce qui dépasse, fond uni dessous, image ou tuiles dans un cadre enfant
  local art = CreateFrame("Frame", nil, card)
  art:SetPoint("TOPLEFT", card, "TOPLEFT", ART_INSET, -ART_INSET)
  if art.SetClipsChildren then art:SetClipsChildren(true) end
  art:SetFrameLevel(base + 1)
  c.art = art
  c.solid = art:CreateTexture(nil, "BACKGROUND")
  c.solid:SetAllPoints(art)
  local canvas = CreateFrame("Frame", nil, art)
  canvas:SetFrameLevel(base + 2)
  c.canvas = canvas
  c.image = canvas:CreateTexture(nil, "BACKGROUND")
  c.image:SetAllPoints(canvas)
  c.image:Hide()

  -- Assombrissement : du bas (texte) vers le haut, bande du haut (badges), lueur de survol
  local shade = CreateFrame("Frame", nil, art)
  shade:SetAllPoints(art)
  shade:SetFrameLevel(base + 3)
  local dark = shade:CreateTexture(nil, "ARTWORK")
  dark:SetAllPoints(shade)
  gradient(dark, "VERTICAL", SHADE_BOTTOM, SHADE_TOP)
  local topBand = shade:CreateTexture(nil, "ARTWORK", nil, 1)
  topBand:SetPoint("TOPLEFT", shade, "TOPLEFT", 0, 0)
  topBand:SetPoint("TOPRIGHT", shade, "TOPRIGHT", 0, 0)
  topBand:SetHeight(TOP_BAND)
  gradient(topBand, "VERTICAL", { 0, 0, 0, 0 }, { 0, 0, 0, 0.6 })
  c.lit = shade:CreateTexture(nil, "OVERLAY")
  c.lit:SetAllPoints(shade)
  c.lit:SetColorTexture(1, 1, 1, 0.05)
  if c.lit.SetBlendMode then c.lit:SetBlendMode("ADD") end
  c.lit:Hide()

  -- Texte
  local content = CreateFrame("Frame", nil, card)
  content:SetAllPoints(card)
  content:SetFrameLevel(base + 4)
  c.content = content
  c.badge = pill(content, "GameFontNormalSmall")
  c.badge:SetPoint("TOPLEFT", content, "TOPLEFT", INNER - 4, -(INNER - 4))
  c.badgeText = c.badge.text
  c.levelPill = pill(content, "GameFontHighlightSmall")
  c.levelPill:SetPoint("TOPRIGHT", content, "TOPRIGHT", -(INNER - 4), -(INNER - 4))
  c.levels = c.levelPill.text
  c.name = fontString(content, "GameFontNormalHuge")
  if c.name.SetWordWrap then c.name:SetWordWrap(true) end
  if c.name.SetShadowColor then c.name:SetShadowColor(0, 0, 0, 0.9) end
  if c.name.SetShadowOffset then c.name:SetShadowOffset(1, -1) end
  c.warning = fontString(content, "GameFontNormalSmall")
  setColor(c.warning, WARN)
  for k = 1, 3 do c.lines[k] = iconLine(content, "GameFontHighlight", ICON) end
  c.hlHeader = fontString(content, "GameFontNormalSmall")
  c.hlHeader:SetText(L.UI_ROUTECHOICE_HIGHLIGHTS)
  setColor(c.hlHeader, GOLD)
  for k = 1, 3 do c.highlights[k] = iconLine(content, "GameFontHighlightSmall", SMALL_ICON) end
  c.reason = fontString(content, "GameFontNormal")
  setColor(c.reason, GOLD)
  c.reason:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", INNER, INNER + BUTTON_H + 8)
  c.button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  c.button:SetHeight(BUTTON_H)
  c.button:SetText(L.UI_ROUTECHOICE_CHOOSE)
  c.button:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", INNER, INNER)
  c.button:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -INNER, INNER)

  -- Liseré au-dessus de tout (ne prend pas la souris)
  local border = CreateFrame("Frame", nil, card, "BackdropTemplate")
  border:SetAllPoints(card)
  border:SetFrameLevel(base + 6)
  if border.SetBackdrop then border:SetBackdrop(EDGE_BACKDROP) end
  c.border = border

  local function choose() if c.data then Popup:Choose(c.data.id) end end
  local function enter() Popup:Focus(c.index) end
  card:SetScript("OnClick", function() Q.SafeCall(choose) end)
  card:SetScript("OnEnter", function() Q.SafeCall(enter) end)
  c.button:SetScript("OnClick", function() Q.SafeCall(choose) end)
  c.button:HookScript("OnEnter", function() Q.SafeCall(enter) end)

  card:Hide()
  self.cardFrames[i] = c
  return c
end

local function footerButton(parent, label, width, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, BUTTON_H)
  b:SetText(label)
  b:SetScript("OnClick", function() Q.SafeCall(onClick) end)
  return b
end

function Popup:Create()
  if self.frame then return self.frame end
  -- Voile plein écran : garde les clics (rien ne se passe), porte le clavier.
  local root = CreateFrame("Frame", "QuestifyRouteChoicePopup", UIParent)
  root:SetAllPoints(UIParent)
  root:SetFrameStrata("DIALOG")
  root:EnableMouse(true)
  root:Hide()
  self.veil = root:CreateTexture(nil, "BACKGROUND")
  self.veil:SetAllPoints(root)
  self.veil:SetColorTexture(0, 0, 0, VEIL_ALPHA)
  local fade = root:CreateAnimationGroup()
  local alpha = fade:CreateAnimation("Alpha")
  alpha:SetFromAlpha(0)
  alpha:SetToAlpha(1)
  alpha:SetDuration(0.2)
  self.fadeIn = fade

  local win = CreateFrame("Frame", nil, root, "BackdropTemplate")
  win:SetPoint("CENTER", root, "CENTER", 0, 10)
  win:EnableMouse(true)
  self.window = win

  self.title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  self.title:SetPoint("TOP", win, "TOP", 0, -18)
  self.title:SetText(L.UI_ROUTECHOICE_TITLE)
  self.subtitle = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.subtitle:SetPoint("TOP", self.title, "BOTTOM", 0, -8)

  self.closeButton = CreateFrame("Button", nil, win, "UIPanelCloseButton")
  self.closeButton:SetPoint("TOPRIGHT", win, "TOPRIGHT", -4, -4)
  self.closeButton:SetScript("OnClick", function() Q.SafeCall(Popup.Later, Popup) end)

  self.keepButton = footerButton(win, L.UI_ROUTECHOICE_KEEP, 190, function() Popup:Keep() end)
  self.laterButton = footerButton(win, L.UI_ROUTECHOICE_LATER, 120, function() Popup:Later() end)
  self.keepButton:SetPoint("BOTTOMRIGHT", win, "BOTTOM", -6, 30)
  self.laterButton:SetPoint("BOTTOMLEFT", win, "BOTTOM", 6, 30)
  self.keysHint = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.keysHint:SetPoint("BOTTOM", win, "BOTTOM", 0, 11)
  self.keysHint:SetText(L.UI_ROUTECHOICE_KEYS)

  -- Échap ferme la fenêtre comme « Plus tard » quand le clavier n'est pas à elle
  if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "QuestifyRouteChoicePopup") end
  root:SetScript("OnKeyDown", function(f, key) Q.SafeCall(Popup.OnKey, Popup, f, key) end)
  root:SetScript("OnKeyUp", function(f, key) Q.SafeCall(Popup.OnKeyUp, Popup, f, key) end)
  root:SetScript("OnHide", function(f) Q.SafeCall(Popup.OnFrameHidden, Popup, f) end)
  self.frame = root
  return root
end

---------------------------------------------------------------------------
-- Contenu
---------------------------------------------------------------------------
-- Thème du suivi (sans fond : thème sombre), opacité d'au moins 0,92.
function Popup:ApplyTheme()
  local Themes = Q.Themes
  if not Themes then return end
  local theme = Themes:Get(Q.Settings:Get("tracker.theme"))
  if not theme.background or theme.background.kind == "none" then theme = Themes:Get("dark") end
  local opacity = math.max(Themes:Opacity(Q.Settings:Get("tracker.opacity")), 0.92)
  Themes:Apply(self.window, theme.key, opacity)
  Themes:StyleText(self.title, "title", theme)
  Themes:StyleText(self.subtitle, "levels", theme)
  Themes:StyleText(self.keysHint, "dim", theme)
  self.theme = theme
end

-- Recadrage « couvrir » d'une image (entrée de Q.ZoneArt) dans une zone aw × ah : coordonnées de
-- texture gauche, droite, haut, bas, centrées dans coords (toute l'image par défaut).
local function coverCoords(entry, aw, ah)
  local l, r, t, b = 0, 1, 0, 1
  local co = entry.coords
  if type(co) == "table" and num(co[1]) and num(co[2]) and num(co[3]) and num(co[4]) then
    l, r, t, b = co[1], co[2], co[3], co[4]
  end
  local iw = (num(entry.width) or 1024) * (r - l)
  local ih = (num(entry.height) or 512) * (b - t)
  if iw <= 0 or ih <= 0 or aw <= 0 or ah <= 0 then return l, r, t, b end
  local target, src = aw / ah, iw / ih
  if src > target then
    local keep, mid = (r - l) * target / src, (l + r) / 2
    return mid - keep / 2, mid + keep / 2, t, b
  end
  local keep, mid = (b - t) * src / target, (t + b) / 2
  return l, r, mid - keep / 2, mid + keep / 2
end

-- Carte du monde de la zone en fond : tuiles du calque 1 (C_Map.GetMapArtLayers /
-- GetMapArtLayerTextures), disposées ligne par ligne comme Blizzard_MapCanvasDetailLayer, à l'échelle
-- pour couvrir la carte et centrées. Tuiles créées une fois par carte, réutilisées ; rien n'est refait
-- pour la même zone à la même taille. -> false si le client ne donne pas la carte.
local function paintMap(c, mapId, aw, ah)
  if not (C_Map and type(C_Map.GetMapArtLayers) == "function"
    and type(C_Map.GetMapArtLayerTextures) == "function") then
    return false
  end
  local ok, layers = pcall(C_Map.GetMapArtLayers, mapId)
  local info = ok and type(layers) == "table" and layers[1]
  if type(info) ~= "table" then return false end
  local lw, lh, tw, th = num(info.layerWidth), num(info.layerHeight), num(info.tileWidth), num(info.tileHeight)
  if not (lw and lh and tw and th and lw > 0 and lh > 0 and tw > 0 and th > 0) then return false end
  local ok2, textures = pcall(C_Map.GetMapArtLayerTextures, mapId, 1)
  if not ok2 or type(textures) ~= "table" or #textures == 0 then return false end
  local cols, rows = math.ceil(lw / tw), math.ceil(lh / th)
  local s = math.max(aw / lw, ah / lh)
  c.canvas:ClearAllPoints()
  c.canvas:SetSize(lw * s, lh * s)
  c.canvas:SetPoint("CENTER", c.art, "CENTER", 0, 0)
  local key = table.concat({ mapId, aw, ah }, ":")
  if c.artKey ~= key then
    local k = 0
    for row = 1, rows do
      for col = 1, cols do
        k = k + 1
        local tx = c.tiles[k]
        if not tx then
          tx = c.canvas:CreateTexture(nil, "BACKGROUND", nil, 1)
          c.tiles[k] = tx
        end
        tx:SetTexture(textures[(row - 1) * cols + col], nil, nil, "TRILINEAR")
        tx:SetSize(tw * s, th * s)
        tx:ClearAllPoints()
        tx:SetPoint("TOPLEFT", c.canvas, "TOPLEFT", (col - 1) * tw * s, -(row - 1) * th * s)
      end
    end
    c.tileCount = k
    c.artKey = key
  end
  for i, tx in ipairs(c.tiles) do tx:SetShown(i <= c.tileCount) end
  return true
end

-- Fond de la carte : Q.ZoneArt, sinon la carte du monde, sinon le fond uni seul. c.artMode = "image" |
-- "map" | "color".
function Popup:PaintArt(c, mapId)
  local aw, ah = c.art:GetSize()
  local fill = CARD_FILL[self.theme and self.theme.key] or CARD_FILL.default
  c.solid:SetColorTexture(fill[1], fill[2], fill[3], 1)
  c.solid:Show()
  c.image:Hide()
  local entry = mapId and type(Q.ZoneArt) == "table" and Q.ZoneArt[mapId]
  if type(entry) == "table" and type(entry.texture) == "string" and entry.texture ~= "" then
    for _, tx in ipairs(c.tiles) do tx:Hide() end
    c.canvas:ClearAllPoints()
    c.canvas:SetSize(aw, ah)
    c.canvas:SetPoint("CENTER", c.art, "CENTER", 0, 0)
    c.image:SetTexture(entry.texture)
    c.image:SetTexCoord(coverCoords(entry, aw, ah))
    c.image:Show()
    c.artMode = "image"
  elseif mapId and paintMap(c, mapId, aw, ah) then
    c.artMode = "map"
  else
    for _, tx in ipairs(c.tiles) do tx:Hide() end
    c.artMode = "color"
  end
end

local function travelLine(card)
  local t = card.travel
  if not t then return nil end
  local kind = L["UI_ROUTECHOICE_KIND_" .. tostring(t.kind)] or tostring(t.kind)
  local text
  if type(t.minutes) == "number" then
    text = string.format(L.UI_ROUTECHOICE_TRAVEL_MIN, kind, t.minutes)
  else
    text = string.format(L.UI_ROUTECHOICE_TRAVEL, kind)
  end
  return { icon = TRAVEL_ICONS[t.kind] or TRAVEL_ICONS.walk, text = text }
end

-- Lignes de chiffres : quêtes et XP, durée et XP/h simulées, trajet (absentes sans donnée).
local function statLines(data)
  local out = {}
  local fmt = data.quests == 1 and L.UI_ROUTECHOICE_QUESTS_ONE or L.UI_ROUTECHOICE_QUESTS
  out[#out + 1] = { icon = ICONS.quests, text = string.format(fmt, data.quests or 0, bigNumber(data.xp)) }
  if data.minutes and data.xpPerHour then
    out[#out + 1] = { icon = ICONS.time, text = string.format(L.UI_ROUTECHOICE_TIME_XPH, duration(data.minutes),
      bigNumber(data.xpPerHour)) }
  elseif data.minutes then
    out[#out + 1] = { icon = ICONS.time, text = string.format(L.UI_ROUTECHOICE_TIME, duration(data.minutes)) }
  elseif data.xpPerHour then
    out[#out + 1] = { icon = ICONS.time, text = string.format(L.UI_ROUTECHOICE_XPH, bigNumber(data.xpPerHour)) }
  end
  out[#out + 1] = travelLine(data)
  return out
end

-- Icône de la classe du joueur (cercles des classes), sinon l'icône de quête.
local function classIcon()
  local cf = Q.Player and Q.Player.classFile
  local tc = type(CLASS_ICON_TCOORDS) == "table" and cf and CLASS_ICON_TCOORDS[cf]
  if type(tc) == "table" then return "Interface\\TargetingFrame\\UI-Classes-Circles", tc end
  return ICONS.class
end

-- Puces des points forts (Q.RouteChoice:Highlights).
local function highlightLines(data)
  local ok, list = pcall(Q.RouteChoice.Highlights, Q.RouteChoice, data.guide)
  if not ok then
    Q:ReportError(list)
    return {}
  end
  local out = {}
  for _, h in ipairs(list) do
    if h.kind == "dungeon" then
      out[#out + 1] = { icon = ICONS.dungeon,
        text = string.format(L.UI_ROUTECHOICE_HL_DUNGEON, h.name, h.minLevel, h.maxLevel) }
    elseif h.kind == "class" then
      local icon, coords = classIcon()
      out[#out + 1] = { icon = icon, coords = coords, text = string.format(L.UI_ROUTECHOICE_HL_CLASS, h.title) }
    elseif h.kind == "fp" then
      local text = h.count == 1 and L.UI_ROUTECHOICE_HL_FP_ONE or string.format(L.UI_ROUTECHOICE_HL_FP, h.count)
      out[#out + 1] = { icon = ICONS.fp, text = text }
    end
  end
  return out
end

local function showLine(row, spec, content, y, textWidth)
  row.icon:ClearAllPoints()
  row.icon:SetPoint("TOPLEFT", content, "TOPLEFT", INNER, -y)
  setIcon(row.icon, spec.icon, spec.coords)
  row.text:SetText(spec.text)
  row.text:SetWidth(textWidth)
  row.icon:Show()
  row.text:Show()
end

local function hideLine(row)
  row.text:SetText("")
  row.icon:Hide()
  row.text:Hide()
end

function Popup:FillCard(c, data, w, h)
  c.data = data
  c.frame:SetSize(w, h)
  c.art:SetSize(w - 2 * ART_INSET, h - 2 * ART_INSET)
  self:PaintArt(c, data.mapId)

  -- Badges du haut : « Conseillé » (doré) ou « Route de Questify », tranche de niveaux
  if data.recommended then
    setPill(c.badge, L.UI_ROUTECHOICE_RECOMMENDED, { GOLD[1], GOLD[2], GOLD[3], 0.95 }, { 0.16, 0.10, 0 }, ICONS.star)
  elseif data.default then
    setPill(c.badge, L.UI_ROUTECHOICE_DEFAULT, { 0, 0, 0, 0.65 }, { 0.85, 0.85, 0.85 })
  else
    c.badge.text:SetText("")
    c.badge:Hide()
  end
  setPill(c.levelPill, string.format(L.UI_ROUTECHOICE_LEVELS, data.minLevel, data.maxLevel), { 0, 0, 0, 0.65 }, TEXT)

  -- Nom de la zone : police du jeu, grande, cernée
  local inner = w - 2 * INNER
  local size = clamp(math.floor(w / 13), 18, 26)
  if c.name.SetFont then pcall(c.name.SetFont, c.name, STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "OUTLINE") end
  setColor(c.name, NAME_COLOR)
  c.name:SetWidth(inner)
  c.name:SetText(data.title)

  local warning = ""
  if data.warning == "low" then
    warning = string.format(L.UI_ROUTECHOICE_WARN_low, data.minLevel)
  elseif data.warning == "high" then
    warning = L.UI_ROUTECHOICE_WARN_high
  end
  c.warning:SetWidth(inner)
  c.warning:SetText(warning)
  c.reason:SetWidth(inner)
  c.reason:SetText(data.recommended and (L["UI_ROUTECHOICE_REASON_" .. tostring(data.reason)] or "") or "")

  -- Placement de haut en bas, au-dessus de la raison et du bouton ; le bloc remonte s'il manque de
  -- place, puis les dernières puces tombent.
  local stats, hl = statLines(data), highlightLines(data)
  local nameH = c.name:GetStringHeight() or size
  local warnH = warning ~= "" and ((c.warning:GetStringHeight() or 12) + 4) or 0
  local reasonH = c.reason:GetText() ~= "" and ((c.reason:GetStringHeight() or 14) + 6) or 0
  local limit = h - INNER - BUTTON_H - 8 - reasonH
  local function blockHeight(nhl)
    return nameH + 6 + warnH + 6 + #stats * LINE_H + (nhl > 0 and (8 + 16 + nhl * HL_H) or 0)
  end
  local nhl = math.min(#hl, #c.highlights)
  local topMin = INNER + 30
  local y = math.floor(h * 0.42)
  if y + blockHeight(nhl) > limit then y = math.max(topMin, limit - blockHeight(nhl)) end
  while nhl > 0 and y + blockHeight(nhl) > limit do nhl = nhl - 1 end

  c.name:ClearAllPoints()
  c.name:SetPoint("TOPLEFT", c.content, "TOPLEFT", INNER, -y)
  y = y + nameH + 6
  c.warning:ClearAllPoints()
  c.warning:SetPoint("TOPLEFT", c.content, "TOPLEFT", INNER, -y)
  c.warning:SetShown(warning ~= "")
  y = y + warnH + 6
  for k, row in ipairs(c.lines) do
    if stats[k] then
      showLine(row, stats[k], c.content, y, inner - ICON - 6)
      y = y + LINE_H
    else
      hideLine(row)
    end
  end
  if nhl > 0 then
    y = y + 8
    c.hlHeader:ClearAllPoints()
    c.hlHeader:SetPoint("TOPLEFT", c.content, "TOPLEFT", INNER, -y)
    c.hlHeader:Show()
    y = y + 16
  else
    c.hlHeader:Hide()
  end
  for k, row in ipairs(c.highlights) do
    if k <= nhl then
      showLine(row, hl[k], c.content, y, inner - SMALL_ICON - 6)
      y = y + HL_H
    else
      hideLine(row)
    end
  end

  if data.recommended then
    c.halo:Show()
    c.pulse:Play()
  else
    c.pulse:Stop()
    c.halo:Hide()
  end
end

-- Carte de repli après une erreur de FillCard : fond uni, nom traduit et « Y aller » seulement
-- (liseré et halo de la conseillée gardés).
function Popup:FillMinimal(c, data, w, h)
  c.data = data
  c.frame:SetSize(w, h)
  c.art:SetSize(w - 2 * ART_INSET, h - 2 * ART_INSET)
  local fill = CARD_FILL[self.theme and self.theme.key] or CARD_FILL.default
  c.solid:SetColorTexture(fill[1], fill[2], fill[3], 1)
  c.solid:Show()
  c.image:Hide()
  for _, tx in ipairs(c.tiles) do tx:Hide() end
  c.artMode = "color"
  c.badge.text:SetText("")
  c.badge:Hide()
  c.levelPill:Hide()
  c.warning:SetText("")
  c.warning:Hide()
  c.reason:SetText("")
  for _, row in ipairs(c.lines) do hideLine(row) end
  for _, row in ipairs(c.highlights) do hideLine(row) end
  c.hlHeader:Hide()
  setColor(c.name, NAME_COLOR)
  c.name:SetWidth(w - 2 * INNER)
  c.name:SetText(data.title or data.id or "?")
  c.name:ClearAllPoints()
  c.name:SetPoint("TOPLEFT", c.content, "TOPLEFT", INNER, -math.floor(h * 0.42))
  c.name:Show()
  c.button:Show()
  if data.recommended then
    c.halo:Show()
    c.pulse:Play()
  else
    c.pulse:Stop()
    c.halo:Hide()
  end
end

-- Liseré et lumière d'une carte : dorés pour la conseillée, éclaircis pour la carte active (survol
-- ou clavier).
function Popup:RefreshLook(c)
  local d = c.data
  if not d then return end
  local lit = self.focus == c.index
  local edge
  if d.recommended then edge = lit and GOLD_LIGHT or GOLD else edge = lit and EDGE_LIGHT or EDGE end
  if c.border.SetBackdropBorderColor then c.border:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1) end
  c.lit:SetShown(lit)
  local v = lit and ART_LIT or ART_REST
  c.image:SetVertexColor(v, v, v, 1)
  for _, tx in ipairs(c.tiles) do tx:SetVertexColor(v, v, v, 1) end
end

function Popup:RefreshLooks()
  for _, c in ipairs(self.cardFrames) do
    if c.data then self:RefreshLook(c) end
  end
end

-- Carte active (survol, flèches, Tab) : Entrée la choisit, après une flèche (Popup.armed).
function Popup:Focus(i)
  if not (self.cards and self.cards[i]) then return end
  self.focus = i
  self:RefreshLooks()
end

function Popup:MoveFocus(delta)
  local n = self.cards and #self.cards or 0
  if n == 0 then return end
  self:Focus(((self.focus or 1) - 1 + delta) % n + 1)
end

function Popup:Fill(fromId, cards)
  local n = #cards
  local cw, ch, ww, wh = Popup.Layout(n)
  self.window:SetSize(ww, wh)
  self:ApplyTheme()
  self.title:SetText(L.UI_ROUTECHOICE_TITLE)
  self.subtitle:SetText(string.format(L.UI_ROUTECHOICE_SUBTITLE, Q.Guides:DisplayTitle(fromId)))
  self.focus = 1
  for i, data in ipairs(cards) do
    if data.recommended then self.focus = i end
  end
  local failed
  for i = 1, math.max(n, #self.cardFrames) do
    if i <= n then
      local c = self:CardFrame(i)
      c.frame:ClearAllPoints()
      c.frame:SetPoint("TOPLEFT", self.window, "TOPLEFT", PAD + (i - 1) * (cw + GAP), -HEADER_H)
      -- une erreur dans une carte ne bloque pas le choix : carte minimale, erreur rapportée une fois
      local ok, err = pcall(self.FillCard, self, c, cards[i], cw, ch)
      c.fallback = not ok
      if not ok then
        failed = failed or err
        local okMin, errMin = pcall(self.FillMinimal, self, c, cards[i], cw, ch)
        if not okMin then failed = failed or errMin end
      end
      c.frame:Show()
    else
      local c = self.cardFrames[i]
      c.data = nil
      c.pulse:Stop()
      c.halo:Hide()
      c.frame:Hide()
    end
  end
  self:RefreshLooks()
  if failed then Q:ReportError(failed) end
end

---------------------------------------------------------------------------
-- Clavier
---------------------------------------------------------------------------
-- Clavier pris seulement fenêtre ouverte et hors combat ; touches non gérées transmises au jeu.
function Popup:SetKeyboard(on)
  local f = self.frame
  on = on and f ~= nil and f:IsShown() and not inCombat() or false
  if f then
    if f.EnableKeyboard then pcall(f.EnableKeyboard, f, on) end
    if on and f.SetPropagateKeyboardInput then pcall(f.SetPropagateKeyboardInput, f, true) end
  end
  self.keyboard = on
end

-- Entrée et Tab ne sont pris qu'après une flèche depuis l'ouverture (self.armed).
function Popup:OnKey(f, key)
  -- en combat la propagation ne se règle plus (fonction protégée) : la fenêtre est déjà fermée
  if inCombat() then return end
  local handled = true
  if key == "ESCAPE" then
    self:Later()
  elseif key == "RIGHT" or key == "LEFT" then
    self.armed = true
    self:MoveFocus(key == "RIGHT" and 1 or -1)
  elseif key == "TAB" and self.armed then
    self:MoveFocus((IsShiftKeyDown and IsShiftKeyDown()) and -1 or 1)
  elseif (key == "ENTER" or key == "NUMPADENTER") and self.armed then
    local card = self.cards and self.cards[self.focus or 0]
    if card then self:Choose(card.id) end
  else
    handled = false
  end
  if f.SetPropagateKeyboardInput then pcall(f.SetPropagateKeyboardInput, f, not handled) end
end

-- Relâchement : toujours transmis au jeu (une touche de déplacement relâchée après une flèche ne
-- reste pas enfoncée). Rien en combat (propagation protégée ; la fenêtre est alors fermée).
function Popup:OnKeyUp(f)
  if inCombat() then return end
  if f.SetPropagateKeyboardInput then pcall(f.SetPropagateKeyboardInput, f, true) end
end

---------------------------------------------------------------------------
-- Affichage
---------------------------------------------------------------------------
-- Ouvre le choix pour le chapitre fromId. manual = demandé par le joueur (/qf route, journal, suivi) :
-- s'affiche même avec l'option coupée ou après « Plus tard », et dit pourquoi rien ne s'ouvre.
-- En combat : rien n'est créé, la demande attend la fin du combat. -> true si la fenêtre est montrée.
function Popup:Open(fromId, manual)
  manual = manual == true
  if not manual and not automatic() then return false end
  if not Q.Guides:Get(fromId) then return false end
  local options = Q.Progress:RouteOptions(fromId)
  if #options < 2 then
    if manual then Q:Print(L.UI_ROUTECHOICE_NONE) end
    return false
  end
  if not manual and isDismissed(fromId) then return false end
  if inCombat() then
    self.resume = { fromId = fromId, manual = manual }
    if manual then Q:Print(L.UI_ROUTECHOICE_AFTER_COMBAT) end
    return false
  end
  self.resume = nil
  self.fromId, self.manual = fromId, manual
  self.armed = false   -- aucune flèche depuis l'ouverture : Entrée et Tab passent au jeu
  self.cards = Q.RouteChoice:Rank(options)
  local f = self:Create()
  local was = f:IsShown()
  self:Fill(fromId, self.cards)
  f:Show()
  if not was and self.fadeIn then self.fadeIn:Play() end
  self:SetKeyboard(true)
  return true
end

function Popup:IsShown()
  return self.frame ~= nil and self.frame:IsShown()
end

-- Ferme sans rien retenir (combat, choix fait, option coupée).
function Popup:Close()
  if self.frame and self.frame:IsShown() then
    self.closing = true
    self.frame:Hide()
    self.closing = false
  end
  for _, c in ipairs(self.cardFrames) do c.pulse:Stop() end
  self:SetKeyboard(false)
end

-- Le joueur ferme sans choisir : si le chapitre attendait ce choix, plus de réouverture automatique.
function Popup:Dismiss(fromId)
  if self.cards and self.cards.demo then return end   -- scène /qf demo : rien n'est retenu
  if fromId and Q.Progress:PendingChoice() == fromId then
    local set = dismissedSet(true)
    if set then set[fromId] = true end
  end
end

-- « Plus tard », Échap, croix : le chapitre reste en attente (Progress:PendingChoice).
function Popup:Later()
  self.resume = nil
  self:Close()
  self:Dismiss(self.fromId)
end
Popup.Hide = Popup.Later

-- Fenêtre cachée par le jeu (Échap par UISpecialFrames, fermeture de toutes les fenêtres) : comme
-- « Plus tard ». Un parent caché (interface masquée) n'est pas une fermeture.
function Popup:OnFrameHidden(f)
  if self.closing or f:IsShown() then return end
  for _, c in ipairs(self.cardFrames) do c.pulse:Stop() end
  self:SetKeyboard(false)
  self.resume = nil
  self:Dismiss(self.fromId)
end

function Popup:Choose(id)
  local fromId = self.fromId
  if self.cards and self.cards.demo then fromId = nil end   -- scène /qf demo : ferme sans choisir
  self.resume = nil
  self:Close()
  if fromId and id then Q.Progress:ChooseRoute(fromId, id) end
end

-- « Garder la route prévue » : la suite par défaut (Guides:Next).
function Popup:Keep()
  for _, c in ipairs(self.cards or {}) do
    if c.default then return self:Choose(c.id) end
  end
  self:Later()
end

-- Début de combat : la fenêtre ouverte se ferme et sera rouverte à la fin.
function Popup:Suspend()
  if self:IsShown() then
    self.resume = { fromId = self.fromId, manual = self.manual }
    self:Close()
  else
    self:SetKeyboard(false)
  end
end

-- Fin de combat : la demande en attente (ou la fenêtre fermée par le combat) s'ouvre, sauf si le
-- choix a été fait entre-temps.
function Popup:Resume()
  local r = self.resume
  if not r or inCombat() then return end
  self.resume = nil
  if not r.manual and Q.Progress:PendingChoice() ~= r.fromId then return end
  self:Open(r.fromId, r.manual)
end

-- Choix demandé par le joueur : le chapitre en attente, sinon celui de Progress:ChoiceNode.
function Popup:OpenForPlayer()
  local node = Q.Progress:PendingChoice() or Q.Progress:ChoiceNode()
  if not node then
    Q:Print(L.UI_ROUTECHOICE_NONE)
    return false
  end
  return self:Open(node, true)
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
Q:On("ROUTE_CHOICE_NEEDED", function(fromId) Popup:Open(fromId) end)
Q:On("ROUTE_CHOSEN", function(fromId)
  local set = dismissedSet(false)
  if set then set[fromId] = nil end
  if Popup.resume and Popup.resume.fromId == fromId then Popup.resume = nil end
  if Popup:IsShown() and Popup.fromId == fromId then Popup:Close() end
end)
Q:RegisterEvent("PLAYER_REGEN_DISABLED", function() Popup:Suspend() end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function() Popup:Resume() end)
-- Nouvelle connexion (pas un /reload) : les choix remis à plus tard sont redemandés.
Q:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, isInitialLogin)
  if isInitialLogin ~= true then return end
  local set = dismissedSet(false)
  if set then Q.char.routeChoiceDismissed = {} end
  local pending = Q.Progress and Q.Progress:PendingChoice()
  if pending and not Popup:IsShown() then Popup:Open(pending) end
end)
Q:On("SETTINGS_CHANGED", function(path)
  if (path == "route" or path == "route.choicePopup") and not automatic() then
    Popup.resume = nil
    Popup:Close()
  end
end)
