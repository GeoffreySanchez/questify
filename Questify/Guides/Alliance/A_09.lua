local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 36 étapes, niveau final 34.00, ~25084 xp/h, 140 min.
Q:RegisterGuide({
  id = "A_09",
  title = "Thousand Needles",
  faction = "Alliance",
  minLevel = 33, maxLevel = 34,
  next = "A_10",
  sim = { steps = 36, endLevel = 34.00, xpPerHour = 25084, minutes = 140 },
  steps = {
    { "boat", 1434, 26.08, 73.35, note = "Take the boat to Ratchet (The Barrens)" }, -- bateau
    { "fp", 1413, 63.08, 37.16 }, -- point de vol
    { "fp", 1445, 67.48, 51.3 }, -- point de vol
    { "accept", 1110 }, -- Rocket Car Parts (lvl 31, ~2500 xp, sim lvl 33)
    { "accept", 1111 }, -- Wharfmaster Dizzywig (lvl 36, ~1400 xp, sim lvl 33)
    { "accept", 5762 }, -- Hemet Nesingwary (lvl 31, ~0 xp, sim lvl 33)
    { "accept", 1104 }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 33)
    { "accept", 1105 }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 33)
    { "accept", 1176 }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 33)
    { "accept", 1175 }, -- A Bump in the Road (lvl 33, ~2650 xp, sim lvl 33)
    { "complete", 1176, at = { 1441, 87.86, 65.44 } }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 33)
    { "turnin", 1176, xp = 1850 }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 33)
    { "accept", 1178 }, -- Goblin Sponsorship (lvl 37, ~710 xp, sim lvl 33)
    { "complete", 1105, at = { 1441, 82.41, 54.63 } }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 33)
    { "goto", 1445, 67.48, 51.3, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 80, note = "Ratchet, The Barrens" }, -- vol
    { "turnin", 1111, xp = 1400 }, -- Wharfmaster Dizzywig (lvl 36, ~1400 xp, sim lvl 33)
    { "accept", 1112 }, -- Parts for Kravel (lvl 36, ~1400 xp, sim lvl 33)
    { "turnin", 1178, xp = 710 }, -- Goblin Sponsorship (lvl 37, ~710 xp, sim lvl 33)
    { "accept", 1180 }, -- Goblin Sponsorship (lvl 37, ~0 xp, sim lvl 33)
    { "accept", 1221, optional = true, dungeon = "Razorfen Kraul" }, -- Blueleaf Tubers (lvl 26, ~0 xp, sim lvl 33)
    { "goto", 1413, 63.08, 37.16, note = "Flight master" }, -- déplacement
    { "fly", 1445, node = 32, note = "Theramore, Dustwallow Marsh" }, -- vol
    { "complete", 1175, obj = 1, at = { 1441, 75.74, 58.39 } }, -- A Bump in the Road (lvl 33, ~2650 xp, sim lvl 33)
    { "complete", 1110, at = { 1441, 71.08, 57.98 } }, -- Rocket Car Parts (lvl 31, ~2500 xp, sim lvl 33)
    { "complete", 1104, at = { 1441, 71.4, 73.84 } }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 33)
    { "turnin", 1110, xp = 2500 }, -- Rocket Car Parts (lvl 31, ~2500 xp, sim lvl 33)
    { "turnin", 1112, xp = 1400 }, -- Parts for Kravel (lvl 36, ~1400 xp, sim lvl 33)
    { "accept", 1114 }, -- Delivery to the Gnomes (lvl 36, ~700 xp, sim lvl 33)
    { "turnin", 1105, xp = 2450 }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 33)
    { "turnin", 1104, xp = 1850 }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 33)
    { "turnin", 1114, xp = 700 }, -- Delivery to the Gnomes (lvl 36, ~700 xp, sim lvl 33)
    { "accept", 1115 }, -- The Rumormonger (lvl 36, ~0 xp, sim lvl 33)
    { "complete", 1175, at = { 1441, 78.44, 87.69 } }, -- A Bump in the Road (lvl 33, ~2650 xp, sim lvl 33)
    { "turnin", 1175, xp = 2650 }, -- A Bump in the Road (lvl 33, ~2650 xp, sim lvl 33)
    { "level", 34, at = { 1441, 78.23, 88.47 }, note = "About 143 more mobs here (Saltstone Crystalhide, level 32)" }, -- farm de niveau
  },
})
