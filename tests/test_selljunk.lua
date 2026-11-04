-- Tests de la vente automatique de la camelote (Q.SellJunk).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local bags, used

local function install()
  bags = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }
  used = {}
  C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 16 or 0 end,
    GetContainerItemInfo = function(bag, slot)
      local it = bags[bag] and bags[bag][slot]
      if not it then return nil end
      return { quality = it.quality, hyperlink = it.link, stackCount = it.count or 1, hasNoValue = it.noValue,
        isLocked = false }
    end,
    UseContainerItem = function(bag, slot)
      used[#used + 1] = bag .. ":" .. slot
      bags[bag][slot] = nil
    end,
  }
end

local function item(id, sellPrice, quality, count, noValue)
  Mock.items[id] = { id = id, name = "Item " .. id, link = "item:" .. id, sellPrice = sellPrice, quality = quality }
  return { link = "item:" .. id, quality = quality, count = count, noValue = noValue }
end

local function load()
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  install()
  bags[0][1] = item(5001, 10, 0, 3)        -- gris, 3 exemplaires : 30 pc
  bags[0][2] = item(5002, 50, 1)           -- blanc : gardé
  bags[0][3] = item(5003, 25, 0)           -- gris : 25 pc
  bags[0][4] = item(5004, 0, 0)            -- gris sans valeur : gardé
  bags[0][5] = item(5005, 40, 0, 1, true)  -- gris marqué sans valeur : gardé
  return Q
end

return {
  sells_gray_items_and_prints_total = function(t)
    local Q = load()
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(1)
    t.eq(used, { "0:1", "0:3" })
    t.ok(bags[0][2] and bags[0][4] and bags[0][5], "white and worthless items kept")
    t.eq(Mock.countPrinted(string.format(Q.L.JUNK_SOLD, 2, Q.Rewards.FormatMoney(55))), 1)
    t.eq(#Mock.errors, 0)
  end,

  stops_when_merchant_closes = function(t)
    load()
    Mock.fire("MERCHANT_SHOW")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(1)
    t.eq(used, { "0:1" }, "first sale only")
  end,

  shift_or_option_off = function(t)
    local Q = load()
    Mock.player.shift = true
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(1)
    t.eq(used, {}, "Shift pauses")
    Mock.player.shift = false
    Mock.fire("MERCHANT_CLOSED")
    Q.Settings:Set("sellJunk", false)
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(1)
    t.eq(used, {}, "option off")
  end,
}
