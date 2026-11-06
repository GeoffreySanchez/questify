local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 72 étapes, niveau final 46.00, ~54544 xp/h, 129 min.
Q:RegisterGuide({
  id = "A_19",
  title = "Feralas",
  faction = "Alliance",
  minLevel = 45, maxLevel = 46,
  next = "A_20",
  sim = { steps = 72, endLevel = 46.00, xpPerHour = 54544, minutes = 129 },
  steps = {
    { "note", "Not running Uldaman? Abandon The Shattered Necklace", optional = true, dungeon = "Uldaman" },
    { "fp", 1449, 45.23, 5.83 }, -- point de vol
    { "accept", 7003 }, -- Zapped Giants (lvl 48, ~4400 xp, sim lvl 45)
    { "accept", 7721 }, -- Fuel for the Zapping (lvl 48, ~4400 xp, sim lvl 45)
    { "accept", 2844 }, -- The Giant Guardian (lvl 49, ~3400 xp, sim lvl 45)
    { "turnin", 2844, xp = 3400 }, -- The Giant Guardian (lvl 49, ~3400 xp, sim lvl 45)
    { "accept", 2845 }, -- Wandering Shay (lvl 49, ~4550 xp, sim lvl 45)
    { "complete", 2845, obj = 1, at = { 1444, 38.25, 10.29 } }, -- Wandering Shay (lvl 49, ~4550 xp, sim lvl 45)
    { "complete", 2845, at = { 1444, 42.33, 21.85 } }, -- Wandering Shay (lvl 49, ~4550 xp, sim lvl 45)
    { "turnin", 2845, xp = 4550 }, -- Wandering Shay (lvl 49, ~4550 xp, sim lvl 45)
    { "accept", 2766, at = { 1444, 39.97, 23.28 }, note = "Loot OOX-22/FE Distress Beacon to start the quest" }, -- Find OOX-22/FE! (lvl 45, ~3900 xp, sim lvl 45)
    { "complete", 7003, at = { 1444, 38.68, 22.35 } }, -- Zapped Giants (lvl 48, ~4400 xp, sim lvl 45)
    { "fp", 1444, 30.24, 43.25 }, -- point de vol
    { "accept", 2821 }, -- The Mark of Quality (lvl 46, ~4050 xp, sim lvl 45)
    { "accept", 2866 }, -- The Ruins of Solarsal (lvl 43, ~2700 xp, sim lvl 45)
    { "accept", 4124 }, -- The Missing Courier (lvl 43, ~360 xp, sim lvl 45)
    { "turnin", 2866, xp = 2700 }, -- The Ruins of Solarsal (lvl 43, ~2700 xp, sim lvl 45)
    { "accept", 2867 }, -- Return to Feathermoon Stronghold (lvl 43, ~1800 xp, sim lvl 45)
    { "turnin", 2867, xp = 1800 }, -- Return to Feathermoon Stronghold (lvl 43, ~1800 xp, sim lvl 45)
    { "accept", 3130 }, -- Against the Hatecrest (lvl 43, ~360 xp, sim lvl 45)
    { "turnin", 3130, xp = 360 }, -- Against the Hatecrest (lvl 43, ~360 xp, sim lvl 45)
    { "accept", 2869 }, -- Against the Hatecrest (lvl 43, ~2700 xp, sim lvl 45)
    { "complete", 2869, at = { 1444, 27.75, 53.32 } }, -- Against the Hatecrest (lvl 43, ~2700 xp, sim lvl 45)
    { "turnin", 2869, xp = 2700 }, -- Against the Hatecrest (lvl 43, ~2700 xp, sim lvl 45)
    { "accept", 2870 }, -- Against Lord Shalzaru (lvl 45, ~2900 xp, sim lvl 45)
    { "turnin", 4124, xp = 360 }, -- The Missing Courier (lvl 43, ~360 xp, sim lvl 45)
    { "accept", 4125 }, -- The Missing Courier (lvl 43, ~2700 xp, sim lvl 45)
    { "accept", 2982 }, -- The High Wilderness (lvl 44, ~3750 xp, sim lvl 45)
    { "complete", 2870, at = { 1444, 28.5, 70.46 } }, -- Against Lord Shalzaru (lvl 45, ~2900 xp, sim lvl 45)
    { "turnin", 4125, xp = 2700 }, -- The Missing Courier (lvl 43, ~2700 xp, sim lvl 45)
    { "accept", 4127 }, -- Boat Wreckage (lvl 44, ~375 xp, sim lvl 45)
    { "complete", 2821, at = { 1444, 52.05, 58.58 } }, -- The Mark of Quality (lvl 46, ~4050 xp, sim lvl 45)
    { "turnin", 4127, xp = 375 }, -- Boat Wreckage (lvl 44, ~375 xp, sim lvl 45)
    { "accept", 4129 }, -- The Knife Revealed (lvl 44, ~375 xp, sim lvl 45)
    { "turnin", 4129, xp = 375 }, -- The Knife Revealed (lvl 44, ~375 xp, sim lvl 45)
    { "accept", 4130 }, -- Psychometric Reading (lvl 44, ~375 xp, sim lvl 45)
    { "turnin", 2821, xp = 4050 }, -- The Mark of Quality (lvl 46, ~4050 xp, sim lvl 45)
    { "accept", 7733 }, -- Improved Quality (lvl 48, ~4400 xp, sim lvl 45)
    { "turnin", 4130, xp = 375 }, -- Psychometric Reading (lvl 44, ~375 xp, sim lvl 45)
    { "accept", 4131 }, -- The Woodpaw Gnolls (lvl 44, ~2800 xp, sim lvl 45)
    { "complete", 7721, at = { 1444, 48.3, 52.09 } }, -- Fuel for the Zapping (lvl 48, ~4400 xp, sim lvl 45)
    { "turnin", 2766, xp = 3900 }, -- Find OOX-22/FE! (lvl 45, ~3900 xp, sim lvl 45)
    { "accept", 2767 }, -- Rescue OOX-22/FE! (lvl 45, ~0 xp, sim lvl 45)
    { "complete", 2982, obj = 2, at = { 1444, 60.16, 65.41 } }, -- The High Wilderness (lvl 44, ~3750 xp, sim lvl 45)
    { "complete", 2982, at = { 1444, 60.75, 56.39 } }, -- The High Wilderness (lvl 44, ~3750 xp, sim lvl 45)
    { "accept", 2969, note = "Timed quest: do it right away" }, -- Freedom for All Creatures (lvl 47, ~3150 xp, sim lvl 45)
    { "complete", 2969, at = { 1444, 67.27, 46.67 } }, -- Freedom for All Creatures (lvl 47, ~3150 xp, sim lvl 45)
    { "turnin", 2969, xp = 3150 }, -- Freedom for All Creatures (lvl 47, ~3150 xp, sim lvl 45)
    { "accept", 2970 }, -- Doling Justice (lvl 47, ~3150 xp, sim lvl 45)
    { "turnin", 4131, xp = 2800 }, -- The Woodpaw Gnolls (lvl 44, ~2800 xp, sim lvl 45)
    { "accept", 4281, at = { 1444, 73.32, 56.31 }, note = "Loot Undelivered Parcel to start the quest" }, -- Thalanaar Delivery (lvl 44, ~2800 xp, sim lvl 45)
    { "accept", 4135 }, -- The Writhing Deep (lvl 46, ~3050 xp, sim lvl 45)
    { "turnin", 4135, xp = 3050 }, -- The Writhing Deep (lvl 46, ~3050 xp, sim lvl 45)
    { "accept", 4265 }, -- Freed from the Hive (lvl 46, ~4050 xp, sim lvl 45)
    { "complete", 4265, at = { 1444, 72.13, 63.84 } }, -- Freed from the Hive (lvl 46, ~4050 xp, sim lvl 45)
    { "fp", 1444, 89.5, 45.85 }, -- point de vol
    { "turnin", 4281, xp = 2800 }, -- Thalanaar Delivery (lvl 44, ~2800 xp, sim lvl 45)
    { "complete", 2970, at = { 1444, 69.3, 39.27 } }, -- Doling Justice (lvl 47, ~3150 xp, sim lvl 45)
    { "turnin", 2970, xp = 3150 }, -- Doling Justice (lvl 47, ~3150 xp, sim lvl 45)
    { "complete", 7733, at = { 1444, 54.73, 32.76 } }, -- Improved Quality (lvl 48, ~4400 xp, sim lvl 45)
    { "complete", 2767, at = { 1444, 45.63, 43.39 } }, -- Rescue OOX-22/FE! (lvl 45, ~0 xp, sim lvl 45)
    { "turnin", 7721, xp = 4400 }, -- Fuel for the Zapping (lvl 48, ~4400 xp, sim lvl 45)
    { "turnin", 7003, xp = 4400 }, -- Zapped Giants (lvl 48, ~4400 xp, sim lvl 45)
    { "turnin", 4265, xp = 4050 }, -- Freed from the Hive (lvl 46, ~4050 xp, sim lvl 45)
    { "accept", 4266 }, -- A Hero's Welcome (lvl 46, ~6050 xp, sim lvl 45)
    { "turnin", 2982, xp = 3750 }, -- The High Wilderness (lvl 44, ~3750 xp, sim lvl 45)
    { "turnin", 2870, xp = 2900 }, -- Against Lord Shalzaru (lvl 45, ~2900 xp, sim lvl 45)
    { "accept", 2871 }, -- Delivering the Relic (lvl 45, ~3900 xp, sim lvl 45)
    { "turnin", 4266, xp = 6050 }, -- A Hero's Welcome (lvl 46, ~6050 xp, sim lvl 45)
    { "turnin", 2871, xp = 3900 }, -- Delivering the Relic (lvl 45, ~3900 xp, sim lvl 45)
    { "turnin", 7733, xp = 4400 }, -- Improved Quality (lvl 48, ~4400 xp, sim lvl 45)
    { "level", 46, at = { 1444, 36.59, 49.3 }, note = "About 4 more mobs here (Coast Crawl Snapclaw, level 44)" }, -- farm de niveau
  },
})
