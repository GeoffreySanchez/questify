local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 31 étapes, niveau final 43.10, ~51599 xp/h, 83 min.
Q:RegisterGuide({
  id = "H_14",
  title = "Swamp of Sorrows",
  faction = "Horde",
  minLevel = 42, maxLevel = 43,
  next = "H_15",
  sim = { steps = 31, endLevel = 43.10, xpPerHour = 51599, minutes = 83 },
  steps = {
    { "fly", 1434, node = 20, note = "Grom'gol, Stranglethorn" }, -- vol
    { "turnin", 624, xp = 3600 }, -- Cortello's Riddle (lvl 43, ~3600 xp, sim lvl 42)
    { "accept", 625 }, -- Cortello's Riddle (lvl 43, ~0 xp, sim lvl 42)
    { "accept", 93176 }, -- My Little Friends (lvl 35, ~810 xp, sim lvl 42)
    { "turnin", 93176, xp = 810 }, -- My Little Friends (lvl 35, ~810 xp, sim lvl 42)
    { "fp", 1435, 46.07, 54.83 }, -- point de vol
    { "accept", 698 }, -- Lack of Surplus (lvl 40, ~3150 xp, sim lvl 42)
    { "accept", 1430 }, -- Fresh Meat (lvl 44, ~3750 xp, sim lvl 42)
    { "turnin", 1420, xp = 2350 }, -- Report to Helgrum (lvl 40, ~2350 xp, sim lvl 42)
    { "accept", 1424 }, -- Pool of Tears (lvl 43, ~4450 xp, sim lvl 42)
    { "complete", 698, at = { 1435, 55.41, 52.01 } }, -- Lack of Surplus (lvl 40, ~3150 xp, sim lvl 42)
    { "complete", 1424, at = { 1435, 72.58, 56.48 } }, -- Pool of Tears (lvl 43, ~4450 xp, sim lvl 42)
    { "turnin", 698, xp = 3150 }, -- Lack of Surplus (lvl 40, ~3150 xp, sim lvl 42)
    { "accept", 699 }, -- Lack of Surplus (lvl 42, ~3450 xp, sim lvl 42)
    { "complete", 1430, at = { 1435, 95.77, 74.9 } }, -- Fresh Meat (lvl 44, ~3750 xp, sim lvl 42)
    { "complete", 699, at = { 1435, 80.35, 27.79 } }, -- Lack of Surplus (lvl 42, ~3450 xp, sim lvl 42)
    { "turnin", 699, xp = 3450 }, -- Lack of Surplus (lvl 42, ~3450 xp, sim lvl 42)
    { "accept", 1422 }, -- Threat From the Sea (lvl 45, ~1460 xp, sim lvl 42)
    { "turnin", 1422, xp = 1460 }, -- Threat From the Sea (lvl 45, ~1460 xp, sim lvl 42)
    { "accept", 1426 }, -- Threat From the Sea (lvl 43, ~4450 xp, sim lvl 42)
    { "complete", 1426, at = { 1435, 85.84, 85.19 } }, -- Threat From the Sea (lvl 43, ~4450 xp, sim lvl 42)
    { "complete", 1426, at = { 1435, 63.26, 82.96 } }, -- Threat From the Sea (lvl 43, ~4450 xp, sim lvl 42)
    { "turnin", 1426, xp = 4450 }, -- Threat From the Sea (lvl 43, ~4450 xp, sim lvl 42)
    { "accept", 1427 }, -- Threat From the Sea (lvl 43, ~3600 xp, sim lvl 42)
    { "turnin", 1427, xp = 3600 }, -- Threat From the Sea (lvl 43, ~3600 xp, sim lvl 42)
    { "accept", 1428 }, -- Continued Threat (lvl 45, ~3900 xp, sim lvl 42)
    { "complete", 1428, obj = 1, at = { 1435, 84.77, 87.21 } }, -- Continued Threat (lvl 45, ~3900 xp, sim lvl 42)
    { "complete", 1428, at = { 1435, 63.26, 82.96 } }, -- Continued Threat (lvl 45, ~3900 xp, sim lvl 42)
    { "turnin", 1428, xp = 3900 }, -- Continued Threat (lvl 45, ~3900 xp, sim lvl 42)
    { "turnin", 1424, xp = 4450 }, -- Pool of Tears (lvl 43, ~4450 xp, sim lvl 43)
    { "turnin", 1430, xp = 3750 }, -- Fresh Meat (lvl 44, ~3750 xp, sim lvl 43)
  },
})
