-- Tests de l'alerte d'avant-poste (Q.Supplies, Engine/Supplies.lua) : sacs presque pleins,
-- réparation, nourriture et boisson, en zone de repos ou juste après un marchand.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_comfort.lua")

-- Objets de test
local JERKY = 117      -- nourriture, niveau 1
local WATER = 159      -- boisson, niveau 1
local MELON = 1205     -- boisson, niveau 15
local BREAD = 4540     -- nourriture rangée en consommable générique (sous-classe 0)
local BISCUIT = 13724  -- nourriture et boisson à la fois
local POTION = 118     -- potion de soins : consommable, mais pas de la nourriture
local FOOD, DRINK = 433, 430

local S   -- état des bouchons locaux

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- Bouchons locaux (Mock.reset les retire avant chaque test) : capacité et contenu des sacs, objets,
-- sort d'utilisation des objets, noms des sorts Nourriture et Boisson, réserve de mana, message au
-- milieu de l'écran.
local function stubs()
  S = {
    numSlots = { [0] = 16, [1] = 0, [2] = 0, [3] = 0, [4] = 0 },
    contents = { [0] = { [1] = JERKY, [2] = WATER } },
    spells = {
      [JERKY] = { "Food", 433 }, [WATER] = { "Drink", 430 }, [MELON] = { "Drink", 431 },
      [BREAD] = { "Food", 434 }, [BISCUIT] = { "Food & Drink", 18234 }, [POTION] = { "Healing Potion", 439 },
    },
    uncached = {},
    mana = 0,
  }
  local function def(id, name, sub, minLevel)
    Mock.items[id] = { id = id, name = name, link = "item:" .. id, classID = 0, subclassID = sub, minLevel = minLevel,
      itemType = "Consumable" }
  end
  def(JERKY, "Tough Jerky", 5, 1)
  def(WATER, "Refreshing Spring Water", 5, 1)
  def(MELON, "Melon Juice", 5, 15)
  def(BREAD, "Tough Hunk of Bread", 0, 1)
  def(BISCUIT, "Enriched Manna Biscuit", 5, 1)
  def(POTION, "Minor Healing Potion", 1, 1)

  C_Container.GetContainerNumSlots = function(bag) return S.numSlots[bag] or 0 end
  C_Container.GetContainerItemID = function(bag, slot)
    local b = S.contents[bag]
    return b and b[slot]
  end
  local getInfo = C_Item.GetItemInfo
  C_Item.GetItemInfo = function(item)
    if S.uncached[item] then return nil end
    return getInfo(item)
  end
  C_Item.GetItemSpell = function(item)
    if S.uncached[item] then return nil end
    local s = S.spells[item]
    if s then return s[1], s[2] end
    return nil
  end
  C_Item.RequestLoadItemDataByID = function(id) Mock.record("C_Item.RequestLoadItemDataByID", id) end
  C_Spell = { GetSpellName = function(id) return ({ [FOOD] = "Food", [DRINK] = "Drink" })[id] end }
  UnitPowerMax = function(unit, power)
    if unit == "player" and power == 0 then return S.mana end
    return 0
  end
  RaidWarningFrame = Mock.newObject("Frame", "RaidWarningFrame")
  RaidWarningUtil = {
    AddMessage = function(text, color) Mock.record("RaidWarningUtil.AddMessage", text, color) end,
  }
end

local function load()
  Ext.install()
  stubs()
  return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
end

