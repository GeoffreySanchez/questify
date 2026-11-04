local addonName, Q = ...

-- Accroche à la fenêtre des talents du jeu (Blizzard_PlayerSpells, variante Camelot de Forever ;
-- spec 2.3, 2.4, 7.7, 7.13) :
--   * trois onglets à nous, « Talents », « Build », « Sorts à apprendre » (ces deux-là marqués « Q »),
--     sous la fenêtre, là où serait son TabSystem principal caché (TOPLEFT sur BOTTOMLEFT, x = 22, y = 2),
--     visibles seulement quand l'affichage des talents (PlayerSpellsFrame.TalentsFrame) est montré ;
--     « Build » et « Sorts » ouvrent Q.UI.BuildWindow (si elle existe, jamais en combat), « Talents » la
--     referme ;
--   * une bande en haut de l'affichage des talents : build suivi et prochain point (« Modifier le
--     build »), écart au build (« Créer un build à partir de mon arbre »), build obsolète (« ⚠ Build
--     obsolète : <raison> », « Choisir un build ») ou aucun build ;
--   * un halo doré, coin « Q », sur le bouton du prochain talent du build ;
--   * une ligne Questify dans l'infobulle de ce talent.
-- Bande et halo sont cachés tant qu'un onglet Questify est choisi. Onglets, bande, halo et ligne
-- d'infobulle disparaissent quand l'affichage montre un autre joueur (IsInspecting) ou l'autre
-- spécialisation (IsActiveTabSelected faux) : nos données sont celles de la configuration active.
-- Les données viennent de Talents:State(), indépendant du réglage talentAlert (popup et suivi seulement).
-- Règles d'intégration (aucune « action bloquée », aucune contamination de l'interface du jeu) :
--   * rien sur les TabSystem de Blizzard (pas d'AddNamedTab), aucune méthode ni fonction de mixin
--     remplacée, aucun SetScript sur un cadre de Blizzard : seulement HookScript ;
--   * aucun cadre de Blizzard caché, montré, déplacé ni re-parenté : seuls nos cadres bougent ;
--   * nos cadres sont créés hors combat (accroche remise à PLAYER_REGEN_ENABLED) ; montrer, cacher ou
--     re-parenter ensuite nos cadres non sécurisés est permis, même en combat ;
--   * le halo ne prend pas la souris : le clic sur le talent reste celui du jeu (point en attente, puis
--     « Appliquer »).
-- Les onglets sont posés dans un support à nous, enfant de PlayerSpellsFrame : PanelTabButtonTemplate
-- porte parentArray="Tabs", qui écrirait sinon le tableau PlayerSpellsFrame.Tabs depuis notre code.
-- Les boutons de talent du jeu sont recyclés (pool) : celui du prochain talent est retrouvé par
-- TalentsFrame:GetTalentButtonByNodeID à chaque rafraîchissement (TALENTS_CHANGED, qui suit aussi
-- TRAIT_CONFIG_UPDATED, BUILDS_CHANGED, affichage) et toutes les POLL secondes par notre veilleur (cadre
-- invisible, enfant de l'affichage), qui suit aussi l'inspection et l'onglet de spécialisation ;
-- l'infobulle vérifie le nœud du bouton au moment du survol.
-- Fenêtre absente ou changée par une mise à jour (cadre ou méthode manquante) : IsHooked() == false,
-- sans erreur ni nouvel essai.
Q.UI = Q.UI or {}
local Hook = { hooked = false, pending = false, failed = false, open = false, live = false,
  selected = "talents", tabs = {}, tabsByKey = {} }
Q.UI.TalentFrameHook = Hook

local L = Q.L

local PLAYER_SPELLS = "Blizzard_PlayerSpells"
local TAB_X, TAB_Y = 22, 2          -- TabSystem caché de PlayerSpellsFrame (Camelot)
local TAB_GAP = 3
local TAB_PADDING = 30              -- place de la marque « Q » et de la pastille (lu par PanelTabButtonMixin)
local TAB_FALLBACK_H = 24
local BAND_Y = -94                  -- sous l'en-tête (onglets de spécialisation, « Actif ») de l'affichage
local BAND_W, BAND_H = 660, 26
local BAND_BUTTON_H = 20
local BAND_LEVEL = 905              -- au-dessus du fond de l'affichage des talents
local HALO_PAD = 12
local HALO_LEVEL = 5
local POLL = 0.25
local GOLD_R, GOLD_G, GOLD_B = 1, 0.82, 0
local QF_R, QF_G, QF_B = 0.35, 0.78, 1    -- couleur des lignes Questify

local TABS = {
  { key = "talents", label = "TALENT_TAB_TALENTS" },
  { key = "build", label = "TALENT_TAB_BUILD", q = true },
  { key = "spells", label = "TALENT_TAB_SPELLS", q = true, pill = true },
}

-- Raisons de Builds:SetActive / Builds:Validate -> texte.
local REASONS = {
  unknown = "TALENT_REASON_UNKNOWN", missing = "TALENT_REASON_MISSING", maxrank = "TALENT_REASON_MAXRANK",
  tier = "TALENT_REASON_TIER", requires = "TALENT_REASON_REQUIRES", toolong = "TALENT_REASON_TOOLONG",
}

local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function plain(v)
  if Q.Util.IsSecret(v) then return nil end
  return v
end

-- obj:method(...) protégé ; valeur secrète -> nil.
local function call(obj, method, ...)
  local fn = type(obj) == "table" and obj[method]
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, obj, ...)
  if ok then return plain(v) end
  return nil
end

local function spellName(id)
  if type(C_Spell) == "table" and type(C_Spell.GetSpellName) == "function" then
    local ok, v = pcall(C_Spell.GetSpellName, id)
    if ok then return plain(v) end
  end
  return nil
end

-- PlayerSpellsFrame et son affichage des talents, ou nil si la fenêtre manque ou a changé.
local function gameFrames()
  local host = PlayerSpellsFrame
  if type(host) ~= "table" then return nil end
  local talents = host.TalentsFrame
  if type(talents) ~= "table" then return nil end
  for _, m in ipairs({ "HookScript", "IsShown", "GetTalentButtonByNodeID" }) do
    if type(talents[m]) ~= "function" then return nil end
  end
  return host, talents
end

local function isOpen(frame)
  local v = call(frame, "IsVisible")
  if v == nil then v = call(frame, "IsShown") end
  return v == true
end

---------------------------------------------------------------------------
-- Données : Talents:State()
---------------------------------------------------------------------------
local function spentPoints(tree)
  local n = 0
  for _, node in pairs(tree.nodes or {}) do n = n + (node.rank or 0) end
  return n
end

-- Prochain point du build quand aucun n'est à dépenser : Builds:Due sur l'arbre avec un point fictif.
local function upcoming(build, tree)
  local probe = {}
  for k, v in pairs(tree) do probe[k] = v end
  probe.unspent = 1
  return Q.Builds:Due(build, probe)[1]
end

-- { unspent, build, tree, due = { … }, deviates, upcoming, done } d'après Talents:State() ; sans arbre
-- lisible, seulement le build actif.
local function snapshot()
  local s = Q.Talents and Q.Talents:State()
  if not s then
    return { unspent = 0, build = Q.Builds and Q.Builds:Active() or nil, due = {}, deviates = false }
  end
  s.due = s.due or {}
  if s.obsolete then return s end   -- build obsolète : ni prochain point ni halo
  if s.build and s.tree and (s.unspent or 0) <= 0 then
    -- aucun point maintenant : le prochain point du build, avec son niveau
    s.upcoming = upcoming(s.build, s.tree)
  end
  if s.build and s.tree and not s.due[1] then
    s.done = #(s.build.order or {}) <= spentPoints(s.tree)
  end
  return s
end

local function entryText(entry)
  return string.format(L.TALENT_BAND_NEXT, spellName(entry.spellID) or "?", entry.rank or 1,
    entry.node and entry.node.maxRanks or 1)
end

local function nextText(s)
  if s.due[1] then return entryText(s.due[1]) end
  if s.upcoming then return string.format(L.TALENT_BAND_NEXT_AT, entryText(s.upcoming), s.upcoming.level or 0) end
  if s.done then return L.TALENT_BAND_DONE end
  return L.TALENT_BAND_NO_NEXT
end

local function spellsToLearn()
  local S = Q.SpellList
  if type(S) ~= "table" or type(S.Summary) ~= "function" then return nil end
  local ok, sum = pcall(S.Summary, S)
  if not ok or type(sum) ~= "table" then return nil end
  return tonumber(sum.now)
end

-- Affichage des talents ouvert sur la configuration active du joueur : pas en inspection, onglet de la
-- spécialisation active. Méthode absente : pas d'inspection, onglet actif.
function Hook:IsLive()
  if not self.open then return false end
  local talents = self.talents
  if call(talents, "IsInspecting") == true then return false end
  if call(talents, "IsActiveTabSelected") == false then return false end
  return true
end

---------------------------------------------------------------------------
-- Fenêtre des builds (tâche 9) et onglets
---------------------------------------------------------------------------
local function buildWindow()
  local W = Q.UI.BuildWindow
  return type(W) == "table" and W or nil
end

local function paintTabs()
  local selectTab, deselectTab = PanelTemplates_SelectTab, PanelTemplates_DeselectTab
  for _, tab in ipairs(Hook.tabs) do
    local on = tab.qfKey == Hook.selected
    if tab.qfPanel and type(selectTab) == "function" and type(deselectTab) == "function" then
      pcall(on and selectTab or deselectTab, tab)
    elseif on then
      tab:LockHighlight()
    else
      tab:UnlockHighlight()
    end
  end
end

-- Onglet « build » ou « spells » : fenêtre des builds posée sur PlayerSpellsFrame. Sans elle, ou en
-- combat, le clic est ignoré (rien d'affiché).
function Hook:OpenWindow(tab)
  if inCombat() then return false end
  local W = buildWindow()
  if not W or type(W.Open) ~= "function" then return false end
  if type(W.SetHost) == "function" then W:SetHost(self.host) end
  W:Open(tab)
  self.selected = tab
  paintTabs()
  self:UpdateVisibility()
  return true
end

-- Rend la fenêtre des builds à l'autonome (I1) : /qf build, la minicarte et la popup l'ouvrent ensuite
-- seule, pas dans la fenêtre du jeu cachée. En combat, BuildWindow:SetHost diffère le changement.
local function releaseHost()
  local W = buildWindow()
  if W and type(W.SetHost) == "function" then W:SetHost(nil) end
end

function Hook:CloseWindow()
  local W = buildWindow()
  if W and type(W.Close) == "function" then W:Close() end
  releaseHost()
  self.selected = "talents"
  paintTabs()
  self:UpdateVisibility()
end

function Hook:SelectTab(key)
  if key == "talents" then self:CloseWindow() else self:OpenWindow(key) end
end

-- « Q » doré : nos onglets, la bande et le coin du halo. Ne prend pas la souris.
local function qBadge(parent, size)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(size, size)
  f:EnableMouse(false)
  local bg = f:CreateTexture(nil, "ARTWORK")
  bg:SetAllPoints(f)
  bg:SetColorTexture(GOLD_R, GOLD_G, GOLD_B, 1)
  local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("CENTER", f, "CENTER", 0, 0)
  text:SetText("Q")
  text:SetTextColor(0.16, 0.11, 0.02, 1)
  f.text = text
  return f
end

local function hasTemplate(name)
  local X = C_XMLUtil
  if type(X) == "table" and type(X.GetTemplateInfo) == "function" then
    local ok, info = pcall(X.GetTemplateInfo, name)
    return ok and info ~= nil
  end
  return true   -- sans moyen de savoir, CreateFrame (protégé) tranche
end

-- Onglet au modèle du jeu, sinon simple bouton ; -> bouton, modèle d'onglet ?
local function newTab(parent, name)
  if hasTemplate("PanelTabButtonTemplate") then
    local ok, tab = pcall(CreateFrame, "Button", name, parent, "PanelTabButtonTemplate")
    if ok and tab then return tab, true end
  end
  return CreateFrame("Button", name, parent, "UIPanelButtonTemplate"), false
end

local function tabText(tab)
  return call(tab, "GetFontString") or tab.Text
end

local function fitTab(tab)
  if tab.qfPanel then
    if type(PanelTemplates_TabResize) == "function" then pcall(PanelTemplates_TabResize, tab, TAB_PADDING) end
  else
    local w = call(tab, "GetTextWidth")
    tab:SetSize(math.max(90, (type(w) == "number" and w or 0) + TAB_PADDING + 20), TAB_FALLBACK_H)
  end
end

local function createTabs(host)
  local holder = CreateFrame("Frame", "QuestifyTalentTabs", host)
  holder:SetSize(1, 32)
  holder:SetPoint("TOPLEFT", host, "BOTTOMLEFT", TAB_X, TAB_Y)
  holder.tabPadding = TAB_PADDING   -- lu par PanelTabButtonMixin:OnShow (PanelTemplates_TabResize)
  holder:Hide()
  local prev
  for i, def in ipairs(TABS) do
    local tab, panel = newTab(holder, "QuestifyTalentTab" .. i)
    tab.qfKey, tab.qfPanel = def.key, panel
    tab:SetText(L[def.label])
    fitTab(tab)
    if prev then tab:SetPoint("LEFT", prev, "RIGHT", TAB_GAP, 0) else tab:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0) end
    local fs = tabText(tab)
    if def.q then
      local badge = qBadge(tab, 12)
      if type(fs) == "table" then badge:SetPoint("RIGHT", fs, "LEFT", -3, 0) else badge:SetPoint("LEFT", tab, "LEFT", 10, 0) end
      tab.qfBadge = badge
    end
    if def.pill then
      local pill = CreateFrame("Frame", nil, tab)
      pill:SetSize(18, 14)
      pill:EnableMouse(false)
      local bg = pill:CreateTexture(nil, "ARTWORK")
      bg:SetAllPoints(pill)
      bg:SetColorTexture(0.35, 0.72, 0.36, 1)
      local n = pill:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      n:SetPoint("CENTER", pill, "CENTER", 0, 0)
      n:SetTextColor(0, 0, 0, 1)
      pill.text = n
      if type(fs) == "table" then pill:SetPoint("LEFT", fs, "RIGHT", 3, 0) else pill:SetPoint("RIGHT", tab, "RIGHT", -10, 0) end
      pill:Hide()
      tab.qfPill = pill
    end
    local key = def.key
    tab:SetScript("OnClick", function() Q.SafeCall(Hook.SelectTab, Hook, key) end)
    Hook.tabs[i] = tab
    Hook.tabsByKey[key] = tab
    prev = tab
  end
  return holder
end

function Hook:UpdatePill()
  local tab = self.tabsByKey.spells
  local pill = tab and tab.qfPill
  if not pill then return end
  local n = spellsToLearn()
  if n and n > 0 then
    pill.text:SetText(tostring(n))
    pill:Show()
  else
    pill:Hide()
  end
end

---------------------------------------------------------------------------
-- Bande en haut de l'affichage des talents
---------------------------------------------------------------------------
local function createBand(talents)
  local band = CreateFrame("Frame", "QuestifyTalentBand", talents, "BackdropTemplate")
  band:SetSize(BAND_W, BAND_H)
  band:SetPoint("TOP", talents, "TOP", 0, BAND_Y)
  band:SetFrameLevel((call(talents, "GetFrameLevel") or 1) + BAND_LEVEL)
  band:EnableMouse(false)
  if band.SetBackdrop then
    band:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    band:SetBackdropColor(0.05, 0.14, 0.19, 0.92)
    band:SetBackdropBorderColor(0.18, 0.35, 0.43, 1)
  end
  local logo = qBadge(band, 16)
  logo:SetPoint("LEFT", band, "LEFT", 6, 0)
  local button = CreateFrame("Button", nil, band, "UIPanelButtonTemplate")
  button:SetSize(150, BAND_BUTTON_H)
  button:SetPoint("RIGHT", band, "RIGHT", -4, 0)
  button:SetScript("OnClick", function() Q.SafeCall(Hook.OnBandClick, Hook) end)
  local text = band:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("LEFT", logo, "RIGHT", 6, 0)
  text:SetPoint("RIGHT", button, "LEFT", -8, 0)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(false)
  band.logo, band.button, band.text = logo, button, text
  band:Hide()
  return band
end

-- Veilleur : cadre invisible à nous, sans souris, montré avec l'affichage des talents (même en
-- inspection ou sur l'autre onglet, quand bande et onglets sont cachés).
local function createWatcher(talents)
  local watcher = CreateFrame("Frame", nil, talents)
  watcher:SetSize(1, 1)
  watcher:EnableMouse(false)
  local elapsed = 0
  watcher:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + (dt or 0)
    if elapsed < POLL then return end
    elapsed = 0
    Q.SafeCall(Hook.Tick, Hook)
  end)
  return watcher
