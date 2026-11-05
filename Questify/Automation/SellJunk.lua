local addonName, Q = ...

-- Vente automatique de la camelote à l'ouverture d'un marchand : les objets gris, et l'équipement
-- blanc (armes, armures) qui ne sert pas : ni une amélioration pour la classe, ni la moitié d'une
-- paire main droite + main gauche qui battrait l'arme à deux mains portée, ni un objet pour un
-- emplacement vide. Arme à deux mains portée : la meilleure main droite blanche et la meilleure
-- main gauche blanche des sacs restent (paire encore incomplète). Jamais : un objet (même gris)
-- qu'on vient de recommander d'équiper, le vert et au-dessus, les objets blancs qui ne s'équipent
-- pas (composants de métier, plantes, tissu, nourriture, réactifs, sacs, objets de quête), les
-- outils de métier, un objet sans prix de vente ou verrouillé. Un équipement des sacs pas encore
-- en cache : aucun blanc vendu à cette visite (le gris, si).
-- Option sellJunk ; Maj (Shift) en ouvrant le marchand suspend la vente, comme les autres
-- automatisations. Les objets partent un par un (petit délai) et la vente s'arrête si la fenêtre
-- du marchand se ferme. Un message dit combien d'objets et pour combien.
local SellJunk = {}
Q.SellJunk = SellJunk

local L = Q.L

local SELL_DELAY = 0.15   -- secondes entre deux ventes
local BAGS = { 0, 1, 2, 3, 4 }
local POOR, COMMON = 0, 1
local QUEST_BIND = 4      -- objet lié à une quête (bindType de GetItemInfo)
local FISHING_POLE = 20   -- sous-classe d'arme des cannes à pêche

-- Outils de métier blancs qui s'équipent comme des armes : jamais vendus.
local TOOLS = {
  [2901] = true,    -- Mining Pick (minage)
  [5956] = true,    -- Blacksmith Hammer (forge)
  [7005] = true,    -- Skinning Knife (dépeçage)
  [6219] = true,    -- Arclight Spanner (ingénierie)
}

local function setting(path) return Q.Settings:Get(path) end

local function numSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
  if GetContainerNumSlots then return GetContainerNumSlots(bag) or 0 end
  return 0
end

-- -> { quality, link, count, noValue, locked } ou nil
local function slotInfo(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if type(info) ~= "table" then return nil end
    return { quality = info.quality, link = info.hyperlink, count = info.stackCount or 1,
      noValue = info.hasNoValue, locked = info.isLocked }
  end
  if GetContainerItemInfo then
    local _, count, locked, quality, _, _, link, _, noValue = GetContainerItemInfo(bag, slot)
    if not link then return nil end
    return { quality = quality, link = link, count = count or 1, noValue = noValue, locked = locked }
  end
  return nil
end

local function useItem(bag, slot)
  if C_Container and C_Container.UseContainerItem then return C_Container.UseContainerItem(bag, slot) end
  if UseContainerItem then return UseContainerItem(bag, slot) end
end

local function sellPrice(link)
  local price = select(11, Q.API.GetItemInfo(link))
  return tonumber(price) or 0
end

local function itemId(link)
  return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

-- Emplacement d'équipement (GetItemInfoInstant, connu sans le cache) : une chaîne non vide, hors
-- objets non équipables. Une cage de mascotte (lien battlepet) n'en a pas.
local NON_EQUIP = { [""] = true, INVTYPE_NON_EQUIP = true, INVTYPE_NON_EQUIP_IGNORE = true }
local function equipSlot(loc)
  return type(loc) == "string" and not NON_EQUIP[loc]
end

-- Équipement blanc candidat à la vente : une arme ou une armure qui va dans un emplacement
-- d'équipement connu (pas un sac, une chemise, un tabard, des munitions), hors outils de métier
-- et objets de quête. Un objet pas encore en cache n'est pas jugé.
local function sellableGear(item)
  if not item.loaded or (item.classID ~= 2 and item.classID ~= 4) then return false end
  if not Q.Rewards:SlotsFor(item.equipLoc) then return false end
  if item.bindType == QUEST_BIND then return false end
  if item.classID == 2 and item.subclassID == FISHING_POLE then return false end
  return not TOOLS[itemId(item.link)]
end

-- Le personnage, au niveau requis de l'objet s'il est plus haut : un blanc qu'on pourra bientôt
-- porter est jugé comme s'il était déjà portable.
local function judgeAs(item)
  local P = Q.Player or {}
  return { classFile = P.classFile, level = math.max(P.level or 1, item.minLevel or 0) }
end

-- L'équipement blanc sert-il encore ? Amélioration (ou moitié d'une paire meilleure que l'arme à
-- deux mains portée, avec les équipements des sacs), ou objet pour un emplacement vide.
local function stillUseful(item, pool)
  local R, player = Q.Rewards, judgeAs(item)
  local gain = R:UpgradeGain(item, player, nil, pool)
  if gain and gain > R.EPSILON then return true end
  return R:FillsEmptySlot(item, player)
