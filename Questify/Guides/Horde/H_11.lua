local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 52 étapes, niveau final 39.29, ~33118 xp/h, 191 min.
Q:RegisterGuide({
  id = "H_11",
  title = "Arathi Highlands",
  faction = "Horde",
  minLevel = 38, maxLevel = 39,
  next = "H_12",
  sim = { steps = 52, endLevel = 39.29, xpPerHour = 33118, minutes = 191 },
  steps = {
    { "hearth", 1434 }, -- pierre de foyer
    { "fly", 1434, node = 20, note = "Grom'gol, Stranglethorn" }, -- vol
    { "boat", 1434, 31.54, 29.36, note = "Take the zeppelin to Undercity (Tirisfal Glades)" }, -- bateau
    { "goto", 1458, 63.25, 48.56, note = "Flight master" }, -- déplacement
    { "fly", 1417, node = 17, note = "Hammerfall, Arathi" }, -- vol
    { "turnin", 638, xp = 710 }, -- Trollbane (lvl 37, ~710 xp, sim lvl 38)
    { "sethearth", 1417, 73.84, 32.46 }, -- lier la pierre de foyer
    { "accept", 639 }, -- Sigil of Strom (lvl 37, ~2850 xp, sim lvl 38)
    { "complete", 639, at = { 1417, 27.25, 63.66 } }, -- Sigil of Strom (lvl 37, ~2850 xp, sim lvl 38)
    { "hearth", 1417 }, -- pierre de foyer
    { "turnin", 639, xp = 2850 }, -- Sigil of Strom (lvl 37, ~2850 xp, sim lvl 38)
    { "accept", 640 }, -- The Broken Sigil (lvl 40, ~3150 xp, sim lvl 38)
    { "turnin", 635, xp = 275 }, -- Crystal in the Mountains (lvl 35, ~275 xp, sim lvl 38)
    { "goto", 1417, 73.02, 32.7, note = "Flight master" }, -- déplacement
    { "fly", 1424, node = 13, note = "Tarren Mill, Hillsbrad" }, -- vol
    { "accept", 503 }, -- Gol'dir (lvl 36, ~2800 xp, sim lvl 38)
    { "complete", 503, at = { 1416, 61.9, 42.38 } }, -- Gol'dir (lvl 36, ~2800 xp, sim lvl 38)
    { "turnin", 503, xp = 2800 }, -- Gol'dir (lvl 36, ~2800 xp, sim lvl 38)
    { "accept", 506 }, -- Blackmoore's Legacy (lvl 36, ~2100 xp, sim lvl 38)
    { "turnin", 506, xp = 2100 }, -- Blackmoore's Legacy (lvl 36, ~2100 xp, sim lvl 38)
    { "accept", 507 }, -- Lord Aliden Perenolde (lvl 42, ~4300 xp, sim lvl 38)
    { "complete", 507, at = { 1416, 39.32, 14.58 } }, -- Lord Aliden Perenolde (lvl 42, ~4300 xp, sim lvl 38)
    { "turnin", 507, xp = 4300 }, -- Lord Aliden Perenolde (lvl 42, ~4300 xp, sim lvl 38)
    { "accept", 508 }, -- Taretha's Gift (lvl 40, ~3900 xp, sim lvl 38)
    { "turnin", 508, xp = 3900 }, -- Taretha's Gift (lvl 40, ~3900 xp, sim lvl 38)
    { "complete", 640, at = { 1417, 23.36, 59.91 } }, -- The Broken Sigil (lvl 40, ~3150 xp, sim lvl 38)
    { "accept", 663 }, -- Land Ho! (lvl 35, ~690 xp, sim lvl 38)
    { "turnin", 663, xp = 690 }, -- Land Ho! (lvl 35, ~690 xp, sim lvl 38)
    { "accept", 665 }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 38)
    { "level", 39, at = { 1417, 23.19, 87.78 }, note = "About 32 mobs here (Daggerspine Raider, level 38)" }, -- farm de niveau
    { "complete", 665, at = { 1417, 33.87, 80.6 } }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 39)
    { "turnin", 665, xp = 3150 }, -- Sunken Treasure (lvl 40, ~3150 xp, sim lvl 39)
    { "accept", 666 }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "complete", 666, at = { 1417, 23.62, 88.25 } }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "turnin", 666, xp = 3900 }, -- Sunken Treasure (lvl 40, ~3900 xp, sim lvl 39)
    { "accept", 668 }, -- Sunken Treasure (lvl 40, ~1550 xp, sim lvl 39)
    { "turnin", 668, xp = 1550 }, -- Sunken Treasure (lvl 40, ~1550 xp, sim lvl 39)
    { "accept", 669 }, -- Sunken Treasure (lvl 40, ~0 xp, sim lvl 39)
    { "turnin", 640, xp = 3150 }, -- The Broken Sigil (lvl 40, ~3150 xp, sim lvl 39)
    { "accept", 641 }, -- Sigil of Thoradin (lvl 40, ~315 xp, sim lvl 39)
    { "turnin", 641, xp = 315 }, -- Sigil of Thoradin (lvl 40, ~315 xp, sim lvl 39)
    { "accept", 643 }, -- Sigil of Arathor (lvl 41, ~3300 xp, sim lvl 39)
    { "complete", 643, at = { 1417, 33.47, 52.08 } }, -- Sigil of Arathor (lvl 41, ~3300 xp, sim lvl 39)
    { "hearth", 1417 }, -- pierre de foyer
    { "turnin", 643, xp = 3300 }, -- Sigil of Arathor (lvl 41, ~3300 xp, sim lvl 39)
    { "accept", 644 }, -- Sigil of Trollbane (lvl 42, ~3450 xp, sim lvl 39)
    { "complete", 644, at = { 1417, 28.36, 58.11 } }, -- Sigil of Trollbane (lvl 42, ~3450 xp, sim lvl 39)
    { "turnin", 644, xp = 3450 }, -- Sigil of Trollbane (lvl 42, ~3450 xp, sim lvl 39)
    { "accept", 645 }, -- Trol'kalar (lvl 42, ~860 xp, sim lvl 39)
    { "turnin", 645, xp = 860 }, -- Trol'kalar (lvl 42, ~860 xp, sim lvl 39)
    { "accept", 646 }, -- Trol'kalar (lvl 42, ~4300 xp, sim lvl 39)
    { "turnin", 646, xp = 4300 }, -- Trol'kalar (lvl 42, ~4300 xp, sim lvl 39)
  },
})