end

-- Textes de la bande (la montrer ou la cacher revient à UpdateVisibility).
function Hook:UpdateBand(s)
  local band = self.band
  local name = s.build and Q.Builds:Name(s.build) or ""
  if not s.build then
    band.mode = "none"
    band.text:SetText(L.TALENT_BAND_NONE)
    band.button:SetText(L.UI_TALENT_NO_BUILD)
  elseif s.obsolete then
    band.mode = "obsolete"
    band.text:SetText(string.format(L.TALENT_BAND_OBSOLETE,
      L["BUILD_OBSOLETE_" .. tostring(s.obsolete)] or tostring(s.obsolete)))
    band.button:SetText(L.UI_TALENT_NO_BUILD)
  elseif s.deviates and s.tree then
    band.mode = "tree"
    band.text:SetText(string.format(L.TALENT_BAND_DEVIATES, name))
    band.button:SetText(L.TALENT_BAND_FROM_TREE)
  else
    band.mode = "edit"
    band.text:SetText(string.format(L.TALENT_BAND_BUILD, name, nextText(s)))
    band.button:SetText(L.TALENT_BAND_EDIT)
  end
  local w = call(band.button, "GetTextWidth")
  band.button:SetWidth(math.max(120, (type(w) == "number" and w or 0) + 24))
