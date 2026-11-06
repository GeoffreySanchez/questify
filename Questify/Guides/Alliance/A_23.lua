local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 97 étapes, niveau final 58.00, ~91553 xp/h, 128 min.
Q:RegisterGuide({
  id = "A_23",
  title = "Western Plaguelands",
  faction = "Alliance",
  minLevel = 57, maxLevel = 58,
  next = "A_29",
  sim = { steps = 97, endLevel = 58.00, xpPerHour = 91553, minutes = 128 },
  steps = {
    { "note", "Not running Blackrock Depths? Abandon Ribbly Screwspigot", optional = true, dungeon = "Blackrock Depths" },
    { "goto", 1448, 62.49, 24.24, note = "Flight master" }, -- déplacement
    { "fly", 1439, node = 26, note = "Auberdine, Darkshore" }, -- vol
    { "boat", 1439, 32.4, 43.8, note = "Take the boat to Menethil Harbor" }, -- bateau
    { "goto", 1437, 9.49, 59.69, note = "Flight master" }, -- déplacement
    { "fly", 1424, node = 14, note = "Southshore, Hillsbrad" }, -- vol
    { "fp", 1422, 42.92, 85.06 }, -- point de vol
    { "accept", 5092 }, -- Clear the Way (lvl 52, ~5100 xp, sim lvl 57)
    { "accept", 5401 }, -- Argent Dawn Commission (lvl 55, ~560 xp, sim lvl 57)
    { "turnin", 6028, xp = 2550 }, -- The Everlook Report (lvl 52, ~2550 xp, sim lvl 57)
    { "turnin", 5401, xp = 560 }, -- Argent Dawn Commission (lvl 55, ~560 xp, sim lvl 57)
    { "accept", 5343, optional = true, dungeon = "Scholomance" }, -- Barov Family Fortune (lvl 60, ~0 xp, sim lvl 57)
    { "complete", 5092, at = { 1422, 37.47, 56.15 } }, -- Clear the Way (lvl 52, ~5100 xp, sim lvl 57)
    { "accept", 4971 }, -- A Matter of Time (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 5092, xp = 5100 }, -- Clear the Way (lvl 52, ~5100 xp, sim lvl 57)
    { "accept", 5097 }, -- All Along the Watchtowers (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 5215 }, -- The Scourge Cauldrons (lvl 53, ~530 xp, sim lvl 57)
    { "turnin", 5215, xp = 530 }, -- The Scourge Cauldrons (lvl 53, ~530 xp, sim lvl 57)
    { "accept", 5216 }, -- Target: Felstone Field (lvl 53, ~5250 xp, sim lvl 57)
    { "complete", 5097, obj = 1, at = { 1422, 40.05, 71.6 } }, -- All Along the Watchtowers (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 5216, at = { 1422, 36.93, 57.41 } }, -- Target: Felstone Field (lvl 53, ~5250 xp, sim lvl 57)
    { "turnin", 5216, xp = 5250 }, -- Target: Felstone Field (lvl 53, ~5250 xp, sim lvl 57)
    { "accept", 5217 }, -- Return to Chillwind Camp (lvl 53, ~2650 xp, sim lvl 57)
    { "complete", 5097, at = { 1422, 42.33, 66.24 } }, -- All Along the Watchtowers (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 5097, at = { 1422, 46.62, 71.05 } }, -- All Along the Watchtowers (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 5217, xp = 2650 }, -- Return to Chillwind Camp (lvl 53, ~2650 xp, sim lvl 57)
    { "accept", 5219 }, -- Target: Dalson's Tears (lvl 55, ~5650 xp, sim lvl 57)
    { "turnin", 5097, xp = 5800 }, -- All Along the Watchtowers (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 5533 }, -- Scholomance (lvl 55, ~560 xp, sim lvl 57)
    { "accept", 211 }, -- Alas, Andorhal (lvl 60, ~8300 xp, sim lvl 57)
    { "turnin", 5533, xp = 560 }, -- Scholomance (lvl 55, ~560 xp, sim lvl 57)
    { "accept", 5537 }, -- Skeletal Fragments (lvl 57, ~4500 xp, sim lvl 57)
    { "complete", 211, at = { 1422, 45.27, 69.21 } }, -- Alas, Andorhal (lvl 60, ~8300 xp, sim lvl 57)
    { "complete", 5537, at = { 1422, 44.06, 68.48 } }, -- Skeletal Fragments (lvl 57, ~4500 xp, sim lvl 57)
    { "complete", 5219, at = { 1422, 46.11, 52.61 } }, -- Target: Dalson's Tears (lvl 55, ~5650 xp, sim lvl 57)
    { "turnin", 5219, xp = 5650 }, -- Target: Dalson's Tears (lvl 55, ~5650 xp, sim lvl 57)
    { "accept", 5220 }, -- Return to Chillwind Camp (lvl 55, ~2800 xp, sim lvl 57)
    { "accept", 5058 }, -- Mrs. Dalson's Diary (lvl 55, ~1400 xp, sim lvl 57)
    { "turnin", 5058, xp = 1400 }, -- Mrs. Dalson's Diary (lvl 55, ~1400 xp, sim lvl 57)
    { "accept", 5060 }, -- Locked Away (lvl 55, ~7050 xp, sim lvl 57)
    { "complete", 5060, at = { 1422, 48.23, 49.67 } }, -- Locked Away (lvl 55, ~7050 xp, sim lvl 57)
    { "turnin", 5060, xp = 7050 }, -- Locked Away (lvl 55, ~7050 xp, sim lvl 57)
    { "accept", 6004 }, -- Unfinished Business (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 6004, at = { 1422, 51.17, 40.34 } }, -- Unfinished Business (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 4984 }, -- The Wildlife Suffers Too (lvl 54, ~4100 xp, sim lvl 57)
    { "complete", 4971, at = { 1422, 48.03, 64.46 } }, -- A Matter of Time (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 5220, xp = 2800 }, -- Return to Chillwind Camp (lvl 55, ~2800 xp, sim lvl 57)
    { "accept", 5222 }, -- Target: Writhing Haunt (lvl 55, ~5650 xp, sim lvl 57)
    { "turnin", 5537, xp = 4500 }, -- Skeletal Fragments (lvl 57, ~4500 xp, sim lvl 57)
    { "turnin", 211, xp = 8300 }, -- Alas, Andorhal (lvl 60, ~8300 xp, sim lvl 57)
    { "turnin", 4971, xp = 5800 }, -- A Matter of Time (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 4972 }, -- Counting Out Time (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 4972, at = { 1422, 39.98, 68.21 } }, -- Counting Out Time (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 4972, xp = 5800 }, -- Counting Out Time (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 84395 }, -- Undead Potatoes (lvl 60, ~6600 xp, sim lvl 57)
    { "accept", 5021 }, -- Better Late Than Never (lvl 52, ~2550 xp, sim lvl 57)
    { "turnin", 5021, xp = 2550 }, -- Better Late Than Never (lvl 52, ~2550 xp, sim lvl 57)
    { "accept", 5022 }, -- Better Late Than Never (lvl 52, ~2550 xp, sim lvl 57)
    { "complete", 84395, at = { 1422, 38.2, 54.6 } }, -- Undead Potatoes (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 6004, at = { 1422, 40.66, 51.85 } }, -- Unfinished Business (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 4984, at = { 1422, 46.24, 45.57 } }, -- The Wildlife Suffers Too (lvl 54, ~4100 xp, sim lvl 57)
    { "turnin", 6004, xp = 5800 }, -- Unfinished Business (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 6023 }, -- Unfinished Business (lvl 57, ~6000 xp, sim lvl 57)
    { "complete", 6023, obj = 2, at = { 1422, 55.15, 23.62 } }, -- Unfinished Business (lvl 57, ~6000 xp, sim lvl 57)
    { "complete", 6023, at = { 1422, 57.83, 36.1 } }, -- Unfinished Business (lvl 57, ~6000 xp, sim lvl 57)
    { "turnin", 6023, xp = 6000 }, -- Unfinished Business (lvl 57, ~6000 xp, sim lvl 57)
    { "accept", 6025 }, -- Unfinished Business (lvl 58, ~6200 xp, sim lvl 57)
    { "complete", 6025, at = { 1422, 45.81, 18.25 } }, -- Unfinished Business (lvl 58, ~6200 xp, sim lvl 57)
    { "turnin", 6025, xp = 6200 }, -- Unfinished Business (lvl 58, ~6200 xp, sim lvl 57)
    { "turnin", 4984, xp = 4100 }, -- The Wildlife Suffers Too (lvl 54, ~4100 xp, sim lvl 57)
    { "accept", 4985 }, -- The Wildlife Suffers Too (lvl 56, ~4350 xp, sim lvl 57)
    { "complete", 5222, at = { 1422, 52.88, 66.08 } }, -- Target: Writhing Haunt (lvl 55, ~5650 xp, sim lvl 57)
    { "turnin", 5222, xp = 5650 }, -- Target: Writhing Haunt (lvl 55, ~5650 xp, sim lvl 57)
    { "accept", 5223 }, -- Return to Chillwind Camp (lvl 55, ~5650 xp, sim lvl 57)
    { "turnin", 5223, xp = 5650 }, -- Return to Chillwind Camp (lvl 55, ~5650 xp, sim lvl 57)
    { "accept", 5225 }, -- Target: Gahrron's Withering (lvl 58, ~6200 xp, sim lvl 57)
    { "accept", 5382, optional = true, dungeon = "Scholomance" }, -- Doctor Theolen Krastinov, the Butcher (lvl 60, ~0 xp, sim lvl 57)
    { "accept", 84402 }, -- Necromancy 101 (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 84402, at = { 1422, 69.41, 72.84 } }, -- Necromancy 101 (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 5225, at = { 1422, 62.18, 59.06 } }, -- Target: Gahrron's Withering (lvl 58, ~6200 xp, sim lvl 57)
    { "turnin", 5225, xp = 6200 }, -- Target: Gahrron's Withering (lvl 58, ~6200 xp, sim lvl 57)
    { "accept", 5226 }, -- Return to Chillwind Camp (lvl 58, ~3100 xp, sim lvl 57)
    { "complete", 4985, at = { 1422, 64.84, 47.98 } }, -- The Wildlife Suffers Too (lvl 56, ~4350 xp, sim lvl 57)
    { "turnin", 4985, xp = 4350 }, -- The Wildlife Suffers Too (lvl 56, ~4350 xp, sim lvl 57)
    { "turnin", 5226, xp = 3100 }, -- Return to Chillwind Camp (lvl 58, ~3100 xp, sim lvl 57)
    { "accept", 5237 }, -- Mission Accomplished! (lvl 58, ~9300 xp, sim lvl 57)
    { "turnin", 5237, xp = 9300 }, -- Mission Accomplished! (lvl 58, ~9300 xp, sim lvl 57)
    { "goto", 1422, 42.92, 85.06, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "turnin", 5022, xp = 2550 }, -- Better Late Than Never (lvl 52, ~2550 xp, sim lvl 57)
    { "turnin", 84395, xp = 6600 }, -- Undead Potatoes (lvl 60, ~6600 xp, sim lvl 57)
    { "turnin", 84397, xp = 6600 }, -- Northern Kalimdor - A Comprehensive Guide (lvl 60, ~6600 xp, sim lvl 57)
    { "turnin", 84399, xp = 6600 }, -- Ka-Boom! (lvl 60, ~6600 xp, sim lvl 57)
    { "turnin", 84402, xp = 6600 }, -- Necromancy 101 (lvl 60, ~6600 xp, sim lvl 57)
    { "level", 58, at = { 1422, 64.84, 47.98 }, note = "About 51 more mobs near the last objective" }, -- farm de niveau
  },
})
