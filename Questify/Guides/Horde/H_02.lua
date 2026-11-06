local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 78 étapes, niveau final 21.26, ~27042 xp/h, 154 min.
Q:RegisterGuide({
  id = "H_02",
  title = "Stonetalon Mountains and The Barrens",
  faction = "Horde",
  minLevel = 17, maxLevel = 21,
  next = "H_03",
  sim = { steps = 78, endLevel = 21.26, xpPerHour = 27042, minutes = 154 },
  steps = {
    { "accept", 6541 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 18)
    { "accept", 905 }, -- The Angry Scytheclaws (lvl 17, ~1250 xp, sim lvl 18)
    { "complete", 905, at = { 1413, 52.6, 46.11 } }, -- The Angry Scytheclaws (lvl 17, ~1250 xp, sim lvl 18)
    { "turnin", 905, xp = 1250 }, -- The Angry Scytheclaws (lvl 17, ~1250 xp, sim lvl 18)
    { "accept", 3261 }, -- Jorn Skyseer (lvl 18, ~135 xp, sim lvl 18)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 77, note = "Camp Taurajo, The Barrens" }, -- vol
    { "turnin", 3261, xp = 135 }, -- Jorn Skyseer (lvl 18, ~135 xp, sim lvl 18)
    { "accept", 882 }, -- Ishamuhale (lvl 19, ~1800 xp, sim lvl 18)
    { "accept", 5052 }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 18)
    { "turnin", 1060, xp = 1550 }, -- Letter to Jin'Zil (lvl 20, ~1550 xp, sim lvl 18)
    { "accept", 6542 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 18)
    { "accept", 6523 }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 18)
    { "complete", 6523, at = { 1442, 77.1, 90.85 } }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 18)
    { "turnin", 1483, xp = 415 }, -- Ziz Fizziks (lvl 21, ~415 xp, sim lvl 18)
    { "accept", 1093 }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 18)
    { "complete", 1093, at = { 1442, 62.38, 53.01 } }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 18)
    { "turnin", 1093, xp = 1650 }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 18)
    { "accept", 1094 }, -- Further Instructions (lvl 21, ~830 xp, sim lvl 18)
    { "accept", 1090 }, -- Gerenzo's Orders (lvl 22, ~2200 xp, sim lvl 18)
    { "complete", 1090, at = { 1442, 71.87, 60 } }, -- Gerenzo's Orders (lvl 22, ~2200 xp, sim lvl 18)
    { "turnin", 1090, xp = 2200 }, -- Gerenzo's Orders (lvl 22, ~2200 xp, sim lvl 18)
    { "accept", 1092 }, -- Gerenzo's Orders (lvl 22, ~1300 xp, sim lvl 18)
    { "turnin", 6541, xp = 145 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 18)
    { "turnin", 6542, xp = 145 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 18)
    { "hearth", 1413 }, -- pierre de foyer
    { "complete", 882, at = { 1413, 59.8, 30.6 } }, -- Ishamuhale (lvl 19, ~1800 xp, sim lvl 18)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 77, note = "Camp Taurajo, The Barrens" }, -- vol
    { "turnin", 882, xp = 1800 }, -- Ishamuhale (lvl 19, ~1800 xp, sim lvl 18)
    { "accept", 907 }, -- Enraged Thunder Lizards (lvl 18, ~1700 xp, sim lvl 18)
    { "accept", 884, at = { 1413, 49.4, 59.2 }, note = "Loot Owatanka's Tailspike to start the quest" }, -- Owatanka (lvl 24, ~1450 xp, sim lvl 18)
    { "complete", 907, at = { 1413, 49.33, 59.83 } }, -- Enraged Thunder Lizards (lvl 18, ~1700 xp, sim lvl 18)
    { "accept", 843 }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 18)
    { "complete", 5052, at = { 1413, 47.24, 84.86 } }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 18)
    { "complete", 843, at = { 1413, 47.47, 85 } }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 18)
    { "turnin", 843, xp = 1850 }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 19)
    { "accept", 846 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 19)
    { "turnin", 5052, xp = 1250 }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 19)
    { "accept", 879 }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 19)
    { "turnin", 907, xp = 1700 }, -- Enraged Thunder Lizards (lvl 18, ~1700 xp, sim lvl 19)
    { "accept", 913 }, -- Cry of the Thunderhawk (lvl 20, ~1950 xp, sim lvl 19)
    { "turnin", 884, xp = 1450 }, -- Owatanka (lvl 24, ~1450 xp, sim lvl 19)
    { "complete", 913, at = { 1413, 48.97, 55.85 } }, -- Cry of the Thunderhawk (lvl 20, ~1950 xp, sim lvl 19)
    { "fp", 1445, 35.56, 31.88 }, -- point de vol
    { "complete", 846, at = { 1413, 49.19, 84.17 } }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 19)
    { "turnin", 846, xp = 2100 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 20)
    { "accept", 849 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 20)
    { "complete", 879, obj = 1, at = { 1413, 45.12, 80.07 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 20)
    { "complete", 849, at = { 1413, 46.97, 85.63 } }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 20)
    { "complete", 879, obj = 2, at = { 1413, 43.75, 83.26 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 20)
    { "complete", 879, at = { 1413, 40.15, 80.54 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 20)
    { "turnin", 849, xp = 2100 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 20)
    { "turnin", 879, xp = 1500 }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 20)
    { "accept", 906 }, -- Betrayal from Within (lvl 25, ~3050 xp, sim lvl 20)
    { "turnin", 913, xp = 1950 }, -- Cry of the Thunderhawk (lvl 20, ~1950 xp, sim lvl 20)
    { "accept", 874 }, -- Mahren Skyseer (lvl 27, ~550 xp, sim lvl 20)
    { "hearth", 1413 }, -- pierre de foyer
    { "turnin", 874, xp = 550 }, -- Mahren Skyseer (lvl 27, ~550 xp, sim lvl 20)
    { "turnin", 1094, xp = 830 }, -- Further Instructions (lvl 21, ~830 xp, sim lvl 20)
    { "accept", 1095 }, -- Further Instructions (lvl 27, ~1100 xp, sim lvl 20)
    { "fly", 1413, node = 25, note = "Crossroads, The Barrens" }, -- vol
    { "turnin", 906, xp = 3050 }, -- Betrayal from Within (lvl 25, ~3050 xp, sim lvl 20)
    { "turnin", 6523, xp = 1350 }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 20)
    { "accept", 6401 }, -- Kaya's Alive (lvl 18, ~1000 xp, sim lvl 20)
    { "turnin", 1092, xp = 1300 }, -- Gerenzo's Orders (lvl 22, ~1300 xp, sim lvl 20)
    { "turnin", 1095, xp = 1100 }, -- Further Instructions (lvl 27, ~1100 xp, sim lvl 20)
    { "fp", 1442, 45.12, 59.84 }, -- point de vol
    { "accept", 6282 }, -- Harpies Threaten (lvl 26, ~2100 xp, sim lvl 20)
    { "turnin", 6401, xp = 1000 }, -- Kaya's Alive (lvl 18, ~1000 xp, sim lvl 20)
    { "accept", 79980 }, -- Scramble (lvl 24, ~970 xp, sim lvl 20)
    { "turnin", 79980, xp = 970 }, -- Scramble (lvl 24, ~970 xp, sim lvl 20)
    { "complete", 6282, at = { 1442, 32.24, 59.97 } }, -- Harpies Threaten (lvl 26, ~2100 xp, sim lvl 20)
    { "complete", 6282, at = { 1442, 36.82, 67.37 } }, -- Harpies Threaten (lvl 26, ~2100 xp, sim lvl 20)
    { "turnin", 6282, xp = 2100 }, -- Harpies Threaten (lvl 26, ~2100 xp, sim lvl 21)
    { "accept", 6283 }, -- Bloodfury Bloodline (lvl 26, ~2100 xp, sim lvl 21)
    { "complete", 6283, at = { 1442, 30.75, 61.91 } }, -- Bloodfury Bloodline (lvl 26, ~2100 xp, sim lvl 21)
    { "turnin", 6283, xp = 2100 }, -- Bloodfury Bloodline (lvl 26, ~2100 xp, sim lvl 21)
  },
})
