local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 52 étapes, niveau final 59.00, ~58821 xp/h, 206 min.
Q:RegisterGuide({
  id = "A_29",
  title = "Eastern Plaguelands",
  faction = "Alliance",
  minLevel = 58, maxLevel = 59,
  next = "A_30",
  sim = { steps = 52, endLevel = 59.00, xpPerHour = 58821, minutes = 206 },
  steps = {
    { "goto", 1453, 71.29, 72.23, note = "Flight master" }, -- déplacement
    { "fly", 1417, node = 16, note = "Refuge Pointe, Arathi" }, -- vol
    { "fp", 1423, 71.81, 49.6 }, -- point de vol
    { "accept", 9664 }, -- Establishing New Outposts (lvl 60, ~6600 xp, sim lvl 58)
    { "accept", 5211 }, -- Defenders of Darrowshire (lvl 55, ~5650 xp, sim lvl 58)
    { "turnin", 6030, xp = 2040 }, -- Duke Nicholas Zverenhoff (lvl 52, ~2040 xp, sim lvl 58)
    { "accept", 5251, optional = true, dungeon = "Stratholme" }, -- The Archivist (lvl 60, ~0 xp, sim lvl 58)
    { "accept", 5212, optional = true, dungeon = "Stratholme" }, -- The Flesh Does Not Lie (lvl 60, ~0 xp, sim lvl 58)
    { "accept", 6021 }, -- Zaeldarr the Outcast (lvl 55, ~4200 xp, sim lvl 58)
    { "accept", 5281 }, -- The Restless Souls (lvl 60, ~6600 xp, sim lvl 58)
    { "turnin", 5601, xp = 560 }, -- Sister Pamela (lvl 55, ~560 xp, sim lvl 58)
    { "accept", 6024 }, -- Hameya's Plea (lvl 60, ~6600 xp, sim lvl 58)
    { "accept", 5543 }, -- Blood Tinged Skies (lvl 56, ~5800 xp, sim lvl 58)
    { "accept", 5542 }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 58)
    { "accept", 5544 }, -- Carrion Grubbage (lvl 56, ~5800 xp, sim lvl 58)
    { "accept", 6164 }, -- Augustus' Receipt Book (lvl 55, ~1400 xp, sim lvl 58)
    { "turnin", 5281, xp = 6600 }, -- The Restless Souls (lvl 60, ~6600 xp, sim lvl 58)
    { "accept", 5282, optional = true, dungeon = "Stratholme" }, -- The Restless Souls (lvl 60, ~0 xp, sim lvl 58)
    { "complete", 6164, at = { 1423, 14.04, 24.22 } }, -- Augustus' Receipt Book (lvl 55, ~1400 xp, sim lvl 58)
    { "complete", 5542, obj = 3, at = { 1423, 28.26, 33.69 } }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 58)
    { "turnin", 5245, xp = 5800 }, -- Troubled Spirits of Kel'Theril (lvl 56, ~5800 xp, sim lvl 58)
    { "complete", 6024, at = { 1423, 61.96, 11.11 } }, -- Hameya's Plea (lvl 60, ~6600 xp, sim lvl 58)
    { "complete", 5211, at = { 1423, 57.48, 31.44 } }, -- Defenders of Darrowshire (lvl 55, ~5650 xp, sim lvl 58)
    { "complete", 9664, obj = 2, at = { 1423, 59.04, 39.41 } }, -- Establishing New Outposts (lvl 60, ~6600 xp, sim lvl 58)
    { "complete", 5542, obj = 2, at = { 1423, 46.24, 51.84 } }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 58)
    { "complete", 9664, obj = 1, at = { 1423, 34.09, 64.1 } }, -- Establishing New Outposts (lvl 60, ~6600 xp, sim lvl 58)
    { "complete", 5542, at = { 1423, 14.95, 67.41 } }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 58)
    { "complete", 5543, at = { 1423, 13.96, 66.95 } }, -- Blood Tinged Skies (lvl 56, ~5800 xp, sim lvl 58)
    { "complete", 5544, at = { 1423, 13.83, 65.59 } }, -- Carrion Grubbage (lvl 56, ~5800 xp, sim lvl 58)
    { "turnin", 5543, xp = 5800 }, -- Blood Tinged Skies (lvl 56, ~5800 xp, sim lvl 58)
    { "turnin", 5544, xp = 5800 }, -- Carrion Grubbage (lvl 56, ~5800 xp, sim lvl 58)
    { "turnin", 5542, xp = 5800 }, -- Demon Dogs (lvl 56, ~5800 xp, sim lvl 58)
    { "accept", 5742 }, -- Redemption (lvl 56, ~580 xp, sim lvl 58)
    { "complete", 5742, at = { 1423, 5.16, 35.57 } }, -- Redemption (lvl 56, ~580 xp, sim lvl 58)
    { "turnin", 5742, xp = 580 }, -- Redemption (lvl 56, ~580 xp, sim lvl 58)
    { "accept", 5781 }, -- Of Forgotten Memories (lvl 57, ~6000 xp, sim lvl 58)
    { "complete", 5781, at = { 1423, 23.85, 74.22 } }, -- Of Forgotten Memories (lvl 57, ~6000 xp, sim lvl 58)
    { "turnin", 6024, xp = 6600 }, -- Hameya's Plea (lvl 60, ~6600 xp, sim lvl 58)
    { "complete", 6021, at = { 1423, 23.07, 72.63 } }, -- Zaeldarr the Outcast (lvl 55, ~4200 xp, sim lvl 58)
    { "turnin", 5781, xp = 6000 }, -- Of Forgotten Memories (lvl 57, ~6000 xp, sim lvl 58)
    { "accept", 5845 }, -- Of Lost Honor (lvl 58, ~6200 xp, sim lvl 58)
    { "turnin", 6164, xp = 1400 }, -- Augustus' Receipt Book (lvl 55, ~1400 xp, sim lvl 58)
    { "complete", 9664, obj = 4, at = { 1423, 18.16, 25.06 } }, -- Establishing New Outposts (lvl 60, ~6600 xp, sim lvl 58)
    { "complete", 9664, at = { 1423, 49.25, 18.2 } }, -- Establishing New Outposts (lvl 60, ~6600 xp, sim lvl 58)
    { "complete", 5845, at = { 1423, 62.53, 26.81 } }, -- Of Lost Honor (lvl 58, ~6200 xp, sim lvl 58)
    { "accept", 5214, optional = true, dungeon = "Stratholme" }, -- The Great Ezra Grimm (lvl 60, ~0 xp, sim lvl 58)
    { "turnin", 9664, xp = 6600 }, -- Establishing New Outposts (lvl 60, ~6600 xp, sim lvl 58)
    { "turnin", 5211, xp = 5650 }, -- Defenders of Darrowshire (lvl 55, ~5650 xp, sim lvl 58)
    { "accept", 5243, optional = true, dungeon = "Stratholme" }, -- Houses of the Holy (lvl 60, ~0 xp, sim lvl 58)
    { "turnin", 6021, xp = 4200 }, -- Zaeldarr the Outcast (lvl 55, ~4200 xp, sim lvl 58)
    { "turnin", 5845, xp = 6200 }, -- Of Lost Honor (lvl 58, ~6200 xp, sim lvl 58)
    { "level", 59, at = { 1423, 11.11, 20.9 }, note = "About 303 more mobs here (Terrordale Spirit, level 59)" }, -- farm de niveau
  },
})
