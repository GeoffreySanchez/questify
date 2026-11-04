local addonName, Q = ...

-- Rappel sacs pleins et réparation (option supplyReminders). Version pratique :
--   état : 2 places libres ou moins dans les sacs (sacs spécialisés exclus), ou l'objet équipé le
--   plus abîmé à 20 % ou moins ;
--   moment : en ville (zone de repos : auberge, capitale) ou moins de 2 minutes après la fenêtre
--   d'un marchand, et seulement si l'une des 3 prochaines étapes est à plus de 800 yards
--   (position inconnue : le rappel est donné quand même).
-- Un rappel apparaît au plus une fois toutes les 10 minutes par type (sacs, réparation) : une
-- ligne dans le suivi pendant 2 minutes (ou jusqu'à ce que le problème soit réglé) et une ligne
-- dans la discussion, jamais en combat.
local Supplies = {}
Q.Supplies = Supplies

local L = Q.L
local C = Q.Comfort

local MIN_FREE = 2
local MIN_DURABILITY = 0.2
local MERCHANT_RECENT = 120   -- secondes après la fermeture du marchand
local FAR = 800               -- yards
local NEXT_STEPS = 3
local REMIND_EVERY = 10 * 60
local SHOW_FOR = 120          -- secondes d'affichage de la ligne du suivi
local CHECK_DELAY = 1         -- regroupe les évènements de sacs en rafale
local BAGS = { 0, 1, 2, 3, 4 }
local SLOTS = 18              -- emplacements d'équipement (1-18)

local COLOR = "|cffffd040"

local merchantOpen = false
local merchantClosedAt
local fired = {}       -- [type] = GetTime() du dernier rappel
local shown = {}       -- [type] = { text, untilTime } lignes affichées
local pending = false
local lastSig

local function now() return (GetTime and GetTime()) or 0 end
local function enabled() return C.Enabled("supplyReminders") end

---------------------------------------------------------------------------
-- État des sacs et de l'équipement
---------------------------------------------------------------------------
-- Places libres dans les sacs ordinaires, nil si l'information manque (un seul sac illisible
-- suffit : un total partiel donnerait un faux rappel).
function Supplies:FreeSlots()
  local fn = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
  if type(fn) ~= "function" then return nil end
  local total = 0
  for _, bag in ipairs(BAGS) do
    local ok, free, family = pcall(fn, bag)
    if not ok then return nil end
    free = C.Number(free)
    if free == nil then return nil end
    family = C.Number(family)
    -- carquois, sac de munitions ou d'âmes : ces places ne prennent pas le butin
    if bag == 0 or family == nil or family == 0 then total = total + free end
  end
  return total
end

-- Durabilité la plus basse de l'équipement (0-1), nil si inconnue.
function Supplies:LowestDurability()
  if type(GetInventoryItemDurability) ~= "function" then return nil end
  local lowest
  for slot = 1, SLOTS do
    local ok, cur, max = pcall(GetInventoryItemDurability, slot)
    if ok then
      cur, max = C.Number(cur), C.Number(max)
      if cur and max and max > 0 then
        local r = cur / max
        if not lowest or r < lowest then lowest = r end
      end
    end
  end
  return lowest
end

local function resting()
  local v = C.Call(IsResting)
  return v == true or v == 1
end

-- Vrai si l'une des prochaines étapes mène loin (ou si on ne peut pas le savoir).
function Supplies:LeadsAway()
  local P = Q.Progress
  if not (P and P:IsEnabled()) then return true end
  local pm = Q.Maps:PlayerPos()
  if not pm then return true end
  local cur = P:Current()
  if not cur then return false end
  local count, started, known = 0, false, 0
  for _, e in ipairs(P:Entries()) do
    if e == cur then started = true end
    if started then
      local s = P:State(e)
      if s ~= "done" and s ~= "skipped" then
        count = count + 1
        local target = Q.Targets:ForEntry(e)
        if target and target.mapId then
          local d = Q.Maps:DistanceFromPlayer(target.mapId, target.x, target.y)
          if d == nil or d > FAR then return true end
          known = known + 1
        elseif e.step.action == "hearth" or e.step.action == "fly" or e.step.action == "boat" then
          return true
        end
        if count >= NEXT_STEPS then break end
      end
    end
  end
  return known == 0 and count > 0
