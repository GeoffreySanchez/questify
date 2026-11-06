local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 67 étapes, niveau final 37.00, ~39634 xp/h, 210 min.
Q:RegisterGuide({
  id = "A_11",
  title = "Desolace",
  faction = "Alliance",
  minLevel = 35, maxLevel = 37,
  next = "A_12",
  sim = { steps = 67, endLevel = 37.00, xpPerHour = 39634, minutes = 210 },
  steps = {
    { "note", "Not running Excavation Site: Wetlands? Abandon Horrors in the Highland, Lost in the Thicket Things, Prehistoric Prism", optional = true, dungeon = "Excavation Site: Wetlands" },
    { "hearth", 1431 }, -- pierre de foyer
    { "goto", 1431, 77.49, 44.29, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "boat", 1453, 24.1, 55.4, note = "Take the boat to Auberdine (Stormwind Harbor)" }, -- bateau
    { "goto", 1439, 36.34, 45.58, note = "Flight master" }, -- déplacement
    { "fly", 1440, node = 28, note = "Astranaar, Ashenvale" }, -- vol
    { "fp", 1443, 64.66, 10.54 }, -- point de vol
    { "accept", 261 }, -- Down the Scarlet Path (lvl 39, ~3000 xp, sim lvl 35)
    { "accept", 1387 }, -- Centaur Bounty (lvl 31, ~3750 xp, sim lvl 35)
    { "accept", 93224 }, -- Carved Centaur Totems (lvl 40, ~3150 xp, sim lvl 35)
    { "accept", 1437 }, -- Vahlarriel's Search (lvl 33, ~1950 xp, sim lvl 35)
    { "turnin", 1437, xp = 1950 }, -- Vahlarriel's Search (lvl 33, ~1950 xp, sim lvl 35)
    { "accept", 1465 }, -- Vahlarriel's Search (lvl 33, ~1950 xp, sim lvl 35)
    { "turnin", 1465, xp = 1950 }, -- Vahlarriel's Search (lvl 33, ~1950 xp, sim lvl 35)
    { "accept", 1438 }, -- Vahlarriel's Search (lvl 33, ~2650 xp, sim lvl 35)
    { "accept", 5821 }, -- Bodyguard for Hire (lvl 35, ~2750 xp, sim lvl 35)
    { "accept", 5501 }, -- Bone Collector (lvl 39, ~2250 xp, sim lvl 35)
    { "accept", 635, at = { 1443, 54.76, 28.18 }, note = "Loot Pendant of Myzrael to start the quest" }, -- Crystal in the Mountains (lvl 35, ~0 xp, sim lvl 35)
    { "turnin", 1438, xp = 2650 }, -- Vahlarriel's Search (lvl 33, ~2650 xp, sim lvl 35)
    { "accept", 1439 }, -- Search for Tyranis (lvl 33, ~2650 xp, sim lvl 35)
    { "accept", 79950 }, -- Demons and You (lvl 35, ~2750 xp, sim lvl 35)
    { "accept", 5741 }, -- Sceptre of Light (lvl 33, ~2650 xp, sim lvl 35)
    { "accept", 6161 }, -- Claim Rackmore's Treasure! (lvl 36, ~2800 xp, sim lvl 35)
    { "complete", 6161, obj = 1, at = { 1443, 33.01, 32.36 } }, -- Claim Rackmore's Treasure! (lvl 36, ~2800 xp, sim lvl 35)
    { "complete", 93224, at = { 1443, 30.57, 56.1 } }, -- Carved Centaur Totems (lvl 40, ~3150 xp, sim lvl 35)
    { "accept", 6132 }, -- Get Me Out of Here! (lvl 39, ~2250 xp, sim lvl 35)
    { "complete", 6132, at = { 1443, 40.15, 61.58 } }, -- Get Me Out of Here! (lvl 39, ~2250 xp, sim lvl 35)
    { "turnin", 6132, xp = 2250 }, -- Get Me Out of Here! (lvl 39, ~2250 xp, sim lvl 35)
    { "accept", 6134 }, -- Ghost-o-plasm Round Up (lvl 39, ~2250 xp, sim lvl 35)
    { "accept", 5943 }, -- Gizelton Caravan (lvl 38, ~2850 xp, sim lvl 35)
    { "complete", 6134, at = { 1443, 64.18, 91.63 } }, -- Ghost-o-plasm Round Up (lvl 39, ~2250 xp, sim lvl 35)
    { "complete", 261, at = { 1443, 63.98, 89.83 } }, -- Down the Scarlet Path (lvl 39, ~3000 xp, sim lvl 35)
    { "accept", 92743 }, -- A Conqueror's Crown (lvl 40, ~1950 xp, sim lvl 35)
    { "turnin", 92743, xp = 1950 }, -- A Conqueror's Crown (lvl 40, ~1950 xp, sim lvl 35)
    { "complete", 5821, at = { 1443, 67.17, 56.62 } }, -- Bodyguard for Hire (lvl 35, ~2750 xp, sim lvl 35)
    { "accept", 5561 }, -- Kodo Roundup (lvl 34, ~2000 xp, sim lvl 35)
    { "turnin", 5821, xp = 2750 }, -- Bodyguard for Hire (lvl 35, ~2750 xp, sim lvl 35)
    { "complete", 5943, at = { 1443, 55.69, 67.79 } }, -- Gizelton Caravan (lvl 38, ~2850 xp, sim lvl 35)
    { "turnin", 6134, xp = 2250 }, -- Ghost-o-plasm Round Up (lvl 39, ~2250 xp, sim lvl 35)
    { "complete", 5501, at = { 1443, 50.28, 58.88 } }, -- Bone Collector (lvl 39, ~2250 xp, sim lvl 35)
    { "complete", 5561, at = { 1443, 52.17, 58.23 } }, -- Kodo Roundup (lvl 34, ~2000 xp, sim lvl 35)
    { "turnin", 5561, xp = 2000 }, -- Kodo Roundup (lvl 34, ~2000 xp, sim lvl 35)
    { "turnin", 5943, xp = 2850 }, -- Gizelton Caravan (lvl 38, ~2850 xp, sim lvl 35)
    { "complete", 1387, at = { 1443, 72.21, 44.04 } }, -- Centaur Bounty (lvl 31, ~3750 xp, sim lvl 35)
    { "turnin", 5501, xp = 2250 }, -- Bone Collector (lvl 39, ~2250 xp, sim lvl 35)
    { "complete", 79950, at = { 1443, 55, 26.2 } }, -- Demons and You (lvl 35, ~2750 xp, sim lvl 35)
    { "complete", 5741, at = { 1443, 55.17, 30.15 } }, -- Sceptre of Light (lvl 33, ~2650 xp, sim lvl 35)
    { "complete", 1439, at = { 1443, 53.01, 29.08 } }, -- Search for Tyranis (lvl 33, ~2650 xp, sim lvl 35)
    { "turnin", 1439, xp = 2650 }, -- Search for Tyranis (lvl 33, ~2650 xp, sim lvl 35)
    { "accept", 1440 }, -- Return to Vahlarriel (lvl 33, ~3300 xp, sim lvl 35)
    { "turnin", 5741, xp = 2650 }, -- Sceptre of Light (lvl 33, ~2650 xp, sim lvl 35)
    { "accept", 6027 }, -- Book of the Ancients (lvl 38, ~3550 xp, sim lvl 35)
    { "complete", 6161, at = { 1443, 35.44, 25.28 } }, -- Claim Rackmore's Treasure! (lvl 36, ~2800 xp, sim lvl 35)
    { "complete", 6027, at = { 1443, 28.24, 6.67 } }, -- Book of the Ancients (lvl 38, ~3550 xp, sim lvl 36)
    { "turnin", 6161, xp = 2800 }, -- Claim Rackmore's Treasure! (lvl 36, ~2800 xp, sim lvl 36)
    { "turnin", 6027, xp = 3550 }, -- Book of the Ancients (lvl 38, ~3550 xp, sim lvl 36)
    { "complete", 1440, at = { 1443, 58.27, 30.91 } }, -- Return to Vahlarriel (lvl 33, ~3300 xp, sim lvl 36)
    { "turnin", 1440, xp = 3300 }, -- Return to Vahlarriel (lvl 33, ~3300 xp, sim lvl 36)
    { "turnin", 93224, xp = 3150 }, -- Carved Centaur Totems (lvl 40, ~3150 xp, sim lvl 36)
    { "turnin", 1387, xp = 3750 }, -- Centaur Bounty (lvl 31, ~3750 xp, sim lvl 36)
    { "turnin", 261, xp = 3000 }, -- Down the Scarlet Path (lvl 39, ~3000 xp, sim lvl 36)
    { "hearth", 1431 }, -- pierre de foyer
    { "goto", 1431, 77.49, 44.29, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "turnin", 79950, xp = 2750 }, -- Demons and You (lvl 35, ~2750 xp, sim lvl 36)
    { "level", 37, at = { 1443, 28.24, 6.67 }, note = "About 176 more mobs near the last objective" }, -- farm de niveau
  },
})
