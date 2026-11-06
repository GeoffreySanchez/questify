local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-07.
-- Simulation : 62 étapes, niveau final 45.00, ~54167 xp/h, 124 min.
Q:RegisterGuide({
  id = "H_16",
  title = "Tanaris",
  faction = "Horde",
  minLevel = 44, maxLevel = 45,
  next = "H_17",
  sim = { steps = 62, endLevel = 45.00, xpPerHour = 54167, minutes = 124 },
  steps = {
    { "note", "Not running Uldaman? Abandon Solution to Doom", optional = true, dungeon = "Uldaman" },
    { "goto", 1456, 47, 49.83, note = "Flight master" }, -- déplacement
    { "fly", 1441, node = 30, note = "Freewind Post, Thousand Needles" }, -- vol
    { "fp", 1446, 51.6, 25.44 }, -- point de vol
    { "accept", 5863 }, -- The Dunemaul Compound (lvl 49, ~4550 xp, sim lvl 44)
    { "accept", 1707 }, -- Water Pouch Bounty (lvl 44, ~2800 xp, sim lvl 44)
    { "sethearth", 1446, 52.51, 27.91 }, -- lier la pierre de foyer
    { "accept", 2768, optional = true, dungeon = "Zul'Farrak" }, -- Divino-matic Rod (lvl 47, ~0 xp, sim lvl 44)
    { "accept", 1690 }, -- Wastewander Justice (lvl 43, ~3600 xp, sim lvl 44)
    { "accept", 992 }, -- Gadgetzan Water Survey (lvl 46, ~3050 xp, sim lvl 44)
    { "complete", 992, at = { 1446, 39, 29 } }, -- Gadgetzan Water Survey (lvl 46, ~3050 xp, sim lvl 44)
    { "turnin", 992, xp = 3050 }, -- Gadgetzan Water Survey (lvl 46, ~3050 xp, sim lvl 44)
    { "accept", 82 }, -- Noxious Lair Investigation (lvl 47, ~3150 xp, sim lvl 44)
    { "complete", 82, at = { 1446, 31.97, 45.08 } }, -- Noxious Lair Investigation (lvl 47, ~3150 xp, sim lvl 44)
    { "complete", 5863, at = { 1446, 40, 51.34 } }, -- The Dunemaul Compound (lvl 49, ~4550 xp, sim lvl 44)
    { "complete", 5863, at = { 1446, 41.5, 57.81 } }, -- The Dunemaul Compound (lvl 49, ~4550 xp, sim lvl 44)
    { "hearth", 1446 }, -- pierre de foyer
    { "complete", 1707, at = { 1446, 62.85, 33.86 } }, -- Water Pouch Bounty (lvl 44, ~2800 xp, sim lvl 44)
    { "complete", 1690, at = { 1446, 63.5, 29.99 } }, -- Wastewander Justice (lvl 43, ~3600 xp, sim lvl 44)
    { "accept", 2873 }, -- Stoley's Shipment (lvl 45, ~3900 xp, sim lvl 44)
    { "accept", 8366 }, -- Southsea Shakedown (lvl 45, ~3900 xp, sim lvl 44)
    { "accept", 8365 }, -- Pirate Hats Ahoy! (lvl 45, ~3900 xp, sim lvl 44)
    { "turnin", 5863, xp = 4550 }, -- The Dunemaul Compound (lvl 49, ~4550 xp, sim lvl 44)
    { "turnin", 1690, xp = 3600 }, -- Wastewander Justice (lvl 43, ~3600 xp, sim lvl 44)
    { "turnin", 1707, xp = 2800 }, -- Water Pouch Bounty (lvl 44, ~2800 xp, sim lvl 44)
    { "accept", 1691 }, -- More Wastewander Justice (lvl 44, ~3750 xp, sim lvl 44)
    { "accept", 2875 }, -- WANTED: Andre Firebeard (lvl 45, ~3900 xp, sim lvl 44)
    { "accept", 2781 }, -- WANTED: Caliph Scorpidsting (lvl 46, ~5050 xp, sim lvl 44)
    { "accept", 2865, optional = true, dungeon = "Zul'Farrak" }, -- Scarab Shells (lvl 45, ~0 xp, sim lvl 44)
    { "turnin", 82, xp = 3150 }, -- Noxious Lair Investigation (lvl 47, ~3150 xp, sim lvl 44)
    { "accept", 10 }, -- The Scrimshank Redemption (lvl 48, ~4400 xp, sim lvl 44)
    { "accept", 3042, optional = true, dungeon = "Zul'Farrak" }, -- Troll Temper (lvl 45, ~0 xp, sim lvl 44)
    { "complete", 2781, at = { 1446, 61.77, 38.17 } }, -- WANTED: Caliph Scorpidsting (lvl 46, ~5050 xp, sim lvl 44)
    { "complete", 1691, at = { 1446, 63.75, 38.86 } }, -- More Wastewander Justice (lvl 44, ~3750 xp, sim lvl 44)
    { "complete", 2873, at = { 1446, 72.15, 46.77 } }, -- Stoley's Shipment (lvl 45, ~3900 xp, sim lvl 44)
    { "complete", 8366, at = { 1446, 73.04, 47.24 } }, -- Southsea Shakedown (lvl 45, ~3900 xp, sim lvl 44)
    { "complete", 2875, at = { 1446, 73.37, 47.14 } }, -- WANTED: Andre Firebeard (lvl 45, ~3900 xp, sim lvl 44)
    { "complete", 8365, at = { 1446, 73.86, 47.21 } }, -- Pirate Hats Ahoy! (lvl 45, ~3900 xp, sim lvl 44)
    { "accept", 351, at = { 1446, 73.88, 47.24 }, note = "Loot OOX-17/TN Distress Beacon to start the quest" }, -- Find OOX-17/TN! (lvl 48, ~4400 xp, sim lvl 44)
    { "complete", 8366, at = { 1446, 75.27, 45.64 } }, -- Southsea Shakedown (lvl 45, ~3900 xp, sim lvl 44)
    { "turnin", 351, xp = 4400 }, -- Find OOX-17/TN! (lvl 48, ~4400 xp, sim lvl 44)
    { "accept", 648 }, -- Rescue OOX-17/TN! (lvl 48, ~0 xp, sim lvl 44)
    { "complete", 10, at = { 1446, 55.96, 71.17 } }, -- The Scrimshank Redemption (lvl 48, ~4400 xp, sim lvl 44)
    { "hearth", 1446 }, -- pierre de foyer
    { "turnin", 10, xp = 4400 }, -- The Scrimshank Redemption (lvl 48, ~4400 xp, sim lvl 44)
    { "accept", 110 }, -- Insect Part Analysis (lvl 48, ~440 xp, sim lvl 44)
    { "turnin", 110, xp = 440 }, -- Insect Part Analysis (lvl 48, ~440 xp, sim lvl 44)
    { "accept", 113 }, -- Insect Part Analysis (lvl 48, ~440 xp, sim lvl 44)
    { "turnin", 113, xp = 440 }, -- Insect Part Analysis (lvl 48, ~440 xp, sim lvl 44)
    { "accept", 32 }, -- Rise of the Silithid (lvl 48, ~5450 xp, sim lvl 44)
    { "turnin", 2781, xp = 5050 }, -- WANTED: Caliph Scorpidsting (lvl 46, ~5050 xp, sim lvl 44)
    { "turnin", 1691, xp = 3750 }, -- More Wastewander Justice (lvl 44, ~3750 xp, sim lvl 44)
    { "turnin", 2873, xp = 3900 }, -- Stoley's Shipment (lvl 45, ~3900 xp, sim lvl 44)
    { "accept", 2874 }, -- Deliver to MacKinley (lvl 45, ~0 xp, sim lvl 44)
    { "turnin", 2875, xp = 3900 }, -- WANTED: Andre Firebeard (lvl 45, ~3900 xp, sim lvl 44)
    { "turnin", 8366, xp = 3900 }, -- Southsea Shakedown (lvl 45, ~3900 xp, sim lvl 44)
    { "complete", 648, at = { 1446, 67.06, 23.16 } }, -- Rescue OOX-17/TN! (lvl 48, ~0 xp, sim lvl 44)
    { "turnin", 8365, xp = 3900 }, -- Pirate Hats Ahoy! (lvl 45, ~3900 xp, sim lvl 44)
    { "goto", 1446, 51.6, 25.44, note = "Flight master" }, -- déplacement
    { "fly", 1454, node = 23, note = "Orgrimmar, Durotar" }, -- vol
    { "turnin", 32, xp = 5450 }, -- Rise of the Silithid (lvl 48, ~5450 xp, sim lvl 44)
    { "level", 45, at = { 1446, 75.27, 45.64 }, note = "About 9 more mobs near the last objective" }, -- farm de niveau
  },
})
