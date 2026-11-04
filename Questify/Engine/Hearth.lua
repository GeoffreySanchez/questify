local addonName, Q = ...

-- Pierre de foyer dans le suivi (option hearthHints) :
--   étape « hearth » : recharge de la pierre (« Pierre prête » / « Pierre dans 12 min ») ; si elle
--   n'est pas prête dans les 2 minutes, une ligne de conseil : vol vers un point de vol connu près
--   de la destination, sinon le trajet à pied estimé à 7 yards par seconde ;
--   étape « sethearth » : le foyer actuel (GetBindLocation).
-- Les lignes sont ajoutées sous le texte de l'étape courante par UI/Tracker.lua (Hearth:Lines).
local Hearth = {}
Q.Hearth = Hearth

local L = Q.L
local C = Q.Comfort

local HEARTHSTONE = 6948
local READY_SOON = 120      -- secondes : en dessous, pas de conseil de trajet
local WALK_SPEED = 7        -- yards par seconde
local NODE_NEAR = 800       -- yards entre le point de vol et la destination
local FLY_WORTH = 300       -- secondes de marche au-delà desquelles un vol vaut le coup
local LOOKAHEAD = 6         -- étapes examinées après la pierre pour trouver la destination
local TICK = 5
local GCD = 1.5             -- recharge globale : la pierre est prête

local GRAY = "|cffaaaaaa"
local GREEN = "|cff40ff40"
local ORANGE = "|cffffb040"

local FACTION_NEUTRAL, FACTION_HORDE, FACTION_ALLIANCE = 0, 1, 2

local lastSig
local ticker

local function enabled() return C.Enabled("hearthHints") end

---------------------------------------------------------------------------
-- Recharge
---------------------------------------------------------------------------
-- Nombre de pierres dans les sacs, nil si inconnu.
local function stoneCount()
  local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
  return C.Number(C.Call(fn, HEARTHSTONE))
end

-- -> start, duration (secondes) ou nil.
local function readCooldown()
  local sources = {
    C_Container and C_Container.GetItemCooldown,
    C_Item and C_Item.GetItemCooldown,
    GetItemCooldown,
  }
  for i = 1, 3 do
    local fn = sources[i]
    if type(fn) == "function" then
      local ok, start, duration = pcall(fn, HEARTHSTONE)
      if ok then
        start, duration = C.Number(start), C.Number(duration)
        if start and duration then return start, duration end
        return nil
      end
    end
  end
  return nil
end

-- Secondes avant que la pierre soit prête : 0 = prête ; nil = inconnu ou pas de pierre.
function Hearth:Remaining()
  local count = stoneCount()
  if count ~= nil and count <= 0 then return nil end
  local start, duration = readCooldown()
  if not start then return nil end
  if start <= 0 or duration <= GCD then return 0 end
  local t = (GetTime and GetTime()) or 0
  return math.max(0, start + duration - t)
end

---------------------------------------------------------------------------
-- Destination et conseil de trajet
---------------------------------------------------------------------------
-- Point d'arrivée de l'étape « hearth » : la dernière étape « sethearth » de la même carte avant
-- elle, sinon la première étape localisée sur cette carte après elle. -> map, x, y ou nil.
-- Gardé en cache par étape (le suivi le redemande à chaque mise en page).
local destCache = {}

