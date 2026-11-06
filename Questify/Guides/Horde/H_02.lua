local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 99 étapes, niveau final 21.05, ~25206 xp/h, 163 min.
Q:RegisterGuide({
  id = "H_02",
  title = "Stonetalon Mountains and The Barrens",
  faction = "Horde",
  minLevel = 17, maxLevel = 21,
  next = "H_03",
  sim = { steps = 99, endLevel = 21.05, xpPerHour = 25206, minutes = 163 },
  steps = {
    { "accept", 6541 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 17)
    { "accept", 905 }, -- The Angry Scytheclaws (lvl 17, ~1250 xp, sim lvl 17)
    { "complete", 905, at = { 1413, 52.6, 46.11 } }, -- The Angry Scytheclaws (lvl 17, ~1250 xp, sim lvl 17)
    { "accept", 899 }, -- Consumed by Hatred (lvl 20, ~1950 xp, sim lvl 17)
    { "turnin", 905, xp = 1250 }, -- The Angry Scytheclaws (lvl 17, ~1250 xp, sim lvl 17)
    { "accept", 3261 }, -- Jorn Skyseer (lvl 18, ~135 xp, sim lvl 17)
    { "accept", 3281 }, -- Stolen Silver (lvl 18, ~1350 xp, sim lvl 17)
    { "accept", 97003 }, -- Chol'aruk the Ravener (lvl 21, ~1650 xp, sim lvl 17)
    { "accept", 95507 }, -- Vrang's Game (lvl 18, ~1350 xp, sim lvl 17)
    { "accept", 95494 }, -- Bruised Pride and Lion Hides (lvl 18, ~1350 xp, sim lvl 17)
    { "accept", 95621 }, -- Trouble in the Valley (lvl 18, ~1350 xp, sim lvl 17)
    { "complete", 95621, at = { 1413, 41.74, 15.49 } }, -- Trouble in the Valley (lvl 18, ~1350 xp, sim lvl 17)
    { "accept", 1062 }, -- Goblin Invaders (lvl 19, ~1450 xp, sim lvl 17)
    { "accept", 6548 }, -- Avenge My Village (lvl 18, ~1350 xp, sim lvl 17)
    { "turnin", 1060, xp = 1550 }, -- Letter to Jin'Zil (lvl 20, ~1550 xp, sim lvl 17)
    { "accept", 6461 }, -- Blood Feeders (lvl 19, ~1450 xp, sim lvl 18)
    { "complete", 1062, at = { 1442, 66.63, 51.24 } }, -- Goblin Invaders (lvl 19, ~1450 xp, sim lvl 18)
    { "turnin", 1483, xp = 415 }, -- Ziz Fizziks (lvl 21, ~415 xp, sim lvl 18)
    { "accept", 1093 }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 18)
    { "fp", 1442, 45.12, 59.84 }, -- point de vol
    { "accept", 6421 }, -- Boulderslide Ravine (lvl 18, ~1350 xp, sim lvl 18)
    { "complete", 6461, at = { 1442, 54.64, 75.79 } }, -- Blood Feeders (lvl 19, ~1450 xp, sim lvl 18)
    { "complete", 6421, at = { 1442, 59.73, 91.48 } }, -- Boulderslide Ravine (lvl 18, ~1350 xp, sim lvl 18)
    { "turnin", 6461, xp = 1450 }, -- Blood Feeders (lvl 19, ~1450 xp, sim lvl 18)
    { "accept", 6542 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 18)
    { "complete", 6548, at = { 1442, 82.86, 86.34 } }, -- Avenge My Village (lvl 18, ~1350 xp, sim lvl 18)
    { "turnin", 1062, xp = 1450 }, -- Goblin Invaders (lvl 19, ~1450 xp, sim lvl 18)
    { "accept", 1068 }, -- Shredding Machines (lvl 23, ~1850 xp, sim lvl 18)
    { "turnin", 6548, xp = 1350 }, -- Avenge My Village (lvl 18, ~1350 xp, sim lvl 18)
    { "accept", 6629 }, -- Kill Grundig Darkcloud (lvl 18, ~1350 xp, sim lvl 18)
    { "complete", 1068, obj = 1, at = { 1442, 67.2, 46.69 } }, -- Shredding Machines (lvl 23, ~1850 xp, sim lvl 18)
    { "complete", 1093, at = { 1442, 62.38, 53.01 } }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 18)
    { "complete", 1068, at = { 1442, 64.09, 56.62 } }, -- Shredding Machines (lvl 23, ~1850 xp, sim lvl 18)
    { "turnin", 1093, xp = 1650 }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 18)
    { "accept", 1094 }, -- Further Instructions (lvl 21, ~830 xp, sim lvl 18)
    { "turnin", 6421, xp = 1350 }, -- Boulderslide Ravine (lvl 18, ~1350 xp, sim lvl 18)
    { "accept", 6481 }, -- Earthen Arise (lvl 20, ~1550 xp, sim lvl 18)
    { "accept", 6284 }, -- Arachnophobia (lvl 21, ~1650 xp, sim lvl 18)
    { "accept", 6523 }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 18)
    { "complete", 6629, at = { 1442, 73.65, 86.12 } }, -- Kill Grundig Darkcloud (lvl 18, ~1350 xp, sim lvl 18)
    { "complete", 6523, at = { 1442, 77.1, 90.85 } }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 18)
    { "turnin", 6629, xp = 1350 }, -- Kill Grundig Darkcloud (lvl 18, ~1350 xp, sim lvl 18)
    { "turnin", 6523, xp = 1350 }, -- Protect Kaya (lvl 18, ~1350 xp, sim lvl 19)
    { "accept", 6401 }, -- Kaya's Alive (lvl 18, ~1000 xp, sim lvl 19)
    { "turnin", 1068, xp = 1850 }, -- Shredding Machines (lvl 23, ~1850 xp, sim lvl 19)
    { "hearth", 1413 }, -- pierre de foyer
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 77, note = "Camp Taurajo, The Barrens" }, -- vol
    { "turnin", 3261, xp = 135 }, -- Jorn Skyseer (lvl 18, ~135 xp, sim lvl 19)
    { "accept", 882 }, -- Ishamuhale (lvl 19, ~1800 xp, sim lvl 19)
    { "accept", 97250 }, -- Wrongly Blamed, Justly Corrected (lvl 23, ~1850 xp, sim lvl 19)
    { "complete", 899, at = { 1413, 52.96, 53.61 } }, -- Consumed by Hatred (lvl 20, ~1950 xp, sim lvl 19)
    { "complete", 3281, at = { 1413, 58.04, 53.87 } }, -- Stolen Silver (lvl 18, ~1350 xp, sim lvl 19)
    { "accept", 1069 }, -- Deepmoss Spider Eggs (lvl 20, ~1950 xp, sim lvl 19)
    { "sethearth", 1413, 62.05, 39.41 }, -- lier la pierre de foyer
    { "turnin", 1094, xp = 830 }, -- Further Instructions (lvl 21, ~830 xp, sim lvl 19)
    { "complete", 95494, at = { 1413, 61.99, 32.86 } }, -- Bruised Pride and Lion Hides (lvl 18, ~1350 xp, sim lvl 19)
    { "complete", 882, at = { 1413, 59.8, 30.6 } }, -- Ishamuhale (lvl 19, ~1800 xp, sim lvl 19)
    { "complete", 97003, at = { 1413, 57.87, 26.4 } }, -- Chol'aruk the Ravener (lvl 21, ~1650 xp, sim lvl 19)
    { "turnin", 97003, xp = 1650 }, -- Chol'aruk the Ravener (lvl 21, ~1650 xp, sim lvl 19)
    { "turnin", 3281, xp = 1350 }, -- Stolen Silver (lvl 18, ~1350 xp, sim lvl 19)
    { "turnin", 899, xp = 1950 }, -- Consumed by Hatred (lvl 20, ~1950 xp, sim lvl 19)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 77, note = "Camp Taurajo, The Barrens" }, -- vol
    { "turnin", 882, xp = 1800 }, -- Ishamuhale (lvl 19, ~1800 xp, sim lvl 19)
    { "accept", 907 }, -- Enraged Thunder Lizards (lvl 18, ~1700 xp, sim lvl 19)
    { "accept", 897, at = { 1413, 42, 70 }, note = "Loot Harvester's Head to start the quest" }, -- The Harvester (lvl 24, ~2400 xp, sim lvl 19)
    { "accept", 79192 }, -- Stepping Stones (lvl 24, ~970 xp, sim lvl 19)
    { "complete", 97250, at = { 1413, 48.9, 77.05 } }, -- Wrongly Blamed, Justly Corrected (lvl 23, ~1850 xp, sim lvl 19)
    { "complete", 907, at = { 1413, 49.33, 59.83 } }, -- Enraged Thunder Lizards (lvl 18, ~1700 xp, sim lvl 19)
    { "accept", 884, at = { 1413, 49.4, 59.2 }, note = "Loot Owatanka's Tailspike to start the quest" }, -- Owatanka (lvl 24, ~1450 xp, sim lvl 19)
    { "turnin", 907, xp = 1700 }, -- Enraged Thunder Lizards (lvl 18, ~1700 xp, sim lvl 19)
    { "accept", 913 }, -- Cry of the Thunderhawk (lvl 20, ~1950 xp, sim lvl 19)
    { "turnin", 897, xp = 2400 }, -- The Harvester (lvl 24, ~2400 xp, sim lvl 19)
    { "turnin", 884, xp = 1450 }, -- Owatanka (lvl 24, ~1450 xp, sim lvl 20)
    { "turnin", 97250, xp = 1850 }, -- Wrongly Blamed, Justly Corrected (lvl 23, ~1850 xp, sim lvl 20)
    { "complete", 913, at = { 1413, 48.97, 55.85 } }, -- Cry of the Thunderhawk (lvl 20, ~1950 xp, sim lvl 20)
    { "turnin", 913, xp = 1950 }, -- Cry of the Thunderhawk (lvl 20, ~1950 xp, sim lvl 20)
    { "goto", 1413, 44.45, 59.15, note = "Flight master" }, -- déplacement
    { "fly", 1442, node = 29, note = "Sun Rock Retreat, Stonetalon Mountains" }, -- vol
    { "complete", 6481, at = { 1442, 57.4, 89.4 } }, -- Earthen Arise (lvl 20, ~1550 xp, sim lvl 20)
    { "complete", 1069, at = { 1442, 53.49, 73.76 } }, -- Deepmoss Spider Eggs (lvl 20, ~1950 xp, sim lvl 20)
    { "complete", 6284, at = { 1442, 53.25, 72.55 } }, -- Arachnophobia (lvl 21, ~1650 xp, sim lvl 20)
    { "turnin", 6481, xp = 1550 }, -- Earthen Arise (lvl 20, ~1550 xp, sim lvl 20)
    { "turnin", 6284, xp = 1650 }, -- Arachnophobia (lvl 21, ~1650 xp, sim lvl 20)
    { "turnin", 6401, xp = 1000 }, -- Kaya's Alive (lvl 18, ~1000 xp, sim lvl 20)
    { "turnin", 79192, xp = 970 }, -- Stepping Stones (lvl 24, ~970 xp, sim lvl 20)
    { "accept", 79980 }, -- Scramble (lvl 24, ~970 xp, sim lvl 20)
    { "turnin", 79980, xp = 970 }, -- Scramble (lvl 24, ~970 xp, sim lvl 20)
    { "accept", 78270 }, -- Goblin Lockpicks (lvl 23, ~1400 xp, sim lvl 20)
    { "turnin", 78270, xp = 1400 }, -- Goblin Lockpicks (lvl 23, ~1400 xp, sim lvl 20)
    { "turnin", 95621, xp = 1350 }, -- Trouble in the Valley (lvl 18, ~1350 xp, sim lvl 20)
    { "complete", 95507, at = { 1413, 47, 12.75 } }, -- Vrang's Game (lvl 18, ~1350 xp, sim lvl 20)
    { "turnin", 95494, xp = 1350 }, -- Bruised Pride and Lion Hides (lvl 18, ~1350 xp, sim lvl 20)
    { "turnin", 95507, xp = 1350 }, -- Vrang's Game (lvl 18, ~1350 xp, sim lvl 20)
    { "turnin", 6542, xp = 145 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 20)
    { "turnin", 6541, xp = 145 }, -- Report to Kadrak (lvl 19, ~145 xp, sim lvl 20)
    { "hearth", 1413 }, -- pierre de foyer
    { "turnin", 1069, xp = 1950 }, -- Deepmoss Spider Eggs (lvl 20, ~1950 xp, sim lvl 20)
  },
})
