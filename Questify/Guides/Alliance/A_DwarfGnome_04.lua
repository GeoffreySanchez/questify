local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-04.
-- Simulation : 45 étapes, niveau final 17.05, ~18038 xp/h, 78 min.
Q:RegisterGuide({
  id = "A_DwarfGnome_04",
  title = "Westfall",
  faction = "Alliance",
  races = { "Dwarf", "Gnome" },
  minLevel = 14, maxLevel = 16,
  next = "A_01",
  sim = { steps = 45, endLevel = 17.05, xpPerHour = 18038, minutes = 78 },
  steps = {
    { "accept", 64 }, -- The Forgotten Heirloom (lvl 12, ~910 xp, sim lvl 15)
    { "accept", 151 }, -- Poor Old Blanchy (lvl 14, ~1250 xp, sim lvl 15)
    { "fp", 1436, 56.55, 52.64 }, -- point de vol
    { "accept", 12 }, -- The People's Militia (lvl 12, ~910 xp, sim lvl 15)
    { "accept", 92744 }, -- Murloc Gills (lvl 12, ~910 xp, sim lvl 15)
    { "sethearth", 1436, 52.86, 53.71 }, -- lier la pierre de foyer
    { "accept", 92742 }, -- Testing the Wells (lvl 12, ~910 xp, sim lvl 15)
    { "complete", 92742, obj = 2, at = { 1436, 46.08, 38.14 } }, -- Testing the Wells (lvl 12, ~910 xp, sim lvl 15)
    { "complete", 92744, at = { 1436, 34.53, 17 } }, -- Murloc Gills (lvl 12, ~910 xp, sim lvl 15)
    { "accept", 136, at = { 1436, 34.53, 17 }, note = "Loot Captain Sander's Treasure Map to start the quest" }, -- Captain Sander's Hidden Treasure (lvl 16, ~580 xp, sim lvl 15)
    { "complete", 64, at = { 1436, 49.33, 19.28 } }, -- The Forgotten Heirloom (lvl 12, ~910 xp, sim lvl 15)
    { "complete", 92742, at = { 1436, 56.62, 18.69 } }, -- Testing the Wells (lvl 12, ~910 xp, sim lvl 15)
    { "complete", 151, at = { 1436, 57.27, 18.31 } }, -- Poor Old Blanchy (lvl 14, ~1250 xp, sim lvl 15)
    { "turnin", 92744, xp = 910 }, -- Murloc Gills (lvl 12, ~910 xp, sim lvl 15)
    { "turnin", 92742, xp = 910 }, -- Testing the Wells (lvl 12, ~910 xp, sim lvl 15)
    { "accept", 92745 }, -- The State of the Mines (lvl 14, ~980 xp, sim lvl 15)
    { "turnin", 136, xp = 580 }, -- Captain Sander's Hidden Treasure (lvl 16, ~580 xp, sim lvl 15)
    { "accept", 138 }, -- Captain Sander's Hidden Treasure (lvl 16, ~580 xp, sim lvl 15)
    { "complete", 92745, obj = 2, at = { 1436, 29.98, 47.26 } }, -- The State of the Mines (lvl 14, ~980 xp, sim lvl 15)
    { "turnin", 138, xp = 580 }, -- Captain Sander's Hidden Treasure (lvl 16, ~580 xp, sim lvl 15)
    { "accept", 139 }, -- Captain Sander's Hidden Treasure (lvl 16, ~580 xp, sim lvl 15)
    { "complete", 12, obj = 2, at = { 1436, 44.8, 25.95 } }, -- The People's Militia (lvl 12, ~910 xp, sim lvl 15)
    { "complete", 92745, at = { 1436, 45.29, 20.05 } }, -- The State of the Mines (lvl 14, ~980 xp, sim lvl 15)
    { "turnin", 139, xp = 580 }, -- Captain Sander's Hidden Treasure (lvl 16, ~580 xp, sim lvl 15)
    { "accept", 140 }, -- Captain Sander's Hidden Treasure (lvl 16, ~1150 xp, sim lvl 16)
    { "turnin", 140, xp = 1150 }, -- Captain Sander's Hidden Treasure (lvl 16, ~1150 xp, sim lvl 16)
    { "complete", 12, at = { 1436, 31.61, 33.78 } }, -- The People's Militia (lvl 12, ~910 xp, sim lvl 16)
    { "turnin", 12, xp = 910 }, -- The People's Militia (lvl 12, ~910 xp, sim lvl 16)
    { "accept", 13 }, -- The People's Militia (lvl 14, ~980 xp, sim lvl 16)
    { "turnin", 92745, xp = 980 }, -- The State of the Mines (lvl 14, ~980 xp, sim lvl 16)
    { "accept", 92747 }, -- Moonbrook Espionage (lvl 15, ~1050 xp, sim lvl 16)
    { "complete", 92747, at = { 1436, 43.11, 68.85 } }, -- Moonbrook Espionage (lvl 15, ~1050 xp, sim lvl 16)
    { "complete", 13, at = { 1436, 43.7, 68.91 } }, -- The People's Militia (lvl 14, ~980 xp, sim lvl 16)
    { "turnin", 92747, xp = 1050 }, -- Moonbrook Espionage (lvl 15, ~1050 xp, sim lvl 16)
    { "accept", 92748 }, -- Explosive Consultation (lvl 16, ~580 xp, sim lvl 16)
    { "turnin", 13, xp = 980 }, -- The People's Militia (lvl 14, ~980 xp, sim lvl 16)
    { "accept", 14 }, -- The People's Militia (lvl 17, ~1600 xp, sim lvl 16)
    { "complete", 14, at = { 1436, 52.07, 76.61 } }, -- The People's Militia (lvl 17, ~1600 xp, sim lvl 16)
    { "turnin", 14, xp = 1600 }, -- The People's Militia (lvl 17, ~1600 xp, sim lvl 16)
    { "turnin", 151, xp = 1250 }, -- Poor Old Blanchy (lvl 14, ~1250 xp, sim lvl 16)
    { "turnin", 64, xp = 910 }, -- The Forgotten Heirloom (lvl 12, ~910 xp, sim lvl 16)
    { "accept", 168, optional = true, dungeon = "The Deadmines" }, -- Collecting Memories (lvl 18, ~0 xp, sim lvl 17)
    { "accept", 167, optional = true, dungeon = "The Deadmines" }, -- Oh Brother. . . (lvl 20, ~0 xp, sim lvl 17)
    { "accept", 2040, optional = true, dungeon = "The Deadmines" }, -- Underground Assault (lvl 20, ~0 xp, sim lvl 17)
    { "turnin", 92748, xp = 580 }, -- Explosive Consultation (lvl 16, ~580 xp, sim lvl 17)
  },
})
