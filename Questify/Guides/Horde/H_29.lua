local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 88 étapes, niveau final 59.00, ~64186 xp/h, 367 min.
Q:RegisterGuide({
  id = "H_29",
  title = "Western Plaguelands and Eastern Plaguelands",
  faction = "Horde",
  minLevel = 57, maxLevel = 59,
  next = "H_30",
  sim = { steps = 88, endLevel = 59.00, xpPerHour = 64186, minutes = 367 },
  steps = {
    { "note", "Not running Blackrock Depths? Abandon Ribbly Screwspigot", optional = true, dungeon = "Blackrock Depths" },
    { "goto", 1440, 73.18, 61.59, note = "Flight master" }, -- déplacement
    { "fly", 1454, node = 23, note = "Orgrimmar, Durotar" }, -- vol
    { "boat", 1411, 50.8, 13.5, note = "Take the zeppelin to Undercity (Tirisfal Glades)" }, -- bateau
    { "accept", 5021 }, -- Better Late Than Never (lvl 52, ~2550 xp, sim lvl 57)
    { "turnin", 5021, xp = 2550 }, -- Better Late Than Never (lvl 52, ~2550 xp, sim lvl 57)
    { "accept", 4971 }, -- A Matter of Time (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 4971, at = { 1422, 48.03, 64.46 } }, -- A Matter of Time (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 4984 }, -- The Wildlife Suffers Too (lvl 54, ~4100 xp, sim lvl 57)
    { "accept", 5058 }, -- Mrs. Dalson's Diary (lvl 55, ~1400 xp, sim lvl 57)
    { "turnin", 5058, xp = 1400 }, -- Mrs. Dalson's Diary (lvl 55, ~1400 xp, sim lvl 57)
    { "accept", 5060 }, -- Locked Away (lvl 55, ~7050 xp, sim lvl 57)
    { "complete", 5060, at = { 1422, 48.23, 49.67 } }, -- Locked Away (lvl 55, ~7050 xp, sim lvl 57)
    { "turnin", 5060, xp = 7050 }, -- Locked Away (lvl 55, ~7050 xp, sim lvl 57)
    { "accept", 6004 }, -- Unfinished Business (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 6004, at = { 1422, 51.17, 40.34 } }, -- Unfinished Business (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 4984, at = { 1422, 46.24, 45.57 } }, -- The Wildlife Suffers Too (lvl 54, ~4100 xp, sim lvl 57)
    { "complete", 6004, at = { 1422, 40.66, 51.85 } }, -- Unfinished Business (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 4971, xp = 5800 }, -- A Matter of Time (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 4972 }, -- Counting Out Time (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 4972, at = { 1422, 39.98, 68.21 } }, -- Counting Out Time (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 4972, xp = 5800 }, -- Counting Out Time (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 4984, xp = 4100 }, -- The Wildlife Suffers Too (lvl 54, ~4100 xp, sim lvl 57)
    { "accept", 4985 }, -- The Wildlife Suffers Too (lvl 56, ~4350 xp, sim lvl 57)
    { "complete", 4985, at = { 1422, 64.84, 47.98 } }, -- The Wildlife Suffers Too (lvl 56, ~4350 xp, sim lvl 57)
    { "turnin", 6004, xp = 5800 }, -- Unfinished Business (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 6023 }, -- Unfinished Business (lvl 57, ~6000 xp, sim lvl 57)
    { "accept", 5542 }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 5544 }, -- Carrion Grubbage (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 5543 }, -- Blood Tinged Skies (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 6023, obj = 2, at = { 1422, 55.15, 23.62 } }, -- Unfinished Business (lvl 57, ~6000 xp, sim lvl 57)
    { "complete", 6023, at = { 1422, 57.83, 36.1 } }, -- Unfinished Business (lvl 57, ~6000 xp, sim lvl 57)
    { "turnin", 6023, xp = 6000 }, -- Unfinished Business (lvl 57, ~6000 xp, sim lvl 57)
    { "accept", 6025 }, -- Unfinished Business (lvl 58, ~6200 xp, sim lvl 57)
    { "complete", 6025, at = { 1422, 45.81, 18.25 } }, -- Unfinished Business (lvl 58, ~6200 xp, sim lvl 57)
    { "turnin", 6025, xp = 6200 }, -- Unfinished Business (lvl 58, ~6200 xp, sim lvl 57)
    { "turnin", 4985, xp = 4350 }, -- The Wildlife Suffers Too (lvl 56, ~4350 xp, sim lvl 57)
    { "accept", 5382, optional = true, dungeon = "Scholomance" }, -- Doctor Theolen Krastinov, the Butcher (lvl 60, ~0 xp, sim lvl 57)
    { "complete", 5543, at = { 1423, 13.96, 66.95 } }, -- Blood Tinged Skies (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 5544, at = { 1423, 13.83, 65.59 } }, -- Carrion Grubbage (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 5542, obj = 1, at = { 1423, 14.95, 67.41 } }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 57)
    { "accept", 6024 }, -- Hameya's Plea (lvl 60, ~6600 xp, sim lvl 57)
    { "accept", 6042 }, -- Un-Life's Little Annoyances (lvl 58, ~6200 xp, sim lvl 57)
    { "accept", 6133 }, -- The Ranger Lord's Behest (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 6042, obj = 1, at = { 1423, 42.12, 52.95 } }, -- Un-Life's Little Annoyances (lvl 58, ~6200 xp, sim lvl 57)
    { "complete", 5542, obj = 2, at = { 1423, 46.24, 51.84 } }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 57)
    { "fp", 1423, 70.53, 47.55 }, -- point de vol
    { "accept", 5281 }, -- The Restless Souls (lvl 60, ~6600 xp, sim lvl 57)
    { "accept", 6021 }, -- Zaeldarr the Outcast (lvl 55, ~4200 xp, sim lvl 57)
    { "turnin", 6030, xp = 2550 }, -- Duke Nicholas Zverenhoff (lvl 52, ~2550 xp, sim lvl 57)
    { "accept", 5251, optional = true, dungeon = "Stratholme" }, -- The Archivist (lvl 60, ~0 xp, sim lvl 57)
    { "accept", 5503 }, -- Argent Dawn Commission (lvl 55, ~560 xp, sim lvl 57)
    { "turnin", 5503, xp = 560 }, -- Argent Dawn Commission (lvl 55, ~560 xp, sim lvl 57)
    { "accept", 5211 }, -- Defenders of Darrowshire (lvl 55, ~5650 xp, sim lvl 57)
    { "accept", 5212, optional = true, dungeon = "Stratholme" }, -- The Flesh Does Not Lie (lvl 60, ~0 xp, sim lvl 57)
    { "accept", 5243, optional = true, dungeon = "Stratholme" }, -- Houses of the Holy (lvl 60, ~0 xp, sim lvl 57)
    { "accept", 9665 }, -- Bolstering Our Defenses (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 5211, at = { 1423, 57.48, 31.44 } }, -- Defenders of Darrowshire (lvl 55, ~5650 xp, sim lvl 57)
    { "complete", 6024, at = { 1423, 61.96, 11.11 } }, -- Hameya's Plea (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 6133, at = { 1423, 46.71, 11.83 } }, -- The Ranger Lord's Behest (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 9665, obj = 3, at = { 1423, 49.25, 18.2 } }, -- Bolstering Our Defenses (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 6042, at = { 1423, 45.11, 34.45 } }, -- Un-Life's Little Annoyances (lvl 58, ~6200 xp, sim lvl 57)
    { "complete", 5542, at = { 1423, 28.26, 33.69 } }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 57)
    { "complete", 9665, obj = 4, at = { 1423, 18.16, 25.06 } }, -- Bolstering Our Defenses (lvl 60, ~6600 xp, sim lvl 57)
    { "accept", 6164 }, -- Augustus' Receipt Book (lvl 55, ~1400 xp, sim lvl 57)
    { "turnin", 5281, xp = 6600 }, -- The Restless Souls (lvl 60, ~6600 xp, sim lvl 57)
    { "accept", 5282, optional = true, dungeon = "Stratholme" }, -- The Restless Souls (lvl 60, ~0 xp, sim lvl 57)
    { "complete", 6164, at = { 1423, 14.04, 24.22 } }, -- Augustus' Receipt Book (lvl 55, ~1400 xp, sim lvl 57)
    { "turnin", 6164, xp = 1400 }, -- Augustus' Receipt Book (lvl 55, ~1400 xp, sim lvl 57)
    { "turnin", 5543, xp = 5800 }, -- Blood Tinged Skies (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 5544, xp = 5800 }, -- Carrion Grubbage (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 5542, xp = 5800 }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 57)
    { "turnin", 6042, xp = 6200 }, -- Un-Life's Little Annoyances (lvl 58, ~6200 xp, sim lvl 57)
    { "turnin", 6133, xp = 6600 }, -- The Ranger Lord's Behest (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 6021, at = { 1423, 23.07, 72.63 } }, -- Zaeldarr the Outcast (lvl 55, ~4200 xp, sim lvl 57)
    { "turnin", 6024, xp = 6600 }, -- Hameya's Plea (lvl 60, ~6600 xp, sim lvl 57)
    { "turnin", 5601, xp = 560 }, -- Sister Pamela (lvl 55, ~560 xp, sim lvl 57)
    { "complete", 9665, obj = 1, at = { 1423, 34.09, 64.1 } }, -- Bolstering Our Defenses (lvl 60, ~6600 xp, sim lvl 57)
    { "complete", 9665, at = { 1423, 59.04, 39.41 } }, -- Bolstering Our Defenses (lvl 60, ~6600 xp, sim lvl 57)
    { "turnin", 9665, xp = 6600 }, -- Bolstering Our Defenses (lvl 60, ~6600 xp, sim lvl 57)
    { "accept", 5214, optional = true, dungeon = "Stratholme" }, -- The Great Ezra Grimm (lvl 60, ~0 xp, sim lvl 57)
    { "turnin", 5211, xp = 5650 }, -- Defenders of Darrowshire (lvl 55, ~5650 xp, sim lvl 57)
    { "accept", 5529, optional = true, dungeon = "Scholomance" }, -- Plagued Hatchlings (lvl 58, ~0 xp, sim lvl 57)
    { "turnin", 6021, xp = 4200 }, -- Zaeldarr the Outcast (lvl 55, ~4200 xp, sim lvl 57)
    { "level", 59, at = { 1423, 67.8, 43.65 }, note = "About 662 more mobs here (Diseased Flayer, level 58)" }, -- farm de niveau
  },
})
