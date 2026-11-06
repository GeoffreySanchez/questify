local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 77 étapes, niveau final 57.03, ~65286 xp/h, 177 min.
Q:RegisterGuide({
  id = "H_28",
  title = "Felwood and Winterspring",
  faction = "Horde",
  minLevel = 56, maxLevel = 57,
  next = "H_29",
  sim = { steps = 77, endLevel = 57.03, xpPerHour = 65286, minutes = 177 },
  steps = {
    { "hearth", 1447 }, -- pierre de foyer
    { "goto", 1447, 21.96, 49.62, note = "Flight master" }, -- déplacement
    { "fly", 1448, node = 48, note = "Bloodvenom Post, Felwood" }, -- vol
    { "accept", 4521 }, -- Wild Guardians (lvl 56, ~5800 xp, sim lvl 56)
    { "fp", 1452, 60.47, 36.3 }, -- point de vol
    { "accept", 6603 }, -- Trouble in Winterspring! (lvl 56, ~580 xp, sim lvl 56)
    { "accept", 3783 }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 84399 }, -- Ka-Boom! (lvl 60, ~0 xp, sim lvl 56)
    { "accept", 5054 }, -- Ursius of the Shardtooth (lvl 56, ~5800 xp, sim lvl 56)
    { "accept", 969 }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "complete", 4521, obj = 1, at = { 1452, 60.94, 30.59 } }, -- Wild Guardians (lvl 56, ~5800 xp, sim lvl 56)
    { "complete", 5054, at = { 1452, 60.92, 32.9 } }, -- Ursius of the Shardtooth (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 5054, xp = 5800 }, -- Ursius of the Shardtooth (lvl 56, ~5800 xp, sim lvl 56)
    { "accept", 5055 }, -- Brumeran of the Chillwind (lvl 58, ~6200 xp, sim lvl 56)
    { "accept", 6030 }, -- Duke Nicholas Zverenhoff (lvl 52, ~0 xp, sim lvl 56)
    { "sethearth", 1452, 61.36, 38.83 }, -- lier la pierre de foyer
    { "accept", 6029 }, -- The Everlook Report (lvl 52, ~0 xp, sim lvl 56)
    { "accept", 5601 }, -- Sister Pamela (lvl 55, ~0 xp, sim lvl 56)
    { "complete", 4521, at = { 1452, 54.48, 37.45 } }, -- Wild Guardians (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 6603, xp = 580 }, -- Trouble in Winterspring! (lvl 56, ~580 xp, sim lvl 56)
    { "accept", 5082 }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 5083, xp = 2900 }, -- Winterfall Firewater (lvl 56, ~2900 xp, sim lvl 56)
    { "accept", 5084 }, -- Falling to Corruption (lvl 56, ~4350 xp, sim lvl 56)
    { "turnin", 980, xp = 2800 }, -- The New Springs (lvl 55, ~2800 xp, sim lvl 56)
    { "turnin", 5084, xp = 4350 }, -- Falling to Corruption (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 5085 }, -- Mystery Goo (lvl 56, ~4350 xp, sim lvl 56)
    { "turnin", 4521, xp = 5800 }, -- Wild Guardians (lvl 56, ~5800 xp, sim lvl 56)
    { "accept", 4741 }, -- Wild Guardians (lvl 58, ~6200 xp, sim lvl 56)
    { "goto", 1448, 34.44, 53.96, note = "Flight master" }, -- déplacement
    { "fly", 1452, node = 53, note = "Everlook, Winterspring" }, -- vol
    { "complete", 969, at = { 1452, 60.01, 66.39 } }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "complete", 5055, at = { 1452, 62.54, 57.9 } }, -- Brumeran of the Chillwind (lvl 58, ~6200 xp, sim lvl 56)
    { "complete", 3783, at = { 1452, 66.83, 42.67 } }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "turnin", 5055, xp = 6200 }, -- Brumeran of the Chillwind (lvl 58, ~6200 xp, sim lvl 56)
    { "accept", 5056 }, -- Shy-Rotam (lvl 60, ~8300 xp, sim lvl 56)
    { "turnin", 969, xp = 6600 }, -- Luck Be With You (lvl 60, ~6600 xp, sim lvl 56)
    { "accept", 975 }, -- Cache of Mau'ari (lvl 60, ~6600 xp, sim lvl 56)
    { "turnin", 3783, xp = 4350 }, -- Are We There, Yeti? (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 977 }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "complete", 4741, at = { 1452, 64.1, 21.8 } }, -- Wild Guardians (lvl 58, ~6200 xp, sim lvl 56)
    { "complete", 5056, at = { 1452, 49.81, 9.8 } }, -- Shy-Rotam (lvl 60, ~8300 xp, sim lvl 56)
    { "turnin", 5085, xp = 4350 }, -- Mystery Goo (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 5086 }, -- Toxic Horrors (lvl 56, ~4350 xp, sim lvl 56)
    { "complete", 5086, at = { 1448, 50.08, 23.49 } }, -- Toxic Horrors (lvl 56, ~4350 xp, sim lvl 56)
    { "turnin", 4741, xp = 6200 }, -- Wild Guardians (lvl 58, ~6200 xp, sim lvl 56)
    { "accept", 4721 }, -- Wild Guardians (lvl 59, ~6400 xp, sim lvl 56)
    { "turnin", 5086, xp = 4350 }, -- Toxic Horrors (lvl 56, ~4350 xp, sim lvl 56)
    { "accept", 5087 }, -- Winterfall Runners (lvl 57, ~6000 xp, sim lvl 56)
    { "accept", 8464 }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "turnin", 8465, xp = 560 }, -- Speak to Salfa (lvl 55, ~560 xp, sim lvl 56)
    { "complete", 5087, at = { 1452, 27.94, 34.47 } }, -- Winterfall Runners (lvl 57, ~6000 xp, sim lvl 56)
    { "turnin", 5087, xp = 6000 }, -- Winterfall Runners (lvl 57, ~6000 xp, sim lvl 56)
    { "accept", 5121 }, -- High Chief Winterfall (lvl 59, ~6400 xp, sim lvl 56)
    { "hearth", 1452 }, -- pierre de foyer
    { "accept", 4882, at = { 1452, 64.32, 22.19 }, note = "Loot Blue-feathered Necklace to start the quest" }, -- Guarding Secrets (lvl 59, ~3200 xp, sim lvl 56)
    { "complete", 4721, at = { 1452, 64.35, 22.54 } }, -- Wild Guardians (lvl 59, ~6400 xp, sim lvl 56)
    { "complete", 5082, obj = 2, at = { 1452, 66.47, 34.66 } }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "complete", 8464, at = { 1452, 67.73, 35.93 } }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "complete", 5121, at = { 1452, 69.56, 38.31 } }, -- High Chief Winterfall (lvl 59, ~6400 xp, sim lvl 56)
    { "accept", 5123, at = { 1452, 69.56, 38.31 }, note = "Loot Crudely-written Log to start the quest" }, -- The Final Piece (lvl 59, ~3200 xp, sim lvl 56)
    { "complete", 977, at = { 1452, 70.84, 39.16 } }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "turnin", 5056, xp = 8300 }, -- Shy-Rotam (lvl 60, ~8300 xp, sim lvl 56)
    { "accept", 5057 }, -- Past Endeavors (lvl 60, ~3300 xp, sim lvl 56)
    { "turnin", 5057, xp = 3300 }, -- Past Endeavors (lvl 60, ~3300 xp, sim lvl 56)
    { "complete", 975, at = { 1452, 61.92, 38.3 } }, -- Cache of Mau'ari (lvl 60, ~6600 xp, sim lvl 56)
    { "turnin", 975, xp = 6600 }, -- Cache of Mau'ari (lvl 60, ~6600 xp, sim lvl 56)
    { "complete", 84399, at = { 1452, 60.7, 37.7 } }, -- Ka-Boom! (lvl 60, ~0 xp, sim lvl 56)
    { "turnin", 977, xp = 4650 }, -- Are We There, Yeti? (lvl 58, ~4650 xp, sim lvl 56)
    { "complete", 5082, at = { 1452, 41.52, 43.15 } }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 5121, xp = 6400 }, -- High Chief Winterfall (lvl 59, ~6400 xp, sim lvl 56)
    { "turnin", 5123, xp = 3200 }, -- The Final Piece (lvl 59, ~3200 xp, sim lvl 56)
    { "turnin", 5082, xp = 5800 }, -- Threat of the Winterfall (lvl 56, ~5800 xp, sim lvl 56)
    { "turnin", 8464, xp = 6200 }, -- Winterfall Activity (lvl 58, ~6200 xp, sim lvl 56)
    { "accept", 84397 }, -- Northern Kalimdor - A Comprehensive Guide (lvl 60, ~0 xp, sim lvl 56)
    { "complete", 84397, at = { 1448, 65.2, 3.3 } }, -- Northern Kalimdor - A Comprehensive Guide (lvl 60, ~0 xp, sim lvl 56)
    { "turnin", 4721, xp = 6400 }, -- Wild Guardians (lvl 59, ~6400 xp, sim lvl 56)
    { "turnin", 4882, xp = 3200 }, -- Guarding Secrets (lvl 59, ~3200 xp, sim lvl 57)
  },
})
