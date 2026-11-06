local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 54 étapes, niveau final 49.00, ~59276 xp/h, 267 min.
Q:RegisterGuide({
  id = "H_18",
  title = "Stranglethorn Vale",
  faction = "Horde",
  minLevel = 47, maxLevel = 49,
  next = "H_21",
  sim = { steps = 54, endLevel = 49.00, xpPerHour = 59276, minutes = 267 },
  steps = {
    { "note", "Not running Uldaman? Abandon Uldaman Reagent Run", optional = true, dungeon = "Uldaman" },
    { "boat", 1411, 50.69, 12.89, note = "Take the zeppelin to Grom'gol (Stranglethorn Vale)" }, -- bateau
    { "goto", 1434, 32.54, 29.35, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 18, note = "Booty Bay, Stranglethorn" }, -- vol
    { "accept", 209 }, -- Skullsplitter Tusks (lvl 42, ~3450 xp, sim lvl 47)
    { "turnin", 2874, xp = 3900 }, -- Deliver to MacKinley (lvl 45, ~3900 xp, sim lvl 47)
    { "turnin", 648, xp = 5450 }, -- Rescue OOX-17/TN! (lvl 48, ~5450 xp, sim lvl 47)
    { "turnin", 2767, xp = 4850 }, -- Rescue OOX-22/FE! (lvl 45, ~4850 xp, sim lvl 47)
    { "accept", 8552, at = { 1434, 23.25, 72.1 }, note = "Loot Monogrammed Sash to start the quest" }, -- The Monogrammed Sash (lvl 50, ~2350 xp, sim lvl 47)
    { "turnin", 8552, xp = 2350 }, -- The Monogrammed Sash (lvl 50, ~2350 xp, sim lvl 47)
    { "accept", 8553 }, -- The Captain's Cutlass (lvl 50, ~470 xp, sim lvl 47)
    { "accept", 8551 }, -- The Captain's Chest (lvl 47, ~3150 xp, sim lvl 47)
    { "turnin", 8553, xp = 470 }, -- The Captain's Cutlass (lvl 50, ~470 xp, sim lvl 47)
    { "accept", 8554 }, -- Facing Negolash (lvl 50, ~7100 xp, sim lvl 47)
    { "goto", 1434, 26.87, 77.1, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 20, note = "Grom'gol, Stranglethorn" }, -- vol
    { "accept", 584 }, -- Bloodscalp Clan Heads (lvl 41, ~2640 xp, sim lvl 47)
    { "sethearth", 1434, 31.49, 29.75 }, -- lier la pierre de foyer
    { "complete", 584, at = { 1434, 23.44, 8.12 } }, -- Bloodscalp Clan Heads (lvl 41, ~2640 xp, sim lvl 47)
    { "turnin", 584, xp = 2640 }, -- Bloodscalp Clan Heads (lvl 41, ~2640 xp, sim lvl 47)
    { "accept", 586 }, -- Speaking with Gan'zulah (lvl 46, ~4050 xp, sim lvl 47)
    { "accept", 585 }, -- Speaking with Nezzliok (lvl 40, ~1410 xp, sim lvl 47)
    { "complete", 585, obj = 1, at = { 1434, 46.13, 32.33 } }, -- Speaking with Nezzliok (lvl 40, ~1410 xp, sim lvl 47)
    { "complete", 585, obj = 3, at = { 1434, 47.65, 39.54 } }, -- Speaking with Nezzliok (lvl 40, ~1410 xp, sim lvl 47)
    { "complete", 209, at = { 1434, 47.41, 39.79 } }, -- Skullsplitter Tusks (lvl 42, ~3450 xp, sim lvl 47)
    { "complete", 586, at = { 1434, 45.64, 42.96 } }, -- Speaking with Gan'zulah (lvl 46, ~4050 xp, sim lvl 47)
    { "complete", 585, at = { 1434, 42.21, 36.11 } }, -- Speaking with Nezzliok (lvl 40, ~1410 xp, sim lvl 47)
    { "turnin", 586, xp = 4050 }, -- Speaking with Gan'zulah (lvl 46, ~4050 xp, sim lvl 47)
    { "turnin", 585, xp = 1410 }, -- Speaking with Nezzliok (lvl 40, ~1410 xp, sim lvl 47)
    { "accept", 588 }, -- The Fate of Yenniku (lvl 45, ~390 xp, sim lvl 47)
    { "turnin", 588, xp = 390 }, -- The Fate of Yenniku (lvl 45, ~390 xp, sim lvl 47)
    { "accept", 589 }, -- The Singing Crystals (lvl 45, ~3900 xp, sim lvl 47)
    { "complete", 589, at = { 1434, 43.11, 48.08 } }, -- The Singing Crystals (lvl 45, ~3900 xp, sim lvl 47)
    { "hearth", 1434 }, -- pierre de foyer
    { "turnin", 589, xp = 3900 }, -- The Singing Crystals (lvl 45, ~3900 xp, sim lvl 47)
    { "accept", 591 }, -- The Mind's Eye (lvl 46, ~5050 xp, sim lvl 47)
    { "complete", 591, at = { 1434, 52.93, 27.6 } }, -- The Mind's Eye (lvl 46, ~5050 xp, sim lvl 47)
    { "turnin", 591, xp = 5050 }, -- The Mind's Eye (lvl 46, ~5050 xp, sim lvl 47)
    { "accept", 592 }, -- Saving Yenniku (lvl 46, ~5050 xp, sim lvl 47)
    { "complete", 592, at = { 1434, 39.02, 58.35 } }, -- Saving Yenniku (lvl 46, ~5050 xp, sim lvl 47)
    { "complete", 8551, at = { 1434, 36.95, 69.73 } }, -- The Captain's Chest (lvl 47, ~3150 xp, sim lvl 47)
    { "accept", 594, at = { 1434, 33.79, 77.68 }, note = "Loot Carefully Folded Note to start the quest" }, -- Message in a Bottle (lvl 45, ~2900 xp, sim lvl 47)
    { "turnin", 594, xp = 2900 }, -- Message in a Bottle (lvl 45, ~2900 xp, sim lvl 47)
    { "accept", 630 }, -- Message in a Bottle (lvl 51, ~7350 xp, sim lvl 47)
    { "complete", 630, at = { 1434, 40.95, 83.9 } }, -- Message in a Bottle (lvl 51, ~7350 xp, sim lvl 47)
    { "turnin", 630, xp = 7350 }, -- Message in a Bottle (lvl 51, ~7350 xp, sim lvl 47)
    { "complete", 8554, at = { 1434, 32.45, 81.57 } }, -- Facing Negolash (lvl 50, ~7100 xp, sim lvl 47)
    { "turnin", 209, xp = 3450 }, -- Skullsplitter Tusks (lvl 42, ~3450 xp, sim lvl 47)
    { "turnin", 8554, xp = 7100 }, -- Facing Negolash (lvl 50, ~7100 xp, sim lvl 47)
    { "turnin", 8551, xp = 3150 }, -- The Captain's Chest (lvl 47, ~3150 xp, sim lvl 47)
    { "goto", 1434, 26.87, 77.1, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 20, note = "Grom'gol, Stranglethorn" }, -- vol
    { "turnin", 592, xp = 5050 }, -- Saving Yenniku (lvl 46, ~5050 xp, sim lvl 47)
    { "level", 49, at = { 1434, 32.45, 81.57 }, note = "About 525 more mobs near the last objective" }, -- farm de niveau
  },
})
