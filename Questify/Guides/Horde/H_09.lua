local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 99 étapes, niveau final 37.06, ~39942 xp/h, 208 min.
Q:RegisterGuide({
  id = "H_09",
  title = "Stranglethorn Vale",
  faction = "Horde",
  minLevel = 35, maxLevel = 37,
  next = "H_10",
  sim = { steps = 99, endLevel = 37.06, xpPerHour = 39942, minutes = 208 },
  steps = {
    { "boat", 1411, 50.69, 12.89, note = "Take the zeppelin to Grom'gol (Stranglethorn Vale)" }, -- bateau
    { "fp", 1434, 32.54, 29.35 }, -- point de vol
    { "accept", 568 }, -- The Defense of Grom'gol (lvl 36, ~2800 xp, sim lvl 35)
    { "accept", 581 }, -- Hunt for Yenniku (lvl 34, ~2000 xp, sim lvl 35)
    { "accept", 629 }, -- The Vile Reef (lvl 37, ~2850 xp, sim lvl 35)
    { "accept", 638 }, -- Trollbane (lvl 37, ~0 xp, sim lvl 35)
    { "complete", 568, at = { 1434, 38.49, 20.44 } }, -- The Defense of Grom'gol (lvl 36, ~2800 xp, sim lvl 35)
    { "accept", 339 }, -- Chapter I (lvl 40, ~780 xp, sim lvl 35)
    { "accept", 342 }, -- Chapter IV (lvl 40, ~780 xp, sim lvl 35)
    { "accept", 583 }, -- Welcome to the Jungle (lvl 30, ~245 xp, sim lvl 35)
    { "accept", 341 }, -- Chapter III (lvl 40, ~780 xp, sim lvl 35)
    { "turnin", 5762, xp = 1250 }, -- Hemet Nesingwary (lvl 31, ~1250 xp, sim lvl 35)
    { "turnin", 583, xp = 245 }, -- Welcome to the Jungle (lvl 30, ~245 xp, sim lvl 35)
    { "accept", 194 }, -- Raptor Mastery (lvl 34, ~1350 xp, sim lvl 35)
    { "accept", 185 }, -- Tiger Mastery (lvl 31, ~1250 xp, sim lvl 35)
    { "accept", 190 }, -- Panther Mastery (lvl 31, ~1250 xp, sim lvl 35)
    { "turnin", 5763, xp = 1250 }, -- Hunting in Stranglethorn (lvl 31, ~1250 xp, sim lvl 35)
    { "complete", 185, at = { 1434, 34.28, 11.84 } }, -- Tiger Mastery (lvl 31, ~1250 xp, sim lvl 35)
    { "complete", 190, at = { 1434, 41.8, 12.69 } }, -- Panther Mastery (lvl 31, ~1250 xp, sim lvl 35)
    { "turnin", 185, xp = 1250 }, -- Tiger Mastery (lvl 31, ~1250 xp, sim lvl 35)
    { "accept", 186 }, -- Tiger Mastery (lvl 33, ~1300 xp, sim lvl 35)
    { "turnin", 190, xp = 1250 }, -- Panther Mastery (lvl 31, ~1250 xp, sim lvl 35)
    { "accept", 191 }, -- Panther Mastery (lvl 33, ~1300 xp, sim lvl 35)
    { "complete", 194, at = { 1434, 26.88, 16.33 } }, -- Raptor Mastery (lvl 34, ~1350 xp, sim lvl 35)
    { "complete", 581, at = { 1434, 25.24, 10.4 } }, -- Hunt for Yenniku (lvl 34, ~2000 xp, sim lvl 35)
    { "accept", 635, at = { 1434, 25.06, 10.31 }, note = "Loot Pendant of Myzrael to start the quest" }, -- Crystal in the Mountains (lvl 35, ~0 xp, sim lvl 35)
    { "complete", 191, at = { 1434, 29.62, 10.42 } }, -- Panther Mastery (lvl 33, ~1300 xp, sim lvl 35)
    { "complete", 186, at = { 1434, 29.8, 10.25 } }, -- Tiger Mastery (lvl 33, ~1300 xp, sim lvl 35)
    { "turnin", 191, xp = 1300 }, -- Panther Mastery (lvl 33, ~1300 xp, sim lvl 35)
    { "accept", 192 }, -- Panther Mastery (lvl 38, ~2150 xp, sim lvl 35)
    { "turnin", 186, xp = 1300 }, -- Tiger Mastery (lvl 33, ~1300 xp, sim lvl 35)
    { "accept", 187 }, -- Tiger Mastery (lvl 35, ~2050 xp, sim lvl 35)
    { "turnin", 194, xp = 1350 }, -- Raptor Mastery (lvl 34, ~1350 xp, sim lvl 35)
    { "accept", 195 }, -- Raptor Mastery (lvl 36, ~1400 xp, sim lvl 35)
    { "complete", 187, at = { 1434, 35.01, 18.88 } }, -- Tiger Mastery (lvl 35, ~2050 xp, sim lvl 35)
    { "turnin", 581, xp = 2000 }, -- Hunt for Yenniku (lvl 34, ~2000 xp, sim lvl 35)
    { "accept", 582 }, -- Headhunting (lvl 37, ~2100 xp, sim lvl 35)
    { "turnin", 568, xp = 2800 }, -- The Defense of Grom'gol (lvl 36, ~2800 xp, sim lvl 35)
    { "accept", 569 }, -- The Defense of Grom'gol (lvl 37, ~2850 xp, sim lvl 35)
    { "fp", 1434, 26.87, 77.1 }, -- point de vol
    { "accept", 189 }, -- Bloodscalp Ears (lvl 35, ~2050 xp, sim lvl 35)
    { "accept", 213 }, -- Hostile Takeover (lvl 36, ~2800 xp, sim lvl 35)
    { "accept", 201 }, -- Investigate the Camp (lvl 32, ~255 xp, sim lvl 35)
    { "accept", 605 }, -- Singing Blue Shards (lvl 35, ~2750 xp, sim lvl 35)
    { "sethearth", 1434, 27.04, 77.31 }, -- lier la pierre de foyer
    { "accept", 575 }, -- Supply and Demand (lvl 31, ~1250 xp, sim lvl 35)
    { "goto", 1434, 26.87, 77.1, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 20, note = "Grom'gol, Stranglethorn" }, -- vol
    { "complete", 192, at = { 1434, 49.19, 21.6 } }, -- Panther Mastery (lvl 38, ~2150 xp, sim lvl 35)
    { "complete", 213, at = { 1434, 43.95, 22.24 } }, -- Hostile Takeover (lvl 36, ~2800 xp, sim lvl 35)
    { "complete", 575, at = { 1434, 40.47, 13.2 } }, -- Supply and Demand (lvl 31, ~1250 xp, sim lvl 35)
    { "complete", 201, at = { 1434, 35.65, 10.59 } }, -- Investigate the Camp (lvl 32, ~255 xp, sim lvl 35)
    { "turnin", 187, xp = 2050 }, -- Tiger Mastery (lvl 35, ~2050 xp, sim lvl 35)
    { "accept", 188 }, -- Tiger Mastery (lvl 37, ~2850 xp, sim lvl 35)
    { "turnin", 192, xp = 2150 }, -- Panther Mastery (lvl 38, ~2150 xp, sim lvl 35)
    { "accept", 193 }, -- Panther Mastery (lvl 40, ~3150 xp, sim lvl 35)
    { "complete", 189, at = { 1434, 25.2, 10.38 } }, -- Bloodscalp Ears (lvl 35, ~2050 xp, sim lvl 35)
    { "complete", 582, at = { 1434, 23.53, 9.81 } }, -- Headhunting (lvl 37, ~2100 xp, sim lvl 36)
    { "complete", 605, at = { 1434, 24.73, 17.49 } }, -- Singing Blue Shards (lvl 35, ~2750 xp, sim lvl 36)
    { "complete", 629, at = { 1434, 24.8, 22.96 } }, -- The Vile Reef (lvl 37, ~2850 xp, sim lvl 36)
    { "hearth", 1434 }, -- pierre de foyer
    { "turnin", 213, xp = 2800 }, -- Hostile Takeover (lvl 36, ~2800 xp, sim lvl 36)
    { "turnin", 189, xp = 2050 }, -- Bloodscalp Ears (lvl 35, ~2050 xp, sim lvl 36)
    { "turnin", 201, xp = 255 }, -- Investigate the Camp (lvl 32, ~255 xp, sim lvl 36)
    { "turnin", 605, xp = 2750 }, -- Singing Blue Shards (lvl 35, ~2750 xp, sim lvl 36)
    { "turnin", 575, xp = 1250 }, -- Supply and Demand (lvl 31, ~1250 xp, sim lvl 36)
    { "accept", 577 }, -- Some Assembly Required (lvl 36, ~1400 xp, sim lvl 36)
    { "goto", 1434, 26.87, 77.1, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 20, note = "Grom'gol, Stranglethorn" }, -- vol
    { "complete", 193, at = { 1434, 49.6, 23.97 } }, -- Panther Mastery (lvl 40, ~3150 xp, sim lvl 36)
    { "complete", 342, obj = 2, at = { 1434, 44.83, 9.73 } }, -- Chapter IV (lvl 40, ~780 xp, sim lvl 36)
    { "complete", 339, at = { 1434, 44.83, 9.73 } }, -- Chapter I (lvl 40, ~780 xp, sim lvl 36)
    { "complete", 195, at = { 1434, 38.49, 20.44 } }, -- Raptor Mastery (lvl 36, ~1400 xp, sim lvl 36)
    { "complete", 577, at = { 1434, 39.33, 29.86 } }, -- Some Assembly Required (lvl 36, ~1400 xp, sim lvl 36)
    { "complete", 341, obj = 2, at = { 1434, 37.37, 31.22 } }, -- Chapter III (lvl 40, ~780 xp, sim lvl 36)
    { "complete", 569, at = { 1434, 37.32, 31 } }, -- The Defense of Grom'gol (lvl 37, ~2850 xp, sim lvl 36)
    { "complete", 342, at = { 1434, 34.75, 22.74 } }, -- Chapter IV (lvl 40, ~780 xp, sim lvl 36)
    { "complete", 341, at = { 1434, 34.75, 22.74 } }, -- Chapter III (lvl 40, ~780 xp, sim lvl 36)
    { "complete", 339, at = { 1434, 34.75, 22.74 } }, -- Chapter I (lvl 40, ~780 xp, sim lvl 36)
    { "complete", 188, at = { 1434, 31.84, 16.45 } }, -- Tiger Mastery (lvl 37, ~2850 xp, sim lvl 36)
    { "turnin", 193, xp = 3150 }, -- Panther Mastery (lvl 40, ~3150 xp, sim lvl 36)
    { "turnin", 339, xp = 780 }, -- Chapter I (lvl 40, ~780 xp, sim lvl 36)
    { "turnin", 341, xp = 780 }, -- Chapter III (lvl 40, ~780 xp, sim lvl 36)
    { "turnin", 342, xp = 780 }, -- Chapter IV (lvl 40, ~780 xp, sim lvl 36)
    { "turnin", 188, xp = 2850 }, -- Tiger Mastery (lvl 37, ~2850 xp, sim lvl 36)
    { "turnin", 195, xp = 1400 }, -- Raptor Mastery (lvl 36, ~1400 xp, sim lvl 36)
    { "turnin", 629, xp = 2850 }, -- The Vile Reef (lvl 37, ~2850 xp, sim lvl 36)
    { "turnin", 582, xp = 2100 }, -- Headhunting (lvl 37, ~2100 xp, sim lvl 36)
    { "turnin", 569, xp = 2850 }, -- The Defense of Grom'gol (lvl 37, ~2850 xp, sim lvl 36)
    { "goto", 1434, 32.54, 29.35, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 18, note = "Booty Bay, Stranglethorn" }, -- vol
    { "turnin", 577, xp = 1400 }, -- Some Assembly Required (lvl 36, ~1400 xp, sim lvl 36)
    { "accept", 628 }, -- Excelsior (lvl 38, ~2850 xp, sim lvl 37)
    { "goto", 1434, 26.87, 77.1, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 20, note = "Grom'gol, Stranglethorn" }, -- vol
    { "complete", 628, at = { 1434, 33.43, 32.53 } }, -- Excelsior (lvl 38, ~2850 xp, sim lvl 37)
    { "goto", 1434, 32.54, 29.35, note = "Flight master" }, -- déplacement
    { "fly", 1434, node = 18, note = "Booty Bay, Stranglethorn" }, -- vol
    { "turnin", 628, xp = 2850 }, -- Excelsior (lvl 38, ~2850 xp, sim lvl 37)
  },
})
