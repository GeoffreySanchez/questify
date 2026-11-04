local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-04.
-- Simulation : 48 étapes, niveau final 7.14, ~13031 xp/h, 54 min.
Q:RegisterGuide({
  id = "H_Tauren_01",
  title = "Camp Narache",
  faction = "Horde",
  races = { "Tauren" },
  minLevel = 1, maxLevel = 6,
  next = "H_Tauren_02",
  steps = {
    { "accept", 752 }, -- A Humble Task (lvl 2, ~85 xp, sim lvl 1)
    { "turnin", 752, xp = 85 }, -- A Humble Task (lvl 2, ~85 xp, sim lvl 1)
    { "accept", 753 }, -- A Humble Task (lvl 3, ~250 xp, sim lvl 1)
    { "level", 2, note = "About 7 mobs" }, -- farm de niveau
    { "complete", 753, at = { 1412, 48.98, 81.16 } }, -- A Humble Task (lvl 3, ~250 xp, sim lvl 2)
    { "turnin", 753, xp = 250 }, -- A Humble Task (lvl 3, ~250 xp, sim lvl 2)
    { "accept", 755 }, -- Rites of the Earthmother (lvl 3, ~250 xp, sim lvl 2)
    { "turnin", 755, xp = 250 }, -- Rites of the Earthmother (lvl 3, ~250 xp, sim lvl 2)
    { "accept", 757 }, -- Rite of Strength (lvl 4, ~445 xp, sim lvl 2)
    { "level", 3, at = { 1412, 60.9, 78.44 }, note = "About 7 mobs here (Bristleback Quilboar, level 3)" }, -- farm de niveau
    { "complete", 757, at = { 1412, 60.89, 78.43 } }, -- Rite of Strength (lvl 4, ~445 xp, sim lvl 3)
    { "accept", 3376 }, -- Break Sharptusk! (lvl 5, ~670 xp, sim lvl 3)
    { "turnin", 757, xp = 445 }, -- Rite of Strength (lvl 4, ~445 xp, sim lvl 3)
    { "accept", 96659 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 4)
    { "accept", 763 }, -- Rites of the Earthmother (lvl 5, ~335 xp, sim lvl 4)
    { "turnin", 96659, xp = 135 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 4)
    { "accept", 96605 }, -- The Great Outdoors (lvl 6, ~540 xp, sim lvl 4)
    { "accept", 99079 }, -- Longwalker Malah (lvl 9, ~780 xp, sim lvl 4)
    { "sethearth", 1412, 45.93, 64.16 }, -- lier la pierre de foyer
    { "turnin", 763, xp = 335 }, -- Rites of the Earthmother (lvl 5, ~335 xp, sim lvl 4)
    { "accept", 767 }, -- Rite of Vision (lvl 6, ~55 xp, sim lvl 4)
    { "accept", 761 }, -- Swoop Hunting (lvl 6, ~680 xp, sim lvl 4)
    { "accept", 99108 }, -- Sparring Match (lvl 6, ~540 xp, sim lvl 4)
    { "turnin", 99079, xp = 780 }, -- Longwalker Malah (lvl 9, ~780 xp, sim lvl 4)
    { "accept", 99081 }, -- Grim Tidings (lvl 9, ~780 xp, sim lvl 4)
    { "complete", 3376, at = { 1412, 61.02, 78 } }, -- Break Sharptusk! (lvl 5, ~670 xp, sim lvl 4)
    { "hearth", 1412 }, -- pierre de foyer
    { "turnin", 99081, xp = 780 }, -- Grim Tidings (lvl 9, ~780 xp, sim lvl 4)
    { "accept", 99101 }, -- Our Ancient Enemy (lvl 9, ~780 xp, sim lvl 5)
    { "turnin", 99101, xp = 780 }, -- Our Ancient Enemy (lvl 9, ~780 xp, sim lvl 5)
    { "accept", 743 }, -- Dangers of the Windfury (lvl 8, ~700 xp, sim lvl 5)
    { "complete", 96605, at = { 1412, 46.21, 67.31 } }, -- The Great Outdoors (lvl 6, ~540 xp, sim lvl 5)
    { "turnin", 96605, xp = 540 }, -- The Great Outdoors (lvl 6, ~540 xp, sim lvl 5)
    { "turnin", 3376, xp = 670 }, -- Break Sharptusk! (lvl 5, ~670 xp, sim lvl 5)
    { "accept", 95805, note = "Timed quest: do it right away" }, -- Grace of An'she and Mu'sha (lvl 4, ~180 xp, sim lvl 5)
    { "turnin", 95805, xp = 180 }, -- Grace of An'she and Mu'sha (lvl 4, ~180 xp, sim lvl 5)
    { "complete", 743, at = { 1412, 62.42, 71.56 } }, -- Dangers of the Windfury (lvl 8, ~700 xp, sim lvl 5)
    { "accept", 749 }, -- The Ravaged Caravan (lvl 8, ~530 xp, sim lvl 6)
    { "complete", 761, at = { 1412, 51.99, 62.13 } }, -- Swoop Hunting (lvl 6, ~680 xp, sim lvl 6)
    { "complete", 99108, at = { 1412, 48.67, 63.68 } }, -- Sparring Match (lvl 6, ~540 xp, sim lvl 6)
    { "turnin", 99108, xp = 540 }, -- Sparring Match (lvl 6, ~540 xp, sim lvl 6)
    { "turnin", 761, xp = 680 }, -- Swoop Hunting (lvl 6, ~680 xp, sim lvl 6)
    { "turnin", 743, xp = 700 }, -- Dangers of the Windfury (lvl 8, ~700 xp, sim lvl 6)
    { "accept", 98430 }, -- The Longwalkers (lvl 8, ~0 xp, sim lvl 6)
    { "level", 7, at = { 1412, 32.97, 64.01 }, note = "About 1 mobs here (Palemane Poacher, level 7)" }, -- farm de niveau
    { "complete", 98430, at = { 1412, 37.19, 64.62 } }, -- The Longwalkers (lvl 8, ~0 xp, sim lvl 7)
    { "turnin", 767, xp = 55 }, -- Rite of Vision (lvl 6, ~55 xp, sim lvl 7)
    { "turnin", 749, xp = 530 }, -- The Ravaged Caravan (lvl 8, ~530 xp, sim lvl 7)
  },
})
