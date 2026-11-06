local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 55 étapes, niveau final 33.00, ~31794 xp/h, 103 min.
Q:RegisterGuide({
  id = "A_07",
  title = "Duskwood",
  faction = "Alliance",
  minLevel = 32, maxLevel = 33,
  next = "A_09",
  sim = { steps = 55, endLevel = 33.00, xpPerHour = 31794, minutes = 103 },
  steps = {
    { "note", "Not running Excavation Site: Wetlands? Abandon Highland Hides", optional = true, dungeon = "Excavation Site: Wetlands" },
    { "hearth", 1431 }, -- pierre de foyer
    { "accept", 173 }, -- Worgen in the Woods (lvl 28, ~1150 xp, sim lvl 32)
    { "complete", 173, at = { 1431, 64.98, 68.93 } }, -- Worgen in the Woods (lvl 28, ~1150 xp, sim lvl 32)
    { "goto", 1431, 77.49, 44.29, note = "Flight master" }, -- déplacement
    { "fly", 1436, node = 4, note = "Sentinel Hill, Westfall" }, -- vol
    { "accept", 68 }, -- The Legend of Stalvan (lvl 28, ~1700 xp, sim lvl 32)
    { "accept", 225 }, -- The Weathered Grave (lvl 35, ~690 xp, sim lvl 32)
    { "turnin", 225, xp = 690 }, -- The Weathered Grave (lvl 35, ~690 xp, sim lvl 32)
    { "accept", 227 }, -- Morgan Ladimore (lvl 35, ~275 xp, sim lvl 32)
    { "turnin", 68, xp = 1700 }, -- The Legend of Stalvan (lvl 28, ~1700 xp, sim lvl 32)
    { "accept", 69 }, -- The Legend of Stalvan (lvl 28, ~570 xp, sim lvl 32)
    { "turnin", 227, xp = 275 }, -- Morgan Ladimore (lvl 35, ~275 xp, sim lvl 32)
    { "accept", 228 }, -- Mor'Ladim (lvl 35, ~2050 xp, sim lvl 32)
    { "turnin", 69, xp = 570 }, -- The Legend of Stalvan (lvl 28, ~570 xp, sim lvl 32)
    { "accept", 70 }, -- The Legend of Stalvan (lvl 28, ~1700 xp, sim lvl 32)
    { "complete", 70, at = { 1429, 44.3, 65.82 } }, -- The Legend of Stalvan (lvl 28, ~1700 xp, sim lvl 32)
    { "turnin", 70, xp = 1700 }, -- The Legend of Stalvan (lvl 28, ~1700 xp, sim lvl 32)
    { "accept", 72 }, -- The Legend of Stalvan (lvl 28, ~230 xp, sim lvl 32)
    { "turnin", 72, xp = 230 }, -- The Legend of Stalvan (lvl 28, ~230 xp, sim lvl 32)
    { "accept", 74 }, -- The Legend of Stalvan (lvl 28, ~1150 xp, sim lvl 32)
    { "goto", 1453, 71.29, 72.23, note = "Flight master" }, -- déplacement
    { "fly", 1433, node = 5, note = "Lakeshire, Redridge" }, -- vol
    { "turnin", 74, xp = 1150 }, -- The Legend of Stalvan (lvl 28, ~1150 xp, sim lvl 32)
    { "accept", 75 }, -- The Legend of Stalvan (lvl 28, ~1150 xp, sim lvl 32)
    { "complete", 75, at = { 1429, 85.7, 69.54 } }, -- The Legend of Stalvan (lvl 28, ~1150 xp, sim lvl 32)
    { "turnin", 75, xp = 1150 }, -- The Legend of Stalvan (lvl 28, ~1150 xp, sim lvl 32)
    { "accept", 78 }, -- The Legend of Stalvan (lvl 28, ~570 xp, sim lvl 32)
    { "turnin", 78, xp = 570 }, -- The Legend of Stalvan (lvl 28, ~570 xp, sim lvl 32)
    { "accept", 79 }, -- The Legend of Stalvan (lvl 28, ~230 xp, sim lvl 32)
    { "turnin", 79, xp = 230 }, -- The Legend of Stalvan (lvl 28, ~230 xp, sim lvl 32)
    { "accept", 80 }, -- The Legend of Stalvan (lvl 28, ~230 xp, sim lvl 32)
    { "turnin", 80, xp = 230 }, -- The Legend of Stalvan (lvl 28, ~230 xp, sim lvl 32)
    { "accept", 97 }, -- The Legend of Stalvan (lvl 28, ~230 xp, sim lvl 32)
    { "turnin", 97, xp = 230 }, -- The Legend of Stalvan (lvl 28, ~230 xp, sim lvl 32)
    { "accept", 98 }, -- The Legend of Stalvan (lvl 35, ~4100 xp, sim lvl 32)
    { "turnin", 173, xp = 1150 }, -- Worgen in the Woods (lvl 28, ~1150 xp, sim lvl 32)
    { "accept", 221 }, -- Worgen in the Woods (lvl 29, ~1750 xp, sim lvl 32)
    { "complete", 98, at = { 1431, 77.35, 36.19 } }, -- The Legend of Stalvan (lvl 35, ~4100 xp, sim lvl 32)
    { "complete", 228, at = { 1431, 16.67, 37.35 } }, -- Mor'Ladim (lvl 35, ~2050 xp, sim lvl 32)
    { "complete", 221, at = { 1431, 64.06, 72.31 } }, -- Worgen in the Woods (lvl 29, ~1750 xp, sim lvl 32)
    { "turnin", 228, xp = 2050 }, -- Mor'Ladim (lvl 35, ~2050 xp, sim lvl 32)
    { "accept", 229 }, -- The Daughter Who Lived (lvl 35, ~275 xp, sim lvl 32)
    { "turnin", 229, xp = 275 }, -- The Daughter Who Lived (lvl 35, ~275 xp, sim lvl 32)
    { "accept", 231 }, -- A Daughter's Love (lvl 35, ~1350 xp, sim lvl 32)
    { "turnin", 221, xp = 1750 }, -- Worgen in the Woods (lvl 29, ~1750 xp, sim lvl 32)
    { "turnin", 98, xp = 4100 }, -- The Legend of Stalvan (lvl 35, ~4100 xp, sim lvl 32)
    { "accept", 222 }, -- Worgen in the Woods (lvl 31, ~1900 xp, sim lvl 32)
    { "complete", 222, at = { 1431, 72.52, 71.17 } }, -- Worgen in the Woods (lvl 31, ~1900 xp, sim lvl 32)
    { "turnin", 222, xp = 1900 }, -- Worgen in the Woods (lvl 31, ~1900 xp, sim lvl 32)
    { "accept", 223 }, -- Worgen in the Woods (lvl 31, ~3150 xp, sim lvl 32)
    { "turnin", 223, xp = 3150 }, -- Worgen in the Woods (lvl 31, ~3150 xp, sim lvl 32)
    { "turnin", 231, xp = 1350 }, -- A Daughter's Love (lvl 35, ~1350 xp, sim lvl 32)
    { "turnin", 563, xp = 3200 }, -- Reassignment (lvl 32, ~3200 xp, sim lvl 32)
    { "level", 33, at = { 1431, 72.52, 71.17 }, note = "About 117 more mobs near the last objective" }, -- farm de niveau
  },
})
