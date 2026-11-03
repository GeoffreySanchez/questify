local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-03.
-- Simulation : 65 étapes, niveau final 22.00, ~28213 xp/h, 146 min.
Q:RegisterGuide({
  id = "A_02",
  title = "Ashenvale and Stonetalon Mountains",
  faction = "Alliance",
  minLevel = 20, maxLevel = 22,
  next = "A_03",
  steps = {
    { "fp", 1440, 34.41, 47.99 }, -- point de vol
    { "accept", 1008 }, -- The Zoram Strand (lvl 19, ~1450 xp, sim lvl 19)
    { "accept", 1056 }, -- Journey to Stonetalon Peak (lvl 18, ~680 xp, sim lvl 19)
    { "turnin", 990, xp = 365 }, -- Trek to Ashenvale (lvl 19, ~365 xp, sim lvl 19)
    { "accept", 1054 }, -- Culling the Threat (lvl 25, ~2000 xp, sim lvl 19)
    { "accept", 991 }, -- Raene's Cleansing (lvl 19, ~1450 xp, sim lvl 19)
    { "sethearth", 1440, 36.99, 49.22 }, -- lier la pierre de foyer
    { "accept", 78132 }, -- Dragonslayer's Helm (lvl 25, ~1000 xp, sim lvl 19)
    { "accept", 78134 }, -- Dragonslayer's Lance (lvl 25, ~1000 xp, sim lvl 19)
    { "turnin", 78134, xp = 1000 }, -- Dragonslayer's Lance (lvl 25, ~1000 xp, sim lvl 19)
    { "accept", 78133 }, -- Dragonslayer's Shield (lvl 25, ~1000 xp, sim lvl 19)
    { "turnin", 78132, xp = 1000 }, -- Dragonslayer's Helm (lvl 25, ~1000 xp, sim lvl 19)
    { "turnin", 78133, xp = 1000 }, -- Dragonslayer's Shield (lvl 25, ~1000 xp, sim lvl 19)
    { "turnin", 945, xp = 1350 }, -- Therylune's Escape (lvl 18, ~1350 xp, sim lvl 19)
    { "turnin", 991, xp = 1450 }, -- Raene's Cleansing (lvl 19, ~1450 xp, sim lvl 19)
    { "accept", 1023 }, -- Raene's Cleansing (lvl 21, ~1250 xp, sim lvl 19)
    { "complete", 1023, at = { 1440, 20.54, 42.9 } }, -- Raene's Cleansing (lvl 21, ~1250 xp, sim lvl 19)
    { "fp", 1442, 36.44, 7.18 }, -- point de vol
    { "turnin", 1056, xp = 680 }, -- Journey to Stonetalon Peak (lvl 18, ~680 xp, sim lvl 19)
    { "accept", 1007 }, -- The Ancient Statuette (lvl 20, ~1150 xp, sim lvl 19)
    { "complete", 1007, at = { 1440, 14.2, 20.64 } }, -- The Ancient Statuette (lvl 20, ~1150 xp, sim lvl 19)
    { "complete", 1008, at = { 1440, 12.08, 28.68 } }, -- The Zoram Strand (lvl 19, ~1450 xp, sim lvl 19)
    { "turnin", 1007, xp = 1150 }, -- The Ancient Statuette (lvl 20, ~1150 xp, sim lvl 19)
    { "accept", 1009 }, -- Ruuzel (lvl 25, ~2000 xp, sim lvl 20)
    { "complete", 1009, at = { 1440, 7.22, 13.06 } }, -- Ruuzel (lvl 25, ~2000 xp, sim lvl 20)
    { "turnin", 1009, xp = 2000 }, -- Ruuzel (lvl 25, ~2000 xp, sim lvl 20)
    { "turnin", 967, xp = 1000 }, -- The Tower of Althalaxx (lvl 18, ~1000 xp, sim lvl 20)
    { "accept", 1010 }, -- Bathran's Hair (lvl 20, ~780 xp, sim lvl 20)
    { "complete", 1010, at = { 1440, 31.5, 23.36 } }, -- Bathran's Hair (lvl 20, ~780 xp, sim lvl 20)
    { "turnin", 5713, xp = 1050 }, -- One Shot.  One Kill. (lvl 15, ~1050 xp, sim lvl 20)
    { "turnin", 1010, xp = 780 }, -- Bathran's Hair (lvl 20, ~780 xp, sim lvl 20)
    { "accept", 1020 }, -- Orendil's Cure (lvl 20, ~1950 xp, sim lvl 20)
    { "turnin", 1008, xp = 1450 }, -- The Zoram Strand (lvl 19, ~1450 xp, sim lvl 20)
    { "accept", 1070 }, -- On Guard in Stonetalon (lvl 21, ~830 xp, sim lvl 20)
    { "turnin", 1020, xp = 1950 }, -- Orendil's Cure (lvl 20, ~1950 xp, sim lvl 20)
    { "accept", 1033 }, -- Elune's Tear (lvl 22, ~1750 xp, sim lvl 20)
    { "turnin", 1023, xp = 1250 }, -- Raene's Cleansing (lvl 21, ~1250 xp, sim lvl 20)
    { "accept", 1025 }, -- An Aggressive Defense (lvl 24, ~1950 xp, sim lvl 20)
    { "accept", 1024 }, -- Raene's Cleansing (lvl 21, ~830 xp, sim lvl 20)
    { "complete", 1054, at = { 1440, 39.61, 36.31 } }, -- Culling the Threat (lvl 25, ~2000 xp, sim lvl 20)
    { "complete", 1033, at = { 1440, 46.37, 46.39 } }, -- Elune's Tear (lvl 22, ~1750 xp, sim lvl 20)
    { "turnin", 1024, xp = 830 }, -- Raene's Cleansing (lvl 21, ~830 xp, sim lvl 20)
    { "accept", 1026 }, -- Raene's Cleansing (lvl 27, ~2200 xp, sim lvl 20)
    { "complete", 1026, at = { 1440, 54.42, 35.4 } }, -- Raene's Cleansing (lvl 27, ~2200 xp, sim lvl 20)
    { "turnin", 1026, xp = 2200 }, -- Raene's Cleansing (lvl 27, ~2200 xp, sim lvl 20)
    { "complete", 1025, obj = 3, at = { 1440, 53.61, 63.75 } }, -- An Aggressive Defense (lvl 24, ~1950 xp, sim lvl 20)
    { "complete", 1025, at = { 1440, 50.09, 60.15 } }, -- An Aggressive Defense (lvl 24, ~1950 xp, sim lvl 20)
    { "turnin", 1033, xp = 1750 }, -- Elune's Tear (lvl 22, ~1750 xp, sim lvl 20)
    { "accept", 1034 }, -- The Ruins of Stardust (lvl 23, ~1850 xp, sim lvl 20)
    { "complete", 1034, at = { 1440, 33.3, 67.8 } }, -- The Ruins of Stardust (lvl 23, ~1850 xp, sim lvl 20)
    { "turnin", 1034, xp = 1850 }, -- The Ruins of Stardust (lvl 23, ~1850 xp, sim lvl 20)
    { "turnin", 1025, xp = 1950 }, -- An Aggressive Defense (lvl 24, ~1950 xp, sim lvl 20)
    { "turnin", 1054, xp = 2000 }, -- Culling the Threat (lvl 25, ~2000 xp, sim lvl 20)
    { "accept", 78270 }, -- Goblin Lockpicks (lvl 23, ~1400 xp, sim lvl 21)
    { "turnin", 78270, xp = 1400 }, -- Goblin Lockpicks (lvl 23, ~1400 xp, sim lvl 21)
    { "accept", 1093 }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 21)
    { "turnin", 1070, xp = 830 }, -- On Guard in Stonetalon (lvl 21, ~830 xp, sim lvl 21)
    { "accept", 1085 }, -- On Guard in Stonetalon (lvl 21, ~165 xp, sim lvl 21)
    { "turnin", 1085, xp = 165 }, -- On Guard in Stonetalon (lvl 21, ~165 xp, sim lvl 21)
    { "accept", 1071 }, -- A Gnome's Respite (lvl 21, ~1650 xp, sim lvl 21)
    { "complete", 1071, at = { 1442, 66.63, 51.24 } }, -- A Gnome's Respite (lvl 21, ~1650 xp, sim lvl 21)
    { "complete", 1093, at = { 1442, 62.38, 53.01 } }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 21)
    { "turnin", 1093, xp = 1650 }, -- Super Reaper 6000 (lvl 21, ~1650 xp, sim lvl 21)
    { "turnin", 1071, xp = 1650 }, -- A Gnome's Respite (lvl 21, ~1650 xp, sim lvl 21)
    { "level", 22, at = { 1442, 59.9, 53 }, note = "About 97 more mobs here (Venture Co. Light Shredder, level 20)" }, -- farm de niveau
  },
})
