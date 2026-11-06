-- Fixture des étapes de classe (champ classes, tests/test_classsteps.lua) : deux chapitres Nain/Gnome.
-- Le premier mêle des étapes communes, des étapes du Démoniste (chaîne 1599 puis 1598) et une note du
-- Mage ; le second rend la suite de la chaîne du Démoniste. Chargée comme fichier pour survivre à
-- Mock.reload().
local _, Q = ...

Q:RegisterGuide({
  id = "C_Class_01",
  title = "Coldridge Valley",
  faction = "Alliance",
  races = { "Dwarf", "Gnome" },
  minLevel = 1, maxLevel = 6,
  next = "C_Class_02",
  steps = {
    { "accept", 179 },                                          -- 1  Dwarven Outfitters
    { "accept", 1599, classes = { "WARLOCK" } },                -- 2  Beginnings (démoniste)
    { "note", "Mage only", classes = { "MAGE" } },              -- 3
    { "complete", 1599, classes = { "WARLOCK" } },              -- 4
    { "turnin", 1599, xp = 300, classes = { "WARLOCK" } },      -- 5
    { "turnin", 179, xp = 100 },                                -- 6
    { "accept", 170 },                                          -- 7  A New Threat
  },
})

Q:RegisterGuide({
  id = "C_Class_02",
  title = "Dun Morogh",
  faction = "Alliance",
  races = { "Dwarf", "Gnome" },
  minLevel = 6, maxLevel = 11,
  steps = {
    { "accept", 1598, classes = { "WARLOCK", "MAGE" } },        -- 1  The Stolen Tome
    { "turnin", 1598, classes = { "WARLOCK" } },                -- 2
    { "note", "End of the chapter" },                           -- 3
  },
})
