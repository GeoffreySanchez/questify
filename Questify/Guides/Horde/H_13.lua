local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 42 étapes, niveau final 41.18, ~45349 xp/h, 102 min.
Q:RegisterGuide({
  id = "H_13",
  title = "Stranglethorn Vale",
  faction = "Horde",
  minLevel = 40, maxLevel = 41,
  next = "H_14",
  sim = { steps = 42, endLevel = 41.18, xpPerHour = 45349, minutes = 102 },
  steps = {
    { "note", "Not running Uldaman? Abandon Power Stones", optional = true, dungeon = "Uldaman" },
    { "goto", 1418, 3.99, 44.78, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 20, note = "Grom'gol, Stranglethorn" }, -- vol
    { "accept", 196 }, -- Raptor Mastery (lvl 41, ~2450 xp, sim lvl 40)
    { "complete", 196, at = { 1434, 31.35, 42.55 } }, -- Raptor Mastery (lvl 41, ~2450 xp, sim lvl 40)
    { "accept", 606 }, -- Scaring Shaky (lvl 41, ~820 xp, sim lvl 40)
    { "turnin", 669, xp = 3150 }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 40)
    { "sethearth", 1434, 27.04, 77.31 }, -- lier la pierre de foyer
    { "accept", 617 }, -- Akiris by the Bundle (lvl 43, ~3600 xp, sim lvl 40)
    { "complete", 606, at = { 1434, 32.62, 66.62 } }, -- Scaring Shaky (lvl 41, ~820 xp, sim lvl 40)
    { "turnin", 606, xp = 820 }, -- Scaring Shaky (lvl 41, ~820 xp, sim lvl 40)
    { "accept", 607 }, -- Return to MacKinley (lvl 41, ~2450 xp, sim lvl 40)
    { "turnin", 607, xp = 2450 }, -- Return to MacKinley (lvl 41, ~2450 xp, sim lvl 40)
    { "accept", 609 }, -- Voodoo Dues (lvl 44, ~3750 xp, sim lvl 40)
    { "accept", 595 }, -- The Bloodsail Buccaneers (lvl 41, ~2450 xp, sim lvl 40)
    { "complete", 609, at = { 1434, 35.26, 51.27 } }, -- Voodoo Dues (lvl 44, ~3750 xp, sim lvl 40)
    { "complete", 609, at = { 1434, 40, 58.24 } }, -- Voodoo Dues (lvl 44, ~3750 xp, sim lvl 40)
    { "hearth", 1434 }, -- pierre de foyer
    { "turnin", 609, xp = 3750 }, -- Voodoo Dues (lvl 44, ~3750 xp, sim lvl 40)
    { "accept", 613 }, -- Cracking Maury's Foot (lvl 44, ~4650 xp, sim lvl 40)
    { "turnin", 595, xp = 2450 }, -- The Bloodsail Buccaneers (lvl 41, ~2450 xp, sim lvl 40)
    { "accept", 597 }, -- The Bloodsail Buccaneers (lvl 41, ~2450 xp, sim lvl 40)
    { "complete", 617, at = { 1434, 27.13, 62.54 } }, -- Akiris by the Bundle (lvl 43, ~3600 xp, sim lvl 40)
    { "turnin", 196, xp = 2450 }, -- Raptor Mastery (lvl 41, ~2450 xp, sim lvl 40)
    { "accept", 197 }, -- Raptor Mastery (lvl 43, ~3600 xp, sim lvl 40)
    { "complete", 197, at = { 1434, 31.85, 42 } }, -- Raptor Mastery (lvl 43, ~3600 xp, sim lvl 40)
    { "turnin", 197, xp = 3600 }, -- Raptor Mastery (lvl 43, ~3600 xp, sim lvl 40)
    { "accept", 208 }, -- Big Game Hunter (lvl 43, ~5350 xp, sim lvl 40)
    { "complete", 208, at = { 1434, 38.21, 35.58 } }, -- Big Game Hunter (lvl 43, ~5350 xp, sim lvl 40)
    { "turnin", 208, xp = 5350 }, -- Big Game Hunter (lvl 43, ~5350 xp, sim lvl 40)
    { "complete", 613, at = { 1434, 50.96, 28.04 } }, -- Cracking Maury's Foot (lvl 44, ~4650 xp, sim lvl 40)
    { "goto", 1434, 32.54, 29.35, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 18, note = "Booty Bay, Stranglethorn" }, -- vol
    { "turnin", 597, xp = 2450 }, -- The Bloodsail Buccaneers (lvl 41, ~2450 xp, sim lvl 40)
    { "accept", 599 }, -- The Bloodsail Buccaneers (lvl 41, ~820 xp, sim lvl 41)
    { "turnin", 613, xp = 4650 }, -- Cracking Maury's Foot (lvl 44, ~4650 xp, sim lvl 41)
    { "turnin", 599, xp = 820 }, -- The Bloodsail Buccaneers (lvl 41, ~820 xp, sim lvl 41)
    { "accept", 604 }, -- The Bloodsail Buccaneers (lvl 43, ~3600 xp, sim lvl 41)
    { "turnin", 617, xp = 3600 }, -- Akiris by the Bundle (lvl 43, ~3600 xp, sim lvl 41)
    { "complete", 604, at = { 1434, 26.87, 83.26 } }, -- The Bloodsail Buccaneers (lvl 43, ~3600 xp, sim lvl 41)
    { "turnin", 604, xp = 3600 }, -- The Bloodsail Buccaneers (lvl 43, ~3600 xp, sim lvl 41)
    { "accept", 624, at = { 1434, 33.64, 88.37 }, note = "Loot Cortello's Riddle to start the quest" }, -- Cortello's Riddle (lvl 43, ~0 xp, sim lvl 41)
  },
})
