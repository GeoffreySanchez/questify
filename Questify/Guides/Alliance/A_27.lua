local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 67 étapes, niveau final 57.00, ~69091 xp/h, 163 min.
Q:RegisterGuide({
  id = "A_27",
  title = "Felwood and Winterspring",
  faction = "Alliance",
  minLevel = 56, maxLevel = 57,
  next = "A_23",
  sim = { steps = 67, endLevel = 57.00, xpPerHour = 69091, minutes = 163 },
  steps = {
    { "accept", 969 }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "accept", 4809 }, -- Chillwind Horns (lvl 54, ~5450 xp, sim lvl 56)
    { "accept", 6604 }, -- Enraged Wildkin (lvl 59, ~640 xp, sim lvl 56)
    { "accept", 5601 }, -- Sister Pamela (lvl 55, ~0 xp, sim lvl 56)
    { "accept", 6028 }, -- The Everlook Report (lvl 52, ~0 xp, sim lvl 56)
    { "sethearth", 1452, 61.36, 38.83 }, -- lier la pierre de foyer
    { "accept", 6030 }, -- Duke Nicholas Zverenhoff (lvl 52, ~0 xp, sim lvl 56)
    { "accept", 6603 }, -- Trouble in Winterspring! (lvl 56, ~580 xp, sim lvl 56)
    { "accept", 3783 }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 84399 }, -- Ka-Boom! (lvl 60, ~0 xp, sim lvl 56)
    { "turnin", 6604, xp = 640 }, -- Enraged Wildkin (lvl 59, ~640 xp, sim lvl 56)
    { "accept", 4861 }, -- Enraged Wildkin (lvl 59, ~3200 xp, sim lvl 56)
    { "accept", 5244 }, -- The Ruins of Kel'Theril (lvl 56, ~580 xp, sim lvl 56)
    { "turnin", 5244, xp = 580 }, -- The Ruins of Kel'Theril (lvl 56, ~580 xp, sim lvl 56)
    { "accept", 5245 }, -- Troubled Spirits of Kel'Theril (lvl 56, ~0 xp, sim lvl 56)
    { "accept", 5084 }, -- Falling to Corruption (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 4842 }, -- Strange Sources (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 6603, xp = 580 }, -- Trouble in Winterspring! (lvl 56, ~580 xp, sim lvl 56)
    { "accept", 5082 }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 5084, xp = 4350 }, -- Falling to Corruption (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 5085 }, -- Mystery Goo (lvl 56, ~4350 xp, sim lvl 56)
    { "turnin", 5085, xp = 4350 }, -- Mystery Goo (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 5086 }, -- Toxic Horrors (lvl 56, ~4350 xp, sim lvl 56)
    { "complete", 5086, at = { 1448, 50.08, 23.49 } }, -- Toxic Horrors (lvl 56, ~4350 xp, sim lvl 56)
    { "turnin", 5086, xp = 4350 }, -- Toxic Horrors (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 5087 }, -- Winterfall Runners (lvl 57, ~6000 xp, sim lvl 56)
    { "complete", 4842, at = { 1452, 59.82, 74.25 } }, -- Strange Sources (lvl 56, ~5800 xp, sim lvl 56)
    { "complete", 969, at = { 1452, 60.01, 66.39 } }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "turnin", 4861, xp = 3200 }, -- Enraged Wildkin (lvl 59, ~3200 xp, sim lvl 56)
    { "accept", 4863 }, -- Enraged Wildkin (lvl 59, ~3200 xp, sim lvl 56)
    { "turnin", 4863, xp = 3200 }, -- Enraged Wildkin (lvl 59, ~3200 xp, sim lvl 56)
    { "accept", 4864 }, -- Enraged Wildkin (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 4864, obj = 1, at = { 1452, 61.4, 60.73 } }, -- Enraged Wildkin (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 4864, at = { 1452, 64.77, 59.76 } }, -- Enraged Wildkin (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 4809, at = { 1452, 67.12, 50.22 } }, -- Chillwind Horns (lvl 54, ~5450 xp, sim lvl 56)
    { "complete", 3783, at = { 1452, 66.83, 42.67 } }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "turnin", 969, xp = 6600 }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "accept", 975 }, -- Cache of Mau'ari (lvl 60, ~6600 xp, sim lvl 56)
    { "turnin", 4809, xp = 5450 }, -- Chillwind Horns (lvl 54, ~5450 xp, sim lvl 56)
    { "complete", 975, at = { 1452, 61.92, 38.3 } }, -- Cache of Mau'ari (lvl 60, ~6600 xp, sim lvl 56)
    { "turnin", 975, xp = 6600 }, -- Cache of Mau'ari (lvl 60, ~6600 xp, sim lvl 56)
    { "complete", 84399, at = { 1452, 60.7, 37.7 } }, -- Ka-Boom! (lvl 60, ~0 xp, sim lvl 56)
    { "turnin", 3783, xp = 4350 }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 977 }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "turnin", 4864, xp = 6400 }, -- Enraged Wildkin (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 5087, at = { 1452, 27.94, 34.47 } }, -- Winterfall Runners (lvl 57, ~6000 xp, sim lvl 56)
    { "accept", 8464 }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "turnin", 5087, xp = 6000 }, -- Winterfall Runners (lvl 57, ~6000 xp, sim lvl 56)
    { "turnin", 4842, xp = 5800 }, -- Strange Sources (lvl 56, ~5800 xp, sim lvl 56)
    { "accept", 5121 }, -- High Chief Winterfall (lvl 59, ~6400 xp, sim lvl 56)
    { "hearth", 1452 }, -- pierre de foyer
    { "complete", 5245, at = { 1452, 55.14, 42.98 } }, -- Troubled Spirits of Kel'Theril (lvl 56, ~0 xp, sim lvl 56)
    { "complete", 977, at = { 1452, 70.84, 39.16 } }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "complete", 5121, at = { 1452, 69.56, 38.31 } }, -- High Chief Winterfall (lvl 59, ~6400 xp, sim lvl 56)
    { "accept", 5123, at = { 1452, 69.56, 38.31 }, note = "Loot Crudely-written Log to start the quest" }, -- The Final Piece (lvl 59, ~3200 xp, sim lvl 56)
    { "complete", 8464, at = { 1452, 67.73, 35.93 } }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "complete", 5082, obj = 2, at = { 1452, 66.47, 34.66 } }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 977, xp = 4650 }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "complete", 5245, at = { 1452, 50.88, 41.71 } }, -- Troubled Spirits of Kel'Theril (lvl 56, ~0 xp, sim lvl 56)
    { "complete", 5082, at = { 1452, 41.52, 43.15 } }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 5121, xp = 6400 }, -- High Chief Winterfall (lvl 59, ~6400 xp, sim lvl 56)
    { "turnin", 5123, xp = 3200 }, -- The Final Piece (lvl 59, ~3200 xp, sim lvl 56)
    { "turnin", 5082, xp = 5800 }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 8464, xp = 6200 }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "accept", 84397 }, -- Northern Kalimdor - A Comprehensive Guide (lvl 60, ~0 xp, sim lvl 56)
    { "complete", 84397, at = { 1448, 65.2, 3.3 } }, -- Northern Kalimdor - A Comprehensive Guide (lvl 60, ~0 xp, sim lvl 56)
    { "level", 57, at = { 1452, 41.52, 43.15 }, note = "About 73 more mobs near the last objective" }, -- farm de niveau
  },
})
