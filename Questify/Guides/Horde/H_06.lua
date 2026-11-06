local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 51 étapes, niveau final 32.07, ~37782 xp/h, 155 min.
Q:RegisterGuide({
  id = "H_06",
  title = "Alterac Mountains and Arathi Highlands",
  faction = "Horde",
  minLevel = 30, maxLevel = 32,
  next = "H_07",
  sim = { steps = 51, endLevel = 32.07, xpPerHour = 37782, minutes = 155 },
  steps = {
    { "note", "Not running Blackfathom Deeps? Abandon Trouble in the Deeps, The Essence of Aku'Mai", optional = true, dungeon = "Blackfathom Deeps" },
    { "note", "Not running Wailing Caverns? Abandon Trouble at the Docks, Deviate Hides, Deviate Eradication, Hamuul Runetotem", optional = true, dungeon = "Wailing Caverns" },
    { "goto", 1458, 63.25, 48.56, note = "Flight master" }, -- déplacement
    { "fly", 1424, node = 13, note = "Tarren Mill, Hillsbrad" }, -- vol
    { "accept", 535 }, -- Valik (lvl 34, ~270 xp, sim lvl 30)
    { "accept", 676 }, -- The Hammer May Fall (lvl 32, ~2550 xp, sim lvl 30)
    { "accept", 556 }, -- Stone Tokens (lvl 32, ~2550 xp, sim lvl 30)
    { "accept", 544 }, -- Prison Break In (lvl 34, ~3350 xp, sim lvl 30)
    { "accept", 498 }, -- The Rescue (lvl 22, ~880 xp, sim lvl 30)
    { "accept", 1361 }, -- Regthar Deathgate (lvl 32, ~0 xp, sim lvl 30)
    { "complete", 498, at = { 1424, 75.33, 41.5 } }, -- The Rescue (lvl 22, ~880 xp, sim lvl 30)
    { "turnin", 498, xp = 880 }, -- The Rescue (lvl 22, ~880 xp, sim lvl 30)
    { "accept", 533 }, -- Infiltration (lvl 34, ~2700 xp, sim lvl 30)
    { "complete", 533, at = { 1416, 58.3, 67.96 } }, -- Infiltration (lvl 34, ~2700 xp, sim lvl 30)
    { "complete", 535, at = { 1416, 58.98, 68.49 } }, -- Valik (lvl 34, ~270 xp, sim lvl 30)
    { "turnin", 535, xp = 270 }, -- Valik (lvl 34, ~270 xp, sim lvl 30)
    { "level", 31, at = { 1416, 14.01, 58.47 }, note = "About 11 mobs here (High Order Mage, level 30)" }, -- farm de niveau
    { "complete", 556, at = { 1416, 19.4, 84.93 } }, -- Stone Tokens (lvl 32, ~2550 xp, sim lvl 31)
    { "complete", 544, at = { 1416, 19.91, 85.97 } }, -- Prison Break In (lvl 34, ~3350 xp, sim lvl 31)
    { "hearth", 1424 }, -- pierre de foyer
    { "turnin", 556, xp = 2550 }, -- Stone Tokens (lvl 32, ~2550 xp, sim lvl 31)
    { "accept", 557 }, -- Bracers of Binding (lvl 34, ~2700 xp, sim lvl 31)
    { "turnin", 544, xp = 3350 }, -- Prison Break In (lvl 34, ~3350 xp, sim lvl 31)
    { "accept", 545 }, -- Dalaran Patrols (lvl 35, ~2050 xp, sim lvl 31)
    { "turnin", 533, xp = 2700 }, -- Infiltration (lvl 34, ~2700 xp, sim lvl 31)
    { "complete", 676, at = { 1417, 35.32, 42.95 } }, -- The Hammer May Fall (lvl 32, ~2550 xp, sim lvl 31)
    { "fp", 1417, 73.02, 32.7 }, -- point de vol
    { "accept", 655 }, -- Hammerfall (lvl 34, ~270 xp, sim lvl 31)
    { "turnin", 676, xp = 2550 }, -- The Hammer May Fall (lvl 32, ~2550 xp, sim lvl 31)
    { "turnin", 655, xp = 270 }, -- Hammerfall (lvl 34, ~270 xp, sim lvl 31)
    { "accept", 672 }, -- Raising Spirits (lvl 34, ~2700 xp, sim lvl 31)
    { "complete", 672, at = { 1417, 66.71, 38.36 } }, -- Raising Spirits (lvl 34, ~2700 xp, sim lvl 31)
    { "turnin", 672, xp = 2700 }, -- Raising Spirits (lvl 34, ~2700 xp, sim lvl 31)
    { "accept", 674 }, -- Raising Spirits (lvl 34, ~270 xp, sim lvl 31)
    { "turnin", 674, xp = 270 }, -- Raising Spirits (lvl 34, ~270 xp, sim lvl 31)
    { "accept", 675 }, -- Raising Spirits (lvl 34, ~270 xp, sim lvl 31)
    { "turnin", 675, xp = 270 }, -- Raising Spirits (lvl 34, ~270 xp, sim lvl 31)
    { "accept", 79949 }, -- A Web of Lies: Debunking Myths and Legends (lvl 35, ~2750 xp, sim lvl 31)
    { "complete", 79949, at = { 1417, 73.6, 65.2 } }, -- A Web of Lies: Debunking Myths and Legends (lvl 35, ~2750 xp, sim lvl 31)
    { "goto", 1417, 73.02, 32.7, note = "Flight master" }, -- déplacement
    { "fly", 1424, node = 13, note = "Tarren Mill, Hillsbrad" }, -- vol
    { "turnin", 97287, xp = 1300 }, -- Shrewd Negotiations (lvl 33, ~1300 xp, sim lvl 31)
    { "accept", 96984, optional = true, dungeon = "City of Dalaran" }, -- Heart of Disruption (lvl 33, ~0 xp, sim lvl 31)
    { "complete", 557, at = { 1416, 21.03, 58.34 } }, -- Bracers of Binding (lvl 34, ~2700 xp, sim lvl 31)
    { "complete", 545, at = { 1416, 21.01, 58.98 } }, -- Dalaran Patrols (lvl 35, ~2050 xp, sim lvl 31)
    { "turnin", 557, xp = 2700 }, -- Bracers of Binding (lvl 34, ~2700 xp, sim lvl 31)
    { "turnin", 545, xp = 2050 }, -- Dalaran Patrols (lvl 35, ~2050 xp, sim lvl 31)
    { "accept", 79948 }, -- Defensive Magics 101 (lvl 35, ~2750 xp, sim lvl 31)
    { "complete", 79948, at = { 1416, 48.45, 57.65 } }, -- Defensive Magics 101 (lvl 35, ~2750 xp, sim lvl 31)
    { "turnin", 79948, xp = 2750 }, -- Defensive Magics 101 (lvl 35, ~2750 xp, sim lvl 31)
    { "turnin", 79949, xp = 2750 }, -- A Web of Lies: Debunking Myths and Legends (lvl 35, ~2750 xp, sim lvl 32)
  },
})
