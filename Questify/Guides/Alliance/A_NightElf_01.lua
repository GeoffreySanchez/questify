local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 44 étapes, niveau final 6.53, ~10037 xp/h, 57 min.
Q:RegisterGuide({
  id = "A_NightElf_01",
  title = "Shadowglen",
  faction = "Alliance",
  races = { "NightElf" },
  minLevel = 1, maxLevel = 6,
  next = "A_NightElf_02",
  sim = { steps = 44, endLevel = 6.53, xpPerHour = 10037, minutes = 57 },
  steps = {
    { "accept", 456 }, -- The Balance of Nature (lvl 2, ~170 xp, sim lvl 1)
    { "complete", 456, at = { 1438, 61.71, 43.79 } }, -- The Balance of Nature (lvl 2, ~170 xp, sim lvl 1)
    { "accept", 4495 }, -- A Good Friend (lvl 4, ~270 xp, sim lvl 2)
    { "accept", 458 }, -- The Woodland Protector (lvl 1, ~40 xp, sim lvl 2)
    { "turnin", 456, xp = 170 }, -- The Balance of Nature (lvl 2, ~170 xp, sim lvl 2)
    { "accept", 457 }, -- The Balance of Nature (lvl 3, ~250 xp, sim lvl 2)
    { "turnin", 458, xp = 40 }, -- The Woodland Protector (lvl 1, ~40 xp, sim lvl 2)
    { "accept", 97977 }, -- Nature's Call (lvl 3, ~250 xp, sim lvl 2)
    { "accept", 459 }, -- The Woodland Protector (lvl 3, ~250 xp, sim lvl 2)
    { "complete", 459, at = { 1438, 55.45, 45.11 } }, -- The Woodland Protector (lvl 3, ~250 xp, sim lvl 2)
    { "accept", 916 }, -- Webwood Venom (lvl 4, ~355 xp, sim lvl 3)
    { "complete", 916, at = { 1438, 56.64, 27.55 } }, -- Webwood Venom (lvl 4, ~355 xp, sim lvl 3)
    { "accept", 97236, at = { 1438, 56.65, 26.31 }, note = "Loot Fang of Githyiss to start the quest" }, -- Fang of Githyiss (lvl 5, ~225 xp, sim lvl 4)
    { "turnin", 4495, xp = 270 }, -- A Good Friend (lvl 4, ~270 xp, sim lvl 4)
    { "accept", 3519 }, -- A Friend in Need (lvl 4, ~90 xp, sim lvl 4)
    { "complete", 97977, at = { 1438, 54.87, 38.85 } }, -- Nature's Call (lvl 3, ~250 xp, sim lvl 4)
    { "turnin", 916, xp = 355 }, -- Webwood Venom (lvl 4, ~355 xp, sim lvl 4)
    { "accept", 917 }, -- Webwood Egg (lvl 5, ~560 xp, sim lvl 4)
    { "turnin", 97236, xp = 225 }, -- Fang of Githyiss (lvl 5, ~225 xp, sim lvl 4)
    { "turnin", 3519, xp = 90 }, -- A Friend in Need (lvl 4, ~90 xp, sim lvl 4)
    { "accept", 3521 }, -- Iverron's Antidote (lvl 4, ~355 xp, sim lvl 4)
    { "complete", 457, at = { 1438, 62.21, 37.16 } }, -- The Balance of Nature (lvl 3, ~250 xp, sim lvl 4)
    { "complete", 917, at = { 1438, 56.81, 26.5 } }, -- Webwood Egg (lvl 5, ~560 xp, sim lvl 5)
    { "complete", 3521, obj = 3, at = { 1438, 56.88, 31.11 } }, -- Iverron's Antidote (lvl 4, ~355 xp, sim lvl 5)
    { "complete", 3521, obj = 2, at = { 1438, 57.56, 38.33 } }, -- Iverron's Antidote (lvl 4, ~355 xp, sim lvl 5)
    { "turnin", 917, xp = 560 }, -- Webwood Egg (lvl 5, ~560 xp, sim lvl 5)
    { "accept", 920 }, -- Tenaron's Summons (lvl 5, ~45 xp, sim lvl 5)
    { "complete", 3521, at = { 1438, 55.52, 44.6 } }, -- Iverron's Antidote (lvl 4, ~355 xp, sim lvl 5)
    { "turnin", 459, xp = 250 }, -- The Woodland Protector (lvl 3, ~250 xp, sim lvl 5)
    { "turnin", 97977, xp = 250 }, -- Nature's Call (lvl 3, ~250 xp, sim lvl 5)
    { "turnin", 457, xp = 250 }, -- The Balance of Nature (lvl 3, ~250 xp, sim lvl 5)
    { "turnin", 3521, xp = 355 }, -- Iverron's Antidote (lvl 4, ~355 xp, sim lvl 6)
    { "accept", 3522 }, -- Iverron's Antidote (lvl 4, ~445 xp, sim lvl 6)
    { "turnin", 920, xp = 45 }, -- Tenaron's Summons (lvl 5, ~45 xp, sim lvl 6)
    { "accept", 921 }, -- Crown of the Earth (lvl 5, ~335 xp, sim lvl 6)
    { "turnin", 3522, xp = 445 }, -- Iverron's Antidote (lvl 4, ~445 xp, sim lvl 6)
    { "complete", 921, at = { 1438, 59.95, 33.05 } }, -- Crown of the Earth (lvl 5, ~335 xp, sim lvl 6)
    { "turnin", 921, xp = 335 }, -- Crown of the Earth (lvl 5, ~335 xp, sim lvl 6)
    { "accept", 928 }, -- Crown of the Earth (lvl 5, ~225 xp, sim lvl 6)
    { "accept", 96630 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 6)
    { "accept", 2159 }, -- Dolanaar Delivery (lvl 5, ~110 xp, sim lvl 6)
    { "turnin", 96630, xp = 135 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 6)
    { "turnin", 2159, xp = 110 }, -- Dolanaar Delivery (lvl 5, ~110 xp, sim lvl 6)
    { "turnin", 928, xp = 225 }, -- Crown of the Earth (lvl 5, ~225 xp, sim lvl 6)
  },
})
