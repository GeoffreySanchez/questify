local addonName, Q = ...

-- Vente automatique de la camelote (objets de qualité médiocre, gris) à l'ouverture d'un marchand.
-- Option sellJunk ; Maj (Shift) en ouvrant le marchand suspend la vente, comme les autres
-- automatisations. Les objets partent un par un (petit délai) et la vente s'arrête si la fenêtre
-- du marchand se ferme. Un message dit combien d'objets et pour combien.
local SellJunk = {}
Q.SellJunk = SellJunk

local L = Q.L

local SELL_DELAY = 0.15   -- secondes entre deux ventes
local BAGS = { 0, 1, 2, 3, 4 }
local POOR = 0

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

-- Objets gris vendables : { { bag, slot, value } }.
function SellJunk:Collect()
  local list = {}
  for _, bag in ipairs(BAGS) do
    for slot = 1, numSlots(bag) do
      local info = slotInfo(bag, slot)
      if info and info.quality == POOR and not info.noValue and not info.locked and type(info.link) == "string" then
        local value = sellPrice(info.link) * (info.count or 1)
        if value > 0 then list[#list + 1] = { bag = bag, slot = slot, value = value } end
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
    -- l'objet est-il toujours là et toujours gris ?
    local info = slotInfo(item.bag, item.slot)
    if info and info.quality == POOR and not info.locked then
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
