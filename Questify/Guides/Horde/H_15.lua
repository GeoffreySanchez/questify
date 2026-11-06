local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 26 étapes, niveau final 44.00, ~38665 xp/h, 165 min.
Q:RegisterGuide({
  id = "H_15",
  title = "Desolace",
  faction = "Horde",
  minLevel = 43, maxLevel = 44,
  next = "H_16",
  sim = { steps = 26, endLevel = 44.00, xpPerHour = 38665, minutes = 165 },
  steps = {
    { "hearth", 1434 }, -- pierre de foyer
    { "boat", 1434, 26.08, 73.35, note = "Take the boat to Ratchet (The Barrens)" }, -- bateau
    { "goto", 1413, 63.08, 37.16, note = "Flight master" }, -- déplacement
    { "fly", 1443, node = 38, note = "Shadowprey Village, Desolace" }, -- vol
    { "accept", 7029, optional = true, dungeon = "Maraudon" }, -- Vyletongue Corruption (lvl 47, ~0 xp, sim lvl 43)
    { "accept", 6134 }, -- Ghost-o-plasm Round Up (lvl 39, ~2250 xp, sim lvl 43)
    { "accept", 1488 }, -- The Corrupter (lvl 40, ~3900 xp, sim lvl 43)
    { "accept", 93225 }, -- Carved Centaur Totems (lvl 40, ~3150 xp, sim lvl 43)
    { "accept", 94872 }, -- Buying Friendship: Magram (lvl 45, ~1460 xp, sim lvl 43)
    { "complete", 1488, at = { 1443, 56.95, 75.74 } }, -- The Corrupter (lvl 40, ~3900 xp, sim lvl 43)
    { "complete", 6134, at = { 1443, 64.18, 91.63 } }, -- Ghost-o-plasm Round Up (lvl 39, ~2250 xp, sim lvl 43)
    { "turnin", 94872, xp = 1460 }, -- Buying Friendship: Magram (lvl 45, ~1460 xp, sim lvl 43)
    { "accept", 92743 }, -- A Conqueror's Crown (lvl 40, ~1950 xp, sim lvl 43)
    { "turnin", 92743, xp = 1950 }, -- A Conqueror's Crown (lvl 40, ~1950 xp, sim lvl 43)
    { "accept", 5501 }, -- Bone Collector (lvl 39, ~2250 xp, sim lvl 43)
    { "accept", 7028, optional = true, dungeon = "Maraudon" }, -- Twisted Evils (lvl 47, ~0 xp, sim lvl 43)
    { "turnin", 1488, xp = 3900 }, -- The Corrupter (lvl 40, ~3900 xp, sim lvl 43)
    { "accept", 6132 }, -- Get Me Out of Here! (lvl 39, ~2250 xp, sim lvl 43)
    { "complete", 93225, at = { 1443, 30.82, 58.88 } }, -- Carved Centaur Totems (lvl 40, ~3150 xp, sim lvl 43)
    { "complete", 6132, at = { 1443, 40.15, 61.58 } }, -- Get Me Out of Here! (lvl 39, ~2250 xp, sim lvl 43)
    { "turnin", 6132, xp = 2250 }, -- Get Me Out of Here! (lvl 39, ~2250 xp, sim lvl 43)
    { "turnin", 6134, xp = 2250 }, -- Ghost-o-plasm Round Up (lvl 39, ~2250 xp, sim lvl 43)
    { "complete", 5501, at = { 1443, 50.28, 58.88 } }, -- Bone Collector (lvl 39, ~2250 xp, sim lvl 43)
    { "turnin", 93225, xp = 3150 }, -- Carved Centaur Totems (lvl 40, ~3150 xp, sim lvl 43)
    { "turnin", 5501, xp = 2250 }, -- Bone Collector (lvl 39, ~2250 xp, sim lvl 43)
    { "level", 44, at = { 1443, 30.82, 58.88 }, note = "About 361 more mobs near the last objective" }, -- farm de niveau
  },
})
