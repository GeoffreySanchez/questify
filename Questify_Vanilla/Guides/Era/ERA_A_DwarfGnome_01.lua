local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger les plans de tools/routebuilder/build_era.lua, puis le relancer (route Classic Era).
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9 (vue Classic Era), généré le 2026-11-03.
-- Simulation : 35 étapes, niveau final 6.01, ~12025 xp/h, 38 min.
Q:RegisterGuide({
  id = "ERA_A_DwarfGnome_01",
  title = "Coldridge Valley",
  faction = "Alliance",
  races = { "Dwarf", "Gnome" },
  minLevel = 1, maxLevel = 6,
  next = "ERA_A_DwarfGnome_02",
  steps = {
    { "accept", 179 }, -- Dwarven Outfitters (lvl 1, ~80 xp, sim lvl 1)
    { "complete", 179, at = { 1426, 28.87, 74.48 } }, -- Dwarven Outfitters (lvl 1, ~80 xp, sim lvl 1)
    { "accept", 183 }, -- The Boar Hunter (lvl 3, ~250 xp, sim lvl 2)
    { "complete", 183, at = { 1426, 21.48, 71.05 } }, -- The Boar Hunter (lvl 3, ~250 xp, sim lvl 2)
    { "turnin", 183, xp = 250 }, -- The Boar Hunter (lvl 3, ~250 xp, sim lvl 3)
    { "accept", 182 }, -- The Troll Cave (lvl 4, ~355 xp, sim lvl 3)
    { "complete", 182, at = { 1426, 28.79, 80.25 } }, -- The Troll Cave (lvl 4, ~355 xp, sim lvl 3)
    { "turnin", 182, xp = 355 }, -- The Troll Cave (lvl 4, ~355 xp, sim lvl 3)
    { "accept", 218 }, -- The Stolen Journal (lvl 5, ~560 xp, sim lvl 4)
    { "accept", 3364, note = "Timed quest: do it right away" }, -- Scalding Mornbrew Delivery (lvl 5, ~225 xp, sim lvl 4)
    { "turnin", 3364, xp = 225 }, -- Scalding Mornbrew Delivery (lvl 5, ~225 xp, sim lvl 4)
    { "accept", 3365 }, -- Bring Back the Mug (lvl 5, ~450 xp, sim lvl 4)
    { "accept", 3361 }, -- A Refugee's Quandary (lvl 3, ~250 xp, sim lvl 4)
    { "turnin", 179, xp = 80 }, -- Dwarven Outfitters (lvl 1, ~80 xp, sim lvl 4)
    { "accept", 233 }, -- Coldridge Valley Mail Delivery (lvl 3, ~190 xp, sim lvl 4)
    { "accept", 170 }, -- A New Threat (lvl 2, ~170 xp, sim lvl 4)
    { "complete", 170, at = { 1426, 31.05, 75.75 } }, -- A New Threat (lvl 2, ~170 xp, sim lvl 4)
    { "complete", 218, at = { 1426, 30.48, 80.15 } }, -- The Stolen Journal (lvl 5, ~560 xp, sim lvl 4)
    { "complete", 3361, obj = 3, at = { 1426, 26.33, 79.28 } }, -- A Refugee's Quandary (lvl 3, ~250 xp, sim lvl 4)
    { "complete", 3361, obj = 2, at = { 1426, 22.78, 80 } }, -- A Refugee's Quandary (lvl 3, ~250 xp, sim lvl 4)
    { "complete", 3361, at = { 1426, 20.88, 76.07 } }, -- A Refugee's Quandary (lvl 3, ~250 xp, sim lvl 4)
    { "turnin", 233, xp = 190 }, -- Coldridge Valley Mail Delivery (lvl 3, ~190 xp, sim lvl 4)
    { "accept", 234 }, -- Coldridge Valley Mail Delivery (lvl 4, ~270 xp, sim lvl 4)
    { "turnin", 3365, xp = 450 }, -- Bring Back the Mug (lvl 5, ~450 xp, sim lvl 4)
    { "turnin", 218, xp = 560 }, -- The Stolen Journal (lvl 5, ~560 xp, sim lvl 4)
    { "turnin", 234, xp = 270 }, -- Coldridge Valley Mail Delivery (lvl 4, ~270 xp, sim lvl 4)
    { "accept", 282 }, -- Senir's Observations (lvl 5, ~335 xp, sim lvl 5)
    { "turnin", 3361, xp = 250 }, -- A Refugee's Quandary (lvl 3, ~250 xp, sim lvl 5)
    { "turnin", 170, xp = 170 }, -- A New Threat (lvl 2, ~170 xp, sim lvl 5)
    { "turnin", 282, xp = 335 }, -- Senir's Observations (lvl 5, ~335 xp, sim lvl 5)
    { "accept", 420 }, -- Senir's Observations (lvl 5, ~335 xp, sim lvl 5)
    { "accept", 2160 }, -- Supplies to Tannok (lvl 5, ~110 xp, sim lvl 5)
    { "turnin", 420, xp = 335 }, -- Senir's Observations (lvl 5, ~335 xp, sim lvl 5)
    { "turnin", 2160, xp = 110 }, -- Supplies to Tannok (lvl 5, ~110 xp, sim lvl 5)
    { "level", 6, at = { 1426, 41.94, 47.66 }, note = "About 20 more mobs here (Wendigo, level 6)" }, -- farm de niveau
  },
})
