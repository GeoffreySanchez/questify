local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 48 étapes, niveau final 42.00, ~43041 xp/h, 133 min.
Q:RegisterGuide({
  id = "A_16",
  title = "Badlands",
  faction = "Alliance",
  minLevel = 41, maxLevel = 42,
  next = "A_17",
  sim = { steps = 48, endLevel = 42.00, xpPerHour = 43041, minutes = 133 },
  steps = {
    { "hearth", 1434 }, -- pierre de foyer
    { "goto", 1434, 27.53, 77.79, note = "Flight master" }, -- déplacement
    { "fly", 1455, node = 6, note = "Ironforge, Dun Morogh" }, -- vol
    { "fp", 1432, 33.94, 50.95 }, -- point de vol
    { "accept", 710 }, -- Study of the Elements: Rock (lvl 37, ~2850 xp, sim lvl 41)
    { "complete", 710, at = { 1418, 20.96, 45.07 } }, -- Study of the Elements: Rock (lvl 37, ~2850 xp, sim lvl 41)
    { "turnin", 710, xp = 2850 }, -- Study of the Elements: Rock (lvl 37, ~2850 xp, sim lvl 41)
    { "accept", 711 }, -- Study of the Elements: Rock (lvl 39, ~3000 xp, sim lvl 41)
    { "accept", 703 }, -- Barbecued Buzzard Wings (lvl 40, ~2350 xp, sim lvl 41)
    { "accept", 2418, optional = true, dungeon = "Uldaman" }, -- Power Stones (lvl 36, ~0 xp, sim lvl 41)
    { "accept", 719 }, -- A Dwarf and His Tools (lvl 35, ~2200 xp, sim lvl 41)
    { "accept", 718 }, -- Mirages (lvl 38, ~2150 xp, sim lvl 41)
    { "accept", 79951 }, -- Mummies: A Guide to the Unsavory Undead (lvl 35, ~2200 xp, sim lvl 41)
    { "complete", 79951, at = { 1418, 56.7, 39.9 } }, -- Mummies: A Guide to the Unsavory Undead (lvl 35, ~2200 xp, sim lvl 41)
    { "complete", 718, at = { 1418, 66.6, 22 } }, -- Mirages (lvl 38, ~2150 xp, sim lvl 41)
    { "complete", 719, at = { 1418, 53.23, 32.73 } }, -- A Dwarf and His Tools (lvl 35, ~2200 xp, sim lvl 41)
    { "accept", 720 }, -- A Sign of Hope (lvl 35, ~1080 xp, sim lvl 41)
    { "turnin", 718, xp = 2150 }, -- Mirages (lvl 38, ~2150 xp, sim lvl 41)
    { "accept", 733 }, -- Scrounging (lvl 40, ~3150 xp, sim lvl 41)
    { "turnin", 720, xp = 1080 }, -- A Sign of Hope (lvl 35, ~1080 xp, sim lvl 41)
    { "turnin", 719, xp = 2200 }, -- A Dwarf and His Tools (lvl 35, ~2200 xp, sim lvl 41)
    { "accept", 721, optional = true, dungeon = "Uldaman" }, -- A Sign of Hope (lvl 35, ~0 xp, sim lvl 41)
    { "accept", 732 }, -- Tremors of the Earth (lvl 43, ~3600 xp, sim lvl 41)
    { "accept", 709, optional = true, dungeon = "Uldaman" }, -- Solution to Doom (lvl 40, ~0 xp, sim lvl 41)
    { "complete", 711, at = { 1418, 42.98, 80.83 } }, -- Study of the Elements: Rock (lvl 39, ~3000 xp, sim lvl 41)
    { "turnin", 711, xp = 3000 }, -- Study of the Elements: Rock (lvl 39, ~3000 xp, sim lvl 41)
    { "accept", 712 }, -- Study of the Elements: Rock (lvl 42, ~3450 xp, sim lvl 41)
    { "complete", 703, at = { 1418, 15.71, 60.94 } }, -- Barbecued Buzzard Wings (lvl 40, ~2350 xp, sim lvl 41)
    { "complete", 712, at = { 1418, 3.82, 80.28 } }, -- Study of the Elements: Rock (lvl 42, ~3450 xp, sim lvl 41)
    { "complete", 733, at = { 1418, 11.41, 76.2 } }, -- Scrounging (lvl 40, ~3150 xp, sim lvl 41)
    { "complete", 732, at = { 1418, 12.62, 75.49 } }, -- Tremors of the Earth (lvl 43, ~3600 xp, sim lvl 41)
    { "turnin", 712, xp = 3450 }, -- Study of the Elements: Rock (lvl 42, ~3450 xp, sim lvl 41)
    { "turnin", 703, xp = 2350 }, -- Barbecued Buzzard Wings (lvl 40, ~2350 xp, sim lvl 41)
    { "turnin", 732, xp = 3600 }, -- Tremors of the Earth (lvl 43, ~3600 xp, sim lvl 41)
    { "turnin", 733, xp = 3150 }, -- Scrounging (lvl 40, ~3150 xp, sim lvl 41)
    { "accept", 2198, at = { 1418, 47.68, 11.24 }, optional = true, dungeon = "Uldaman", note = "Loot Shattered Necklace to start the quest" }, -- The Shattered Necklace (lvl 41, ~0 xp, sim lvl 41)
    { "goto", 1432, 33.94, 50.95, note = "Flight master" }, -- déplacement
    { "fly", 1455, node = 6, note = "Ironforge, Dun Morogh" }, -- vol
    { "turnin", 653, xp = 2350 }, -- Myzrael's Allies (lvl 40, ~2350 xp, sim lvl 41)
    { "goto", 1455, 55.5, 47.74, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "turnin", 79952, xp = 2200 }, -- RwlRwlRwlRwl! (lvl 35, ~2200 xp, sim lvl 41)
    { "turnin", 79949, xp = 2200 }, -- A Web of Lies: Debunking Myths and Legends (lvl 35, ~2200 xp, sim lvl 41)
    { "turnin", 79951, xp = 2200 }, -- Mummies: A Guide to the Unsavory Undead (lvl 35, ~2200 xp, sim lvl 41)
    { "turnin", 697, xp = 3750 }, -- Malin's Request (lvl 39, ~3750 xp, sim lvl 41)
    { "hearth", 1434 }, -- pierre de foyer
    { "turnin", 669, xp = 3150 }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 41)
    { "level", 42, at = { 1434, 27.13, 82.94 }, note = "About 97 more mobs here (Bloodsail Swashbuckler, level 42)" }, -- farm de niveau
  },
})
