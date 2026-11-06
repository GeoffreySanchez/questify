local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 30 étapes, niveau final 48.00, ~50502 xp/h, 300 min.
Q:RegisterGuide({
  id = "A_20",
  title = "Tanaris",
  faction = "Alliance",
  minLevel = 46, maxLevel = 48,
  next = "A_21",
  sim = { steps = 30, endLevel = 48.00, xpPerHour = 50502, minutes = 300 },
  steps = {
    { "note", "Not running Maraudon? Abandon Shadowshard Fragments", optional = true, dungeon = "Maraudon" },
    { "hearth", 1446 }, -- pierre de foyer
    { "accept", 10 }, -- The Scrimshank Redemption (lvl 48, ~4400 xp, sim lvl 46)
    { "accept", 3362 }, -- Thistleshrub Valley (lvl 50, ~4700 xp, sim lvl 46)
    { "accept", 5863 }, -- The Dunemaul Compound (lvl 49, ~4550 xp, sim lvl 46)
    { "accept", 2605 }, -- The Thirsty Goblin (lvl 49, ~4550 xp, sim lvl 46)
    { "accept", 3161 }, -- Gahz'ridian (lvl 48, ~4400 xp, sim lvl 46)
    { "accept", 351, at = { 1446, 73.88, 47.24 }, note = "Loot OOX-17/TN Distress Beacon to start the quest" }, -- Find OOX-17/TN! (lvl 48, ~4400 xp, sim lvl 46)
    { "turnin", 351, xp = 4400 }, -- Find OOX-17/TN! (lvl 48, ~4400 xp, sim lvl 46)
    { "accept", 648 }, -- Rescue OOX-17/TN! (lvl 48, ~0 xp, sim lvl 46)
    { "complete", 10, at = { 1446, 55.96, 71.17 } }, -- The Scrimshank Redemption (lvl 48, ~4400 xp, sim lvl 46)
    { "complete", 3161, at = { 1446, 46.98, 65.67 } }, -- Gahz'ridian (lvl 48, ~4400 xp, sim lvl 46)
    { "complete", 2605, at = { 1446, 29.71, 65.89 } }, -- The Thirsty Goblin (lvl 49, ~4550 xp, sim lvl 46)
    { "complete", 3362, at = { 1446, 29.66, 62.86 } }, -- Thistleshrub Valley (lvl 50, ~4700 xp, sim lvl 46)
    { "complete", 5863, obj = 3, at = { 1446, 41.5, 57.81 } }, -- The Dunemaul Compound (lvl 49, ~4550 xp, sim lvl 46)
    { "complete", 5863, at = { 1446, 40, 51.34 } }, -- The Dunemaul Compound (lvl 49, ~4550 xp, sim lvl 46)
    { "turnin", 3161, xp = 4400 }, -- Gahz'ridian (lvl 48, ~4400 xp, sim lvl 46)
    { "turnin", 2605, xp = 4550 }, -- The Thirsty Goblin (lvl 49, ~4550 xp, sim lvl 46)
    { "accept", 2606 }, -- In Good Taste (lvl 49, ~455 xp, sim lvl 46)
    { "turnin", 10, xp = 4400 }, -- The Scrimshank Redemption (lvl 48, ~4400 xp, sim lvl 46)
    { "accept", 110 }, -- Insect Part Analysis (lvl 48, ~440 xp, sim lvl 46)
    { "turnin", 110, xp = 440 }, -- Insect Part Analysis (lvl 48, ~440 xp, sim lvl 46)
    { "accept", 113 }, -- Insect Part Analysis (lvl 48, ~440 xp, sim lvl 46)
    { "turnin", 113, xp = 440 }, -- Insect Part Analysis (lvl 48, ~440 xp, sim lvl 46)
    { "turnin", 2606, xp = 455 }, -- In Good Taste (lvl 49, ~455 xp, sim lvl 46)
    { "turnin", 3362, xp = 4700 }, -- Thistleshrub Valley (lvl 50, ~4700 xp, sim lvl 46)
    { "turnin", 5863, xp = 4550 }, -- The Dunemaul Compound (lvl 49, ~4550 xp, sim lvl 46)
    { "accept", 2874 }, -- Deliver to MacKinley (lvl 45, ~0 xp, sim lvl 46)
    { "complete", 648, at = { 1446, 67.06, 23.16 } }, -- Rescue OOX-17/TN! (lvl 48, ~0 xp, sim lvl 46)
    { "level", 48, at = { 1446, 40, 51.34 }, note = "About 699 more mobs near the last objective" }, -- farm de niveau
  },
})
