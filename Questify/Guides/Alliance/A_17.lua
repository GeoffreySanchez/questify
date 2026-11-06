local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 67 étapes, niveau final 44.00, ~47230 xp/h, 264 min.
Q:RegisterGuide({
  id = "A_17",
  title = "Stranglethorn Vale",
  faction = "Alliance",
  minLevel = 42, maxLevel = 44,
  next = "A_18",
  sim = { steps = 67, endLevel = 44.00, xpPerHour = 47230, minutes = 264 },
  steps = {
    { "note", "Not running Scarlet Monastery? Abandon Past Due", optional = true, dungeon = "Scarlet Monastery" },
    { "note", "Not running Uldaman? Abandon A Sign of Hope, Power Stones", optional = true, dungeon = "Uldaman" },
    { "accept", 621 }, -- Zanzil's Secret (lvl 44, ~3750 xp, sim lvl 42)
    { "accept", 604 }, -- The Bloodsail Buccaneers (lvl 43, ~3600 xp, sim lvl 42)
    { "accept", 1183 }, -- Goblin Sponsorship (lvl 37, ~0 xp, sim lvl 42)
    { "accept", 348 }, -- Stranglethorn Fever (lvl 45, ~5850 xp, sim lvl 42)
    { "accept", 2872 }, -- Stoley's Debt (lvl 45, ~0 xp, sim lvl 42)
    { "accept", 609 }, -- Voodoo Dues (lvl 44, ~3750 xp, sim lvl 42)
    { "accept", 587 }, -- Up to Snuff (lvl 41, ~1650 xp, sim lvl 42)
    { "accept", 1117 }, -- Rumors for Kravel (lvl 36, ~0 xp, sim lvl 42)
    { "accept", 617 }, -- Akiris by the Bundle (lvl 43, ~3600 xp, sim lvl 42)
    { "complete", 348, at = { 1434, 35.05, 60.88 } }, -- Stranglethorn Fever (lvl 45, ~5850 xp, sim lvl 42)
    { "complete", 609, at = { 1434, 35.26, 51.27 } }, -- Voodoo Dues (lvl 44, ~3750 xp, sim lvl 42)
    { "complete", 609, at = { 1434, 40, 58.24 } }, -- Voodoo Dues (lvl 44, ~3750 xp, sim lvl 42)
    { "complete", 621, at = { 1434, 39.62, 58.31 } }, -- Zanzil's Secret (lvl 44, ~3750 xp, sim lvl 42)
    { "accept", 576 }, -- Keep An Eye Out (lvl 42, ~2550 xp, sim lvl 42)
    { "turnin", 609, xp = 3750 }, -- Voodoo Dues (lvl 44, ~3750 xp, sim lvl 42)
    { "accept", 613 }, -- Cracking Maury's Foot (lvl 44, ~4650 xp, sim lvl 42)
    { "turnin", 621, xp = 3750 }, -- Zanzil's Secret (lvl 44, ~3750 xp, sim lvl 42)
    { "turnin", 348, xp = 5850 }, -- Stranglethorn Fever (lvl 45, ~5850 xp, sim lvl 42)
    { "complete", 604, at = { 1434, 26.87, 83.26 } }, -- The Bloodsail Buccaneers (lvl 43, ~3600 xp, sim lvl 42)
    { "turnin", 604, xp = 3600 }, -- The Bloodsail Buccaneers (lvl 43, ~3600 xp, sim lvl 42)
    { "accept", 608 }, -- The Bloodsail Buccaneers (lvl 45, ~4850 xp, sim lvl 42)
    { "accept", 8551 }, -- The Captain's Chest (lvl 47, ~3150 xp, sim lvl 42)
    { "complete", 617, at = { 1434, 27.13, 62.54 } }, -- Akiris by the Bundle (lvl 43, ~3600 xp, sim lvl 42)
    { "complete", 576, at = { 1434, 23.83, 53.95 } }, -- Keep An Eye Out (lvl 42, ~2550 xp, sim lvl 42)
    { "accept", 341 }, -- Chapter III (lvl 40, ~780 xp, sim lvl 42)
    { "accept", 342 }, -- Chapter IV (lvl 40, ~780 xp, sim lvl 42)
    { "accept", 339 }, -- Chapter I (lvl 40, ~780 xp, sim lvl 42)
    { "accept", 196 }, -- Raptor Mastery (lvl 41, ~2450 xp, sim lvl 42)
    { "complete", 196, at = { 1434, 31.35, 42.55 } }, -- Raptor Mastery (lvl 41, ~2450 xp, sim lvl 42)
    { "turnin", 196, xp = 2450 }, -- Raptor Mastery (lvl 41, ~2450 xp, sim lvl 42)
    { "accept", 197 }, -- Raptor Mastery (lvl 43, ~3600 xp, sim lvl 42)
    { "complete", 197, at = { 1434, 31.85, 42 } }, -- Raptor Mastery (lvl 43, ~3600 xp, sim lvl 42)
    { "complete", 342, at = { 1434, 34.75, 22.74 } }, -- Chapter IV (lvl 40, ~780 xp, sim lvl 42)
    { "complete", 339, at = { 1434, 34.75, 22.74 } }, -- Chapter I (lvl 40, ~780 xp, sim lvl 43)
    { "complete", 341, at = { 1434, 34.75, 22.74 } }, -- Chapter III (lvl 40, ~780 xp, sim lvl 43)
    { "turnin", 197, xp = 3600 }, -- Raptor Mastery (lvl 43, ~3600 xp, sim lvl 43)
    { "accept", 208 }, -- Big Game Hunter (lvl 43, ~5350 xp, sim lvl 43)
    { "accept", 202 }, -- Colonel Kurzen (lvl 40, ~3150 xp, sim lvl 43)
    { "complete", 202, obj = 3, at = { 1434, 49.94, 3.95 } }, -- Colonel Kurzen (lvl 40, ~3150 xp, sim lvl 43)
    { "complete", 202, at = { 1434, 47.59, 7.02 } }, -- Colonel Kurzen (lvl 40, ~3150 xp, sim lvl 43)
    { "turnin", 202, xp = 3150 }, -- Colonel Kurzen (lvl 40, ~3150 xp, sim lvl 43)
    { "accept", 206 }, -- Mai'Zoth (lvl 46, ~5050 xp, sim lvl 43)
    { "complete", 341, at = { 1434, 37.37, 31.22 } }, -- Chapter III (lvl 40, ~780 xp, sim lvl 43)
    { "complete", 208, at = { 1434, 38.21, 35.58 } }, -- Big Game Hunter (lvl 43, ~5350 xp, sim lvl 43)
    { "complete", 613, at = { 1434, 50.96, 28.04 } }, -- Cracking Maury's Foot (lvl 44, ~4650 xp, sim lvl 43)
    { "complete", 206, at = { 1434, 52.93, 27.6 } }, -- Mai'Zoth (lvl 46, ~5050 xp, sim lvl 43)
    { "complete", 339, at = { 1434, 44.83, 9.73 } }, -- Chapter I (lvl 40, ~780 xp, sim lvl 43)
    { "complete", 342, at = { 1434, 44.83, 9.73 } }, -- Chapter IV (lvl 40, ~780 xp, sim lvl 43)
    { "turnin", 206, xp = 5050 }, -- Mai'Zoth (lvl 46, ~5050 xp, sim lvl 43)
    { "turnin", 341, xp = 780 }, -- Chapter III (lvl 40, ~780 xp, sim lvl 43)
    { "turnin", 342, xp = 780 }, -- Chapter IV (lvl 40, ~780 xp, sim lvl 43)
    { "turnin", 339, xp = 780 }, -- Chapter I (lvl 40, ~780 xp, sim lvl 43)
    { "turnin", 208, xp = 5350 }, -- Big Game Hunter (lvl 43, ~5350 xp, sim lvl 43)
    { "hearth", 1434 }, -- pierre de foyer
    { "complete", 8551, at = { 1434, 36.95, 69.73 } }, -- The Captain's Chest (lvl 47, ~3150 xp, sim lvl 43)
    { "complete", 608, obj = 1, at = { 1434, 32.87, 88.2 } }, -- The Bloodsail Buccaneers (lvl 45, ~4850 xp, sim lvl 43)
    { "complete", 587, at = { 1434, 29.97, 89.12 } }, -- Up to Snuff (lvl 41, ~1650 xp, sim lvl 43)
    { "complete", 608, at = { 1434, 29.32, 88.29 } }, -- The Bloodsail Buccaneers (lvl 45, ~4850 xp, sim lvl 43)
    { "turnin", 576, xp = 2550 }, -- Keep An Eye Out (lvl 42, ~2550 xp, sim lvl 43)
    { "turnin", 613, xp = 4650 }, -- Cracking Maury's Foot (lvl 44, ~4650 xp, sim lvl 43)
    { "turnin", 608, xp = 4850 }, -- The Bloodsail Buccaneers (lvl 45, ~4850 xp, sim lvl 43)
    { "turnin", 587, xp = 1650 }, -- Up to Snuff (lvl 41, ~1650 xp, sim lvl 43)
    { "turnin", 617, xp = 3600 }, -- Akiris by the Bundle (lvl 43, ~3600 xp, sim lvl 43)
    { "turnin", 8551, xp = 3150 }, -- The Captain's Chest (lvl 47, ~3150 xp, sim lvl 43)
    { "level", 44, at = { 1434, 27.13, 62.54 }, note = "About 85 more mobs here (Naga Explorer, level 43)" }, -- farm de niveau
  },
})
