local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 78 étapes, niveau final 56.00, ~59245 xp/h, 359 min.
Q:RegisterGuide({
  id = "A_26",
  title = "Un'Goro Crater",
  faction = "Alliance",
  minLevel = 54, maxLevel = 56,
  next = "A_27",
  sim = { steps = 78, endLevel = 56.00, xpPerHour = 59245, minutes = 359 },
  steps = {
    { "hearth", 1446 }, -- pierre de foyer
    { "goto", 1446, 51.01, 29.34, note = "Flight master" }, -- déplacement
    { "fly", 1449, node = 79, note = "Marshal's Refuge, Un'Goro Crater" }, -- vol
    { "accept", 4284 }, -- Crystals of Power (lvl 53, ~5250 xp, sim lvl 54)
    { "accept", 3881 }, -- Expedition Salvation (lvl 53, ~3950 xp, sim lvl 54)
    { "accept", 3883 }, -- Alien Ecology (lvl 52, ~2550 xp, sim lvl 54)
    { "accept", 3882 }, -- Roll the Bones (lvl 51, ~4900 xp, sim lvl 54)
    { "accept", 4492 }, -- Lost! (lvl 55, ~2800 xp, sim lvl 54)
    { "accept", 4501 }, -- Beware of Pterrordax (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 4141 }, -- Muigin and Larion (lvl 52, ~5100 xp, sim lvl 54)
    { "complete", 4492, at = { 1449, 43.71, 8.29 } }, -- Lost! (lvl 55, ~2800 xp, sim lvl 54)
    { "accept", 4503 }, -- Shizzle's Flyer (lvl 51, ~4900 xp, sim lvl 54)
    { "accept", 4243 }, -- Chasing A-Me 01 (lvl 53, ~2650 xp, sim lvl 54)
    { "complete", 4501, obj = 2, at = { 1449, 41.02, 29.78 } }, -- Beware of Pterrordax (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 974 }, -- Finding the Source (lvl 55, ~5650 xp, sim lvl 54)
    { "complete", 3881, obj = 2, at = { 1449, 38.45, 66.06 } }, -- Expedition Salvation (lvl 53, ~3950 xp, sim lvl 54)
    { "complete", 3883, at = { 1449, 48.69, 85.32 } }, -- Alien Ecology (lvl 52, ~2550 xp, sim lvl 54)
    { "complete", 4503, obj = 2, at = { 1449, 57.08, 88.97 } }, -- Shizzle's Flyer (lvl 51, ~4900 xp, sim lvl 54)
    { "accept", 4289 }, -- The Apes of Un'Goro (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 4290 }, -- The Fare of Lar'korwi (lvl 53, ~5250 xp, sim lvl 54)
    { "complete", 4284, at = { 1449, 73.61, 63.55 } }, -- Crystals of Power (lvl 53, ~5250 xp, sim lvl 54)
    { "complete", 4290, at = { 1449, 68.74, 56.71 } }, -- The Fare of Lar'korwi (lvl 53, ~5250 xp, sim lvl 54)
    { "complete", 3881, at = { 1449, 68.54, 36.54 } }, -- Expedition Salvation (lvl 53, ~3950 xp, sim lvl 54)
    { "turnin", 4243, xp = 2650 }, -- Chasing A-Me 01 (lvl 53, ~2650 xp, sim lvl 54)
    { "accept", 3884, at = { 1449, 67.41, 15.55 }, note = "Loot A Mangled Journal to start the quest" }, -- Williden's Journal (lvl 50, ~3550 xp, sim lvl 54)
    { "complete", 4289, at = { 1449, 67.39, 15.6 } }, -- The Apes of Un'Goro (lvl 55, ~5650 xp, sim lvl 54)
    { "complete", 4501, at = { 1449, 56.96, 10.21 } }, -- Beware of Pterrordax (lvl 55, ~5650 xp, sim lvl 54)
    { "turnin", 3881, xp = 3950 }, -- Expedition Salvation (lvl 53, ~3950 xp, sim lvl 54)
    { "turnin", 3884, xp = 3550 }, -- Williden's Journal (lvl 50, ~3550 xp, sim lvl 54)
    { "turnin", 3883, xp = 2550 }, -- Alien Ecology (lvl 52, ~2550 xp, sim lvl 54)
    { "turnin", 4501, xp = 5650 }, -- Beware of Pterrordax (lvl 55, ~5650 xp, sim lvl 54)
    { "turnin", 4284, xp = 5250 }, -- Crystals of Power (lvl 53, ~5250 xp, sim lvl 54)
    { "accept", 4285 }, -- The Northern Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "accept", 4287 }, -- The Eastern Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "accept", 4288 }, -- The Western Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "complete", 4285, at = { 1449, 56.52, 12.54 } }, -- The Northern Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "complete", 974, at = { 1449, 49.69, 45.64 } }, -- Finding the Source (lvl 55, ~5650 xp, sim lvl 54)
    { "turnin", 4492, xp = 2800 }, -- Lost! (lvl 55, ~2800 xp, sim lvl 54)
    { "accept", 4491 }, -- A Little Help From My Friends (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 3844 }, -- It's a Secret to Everybody (lvl 52, ~1250 xp, sim lvl 54)
    { "turnin", 3844, xp = 1250 }, -- It's a Secret to Everybody (lvl 52, ~1250 xp, sim lvl 54)
    { "turnin", 4290, xp = 5250 }, -- The Fare of Lar'korwi (lvl 53, ~5250 xp, sim lvl 54)
    { "accept", 4291 }, -- The Scent of Lar'korwi (lvl 53, ~5250 xp, sim lvl 54)
    { "turnin", 4289, xp = 5650 }, -- The Apes of Un'Goro (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 4301 }, -- The Mighty U'cha (lvl 55, ~5650 xp, sim lvl 54)
    { "complete", 4291, at = { 1449, 66.5, 66.5 } }, -- The Scent of Lar'korwi (lvl 53, ~5250 xp, sim lvl 54)
    { "turnin", 4291, xp = 5250 }, -- The Scent of Lar'korwi (lvl 53, ~5250 xp, sim lvl 54)
    { "accept", 4292 }, -- The Bait for Lar'korwi (lvl 56, ~7300 xp, sim lvl 54)
    { "complete", 4141, at = { 1449, 68.8, 29.53 } }, -- Muigin and Larion (lvl 52, ~5100 xp, sim lvl 54)
    { "complete", 4301, at = { 1449, 68.14, 12.56 } }, -- The Mighty U'cha (lvl 55, ~5650 xp, sim lvl 54)
    { "complete", 4287, at = { 1449, 77.16, 49.98 } }, -- The Eastern Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "complete", 4292, at = { 1449, 79.65, 49.83 } }, -- The Bait for Lar'korwi (lvl 56, ~7300 xp, sim lvl 54)
    { "turnin", 4301, xp = 5650 }, -- The Mighty U'cha (lvl 55, ~5650 xp, sim lvl 54)
    { "turnin", 4292, xp = 7300 }, -- The Bait for Lar'korwi (lvl 56, ~7300 xp, sim lvl 54)
    { "complete", 4503, at = { 1449, 50.63, 63.36 } }, -- Shizzle's Flyer (lvl 51, ~4900 xp, sim lvl 54)
    { "complete", 3882, at = { 1449, 32.12, 75.49 } }, -- Roll the Bones (lvl 51, ~4900 xp, sim lvl 54)
    { "complete", 4288, at = { 1449, 23.86, 59.19 } }, -- The Western Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "turnin", 974, xp = 5650 }, -- Finding the Source (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 980 }, -- The New Springs (lvl 55, ~2800 xp, sim lvl 54)
    { "turnin", 4503, xp = 4900 }, -- Shizzle's Flyer (lvl 51, ~4900 xp, sim lvl 54)
    { "turnin", 4141, xp = 5100 }, -- Muigin and Larion (lvl 52, ~5100 xp, sim lvl 54)
    { "turnin", 3882, xp = 4900 }, -- Roll the Bones (lvl 51, ~4900 xp, sim lvl 54)
    { "complete", 4491, at = { 1449, 43.71, 8.29 } }, -- A Little Help From My Friends (lvl 55, ~5650 xp, sim lvl 54)
    { "turnin", 4491, xp = 5650 }, -- A Little Help From My Friends (lvl 55, ~5650 xp, sim lvl 54)
    { "turnin", 4285, xp = 3950 }, -- The Northern Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "turnin", 4288, xp = 3950 }, -- The Western Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "turnin", 4287, xp = 3950 }, -- The Eastern Pylon (lvl 53, ~3950 xp, sim lvl 54)
    { "accept", 4321 }, -- Making Sense of It (lvl 53, ~530 xp, sim lvl 54)
    { "turnin", 4321, xp = 530 }, -- Making Sense of It (lvl 53, ~530 xp, sim lvl 54)
    { "goto", 1449, 45.23, 5.83, note = "Flight master" }, -- déplacement
    { "fly", 1448, node = 65, note = "Talonbranch Glade, Felwood" }, -- vol
    { "turnin", 980, xp = 2800 }, -- The New Springs (lvl 55, ~2800 xp, sim lvl 54)
    { "turnin", 5083, xp = 2900 }, -- Winterfall Firewater (lvl 56, ~2900 xp, sim lvl 54)
    { "turnin", 8465, xp = 560 }, -- Speak to Salfa (lvl 55, ~560 xp, sim lvl 54)
    { "turnin", 5249, xp = 580 }, -- To Winterspring! (lvl 56, ~580 xp, sim lvl 54)
    { "fp", 1452, 62.33, 36.61 }, -- point de vol
    { "turnin", 4808, xp = 2700 }, -- Felnok Steelspring (lvl 54, ~2700 xp, sim lvl 54)
    { "level", 56, at = { 1452, 66.83, 42.67 }, note = "About 633 more mobs here (Ice Thistle Yeti, level 55)" }, -- farm de niveau
  },
})
