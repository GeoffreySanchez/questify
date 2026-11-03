-- Fixture de guides pour les tests : deux chapitres Alliance Nain/Gnome (1-6 puis 6-11).
-- Même format que les guides générés (spec § 5.2) : IDs, coordonnées, estimations d'XP.
local _, Q = ...

Q:RegisterGuide({
  id = "A_DwarfGnome_01",
  title = "Coldridge Valley",
  faction = "Alliance",
  races = { "Dwarf", "Gnome" },
  minLevel = 1, maxLevel = 6,
  next = "A_DwarfGnome_02",
  steps = {
    { "accept", 179 },                                   -- 1  Dwarven Outfitters
    { "complete", 179 },                                 -- 2
    { "turnin", 179 },                                   -- 3
    { "accept", 233 },                                   -- 4  Coldridge Valley Mail Delivery
    { "accept", 170 },                                   -- 5  A New Threat
    { "accept", 1599, class = { "WARLOCK" } },           -- 6  Beginnings (démoniste)
    { "complete", 170, at = { 1426, 26.1, 74.3 } },      -- 7
    { "turnin", 170 },                                   -- 8
    { "accept", 3361 },                                  -- 9  A Refugee's Quandary
    { "complete", 3361, obj = 2 },                       -- 10
    { "complete", 3361 },                                -- 11
    { "turnin", 3361 },                                  -- 12
    { "goto", 1426, 22.6, 71.4, note = "Talin Keeneye's camp" }, -- 13
    { "turnin", 233 },                                   -- 14
    { "accept", 3364 },                                  -- 15 Scalding Mornbrew Delivery (niveau 4)
    { "turnin", 3364 },                                  -- 16
    { "accept", 3365 },                                  -- 17
    { "turnin", 3365 },                                  -- 18
    { "level", 6 },                                      -- 19
  },
})

Q:RegisterGuide({
  id = "A_DwarfGnome_02",
  title = "Dun Morogh",
  faction = "Alliance",
  races = { "Dwarf", "Gnome" },
  minLevel = 6, maxLevel = 11,
  steps = {
    { "goto", 1426, 46.7, 53.7 },
    { "sethearth", 1426, 47.4, 52.5 },
    { "fp", 1455, 55.5, 47.7 },
    { "fly", 1432 },
    { "accept", 6387, race = { "Dwarf", "Gnome" } },
    { "hearth", 1426 },
    { "boat", 1437, 4.6, 57.1, note = "Boat to Darkshore" },
    { "note", "Train your skills in Ironforge" },
    { "level", 11, xp = 1200 },
  },
})
