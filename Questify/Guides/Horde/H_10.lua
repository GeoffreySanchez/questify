local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 39 étapes, niveau final 38.00, ~38998 xp/h, 112 min.
Q:RegisterGuide({
  id = "H_10",
  title = "Dustwallow Marsh",
  faction = "Horde",
  minLevel = 37, maxLevel = 38,
  next = "H_11",
  sim = { steps = 39, endLevel = 38.00, xpPerHour = 38998, minutes = 112 },
  steps = {
    { "note", "Not running City of Dalaran? Abandon Heart of Disruption, The Grave Knight", optional = true, dungeon = "City of Dalaran" },
    { "boat", 1434, 26.08, 73.35, note = "Take the boat to Ratchet (The Barrens)" }, -- bateau
    { "fp", 1445, 35.56, 31.88 }, -- point de vol
    { "accept", 1201 }, -- Theramore Spies (lvl 35, ~2750 xp, sim lvl 37)
    { "complete", 1201, at = { 1445, 38.45, 25.29 } }, -- Theramore Spies (lvl 35, ~2750 xp, sim lvl 37)
    { "turnin", 1201, xp = 2750 }, -- Theramore Spies (lvl 35, ~2750 xp, sim lvl 37)
    { "accept", 1202 }, -- The Theramore Docks (lvl 35, ~2750 xp, sim lvl 37)
    { "accept", 1268 }, -- Suspicious Hoofprints (lvl 35, ~1350 xp, sim lvl 37)
    { "accept", 1251 }, -- The Black Shield (lvl 35, ~690 xp, sim lvl 37)
    { "accept", 1269 }, -- Lieutenant Paval Reethe (lvl 37, ~710 xp, sim lvl 37)
    { "accept", 1177 }, -- Hungry! (lvl 36, ~2800 xp, sim lvl 37)
    { "turnin", 1268, xp = 1350 }, -- Suspicious Hoofprints (lvl 35, ~1350 xp, sim lvl 37)
    { "turnin", 1251, xp = 690 }, -- The Black Shield (lvl 35, ~690 xp, sim lvl 37)
    { "turnin", 1269, xp = 710 }, -- Lieutenant Paval Reethe (lvl 37, ~710 xp, sim lvl 37)
    { "accept", 1321 }, -- The Black Shield (lvl 35, ~275 xp, sim lvl 37)
    { "turnin", 1321, xp = 275 }, -- The Black Shield (lvl 35, ~275 xp, sim lvl 37)
    { "accept", 1322 }, -- The Black Shield (lvl 37, ~2850 xp, sim lvl 37)
    { "accept", 1273 }, -- Questioning Reethe (lvl 37, ~3550 xp, sim lvl 37)
    { "complete", 1273, at = { 1445, 42.65, 38.07 } }, -- Questioning Reethe (lvl 37, ~3550 xp, sim lvl 37)
    { "accept", 1218 }, -- Soothing Spices (lvl 35, ~1350 xp, sim lvl 37)
    { "accept", 1238 }, -- The Lost Report (lvl 35, ~2050 xp, sim lvl 37)
    { "complete", 1218, at = { 1445, 66.44, 51.46 } }, -- Soothing Spices (lvl 35, ~1350 xp, sim lvl 37)
    { "complete", 1202, at = { 1445, 71.53, 51.19 } }, -- The Theramore Docks (lvl 35, ~2750 xp, sim lvl 37)
    { "turnin", 1218, xp = 1350 }, -- Soothing Spices (lvl 35, ~1350 xp, sim lvl 37)
    { "accept", 1206 }, -- Jarl Needs Eyes (lvl 35, ~2750 xp, sim lvl 37)
    { "turnin", 1238, xp = 2050 }, -- The Lost Report (lvl 35, ~2050 xp, sim lvl 37)
    { "turnin", 1202, xp = 2750 }, -- The Theramore Docks (lvl 35, ~2750 xp, sim lvl 37)
    { "complete", 1206, at = { 1445, 31.88, 21.93 } }, -- Jarl Needs Eyes (lvl 35, ~2750 xp, sim lvl 37)
    { "complete", 1177, at = { 1445, 58.75, 9.66 } }, -- Hungry! (lvl 36, ~2800 xp, sim lvl 37)
    { "accept", 1239 }, -- The Severed Head (lvl 35, ~2050 xp, sim lvl 37)
    { "turnin", 1206, xp = 2750 }, -- Jarl Needs Eyes (lvl 35, ~2750 xp, sim lvl 37)
    { "complete", 1322, at = { 1445, 42.69, 43.51 } }, -- The Black Shield (lvl 37, ~2850 xp, sim lvl 37)
    { "turnin", 1177, xp = 2800 }, -- Hungry! (lvl 36, ~2800 xp, sim lvl 37)
    { "turnin", 1239, xp = 2050 }, -- The Severed Head (lvl 35, ~2050 xp, sim lvl 37)
    { "turnin", 1322, xp = 2850 }, -- The Black Shield (lvl 37, ~2850 xp, sim lvl 37)
    { "accept", 1323 }, -- The Black Shield (lvl 37, ~1400 xp, sim lvl 37)
    { "turnin", 1323, xp = 1400 }, -- The Black Shield (lvl 37, ~1400 xp, sim lvl 37)
    { "turnin", 1273, xp = 3550 }, -- Questioning Reethe (lvl 37, ~3550 xp, sim lvl 37)
    { "level", 38, at = { 1445, 31.86, 21.94 }, note = "About 57 more mobs here (Darkmist Silkspinner, level 38)" }, -- farm de niveau
  },
})
