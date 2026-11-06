local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 24 étapes, niveau final 54.00, ~44716 xp/h, 224 min.
Q:RegisterGuide({
  id = "H_25",
  title = "Azshara",
  faction = "Horde",
  minLevel = 53, maxLevel = 54,
  next = "H_26",
  sim = { steps = 24, endLevel = 54.00, xpPerHour = 44716, minutes = 224 },
  steps = {
    { "hearth", 1434 }, -- pierre de foyer
    { "boat", 1434, 31.43, 29.91, note = "Take the zeppelin to Orgrimmar (Durotar)" }, -- bateau
    { "fp", 1447, 21.96, 49.62 }, -- point de vol
    { "accept", 3517 }, -- Stealing Knowledge (lvl 52, ~5100 xp, sim lvl 53)
    { "complete", 3517, at = { 1447, 35.16, 56.94 } }, -- Stealing Knowledge (lvl 52, ~5100 xp, sim lvl 53)
    { "accept", 5535 }, -- Spiritual Unrest (lvl 47, ~3360 xp, sim lvl 53)
    { "sethearth", 1447, 11.77, 76.54 }, -- lier la pierre de foyer
    { "accept", 5536 }, -- A Land Filled with Hatred (lvl 47, ~3360 xp, sim lvl 53)
    { "complete", 5535, at = { 1447, 17.1, 69.7 } }, -- Spiritual Unrest (lvl 47, ~3360 xp, sim lvl 53)
    { "complete", 5536, at = { 1447, 20.31, 61.77 } }, -- A Land Filled with Hatred (lvl 47, ~3360 xp, sim lvl 53)
    { "turnin", 5535, xp = 3360 }, -- Spiritual Unrest (lvl 47, ~3360 xp, sim lvl 53)
    { "turnin", 5536, xp = 3360 }, -- A Land Filled with Hatred (lvl 47, ~3360 xp, sim lvl 53)
    { "turnin", 3517, xp = 5100 }, -- Stealing Knowledge (lvl 52, ~5100 xp, sim lvl 53)
    { "accept", 3561 }, -- Delivery to Archmage Xylem (lvl 52, ~2550 xp, sim lvl 53)
    { "turnin", 3561, xp = 2550 }, -- Delivery to Archmage Xylem (lvl 52, ~2550 xp, sim lvl 53)
    { "accept", 3565 }, -- Xylem's Payment to Jediga (lvl 52, ~3800 xp, sim lvl 53)
    { "turnin", 3565, xp = 3800 }, -- Xylem's Payment to Jediga (lvl 52, ~3800 xp, sim lvl 53)
    { "accept", 3601 }, -- Kim'jael Indeed! (lvl 53, ~6550 xp, sim lvl 53)
    { "complete", 3601, at = { 1447, 57.57, 28.05 } }, -- Kim'jael Indeed! (lvl 53, ~6550 xp, sim lvl 53)
    { "turnin", 3601, xp = 6550 }, -- Kim'jael Indeed! (lvl 53, ~6550 xp, sim lvl 53)
    { "accept", 5534 }, -- Kim'jael's "Missing" Equipment (lvl 53, ~6550 xp, sim lvl 53)
    { "complete", 5534, at = { 1447, 47.31, 49.11 } }, -- Kim'jael's "Missing" Equipment (lvl 53, ~6550 xp, sim lvl 53)
    { "turnin", 5534, xp = 6550 }, -- Kim'jael's "Missing" Equipment (lvl 53, ~6550 xp, sim lvl 53)
    { "level", 54, at = { 1447, 56.35, 27.88 }, note = "About 278 more mobs here (Blood Elf Reclaimer, level 52)" }, -- farm de niveau
  },
})
