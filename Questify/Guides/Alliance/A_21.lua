local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 20 étapes, niveau final 50.00, ~63643 xp/h, 260 min.
Q:RegisterGuide({
  id = "A_21",
  title = "Stranglethorn Vale",
  faction = "Alliance",
  minLevel = 48, maxLevel = 50,
  next = "A_22",
  sim = { steps = 20, endLevel = 50.00, xpPerHour = 63643, minutes = 260 },
  steps = {
    { "hearth", 1446 }, -- pierre de foyer
    { "goto", 1446, 51.01, 29.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 80, note = "Ratchet, The Barrens" }, -- vol
    { "boat", 1413, 63.54, 38.61, note = "Take the boat to Booty Bay (Stranglethorn Vale)" }, -- bateau
    { "accept", 8552, at = { 1434, 23.25, 72.1 }, note = "Loot Monogrammed Sash to start the quest" }, -- The Monogrammed Sash (lvl 50, ~2350 xp, sim lvl 48)
    { "turnin", 8552, xp = 2350 }, -- The Monogrammed Sash (lvl 50, ~2350 xp, sim lvl 48)
    { "accept", 8553 }, -- The Captain's Cutlass (lvl 50, ~470 xp, sim lvl 48)
    { "turnin", 8553, xp = 470 }, -- The Captain's Cutlass (lvl 50, ~470 xp, sim lvl 48)
    { "accept", 8554 }, -- Facing Negolash (lvl 50, ~7100 xp, sim lvl 48)
    { "turnin", 648, xp = 5450 }, -- Rescue OOX-17/TN! (lvl 48, ~5450 xp, sim lvl 48)
    { "turnin", 2767, xp = 4850 }, -- Rescue OOX-22/FE! (lvl 45, ~4850 xp, sim lvl 48)
    { "turnin", 2874, xp = 3900 }, -- Deliver to MacKinley (lvl 45, ~3900 xp, sim lvl 48)
    { "accept", 594, at = { 1434, 33.79, 77.68 }, note = "Loot Carefully Folded Note to start the quest" }, -- Message in a Bottle (lvl 45, ~2900 xp, sim lvl 48)
    { "turnin", 594, xp = 2900 }, -- Message in a Bottle (lvl 45, ~2900 xp, sim lvl 48)
    { "accept", 630 }, -- Message in a Bottle (lvl 51, ~7350 xp, sim lvl 48)
    { "complete", 630, at = { 1434, 40.95, 83.9 } }, -- Message in a Bottle (lvl 51, ~7350 xp, sim lvl 48)
    { "turnin", 630, xp = 7350 }, -- Message in a Bottle (lvl 51, ~7350 xp, sim lvl 48)
    { "complete", 8554, at = { 1434, 32.45, 81.57 } }, -- Facing Negolash (lvl 50, ~7100 xp, sim lvl 48)
    { "turnin", 8554, xp = 7100 }, -- Facing Negolash (lvl 50, ~7100 xp, sim lvl 48)
    { "level", 50, at = { 1434, 32.45, 81.57 }, note = "About 708 more mobs near the last objective" }, -- farm de niveau
  },
})
