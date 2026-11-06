local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 25 étapes, niveau final 33.00, ~31624 xp/h, 103 min.
Q:RegisterGuide({
  id = "A_07",
  title = "Duskwood",
  faction = "Alliance",
  minLevel = 32, maxLevel = 33,
  next = "A_09",
  sim = { steps = 25, endLevel = 33.00, xpPerHour = 31624, minutes = 103 },
  steps = {
    { "note", "Not running Excavation Site: Wetlands? Abandon Highland Hides", optional = true, dungeon = "Excavation Site: Wetlands" },
    { "hearth", 1431 }, -- pierre de foyer
    { "accept", 173 }, -- Worgen in the Woods (lvl 28, ~1150 xp, sim lvl 32)
    { "complete", 173, at = { 1431, 64.98, 68.93 } }, -- Worgen in the Woods (lvl 28, ~1150 xp, sim lvl 32)
    { "accept", 225 }, -- The Weathered Grave (lvl 35, ~690 xp, sim lvl 32)
    { "turnin", 225, xp = 690 }, -- The Weathered Grave (lvl 35, ~690 xp, sim lvl 32)
    { "accept", 227 }, -- Morgan Ladimore (lvl 35, ~275 xp, sim lvl 32)
    { "turnin", 227, xp = 275 }, -- Morgan Ladimore (lvl 35, ~275 xp, sim lvl 32)
    { "accept", 228 }, -- Mor'Ladim (lvl 35, ~2050 xp, sim lvl 32)
    { "turnin", 173, xp = 1150 }, -- Worgen in the Woods (lvl 28, ~1150 xp, sim lvl 32)
    { "accept", 221 }, -- Worgen in the Woods (lvl 29, ~1750 xp, sim lvl 32)
    { "complete", 221, at = { 1431, 64.06, 72.31 } }, -- Worgen in the Woods (lvl 29, ~1750 xp, sim lvl 32)
    { "complete", 228, at = { 1431, 16.67, 37.35 } }, -- Mor'Ladim (lvl 35, ~2050 xp, sim lvl 32)
    { "turnin", 228, xp = 2050 }, -- Mor'Ladim (lvl 35, ~2050 xp, sim lvl 32)
    { "accept", 229 }, -- The Daughter Who Lived (lvl 35, ~275 xp, sim lvl 32)
    { "turnin", 229, xp = 275 }, -- The Daughter Who Lived (lvl 35, ~275 xp, sim lvl 32)
    { "accept", 231 }, -- A Daughter's Love (lvl 35, ~1350 xp, sim lvl 32)
    { "turnin", 221, xp = 1750 }, -- Worgen in the Woods (lvl 29, ~1750 xp, sim lvl 32)
    { "accept", 222 }, -- Worgen in the Woods (lvl 31, ~1900 xp, sim lvl 32)
    { "complete", 222, at = { 1431, 72.52, 71.17 } }, -- Worgen in the Woods (lvl 31, ~1900 xp, sim lvl 32)
    { "turnin", 222, xp = 1900 }, -- Worgen in the Woods (lvl 31, ~1900 xp, sim lvl 32)
    { "accept", 223 }, -- Worgen in the Woods (lvl 31, ~3150 xp, sim lvl 32)
    { "turnin", 223, xp = 3150 }, -- Worgen in the Woods (lvl 31, ~3150 xp, sim lvl 32)
    { "turnin", 231, xp = 1350 }, -- A Daughter's Love (lvl 35, ~1350 xp, sim lvl 32)
    { "level", 33, at = { 1431, 72.52, 71.17 }, note = "About 198 more mobs near the last objective" }, -- farm de niveau
  },
})
