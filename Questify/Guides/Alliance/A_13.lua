local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 38 étapes, niveau final 40.15, ~33753 xp/h, 82 min.
Q:RegisterGuide({
  id = "A_13",
  title = "Arathi Highlands",
  faction = "Alliance",
  minLevel = 39, maxLevel = 40,
  next = "A_15",
  sim = { steps = 38, endLevel = 40.15, xpPerHour = 33753, minutes = 82 },
  steps = {
    { "goto", 1433, 25.5, 59.41, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "boat", 1453, 69.6, 30.3, note = "Take the Deeprun Tram to Ironforge" }, -- bateau
    { "fp", 1455, 55.5, 47.74 }, -- point de vol
    { "fp", 1417, 45.73, 46.1 }, -- point de vol
    { "accept", 691 }, -- Worth Its Weight in Gold (lvl 36, ~3500 xp, sim lvl 39)
    { "accept", 684 }, -- WANTED: Marez Cowl (lvl 39, ~3750 xp, sim lvl 39)
    { "accept", 685 }, -- WANTED: Otto and Falconcrest (lvl 40, ~3900 xp, sim lvl 39)
    { "turnin", 635, xp = 275 }, -- Crystal in the Mountains (lvl 35, ~275 xp, sim lvl 39)
    { "complete", 691, at = { 1417, 68.31, 80.15 } }, -- Worth Its Weight in Gold (lvl 36, ~3500 xp, sim lvl 39)
    { "turnin", 691, xp = 3500 }, -- Worth Its Weight in Gold (lvl 36, ~3500 xp, sim lvl 39)
    { "accept", 693 }, -- Wand over Fist (lvl 39, ~3000 xp, sim lvl 39)
    { "complete", 693, at = { 1417, 54.75, 81.87 } }, -- Wand over Fist (lvl 39, ~3000 xp, sim lvl 39)
    { "turnin", 693, xp = 3000 }, -- Wand over Fist (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 694 }, -- Trelane's Defenses (lvl 39, ~3000 xp, sim lvl 39)
    { "accept", 663 }, -- Land Ho! (lvl 35, ~690 xp, sim lvl 39)
    { "turnin", 663, xp = 690 }, -- Land Ho! (lvl 35, ~690 xp, sim lvl 39)
    { "accept", 662 }, -- Deep Sea Salvage (lvl 40, ~3150 xp, sim lvl 39)
    { "accept", 665 }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 39)
    { "complete", 665, at = { 1417, 33.87, 80.6 } }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 39)
    { "turnin", 665, xp = 3150 }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 39)
    { "accept", 666 }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "complete", 662, at = { 1417, 23.05, 84.51 } }, -- Deep Sea Salvage (lvl 40, ~3150 xp, sim lvl 39)
    { "complete", 666, at = { 1417, 23.62, 88.25 } }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "turnin", 662, xp = 3150 }, -- Deep Sea Salvage (lvl 40, ~3150 xp, sim lvl 39)
    { "turnin", 666, xp = 3900 }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "accept", 668 }, -- Sunken Treasure (lvl 40, ~1550 xp, sim lvl 39)
    { "turnin", 668, xp = 1550 }, -- Sunken Treasure (lvl 40, ~1550 xp, sim lvl 39)
    { "complete", 694, at = { 1417, 19.96, 67.41 } }, -- Trelane's Defenses (lvl 39, ~3000 xp, sim lvl 40)
    { "complete", 685, at = { 1417, 26.22, 65.55 } }, -- WANTED: Otto and Falconcrest (lvl 40, ~3900 xp, sim lvl 40)
    { "complete", 684, at = { 1417, 29.55, 63.55 } }, -- WANTED: Marez Cowl (lvl 39, ~3750 xp, sim lvl 40)
    { "turnin", 694, xp = 3000 }, -- Trelane's Defenses (lvl 39, ~3000 xp, sim lvl 40)
    { "turnin", 685, xp = 3900 }, -- WANTED: Otto and Falconcrest (lvl 40, ~3900 xp, sim lvl 40)
    { "turnin", 684, xp = 3750 }, -- WANTED: Marez Cowl (lvl 39, ~3750 xp, sim lvl 40)
    { "goto", 1417, 45.73, 46.1, note = "Flight master" }, -- déplacement
    { "fly", 1424, node = 14, note = "Southshore, Hillsbrad" }, -- vol
    { "turnin", 602, xp = 1400 }, -- Magical Analysis (lvl 37, ~1400 xp, sim lvl 40)
    { "accept", 96800, optional = true, dungeon = "Scarlet Monastery" }, -- Past Due (lvl 38, ~0 xp, sim lvl 40)
  },
})
