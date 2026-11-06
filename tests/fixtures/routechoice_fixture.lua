-- Fixture du choix de suite (tests/test_routechoice.lua) : Loch Modan -> Marche de l'Ouest (défaut) ou
-- Sombrivage, chiffres de la simulation réelle. Chargée comme fichier pour survivre à Mock.reload().
local _, Q = ...

Q:RegisterGuide({ id = "T_FROM", title = "Loch Modan", faction = "Alliance", races = { "Dwarf", "Gnome" },
  minLevel = 11, maxLevel = 14, next = "T_WEST",
  choices = {
    { id = "T_WEST", travel = { kind = "walk", minutes = 3 } },
    { id = "T_DARK", travel = { kind = "boat", minutes = 6 } },
  },
  sim = { steps = 2, endLevel = 15.55, xpPerHour = 21188, minutes = 119 },
  steps = { { "note", "first" }, { "note", "last" } } })
Q:RegisterGuide({ id = "T_WEST", title = "Westfall", faction = "Alliance", races = { "Dwarf", "Gnome" },
  minLevel = 14, maxLevel = 16, sim = { steps = 45, endLevel = 17.05, xpPerHour = 18038, minutes = 78 },
  steps = { { "accept", 179 }, { "turnin", 179, xp = 500 } } })
Q:RegisterGuide({ id = "T_DARK", title = "Darkshore", faction = "Alliance",
  minLevel = 16, maxLevel = 19, sim = { steps = 119, endLevel = 19.9, xpPerHour = 26898, minutes = 158 },
  steps = { { "accept", 233 }, { "turnin", 233, xp = 900 }, { "turnin", 170, xp = 100 } } })
