local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-04.
-- Simulation : 87 étapes, niveau final 29.00, ~34361 xp/h, 156 min.
Q:RegisterGuide({
  id = "A_04",
  title = "Wetlands",
  faction = "Alliance",
  minLevel = 26, maxLevel = 29,
  next = "A_05",
  steps = {
    { "note", "You pass through Stormwind: run The Stockade now for Crime and Punishment and What Comes Around..., or abandon them", optional = true, dungeon = "The Stockade" },
    { "goto", 1433, 25.5, 59.41, note = "Flight master" }, -- déplacement
    { "fly", 1453, node = 2, note = "Stormwind, Elwynn" }, -- vol
    { "boat", 1453, 24.1, 55.4, note = "Take the boat to Auberdine (Stormwind Harbor)" }, -- bateau
    { "boat", 1439, 32.4, 43.8, note = "Take the boat to Menethil Harbor" }, -- bateau
    { "fp", 1437, 9.49, 59.69 }, -- point de vol
    { "accept", 98189 }, -- Return the Statuette (lvl 25, ~1000 xp, sim lvl 26)
    { "accept", 98072 }, -- Crocs of the Sky (lvl 27, ~2200 xp, sim lvl 26)
    { "accept", 98240 }, -- Crimson Crate Delivery (lvl 29, ~590 xp, sim lvl 26)
    { "accept", 98815, optional = true, dungeon = "Excavation Site: Wetlands" }, -- Highland Hides (lvl 28, ~0 xp, sim lvl 26)
    { "accept", 464 }, -- War Banners (lvl 28, ~2300 xp, sim lvl 26)
    { "accept", 98230 }, -- This Land Was Their Land (lvl 29, ~590 xp, sim lvl 26)
    { "turnin", 98189, xp = 1000 }, -- Return the Statuette (lvl 25, ~1000 xp, sim lvl 26)
    { "accept", 98221 }, -- From the Ashes (lvl 28, ~570 xp, sim lvl 26)
    { "turnin", 98221, xp = 570 }, -- From the Ashes (lvl 28, ~570 xp, sim lvl 26)
    { "accept", 288 }, -- The Third Fleet (lvl 27, ~220 xp, sim lvl 26)
    { "complete", 288, at = { 1437, 10.7, 60.95 } }, -- The Third Fleet (lvl 27, ~220 xp, sim lvl 26)
    { "sethearth", 1437, 10.7, 60.95 }, -- lier la pierre de foyer
    { "turnin", 288, xp = 220 }, -- The Third Fleet (lvl 27, ~220 xp, sim lvl 26)
    { "accept", 289 }, -- The Cursed Crew (lvl 29, ~1750 xp, sim lvl 26)
    { "accept", 470 }, -- Digging Through the Ooze (lvl 24, ~2400 xp, sim lvl 26)
    { "accept", 95647, optional = true, dungeon = "Excavation Site: Wetlands" }, -- Lost in the Thicket Things (lvl 31, ~0 xp, sim lvl 26)
    { "accept", 472 }, -- Fall of Dun Modr (lvl 25, ~1000 xp, sim lvl 26)
    { "accept", 305 }, -- In Search of The Excavation Team (lvl 24, ~970 xp, sim lvl 26)
    { "complete", 289, at = { 1437, 13.81, 30.07 } }, -- The Cursed Crew (lvl 29, ~1750 xp, sim lvl 26)
    { "complete", 289, at = { 1437, 14.67, 24.18 } }, -- The Cursed Crew (lvl 29, ~1750 xp, sim lvl 26)
    { "level", 27, at = { 1437, 36.72, 21.01 }, note = "About 14 mobs here (Highland Scytheclaw, level 25)" }, -- farm de niveau
    { "accept", 87491 }, -- Spark of Freedom (lvl 32, ~640 xp, sim lvl 27)
    { "turnin", 87491, xp = 640 }, -- Spark of Freedom (lvl 32, ~640 xp, sim lvl 27)
    { "accept", 304, optional = true, dungeon = "Group quest: Balgaras the Foul, level 34 elite" }, -- A Grim Task (lvl 34, ~3350 xp, sim lvl 27)
    { "turnin", 472, xp = 1000 }, -- Fall of Dun Modr (lvl 25, ~1000 xp, sim lvl 27)
    { "accept", 303 }, -- The Dark Iron War (lvl 30, ~2450 xp, sim lvl 27)
    { "accept", 98245 }, -- Razormaw Needling (lvl 29, ~2350 xp, sim lvl 27)
    { "accept", 98291 }, -- Death to the Dragonmaw (lvl 30, ~2450 xp, sim lvl 27)
    { "turnin", 98230, xp = 590 }, -- This Land Was Their Land (lvl 29, ~590 xp, sim lvl 27)
    { "turnin", 98240, xp = 590 }, -- Crimson Crate Delivery (lvl 29, ~590 xp, sim lvl 27)
    { "accept", 95646, optional = true, dungeon = "Excavation Site: Wetlands" }, -- Horrors in the Highland (lvl 31, ~0 xp, sim lvl 27)
    { "accept", 98283 }, -- Carnage (lvl 30, ~2450 xp, sim lvl 27)
    { "complete", 304, at = { 1437, 61.9, 29.94 }, optional = true, dungeon = "Group quest: Balgaras the Foul, level 34 elite" }, -- A Grim Task (lvl 34, ~3350 xp, sim lvl 27)
    { "complete", 98283, obj = 1, at = { 1437, 59.47, 32.33 } }, -- Carnage (lvl 30, ~2450 xp, sim lvl 27)
    { "complete", 98283, at = { 1437, 69.89, 29.26 } }, -- Carnage (lvl 30, ~2450 xp, sim lvl 27)
    { "complete", 98245, at = { 1437, 68.59, 30.72 } }, -- Razormaw Needling (lvl 29, ~2350 xp, sim lvl 27)
    { "complete", 98072, at = { 1437, 63.79, 42.65 } }, -- Crocs of the Sky (lvl 27, ~2200 xp, sim lvl 27)
    { "complete", 98291, at = { 1437, 60.93, 44.99 } }, -- Death to the Dragonmaw (lvl 30, ~2450 xp, sim lvl 27)
    { "complete", 464, at = { 1437, 60.83, 45.03 } }, -- War Banners (lvl 28, ~2300 xp, sim lvl 27)
    { "turnin", 98283, xp = 2450 }, -- Carnage (lvl 30, ~2450 xp, sim lvl 27)
    { "turnin", 304, xp = 3350, optional = true, dungeon = "Group quest: Balgaras the Foul, level 34 elite" }, -- A Grim Task (lvl 34, ~3350 xp, sim lvl 27)
    { "complete", 303, at = { 1437, 48.17, 16.87 } }, -- The Dark Iron War (lvl 30, ~2450 xp, sim lvl 27)
    { "turnin", 303, xp = 2450 }, -- The Dark Iron War (lvl 30, ~2450 xp, sim lvl 27)
    { "complete", 470, at = { 1437, 44.36, 25.54 } }, -- Digging Through the Ooze (lvl 24, ~2400 xp, sim lvl 27)
    { "accept", 299 }, -- Uncovering the Past (lvl 27, ~2300 xp, sim lvl 27)
    { "accept", 98216, optional = true, dungeon = "Group quest: Goaz Warder, level 32 elite" }, -- Understanding Our Present (lvl 31, ~2500 xp, sim lvl 27)
    { "turnin", 305, xp = 970 }, -- In Search of The Excavation Team (lvl 24, ~970 xp, sim lvl 27)
    { "accept", 306 }, -- In Search of The Excavation Team (lvl 24, ~485 xp, sim lvl 27)
    { "accept", 98824, optional = true, dungeon = "Excavation Site: Wetlands" }, -- Prehistoric Prism (lvl 31, ~0 xp, sim lvl 27)
    { "accept", 294 }, -- Ormer's Revenge (lvl 24, ~1950 xp, sim lvl 27)
    { "complete", 299, at = { 1437, 34.65, 47.15 } }, -- Uncovering the Past (lvl 27, ~2300 xp, sim lvl 27)
    { "complete", 98216, at = { 1437, 34.65, 49.89 }, optional = true, dungeon = "Group quest: Goaz Warder, level 32 elite" }, -- Understanding Our Present (lvl 31, ~2500 xp, sim lvl 27)
    { "turnin", 470, xp = 2400 }, -- Digging Through the Ooze (lvl 24, ~2400 xp, sim lvl 27)
    { "turnin", 289, xp = 1750 }, -- The Cursed Crew (lvl 29, ~1750 xp, sim lvl 28)
    { "accept", 290 }, -- Lifting the Curse (lvl 30, ~1200 xp, sim lvl 28)
    { "turnin", 464, xp = 2300 }, -- War Banners (lvl 28, ~2300 xp, sim lvl 28)
    { "accept", 465 }, -- Nek'rosh's Gambit (lvl 31, ~1900 xp, sim lvl 28)
    { "complete", 294, at = { 1437, 24.5, 48.38 } }, -- Ormer's Revenge (lvl 24, ~1950 xp, sim lvl 28)
    { "turnin", 465, xp = 1900 }, -- Nek'rosh's Gambit (lvl 31, ~1900 xp, sim lvl 28)
    { "accept", 474, optional = true, dungeon = "Group quest: Chieftain Nek'rosh, level 32 elite" }, -- Defeat Nek'rosh (lvl 32, ~2550 xp, sim lvl 28)
    { "turnin", 98291, xp = 2450 }, -- Death to the Dragonmaw (lvl 30, ~2450 xp, sim lvl 28)
    { "turnin", 98245, xp = 2350 }, -- Razormaw Needling (lvl 29, ~2350 xp, sim lvl 28)
    { "accept", 98223 }, -- Old Habits (lvl 31, ~940 xp, sim lvl 28)
    { "complete", 474, at = { 1437, 53.51, 54.67 }, optional = true, dungeon = "Group quest: Chieftain Nek'rosh, level 32 elite" }, -- Defeat Nek'rosh (lvl 32, ~2550 xp, sim lvl 28)
    { "turnin", 98216, xp = 2500, optional = true, dungeon = "Group quest: Goaz Warder, level 32 elite" }, -- Understanding Our Present (lvl 31, ~2500 xp, sim lvl 28)
    { "turnin", 299, xp = 2300 }, -- Uncovering the Past (lvl 27, ~2300 xp, sim lvl 28)
    { "turnin", 294, xp = 1950 }, -- Ormer's Revenge (lvl 24, ~1950 xp, sim lvl 28)
    { "accept", 295 }, -- Ormer's Revenge (lvl 27, ~2200 xp, sim lvl 28)
    { "complete", 295, at = { 1437, 35.04, 50.27 } }, -- Ormer's Revenge (lvl 27, ~2200 xp, sim lvl 28)
    { "turnin", 295, xp = 2200 }, -- Ormer's Revenge (lvl 27, ~2200 xp, sim lvl 28)
    { "accept", 296 }, -- Ormer's Revenge (lvl 29, ~2950 xp, sim lvl 28)
    { "complete", 296, at = { 1437, 33.26, 51.51 } }, -- Ormer's Revenge (lvl 29, ~2950 xp, sim lvl 28)
    { "turnin", 296, xp = 2950 }, -- Ormer's Revenge (lvl 29, ~2950 xp, sim lvl 28)
    { "complete", 290, at = { 1437, 15.45, 23.61 } }, -- Lifting the Curse (lvl 30, ~1200 xp, sim lvl 28)
    { "turnin", 290, xp = 1200 }, -- Lifting the Curse (lvl 30, ~1200 xp, sim lvl 28)
    { "accept", 292 }, -- The Eye of Paleth (lvl 30, ~1200 xp, sim lvl 28)
    { "turnin", 306, xp = 485 }, -- In Search of The Excavation Team (lvl 24, ~485 xp, sim lvl 28)
    { "turnin", 98072, xp = 2200 }, -- Crocs of the Sky (lvl 27, ~2200 xp, sim lvl 28)
    { "turnin", 98223, xp = 940 }, -- Old Habits (lvl 31, ~940 xp, sim lvl 28)
    { "turnin", 474, xp = 2550, optional = true, dungeon = "Group quest: Chieftain Nek'rosh, level 32 elite" }, -- Defeat Nek'rosh (lvl 32, ~2550 xp, sim lvl 28)
    { "turnin", 292, xp = 1200 }, -- The Eye of Paleth (lvl 30, ~1200 xp, sim lvl 28)
    { "note", "Last pass near the Excavation Site: run it now, or abandon Highland Hides, Horrors in the Highland, Lost in the Thicket Things and Prehistoric Prism", optional = true, dungeon = "Excavation Site: Wetlands" },
    { "level", 29, at = { 1437, 11.76, 65.38 }, note = "About 20 more mobs here (Bluegill Raider, level 28)" }, -- farm de niveau
  },
})
