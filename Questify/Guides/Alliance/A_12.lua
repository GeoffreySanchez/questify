local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 74 étapes, niveau final 39.62, ~44649 xp/h, 282 min.
Q:RegisterGuide({
  id = "A_12",
  title = "Stranglethorn Vale and Swamp of Sorrows",
  faction = "Alliance",
  minLevel = 37, maxLevel = 39,
  next = "A_13",
  sim = { steps = 74, endLevel = 39.62, xpPerHour = 44649, minutes = 282 },
  steps = {
    { "hearth", 1431 }, -- pierre de foyer
    { "fp", 1434, 27.53, 77.79 }, -- point de vol
    { "accept", 189 }, -- Bloodscalp Ears (lvl 35, ~2050 xp, sim lvl 37)
    { "accept", 616 }, -- The Haunted Isle (lvl 37, ~285 xp, sim lvl 37)
    { "turnin", 210, xp = 1400 }, -- Krazek's Cookery (lvl 37, ~1400 xp, sim lvl 37)
    { "turnin", 1115, xp = 1400 }, -- The Rumormonger (lvl 36, ~1400 xp, sim lvl 37)
    { "accept", 605 }, -- Singing Blue Shards (lvl 35, ~2750 xp, sim lvl 37)
    { "sethearth", 1434, 27.04, 77.31 }, -- lier la pierre de foyer
    { "turnin", 616, xp = 285 }, -- The Haunted Isle (lvl 37, ~285 xp, sim lvl 37)
    { "accept", 578 }, -- The Stone of the Tides (lvl 37, ~2850 xp, sim lvl 37)
    { "accept", 606 }, -- Scaring Shaky (lvl 41, ~820 xp, sim lvl 37)
    { "accept", 575 }, -- Supply and Demand (lvl 31, ~1000 xp, sim lvl 37)
    { "accept", 595 }, -- The Bloodsail Buccaneers (lvl 41, ~2450 xp, sim lvl 37)
    { "turnin", 1180, xp = 710 }, -- Goblin Sponsorship (lvl 37, ~710 xp, sim lvl 37)
    { "accept", 1181 }, -- Goblin Sponsorship (lvl 37, ~285 xp, sim lvl 37)
    { "turnin", 595, xp = 2450 }, -- The Bloodsail Buccaneers (lvl 41, ~2450 xp, sim lvl 37)
    { "accept", 597 }, -- The Bloodsail Buccaneers (lvl 41, ~2450 xp, sim lvl 37)
    { "complete", 578, at = { 1434, 20.79, 23.15 } }, -- The Stone of the Tides (lvl 37, ~2850 xp, sim lvl 37)
    { "complete", 605, at = { 1434, 24.73, 17.49 } }, -- Singing Blue Shards (lvl 35, ~2750 xp, sim lvl 37)
    { "complete", 189, at = { 1434, 25.2, 10.38 } }, -- Bloodscalp Ears (lvl 35, ~2050 xp, sim lvl 37)
    { "accept", 193 }, -- Panther Mastery (lvl 40, ~3150 xp, sim lvl 37)
    { "accept", 205 }, -- Troll Witchery (lvl 40, ~3150 xp, sim lvl 37)
    { "complete", 575, at = { 1434, 40.47, 13.2 } }, -- Supply and Demand (lvl 31, ~1000 xp, sim lvl 37)
    { "hearth", 1434 }, -- pierre de foyer
    { "turnin", 597, xp = 2450 }, -- The Bloodsail Buccaneers (lvl 41, ~2450 xp, sim lvl 37)
    { "accept", 599 }, -- The Bloodsail Buccaneers (lvl 41, ~820 xp, sim lvl 37)
    { "turnin", 575, xp = 1000 }, -- Supply and Demand (lvl 31, ~1000 xp, sim lvl 37)
    { "accept", 577 }, -- Some Assembly Required (lvl 36, ~1400 xp, sim lvl 37)
    { "accept", 576 }, -- Keep An Eye Out (lvl 42, ~2550 xp, sim lvl 37)
    { "turnin", 1181, xp = 285 }, -- Goblin Sponsorship (lvl 37, ~285 xp, sim lvl 37)
    { "turnin", 578, xp = 2850 }, -- The Stone of the Tides (lvl 37, ~2850 xp, sim lvl 37)
    { "accept", 601 }, -- Water Elementals (lvl 37, ~2850 xp, sim lvl 37)
    { "accept", 1182 }, -- Goblin Sponsorship (lvl 37, ~2850 xp, sim lvl 37)
    { "turnin", 189, xp = 2050 }, -- Bloodscalp Ears (lvl 35, ~2050 xp, sim lvl 37)
    { "accept", 209 }, -- Skullsplitter Tusks (lvl 42, ~3450 xp, sim lvl 37)
    { "accept", 587 }, -- Up to Snuff (lvl 41, ~1650 xp, sim lvl 37)
    { "turnin", 605, xp = 2750 }, -- Singing Blue Shards (lvl 35, ~2750 xp, sim lvl 37)
    { "accept", 600 }, -- Venture Company Mining (lvl 41, ~3300 xp, sim lvl 37)
    { "turnin", 599, xp = 820 }, -- The Bloodsail Buccaneers (lvl 41, ~820 xp, sim lvl 37)
    { "complete", 587, at = { 1434, 29.97, 89.12 } }, -- Up to Snuff (lvl 41, ~1650 xp, sim lvl 37)
    { "complete", 577, at = { 1434, 39.33, 29.86 } }, -- Some Assembly Required (lvl 36, ~1400 xp, sim lvl 37)
    { "complete", 1182, at = { 1434, 43.33, 20.33 } }, -- Goblin Sponsorship (lvl 37, ~2850 xp, sim lvl 37)
    { "complete", 193, at = { 1434, 49.6, 23.97 } }, -- Panther Mastery (lvl 40, ~3150 xp, sim lvl 37)
    { "complete", 205, at = { 1434, 47.39, 39.76 } }, -- Troll Witchery (lvl 40, ~3150 xp, sim lvl 37)
    { "complete", 209, at = { 1434, 47.41, 39.79 } }, -- Skullsplitter Tusks (lvl 42, ~3450 xp, sim lvl 37)
    { "complete", 600, at = { 1434, 41.63, 44.07 } }, -- Venture Company Mining (lvl 41, ~3300 xp, sim lvl 38)
    { "hearth", 1434 }, -- pierre de foyer
    { "turnin", 577, xp = 1400 }, -- Some Assembly Required (lvl 36, ~1400 xp, sim lvl 38)
    { "accept", 628 }, -- Excelsior (lvl 38, ~2850 xp, sim lvl 38)
    { "turnin", 209, xp = 3450 }, -- Skullsplitter Tusks (lvl 42, ~3450 xp, sim lvl 38)
    { "turnin", 587, xp = 1650 }, -- Up to Snuff (lvl 41, ~1650 xp, sim lvl 38)
    { "turnin", 600, xp = 3300 }, -- Venture Company Mining (lvl 41, ~3300 xp, sim lvl 38)
    { "turnin", 1182, xp = 2850 }, -- Goblin Sponsorship (lvl 37, ~2850 xp, sim lvl 38)
    { "complete", 606, at = { 1434, 32.62, 66.62 } }, -- Scaring Shaky (lvl 41, ~820 xp, sim lvl 38)
    { "turnin", 606, xp = 820 }, -- Scaring Shaky (lvl 41, ~820 xp, sim lvl 38)
    { "accept", 607 }, -- Return to MacKinley (lvl 41, ~2450 xp, sim lvl 38)
    { "complete", 576, at = { 1434, 23.83, 53.95 } }, -- Keep An Eye Out (lvl 42, ~2550 xp, sim lvl 38)
    { "complete", 601, at = { 1434, 20.99, 23.31 } }, -- Water Elementals (lvl 37, ~2850 xp, sim lvl 39)
    { "complete", 628, at = { 1434, 33.43, 32.53 } }, -- Excelsior (lvl 38, ~2850 xp, sim lvl 39)
    { "hearth", 1434 }, -- pierre de foyer
    { "turnin", 601, xp = 2850 }, -- Water Elementals (lvl 37, ~2850 xp, sim lvl 39)
    { "accept", 602 }, -- Magical Analysis (lvl 37, ~0 xp, sim lvl 39)
    { "turnin", 607, xp = 2450 }, -- Return to MacKinley (lvl 41, ~2450 xp, sim lvl 39)
    { "turnin", 628, xp = 2850 }, -- Excelsior (lvl 38, ~2850 xp, sim lvl 39)
    { "turnin", 576, xp = 2550 }, -- Keep An Eye Out (lvl 42, ~2550 xp, sim lvl 39)
    { "turnin", 193, xp = 3150 }, -- Panther Mastery (lvl 40, ~3150 xp, sim lvl 39)
    { "turnin", 205, xp = 3150 }, -- Troll Witchery (lvl 40, ~3150 xp, sim lvl 39)
    { "accept", 93176 }, -- My Little Friends (lvl 35, ~1350 xp, sim lvl 39)
    { "turnin", 93176, xp = 1350 }, -- My Little Friends (lvl 35, ~1350 xp, sim lvl 39)
    { "accept", 1389 }, -- Draenethyst Crystals (lvl 35, ~2750 xp, sim lvl 39)
    { "complete", 1389, at = { 1435, 63.27, 22.35 } }, -- Draenethyst Crystals (lvl 35, ~2750 xp, sim lvl 39)
    { "accept", 1392, at = { 1435, 54.9, 34.1 }, note = "Loot Noboru's Cudgel to start the quest" }, -- Noboru the Cudgel (lvl 39, ~2250 xp, sim lvl 39)
    { "turnin", 1389, xp = 2750 }, -- Draenethyst Crystals (lvl 35, ~2750 xp, sim lvl 39)
    { "turnin", 1392, xp = 2250 }, -- Noboru the Cudgel (lvl 39, ~2250 xp, sim lvl 39)
  },
})
