local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 50 étapes, niveau final 33.04, ~28645 xp/h, 111 min.
Q:RegisterGuide({
  id = "H_07",
  title = "Thousand Needles",
  faction = "Horde",
  minLevel = 32, maxLevel = 33,
  next = "H_08",
  sim = { steps = 50, endLevel = 33.04, xpPerHour = 28645, minutes = 111 },
  steps = {
    { "note", "Not running Blackfathom Deeps? Abandon Amongst the Ruins", optional = true, dungeon = "Blackfathom Deeps" },
    { "boat", 1420, 60.7, 58.9, note = "Take the zeppelin to Orgrimmar (Durotar)" }, -- bateau
    { "goto", 1454, 45.12, 63.89, note = "Flight master" }, -- déplacement
    { "fly", 1441, node = 30, note = "Freewind Post, Thousand Needles" }, -- vol
    { "accept", 5361 }, -- Family Tree (lvl 35, ~2050 xp, sim lvl 32)
    { "goto", 1441, 45.14, 49.11, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 25, note = "Crossroads, The Barrens" }, -- vol
    { "accept", 1145 }, -- The Swarm Grows (lvl 33, ~1300 xp, sim lvl 32)
    { "sethearth", 1413, 51.99, 29.89 }, -- lier la pierre de foyer
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1454, node = 23, note = "Orgrimmar, Durotar" }, -- vol
    { "turnin", 1145, xp = 1300 }, -- The Swarm Grows (lvl 33, ~1300 xp, sim lvl 32)
    { "accept", 1146 }, -- The Swarm Grows (lvl 33, ~1950 xp, sim lvl 32)
    { "hearth", 1413 }, -- pierre de foyer
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1441, node = 30, note = "Freewind Post, Thousand Needles" }, -- vol
    { "accept", 1176 }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 32)
    { "accept", 1105 }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 32)
    { "accept", 1104 }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 32)
    { "accept", 5762 }, -- Hemet Nesingwary (lvl 31, ~0 xp, sim lvl 32)
    { "complete", 1104, at = { 1441, 71.4, 73.84 } }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 32)
    { "turnin", 1146, xp = 1950 }, -- The Swarm Grows (lvl 33, ~1950 xp, sim lvl 32)
    { "accept", 1147 }, -- The Swarm Grows (lvl 35, ~2750 xp, sim lvl 32)
    { "complete", 1105, at = { 1441, 82.41, 54.63 } }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 32)
    { "complete", 1176, at = { 1441, 87.86, 65.44 } }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 32)
    { "turnin", 1176, xp = 1850 }, -- Load Lightening (lvl 30, ~1850 xp, sim lvl 32)
    { "turnin", 1105, xp = 2450 }, -- Hardened Shells (lvl 30, ~2450 xp, sim lvl 32)
    { "turnin", 1104, xp = 1850 }, -- Salt Flat Venom (lvl 30, ~1850 xp, sim lvl 32)
    { "complete", 1147, at = { 1441, 67.73, 82.45 } }, -- The Swarm Grows (lvl 35, ~2750 xp, sim lvl 32)
    { "accept", 1148, at = { 1441, 69.97, 85.22 }, note = "Loot Cracked Silithid Carapace to start the quest" }, -- Parts of the Swarm (lvl 35, ~1350 xp, sim lvl 32)
    { "complete", 1148, at = { 1441, 69.98, 85.21 } }, -- Parts of the Swarm (lvl 35, ~1350 xp, sim lvl 32)
    { "complete", 1147, at = { 1441, 64.99, 85.97 } }, -- The Swarm Grows (lvl 35, ~2750 xp, sim lvl 32)
    { "turnin", 1147, xp = 2750 }, -- The Swarm Grows (lvl 35, ~2750 xp, sim lvl 32)
    { "hearth", 1413 }, -- pierre de foyer
    { "turnin", 1148, xp = 1350 }, -- Parts of the Swarm (lvl 35, ~1350 xp, sim lvl 32)
    { "accept", 1184 }, -- Parts of the Swarm (lvl 35, ~1350 xp, sim lvl 32)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1454, node = 23, note = "Orgrimmar, Durotar" }, -- vol
    { "turnin", 1184, xp = 1350 }, -- Parts of the Swarm (lvl 35, ~1350 xp, sim lvl 32)
    { "accept", 1431 }, -- Alliance Relations (lvl 30, ~610 xp, sim lvl 32)
    { "turnin", 1431, xp = 610 }, -- Alliance Relations (lvl 30, ~610 xp, sim lvl 32)
    { "accept", 1432 }, -- Alliance Relations (lvl 30, ~1200 xp, sim lvl 32)
    { "goto", 1454, 45.12, 63.89, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 25, note = "Crossroads, The Barrens" }, -- vol
    { "turnin", 1361, xp = 640 }, -- Regthar Deathgate (lvl 32, ~640 xp, sim lvl 32)
    { "accept", 1362 }, -- The Kolkar of Desolace (lvl 32, ~640 xp, sim lvl 32)
    { "fp", 1456, 47, 49.83 }, -- point de vol
    { "turnin", 1362, xp = 640 }, -- The Kolkar of Desolace (lvl 32, ~640 xp, sim lvl 32)
    { "turnin", 5361, xp = 2050 }, -- Family Tree (lvl 35, ~2050 xp, sim lvl 32)
    { "turnin", 1432, xp = 1200 }, -- Alliance Relations (lvl 30, ~1200 xp, sim lvl 33)
  },
})
