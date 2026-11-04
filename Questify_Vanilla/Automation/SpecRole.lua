local addonName, Q = ...

-- Spécialisation du joueur et profil de butin (Q.Rewards, réglage par personnage Q.char.rewardRole).
-- Le profil se choisit à la création du personnage (assistant) ; à partir du niveau 10, quand le
-- joueur choisit une spécialisation dont le profil diffère du sien, une fenêtre propose de passer
-- au profil de la spécialisation : « Oui » ou « Non, garder <profil actuel> ».
-- Correspondance : HEALER -> healer ; TANK -> tank ; DAMAGER : chasseur -> ranged, statistique
-- principale Intelligence -> caster, sinon melee. Un profil que la classe n'a pas donne "auto" (pas
-- de proposition). Classes à un seul profil (voleur, mage, démoniste) : jamais de proposition.
-- API (branche forever de wow-ui-source, Camelot/CharacterFrame.lua et PaperDollFrame.lua) :
--   C_SpecializationInfo.GetSpecialization() -> index (nil, 0, ou supérieur au nombre de
--   spécialisations de la classe pour la spécialisation de départ : rien n'est choisi) ;
--   C_SpecializationInfo.GetSpecializationInfo(index, false, false, nil, UnitSex("player"))
--   -> id, nom, description, icône, rôle, statistique principale (LE_UNIT_STAT_*).
-- Déclencheurs : PLAYER_SPECIALIZATION_CHANGED (joueur), ACTIVE_PLAYER_SPECIALIZATION_CHANGED,
-- ACTIVE_TALENT_GROUP_CHANGED (regroupés en une seule vérification), et une fois après la connexion.
-- « Non » est gardé par spécialisation (Q.char.specRoleAnswered[specID]) : jamais redemandé pour
-- celle-ci ; une autre spécialisation redemande. « Oui » rend le profil identique, rien à garder.
-- Jamais affichée en combat : la fenêtre attend PLAYER_REGEN_ENABLED (celle à l'écran au début
-- d'un combat est cachée puis reproposée). Rien de protégé ici.
local SpecRole = {}
Q.SpecRole = SpecRole

SpecRole.MIN_LEVEL = 10        -- niveau des spécialisations (en dessous : rien)
local CHANGE_DELAY = 0.5       -- plusieurs évènements d'affilée : une seule vérification
local LOGIN_DELAY = 5          -- vérification de connexion, après l'assistant et les autres fenêtres
local INIT_RETRY_DELAY = 2     -- données de spécialisation pas encore prêtes : nouvel essai
local INIT_RETRIES = 5
local MAX_SPECS = 6
local INT_STAT = 4             -- LE_UNIT_STAT_INTELLECT

local FRAME_NAME = "QuestifyVanillaSpecRolePopup"
local WIDTH, HEIGHT = 440, 116
local ICON_SIZE = 40

-- Identifiants de classe (UnitClass, 3e valeur) pour les API qui les demandent.
local CLASS_IDS = {
  WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, SHAMAN = 7, MAGE = 8, WARLOCK = 9, DRUID = 11,
}
local ROLE_PROFILE = { HEALER = "healer", TANK = "tank" }

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function inCombat() return InCombatLockdown and InCombatLockdown() end

-- Valeur lisible : nil si secrète.
local function plain(v)
  if Q.Util.IsSecret(v) then return nil end
  return v
end

-- Appel protégé : ok, résultats ; faux si la fonction manque ou échoue.
local function call(fn, ...)
  if type(fn) ~= "function" then return false end
  return pcall(fn, ...)
end

local function specApi()
  local S = C_SpecializationInfo
  if type(S) ~= "table" then return nil end
  return S
end

local function playerClass()
  local classFile = Q.Player and Q.Player.classFile
  if not classFile and UnitClass then
    local ok, _, cf = pcall(UnitClass, "player")
    if ok then classFile = plain(cf) end
  end
  return classFile
end

local function playerLevel()
  local level = tonumber(Q.Player and Q.Player.level) or 0
  if UnitLevel then
    local ok, l = pcall(UnitLevel, "player")
    l = ok and tonumber(plain(l)) or 0
    if l > level then level = l end
  end
  return level
end

local function playerSex()
  if not UnitSex then return nil end
  local ok, sex = pcall(UnitSex, "player")
  return ok and plain(sex) or nil
end

-- Nombre de spécialisations de la classe, ou nil si l'API ne le dit pas.
local function numSpecs(S, classFile)
  local classID = CLASS_IDS[classFile]
  local ok, n = call(S.GetNumSpecializationsForClassID, classID)
  n = ok and tonumber(plain(n)) or nil
  if not n and type(GetNumSpecializations) == "function" then
    ok, n = pcall(GetNumSpecializations)
    n = ok and tonumber(plain(n)) or nil
  end
  if n and n > 0 then return math.min(n, MAX_SPECS) end
  return nil
end

-- Infos de la spécialisation d'index i : { index, id, name, icon, role, primaryStat } ou nil.
local function specInfo(S, index)
  local ok, id, name, _, icon, role, primaryStat = call(S.GetSpecializationInfo, index, false, false, nil, playerSex())
  if not ok then return nil end
  id, name, icon, role, primaryStat = plain(id), plain(name), plain(icon), plain(role), plain(primaryStat)
  if type(id) ~= "number" or id <= 0 or type(role) ~= "string" then return nil end
  return { index = index, id = id, name = type(name) == "string" and name or nil, icon = icon, role = role,
    primaryStat = tonumber(primaryStat) }
end

---------------------------------------------------------------------------
-- Détection et correspondance
---------------------------------------------------------------------------
-- ProfileFor(role, primaryStat, classFile) -> profil de butin de la classe, ou "auto".
function SpecRole:ProfileFor(role, primaryStat, classFile)
  local profile = ROLE_PROFILE[role]
  if role == "DAMAGER" then
    if classFile == "HUNTER" then
      profile = "ranged"
    elseif tonumber(primaryStat) == (tonumber(LE_UNIT_STAT_INTELLECT) or INT_STAT) then
      profile = "caster"
    else
      profile = "melee"
    end
  end
  local roles = Q.Rewards and Q.Rewards.CLASS_ROLES and Q.Rewards.CLASS_ROLES[classFile]
  for _, r in ipairs(roles or {}) do
    if r == profile then return profile end
  end
  return "auto"
end

-- Detect() -> spécialisation choisie par le joueur { index, id, name, icon, role, primaryStat },
-- ou nil : API absente, aucune spécialisation, spécialisation de départ, choix désactivé pour la classe.
function SpecRole:Detect()
  local S = specApi()
  if not S then return nil end
  local ok, index = call(S.GetSpecialization)
  index = ok and tonumber(plain(index)) or nil
  if not index or index <= 0 then return nil end
  local classFile = playerClass()
  local n = numSpecs(S, classFile)
  if n and index > n then return nil end   -- spécialisation de départ (avant le choix)
  local classID = CLASS_IDS[classFile]
  if classID and type(S.IsSpecSelectionEnabled) == "function" then
    local okEnabled, enabled = pcall(S.IsSpecSelectionEnabled, classID)
    if okEnabled and plain(enabled) == false then return nil end
  end
  return specInfo(S, index)
end

-- IconForProfile(profile, classFile) -> icône de la spécialisation de la classe qui correspond au
-- profil (la première), ou nil si l'API ne la donne pas.
function SpecRole:IconForProfile(profile, classFile)
  local S = specApi()
  classFile = classFile or playerClass()
  if not S or not profile or profile == "auto" or classFile ~= playerClass() then return nil end
  local n = numSpecs(S, classFile)
  for i = 1, n or 0 do
    local info = specInfo(S, i)
    if info and info.icon and self:ProfileFor(info.role, info.primaryStat, classFile) == profile then
      return info.icon
    end
  end
  return nil
end

-- Offer() -> proposition { specID, specName, icon, profile, current } ou nil (rien à proposer).
function SpecRole:Offer()
  local Rw = Q.Rewards
  if not (Q.char and Rw) then return nil end
  local classFile = playerClass()
  if not classFile or not Rw:HasChoice(classFile) then return nil end
  if playerLevel() < self.MIN_LEVEL then return nil end
  local spec = self:Detect()
  if not spec then return nil end
  local profile = self:ProfileFor(spec.role, spec.primaryStat, classFile)
  if profile == "auto" then return nil end
  local current = Rw:Role(classFile)
  if profile == current then return nil end
  local answered = Q.char.specRoleAnswered
  if type(answered) == "table" and answered[spec.id] then return nil end
  return { specID = spec.id, specName = spec.name or Rw:RoleLabel(profile, classFile), icon = spec.icon,
    profile = profile, current = current, classFile = classFile }
end

-- Describe() -> une ligne pour /qf bug : spécialisation détectée et profil.
function SpecRole:Describe()
  local classFile = playerClass()
  local spec = self:Detect()
  local role = Q.Rewards and Q.Rewards:Role(classFile) or "auto"
  local chosen = Q.char and Q.char.rewardRoleChosen and "yes" or "no"
  if not spec then
    return string.format("none (reward role %s, chosen at creation: %s)", tostring(role), chosen)
  end
  local answered = Q.char and type(Q.char.specRoleAnswered) == "table" and Q.char.specRoleAnswered[spec.id]
  return string.format("%s (id %s, %s, stat %s) -> %s; reward role %s, chosen at creation: %s%s",
    tostring(spec.name), tostring(spec.id), tostring(spec.role), tostring(spec.primaryStat),
    self:ProfileFor(spec.role, spec.primaryStat, classFile), tostring(role), chosen,
    answered and ", kept after asking" or "")
end

---------------------------------------------------------------------------
-- Fenêtre
---------------------------------------------------------------------------
local function fitButton(b, minWidth)
  local w = minWidth
  if b.GetTextWidth then
    local ok, tw = pcall(b.GetTextWidth, b)
    if ok and type(tw) == "number" then w = math.max(minWidth, tw + 30) end
  end
  b:SetWidth(math.min(w, WIDTH / 2 - 16))
end

function SpecRole:Create()
  if self.frame then return self.frame end
  local L = Q.L
  local f = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
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

  local icon = f:CreateTexture(nil, "ARTWORK")
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -14)
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
  title:SetText(L.MINIMAP_TIP_TITLE)
  local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  text:SetWidth(WIDTH - ICON_SIZE - 44)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(true)

  local yes = CreateFrame("Button", FRAME_NAME .. "Yes", f, "UIPanelButtonTemplate")
  yes:SetSize(120, 22)
  yes:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -4, 12)
  yes:SetText(L.SPECROLE_YES)
  yes:SetScript("OnClick", function() Q.SafeCall(SpecRole.Accept, SpecRole) end)
  local no = CreateFrame("Button", FRAME_NAME .. "No", f, "UIPanelButtonTemplate")
  no:SetSize(120, 22)
  no:SetPoint("BOTTOMLEFT", f, "BOTTOM", 4, 12)
  no:SetScript("OnClick", function() Q.SafeCall(SpecRole.Decline, SpecRole) end)

  f:Hide()
  self.frame, self.icon, self.text, self.yesButton, self.noButton = f, icon, text, yes, no
  return f
