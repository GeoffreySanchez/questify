local addonName, Q = ...

-- Alerte élites / danger (option dangerAlert). Pendant une étape « complete » (zone d'objectif),
-- hors instance : les barres de nom visibles et la cible sont examinées ; un monstre élite, ou de
-- 3 niveaux ou plus au-dessus du joueur, donne une ligne d'avertissement dans le suivi
-- (Danger:Line) et une seule ligne dans la discussion par monstre toutes les 5 minutes (jamais en
-- combat). Toute valeur secrète est ignorée : le monstre ne compte pas.
local Danger = {}
Q.Danger = Danger

local L = Q.L
local C = Q.Comfort

local LEVEL_GAP = 3
local CHAT_EVERY = 5 * 60   -- secondes entre deux messages pour un même monstre
local ELITE = { elite = true, rareelite = true, worldboss = true }
local COLOR = "|cffff8040"

local tracked = {}    -- unités dont la barre de nom est affichée : [unit] = true
local warned = {}     -- [clé du monstre] = GetTime() du dernier message
local dangers = {}    -- [unit] = résultat d'Evaluate pour les unités dangereuses
local threat          -- menace affichée : { name, levelText, elite }
local lastLine

local function now() return (GetTime and GetTime()) or 0 end
local function enabled() return C.Enabled("dangerAlert") end

-- Vrai quand l'alerte doit regarder les monstres : option, route active, étape « complete »,
-- hors instance.
function Danger:Active()
  if not enabled() then return false end
  local P = Q.Progress
  if not (P and P:IsEnabled()) then return false end
  local cur = P:Current()
  if not (cur and cur.step.action == "complete") then return false end
  return not C.InInstance()
end

-- Appel d'une fonction d'unité ; nil si absente, en erreur ou secrète.
local function unitValue(fn, ...)
  return C.Call(fn, ...)
end

-- Booléen d'une fonction d'unité (true ou 1 selon les clients) ; faux si inconnu.
local function unitFlag(fn, ...)
  local v = C.Call(fn, ...)
  return v == true or v == 1
end

local function playerLevel()
  local lvl = C.Number(unitValue(UnitLevel, "player"))
  return lvl or (Q.Player and Q.Player.level) or 1
end

-- Clé d'un monstre pour limiter les messages : npcID, sinon nom ; nil si inconnu.
local function mobKey(unit, name)
  local NP = Q.UI and Q.UI.Nameplates
  local id = NP and NP.NpcId and NP:NpcId(unit)
  if type(id) == "number" then return "npc:" .. id end
  if name then return "name:" .. name end
  return nil
end

-- Examine une unité : -> { name, levelText, elite, level, key } si elle est dangereuse, sinon nil.
function Danger:Evaluate(unit)
  if type(unit) ~= "string" then return nil end
  if not unitFlag(UnitExists, unit) then return nil end
  if unitFlag(UnitIsPlayer, unit) or unitFlag(UnitPlayerControlled, unit) then return nil end
  if unitFlag(UnitIsDead, unit) then return nil end
  if not unitFlag(UnitCanAttack, "player", unit) then return nil end
  local class = unitValue(UnitClassification, unit)
  local elite = type(class) == "string" and ELITE[class] == true
  local level = C.Number(unitValue(UnitLevel, unit))
  if level == nil and not elite then return nil end
  local high = level ~= nil and (level < 0 or level - playerLevel() >= LEVEL_GAP)
  if not (elite or high) then return nil end
  local name = unitValue(UnitName, unit)
  if type(name) ~= "string" or name == "" then name = nil end
  local levelText = (level == nil or level < 0) and "??" or tostring(level)
  return { name = name, levelText = levelText, elite = elite, level = level or 99, key = mobKey(unit, name) }
end

-- Plus dangereux d'abord : élite, puis niveau le plus haut.
local function worse(a, b)
  if a.elite ~= b.elite then return a.elite end
  return (a.level or 0) > (b.level or 0)
end

local function warnChat(info)
  if not info.key or C.InCombat() then return end
  local t = now()
  local last = warned[info.key]
  if last and t - last < CHAT_EVERY then return end
  warned[info.key] = t
  local name = info.name or L.COMFORT_DANGER_UNKNOWN
  Q:Print(info.elite and L.COMFORT_DANGER_CHAT_ELITE or L.COMFORT_DANGER_CHAT_HIGH, name, info.levelText)
end

-- Examine une unité et garde le résultat (chaque barre de nom n'est lue qu'à son apparition).
local function evalUnit(unit)
  local info
  if Danger:Active() then
    local ok, res = pcall(Danger.Evaluate, Danger, unit)
    if ok then info = res end
  end
  dangers[unit] = info
  if info then warnChat(info) end
end

-- Menace la plus forte parmi les unités gardées ; prévient le suivi si la ligne change.
local function refreshLine()
  local best
  for _, info in pairs(dangers) do
    if not best or worse(info, best) then best = info end
  end
  threat = best
  local line = Danger:Line()
  if line ~= lastLine then
    lastLine = line
    C.Notify("danger")
  end
end

-- Relit toutes les barres de nom suivies et la cible (changement d'étape, de zone, fin de combat).
function Danger:Scan()
  dangers = {}
  if self:Active() then
    evalUnit("target")
    for unit in pairs(tracked) do evalUnit(unit) end
  end
  refreshLine()
end

-- Ligne d'avertissement du suivi (colorée), ou nil.
function Danger:Line()
  local t = threat
  if not t or not enabled() then return nil end
  local name = t.name or L.COMFORT_DANGER_UNKNOWN
  return COLOR .. C.Format(t.elite and L.COMFORT_DANGER_ELITE or L.COMFORT_DANGER_HIGH, name, t.levelText) .. "|r"
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
local function scan() Danger:Scan() end

Q:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, unit)
  if Q.Util.IsSecret(unit) or type(unit) ~= "string" then return end
  tracked[unit] = true
  evalUnit(unit)
  refreshLine()
end)
Q:RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(_, unit)
  if Q.Util.IsSecret(unit) or type(unit) ~= "string" then return end
  tracked[unit] = nil
  dangers[unit] = nil
  refreshLine()
end)
Q:RegisterEvent("PLAYER_TARGET_CHANGED", function()
  evalUnit("target")
  refreshLine()
end)
Q:RegisterEvent("ZONE_CHANGED_NEW_AREA", scan)
Q:On("STEP_CHANGED", scan)
Q:On("COMBAT_ENDED", scan)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "dangerAlert" then scan() end
end)
