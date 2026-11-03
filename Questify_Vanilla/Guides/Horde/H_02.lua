local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-03.
-- Simulation : 75 étapes, niveau final 21.34, ~25236 xp/h, 174 min.
Q:RegisterGuide({
  id = "H_02",
  title = "Stonetalon Mountains and The Barrens",
  faction = "Horde",
  minLevel = 17, maxLevel = 21,
  next = "H_03",
  steps = {
    { "hearth", 1413 }, -- pierre de foyer
    { "accept", 3281 }, -- Stolen Silver (lvl 18, ~1350 xp, sim lvl 17)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, note = "Ratchet, The Barrens" }, -- vol
    { "accept", 1483 }, -- Ziz Fizziks (lvl 21, ~415 xp, sim lvl 17)
    { "complete", 3281, at = { 1413, 58.04, 53.87 } }, -- Stolen Silver (lvl 18, ~1350 xp, sim lvl 17)
    { "accept", 884, at = { 1413, 49.4, 59.2 }, note = "Loot Owatanka's Tailspike to start the quest" }, -- Owatanka (lvl 24, ~1450 xp, sim lvl 17)
    { "turnin", 884, xp = 1450 }, -- Owatanka (lvl 24, ~1450 xp, sim lvl 17)
    { "sethearth", 1413, 45.58, 59.04 }, -- lier la pierre de foyer
    { "accept", 878 }, -- Tribes at War (lvl 21, ~1650 xp, sim lvl 18)
    { "complete", 878, obj = 1, at = { 1413, 45.69, 54.16 } }, -- Tribes at War (lvl 21, ~1650 xp, sim lvl 18)
    { "complete", 878, obj = 2, at = { 1413, 45.14, 51.55 } }, -- Tribes at War (lvl 21, ~1650 xp, sim lvl 18)
    { "complete", 878, at = { 1413, 43.26, 48.08 } }, -- Tribes at War (lvl 21, ~1650 xp, sim lvl 18)
    { "turnin", 878, xp = 1650 }, -- Tribes at War (lvl 21, ~1650 xp, sim lvl 18)
    { "accept", 5052 }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 18)
    { "accept", 843 }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 18)
    { "complete", 843, at = { 1413, 47.47, 85 } }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 18)
    { "complete", 5052, at = { 1413, 47.24, 84.86 } }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 18)
    { "turnin", 843, xp = 1850 }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 18)
    { "accept", 846 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 18)
    { "complete", 846, at = { 1413, 49.19, 84.17 } }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 18)
    { "turnin", 846, xp = 2100 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 19)
    { "accept", 849 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 19)
    { "hearth", 1413 }, -- pierre de foyer
    { "turnin", 5052, xp = 1250 }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 19)
    { "accept", 879 }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 19)
    { "complete", 879, obj = 3, at = { 1413, 40.15, 80.54 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 19)
    { "complete", 879, obj = 2, at = { 1413, 43.75, 83.26 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 19)
    { "complete", 849, at = { 1413, 46.97, 85.63 } }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 19)
    { "complete", 879, at = { 1413, 45.12, 80.07 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 19)
    { "turnin", 849, xp = 2100 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 19)
    { "turnin", 879, xp = 1500 }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 19)
    { "accept", 906 }, -- Betrayal from Within (lvl 25, ~3050 xp, sim lvl 19)
    { "turnin", 1060, xp = 1550 }, -- Letter to Jin'Zil (lvl 20, ~1550 xp, sim lvl 19)
    { "accept", 6542 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 19)
    { "accept", 6284 }, -- Arachnophobia (lvl 21, ~1650 xp, sim lvl 19)
    { "level", 20, at = { 1442, 53.6, 72.73 }, note = "About 55 mobs here (Cat, level 18)" }, -- farm de niveau
    { "complete", 6284, at = { 1442, 53.25, 72.55 } }, -- Arachnophobia (lvl 21, ~1650 xp, sim lvl 20)
    { "turnin", 1483, xp = 415 }, -- Ziz Fizziks (lvl 21, ~415 xp, sim lvl 20)
    { "accept", 1093 }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 20)
    { "complete", 1093, at = { 1442, 62.38, 53.01 } }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 20)
    { "turnin", 1093, xp = 1650 }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 20)
    { "accept", 1094 }, -- Further Instructions (lvl 21, ~830 xp, sim lvl 20)
    { "accept", 6523 }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 20)
    { "complete", 6523, at = { 1442, 77.1, 90.85 } }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 20)
    { "turnin", 6523, xp = 1350 }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 20)
    { "accept", 6401 }, -- Kaya's Alive (lvl 18, ~1000 xp, sim lvl 20)
    { "accept", 1487, optional = true, dungeon = "Wailing Caverns" }, -- Deviate Eradication (lvl 21, ~0 xp, sim lvl 20)
    { "turnin", 906, xp = 3050 }, -- Betrayal from Within (lvl 25, ~3050 xp, sim lvl 20)
    { "turnin", 3281, xp = 1350 }, -- Stolen Silver (lvl 18, ~1350 xp, sim lvl 20)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, note = "Ratchet, The Barrens" }, -- vol
    { "turnin", 1094, xp = 830 }, -- Further Instructions (lvl 21, ~830 xp, sim lvl 20)
    { "accept", 1095 }, -- Further Instructions (lvl 27, ~1100 xp, sim lvl 20)
    { "fly", 1413, note = "Crossroads, The Barrens" }, -- vol
    { "turnin", 6542, xp = 145 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 20)
    { "turnin", 1095, xp = 1100 }, -- Further Instructions (lvl 27, ~1100 xp, sim lvl 20)
    { "accept", 1096 }, -- Gerenzo Wrenchwhistle (lvl 27, ~2200 xp, sim lvl 20)
    { "fp", 1442, 45.12, 59.84 }, -- point de vol
    { "accept", 6282 }, -- Harpies Threaten (lvl 26, ~2100 xp, sim lvl 20)
    { "accept", 1087 }, -- Cenarius' Legacy (lvl 25, ~1500 xp, sim lvl 20)
    { "complete", 6282, at = { 1442, 36.82, 67.37 } }, -- Harpies Threaten (lvl 26, ~2100 xp, sim lvl 20)
    { "complete", 6282, at = { 1442, 32.24, 59.97 } }, -- Harpies Threaten (lvl 26, ~2100 xp, sim lvl 20)
    { "accept", 79980 }, -- Scramble (lvl 24, ~970 xp, sim lvl 20)
    { "turnin", 79980, xp = 970 }, -- Scramble (lvl 24, ~970 xp, sim lvl 20)
    { "complete", 1087, at = { 1442, 36.18, 12.84 } }, -- Cenarius' Legacy (lvl 25, ~1500 xp, sim lvl 20)
    { "complete", 1096, at = { 1442, 64.49, 40.25 } }, -- Gerenzo Wrenchwhistle (lvl 27, ~2200 xp, sim lvl 20)
    { "turnin", 1096, xp = 2200 }, -- Gerenzo Wrenchwhistle (lvl 27, ~2200 xp, sim lvl 20)
    { "turnin", 6284, xp = 1650 }, -- Arachnophobia (lvl 21, ~1650 xp, sim lvl 20)
    { "turnin", 6282, xp = 2100 }, -- Harpies Threaten (lvl 26, ~2100 xp, sim lvl 21)
    { "accept", 6283 }, -- Bloodfury Bloodline (lvl 26, ~2100 xp, sim lvl 21)
    { "complete", 6283, at = { 1442, 30.75, 61.91 } }, -- Bloodfury Bloodline (lvl 26, ~2100 xp, sim lvl 21)
    { "turnin", 1087, xp = 1500 }, -- Cenarius' Legacy (lvl 25, ~1500 xp, sim lvl 21)
    { "turnin", 6283, xp = 2100 }, -- Bloodfury Bloodline (lvl 26, ~2100 xp, sim lvl 21)
    { "turnin", 6401, xp = 1000 }, -- Kaya's Alive (lvl 18, ~1000 xp, sim lvl 21)
  },
})