end

function SpecRole:IsShown()
  return self.frame ~= nil and self.frame:IsShown()
end

function SpecRole:ShowOffer(offer)
  local L, Rw = Q.L, Q.Rewards
  self:Create()
  self.current = offer
  self.icon:SetTexture(offer.icon or "Interface\\Icons\\INV_Misc_Book_09")
  self.text:SetText(string.format(L.SPECROLE_TEXT, tostring(offer.specName),
    tostring(Rw:RoleLabel(offer.profile, offer.classFile))))
  self.yesButton:SetText(L.SPECROLE_YES)
  fitButton(self.yesButton, 120)
  self.noButton:SetText(string.format(L.SPECROLE_NO, tostring(Rw:RoleLabel(offer.current, offer.classFile))))
  fitButton(self.noButton, 120)
  self.frame:Show()
  if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPEN then pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPEN) end
end

function SpecRole:Hide()
  self.current = nil
  if self.frame then self.frame:Hide() end
end

-- Check() : propose le profil de la spécialisation si besoin ; en combat, attend la fin du combat.
-- Une fenêtre devenue sans objet (profil déjà changé ailleurs) se ferme.
function SpecRole:Check()
  local offer = self:Offer()
  if not offer then
    self.waitCombat = false
    if self.current then self:Hide() end
    return nil
  end
  if inCombat() then
    self.waitCombat = true
    if self.current then self:Hide() end
    return nil
  end
  self.waitCombat = false
  self:ShowOffer(offer)
  return offer
