local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-03.
-- Simulation : 69 étapes, niveau final 15.20, ~21149 xp/h, 107 min.
Q:RegisterGuide({
  id = "A_DwarfGnome_03",
  title = "Loch Modan",
  faction = "Alliance",
  races = { "Dwarf", "Gnome" },
  minLevel = 11, maxLevel = 14,
  next = "A_DwarfGnome_04",
  steps = {
    { "accept", 416 }, -- Rat Catching (lvl 11, ~880 xp, sim lvl 11)
    { "accept", 1339 }, -- Mountaineer Stormpike's Task (lvl 15, ~540 xp, sim lvl 11)
    { "accept", 298 }, -- Excavation Progress Report (lvl 15, ~270 xp, sim lvl 11)
    { "turnin", 298, xp = 270 }, -- Excavation Progress Report (lvl 15, ~270 xp, sim lvl 11)
    { "accept", 301 }, -- Report to Ironforge (lvl 15, ~540 xp, sim lvl 12)
    { "accept", 6387 }, -- Honor Students (lvl 10, ~210 xp, sim lvl 12)
    { "turnin", 6387, xp = 210 }, -- Honor Students (lvl 10, ~210 xp, sim lvl 12)
    { "accept", 6391 }, -- Ride to Ironforge (lvl 10, ~420 xp, sim lvl 12)
    { "accept", 307 }, -- Filthy Paws (lvl 15, ~1350 xp, sim lvl 12)
    { "turnin", 1339, xp = 540 }, -- Mountaineer Stormpike's Task (lvl 15, ~540 xp, sim lvl 12)
    { "complete", 307, at = { 1432, 35.5, 24.64 } }, -- Filthy Paws (lvl 15, ~1350 xp, sim lvl 12)
    { "complete", 416, at = { 1432, 36.76, 22.21 } }, -- Rat Catching (lvl 11, ~880 xp, sim lvl 12)
    { "turnin", 307, xp = 1350 }, -- Filthy Paws (lvl 15, ~1350 xp, sim lvl 12)
    { "accept", 1338 }, -- Stormpike's Order (lvl 14, ~980 xp, sim lvl 12)
    { "turnin", 301, xp = 540 }, -- Report to Ironforge (lvl 15, ~540 xp, sim lvl 12)
    { "accept", 302 }, -- Powder to Ironband (lvl 15, ~270 xp, sim lvl 12)
    { "turnin", 6391, xp = 420 }, -- Ride to Ironforge (lvl 10, ~420 xp, sim lvl 12)
    { "accept", 6388 }, -- Gryth Thurden (lvl 10, ~210 xp, sim lvl 12)
    { "turnin", 6388, xp = 210 }, -- Gryth Thurden (lvl 10, ~210 xp, sim lvl 12)
    { "accept", 6392 }, -- Return to Brock (lvl 10, ~1050 xp, sim lvl 12)
    { "accept", 2039 }, -- Find Bingles (lvl 15, ~270 xp, sim lvl 12)
    { "goto", 1455, 55.5, 47.74, note = "Flight master" }, -- déplacement
    { "fly", 1432, note = "Thelsamar, Loch Modan" }, -- vol
    { "accept", 224 }, -- In Defense of the King's Lands (lvl 12, ~910 xp, sim lvl 12)
    { "accept", 267 }, -- The Trogg Threat (lvl 12, ~910 xp, sim lvl 12)
    { "complete", 267, at = { 1432, 32.79, 73.78 } }, -- The Trogg Threat (lvl 12, ~910 xp, sim lvl 12)
    { "complete", 224, at = { 1432, 31.8, 73.61 } }, -- In Defense of the King's Lands (lvl 12, ~910 xp, sim lvl 12)
    { "turnin", 224, xp = 910 }, -- In Defense of the King's Lands (lvl 12, ~910 xp, sim lvl 12)
    { "accept", 237 }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 13)
    { "complete", 237, at = { 1432, 35.7, 85.02 } }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 13)
    { "turnin", 237, xp = 1050 }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 13)
    { "accept", 263 }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 13)
    { "accept", 86585 }, -- Banner of the Fallen (lvl 17, ~1250 xp, sim lvl 13)
    { "complete", 263, at = { 1432, 36.01, 91.83 } }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 13)
    { "complete", 86585, at = { 1432, 32.86, 87.05 } }, -- Banner of the Fallen (lvl 17, ~1250 xp, sim lvl 13)
    { "turnin", 263, xp = 1050 }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 13)
    { "turnin", 267, xp = 910 }, -- The Trogg Threat (lvl 12, ~910 xp, sim lvl 13)
    { "accept", 217 }, -- In Defense of the King's Lands (lvl 17, ~1600 xp, sim lvl 13)
    { "complete", 217, at = { 1432, 34.77, 90.45 } }, -- In Defense of the King's Lands (lvl 17, ~1600 xp, sim lvl 13)
    { "turnin", 86585, xp = 1250 }, -- Banner of the Fallen (lvl 17, ~1250 xp, sim lvl 13)
    { "turnin", 217, xp = 1600 }, -- In Defense of the King's Lands (lvl 17, ~1600 xp, sim lvl 13)
    { "turnin", 416, xp = 880 }, -- Rat Catching (lvl 11, ~880 xp, sim lvl 14)
    { "turnin", 6392, xp = 1050 }, -- Return to Brock (lvl 10, ~1050 xp, sim lvl 14)
    { "turnin", 302, xp = 270 }, -- Powder to Ironband (lvl 15, ~270 xp, sim lvl 14)
    { "accept", 273 }, -- Resupplying the Excavation (lvl 15, ~270 xp, sim lvl 14)
    { "complete", 273, at = { 1432, 52.2, 69.37 } }, -- Resupplying the Excavation (lvl 15, ~270 xp, sim lvl 14)
    { "turnin", 273, xp = 270 }, -- Resupplying the Excavation (lvl 15, ~270 xp, sim lvl 14)
    { "accept", 454 }, -- After the Ambush (lvl 15, ~105 xp, sim lvl 14)
    { "turnin", 454, xp = 105 }, -- After the Ambush (lvl 15, ~105 xp, sim lvl 14)
    { "accept", 309 }, -- Protecting the Shipment (lvl 15, ~1050 xp, sim lvl 14)
    { "complete", 309, at = { 1432, 65.12, 65.77 } }, -- Protecting the Shipment (lvl 15, ~1050 xp, sim lvl 14)
    { "turnin", 309, xp = 1050 }, -- Protecting the Shipment (lvl 15, ~1050 xp, sim lvl 14)
    { "accept", 86758 }, -- Twisting the Knife (lvl 16, ~1150 xp, sim lvl 14)
    { "accept", 385 }, -- Crocolisk Hunting (lvl 15, ~1050 xp, sim lvl 14)
    { "turnin", 2039, xp = 270 }, -- Find Bingles (lvl 15, ~270 xp, sim lvl 14)
    { "complete", 385, at = { 1432, 63.17, 47.6 } }, -- Crocolisk Hunting (lvl 15, ~1050 xp, sim lvl 14)
    { "complete", 86758, at = { 1432, 63.26, 47.65 } }, -- Twisting the Knife (lvl 16, ~1150 xp, sim lvl 14)
    { "turnin", 385, xp = 1050 }, -- Crocolisk Hunting (lvl 15, ~1050 xp, sim lvl 14)
    { "turnin", 86758, xp = 1150 }, -- Twisting the Knife (lvl 16, ~1150 xp, sim lvl 14)
    { "accept", 257, note = "Timed quest: do it right away" }, -- A Hunter's Boast (lvl 16, ~880 xp, sim lvl 14)
    { "complete", 257, at = { 1432, 76.53, 71.82 } }, -- A Hunter's Boast (lvl 16, ~880 xp, sim lvl 14)
    { "turnin", 257, xp = 880 }, -- A Hunter's Boast (lvl 16, ~880 xp, sim lvl 14)
    { "accept", 258, note = "Timed quest: do it right away" }, -- A Hunter's Challenge (lvl 17, ~950 xp, sim lvl 15)
    { "complete", 258, at = { 1432, 65.43, 39.37 } }, -- A Hunter's Challenge (lvl 17, ~950 xp, sim lvl 15)
    { "turnin", 258, xp = 950 }, -- A Hunter's Challenge (lvl 17, ~950 xp, sim lvl 15)
    { "goto", 1432, 33.94, 50.95, note = "Flight master" }, -- déplacement
    { "fly", 1455, note = "Ironforge, Dun Morogh" }, -- vol
    { "boat", 1455, 78, 51.4, note = "Take the Deeprun Tram to Stormwind" }, -- bateau
    { "turnin", 1338, xp = 980 }, -- Stormpike's Order (lvl 14, ~980 xp, sim lvl 15)
  },
})
