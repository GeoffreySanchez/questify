local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 32 étapes, niveau final 44.00, ~44482 xp/h, 129 min.
Q:RegisterGuide({
  id = "H_15",
  title = "Dustwallow Marsh",
  faction = "Horde",
  minLevel = 43, maxLevel = 44,
  next = "H_16",
  sim = { steps = 32, endLevel = 44.00, xpPerHour = 44482, minutes = 129 },
  steps = {
    { "hearth", 1434 }, -- pierre de foyer
    { "boat", 1434, 26.08, 73.35, note = "Take the boat to Ratchet (The Barrens)" }, -- bateau
    { "goto", 1413, 63.08, 37.16, note = "Flight master" }, -- déplacement
    { "fly", 1445, node = 55, note = "Brackenwall Village, Dustwallow Marsh" }, -- vol
    { "accept", 1169 }, -- Identifying the Brood (lvl 43, ~5350 xp, sim lvl 43)
    { "complete", 1169, at = { 1445, 44.68, 66.09 } }, -- Identifying the Brood (lvl 43, ~5350 xp, sim lvl 43)
    { "turnin", 1169, xp = 5350 }, -- Identifying the Brood (lvl 43, ~5350 xp, sim lvl 43)
    { "accept", 1170 }, -- The Brood of Onyxia (lvl 43, ~360 xp, sim lvl 43)
    { "accept", 1276 }, -- The Black Shield (lvl 37, ~1120 xp, sim lvl 43)
    { "accept", 1166 }, -- Overlord Mok'Morokk's Concern (lvl 43, ~4450 xp, sim lvl 43)
    { "turnin", 1170, xp = 360 }, -- The Brood of Onyxia (lvl 43, ~360 xp, sim lvl 43)
    { "accept", 1171 }, -- The Brood of Onyxia (lvl 43, ~360 xp, sim lvl 43)
    { "turnin", 1171, xp = 360 }, -- The Brood of Onyxia (lvl 43, ~360 xp, sim lvl 43)
    { "accept", 1172 }, -- The Brood of Onyxia (lvl 45, ~4850 xp, sim lvl 43)
    { "accept", 1168 }, -- Army of the Black Dragon (lvl 43, ~4450 xp, sim lvl 43)
    { "turnin", 625, xp = 3600 }, -- Cortello's Riddle (lvl 43, ~3600 xp, sim lvl 43)
    { "complete", 1166, obj = 3, at = { 1445, 36.64, 69.57 } }, -- Overlord Mok'Morokk's Concern (lvl 43, ~4450 xp, sim lvl 43)
    { "complete", 1168, obj = 3, at = { 1445, 37.46, 68.38 } }, -- Army of the Black Dragon (lvl 43, ~4450 xp, sim lvl 43)
    { "complete", 1166, obj = 2, at = { 1445, 38.66, 65.57 } }, -- Overlord Mok'Morokk's Concern (lvl 43, ~4450 xp, sim lvl 43)
    { "complete", 1166, at = { 1445, 44.53, 66.04 } }, -- Overlord Mok'Morokk's Concern (lvl 43, ~4450 xp, sim lvl 43)
    { "complete", 1168, at = { 1445, 43.65, 66.29 } }, -- Army of the Black Dragon (lvl 43, ~4450 xp, sim lvl 43)
    { "complete", 1172, at = { 1445, 48.48, 73.62 } }, -- The Brood of Onyxia (lvl 45, ~4850 xp, sim lvl 43)
    { "turnin", 1172, xp = 4850 }, -- The Brood of Onyxia (lvl 45, ~4850 xp, sim lvl 43)
    { "turnin", 1166, xp = 4450 }, -- Overlord Mok'Morokk's Concern (lvl 43, ~4450 xp, sim lvl 43)
    { "accept", 1173 }, -- Challenge Overlord Mok'Morokk (lvl 45, ~4850 xp, sim lvl 43)
    { "turnin", 1168, xp = 4450 }, -- Army of the Black Dragon (lvl 43, ~4450 xp, sim lvl 43)
    { "complete", 1173, at = { 1445, 36.41, 31.43 } }, -- Challenge Overlord Mok'Morokk (lvl 45, ~4850 xp, sim lvl 43)
    { "turnin", 1173, xp = 4850 }, -- Challenge Overlord Mok'Morokk (lvl 45, ~4850 xp, sim lvl 43)
    { "goto", 1445, 35.56, 31.88, note = "Flight master" }, -- déplacement
    { "fly", 1456, node = 22, note = "Thunder Bluff, Mulgore" }, -- vol
    { "turnin", 1276, xp = 1120 }, -- The Black Shield (lvl 37, ~1120 xp, sim lvl 43)
    { "level", 44, at = { 1445, 43.65, 66.29 }, note = "About 173 more mobs near the last objective" }, -- farm de niveau
  },
})
