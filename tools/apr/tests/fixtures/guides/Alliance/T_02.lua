local addonName, Q = ...
-- Guide fictif (tests de tools/apr).
Q:RegisterGuide({
  id = "T_02",
  title = "Test Hills",
  faction = "Alliance",
  minLevel = 6, maxLevel = 10,
  steps = {
    { "goto", 9902, 40, 40 },
    { "accept", 201 },
    { "accept", 202 },
    { "accept", 203 },
    { "complete", 201 },
    { "complete", 202 },
    { "turnin", 201 },
    { "turnin", 202 },
    { "turnin", 203 },
    { "accept", 110 },
    { "turnin", 110 },
  },
})
