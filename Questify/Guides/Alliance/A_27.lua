local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 48 étapes, niveau final 57.00, ~55796 xp/h, 202 min.
Q:RegisterGuide({
  id = "A_27",
  title = "Winterspring",
  faction = "Alliance",
  minLevel = 56, maxLevel = 57,
  next = "A_23",
  sim = { steps = 48, endLevel = 57.00, xpPerHour = 55796, minutes = 202 },
  steps = {
    { "hearth", 1446 }, -- pierre de foyer
    { "goto", 1446, 51.01, 29.34, note = "Flight master" }, -- déplacement
    { "fly", 1448, node = 65, note = "Talonbranch Glade, Felwood" }, -- vol
    { "fp", 1452, 62.33, 36.61 }, -- point de vol
    { "accept", 5601 }, -- Sister Pamela (lvl 55, ~0 xp, sim lvl 56)
    { "accept", 6030 }, -- Duke Nicholas Zverenhoff (lvl 52, ~0 xp, sim lvl 56)
    { "accept", 6028 }, -- The Everlook Report (lvl 52, ~0 xp, sim lvl 56)
    { "accept", 6604 }, -- Enraged Wildkin (lvl 59, ~640 xp, sim lvl 56)
    { "accept", 6603 }, -- Trouble in Winterspring! (lvl 56, ~580 xp, sim lvl 56)
    { "accept", 3783 }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 969 }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "turnin", 5249, xp = 580 }, -- To Winterspring! (lvl 56, ~580 xp, sim lvl 56)
    { "accept", 5244 }, -- The Ruins of Kel'Theril (lvl 56, ~580 xp, sim lvl 56)
    { "turnin", 5244, xp = 580 }, -- The Ruins of Kel'Theril (lvl 56, ~580 xp, sim lvl 56)
    { "turnin", 6604, xp = 640 }, -- Enraged Wildkin (lvl 59, ~640 xp, sim lvl 56)
    { "accept", 5245 }, -- Troubled Spirits of Kel'Theril (lvl 56, ~0 xp, sim lvl 56)
    { "accept", 4861 }, -- Enraged Wildkin (lvl 59, ~3200 xp, sim lvl 56)
    { "accept", 8464 }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "turnin", 8465, xp = 560 }, -- Speak to Salfa (lvl 55, ~560 xp, sim lvl 56)
    { "turnin", 6603, xp = 580 }, -- Trouble in Winterspring! (lvl 56, ~580 xp, sim lvl 56)
    { "turnin", 980, xp = 2800 }, -- The New Springs (lvl 55, ~2800 xp, sim lvl 56)
    { "accept", 4842 }, -- Strange Sources (lvl 56, ~5800 xp, sim lvl 56)
    { "accept", 5082 }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 5083, xp = 2900 }, -- Winterfall Firewater (lvl 56, ~2900 xp, sim lvl 56)
    { "complete", 4842, at = { 1452, 59.82, 74.25 } }, -- Strange Sources (lvl 56, ~5800 xp, sim lvl 56)
    { "complete", 969, at = { 1452, 60.01, 66.39 } }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "turnin", 4861, xp = 3200 }, -- Enraged Wildkin (lvl 59, ~3200 xp, sim lvl 56)
    { "accept", 4863 }, -- Enraged Wildkin (lvl 59, ~3200 xp, sim lvl 56)
    { "turnin", 4863, xp = 3200 }, -- Enraged Wildkin (lvl 59, ~3200 xp, sim lvl 56)
    { "accept", 4864 }, -- Enraged Wildkin (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 4864, obj = 1, at = { 1452, 61.4, 60.73 } }, -- Enraged Wildkin (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 4864, at = { 1452, 64.77, 59.76 } }, -- Enraged Wildkin (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 3783, at = { 1452, 66.83, 42.67 } }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "turnin", 969, xp = 6600 }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "turnin", 3783, xp = 4350 }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 977 }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "complete", 977, at = { 1452, 70.84, 39.16 } }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "complete", 8464, at = { 1452, 67.73, 35.93 } }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "complete", 5082, obj = 2, at = { 1452, 66.47, 34.66 } }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 977, xp = 4650 }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "complete", 5245, at = { 1452, 55.14, 42.98 } }, -- Troubled Spirits of Kel'Theril (lvl 56, ~0 xp, sim lvl 56)
    { "complete", 5245, at = { 1452, 50.88, 41.71 } }, -- Troubled Spirits of Kel'Theril (lvl 56, ~0 xp, sim lvl 56)
    { "turnin", 4864, xp = 6400 }, -- Enraged Wildkin (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 5082, at = { 1452, 41.52, 43.15 } }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 5082, xp = 5800 }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 4842, xp = 5800 }, -- Strange Sources (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 8464, xp = 6200 }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "level", 57, at = { 1452, 41.52, 43.15 }, note = "About 350 more mobs near the last objective" }, -- farm de niveau
  },
})