local function lines(Q)
  local out = {}
  for _, l in ipairs(Q.Supplies:Lines()) do out[#out + 1] = plain(l) end
  return out
end

local function warnTexts(Q)
  local out = {}
  for _, line in ipairs(Q.UI.Tracker.warnLines) do
    if line:IsShown() then out[#out + 1] = plain(line:GetText()) end
  end
  return out
end

local function centerTexts()
  local out = {}
  for _, c in ipairs(Mock.callsTo("RaidWarningUtil.AddMessage")) do out[#out + 1] = c.args[1] end
  return out
end

-- Textes attendus
local function slots(Q, free, total)
  return string.format(free <= 1 and Q.L.COMFORT_SLOTS_FREE_ONE or Q.L.COMFORT_SLOTS_FREE, free, total)
end
local function bagsLine(Q, free, total) return string.format(Q.L.COMFORT_BAGS_FULL, slots(Q, free, total)) end
local function alert(Q, ...)
  return string.format(Q.L.COMFORT_SUPPLY_ALERT, table.concat({ ... }, Q.L.COMFORT_LIST_SEP))
end

-- Sacs de 64 places (sac à dos de 16 et quatre sacs de 12), dont `free` libres.
local function bags64(free)
  S.numSlots = { [0] = 16, [1] = 12, [2] = 12, [3] = 12, [4] = 12 }
  local left = free
  for bag = 0, 4 do
    local n = math.min(left, S.numSlots[bag])
    Mock.comfort.freeSlots[bag] = n
    left = left - n
  end
end

local function mage()
  Mock.player.classFile = "MAGE"
  S.mana = 120
end

local function enterTown()
  Mock.comfort.resting = true
  Mock.fire("PLAYER_UPDATE_RESTING")
  Mock.advance(2)
end

local function leaveTown()
  Mock.comfort.resting = false
  Mock.fire("PLAYER_UPDATE_RESTING")
  Mock.advance(2)
end

local function bagsChanged()
  Mock.fire("BAG_UPDATE_DELAYED")
  Mock.advance(2)
end

return {
  ---------------------------------------------------------------------------
  -- Sacs
  ---------------------------------------------------------------------------
  five_free_of_64_alerts = function(t)
    local Q = load()
    bags64(5)
    enterTown()
    local expected = bagsLine(Q, 5, 64)
    t.eq(lines(Q), { expected })
    t.eq(warnTexts(Q), { expected })
    local msg = alert(Q, slots(Q, 5, 64))
    t.eq(Mock.countPrinted(msg), 1)
    t.eq(centerTexts(), { msg })
    -- sacs vidés : la ligne disparaît
    bags64(30)
    bagsChanged()
    t.eq(lines(Q), {})
    t.eq(warnTexts(Q), {})
    t.eq(#Mock.errors, 0)
  end,

  twelve_free_of_64_is_under_20_percent = function(t)
    local Q = load()
    bags64(12)
    enterTown()
    t.eq(lines(Q), { bagsLine(Q, 12, 64) })
    t.eq(Mock.countPrinted(alert(Q, slots(Q, 12, 64))), 1)
  end,

  twenty_free_of_64_is_enough = function(t)
    local Q = load()
    bags64(20)
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
    t.eq(centerTexts(), {})
  end,

  -- Connexion dans une auberge : les sacs ne sont pas encore lus pendant quelques secondes. Le
  -- premier relevé attend (sinon le sac à dos seul passerait pour plein), puis tout est lu.
  login_grace_waits_for_bags = function(t)
    local Q = load()
    Mock.comfort.resting = true
    Mock.comfort.freeSlots = { [0] = 2 }   -- seul le sac à dos est lu : 2 libres sur 16
    Mock.fire("PLAYER_ENTERING_WORLD")
    Mock.advance(2)
    t.eq(lines(Q), {}, "nothing during the login grace")
    bags64(40)                             -- les autres sacs arrivent
    Mock.fire("BAG_UPDATE_DELAYED")
    Mock.advance(5)
    t.eq(lines(Q), {}, "40 free of 64: no alert")
    t.eq(#Mock.prints, 0)
  end,

  small_backpack_under_six_free = function(t)
    local Q = load()
    Mock.comfort.freeSlots = { [0] = 5 }   -- sac à dos seul, 16 places : 31 %, mais moins de 6
    enterTown()
    t.eq(lines(Q), { bagsLine(Q, 5, 16) })
    Mock.comfort.freeSlots = { [0] = 6 }
    bagsChanged()
    t.eq(lines(Q), {})
  end,

  one_free_slot_singular = function(t)
    local Q = load()
    Mock.comfort.freeSlots = { [0] = 1 }
    enterTown()
    t.eq(lines(Q), { bagsLine(Q, 1, 16) })
    t.eq(Mock.countPrinted(alert(Q, string.format(Q.L.COMFORT_SLOTS_FREE_ONE, 1, 16))), 1)
  end,

  quiver_slots_do_not_count = function(t)
    local Q = load()
    bags64(2)
    Mock.comfort.freeSlots[4] = 12
    Mock.comfort.bagFamily[4] = 1
    t.eq({ Q.Supplies:FreeSlots() }, { 2, 52 })
  end,

  unknown_bag_size_is_silent = function(t)
    local Q = load()
    bags64(2)
    C_Container.GetContainerNumSlots = nil
    C_Container.GetContainerItemID = nil
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
    t.eq(#Mock.errors, 0)
  end,

  ---------------------------------------------------------------------------
  -- Réparation
  ---------------------------------------------------------------------------
  low_durability_reminds_to_repair = function(t)
    local Q = load()
    Mock.comfort.durability = { [5] = { 90, 100 }, [16] = { 15, 100 } }
    enterTown()
    t.eq(lines(Q), { string.format(Q.L.COMFORT_REPAIR, 15) })
    t.eq(Mock.countPrinted(alert(Q, string.format(Q.L.COMFORT_PART_REPAIR, 15))), 1)
  end,

  ---------------------------------------------------------------------------
  -- Nourriture et boisson
  ---------------------------------------------------------------------------
  no_food_alerts = function(t)
    local Q = load()
    S.contents[0][1] = nil
    enterTown()
    t.eq(lines(Q), { Q.L.COMFORT_NO_FOOD })
    t.eq(Mock.countPrinted(alert(Q, Q.L.COMFORT_PART_FOOD)), 1)
    -- de la nourriture achetée : la ligne disparaît
    S.contents[1] = { [3] = JERKY }
    S.numSlots[1] = 6
    bagsChanged()
    t.eq(lines(Q), {})
  end,

  potion_is_not_food = function(t)
    local Q = load()
    S.contents[0][1] = POTION
    enterTown()
    t.eq(lines(Q), { Q.L.COMFORT_NO_FOOD })
  end,

  warrior_without_drink_is_fine = function(t)
    local Q = load()
    S.contents[0][2] = nil
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
  end,

  mage_without_drink_alerts = function(t)
    local Q = load()
    mage()
    enterTown()
    t.eq(lines(Q), {}, "water in the bags")
    -- la dernière bouteille bue en ville : l'alerte vient pendant le passage
    S.contents[0][2] = nil
    bagsChanged()
    t.eq(lines(Q), { Q.L.COMFORT_NO_DRINK })
    t.eq(Mock.countPrinted(alert(Q, Q.L.COMFORT_PART_DRINK)), 1)
    t.eq(centerTexts(), { alert(Q, Q.L.COMFORT_PART_DRINK) })
  end,

  drink_above_level_counts_as_missing = function(t)
    local Q = load()
    mage()
    S.contents[0][2] = MELON
    enterTown()
    t.eq(lines(Q), { Q.L.COMFORT_NO_DRINK })
  end,

  drink_at_level_is_usable = function(t)
    local Q = load()
    mage()
    Mock.player.level = 15
    S.contents[0][2] = MELON
    enterTown()
    t.eq(lines(Q), {})
  end,

  generic_consumable_with_food_spell_counts = function(t)
    local Q = load()
    S.contents[0][1] = BREAD
    enterTown()
    t.eq(lines(Q), {})
  end,

  item_giving_both_counts_for_both = function(t)
    local Q = load()
    mage()
    S.contents[0] = { [4] = BISCUIT }
    enterTown()
    t.eq(lines(Q), {})
  end,

  uncached_item_gives_no_alert = function(t)
    local Q = load()
    mage()
    S.contents[0][2] = BISCUIT
    S.spells[BISCUIT] = { "Food", 434 }   -- se révélera être de la nourriture seulement
    S.uncached[BISCUIT] = true
    enterTown()
    t.eq(lines(Q), {}, "not concluded while an item is loading")
    t.eq(#Mock.prints, 0)
    t.ok(Mock.countCalls("C_Item.RequestLoadItemDataByID") >= 1, "item data requested")
    t.eq(Mock.lastCall("C_Item.RequestLoadItemDataByID").args[1], BISCUIT)
    Mock.advance(30)                        -- les nouveaux essais s'arrêtent
    local requests = Mock.countCalls("C_Item.RequestLoadItemDataByID")
    Mock.advance(30)
    t.eq(Mock.countCalls("C_Item.RequestLoadItemDataByID"), requests, "retries are bounded")
    t.eq(lines(Q), {})
    -- l'objet arrive : ce n'est pas une boisson
    S.uncached[BISCUIT] = nil
    Mock.fire("GET_ITEM_INFO_RECEIVED", BISCUIT, true)
    Mock.advance(2)
    t.eq(lines(Q), { Q.L.COMFORT_NO_DRINK })
  end,

  uncached_item_is_checked_again_without_event = function(t)
    local Q = load()
    mage()
    S.contents[0][2] = BISCUIT
    S.spells[BISCUIT] = { "Food", 434 }
    S.uncached[BISCUIT] = true
    enterTown()
    t.eq(lines(Q), {})
    S.uncached[BISCUIT] = nil
    Mock.advance(10)
    t.eq(lines(Q), { Q.L.COMFORT_NO_DRINK })
  end,

  ---------------------------------------------------------------------------
  -- Moment et regroupement
  ---------------------------------------------------------------------------
  several_problems_one_alert = function(t)
    local Q = load()
    mage()
    bags64(5)
    Mock.comfort.durability = { [16] = { 15, 100 } }
    S.contents[0][2] = nil
    enterTown()
    t.eq(lines(Q), { bagsLine(Q, 5, 64), string.format(Q.L.COMFORT_REPAIR, 15), Q.L.COMFORT_NO_DRINK })
    local msg = alert(Q, slots(Q, 5, 64), string.format(Q.L.COMFORT_PART_REPAIR, 15), Q.L.COMFORT_PART_DRINK)
    t.eq(Mock.countPrinted(msg), 1)
    t.eq(#Mock.prints, 1, "one chat line")
    t.eq(centerTexts(), { msg })
  end,

  one_alert_per_outpost_visit = function(t)
    local Q = load()
    bags64(5)
    local msg = alert(Q, slots(Q, 5, 64))
    enterTown()
    t.eq(Mock.countPrinted(msg), 1)
    Mock.advance(130)                       -- la ligne s'efface au bout de 2 minutes
    t.eq(lines(Q), {})
    Mock.advance(600)                       -- plus de 10 minutes, toujours en ville
    Mock.fire("PLAYER_UPDATE_RESTING")
    Mock.fire("MERCHANT_SHOW")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(2)
    t.eq(Mock.countPrinted(msg), 1, "same visit: no second alert")
    t.eq(lines(Q), {})
    t.eq(#centerTexts(), 1)
    leaveTown()
    Mock.advance(130)                       -- le marchand quitté compte encore 2 minutes
    enterTown()
    t.eq(Mock.countPrinted(msg), 2, "new visit")
    t.eq(#centerTexts(), 2)
  end,

  ten_minutes_between_alerts = function(t)
    local Q = load()
    bags64(5)
    local msg = alert(Q, slots(Q, 5, 64))
    enterTown()
    leaveTown()
    Mock.advance(60)
    enterTown()
    t.eq(Mock.countPrinted(msg), 1, "back within 10 minutes")
    leaveTown()
    Mock.advance(600)
    enterTown()
    t.eq(Mock.countPrinted(msg), 2)
  end,

  alerts_even_when_next_steps_are_near = function(t)
    local Q = load()
    Q.Progress:InsertSteps("test", { { "goto", 1426, 30, 71 } })
    bags64(5)
    enterTown()
    t.eq(lines(Q), { bagsLine(Q, 5, 64) })
  end,

  after_leaving_a_merchant = function(t)
    local Q = load()
    bags64(2)
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(2)
    t.eq(lines(Q), {}, "not while the merchant is open")
    t.eq(#Mock.prints, 0)
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(2)
    t.eq(lines(Q), { bagsLine(Q, 2, 64) })
    t.eq(#centerTexts(), 1)
  end,

  outside_town_without_merchant_nothing = function(t)
    local Q = load()
    mage()
    bags64(2)
    S.contents[0] = {}
    Mock.comfort.durability = { [16] = { 5, 100 } }
    bagsChanged()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
    t.eq(centerTexts(), {})
  end,

  merchant_long_ago_and_outside_town = function(t)
    local Q = load()
    Mock.fire("MERCHANT_SHOW")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(200)
    bags64(2)
    bagsChanged()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
  end,

  combat_gives_nothing_until_it_ends = function(t)
    local Q = load()
    bags64(2)
    S.contents[0][1] = nil
    Mock.player.combat = true
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
    t.eq(centerTexts(), {})
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    Mock.advance(2)
    t.eq(lines(Q), { bagsLine(Q, 2, 64), Q.L.COMFORT_NO_FOOD })
  end,

  option_off = function(t)
    local Q = load()
    Q.Settings:Set("supplyReminders", false)
    bags64(2)
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
    Q.Settings:Set("supplyReminders", true)
    Mock.advance(2)
    t.eq(lines(Q), { bagsLine(Q, 2, 64) })
  end,

  ---------------------------------------------------------------------------
  -- API absentes ou secrètes
  ---------------------------------------------------------------------------
  center_message_falls_back_to_errors_frame = function(t)
    local Q = load()
    bags64(5)
    RaidWarningFrame, RaidWarningUtil = nil, nil
    UIErrorsFrame = { AddMessage = function(_, text) Mock.record("UIErrorsFrame:AddMessage", text) end }
    enterTown()
    local msg = alert(Q, slots(Q, 5, 64))
    t.eq(Mock.countPrinted(msg), 1)
    t.eq(Mock.lastCall("UIErrorsFrame:AddMessage").args[1], msg)
  end,

  missing_api_is_silent = function(t)
    local Q = load()
    mage()
    S.contents[0] = {}
    C_Container.GetContainerNumFreeSlots = nil
    GetInventoryItemDurability = nil
    IsResting = nil
    C_Spell = nil
    C_Item.GetItemSpell = nil
    RaidWarningFrame, RaidWarningUtil = nil, nil
    Mock.fire("PLAYER_UPDATE_RESTING")
    Mock.fire("MERCHANT_SHOW")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(2)
    t.eq(lines(Q), {})
    t.eq(#Mock.errors, 0)
    t.eq(#Mock.prints, 0)
  end,

  secret_values_are_ignored = function(t)
    local Q = load()
    mage()
    Mock.comfort.freeSlots = { [0] = Mock.strictSecret(0) }
    Mock.comfort.durability = { [5] = { Mock.strictSecret(1), 100 } }
    IsResting = function() return Mock.strictSecret(true) end
    Mock.fire("PLAYER_UPDATE_RESTING")
    Mock.fire("MERCHANT_SHOW")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(2)
    t.eq(lines(Q), {})
    t.eq(#Mock.errors, 0)
  end,

  secret_bag_contents_and_mana_are_ignored = function(t)
    local Q = load()
    mage()
    C_Container.GetContainerItemID = function() return Mock.strictSecret(JERKY) end
    UnitPowerMax = function() return Mock.strictSecret(120) end
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
    t.eq(#Mock.errors, 0)
  end,

  without_questiedb_does_nothing = function(t)
    Mock.addons.QuestieDB = false
    Ext.install()
    stubs()
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
    local before = #Mock.prints
    bags64(2)
    Mock.comfort.durability = { [5] = { 1, 100 } }
    S.contents[0] = {}
    enterTown()
    Mock.fire("MERCHANT_SHOW")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(2)
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, before)
    t.eq(#Mock.errors, 0)
  end,
}
