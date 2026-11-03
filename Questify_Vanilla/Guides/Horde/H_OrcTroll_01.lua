local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-03.
-- Simulation : 40 étapes, niveau final 6.08, ~12415 xp/h, 38 min.
Q:RegisterGuide({
  id = "H_OrcTroll_01",
  title = "Valley of Trials",
  faction = "Horde",
  races = { "Orc", "Troll" },
  minLevel = 1, maxLevel = 6,
  next = "H_OrcTroll_02",
  steps = {
    { "accept", 4641 }, -- Your Place In The World (lvl 1, ~40 xp, sim lvl 1)
    { "turnin", 4641, xp = 40 }, -- Your Place In The World (lvl 1, ~40 xp, sim lvl 1)
    { "accept", 788 }, -- Cutting Teeth (lvl 2, ~170 xp, sim lvl 1)
    { "accept", 97279 }, -- Wayward Weapons (lvl 2, ~170 xp, sim lvl 1)
    { "complete", 788, at = { 1411, 43.36, 62.48 } }, -- Cutting Teeth (lvl 2, ~170 xp, sim lvl 1)
    { "turnin", 788, xp = 170 }, -- Cutting Teeth (lvl 2, ~170 xp, sim lvl 2)
    { "accept", 789 }, -- Sting of the Scorpid (lvl 3, ~250 xp, sim lvl 2)
    { "accept", 790 }, -- Sarkoth (lvl 5, ~450 xp, sim lvl 2)
    { "complete", 789, at = { 1411, 40.57, 62.44 } }, -- Sting of the Scorpid (lvl 3, ~250 xp, sim lvl 2)
    { "accept", 4402 }, -- Galgar's Cactus Apple Surprise (lvl 3, ~380 xp, sim lvl 3)
    { "accept", 792, class = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARRIOR" } }, -- Vile Familiars (lvl 4, ~445 xp, sim lvl 3)
    { "accept", 5441 }, -- Lazy Peons (lvl 4, ~445 xp, sim lvl 3)
    { "complete", 4402, at = { 1411, 45.35, 62.45 } }, -- Galgar's Cactus Apple Surprise (lvl 3, ~380 xp, sim lvl 3)
    { "complete", 792, at = { 1411, 44.74, 55.67 }, class = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARRIOR" } }, -- Vile Familiars (lvl 4, ~445 xp, sim lvl 3)
    { "complete", 5441, at = { 1411, 41.68, 58.86 } }, -- Lazy Peons (lvl 4, ~445 xp, sim lvl 3)
    { "complete", 97279, at = { 1411, 44.26, 64.18 } }, -- Wayward Weapons (lvl 2, ~170 xp, sim lvl 3)
    { "turnin", 5441, xp = 445 }, -- Lazy Peons (lvl 4, ~445 xp, sim lvl 3)
    { "accept", 6394 }, -- Thazz'ril's Pick (lvl 4, ~445 xp, sim lvl 4)
    { "turnin", 792, xp = 445, class = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARRIOR" } }, -- Vile Familiars (lvl 4, ~445 xp, sim lvl 4)
    { "accept", 794 }, -- Burning Blade Medallion (lvl 5, ~670 xp, sim lvl 4)
    { "turnin", 97279, xp = 170 }, -- Wayward Weapons (lvl 2, ~170 xp, sim lvl 4)
    { "complete", 790, at = { 1411, 40.5, 66.83 } }, -- Sarkoth (lvl 5, ~450 xp, sim lvl 4)
    { "turnin", 790, xp = 450 }, -- Sarkoth (lvl 5, ~450 xp, sim lvl 4)
    { "accept", 804 }, -- Sarkoth (lvl 5, ~110 xp, sim lvl 4)
    { "complete", 794, at = { 1411, 42.71, 52.95 } }, -- Burning Blade Medallion (lvl 5, ~670 xp, sim lvl 4)
    { "complete", 6394, at = { 1411, 43.73, 53.79 } }, -- Thazz'ril's Pick (lvl 4, ~445 xp, sim lvl 4)
    { "turnin", 4402, xp = 380 }, -- Galgar's Cactus Apple Surprise (lvl 3, ~380 xp, sim lvl 4)
    { "turnin", 804, xp = 110 }, -- Sarkoth (lvl 5, ~110 xp, sim lvl 4)
    { "turnin", 789, xp = 250 }, -- Sting of the Scorpid (lvl 3, ~250 xp, sim lvl 4)
    { "turnin", 794, xp = 670 }, -- Burning Blade Medallion (lvl 5, ~670 xp, sim lvl 4)
    { "accept", 805 }, -- Report to Sen'jin Village (lvl 5, ~225 xp, sim lvl 5)
    { "accept", 96652 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 5)
    { "turnin", 6394, xp = 445 }, -- Thazz'ril's Pick (lvl 4, ~445 xp, sim lvl 5)
    { "accept", 99123 }, -- Lost in the Shadows (lvl 8, ~700 xp, sim lvl 5)
    { "complete", 99123, at = { 1411, 51.41, 79.29 } }, -- Lost in the Shadows (lvl 8, ~700 xp, sim lvl 5)
    { "accept", 96876, at = { 1411, 51.03, 55.6 }, note = "Loot Ukor's Lost Pack to start the quest" }, -- Ukor's Lost Pack (lvl 8, ~530 xp, sim lvl 5)
    { "turnin", 96652, xp = 135 }, -- The Adventurer (lvl 6, ~135 xp, sim lvl 5)
    { "turnin", 96876, xp = 530 }, -- Ukor's Lost Pack (lvl 8, ~530 xp, sim lvl 5)
    { "turnin", 99123, xp = 700 }, -- Lost in the Shadows (lvl 8, ~700 xp, sim lvl 5)
    { "turnin", 805, xp = 225 }, -- Report to Sen'jin Village (lvl 5, ~225 xp, sim lvl 6)
  },
})
