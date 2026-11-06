local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 38 étapes, niveau final 53.00, ~53983 xp/h, 178 min.
Q:RegisterGuide({
  id = "H_24",
  title = "Searing Gorge and Burning Steppes",
  faction = "Horde",
  minLevel = 52, maxLevel = 53,
  next = "H_25",
  sim = { steps = 38, endLevel = 53.00, xpPerHour = 53983, minutes = 178 },
  steps = {
    { "fp", 1428, 65.69, 24.22 }, -- point de vol
    { "accept", 4726 }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4296 }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "accept", 4123, optional = true, dungeon = "Blackrock Depths" }, -- The Heart of the Mountain (lvl 55, ~0 xp, sim lvl 52)
    { "accept", 4136, optional = true, dungeon = "Blackrock Depths" }, -- Ribbly Screwspigot (lvl 53, ~0 xp, sim lvl 52)
    { "accept", 4023 }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4023, at = { 1428, 94.4, 31.8 } }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "turnin", 4023, xp = 5450 }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4726, at = { 1428, 86.98, 31.41 } }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "complete", 4296, at = { 1428, 54.12, 40.76 } }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "turnin", 4726, xp = 5100 }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "turnin", 4296, xp = 2350 }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "accept", 4451, at = { 1427, 42.09, 34.68 }, note = "Loot Grimesilt Outhouse Key to start the quest" }, -- The Key to Freedom (lvl 47, ~5250 xp, sim lvl 52)
    { "fp", 1427, 34.84, 30.87 }, -- point de vol
    { "accept", 7722 }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 52)
    { "accept", 7724 }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 52)
    { "accept", 7723 }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 52)
    { "accept", 7727 }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 52)
    { "accept", 7701 }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 52)
    { "accept", 7728 }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 52)
    { "accept", 7729 }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 52)
    { "complete", 7727, at = { 1427, 48.4, 24.03 } }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 52)
    { "complete", 7722, at = { 1427, 40.45, 35.74 } }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 52)
    { "complete", 7729, at = { 1427, 43.75, 35.25 } }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 52)
    { "complete", 7701, at = { 1427, 40.77, 35.89 } }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 52)
    { "complete", 7723, at = { 1427, 43.63, 41.32 } }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 52)
    { "complete", 7728, obj = 1, at = { 1427, 39.88, 50.1 } }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 52)
    { "complete", 7724, at = { 1427, 28.59, 72.01 } }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 52)
    { "complete", 7728, at = { 1427, 33.01, 53.96 } }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 52)
    { "turnin", 7701, xp = 4700 }, -- WANTED: Overseer Maltorius (lvl 50, ~4700 xp, sim lvl 52)
    { "turnin", 7727, xp = 4550 }, -- Incendosaurs? Whateverosaur is More Like It (lvl 49, ~4550 xp, sim lvl 52)
    { "turnin", 7723, xp = 4550 }, -- Curse These Fat Fingers (lvl 49, ~4550 xp, sim lvl 52)
    { "turnin", 7724, xp = 4550 }, -- Fiery Menace! (lvl 49, ~4550 xp, sim lvl 52)
    { "turnin", 7728, xp = 4400 }, -- STOLEN: Smithing Tuyere and Lookout's Spyglass (lvl 48, ~4400 xp, sim lvl 52)
    { "turnin", 7729, xp = 4400 }, -- JOB OPPORTUNITY: Culling the Competition (lvl 48, ~4400 xp, sim lvl 52)
    { "turnin", 7722, xp = 4700 }, -- What the Flux? (lvl 50, ~4700 xp, sim lvl 52)
    { "turnin", 4451, xp = 5250 }, -- The Key to Freedom (lvl 47, ~5250 xp, sim lvl 52)
    { "level", 53, at = { 1427, 33.01, 53.96 }, note = "About 270 more mobs near the last objective" }, -- farm de niveau
  },
})
