local addonName, Q = ...

-- Thèmes visuels du suivi (UI/Tracker.lua) : fond, bordure, couleurs du texte et ombre.
--   parchment   (défaut) parchemin de la fenêtre des quêtes, fine bordure dorée, texte brun foncé ;
--   dark        fond noir, bordure discrète, texte clair ;
--   transparent ni fond ni bordure, texte clair cerné de noir (lisible sur le monde) ;
--   gradient    fondu vertical du gris foncé (en haut) au transparent (en bas), texte clair ombré.
-- Réglages : tracker.theme (clé) et tracker.opacity (0 à 1). L'opacité ne touche que le fond et la
-- bordure : le texte reste toujours opaque.
-- Textures et atlas : uniquement ceux de l'interface de Blizzard pour Forever (QuestBG-Parchment est
-- le fond des fenêtres de quête, Blizzard_UIPanels_Game/Mainline/QuestFrameTemplates.xml). Atlas
-- absent du client : couleur unie de secours, sans erreur.
Q.UI = Q.UI or {}
local Themes = {}
Q.Themes = Themes

local L = Q.L

local DEFAULT_KEY = "parchment"
local DEFAULT_OPACITY = 0.9
Themes.DEFAULT_KEY, Themes.DEFAULT_OPACITY = DEFAULT_KEY, DEFAULT_OPACITY

---------------------------------------------------------------------------
-- Bordures (BackdropTemplate, bordure seule : le fond est une texture à part)
---------------------------------------------------------------------------
-- Tables constantes : SetBackdrop ne refait rien quand on lui redonne la même table.
local TOOLTIP_EDGE = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tileEdge = true,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

---------------------------------------------------------------------------
-- Couleurs du texte
---------------------------------------------------------------------------
-- Rôles : title (titre du chapitre), body (étape courante), dim (étapes suivantes, niveaux des
-- monstres), levels (niveaux du chapitre), distance, bar (texte de la barre), xp (ligne XP/h),
-- warn (avertissements), alertes (classAlert, dungeonAlert, trainerAlert).
local LIGHT_TEXT = {
  title = { 1, 0.82, 0 },
  body = { 1, 1, 1 },
  dim = { 0.5, 0.5, 0.5 },
  levels = { 1, 1, 1 },
  distance = { 1, 1, 1 },
  bar = { 1, 1, 1 },
  xp = { 0.75, 0.85, 1 },
  warn = { 1, 0.82, 0 },
  classAlert = { 1, 0.82, 0 },
  dungeonAlert = { 1, 0.7, 0.4 },
  trainerAlert = { 0.5, 0.85, 1 },
}

-- Sur le monde, le gris des étapes suivantes est éclairci.
local OVERLAY_TEXT = {}
for role, c in pairs(LIGHT_TEXT) do OVERLAY_TEXT[role] = c end
OVERLAY_TEXT.dim = { 0.72, 0.72, 0.72 }

-- Encre brune sur parchemin (proche du texte des fenêtres de quête).
local PARCHMENT_TEXT = {
  title = { 0.30, 0.13, 0 },
  body = { 0.17, 0.10, 0.03 },
  dim = { 0.36, 0.27, 0.16 },
  levels = { 0.36, 0.27, 0.16 },
  distance = { 0.25, 0.15, 0.05 },
  bar = { 1, 1, 1 },
  xp = { 0.12, 0.25, 0.50 },
  warn = { 0.55, 0.30, 0 },
  classAlert = { 0.48, 0.27, 0 },
  dungeonAlert = { 0.60, 0.22, 0.04 },
  trainerAlert = { 0.08, 0.30, 0.55 },
}

-- Codes de couleur intégrés aux textes (Engine/Format.lua, textes, modules de confort, suivi)
-- remplacés sur parchemin par une teinte foncée de même sens : les noms de quête restent mis en
-- valeur (ambre foncé), les PNJ en vert, les monstres en rouge, les objets en bleu.
local PARCHMENT_CODES = {
  ffffffff = "ff2b1a08",   -- objectif à faire, objectif suivi par la flèche
  ffffd100 = "ff7a3d00",   -- nom de quête, groupes du mode zone
  ff00ff96 = "ff00663a",   -- PNJ
  ffff6060 = "ffa31414",   -- monstre
  ff66bbff = "ff1d4f8c",   -- objet du monde
  ff999999 = "ff5e4b33",   -- note
  ff808080 = "ff7d6b52",   -- fait
  ffaaaaaa = "ff6a5841",   -- niveau, texte gris
  ffc8c8c8 = "ff45341e",   -- objectif du mode zone
  ff40e050 = "ff1f6e1f",   -- ligne de la zone
  ff40ff40 = "ff1a6e1a",   -- pierre de foyer prête
  ffff5555 = "ffa31414",   -- raison du blocage
  ffffb040 = "ff8a4b00",   -- pierre de foyer en recharge
  ffff8040 = "ffa03a00",   -- danger
  ffffd040 = "ff7a5200",   -- sacs, réparation
}

local SHADOW = { color = { 0, 0, 0, 1 }, x = 1, y = -1 }
local NO_SHADOW = { color = { 0, 0, 0, 0 }, x = 0, y = 0 }

