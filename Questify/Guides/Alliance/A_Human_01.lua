local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 52 étapes, niveau final 6.27, ~11675 xp/h, 44 min.
Q:RegisterGuide({
  id = "A_Human_01",
  title = "Northshire",
  faction = "Alliance",
  races = { "Human" },
  minLevel = 1, maxLevel = 6,
  next = "A_Human_02",
  sim = { steps = 52, endLevel = 6.27, xpPerHour = 11675, minutes = 44 },
  steps = {
    { "accept", 783 }, -- A Threat Within (lvl 1, ~40 xp, sim lvl 1)
    { "turnin", 783, xp = 40 }, -- A Threat Within (lvl 1, ~40 xp, sim lvl 1)
    { "accept", 7 }, -- Kobold Camp Cleanup (lvl 2, ~170 xp, sim lvl 1)
    { "accept", 5261 }, -- Eagan Peltskinner (lvl 2, ~85 xp, sim lvl 1)
    { "complete", 7, at = { 1429, 48.82, 36.18 } }, -- Kobold Camp Cleanup (lvl 2, ~170 xp, sim lvl 1)
    { "accept", 91741, at = { 1429, 48.47, 34.61 }, note = "Loot Nibbled-On Book to start the quest" }, -- Nibbled-On Book (lvl 2, ~85 xp, sim lvl 2)
    { "accept", 18 }, -- Brotherhood of Thieves (lvl 4, ~355 xp, sim lvl 2)
    { "turnin", 7, xp = 170 }, -- Kobold Camp Cleanup (lvl 2, ~170 xp, sim lvl 2)
    { "accept", 15 }, -- Investigate Echo Ridge (lvl 3, ~250 xp, sim lvl 2)
    { "turnin", 91741, xp = 85 }, -- Nibbled-On Book (lvl 2, ~85 xp, sim lvl 2)
    { "accept", 92124 }, -- Book Inventory (lvl 2, ~85 xp, sim lvl 2)
    { "turnin", 92124, xp = 85 }, -- Book Inventory (lvl 2, ~85 xp, sim lvl 2)
    { "accept", 91743 }, -- Rascally Rodents (lvl 2, ~170 xp, sim lvl 2)
    { "turnin", 5261, xp = 85 }, -- Eagan Peltskinner (lvl 2, ~85 xp, sim lvl 2)
    { "accept", 33 }, -- Wolves Across the Border (lvl 2, ~170 xp, sim lvl 2)
    { "complete", 15, at = { 1429, 48.3, 34.03 } }, -- Investigate Echo Ridge (lvl 3, ~250 xp, sim lvl 2)
    { "complete", 91743, at = { 1429, 48.47, 34.61 } }, -- Rascally Rodents (lvl 2, ~170 xp, sim lvl 3)
    { "complete", 33, at = { 1429, 46.98, 37.19 } }, -- Wolves Across the Border (lvl 2, ~170 xp, sim lvl 3)
    { "turnin", 91743, xp = 170 }, -- Rascally Rodents (lvl 2, ~170 xp, sim lvl 4)
    { "accept", 91745 }, -- Mining Consultant (lvl 3, ~250 xp, sim lvl 4)
    { "turnin", 15, xp = 250 }, -- Investigate Echo Ridge (lvl 3, ~250 xp, sim lvl 4)
    { "accept", 21 }, -- Skirmish at Echo Ridge (lvl 5, ~450 xp, sim lvl 4)
    { "turnin", 33, xp = 170 }, -- Wolves Across the Border (lvl 2, ~170 xp, sim lvl 4)
    { "complete", 18, at = { 1429, 53.96, 47.73 } }, -- Brotherhood of Thieves (lvl 4, ~355 xp, sim lvl 4)
    { "turnin", 18, xp = 355 }, -- Brotherhood of Thieves (lvl 4, ~355 xp, sim lvl 4)
    { "accept", 6 }, -- Bounty on Garrick Padfoot (lvl 5, ~335 xp, sim lvl 5)
    { "accept", 3903 }, -- Milly Osworth (lvl 4, ~35 xp, sim lvl 5)
    { "turnin", 91745, xp = 250 }, -- Mining Consultant (lvl 3, ~250 xp, sim lvl 5)
    { "accept", 91752 }, -- The Big Picture (lvl 3, ~250 xp, sim lvl 5)
    { "complete", 21, at = { 1429, 48.87, 28.34 } }, -- Skirmish at Echo Ridge (lvl 5, ~450 xp, sim lvl 5)
    { "complete", 91752, at = { 1429, 49.22, 28.01 } }, -- The Big Picture (lvl 3, ~250 xp, sim lvl 5)
    { "turnin", 3903, xp = 35 }, -- Milly Osworth (lvl 4, ~35 xp, sim lvl 5)
    { "accept", 3904 }, -- Milly's Harvest (lvl 4, ~180 xp, sim lvl 5)
    { "turnin", 91752, xp = 250 }, -- The Big Picture (lvl 3, ~250 xp, sim lvl 5)
    { "turnin", 21, xp = 450 }, -- Skirmish at Echo Ridge (lvl 5, ~450 xp, sim lvl 5)
    { "accept", 96627 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 5)
    { "accept", 54 }, -- Report to Goldshire (lvl 5, ~225 xp, sim lvl 5)
    { "accept", 91758 }, -- Follow That Kobold! (lvl 4, ~180 xp, sim lvl 5)
    { "complete", 3904, at = { 1429, 53.97, 48.63 } }, -- Milly's Harvest (lvl 4, ~180 xp, sim lvl 5)
    { "complete", 6, at = { 1429, 57.52, 48.25 } }, -- Bounty on Garrick Padfoot (lvl 5, ~335 xp, sim lvl 5)
    { "turnin", 91758, xp = 180 }, -- Follow That Kobold! (lvl 4, ~180 xp, sim lvl 5)
    { "accept", 91772 }, -- Shhh! We're Hunting Kobolds (lvl 4, ~355 xp, sim lvl 5)
    { "turnin", 3904, xp = 180 }, -- Milly's Harvest (lvl 4, ~180 xp, sim lvl 5)
    { "accept", 3905 }, -- Grape Manifest (lvl 4, ~355 xp, sim lvl 5)
    { "turnin", 3905, xp = 355 }, -- Grape Manifest (lvl 4, ~355 xp, sim lvl 5)
    { "turnin", 6, xp = 335 }, -- Bounty on Garrick Padfoot (lvl 5, ~335 xp, sim lvl 5)
    { "complete", 91772, at = { 1429, 47.73, 45.86 } }, -- Shhh! We're Hunting Kobolds (lvl 4, ~355 xp, sim lvl 6)
    { "accept", 2158 }, -- Rest and Relaxation (lvl 5, ~110 xp, sim lvl 6)
    { "turnin", 96627, xp = 135 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 6)
    { "turnin", 2158, xp = 110 }, -- Rest and Relaxation (lvl 5, ~110 xp, sim lvl 6)
    { "turnin", 91772, xp = 355 }, -- Shhh! We're Hunting Kobolds (lvl 4, ~355 xp, sim lvl 6)
    { "turnin", 54, xp = 225 }, -- Report to Goldshire (lvl 5, ~225 xp, sim lvl 6)
  },
})
