local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 25 étapes, niveau final 40.34, ~41725 xp/h, 133 min.
Q:RegisterGuide({
  id = "H_12",
  title = "Badlands",
  faction = "Horde",
  minLevel = 39, maxLevel = 40,
  next = "H_13",
  sim = { steps = 25, endLevel = 40.34, xpPerHour = 41725, minutes = 133 },
  steps = {
    { "fp", 1418, 3.99, 44.78 }, -- point de vol
    { "accept", 2258 }, -- Badlands Reagent Run (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 1419 }, -- Coyote Thieves (lvl 40, ~3150 xp, sim lvl 39)
    { "accept", 1420 }, -- Report to Helgrum (lvl 40, ~0 xp, sim lvl 39)
    { "complete", 2258, obj = 3, at = { 1418, 21.13, 45.46 } }, -- Badlands Reagent Run (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 710 }, -- Study of the Elements: Rock (lvl 37, ~2850 xp, sim lvl 39)
    { "complete", 710, at = { 1418, 20.96, 45.07 } }, -- Study of the Elements: Rock (lvl 37, ~2850 xp, sim lvl 39)
    { "turnin", 710, xp = 2850 }, -- Study of the Elements: Rock (lvl 37, ~2850 xp, sim lvl 39)
    { "accept", 711 }, -- Study of the Elements: Rock (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 2418, optional = true, dungeon = "Uldaman" }, -- Power Stones (lvl 36, ~0 xp, sim lvl 39)
    { "accept", 709, optional = true, dungeon = "Uldaman" }, -- Solution to Doom (lvl 40, ~0 xp, sim lvl 39)
    { "complete", 711, at = { 1418, 42.98, 80.83 } }, -- Study of the Elements: Rock (lvl 39, ~3000 xp, sim lvl 39)
    { "complete", 1419, at = { 1418, 35.5, 62.56 } }, -- Coyote Thieves (lvl 40, ~3150 xp, sim lvl 39)
    { "complete", 2258, obj = 2, at = { 1418, 35.5, 62.56 } }, -- Badlands Reagent Run (lvl 39, ~3000 xp, sim lvl 39)
    { "turnin", 711, xp = 3000 }, -- Study of the Elements: Rock (lvl 39, ~3000 xp, sim lvl 40)
    { "accept", 712 }, -- Study of the Elements: Rock (lvl 42, ~3450 xp, sim lvl 40)
    { "accept", 782 }, -- Broken Alliances (lvl 43, ~3600 xp, sim lvl 40)
    { "complete", 712, at = { 1418, 3.82, 80.28 } }, -- Study of the Elements: Rock (lvl 42, ~3450 xp, sim lvl 40)
    { "complete", 782, at = { 1418, 12.62, 75.49 } }, -- Broken Alliances (lvl 43, ~3600 xp, sim lvl 40)
    { "complete", 2258, at = { 1418, 15.71, 60.94 } }, -- Badlands Reagent Run (lvl 39, ~3000 xp, sim lvl 40)
    { "turnin", 712, xp = 3450 }, -- Study of the Elements: Rock (lvl 42, ~3450 xp, sim lvl 40)
    { "turnin", 1419, xp = 3150 }, -- Coyote Thieves (lvl 40, ~3150 xp, sim lvl 40)
    { "turnin", 782, xp = 3600 }, -- Broken Alliances (lvl 43, ~3600 xp, sim lvl 40)
    { "turnin", 2258, xp = 3000 }, -- Badlands Reagent Run (lvl 39, ~3000 xp, sim lvl 40)
    { "accept", 2202, optional = true, dungeon = "Uldaman" }, -- Uldaman Reagent Run (lvl 42, ~0 xp, sim lvl 40)
  },
})
