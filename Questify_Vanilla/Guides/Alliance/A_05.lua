local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-03.
-- Simulation : 13 étapes, niveau final 30.13, ~30685 xp/h, 38 min.
Q:RegisterGuide({
  id = "A_05",
  title = "Hillsbrad Foothills",
  faction = "Alliance",
  minLevel = 29, maxLevel = 30,
  steps = {
    { "accept", 98071 }, -- Brewer's Trade (lvl 27, ~1100 xp, sim lvl 29)
    { "turnin", 98071, xp = 1100 }, -- Brewer's Trade (lvl 27, ~1100 xp, sim lvl 29)
    { "fp", 1424, 49.34, 52.27 }, -- point de vol
    { "accept", 536 }, -- Down the Coast (lvl 30, ~1850 xp, sim lvl 29)
    { "complete", 536, at = { 1424, 43.8, 67.72 } }, -- Down the Coast (lvl 30, ~1850 xp, sim lvl 29)
    { "turnin", 536, xp = 1850 }, -- Down the Coast (lvl 30, ~1850 xp, sim lvl 29)
    { "accept", 559 }, -- Farren's Proof (lvl 32, ~2550 xp, sim lvl 29)
    { "accept", 98059 }, -- Hillsbrad's Hoard (lvl 27, ~1100 xp, sim lvl 29)
    { "turnin", 98059, xp = 1100 }, -- Hillsbrad's Hoard (lvl 27, ~1100 xp, sim lvl 29)
    { "complete", 559, at = { 1424, 32.19, 72.78 } }, -- Farren's Proof (lvl 32, ~2550 xp, sim lvl 29)
    { "turnin", 559, xp = 2550 }, -- Farren's Proof (lvl 32, ~2550 xp, sim lvl 30)
    { "accept", 560 }, -- Farren's Proof (lvl 32, ~255 xp, sim lvl 30)
    { "turnin", 560, xp = 255 }, -- Farren's Proof (lvl 32, ~255 xp, sim lvl 30)
  },
})
