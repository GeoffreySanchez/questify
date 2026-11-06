local addonName, Q = ...
-- Guide fictif (tests de tools/apr). Source : QuestieDB commit abc123, généré le 2026-01-01.
Q:RegisterGuide({
  id = "T_01",
  title = "Test Valley",
  faction = "Alliance",
  races = { "Human", "Dwarf" },
  minLevel = 1, maxLevel = 6,
  next = "T_02",
  steps = {
    { "accept", 102 },
    { "accept", 101 },
    { "sethearth", 9901, 50, 50 },
    { "complete", 101, at = { 9901, 50, 50 } },
    { "complete", 102 },
    { "turnin", 101 },
    { "turnin", 102 },
    { "accept", 106 },
    { "turnin", 106 },
    { "accept", 107 },
    { "turnin", 107 },
    { "accept", 108, classes = { "WARRIOR" } },
    { "turnin", 108, classes = { "WARRIOR" } },
    { "hearth", 9901 },
  },
})
