local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 56 étapes, niveau final 47.01, ~50867 xp/h, 147 min.
Q:RegisterGuide({
  id = "H_17",
  title = "Feralas",
  faction = "Horde",
  minLevel = 46, maxLevel = 47,
  next = "H_18",
  sim = { steps = 56, endLevel = 47.01, xpPerHour = 50867, minutes = 147 },
  steps = {
    { "note", "Not running Uldaman? Abandon Uldaman Reagent Run", optional = true, dungeon = "Uldaman" },
    { "goto", 1446, 51.6, 25.44, note = "Flight master" }, -- déplacement
    { "fly", 1441, node = 30, note = "Freewind Post, Thousand Needles" }, -- vol
    { "fp", 1444, 75.45, 44.36 }, -- point de vol
    { "accept", 3063 }, -- Vengeance on the Northspring (lvl 50, ~3550 xp, sim lvl 46)
    { "accept", 2975 }, -- The Ogres of Feralas (lvl 43, ~2700 xp, sim lvl 46)
    { "accept", 2987 }, -- Gordunni Cobalt (lvl 43, ~3600 xp, sim lvl 46)
    { "accept", 2973 }, -- A New Cloak's Sheen (lvl 45, ~3900 xp, sim lvl 46)
    { "accept", 2862 }, -- War on the Woodpaw (lvl 42, ~2550 xp, sim lvl 46)
    { "accept", 2822 }, -- The Mark of Quality (lvl 46, ~4050 xp, sim lvl 46)
    { "accept", 2978, at = { 1444, 80.55, 34.29 }, note = "Loot Gordunni Scroll to start the quest" }, -- The Gordunni Scroll (lvl 43, ~1800 xp, sim lvl 46)
    { "complete", 2975, at = { 1444, 74.78, 26.47 } }, -- The Ogres of Feralas (lvl 43, ~2700 xp, sim lvl 46)
    { "complete", 2987, at = { 1444, 75.97, 33.44 } }, -- Gordunni Cobalt (lvl 43, ~3600 xp, sim lvl 46)
    { "complete", 2862, at = { 1444, 72.51, 37.63 } }, -- War on the Woodpaw (lvl 42, ~2550 xp, sim lvl 46)
    { "turnin", 2862, xp = 2550 }, -- War on the Woodpaw (lvl 42, ~2550 xp, sim lvl 46)
    { "accept", 2863 }, -- Alpha Strike (lvl 43, ~2700 xp, sim lvl 46)
    { "complete", 2973, at = { 1444, 66.91, 47.29 } }, -- A New Cloak's Sheen (lvl 45, ~3900 xp, sim lvl 46)
    { "accept", 7003 }, -- Zapped Giants (lvl 48, ~4400 xp, sim lvl 46)
    { "accept", 7721 }, -- Fuel for the Zapping (lvl 48, ~4400 xp, sim lvl 46)
    { "accept", 2766, at = { 1444, 39.97, 23.28 }, note = "Loot OOX-22/FE Distress Beacon to start the quest" }, -- Find OOX-22/FE! (lvl 45, ~3900 xp, sim lvl 46)
    { "complete", 7003, at = { 1444, 38.68, 22.35 } }, -- Zapped Giants (lvl 48, ~4400 xp, sim lvl 46)
    { "complete", 3063, at = { 1444, 40.25, 14.5 } }, -- Vengeance on the Northspring (lvl 50, ~3550 xp, sim lvl 46)
    { "complete", 7721, at = { 1444, 48.3, 52.09 } }, -- Fuel for the Zapping (lvl 48, ~4400 xp, sim lvl 46)
    { "complete", 2822, at = { 1444, 52.05, 58.58 } }, -- The Mark of Quality (lvl 46, ~4050 xp, sim lvl 46)
    { "turnin", 2766, xp = 3900 }, -- Find OOX-22/FE! (lvl 45, ~3900 xp, sim lvl 46)
    { "accept", 2767 }, -- Rescue OOX-22/FE! (lvl 45, ~0 xp, sim lvl 46)
    { "complete", 2863, at = { 1444, 65.63, 52.47 } }, -- Alpha Strike (lvl 43, ~2700 xp, sim lvl 46)
    { "turnin", 2987, xp = 3600 }, -- Gordunni Cobalt (lvl 43, ~3600 xp, sim lvl 46)
    { "turnin", 2978, xp = 1800 }, -- The Gordunni Scroll (lvl 43, ~1800 xp, sim lvl 46)
    { "turnin", 2975, xp = 2700 }, -- The Ogres of Feralas (lvl 43, ~2700 xp, sim lvl 46)
    { "accept", 2980 }, -- The Ogres of Feralas (lvl 44, ~3750 xp, sim lvl 46)
    { "accept", 2979 }, -- Dark Ceremony (lvl 46, ~4050 xp, sim lvl 46)
    { "turnin", 3063, xp = 3550 }, -- Vengeance on the Northspring (lvl 50, ~3550 xp, sim lvl 46)
    { "turnin", 2973, xp = 3900 }, -- A New Cloak's Sheen (lvl 45, ~3900 xp, sim lvl 46)
    { "turnin", 2863, xp = 2700 }, -- Alpha Strike (lvl 43, ~2700 xp, sim lvl 46)
    { "accept", 2902 }, -- Woodpaw Investigation (lvl 43, ~1800 xp, sim lvl 46)
    { "turnin", 2822, xp = 4050 }, -- The Mark of Quality (lvl 46, ~4050 xp, sim lvl 46)
    { "accept", 7734 }, -- Improved Quality (lvl 48, ~4400 xp, sim lvl 46)
    { "complete", 7734, at = { 1444, 54.73, 32.76 } }, -- Improved Quality (lvl 48, ~4400 xp, sim lvl 46)
    { "complete", 2767, at = { 1444, 45.63, 43.39 } }, -- Rescue OOX-22/FE! (lvl 45, ~0 xp, sim lvl 46)
    { "turnin", 7003, xp = 4400 }, -- Zapped Giants (lvl 48, ~4400 xp, sim lvl 46)
    { "turnin", 7721, xp = 4400 }, -- Fuel for the Zapping (lvl 48, ~4400 xp, sim lvl 46)
    { "complete", 2980, at = { 1444, 60.26, 66.29 } }, -- The Ogres of Feralas (lvl 44, ~3750 xp, sim lvl 46)
    { "complete", 2979, at = { 1444, 60.44, 69.41 } }, -- Dark Ceremony (lvl 46, ~4050 xp, sim lvl 46)
    { "turnin", 2902, xp = 1800 }, -- Woodpaw Investigation (lvl 43, ~1800 xp, sim lvl 46)
    { "accept", 2903 }, -- The Battle Plans (lvl 43, ~3600 xp, sim lvl 46)
    { "turnin", 7734, xp = 4400 }, -- Improved Quality (lvl 48, ~4400 xp, sim lvl 46)
    { "turnin", 2903, xp = 3600 }, -- The Battle Plans (lvl 43, ~3600 xp, sim lvl 46)
    { "accept", 7730 }, -- Zukk'ash Infestation (lvl 45, ~3900 xp, sim lvl 46)
    { "accept", 7731 }, -- Stinglasher (lvl 47, ~4200 xp, sim lvl 46)
    { "complete", 7730, at = { 1444, 73.68, 63.39 } }, -- Zukk'ash Infestation (lvl 45, ~3900 xp, sim lvl 46)
    { "complete", 7731, at = { 1444, 75.58, 60.85 } }, -- Stinglasher (lvl 47, ~4200 xp, sim lvl 46)
    { "turnin", 2980, xp = 3750 }, -- The Ogres of Feralas (lvl 44, ~3750 xp, sim lvl 46)
    { "turnin", 2979, xp = 4050 }, -- Dark Ceremony (lvl 46, ~4050 xp, sim lvl 46)
    { "turnin", 7730, xp = 3900 }, -- Zukk'ash Infestation (lvl 45, ~3900 xp, sim lvl 46)
    { "turnin", 7731, xp = 4200 }, -- Stinglasher (lvl 47, ~4200 xp, sim lvl 46)
  },
})
