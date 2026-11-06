local addonName, Q = ...

-- Alerte d'avant-poste (option supplyReminders) : avant de repartir, prévient des sacs presque
-- pleins, de l'équipement à réparer et du manque de nourriture ou de boisson.
--   état : moins de 6 places libres, ou moins de 20 % de la capacité, dans les sacs ordinaires
--   (sacs spécialisés exclus) ; l'objet équipé le plus abîmé à 20 % ou moins ; aucune nourriture
--   utilisable dans les sacs ; aucune boisson utilisable si le personnage a une réserve de mana.
--   Nourriture ou boisson : un consommable dont le sort d'utilisation porte le nom du sort
--   « Nourriture » (433) ou « Boisson » (430) du client (donc localisé), et dont le niveau requis
--   ne dépasse pas celui du joueur. Un objet des sacs pas encore en cache : son chargement est
--   demandé et rien n'est conclu tant qu'il manque (pas de fausse alerte).
--   moment : en avant-poste, c'est-à-dire en zone de repos (auberge, ville, capitale) ou moins
--   de 2 minutes après la fenêtre d'un marchand ; pas pendant la vente (fenêtre ouverte), mais à
--   sa fermeture ; jamais en combat.
-- Une alerte par passage en avant-poste et par type (sacs, réparation, nourriture, boisson) :
-- quitter l'avant-poste remet le passage à zéro, et un même type attend en plus 10 minutes entre
-- deux alertes. Une alerte donne une ligne dans le suivi pendant 2 minutes (ou jusqu'à ce que le
-- problème soit réglé), une ligne dans la discussion et un message au milieu de l'écran ; les
-- problèmes trouvés ensemble sont regroupés dans la même ligne de discussion et le même message.
local Supplies = {}
Q.Supplies = Supplies

local L = Q.L
local C = Q.Comfort

local MIN_FREE = 6             -- places libres : alerte en dessous
local MIN_FREE_RATIO = 0.2     -- part de la capacité des sacs : alerte en dessous
local MIN_DURABILITY = 0.2
local MERCHANT_RECENT = 120    -- secondes après la fermeture du marchand
local REMIND_EVERY = 10 * 60
local SHOW_FOR = 120           -- secondes d'affichage de la ligne du suivi
local CHECK_DELAY = 1          -- regroupe les évènements de sacs en rafale
local RETRY_DELAY = 2          -- objets en cours de chargement : nouvel essai
local MAX_RETRIES = 5
local BAGS = { 0, 1, 2, 3, 4 }
local SLOTS = 18               -- emplacements d'équipement (1-18)
local KINDS = { "bags", "repair", "food", "drink" }

local CONSUMABLE = 0           -- classe d'objet des consommables
-- Sous-classes retenues : nourriture et boissons (5), et consommable générique (0), où les
-- données d'époque rangent souvent la nourriture ; le nom du sort tranche dans les deux cas.
local FOOD_SUBCLASSES = { [0] = true, [5] = true }
local FOOD_SPELL, DRINK_SPELL = 433, 430

local COLOR = "|cffffd040"
local CENTER_COLOR = { r = 1, g = 0.82, b = 0.25 }

local merchantOpen = false
local merchantClosedAt
local fired = {}       -- [type] = GetTime() du dernier rappel
local visit = {}       -- [type] = true : alerte déjà donnée pendant ce passage en avant-poste
local shown = {}       -- [type] = { text, untilTime } lignes affichées
local pending = false
local retries = 0
local loading = false  -- objets des sacs en cours de chargement au dernier relevé
local lastSig

local function now() return (GetTime and GetTime()) or 0 end
local function enabled() return C.Enabled("supplyReminders") end

---------------------------------------------------------------------------
-- État des sacs et de l'équipement
---------------------------------------------------------------------------
local function containerFn(name)
  local fn = C_Container and C_Container[name]
  if type(fn) ~= "function" then fn = _G[name] end
  return type(fn) == "function" and fn or nil
