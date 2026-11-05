local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-04.
-- Simulation : 78 étapes, niveau final 15.55, ~21188 xp/h, 119 min.
Q:RegisterGuide({
  id = "A_DwarfGnome_03",
  title = "Loch Modan",
  faction = "Alliance",
  races = { "Dwarf", "Gnome" },
  minLevel = 11, maxLevel = 14,
  next = "A_DwarfGnome_04",
  choices = {
    { id = "A_DwarfGnome_04", travel = { kind = "walk", minutes = 2 } },
    { id = "A_01", travel = { kind = "boat", minutes = 7 } },
  },
  sim = { steps = 78, endLevel = 15.55, xpPerHour = 21188, minutes = 119 },
  steps = {
    { "accept", 1339 }, -- Mountaineer Stormpike's Task (lvl 15, ~540 xp, sim lvl 12)
    { "sethearth", 1432, 35.53, 48.4 }, -- lier la pierre de foyer
    { "accept", 224 }, -- In Defense of the King's Lands (lvl 12, ~910 xp, sim lvl 12)
    { "complete", 224, at = { 1432, 31.8, 73.61 } }, -- In Defense of the King's Lands (lvl 12, ~910 xp, sim lvl 12)
    { "turnin", 224, xp = 910 }, -- In Defense of the King's Lands (lvl 12, ~910 xp, sim lvl 12)
    { "accept", 237 }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 12)
    { "complete", 237, at = { 1432, 35.7, 85.02 } }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 12)
    { "turnin", 237, xp = 1050 }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 12)
    { "accept", 263 }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 12)
    { "accept", 86585 }, -- Banner of the Fallen (lvl 17, ~1250 xp, sim lvl 12)
    { "complete", 263, at = { 1432, 36.01, 91.83 } }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 12)
    { "accept", 298 }, -- Excavation Progress Report (lvl 15, ~270 xp, sim lvl 12)
    { "level", 13, at = { 1432, 32.79, 73.77 }, note = "About 18 mobs here (Stonesplinter Trogg, level 11)" }, -- farm de niveau
    { "accept", 436 }, -- Ironband's Excavation (lvl 18, ~340 xp, sim lvl 13)
    { "turnin", 298, xp = 270 }, -- Excavation Progress Report (lvl 15, ~270 xp, sim lvl 13)
    { "accept", 301 }, -- Report to Ironforge (lvl 15, ~540 xp, sim lvl 13)
    { "accept", 6387 }, -- Honor Students (lvl 10, ~210 xp, sim lvl 13)
    { "turnin", 6387, xp = 210 }, -- Honor Students (lvl 10, ~210 xp, sim lvl 13)
    { "accept", 6391 }, -- Ride to Ironforge (lvl 10, ~420 xp, sim lvl 13)
    { "fly", 1455, node = 6, note = "Ironforge, Dun Morogh" }, -- vol
    { "turnin", 301, xp = 540 }, -- Report to Ironforge (lvl 15, ~540 xp, sim lvl 13)
    { "note", "The Hall of Thanes is under Ironforge (levels 13-18): run it on this visit, or abandon Old Ironforge Incursion", optional = true, dungeon = "The Hall of Thanes" },
    { "accept", 302 }, -- Powder to Ironband (lvl 15, ~270 xp, sim lvl 13)
    { "accept", 79091 }, -- Archmage Antonidas: The Unabridged Autobiography (lvl 20, ~1550 xp, sim lvl 13)
    { "turnin", 6391, xp = 420 }, -- Ride to Ironforge (lvl 10, ~420 xp, sim lvl 13)
    { "accept", 6388 }, -- Gryth Thurden (lvl 10, ~210 xp, sim lvl 13)
    { "turnin", 6388, xp = 210 }, -- Gryth Thurden (lvl 10, ~210 xp, sim lvl 13)
    { "accept", 6392 }, -- Return to Brock (lvl 10, ~1050 xp, sim lvl 13)
    { "accept", 2039 }, -- Find Bingles (lvl 15, ~270 xp, sim lvl 13)
    { "turnin", 1339, xp = 540 }, -- Mountaineer Stormpike's Task (lvl 15, ~540 xp, sim lvl 13)
    { "accept", 307 }, -- Filthy Paws (lvl 15, ~1350 xp, sim lvl 13)
    { "accept", 1338 }, -- Stormpike's Order (lvl 14, ~980 xp, sim lvl 13)
    { "complete", 307, at = { 1432, 35.5, 24.64 } }, -- Filthy Paws (lvl 15, ~1350 xp, sim lvl 13)
    { "turnin", 307, xp = 1350 }, -- Filthy Paws (lvl 15, ~1350 xp, sim lvl 13)
    { "turnin", 302, xp = 270 }, -- Powder to Ironband (lvl 15, ~270 xp, sim lvl 13)
    { "accept", 273 }, -- Resupplying the Excavation (lvl 15, ~270 xp, sim lvl 13)
    { "turnin", 6392, xp = 1050 }, -- Return to Brock (lvl 10, ~1050 xp, sim lvl 13)
    { "complete", 273, at = { 1432, 52.2, 69.37 } }, -- Resupplying the Excavation (lvl 15, ~270 xp, sim lvl 13)
    { "turnin", 273, xp = 270 }, -- Resupplying the Excavation (lvl 15, ~270 xp, sim lvl 13)
    { "accept", 454 }, -- After the Ambush (lvl 15, ~105 xp, sim lvl 13)
    { "turnin", 454, xp = 105 }, -- After the Ambush (lvl 15, ~105 xp, sim lvl 13)
    { "accept", 309 }, -- Protecting the Shipment (lvl 15, ~1050 xp, sim lvl 13)
    { "turnin", 436, xp = 340 }, -- Ironband's Excavation (lvl 18, ~340 xp, sim lvl 13)
    { "accept", 297 }, -- Gathering Idols (lvl 18, ~1350 xp, sim lvl 13)
    { "level", 14, at = { 1432, 59.21, 40.68 }, note = "About 50 mobs here (Loch Crocolisk, level 14)" }, -- farm de niveau
    { "complete", 309, at = { 1432, 65.12, 65.77 } }, -- Protecting the Shipment (lvl 15, ~1050 xp, sim lvl 14)
    { "turnin", 309, xp = 1050 }, -- Protecting the Shipment (lvl 15, ~1050 xp, sim lvl 14)
    { "accept", 257, note = "Timed quest: do it right away" }, -- A Hunter's Boast (lvl 16, ~880 xp, sim lvl 14)
    { "complete", 257, at = { 1432, 76.53, 71.82 } }, -- A Hunter's Boast (lvl 16, ~880 xp, sim lvl 14)
    { "turnin", 257, xp = 880 }, -- A Hunter's Boast (lvl 16, ~880 xp, sim lvl 14)
    { "accept", 258, note = "Timed quest: do it right away" }, -- A Hunter's Challenge (lvl 17, ~950 xp, sim lvl 14)
    { "complete", 258, at = { 1432, 65.43, 39.37 } }, -- A Hunter's Challenge (lvl 17, ~950 xp, sim lvl 14)
    { "turnin", 258, xp = 950 }, -- A Hunter's Challenge (lvl 17, ~950 xp, sim lvl 14)
    { "accept", 86758 }, -- Twisting the Knife (lvl 16, ~1150 xp, sim lvl 14)
    { "turnin", 2039, xp = 270 }, -- Find Bingles (lvl 15, ~270 xp, sim lvl 14)
    { "complete", 86758, at = { 1432, 63.26, 47.65 } }, -- Twisting the Knife (lvl 16, ~1150 xp, sim lvl 14)
    { "complete", 86585, at = { 1432, 32.86, 87.05 } }, -- Banner of the Fallen (lvl 17, ~1250 xp, sim lvl 14)
    { "turnin", 263, xp = 1050 }, -- In Defense of the King's Lands (lvl 15, ~1050 xp, sim lvl 14)
    { "turnin", 86585, xp = 1250 }, -- Banner of the Fallen (lvl 17, ~1250 xp, sim lvl 14)
    { "complete", 297, at = { 1432, 70.11, 64.42 } }, -- Gathering Idols (lvl 18, ~1350 xp, sim lvl 14)
    { "accept", 86613, at = { 1432, 69.79, 65 }, note = "Loot Excavation Tools to start the quest" }, -- Excavation Tools (lvl 18, ~1350 xp, sim lvl 14)
    { "complete", 86613, at = { 1432, 69.79, 65 } }, -- Excavation Tools (lvl 18, ~1350 xp, sim lvl 14)
    { "turnin", 297, xp = 1350 }, -- Gathering Idols (lvl 18, ~1350 xp, sim lvl 14)
    { "turnin", 86613, xp = 1350 }, -- Excavation Tools (lvl 18, ~1350 xp, sim lvl 14)
    { "turnin", 86758, xp = 1150 }, -- Twisting the Knife (lvl 16, ~1150 xp, sim lvl 15)
    { "accept", 78148 }, -- Runes of the Sorcerer-Kings (lvl 20, ~1550 xp, sim lvl 15)
    { "complete", 78148, at = { 1432, 77.4, 14 } }, -- Runes of the Sorcerer-Kings (lvl 20, ~1550 xp, sim lvl 15)
    { "hearth", 1432 }, -- pierre de foyer
    { "accept", 79093 }, -- Rumi of Gnomeregan: The Collected Works (lvl 20, ~1550 xp, sim lvl 15)
    { "complete", 79093, at = { 1432, 35.6, 48.9 } }, -- Rumi of Gnomeregan: The Collected Works (lvl 20, ~1550 xp, sim lvl 15)
    { "goto", 1432, 33.94, 50.95, note = "Flight master" }, -- déplacement
    { "fly", 1455, node = 6, note = "Ironforge, Dun Morogh" }, -- vol
    { "complete", 79091, at = { 1455, 76, 10.4 } }, -- Archmage Antonidas: The Unabridged Autobiography (lvl 20, ~1550 xp, sim lvl 15)
    { "boat", 1455, 78, 51.4, note = "Take the Deeprun Tram to Stormwind" }, -- bateau
    { "turnin", 1338, xp = 980 }, -- Stormpike's Order (lvl 14, ~980 xp, sim lvl 15)
    { "fp", 1453, 71.29, 72.23 }, -- point de vol
    { "turnin", 79091, xp = 1550 }, -- Archmage Antonidas: The Unabridged Autobiography (lvl 20, ~1550 xp, sim lvl 15)
    { "turnin", 78148, xp = 1550 }, -- Runes of the Sorcerer-Kings (lvl 20, ~1550 xp, sim lvl 15)
    { "turnin", 79093, xp = 1550 }, -- Rumi of Gnomeregan: The Collected Works (lvl 20, ~1550 xp, sim lvl 15)
  },
})
