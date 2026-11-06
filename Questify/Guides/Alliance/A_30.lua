local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 53 étapes, niveau final 60.00, ~75126 xp/h, 167 min.
Q:RegisterGuide({
  id = "A_30",
  title = "Silithus",
  faction = "Alliance",
  minLevel = 59, maxLevel = 60,
  sim = { steps = 53, endLevel = 60.00, xpPerHour = 75126, minutes = 167 },
  steps = {
    { "note", "Not running Blackrock Depths? Abandon The Heart of the Mountain, Ragnar Thunderbrew", optional = true, dungeon = "Blackrock Depths" },
    { "hearth", 1446 }, -- pierre de foyer
    { "goto", 1446, 51.01, 29.34, note = "Flight master" }, -- déplacement
    { "fly", 1449, node = 79, note = "Marshal's Refuge, Un'Goro Crater" }, -- vol
    { "fp", 1451, 50.58, 34.45 }, -- point de vol
    { "accept", 9415 }, -- Report to Marshal Bluewall (lvl 60, ~6600 xp, sim lvl 59)
    { "accept", 8284 }, -- The Twilight Mystery (lvl 58, ~6200 xp, sim lvl 59)
    { "accept", 8318 }, -- Secret Communication (lvl 60, ~6600 xp, sim lvl 59)
    { "accept", 8280 }, -- Securing the Supply Lines (lvl 55, ~5650 xp, sim lvl 59)
    { "accept", 8283 }, -- Wanted - Deathclasp, Terror of the Sands (lvl 59, ~8050 xp, sim lvl 59)
    { "accept", 8277 }, -- Deadly Desert Venom (lvl 55, ~5650 xp, sim lvl 59)
    { "complete", 8277, at = { 1451, 64.64, 30.1 } }, -- Deadly Desert Venom (lvl 55, ~5650 xp, sim lvl 59)
    { "complete", 8280, at = { 1451, 56.05, 29.94 } }, -- Securing the Supply Lines (lvl 55, ~5650 xp, sim lvl 59)
    { "complete", 8284, at = { 1451, 22.09, 10.4 } }, -- The Twilight Mystery (lvl 58, ~6200 xp, sim lvl 59)
    { "accept", 8304 }, -- Dearest Natalia (lvl 60, ~6600 xp, sim lvl 59)
    { "turnin", 8284, xp = 6200 }, -- The Twilight Mystery (lvl 58, ~6200 xp, sim lvl 59)
    { "accept", 8285 }, -- The Deserter (lvl 59, ~4800 xp, sim lvl 59)
    { "turnin", 8280, xp = 5650 }, -- Securing the Supply Lines (lvl 55, ~5650 xp, sim lvl 59)
    { "accept", 8281 }, -- Stepping Up Security (lvl 57, ~6000 xp, sim lvl 59)
    { "turnin", 8277, xp = 5650 }, -- Deadly Desert Venom (lvl 55, ~5650 xp, sim lvl 59)
    { "accept", 8278 }, -- Noggle's Last Hope (lvl 57, ~6000 xp, sim lvl 59)
    { "turnin", 8285, xp = 4800 }, -- The Deserter (lvl 59, ~4800 xp, sim lvl 59)
    { "accept", 8279 }, -- The Twilight Lexicon (lvl 60, ~8300 xp, sim lvl 59)
    { "complete", 8278, obj = 2, at = { 1451, 35.96, 61.76 } }, -- Noggle's Last Hope (lvl 57, ~6000 xp, sim lvl 59)
    { "complete", 8278, at = { 1451, 28.53, 77.78 } }, -- Noggle's Last Hope (lvl 57, ~6000 xp, sim lvl 59)
    { "complete", 8279, obj = 2, at = { 1451, 16.09, 86.37 } }, -- The Twilight Lexicon (lvl 60, ~8300 xp, sim lvl 59)
    { "accept", 8308, at = { 1451, 21.77, 60.87 }, note = "Loot Brann Bronzebeard's Lost Letter to start the quest" }, -- Brann Bronzebeard's Lost Letter (lvl 60, ~8300 xp, sim lvl 59)
    { "complete", 8279, obj = 1, at = { 1451, 26.35, 36.62 } }, -- The Twilight Lexicon (lvl 60, ~8300 xp, sim lvl 59)
    { "complete", 8281, at = { 1451, 30.56, 43.71 } }, -- Stepping Up Security (lvl 57, ~6000 xp, sim lvl 59)
    { "complete", 8279, at = { 1451, 40.86, 42.22 } }, -- The Twilight Lexicon (lvl 60, ~8300 xp, sim lvl 59)
    { "complete", 8318, at = { 1451, 39.34, 44.52 } }, -- Secret Communication (lvl 60, ~6600 xp, sim lvl 59)
    { "turnin", 8281, xp = 6000 }, -- Stepping Up Security (lvl 57, ~6000 xp, sim lvl 59)
    { "turnin", 8278, xp = 6000 }, -- Noggle's Last Hope (lvl 57, ~6000 xp, sim lvl 59)
    { "accept", 8282 }, -- Noggle's Lost Satchel (lvl 58, ~6200 xp, sim lvl 59)
    { "turnin", 8279, xp = 8300 }, -- The Twilight Lexicon (lvl 60, ~8300 xp, sim lvl 59)
    { "accept", 8323 }, -- True Believers (lvl 59, ~6400 xp, sim lvl 59)
    { "accept", 8287 }, -- A Terrible Purpose (lvl 60, ~6600 xp, sim lvl 59)
    { "complete", 8282, at = { 1451, 44.56, 91.38 } }, -- Noggle's Lost Satchel (lvl 58, ~6200 xp, sim lvl 59)
    { "complete", 8283, at = { 1451, 45.07, 92.31 } }, -- Wanted - Deathclasp, Terror of the Sands (lvl 59, ~8050 xp, sim lvl 59)
    { "turnin", 8308, xp = 8300 }, -- Brann Bronzebeard's Lost Letter (lvl 60, ~8300 xp, sim lvl 59)
    { "complete", 8304, at = { 1451, 40.81, 88.86 } }, -- Dearest Natalia (lvl 60, ~6600 xp, sim lvl 59)
    { "accept", 9419 }, -- Scouring the Desert (lvl 60, ~6600 xp, sim lvl 59)
    { "turnin", 9415, xp = 6600 }, -- Report to Marshal Bluewall (lvl 60, ~6600 xp, sim lvl 59)
    { "complete", 9419, at = { 1451, 32.95, 50.81 } }, -- Scouring the Desert (lvl 60, ~6600 xp, sim lvl 59)
    { "turnin", 9419, xp = 6600 }, -- Scouring the Desert (lvl 60, ~6600 xp, sim lvl 59)
    { "complete", 8323, at = { 1451, 39.34, 44.52 } }, -- True Believers (lvl 59, ~6400 xp, sim lvl 59)
    { "turnin", 8318, xp = 6600 }, -- Secret Communication (lvl 60, ~6600 xp, sim lvl 59)
    { "turnin", 8287, xp = 6600 }, -- A Terrible Purpose (lvl 60, ~6600 xp, sim lvl 59)
    { "turnin", 8304, xp = 6600 }, -- Dearest Natalia (lvl 60, ~6600 xp, sim lvl 59)
    { "turnin", 8283, xp = 8050 }, -- Wanted - Deathclasp, Terror of the Sands (lvl 59, ~8050 xp, sim lvl 59)
    { "turnin", 8282, xp = 6200 }, -- Noggle's Lost Satchel (lvl 58, ~6200 xp, sim lvl 59)
    { "turnin", 8323, xp = 6400 }, -- True Believers (lvl 59, ~6400 xp, sim lvl 59)
    { "level", 60, at = { 1451, 65.55, 74.85 }, note = "About 95 more mobs here (Rock Stalker, level 58)" }, -- farm de niveau
  },
})
