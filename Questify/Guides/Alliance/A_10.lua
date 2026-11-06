local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 62 étapes, niveau final 35.00, ~47704 xp/h, 79 min.
Q:RegisterGuide({
  id = "A_10",
  title = "Stranglethorn Vale",
  faction = "Alliance",
  minLevel = 34, maxLevel = 35,
  next = "A_11",
  sim = { steps = 62, endLevel = 35.00, xpPerHour = 47704, minutes = 79 },
  steps = {
    { "note", "Not running Razorfen Kraul? Abandon Blueleaf Tubers", optional = true, dungeon = "Razorfen Kraul" },
    { "hearth", 1431 }, -- pierre de foyer
    { "accept", 583 }, -- Welcome to the Jungle (lvl 30, ~245 xp, sim lvl 34)
    { "turnin", 583, xp = 245 }, -- Welcome to the Jungle (lvl 30, ~245 xp, sim lvl 34)
    { "accept", 194 }, -- Raptor Mastery (lvl 34, ~1350 xp, sim lvl 34)
    { "turnin", 5762, xp = 1250 }, -- Hemet Nesingwary (lvl 31, ~1250 xp, sim lvl 34)
    { "accept", 185 }, -- Tiger Mastery (lvl 31, ~1250 xp, sim lvl 34)
    { "accept", 190 }, -- Panther Mastery (lvl 31, ~1250 xp, sim lvl 34)
    { "complete", 185, at = { 1434, 34.28, 11.84 } }, -- Tiger Mastery (lvl 31, ~1250 xp, sim lvl 34)
    { "complete", 190, at = { 1434, 41.8, 12.69 } }, -- Panther Mastery (lvl 31, ~1250 xp, sim lvl 34)
    { "accept", 215 }, -- Jungle Secrets (lvl 33, ~1300 xp, sim lvl 34)
    { "turnin", 215, xp = 1300 }, -- Jungle Secrets (lvl 33, ~1300 xp, sim lvl 34)
    { "accept", 200 }, -- Bookie Herod (lvl 35, ~1350 xp, sim lvl 34)
    { "accept", 203 }, -- The Second Rebellion (lvl 33, ~1950 xp, sim lvl 34)
    { "accept", 204 }, -- Bad Medicine (lvl 34, ~2700 xp, sim lvl 34)
    { "accept", 210 }, -- Krazek's Cookery (lvl 37, ~0 xp, sim lvl 34)
    { "turnin", 185, xp = 1250 }, -- Tiger Mastery (lvl 31, ~1250 xp, sim lvl 34)
    { "accept", 186 }, -- Tiger Mastery (lvl 33, ~1300 xp, sim lvl 34)
    { "turnin", 190, xp = 1250 }, -- Panther Mastery (lvl 31, ~1250 xp, sim lvl 34)
    { "accept", 191 }, -- Panther Mastery (lvl 33, ~1300 xp, sim lvl 34)
    { "complete", 186, at = { 1434, 29.8, 10.25 } }, -- Tiger Mastery (lvl 33, ~1300 xp, sim lvl 34)
    { "complete", 191, at = { 1434, 29.62, 10.42 } }, -- Panther Mastery (lvl 33, ~1300 xp, sim lvl 34)
    { "complete", 194, at = { 1434, 26.88, 16.33 } }, -- Raptor Mastery (lvl 34, ~1350 xp, sim lvl 34)
    { "turnin", 191, xp = 1300 }, -- Panther Mastery (lvl 33, ~1300 xp, sim lvl 34)
    { "accept", 192 }, -- Panther Mastery (lvl 38, ~2150 xp, sim lvl 34)
    { "turnin", 186, xp = 1300 }, -- Tiger Mastery (lvl 33, ~1300 xp, sim lvl 34)
    { "accept", 187 }, -- Tiger Mastery (lvl 35, ~2050 xp, sim lvl 34)
    { "turnin", 194, xp = 1350 }, -- Raptor Mastery (lvl 34, ~1350 xp, sim lvl 34)
    { "accept", 195 }, -- Raptor Mastery (lvl 36, ~1400 xp, sim lvl 34)
    { "complete", 187, at = { 1434, 35.01, 18.88 } }, -- Tiger Mastery (lvl 35, ~2050 xp, sim lvl 34)
    { "complete", 195, at = { 1434, 38.49, 20.44 } }, -- Raptor Mastery (lvl 36, ~1400 xp, sim lvl 34)
    { "complete", 192, at = { 1434, 49.19, 21.6 } }, -- Panther Mastery (lvl 38, ~2150 xp, sim lvl 34)
    { "complete", 204, obj = 2, at = { 1434, 44.3, 9.63 } }, -- Bad Medicine (lvl 34, ~2700 xp, sim lvl 34)
    { "complete", 203, at = { 1434, 44.7, 10.07 } }, -- The Second Rebellion (lvl 33, ~1950 xp, sim lvl 34)
    { "turnin", 200, xp = 1350 }, -- Bookie Herod (lvl 35, ~1350 xp, sim lvl 34)
    { "accept", 328 }, -- The Hidden Key (lvl 37, ~1400 xp, sim lvl 34)
    { "turnin", 328, xp = 1400 }, -- The Hidden Key (lvl 37, ~1400 xp, sim lvl 34)
    { "accept", 329 }, -- The Spy Revealed! (lvl 37, ~1400 xp, sim lvl 34)
    { "complete", 204, at = { 1434, 47.45, 7.11 } }, -- Bad Medicine (lvl 34, ~2700 xp, sim lvl 34)
    { "turnin", 329, xp = 1400 }, -- The Spy Revealed! (lvl 37, ~1400 xp, sim lvl 34)
    { "accept", 330 }, -- Patrol Schedules (lvl 37, ~285 xp, sim lvl 34)
    { "turnin", 203, xp = 1950 }, -- The Second Rebellion (lvl 33, ~1950 xp, sim lvl 34)
    { "turnin", 204, xp = 2700 }, -- Bad Medicine (lvl 34, ~2700 xp, sim lvl 34)
    { "accept", 574 }, -- Special Forces (lvl 38, ~2850 xp, sim lvl 34)
    { "accept", 207 }, -- Kurzen's Mystery (lvl 38, ~3550 xp, sim lvl 34)
    { "turnin", 330, xp = 285 }, -- Patrol Schedules (lvl 37, ~285 xp, sim lvl 34)
    { "accept", 331 }, -- Report to Doren (lvl 37, ~2850 xp, sim lvl 34)
    { "turnin", 331, xp = 2850 }, -- Report to Doren (lvl 37, ~2850 xp, sim lvl 34)
    { "turnin", 187, xp = 2050 }, -- Tiger Mastery (lvl 35, ~2050 xp, sim lvl 34)
    { "accept", 188 }, -- Tiger Mastery (lvl 37, ~2850 xp, sim lvl 34)
    { "turnin", 192, xp = 2150 }, -- Panther Mastery (lvl 38, ~2150 xp, sim lvl 34)
    { "turnin", 195, xp = 1400 }, -- Raptor Mastery (lvl 36, ~1400 xp, sim lvl 34)
    { "complete", 207, obj = 4, at = { 1434, 24.7, 8.93 } }, -- Kurzen's Mystery (lvl 38, ~3550 xp, sim lvl 34)
    { "complete", 207, obj = 3, at = { 1434, 22.95, 12.02 } }, -- Kurzen's Mystery (lvl 38, ~3550 xp, sim lvl 34)
    { "complete", 207, obj = 2, at = { 1434, 24.8, 22.96 } }, -- Kurzen's Mystery (lvl 38, ~3550 xp, sim lvl 34)
    { "complete", 207, at = { 1434, 29.48, 19.14 } }, -- Kurzen's Mystery (lvl 38, ~3550 xp, sim lvl 34)
    { "complete", 188, at = { 1434, 31.84, 16.45 } }, -- Tiger Mastery (lvl 37, ~2850 xp, sim lvl 34)
    { "turnin", 188, xp = 2850 }, -- Tiger Mastery (lvl 37, ~2850 xp, sim lvl 34)
    { "complete", 574, at = { 1434, 45.79, 7.9 } }, -- Special Forces (lvl 38, ~2850 xp, sim lvl 34)
    { "turnin", 574, xp = 2850 }, -- Special Forces (lvl 38, ~2850 xp, sim lvl 34)
    { "turnin", 207, xp = 3550 }, -- Kurzen's Mystery (lvl 38, ~3550 xp, sim lvl 34)
    { "level", 35, at = { 1434, 45.68, 8.42 }, note = "About 11 more mobs here (Kurzen Commando, level 34)" }, -- farm de niveau
  },
})
