-- Tests de l'annonce d'amélioration d'équipement (Q.UI.UpgradePopup).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local STR, STA, INT = "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_INTELLECT_SHORT"

local bags   -- { [bag] = { [slot] = lien } }
local equipped

local function installBags()
  bags = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }
  equipped = {}
  C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 16 or 0 end,
    GetContainerItemLink = function(bag, slot) return bags[bag] and bags[bag][slot] end,
  }
  C_Item.EquipItemByName = function(link) equipped[#equipped + 1] = link end
end

local function item(id, def)
  def.id = id
  def.name = def.name or ("Item " .. id)
  def.link = "item:" .. id
  def.minLevel = def.minLevel or 0
  Mock.items[id] = def
  return def.link
end

local function load()
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  installBags()
  Mock.player.level = 5
  Mock.fire("PLAYER_LEVEL_UP", 5)
  Q.UI.UpgradePopup.snapshot = Q.UI.UpgradePopup.ReadBags()
  -- porté : une chemise de mailles faible
  Mock.inventory[5] = item(3001, { name = "Worn Mail Vest", equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3,
    stats = { [STR] = 1 } })
  return Q
end

local function receive(slot, link)
  bags[0][slot] = link
  Mock.fire("BAG_UPDATE_DELAYED")
end

local function shown(Q)
  local f = Q.UI.UpgradePopup.frame
  return f ~= nil and f:IsShown()
end

return {
  upgrade_announced_with_icon_and_text = function(t)
    local Q = load()
    receive(1, item(3002, { name = "Ringmail Hauberk", equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3,
      texture = 132624, stats = { [STR] = 4, [STA] = 3 } }))
    local P = Q.UI.UpgradePopup
    t.ok(shown(Q), "popup in the middle of the screen")
    t.eq(P.icon:GetTexture(), 132624)
    t.eq(P.text:GetText(), string.format(Q.L.UI_UPGRADE_TEXT, "item:3002"))
    local p, rel = P.frame:GetPoint(1)
    t.eq(p, "CENTER"); t.ok(rel == UIParent)
    t.ok(P.pulse:IsPlaying(), "glow around the icon")
    Mock.advance(8)
    t.ok(not shown(Q), "fades after a few seconds")
    t.eq(#Mock.errors, 0)
  end,

  no_popup_for_worse_unusable_or_non_gear = function(t)
    local Q = load()
    receive(1, item(3003, { name = "Rusty Vest", equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3,
      stats = {} }))
    t.ok(not shown(Q), "worse than what is worn")
    receive(2, item(3004, { name = "Silk Robe", equipLoc = "INVTYPE_ROBE", classID = 4, subclassID = 1,
      stats = { [INT] = 20 } }))
    t.ok(not shown(Q), "no strength for a warrior: no gain")
    receive(3, item(3005, { name = "Plate Chest", equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 4,
      stats = { [STR] = 30 } }))
    t.ok(not shown(Q), "plate before level 40")
    receive(4, item(3006, { name = "Wolf Meat", equipLoc = "", classID = 7, subclassID = 8 }))
    t.ok(not shown(Q), "not gear")
  end,

  items_present_at_login_not_announced = function(t)
    Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
    installBags()
    bags[0][1] = item(3010, { name = "Big Axe", equipLoc = "INVTYPE_2HWEAPON", classID = 2, subclassID = 1,
      stats = { [STR] = 10 } })
    local Q = Mock.reload()
    Mock.fire("BAG_UPDATE_DELAYED")
    t.ok(not shown(Q), "only new items")
  end,

  moving_items_is_not_new = function(t)
    local Q = load()
    local link = item(3011, { name = "Ringmail Gloves", equipLoc = "INVTYPE_HAND", classID = 4, subclassID = 3,
      stats = { [STR] = 2 } })
    receive(1, link)
    Q.UI.UpgradePopup:Next()
    bags[0][1] = nil
    receive(5, link)
    t.ok(not shown(Q), "same item, other slot")
  end,

  click_equips_right_click_closes_queue_follows = function(t)
    local Q = load()
    local a = item(3020, { name = "Ringmail Gloves", equipLoc = "INVTYPE_HAND", classID = 4, subclassID = 3,
      stats = { [STR] = 2 } })
    local b = item(3021, { name = "Ringmail Boots", equipLoc = "INVTYPE_FEET", classID = 4, subclassID = 3,
      stats = { [STA] = 2 } })
    bags[0][1], bags[0][2] = a, b
    Mock.fire("BAG_UPDATE_DELAYED")
    local P = Q.UI.UpgradePopup
    local first = P.current.link
    P.frame:GetScript("OnClick")(P.frame, "LeftButton")
    t.eq(equipped, { first }, "left click equips")
    t.ok(shown(Q), "next upgrade in the queue")
    t.ok(P.current.link ~= first)
    P.frame:GetScript("OnClick")(P.frame, "RightButton")
    t.eq(#equipped, 1, "right click only closes")
    t.ok(not shown(Q))
  end,

  no_equip_in_combat = function(t)
    local Q = load()
    receive(1, item(3030, { name = "Ringmail Gloves", equipLoc = "INVTYPE_HAND", classID = 4, subclassID = 3,
      stats = { [STR] = 2 } }))
    Mock.player.combat = true
    t.eq(Q.UI.UpgradePopup:EquipCurrent(), false)
    t.eq(equipped, {})
    Mock.player.combat = false
  end,

  waits_for_item_cache = function(t)
    local Q = load()
    receive(1, "item:3040")             -- pas encore en cache
    t.ok(not shown(Q))
    item(3040, { name = "Ringmail Belt", equipLoc = "INVTYPE_WAIST", classID = 4, subclassID = 3,
      stats = { [STR] = 3 } })
    Mock.advance(0.5)
    t.ok(shown(Q), "announced once the item is loaded")
  end,

  option_off = function(t)
    local Q = load()
    Q.Settings:Set("upgradePopup", false)
    receive(1, item(3050, { name = "Ringmail Gloves", equipLoc = "INVTYPE_HAND", classID = 4, subclassID = 3,
      stats = { [STR] = 2 } }))
    t.ok(not shown(Q))
  end,
}