end

-- Places libres et capacité des sacs ordinaires, nil si l'information manque (un seul sac
-- illisible suffit : un total partiel donnerait un faux rappel).
function Supplies:FreeSlots()
  local freeFn, sizeFn = containerFn("GetContainerNumFreeSlots"), containerFn("GetContainerNumSlots")
  if not (freeFn and sizeFn) then return nil end
  local free, total = 0, 0
  for _, bag in ipairs(BAGS) do
    local ok, n, family = pcall(freeFn, bag)
    if not ok then return nil end
    n = C.Number(n)
    local size = C.Number(C.Call(sizeFn, bag))
    if n == nil or size == nil then return nil end
    family = C.Number(family)
    -- carquois, sac de munitions ou d'âmes : ces places ne prennent pas le butin
    if bag == 0 or family == nil or family == 0 then
      free, total = free + n, total + size
    end
  end
  return free, total
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

---------------------------------------------------------------------------
-- Nourriture et boisson
---------------------------------------------------------------------------
-- Nom localisé d'un sort, nil s'il est inconnu.
local function spellName(id)
  local name = C.Call(C_Spell and C_Spell.GetSpellName, id)
  if type(name) ~= "string" then name = C.Call(GetSpellInfo, id) end
  if type(name) == "string" and name ~= "" then return name end
  return nil
end

