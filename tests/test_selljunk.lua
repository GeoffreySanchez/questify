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
        isLocked = it.locked == true }
    end,
    GetContainerItemLink = function(bag, slot)
      local it = bags[bag] and bags[bag][slot]
      return it and it.link
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

-- Équipement (arme ou armure) de qualité donnée, déclaré dans le mock ; renvoie l'objet du sac.
local DPS, ARMOR, STR = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "RESISTANCE0_NAME", "ITEM_MOD_STRENGTH_SHORT"
local function gear(id, quality, def)
  def.id, def.quality = id, quality
  def.name = def.name or ("Gear " .. id)
  def.link = "item:" .. id
  if def.sellPrice == nil then def.sellPrice = 10 end
  Mock.items[id] = def
  return { link = def.link, quality = quality, locked = def.locked }
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

  -- Ruling F1 : gris + équipement blanc inutile ; jamais le vert, ni le blanc non équipable, ni la
  -- moitié blanche d'une paire qui bat l'arme à deux mains portée.
  sells_useless_white_gear_only = function(t)
    local Q = load()
    Q.Player.classFile, Q.Player.level = "SHAMAN", 10
    -- portée : une hache à deux mains (chaman : 10)
    Mock.inventory[16] = "item:5100"
    gear(5100, 1, { equipLoc = "INVTYPE_2HWEAPON", classID = 2, subclassID = 1, stats = { [DPS] = 4 } })
    bags[0][6] = gear(5101, 1, { name = "Wooden Mace", equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 4,
      stats = { [DPS] = 3 } })                                -- 7,5 : avec le bouclier vert, 10,55 > 10
    bags[0][7] = gear(5102, 2, { equipLoc = "INVTYPE_SHIELD", classID = 4, subclassID = 6,
      stats = { [ARMOR] = 150, [STR] = 1 } })                 -- vert : 2,25 + 0,8
    bags[0][8] = gear(5103, 1, { name = "Bent Dagger", equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15,
      sellPrice = 20, stats = { [DPS] = 1 } })                -- 2,5 + 3,05 < 10 : inutile
    bags[0][9] = gear(5104, 1, { name = "Plate Vest", equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 4,
      sellPrice = 40, stats = { [STR] = 3 } })                -- plaque : jamais pour un chaman
    bags[0][10] = item(5105, 15, 1)                           -- tissu blanc (pas un équipement)
    Mock.items[5105].classID, Mock.items[5105].subclassID = 7, 5
    bags[0][11] = item(5106, 12, 1)                           -- plante blanche
    Mock.items[5106].classID, Mock.items[5106].subclassID = 7, 9
    bags[0][12] = gear(5107, 2, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, stats = { [DPS] = 0.5 } })
    bags[0][13] = gear(5108, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, sellPrice = 0,
      stats = { [DPS] = 0.5 } })                              -- sans prix de vente
    bags[0][14] = gear(5109, 1, { equipLoc = "INVTYPE_HAND", classID = 4, subclassID = 2, stats = { [STR] = 1 } })
    -- gants : mains vides, donc une amélioration
    bags[0][15] = gear(5110, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, locked = true,
      stats = { [DPS] = 1 } })                                -- verrouillé
    bags[0][16] = gear(2901, 1, { name = "Mining Pick", equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 0,
      stats = { [DPS] = 1 } })                                -- outil de métier
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3", "0:8", "0:9" })
    t.ok(bags[0][6], "white mace kept: half of a better pair")
    t.ok(bags[0][7] and bags[0][12], "green never sold")
    t.ok(bags[0][10] and bags[0][11], "white cloth and herb never sold")
    t.ok(bags[0][13] and bags[0][15] and bags[0][16], "no price, locked and tool kept")
    t.ok(bags[0][14], "white upgrade kept")
    t.eq(Mock.countPrinted(string.format(Q.L.JUNK_SOLD, 4, Q.Rewards.FormatMoney(30 + 25 + 20 + 40))), 1)
    t.eq(#Mock.errors, 0)
  end,

  fishing_pole_and_recommended_item_kept = function(t)
    local Q = load()
    Q.Player.classFile, Q.Player.level = "WARRIOR", 10
    Mock.inventory[16] = "item:5200"
    gear(5200, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, stats = { [DPS] = 10 } })
    bags[0][6] = gear(5201, 1, { name = "Fishing Pole", equipLoc = "INVTYPE_2HWEAPON", classID = 2, subclassID = 20,
      stats = {} })
    bags[0][7] = gear(5202, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, stats = { [DPS] = 2 } })
    bags[0][8] = gear(5203, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, stats = { [DPS] = 2 } })
    -- l'annonce vient de recommander 5202 : on ne le vend pas
    Q.UI.UpgradePopup:Push({ link = "item:5202", name = "Gear 5202" })
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3", "0:8" })
    t.ok(bags[0][6] and bags[0][7])
  end,

  -- Ruling F1-bis : arme à deux mains portée, paire encore incomplète : la meilleure main droite
  -- blanche et la meilleure main gauche blanche restent, une de chaque.
  two_hander_keeps_the_best_white_main_and_off_hand = function(t)
    local Q = load()
    Q.Player.classFile, Q.Player.level = "SHAMAN", 10
    Mock.inventory[16] = "item:5300"
    gear(5300, 1, { equipLoc = "INVTYPE_2HWEAPON", classID = 2, subclassID = 10, stats = { [DPS] = 10 } })  -- 25
    bags[0][6] = gear(5301, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 4, stats = { [DPS] = 3 } })
    bags[0][7] = gear(5302, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 4, stats = { [DPS] = 2 } })
    bags[0][8] = gear(5303, 1, { equipLoc = "INVTYPE_SHIELD", classID = 4, subclassID = 6, stats = { [ARMOR] = 100 } })
    bags[0][9] = gear(5304, 1, { equipLoc = "INVTYPE_SHIELD", classID = 4, subclassID = 6, stats = { [ARMOR] = 50 } })
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3", "0:7", "0:9" }, "the weaker mace and shield are sold")
    t.ok(bags[0][6] and bags[0][8], "best white mace and best white shield kept")
  end,

  -- Une masse grise moitié d'une paire annoncée n'est pas vendue.
  gray_half_of_an_announced_pair_kept = function(t)
    local Q = load()
    Q.Player.classFile, Q.Player.level = "SHAMAN", 10
    Mock.inventory[16] = "item:5400"
    gear(5400, 1, { equipLoc = "INVTYPE_2HWEAPON", classID = 2, subclassID = 10, stats = { [DPS] = 4 } })   -- 10
    bags[0][6] = gear(5401, 0, { name = "Worn Mace", equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 4,
      stats = { [DPS] = 3 } })                                -- grise : 7,5
    local P = Q.UI.UpgradePopup
    P.snapshot = P.ReadBags()
    bags[0][7] = gear(5402, 2, { name = "Shield", equipLoc = "INVTYPE_SHIELD", classID = 4, subclassID = 6,
      stats = { [ARMOR] = 200, [STR] = 1 } })                 -- 3,8 : 11,3 > 10
    Mock.fire("BAG_UPDATE_DELAYED")
    t.eq(P.current and P.current.pair and P.current.pair.main, "item:5401", "the gray mace is announced")
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3" })
    t.ok(bags[0][6], "announced gray mace kept")
  end,

  -- Ruling F1-ter : un blanc utilisable pour un emplacement vide reste, même de score nul.
  white_item_for_an_empty_slot_kept = function(t)
    local Q = load()
    Q.Player.classFile, Q.Player.level = "MAGE", 10
    Mock.inventory[5] = "item:5500"
    gear(5500, 1, { equipLoc = "INVTYPE_ROBE", classID = 4, subclassID = 1, stats = { ["ITEM_MOD_INTELLECT_SHORT"] = 5 } })
    bags[0][6] = gear(5501, 1, { name = "Cloth Boots", equipLoc = "INVTYPE_FEET", classID = 4, subclassID = 1,
      stats = { [ARMOR] = 10 } })                             -- pas de bottes portées, score 0 pour un mage
    bags[0][7] = gear(5502, 1, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 1,
      stats = { [ARMOR] = 12 } })                             -- robe portée meilleure
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3", "0:7" })
    t.ok(bags[0][6], "boots for the empty feet slot kept")
  end,

  rogue_keeps_a_white_dagger_for_the_empty_off_hand = function(t)
    local Q = load()
    Q.Player.classFile, Q.Player.level = "ROGUE", 12
    Mock.inventory[16] = "item:5600"
    gear(5600, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, stats = { [DPS] = 10 } })
    bags[0][6] = gear(5601, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, stats = { [DPS] = 2 } })
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3" })
    t.ok(bags[0][6], "white dagger kept: the off-hand is empty")
    -- main gauche occupée par mieux : la dague part
    Mock.fire("MERCHANT_CLOSED")
    Mock.inventory[17] = "item:5602"
    gear(5602, 1, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, stats = { [DPS] = 5 } })
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3", "0:6" })
  end,

  -- Ruling F1-quater : un équipement des sacs pas encore en cache : aucun blanc vendu à cette visite.
  -- GetItemInfoInstant connaît l'emplacement sans le cache ; GetItemInfo pas encore (bouchon local).
  uncached_gear_blocks_white_sales = function(t)
    local Q = load()
    Q.Player.classFile, Q.Player.level = "SHAMAN", 10
    bags[0][6] = gear(5701, 1, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 4, stats = { [STR] = 3 } })
    bags[0][7] = gear(5799, 1, { equipLoc = "INVTYPE_LEGS", classID = 4, subclassID = 1, stats = { [STR] = 1 } })
    local getInfo, cached = C_Item.GetItemInfo, false
    C_Item.GetItemInfo = function(it)
      if not cached and tostring(it):find("item:5799", 1, true) then return nil end   -- pas en cache
      return getInfo(it)
    end
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3" }, "gray sold, no white this time")
    Mock.fire("MERCHANT_CLOSED")
    cached = true
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    t.eq(used, { "0:1", "0:3", "0:6" }, "sold once everything is known")
    C_Item.GetItemInfo = getInfo
  end,

  -- M7 : une cage de mascotte (ou tout objet non équipable) hors cache ne bloque pas la vente du blanc.
  uncached_pet_cage_does_not_block_white_sales = function(t)
    local Q = load()
    Q.Player.classFile, Q.Player.level = "SHAMAN", 10
    bags[0][6] = gear(5701, 1, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 4, stats = { [STR] = 3 } })
    -- mascotte en cage : lien battlepet, inconnu de GetItemInfo et de GetItemInfoInstant
    bags[0][7] = { link = "|cffffffff|Hbattlepet:40:1:0:152:12:12:0x0|h[Pet]|h|r", quality = 1 }
    -- objet non équipable hors cache : GetItemInfoInstant dit INVTYPE_NON_EQUIP_IGNORE
    Mock.items[5798] = { id = 5798, name = "Pet Cage", link = "item:5798", quality = 1, classID = 17,
      equipLoc = "INVTYPE_NON_EQUIP_IGNORE" }
    bags[0][8] = { link = "item:5798", quality = 1 }
    local getInfo = C_Item.GetItemInfo
    C_Item.GetItemInfo = function(it)
      if tostring(it):find("item:5798", 1, true) then return nil end   -- pas en cache
      return getInfo(it)
    end
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(3)
    C_Item.GetItemInfo = getInfo
    t.eq(used, { "0:1", "0:3", "0:6" }, "useless white chest sold anyway")
    t.ok(bags[0][7] and bags[0][8], "pet cage and non-equippable item kept")
  end,
}
