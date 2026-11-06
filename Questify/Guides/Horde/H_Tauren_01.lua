local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 38 étapes, niveau final 7.34, ~11775 xp/h, 65 min.
Q:RegisterGuide({
  id = "H_Tauren_01",
  title = "Camp Narache",
  faction = "Horde",
  races = { "Tauren" },
  minLevel = 1, maxLevel = 6,
  next = "H_Tauren_02",
  sim = { steps = 38, endLevel = 7.34, xpPerHour = 11775, minutes = 65 },
  steps = {
    { "accept", 752 }, -- A Humble Task (lvl 2, ~85 xp, sim lvl 1)
    { "accept", 747 }, -- The Hunt Begins (lvl 2, ~170 xp, sim lvl 1)
    { "complete", 747, at = { 1412, 44.79, 84.54 } }, -- The Hunt Begins (lvl 2, ~170 xp, sim lvl 1)
    { "turnin", 752, xp = 85 }, -- A Humble Task (lvl 2, ~85 xp, sim lvl 3)
    { "accept", 753 }, -- A Humble Task (lvl 3, ~250 xp, sim lvl 3)
    { "complete", 753, at = { 1412, 48.98, 81.16 } }, -- A Humble Task (lvl 3, ~250 xp, sim lvl 3)
    { "turnin", 747, xp = 170 }, -- The Hunt Begins (lvl 2, ~170 xp, sim lvl 3)
    { "accept", 750 }, -- The Hunt Continues (lvl 3, ~250 xp, sim lvl 3)
    { "accept", 3376 }, -- Break Sharptusk! (lvl 5, ~670 xp, sim lvl 3)
    { "turnin", 753, xp = 250 }, -- A Humble Task (lvl 3, ~250 xp, sim lvl 3)
    { "accept", 755 }, -- Rites of the Earthmother (lvl 3, ~250 xp, sim lvl 3)
    { "turnin", 755, xp = 250 }, -- Rites of the Earthmother (lvl 3, ~250 xp, sim lvl 3)
    { "accept", 757 }, -- Rite of Strength (lvl 4, ~445 xp, sim lvl 3)
    { "complete", 750, at = { 1412, 50.83, 88.66 } }, -- The Hunt Continues (lvl 3, ~250 xp, sim lvl 3)
    { "turnin", 750, xp = 250 }, -- The Hunt Continues (lvl 3, ~250 xp, sim lvl 4)
    { "accept", 780 }, -- The Battleboars (lvl 4, ~445 xp, sim lvl 4)
    { "accept", 99079 }, -- Longwalker Malah (lvl 9, ~780 xp, sim lvl 4)
    { "accept", 745 }, -- Sharing the Land (lvl 8, ~540 xp, sim lvl 4)
    { "complete", 745, at = { 1412, 35.97, 65.02 } }, -- Sharing the Land (lvl 8, ~540 xp, sim lvl 4)
    { "complete", 745, at = { 1412, 51.94, 73.68 } }, -- Sharing the Land (lvl 8, ~540 xp, sim lvl 4)
    { "accept", 749 }, -- The Ravaged Caravan (lvl 8, ~530 xp, sim lvl 5)
    { "turnin", 99079, xp = 780 }, -- Longwalker Malah (lvl 9, ~780 xp, sim lvl 5)
    { "accept", 99081 }, -- Grim Tidings (lvl 9, ~780 xp, sim lvl 5)
    { "complete", 3376, at = { 1412, 61.02, 78 } }, -- Break Sharptusk! (lvl 5, ~670 xp, sim lvl 5)
    { "complete", 757, at = { 1412, 60.89, 78.43 } }, -- Rite of Strength (lvl 4, ~445 xp, sim lvl 5)
    { "accept", 781, at = { 1412, 59.8, 82.2 }, note = "Loot Dirt-stained Map to start the quest" }, -- Attack on Camp Narache (lvl 4, ~355 xp, sim lvl 5)
    { "complete", 780, at = { 1412, 54.33, 86.11 } }, -- The Battleboars (lvl 4, ~445 xp, sim lvl 5)
    { "turnin", 780, xp = 445 }, -- The Battleboars (lvl 4, ~445 xp, sim lvl 6)
    { "turnin", 3376, xp = 670 }, -- Break Sharptusk! (lvl 5, ~670 xp, sim lvl 6)
    { "turnin", 757, xp = 445 }, -- Rite of Strength (lvl 4, ~445 xp, sim lvl 6)
    { "turnin", 781, xp = 355 }, -- Attack on Camp Narache (lvl 4, ~355 xp, sim lvl 6)
    { "accept", 763 }, -- Rites of the Earthmother (lvl 5, ~335 xp, sim lvl 6)
    { "turnin", 99081, xp = 780 }, -- Grim Tidings (lvl 9, ~780 xp, sim lvl 6)
    { "accept", 99101 }, -- Our Ancient Enemy (lvl 9, ~780 xp, sim lvl 6)
    { "turnin", 99101, xp = 780 }, -- Our Ancient Enemy (lvl 9, ~780 xp, sim lvl 6)
    { "turnin", 745, xp = 540 }, -- Sharing the Land (lvl 8, ~540 xp, sim lvl 7)
    { "turnin", 763, xp = 335 }, -- Rites of the Earthmother (lvl 5, ~335 xp, sim lvl 7)
    { "turnin", 749, xp = 530 }, -- The Ravaged Caravan (lvl 8, ~530 xp, sim lvl 7)
  },
})
