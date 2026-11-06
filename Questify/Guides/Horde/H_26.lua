local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 48 étapes, niveau final 55.00, ~65623 xp/h, 159 min.
Q:RegisterGuide({
  id = "H_26",
  title = "Felwood",
  faction = "Horde",
  minLevel = 54, maxLevel = 55,
  next = "H_27",
  sim = { steps = 48, endLevel = 55.00, xpPerHour = 65623, minutes = 159 },
  steps = {
    { "hearth", 1447 }, -- pierre de foyer
    { "accept", 5155 }, -- Forces of Jaedenar (lvl 51, ~4900 xp, sim lvl 54)
    { "accept", 5156 }, -- Verifying the Corruption (lvl 54, ~6800 xp, sim lvl 54)
    { "accept", 4102 }, -- Cleansing Felwood (lvl 55, ~5650 xp, sim lvl 54)
    { "complete", 4102, at = { 1448, 58.31, 20.92 } }, -- Cleansing Felwood (lvl 55, ~5650 xp, sim lvl 54)
    { "complete", 5156, at = { 1448, 43.73, 40.16 } }, -- Verifying the Corruption (lvl 54, ~6800 xp, sim lvl 54)
    { "complete", 5156, at = { 1448, 41.03, 41.96 } }, -- Verifying the Corruption (lvl 54, ~6800 xp, sim lvl 54)
    { "accept", 5202, at = { 1448, 39.53, 48.92 }, note = "Loot Blood Red Key to start the quest" }, -- A Strange Red Key (lvl 55, ~5650 xp, sim lvl 54)
    { "fp", 1448, 34.44, 53.96 }, -- point de vol
    { "accept", 4505 }, -- Well of Corruption (lvl 54, ~5450 xp, sim lvl 54)
    { "accept", 6162 }, -- A Husband's Last Battle (lvl 51, ~4900 xp, sim lvl 54)
    { "turnin", 5202, xp = 5650 }, -- A Strange Red Key (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 5203 }, -- Rescue From Jaedenar (lvl 55, ~5650 xp, sim lvl 54)
    { "complete", 5203, at = { 1448, 35.45, 59.06 } }, -- Rescue From Jaedenar (lvl 55, ~5650 xp, sim lvl 54)
    { "complete", 5155, at = { 1448, 38.7, 60.78 } }, -- Forces of Jaedenar (lvl 51, ~4900 xp, sim lvl 54)
    { "turnin", 5156, xp = 6800 }, -- Verifying the Corruption (lvl 54, ~6800 xp, sim lvl 54)
    { "turnin", 5203, xp = 5650 }, -- Rescue From Jaedenar (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 5204 }, -- Retribution of the Light (lvl 57, ~4500 xp, sim lvl 54)
    { "turnin", 5155, xp = 4900 }, -- Forces of Jaedenar (lvl 51, ~4900 xp, sim lvl 54)
    { "accept", 5157 }, -- Collection of the Corrupt Water (lvl 52, ~3800 xp, sim lvl 54)
    { "accept", 8460 }, -- Timbermaw Ally (lvl 48, ~3520 xp, sim lvl 54)
    { "complete", 8460, at = { 1448, 48.61, 91.57 } }, -- Timbermaw Ally (lvl 48, ~3520 xp, sim lvl 54)
    { "complete", 6162, at = { 1448, 48.23, 94.28 } }, -- A Husband's Last Battle (lvl 51, ~4900 xp, sim lvl 54)
    { "turnin", 4102, xp = 5650 }, -- Cleansing Felwood (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 5887 }, -- Salve via Hunting (lvl 55, ~4200 xp, sim lvl 54)
    { "complete", 4505, at = { 1448, 32.32, 66.56 } }, -- Well of Corruption (lvl 54, ~5450 xp, sim lvl 54)
    { "complete", 5157, at = { 1448, 35.17, 59.79 } }, -- Collection of the Corrupt Water (lvl 52, ~3800 xp, sim lvl 54)
    { "complete", 5204, at = { 1448, 38.3, 50.51 } }, -- Retribution of the Light (lvl 57, ~4500 xp, sim lvl 54)
    { "turnin", 5204, xp = 4500 }, -- Retribution of the Light (lvl 57, ~4500 xp, sim lvl 54)
    { "accept", 5385 }, -- The Remains of Trey Lightforge (lvl 57, ~7550 xp, sim lvl 54)
    { "complete", 5887, at = { 1448, 37.71, 46.16 } }, -- Salve via Hunting (lvl 55, ~4200 xp, sim lvl 54)
    { "turnin", 4505, xp = 5450 }, -- Well of Corruption (lvl 54, ~5450 xp, sim lvl 54)
    { "accept", 4506 }, -- Corrupted Sabers (lvl 54, ~5450 xp, sim lvl 54)
    { "turnin", 6162, xp = 4900 }, -- A Husband's Last Battle (lvl 51, ~4900 xp, sim lvl 54)
    { "complete", 4506, at = { 1448, 34.26, 52.32 } }, -- Corrupted Sabers (lvl 54, ~5450 xp, sim lvl 54)
    { "turnin", 4506, xp = 5450 }, -- Corrupted Sabers (lvl 54, ~5450 xp, sim lvl 54)
    { "turnin", 5887, xp = 4200 }, -- Salve via Hunting (lvl 55, ~4200 xp, sim lvl 54)
    { "turnin", 8460, xp = 3520 }, -- Timbermaw Ally (lvl 48, ~3520 xp, sim lvl 54)
    { "accept", 8462 }, -- Speak to Nafien (lvl 55, ~560 xp, sim lvl 54)
    { "turnin", 5157, xp = 3800 }, -- Collection of the Corrupt Water (lvl 52, ~3800 xp, sim lvl 54)
    { "turnin", 5385, xp = 7550 }, -- The Remains of Trey Lightforge (lvl 57, ~7550 xp, sim lvl 54)
    { "accept", 8461 }, -- Deadwood of the North (lvl 55, ~5650 xp, sim lvl 54)
    { "turnin", 8462, xp = 560 }, -- Speak to Nafien (lvl 55, ~560 xp, sim lvl 54)
    { "accept", 5083, at = { 1448, 60.23, 5.75 }, note = "Loot Empty Firewater Flask to start the quest" }, -- Winterfall Firewater (lvl 56, ~0 xp, sim lvl 54)
    { "complete", 8461, at = { 1448, 62.07, 8.44 } }, -- Deadwood of the North (lvl 55, ~5650 xp, sim lvl 54)
    { "turnin", 8461, xp = 5650 }, -- Deadwood of the North (lvl 55, ~5650 xp, sim lvl 54)
    { "accept", 8465 }, -- Speak to Salfa (lvl 55, ~0 xp, sim lvl 54)
    { "level", 55, at = { 1448, 62.54, 9.84 }, note = "About 219 more mobs here (Deadwood Avenger, level 54)" }, -- farm de niveau
  },
})
