-- Tests du rappel sacs pleins et réparation (Q.Supplies, Engine/Supplies.lua).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_comfort.lua")

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- far = true : l'étape courante mène loin de la ville (goto à l'autre bout de Dun Morogh).
local function load(far)
  Ext.install()
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  if far ~= false then Q.Progress:InsertSteps("test", { { "goto", 1426, 90, 10 } }) end
  return Q
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

local function fullBags() Mock.comfort.freeSlots = { [0] = 1, [1] = 1, [2] = 0, [3] = 0, [4] = 0 } end

local function enterTown()
  Mock.comfort.resting = true
  Mock.fire("PLAYER_UPDATE_RESTING")
  Mock.advance(2)
end

return {
  full_bags_in_town_before_leaving = function(t)
    local Q = load()
    fullBags()
    enterTown()
    local expected = string.format(Q.L.COMFORT_BAGS_FULL, 2)
    t.eq(lines(Q), { expected })
    t.eq(warnTexts(Q), { expected })
    t.eq(Mock.countPrinted(string.format(Q.L.COMFORT_BAGS_CHAT, 2)), 1)
    -- sacs vidés : la ligne disparaît
    Mock.comfort.freeSlots[0] = 12
    Mock.fire("BAG_UPDATE_DELAYED")
    Mock.advance(2)
    t.eq(lines(Q), {})
    t.eq(warnTexts(Q), {})
    t.eq(#Mock.errors, 0)
  end,

  low_durability_reminds_to_repair = function(t)
    local Q = load()
    Mock.comfort.durability = { [5] = { 90, 100 }, [16] = { 15, 100 } }
    enterTown()
    t.eq(lines(Q), { string.format(Q.L.COMFORT_REPAIR, 15) })
    t.eq(Mock.countPrinted(string.format(Q.L.COMFORT_REPAIR_CHAT, 15)), 1)
  end,

  quiver_slots_do_not_count = function(t)
    local Q = load()
    fullBags()
    Mock.comfort.freeSlots[4] = 16
    Mock.comfort.bagFamily[4] = 1
    t.eq(Q.Supplies:FreeSlots(), 2)
  end,

  at_most_once_per_ten_minutes = function(t)
    local Q = load()
    fullBags()
    local msg = string.format(Q.L.COMFORT_BAGS_CHAT, 2)
    enterTown()
    t.eq(Mock.countPrinted(msg), 1)
    Mock.advance(130)                       -- la ligne s'efface au bout de 2 minutes
    t.eq(lines(Q), {})
    Mock.fire("PLAYER_UPDATE_RESTING")
    Mock.advance(2)
    t.eq(Mock.countPrinted(msg), 1, "no second reminder within 10 minutes")
    t.eq(lines(Q), {})
    Mock.advance(600)
    Mock.fire("PLAYER_UPDATE_RESTING")
    Mock.advance(2)
    t.eq(Mock.countPrinted(msg), 2)
  end,

  after_leaving_a_merchant = function(t)
    local Q = load()
    fullBags()
    Mock.fire("MERCHANT_SHOW")
    Mock.advance(2)
    t.eq(lines(Q), {}, "not while the merchant is open")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(2)
    t.eq(lines(Q), { string.format(Q.L.COMFORT_BAGS_FULL, 2) })
  end,

  merchant_long_ago_and_outside_town = function(t)
    local Q = load()
    Mock.fire("MERCHANT_SHOW")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(200)
    fullBags()
    Mock.fire("BAG_UPDATE_DELAYED")
    Mock.advance(2)
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
  end,

  next_steps_in_town_no_reminder = function(t)
    local Q = load(false)   -- étapes suivantes à côté du joueur
    fullBags()
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
  end,

  option_off = function(t)
    local Q = load()
    Q.Settings:Set("supplyReminders", false)
    fullBags()
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
    Q.Settings:Set("supplyReminders", true)
    Mock.advance(2)
    t.eq(lines(Q), { string.format(Q.L.COMFORT_BAGS_FULL, 2) })
  end,

  combat_waits_until_it_ends = function(t)
    local Q = load()
    fullBags()
    Mock.player.combat = true
    enterTown()
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, 0)
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    Mock.advance(2)
    t.eq(lines(Q), { string.format(Q.L.COMFORT_BAGS_FULL, 2) })
  end,

  missing_api_is_silent = function(t)
    local Q = load()
    C_Container.GetContainerNumFreeSlots = nil
    GetInventoryItemDurability = nil
    IsResting = nil
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

  without_questiedb_does_nothing = function(t)
    Mock.addons.QuestieDB = false
    Ext.install()
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
    local before = #Mock.prints
    fullBags()
    Mock.comfort.durability = { [5] = { 1, 100 } }
    enterTown()
    Mock.fire("MERCHANT_SHOW")
    Mock.fire("MERCHANT_CLOSED")
    Mock.advance(2)
    t.eq(lines(Q), {})
    t.eq(#Mock.prints, before)
    t.eq(#Mock.errors, 0)
  end,
}
