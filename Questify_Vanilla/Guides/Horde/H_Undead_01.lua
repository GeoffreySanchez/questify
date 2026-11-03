local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-03.
-- Simulation : 38 étapes, niveau final 6.03, ~9530 xp/h, 48 min.
Q:RegisterGuide({
  id = "H_Undead_01",
  title = "Deathknell",
  faction = "Horde",
  races = { "Undead" },
  minLevel = 1, maxLevel = 6,
  next = "H_Undead_02",
  steps = {
    { "accept", 363 }, -- Rude Awakening (lvl 1, ~40 xp, sim lvl 1)
    { "turnin", 363, xp = 40 }, -- Rude Awakening (lvl 1, ~40 xp, sim lvl 1)
    { "accept", 364 }, -- The Mindless Ones (lvl 2, ~170 xp, sim lvl 1)
    { "complete", 364, at = { 1420, 32.1, 63.41 } }, -- The Mindless Ones (lvl 2, ~170 xp, sim lvl 1)
    { "accept", 376 }, -- The Damned (lvl 2, ~170 xp, sim lvl 2)
    { "turnin", 364, xp = 170 }, -- The Mindless Ones (lvl 2, ~170 xp, sim lvl 2)
    { "accept", 3901 }, -- Rattling the Rattlecages (lvl 3, ~250 xp, sim lvl 2)
    { "complete", 376, at = { 1420, 35.73, 58.33 } }, -- The Damned (lvl 2, ~170 xp, sim lvl 2)
    { "complete", 3901, at = { 1420, 33.15, 61.99 } }, -- Rattling the Rattlecages (lvl 3, ~250 xp, sim lvl 3)
    { "turnin", 376, xp = 170 }, -- The Damned (lvl 2, ~170 xp, sim lvl 3)
    { "accept", 6395 }, -- Marla's Last Wish (lvl 5, ~450 xp, sim lvl 3)
    { "turnin", 3901, xp = 250 }, -- Rattling the Rattlecages (lvl 3, ~250 xp, sim lvl 3)
    { "accept", 98389 }, -- A Light in the Darkness (lvl 4, ~355 xp, sim lvl 4)
    { "accept", 380 }, -- Night Web's Hollow (lvl 4, ~355 xp, sim lvl 4)
    { "accept", 3902 }, -- Scavenging Deathknell (lvl 3, ~315 xp, sim lvl 4)
    { "complete", 6395, at = { 1420, 31.17, 65.08 } }, -- Marla's Last Wish (lvl 5, ~450 xp, sim lvl 4)
    { "complete", 380, at = { 1420, 28.4, 58.08 } }, -- Night Web's Hollow (lvl 4, ~355 xp, sim lvl 4)
    { "complete", 98389, at = { 1420, 26.61, 59.72 } }, -- A Light in the Darkness (lvl 4, ~355 xp, sim lvl 4)
    { "turnin", 6395, xp = 450 }, -- Marla's Last Wish (lvl 5, ~450 xp, sim lvl 4)
    { "turnin", 98389, xp = 355 }, -- A Light in the Darkness (lvl 4, ~355 xp, sim lvl 4)
    { "turnin", 380, xp = 355 }, -- Night Web's Hollow (lvl 4, ~355 xp, sim lvl 4)
    { "accept", 381 }, -- The Scarlet Crusade (lvl 4, ~355 xp, sim lvl 5)
    { "complete", 3902, at = { 1420, 33.04, 64.29 } }, -- Scavenging Deathknell (lvl 3, ~315 xp, sim lvl 5)
    { "complete", 381, at = { 1420, 37.52, 67.46 } }, -- The Scarlet Crusade (lvl 4, ~355 xp, sim lvl 5)
    { "turnin", 381, xp = 355 }, -- The Scarlet Crusade (lvl 4, ~355 xp, sim lvl 5)
    { "accept", 382 }, -- The Red Messenger (lvl 5, ~670 xp, sim lvl 5)
    { "complete", 382, at = { 1420, 36.57, 68.54 } }, -- The Red Messenger (lvl 5, ~670 xp, sim lvl 5)
    { "turnin", 382, xp = 670 }, -- The Red Messenger (lvl 5, ~670 xp, sim lvl 5)
    { "accept", 383 }, -- Vital Intelligence (lvl 5, ~335 xp, sim lvl 5)
    { "accept", 96656 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 5)
    { "turnin", 3902, xp = 315 }, -- Scavenging Deathknell (lvl 3, ~315 xp, sim lvl 5)
    { "accept", 8 }, -- A Rogue's Deal (lvl 5, ~110 xp, sim lvl 5)
    { "turnin", 8, xp = 110 }, -- A Rogue's Deal (lvl 5, ~110 xp, sim lvl 5)
    { "accept", 590 }, -- A Rogue's Deal (lvl 5, ~110 xp, sim lvl 5)
    { "complete", 590, at = { 1420, 38.23, 56.79 } }, -- A Rogue's Deal (lvl 5, ~110 xp, sim lvl 5)
    { "turnin", 590, xp = 110 }, -- A Rogue's Deal (lvl 5, ~110 xp, sim lvl 5)
    { "turnin", 96656, xp = 135 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 5)
    { "turnin", 383, xp = 335 }, -- Vital Intelligence (lvl 5, ~335 xp, sim lvl 5)
  },
})