---------------------------------------------------------------------------
-- Thèmes
---------------------------------------------------------------------------
-- background.kind : "atlas" (fallback = couleur si l'atlas manque), "color", "gradient" (from =
-- bas, to = haut en VERTICAL, comme SetGradient) ou "none".
-- border : { backdrop, color = { r, g, b, a }, inset } ou nil.
-- bar : couleurs de la barre de progression ; glowBlend : mode de fusion des lueurs d'alerte (ADD
-- disparaît sur un fond clair).
local THEMES = {
  parchment = {
    label = "UI_THEME_PARCHMENT",
    background = { kind = "atlas", atlas = "QuestBG-Parchment", fallback = { 0.87, 0.78, 0.60 } },
    border = { backdrop = TOOLTIP_EDGE, color = { 0.72, 0.55, 0.25, 1 }, inset = 3 },
    text = PARCHMENT_TEXT,
    codes = PARCHMENT_CODES,
    shadow = NO_SHADOW,
    bar = { fill = { 0.55, 0.35, 0.10 }, bg = { 0.20, 0.12, 0.04, 0.55 } },
    glowBlend = "BLEND",
  },
  dark = {
    label = "UI_THEME_DARK",
    background = { kind = "color", color = { 0, 0, 0 } },
    border = { backdrop = TOOLTIP_EDGE, color = { 0.5, 0.5, 0.5, 0.8 }, inset = 3 },
    text = LIGHT_TEXT,
    shadow = SHADOW,
    bar = { fill = { 0.26, 0.56, 0.95 }, bg = { 0, 0, 0, 0.5 } },
    glowBlend = "ADD",
  },
  transparent = {
    label = "UI_THEME_TRANSPARENT",
    background = { kind = "none" },
    text = OVERLAY_TEXT,
    shadow = SHADOW,
    outline = true,
    bar = { fill = { 0.26, 0.56, 0.95 }, bg = { 0, 0, 0, 0.5 } },
    glowBlend = "ADD",
  },
  gradient = {
    label = "UI_THEME_GRADIENT",
    background = { kind = "gradient", orientation = "VERTICAL",
      from = { 0.12, 0.12, 0.12, 0 }, to = { 0.12, 0.12, 0.12, 1 } },
    text = OVERLAY_TEXT,
    shadow = SHADOW,
    bar = { fill = { 0.26, 0.56, 0.95 }, bg = { 0, 0, 0, 0.5 } },
    glowBlend = "ADD",
  },
}
local ORDER = { "parchment", "dark", "transparent", "gradient" }
for key, theme in pairs(THEMES) do theme.key = key end
Themes.themes = THEMES

---------------------------------------------------------------------------
-- Accès
---------------------------------------------------------------------------
-- Clé valide, sinon nil. Accepte aussi le nom affiché, sans tenir compte de la casse.
function Themes:Find(key)
  if type(key) ~= "string" then return nil end
  if THEMES[key] then return key end
  local wanted = key:lower()
  for _, k in ipairs(ORDER) do
    if k == wanted or tostring(L[THEMES[k].label]):lower() == wanted then return k end
  end
  return nil
end

-- Clé valide (parchemin pour une clé inconnue ou absente).
function Themes:Resolve(key)
  return self:Find(key) or DEFAULT_KEY
end

-- Q.Themes:Get(key) -> thème ; clé inconnue : parchemin.
function Themes:Get(key)
  return THEMES[self:Resolve(key)]
end

