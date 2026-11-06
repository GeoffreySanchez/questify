local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 63 étapes, niveau final 35.06, ~40062 xp/h, 185 min.
Q:RegisterGuide({
  id = "H_08",
  title = "Desolace",
  faction = "Horde",
  minLevel = 33, maxLevel = 35,
  next = "H_09",
  sim = { steps = 63, endLevel = 35.06, xpPerHour = 40062, minutes = 185 },
  steps = {
    { "accept", 1434 }, -- Befouled by Satyr (lvl 33, ~2650 xp, sim lvl 33)
    { "accept", 1433 }, -- Alliance Relations (lvl 33, ~265 xp, sim lvl 33)
    { "turnin", 1433, xp = 265 }, -- Alliance Relations (lvl 33, ~265 xp, sim lvl 33)
    { "accept", 1435 }, -- The Burning of Spirits (lvl 33, ~2650 xp, sim lvl 33)
    { "accept", 5763 }, -- Hunting in Stranglethorn (lvl 31, ~0 xp, sim lvl 33)
    { "fp", 1443, 21.6, 74.13 }, -- point de vol
    { "accept", 6143 }, -- Other Fish to Fry (lvl 36, ~2800 xp, sim lvl 33)
    { "accept", 6142 }, -- Clam Bait (lvl 35, ~2750 xp, sim lvl 33)
    { "accept", 5381 }, -- Hand of Iruxos (lvl 38, ~2850 xp, sim lvl 33)
    { "accept", 5741 }, -- Sceptre of Light (lvl 33, ~2650 xp, sim lvl 33)
    { "complete", 5381, at = { 1443, 55, 26.6 } }, -- Hand of Iruxos (lvl 38, ~2850 xp, sim lvl 33)
    { "accept", 1480, at = { 1443, 54.81, 28.21 }, note = "Loot Flayed Demon Skin to start the quest" }, -- The Corrupter (lvl 33, ~1300 xp, sim lvl 33)
    { "complete", 5741, at = { 1443, 55.17, 30.15 } }, -- Sceptre of Light (lvl 33, ~2650 xp, sim lvl 33)
    { "complete", 1435, at = { 1443, 54.81, 28.21 } }, -- The Burning of Spirits (lvl 33, ~2650 xp, sim lvl 33)
    { "turnin", 1480, xp = 1300 }, -- The Corrupter (lvl 33, ~1300 xp, sim lvl 33)
    { "accept", 1481 }, -- The Corrupter (lvl 33, ~2650 xp, sim lvl 33)
    { "turnin", 1435, xp = 2650 }, -- The Burning of Spirits (lvl 33, ~2650 xp, sim lvl 33)
    { "accept", 1365 }, -- Khan Dez'hepah (lvl 35, ~3450 xp, sim lvl 33)
    { "accept", 5561 }, -- Kodo Roundup (lvl 34, ~2000 xp, sim lvl 33)
    { "complete", 1365, at = { 1443, 73.92, 46.32 } }, -- Khan Dez'hepah (lvl 35, ~3450 xp, sim lvl 33)
    { "complete", 1481, at = { 1443, 76.49, 25.56 } }, -- The Corrupter (lvl 33, ~2650 xp, sim lvl 33)
    { "complete", 1434, at = { 1443, 74.85, 23.46 } }, -- Befouled by Satyr (lvl 33, ~2650 xp, sim lvl 33)
    { "accept", 5821 }, -- Bodyguard for Hire (lvl 35, ~2750 xp, sim lvl 33)
    { "turnin", 1481, xp = 2650 }, -- The Corrupter (lvl 33, ~2650 xp, sim lvl 33)
    { "accept", 1482 }, -- The Corrupter (lvl 35, ~2750 xp, sim lvl 33)
    { "turnin", 1434, xp = 2650 }, -- Befouled by Satyr (lvl 33, ~2650 xp, sim lvl 33)
    { "accept", 1436 }, -- Alliance Relations (lvl 33, ~2650 xp, sim lvl 33)
    { "complete", 5561, at = { 1443, 52.17, 58.23 } }, -- Kodo Roundup (lvl 34, ~2000 xp, sim lvl 33)
    { "turnin", 1365, xp = 3450 }, -- Khan Dez'hepah (lvl 35, ~3450 xp, sim lvl 33)
    { "accept", 1366 }, -- Centaur Bounty (lvl 31, ~3750 xp, sim lvl 33)
    { "complete", 5821, at = { 1443, 67.17, 56.62 } }, -- Bodyguard for Hire (lvl 35, ~2750 xp, sim lvl 33)
    { "complete", 1366, at = { 1443, 72.21, 44.04 } }, -- Centaur Bounty (lvl 31, ~3750 xp, sim lvl 33)
    { "turnin", 5741, xp = 2650 }, -- Sceptre of Light (lvl 33, ~2650 xp, sim lvl 33)
    { "accept", 6027 }, -- Book of the Ancients (lvl 38, ~3550 xp, sim lvl 33)
    { "accept", 6161 }, -- Claim Rackmore's Treasure! (lvl 36, ~2800 xp, sim lvl 33)
    { "complete", 6161, obj = 1, at = { 1443, 33.01, 32.36 } }, -- Claim Rackmore's Treasure! (lvl 36, ~2800 xp, sim lvl 33)
    { "complete", 6142, at = { 1443, 33.28, 28.35 } }, -- Clam Bait (lvl 35, ~2750 xp, sim lvl 34)
    { "complete", 6161, at = { 1443, 35.44, 25.28 } }, -- Claim Rackmore's Treasure! (lvl 36, ~2800 xp, sim lvl 34)
    { "complete", 6143, obj = 2, at = { 1443, 36.22, 22.48 } }, -- Other Fish to Fry (lvl 36, ~2800 xp, sim lvl 34)
    { "complete", 6143, at = { 1443, 32.21, 22.1 } }, -- Other Fish to Fry (lvl 36, ~2800 xp, sim lvl 34)
    { "complete", 1482, at = { 1443, 28.14, 7.26 } }, -- The Corrupter (lvl 35, ~2750 xp, sim lvl 34)
    { "complete", 6027, at = { 1443, 28.24, 6.67 } }, -- Book of the Ancients (lvl 38, ~3550 xp, sim lvl 34)
    { "turnin", 6161, xp = 2800 }, -- Claim Rackmore's Treasure! (lvl 36, ~2800 xp, sim lvl 34)
    { "turnin", 6027, xp = 3550 }, -- Book of the Ancients (lvl 38, ~3550 xp, sim lvl 34)
    { "turnin", 5381, xp = 2850 }, -- Hand of Iruxos (lvl 38, ~2850 xp, sim lvl 34)
    { "accept", 5581 }, -- Portals of the Legion (lvl 38, ~3550 xp, sim lvl 34)
    { "turnin", 6142, xp = 2750 }, -- Clam Bait (lvl 35, ~2750 xp, sim lvl 34)
    { "turnin", 6143, xp = 2800 }, -- Other Fish to Fry (lvl 36, ~2800 xp, sim lvl 34)
    { "complete", 5581, at = { 1443, 53.22, 81.02 } }, -- Portals of the Legion (lvl 38, ~3550 xp, sim lvl 34)
    { "accept", 5943 }, -- Gizelton Caravan (lvl 38, ~2850 xp, sim lvl 34)
    { "turnin", 5581, xp = 3550 }, -- Portals of the Legion (lvl 38, ~3550 xp, sim lvl 34)
    { "turnin", 1482, xp = 2750 }, -- The Corrupter (lvl 35, ~2750 xp, sim lvl 34)
    { "accept", 1484 }, -- The Corrupter (lvl 35, ~275 xp, sim lvl 34)
    { "turnin", 1484, xp = 275 }, -- The Corrupter (lvl 35, ~275 xp, sim lvl 34)
    { "turnin", 1366, xp = 3750 }, -- Centaur Bounty (lvl 31, ~3750 xp, sim lvl 34)
    { "complete", 5943, at = { 1443, 55.69, 67.79 } }, -- Gizelton Caravan (lvl 38, ~2850 xp, sim lvl 34)
    { "turnin", 5943, xp = 2850 }, -- Gizelton Caravan (lvl 38, ~2850 xp, sim lvl 34)
    { "turnin", 5821, xp = 2750 }, -- Bodyguard for Hire (lvl 35, ~2750 xp, sim lvl 34)
    { "turnin", 5561, xp = 2000 }, -- Kodo Roundup (lvl 34, ~2000 xp, sim lvl 34)
    { "hearth", 1413 }, -- pierre de foyer
    { "goto", 1413, 51.5, 30.34, note = "Flight master" }, -- déplacement
    { "fly", 1454, node = 23, note = "Orgrimmar, Durotar" }, -- vol
    { "turnin", 1436, xp = 2650 }, -- Alliance Relations (lvl 33, ~2650 xp, sim lvl 35)
  },
})
