-- tools/routebuilder/plans.lua : découpage des routes en chapitres (ordre des zones du § 6 de la spec).
--
-- Chaque plan : { id, title, faction, races = {...}|nil, zones = {uiMapId,...}, minLevel, maxLevel,
--   endZones = {...}|nil, entry = {mapId, x, y}, exit = {mapId, x, y}|nil,
--   bounds = { [uiMapId] = {x1, y1, x2, y2} | { {x1,y1,x2,y2}, ... } }|nil  -- limite la région (départs, objectifs)
--   dungeons = {nom,...}|nil      -- quêtes de donjon prises au passage, en `optional`
--   optional = { [questId] = "nom du donjon" }|nil  -- quêtes forcées, marquées optional + dungeon
--   force = { [questId] = true }|nil, drop = { [questId] = "raison" }|nil
--   arrive = { via = {mapId, x, y}|nil, steps = {...}, time = s }|nil  -- étapes d'arrivée quand on vient
--                                    -- d'un autre continent ou de plus de 1500 yd (via : trajet calculé
--                                    -- jusqu'à ce point avant les étapes fixes ; time = durée des étapes fixes)
--   flightPaths = { "<nom TaxiNodes>", ... }|nil  -- points de vol à prendre dans ce chapitre (détour planifié)
--   levelSlack = n|nil               -- niveaux de dépassement tolérés au-delà de maxLevel (défaut 1)
--   levelBelow = n|nil               -- quêtes acceptées jusqu'à minLevel - n (défaut 3) : têtes de chaîne basses
--   far = yd|nil                     -- distance objectif-hub au-delà de laquelle une quête est écartée (défaut 900)
--   dungeonReqSlack = n|nil          -- quêtes de donjon prises jusqu'au niveau requis maxLevel + n (défaut 0)
--   dungeonLevelHigh = n|nil         -- quêtes de donjon prises jusqu'au niveau de quête maxLevel + n
--   logCap = n|nil                   -- plafond du journal (défaut 20)
--   strictLevel = true|nil           -- farm des tâches bloquées par le niveau compté dans l'ordonnancement
--                                    -- (objectifs jamais avancés vers un niveau plus bas ; plus de marche)
--   precede = { { "A3376", "O757" }, ... }|nil  -- ordre imposé : la première tâche avant la seconde
--                                    -- (A/T/C<quête> ; O<quête> = tous les objectifs de la quête)
--   safeLevel = { [questId] = n }|nil -- niveau dès lequel les objectifs de la quête sont faits (remplace le
--                                    -- niveau « sûr » calculé : quête niveau - 1, monstres niveau - 1)
--   next = id | nextByRace = { [raceKey] = id }
--   choices = { { id = planId, races = {raceKey,...}|nil, label = "..."|nil, weight = n|nil,
--                 travel = { kind = "walk"|"fly"|"boat"|"zeppelin"|"tram"|"portal"|"hearth",
--                            minutes = n|nil }|nil }, ... }|nil
--                                    -- choix de suite proposés au joueur en fin de chapitre (2 à 4, ordre
--                                    -- d'affichage) ; la suite par défaut (next, ou nextByRace de chaque race
--                                    -- concernée) doit en faire partie et reste la seule simulée (pathFor).
--                                    -- travel.minutes : tools/routebuilder/travel.lua <planId> (sim.route
--                                    -- depuis la fin du chapitre, d'après les guides et rapports générés).
--                                    -- Contrôlé par plans.validate (build.lua s'arrête sur une erreur).
-- }
--
-- Identifiants : A_<Start>_<NN>, A_<NN> (tronc commun), H_<Start>_<NN>, H_<NN>, A_Skyborne_<NN>, H_Skyborne_<NN>.
-- Les rectangles `bounds` et les points `entry` des chapitres autres que A_DwarfGnome_01 sont une
-- première estimation (PNJ de départ réels de QuestieDB) à vérifier lors de la relecture (Tasks 14-16).

-- uiMapIDs
local DUN_MOROGH, ELWYNN, TELDRASSIL, DARKSHORE, LOCH_MODAN, WESTFALL = 1426, 1429, 1438, 1439, 1432, 1436
local REDRIDGE, DUSKWOOD, WETLANDS, ASHENVALE, STONETALON, HILLSBRAD = 1433, 1431, 1437, 1440, 1442, 1424
local DUROTAR, MULGORE, TIRISFAL, SILVERPINE, BARRENS, NEEDLES, ZEPHRAS = 1411, 1412, 1420, 1421, 1413, 1441, 2521
local IRONFORGE, STORMWIND, DARNASSUS, ORGRIMMAR, THUNDERBLUFF, UNDERCITY = 1455, 1453, 1457, 1454, 1456, 1458
local ALTERAC, ARATHI, BADLANDS, BLASTED, WPL, EPL, HINTERLANDS = 1416, 1417, 1418, 1419, 1422, 1423, 1425
local SEARING, BURNING, STV, SWAMP = 1427, 1428, 1434, 1435
local DESOLACE, FERALAS, DUSTWALLOW, TANARIS, AZSHARA, FELWOOD, UNGORO, SILITHUS, WINTERSPRING =
  1443, 1444, 1445, 1446, 1447, 1448, 1449, 1451, 1452

local plans = {}

plans.Alliance = {
  -- Nain / Gnome : Coldridge, Dun Morogh (pré-quêtes de Hall of Thanes), Loch Modan (avec les allers-retours
  -- à Ironforge des suites « Honor Students » et « Report to Ironforge »), puis Marche de l'Ouest par le tram.
  {
    id = "A_DwarfGnome_01", title = "Coldridge Valley", faction = "Alliance", races = { "Dwarf", "Gnome" },
    zones = { DUN_MOROGH }, bounds = { [DUN_MOROGH] = { 19, 57, 38, 85 } }, endZones = { DUN_MOROGH },
    minLevel = 1, maxLevel = 6, entry = { DUN_MOROGH, 29.93, 71.20 }, next = "A_DwarfGnome_02",
  },
  {
    id = "A_DwarfGnome_02", title = "Dun Morogh", faction = "Alliance", races = { "Dwarf", "Gnome" },
    zones = { DUN_MOROGH, IRONFORGE }, endZones = { LOCH_MODAN },
    minLevel = 6, maxLevel = 11, entry = { DUN_MOROGH, 46.7, 53.8 }, next = "A_DwarfGnome_03",
    flightPaths = { "Ironforge, Dun Morogh" },
    dungeons = { "The Hall of Thanes", "Gnomeregan" },
    optional = { [96391] = "The Hall of Thanes", [96392] = "The Hall of Thanes", [96393] = "The Hall of Thanes" },
    -- Réserve de MacGrann (312) : un coffre, pas de monstre à tuer ; faite dès la prise (38.51, 53.93) au lieu
    -- d'attendre le niveau 11 (retour depuis Gol'Bolar). Mesuré : Nain/Gnome 1-30 -16 min.
    safeLevel = { [312] = 7 },
  },
  {
    id = "A_DwarfGnome_03", title = "Loch Modan", faction = "Alliance", races = { "Dwarf", "Gnome" },
    zones = { LOCH_MODAN, IRONFORGE }, endZones = { STORMWIND },
    minLevel = 11, maxLevel = 14, entry = { LOCH_MODAN, 33.9, 51.0 }, next = "A_DwarfGnome_04", strictLevel = true,
    flightPaths = { "Thelsamar, Loch Modan" },
    -- Fin à Stormwind : Marche de l'Ouest à pied (suite par défaut) ou Sombrivage par le bateau du port
    -- de Stormwind (A_01 commence par ce bateau). Minutes : travel.lua A_DwarfGnome_03 (guides du
    -- 2026-11-06, QuestieDB v1.0.11, lot I) : fin au sud de Stormwind, Marche de l'Ouest 122 s de marche,
    -- Sombrivage 80 s de marche + 300 s de bateau + 44 s de marche.
    choices = {
      { id = "A_DwarfGnome_04", travel = { kind = "walk", minutes = 2 } },
      { id = "A_01", travel = { kind = "boat", minutes = 7 } },
    },
  },
  {
    id = "A_DwarfGnome_04", title = "Westfall", faction = "Alliance", races = { "Dwarf", "Gnome" },
    -- Quartier des Nains de Stormwind (sortie du tram) : quêtes des Mortemines prises au passage
    -- (Wilder Thistlenettle, Shoni the Shilent) ; second rectangle : maître de vol
    zones = { WESTFALL, STORMWIND }, bounds = { [STORMWIND] = { { 62, 33, 71, 42 }, { 69, 70, 74, 75 } } }, endZones = { STORMWIND },
    minLevel = 14, maxLevel = 16, levelSlack = 1, dungeonLevelHigh = 4,
    entry = { WESTFALL, 56.3, 47.5 }, next = "A_01",
    flightPaths = { "Stormwind, Elwynn", "Sentinel Hill, Westfall" },
    dungeons = { "The Deadmines" },
    -- Poor Old Blanchy (151) : écartée par le budget d'XP (« level band reached ») ; +1 085 XP pour +3 min
    force = { [151] = true },
  },
  -- Humain : Northshire, Elwynn, Marche de l'Ouest
  {
    id = "A_Human_01", title = "Northshire", faction = "Alliance", races = { "Human" },
    zones = { ELWYNN }, bounds = { [ELWYNN] = { 42, 24, 59, 50 } }, endZones = { ELWYNN },
    minLevel = 1, maxLevel = 6, entry = { ELWYNN, 48.9, 41.6 }, next = "A_Human_02",
  },
  {
    id = "A_Human_02", title = "Elwynn Forest", faction = "Alliance", races = { "Human" },
    zones = { ELWYNN, STORMWIND }, endZones = { WESTFALL },
    minLevel = 6, maxLevel = 11, entry = { ELWYNN, 43.4, 65.5 }, next = "A_Human_03",
    flightPaths = { "Stormwind, Elwynn" },
  },
  {
    id = "A_Human_03", title = "Westfall", faction = "Alliance", races = { "Human" },
    zones = { WESTFALL }, endZones = { STORMWIND }, minLevel = 11, maxLevel = 16, levelSlack = 0,
    entry = { WESTFALL, 56.3, 47.5 }, next = "A_01",
    flightPaths = { "Sentinel Hill, Westfall" },
    dungeons = { "The Deadmines" },
    -- Rumi of Gnomeregan (79093, niveau 20) : écartée « au-dessus de la tranche » ; rendue à Stormwind en fin
    -- de chapitre. Forcée ici seulement : un forçage global la placerait plus tôt (Elwynn + Stormwind).
    force = { [79093] = true },
  },
  -- Elfe de la nuit : Shadowglen, Teldrassil, Sombrivage (toute la zone), puis tronc commun aux Carmines
  {
    id = "A_NightElf_01", title = "Shadowglen", faction = "Alliance", races = { "NightElf" },
    zones = { TELDRASSIL }, bounds = { [TELDRASSIL] = { 52, 24, 68, 50 } }, endZones = { TELDRASSIL },
    minLevel = 1, maxLevel = 6, entry = { TELDRASSIL, 58.7, 44.3 }, next = "A_NightElf_02",
  },
  {
    id = "A_NightElf_02", title = "Teldrassil", faction = "Alliance", races = { "NightElf" },
    zones = { TELDRASSIL, DARNASSUS }, endZones = { DARKSHORE },
    minLevel = 6, maxLevel = 11, entry = { TELDRASSIL, 55.9, 57.3 }, next = "A_NightElf_03",
    flightPaths = { "Rut'theran Village, Teldrassil" },
    -- strictLevel (QuestieDB v1.0.11 : Escaping Ban'ethil 99053 passe niveau 10) : sans lui, 105 mobs de farm
    -- au milieu du chapitre pour des objectifs avancés avant leur niveau ; avec lui (et sur A_NightElf_03),
    -- Elfe 1-30 -23 min, farm 105 -> 11 mobs ici.
    strictLevel = true,
  },
  {
    id = "A_NightElf_03", title = "Darkshore", faction = "Alliance", races = { "NightElf" },
    zones = { DARKSHORE }, minLevel = 11, maxLevel = 20, entry = { DARKSHORE, 37.0, 44.0 },
    flightPaths = { "Auberdine, Darkshore" },
    strictLevel = true, -- avec A_NightElf_02 (voir là-bas) : sinon jusqu'à 159 mobs de farm pour une tête de chaîne
    dungeons = { "Blackfathom Deeps" },
    nextByRace = { NightElf = "A_02" },
    -- Lot Alliance 2026-11-07 : A_02 et A_03 rendent à Stormwind ; emportées d'ici, ces deux quêtes faisaient farmer
    -- 190 mobs au niveau 13 (ordre strictLevel). Fin à 20 : le tronc part du niveau le plus bas des parcours qui
    -- arrivent à A_02 (A_01 finit à 19.71) ; à 19.27, il coûtait +49 min aux trois autres parcours. Elfe 1-30 -7 min.
    drop = { [78124] = "Night Elf path: turned in at Stormwind two chapters later; carried from here it costs a 190-mob grind at level 13",
             [97914] = "Night Elf path: turned in at Stormwind two chapters later; carried from here it costs a 190-mob grind at level 13" },
  },
  -- Skyborne (Alliance) : île de Zephras (1-16 : la zone suffit), bateau pour Dalaran, portail Skyborne
  -- vers Stormwind, puis tronc commun à Sombrivage (A_01)
  {
    id = "A_Skyborne_01", title = "Zephras Isle", faction = "Alliance", races = { "Skyborne" },
    zones = { ZEPHRAS }, minLevel = 1, maxLevel = 15, entry = { ZEPHRAS, 42.8, 23.4 },
    nextByRace = { Skyborne = "A_01" },
  },
  -- Tronc commun Alliance : Nain, Gnome, Humain et Skyborne à partir de Sombrivage ; Elfe de la nuit à
  -- partir d'Ashenvale. Ordre du § 6 de la spec revu d'après les rapports (docs/routes/README.md) :
  -- Les Carmines passent avec le Bois de la Pénombre (un seul aller-retour vers les Royaumes de l'Est),
  -- et Les Paluns sont faites en une fois, avant les Contreforts d'Hautebrande (bateau Menethil -> Southshore).
  {
    id = "A_01", title = "Darkshore", faction = "Alliance", zones = { DARKSHORE },
    minLevel = 16, maxLevel = 19, entry = { DARKSHORE, 37.0, 44.0 }, next = "A_02", logCap = 18,
    flightPaths = { "Auberdine, Darkshore" },
    dungeons = { "Blackfathom Deeps" },
  },
  {
    id = "A_02", title = "Ashenvale and Stonetalon Mountains", faction = "Alliance", zones = { ASHENVALE, STONETALON },
    minLevel = 20, maxLevel = 22, levelSlack = 0, entry = { ASHENVALE, 34.4, 48.0 }, next = "A_03",
    flightPaths = { "Astranaar, Ashenvale" },
    dungeons = { "Blackfathom Deeps" },
    -- rendus à Stormwind au passage vers les Carmines (A Scroll from Mauren 1075) : 1-30 -7 min par parcours
    endZones = { STORMWIND },
  },
  {
    id = "A_03", title = "Redridge Mountains and Duskwood", faction = "Alliance", zones = { REDRIDGE, DUSKWOOD },
    minLevel = 22, maxLevel = 26, levelSlack = 1, far = 1600, entry = { REDRIDGE, 30.6, 59.4 }, next = "A_04",
    flightPaths = { "Lakeshire, Redridge", "Darkshire, Duskwood" },
    dungeons = { "The Stockade" },
    optional = { [253] = "Group quest: Eliza, level 31 elite" },
    -- Worgen in the Woods (173) : écartée ici seulement (chaîne de Nightbane 27-31) ; faite en A_07 (30-34).
    -- Avant le lot H (2026-11-06), écartée dans overrides.lua pour toute la route.
    drop = { [173] = "Worgen in the Woods chain: Nightbane mobs 27-31, above the 22-26 band" },
    -- rendus au passage vers le port de Stormwind (A_04) : Stalvan 67 / 69, Seeking Wisdom 269, An Old History
    -- Book 337 (lot Alliance 2026-11-07 : avec A_02, 1-30 -53 min sur Humain, Nain/Gnome et Skyborne)
    endZones = { STORMWIND, ELWYNN, WESTFALL },
  },
  {
    id = "A_04", title = "Wetlands", faction = "Alliance", zones = { WETLANDS },
    minLevel = 26, maxLevel = 29, levelSlack = 0, entry = { WETLANDS, 9.5, 59.7 }, next = "A_05",
    flightPaths = { "Menethil Harbor, Wetlands" },
    dungeons = { "Excavation Site: Wetlands" },
    optional = { [304] = "Group quest: Balgaras the Foul, level 34 elite",
                 [474] = "Group quest: Chieftain Nek'rosh, level 32 elite",
                 [98216] = "Group quest: Goaz Warder, level 32 elite" },
    -- Les Paluns ne se rejoignent pas à pied depuis Ironforge en ligne droite (montagnes, Dun Algaz) :
    -- trajet calculé jusqu'au port de Stormwind, puis bateaux Stormwind -> Auberdine -> Menethil.
    arrive = { via = { STORMWIND, 24.1, 55.4 }, steps = {
      { "boat", STORMWIND, 24.1, 55.4, note = "Take the boat to Auberdine (Stormwind Harbor)" },
      { "boat", DARKSHORE, 32.4, 43.8, note = "Take the boat to Menethil Harbor" },
    }, time = 720 },
  },
  {
    id = "A_05", title = "Hillsbrad Foothills", faction = "Alliance", zones = { HILLSBRAD },
    minLevel = 29, maxLevel = 30, levelSlack = 0, entry = { HILLSBRAD, 49.3, 52.3 }, next = "A_08",
    flightPaths = { "Southshore, Hillsbrad" },
    -- bateau Menethil -> Southshore (sinon ligne droite par-dessus la mer)
    arrive = { via = { WETLANDS, 4.9, 57.3 }, steps = {
      { "boat", WETLANDS, 4.9, 57.3, note = "Take the boat to Southshore" },
    }, time = 420 },
    dungeons = { "City of Dalaran", "Excavation Site: Wetlands" },
  },
  -- Routes 30-60 (lot H, 2026-11-06) : chapitres du plan « meta paths 1-60 », reconstruits et mesurés ici
  -- (docs/routes/README.md). Ordre du parcours (next) :
  --   A_05 -> A_08 -> A_07 -> A_09 -> A_10 -> A_11 -> A_12 -> A_13 -> A_15 -> A_16 -> A_17 -> A_18 -> A_19 ->
  --   A_20 -> A_21 -> A_22 -> A_28 -> A_24 -> A_26 -> A_27 -> A_23 -> A_29 -> A_30.
  -- Les Steppes ardentes (A_28) suivent la Gorge des Vents brûlants (contenu 52-54) et les Maleterres de
  -- l'Ouest (A_23) passent à 57-58 (contenu 55-58 ; à 51-53 : ~1 050 mobs de farm mesurés). A_06, A_14 et
  -- A_25 sont écrits mais hors chaîne (aucun parcours ne les suit : ni simulés, ni générés).
  -- Chaque chapitre est sur un seul continent. Tranches contiguës (minLevel = maxLevel du précédent),
  -- levelBelow = 8 (restes d'une zone déjà visitée), far = 1600, widen = false (une zone revisitée plus tard
  -- garde ses quêtes hautes pour cette visite). Entrées : maîtres de vol ou donneurs de QuestieDB.
  {
    id = "A_08", title = "Ashenvale", faction = "Alliance", zones = { ASHENVALE },
    -- levelBelow 10 (lot Alliance 2026-11-07) : chaîne Raene's Cleansing (1024, niveau 21, puis 1026 -> 1046) ;
    -- A_08 -11 min, +8 quêtes, -63 mobs
    minLevel = 30, maxLevel = 32, levelSlack = 0, levelBelow = 10, far = 1600, widen = false, entry = { ASHENVALE, 34.41, 47.99 }, next = "A_07",
    flightPaths = { "Astranaar, Ashenvale" },
    dungeons = { "Blackfathom Deeps" },
  },
  {
    id = "A_07", title = "Duskwood", faction = "Alliance",
    -- Lot Alliance 2026-11-07 : chaînes Stalvan (66 -> 98 : Old Footlocker en Marche de l'Ouest, Comté-de-l'Or et
    -- Marshal Haggard en Elwynn, Caretaker Folsom à Stormwind) et Missing Diplomat (1242 -> 1247 : Jorgen, Elling
    -- Trias et Dashel Stonefist à Stormwind). Rectangles autour de ces donneurs (QuestieDB), rendus partout dans
    -- ces cartes. A_07 +1 min, +11 quêtes, -64 mobs.
    zones = { DUSKWOOD, ELWYNN, WESTFALL, STORMWIND },
    bounds = {
      [STORMWIND] = { { 40, 70, 45, 75 }, { 64, 72, 68, 76 }, { 74, 83, 78, 87 }, { 72, 57, 76, 61 } },
      [ELWYNN] = { { 41, 63, 46, 68 }, { 82, 67, 87, 72 } },
      [WESTFALL] = { { 39, 64, 44, 69 } },
    },
    endZones = { STORMWIND, ELWYNN, WESTFALL },
    minLevel = 32, maxLevel = 33, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { DUSKWOOD, 77.49, 44.29 }, next = "A_09",
    flightPaths = { "Darkshire, Duskwood" },
  },
  {
    id = "A_09", title = "Thousand Needles", faction = "Alliance", zones = { NEEDLES, BARRENS },
    bounds = { [BARRENS] = { 58, 32, 66, 42 } }, -- Ratchet
    minLevel = 33, maxLevel = 34, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { NEEDLES, 77.79, 77.27 }, next = "A_10",
    flightPaths = { "Ratchet, The Barrens" },
    dungeons = { "Razorfen Kraul" },
  },
  {
    id = "A_10", title = "Stranglethorn Vale", faction = "Alliance", zones = { STV },
    bounds = { [STV] = { 20, 0, 55, 40 } }, -- nord : camp rebelle, Nesingwary
    minLevel = 34, maxLevel = 35, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { STV, 35.66, 10.81 }, next = "A_11",
  },
  {
    id = "A_11", title = "Desolace", faction = "Alliance", zones = { DESOLACE },
    minLevel = 35, maxLevel = 37, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { DESOLACE, 64.66, 10.54 }, next = "A_12",
    flightPaths = { "Nijel's Point, Desolace" },
    -- Zones de fin (lot Alliance 2026-11-07, ici et plus bas) : rendus en fin de chapitre dans une capitale ou une zone
    -- voisine sur la route du chapitre suivant ; chaque ajout mesuré, gardé seulement s'il fait gagner. A_11 : -2 à
    -- -5 min, -30 mobs.
    endZones = { IRONFORGE, STORMWIND },
  },
  {
    id = "A_12", title = "Stranglethorn Vale and Swamp of Sorrows", faction = "Alliance", zones = { STV, SWAMP },
    minLevel = 37, maxLevel = 39, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { STV, 27.0, 77.13 }, next = "A_13",
    flightPaths = { "Booty Bay, Stranglethorn" },
    -- The Caravan Road 1041 (Bois de la Pénombre), livres de Stormwind, Deliver the Shipment 1425 (Terres foudroyées) :
    -- A_12 -55 min, +8 quêtes
    endZones = { DUSKWOOD, STORMWIND, BLASTED },
  },
  {
    id = "A_13", title = "Arathi Highlands", faction = "Alliance", zones = { ALTERAC, ARATHI },
    minLevel = 39, maxLevel = 40, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { ARATHI, 45.73, 46.10 }, next = "A_15",
    -- titre : aucune étape mesurée dans les Montagnes d'Alterac (zone gardée pour les candidates)
    flightPaths = { "Refuge Pointe, Arathi" },
    dungeons = { "Scarlet Monastery", "Gnomeregan" },
  },
  {
    id = "A_15", title = "Dustwallow Marsh", faction = "Alliance", zones = { DUSTWALLOW, DESOLACE },
    minLevel = 40, maxLevel = 41, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { DUSTWALLOW, 67.48, 51.30 }, next = "A_16",
    -- titre : aucune quête de Désolace retenue (mesuré) ; zone gardée pour les candidates
    flightPaths = { "Theramore, Dustwallow Marsh" },
    dungeons = { "Razorfen Downs", "Maraudon" },
  },
  {
    id = "A_16", title = "Badlands", faction = "Alliance", zones = { BADLANDS },
    minLevel = 41, maxLevel = 42, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { BADLANDS, 37.90, 10.59 }, next = "A_17",
    dungeons = { "Uldaman" },
    -- Ironforge, Loch Modan (Murdaloc 739), Stormwind, et la Strangleronce du chapitre suivant : A_16 -15 min,
    -- +8 quêtes, -82 mobs
    endZones = { IRONFORGE, LOCH_MODAN, STORMWIND, STV },
    -- Suites des quêtes d'Uldaman prises seulement au passage (722 après 721, 727 après 709) : écartées par la
    -- simulation (« prerequisite unavailable », sim.lua) depuis le lot L ; l'écart manuel est retiré (mesuré identique).
  },
  {
    id = "A_17", title = "Stranglethorn Vale", faction = "Alliance", zones = { STV, SWAMP },
    minLevel = 42, maxLevel = 44, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { STV, 27.0, 77.13 }, next = "A_18",
    -- rendus à Stormwind et au Marais des Chagrins (Cortello's Riddle 624) : A_17 -73 min, -225 mobs ; Marais en zone
    -- de quêtes (restes) : -7 min ; titre : aucune étape placée au Marais (mesuré)
    endZones = { STORMWIND, SWAMP },
  },
  {
    -- Mille pointes en zone de quêtes (restes 41-47) : -5 min, +2 quêtes, -17 mobs (A_19 +4 min) ; titre : aucune
    -- étape placée à Mille pointes (mesuré)
    id = "A_18", title = "Tanaris", faction = "Alliance", zones = { TANARIS, NEEDLES },
    minLevel = 44, maxLevel = 45, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { TANARIS, 51.01, 29.34 }, next = "A_19",
    flightPaths = { "Gadgetzan, Tanaris" },
    dungeons = { "Zul'Farrak" },
  },
  {
    id = "A_19", title = "Feralas", faction = "Alliance", zones = { FERALAS },
    minLevel = 45, maxLevel = 46, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { FERALAS, 30.24, 43.25 }, next = "A_20",
    flightPaths = { "Feathermoon, Feralas" },
    dungeons = { "Maraudon" },
  },
  {
    id = "A_20", title = "Tanaris", faction = "Alliance", zones = { TANARIS },
    minLevel = 46, maxLevel = 48, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { TANARIS, 51.01, 29.34 }, next = "A_21",
    dungeons = { "Zul'Farrak" },
    -- Gahz'ridian 3161, Thistleshrub Valley 3362, The Thirsty Goblin 2605 : forcées par le plan « meta paths » (5 quêtes
    -- seulement sans elles, ~1 500 mobs de farm) ; forçage retiré au lot L (mesuré après les corrections du simulateur :
    -- Alliance 1-60 -16 min, -3 quêtes, +28 mobs)
  },
  {
    id = "A_21", title = "Stranglethorn Vale", faction = "Alliance", zones = { STV, SWAMP },
    minLevel = 48, maxLevel = 50, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { STV, 27.0, 77.13 }, next = "A_22",
    dungeons = { "The Temple of Atal'Hakkar" },
  },
  {
    id = "A_22", title = "Searing Gorge and Blasted Lands", faction = "Alliance", zones = { SEARING, BLASTED },
    minLevel = 50, maxLevel = 52, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { SEARING, 37.94, 30.86 }, next = "A_28",
    flightPaths = { "Thorium Point, Searing Gorge", "Nethergarde Keep, Blasted Lands" },
    dungeons = { "Blackrock Depths" },
    -- Ironforge (Suntara Stones 3368, Rise, Obsidion! 3566), Loch Modan (The Horn of the Beast 3181), Stormwind ;
    -- 3441 Divine Retribution et 3453 The Torch of Retribution (QuestieDB : « event », récits de Kalaran Windblade)
    -- ouvrent la chaîne de Thorium Point 3442 -> 3481. A_22 -23 min, +14 quêtes, -259 mobs. Forcées jusqu'au lot L :
    -- les quêtes « event » sont maintenant des candidates ordinaires (sim.lua), forçage retiré (mesuré identique).
    endZones = { IRONFORGE, STORMWIND, LOCH_MODAN },
  },
  {
    id = "A_28", title = "Burning Steppes", faction = "Alliance", zones = { BURNING },
    minLevel = 52, maxLevel = 53, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { BURNING, 84.33, 68.33 }, next = "A_24",
    flightPaths = { "Morgan's Vigil, Burning Steppes" },
    dungeons = { "Blackrock Depths" },
    endZones = { REDRIDGE, STORMWIND }, -- The True Masters 4183 (Lakeshire), Stormwind : -8 min, +2 quêtes, -47 mobs
  },
  {
    id = "A_24", title = "Felwood", faction = "Alliance", zones = { FELWOOD },
    minLevel = 53, maxLevel = 54, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { FELWOOD, 62.49, 24.24 }, next = "A_26",
    flightPaths = { "Talonbranch Glade, Felwood" },
    endZones = { ASHENVALE, UNGORO }, -- Ancient Spirit 4261 (Orneval), Un'Goro du chapitre suivant : -4 min
  },
  {
    id = "A_26", title = "Un'Goro Crater", faction = "Alliance", zones = { UNGORO },
    minLevel = 54, maxLevel = 56, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { UNGORO, 45.23, 5.83 }, next = "A_27",
    flightPaths = { "Marshal's Refuge, Un'Goro Crater" },
    -- pylônes 4285, 4287, 4288 et 4321 (QuestieDB : « event ») : -8 min, +4 quêtes, -41 mobs ; forcés jusqu'au lot L,
    -- candidates ordinaires depuis (forçage retiré, mesuré identique) ; rendus au Gangrebois (Linken's Memory 3942)
    -- et au Berceau-de-l'Hiver du chapitre suivant : -4 min, +5 quêtes, -83 mobs
    endZones = { FELWOOD, WINTERSPRING },
  },
  {
    id = "A_27", title = "Felwood and Winterspring", faction = "Alliance", zones = { WINTERSPRING, FELWOOD },
    minLevel = 56, maxLevel = 57, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { WINTERSPRING, 62.33, 36.61 }, next = "A_23",
    flightPaths = { "Everlook, Winterspring" },
    -- Gangrebois en zone de quêtes : chaîne Falling to Corruption 5084 -> Mystery Goo 5085 -> Toxic Horrors 5086 ->
    -- Winterfall Runners 5087 -> High Chief Winterfall 5121 ; -9 min, +5 quêtes, -175 mobs
    endZones = { FELWOOD },
  },
  {
    id = "A_23", title = "Western Plaguelands", faction = "Alliance", zones = { WPL },
    minLevel = 57, maxLevel = 58, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { WPL, 42.92, 85.06 }, next = "A_29",
    flightPaths = { "Chillwind Camp, Western Plaguelands" },
    dungeons = { "Scholomance" },
    endZones = { STORMWIND }, -- -15 min, +4 quêtes, -72 mobs (A_29 : +15 min de trajet depuis Stormwind)
  },
  {
    id = "A_29", title = "Eastern Plaguelands", faction = "Alliance", zones = { EPL },
    minLevel = 58, maxLevel = 59, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { EPL, 71.81, 49.60 }, next = "A_30",
    flightPaths = { "Light's Hope Chapel, Eastern Plaguelands" },
    dungeons = { "Stratholme" },
    -- 5742 Redemption (QuestieDB : « event », histoire de Tirion Fordring), tête de Of Forgotten Memories 5781 :
    -- -3 min, +3 quêtes, -53 mobs ; forcée jusqu'au lot L, candidate ordinaire depuis (forçage retiré, mesuré
    -- identique). Maleterres de l'Ouest en zone de quêtes : -6 min mesurées, mais seulement grâce aux suites de 5848
    -- écartées ci-dessous ; sans elles +12 min (non retenu).
    -- Suites des quêtes de Stratholme prises seulement au passage (5213 après 5212, 5861 après 5848) : écartées par
    -- la simulation depuis le lot L ; l'écart manuel est retiré (mesuré identique).
  },
  {
    id = "A_30", title = "Silithus", faction = "Alliance", zones = { WINTERSPRING, SILITHUS },
    minLevel = 59, maxLevel = 60, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { SILITHUS, 50.58, 34.45 },
    -- titre : aucune étape mesurée au Berceau-de-l'Hiver (A_27 y prend les quêtes) ; zone gardée
    flightPaths = { "Cenarion Hold, Silithus" },
  },
  -- Hors chaîne (écrits, ni simulés ni générés)
  {
    id = "A_06", title = "Hillsbrad Foothills", faction = "Alliance", zones = { HILLSBRAD },
    minLevel = 30, maxLevel = 32, levelSlack = 0, entry = { HILLSBRAD, 49.34, 52.27 }, next = "A_08",
    -- hors chaîne : restes des Contreforts d'Hautebrande (A_05 finit déjà à 30)
  },
  {
    id = "A_14", title = "The Hinterlands", faction = "Alliance", zones = { HINTERLANDS },
    minLevel = 43, maxLevel = 46, levelSlack = 0, entry = { HINTERLANDS, 11.07, 46.15 }, next = "A_15",
    flightPaths = { "Aerie Peak, The Hinterlands" },
    -- hors chaîne : peu de quêtes Alliance, beaucoup de farm (plan « meta paths »)
  },
  {
    id = "A_25", title = "Feralas and Azshara", faction = "Alliance", zones = { FERALAS, AZSHARA },
    minLevel = 54, maxLevel = 55, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { FERALAS, 30.24, 43.25 }, next = "A_26",
    flightPaths = { "Talrendis Point, Azshara" },
    dungeons = { "Dire Maul" },
  },
}

plans.Horde = {
  -- Orc / Troll
  {
    id = "H_OrcTroll_01", title = "Valley of Trials", faction = "Horde", races = { "Orc", "Troll" },
    zones = { DUROTAR }, bounds = { [DUROTAR] = { 36, 50, 52, 80 } }, endZones = { DUROTAR },
    minLevel = 1, maxLevel = 6, entry = { DUROTAR, 42.1, 68.3 }, next = "H_OrcTroll_02",
  },
  {
    id = "H_OrcTroll_02", title = "Durotar", faction = "Horde", races = { "Orc", "Troll" },
    zones = { DUROTAR, ORGRIMMAR }, endZones = { BARRENS },
    minLevel = 6, maxLevel = 12, entry = { DUROTAR, 52.0, 43.0 },
    flightPaths = { "Orgrimmar, Durotar" },
    nextByRace = { Orc = "H_01", Troll = "H_01" },
  },
  -- Tauren
  {
    id = "H_Tauren_01", title = "Camp Narache", faction = "Horde", races = { "Tauren" },
    zones = { MULGORE }, bounds = { [MULGORE] = { 33, 62, 66, 92 } }, endZones = { MULGORE },
    minLevel = 1, maxLevel = 6, entry = { MULGORE, 43.9, 76.7 }, next = "H_Tauren_02",
    -- Socle du camp (747, 750, 780, 745, 781) avec 752 et 3376, sinon écartés par le budget d'XP ; forcer le
    -- socle seul faisait perdre 752 et Sharptusk (55 -> 64 min). 3376 prise avant le premier passage à
    -- Brambleblade (objectif de 757 au même endroit). Mesuré (QuestieDB v1.0.11) : Tauren 1-30 -62 min.
    force = { [747] = true, [750] = true, [780] = true, [745] = true, [781] = true, [752] = true, [3376] = true },
    precede = { { "A3376", "O757" } },
  },
  {
    id = "H_Tauren_02", title = "Mulgore", faction = "Horde", races = { "Tauren" },
    zones = { MULGORE, THUNDERBLUFF }, endZones = { BARRENS },
    minLevel = 6, maxLevel = 12, entry = { MULGORE, 47.0, 60.0 }, nextByRace = { Tauren = "H_01" },
    flightPaths = { "Thunder Bluff, Mulgore" },
  },
  -- Mort-vivant
  {
    id = "H_Undead_01", title = "Deathknell", faction = "Horde", races = { "Undead" },
    zones = { TIRISFAL }, bounds = { [TIRISFAL] = { 26, 56, 40, 74 } }, endZones = { TIRISFAL },
    minLevel = 1, maxLevel = 6, entry = { TIRISFAL, 30.8, 66.2 }, next = "H_Undead_02",
    drop = { [590] = "Opened by the turn-in of 8 in Brill: 1,071 yd back to Calvin Montague, then back to Brill, for 110 XP" },
  },
  {
    id = "H_Undead_02", title = "Tirisfal Glades", faction = "Horde", races = { "Undead" },
    zones = { TIRISFAL, UNDERCITY }, endZones = { SILVERPINE },
    minLevel = 6, maxLevel = 12, entry = { TIRISFAL, 61.0, 52.0 }, next = "H_Undead_03",
    flightPaths = { "Undercity, Tirisfal" },
    dungeons = { "Ruins of Lordaeron" },
  },
  {
    id = "H_Undead_03", title = "Silverpine Forest", faction = "Horde", races = { "Undead" },
    zones = { SILVERPINE, UNDERCITY }, endZones = { TIRISFAL }, dungeonReqSlack = 1, dungeonLevelHigh = 8,
    -- 12-14 sans dépassement (levelSlack = 0) : le tronc des Tarides commence à 12 ; à 16.25, l'Undead y
    -- arrivait 3.4 niveaux au-dessus du parcours Orc. Mesuré (2026-11-07) : Undead 1-30 -88 min, autres
    -- parcours -13 min (tronc moins chargé), +43 mobs de farm en H_03-H_04.
    minLevel = 12, maxLevel = 14, levelSlack = 0, entry = { SILVERPINE, 43.0, 41.0 }, nextByRace = { Undead = "H_01" },
    flightPaths = { "The Sepulcher, Silverpine Forest" },
    dungeons = { "Ruins of Lordaeron" },
  },
  -- Skyborne (Horde)
  {
    id = "H_Skyborne_01", title = "Zephras Isle", faction = "Horde", races = { "Skyborne" },
    zones = { ZEPHRAS }, minLevel = 1, maxLevel = 15, entry = { ZEPHRAS, 42.8, 23.4 },
    nextByRace = { Skyborne = "H_01" },
  },
  -- Tronc commun Horde. Ordre du § 6 de la spec revu d'après les rapports (docs/routes/README.md) :
  -- Ashenvale passe à 21-25 (ses quêtes Horde sont surtout de niveau 21-26), le sud des Tarides et
  -- Mille pointes suivent, et les Contreforts d'Hautebrande ferment la route à 28-30 (un seul trajet
  -- vers les Royaumes de l'Est, au lieu d'un aller-retour à 21-23).
  {
    id = "H_01", title = "The Barrens", faction = "Horde", zones = { BARRENS },
    minLevel = 12, maxLevel = 17, entry = { BARRENS, 52.0, 30.0 }, next = "H_02",
    flightPaths = { "Crossroads, The Barrens", "Ratchet, The Barrens", "Camp Taurajo, The Barrens" },
    dungeons = { "Wailing Caverns", "Ragefire Chasm" },
  },
  {
    id = "H_02", title = "Stonetalon Mountains and The Barrens", faction = "Horde",
    zones = { STONETALON, BARRENS }, minLevel = 17, maxLevel = 21, levelSlack = 0, levelBelow = 6, far = 1600,
    entry = { BARRENS, 52.0, 30.0 }, next = "H_03",
    flightPaths = { "Sun Rock Retreat, Stonetalon Mountains" },
    dungeons = { "Wailing Caverns" },
  },
  {
    id = "H_03", title = "Ashenvale and Stonetalon Mountains", faction = "Horde", zones = { ASHENVALE, STONETALON },
    minLevel = 21, maxLevel = 25, levelSlack = 0, levelBelow = 6, far = 1600, entry = { ASHENVALE, 73.0, 61.0 }, next = "H_04",
    flightPaths = { "Splintertree Post, Ashenvale", "Zoram'gar Outpost, Ashenvale" },
    dungeons = { "Blackfathom Deeps" },
  },
  {
    id = "H_04", title = "Southern Barrens and Thousand Needles", faction = "Horde", zones = { BARRENS, NEEDLES },
    minLevel = 25, maxLevel = 28, levelSlack = 0, levelBelow = 6, far = 1600, entry = { BARRENS, 44.5, 59.1 }, next = "H_05",
    -- Egg Hunt (868) faite dans le sud des Tarides avant Mille pointes, sans y revenir. Mesuré : Horde -11 min.
    precede = { { "O868", "O1153" }, { "O868", "A1149" }, { "O868", "A5147" }, { "O868", "A4821" } },
    flightPaths = { "Freewind Post, Thousand Needles" },
  },
  {
    id = "H_05", title = "Hillsbrad Foothills", faction = "Horde", zones = { HILLSBRAD },
    minLevel = 28, maxLevel = 30, levelSlack = 0, levelBelow = 6, far = 1600, entry = { HILLSBRAD, 62.0, 20.0 }, endZones = { UNDERCITY },
    next = "H_06",
    -- strictLevel (QuestieDB v1.0.11) : sans lui, tranche élargie (147 mobs à farmer), 44 mobs de farm final,
    -- 188 min et une zone d'objectifs coupée sans contrainte (567 Dangerous!) ; avec lui, 176 min, aucun farm.
    strictLevel = true,
    flightPaths = { "Tarren Mill, Hillsbrad" },
    dungeons = { "City of Dalaran" },
  },
  -- Routes 30-60 (lot H, 2026-11-06) : chapitres du plan « meta paths 1-60 », reconstruits et mesurés ici
  -- (docs/routes/README.md). Ordre : H_05 -> H_06 -> ... -> H_18 -> H_21 -> H_23 -> ... -> H_30. H_19 (Marais
  -- des Chagrins 45-46 : aucune quête mesurée) et H_22 (Féralas 49-50 : aucune quête) sont supprimés ; H_20
  -- (Tanaris 47-49 : 5 quêtes, ~700 mobs de farm) est hors chaîne, Tanaris I (H_16) prend ses quêtes hautes.
  -- Chaque chapitre est sur un seul continent. Tranches contiguës, levelBelow = 8, far = 1600, widen = false
  -- (sauf H_16). Entrées : maîtres de vol ou donneurs de QuestieDB.
  -- Optimisation du 2026-11-07 (chaque changement mesuré au simulateur, journal dans le rapport du lot Horde) :
  -- capitales sur le trajet (Orgrimmar en H_07 et H_25, Fossoyeuse en H_29) et en endZones (livraisons,
  -- rendus des livres d'Owen Thadd), Rempart de Tirisfal en H_29, tranches 40-49 rééquilibrées (Strangleronce II
  -- 40-42, Tanaris 44-45, Féralas 45-47, Strangleronce III 47-49), Désolace II remplacée par Âprefange II
  -- (chaîne de Brackenwall 43-45). Ordre des zones inchangé : les essais avec moins de traversées
  -- (Âprefange avant Strangleronce, Strangleronce I avant Mille pointes, Silithus avant les Maleterres) coûtent
  -- +10 à +97 min.
  {
    id = "H_06", title = "Alterac Mountains and Arathi Highlands", faction = "Horde", zones = { HILLSBRAD, ALTERAC, ARATHI },
    minLevel = 30, maxLevel = 32, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { HILLSBRAD, 60.14, 18.62 }, endZones = { UNDERCITY }, next = "H_07",
    flightPaths = { "Hammerfall, Arathi" },
    dungeons = { "City of Dalaran", "Scarlet Monastery" },
    -- plan « meta paths » : accroches de Tarren Mill (Prison Break In, Stone Tokens, Infiltration,
    -- Dalaran Patrols, The Hammer May Fall) ; lot L : +53 min sans ce forçage (gardé)
    force = { [544] = true, [556] = true, [533] = true, [545] = true, [676] = true },
  },
  {
    id = "H_07", title = "Thousand Needles", faction = "Horde", zones = { NEEDLES, BARRENS, ORGRIMMAR },
    bounds = { [BARRENS] = { 44, 26, 53, 32 } }, -- Carrefour et Bastion : The Swarm Grows, The Kolkar of Desolace
    -- Orgrimmar (zeppelin depuis Fossoyeuse) : The Swarm Grows (1146) et Alliance Relations (1432), têtes des
    -- chaînes des Mille pointes et de Désolace. Mesuré : -19 min, -154 mobs (H_07 et H_08 sans farm).
    -- (1145 The Swarm Grows et 1362 The Kolkar of Desolace, forcées jusqu'au lot L : forçage retiré, mesuré identique)
    endZones = { ORGRIMMAR, DESOLACE },
    minLevel = 32, maxLevel = 33, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { NEEDLES, 45.14, 49.11 }, next = "H_08",
  },
  {
    id = "H_08", title = "Desolace", faction = "Horde", zones = { DESOLACE }, endZones = { ORGRIMMAR, THUNDERBLUFF },
    minLevel = 33, maxLevel = 35, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { DESOLACE, 21.60, 74.13 }, next = "H_09",
    flightPaths = { "Shadowprey Village, Desolace" },
    dungeons = { "Maraudon" },
  },
  {
    id = "H_09", title = "Stranglethorn Vale", faction = "Horde", zones = { STV },
    minLevel = 35, maxLevel = 37, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { STV, 32.54, 29.35 }, next = "H_10",
    flightPaths = { "Grom'gol, Stranglethorn" },
    dungeons = { "Gnomeregan" },
  },
  {
    id = "H_10", title = "Dustwallow Marsh", faction = "Horde", zones = { DUSTWALLOW },
    minLevel = 37, maxLevel = 38, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { DUSTWALLOW, 35.56, 31.88 }, next = "H_11",
    flightPaths = { "Brackenwall Village, Dustwallow Marsh" },
    dungeons = { "Razorfen Downs" },
  },
  {
    id = "H_11", title = "Arathi Highlands", faction = "Horde", zones = { ARATHI, HILLSBRAD, ALTERAC },
    minLevel = 38, maxLevel = 39, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { ARATHI, 73.02, 32.70 }, next = "H_12",
    -- The Crown of Will (518-521, Tarren Mill) : objectifs dans les Montagnes d'Alterac
    dungeons = { "Scarlet Monastery" },
  },
  {
    id = "H_12", title = "Badlands", faction = "Horde", zones = { BADLANDS },
    minLevel = 39, maxLevel = 40, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { BADLANDS, 3.99, 44.78 }, next = "H_13",
    flightPaths = { "Kargath, Badlands" },
    dungeons = { "Uldaman" },
  },
  {
    id = "H_13", title = "Stranglethorn Vale", faction = "Horde", zones = { STV },
    -- 40-42 (au lieu de 40-41) : 12 quêtes 37-44 de Strangleronce y étaient écartées « level band reached », et
    -- le Marais des Chagrins (42-43) ne farme plus. Mesuré : -55 min, -208 mobs.
    minLevel = 40, maxLevel = 42, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { STV, 32.54, 29.35 }, next = "H_14",
  },
  {
    id = "H_14", title = "Swamp of Sorrows", faction = "Horde", zones = { SWAMP },
    minLevel = 42, maxLevel = 43, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { SWAMP, 46.07, 54.83 }, next = "H_15",
    flightPaths = { "Stonard, Swamp of Sorrows" },
    dungeons = { "The Temple of Atal'Hakkar" },
  },
  {
    -- Âprefange II (au lieu de Désolace II : 7 quêtes, 361 mobs de farm) : chaîne de Brackenwall 43-45
    -- (The Brood of Onyxia 1169-1172, Mok'Morokk, Tharg). Mesuré : -98 mobs, temps égal.
    id = "H_15", title = "Dustwallow Marsh", faction = "Horde", zones = { DUSTWALLOW }, endZones = { ORGRIMMAR, THUNDERBLUFF },
    minLevel = 43, maxLevel = 44, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { DUSTWALLOW, 35.56, 31.88 }, next = "H_16",
  },
  {
    id = "H_16", title = "Tanaris", faction = "Horde", zones = { TANARIS }, endZones = { ORGRIMMAR, THUNDERBLUFF },
    -- 44-45 (au lieu de 44-46) : Féralas prend 45-47. Mesuré : -20 min, -90 mobs.
    minLevel = 44, maxLevel = 45, levelSlack = 0, levelBelow = 8, far = 1600, entry = { TANARIS, 51.60, 25.44 }, next = "H_17",
    flightPaths = { "Gadgetzan, Tanaris" },
    dungeons = { "Zul'Farrak" },
    -- Gahz'ridian (3161, rendement bas) et The Thirsty Goblin (2605, loin de Gadgetzan) : forcées au lot Horde (-8 min,
    -- -96 mobs), forçage retiré au lot L (mesuré après les corrections du simulateur : Horde 1-60 -10 min, -1 quête,
    -- +43 mobs).
  },
  {
    id = "H_17", title = "Feralas", faction = "Horde", zones = { FERALAS }, endZones = { ORGRIMMAR, THUNDERBLUFF },
    minLevel = 45, maxLevel = 47, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { FERALAS, 75.45, 44.36 }, next = "H_18",
    flightPaths = { "Camp Mojache, Feralas" },
    force = { [3062] = true }, -- Dark Heart, à plus de 1 600 yd de Camp Mojache. Mesuré : -4 min, -24 mobs (lot L : +10 min sans).
  },
  {
    id = "H_18", title = "Stranglethorn Vale", faction = "Horde", zones = { STV },
    -- 47-49 et Hinterlands 49-51 (au lieu de 47-48 et 48-51). Mesuré : -26 min, -69 mobs.
    minLevel = 47, maxLevel = 49, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { STV, 26.87, 77.10 }, next = "H_21",
    flightPaths = { "Booty Bay, Stranglethorn" },
  },
  {
    id = "H_21", title = "The Hinterlands", faction = "Horde", zones = { HINTERLANDS },
    -- rendus au passage à Tarren Mill (Venom Bottles 2933) et à Fossoyeuse (Rin'ji's Secret 2782, livres)
    endZones = { HILLSBRAD, UNDERCITY },
    minLevel = 49, maxLevel = 51, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { HINTERLANDS, 81.70, 81.76 }, next = "H_23",
    flightPaths = { "Revantusk Village, The Hinterlands" },
    -- The Final Message to the Wildhammer (7843, écartée « far » : puits d'Aerie Peak) forcée jusqu'au lot L ;
    -- forçage retiré (mesuré après les corrections du simulateur : Horde 1-60 -4 min, -1 quête, +22 mobs)
  },
  {
    id = "H_23", title = "Blasted Lands", faction = "Horde", zones = { BLASTED },
    minLevel = 51, maxLevel = 52, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { BLASTED, 50.55, 14.20 }, next = "H_24",
  },
  {
    id = "H_24", title = "Searing Gorge and Burning Steppes", faction = "Horde", zones = { SEARING, BURNING },
    endZones = { UNDERCITY }, -- livres d'Owen Thadd (81953, 81955). Mesuré : -30 mobs, temps égal.
    minLevel = 52, maxLevel = 53, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { SEARING, 34.84, 30.87 }, next = "H_25",
    flightPaths = { "Thorium Point, Searing Gorge", "Flame Crest, Burning Steppes" },
    dungeons = { "Blackrock Depths" },
    -- 3441 et 3453 : récits de Kalaran Windblade (drapeau « event » dans QuestieDB), têtes de la chaîne
    -- The Flawless Flame -> Trinkets... (3442-3481). Mesuré : -11 min, -177 mobs. Forcées jusqu'au lot L, candidates
    -- ordinaires depuis (forçage retiré, mesuré identique). A Taste of Flame 4023, Tablet of the Seven 4296 et Broodling
    -- Essence 4726, forcées par le plan « meta paths » : forçage retiré au lot L (mesuré identique).
  },
  {
    -- Orgrimmar (zeppelin depuis Grom'gol) : Betrayed (3504) ; livraisons rendues à Orgrimmar et aux
    -- Pitons-du-Tonnerre (3507, 3518, 3541). Mesuré : -14 min, -117 mobs.
    id = "H_25", title = "Azshara", faction = "Horde", zones = { AZSHARA, ORGRIMMAR }, endZones = { ORGRIMMAR, THUNDERBLUFF },
    minLevel = 53, maxLevel = 54, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { AZSHARA, 21.96, 49.62 }, next = "H_26",
    flightPaths = { "Valormok, Azshara" },
  },
  {
    id = "H_26", title = "Felwood", faction = "Horde", zones = { FELWOOD }, endZones = { ORGRIMMAR, THUNDERBLUFF },
    minLevel = 54, maxLevel = 55, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { FELWOOD, 34.44, 53.96 }, next = "H_27",
    flightPaths = { "Bloodvenom Post, Felwood" },
  },
  {
    id = "H_27", title = "Un'Goro Crater", faction = "Horde", zones = { UNGORO }, endZones = { ORGRIMMAR, THUNDERBLUFF },
    minLevel = 55, maxLevel = 56, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { UNGORO, 45.23, 5.83 }, next = "H_28",
    flightPaths = { "Marshal's Refuge, Un'Goro Crater" },
  },
  {
    id = "H_28", title = "Felwood and Winterspring", faction = "Horde", zones = { FELWOOD, WINTERSPRING },
    minLevel = 56, maxLevel = 57, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { WINTERSPRING, 60.47, 36.30 }, next = "H_29",
    flightPaths = { "Everlook, Winterspring" },
  },
  {
    id = "H_29", title = "Western Plaguelands and Eastern Plaguelands", faction = "Horde", zones = { WPL, EPL, TIRISFAL, UNDERCITY },
    -- Rempart de Tirisfal (Derrington, Vandis, Dithers : chaîne des chaudrons 5228-5238, Scarlet Diversions,
    -- A Plague Upon Thee) et Fossoyeuse (A Call to Arms 5094, livres d'Oran Snakewrithe), au débarquement du
    -- zeppelin. Mesuré : -97 min, -512 mobs ; levelBelow = 10 (une quête basse du Rempart en plus) : -6 min.
    bounds = { [TIRISFAL] = { 78, 60, 90, 80 } },
    -- 5342 The Last Barov (suite de 5341, prise au passage pour Scholomance, jamais rendue) : écartée par la
    -- simulation depuis le lot L ; l'écart manuel est retiré (mesuré identique).
    minLevel = 57, maxLevel = 59, levelSlack = 0, levelBelow = 10, far = 1600, widen = false, entry = { WPL, 38.40, 54.05 }, next = "H_30",
    flightPaths = { "Light's Hope Chapel, Eastern Plaguelands" },
    dungeons = { "Scholomance", "Stratholme" },
  },
  {
    id = "H_30", title = "Silithus", faction = "Horde", zones = { WINTERSPRING, SILITHUS },
    minLevel = 59, maxLevel = 60, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { SILITHUS, 48.68, 36.67 },
    -- titre : Berceau-de-l'Hiver seulement traversé (pierre de foyer, vol) ; ses quêtes sont faites en H_28
    flightPaths = { "Cenarion Hold, Silithus" },
  },
  -- Hors chaîne (écrits, ni simulés ni générés)
  {
    id = "H_20", title = "Tanaris", faction = "Horde", zones = { TANARIS },
    minLevel = 47, maxLevel = 49, levelSlack = 0, levelBelow = 8, far = 1600, widen = false, entry = { TANARIS, 51.60, 25.44 }, next = "H_21",
    dungeons = { "Zul'Farrak" },
    -- comme A_20 : quêtes de Tanaris à plus de 1 600 yd de Gadgetzan (sinon 1 quête, ~700 mobs de farm)
    force = { [3161] = true, [3362] = true, [2605] = true },
  },
}

-- Recherche d'un plan par identifiant (dans toutes les factions).
function plans.find(id)
  for _, faction in ipairs({ "Alliance", "Horde" }) do
    for i, p in ipairs(plans[faction]) do if p.id == id then return p, faction, i end end
  end
end

-- Chaîne de chapitres suivie par une race donnée, du premier chapitre de départ au dernier du tronc.
function plans.pathFor(faction, race)
  return plans.pathIn(plans[faction], race)
end

-- Même chose sur une liste de plans donnée (tests).
function plans.pathIn(list, race)
  local byId = {}
  for _, p in ipairs(list) do byId[p.id] = p end
  local first
  for _, p in ipairs(list) do
    if p.races and p.minLevel == 1 then
      for _, r in ipairs(p.races) do if r == race then first = p end end
    end
    if first then break end
  end
  local path, seen = {}, {}
  local p = first
  while p and not seen[p.id] do
    seen[p.id] = true
    path[#path + 1] = p
    local nid = (p.nextByRace and p.nextByRace[race]) or p.next
    p = nid and byId[nid] or nil
  end
  return path
end

-- Genres de trajet admis dans choices[i].travel.kind (lus tels quels par le jeu).
plans.TRAVEL_KINDS = { "walk", "fly", "boat", "zeppelin", "tram", "portal", "hearth" }
-- Races de chaque faction (clés de nextByRace et de choices[i].races).
plans.RACES = {
  Alliance = { "Human", "Dwarf", "NightElf", "Gnome", "Skyborne" },
  Horde = { "Orc", "Undead", "Tauren", "Troll", "Skyborne" },
}

local function contains(list, v)
  for _, x in ipairs(list or {}) do if x == v then return true end end
  return false
end

local function sortedKeys(t)
  local keys = {}
  for k in pairs(t or {}) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  return keys
end

-- Contrôle des suites d'une table de plans { Alliance = {...}, Horde = {...} } (plans par défaut) :
-- `next` / `nextByRace` vers des chapitres connus, et `choices` (2 à 4 entrées, chapitres connus de la
-- même faction, sans doublon ni le chapitre lui-même, races de la faction, genre de trajet admis,
-- minutes entières, suite par défaut présente pour chaque race qui la suit). Renvoie la liste des
-- erreurs { id = planId, msg = "..." } (vide si tout va bien). build.lua s'arrête sur la première liste
-- non vide ; tools/validate_guides.lua applique le même contrôle aux guides générés.
function plans.validate(p)
  p = p or plans
  local errs = {}
  local function err(id, fmt, ...) errs[#errs + 1] = { id = id, msg = fmt:format(...) } end
  local byId = {}
  for _, faction in ipairs({ "Alliance", "Horde" }) do
    for _, plan in ipairs(p[faction] or {}) do
      if byId[plan.id] then err(plan.id, "duplicate chapter id") end
      byId[plan.id] = plan
    end
  end
  local kinds = table.concat(plans.TRAVEL_KINDS, ", ")
  for _, faction in ipairs({ "Alliance", "Horde" }) do
    for _, plan in ipairs(p[faction] or {}) do
      local id = plan.id
      local races = plan.races or plans.RACES[plan.faction] or {}
      if plan.next ~= nil and not byId[plan.next] then err(id, "next %q is not a known chapter", tostring(plan.next)) end
      for _, race in ipairs(sortedKeys(plan.nextByRace)) do
        local nid = plan.nextByRace[race]
        if not byId[nid] then err(id, "nextByRace.%s %q is not a known chapter", tostring(race), tostring(nid)) end
      end
      local list = plan.choices
      if list ~= nil and type(list) ~= "table" then
        err(id, "choices must be a list")
      elseif list ~= nil then
        if #list < 2 or #list > 4 then err(id, "choices has %d entries (2 to 4 expected)", #list) end
        local seen = {}
        for i, c in ipairs(list) do
          local at = ("choices[%d]"):format(i)
          if type(c) ~= "table" or type(c.id) ~= "string" or c.id == "" then
            err(id, "%s: missing id", at)
          else
            local target = byId[c.id]
            if not target then err(id, "%s: %q is not a known chapter", at, c.id)
            elseif target.faction ~= plan.faction then
              err(id, "%s: %q is a %s chapter, this one is %s", at, c.id, tostring(target.faction), tostring(plan.faction))
            end
            if c.id == id then err(id, "%s: a chapter cannot be its own choice", at) end
            if seen[c.id] then err(id, "%s: duplicate id %q", at, c.id) end
            seen[c.id] = seen[c.id] or c
            if c.races ~= nil then
              if type(c.races) ~= "table" or #c.races == 0 then err(id, "%s: races must be a non-empty list", at)
              else
                for _, r in ipairs(c.races) do
                  if not contains(races, r) then err(id, "%s: race %s does not play this chapter", at, tostring(r)) end
                end
              end
            end
            if c.label ~= nil and type(c.label) ~= "string" then err(id, "%s: label must be a string", at) end
            if c.weight ~= nil and (type(c.weight) ~= "number" or c.weight <= 0) then
              err(id, "%s: weight must be a positive number", at)
            end
            if c.travel ~= nil then
              local t = c.travel
              if type(t) ~= "table" or not contains(plans.TRAVEL_KINDS, t.kind) then
                err(id, "%s: travel.kind %s is not one of %s", at, tostring(type(t) == "table" and t.kind or t), kinds)
              elseif t.minutes ~= nil and (type(t.minutes) ~= "number" or t.minutes < 0 or t.minutes ~= math.floor(t.minutes)) then
                err(id, "%s: travel.minutes must be a whole number of minutes", at)
              end
            end
          end
        end
        -- suite par défaut : proposée à chaque race qui la suit (pathFor : nextByRace[race], sinon next)
        if plan.next == nil and plan.nextByRace == nil then
          err(id, "choices without a default successor (next or nextByRace)")
        end
        for _, race in ipairs(races) do
          local nid = (plan.nextByRace and plan.nextByRace[race]) or plan.next
          if nid ~= nil then
            local c = seen[nid]
            local field = (plan.nextByRace and plan.nextByRace[race]) and ("nextByRace." .. race) or "next"
            if not c then err(id, "default successor %s = %q is not in choices", field, tostring(nid))
            elseif c.races and type(c.races) == "table" and not contains(c.races, race) then
              err(id, "default successor %s = %q is not offered to %s (choices races)", field, tostring(nid), race)
            end
          end
        end
      end
    end
  end
  -- une erreur répétée pour plusieurs races n'est donnée qu'une fois
  local out, dup = {}, {}
  for _, e in ipairs(errs) do
    local key = e.id .. "\0" .. e.msg
    if not dup[key] then dup[key] = true; out[#out + 1] = e end
  end
  return out
end

return plans
