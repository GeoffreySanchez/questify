local addonName, Q = ...
-- Généré par tools/routebuilder/build_dungeons.lua. Ne pas modifier à la main.
-- Source : QuestieDB commit c5de61ab7c629132a772cccddf7f604ac48cecf9, généré le 2026-11-04.
-- Donjons de WoW: Forever : zone, niveaux conseillés, factions autorisées, entrée (uiMapID, x, y en 0-100,
-- entranceSource = questiedb ou manual), quêtes par faction : IDs, PNJ (giver) ou objet (obj) de départ et
-- position (at), PNJ de fin (ender, endAt), niveaux, masques de races et de classes, préquêtes (pre = au
-- moins une, preAll = toutes). bc = préquête de passage ; talk = quête sans objectif ; inside = quête
-- prise dans le donjon (objet ramassé, item, ou PNJ de l'instance) : seulement « faire » et « rendre ».
-- Seulement des faits (IDs, niveaux, coordonnées) ; les noms en commentaire viennent de QuestieDB.
Q.DungeonData = {
  { key = "RFC", name = "Ragefire Chasm", areaId = 2437, minLevel = 13, maxLevel = 18,
    factions = { "Horde" }, entrance = { 1454, 52.6, 49 }, entranceSource = "questiedb",
    quests = {
      Horde = {
        { id = 5722, talk = true, giver = 11833, at = { 1456, 70.14, 29.52 }, level = 16, reqLevel = 9, races = 8589934770 }, -- Searching for the Lost Satchel
        { id = 5723, giver = 11833, at = { 1456, 70.14, 29.52 }, ender = 11833, endAt = { 1456, 70.14, 29.52 }, level = 15, reqLevel = 9, races = 8589934770 }, -- Testing an Enemy's Strength
        { id = 5724, inside = true, ender = 11833, endAt = { 1456, 70.14, 29.52 }, level = 16, reqLevel = 9, races = 8589934770, pre = { 5722 } }, -- Returning the Lost Satchel
        { id = 5725, giver = 2425, at = { 1458, 56.25, 92.2 }, ender = 2425, endAt = { 1458, 56.25, 92.2 }, level = 16, reqLevel = 9, races = 8589934770 }, -- The Power to Destroy...
        { id = 5728, giver = 4949, at = { 1454, 31.73, 37.82 }, ender = 4949, endAt = { 1454, 31.73, 37.82 }, level = 16, reqLevel = 9, races = 8589934770, pre = { 5727 } }, -- Hidden Enemies
        { id = 5761, giver = 3216, at = { 1454, 49.47, 50.59 }, ender = 3216, endAt = { 1454, 49.47, 50.59 }, level = 16, reqLevel = 9, races = 8589934770 }, -- Slaying the Beast
      },
    },
  },
  { key = "THANES", name = "The Hall of Thanes", areaId = 16919, minLevel = 13, maxLevel = 18,
    factions = { "Alliance" }, entrance = { 1455, 27.63, 47.83 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 96393, giver = 264936, at = { 1426, 64.87, 58.47 }, ender = 2784, endAt = { 1455, 39.09, 56.2 }, level = 16, reqLevel = 9, races = 4294967373, pre = { 96391 } }, -- Old Ironforge Incursion
        { id = 96394, giver = 264943, at = { 1455, 33.18, 47.94 }, ender = 264943, endAt = { 1455, 33.18, 47.94 }, level = 15, reqLevel = 10, races = 4294967373 }, -- The Restless Dead
        { id = 96403, giver = 265003, at = { 1455, 32.18, 44.5 }, ender = 265003, endAt = { 1455, 32.18, 44.5 }, level = 15, reqLevel = 10, races = 4294967373 }, -- Important Heirlooms
      },
    },
  },
  { key = "LORDAERON", name = "Ruins of Lordaeron", areaId = 16611, minLevel = 15, maxLevel = 22,
    factions = { "Horde" }, entrance = { 1458, 72.48, 11.33 }, entranceSource = "questiedb",
    quests = {
      Horde = {
        { id = 92401, giver = 250686, at = { 1421, 44.52, 43.02 }, ender = 250686, endAt = { 1421, 44.52, 43.02 }, level = 22, reqLevel = 15, races = 8589934770 }, -- A Frightened Request
        { id = 92421, giver = 266484, at = { 1458, 58.08, 89.51 }, ender = 266484, endAt = { 1458, 58.08, 89.51 }, level = 22, reqLevel = 15, races = 8589934770 }, -- Light's Justice
        { id = 92422, giver = 251001, at = { 1420, 65.25, 60.2 }, ender = 251001, endAt = { 1420, 65.25, 60.2 }, level = 22, reqLevel = 15, races = 8589934770 }, -- The Wrath of Rath'mael
        { id = 95204, inside = true, item = 275521, ender = 7825, endAt = { 1458, 73.06, 32.85 }, level = 22, reqLevel = 16, races = 8589934770 }, -- Crest of Lordaeron
        { id = 95216, giver = 11835, at = { 1458, 46.31, 71.91 }, ender = 11835, endAt = { 1458, 46.31, 71.91 }, level = 22, reqLevel = 16, races = 8589934770 }, -- The New Plague
        { id = 97288, inside = true, item = 280438, ender = 2055, endAt = { 1458, 48.82, 69.28 }, level = 21, reqLevel = 16, races = 8589934770 }, -- Unending Torment
        { id = 97289, talk = true, giver = 2055, at = { 1458, 48.82, 69.28 }, ender = 271613, endAt = { 1458, 45.88, 61.7 }, level = 21, reqLevel = 16, races = 8589934770 }, -- Unending Torment
        { id = 97291, giver = 2055, at = { 1458, 48.82, 69.28 }, ender = 2055, endAt = { 1458, 48.82, 69.28 }, level = 21, reqLevel = 16, races = 8589934770 }, -- Unending Torment
        { id = 97292, talk = true, giver = 2055, at = { 1458, 48.82, 69.28 }, ender = 2055, endAt = { 1458, 48.82, 69.28 }, level = 21, reqLevel = 16, races = 8589934770 }, -- Unending Torment
      },
    },
  },
  { key = "WC", name = "Wailing Caverns", areaId = 718, minLevel = 17, maxLevel = 24,
    factions = { "Alliance", "Horde" }, entrance = { 1413, 46, 36.5 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 959, giver = 3665, at = { 1413, 63.09, 37.61 }, ender = 3665, endAt = { 1413, 63.09, 37.61 }, level = 18, reqLevel = 14 }, -- Trouble at the Docks
        { id = 1486, giver = 5767, at = { 1413, 45.99, 35.66 }, ender = 5767, endAt = { 1413, 45.99, 35.66 }, level = 17, reqLevel = 13 }, -- Deviate Hides
        { id = 1487, giver = 5768, at = { 1413, 46.01, 35.74 }, ender = 5768, endAt = { 1413, 46.01, 35.74 }, level = 21, reqLevel = 15 }, -- Deviate Eradication
        { id = 1491, giver = 3446, at = { 1413, 62.37, 37.62 }, ender = 3446, endAt = { 1413, 62.37, 37.62 }, level = 18, reqLevel = 13, pre = { 865 } }, -- Smart Drinks
        { id = 6981, inside = true, item = 10441, ender = 8418, endAt = { 1413, 48.18, 32.78 }, level = 26, reqLevel = 15 }, -- The Glowing Shard
      },
      Horde = {
        { id = 914, giver = 5770, at = { 1456, 75.65, 31.61 }, ender = 5770, endAt = { 1456, 75.65, 31.61 }, level = 22, reqLevel = 11, races = 8589934770, pre = { 1490 } }, -- Leaders of the Fang
        { id = 959, giver = 3665, at = { 1413, 63.09, 37.61 }, ender = 3665, endAt = { 1413, 63.09, 37.61 }, level = 18, reqLevel = 14 }, -- Trouble at the Docks
        { id = 962, giver = 3419, at = { 1456, 22.81, 20.89 }, ender = 3419, endAt = { 1456, 22.81, 20.89 }, level = 18, reqLevel = 14, races = 8589934770 }, -- Serpentbloom
        { id = 1486, giver = 5767, at = { 1413, 45.99, 35.66 }, ender = 5767, endAt = { 1413, 45.99, 35.66 }, level = 17, reqLevel = 13 }, -- Deviate Hides
        { id = 1487, giver = 5768, at = { 1413, 46.01, 35.74 }, ender = 5768, endAt = { 1413, 46.01, 35.74 }, level = 21, reqLevel = 15 }, -- Deviate Eradication
        { id = 1489, talk = true, giver = 3448, at = { 1413, 52.26, 31.93 }, ender = 5769, endAt = { 1456, 78.62, 28.56 }, level = 16, reqLevel = 12, races = 8589934770, pre = { 880 } }, -- Hamuul Runetotem
        { id = 1490, talk = true, giver = 5769, at = { 1456, 78.62, 28.56 }, ender = 5770, endAt = { 1456, 75.65, 31.61 }, level = 16, reqLevel = 12, races = 8589934770, pre = { 1489 } }, -- Nara Wildmane
        { id = 1491, giver = 3446, at = { 1413, 62.37, 37.62 }, ender = 3446, endAt = { 1413, 62.37, 37.62 }, level = 18, reqLevel = 13, pre = { 865 } }, -- Smart Drinks
        { id = 6981, inside = true, item = 10441, ender = 8418, endAt = { 1413, 48.18, 32.78 }, level = 26, reqLevel = 15 }, -- The Glowing Shard
      },
    },
  },
  { key = "DM", name = "The Deadmines", areaId = 1581, minLevel = 17, maxLevel = 26,
    factions = { "Alliance" }, entrance = { 1436, 42.5, 71.7 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 166, giver = 234, at = { 1436, 56.33, 47.52 }, ender = 234, endAt = { 1436, 56.33, 47.52 }, level = 22, reqLevel = 14, races = 4294967373, pre = { 155 } }, -- The Defias Brotherhood
        { id = 167, giver = 656, at = { 1453, 70.31, 40.82 }, ender = 656, endAt = { 1453, 70.31, 40.82 }, level = 20, reqLevel = 15, races = 4294967373 }, -- Oh Brother. . .
        { id = 168, giver = 656, at = { 1453, 70.31, 40.82 }, ender = 656, endAt = { 1453, 70.31, 40.82 }, level = 18, reqLevel = 14, races = 4294967373 }, -- Collecting Memories
        { id = 214, giver = 820, at = { 1436, 56.67, 47.35 }, ender = 820, endAt = { 1436, 56.67, 47.35 }, level = 17, reqLevel = 14, races = 4294967373, pre = { 155 } }, -- Red Silk Bandanas
        { id = 2040, giver = 6579, at = { 1453, 62.63, 34.11 }, ender = 6579, endAt = { 1453, 62.63, 34.11 }, level = 20, reqLevel = 15, races = 4294967373 }, -- Underground Assault
        { id = 92753, giver = 253092, at = { 1436, 52.48, 52.97 }, ender = 253279, endAt = { 1436, 38.68, 83.7 }, level = 18, reqLevel = 9, races = 4294967373, pre = { 92752 } }, -- Destruction in Deadmines
        { id = 92752, bc = true, giver = 11026, at = { 1453, 61.88, 30.56 }, ender = 253092, endAt = { 1436, 52.48, 52.97 }, level = 16, reqLevel = 9, races = 4294967373, preAll = { 92749, 92751 } }, -- Explosive Consultation
        { id = 92751, bc = true, giver = 1325, at = { 1453, 80.28, 70.07 }, ender = 11026, endAt = { 1453, 61.88, 30.56 }, level = 16, reqLevel = 9, races = 4294967373, pre = { 92750 } }, -- Detonation at a Distance
        { id = 92750, bc = true, giver = 11026, at = { 1453, 61.88, 30.56 }, ender = 1325, endAt = { 1453, 80.28, 70.07 }, level = 16, reqLevel = 9, races = 4294967373, pre = { 92748 } }, -- Detonation at a Distance
      },
    },
  },
  { key = "SFK", name = "Shadowfang Keep", areaId = 209, minLevel = 22, maxLevel = 30,
    factions = { "Horde" }, entrance = { 1421, 44.8, 67.8 }, entranceSource = "questiedb",
    quests = {
      Horde = {
        { id = 1013, giver = 2934, at = { 1458, 53.74, 54.46 }, ender = 2934, endAt = { 1458, 53.74, 54.46 }, level = 26, reqLevel = 16, races = 8589934770 }, -- The Book of Ur
        { id = 1014, giver = 1938, at = { 1421, 44.2, 39.81 }, ender = 1938, endAt = { 1421, 44.2, 39.81 }, level = 27, reqLevel = 18, races = 8589934770 }, -- Arugal Must Die
        { id = 1098, talk = true, giver = 1952, at = { 1421, 43.42, 40.86 }, level = 25, reqLevel = 18, races = 8589934770 }, -- Deathstalkers in Shadowfang
      },
    },
  },
  { key = "BFD", name = "Blackfathom Deeps", areaId = 719, minLevel = 24, maxLevel = 32,
    factions = { "Alliance", "Horde" }, entrance = { 1440, 14.5, 14.2 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 971, giver = 2786, at = { 1455, 50.83, 5.62 }, ender = 2786, endAt = { 1455, 50.83, 5.62 }, level = 23, reqLevel = 10, races = 4294967373 }, -- Knowledge in the Deeps
        { id = 1198, talk = true, giver = 4786, at = { 1457, 55.36, 25.03 }, level = 24, reqLevel = 18 }, -- In Search of Thaelrid
        { id = 1199, giver = 4784, at = { 1457, 55.24, 23.99 }, ender = 4784, endAt = { 1457, 55.24, 23.99 }, level = 25, reqLevel = 20, races = 4294967373 }, -- Twilight Falls
        { id = 1200, inside = true, ender = 4783, endAt = { 1457, 56.16, 24.39 }, level = 27, reqLevel = 18, races = 4294967373 }, -- Blackfathom Villainy
        { id = 1275, giver = 8997, at = { 1439, 38.33, 43.04 }, ender = 8997, endAt = { 1439, 38.33, 43.04 }, level = 24, reqLevel = 18, races = 4294967373 }, -- Researching the Corruption
      },
      Horde = {
        { id = 6561, inside = true, ender = 9087, endAt = { 1456, 71.06, 34.19 }, level = 27, reqLevel = 18, races = 8589934770 }, -- Blackfathom Villainy
        { id = 6562, talk = true, giver = 11862, at = { 1442, 47.36, 64.25 }, ender = 12736, endAt = { 1440, 11.56, 34.29 }, level = 22, reqLevel = 17, races = 8589934770 }, -- Trouble in the Deeps
        { id = 6563, giver = 12736, at = { 1440, 11.56, 34.29 }, ender = 12736, endAt = { 1440, 11.56, 34.29 }, level = 22, reqLevel = 17, races = 8589934770 }, -- The Essence of Aku'Mai
        { id = 6564, inside = true, item = 16790, ender = 12736, endAt = { 1440, 11.56, 34.29 }, level = 22, reqLevel = 17, races = 8589934770, pre = { 6562 } }, -- Allegiance to the Old Gods
        { id = 6565, giver = 12736, at = { 1440, 11.56, 34.29 }, ender = 12736, endAt = { 1440, 11.56, 34.29 }, level = 26, reqLevel = 17, races = 8589934770, pre = { 6564 } }, -- Allegiance to the Old Gods
        { id = 6921, giver = 12736, at = { 1440, 11.56, 34.29 }, ender = 12736, endAt = { 1440, 11.56, 34.29 }, level = 27, reqLevel = 21, races = 8589934770 }, -- Amongst the Ruins
        { id = 6922, inside = true, item = 16782, ender = 12736, endAt = { 1440, 11.56, 34.29 }, level = 30, reqLevel = 21, races = 8589934770 }, -- Baron Aquanis
      },
    },
  },
  { key = "STOCKADE", name = "The Stockade", areaId = 717, minLevel = 24, maxLevel = 32,
    factions = { "Alliance" }, entrance = { 1453, 52.41, 70.01 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 377, giver = 270, at = { 1431, 71.92, 47.79 }, ender = 270, endAt = { 1431, 71.92, 47.79 }, level = 26, reqLevel = 22, races = 4294967373 }, -- Crime and Punishment
        { id = 378, giver = 1074, at = { 1437, 49.67, 18.23 }, ender = 1074, endAt = { 1437, 49.67, 18.23 }, level = 27, reqLevel = 22, races = 4294967373, pre = { 303 } }, -- The Fury Runs Deep
        { id = 386, giver = 859, at = { 1433, 21.17, 46.58 }, ender = 859, endAt = { 1433, 21.17, 46.58 }, level = 25, reqLevel = 22, races = 4294967373 }, -- What Comes Around...
        { id = 387, giver = 1719, at = { 1453, 51.49, 69.38 }, ender = 1719, endAt = { 1453, 51.49, 69.38 }, level = 26, reqLevel = 22, races = 4294967373 }, -- Quell The Uprising
        { id = 388, giver = 1721, at = { 1453, 76.42, 63.67 }, ender = 1721, endAt = { 1453, 76.42, 63.67 }, level = 26, reqLevel = 22, races = 4294967373 }, -- The Color of Blood
        { id = 391, giver = 1719, at = { 1453, 51.49, 69.38 }, ender = 1719, endAt = { 1453, 51.49, 69.38 }, level = 29, reqLevel = 16, races = 4294967373, pre = { 389 } }, -- The Stockade Riots
        { id = 389, bc = true, giver = 1646, at = { 1453, 57.74, 47.86 }, ender = 1719, endAt = { 1453, 51.49, 69.38 }, level = 22, reqLevel = 16, races = 4294967373, pre = { 373 } }, -- Bazil Thredd
      },
    },
  },
  { key = "EXCAVATION", name = "Excavation Site: Wetlands", areaId = 16732, minLevel = 24, maxLevel = 29,
    factions = { "Alliance", "Horde" }, entrance = { 1437, 47.79, 56.16 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 95646, giver = 1244, at = { 1437, 56.37, 40.4 }, ender = 1244, endAt = { 1437, 56.37, 40.4 }, level = 31, reqLevel = 24, races = 4294967373 }, -- Horrors in the Highland
        { id = 95647, talk = true, giver = 1480, at = { 1437, 11.88, 58.82 }, level = 31, reqLevel = 24, races = 4294967373 }, -- Lost in the Thicket Things
        { id = 95737, talk = true, giver = 3970, at = { 1440, 34.98, 48.46 }, ender = 1480, endAt = { 1437, 11.88, 58.82 }, level = 31, reqLevel = 24, races = 4294967373 }, -- Seeking Caitlin
        { id = 95772, talk = true, giver = 956, at = { 1433, 25.79, 46.44 }, level = 31, reqLevel = 24, races = 4294967373 }, -- Songblade Search
        { id = 95810, inside = true, item = 270865, ender = 1077, endAt = { 1437, 38.81, 52.39 }, level = 31, reqLevel = 24, races = 4294967373 }, -- Lost Relic Carry
        { id = 98815, giver = 2094, at = { 1437, 8.55, 55.74 }, ender = 2094, endAt = { 1437, 8.55, 55.74 }, level = 28, reqLevel = 24, races = 4294967373 }, -- Highland Hides
        { id = 98824, giver = 1077, at = { 1437, 38.81, 52.39 }, ender = 5387, endAt = { 1455, 69.93, 18.55 }, level = 31, reqLevel = 24, races = 4294967373 }, -- Prehistoric Prism
      },
      Horde = {
        { id = 95663, talk = true, giver = 2787, at = { 1417, 74.54, 35.64 }, level = 31, reqLevel = 24, races = 8589934770 }, -- Dragonmaw Rumors
        { id = 95664, inside = true, item = 270866, ender = 9087, endAt = { 1456, 71.06, 34.19 }, level = 31, reqLevel = 24, races = 8589934770 }, -- Elder Knowledge
        { id = 95697, giver = 3368, at = { 1454, 57.2, 53.32 }, ender = 3368, endAt = { 1454, 57.2, 53.32 }, level = 31, reqLevel = 24, races = 8589934770 }, -- Changing Tastes
        { id = 98823, talk = true, giver = 9087, at = { 1456, 71.06, 34.19 }, ender = 259118, endAt = { 1412, 33.41, 22.58 }, level = 31, reqLevel = 24, races = 8589934770 }, -- Earthen Echo
      },
    },
  },
  { key = "DALARAN", name = "City of Dalaran", areaId = 16544, minLevel = 28, maxLevel = 33,
    factions = { "Alliance", "Horde" }, entrance = { 1416, 8.46, 59.21 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 92456, giver = 5502, at = { 1453, 31.5, 62.61 }, ender = 5502, endAt = { 1453, 31.5, 62.61 }, level = 33, reqLevel = 24, races = 4294967373 }, -- A Green Sample
        { id = 92457, giver = 269127, at = { 1416, 14.3, 59.57 }, ender = 269127, endAt = { 1416, 14.3, 59.57 }, level = 33, reqLevel = 24, races = 4294967373 }, -- Starving Arcane
        { id = 92458, giver = 269127, at = { 1416, 14.3, 59.57 }, ender = 269127, endAt = { 1416, 14.3, 59.57 }, level = 33, reqLevel = 24, races = 4294967373 }, -- Heart of Disruption
        { id = 92489, giver = 5694, at = { 1453, 48.71, 87.62 }, ender = 5694, endAt = { 1453, 48.71, 87.62 }, level = 33, reqLevel = 24, races = 4294967373 }, -- Power Overwhelming
      },
      Horde = {
        { id = 96984, giver = 269127, at = { 1416, 14.3, 59.57 }, ender = 2410, endAt = { 1424, 61.6, 20.85 }, level = 33, reqLevel = 24, races = 8589934770 }, -- Heart of Disruption
        { id = 96986, giver = 2278, at = { 1424, 62.63, 20.65 }, ender = 2278, endAt = { 1424, 62.63, 20.65 }, level = 33, reqLevel = 24, races = 8589934770 }, -- The Grave Knight
        { id = 96988, giver = 11044, at = { 1458, 46.61, 74.09 }, ender = 11044, endAt = { 1458, 46.61, 74.09 }, level = 33, reqLevel = 24, races = 8589934770 }, -- Source of Power
      },
    },
  },
  { key = "SM", name = "Scarlet Monastery", areaId = 796, minLevel = 28, maxLevel = 45,
    factions = { "Alliance", "Horde" }, entrance = { 1420, 82.6, 33.8 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 1050, giver = 3979, at = { 1455, 74.97, 12.48 }, ender = 3979, endAt = { 1455, 74.97, 12.48 }, level = 38, reqLevel = 28, races = 4294967373 }, -- Mythology of the Titans
        { id = 1053, giver = 3980, at = { 1424, 51.47, 58.35 }, ender = 3980, endAt = { 1424, 51.47, 58.35 }, level = 40, reqLevel = 34, races = 4294967373, pre = { 1052 } }, -- In the Name of the Light
        { id = 96800, giver = 264265, at = { 1416, 9.75, 63.36 }, ender = 264265, endAt = { 1416, 9.75, 63.36 }, level = 38, reqLevel = 30, races = 4294967373 }, -- Past Due
        { id = 1052, bc = true, giver = 1182, at = { 1443, 66.52, 7.91 }, ender = 3980, endAt = { 1424, 51.47, 58.35 }, level = 40, reqLevel = 34, races = 4294967373, pre = { 261 } }, -- Down the Scarlet Path
      },
      Horde = {
        { id = 1048, giver = 2425, at = { 1458, 56.25, 92.2 }, ender = 2425, endAt = { 1458, 56.25, 92.2 }, level = 42, reqLevel = 33, races = 8589934770 }, -- Into The Scarlet Monastery
        { id = 1049, giver = 3978, at = { 1456, 34.4, 46.87 }, ender = 3978, endAt = { 1456, 34.4, 46.87 }, level = 38, reqLevel = 28, races = 162 }, -- Compendium of the Fallen
        { id = 1051, inside = true, ender = 3982, endAt = { 1424, 62.67, 18.88 }, level = 33, reqLevel = 25, races = 8589934770 }, -- Vorrel's Revenge
        { id = 1113, giver = 2055, at = { 1458, 48.82, 69.28 }, ender = 2055, endAt = { 1458, 48.82, 69.28 }, level = 33, reqLevel = 30, races = 8589934770, pre = { 1109 } }, -- Hearts of Zeal
        { id = 1160, giver = 4488, at = { 1458, 57.8, 65.42 }, ender = 4488, endAt = { 1458, 57.8, 65.42 }, level = 36, reqLevel = 25, races = 8589934770, pre = { 1159 } }, -- Test of Lore
        { id = 1159, bc = true, giver = 4489, at = { 1442, 78.8, 45.69 }, ender = 4488, endAt = { 1458, 57.8, 65.42 }, level = 30, reqLevel = 25, races = 8589934770, pre = { 6627 } }, -- Test of Lore
      },
    },
  },
  { key = "GNOMER", name = "Gnomeregan", areaId = 721, minLevel = 29, maxLevel = 38,
    factions = { "Alliance", "Horde" }, entrance = { 1426, 24.3, 39.8 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 2904, inside = true, ender = 7853, endAt = { 1434, 27.6, 77.48 }, level = 30, reqLevel = 24 }, -- A Fine Mess
        { id = 2922, giver = 7944, at = { 1455, 69.55, 50.33 }, ender = 7944, endAt = { 1455, 69.55, 50.33 }, level = 26, reqLevel = 20, races = 4294967373 }, -- Save Techbot's Brain!
        { id = 2923, talk = true, giver = 7917, at = { 1453, 51.05, 48.39 }, ender = 7944, endAt = { 1455, 69.55, 50.33 }, level = 26, reqLevel = 20, races = 4294967373 }, -- Tinkmaster Overspark
        { id = 2924, giver = 6169, at = { 1455, 67.92, 46.1 }, ender = 6169, endAt = { 1455, 67.92, 46.1 }, level = 30, reqLevel = 24, races = 4294967373 }, -- Essential Artificials
        { id = 2925, talk = true, giver = 6142, at = { 1457, 59.51, 45.38 }, ender = 6169, endAt = { 1455, 67.92, 46.1 }, level = 30, reqLevel = 24, races = 4294967373 }, -- Klockmort's Essentials
        { id = 2926, giver = 1268, at = { 1426, 45.89, 49.39 }, ender = 1268, endAt = { 1426, 45.89, 49.39 }, level = 27, reqLevel = 20, races = 4294967373 }, -- Gnogaine
        { id = 2927, talk = true, giver = 6569, at = { 1455, 69.18, 50.55 }, ender = 1268, endAt = { 1426, 45.89, 49.39 }, level = 27, reqLevel = 20, races = 4294967373 }, -- The Day After
        { id = 2928, giver = 6579, at = { 1453, 62.63, 34.11 }, ender = 6579, endAt = { 1453, 62.63, 34.11 }, level = 30, reqLevel = 20, races = 4294967373 }, -- Gyrodrillmatic Excavationators
        { id = 2929, giver = 7937, at = { 1455, 68.75, 48.97 }, ender = 7937, endAt = { 1455, 68.75, 48.97 }, level = 35, reqLevel = 25, races = 4294967373 }, -- The Grand Betrayal
        { id = 2930, giver = 7950, at = { 1455, 69.83, 48.1 }, ender = 7950, endAt = { 1455, 69.83, 48.1 }, level = 30, reqLevel = 25, races = 4294967373 }, -- Data Rescue
        { id = 2931, talk = true, giver = 4077, at = { 1442, 59.52, 67.15 }, ender = 7950, endAt = { 1455, 69.83, 48.1 }, level = 28, reqLevel = 25, races = 4294967373 }, -- Castpipe's Task
        { id = 2947, inside = true, ender = 6826, endAt = { 1455, 36.38, 3.61 }, level = 34, reqLevel = 28, races = 4294967373, pre = { 2945 } }, -- Return of the Ring
        { id = 2962, giver = 1268, at = { 1426, 45.89, 49.39 }, ender = 1268, endAt = { 1426, 45.89, 49.39 }, level = 30, reqLevel = 20, races = 4294967373, pre = { 2926 } }, -- The Only Cure is More Green Glow
      },
      Horde = {
        { id = 2841, giver = 3412, at = { 1454, 75.99, 25.41 }, ender = 3412, endAt = { 1454, 75.99, 25.41 }, level = 35, reqLevel = 25, races = 8589934770 }, -- Rig Wars
        { id = 2842, talk = true, giver = 3413, at = { 1454, 75.49, 25.36 }, ender = 7853, endAt = { 1434, 27.6, 77.48 }, level = 35, reqLevel = 20, races = 8589934770 }, -- Chief Engineer Scooty
        { id = 2843, giver = 7853, at = { 1434, 27.6, 77.48 }, ender = 7853, endAt = { 1434, 27.6, 77.48 }, level = 35, reqLevel = 20, races = 8589934770, pre = { 2842 } }, -- Gnomer-gooooone!
        { id = 2904, inside = true, ender = 7853, endAt = { 1434, 27.6, 77.48 }, level = 30, reqLevel = 24 }, -- A Fine Mess
        { id = 2949, inside = true, ender = 3412, endAt = { 1454, 75.99, 25.41 }, level = 34, reqLevel = 28, races = 8589934770, pre = { 2945 } }, -- Return of the Ring
      },
    },
  },
  { key = "RFK", name = "Razorfen Kraul", areaId = 491, minLevel = 29, maxLevel = 38,
    factions = { "Alliance", "Horde" }, entrance = { 1413, 42.9, 90.2 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 1101, giver = 4048, at = { 1444, 89.64, 46.57 }, ender = 4048, endAt = { 1444, 89.64, 46.57 }, level = 34, reqLevel = 29, races = 4294967373, pre = { 1100 } }, -- The Crone of the Kraul
        { id = 1142, inside = true, ender = 4521, endAt = { 1457, 69.54, 67.75 }, level = 30, reqLevel = 25, races = 4294967373 }, -- Mortality Wanes
        { id = 1221, giver = 3446, at = { 1413, 62.37, 37.62 }, ender = 3446, endAt = { 1413, 62.37, 37.62 }, level = 26, reqLevel = 20 }, -- Blueleaf Tubers
      },
      Horde = {
        { id = 1102, giver = 4451, at = { 1456, 35.97, 59.92 }, ender = 4451, endAt = { 1456, 35.97, 59.92 }, level = 34, reqLevel = 29, races = 8589934770 }, -- A Vengeful Fate
        { id = 1109, giver = 2055, at = { 1458, 48.82, 69.28 }, ender = 2055, endAt = { 1458, 48.82, 69.28 }, level = 33, reqLevel = 30, races = 8589934770 }, -- Going, Going, Guano!
        { id = 1221, giver = 3446, at = { 1413, 62.37, 37.62 }, ender = 3446, endAt = { 1413, 62.37, 37.62 }, level = 26, reqLevel = 20 }, -- Blueleaf Tubers
      },
    },
  },
  { key = "RFD", name = "Razorfen Downs", areaId = 722, minLevel = 37, maxLevel = 46,
    factions = { "Alliance", "Horde" }, entrance = { 1413, 49, 93.9 }, entranceSource = "questiedb",
    quests = {
      Alliance = {
        { id = 3636, giver = 1284, at = { 1453, 50.31, 45.47 }, ender = 1284, endAt = { 1453, 50.31, 45.47 }, level = 42, reqLevel = 39, races = 4294967373 }, -- Bring the Light
        { id = 6626, giver = 12866, at = { 1413, 49.01, 94.94 }, ender = 12866, endAt = { 1413, 49.01, 94.94 }, level = 35, reqLevel = 28 }, -- A Host of Evil
      },
      Horde = {
        { id = 3341, giver = 2308, at = { 1458, 74.05, 33.31 }, ender = 2308, endAt = { 1458, 74.05, 33.31 }, level = 42, reqLevel = 37, races = 8589934770 }, -- Bring the End
        { id = 6521, giver = 2425, at = { 1458, 56.25, 92.2 }, ender = 2425, endAt = { 1458, 56.25, 92.2 }, level = 36, reqLevel = 28, races = 8589934770, pre = { 6522 } }, -- An Unholy Alliance
        { id = 6522, inside = true, item = 17008, ender = 2425, endAt = { 1458, 56.25, 92.2 }, level = 36, reqLevel = 28, races = 8589934770 }, -- An Unholy Alliance
        { id = 6626, giver = 12866, at = { 1413, 49.01, 94.94 }, ender = 12866, endAt = { 1413, 49.01, 94.94 }, level = 35, reqLevel = 28 }, -- A Host of Evil
      },
    },
  },
}
