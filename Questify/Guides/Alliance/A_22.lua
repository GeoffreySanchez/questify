local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 106 étapes, niveau final 52.00, ~62277 xp/h, 290 min.
Q:RegisterGuide({
  id = "A_22",
  title = "Searing Gorge and Blasted Lands",
  faction = "Alliance",
  minLevel = 50, maxLevel = 52,
  next = "A_28",
  sim = { steps = 106, endLevel = 52.00, xpPerHour = 62277, minutes = 290 },
  steps = {
    { "note", "Not running Zul'Farrak? Abandon Scarab Shells, Troll Temper", optional = true, dungeon = "Zul'Farrak" },
    { "goto", 1434, 27.53, 77.79, note = "Flight master" }, -- déplacement
    { "fly", 1419, node = 45, note = "Nethergarde Keep, Blasted Lands" }, -- vol
    { "accept", 3501 }, -- Everything Counts In Large Amounts (lvl 55, ~5650 xp, sim lvl 50)
    { "accept", 2521 }, -- To Serve Kum'isha (lvl 55, ~8450 xp, sim lvl 50)
    { "accept", 81956 }, -- Conjurer's Codex (lvl 45, ~3120 xp, sim lvl 50)
    { "complete", 81956, at = { 1419, 55.43, 32.3 } }, -- Conjurer's Codex (lvl 45, ~3120 xp, sim lvl 50)
    { "accept", 2601 }, -- The Basilisk's Bite (lvl 50, ~4700 xp, sim lvl 50)
    { "accept", 2603 }, -- Vulture's Vigor (lvl 50, ~4700 xp, sim lvl 50)
    { "accept", 2585 }, -- The Decisive Striker (lvl 50, ~4700 xp, sim lvl 50)
    { "accept", 2583 }, -- A Boar's Vitality (lvl 50, ~4700 xp, sim lvl 50)
    { "accept", 2581 }, -- Snickerfang Jowls (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 2521, at = { 1419, 47.73, 19.9 } }, -- To Serve Kum'isha (lvl 55, ~8450 xp, sim lvl 50)
    { "complete", 2585, at = { 1419, 47.8, 20.03 } }, -- The Decisive Striker (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 2583, obj = 2, at = { 1419, 47.74, 21.26 } }, -- A Boar's Vitality (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 2581, obj = 3, at = { 1419, 46.16, 21.89 } }, -- Snickerfang Jowls (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 2601, at = { 1419, 45.74, 22.7 } }, -- The Basilisk's Bite (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 3501, at = { 1419, 47.63, 29.99 } }, -- Everything Counts In Large Amounts (lvl 55, ~5650 xp, sim lvl 50)
    { "complete", 2585, at = { 1419, 45.68, 35.17 } }, -- The Decisive Striker (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 2581, at = { 1419, 47.37, 36.25 } }, -- Snickerfang Jowls (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 2583, obj = 1, at = { 1419, 51.94, 38.22 } }, -- A Boar's Vitality (lvl 50, ~4700 xp, sim lvl 50)
    { "turnin", 2521, xp = 8450 }, -- To Serve Kum'isha (lvl 55, ~8450 xp, sim lvl 50)
    { "turnin", 3501, xp = 5650 }, -- Everything Counts In Large Amounts (lvl 55, ~5650 xp, sim lvl 50)
    { "complete", 2603, at = { 1419, 55.15, 36.6 } }, -- Vulture's Vigor (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 2583, at = { 1419, 59.86, 38.52 } }, -- A Boar's Vitality (lvl 50, ~4700 xp, sim lvl 50)
    { "accept", 4128, optional = true, dungeon = "Blackrock Depths" }, -- Ragnar Thunderbrew (lvl 55, ~0 xp, sim lvl 50)
    { "turnin", 2601, xp = 4700 }, -- The Basilisk's Bite (lvl 50, ~4700 xp, sim lvl 50)
    { "turnin", 2603, xp = 4700 }, -- Vulture's Vigor (lvl 50, ~4700 xp, sim lvl 50)
    { "turnin", 2581, xp = 4700 }, -- Snickerfang Jowls (lvl 50, ~4700 xp, sim lvl 50)
    { "turnin", 2583, xp = 4700 }, -- A Boar's Vitality (lvl 50, ~4700 xp, sim lvl 50)
    { "turnin", 2585, xp = 4700 }, -- The Decisive Striker (lvl 50, ~4700 xp, sim lvl 50)
    { "fp", 1428, 84.33, 68.33 }, -- point de vol
    { "accept", 3181, at = { 1427, 73.52, 82.31 }, note = "Loot Margol's Horn to start the quest" }, -- The Horn of the Beast (lvl 48, ~5450 xp, sim lvl 50)
    { "accept", 4449 }, -- Caught! (lvl 45, ~3120 xp, sim lvl 50)
    { "complete", 4449, obj = 2, at = { 1427, 46.81, 53.53 } }, -- Caught! (lvl 45, ~3120 xp, sim lvl 50)
    { "fp", 1427, 37.94, 30.86 }, -- point de vol
    { "accept", 3441 }, -- Divine Retribution (lvl 48, ~440 xp, sim lvl 50)
    { "complete", 3441, at = { 1427, 39.06, 38.99 } }, -- Divine Retribution (lvl 48, ~440 xp, sim lvl 50)
    { "turnin", 3441, xp = 440 }, -- Divine Retribution (lvl 48, ~440 xp, sim lvl 50)
    { "accept", 3442 }, -- The Flawless Flame (lvl 48, ~4400 xp, sim lvl 50)
    { "accept", 4451, at = { 1427, 42.09, 34.68 }, note = "Loot Grimesilt Outhouse Key to start the quest" }, -- The Key to Freedom (lvl 47, ~5250 xp, sim lvl 50)
    { "accept", 7722 }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 50)
    { "accept", 7701 }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 50)
    { "accept", 7728 }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 50)
    { "accept", 7729 }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 50)
    { "accept", 7723 }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 50)
    { "accept", 7724 }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 50)
    { "accept", 7727 }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 50)
    { "complete", 7722, at = { 1427, 40.45, 35.74 } }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 7729, at = { 1427, 43.75, 35.25 } }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 50)
    { "complete", 7723, at = { 1427, 43.63, 41.32 } }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 50)
    { "complete", 7701, at = { 1427, 40.77, 35.89 } }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 3442, at = { 1427, 54.57, 47.42 } }, -- The Flawless Flame (lvl 48, ~4400 xp, sim lvl 50)
    { "turnin", 3442, xp = 4400 }, -- The Flawless Flame (lvl 48, ~4400 xp, sim lvl 50)
    { "accept", 3443 }, -- Forging the Shaft (lvl 48, ~4400 xp, sim lvl 50)
    { "complete", 3443, at = { 1427, 42.09, 34.68 } }, -- Forging the Shaft (lvl 48, ~4400 xp, sim lvl 50)
    { "turnin", 3443, xp = 4400 }, -- Forging the Shaft (lvl 48, ~4400 xp, sim lvl 50)
    { "accept", 3452 }, -- The Flame's Casing (lvl 50, ~4700 xp, sim lvl 50)
    { "complete", 3452, at = { 1427, 21.78, 37.25 } }, -- The Flame's Casing (lvl 50, ~4700 xp, sim lvl 50)
    { "turnin", 3452, xp = 4700 }, -- The Flame's Casing (lvl 50, ~4700 xp, sim lvl 51)
    { "accept", 3453 }, -- The Torch of Retribution (lvl 50, ~470 xp, sim lvl 51)
    { "complete", 3453, at = { 1427, 39.06, 38.99 } }, -- The Torch of Retribution (lvl 50, ~470 xp, sim lvl 51)
    { "turnin", 3453, xp = 470 }, -- The Torch of Retribution (lvl 50, ~470 xp, sim lvl 51)
    { "accept", 3454 }, -- The Torch of Retribution (lvl 50, ~4700 xp, sim lvl 51)
    { "turnin", 3454, xp = 4700 }, -- The Torch of Retribution (lvl 50, ~4700 xp, sim lvl 51)
    { "accept", 3462 }, -- Squire Maltrake (lvl 50, ~470 xp, sim lvl 51)
    { "turnin", 3462, xp = 470 }, -- Squire Maltrake (lvl 50, ~470 xp, sim lvl 51)
    { "accept", 3463 }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 51)
    { "complete", 7728, obj = 1, at = { 1427, 39.88, 50.1 } }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 51)
    { "accept", 81955 }, -- A Mind of Metal (lvl 45, ~3120 xp, sim lvl 51)
    { "complete", 81955, at = { 1427, 37.85, 49.45 } }, -- A Mind of Metal (lvl 45, ~3120 xp, sim lvl 51)
    { "complete", 3463, at = { 1427, 35.67, 60.68 } }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 51)
    { "complete", 7728, at = { 1427, 33.01, 53.96 } }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 51)
    { "complete", 7724, at = { 1427, 28.59, 72.01 } }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 51)
    { "complete", 3463, obj = 2, at = { 1427, 44.03, 60.91 } }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 51)
    { "complete", 3463, at = { 1427, 50.07, 54.74 } }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 51)
    { "complete", 4449, at = { 1427, 63.3, 60.56 } }, -- Caught! (lvl 45, ~3120 xp, sim lvl 51)
    { "accept", 3367 }, -- Suntara Stones (lvl 48, ~4400 xp, sim lvl 51)
    { "turnin", 4449, xp = 3120 }, -- Caught! (lvl 45, ~3120 xp, sim lvl 51)
    { "turnin", 4451, xp = 5250 }, -- The Key to Freedom (lvl 47, ~5250 xp, sim lvl 51)
    { "complete", 3367, at = { 1427, 74.47, 19.44 } }, -- Suntara Stones (lvl 48, ~4400 xp, sim lvl 51)
    { "turnin", 3367, xp = 4400 }, -- Suntara Stones (lvl 48, ~4400 xp, sim lvl 51)
    { "accept", 3368 }, -- Suntara Stones (lvl 48, ~4400 xp, sim lvl 51)
    { "complete", 7727, at = { 1427, 48.4, 24.03 } }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 51)
    { "turnin", 7728, xp = 4400 }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 51)
    { "turnin", 7729, xp = 4400 }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 51)
    { "turnin", 7701, xp = 4700 }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 51)
    { "turnin", 7723, xp = 4550 }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 51)
    { "turnin", 7727, xp = 4550 }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 51)
    { "turnin", 7724, xp = 4550 }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 51)
    { "turnin", 7722, xp = 4700 }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 51)
    { "turnin", 3463, xp = 7600 }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 51)
    { "accept", 3481 }, -- Trinkets... (lvl 50, ~470 xp, sim lvl 51)
    { "turnin", 3481, xp = 470 }, -- Trinkets... (lvl 50, ~470 xp, sim lvl 51)
    { "goto", 1427, 37.94, 30.86, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "turnin", 81955, xp = 3120 }, -- A Mind of Metal (lvl 45, ~3120 xp, sim lvl 51)
    { "turnin", 81956, xp = 3120 }, -- Conjurer's Codex (lvl 45, ~3120 xp, sim lvl 51)
    { "turnin", 81949, xp = 3120 }, -- Legends of the Tidesages (lvl 45, ~3120 xp, sim lvl 51)
    { "goto", 1453, 71.29, 72.23, note = "Flight master" }, -- déplacement
    { "fly", 1432, node = 8, note = "Thelsamar, Loch Modan" }, -- vol
    { "turnin", 3181, xp = 5450 }, -- The Horn of the Beast (lvl 48, ~5450 xp, sim lvl 51)
    { "goto", 1432, 33.94, 50.95, note = "Flight master" }, -- déplacement
    { "fly", 1455, node = 6, note = "Ironforge, Dun Morogh" }, -- vol
    { "turnin", 3368, xp = 4400 }, -- Suntara Stones (lvl 48, ~4400 xp, sim lvl 51)
    { "level", 52, at = { 1427, 48.4, 24.03 }, note = "About 137 more mobs near the last objective" }, -- farm de niveau
  },
})
