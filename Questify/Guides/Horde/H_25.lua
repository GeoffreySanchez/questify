local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 49 étapes, niveau final 54.00, ~48284 xp/h, 208 min.
Q:RegisterGuide({
  id = "H_25",
  title = "Azshara",
  faction = "Horde",
  minLevel = 53, maxLevel = 54,
  next = "H_26",
  sim = { steps = 49, endLevel = 54.00, xpPerHour = 48284, minutes = 208 },
  steps = {
    { "boat", 1420, 60.7, 58.9, note = "Take the zeppelin to Orgrimmar (Durotar)" }, -- bateau
    { "fp", 1447, 21.96, 49.62 }, -- point de vol
    { "accept", 3517 }, -- Stealing Knowledge (lvl 52, ~5100 xp, sim lvl 53)
    { "complete", 3517, at = { 1447, 35.16, 56.94 } }, -- Stealing Knowledge (lvl 52, ~5100 xp, sim lvl 53)
    { "turnin", 3517, xp = 5100 }, -- Stealing Knowledge (lvl 52, ~5100 xp, sim lvl 53)
    { "accept", 3518 }, -- Delivery to Magatha (lvl 52, ~2550 xp, sim lvl 53)
    { "accept", 3541 }, -- Delivery to Jes'rimon (lvl 52, ~2550 xp, sim lvl 53)
    { "accept", 3561 }, -- Delivery to Archmage Xylem (lvl 52, ~2550 xp, sim lvl 53)
    { "turnin", 3561, xp = 2550 }, -- Delivery to Archmage Xylem (lvl 52, ~2550 xp, sim lvl 53)
    { "accept", 3565 }, -- Xylem's Payment to Jediga (lvl 52, ~3800 xp, sim lvl 53)
    { "goto", 1447, 21.96, 49.62, note = "Flight master" }, -- déplacement
    { "fly", 1454, node = 23, note = "Orgrimmar, Durotar" }, -- vol
    { "accept", 3504 }, -- Betrayed (lvl 53, ~2650 xp, sim lvl 53)
    { "accept", 649 }, -- Ripple Recovery (lvl 48, ~440 xp, sim lvl 53)
    { "turnin", 649, xp = 440 }, -- Ripple Recovery (lvl 48, ~440 xp, sim lvl 53)
    { "turnin", 3541, xp = 2550 }, -- Delivery to Jes'rimon (lvl 52, ~2550 xp, sim lvl 53)
    { "accept", 3563 }, -- Jes'rimon's Payment to Jediga (lvl 52, ~3800 xp, sim lvl 53)
    { "accept", 5535 }, -- Spiritual Unrest (lvl 47, ~3360 xp, sim lvl 53)
    { "sethearth", 1447, 11.77, 76.54 }, -- lier la pierre de foyer
    { "accept", 5536 }, -- A Land Filled with Hatred (lvl 47, ~3360 xp, sim lvl 53)
    { "complete", 5535, at = { 1447, 17.1, 69.7 } }, -- Spiritual Unrest (lvl 47, ~3360 xp, sim lvl 53)
    { "complete", 5536, at = { 1447, 20.31, 61.77 } }, -- A Land Filled with Hatred (lvl 47, ~3360 xp, sim lvl 53)
    { "turnin", 3504, xp = 2650 }, -- Betrayed (lvl 53, ~2650 xp, sim lvl 53)
    { "accept", 3505 }, -- Betrayed (lvl 53, ~3950 xp, sim lvl 53)
    { "turnin", 3565, xp = 3800 }, -- Xylem's Payment to Jediga (lvl 52, ~3800 xp, sim lvl 53)
    { "turnin", 3563, xp = 3800 }, -- Jes'rimon's Payment to Jediga (lvl 52, ~3800 xp, sim lvl 53)
    { "accept", 3601 }, -- Kim'jael Indeed! (lvl 53, ~6550 xp, sim lvl 53)
    { "complete", 3601, at = { 1447, 57.57, 28.05 } }, -- Kim'jael Indeed! (lvl 53, ~6550 xp, sim lvl 53)
    { "complete", 3505, at = { 1447, 56.35, 27.88 } }, -- Betrayed (lvl 53, ~3950 xp, sim lvl 53)
    { "complete", 3505, at = { 1447, 59.53, 31.47 } }, -- Betrayed (lvl 53, ~3950 xp, sim lvl 53)
    { "turnin", 3505, xp = 3950 }, -- Betrayed (lvl 53, ~3950 xp, sim lvl 53)
    { "accept", 3506 }, -- Betrayed (lvl 56, ~4350 xp, sim lvl 53)
    { "complete", 3506, at = { 1447, 59.51, 31.37 } }, -- Betrayed (lvl 56, ~4350 xp, sim lvl 53)
    { "turnin", 3601, xp = 6550 }, -- Kim'jael Indeed! (lvl 53, ~6550 xp, sim lvl 53)
    { "accept", 5534 }, -- Kim'jael's "Missing" Equipment (lvl 53, ~6550 xp, sim lvl 53)
    { "complete", 5534, at = { 1447, 47.31, 49.11 } }, -- Kim'jael's "Missing" Equipment (lvl 53, ~6550 xp, sim lvl 53)
    { "turnin", 5534, xp = 6550 }, -- Kim'jael's "Missing" Equipment (lvl 53, ~6550 xp, sim lvl 53)
    { "hearth", 1447 }, -- pierre de foyer
    { "turnin", 5535, xp = 3360 }, -- Spiritual Unrest (lvl 47, ~3360 xp, sim lvl 53)
    { "turnin", 5536, xp = 3360 }, -- A Land Filled with Hatred (lvl 47, ~3360 xp, sim lvl 53)
    { "turnin", 3506, xp = 4350 }, -- Betrayed (lvl 56, ~4350 xp, sim lvl 53)
    { "accept", 3507 }, -- Betrayed (lvl 56, ~7300 xp, sim lvl 53)
    { "goto", 1447, 21.96, 49.62, note = "Flight master" }, -- déplacement
    { "fly", 1454, node = 23, note = "Orgrimmar, Durotar" }, -- vol
    { "turnin", 3507, xp = 7300 }, -- Betrayed (lvl 56, ~7300 xp, sim lvl 53)
    { "goto", 1454, 45.12, 63.89, note = "Flight master" }, -- déplacement
    { "fly", 1456, node = 22, note = "Thunder Bluff, Mulgore" }, -- vol
    { "turnin", 3518, xp = 2550 }, -- Delivery to Magatha (lvl 52, ~2550 xp, sim lvl 53)
    { "level", 54, at = { 1447, 47.31, 49.11 }, note = "About 161 more mobs near the last objective" }, -- farm de niveau
  },
})
