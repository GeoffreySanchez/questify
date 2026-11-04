local addonName, Q = ...

-- Choix du build de talents : des cartes au milieu de l'écran, une par preset de la classe, qui
-- apparaissent avec une animation (comme l'annonce d'un objet plus fort). Monde ouvert (kind
-- « leveling ») : une planète Azeroth qui tourne (carte du monde du jeu dans un masque rond) ;
-- donjon (kind « dungeon ») : un portail qui tourbillonne. S'ouvre au niveau 10 (TALENTS_ASK) et
-- depuis le journal, jamais en combat (attente de PLAYER_REGEN_ENABLED).
Q.UI = Q.UI or {}
local Picker = { cards = {} }
Q.UI.TalentPicker = Picker

local L = Q.L

local FRAME_NAME = "QuestifyTalentPicker"
local CARD_W, CARD_H = 220, 300
local GAP = 30
local ART = 140
local SPIN_SPEED = 0.025      -- tours de planète par seconde
local ROUND_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
-- Rangée centrale de la carte du monde (4 tuiles de 256 px) : Royaumes de l'Est et Kalimdor.
local WORLD_TILES = { "Interface\\WorldMap\\World\\World5", "Interface\\WorldMap\\World\\World6",
  "Interface\\WorldMap\\World\\World7", "Interface\\WorldMap\\World\\World8" }
local PORTAL_ICON = "Interface\\Icons\\Spell_Arcane_PortalIronForge"

local function safe(fn)
  return function(...) return Q.SafeCall(fn, ...) end
end

local function inCombat() return InCombatLockdown and InCombatLockdown() end