end

-- « Oui » : le profil de la spécialisation devient celui du personnage.
function SpecRole:Accept()
  local offer = self.current
  self:Hide()
  if not offer or not Q.Rewards then return false end
  if not Q.Rewards:SetRole(offer.profile) then return false end
  Q:Print(Q.L.MINIMAP_ROLE_SET, Q.Rewards:RoleLabel(offer.profile, offer.classFile))
  return true
end

-- « Non » : le profil reste ; la question n'est plus posée pour cette spécialisation.
function SpecRole:Decline()
  local offer = self.current
  self:Hide()
  if not offer or not Q.char then return false end
  if type(Q.char.specRoleAnswered) ~= "table" then Q.char.specRoleAnswered = {} end
  Q.char.specRoleAnswered[offer.specID] = true
  Q:Print(Q.L.SPECROLE_KEPT, Q.Rewards:RoleLabel(Q.Rewards:Role(offer.classFile), offer.classFile))
  return true
end

-- Début de combat : la fenêtre se cache et sera reproposée à la fin du combat.
function SpecRole:Suspend()
  if not self.current then return end
  self:Hide()
  self.waitCombat = true
end

function SpecRole:Resume()
  if not self.waitCombat or inCombat() then return end
  self:Check()
end

-- Plusieurs évènements de spécialisation d'affilée : une seule vérification, un peu plus tard.
function SpecRole:ScheduleCheck()
  self.serial = (self.serial or 0) + 1
  local mine = self.serial
  Q:After(CHANGE_DELAY, function()
    if mine == SpecRole.serial then SpecRole:Check() end
  end)