-- Le personnage a-t-il une réserve de mana ? Inconnu = non (pas d'alerte de boisson).
function Supplies:HasMana()
  local power = Enum and Enum.PowerType
  local mana = (type(power) == "table" and C.Number(power.Mana)) or 0
  local max = C.Number(C.Call(UnitPowerMax, "player", mana))
  return max ~= nil and max > 0
end

local function playerLevel()
  return C.Number(C.Call(UnitLevel, "player")) or (Q.Player and Q.Player.level)
end

-- Objet de l'emplacement : id, ou nil (vide) ; illisible = false.
local function slotItem(bag, slot)
  local idFn = containerFn("GetContainerItemID")
  if idFn then
    local ok, id = pcall(idFn, bag, slot)
    if not ok or Q.Util.IsSecret(id) then return false end
    if id == nil then return nil end
    return C.Number(id) or false
  end
  local infoFn = C_Container and C_Container.GetContainerItemInfo
  if type(infoFn) ~= "function" then return false end
  local ok, info = pcall(infoFn, bag, slot)
  if not ok or Q.Util.IsSecret(info) then return false end
  if info == nil then return nil end
  if type(info) ~= "table" then return false end
  local id = info.itemID
  if id == nil then return nil end
  return C.Number(id) or false
end

local function requestLoad(id)
  local fn = C_Item and C_Item.RequestLoadItemDataByID
  if type(fn) == "function" then pcall(fn, id) end
end

-- Le nom du sort d'utilisation désigne-t-il ce sort ? Un nom qui contient à la fois les deux
-- (« Nourriture et boisson ») compte pour les deux.
local function spellIs(spell, name, other)
  if spell == name then return true end
  local s = spell:lower()
  return s:find(name:lower(), 1, true) ~= nil and s:find(other:lower(), 1, true) ~= nil
end

-- -> isFood, isDrink, waiting (objet pas encore en cache).
local function classify(id, foodName, drinkName, level)
  local API = Q.API
  local _, _, _, _, _, classID, subclassID = C.Call(API.GetItemInfoInstant, id)
  classID, subclassID = C.Number(classID), C.Number(subclassID)
  if classID == nil then
    requestLoad(id)
    return false, false, true
  end
  if classID ~= CONSUMABLE or not FOOD_SUBCLASSES[subclassID] then return false, false, false end
  local name, _, _, _, minLevel = C.Call(API.GetItemInfo, id)
  if name == nil then
    requestLoad(id)
    return false, false, true
  end
  minLevel = C.Number(minLevel) or 0
  if level and minLevel > level then return false, false, false end
  local spell = C.Call(C_Item and C_Item.GetItemSpell, id)
  if spell == nil then spell = C.Call(GetItemSpell, id) end
  if type(spell) ~= "string" then return false, false, false end
  return spellIs(spell, foodName, drinkName), spellIs(spell, drinkName, foodName), false
end

-- Nourriture et boisson utilisables dans les sacs : true (présente), false (absente), nil
-- (inconnu : API absente, valeur secrète ou objet en cours de chargement).
function Supplies:FoodAndDrink()
  loading = false
  local foodName, drinkName = spellName(FOOD_SPELL), spellName(DRINK_SPELL)
  local sizeFn = containerFn("GetContainerNumSlots")
  if not (foodName and drinkName and sizeFn) then return nil, nil end
  local level = playerLevel()
  local food, drink, unknown = false, false, false
  for _, bag in ipairs(BAGS) do
    local size = C.Number(C.Call(sizeFn, bag))
    if size == nil then return nil, nil end
    for slot = 1, size do
      local id = slotItem(bag, slot)
      if id == false then
        unknown = true
      elseif id then
        local isFood, isDrink, waiting = classify(id, foodName, drinkName, level)
        food, drink = food or isFood, drink or isDrink
        if waiting then unknown, loading = true, true end
      end
      if food and drink then return true, true end
    end
  end
  if unknown then
    return food or nil, drink or nil
  end
  return food, drink
end

---------------------------------------------------------------------------
-- Rappels
---------------------------------------------------------------------------
local function resting()
  local v = C.Call(IsResting)
  return v == true or v == 1
end

-- Marchand fermé depuis moins de 2 minutes. Fenêtre encore ouverte : pas de rappel (la vente de
-- la camelote est peut-être en cours), il viendra à la fermeture.
local function leftMerchant(t)
  return merchantClosedAt ~= nil and t - merchantClosedAt <= MERCHANT_RECENT
end

-- Problèmes actuels (champs absents si tout va bien) : bags = { free, total }, repair =
-- pourcentage, food = true, drink = true.
function Supplies:Problems()
  local out = {}
  local free, total = self:FreeSlots()
  if free and total and total > 0 and (free < MIN_FREE or free < total * MIN_FREE_RATIO) then
    out.bags = { free = free, total = total }
  end
  local dur = self:LowestDurability()
  if dur and dur <= MIN_DURABILITY then out.repair = math.floor(dur * 100 + 0.5) end
  local food, drink = self:FoodAndDrink()
  if food == false then out.food = true end
  if drink == false and self:HasMana() then out.drink = true end
  return out
end

local function slotsText(value)
  local fmt = value.free <= 1 and L.COMFORT_SLOTS_FREE_ONE or L.COMFORT_SLOTS_FREE
  return C.Format(fmt, value.free, value.total)
end

-- Ligne du suivi.
local function lineFor(kind, value)
  if kind == "bags" then return C.Format(L.COMFORT_BAGS_FULL, slotsText(value)) end
  if kind == "repair" then return C.Format(L.COMFORT_REPAIR, value) end
  if kind == "food" then return L.COMFORT_NO_FOOD end
  return L.COMFORT_NO_DRINK
end

-- Morceau de l'alerte regroupée (discussion, milieu de l'écran).
local function partFor(kind, value)
  if kind == "bags" then return slotsText(value) end
  if kind == "repair" then return C.Format(L.COMFORT_PART_REPAIR, value) end
  if kind == "food" then return L.COMFORT_PART_FOOD end
  return L.COMFORT_PART_DRINK
end

