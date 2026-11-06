local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 50 étapes, niveau final 40.00, ~33831 xp/h, 110 min.
Q:RegisterGuide({
  id = "A_13",
  title = "Arathi Highlands",
  faction = "Alliance",
  minLevel = 39, maxLevel = 40,
  next = "A_15",
  sim = { steps = 50, endLevel = 40.00, xpPerHour = 33831, minutes = 110 },
  steps = {
    { "boat", 1453, 69.6, 30.3, note = "Take the Deeprun Tram to Ironforge" }, -- bateau
    { "fp", 1455, 55.5, 47.74 }, -- point de vol
    { "fp", 1417, 45.73, 46.1 }, -- point de vol
    { "accept", 691 }, -- Worth Its Weight in Gold (lvl 36, ~3500 xp, sim lvl 39)
    { "accept", 684 }, -- WANTED: Marez Cowl (lvl 39, ~3750 xp, sim lvl 39)
    { "accept", 642 }, -- The Princess Trapped (lvl 37, ~2850 xp, sim lvl 39)
    { "turnin", 635, xp = 275 }, -- Crystal in the Mountains (lvl 35, ~275 xp, sim lvl 39)
    { "complete", 642, at = { 1417, 84.83, 32.17 } }, -- The Princess Trapped (lvl 37, ~2850 xp, sim lvl 39)
    { "turnin", 642, xp = 2850 }, -- The Princess Trapped (lvl 37, ~2850 xp, sim lvl 39)
    { "accept", 651 }, -- Stones of Binding (lvl 38, ~2850 xp, sim lvl 39)
    { "complete", 651, obj = 2, at = { 1417, 66.7, 29.72 } }, -- Stones of Binding (lvl 38, ~2850 xp, sim lvl 39)
    { "complete", 691, at = { 1417, 68.31, 80.15 } }, -- Worth Its Weight in Gold (lvl 36, ~3500 xp, sim lvl 39)
    { "complete", 651, obj = 3, at = { 1417, 52.04, 50.73 } }, -- Stones of Binding (lvl 38, ~2850 xp, sim lvl 39)
    { "turnin", 691, xp = 3500 }, -- Worth Its Weight in Gold (lvl 36, ~3500 xp, sim lvl 39)
    { "accept", 693 }, -- Wand over Fist (lvl 39, ~3000 xp, sim lvl 39)
    { "complete", 693, at = { 1417, 54.75, 81.87 } }, -- Wand over Fist (lvl 39, ~3000 xp, sim lvl 39)
    { "turnin", 693, xp = 3000 }, -- Wand over Fist (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 694 }, -- Trelane's Defenses (lvl 39, ~3000 xp, sim lvl 39)
    { "complete", 651, at = { 1417, 25.46, 30.11 } }, -- Stones of Binding (lvl 38, ~2850 xp, sim lvl 39)
    { "complete", 694, at = { 1417, 19.96, 67.41 } }, -- Trelane's Defenses (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 663 }, -- Land Ho! (lvl 35, ~690 xp, sim lvl 39)
    { "turnin", 663, xp = 690 }, -- Land Ho! (lvl 35, ~690 xp, sim lvl 39)
    { "accept", 665 }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 39)
    { "complete", 665, at = { 1417, 33.87, 80.6 } }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 39)
    { "turnin", 665, xp = 3150 }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 39)
    { "accept", 666 }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "turnin", 651, xp = 2850 }, -- Stones of Binding (lvl 38, ~2850 xp, sim lvl 39)
    { "accept", 652 }, -- Breaking the Keystone (lvl 42, ~3450 xp, sim lvl 39)
    { "turnin", 694, xp = 3000 }, -- Trelane's Defenses (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 695 }, -- An Apprentice's Enchantment (lvl 39, ~300 xp, sim lvl 39)
    { "turnin", 695, xp = 300 }, -- An Apprentice's Enchantment (lvl 39, ~300 xp, sim lvl 39)
    { "accept", 696 }, -- Attack on the Tower (lvl 39, ~3000 xp, sim lvl 39)
    { "complete", 652, at = { 1417, 63.9, 30 } }, -- Breaking the Keystone (lvl 42, ~3450 xp, sim lvl 39)
    { "turnin", 652, xp = 3450 }, -- Breaking the Keystone (lvl 42, ~3450 xp, sim lvl 39)
    { "accept", 653 }, -- Myzrael's Allies (lvl 40, ~0 xp, sim lvl 39)
    { "complete", 684, at = { 1417, 29.55, 63.55 } }, -- WANTED: Marez Cowl (lvl 39, ~3750 xp, sim lvl 39)
    { "complete", 696, at = { 1417, 18.18, 68.14 } }, -- Attack on the Tower (lvl 39, ~3000 xp, sim lvl 39)
    { "complete", 666, at = { 1417, 23.62, 88.25 } }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "turnin", 666, xp = 3900 }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "accept", 668 }, -- Sunken Treasure (lvl 40, ~1550 xp, sim lvl 39)
    { "turnin", 668, xp = 1550 }, -- Sunken Treasure (lvl 40, ~1550 xp, sim lvl 39)
    { "accept", 669 }, -- Sunken Treasure (lvl 40, ~0 xp, sim lvl 39)
    { "turnin", 684, xp = 3750 }, -- WANTED: Marez Cowl (lvl 39, ~3750 xp, sim lvl 39)
    { "turnin", 696, xp = 3000 }, -- Attack on the Tower (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 697 }, -- Malin's Request (lvl 39, ~0 xp, sim lvl 39)
    { "goto", 1417, 45.73, 46.1, note = "Flight master" }, -- déplacement
    { "fly", 1424, node = 14, note = "Southshore, Hillsbrad" }, -- vol
    { "turnin", 602, xp = 1400 }, -- Magical Analysis (lvl 37, ~1400 xp, sim lvl 39)
    { "accept", 96800, optional = true, dungeon = "Scarlet Monastery" }, -- Past Due (lvl 38, ~0 xp, sim lvl 39)
    { "level", 40, at = { 1417, 29.55, 63.55 }, note = "About 21 more mobs near the last objective" }, -- farm de niveau
  },
})
