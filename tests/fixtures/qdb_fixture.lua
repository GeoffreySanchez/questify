-- Fixture QuestieDB pour les tests : un extrait réel de la vue Forever (Coldridge Valley, Dun Morogh).
-- Format : champs nommés comme dans LibQuestieDB.Meta (le mock accepte aussi les index positionnels).
-- Les spawns sont en {[areaId] = {{x, y}, ...}} 0-100, comme QuestieDB.
-- La section zones reprend la forme des chaînes ZoneDB (le mock les sérialise en « return {...} »).
-- Les autres flux ajoutent leurs données via Mock.loadAddon(toc, { qdb = {...} }) sans modifier ce fichier.

local ALLIANCE = 4294967373   -- Humain, Nain, Elfe de la nuit, Gnome, Skyborne Alliance
local DWARF_GNOME = 68
local WARLOCK = 256

return {
  quests = {
    [179] = {
      name = "Dwarven Outfitters",
      startedBy = { { 658 } }, finishedBy = { { 658 } },
      requiredLevel = 1, questLevel = 1, requiredRaces = ALLIANCE,
      objectivesText = { "Sten Stoutarm would like 8 pieces of Tough Wolf Meat." },
      objectives = { nil, nil, { { 750 } } },
      zoneOrSort = 132, specialFlags = 8,
    },
    [170] = {
      name = "A New Threat",
      startedBy = { { 713 } }, finishedBy = { { 713 } },
      requiredLevel = 1, questLevel = 2, requiredRaces = ALLIANCE,
      objectivesText = { "Balir Frosthammer wants you to kill 6 Rockjaw Troggs and 6 Burly Rockjaw Troggs." },
      objectives = { { { 707 }, { 724 } } },
      preQuestSingle = { 179 },
      zoneOrSort = 132, specialFlags = 8,
    },
    [233] = {
      name = "Coldridge Valley Mail Delivery",
      startedBy = { { 658 } }, finishedBy = { { 714 } },
      requiredLevel = 1, questLevel = 3, requiredRaces = ALLIANCE,
      objectivesText = { "Deliver the stack of letters to Talin Keeneye." },
      sourceItemId = 2187,
      preQuestSingle = { 179 },
      nextQuestInChain = 234,
      zoneOrSort = 132,
    },
    [3361] = {
      name = "A Refugee's Quandary",
      startedBy = { { 8416 } }, finishedBy = { { 8416 } },
      requiredLevel = 3, questLevel = 3, requiredRaces = ALLIANCE,
      objectivesText = { "Bring Felix's Box, Felix's Chest and Felix's Bucket of Bolts to Felix Whindlebolt in Anvilmar." },
      objectives = { nil, nil, { { 10438 }, { 16313 }, { 16314 } } },
      zoneOrSort = 132, specialFlags = 8,
    },
    -- Chaîne de classe Démoniste (fixture : 1598 puis 1599, toutes deux réservées aux démonistes)
    [1598] = {
      name = "The Stolen Tome",
      startedBy = { { 459 } }, finishedBy = { { 459 } },
      requiredLevel = 1, questLevel = 4, requiredRaces = ALLIANCE, requiredClasses = WARLOCK,
      objectivesText = { "Retrieve the Powers of the Void for Drusilla La Salle." },
      objectives = { nil, nil, { { 6785 } } },
      zoneOrSort = -61, specialFlags = 8,
    },
    [1599] = {
      name = "Beginnings",
      startedBy = { { 460 } }, finishedBy = { { 460 } },
      requiredLevel = 1, questLevel = 4, requiredRaces = ALLIANCE, requiredClasses = WARLOCK,
      objectivesText = { "Bring 3 Feather Charms to Alamar Grimm in Anvilmar." },
      objectives = { nil, nil, { { 6753 } } },
      zoneOrSort = -61, specialFlags = 8,
    },
    -- Niveau requis 4 (étape « blocked » au niveau 1), puis sa suite
    [3364] = {
      name = "Scalding Mornbrew Delivery",
      startedBy = { { 12738 } }, finishedBy = { { 836 } },
      requiredLevel = 4, questLevel = 5, requiredRaces = ALLIANCE,
      objectivesText = { "Take a Scalding Mornbrew to Durnan Furcutter inside Anvilmar before it gets cold in five minutes!" },
      sourceItemId = 10439,
      zoneOrSort = 132,
    },
    [3365] = {
      name = "Bring Back the Mug",
      startedBy = { { 836 } }, finishedBy = { { 12738 } },
      requiredLevel = 4, questLevel = 5, requiredRaces = ALLIANCE,
      objectivesText = { "Return Nori's Mug to Nori Pridedrift." },
      sourceItemId = 10440,
      preQuestSingle = { 3364 },
      zoneOrSort = 132,
    },
    -- Réservée aux Nains et Gnomes (Loch Modan)
    [6387] = {
      name = "Honor Students",
      startedBy = { { 1681 } }, finishedBy = { { 1572 } },
      requiredLevel = 10, questLevel = 10, requiredRaces = DWARF_GNOME,
      objectivesText = { "Bring Brock's List to Thorgrum Borrelson in Thelsamar." },
      sourceItemId = 16310,
      nextQuestInChain = 6391,
      zoneOrSort = 38,
    },
  },

  npcs = {
    [658] = { name = "Sten Stoutarm", minLevel = 5, maxLevel = 5, spawns = { [1] = { { 29.93, 71.2 } } }, zoneID = 1,
      questStarts = { 179, 233 }, questEnds = { 179 }, factionID = 55, friendlyToFaction = "A", npcFlags = 3 },
    [713] = { name = "Balir Frosthammer", minLevel = 5, maxLevel = 5, spawns = { [1] = { { 29.71, 71.25 } } }, zoneID = 1,
      questStarts = { 170 }, questEnds = { 170 }, factionID = 55, friendlyToFaction = "A", npcFlags = 2 },
    [714] = { name = "Talin Keeneye", minLevel = 5, maxLevel = 5, spawns = { [1] = { { 22.6, 71.43 } } }, zoneID = 1,
      questStarts = { 183, 234 }, questEnds = { 183, 233 }, factionID = 55, friendlyToFaction = "A", npcFlags = 2 },
    [705] = { name = "Ragged Young Wolf", minLevel = 1, maxLevel = 1, zoneID = 1,
      spawns = { [1] = { { 32.28, 70.8 }, { 31.42, 70.05 }, { 31.3, 73.97 }, { 29.93, 73.41 }, { 30.31, 74.18 },
        { 30.91, 73.17 }, { 28.73, 72.36 }, { 27.6, 72.36 }, { 26.48, 70.81 }, { 22.57, 78.23 } } } },
    [707] = { name = "Rockjaw Trogg", minLevel = 1, maxLevel = 2, zoneID = 1,
      spawns = { [1] = { { 32.35, 74.47 }, { 31.13, 74.74 }, { 24.31, 71.0 }, { 23.83, 73.48 }, { 21.82, 72.42 } } } },
    [724] = { name = "Burly Rockjaw Trogg", minLevel = 2, maxLevel = 2, zoneID = 1,
      spawns = { [1] = { { 31.63, 73.69 }, { 27.22, 72.14 }, { 26.87, 73.14 }, { 26.3, 73.16 }, { 25.65, 72.46 } } } },
    [8416] = { name = "Felix Whindlebolt", minLevel = 2, maxLevel = 2, spawns = { [1] = { { 28.55, 67.64 } } }, zoneID = 1,
      questStarts = { 3361 }, questEnds = { 3361 }, factionID = 875, friendlyToFaction = "A", npcFlags = 3 },
    [460] = { name = "Alamar Grimm", minLevel = 5, maxLevel = 5, spawns = { [1] = { { 28.65, 66.14 } } }, zoneID = 1,
      questStarts = { 1599 }, questEnds = { 1599 }, factionID = 875, friendlyToFaction = "A",
      subName = "Warlock Trainer", npcFlags = 19 },
    [459] = { name = "Drusilla La Salle", minLevel = 5, maxLevel = 5, spawns = { [12] = { { 49.87, 42.65 } } }, zoneID = 12,
      questStarts = { 1598 }, questEnds = { 1598 }, factionID = 12, friendlyToFaction = "A",
      subName = "Warlock Trainer", npcFlags = 19 },
    [946] = { name = "Frostmane Novice", minLevel = 3, maxLevel = 4, zoneID = 1,
      spawns = { [1] = { { 28.99, 82.57 }, { 28.69, 83.14 }, { 29.05, 81.17 } } } },
    [12738] = { name = "Nori Pridedrift", minLevel = 5, maxLevel = 5, spawns = { [1] = { { 24.98, 75.96 } } }, zoneID = 1,
      questStarts = { 3364 }, questEnds = { 3365 }, factionID = 55, friendlyToFaction = "A", npcFlags = 2 },
    [836] = { name = "Durnan Furcutter", minLevel = 5, maxLevel = 5, spawns = { [1] = { { 28.77, 66.37 } } }, zoneID = 1,
      questStarts = { 3365 }, questEnds = { 3364 }, factionID = 55, friendlyToFaction = "A",
      subName = "Cloth & Leather Armor Merchant", npcFlags = 16391 },
    [1681] = { name = "Brock Stoneseeker", minLevel = 15, maxLevel = 15, spawns = { [38] = { { 37.02, 47.81 } } }, zoneID = 38,
      questStarts = { 6387 }, questEnds = { 6392 }, factionID = 55, friendlyToFaction = "A",
      subName = "Mining Trainer", npcFlags = 19 },
  },

  objects = {
    [148499] = { name = "Felix's Box", spawns = { [1] = { { 20.88, 76.07 } } }, zoneID = 1 },
    [178084] = { name = "Felix's Chest", spawns = { [1] = { { 22.78, 80.0 } } }, zoneID = 1 },
    [178085] = { name = "Felix's Bucket of Bolts", spawns = { [1] = { { 26.33, 79.28 } } }, zoneID = 1 },
    [83763] = { name = "Stolen Books", spawns = { [12] = { { 56.71, 43.96 } } }, zoneID = 12 },
  },

  items = {
    [750] = { name = "Tough Wolf Meat", npcDrops = { 705 }, itemLevel = 1, class = 12 },
    [10438] = { name = "Felix's Box", objectDrops = { 148499 }, itemLevel = 1, class = 12 },
    [16313] = { name = "Felix's Chest", objectDrops = { 178084 }, itemLevel = 1, class = 12 },
    [16314] = { name = "Felix's Bucket of Bolts", objectDrops = { 178085 }, itemLevel = 1, class = 12 },
    [6753] = { name = "Feather Charm", npcDrops = { 946 }, itemLevel = 1, class = 12 },
    [6785] = { name = "Powers of the Void", objectDrops = { 83763 }, itemLevel = 1, class = 12 },
  },

  zones = {
    areaIdToUiMapIdOverride = { [0] = 0, [2257] = 0 },
    areaIdToUiMapId = {
      [1] = 1426,      -- Dun Morogh
      [12] = 1429,     -- Elwynn Forest
      [38] = 1432,     -- Loch Modan
      [11] = 1437,     -- Wetlands
      [40] = 1436,     -- Westfall
      [1519] = 1453,   -- Stormwind City
      [1537] = 1455,   -- Ironforge
      [14] = 1411,     -- Durotar
      [141] = 1438,    -- Teldrassil
    },
    subZoneToParentZoneOverride = { [6176] = 1, [133] = 1 },   -- Coldridge Valley, New Tinkertown -> Dun Morogh
    subZoneToParentZone = { [9] = 12, [131] = 1, [800] = 131 }, -- Northshire Valley, Kharanos, sous-zone imbriquée
  },
}
