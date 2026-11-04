local addonName, Q = ...

-- Animation autour de l'objet à utiliser (coffre, seau, affiche…) quand l'étape courante pointe
-- sur un objet du monde (spec § 5.5).
-- Un addon ne peut rien dessiner dans le monde 3D. On s'accroche donc au cadre d'écran du
-- marqueur 3D natif (C_Navigation.GetFrame(), celui que suit SuperTrackedFrame), que Nav pose sur
-- les coordonnées de l'objet. D'où les conditions : client à API moderne (Forever), affichage
-- « marqueur natif », objet à l'écran (marqueur non collé au bord) et à moins de 50 m.
-- Sinon rien ne s'affiche. Rien ici n'est protégé : le combat ne change rien.
Q.UI = Q.UI or {}
local ObjectGlow = {}
Q.UI.ObjectGlow = ObjectGlow

local CHECK_INTERVAL = 0.1   -- secondes entre deux vérifications (le cadre suit seul le marqueur)
local MAX_DIST = 50          -- au-delà, l'objet est trop petit à l'écran pour être entouré
local SIZE_NEAR, SIZE_FAR = 150, 60
local WAVE_TIME = 1.4
local RING_TEXTURE = "Interface\\Cooldown\\ping4"
local STAR_TEXTURE = "Interface\\Cooldown\\star4"

local function setting(path) return Q.Settings:Get(path) end

local function available()
  return type(C_Navigation) == "table" and type(C_Navigation.GetFrame) == "function"
end
ObjectGlow.Available = function() return available() end

---------------------------------------------------------------------------
-- Cadre et animations
---------------------------------------------------------------------------
-- Onde dorée : l'anneau grandit en s'effaçant, en boucle.
local function newWave(f)
  local ring = f:CreateTexture(nil, "ARTWORK")
  ring:SetTexture(RING_TEXTURE)
  ring:SetBlendMode("ADD")
  ring:SetVertexColor(1, 0.82, 0)
  ring:SetAllPoints(f)
  ring:SetAlpha(0)
  local group = ring:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local scale = group:CreateAnimation("Scale")
  if scale.SetScaleFrom then
    scale:SetScaleFrom(0.35, 0.35)
    scale:SetScaleTo(1.25, 1.25)
  end
  scale:SetDuration(WAVE_TIME)
  local fade = group:CreateAnimation("Alpha")
  fade:SetFromAlpha(0.9)
  fade:SetToAlpha(0)
  fade:SetDuration(WAVE_TIME)
  return ring, group
end

function ObjectGlow:Create()
  if self.frame then return self.frame end
  local f = CreateFrame("Frame", "QuestifyObjectGlow", UIParent)
  f:SetFrameStrata("BACKGROUND")   -- au-dessus du monde, sous le reste de l'interface
  f:SetSize(SIZE_NEAR, SIZE_NEAR)
  if f.EnableMouse then f:EnableMouse(false) end
  f:Hide()

  -- étoile qui tourne lentement au centre
  local star = f:CreateTexture(nil, "BACKGROUND")
  star:SetTexture(STAR_TEXTURE)
  star:SetBlendMode("ADD")
  star:SetVertexColor(1, 0.82, 0)
  star:SetAlpha(0.55)
  star:SetPoint("CENTER", f, "CENTER", 0, 0)
  star:SetSize(SIZE_NEAR * 0.6, SIZE_NEAR * 0.6)
  local spin = star:CreateAnimationGroup()
  spin:SetLooping("REPEAT")
  local rot = spin:CreateAnimation("Rotation")
  if rot.SetDegrees then rot:SetDegrees(-360) end
  rot:SetDuration(6)

  -- deux ondes décalées d'une demi-période : un anneau part toujours de l'objet
  local _, wave1 = newWave(f)
  local _, wave2 = newWave(f)

  self.frame, self.star = f, star
  self.anims = { spin, wave1, wave2 }

  local since = 0
  f:SetScript("OnUpdate", function(_, elapsed)
    since = since + (elapsed or 0)
    if since < CHECK_INTERVAL then return end
    since = 0
    Q.SafeCall(ObjectGlow.Update, ObjectGlow)
  end)
  return f
end

function ObjectGlow:Play()
  local spin, wave1, wave2 = self.anims[1], self.anims[2], self.anims[3]
  if spin:IsPlaying() then return end
  spin:Play()
  wave1:Play()
  self.waveSeq = (self.waveSeq or 0) + 1
  local mine = self.waveSeq
  Q:After(WAVE_TIME / 2, function()
    if mine == ObjectGlow.waveSeq and ObjectGlow.frame:IsShown() then wave2:Play() end
  end)
end

function ObjectGlow:StopAll()
  self.waveSeq = (self.waveSeq or 0) + 1
  for _, a in ipairs(self.anims or {}) do a:Stop() end
end

---------------------------------------------------------------------------
-- Conditions
---------------------------------------------------------------------------
local function navDisplay()
  if not (Q.Nav and Q.Nav.Active) then return "native" end
  local _, display = Q.Nav:Active()
  return display
end

-- -> cadre du marqueur natif et distance (m, ou nil), ou nil si rien ne doit s'afficher.
local function wanted()
  if not available() or setting("objectGlow") == false then return nil end
  local T = Q.UI.Tracker
  local tg = T and T.entry and T.target
  if not (tg and tg.kind == "object") then return nil end
  if navDisplay() ~= "native" then return nil end
  local nav = C_Navigation.GetFrame()
  if not nav then return nil end
  if C_Navigation.WasClampedToScreen and C_Navigation.WasClampedToScreen() then return nil end
  local d = C_Navigation.GetDistance and C_Navigation.GetDistance()
  if type(d) ~= "number" or Q.Util.IsSecret(d) then d = nil end
  if d and d > MAX_DIST then return nil end
  return nav, d
end

local function sizeFor(d)
  if not d then return SIZE_NEAR end
  local k = math.max(0, math.min(1, d / MAX_DIST))
  return math.floor(SIZE_NEAR - (SIZE_NEAR - SIZE_FAR) * k + 0.5)
end
ObjectGlow.SizeFor = function(_, d) return sizeFor(d) end

function ObjectGlow:Update()
  local f = self.frame
  if not f then return end
  local ok, nav, d = pcall(wanted)
  if not ok then
    Q:ReportError(nav)
    nav = nil
  end
  if not nav then
    if self.shown then
      self.shown = false
      self:StopAll()
      f:SetAlpha(0)
    end
    return
  end
  if nav ~= self.anchor then
    f:ClearAllPoints()
    f:SetPoint("CENTER", nav, "CENTER", 0, 0)
    self.anchor = nav
  end
  local size = sizeFor(d)
  if size ~= self.size then
    f:SetSize(size, size)
    self.star:SetSize(size * 0.6, size * 0.6)
    self.size = size
  end
  if not self.shown then
    self.shown = true
    f:SetAlpha(1)
    self:Play()
  end
end

-- Le cadre reste affiché (transparent quand rien n'est à entourer) pour que son OnUpdate tourne ;
-- il n'existe que sur un client qui a le marqueur natif.
Q:On("LOGIN", function()
  if not available() then return end
  local f = ObjectGlow:Create()
  f:SetAlpha(0)
  f:Show()
  ObjectGlow:Update()
end)
for _, msg in ipairs({ "STEP_CHANGED", "PROGRESS_UPDATED", "SETTINGS_CHANGED" }) do
  Q:On(msg, function() ObjectGlow:Update() end)
end
