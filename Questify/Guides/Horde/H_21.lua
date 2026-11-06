local addonName, Q = ...
-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :
-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.
-- Source : QuestieDB commit 80866960788084ae1592abf66a08f0d306458a95, généré le 2026-11-06.
-- Simulation : 64 étapes, niveau final 51.00, ~56167 xp/h, 427 min.
Q:RegisterGuide({
  id = "H_21",
  title = "The Hinterlands",
  faction = "Horde",
  minLevel = 48, maxLevel = 51,
  next = "H_23",
  sim = { steps = 64, endLevel = 51.00, xpPerHour = 56167, minutes = 427 },
  steps = {
    { "goto", 1434, 32.54, 29.35, note = "Flight master" }, -- déplacement
    { "fly", 1417, node = 17, note = "Hammerfall, Arathi" }, -- vol
    { "fp", 1425, 81.7, 81.76 }, -- point de vol
    { "accept", 7815 }, -- Snapjaws, Mon! (lvl 50, ~4700 xp, sim lvl 48)
    { "accept", 7816 }, -- Gammerita, Mon! (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 7845 }, -- Kidnapped Elder Torntusk! (lvl 51, ~4900 xp, sim lvl 48)
    { "accept", 7850 }, -- Dark Vessels (lvl 50, ~5900 xp, sim lvl 48)
    { "accept", 7840 }, -- Lard Lost His Lunch (lvl 49, ~4550 xp, sim lvl 48)
    { "accept", 7839 }, -- Vilebranch Hooligans (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 7828 }, -- Stalking the Stalkers (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 7830 }, -- Avenging the Fallen (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 7829 }, -- Hunt the Savages (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 7849 }, -- Separation Anxiety (lvl 50, ~5900 xp, sim lvl 48)
    { "accept", 7841 }, -- Message to the Wildhammer (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 7861 }, -- Wanted: Vile Priestess Hexx and Her Minions (lvl 51, ~6100 xp, sim lvl 48)
    { "accept", 7862 }, -- Job Opening: Guard Captain of Revantusk Village (lvl 51, ~6100 xp, sim lvl 48)
    { "accept", 7844 }, -- Cannibalistic Cousins (lvl 48, ~4400 xp, sim lvl 48)
    { "complete", 7815, at = { 1425, 76.94, 68.12 } }, -- Snapjaws, Mon! (lvl 50, ~4700 xp, sim lvl 48)
    { "complete", 7828, obj = 1, at = { 1425, 71.91, 57.56 } }, -- Stalking the Stalkers (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 485, at = { 1425, 62.79, 49 }, race = { "Orc", "Troll", "Tauren", "Skyborne" }, note = "Loot OOX-09/HL Distress Beacon to start the quest" }, -- Find OOX-09/HL! (lvl 48, ~4400 xp, sim lvl 48)
    { "complete", 7830, at = { 1425, 62.72, 48.93 } }, -- Avenging the Fallen (lvl 48, ~4400 xp, sim lvl 48)
    { "complete", 7839, at = { 1425, 57.45, 42.6 } }, -- Vilebranch Hooligans (lvl 48, ~4400 xp, sim lvl 48)
    { "turnin", 485, xp = 4400, race = { "Orc", "Troll", "Tauren", "Skyborne" } }, -- Find OOX-09/HL! (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 2742, race = { "Orc", "Troll", "Tauren", "Skyborne" } }, -- Rin'ji is Trapped! (lvl 47, ~4200 xp, sim lvl 48)
    { "complete", 7841, at = { 1425, 31.92, 48.97 } }, -- Message to the Wildhammer (lvl 48, ~4400 xp, sim lvl 48)
    { "complete", 2742, at = { 1425, 34.58, 56.33 }, race = { "Orc", "Troll", "Tauren", "Skyborne" } }, -- Rin'ji is Trapped! (lvl 47, ~4200 xp, sim lvl 48)
    { "complete", 7844, obj = 2, at = { 1425, 48.07, 66.02 } }, -- Cannibalistic Cousins (lvl 48, ~4400 xp, sim lvl 48)
    { "turnin", 7845, xp = 4900 }, -- Kidnapped Elder Torntusk! (lvl 51, ~4900 xp, sim lvl 48)
    { "accept", 7846 }, -- Recover the Key! (lvl 51, ~6100 xp, sim lvl 48)
    { "complete", 7846, at = { 1425, 57.32, 86.64 } }, -- Recover the Key! (lvl 51, ~6100 xp, sim lvl 48)
    { "complete", 7861, at = { 1425, 59.47, 78.26 } }, -- Wanted: Vile Priestess Hexx and Her Minions (lvl 51, ~6100 xp, sim lvl 48)
    { "turnin", 7846, xp = 6100 }, -- Recover the Key! (lvl 51, ~6100 xp, sim lvl 48)
    { "accept", 7847 }, -- Return to Primal Torntusk (lvl 51, ~4900 xp, sim lvl 48)
    { "complete", 7849, obj = 2, at = { 1425, 62.11, 75.35 } }, -- Separation Anxiety (lvl 50, ~5900 xp, sim lvl 48)
    { "complete", 7862, obj = 4, at = { 1425, 60.44, 72.82 } }, -- Job Opening: Guard Captain of Revantusk Village (lvl 51, ~6100 xp, sim lvl 48)
    { "complete", 7862, obj = 3, at = { 1425, 66.62, 80 } }, -- Job Opening: Guard Captain of Revantusk Village (lvl 51, ~6100 xp, sim lvl 48)
    { "turnin", 7839, xp = 4400 }, -- Vilebranch Hooligans (lvl 48, ~4400 xp, sim lvl 48)
    { "turnin", 7847, xp = 4900 }, -- Return to Primal Torntusk (lvl 51, ~4900 xp, sim lvl 48)
    { "turnin", 7861, xp = 6100 }, -- Wanted: Vile Priestess Hexx and Her Minions (lvl 51, ~6100 xp, sim lvl 48)
    { "turnin", 7830, xp = 4400 }, -- Avenging the Fallen (lvl 48, ~4400 xp, sim lvl 48)
    { "turnin", 7841, xp = 4400 }, -- Message to the Wildhammer (lvl 48, ~4400 xp, sim lvl 48)
    { "accept", 7842 }, -- Another Message to the Wildhammer (lvl 48, ~5450 xp, sim lvl 48)
    { "complete", 7850, at = { 1425, 65.8, 70.53 } }, -- Dark Vessels (lvl 50, ~5900 xp, sim lvl 48)
    { "complete", 7862, at = { 1425, 64.69, 70.36 } }, -- Job Opening: Guard Captain of Revantusk Village (lvl 51, ~6100 xp, sim lvl 48)
    { "level", 49, at = { 1425, 57.67, 43.65 }, note = "About 49 mobs here (Jade Ooze, level 47)" }, -- farm de niveau
    { "complete", 7849, at = { 1425, 58.56, 64.76 } }, -- Separation Anxiety (lvl 50, ~5900 xp, sim lvl 49)
    { "complete", 7828, at = { 1425, 50.71, 58.79 } }, -- Stalking the Stalkers (lvl 48, ~4400 xp, sim lvl 49)
    { "complete", 7829, at = { 1425, 53.36, 51.63 } }, -- Hunt the Savages (lvl 48, ~4400 xp, sim lvl 49)
    { "complete", 7842, at = { 1425, 62.72, 48.93 } }, -- Another Message to the Wildhammer (lvl 48, ~5450 xp, sim lvl 49)
    { "complete", 7844, at = { 1425, 71.1, 48.15 } }, -- Cannibalistic Cousins (lvl 48, ~4400 xp, sim lvl 49)
    { "complete", 7840, at = { 1425, 84.49, 41.22 } }, -- Lard Lost His Lunch (lvl 49, ~4550 xp, sim lvl 49)
    { "turnin", 2742, xp = 4200, race = { "Orc", "Troll", "Tauren", "Skyborne" } }, -- Rin'ji is Trapped! (lvl 47, ~4200 xp, sim lvl 49)
    { "complete", 7816, at = { 1425, 80.4, 58.23 } }, -- Gammerita, Mon! (lvl 48, ~4400 xp, sim lvl 49)
    { "turnin", 7844, xp = 4400 }, -- Cannibalistic Cousins (lvl 48, ~4400 xp, sim lvl 49)
    { "turnin", 7842, xp = 5450 }, -- Another Message to the Wildhammer (lvl 48, ~5450 xp, sim lvl 49)
    { "turnin", 7849, xp = 5900 }, -- Separation Anxiety (lvl 50, ~5900 xp, sim lvl 49)
    { "turnin", 7828, xp = 4400 }, -- Stalking the Stalkers (lvl 48, ~4400 xp, sim lvl 49)
    { "turnin", 7829, xp = 4400 }, -- Hunt the Savages (lvl 48, ~4400 xp, sim lvl 49)
    { "turnin", 7850, xp = 5900 }, -- Dark Vessels (lvl 50, ~5900 xp, sim lvl 49)
    { "turnin", 7862, xp = 6100 }, -- Job Opening: Guard Captain of Revantusk Village (lvl 51, ~6100 xp, sim lvl 49)
    { "turnin", 7840, xp = 4550 }, -- Lard Lost His Lunch (lvl 49, ~4550 xp, sim lvl 49)
    { "turnin", 7815, xp = 4700 }, -- Snapjaws, Mon! (lvl 50, ~4700 xp, sim lvl 49)
    { "turnin", 7816, xp = 4400 }, -- Gammerita, Mon! (lvl 48, ~4400 xp, sim lvl 49)
    { "level", 51, at = { 1425, 80.4, 58.23 }, note = "About 789 more mobs near the last objective" }, -- farm de niveau
  },
})
