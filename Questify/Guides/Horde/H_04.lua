local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 108 étapes, niveau final 28.00, ~30704 xp/h, 206 min.
Q:RegisterGuide({
  id = "H_04",
  title = "Southern Barrens and Thousand Needles",
  faction = "Horde",
  minLevel = 25, maxLevel = 28,
  next = "H_05",
  sim = { steps = 108, endLevel = 28.00, xpPerHour = 30704, minutes = 206 },
  steps = {
    { "goto", 1440, 12.24, 33.8, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 25, note = "Crossroads, The Barrens" }, -- vol
    { "accept", 868 }, -- Egg Hunt (lvl 22, ~1750 xp, sim lvl 25)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 77, note = "Camp Taurajo, The Barrens" }, -- vol
    { "accept", 893 }, -- Weapons of Choice (lvl 24, ~1950 xp, sim lvl 25)
    { "accept", 5052 }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 25)
    { "accept", 874 }, -- Mahren Skyseer (lvl 27, ~550 xp, sim lvl 25)
    { "sethearth", 1413, 45.58, 59.04 }, -- lier la pierre de foyer
    { "accept", 843 }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 25)
    { "complete", 5052, at = { 1413, 47.24, 84.86 } }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 25)
    { "complete", 843, at = { 1413, 47.47, 85 } }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 25)
    { "turnin", 843, xp = 1850 }, -- Gann's Reclamation (lvl 23, ~1850 xp, sim lvl 25)
    { "accept", 846 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 25)
    { "accept", 885, at = { 1413, 44.81, 74.93 }, note = "Loot Washte Pawne's Feather to start the quest" }, -- Washte Pawne (lvl 25, ~1500 xp, sim lvl 25)
    { "turnin", 5052, xp = 1250 }, -- Blood Shards of Agamaggan (lvl 21, ~1250 xp, sim lvl 25)
    { "accept", 879 }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 25)
    { "turnin", 885, xp = 1500 }, -- Washte Pawne (lvl 25, ~1500 xp, sim lvl 25)
    { "complete", 868, at = { 1413, 47.96, 70.53 } }, -- Egg Hunt (lvl 22, ~1750 xp, sim lvl 25)
    { "complete", 846, at = { 1413, 49.19, 84.17 } }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 25)
    { "accept", 857 }, -- The Tear of the Moons (lvl 30, ~2450 xp, sim lvl 25)
    { "complete", 857, at = { 1413, 49.13, 84.25 } }, -- The Tear of the Moons (lvl 30, ~2450 xp, sim lvl 25)
    { "turnin", 857, xp = 2450 }, -- The Tear of the Moons (lvl 30, ~2450 xp, sim lvl 25)
    { "turnin", 846, xp = 2100 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 25)
    { "accept", 849 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 25)
    { "complete", 879, obj = 1, at = { 1413, 45.12, 80.07 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 25)
    { "complete", 849, at = { 1413, 46.97, 85.63 } }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 25)
    { "complete", 879, obj = 2, at = { 1413, 43.75, 83.26 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 25)
    { "complete", 893, at = { 1413, 43.52, 82.91 } }, -- Weapons of Choice (lvl 24, ~1950 xp, sim lvl 25)
    { "complete", 893, at = { 1413, 41.93, 81.47 } }, -- Weapons of Choice (lvl 24, ~1950 xp, sim lvl 25)
    { "complete", 879, at = { 1413, 40.15, 80.54 } }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 26)
    { "hearth", 1413 }, -- pierre de foyer
    { "turnin", 879, xp = 1500 }, -- Betrayal from Within (lvl 25, ~1500 xp, sim lvl 26)
    { "accept", 906 }, -- Betrayal from Within (lvl 25, ~3050 xp, sim lvl 26)
    { "turnin", 893, xp = 1950 }, -- Weapons of Choice (lvl 24, ~1950 xp, sim lvl 26)
    { "accept", 1153 }, -- A New Ore Sample (lvl 29, ~2350 xp, sim lvl 26)
    { "goto", 1413, 44.45, 59.15, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 25, note = "Crossroads, The Barrens" }, -- vol
    { "turnin", 868, xp = 1750 }, -- Egg Hunt (lvl 22, ~1750 xp, sim lvl 26)
    { "turnin", 906, xp = 3050 }, -- Betrayal from Within (lvl 25, ~3050 xp, sim lvl 26)
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 80, note = "Ratchet, The Barrens" }, -- vol
    { "accept", 79097 }, -- Baxtan: On Destructive Magics (lvl 20, ~0 xp, sim lvl 26)
    { "complete", 79097, at = { 1413, 62.7, 36.3 } }, -- Baxtan: On Destructive Magics (lvl 20, ~0 xp, sim lvl 26)
    { "accept", 891 }, -- The Guns of Northwatch (lvl 20, ~1240 xp, sim lvl 26)
    { "turnin", 874, xp = 550 }, -- Mahren Skyseer (lvl 27, ~550 xp, sim lvl 26)
    { "accept", 873 }, -- Isha Awak (lvl 27, ~2750 xp, sim lvl 26)
    { "complete", 891, at = { 1413, 61.85, 54.65 } }, -- The Guns of Northwatch (lvl 20, ~1240 xp, sim lvl 26)
    { "complete", 891, at = { 1413, 63.18, 56.64 } }, -- The Guns of Northwatch (lvl 20, ~1240 xp, sim lvl 26)
    { "complete", 873, at = { 1413, 64.12, 50.8 } }, -- Isha Awak (lvl 27, ~2750 xp, sim lvl 26)
    { "turnin", 873, xp = 2750 }, -- Isha Awak (lvl 27, ~2750 xp, sim lvl 26)
    { "turnin", 891, xp = 1240 }, -- The Guns of Northwatch (lvl 20, ~1240 xp, sim lvl 26)
    { "goto", 1413, 63.08, 37.16, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 77, note = "Camp Taurajo, The Barrens" }, -- vol
    { "turnin", 849, xp = 2100 }, -- Revenge of Gann (lvl 26, ~2100 xp, sim lvl 26)
    { "turnin", 5881, xp = 1150 }, -- Calling in the Reserves (lvl 28, ~1150 xp, sim lvl 26)
    { "accept", 4542 }, -- Message to Freewind Post (lvl 25, ~510 xp, sim lvl 26)
    { "accept", 4881, at = { 1441, 39.43, 33.1 }, note = "Loot Assassination Note to start the quest" }, -- Assassination Plot (lvl 28, ~2300 xp, sim lvl 26)
    { "fp", 1441, 45.14, 49.11 }, -- point de vol
    { "accept", 1149 }, -- Test of Faith (lvl 26, ~1050 xp, sim lvl 26)
    { "accept", 4767 }, -- Wind Rider (lvl 29, ~1750 xp, sim lvl 26)
    { "turnin", 4542, xp = 510 }, -- Message to Freewind Post (lvl 25, ~510 xp, sim lvl 26)
    { "accept", 4841 }, -- Pacify the Centaur (lvl 25, ~2000 xp, sim lvl 26)
    { "accept", 4770 }, -- Homeward Bound (lvl 29, ~2350 xp, sim lvl 26)
    { "complete", 4767, at = { 1441, 11.77, 35.26 } }, -- Wind Rider (lvl 29, ~1750 xp, sim lvl 26)
    { "complete", 4770, at = { 1441, 15.15, 32.65 } }, -- Homeward Bound (lvl 29, ~2350 xp, sim lvl 26)
    { "turnin", 4881, xp = 2300 }, -- Assassination Plot (lvl 28, ~2300 xp, sim lvl 26)
    { "accept", 5151 }, -- Hypercapacitor Gizmo (lvl 30, ~3050 xp, sim lvl 26)
    { "turnin", 4770, xp = 2350 }, -- Homeward Bound (lvl 29, ~2350 xp, sim lvl 26)
    { "complete", 5151, at = { 1441, 22.76, 24.62 } }, -- Hypercapacitor Gizmo (lvl 30, ~3050 xp, sim lvl 26)
    { "turnin", 5151, xp = 3050 }, -- Hypercapacitor Gizmo (lvl 30, ~3050 xp, sim lvl 26)
    { "complete", 1149, at = { 1441, 26.43, 32.93 } }, -- Test of Faith (lvl 26, ~1050 xp, sim lvl 26)
    { "turnin", 4767, xp = 1750 }, -- Wind Rider (lvl 29, ~1750 xp, sim lvl 26)
    { "accept", 4821 }, -- Alien Egg (lvl 26, ~2100 xp, sim lvl 26)
    { "turnin", 1149, xp = 1050 }, -- Test of Faith (lvl 26, ~1050 xp, sim lvl 26)
    { "accept", 1150 }, -- Test of Endurance (lvl 30, ~2450 xp, sim lvl 26)
    { "complete", 4841, at = { 1441, 40.95, 36.01 } }, -- Pacify the Centaur (lvl 25, ~2000 xp, sim lvl 26)
    { "complete", 1150, at = { 1441, 26.35, 55.55 } }, -- Test of Endurance (lvl 30, ~2450 xp, sim lvl 27)
    { "complete", 4821, at = { 1441, 37.63, 56.13 } }, -- Alien Egg (lvl 26, ~2100 xp, sim lvl 27)
    { "turnin", 4821, xp = 2100 }, -- Alien Egg (lvl 26, ~2100 xp, sim lvl 27)
    { "accept", 4865 }, -- Serpent Wild (lvl 26, ~1050 xp, sim lvl 27)
    { "turnin", 4841, xp = 2000 }, -- Pacify the Centaur (lvl 25, ~2000 xp, sim lvl 27)
    { "accept", 5064 }, -- Grimtotem Spying (lvl 28, ~2300 xp, sim lvl 27)
    { "accept", 5147 }, -- WANTED: Arnak Grimtotem (lvl 29, ~2350 xp, sim lvl 27)
    { "turnin", 1150, xp = 2450 }, -- Test of Endurance (lvl 30, ~2450 xp, sim lvl 27)
    { "accept", 1151 }, -- Test of Strength (lvl 30, ~3050 xp, sim lvl 27)
    { "complete", 5147, at = { 1441, 38.11, 26.87 } }, -- WANTED: Arnak Grimtotem (lvl 29, ~2350 xp, sim lvl 27)
    { "accept", 4904 }, -- Free at Last (lvl 29, ~2350 xp, sim lvl 27)
    { "complete", 5064, obj = 1, at = { 1441, 31.79, 32.58 } }, -- Grimtotem Spying (lvl 28, ~2300 xp, sim lvl 27)
    { "turnin", 4865, xp = 1050 }, -- Serpent Wild (lvl 26, ~1050 xp, sim lvl 27)
    { "complete", 1151, at = { 1441, 17.1, 38.1 } }, -- Test of Strength (lvl 30, ~3050 xp, sim lvl 27)
    { "complete", 4904, at = { 1441, 30.93, 37.12 } }, -- Free at Last (lvl 29, ~2350 xp, sim lvl 27)
    { "complete", 5064, obj = 2, at = { 1441, 33.76, 39.99 } }, -- Grimtotem Spying (lvl 28, ~2300 xp, sim lvl 27)
    { "complete", 5064, at = { 1441, 39.34, 41.53 } }, -- Grimtotem Spying (lvl 28, ~2300 xp, sim lvl 27)
    { "turnin", 5147, xp = 2350 }, -- WANTED: Arnak Grimtotem (lvl 29, ~2350 xp, sim lvl 27)
    { "turnin", 5064, xp = 2300 }, -- Grimtotem Spying (lvl 28, ~2300 xp, sim lvl 27)
    { "turnin", 4904, xp = 2350 }, -- Free at Last (lvl 29, ~2350 xp, sim lvl 27)
    { "turnin", 1151, xp = 3050 }, -- Test of Strength (lvl 30, ~3050 xp, sim lvl 27)
    { "complete", 1153, at = { 1441, 65.16, 48.23 } }, -- A New Ore Sample (lvl 29, ~2350 xp, sim lvl 27)
    { "hearth", 1413 }, -- pierre de foyer
    { "turnin", 1153, xp = 2350 }, -- A New Ore Sample (lvl 29, ~2350 xp, sim lvl 27)
    { "goto", 1413, 44.45, 59.15, note = "Flight master" }, -- déplacement
    { "fly", 1413, node = 25, note = "Crossroads, The Barrens" }, -- vol
    { "accept", 78143 }, -- Secrets of the Dreamers (lvl 20, ~0 xp, sim lvl 27)
    { "complete", 78143, at = { 1413, 49.3, 32.88 } }, -- Secrets of the Dreamers (lvl 20, ~0 xp, sim lvl 27)
    { "accept", 78145 }, -- Arcanic Systems Manual (lvl 20, ~0 xp, sim lvl 27)
    { "complete", 78145, at = { 1413, 56.3, 8.8 } }, -- Arcanic Systems Manual (lvl 20, ~0 xp, sim lvl 27)
    { "level", 28, at = { 1441, 65.16, 48.23 }, note = "About 72 more mobs near the last objective" }, -- farm de niveau
  },
})
