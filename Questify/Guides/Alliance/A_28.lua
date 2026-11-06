local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 41 étapes, niveau final 53.00, ~64745 xp/h, 149 min.
Q:RegisterGuide({
  id = "A_28",
  title = "Burning Steppes",
  faction = "Alliance",
  minLevel = 52, maxLevel = 53,
  next = "A_24",
  sim = { steps = 41, endLevel = 53.00, xpPerHour = 64745, minutes = 149 },
  steps = {
    { "note", "Not running Zul'Farrak? Abandon Divino-matic Rod", optional = true, dungeon = "Zul'Farrak" },
    { "goto", 1455, 55.5, 47.74, note = "Flight master" }, -- déplacement
    { "fly", 1428, node = 71, note = "Morgan's Vigil, Burning Steppes" }, -- vol
    { "accept", 3823 }, -- Extinguish the Firegut (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4283 }, -- FIFTY! YEP! (lvl 56, ~5800 xp, sim lvl 52)
    { "accept", 4286, optional = true, dungeon = "Blackrock Depths" }, -- The Good Stuff (lvl 56, ~0 xp, sim lvl 52)
    { "accept", 4182 }, -- Dragonkin Menace (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 3823, at = { 1428, 80.83, 43.8 } }, -- Extinguish the Firegut (lvl 52, ~5100 xp, sim lvl 52)
    { "turnin", 3823, xp = 5100 }, -- Extinguish the Firegut (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 3824 }, -- Gor'tesh the Brute Lord (lvl 53, ~5250 xp, sim lvl 52)
    { "accept", 4726 }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4296 }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "accept", 4123, optional = true, dungeon = "Blackrock Depths" }, -- The Heart of the Mountain (lvl 55, ~0 xp, sim lvl 52)
    { "complete", 4296, at = { 1428, 54.12, 40.76 } }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "accept", 81953 }, -- Stonewrought Design (lvl 45, ~2340 xp, sim lvl 52)
    { "complete", 81953, at = { 1428, 28.96, 28.93 } }, -- Stonewrought Design (lvl 45, ~2340 xp, sim lvl 52)
    { "complete", 3824, at = { 1428, 39.33, 55.3 } }, -- Gor'tesh the Brute Lord (lvl 53, ~5250 xp, sim lvl 52)
    { "complete", 4283, at = { 1428, 54.29, 53.81 } }, -- FIFTY! YEP! (lvl 56, ~5800 xp, sim lvl 52)
    { "turnin", 3824, xp = 5250 }, -- Gor'tesh the Brute Lord (lvl 53, ~5250 xp, sim lvl 52)
    { "accept", 3825 }, -- Ogre Head On A Stick = Party (lvl 53, ~5250 xp, sim lvl 52)
    { "turnin", 4283, xp = 5800 }, -- FIFTY! YEP! (lvl 56, ~5800 xp, sim lvl 52)
    { "complete", 4182, obj = 2, at = { 1428, 91.48, 54.68 } }, -- Dragonkin Menace (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4182, at = { 1428, 90.26, 46.85 } }, -- Dragonkin Menace (lvl 54, ~5450 xp, sim lvl 52)
    { "accept", 4023 }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4023, at = { 1428, 94.4, 31.8 } }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "turnin", 4023, xp = 5450 }, -- A Taste of Flame (lvl 54, ~5450 xp, sim lvl 52)
    { "complete", 4726, at = { 1428, 86.98, 31.41 } }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4136, optional = true, dungeon = "Blackrock Depths" }, -- Ribbly Screwspigot (lvl 53, ~0 xp, sim lvl 52)
    { "turnin", 4296, xp = 2350 }, -- Tablet of the Seven (lvl 50, ~2350 xp, sim lvl 52)
    { "turnin", 4726, xp = 5100 }, -- Broodling Essence (lvl 52, ~5100 xp, sim lvl 52)
    { "accept", 4808 }, -- Felnok Steelspring (lvl 54, ~0 xp, sim lvl 52)
    { "complete", 3825, at = { 1428, 81, 46.79 } }, -- Ogre Head On A Stick = Party (lvl 53, ~5250 xp, sim lvl 52)
    { "turnin", 4182, xp = 5450 }, -- Dragonkin Menace (lvl 54, ~5450 xp, sim lvl 52)
    { "accept", 4183 }, -- The True Masters (lvl 54, ~4100 xp, sim lvl 52)
    { "turnin", 3825, xp = 5250 }, -- Ogre Head On A Stick = Party (lvl 53, ~5250 xp, sim lvl 52)
    { "fly", 1433, node = 5, note = "Lakeshire, Redridge" }, -- vol
    { "turnin", 4183, xp = 4100 }, -- The True Masters (lvl 54, ~4100 xp, sim lvl 52)
    { "goto", 1433, 25.5, 59.41, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "turnin", 81953, xp = 2340 }, -- Stonewrought Design (lvl 45, ~2340 xp, sim lvl 52)
    { "level", 53, at = { 1428, 94.4, 31.8 }, note = "About 259 more mobs near the last objective" }, -- farm de niveau
  },
})
