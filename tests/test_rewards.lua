-- Tests du choix de récompense (Q.Rewards) : utilisabilité, score, comparaison à l'équipé.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  return Mock.loadAddon(TOC, opts)
end

local STR, AGI, STA, INT, SPI = "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STAMINA_SHORT",
  "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_SPIRIT_SHORT"
local ARMOR, DPS = "RESISTANCE0_NAME", "ITEM_MOD_DAMAGE_PER_SECOND_SHORT"

-- Déclare un objet dans le mock et renvoie son lien.
local function item(id, def)
  def.id = id
  def.name = def.name or ("Item " .. id)
  def.link = "item:" .. id
  def.minLevel = def.minLevel or 0
  def.sellPrice = def.sellPrice or 0
  Mock.items[id] = def
  return def.link
end

local function choiceOf(def, index)
  return {
    index = index or 1, link = def.link, equipLoc = def.equipLoc, classID = def.classID, subclassID = def.subclassID,
    minLevel = def.minLevel or 0, sellPrice = def.sellPrice or 0, stats = def.stats or {},
  }
end

local warrior = function(level) return { classFile = "WARRIOR", level = level or 10 } end

return {
  pick_upgrade = function(t)
    local Q = load()
    item(1001, { name = "Apprentice's Robe", equipLoc = "INVTYPE_ROBE", classID = 4, subclassID = 1,
      sellPrice = 50, stats = { [INT] = 5, [STA] = 2, [ARMOR] = 10 } })
    item(1002, { name = "Ringmail Hauberk", equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3,
      minLevel = 5, sellPrice = 80, stats = { [STR] = 4, [STA] = 3, [ARMOR] = 60 } })
    Mock.questFrame.choices = { { link = "item:1001" }, { link = "item:1002" } }
    local choices = Q.Rewards:CollectChoices()
    local index, reason, detail = Q.Rewards:Pick(choices, warrior(10))
    t.eq(index, 2); t.eq(reason, "upgrade")
    t.ok(type(detail) == "number" and detail > 0, "detail is the score gain")
  end,

  collect_choices_shape = function(t)
    local Q = load()
    item(1002, { name = "Ringmail Hauberk", equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3,
      minLevel = 5, sellPrice = 80, stats = { [STR] = 4 } })
    item(1003, { name = "Wolf Meat", equipLoc = "", classID = 7, subclassID = 8, sellPrice = 3 })
    Mock.questFrame.choices = { { link = "item:1002" }, { link = "item:1003" } }
    local c = Q.Rewards:CollectChoices()
    t.eq(#c, 2)
    t.eq(c[1].index, 1); t.eq(c[1].link, "item:1002"); t.eq(c[1].equipLoc, "INVTYPE_CHEST")
    t.eq(c[1].classID, 4); t.eq(c[1].subclassID, 3); t.eq(c[1].minLevel, 5); t.eq(c[1].sellPrice, 80)
    t.eq(c[1].stats[STR], 4)
    t.eq(c[2].index, 2); t.eq(c[2].classID, 7); t.eq(c[2].sellPrice, 3)
  end,

  collect_choices_survives_uncached_items = function(t)
    local Q = load()
    -- lien inconnu du cache : on garde les infos instantanées absentes, sans erreur
    Mock.questFrame.choices = { { link = "item:555" } }
    local c = Q.Rewards:CollectChoices()
    t.eq(#c, 1); t.eq(c[1].index, 1); t.eq(c[1].link, "item:555")
    t.eq(c[1].loaded, false)
    t.eq(c[1].sellPrice, 0); t.eq(c[1].stats, {})
  end,

  pick_vendor_when_nothing_usable = function(t)
    local Q = load()
    local a = item(2001, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 4, sellPrice = 120,
      stats = { [STR] = 9, [ARMOR] = 300 } })
    local b = item(2002, { equipLoc = "INVTYPE_LEGS", classID = 4, subclassID = 4, sellPrice = 300,
      stats = { [STR] = 8, [ARMOR] = 250 } })
    local choices = { choiceOf(Mock.items[2001], 1), choiceOf(Mock.items[2002], 2) }
    local index, reason, detail = Q.Rewards:Pick(choices, { classFile = "MAGE", level = 30 })
    t.eq(index, 2); t.eq(reason, "vendor"); t.eq(detail, 300)
  end,

  pick_vendor_when_no_upgrade = function(t)
    local Q = load()
    -- l'équipé vaut mieux que la récompense utilisable : on prend le plus cher à la revente
    Mock.inventory[5] = item(3000, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3,
      stats = { [STR] = 20, [ARMOR] = 100 } })
    item(3001, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3, sellPrice = 40, stats = { [STR] = 5 } })
    item(3002, { equipLoc = "INVTYPE_TRINKET", classID = 4, subclassID = 0, sellPrice = 90, stats = {} })
    local choices = { choiceOf(Mock.items[3001], 1), choiceOf(Mock.items[3002], 2) }
    local index, reason = Q.Rewards:Pick(choices, warrior(20))
    t.eq(reason, "vendor"); t.eq(index, 2, "highest vendor price")
  end,

  rings_compare_lower_slot = function(t)
    local Q = load()
    -- deux anneaux équipés : 12 et 3 points de Force ; la bague proposée en vaut 5
    Mock.inventory[11] = item(4001, { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0, stats = { [STR] = 12 } })
    Mock.inventory[12] = item(4002, { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0, stats = { [STR] = 3 } })
    item(4003, { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0, sellPrice = 10, stats = { [STR] = 5 } })
    item(4004, { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0, sellPrice = 99, stats = { [STR] = 2 } })
    t.eq(Q.Rewards:EquippedScore(11, warrior()), 12)
    t.eq(Q.Rewards:EquippedScore(12, warrior()), 3)
    local better = { choiceOf(Mock.items[4003], 1) }
    local index, reason = Q.Rewards:Pick(better, warrior())
    t.eq(index, 1); t.eq(reason, "upgrade", "5 beats the weaker ring (3)")
    local worse = { choiceOf(Mock.items[4004], 1) }
    local _, reason2 = Q.Rewards:Pick(worse, warrior())
    t.eq(reason2, "vendor", "2 does not beat 3")
    -- un anneau libre : n'importe quelle bague est une amélioration
    Mock.inventory[12] = nil
    t.eq(Q.Rewards:EquippedScore(12, warrior()), 0, "empty slot")
    local _, reason3 = Q.Rewards:Pick(worse, warrior())
    t.eq(reason3, "upgrade")
  end,

  one_hand_weapons_compare_lower_slot = function(t)
    local Q = load()
    Mock.inventory[16] = item(4101, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, stats = { [DPS] = 10 } })
    Mock.inventory[17] = item(4102, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, stats = { [DPS] = 4 } })
    item(4103, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, stats = { [DPS] = 6 } })
    local index, reason = Q.Rewards:Pick({ choiceOf(Mock.items[4103], 1) }, warrior())
    t.eq(index, 1); t.eq(reason, "upgrade", "DPS 6 beats the off-hand 4")
  end,

  slot_mapping = function(t)
    local Q = load()
    t.eq(Q.Rewards:SlotsFor("INVTYPE_HEAD"), { 1 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_CHEST"), { 5 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_ROBE"), { 5 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_CLOAK"), { 15 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_2HWEAPON"), { 16 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_WEAPONMAINHAND"), { 16 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_SHIELD"), { 17 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_HOLDABLE"), { 17 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_WEAPONOFFHAND"), { 17 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_THROWN"), { 18 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_RANGEDRIGHT"), { 18 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_FINGER"), { 11, 12 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_TRINKET"), { 13, 14 })
    t.eq(Q.Rewards:SlotsFor("INVTYPE_WEAPON"), { 16, 17 })
    t.eq(Q.Rewards:SlotsFor(""), nil)
    t.eq(Q.Rewards:SlotsFor("INVTYPE_BAG"), nil)
  end,

  plate_unusable_before_40 = function(t)
    local Q = load()
    local plate = { index = 1, equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 4, minLevel = 0, sellPrice = 1,
      stats = { [STR] = 10 } }
    t.eq(Q.Rewards:Usable(plate, { classFile = "WARRIOR", level = 39 }), false)
    t.eq(Q.Rewards:Usable(plate, { classFile = "WARRIOR", level = 40 }), true)
    t.eq(Q.Rewards:Usable(plate, { classFile = "PALADIN", level = 39 }), false)
    t.eq(Q.Rewards:Usable(plate, { classFile = "PALADIN", level = 40 }), true)
    t.eq(Q.Rewards:Usable(plate, { classFile = "ROGUE", level = 60 }), false)
    local mail = { index = 1, equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3, minLevel = 0 }
    t.eq(Q.Rewards:Usable(mail, { classFile = "HUNTER", level = 39 }), false)
    t.eq(Q.Rewards:Usable(mail, { classFile = "HUNTER", level = 40 }), true)
    t.eq(Q.Rewards:Usable(mail, { classFile = "SHAMAN", level = 39 }), false)
    t.eq(Q.Rewards:Usable(mail, { classFile = "SHAMAN", level = 40 }), true)
    t.eq(Q.Rewards:Usable(mail, { classFile = "WARRIOR", level = 1 }), true)
  end,

  usable_armor_table = function(t)
    local Q = load()
    local function armor(class, sub, level)
      return Q.Rewards:Usable({ index = 1, equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = sub, minLevel = 0 },
        { classFile = class, level = level or 20 })
    end
    t.eq(armor("PRIEST", 1), true); t.eq(armor("PRIEST", 2), false)
    t.eq(armor("MAGE", 1), true); t.eq(armor("MAGE", 2), false)
    t.eq(armor("WARLOCK", 1), true); t.eq(armor("WARLOCK", 2), false)
    t.eq(armor("ROGUE", 2), true); t.eq(armor("ROGUE", 3), false)
    t.eq(armor("DRUID", 2), true); t.eq(armor("DRUID", 3), false)
    t.eq(armor("WARRIOR", 6), true, "shield")
    t.eq(armor("ROGUE", 6), false, "no shield for a rogue")
    t.eq(armor("SHAMAN", 6), true)
    t.eq(armor("PRIEST", 0), true, "misc armor (cloak, ring, trinket, neck) is always usable")
    t.eq(armor("MAGE", 0), true)
  end,

  usable_weapon_table = function(t)
    local Q = load()
    local function weapon(class, sub)
      return Q.Rewards:Usable({ index = 1, equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = sub, minLevel = 0 },
        { classFile = class, level = 20 })
    end
    t.eq(weapon("WARRIOR", 8), true, "2H sword")
    t.eq(weapon("MAGE", 10), true, "staff"); t.eq(weapon("MAGE", 0), false, "axe")
    t.eq(weapon("MAGE", 19), true, "wand"); t.eq(weapon("PRIEST", 4), true, "mace")
    t.eq(weapon("PRIEST", 7), false, "sword")
    t.eq(weapon("ROGUE", 15), true, "dagger"); t.eq(weapon("ROGUE", 5), false, "2H mace")
    t.eq(weapon("HUNTER", 2), true, "bow"); t.eq(weapon("DRUID", 2), false)
    t.eq(weapon("SHAMAN", 5), true, "2H mace"); t.eq(weapon("PALADIN", 8), true)
    t.eq(weapon("WARLOCK", 15), true); t.eq(weapon("WARLOCK", 8), false)
  end,

  min_level_gates_usability = function(t)
    local Q = load()
    local sword = { index = 1, equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, minLevel = 12 }
    t.eq(Q.Rewards:Usable(sword, warrior(11)), false)
    t.eq(Q.Rewards:Usable(sword, warrior(12)), true)
    -- hors équipement : jamais utilisable
    t.eq(Q.Rewards:Usable({ index = 1, equipLoc = "", classID = 0, subclassID = 0, minLevel = 0 }, warrior()), false)
    t.eq(Q.Rewards:Usable({ index = 1, equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 1 }, { classFile = "DEATHKNIGHT", level = 20 }), false)
  end,

  class_weights_drive_the_score = function(t)
    local Q = load()
    -- même objet, deux classes : le mage veut l'Intelligence, le guerrier la Force
    local stats = { [INT] = 10, [STR] = 2 }
    t.near(Q.Rewards:Score(stats, "MAGE"), 10, 0.0001)
    t.near(Q.Rewards:Score(stats, "WARRIOR"), 2, 0.0001)
    t.near(Q.Rewards:Score({ [DPS] = 10 }, "WARRIOR"), 30, 0.0001)
    t.near(Q.Rewards:Score({ [ARMOR] = 100 }, "WARRIOR"), 2, 0.0001)
    t.near(Q.Rewards:Score({ [AGI] = 10, [STA] = 10, [SPI] = 10 }, "ROGUE"), 14, 0.0001)
    t.near(Q.Rewards:Score({ [SPI] = 10 }, "PRIEST"), 8, 0.0001)
    t.eq(Q.Rewards:Score({ [STR] = 10 }, "UNKNOWN"), 0)
    t.eq(Q.Rewards:Score(nil, "MAGE"), 0)
  end,

  equipped_score_uses_inventory = function(t)
    local Q = load()
    t.eq(Q.Rewards:EquippedScore(5, warrior()), 0, "empty")
    Mock.inventory[5] = item(5001, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3,
      stats = { [STR] = 6, [STA] = 4 } })
    t.near(Q.Rewards:EquippedScore(5, warrior()), 8, 0.0001)
    t.near(Q.Rewards:EquippedScore(5, { classFile = "MAGE", level = 10 }), 2, 0.0001)
  end,

  pick_handles_empty_and_single = function(t)
    local Q = load()
    t.eq(Q.Rewards:Pick({}, warrior()), nil)
    t.eq(Q.Rewards:Pick(nil, warrior()), nil)
    item(6001, { equipLoc = "", classID = 0, subclassID = 0, sellPrice = 7 })
    local index, reason = Q.Rewards:Pick({ choiceOf(Mock.items[6001], 1) }, warrior())
    t.eq(index, 1); t.eq(reason, "vendor")
  end,

  better_upgrade_wins_among_several = function(t)
    local Q = load()
    item(7001, { equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 3, stats = { [STR] = 3 } })
    item(7002, { equipLoc = "INVTYPE_LEGS", classID = 4, subclassID = 3, stats = { [STR] = 9 } })
    item(7003, { equipLoc = "INVTYPE_FEET", classID = 4, subclassID = 3, stats = { [STR] = 5 } })
    local choices = { choiceOf(Mock.items[7001], 1), choiceOf(Mock.items[7002], 2), choiceOf(Mock.items[7003], 3) }
    local index, reason = Q.Rewards:Pick(choices, warrior())
    t.eq(index, 2); t.eq(reason, "upgrade")
  end,

  weapon_empty_offhand_compares_main_hand = function(t)
    local Q = load()
    Mock.inventory[16] = item(8001, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, stats = { [DPS] = 20 } })
    item(8002, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, sellPrice = 5, stats = { [DPS] = 3 } })
    item(8003, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, sellPrice = 5, stats = { [DPS] = 25 } })
    local rogue = { classFile = "ROGUE", level = 20 }
    t.eq(Q.Rewards:ComparisonSlots("INVTYPE_WEAPON", rogue), { 16 }, "empty off-hand is not a slot to beat")
    local _, worse = Q.Rewards:Pick({ choiceOf(Mock.items[8002], 1) }, rogue)
    t.eq(worse, "vendor", "3 DPS does not beat the equipped 20 DPS dagger")
    local _, better = Q.Rewards:Pick({ choiceOf(Mock.items[8003], 1) }, rogue)
    t.eq(better, "upgrade")
  end,

  weapon_shield_offhand_compares_main_hand = function(t)
    local Q = load()
    Mock.inventory[16] = item(8101, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, stats = { [DPS] = 20 } })
    Mock.inventory[17] = item(8102, { equipLoc = "INVTYPE_SHIELD", classID = 4, subclassID = 6, stats = { [ARMOR] = 100 } })
    item(8103, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, sellPrice = 5, stats = { [DPS] = 3 } })
    item(8104, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, sellPrice = 5, stats = { [DPS] = 25 } })
    t.eq(Q.Rewards:ComparisonSlots("INVTYPE_WEAPON", warrior(20)), { 16 }, "a shield is not a weapon")
    local _, worse = Q.Rewards:Pick({ choiceOf(Mock.items[8103], 1) }, warrior(20))
    t.eq(worse, "vendor")
    local _, better = Q.Rewards:Pick({ choiceOf(Mock.items[8104], 1) }, warrior(20))
    t.eq(better, "upgrade")
  end,

  dual_wield_compares_the_weaker_hand = function(t)
    local Q = load()
    Mock.inventory[16] = item(8201, { equipLoc = "INVTYPE_WEAPONMAINHAND", classID = 2, subclassID = 15,
      stats = { [DPS] = 20 } })
    Mock.inventory[17] = item(8202, { equipLoc = "INVTYPE_WEAPONOFFHAND", classID = 2, subclassID = 15,
      stats = { [DPS] = 10 } })
    item(8203, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, sellPrice = 5, stats = { [DPS] = 15 } })
    item(8204, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 15, sellPrice = 5, stats = { [DPS] = 8 } })
    local rogue = { classFile = "ROGUE", level = 20 }
    t.eq(Q.Rewards:ComparisonSlots("INVTYPE_WEAPON", rogue), { 16, 17 })
    t.eq(Q.Rewards:ComparisonSlots("INVTYPE_WEAPON", { classFile = "HUNTER", level = 20 }), { 16, 17 })
    local _, better = Q.Rewards:Pick({ choiceOf(Mock.items[8203], 1) }, rogue)
    t.eq(better, "upgrade", "15 beats the off-hand 10")
    local _, worse = Q.Rewards:Pick({ choiceOf(Mock.items[8204], 1) }, rogue)
    t.eq(worse, "vendor", "8 does not beat the off-hand 10")
  end,

  classes_that_cannot_dual_wield_use_the_main_hand = function(t)
    local Q = load()
    Mock.inventory[16] = item(8301, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 4, stats = { [DPS] = 20 } })
    Mock.inventory[17] = item(8302, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 4, stats = { [DPS] = 1 } })
    item(8303, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 4, sellPrice = 5, stats = { [DPS] = 5 } })
    for _, class in ipairs({ "SHAMAN", "PALADIN", "PRIEST", "DRUID", "MAGE", "WARLOCK" }) do
      t.eq(Q.Rewards:ComparisonSlots("INVTYPE_WEAPON", { classFile = class, level = 20 }), { 16 }, class)
    end
    local _, reason = Q.Rewards:Pick({ choiceOf(Mock.items[8303], 1) }, { classFile = "SHAMAN", level = 20 })
    t.eq(reason, "vendor", "5 DPS does not beat the main hand")
    -- les autres emplacements doubles gardent la règle du moins bon des deux
    t.eq(Q.Rewards:ComparisonSlots("INVTYPE_FINGER", { classFile = "SHAMAN", level = 20 }), { 11, 12 })
    t.eq(Q.Rewards:ComparisonSlots("INVTYPE_TRINKET", { classFile = "MAGE", level = 20 }), { 13, 14 })
    t.eq(Q.Rewards:ComparisonSlots("INVTYPE_HEAD", warrior()), { 1 })
    t.eq(Q.Rewards:ComparisonSlots("", warrior()), nil)
  end,

  missing_item_stats_api_is_survived = function(t)
    local Q = load()
    item(8401, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3, stats = { [STR] = 5 } })
    Mock.questFrame.choices = { { link = "item:8401" } }
    Mock.inventory[5] = "item:8401"
    C_Item.GetItemStats = nil
    local choices = Q.Rewards:CollectChoices()
    t.eq(#choices, 1); t.eq(choices[1].stats, {})
    t.eq(choices[1].loaded, false, "cannot be evaluated without stats")
    t.eq(Q.Rewards:AllLoaded(choices), false)
    t.eq(Q.Rewards:EquippedScore(5, warrior()), 0)
    for _, e in ipairs(Mock.errors) do t.ok(not tostring(e):find("Rewards.lua", 1, true), tostring(e)) end
  end,

  -- Profils de rôle ------------------------------------------------------

  caster_shaman_prefers_int_over_str_and_dps = function(t)
    local Q = load()
    Q.Profiles:SetRewardRole("SHAMAN", "caster")   -- profil de butin du chaman (profil d'options actif)
    local int = item(9001, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 2,
      stats = { [INT] = 8, [STA] = 4, [ARMOR] = 60 } })
    local str = item(9002, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 3,
      stats = { [STR] = 9, [STA] = 4, [ARMOR] = 120 } })
    local mace = item(9003, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 4, stats = { [DPS] = 12 } })
    local shaman = { classFile = "SHAMAN", level = 20 }
    local i1 = Q.Rewards:Pick({ choiceOf(Mock.items[9001], 1), choiceOf(Mock.items[9002], 2) }, shaman)
    t.eq(i1, 1, "INT chest over STR chest")
    local i2 = Q.Rewards:Pick({ choiceOf(Mock.items[9001], 1), choiceOf(Mock.items[9003], 2) }, shaman)
    t.eq(i2, 1, "INT chest over a higher-DPS mace")
    -- puissance des sorts
    item(9004, { equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 2, stats = { ITEM_MOD_SPELL_POWER_SHORT = 10 } })
    item(9005, { equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 2, stats = { [STA] = 10 } })
    local i3 = Q.Rewards:Pick({ choiceOf(Mock.items[9005], 1), choiceOf(Mock.items[9004], 2) }, shaman)
    t.eq(i3, 2, "spell power beats stamina")
  end,

  melee_shaman_keeps_current_behaviour = function(t)
    local Q = load()
    local shaman = { classFile = "SHAMAN", level = 20 }
    item(9101, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 2, stats = { [INT] = 8, [STA] = 4, [ARMOR] = 60 } })
    item(9102, { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 2, stats = { [STR] = 9, [STA] = 4, [ARMOR] = 120 } })
    local choices = { choiceOf(Mock.items[9101], 1), choiceOf(Mock.items[9102], 2) }
    local auto = Q.Rewards:Pick(choices, shaman)
    Q.Profiles:SetRewardRole("SHAMAN", "melee")
    t.eq(Q.Rewards:Pick(choices, shaman), auto, "melee = auto for a shaman")
    t.eq(auto, 2, "STR mail still wins")
    t.eq(Q.Rewards:Weights("SHAMAN", "melee"), Q.Rewards:Weights("SHAMAN", "auto"))
  end,

  hunter_ranged_prefers_bow_upgrade = function(t)
    local Q = load()
    Q.Profiles:SetRewardRole("HUNTER", "ranged")
    Mock.inventory[18] = item(9201, { equipLoc = "INVTYPE_RANGED", classID = 2, subclassID = 2, stats = { [DPS] = 5 } })
    Mock.inventory[16] = item(9202, { equipLoc = "INVTYPE_WEAPON", classID = 2, subclassID = 7, stats = { [DPS] = 5 } })
    item(9203, { equipLoc = "INVTYPE_RANGED", classID = 2, subclassID = 2, stats = { [DPS] = 8 } })
    item(9204, { equipLoc = "INVTYPE_2HWEAPON", classID = 2, subclassID = 8, stats = { [DPS] = 12 } })
    local hunter = { classFile = "HUNTER", level = 20 }
    local idx, reason = Q.Rewards:Pick({ choiceOf(Mock.items[9204], 1), choiceOf(Mock.items[9203], 2) }, hunter)
    t.eq(idx, 2); t.eq(reason, "upgrade")
    t.eq(Q.Rewards:Score({ [DPS] = 10 }, "HUNTER", true), 30)
    t.eq(Q.Rewards:Score({ [DPS] = 10 }, "HUNTER", false), 5)
  end,

  role_persists_and_auto_equals_old_tables = function(t)
    local Q = load()
    Q.Player.classFile = "SHAMAN"
    t.eq(Q.Rewards:Role(), "auto", "default")
    t.ok(Q.Rewards:SetRole("caster"))
    t.eq(Q.Profiles:RewardRole("SHAMAN"), "caster", "saved for the class in the active profile")
    t.eq(Q.Rewards:Role(), "caster")
    t.ok(not Q.Rewards:SetRole("tank"), "tank is not a shaman profile")
    t.eq(Q.Rewards:Role(), "caster")
    local Q2 = Mock.reload()
    Q2.Player.classFile = "SHAMAN"
    t.eq(Q2.Rewards:Role(), "caster", "kept after /reload")
    Q = Q2
    t.ok(Q.Rewards:SetRole("auto"))
    local stats = { [STR] = 4, [INT] = 3, [STA] = 2, [AGI] = 1, [SPI] = 5, [ARMOR] = 100, [DPS] = 7 }
    -- ancienne table du chaman : STR .8 INT .8 STA .5 AGI .4 SPI .3 ARMOR .015 DPS 2.5
    local old = 4 * 0.8 + 3 * 0.8 + 2 * 0.5 + 1 * 0.4 + 5 * 0.3 + 100 * 0.015 + 7 * 2.5
    t.near(Q.Rewards:Score(stats, "SHAMAN"), old, 1e-9)
    -- un profil enregistré qui ne convient pas à la classe retombe sur auto
    Q.Profiles:SetRewardRole("SHAMAN", "tank")
    Q.Profiles:SetRewardRole("WARRIOR", "tank")
    t.eq(Q.Rewards:Role("SHAMAN"), "auto")
    t.eq(Q.Rewards:Role("WARRIOR"), "tank")
  end,

  class_role_lists = function(t)
    local Q = load()
    t.eq(Q.Rewards:Roles("SHAMAN"), { "auto", "caster", "melee", "healer" })
    t.eq(Q.Rewards:Roles("HUNTER"), { "auto", "ranged", "melee" })
    t.eq(Q.Rewards:Roles("MAGE"), { "auto", "caster" })
    t.ok(not Q.Rewards:HasChoice("MAGE") and Q.Rewards:HasChoice("PRIEST"))
    t.eq(Q.L.REWARD_SPEC_SHAMAN_CASTER ~= nil, true)
  end,

  options_selector_shows_only_class_profiles = function(t)
    local Q = load()
    local O = Q.UI.Options
    Q.Player.classFile = "SHAMAN"
    O:Open("loot")
    local w = O:Widget("rewardRole")
    t.ok(w and w:IsShown(), "selector shown for a shaman")
    local values = {}
    for i, r in ipairs(w.radios) do if r:IsShown() then values[i] = r.value end end
    t.eq(values, { "auto", "caster", "melee", "healer" }, "only the shaman profiles")
    t.eq(w.radios[2].label:GetText(), Q.L.REWARD_SPEC_SHAMAN_CASTER)
    t.ok(w.radios[1]:GetChecked(), "auto checked")
    Mock.click(w.radios[4], "LeftButton")
    t.eq(Q.Rewards:Role(), "healer")
    t.ok(w.radios[4]:GetChecked() and not w.radios[1]:GetChecked())
    Q.Player.classFile = "ROGUE"
    O:Render()
    t.ok(not w:IsShown(), "no selector for a single-profile class")
    t.ok(O:Widget("lootSingle"):IsShown(), "explanation instead")
  end,

  wizard_selector_shows_only_class_profiles_and_saves = function(t)
    local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")
    local WExt = dofile(Mock.root .. "/tests/mock_ext_wizard.lua")
    Ext.install(); WExt.install()
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
    local W = Q.UI.Wizard
    Q.Player.classFile = "SHAMAN"
    W:Show(4)
    local b = W.rewardRoleButton
    t.ok(b:IsShown())
    Mock.click(b, "LeftButton")
    t.eq(W.choice.rewardRole, "caster")
    t.eq(Q.char.wizardDraft.rewardRole, "caster", "kept in the draft")
    t.eq(Q.Rewards:Role(), "auto", "not applied before Finish")
    W:Finish()
    t.eq(Q.Rewards:Role(), "caster")
    Q.Player.classFile = "MAGE"
    W:Show(4)
    t.ok(not W.rewardRoleButton:IsShown(), "hidden for a single-profile class")
  end,
}
