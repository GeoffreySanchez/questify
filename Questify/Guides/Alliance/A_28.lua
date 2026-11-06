local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 30 étapes, niveau final 53.00, ~61568 xp/h, 157 min.
Q:RegisterGuide({
  id = "A_28",
  title = "Burning Steppes",
  faction = "Alliance",
  minLevel = 52, maxLevel = 53,
  next = "A_24",
  sim = { steps = 30, endLevel = 53.00, xpPerHour = 61568, minutes = 157 },
  steps = {
    { "note", "Not running Zul'Farrak? Abandon Divino-matic Rod", optional = true, dungeon = "Zul'Farrak" },
    { "accept", 4136, optional = true, dungeon = "Blackrock Depths" }, -- Ribbly Screwspigot (lvl 53, ~0 xp, sim lvl 52)
    { "accept", 4296 }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "accept", 4726 }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4123, optional = true, dungeon = "Blackrock Depths" }, -- The Heart of the Mountain (lvl 55, ~0 xp, sim lvl 52)
    { "complete", 4726, at = { 1428, 86.98, 31.41 } }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4182 }, -- Dragonkin Menace (lvl 54, ~5450 xp, sim lvl 52)
    { "accept", 4283 }, -- FIFTY! YEP! (lvl 56, ~5800 xp, sim lvl 52)
    { "accept", 3823 }, -- Extinguish the Firegut (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4286, optional = true, dungeon = "Blackrock Depths" }, -- The Good Stuff (lvl 56, ~0 xp, sim lvl 52)
    { "complete", 3823, at = { 1428, 80.83, 43.8 } }, -- Extinguish the Firegut (lvl 52, ~5100 xp, sim lvl 52)
    { "turnin", 3823, xp = 5100 }, -- Extinguish the Firegut (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 3824 }, -- Gor'tesh the Brute Lord (lvl 53, ~5250 xp, sim lvl 52)
    { "complete", 4283, at = { 1428, 54.29, 53.81 } }, -- FIFTY! YEP! (lvl 56, ~5800 xp, sim lvl 52)
    { "complete", 3824, at = { 1428, 39.33, 55.3 } }, -- Gor'tesh the Brute Lord (lvl 53, ~5250 xp, sim lvl 52)
    { "complete", 4296, at = { 1428, 54.12, 40.76 } }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "turnin", 4296, xp = 2350 }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "turnin", 4726, xp = 5100 }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4023 }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4023, at = { 1428, 94.4, 31.8 } }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "turnin", 4023, xp = 5450 }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4182, at = { 1428, 90.26, 46.85 } }, -- Dragonkin Menace (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4182, at = { 1428, 91.48, 54.68 } }, -- Dragonkin Menace (lvl 54, ~5450 xp, sim lvl 52)
    { "turnin", 4182, xp = 5450 }, -- Dragonkin Menace (lvl 54, ~5450 xp, sim lvl 52)
    { "turnin", 3824, xp = 5250 }, -- Gor'tesh the Brute Lord (lvl 53, ~5250 xp, sim lvl 52)
    { "accept", 3825 }, -- Ogre Head On A Stick = Party (lvl 53, ~5250 xp, sim lvl 52)
    { "turnin", 4283, xp = 5800 }, -- FIFTY! YEP! (lvl 56, ~5800 xp, sim lvl 52)
    { "complete", 3825, at = { 1428, 81, 46.79 } }, -- Ogre Head On A Stick = Party (lvl 53, ~5250 xp, sim lvl 52)
    { "turnin", 3825, xp = 5250 }, -- Ogre Head On A Stick = Party (lvl 53, ~5250 xp, sim lvl 52)
    { "level", 53, at = { 1428, 81.33, 44.53 }, note = "About 306 more mobs here (Firegut Brute, level 52)" }, -- farm de niveau
  },
})
