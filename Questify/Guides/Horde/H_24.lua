local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 72 étapes, niveau final 53.00, ~55772 xp/h, 172 min.
Q:RegisterGuide({
  id = "H_24",
  title = "Searing Gorge and Burning Steppes",
  faction = "Horde",
  minLevel = 52, maxLevel = 53,
  next = "H_25",
  sim = { steps = 72, endLevel = 53.00, xpPerHour = 55772, minutes = 172 },
  steps = {
    { "accept", 81953 }, -- Stonewrought Design (lvl 45, ~585 xp, sim lvl 52)
    { "complete", 81953, at = { 1428, 28.96, 28.93 } }, -- Stonewrought Design (lvl 45, ~585 xp, sim lvl 52)
    { "accept", 81955 }, -- A Mind of Metal (lvl 45, ~585 xp, sim lvl 52)
    { "complete", 81955, at = { 1427, 37.85, 49.45 } }, -- A Mind of Metal (lvl 45, ~585 xp, sim lvl 52)
    { "fp", 1427, 34.84, 30.87 }, -- point de vol
    { "accept", 3441 }, -- Divine Retribution (lvl 48, ~440 xp, sim lvl 52)
    { "complete", 3441, at = { 1427, 39.06, 38.99 } }, -- Divine Retribution (lvl 48, ~440 xp, sim lvl 52)
    { "turnin", 3441, xp = 440 }, -- Divine Retribution (lvl 48, ~440 xp, sim lvl 52)
    { "accept", 3442 }, -- The Flawless Flame (lvl 48, ~4400 xp, sim lvl 52)
    { "accept", 4451, at = { 1427, 42.09, 34.68 }, note = "Loot Grimesilt Outhouse Key to start the quest" }, -- The Key to Freedom (lvl 47, ~5250 xp, sim lvl 52)
    { "accept", 7728 }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 52)
    { "accept", 7701 }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 52)
    { "accept", 7729 }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 52)
    { "accept", 7723 }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 52)
    { "accept", 7724 }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 52)
    { "accept", 7727 }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 52)
    { "accept", 7722 }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 52)
    { "complete", 7727, at = { 1427, 48.4, 24.03 } }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 52)
    { "complete", 3442, at = { 1427, 54.57, 47.42 } }, -- The Flawless Flame (lvl 48, ~4400 xp, sim lvl 52)
    { "complete", 7722, at = { 1427, 40.45, 35.74 } }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 52)
    { "complete", 7729, at = { 1427, 43.75, 35.25 } }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 52)
    { "complete", 7701, at = { 1427, 40.77, 35.89 } }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 52)
    { "complete", 7723, at = { 1427, 43.63, 41.32 } }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 52)
    { "turnin", 3442, xp = 4400 }, -- The Flawless Flame (lvl 48, ~4400 xp, sim lvl 52)
    { "accept", 3443 }, -- Forging the Shaft (lvl 48, ~4400 xp, sim lvl 52)
    { "complete", 3443, at = { 1427, 42.09, 34.68 } }, -- Forging the Shaft (lvl 48, ~4400 xp, sim lvl 52)
    { "turnin", 3443, xp = 4400 }, -- Forging the Shaft (lvl 48, ~4400 xp, sim lvl 52)
    { "accept", 3452 }, -- The Flame's Casing (lvl 50, ~4700 xp, sim lvl 52)
    { "complete", 3452, at = { 1427, 21.78, 37.25 } }, -- The Flame's Casing (lvl 50, ~4700 xp, sim lvl 52)
    { "turnin", 3452, xp = 4700 }, -- The Flame's Casing (lvl 50, ~4700 xp, sim lvl 52)
    { "accept", 3453 }, -- The Torch of Retribution (lvl 50, ~470 xp, sim lvl 52)
    { "complete", 3453, at = { 1427, 39.06, 38.99 } }, -- The Torch of Retribution (lvl 50, ~470 xp, sim lvl 52)
    { "turnin", 3453, xp = 470 }, -- The Torch of Retribution (lvl 50, ~470 xp, sim lvl 52)
    { "accept", 3454 }, -- The Torch of Retribution (lvl 50, ~4700 xp, sim lvl 52)
    { "turnin", 3454, xp = 4700 }, -- The Torch of Retribution (lvl 50, ~4700 xp, sim lvl 52)
    { "accept", 3462 }, -- Squire Maltrake (lvl 50, ~470 xp, sim lvl 52)
    { "turnin", 3462, xp = 470 }, -- Squire Maltrake (lvl 50, ~470 xp, sim lvl 52)
    { "accept", 3463 }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 52)
    { "complete", 3463, obj = 3, at = { 1427, 50.07, 54.74 } }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 52)
    { "complete", 3463, obj = 2, at = { 1427, 44.03, 60.91 } }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 52)
    { "complete", 3463, at = { 1427, 35.67, 60.68 } }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 52)
    { "complete", 7728, obj = 2, at = { 1427, 33.01, 53.96 } }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 52)
    { "complete", 7724, at = { 1427, 28.59, 72.01 } }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 52)
    { "complete", 7728, at = { 1427, 39.88, 50.1 } }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 52)
    { "turnin", 3463, xp = 7600 }, -- Set Them Ablaze! (lvl 52, ~7600 xp, sim lvl 52)
    { "accept", 3481 }, -- Trinkets... (lvl 50, ~470 xp, sim lvl 52)
    { "turnin", 3481, xp = 470 }, -- Trinkets... (lvl 50, ~470 xp, sim lvl 52)
    { "turnin", 7722, xp = 4700 }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 52)
    { "turnin", 7723, xp = 4550 }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 52)
    { "turnin", 7724, xp = 4550 }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 52)
    { "turnin", 7727, xp = 4550 }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 52)
    { "turnin", 7701, xp = 4700 }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 52)
    { "turnin", 7729, xp = 4400 }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 52)
    { "turnin", 7728, xp = 4400 }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 52)
    { "turnin", 4451, xp = 5250 }, -- The Key to Freedom (lvl 47, ~5250 xp, sim lvl 52)
    { "fp", 1428, 65.69, 24.22 }, -- point de vol
    { "accept", 4136, optional = true, dungeon = "Blackrock Depths" }, -- Ribbly Screwspigot (lvl 53, ~0 xp, sim lvl 52)
    { "accept", 4296 }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "accept", 4123, optional = true, dungeon = "Blackrock Depths" }, -- The Heart of the Mountain (lvl 55, ~0 xp, sim lvl 52)
    { "accept", 4726 }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "complete", 4726, at = { 1428, 86.98, 31.41 } }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4023 }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4023, at = { 1428, 94.4, 31.8 } }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "turnin", 4023, xp = 5450 }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4296, at = { 1428, 54.12, 40.76 } }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "turnin", 4296, xp = 2350 }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "turnin", 4726, xp = 5100 }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "fly", 1458, node = 11, note = "Undercity, Tirisfal" }, -- vol
    { "turnin", 81953, xp = 585 }, -- Stonewrought Design (lvl 45, ~585 xp, sim lvl 52)
    { "turnin", 81955, xp = 585 }, -- A Mind of Metal (lvl 45, ~585 xp, sim lvl 52)
    { "turnin", 81956, xp = 585 }, -- Conjurer's Codex (lvl 45, ~585 xp, sim lvl 52)
    { "level", 53, at = { 1458, 47.96, 78.93 }, note = "About 80 more mobs here (Anya Rince, level 52)" }, -- farm de niveau
  },
})