-- Message bien visible au milieu de l'écran : le cadre des avertissements de raid, comme l'avis
-- de nouvelle version (Core/VersionCheck.lua) ; à défaut, la zone des messages d'erreur.
local function centerMessage(text)
  if RaidWarningFrame then
    if type(RaidWarningUtil) == "table" and type(RaidWarningUtil.AddMessage) == "function" then
      if pcall(RaidWarningUtil.AddMessage, text, CENTER_COLOR) then return end
    elseif type(RaidNotice_AddMessage) == "function" then
      if pcall(RaidNotice_AddMessage, RaidWarningFrame, text, CENTER_COLOR) then return end
    end
  end
  local frame = UIErrorsFrame
  if type(frame) == "table" and type(frame.AddMessage) == "function" then
    pcall(frame.AddMessage, frame, text, CENTER_COLOR.r, CENTER_COLOR.g, CENTER_COLOR.b)
  end
end

function Supplies:Check()
  pending = false
  loading = false
  local t = now()
  -- en avant-poste (fenêtre du marchand comprise) ; en sortir ouvre un nouveau passage
  local inside = merchantOpen or resting() or leftMerchant(t)
  if not inside then visit, retries = {}, 0 end
  if not enabled() then
    shown = {}
  elseif not C.InCombat() and (inside or next(shown)) then
    local problems = self:Problems()
    -- lignes déjà affichées : retirées quand le problème est réglé ou le délai passé
    for kind, item in pairs(shown) do
      if problems[kind] == nil or t >= item.untilTime then
        shown[kind] = nil
      else
        item.text = lineFor(kind, problems[kind])
      end
    end
    if inside and not merchantOpen then
      local parts = {}
      for _, kind in ipairs(KINDS) do
        local value = problems[kind]
        local last = fired[kind]
        if value and not visit[kind] and not shown[kind] and (not last or t - last >= REMIND_EVERY) then
          visit[kind], fired[kind] = true, t
          shown[kind] = { text = lineFor(kind, value), untilTime = t + SHOW_FOR }
          parts[#parts + 1] = partFor(kind, value)
        end
      end
      if #parts > 0 then
        local msg = C.Format(L.COMFORT_SUPPLY_ALERT, table.concat(parts, L.COMFORT_LIST_SEP))
        Q:Print(msg)
        centerMessage(msg)
        Q:After(SHOW_FOR + 0.5, function() Supplies:Schedule() end)
      end
    end
    -- objets en cours de chargement : nouvel essai, même si l'évènement de chargement manque
    if loading and retries < MAX_RETRIES then
      retries = retries + 1
      Q:After(RETRY_DELAY, function() Supplies:Schedule() end)
    elseif not loading then
      retries = 0
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
  for _, kind in ipairs(KINDS) do
    local item = shown[kind]
    if item then out[#out + 1] = COLOR .. item.text .. "|r" end
  end
  return out
end

-- Regroupe les évènements : une seule vérification CHECK_DELAY secondes plus tard.
-- Juste après la connexion ou un écran de chargement, la taille des sacs peut manquer : on attend
-- LOGIN_GRACE secondes avant le premier relevé (sinon le sac à dos seul passerait pour plein).
local LOGIN_GRACE = 5
local enteredAt

function Supplies:Schedule()
  if pending then return end
  pending = true
  local wait = CHECK_DELAY
  if enteredAt then wait = math.max(wait, enteredAt + LOGIN_GRACE - now()) end
  Q:After(wait, function() Supplies:Check() end)
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
  -- fin des 2 minutes : constate la sortie de l'avant-poste (nouveau passage ensuite)
  Q:After(MERCHANT_RECENT + 0.5, schedule)
end)
Q:RegisterEvent("PLAYER_ENTERING_WORLD", function()
  enteredAt = now()
  schedule()
end)
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "PLAYER_UPDATE_RESTING",
  "ZONE_CHANGED_NEW_AREA", "PLAYER_LEVEL_UP" }) do
  Q:RegisterEvent(event, schedule)
end
-- objet des sacs arrivé dans le cache : seulement si un relevé l'attendait
for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT" }) do
  Q:RegisterEvent(event, function()
    if loading then schedule() end
  end)
end
Q:On("COMBAT_ENDED", schedule)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "supplyReminders" then schedule() end
end)
