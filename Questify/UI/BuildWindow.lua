local addonName, Q = ...

-- Fenêtre du build du personnage (spec 2.3, 2.5, 7.8) : une coquille à deux volets, « build » et « spells »,
-- que les tâches suivantes remplissent (BuildWindow:Pane(nom) -> cadre où s'accrocher).
--   * autonome (/qf build, menu de la minicarte, repli) : fenêtre déplaçable, fermée par Échap ;
--   * posée sur la fenêtre des talents du jeu (BuildWindow:SetHost(PlayerSpellsFrame), appelé par
--     TalentFrameHook) : notre contenu devient enfant de la fenêtre du jeu et couvre l'affichage des
--     talents (TalentsFrame ne sert que d'ancre : jamais re-parenté, caché ni déplacé), au-dessus des
--     boutons de talent (ActivateButton : niveau 4001) et de la bande du hook (niveau 1005 environ).
--   * Open(volet) -> faux quand la fenêtre est remise à la fin du combat (PLAYER_REGEN_ENABLED) : les
--     cadres ne sont créés que hors combat.
Q.UI = Q.UI or {}
local Window = { host = nil, panes = {}, current = nil, pending = nil }
Q.UI.BuildWindow = Window

local L = Q.L

local FRAME_NAME = "QuestifyBuildWindow"
local WIDTH, HEIGHT = 760, 560
local HOST_LEVEL = 4100             -- au-dessus de ActivateButton (4001)
local PANES = { "build", "spells" }

local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function isPane(name)
  for _, p in ipairs(PANES) do if p == name then return true end end
  return false
end

local function newShell()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "BasicFrameTemplateWithInset")
  if ok and f then return f end
  return CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
end

-- Coquille autonome : cadre déplaçable fermé par Échap, créé une fois.
function Window:EnsureShell()
  if self.shell then return self.shell end
  local f = newShell()
  self.shell = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetFrameStrata("HIGH")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
  f:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)
  if f.SetTitle then f:SetTitle(L.TALENT_WINDOW_TITLE) end
  if UISpecialFrames then tinsert(UISpecialFrames, FRAME_NAME) end
  f:Hide()
  -- Échap (ou toute fermeture de la coquille) : le contenu se ferme aussi et l'état est remis à zéro.
  f:SetScript("OnHide", function()
    if Window.quiet then return end
    Window.current = nil
    if Window.root then Window.root:Hide() end
  end)
  return f
end

-- Contenu (racine et volets), créé une fois ; hors combat seulement. -> racine | nil
function Window:Ensure()
  if self.root then return self.root end
  if inCombat() then return nil end
  local root = CreateFrame("Frame", nil, UIParent)
  self.root = root
  root:EnableMouse(true)          -- les clics ne passent pas aux boutons de talent dessous
  local bg = root:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(root)
  bg:SetColorTexture(0.06, 0.05, 0.04, 0.96)
  self.background = bg
  for _, name in ipairs(PANES) do
    local pane = CreateFrame("Frame", nil, root)
    pane:SetAllPoints(root)
    pane:Hide()
    self.panes[name] = pane
  end
  root:Hide()
  return root
end

-- Place le contenu : sur la fenêtre du jeu quand il y en a une, sinon dans la coquille autonome.
function Window:Layout()
  local root = self.root
  if not root then return end
  root:ClearAllPoints()
  if self.host then
    local anchor = type(self.host.TalentsFrame) == "table" and self.host.TalentsFrame or self.host
    root:SetParent(self.host)
    root:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
    root:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
    if type(self.host.GetFrameStrata) == "function" then root:SetFrameStrata(self.host:GetFrameStrata()) end
    root:SetFrameLevel(HOST_LEVEL)
    if self.shell then
      self.quiet = true
      self.shell:Hide()
      self.quiet = nil
    end
  else
    local shell = self:EnsureShell()
    root:SetParent(shell)
    root:SetPoint("TOPLEFT", shell, "TOPLEFT", 10, -30)
    root:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", -10, 10)
    root:SetFrameLevel(shell:GetFrameLevel() + 2)
  end
  for _, pane in pairs(self.panes) do pane:SetFrameLevel(root:GetFrameLevel() + 1) end
end

-- Fenêtre du jeu qui porte le contenu, ou nil pour la fenêtre autonome.
function Window:SetHost(frame)
  if frame ~= nil and type(frame) ~= "table" then frame = nil end
  if inCombat() then
    -- ni cadre créé ni re-parentage en combat : appliqué à PLAYER_REGEN_ENABLED
    self.hostPending, self.hostWanted = true, frame
    return
  end
  self.hostPending, self.hostWanted = nil, nil
  if self.host == frame then return end
  self.host = frame
  if not self.root then return end
  local wasShown = self.root:IsShown() and self.current ~= nil
  self:Layout()
  if wasShown and self.current then
    if frame then
      self.root:Show()
    else
      self.shell:Show()
      self.root:Show()
    end
  end
end

function Window:Pane(name)
  if not isPane(name) then return nil end
  self:Ensure()
  return self.panes[name]
end

-- Fenêtre du jeu encore montrée (IsVisible, sinon IsShown) ; une méthode absente compte comme cachée.
local function hostVisible(host)
  for _, m in ipairs({ "IsVisible", "IsShown" }) do
    local fn = type(host) == "table" and host[m]
    if type(fn) == "function" then
      local ok, v = pcall(fn, host)
      if ok and not Q.Util.IsSecret(v) then return v == true end
    end
  end
  return false
end

function Window:Open(pane)
  if not isPane(pane) then pane = "build" end
  if inCombat() then
    self.pending = pane
    return false
  end
  self.pending = nil
  -- hôte gardé mais fenêtre du jeu fermée (I1) : le contenu passe dans la fenêtre autonome
  if self.host and not hostVisible(self.host) then self:SetHost(nil) end
  local root = self:Ensure()
  if not root then return false end
  self:Layout()
  for name, frame in pairs(self.panes) do
    if name == pane then frame:Show() else frame:Hide() end
  end
  self.current = pane
  if not self.host then self.shell:Show() end
  root:Show()
  return true
end

function Window:Close()
  self.pending = nil
  self.current = nil
  if self.root then self.root:Hide() end
  if self.shell then self.shell:Hide() end
end

function Window:IsShown()
  if not self.root then return false end
  if self.host then return self.root:IsVisible() end
  return self.root:IsShown() and self.shell ~= nil and self.shell:IsShown()
end

Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if Window.hostPending then Window:SetHost(Window.hostWanted) end
  if Window.pending then Window:Open(Window.pending) end
end)