end

---------------------------------------------------------------------------
-- Rappels
---------------------------------------------------------------------------
-- Marchand fermé depuis moins de 2 minutes. Fenêtre encore ouverte : pas de rappel (la vente de
-- la camelote est peut-être en cours), il viendra à la fermeture.
local function leftMerchant(t)
  return merchantClosedAt ~= nil and t - merchantClosedAt <= MERCHANT_RECENT
end

-- Problèmes actuels : { bags = places libres, repair = pourcentage } (champs absents si tout va bien).
function Supplies:Problems()
  local out = {}
  local free = self:FreeSlots()
  if free and free <= MIN_FREE then out.bags = free end
  local dur = self:LowestDurability()
  if dur and dur <= MIN_DURABILITY then out.repair = math.floor(dur * 100 + 0.5) end
  return out
end

local function lineFor(kind, value)
  if kind == "bags" then return C.Format(L.COMFORT_BAGS_FULL, value) end
  return C.Format(L.COMFORT_REPAIR, value)
end

local function chatFor(kind, value)
  if kind == "bags" then return C.Format(L.COMFORT_BAGS_CHAT, value) end
  return C.Format(L.COMFORT_REPAIR_CHAT, value)
end

function Supplies:Check()
  pending = false
  local t = now()
  if not enabled() then
    shown = {}
  elseif not C.InCombat() then
    local problems = self:Problems()
    -- lignes déjà affichées : retirées quand le problème est réglé ou le délai passé
    for kind, item in pairs(shown) do
      if problems[kind] == nil or t >= item.untilTime then
        shown[kind] = nil
      else
        item.text = lineFor(kind, problems[kind])
      end
    end
    local moment = not merchantOpen and (resting() or leftMerchant(t))
    local away
    for _, kind in ipairs({ "bags", "repair" }) do
      local value = problems[kind]
      local last = fired[kind]
      if value and moment and not shown[kind] and (not last or t - last >= REMIND_EVERY) then
        if away == nil then away = self:LeadsAway() end
        if away then
          fired[kind] = t
          shown[kind] = { text = lineFor(kind, value), untilTime = t + SHOW_FOR }
          Q:Print(chatFor(kind, value))
          Q:After(SHOW_FOR + 0.5, function() Supplies:Schedule() end)
        end
      end
    end
  end
  local lines = self:Lines()
  local sig = table.concat(lines, "\n")
  if sig ~= lastSig then
    lastSig = sig
    C.Notify("supplies")
  end
end

-- Lignes du suivi (colorées), liste vide si aucun rappel.
function Supplies:Lines()
  local out = {}
  if not enabled() then return out end
  for _, kind in ipairs({ "bags", "repair" }) do
    local item = shown[kind]
    if item then out[#out + 1] = COLOR .. item.text .. "|r" end
  end
  return out
end

-- Regroupe les évènements : une seule vérification CHECK_DELAY secondes plus tard.
function Supplies:Schedule()
  if pending then return end
  pending = true
  Q:After(CHECK_DELAY, function() Supplies:Check() end)
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
local function schedule() Supplies:Schedule() end

Q:RegisterEvent("MERCHANT_SHOW", function()
  merchantOpen = true
  schedule()
end)
Q:RegisterEvent("MERCHANT_CLOSED", function()
  if merchantOpen then merchantClosedAt = now() end
  merchantOpen = false
  schedule()
end)
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "PLAYER_UPDATE_RESTING",
  "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD" }) do
  Q:RegisterEvent(event, schedule)
end
Q:On("STEP_CHANGED", schedule)
Q:On("COMBAT_ENDED", schedule)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "supplyReminders" then schedule() end
end)
