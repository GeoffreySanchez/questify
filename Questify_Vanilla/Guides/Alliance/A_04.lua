local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-03.
-- Simulation : 89 étapes, niveau final 29.70, ~39497 xp/h, 165 min.
Q:RegisterGuide({
  id = "A_04",
  title = "Wetlands",
  faction = "Alliance",
  minLevel = 26, maxLevel = 29,
  next = "A_05",
  steps = {
    { "goto", 1433, 25.5, 59.41, note = "Flight master" }, -- déplacement
    { "fly", 1453, note = "Stormwind, Elwynn" }, -- vol
    { "boat", 1453, 69.6, 30.3, note = "Take the Deeprun Tram to Ironforge" }, -- bateau
    { "fp", 1455, 55.5, 47.74 }, -- point de vol
    { "fp", 1437, 9.49, 59.69 }, -- point de vol
    { "accept", 288 }, -- The Third Fleet (lvl 27, ~220 xp, sim lvl 27)
    { "complete", 288, at = { 1437, 10.7, 60.95 } }, -- The Third Fleet (lvl 27, ~220 xp, sim lvl 27)
    { "sethearth", 1437, 10.7, 60.95 }, -- lier la pierre de foyer
    { "turnin", 288, xp = 220 }, -- The Third Fleet (lvl 27, ~220 xp, sim lvl 27)
    { "accept", 289 }, -- The Cursed Crew (lvl 29, ~1750 xp, sim lvl 27)
    { "accept", 464 }, -- War Banners (lvl 28, ~2300 xp, sim lvl 27)
    { "accept", 98230 }, -- This Land Was Their Land (lvl 29, ~590 xp, sim lvl 27)
    { "accept", 98189 }, -- Return the Statuette (lvl 25, ~1000 xp, sim lvl 27)
    { "accept", 98072 }, -- Crocs of the Sky (lvl 27, ~2200 xp, sim lvl 27)
    { "accept", 98240 }, -- Crimson Crate Delivery (lvl 29, ~590 xp, sim lvl 27)
    { "accept", 98815, optional = true, dungeon = "Excavation Site: Wetlands" }, -- Highland Hides (lvl 28, ~0 xp, sim lvl 27)
    { "accept", 472 }, -- Fall of Dun Modr (lvl 25, ~1000 xp, sim lvl 27)
    { "accept", 305 }, -- In Search of The Excavation Team (lvl 24, ~970 xp, sim lvl 27)
    { "complete", 289, at = { 1437, 13.81, 30.07 } }, -- The Cursed Crew (lvl 29, ~1750 xp, sim lvl 27)
    { "complete", 289, at = { 1437, 14.67, 24.18 } }, -- The Cursed Crew (lvl 29, ~1750 xp, sim lvl 27)
    { "accept", 87491 }, -- Spark of Freedom (lvl 32, ~640 xp, sim lvl 27)
    { "accept", 303 }, -- The Dark Iron War (lvl 30, ~2450 xp, sim lvl 27)
    { "accept", 304 }, -- A Grim Task (lvl 34, ~3350 xp, sim lvl 27)
    { "turnin", 472, xp = 1000 }, -- Fall of Dun Modr (lvl 25, ~1000 xp, sim lvl 27)
    { "level", 28, note = "About 170 mobs" }, -- farm de niveau
    { "accept", 631 }, -- The Thandol Span (lvl 31, ~2500 xp, sim lvl 28)
    { "accept", 98291 }, -- Death to the Dragonmaw (lvl 30, ~2450 xp, sim lvl 28)
    { "accept", 98245 }, -- Razormaw Needling (lvl 29, ~2350 xp, sim lvl 28)
    { "turnin", 98240, xp = 590 }, -- Crimson Crate Delivery (lvl 29, ~590 xp, sim lvl 28)
    { "accept", 98283 }, -- Carnage (lvl 30, ~2450 xp, sim lvl 28)
    { "accept", 95646, optional = true, dungeon = "Excavation Site: Wetlands" }, -- Horrors in the Highland (lvl 31, ~0 xp, sim lvl 28)
    { "complete", 304, at = { 1437, 61.9, 29.94 } }, -- A Grim Task (lvl 34, ~3350 xp, sim lvl 28)
    { "complete", 98283, obj = 1, at = { 1437, 59.47, 32.33 } }, -- Carnage (lvl 30, ~2450 xp, sim lvl 28)
    { "complete", 98283, at = { 1437, 69.89, 29.26 } }, -- Carnage (lvl 30, ~2450 xp, sim lvl 28)
    { "complete", 98245, at = { 1437, 68.59, 30.72 } }, -- Razormaw Needling (lvl 29, ~2350 xp, sim lvl 28)
    { "complete", 98072, at = { 1437, 63.79, 42.65 } }, -- Crocs of the Sky (lvl 27, ~2200 xp, sim lvl 28)
    { "complete", 98291, at = { 1437, 60.93, 44.99 } }, -- Death to the Dragonmaw (lvl 30, ~2450 xp, sim lvl 28)
    { "complete", 464, at = { 1437, 60.83, 45.03 } }, -- War Banners (lvl 28, ~2300 xp, sim lvl 28)
    { "turnin", 98283, xp = 2450 }, -- Carnage (lvl 30, ~2450 xp, sim lvl 28)
    { "complete", 303, at = { 1437, 48.17, 16.87 } }, -- The Dark Iron War (lvl 30, ~2450 xp, sim lvl 28)
    { "accept", 87318 }, -- Hearts of the Lost (lvl 33, ~1300 xp, sim lvl 28)
    { "turnin", 631, xp = 2500 }, -- The Thandol Span (lvl 31, ~2500 xp, sim lvl 28)
    { "accept", 632 }, -- The Thandol Span (lvl 31, ~2500 xp, sim lvl 28)
    { "accept", 88758 }, -- Sentiments of the Lost (lvl 33, ~1300 xp, sim lvl 28)
    { "turnin", 87318, xp = 1300 }, -- Hearts of the Lost (lvl 33, ~1300 xp, sim lvl 28)
    { "turnin", 88758, xp = 1300 }, -- Sentiments of the Lost (lvl 33, ~1300 xp, sim lvl 28)
    { "turnin", 87491, xp = 640 }, -- Spark of Freedom (lvl 32, ~640 xp, sim lvl 28)
    { "turnin", 632, xp = 2500 }, -- The Thandol Span (lvl 31, ~2500 xp, sim lvl 28)
    { "turnin", 304, xp = 3350 }, -- A Grim Task (lvl 34, ~3350 xp, sim lvl 28)
    { "turnin", 303, xp = 2450 }, -- The Dark Iron War (lvl 30, ~2450 xp, sim lvl 28)
    { "accept", 294 }, -- Ormer's Revenge (lvl 24, ~1950 xp, sim lvl 28)
    { "accept", 98216 }, -- Understanding Our Present (lvl 31, ~2500 xp, sim lvl 28)
    { "hearth", 1437 }, -- pierre de foyer
    { "accept", 95647, optional = true, dungeon = "Excavation Site: Wetlands" }, -- Lost in the Thicket Things (lvl 31, ~0 xp, sim lvl 28)
    { "turnin", 289, xp = 1750 }, -- The Cursed Crew (lvl 29, ~1750 xp, sim lvl 28)
    { "accept", 290 }, -- Lifting the Curse (lvl 30, ~1200 xp, sim lvl 28)
    { "turnin", 98189, xp = 1000 }, -- Return the Statuette (lvl 25, ~1000 xp, sim lvl 28)
    { "turnin", 464, xp = 2300 }, -- War Banners (lvl 28, ~2300 xp, sim lvl 28)
    { "accept", 98221 }, -- From the Ashes (lvl 28, ~570 xp, sim lvl 28)
    { "accept", 465 }, -- Nek'rosh's Gambit (lvl 31, ~1900 xp, sim lvl 28)
    { "complete", 294, at = { 1437, 24.5, 48.38 } }, -- Ormer's Revenge (lvl 24, ~1950 xp, sim lvl 28)
    { "complete", 98216, at = { 1437, 34.65, 49.89 } }, -- Understanding Our Present (lvl 31, ~2500 xp, sim lvl 29)
    { "turnin", 294, xp = 1950 }, -- Ormer's Revenge (lvl 24, ~1950 xp, sim lvl 29)
    { "accept", 295 }, -- Ormer's Revenge (lvl 27, ~2200 xp, sim lvl 29)
    { "complete", 295, at = { 1437, 35.04, 50.27 } }, -- Ormer's Revenge (lvl 27, ~2200 xp, sim lvl 29)
    { "turnin", 295, xp = 2200 }, -- Ormer's Revenge (lvl 27, ~2200 xp, sim lvl 29)
    { "accept", 296 }, -- Ormer's Revenge (lvl 29, ~2950 xp, sim lvl 29)
    { "complete", 296, at = { 1437, 33.26, 51.51 } }, -- Ormer's Revenge (lvl 29, ~2950 xp, sim lvl 29)
    { "turnin", 296, xp = 2950 }, -- Ormer's Revenge (lvl 29, ~2950 xp, sim lvl 29)
    { "turnin", 98216, xp = 2500 }, -- Understanding Our Present (lvl 31, ~2500 xp, sim lvl 29)
    { "accept", 98824, optional = true, dungeon = "Excavation Site: Wetlands" }, -- Prehistoric Prism (lvl 31, ~0 xp, sim lvl 29)
    { "turnin", 305, xp = 970 }, -- In Search of The Excavation Team (lvl 24, ~970 xp, sim lvl 29)
    { "accept", 306 }, -- In Search of The Excavation Team (lvl 24, ~485 xp, sim lvl 29)
    { "turnin", 465, xp = 1900 }, -- Nek'rosh's Gambit (lvl 31, ~1900 xp, sim lvl 29)
    { "accept", 474 }, -- Defeat Nek'rosh (lvl 32, ~2550 xp, sim lvl 29)
    { "complete", 474, at = { 1437, 53.51, 54.67 } }, -- Defeat Nek'rosh (lvl 32, ~2550 xp, sim lvl 29)
    { "accept", 98223 }, -- Old Habits (lvl 31, ~940 xp, sim lvl 29)
    { "turnin", 98230, xp = 590 }, -- This Land Was Their Land (lvl 29, ~590 xp, sim lvl 29)
    { "turnin", 98291, xp = 2450 }, -- Death to the Dragonmaw (lvl 30, ~2450 xp, sim lvl 29)
    { "turnin", 98245, xp = 2350 }, -- Razormaw Needling (lvl 29, ~2350 xp, sim lvl 29)
    { "complete", 290, at = { 1437, 15.45, 23.61 } }, -- Lifting the Curse (lvl 30, ~1200 xp, sim lvl 29)
    { "turnin", 290, xp = 1200 }, -- Lifting the Curse (lvl 30, ~1200 xp, sim lvl 29)
    { "accept", 292 }, -- The Eye of Paleth (lvl 30, ~1200 xp, sim lvl 29)
    { "turnin", 306, xp = 485 }, -- In Search of The Excavation Team (lvl 24, ~485 xp, sim lvl 29)
    { "turnin", 98072, xp = 2200 }, -- Crocs of the Sky (lvl 27, ~2200 xp, sim lvl 29)
    { "turnin", 474, xp = 2550 }, -- Defeat Nek'rosh (lvl 32, ~2550 xp, sim lvl 29)
    { "turnin", 98221, xp = 570 }, -- From the Ashes (lvl 28, ~570 xp, sim lvl 29)
    { "turnin", 98223, xp = 940 }, -- Old Habits (lvl 31, ~940 xp, sim lvl 29)
    { "turnin", 292, xp = 1200 }, -- The Eye of Paleth (lvl 30, ~1200 xp, sim lvl 29)
  },
})