end

-- Nom « Mon arbre (date heure) », suivi de « #n » s'il est déjà pris par un build de la classe.
local function treeBuildName(class)
  local stamp = type(date) == "function" and date("%Y-%m-%d %H:%M") or "?"
  local taken = {}
  for _, b in ipairs(Q.Builds:List(class)) do taken[Q.Builds:Name(b)] = true end
  local name, n = string.format(L.TALENT_TREE_BUILD_NAME, stamp), 1
  while taken[name] do
    n = n + 1
    name = string.format(L.TALENT_TREE_BUILD_NAME, stamp .. " #" .. n)
  end
  return name
end

-- « Créer un build à partir de mon arbre » : build perso tiré des rangs actuels, devenu le build suivi.
-- Refusé comme build suivi : il est supprimé (pas de copie à chaque clic) et la raison est dite.
function Hook:CreateFromTree()
  local s = self.state
  if not (s and s.tree) then return nil end
  local class = Q.Player and Q.Player.classFile
  local build = Q.Builds:FromTree(s.tree, class, s.build and s.build.specID)
  build.name = treeBuildName(class)
  local key = Q.Builds:Save(build)
  if not key then return nil end
  local ok, reason = Q.Builds:SetActive(Q.Builds:ActiveGroup(), key)
  if not ok then
    Q.Builds:Delete(key)
    Q:Print(L.TALENT_TREE_BUILD_FAILED, L[REASONS[reason] or "TALENT_REASON_UNKNOWN"])
    return nil
  end
  return key