-- Q.Themes:List() -> { { key, label } } dans l'ordre d'affichage.
function Themes:List()
  local out = {}
  for _, k in ipairs(ORDER) do out[#out + 1] = { key = k, label = L[THEMES[k].label] } end
  return out
end

-- Opacité du fond et de la bordure, ramenée entre 0 et 1 (0,9 si absente ou illisible).
function Themes:Opacity(value)
  local v = tonumber(value)
  if not v or v ~= v then return DEFAULT_OPACITY end
  return math.max(0, math.min(1, v))
end

-- Thème du réglage tracker.theme.
function Themes:Current()
  return self:Get(Q.Settings and Q.Settings:Get("tracker.theme"))
end

---------------------------------------------------------------------------
-- Texte
---------------------------------------------------------------------------
-- Remplace les codes de couleur connus par ceux du thème (texte inchangé sans table de codes).
function Themes:Recolor(text, theme)
  if type(text) ~= "string" then return text end
  theme = theme or self:Current()
  local map = theme and theme.codes
  if not map or not text:find("|c", 1, true) then return text end
  return (text:gsub("|c(%x%x%x%x%x%x%x%x)", function(hex)
    local to = map[hex:lower()]
    if to then return "|c" .. to end
  end))
end

-- Couleur d'un rôle : { r, g, b } (body pour un rôle inconnu).
function Themes:TextColor(role, theme)
  theme = theme or self:Current()
  return theme.text[role] or theme.text.body
end

-- Couleur, ombre et contour d'une ligne de texte. Le texte reste opaque quelle que soit
-- l'opacité. La police d'origine est gardée pour retirer le contour d'un thème à l'autre.
function Themes:StyleText(fs, role, theme)
  if not fs then return end
  theme = theme or self:Current()
  local c = self:TextColor(role, theme)
  fs:SetTextColor(c[1], c[2], c[3], 1)
  local sh = theme.shadow or SHADOW
  if fs.SetShadowColor then fs:SetShadowColor(sh.color[1], sh.color[2], sh.color[3], sh.color[4]) end
  if fs.SetShadowOffset then fs:SetShadowOffset(sh.x, sh.y) end
  local base = fs.qvBaseFont
  if not base and fs.GetFont then
    local file, size, flags = fs:GetFont()
    if type(file) == "string" and tonumber(size) then
      base = { file, size, flags or "" }
      fs.qvBaseFont = base
      fs.qvFontFlags = base[3]   -- police d'origine : SetFont seulement pour un contour
    end
  end
  if base and fs.SetFont then
    local flags = theme.outline and "OUTLINE" or base[3]
    if fs.qvFontFlags ~= flags then
      fs:SetFont(base[1], base[2], flags)
      fs.qvFontFlags = flags
    end
  end
end

---------------------------------------------------------------------------
-- Fond et bordure
---------------------------------------------------------------------------
-- Vrai si l'atlas existe dans le client (C_Texture.GetAtlasInfo) ; sans cette API, SetAtlas est
-- tenté sous pcall.
local function atlasAvailable(atlas)
  if type(atlas) ~= "string" or atlas == "" then return false end
  local CT = C_Texture
  if type(CT) == "table" and type(CT.GetAtlasInfo) == "function" then
    local ok, info = pcall(CT.GetAtlasInfo, atlas)
    return ok and info ~= nil
  end
  return true
end
Themes.AtlasAvailable = atlasAvailable

-- Texture de fond propre au thème (créée une fois, sous la bordure et le contenu).
local function backgroundTexture(frame, field, subLevel)
  local tx = frame[field]
  if not tx then
    tx = frame:CreateTexture(nil, "BACKGROUND", nil, subLevel)
    frame[field] = tx
  end
  return tx
end

local function fit(tx, frame, inset)
  tx:ClearAllPoints()
  tx:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
  tx:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
end

-- Fond en dégradé : texture blanche teintée par SetGradient (CreateColor). Sans ces API :
-- couleur unie à mi-chemin.
local function applyGradient(tx, spec)
  local from, to = spec.from, spec.to
  tx:SetColorTexture(1, 1, 1, 1)
  if type(CreateColor) == "function" and tx.SetGradient then
    local ok = pcall(tx.SetGradient, tx, spec.orientation or "VERTICAL",
      CreateColor(from[1], from[2], from[3], from[4]), CreateColor(to[1], to[2], to[3], to[4]))
    if ok then return "gradient" end
  end
  tx:SetColorTexture(to[1], to[2], to[3], ((from[4] or 1) + (to[4] or 1)) / 2)
  return "color"
end

-- Q.Themes:Apply(frame, themeKey, opacity) -> thème appliqué.
-- Pose le fond (atlas, couleur ou dégradé) et la bordure du thème sur frame (BackdropTemplate
-- pour la bordure). Le fond et la bordure prennent l'opacité ; frame garde un alpha de 1, le texte
-- n'est donc jamais atténué. frame.qvThemeBackground = "atlas" | "color" | "gradient" | "none".
function Themes:Apply(frame, themeKey, opacity)
  local theme = self:Get(themeKey)
  if not frame then return theme end
  local alpha = self:Opacity(opacity)
  local spec = theme.background or { kind = "none" }
  local inset = theme.border and theme.border.inset or 0
  local solid = backgroundTexture(frame, "qvThemeBg", -8)
  local grad = backgroundTexture(frame, "qvThemeGradient", -7)
  fit(solid, frame, inset)
  fit(grad, frame, inset)
  solid:Hide()
  grad:Hide()
  local used = "none"
  if spec.kind == "atlas" then
    if atlasAvailable(spec.atlas) and pcall(solid.SetAtlas, solid, spec.atlas) then
      solid:SetVertexColor(1, 1, 1, 1)
      used = "atlas"
    else
      local c = spec.fallback or { 0.87, 0.78, 0.60 }
      solid:SetColorTexture(c[1], c[2], c[3], 1)
      used = "color"
    end
    solid:Show()
  elseif spec.kind == "color" then
    local c = spec.color
    solid:SetColorTexture(c[1], c[2], c[3], 1)
    solid:Show()
    used = "color"
  elseif spec.kind == "gradient" then
    used = applyGradient(grad, spec)
    grad:Show()
  end
  solid:SetAlpha(alpha)
  grad:SetAlpha(alpha)
  frame.qvThemeBackground = used

  if frame.SetBackdrop then
    local border = theme.border
    if border then
      frame:SetBackdrop(border.backdrop)
      local c = border.color
      if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(c[1], c[2], c[3], (c[4] or 1) * alpha)
      end
    else
      frame:SetBackdrop(nil)
    end
  end
  frame.qvThemeKey, frame.qvThemeOpacity = theme.key, alpha
  return theme
end
