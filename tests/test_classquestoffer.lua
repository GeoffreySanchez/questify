-- Tests de l'offre de quête de classe (Q.ClassQuestOffer) : étape « classquest » proposée près du donneur.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

-- Trois donneurs dans la vallée (même position, les tests déplacent le joueur), un à Elwynn (loin).
local NPCS = {
  [90300] = { name = "Test Warlock Trainer", minLevel = 10, maxLevel = 10, spawns = { [1] = { { 30.5, 71.0 } } },
    zoneID = 1, friendlyToFaction = "A" },
  [90301] = { name = "Second Giver", minLevel = 10, maxLevel = 10, spawns = { [1] = { { 30.5, 71.0 } } },
    zoneID = 1, friendlyToFaction = "A" },
  [90302] = { name = "Third Giver", minLevel = 10, maxLevel = 10, spawns = { [1] = { { 30.5, 71.0 } } },
    zoneID = 1, friendlyToFaction = "A" },
  [90303] = { name = "Far Giver", minLevel = 10, maxLevel = 10, spawns = { [12] = { { 40, 60 } } },
    zoneID = 12, friendlyToFaction = "A" },
}

local function quest(name, giver)
  return { name = name, startedBy = { { giver } }, finishedBy = { { giver } }, requiredLevel = 1, questLevel = 1,
    objectivesText = { "Talk." } }
end
local QDB = { npcs = NPCS, quests = {
  [9801] = quest("Offer One", 90300), [9802] = quest("Offer Two", 90301),
  [9803] = quest("Offer Three", 90302), [9804] = quest("Offer Far", 90303),
} }

local function chain(key, title, level, id)
  return { key = key, title = title, level = level, quests = { id }, rewards = {} }
end
local function data()
  return { WARLOCK = {
    chain("WARLOCK_A", "Chain A", 1, 9801), chain("WARLOCK_B", "Chain B", 2, 9802),
    chain("WARLOCK_C", "Chain C", 3, 9803), chain("WARLOCK_FAR", "Chain Far", 1, 9804),
  } }
end

local function load(only)
  Ext.install()
  Mock.player.classFile = "WARLOCK"
  local d = data()
  if only then
    local keep = {}
    for _, c in ipairs(d.WARLOCK) do if only[c.key] then keep[#keep + 1] = c end end
    d.WARLOCK = keep
  end
  return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true, qdb = QDB,
    savedVariables = { QuestifyCharDB = { wizardDone = true } },
    beforeLogin = function(Q) Q.ClassQuestData = d end })
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- Joueur à `yards` à l'est du donneur 90300 (même point que les deux autres).
local function away(Q, yards)
  local m, x, y
  for mapId, list in pairs(Q.QDB:Npc(90300).spawns) do m, x, y = mapId, list[1][1], list[1][2] end
  local unit = Q.Maps:Distance(m, x, y, m, x + 1, y)
  Mock.player.map, Mock.player.x, Mock.player.y = m, x + yards / unit, y
end

local function has(Q, key) return Q.ClassQuestOffer:Has(key) end