end

function Hook:OnBandClick()
  local mode = self.band and self.band.mode
  if mode == "tree" then
    self:CreateFromTree()
  else
    self:OpenWindow("build")
  end
end

---------------------------------------------------------------------------
-- Halo et infobulle
---------------------------------------------------------------------------
local function createHalo(parent)
  local halo = CreateFrame("Frame", "QuestifyTalentHalo", parent)
  halo:EnableMouse(false)   -- le clic reste celui du jeu (spec 7.13)
  local glow = halo:CreateTexture(nil, "OVERLAY")
  glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(GOLD_R, GOLD_G, GOLD_B, 1)
  glow:SetPoint("TOPLEFT", halo, "TOPLEFT", -HALO_PAD, HALO_PAD)
  glow:SetPoint("BOTTOMRIGHT", halo, "BOTTOMRIGHT", HALO_PAD, -HALO_PAD)
  local pulse = glow:CreateAnimationGroup()
  pulse:SetLooping("BOUNCE")
  local fade = pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0.35)
  fade:SetDuration(0.7)
  halo:SetScript("OnShow", function() pulse:Play() end)
  halo:SetScript("OnHide", function() pulse:Stop() end)
  local badge = qBadge(halo, 14)
  badge:SetPoint("TOPLEFT", halo, "TOPLEFT", -6, 6)
  halo.qfGlow, halo.qfBadge = glow, badge
  halo:Hide()
  return halo
