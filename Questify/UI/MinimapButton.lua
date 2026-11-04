local addonName, Q = ...

-- Bouton rond au bord de la minicarte, sans bibliothèque : 31 x 31, enfant de Minimap, cadre
-- MiniMap-TrackingBorder et fond UI-Minimap-Background (textures du jeu), position calculée
-- d'après un angle et le rayon de la minicarte. On le déplace en le glissant autour de la
-- minicarte ; l'angle est gardé dans QuestifyDB.minimapAngle (repris après /reload).
-- L'icône montre le profil de butin du personnage (Q.Rewards) : l'icône de la spécialisation qui
-- correspond au profil si l'API la donne (Q.SpecRole), sinon une icône du jeu par rôle.
--   Clic gauche : menu des choix rapides (MenuUtil.CreateContextMenu de Blizzard_Menu, sinon un
--     petit menu maison) : profil de butin de la classe (le profil actuel coché), quatre
--     interrupteurs (autoQuest, autoReward, zoneMode, mapPins, par Q.Settings:Set), puis
--     « Options… » (fenêtre d'options), « Journal », « Assistant de démarrage », « Signaler un bug ».
--   Ctrl+clic : assistant de démarrage. Clic droit : journal (ouvre ou ferme).
-- Option « minimapButton » (cachée si désactivée). Le bouton n'est pas sécurisé : l'afficher ou le
-- cacher en combat ne pose pas de problème, et rien de protégé n'est appelé.
Q.UI = Q.UI or {}
local Button = {}
Q.UI.MinimapButton = Button

local FRAME_NAME = "QuestifyMinimapButton"
local MENU_NAME = "QuestifyMinimapMenu"
local SIZE = 31
local DEFAULT_ANGLE = 200      -- degrés (0 = à droite, sens trigonométrique)
local RADIUS_PAD = 5           -- le centre du bouton dépasse un peu du bord de la minicarte
local ICON_REFRESH_DELAY = 6   -- après la connexion : les icônes de spécialisation sont prêtes
local MENU_ROW_H = 18
local MENU_WIDTH = 240

-- Icônes du jeu par profil de butin.
local ICONS = {
  auto = "Interface\\Icons\\INV_Misc_Book_09",
  caster = "Interface\\Icons\\Spell_Fire_FireBolt02",
  healer = "Interface\\Icons\\Spell_Holy_HolyBolt",
  melee = "Interface\\Icons\\INV_Sword_04",
  tank = "Interface\\Icons\\INV_Shield_06",
  ranged = "Interface\\Icons\\INV_Weapon_Bow_07",
}
Button.ICONS = ICONS

-- Interrupteurs du menu : réglage, texte.
local TOGGLES = {
  { "autoQuest", "MINIMAP_MENU_AUTOQUEST" },
  { "autoReward", "MINIMAP_MENU_AUTOREWARD" },
  { "zoneMode", "MINIMAP_MENU_ZONEMODE" },
  { "mapPins", "MINIMAP_MENU_MAPPINS" },
}
Button.TOGGLES = TOGGLES

local CHECK_MARK = "|TInterface\\Buttons\\UI-CheckBox-Check:14:14|t "
local NO_MARK = "|TInterface\\Buttons\\UI-CheckBox-Up:14:14|t "

local function enabled()
  return Q.Settings:Get("minimapButton") ~= false
end

local function classFile()
  return Q.Player and Q.Player.classFile
end

local function playSound(kit)
  if PlaySound and SOUNDKIT and SOUNDKIT[kit] then pcall(PlaySound, SOUNDKIT[kit]) end
end

local function hideTooltip()
  if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
end

---------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------
-- Angle gardé (degrés, 0-360), sinon l'angle par défaut.
function Button:Angle()
  local a = tonumber(Q.db and Q.db.minimapAngle)
  if not a or a ~= a then return DEFAULT_ANGLE end
  return a % 360
end

local function minimapRadius()
  local w = Minimap and Minimap.GetWidth and Minimap:GetWidth()
  if type(w) ~= "number" or w <= 0 then w = 140 end
  return w / 2 + RADIUS_PAD
end

-- Décalage (x, y) du centre du bouton par rapport au centre de la minicarte. Minicarte carrée
-- (GetMinimapShape d'un addon de minicarte) : le bouton suit le bord du carré.
function Button:Offset(angle)
  local rad = math.rad(angle or self:Angle())
  local r = minimapRadius()
  local x, y = math.cos(rad), math.sin(rad)
  local shape = type(GetMinimapShape) == "function" and select(2, pcall(GetMinimapShape)) or "ROUND"
  if shape == "SQUARE" then
    local m = math.max(math.abs(x), math.abs(y))
    if m > 0 then x, y = x / m, y / m end
  end
  return x * r, y * r
end

-- UpdatePosition(angle) : place le bouton à cet angle (par défaut l'angle gardé).
function Button:UpdatePosition(angle)
  local b = self.button
  if not b then return end
  local x, y = self:Offset(angle)
  b:ClearAllPoints()
  b:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- SetAngle(deg, noSave) : place le bouton ; l'angle est gardé sauf noSave (pendant le glisser).
function Button:SetAngle(angle, noSave)
  angle = tonumber(angle)
  if not angle or angle ~= angle then return end
  angle = angle % 360
  if not noSave and Q.db then Q.db.minimapAngle = angle end
  self:UpdatePosition(angle)
end

-- Angle du curseur autour du centre de la minicarte.
function Button:CursorAngle()
  if not (Minimap and GetCursorPosition) then return self:Angle() end
  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  if type(mx) ~= "number" or type(my) ~= "number" or type(px) ~= "number" or type(py) ~= "number"
    or type(scale) ~= "number" or scale <= 0 then
    return self:Angle()
  end
  px, py = px / scale, py / scale
  if px == mx and py == my then return self:Angle() end
  return math.deg(math.atan2(py - my, px - mx)) % 360
end

---------------------------------------------------------------------------
-- Icône et bulle d'aide
---------------------------------------------------------------------------
-- IconFor(role, classFile) -> texture : icône de spécialisation, sinon icône du jeu du profil.
function Button:IconFor(role, cf)
  local spec = role ~= "auto" and Q.SpecRole and Q.SpecRole:IconForProfile(role, cf)
  return spec or ICONS[role] or ICONS.auto
end

function Button:UpdateIcon()
  if not self.icon then return end
  local cf = classFile()
  local role = Q.Rewards and Q.Rewards:Role(cf) or "auto"
  self.iconTexture = self:IconFor(role, cf)
  self.icon:SetTexture(self.iconTexture)
end

-- Lignes de la bulle d'aide : titre, profil de butin, clics.
function Button:TooltipLines()
  local L, Rw = Q.L, Q.Rewards
  local cf = classFile()
  local label = Rw and Rw:RoleLabel(Rw:Role(cf), cf) or "?"
  return { L.MINIMAP_TIP_TITLE, string.format(L.MINIMAP_TIP_ROLE, tostring(label)),
    L.MINIMAP_TIP_LEFT, L.MINIMAP_TIP_RIGHT, L.MINIMAP_TIP_CTRL, L.MINIMAP_TIP_DRAG }
end

function Button:ShowTooltip(owner)
  if not (GameTooltip and GameTooltip.SetOwner) or self.dragging then return end
  local lines = self:TooltipLines()
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:SetText(lines[1])
  GameTooltip:AddLine(lines[2], 1, 1, 1)
  for i = 3, #lines do GameTooltip:AddLine(lines[i], 0.7, 0.7, 0.7) end
  GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
-- SelectRole(role) : enregistre le profil de butin du personnage (Q.char.rewardRole, hors profils
-- d'options), met l'icône à jour et l'écrit dans la discussion.
function Button:SelectRole(role)
  local Rw = Q.Rewards
  if not Rw then return false end
  local cf = classFile()
  if not Rw:SetRole(role) then return false end
  self:UpdateIcon()
  Q:Print(Q.L.MINIMAP_ROLE_SET, Rw:RoleLabel(role, cf))
  return true
end

-- Toggle(path) : inverse un réglage (les autres modules réagissent à SETTINGS_CHANGED).
function Button:Toggle(path)
  local on = Q.Settings:Get(path) ~= false
  Q.Settings:Set(path, not on)
  return not on
end

-- OpenOptions() : fenêtre d'options (UI/Options.lua).
function Button:OpenOptions()
  local O = Q.UI.Options
  if O then O:Open() end
end

function Button:OpenJournal(tab)
  local J = Q.UI.Journal
  if J then J:ShowTab(tab or "route") end
end

function Button:OpenBuild()
  local W = Q.UI.BuildWindow
  if W then W:Open("build") end
end

function Button:ToggleJournal()
  local J = Q.UI.Journal
  if J then J:Toggle() end
end

function Button:OpenWizard()
  local W = Q.UI.Wizard
  if W then W:Show() end
end

function Button:OpenReport()
  local R = Q.UI.Report
  if R then R:Show() end
end

---------------------------------------------------------------------------
-- Menu des choix rapides
---------------------------------------------------------------------------
-- MenuEntries() -> liste d'entrées { kind, text, key, checked(), run() } :
--   kind = "title" | "radio" | "checkbox" | "divider" | "button" ;
--   key = profil (radio), réglage (checkbox) ou nom d'action (button).
function Button:MenuEntries()
  local L, Rw = Q.L, Q.Rewards
  local cf = classFile()
  local out = {}
  out[#out + 1] = { kind = "title", text = L.MINIMAP_MENU_TITLE }
  if Rw then
    out[#out + 1] = { kind = "title", text = L.MINIMAP_MENU_LOOT }
    for _, role in ipairs(Rw:Roles(cf)) do
      out[#out + 1] = { kind = "radio", key = role, text = Rw:RoleLabel(role, cf),
        checked = function() return Rw:Role(cf) == role end,
        run = function() Button:SelectRole(role) end }
    end
    out[#out + 1] = { kind = "divider" }
  end
  for _, def in ipairs(TOGGLES) do
    local path = def[1]
    out[#out + 1] = { kind = "checkbox", key = path, text = L[def[2]],
      checked = function() return Q.Settings:Get(path) ~= false end,
      run = function() Button:Toggle(path) end }
  end
  out[#out + 1] = { kind = "divider" }
  out[#out + 1] = { kind = "button", key = "options", text = L.MINIMAP_MENU_OPTIONS,
    run = function() Button:OpenOptions() end }
  out[#out + 1] = { kind = "button", key = "journal", text = L.MINIMAP_MENU_JOURNAL,
    run = function() Button:OpenJournal("route") end }
  out[#out + 1] = { kind = "button", key = "build", text = L.MINIMAP_MENU_BUILD,
    run = function() Button:OpenBuild() end }
  out[#out + 1] = { kind = "button", key = "wizard", text = L.MINIMAP_MENU_WIZARD,
    run = function() Button:OpenWizard() end }
  out[#out + 1] = { kind = "button", key = "bug", text = L.MINIMAP_MENU_BUG,
    run = function() Button:OpenReport() end }
  return out
end

local function isChecked(e)
  if not e.checked then return false end
  local ok, v = pcall(e.checked)
  return ok and v == true
end

local function runEntry(e)
  if e.run then Q.SafeCall(e.run) end
end

-- Remplit une description de menu de Blizzard_Menu avec les entrées.
local function populate(root, entries)
  for _, e in ipairs(entries) do
    if e.kind == "title" then
      root:CreateTitle(e.text)
    elseif e.kind == "divider" then
      root:CreateDivider()
    elseif e.kind == "radio" then
      root:CreateRadio(e.text, function() return isChecked(e) end, function() runEntry(e) end, e.key)
    elseif e.kind == "checkbox" then
      root:CreateCheckbox(e.text, function() return isChecked(e) end, function() runEntry(e) end, e.key)
    elseif e.kind == "button" then
      root:CreateButton(e.text, function() runEntry(e) end, e.key)
    end
  end
end
Button.Populate = populate

-- Petit menu maison, quand MenuUtil manque.
local function fallbackRow(menu, i)
  local row = CreateFrame("Button", nil, menu)
  row:SetHeight(MENU_ROW_H)
  row:SetPoint("LEFT", menu, "LEFT", 10, 0)
  row:SetPoint("RIGHT", menu, "RIGHT", -10, 0)
  row:RegisterForClicks("LeftButtonUp")
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", row, "LEFT", 0, 0)
  text:SetJustifyH("LEFT")
  row.text = text
  row:SetScript("OnClick", function(self)
    Q.SafeCall(function()
      local e = self.entry
      if not e or e.kind == "title" then return end
      runEntry(e)
      if e.kind == "checkbox" then
        Button:RefreshFallback()
      else
        menu:Hide()
      end
    end)
  end)
  menu.rows[i] = row
  return row
end

local function entryLabel(e)
  if e.kind == "title" then return "|cffffd100" .. tostring(e.text) .. "|r" end
  if e.kind == "radio" or e.kind == "checkbox" then
    return (isChecked(e) and CHECK_MARK or NO_MARK) .. tostring(e.text)
  end
  return tostring(e.text)
end

function Button:RefreshFallback()
  local menu = self.fallback
  if not menu or not menu.entries then return end
  local y, i = 8, 0
  for _, e in ipairs(menu.entries) do
    if e.kind == "divider" then
      y = y + 6
    else
      i = i + 1
      local row = menu.rows[i] or fallbackRow(menu, i)
      row.entry = e
      row.text:SetText(entryLabel(e))
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, -y)
      row:SetPoint("RIGHT", menu, "RIGHT", -10, 0)
      if e.kind == "title" then row:EnableMouse(false) else row:EnableMouse(true) end
      row:Show()
      y = y + MENU_ROW_H
    end
  end
  for j = i + 1, #menu.rows do menu.rows[j].entry = nil; menu.rows[j]:Hide() end
  menu:SetSize(MENU_WIDTH, y + 8)
end

function Button:OpenFallback(entries)
  local menu = self.fallback
  if not menu then
    menu = CreateFrame("Frame", MENU_NAME, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    if menu.SetBackdrop then
      menu:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
      })
      menu:SetBackdropColor(0, 0, 0, 0.9)
    end
    menu.rows = {}
    if UISpecialFrames then tinsert(UISpecialFrames, MENU_NAME) end
    self.fallback = menu
  end
  menu.entries = entries
  self:RefreshFallback()
  menu:ClearAllPoints()
  if self.button then
    menu:SetPoint("TOPRIGHT", self.button, "BOTTOMLEFT", 0, 0)
  else
    menu:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
  menu:Show()
end

-- OpenMenu() -> "menu" (Blizzard_Menu) ou "fallback" (menu maison).
function Button:OpenMenu()
  local entries = self:MenuEntries()
  if self.fallback and self.fallback:IsShown() then
    self.fallback:Hide()
    return "closed"
  end
  if type(MenuUtil) == "table" and type(MenuUtil.CreateContextMenu) == "function" then
    local ok, err = pcall(MenuUtil.CreateContextMenu, self.button, function(_, root) populate(root, entries) end)
    if ok then return "menu" end
    Q:ReportError(err)
  end
  self:OpenFallback(entries)
  return "fallback"
end

---------------------------------------------------------------------------
-- Bouton
---------------------------------------------------------------------------
function Button:OnClick(mouse)
  if self.dragging then return end
  hideTooltip()
  if mouse == "RightButton" then
    self:ToggleJournal()
  elseif IsControlKeyDown and IsControlKeyDown() then
    self:OpenWizard()
  else
    self:OpenMenu()
  end
end

local function onDragUpdate(self)
  Q.SafeCall(function() Button:SetAngle(Button:CursorAngle(), true) end)
end

function Button:Create()
  if self.button then return self.button end
  if not Minimap then return nil end
  local b = CreateFrame("Button", FRAME_NAME, Minimap)
  b:SetSize(SIZE, SIZE)
  b:SetFrameStrata("MEDIUM")
  if b.SetFixedFrameStrata then pcall(b.SetFixedFrameStrata, b, true) end
  local level = Minimap.GetFrameLevel and tonumber(Minimap:GetFrameLevel()) or 0
  b:SetFrameLevel(math.max(8, level + 8))
  if b.SetFixedFrameLevel then pcall(b.SetFixedFrameLevel, b, true) end
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local background = b:CreateTexture(nil, "BACKGROUND")
  background:SetSize(24, 24)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetPoint("CENTER", b, "CENTER", 0, 0)
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18)
  icon:SetPoint("CENTER", b, "CENTER", 0, 0)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- icône ronde : masque circulaire du jeu, si le client le permet
  if b.CreateMaskTexture and icon.AddMaskTexture then
    local ok, mask = pcall(b.CreateMaskTexture, b)
    if ok and mask then
      mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
      mask:SetAllPoints(icon)
      pcall(icon.AddMaskTexture, icon, mask)
    end
  end
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetSize(50, 50)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)

  b:SetScript("OnClick", function(_, mouse) Q.SafeCall(Button.OnClick, Button, mouse) end)
  b:SetScript("OnEnter", function(self) Q.SafeCall(Button.ShowTooltip, Button, self) end)
  b:SetScript("OnLeave", hideTooltip)
  b:SetScript("OnMouseDown", function() icon:SetPoint("CENTER", b, "CENTER", 1, -1) end)
  b:SetScript("OnMouseUp", function() icon:SetPoint("CENTER", b, "CENTER", 0, 0) end)
  b:SetScript("OnDragStart", function(self)
    Button.dragging = true
    hideTooltip()
    self:SetScript("OnUpdate", onDragUpdate)
  end)
  b:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    icon:SetPoint("CENTER", b, "CENTER", 0, 0)
    Q.SafeCall(function() Button:SetAngle(Button:CursorAngle()) end)
    Button.dragging = false
  end)

  self.button, self.icon, self.border, self.background = b, icon, border, background
  self:UpdatePosition()
  self:UpdateIcon()
  return b
end

-- Refresh() : affiche ou cache le bouton selon l'option, puis met l'icône et la place à jour.
function Button:Refresh()
  if not enabled() then
    if self.button then self.button:Hide() end
    if self.fallback then self.fallback:Hide() end
    return
  end
  local b = self:Create()
  if not b then return end
  self:UpdatePosition()
  self:UpdateIcon()
  b:Show()
end

function Button:IsShown()
  return self.button ~= nil and self.button:IsShown()
end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
Q:On("LOGIN", function()
  Button:Refresh()
  Q:After(ICON_REFRESH_DELAY, function() Button:UpdateIcon() end)
end)

Q:On("SETTINGS_CHANGED", function(path)
  if path == "minimapButton" then
    Button:Refresh()
  elseif path == "rewardRole" then
    Button:UpdateIcon()
  end
end)

Q:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", function() Button:UpdateIcon() end)
