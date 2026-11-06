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
  },
  {
    id = "A_DwarfGnome_03", title = "Loch Modan", faction = "Alliance", races = { "Dwarf", "Gnome" },
    zones = { LOCH_MODAN, IRONFORGE }, endZones = { STORMWIND },
    minLevel = 11, maxLevel = 14, entry = { LOCH_MODAN, 33.9, 51.0 }, next = "A_DwarfGnome_04", strictLevel = true,
    flightPaths = { "Thelsamar, Loch Modan" },
    -- Fin à Stormwind : Marche de l'Ouest à pied (suite par défaut) ou Sombrivage par le bateau du port
    -- de Stormwind (A_01 commence par ce bateau). Minutes : travel.lua A_DwarfGnome_03 (guides du
    -- 2026-11-06, QuestieDB v1.0.11) ; A_DwarfGnome_04 commence dans le quartier des Nains de Stormwind
    -- (15 s de marche), Sombrivage 105 s de marche + 300 s de bateau + 44 s de marche.
    choices = {
      { id = "A_DwarfGnome_04", travel = { kind = "walk", minutes = 0 } },
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
  },
  {
    id = "A_NightElf_03", title = "Darkshore", faction = "Alliance", races = { "NightElf" },
    zones = { DARKSHORE }, minLevel = 11, maxLevel = 19, entry = { DARKSHORE, 37.0, 44.0 },
    flightPaths = { "Auberdine, Darkshore" },
    dungeons = { "Blackfathom Deeps" },
    nextByRace = { NightElf = "A_02" },
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
  },
  {
    id = "A_03", title = "Redridge Mountains and Duskwood", faction = "Alliance", zones = { REDRIDGE, DUSKWOOD },
    minLevel = 22, maxLevel = 26, levelSlack = 1, far = 1600, entry = { REDRIDGE, 30.6, 59.4 }, next = "A_04",
    flightPaths = { "Lakeshire, Redridge", "Darkshire, Duskwood" },
    dungeons = { "The Stockade" },
    optional = { [253] = "Group quest: Eliza, level 31 elite" },
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
    minLevel = 29, maxLevel = 30, levelSlack = 0, entry = { HILLSBRAD, 49.3, 52.3 },
    flightPaths = { "Southshore, Hillsbrad" },
    -- bateau Menethil -> Southshore (sinon ligne droite par-dessus la mer)
    arrive = { via = { WETLANDS, 4.9, 57.3 }, steps = {
      { "boat", WETLANDS, 4.9, 57.3, note = "Take the boat to Southshore" },
    }, time = 420 },
    dungeons = { "City of Dalaran", "Excavation Site: Wetlands" },
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
    minLevel = 12, maxLevel = 15, entry = { SILVERPINE, 43.0, 41.0 }, nextByRace = { Undead = "H_01" },
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
    flightPaths = { "Freewind Post, Thousand Needles" },
  },
  {
    id = "H_05", title = "Hillsbrad Foothills", faction = "Horde", zones = { HILLSBRAD },
    minLevel = 28, maxLevel = 30, levelSlack = 0, levelBelow = 6, far = 1600, entry = { HILLSBRAD, 62.0, 20.0 }, endZones = { UNDERCITY },
    -- strictLevel (QuestieDB v1.0.11) : sans lui, tranche élargie (147 mobs à farmer), 44 mobs de farm final,
    -- 188 min et une zone d'objectifs coupée sans contrainte (567 Dangerous!) ; avec lui, 176 min, aucun farm.
    strictLevel = true,
    flightPaths = { "Tarren Mill, Hillsbrad" },
    dungeons = { "City of Dalaran" },
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