---------------------------------------------------------------------------
-- Illustrations
---------------------------------------------------------------------------
-- Planète : 2 x 4 tuiles côte à côte qui défilent derrière un masque rond (illusion de rotation),
-- halo bleu (atmosphère) et ombre sur le bord.
local function buildPlanet(card)
  local holder = CreateFrame("Frame", nil, card)
  holder:SetSize(ART, ART)
  holder:SetPoint("TOP", card, "TOP", 0, -26)
  local mask = holder:CreateMaskTexture()
  mask:SetTexture(ROUND_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  mask:SetAllPoints(holder)
  local tiles = {}
  for copy = 0, 1 do
    for i, path in ipairs(WORLD_TILES) do
      local t = holder:CreateTexture(nil, "ARTWORK")
      t:SetTexture(path)
      t:SetSize(ART, ART)
      t:AddMaskTexture(mask)
      tiles[#tiles + 1] = { tex = t, slot = copy * #WORLD_TILES + (i - 1) }
    end
  end
  local width = ART * #WORLD_TILES   -- une rotation complète
  local function place(offset)
    for _, tile in ipairs(tiles) do
      tile.tex:ClearAllPoints()
      tile.tex:SetPoint("TOPLEFT", holder, "TOPLEFT", tile.slot * ART - offset, 0)
    end
  end
  place(0)
  local shade = holder:CreateTexture(nil, "OVERLAY")
  shade:SetTexture(ROUND_MASK)
  shade:SetVertexColor(0, 0, 0.1, 0.35)
  shade:SetAllPoints(holder)
  local halo = card:CreateTexture(nil, "BACKGROUND")
  halo:SetTexture("Interface\\Cooldown\\ping4")
  halo:SetBlendMode("ADD")
  halo:SetVertexColor(0.3, 0.6, 1, 0.9)
  halo:SetPoint("CENTER", holder, "CENTER", 0, 0)
  halo:SetSize(ART * 1.35, ART * 1.35)
  local offset = 0
  card.spin = function(elapsed)
    offset = (offset + width * SPIN_SPEED * (elapsed or 0)) % width
    place(offset)
  end
  card.art, card.tiles = holder, tiles
end

-- Portail : icône ronde du portail, étoile violette qui tourne et anneau qui pulse.
local function buildPortal(card)
  local holder = CreateFrame("Frame", nil, card)
  holder:SetSize(ART, ART)
  holder:SetPoint("TOP", card, "TOP", 0, -26)
  local mask = holder:CreateMaskTexture()
  mask:SetTexture(ROUND_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  mask:SetAllPoints(holder)
  local icon = holder:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(PORTAL_ICON)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon:SetAllPoints(holder)
  icon:AddMaskTexture(mask)
  local swirl = holder:CreateTexture(nil, "OVERLAY")
  swirl:SetTexture("Interface\\Cooldown\\star4")
  swirl:SetBlendMode("ADD")
  swirl:SetVertexColor(0.7, 0.3, 1, 0.9)
  swirl:SetPoint("CENTER", holder, "CENTER", 0, 0)
  swirl:SetSize(ART * 1.1, ART * 1.1)
  local spin = swirl:CreateAnimationGroup()
  spin:SetLooping("REPEAT")
  local rot = spin:CreateAnimation("Rotation")
  if rot.SetDegrees then rot:SetDegrees(-360) end
  rot:SetDuration(4)
  local ring = card:CreateTexture(nil, "BACKGROUND")
  ring:SetTexture("Interface\\Cooldown\\ping4")
  ring:SetBlendMode("ADD")
  ring:SetVertexColor(0.6, 0.2, 1, 0.9)
  ring:SetPoint("CENTER", holder, "CENTER", 0, 0)
  ring:SetSize(ART * 1.35, ART * 1.35)
  local pulse = ring:CreateAnimationGroup()
  pulse:SetLooping("BOUNCE")
  local fade = pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(0.35)
  fade:SetToAlpha(1)
  fade:SetDuration(0.9)
  card.anims = { spin, pulse }
  card.art = holder
end

---------------------------------------------------------------------------
-- Cartes
---------------------------------------------------------------------------
function Picker:Create()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", FRAME_NAME, UIParent)
  self.frame = f
  f:SetSize(CARD_W * 2 + GAP, CARD_H + 80)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
  f:SetFrameStrata("DIALOG")
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  title:SetPoint("TOP", f, "TOP", 0, 0)
  title:SetText(L.UI_TALENT_PICK_TITLE)
  local intro = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  intro:SetPoint("TOP", title, "BOTTOM", 0, -6)
  intro:SetText(L.UI_TALENT_PICK_INTRO)
  local none = CreateFrame("Button", FRAME_NAME .. "None", f, "UIPanelButtonTemplate")
  none:SetSize(200, 22)
  none:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
  none:SetText(L.UI_TALENT_PICK_NONE)
  none:SetScript("OnClick", safe(function() Picker:Pick(false) end))
  self.title, self.intro, self.noneButton = title, intro, none
  -- apparition : fondu et léger zoom
  local appear = f:CreateAnimationGroup()
  local alpha = appear:CreateAnimation("Alpha")
  alpha:SetFromAlpha(0)
  alpha:SetToAlpha(1)
  alpha:SetDuration(0.35)
  local grow = appear:CreateAnimation("Scale")
  if grow.SetScaleFrom then
    grow:SetScaleFrom(0.85, 0.85)
    grow:SetScaleTo(1, 1)
  end
  grow:SetDuration(0.35)
  self.appear = appear
  f:SetScript("OnUpdate", function(_, elapsed)
    for _, card in ipairs(Picker.cards) do
      if card:IsShown() and card.spin then card.spin(elapsed) end
    end
  end)
  f:Hide()
  return f
end

local function newCard(kind)
  local card = CreateFrame("Button", nil, Picker.frame, "BackdropTemplate")
  card:SetSize(CARD_W, CARD_H)
  card:RegisterForClicks("LeftButtonUp")
  if card.SetBackdrop then
    card:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    card:SetBackdropColor(0, 0, 0, 0.85)
    card:SetBackdropBorderColor(1, 0.82, 0, 1)
  end
  if kind == "dungeon" then buildPortal(card) else buildPlanet(card) end
  local kindText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  kindText:SetPoint("TOP", card.art, "BOTTOM", 0, -18)
  kindText:SetText(kind == "dungeon" and L.UI_TALENT_KIND_DUNGEON or L.UI_TALENT_KIND_LEVELING)
  local name = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  name:SetPoint("TOP", kindText, "BOTTOM", 0, -6)
  name:SetWidth(CARD_W - 24)
  local desc = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  desc:SetPoint("TOP", name, "BOTTOM", 0, -6)
  desc:SetWidth(CARD_W - 24)
  desc:SetWordWrap(true)
  local hl = card:CreateTexture(nil, "HIGHLIGHT")
  hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  hl:SetBlendMode("ADD")
  hl:SetAllPoints(card)
  card.kind, card.nameText, card.descText = kind, name, desc
  card:SetScript("OnClick", safe(function(self) Picker:Pick(self.key) end))
  card:SetScript("OnEnter", function(self) self:SetScale(1.04) end)
  card:SetScript("OnLeave", function(self) self:SetScale(1) end)
  return card
end

function Picker:Pick(key)
  Q.Talents:Choose(key)
  self:Hide()
  if key then
    Q:Print(L.UI_TALENT_PICKED, Q.Talents:PresetTitle(Q.Talents:Chosen()))
    local nxt = Q.Talents:Next()
    if nxt and Q.Talents:Unspent() > 0 then Q:Print(L.TALENT_LEVEL_ADVICE, Q.Talents:Advice(nxt)) end
  else
    Q:Print(L.UI_TALENT_PICKED_NONE)
  end
end

function Picker:Hide()
  if not self.frame then return end
  for _, card in ipairs(self.cards) do
    for _, a in ipairs(card.anims or {}) do a:Stop() end
  end
  self.frame:Hide()
end

function Picker:Show()
  local presets = Q.Talents:Presets()
  if #presets == 0 then
    Q:Print(L.UI_TALENT_NO_DATA)
    return
  end
  if inCombat() then
    self.pendingShow = true
    return
  end
  self:Create()
  for _, card in ipairs(self.cards) do card:Hide() end
  local shown = {}
  local byKind = {}
  for _, p in ipairs(presets) do
    local kind = p.kind == "dungeon" and "dungeon" or "leveling"
    byKind[kind] = (byKind[kind] or 0) + 1
    local card
    for _, c in ipairs(self.cards) do
      if not c:IsShown() and c.kind == kind and not c.used then card = c break end
    end
    if not card then
      card = newCard(kind)
      self.cards[#self.cards + 1] = card
    end
    card.used = true
    card.key = p.key
    card.nameText:SetText(Q.Talents:PresetTitle(p))
    local d = p.desc
    if type(d) == "table" then d = d[GetLocale and GetLocale() or "enUS"] or d.enUS end
    card.descText:SetText(type(d) == "string" and d or "")
    card:Show()
    shown[#shown + 1] = card
  end
  for _, c in ipairs(self.cards) do c.used = nil end
  local total = #shown * CARD_W + (#shown - 1) * GAP
  self.frame:SetWidth(math.max(total, 2 * CARD_W + GAP))
  for i, card in ipairs(shown) do
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", self.frame, "TOP", -total / 2 + (i - 1) * (CARD_W + GAP), -50)
    for _, a in ipairs(card.anims or {}) do a:Play() end
  end
  self.shownCards = shown
  self.frame:Show()
  self.appear:Play()
  if PlaySound and SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST then pcall(PlaySound, SOUNDKIT.UI_EPICLOOT_TOAST) end
end

Q:On("TALENTS_ASK", function()
  if Q.Talents:HasAnswered() then return end
  Picker:Show()
end)
Q:RegisterEvent("PLAYER_REGEN_DISABLED", function()
  -- combat : les cartes se ferment et reviennent après (sans choix enregistré)
  if Picker.frame and Picker.frame:IsShown() then
    Picker:Hide()
    Picker.pendingShow = true
  end
end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if Picker.pendingShow then
    Picker.pendingShow = false
    Picker:Show()
  end
end)