end

-- Vérification de connexion (une fois) : attend que les données de spécialisation soient prêtes.
function SpecRole:LoginCheck(tries)
  tries = tries or 0
  -- assistant ouvert (premier démarrage) : la question attend qu'il soit fermé, son choix de
  -- profil compte alors
  local W = Q.UI and Q.UI.Wizard
  if W and type(W.IsShown) == "function" and W:IsShown() then
    Q:After(LOGIN_DELAY, function() SpecRole:LoginCheck(tries) end)
    return
  end
  local S = specApi()
  if S and type(S.IsInitialized) == "function" and tries < INIT_RETRIES then
    local ok, ready = pcall(S.IsInitialized)
    if ok and plain(ready) == false then
      Q:After(INIT_RETRY_DELAY, function() SpecRole:LoginCheck(tries + 1) end)
      return
    end
  end
  self:Check()
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
Q:On("LOGIN", function()
  Q:After(LOGIN_DELAY, function() SpecRole:LoginCheck(0) end)
end)

Q:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function(_, unit)
  -- unité secrète ou absente : on vérifie quand même (la vérification ne fait rien de trop)
  if Q.Util.IsSecret(unit) or unit == nil or unit == "player" then SpecRole:ScheduleCheck() end
end)
Q:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", function() SpecRole:ScheduleCheck() end)
Q:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", function() SpecRole:ScheduleCheck() end)

Q:RegisterEvent("PLAYER_REGEN_DISABLED", function() SpecRole:Suspend() end)
Q:RegisterEvent("PLAYER_REGEN_ENABLED", function() SpecRole:Resume() end)

-- Profil changé ailleurs (bouton de la minicarte, journal) pendant que la fenêtre est ouverte.
Q:On("SETTINGS_CHANGED", function(path)
  if path == "rewardRole" and SpecRole.current then SpecRole:Check() end
end)