end

-- Arme à deux mains portée : meilleure main droite blanche et meilleure main gauche blanche
-- (une de chaque, pas le même objet) -> { [objet] = true } à garder.
local function bestHalves(whites)
  local R = Q.Rewards
  local classFile = Q.Player and Q.Player.classFile
  local function best(fits, except)
    local top, topScore
    for _, it in ipairs(whites) do
      if it ~= except and fits(R, it, judgeAs(it)) then
        local v = R:Score(it.stats, classFile)
        if not top or v > topScore then top, topScore = it, v end
      end
    end
    return top
  end
  local keep = {}
  local main = best(R.FitsMain)
  local off = best(R.FitsOff, main)
  if main then keep[main] = true end
  if off then keep[off] = true end
  return keep
end

-- Objets vendables, dans l'ordre des sacs : { { bag, slot, value, link, quality } }.
function SellJunk:Collect()
  local R = Q.Rewards
  -- 1. relevé des sacs : les gris, les blancs équipables (à juger), et la réserve des équipements
  --    (toutes qualités, comme pour l'annonce d'amélioration) où chercher l'autre moitié d'une paire
  local found, pool, whites, uncached = {}, {}, {}, false
  for _, bag in ipairs(BAGS) do
    for slot = 1, numSlots(bag) do
      local info = slotInfo(bag, slot)
      if info and type(info.link) == "string" and type(info.quality) == "number" then
        local item = R:ReadItem(info.link)
        if item.loaded and item.equipLoc and item.equipLoc ~= "" then pool[#pool + 1] = item end
        if info.quality == POOR then
          found[#found + 1] = { bag = bag, slot = slot, info = info }
        else
          -- pas encore en cache et un équipement : on ne juge aucun blanc cette fois
          if not item.loaded and equipSlot(item.equipLoc) then
            uncached = true
            R:RequestLoad({ item })
          end
          if info.quality == COMMON and sellableGear(item) then
            found[#found + 1] = { bag = bag, slot = slot, info = info, gear = item }
            whites[#whites + 1] = item
          end
        end
      end
    end
  end
  -- 2. arme à deux mains portée : la meilleure moitié blanche de chaque main reste
  local main = R:EquippedItem(16)
  local keep = (main and main.equipLoc == "INVTYPE_2HWEAPON") and bestHalves(whites) or {}
  -- 3. ce qui part : jamais un objet verrouillé, sans valeur ou qu'on vient de recommander, ni un
  --    blanc qui sert encore
  local list = {}
  for _, f in ipairs(found) do
    local info, item = f.info, f.gear
    local kept = info.noValue or info.locked or R:Recommended(info.link)
      or (item and (uncached or keep[item] or stillUseful(item, pool)))
    if not kept then
      local value = sellPrice(info.link) * (info.count or 1)
      if value > 0 then
        list[#list + 1] = { bag = f.bag, slot = f.slot, value = value, link = info.link, quality = info.quality }
      end
    end
  end
  return list
end

function SellJunk:Start()
  if setting("sellJunk") == false then return end
  if IsShiftKeyDown and IsShiftKeyDown() then return end
  local list = self:Collect()
  if #list == 0 then return end
  self.serial = (self.serial or 0) + 1
  local mine, i, count, total = self.serial, 0, 0, 0
  local function step()
    if mine ~= SellJunk.serial or not SellJunk.open then return end
    i = i + 1
    local item = list[i]
    if not item then
      if count > 0 then Q:Print(L.JUNK_SOLD, count, Q.Rewards.FormatMoney(total)) end
      return
    end
    -- l'objet est-il toujours là, le même et de la même qualité ?
    local info = slotInfo(item.bag, item.slot)
    if info and info.link == item.link and info.quality == item.quality and not info.locked then
      useItem(item.bag, item.slot)
      count, total = count + 1, total + item.value
    end
    Q:After(SELL_DELAY, step)
  end
  step()
end

Q:RegisterEvent("MERCHANT_SHOW", function()
  SellJunk.open = true
  Q.SafeCall(SellJunk.Start, SellJunk)
end)
Q:RegisterEvent("MERCHANT_CLOSED", function()
  SellJunk.open = false
  SellJunk.serial = (SellJunk.serial or 0) + 1
end)