local function findDestination(entry)
  local step = entry.step
  local entries = Q.Progress:Entries()
  local index
  for i, e in ipairs(entries) do
    if e == entry or e.key == entry.key then index = i; break end
  end
  if not index then return nil end
  for i = index - 1, 1, -1 do
    local s = entries[i].step
    if s.action == "sethearth" and s.mapId == step.mapId then return s.mapId, s.x, s.y end
  end
  for i = index + 1, math.min(#entries, index + LOOKAHEAD) do
    local target = Q.Targets:ForEntry(entries[i])
    if target and target.mapId == step.mapId and type(target.x) == "number" then
      return target.mapId, target.x, target.y
    end
  end
  return nil
end

function Hearth:Destination(entry)
  local step = type(entry) == "table" and entry.step
  if type(step) ~= "table" or type(step.mapId) ~= "number" or not entry.key then return nil end
  local c = destCache[entry.key]
  if not c then
    c = { findDestination(entry) }
    destCache[entry.key] = c
  end
  return c[1], c[2], c[3]
end

local function playerFactionCode()
  local f = Q.Player and Q.Player.faction
  if f == "Horde" then return FACTION_HORDE end
  if f == "Alliance" then return FACTION_ALLIANCE end
  return nil
end

-- Point de vol connu le plus proche de (m, x, y), à moins de NODE_NEAR yards : -> nom, yards.
function Hearth:KnownNodeNear(m, x, y)
  if not (C_TaxiMap and type(C_TaxiMap.GetTaxiNodesForMap) == "function") then return nil end
  local ok, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap, m)
  if not ok or Q.Util.IsSecret(nodes) or type(nodes) ~= "table" then return nil end
  local mine = playerFactionCode()
  local bestName, bestD
  for _, n in ipairs(nodes) do
    if type(n) == "table" and not Q.Util.IsSecret(n.name) and type(n.name) == "string" and n.isUndiscovered ~= true then
      local faction = C.Number(n.faction)
      if faction == nil or faction == FACTION_NEUTRAL or mine == nil or faction == mine then
        local pos = n.position
        local nx, ny
        if type(pos) == "table" then
          if pos.GetXY then nx, ny = pos:GetXY() else nx, ny = pos.x, pos.y end
        end
        nx, ny = C.Number(nx), C.Number(ny)
        if nx and ny then
          local d = Q.Maps:Distance(m, nx * 100, ny * 100, m, x, y)
          if d and d <= NODE_NEAR and (not bestD or d < bestD) then bestName, bestD = n.name, d end
        end
      end
    end
  end
  return bestName, bestD
end

-- Ligne de conseil quand la pierre n'est pas prête : vol ou marche, nil si rien d'utile.
function Hearth:Hint(entry)
  local m, x, y = self:Destination(entry)
  if not m then return nil end
  local d = Q.Maps:DistanceFromPlayer(m, x, y)
  local walk = d and d / WALK_SPEED
  local node = self:KnownNodeNear(m, x, y)
  if node and (not walk or walk > FLY_WORTH) then
    return C.Format(L.COMFORT_HEARTH_FLY, node)
  end
  if walk then
    return C.Format(L.COMFORT_HEARTH_WALK, C.FormatDuration(walk), Q.Util.FormatDistance(d))
  end
  return nil
end

---------------------------------------------------------------------------
-- Lignes du suivi
---------------------------------------------------------------------------
local function bindLocation()
  local loc = C.Call(GetBindLocation)
  if type(loc) ~= "string" or loc == "" then return nil end
  return loc
end

-- Lignes ajoutées sous l'étape (déjà colorées), ou nil.
function Hearth:Lines(entry)
  if not enabled() then return nil end
  local step = type(entry) == "table" and entry.step
  if type(step) ~= "table" then return nil end
  if step.action == "sethearth" then
    local loc = bindLocation()
    if loc then return { GRAY .. C.Format(L.COMFORT_HEARTH_BIND, loc) .. "|r" } end
    return nil
  end
  if step.action ~= "hearth" then return nil end
  local left = self:Remaining()
  if left == nil then return nil end
  if left <= 0 then return { GREEN .. L.COMFORT_HEARTH_READY .. "|r" } end
  local lines = { ORANGE .. C.Format(L.COMFORT_HEARTH_WAIT, C.FormatDuration(left)) .. "|r" }
  if left > READY_SOON then
    local hint = self:Hint(entry)
    if hint then lines[#lines + 1] = GRAY .. hint .. "|r" end
  end
  return lines
end

-- Recalcule les lignes de l'étape courante ; prévient le suivi si elles changent (sauf
-- silent : le suivi se redessine déjà, par exemple au changement d'étape).
function Hearth:Check(silent)
  local P = Q.Progress
  local cur = P and P:IsEnabled() and P:Current()
  local a = cur and cur.step.action
  local lines
  if a == "hearth" or a == "sethearth" then lines = self:Lines(cur) end
  local sig = lines and table.concat(lines, "\n") or ""
  if sig ~= lastSig then
    lastSig = sig
    if not silent then C.Notify("hearth") end
  end
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
local function check() Hearth:Check() end

Q:On("LOGIN", function()
  if not ticker then ticker = Q:NewTicker(TICK, check) end
end)
Q:On("STEP_CHANGED", function()
  destCache = {}
  Hearth:Check(true)
end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "hearthHints" then check() end
end)
Q:RegisterEvent("BAG_UPDATE_COOLDOWN", check)
Q:RegisterEvent("HEARTHSTONE_BOUND", check)
