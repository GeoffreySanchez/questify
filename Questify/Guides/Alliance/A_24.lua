local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 54 étapes, niveau final 54.00, ~58377 xp/h, 172 min.
Q:RegisterGuide({
  id = "A_24",
  title = "Felwood",
  faction = "Alliance",
  minLevel = 53, maxLevel = 54,
  next = "A_26",
  sim = { steps = 54, endLevel = 54.00, xpPerHour = 58377, minutes = 172 },
  steps = {
    { "goto", 1428, 84.33, 68.33, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "boat", 1453, 24.1, 55.4, note = "Take the boat to Auberdine (Stormwind Harbor)" }, -- bateau
    { "fp", 1448, 62.49, 24.24 }, -- point de vol
    { "accept", 4421 }, -- The Corruption of the Jadefire (lvl 54, ~5450 xp, sim lvl 53)
    { "accept", 5249 }, -- To Winterspring! (lvl 56, ~0 xp, sim lvl 53)
    { "accept", 5156 }, -- Verifying the Corruption (lvl 54, ~6800 xp, sim lvl 53)
    { "accept", 5155 }, -- Forces of Jaedenar (lvl 51, ~4900 xp, sim lvl 53)
    { "accept", 8460 }, -- Timbermaw Ally (lvl 48, ~4400 xp, sim lvl 53)
    { "accept", 4101 }, -- Cleansing Felwood (lvl 55, ~5650 xp, sim lvl 53)
    { "complete", 4101, at = { 1448, 58.31, 20.92 } }, -- Cleansing Felwood (lvl 55, ~5650 xp, sim lvl 53)
    { "complete", 5156, at = { 1448, 43.73, 40.16 } }, -- Verifying the Corruption (lvl 54, ~6800 xp, sim lvl 53)
    { "complete", 5156, at = { 1448, 41.03, 41.96 } }, -- Verifying the Corruption (lvl 54, ~6800 xp, sim lvl 53)
    { "accept", 5202, at = { 1448, 39.53, 48.92 }, note = "Loot Blood Red Key to start the quest" }, -- A Strange Red Key (lvl 55, ~5650 xp, sim lvl 53)
    { "turnin", 5202, xp = 5650 }, -- A Strange Red Key (lvl 55, ~5650 xp, sim lvl 53)
    { "accept", 5203 }, -- Rescue From Jaedenar (lvl 55, ~5650 xp, sim lvl 53)
    { "complete", 5203, at = { 1448, 35.45, 59.06 } }, -- Rescue From Jaedenar (lvl 55, ~5650 xp, sim lvl 53)
    { "complete", 5155, at = { 1448, 38.7, 60.78 } }, -- Forces of Jaedenar (lvl 51, ~4900 xp, sim lvl 53)
    { "complete", 4421, obj = 4, at = { 1448, 32.23, 67.11 } }, -- The Corruption of the Jadefire (lvl 54, ~5450 xp, sim lvl 53)
    { "complete", 4421, at = { 1448, 37.38, 68.62 } }, -- The Corruption of the Jadefire (lvl 54, ~5450 xp, sim lvl 53)
    { "complete", 4421, at = { 1448, 43.09, 87.46 } }, -- The Corruption of the Jadefire (lvl 54, ~5450 xp, sim lvl 53)
    { "complete", 8460, at = { 1448, 48.61, 91.57 } }, -- Timbermaw Ally (lvl 48, ~4400 xp, sim lvl 53)
    { "turnin", 4101, xp = 5650 }, -- Cleansing Felwood (lvl 55, ~5650 xp, sim lvl 53)
    { "accept", 5882 }, -- Salve via Hunting (lvl 55, ~4200 xp, sim lvl 53)
    { "turnin", 8460, xp = 4400 }, -- Timbermaw Ally (lvl 48, ~4400 xp, sim lvl 53)
    { "accept", 8462 }, -- Speak to Nafien (lvl 55, ~560 xp, sim lvl 53)
    { "turnin", 5155, xp = 4900 }, -- Forces of Jaedenar (lvl 51, ~4900 xp, sim lvl 53)
    { "accept", 5157 }, -- Collection of the Corrupt Water (lvl 52, ~3800 xp, sim lvl 53)
    { "turnin", 5203, xp = 5650 }, -- Rescue From Jaedenar (lvl 55, ~5650 xp, sim lvl 53)
    { "accept", 5204 }, -- Retribution of the Light (lvl 57, ~4500 xp, sim lvl 53)
    { "turnin", 4421, xp = 5450 }, -- The Corruption of the Jadefire (lvl 54, ~5450 xp, sim lvl 53)
    { "accept", 4906 }, -- Further Corruption (lvl 54, ~5450 xp, sim lvl 53)
    { "turnin", 5156, xp = 6800 }, -- Verifying the Corruption (lvl 54, ~6800 xp, sim lvl 53)
    { "complete", 5157, at = { 1448, 35.17, 59.79 } }, -- Collection of the Corrupt Water (lvl 52, ~3800 xp, sim lvl 53)
    { "complete", 5204, at = { 1448, 38.3, 50.51 } }, -- Retribution of the Light (lvl 57, ~4500 xp, sim lvl 53)
    { "turnin", 5204, xp = 4500 }, -- Retribution of the Light (lvl 57, ~4500 xp, sim lvl 53)
    { "accept", 5385 }, -- The Remains of Trey Lightforge (lvl 57, ~7550 xp, sim lvl 53)
    { "complete", 5882, at = { 1448, 37.71, 46.16 } }, -- Salve via Hunting (lvl 55, ~4200 xp, sim lvl 53)
    { "accept", 939, at = { 1448, 39.07, 22.35 }, note = "Loot Flute of Xavaric to start the quest" }, -- Flute of Xavaric (lvl 54, ~5450 xp, sim lvl 53)
    { "complete", 4906, at = { 1448, 39.85, 21.18 } }, -- Further Corruption (lvl 54, ~5450 xp, sim lvl 53)
    { "complete", 4906, at = { 1448, 42.08, 18.83 } }, -- Further Corruption (lvl 54, ~5450 xp, sim lvl 53)
    { "complete", 939, at = { 1448, 43.11, 15.57 } }, -- Flute of Xavaric (lvl 54, ~5450 xp, sim lvl 53)
    { "accept", 5083, at = { 1448, 60.23, 5.75 }, note = "Loot Empty Firewater Flask to start the quest" }, -- Winterfall Firewater (lvl 56, ~0 xp, sim lvl 53)
    { "turnin", 8462, xp = 560 }, -- Speak to Nafien (lvl 55, ~560 xp, sim lvl 53)
    { "accept", 8461 }, -- Deadwood of the North (lvl 55, ~5650 xp, sim lvl 53)
    { "complete", 8461, at = { 1448, 62.07, 8.44 } }, -- Deadwood of the North (lvl 55, ~5650 xp, sim lvl 53)
    { "turnin", 8461, xp = 5650 }, -- Deadwood of the North (lvl 55, ~5650 xp, sim lvl 53)
    { "accept", 8465 }, -- Speak to Salfa (lvl 55, ~0 xp, sim lvl 53)
    { "turnin", 4906, xp = 5450 }, -- Further Corruption (lvl 54, ~5450 xp, sim lvl 53)
    { "turnin", 939, xp = 5450 }, -- Flute of Xavaric (lvl 54, ~5450 xp, sim lvl 53)
    { "turnin", 5385, xp = 7550 }, -- The Remains of Trey Lightforge (lvl 57, ~7550 xp, sim lvl 53)
    { "turnin", 5157, xp = 3800 }, -- Collection of the Corrupt Water (lvl 52, ~3800 xp, sim lvl 53)
    { "turnin", 5882, xp = 4200 }, -- Salve via Hunting (lvl 55, ~4200 xp, sim lvl 53)
    { "level", 54, at = { 1448, 62.07, 8.44 }, note = "About 11 more mobs near the last objective" }, -- farm de niveau
  },
})
