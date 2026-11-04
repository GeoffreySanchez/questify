-- Tests des vols automatiques (Q.Taxi, Automation/Taxi.lua).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_comfort.lua")

local function load()
  Ext.install()
  return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
end

-- Étape courante « fly » (étapes insérées avant le chapitre).
local function flyTo(Q, steps)
  Q.Progress:InsertSteps("test", steps)
  return Q.Progress:Current()
end

local function nodes(list) Mock.comfort.nodes = list end

local function taken()
  local out = {}
  for _, c in ipairs(Mock.callsTo("TakeTaxiNode")) do out[#out + 1] = c.args[1] end
  return out
end

return {
  flies_to_the_node_of_the_destination_zone = function(t)
    local Q = load()
    local cur = flyTo(Q, { { "fly", 1432 } })
    t.eq(cur.step.action, "fly")
    nodes({ { name = "Ironforge, Dun Morogh", state = 0 }, { name = "Thelsamar, Loch Modan", state = 1 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), { 2 })
    t.ok(Mock.printed(string.format(Q.L.COMFORT_TAXI_FLYING, "Thelsamar, Loch Modan")), "message")
    -- deuxième ouverture sans fermeture : pas de second vol
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), { 2 })
    t.eq(#Mock.errors, 0)
  end,

  town_of_the_note_wins_over_zone = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1426, note = "Kharanos, Dun Morogh" } })
    nodes({ { name = "Ironforge, Dun Morogh", state = 1 }, { name = "Kharanos, Dun Morogh", state = 1 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), { 2 })
  end,

  node_id_of_the_step_wins = function(t)
    local Q = load()
    local cur = flyTo(Q, { { "fly", 1426, node = 6 } })
    t.eq(cur.step.node, 6, "Normalize keeps node")
    -- noms ambigus (deux nœuds dans la zone), note trompeuse, aucune position : l'ID décide
    nodes({ { name = "Ironforge, Dun Morogh", state = 1, nodeID = 5, slotIndex = 11 },
      { name = "Kharanos, Dun Morogh", state = 1, nodeID = 6, slotIndex = 12 } })
    cur.step.note = "Ironforge, Dun Morogh"
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), { 12 })
    t.ok(Mock.printed(string.format(Q.L.COMFORT_TAXI_FLYING, "Kharanos, Dun Morogh")))
  end,

  normalize_keeps_a_numeric_node = function(t)
    local Q = load()
    t.eq(Q.Guides:Normalize({ "fly", 1453 }).node, nil)
    t.eq(Q.Guides:Normalize({ "fly", 1453, node = 6 }).node, 6)
    local bad, err = Q.Guides:Normalize({ "fly", 1453, node = "Ratchet" })
    t.eq(bad, nil)
    t.ok(tostring(err):find("node must be a number", 1, true), "node validated")
  end,

  node_id_of_current_node_does_nothing = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1426, node = 6 } })
    nodes({ { name = "Kharanos, Dun Morogh", state = 0, nodeID = 6 }, { name = "Ironforge, Dun Morogh", state = 1 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), {})
    t.eq(#Mock.prints, 0)
  end,

  unknown_node_id_falls_back_to_names = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432, node = 999 } })
    nodes({ { name = "Ironforge, Dun Morogh", state = 0, nodeID = 5 }, { name = "Thelsamar, Loch Modan", state = 1, nodeID = 8 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), { 2 })
  end,

  legacy_path_ignores_node_id = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432, node = 6 } })
    C_TaxiMap, GetTaxiMapID = nil, nil
    Mock.comfort.legacy = { { name = "Ironforge, Dun Morogh", type = "CURRENT" },
      { name = "Thelsamar, Loch Modan", type = "REACHABLE" } }
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), { 2 })
  end,

  several_nodes_in_zone_use_next_step_position = function(t)
    local Q = load()
    -- client non anglais : la note ne correspond à aucun nom, deux nœuds dans la zone
    flyTo(Q, { { "fly", 1432, note = "Crossroads, The Barrens" }, { "goto", 1432, 70, 70 } })
    Mock.comfort.taxiMapId = 1432
    nodes({ { name = "Alpha, Loch Modan", state = 1, x = 0.20, y = 0.20 },
      { name = "Beta, Loch Modan", state = 1, x = 0.69, y = 0.71 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), { 2 })
  end,

  ambiguous_without_position_prints_not_found = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    nodes({ { name = "Alpha, Loch Modan", state = 1 }, { name = "Beta, Loch Modan", state = 1 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), {})
    t.ok(Mock.printed(string.format(Q.L.COMFORT_TAXI_NOT_FOUND, "Loch Modan")), "not found message")
  end,

  unreachable_node_prints_a_message = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    nodes({ { name = "Thelsamar, Loch Modan", state = 2 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), {})
    t.eq(Mock.countPrinted(string.format(Q.L.COMFORT_TAXI_UNREACHABLE, "Thelsamar, Loch Modan")), 1)
  end,

  no_matching_node_prints_not_found = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    nodes({ { name = "Ironforge, Dun Morogh", state = 1 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), {})
    t.ok(Mock.printed(string.format(Q.L.COMFORT_TAXI_NOT_FOUND, "Loch Modan")))
  end,

  shift_or_option_off = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    nodes({ { name = "Thelsamar, Loch Modan", state = 1 } })
    Mock.player.shift = true
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), {}, "Shift lets the player choose")
    Mock.fire("TAXIMAP_CLOSED")
    Mock.player.shift = false
    Q.Settings:Set("autoFly", false)
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), {}, "option off")
    t.eq(#Mock.prints, 0, "no message")
  end,

  never_in_combat = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    nodes({ { name = "Thelsamar, Loch Modan", state = 1 } })
    Mock.player.combat = true
    Mock.fire("TAXIMAP_OPENED", 1)
    Mock.advance(1)
    t.eq(taken(), {})
    t.eq(#Mock.errors, 0)
  end,

  only_on_fly_steps = function(t)
    load()
    nodes({ { name = "Thelsamar, Loch Modan", state = 1 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), {}, "current step is an accept step")
    t.eq(#Mock.prints, 0)
  end,

  legacy_taxi_functions = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    C_TaxiMap = nil
    GetTaxiMapID = nil
    Mock.comfort.legacy = { { name = "Ironforge, Dun Morogh", type = "CURRENT" },
      { name = "Thelsamar, Loch Modan", type = "REACHABLE" } }
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), { 2 })
    t.eq(#Mock.errors, 0)
  end,

  empty_list_retries_once = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    nodes({})
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(taken(), {})
    nodes({ { name = "Thelsamar, Loch Modan", state = 1 } })
    Mock.advance(1)
    t.eq(taken(), { 1 })
  end,

  closed_before_retry_does_nothing = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    nodes({})
    Mock.fire("TAXIMAP_OPENED", 1)
    Mock.fire("TAXIMAP_CLOSED")
    nodes({ { name = "Thelsamar, Loch Modan", state = 1 } })
    Mock.advance(1)
    t.eq(taken(), {})
  end,

  missing_api_is_silent = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    C_TaxiMap, GetTaxiMapID, NumTaxiNodes, TaxiNodeName, TaxiNodeGetType = nil, nil, nil, nil, nil
    Mock.fire("TAXIMAP_OPENED", 1)
    Mock.advance(1)
    t.eq(#Mock.errors, 0)
    t.eq(#Mock.prints, 0)
    -- nœuds lisibles mais TakeTaxiNode absent : rien non plus
    Ext.install()
    TakeTaxiNode = nil
    nodes({ { name = "Thelsamar, Loch Modan", state = 1 } })
    Mock.fire("TAXIMAP_CLOSED")
    Mock.fire("TAXIMAP_OPENED", 1)
    t.eq(#Mock.errors, 0)
    t.eq(#Mock.prints, 0)
  end,

  secret_node_names_are_ignored = function(t)
    local Q = load()
    flyTo(Q, { { "fly", 1432 } })
    nodes({ { name = Mock.strictSecret("Thelsamar, Loch Modan"), state = 1 } })
    Mock.fire("TAXIMAP_OPENED", 1)
    Mock.advance(1)
    t.eq(taken(), {})
    t.eq(#Mock.errors, 0)
  end,

  without_questiedb_does_nothing = function(t)
    Mock.addons.QuestieDB = false
    load()
    nodes({ { name = "Thelsamar, Loch Modan", state = 1 } })
    local before = #Mock.prints
    Mock.fire("TAXIMAP_OPENED", 1)
    Mock.advance(1)
    t.eq(taken(), {})
    t.eq(#Mock.prints, before)
    t.eq(#Mock.errors, 0)
  end,
}