return {
  offer_inserted_near_the_giver_not_far = function(t)
    local Q = load({ WARLOCK_A = true })
    away(Q, 300)
    Mock.advance(5)
    t.ok(not has(Q, "WARLOCK_A"), "300 yards: no offer")
    away(Q, 100)
    Mock.advance(5)
    t.ok(has(Q, "WARLOCK_A"), "100 yards: offer")
    local cur = Q.Progress:Current()
    t.eq(cur.step.action, "classquest")
    t.eq(cur.step.key, "WARLOCK_A")
    t.eq(#Mock.errors, 0)
  end,

  offer_hysteresis = function(t)
    local Q = load({ WARLOCK_A = true })
    away(Q, 100)
    Mock.advance(5)
    t.ok(has(Q, "WARLOCK_A"))
    away(Q, 400)
    Mock.advance(5)
    t.ok(has(Q, "WARLOCK_A"), "between 250 and 600 yards: kept")
    away(Q, 700)
    Mock.advance(5)
    t.ok(not has(Q, "WARLOCK_A"), "beyond 600 yards: removed")
    away(Q, 100)
    Mock.advance(5)
    t.ok(has(Q, "WARLOCK_A"), "back near: offered again")
  end,

  zone_change_removes_offer_when_not_near = function(t)
    local Q = load({ WARLOCK_A = true })
    away(Q, 100)
    Mock.advance(5)
    away(Q, 400)
    Mock.fire("ZONE_CHANGED_NEW_AREA")
    t.ok(not has(Q, "WARLOCK_A"), "zone change away from the giver removes it")
  end,

  add_removes_offer_and_inserts_chain = function(t)
    local Q = load({ WARLOCK_A = true })
    away(Q, 100)
    Mock.advance(5)
    local cur = Q.Progress:Current()
    Mock.click(Q.UI.Tracker.current, "LeftButton")
    local P = Q.UI.ClassQuestPopup
    t.ok(P.frame:IsShown(), "popup opened by the click")
    t.eq(P.chain.key, "WARLOCK_A")
    Mock.click(P.addButton, "LeftButton")
    t.ok(not has(Q, "WARLOCK_A"), "offer gone")
    t.eq(Q.char.classQuests.added.WARLOCK_A, true)
    t.eq(Q.Progress:Current().step.action, "accept", "chain steps inserted")
    t.ok(cur.step.action == "classquest")
    Mock.advance(10)
    t.ok(not has(Q, "WARLOCK_A"), "never offered again once added")
    t.eq(#Mock.errors, 0)
  end,

  ignore_removes_offer_for_good = function(t)
    local Q = load({ WARLOCK_A = true })
    away(Q, 100)
    Mock.advance(5)
    Mock.click(Q.UI.Tracker.current, "LeftButton")
    Mock.click(Q.UI.ClassQuestPopup.ignoreButton, "LeftButton")
    t.ok(not has(Q, "WARLOCK_A"))
    t.eq(Q.char.classQuests.ignored.WARLOCK_A, true)
    away(Q, 700); Mock.advance(5)
    away(Q, 100); Mock.advance(5)
    t.ok(not has(Q, "WARLOCK_A"), "ignored: does not come back")
  end,

  skip_hides_offer_until_next_pass = function(t)
    local Q = load({ WARLOCK_A = true })
    away(Q, 100)
    Mock.advance(5)
    local cur = Q.Progress:Current()
    Q.Progress:Skip(cur.key)
    local now = Q.Progress:Current()
    t.ok(not now or now.step.action ~= "classquest", "skipped step is not current")
    Mock.advance(10)
    local count = 0
    for _, e in ipairs(Q.Progress:Entries()) do if e.step.action == "classquest" then count = count + 1 end end
    t.eq(count, 1, "no second copy while near")
    t.ok(not Q.Progress:Current() or Q.Progress:Current().step.action ~= "classquest", "still skipped")
    away(Q, 700); Mock.advance(5)
    t.ok(not has(Q, "WARLOCK_A"), "removed far away")
    away(Q, 100); Mock.advance(5)
    t.eq(Q.Progress:Current().step.action, "classquest", "offered again at the next pass")
    t.eq(Q.char.classQuests.ignored.WARLOCK_A, nil, "skip is not ignore")
  end,

  no_offer_in_combat = function(t)
    local Q = load({ WARLOCK_A = true })
    away(Q, 100)
    Mock.player.combat = true
    Mock.advance(10)
    t.ok(not has(Q, "WARLOCK_A"), "no offer during combat")
    Mock.player.combat = false
    Mock.advance(5)
    t.ok(has(Q, "WARLOCK_A"), "offer after combat")
  end,

  option_off_prevents_and_removes_offer = function(t)
    local Q = load({ WARLOCK_A = true })
    Q.Settings:Set("classQuestOffer", false)
    away(Q, 100)
    Mock.advance(10)
    t.ok(not has(Q, "WARLOCK_A"), "option off: no offer")
    Q.Settings:Set("classQuestOffer", true)
    Mock.advance(5)
    t.ok(has(Q, "WARLOCK_A"), "option on: offer")
    Q.Settings:Set("classQuestOffer", false)
    t.ok(not has(Q, "WARLOCK_A"), "option off removes the offer")
  end,

  option_is_on_by_default_and_in_the_options_panel = function(t)
    local Q = load({ WARLOCK_A = true })
    t.eq(Q.Settings:Get("classQuestOffer"), true)
    local found = Q.OptionsSchema:Entry("classQuestOffer")
    t.ok(found, "schema entry")
    t.eq(found.section, "class")
    t.ok(Q.L[found.label] and Q.L[found.tip], "texts")
  end,

  chain_in_route_is_never_offered = function(t)
    local Q = load({ WARLOCK_A = true })
    local orig = Q.Progress.RouteTurnins
    Q.Progress.RouteTurnins = function() return { [9801] = true } end
    away(Q, 100)
    Mock.advance(10)
    t.ok(not has(Q, "WARLOCK_A"), "in the route: no offer")
    Q.Progress.RouteTurnins = orig
  end,

  at_most_two_offers_most_late_first = function(t)
    local Q = load()
    Mock.player.level = 5
    Mock.fire("PLAYER_LEVEL_UP", 5)
    away(Q, 100)
    Mock.advance(5)
    t.ok(has(Q, "WARLOCK_A") and has(Q, "WARLOCK_B"), "the two most late chains")
    t.ok(not has(Q, "WARLOCK_C"), "no third offer")
    t.ok(not has(Q, "WARLOCK_FAR"), "far giver: no offer")
    t.eq(#Mock.errors, 0)
  end,

  alert_does_not_count_an_offered_chain = function(t)
    local Q = load({ WARLOCK_A = true, WARLOCK_FAR = true })
    away(Q, 100)
    Mock.advance(5)
    local keys = {}
    for _, row in ipairs(Q.ClassQuests:Alerts()) do keys[#keys + 1] = row.chain.key end
    t.eq(keys, { "WARLOCK_FAR" })
  end,

  step_title_text_and_target = function(t)
    local Q = load({ WARLOCK_A = true })
    away(Q, 100)
    Mock.advance(5)
    local cur = Q.Progress:Current()
    t.eq(Q.Format:StepTitle(cur), string.format(Q.L.TITLE_CLASSQUEST, "Offer One"))
    local text = plain(Q.Format:StepText(cur))
    t.ok(text:find("Offer One", 1, true), "chain title in the text")
    t.ok(text:find(plain(Q.L.STEP_CLASSQUEST_HINT), 1, true), "click hint")
    local target = Q.Targets:ForEntry(cur)
    t.ok(target, "target")
    t.eq(target.kind, "npc")
    t.eq(target.id, 90300)
    t.eq(Q.Format:ActionIcon("classquest") ~= nil, true)
  end,

  guides_normalize_accepts_classquest = function(t)
    local Q = load({ WARLOCK_A = true })
    local s = Q.Guides:Normalize({ "classquest", key = "WARLOCK_A" })
    t.eq(s.action, "classquest"); t.eq(s.key, "WARLOCK_A")
    local bad, err = Q.Guides:Normalize({ "classquest" })
    t.eq(bad, nil); t.ok(tostring(err):find("classquest", 1, true))
  end,

  texts_exist_in_both_languages = function(t)
    local Q = load({ WARLOCK_A = true })
    for _, id in ipairs({ "TITLE_CLASSQUEST", "STEP_CLASSQUEST", "STEP_CLASSQUEST_HINT", "OPT_TIP_CLASSQUEST_OFFER",
      "UI_OPT_CLASSQUEST_OFFER" }) do
      t.ok(Q.L[id], id)
    end
  end,
}