end

-- Boutons du jeu déjà accrochés (clés faibles : le jeu peut s'en défaire).
local hookedButtons = setmetatable({}, { __mode = "k" })

local function onButtonEnter(button)
  Q.SafeCall(Hook.OnButtonEnter, Hook, button)
end

local function hookButton(button)
  if hookedButtons[button] then return end
  hookedButtons[button] = true
  if type(button.HookScript) == "function" then pcall(button.HookScript, button, "OnEnter", onButtonEnter) end
end

-- Survol d'un bouton accroché : ligne Questify si c'est, à ce moment, le nœud du prochain talent de la
-- configuration active affichée (pas d'inspection, onglet actif) et que l'infobulle est bien à ce bouton
-- (le jeu la remplit plus tard quand le sort n'est pas encore chargé).
function Hook:OnButtonEnter(button)
  local entry = self.due
  local node = entry and entry.node
  if not node or self.selected ~= "talents" or not self:IsLive() then return end
  if call(button, "GetNodeID") ~= node.nodeID then return end
  local tip = GameTooltip
  if type(tip) ~= "table" then return end
  if type(tip.GetOwner) == "function" and call(tip, "GetOwner") ~= button then return end
  tip:AddLine(string.format(L.TALENT_TIP_NEXT, entry.level or 0, entry.rank or 1, node.maxRanks or 1),
    QF_R, QF_G, QF_B, true)
  tip:Show()   -- infobulle déjà au jeu : la remontrer après AddLine est permis, même en combat
end

-- Halo caché et rendu à notre bande : il ne reste pas enfant d'un bouton du jeu inutilisé.
-- (Cacher et re-parenter notre cadre non sécurisé est permis en combat.)
function Hook:DetachHalo()
  local halo = self.halo
  if not halo then return end
  halo:Hide()
  if self.haloButton then
    halo:SetParent(self.band)
    halo:ClearAllPoints()
    self.haloButton = nil
  end
end

-- Pose le halo sur le bouton actuel du prochain talent, ou le cache (onglet Questify choisi, inspection,
-- autre spécialisation, rien de dû). Re-parenter notre cadre non sécurisé est permis en combat.
function Hook:PlaceHalo()
  local halo = self.halo
  if not halo then return end
  local node = self.live and self.selected == "talents" and self.due and self.due.node
  local button = node and call(self.talents, "GetTalentButtonByNodeID", node.nodeID)
  if type(button) ~= "table" then
    self:DetachHalo()
    return
  end
  hookButton(button)
  if self.haloButton ~= button then
    halo:SetParent(button)
    halo:ClearAllPoints()
    halo:SetAllPoints(button)
    halo:SetFrameLevel((call(button, "GetFrameLevel") or 1) + HALO_LEVEL)
    self.haloButton = button
  end
  halo:Show()
end

---------------------------------------------------------------------------
-- Affichage
---------------------------------------------------------------------------
function Hook:IsHooked() return self.hooked == true end

-- Montre ou cache nos cadres selon l'état (montrer ou cacher nos cadres non sécurisés est permis en
-- combat) : onglets si l'affichage est à la configuration active ; bande et halo en plus si l'onglet
-- « Talents » est choisi. Inspection ou autre spécialisation avec un onglet Questify ouvert : on le ferme.
function Hook:UpdateVisibility()
  if not self.hooked then return end
  if not self.live and self.selected ~= "talents" then
    self.selected = "talents"
    local W = buildWindow()
    if W and type(W.Close) == "function" then W:Close() end
    paintTabs()
  end
  local talents = self.live and self.selected == "talents"
  if self.live then self.tabFrame:Show() else self.tabFrame:Hide() end
  if talents and self.state then self.band:Show() else self.band:Hide() end
  self:PlaceHalo()
end

-- Recalcule bande, halo et pastille ; rien tant que l'affichage des talents est caché, en inspection
-- ou sur l'autre spécialisation.
function Hook:Refresh()
  if not self.hooked or not self.open then return end
  self.live = self:IsLive()
  if self.live then
    local s = snapshot()
    self.state = s
    self.due = s.due[1]
    self:UpdateBand(s)
    self:UpdatePill()
  else
    self.due = nil
  end
  self:UpdateVisibility()
end

-- Veilleur : inspection ou onglet de spécialisation changés -> tout recalculer ; sinon contrôle du
-- bouton du halo (le jeu recycle ses boutons sans évènement pour nous), seulement sur l'onglet « Talents ».
function Hook:Tick()
  if not self.open then return end
  if self:IsLive() ~= self.live then
    self:Refresh()
  elseif self.live and self.selected == "talents" then
    self:PlaceHalo()
  end
end

function Hook:OnTalentsShow()
  self.open = true
  self.selected = "talents"
  paintTabs()
  self:Refresh()
end

-- Affichage des talents caché (fenêtre fermée, passage au grimoire) : nos cadres se cachent, la
-- fenêtre des builds ouverte par nos onglets se referme et redevient autonome.
function Hook:OnTalentsHide()
  self.open = false
  self.live = false
  if self.selected ~= "talents" then self:CloseWindow() else releaseHost() end
  self.tabFrame:Hide()
  self.band:Hide()
  self:DetachHalo()
end

local function build(host, talents)
  Hook.host, Hook.talents = host, talents
  Hook.tabFrame = createTabs(host)
  Hook.band = createBand(talents)
  Hook.halo = createHalo(Hook.band)
  Hook.watcher = createWatcher(talents)
  talents:HookScript("OnShow", function() Q.SafeCall(Hook.OnTalentsShow, Hook) end)
  talents:HookScript("OnHide", function() Q.SafeCall(Hook.OnTalentsHide, Hook) end)
  Hook.hooked = true
  if isOpen(talents) then Hook:OnTalentsShow() end
end

-- Accroche (une seule fois) : hors combat, sinon remise à PLAYER_REGEN_ENABLED. -> vrai si accrochée.
function Hook:Attach()
  if self.hooked or self.failed then return self.hooked end
  local host, talents = gameFrames()
  if not host then return false end
  if inCombat() then
    self.pending = true
    return false
  end
  self.pending = false
  local ok = Q.SafeCall(build, host, talents)
  if not ok then self.failed = true end   -- pas de nouvel essai : l'erreur est déjà signalée
  return self.hooked
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
local function onAddonLoaded(_, name)
  if name ~= PLAYER_SPELLS then return end
  Hook:Attach()
  if Hook.hooked then Q:UnregisterEvent("ADDON_LOADED", onAddonLoaded) end
end
Q:RegisterEvent("ADDON_LOADED", onAddonLoaded)
Q:On("LOGIN", function()
  if type(PlayerSpellsFrame) == "table" then Hook:Attach() end
end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if Hook.pending then Hook:Attach() end
end)
-- TRAIT_CONFIG_UPDATED arrive ici par TALENTS_CHANGED (Engine/Talents.lua).
Q:On("TALENTS_CHANGED", function() Hook:Refresh() end)
Q:On("BUILDS_CHANGED", function() Hook:Refresh() end)
Q:On("SPELLS_CHANGED", function() Hook:Refresh() end)   -- pastille de l'onglet Sorts
