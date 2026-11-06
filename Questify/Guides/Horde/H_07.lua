local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 40 étapes, niveau final 33.00, ~25888 xp/h, 118 min.
Q:RegisterGuide({
  id = "H_07",
  title = "Thousand Needles",
  faction = "Horde",
  minLevel = 32, maxLevel = 33,
  next = "H_08",
  sim = { steps = 40, endLevel = 33.00, xpPerHour = 25888, minutes = 118 },
  steps = {
    { "note", "Not running Blackfathom Deeps? Abandon Amongst the Ruins", optional = true, dungeon = "Blackfathom Deeps" },
    { "boat", 1420, 60.7, 58.9, note = "Take the zeppelin to Orgrimmar (Durotar)" }, -- bateau
    { "goto", 1454, 45.12, 63.89, note = "Flight master" }, -- déplacement
    { "fly", 1441, node = 30, note = "Freewind Post, Thousand Needles" }, -- vol
    { "accept", 5361 }, -- Family Tree (lvl 35, ~2050 xp, sim lvl 32)
    { "accept", 98070 }, -- Stop the Screeching (lvl 31, ~2500 xp, sim lvl 32)
    { "sethearth", 1441, 46.07, 51.52 }, -- lier la pierre de foyer
    { "complete", 98070, at = { 1441, 27.67, 49.38 } }, -- Stop the Screeching (lvl 31, ~2500 xp, sim lvl 32)
    { "turnin", 98070, xp = 2500 }, -- Stop the Screeching (lvl 31, ~2500 xp, sim lvl 32)
    { "accept", 1110 }, -- Rocket Car Parts (lvl 31, ~2500 xp, sim lvl 32)
    { "accept", 5762 }, -- Hemet Nesingwary (lvl 31, ~0 xp, sim lvl 32)
    { "accept", 1104 }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 32)
    { "accept", 1105 }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 32)
    { "accept", 1176 }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 32)
    { "accept", 1175 }, -- A Bump in the Road (lvl 33, ~2650 xp, sim lvl 32)
    { "complete", 1176, at = { 1441, 87.86, 65.44 } }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 32)
    { "complete", 1105, at = { 1441, 82.41, 54.63 } }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 32)
    { "complete", 1175, obj = 1, at = { 1441, 75.74, 58.39 } }, -- A Bump in the Road (lvl 33, ~2650 xp, sim lvl 32)
    { "complete", 1110, at = { 1441, 71.08, 57.98 } }, -- Rocket Car Parts (lvl 31, ~2500 xp, sim lvl 32)
    { "complete", 1104, at = { 1441, 71.4, 73.84 } }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 32)
    { "turnin", 1110, xp = 2500 }, -- Rocket Car Parts (lvl 31, ~2500 xp, sim lvl 32)
    { "turnin", 1104, xp = 1850 }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 32)
    { "turnin", 1105, xp = 2450 }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 32)
    { "complete", 1175, at = { 1441, 78.44, 87.69 } }, -- A Bump in the Road (lvl 33, ~2650 xp, sim lvl 32)
    { "turnin", 1175, xp = 2650 }, -- A Bump in the Road (lvl 33, ~2650 xp, sim lvl 32)
    { "turnin", 1176, xp = 1850 }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 32)
    { "hearth", 1441 }, -- pierre de foyer
    { "goto", 1441, 45.14, 49.11, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 25, note = "Crossroads, The Barrens" }, -- vol
    { "turnin", 1361, xp = 640 }, -- Regthar Deathgate (lvl 32, ~640 xp, sim lvl 32)
    { "accept", 1362 }, -- The Kolkar of Desolace (lvl 32, ~640 xp, sim lvl 32)
    { "accept", 1145 }, -- The Swarm Grows (lvl 33, ~1300 xp, sim lvl 32)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1454, node = 23, note = "Orgrimmar, Durotar" }, -- vol
    { "turnin", 1145, xp = 1300 }, -- The Swarm Grows (lvl 33, ~1300 xp, sim lvl 32)
    { "goto", 1454, 45.12, 63.89, note = "Flight master" }, -- déplacement
    { "fly", 1442, node = 29, note = "Sun Rock Retreat, Stonetalon Mountains" }, -- vol
    { "turnin", 5361, xp = 2050 }, -- Family Tree (lvl 35, ~2050 xp, sim lvl 32)
    { "turnin", 1362, xp = 640 }, -- The Kolkar of Desolace (lvl 32, ~640 xp, sim lvl 32)
    { "level", 33, at = { 1443, 67.87, 60.05 }, note = "About 63 more mobs here (Dread Swoop, level 32)" }, -- farm de niveau
  },
})
