-- tools/routebuilder/build_dungeons.lua : table des donjons de WoW: Forever pour l'addon.
-- Lua 5.1 / LuaJIT, hors jeu, lancé depuis la racine du projet :
--   luajit tools/routebuilder/build_dungeons.lua [--db PATH] [--questie PATH] [--data DIR] [--out FILE]
--          [--date YYYY-MM-DD]
-- Lit la vue Forever de QuestieDB (Alliance puis Horde, chargeur en bac à sable qdb.lua) et écrit
-- Questify/Guides/DungeonData.lua : pour chaque donjon jusqu'au niveau ~45, sa zone, sa plage
-- de niveaux, les factions autorisées, l'entrée (uiMapID, x, y en 0-100) et, par faction, les quêtes
-- (IDs, PNJ de départ et sa position, PNJ de fin et sa position, niveaux, masque de races,
-- préquêtes). Seulement des faits (IDs, niveaux, coordonnées) : aucun texte n'est repris d'un guide.
--
-- Règles :
--   * quête de donjon = zoneOrSort égal à la zone du donjon ou à l'une de ses zones secondaires
--     (support/Forever/Zones/dungeons.lua) ; hors liste noire de Questie, hors quêtes répétables et
--     hors quêtes de classe ;
--   * quête « en ville » : PNJ (ou objet) de départ avec une position sur une carte de zone (pas dans
--     une instance), amical pour la faction et hors capitale de l'autre faction ;
--   * quête « prise dans le donjon » (inside) : commencée par un objet ramassé ou par un PNJ de
--     l'instance, rendue à un PNJ placé : l'addon n'ajoute que « faire » et « rendre », sautées tant
--     que la quête n'est pas dans le journal ;
--   * préquête « de passage » (bc) : préquête sans objectif (parler à quelqu'un) d'une quête de
--     donjon, jusqu'à 3 niveaux : l'addon peut l'enchaîner (prendre, rendre) avant la quête ;
--   * une faction n'est autorisée que si elle a au moins une quête en ville, que le donjon ne lui est
--     pas interdit (only) et que l'entrée n'est pas dans une capitale de l'autre faction.
--     Le Gouffre de Ragefeu (Orgrimmar) est donc Horde seulement.
package.path = "tools/routebuilder/?.lua;" .. package.path
local qdb = require("qdb")
local world = require("world")

---------------------------------------------------------------------------
-- Donjons retenus : clé stable (sauvegardes de l'addon), zone (AreaTable), niveaux conseillés.
-- Niveaux des donjons classiques : plages usuelles de l'outil de recherche de groupe de Classic ;
-- donjons ajoutés par Forever : plages annoncées par Blizzard. À vérifier en jeu.
-- only = seule faction autorisée, quelles que soient les données.
---------------------------------------------------------------------------
local DUNGEONS = {
  { key = "RFC", area = 2437, min = 13, max = 18, only = "Horde" },      -- Gouffre de Ragefeu (Orgrimmar)
  { key = "THANES", area = 16919, min = 13, max = 18 },                  -- The Hall of Thanes (Forever)
  { key = "LORDAERON", area = 16611, min = 15, max = 22 },               -- Ruins of Lordaeron (Forever)
  { key = "WC", area = 718, min = 17, max = 24 },                        -- Cavernes des lamentations
  { key = "DM", area = 1581, min = 17, max = 26 },                       -- Les Mortemines
  { key = "SFK", area = 209, min = 22, max = 30 },                       -- Donjon d'Ombrecroc
  { key = "BFD", area = 719, min = 24, max = 32 },                       -- Profondeurs de Brassenoire
  { key = "STOCKADE", area = 717, min = 24, max = 32, only = "Alliance" }, -- La Prison (Hurlevent)
  { key = "EXCAVATION", area = 16732, min = 24, max = 29 },              -- Excavation Site: Wetlands (Forever)
  { key = "DALARAN", area = 16544, min = 28, max = 33 },                 -- City of Dalaran (Forever)
  { key = "SM", area = 796, min = 28, max = 45 },                        -- Monastère écarlate (toutes les ailes)
  { key = "GNOMER", area = 721, min = 29, max = 38 },                    -- Gnomeregan
  { key = "RFK", area = 491, min = 29, max = 38 },                       -- Kraal de Tranchebauge
  { key = "RFD", area = 722, min = 37, max = 46 },                       -- Souilles de Tranchebauge
}

-- Entrées de secours (uiMapID, x, y) quand QuestieDB n'en donne pas : à vérifier en jeu.
local MANUAL_ENTRANCES = {
  [2437] = { 1454, 52.6, 49.0 }, [718] = { 1413, 46.0, 36.5 }, [1581] = { 1436, 42.5, 71.7 },
  [209] = { 1421, 44.8, 67.8 }, [719] = { 1440, 14.5, 14.2 }, [717] = { 1453, 52.4, 70.0 },
  [721] = { 1426, 24.3, 39.8 }, [491] = { 1413, 42.9, 90.2 }, [796] = { 1420, 82.6, 33.8 },
  [722] = { 1413, 49.0, 93.9 },
}

-- Capitales : une faction n'est jamais envoyée dans une capitale de l'autre.
local CAPITAL = { [1453] = "Alliance", [1455] = "Alliance", [1457] = "Alliance",
                  [1454] = "Horde", [1456] = "Horde", [1458] = "Horde" }
local LETTER = { Alliance = "A", Horde = "H" }
local FACTIONS = { "Alliance", "Horde" }
local MAX_BC_DEPTH = 3

---------------------------------------------------------------------------
-- Arguments
---------------------------------------------------------------------------
local function parseArgs(argv)
  local o = { db = qdb.DEFAULT_DB, questie = qdb.DEFAULT_QUESTIE, data = "tools/routebuilder/data",
              out = "Questify/Guides/DungeonData.lua", date = os.date("%Y-%m-%d") }
  local i = 1
  while i <= #argv do
    local k, v = argv[i], argv[i + 1]
    if k == "--db" then o.db = v elseif k == "--questie" then o.questie = v
    elseif k == "--data" then o.data = v elseif k == "--out" then o.out = v
    elseif k == "--date" then o.date = v
    else error("option inconnue : " .. tostring(k)) end
    i = i + 2
  end
  return o
end

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function round2(v) return math.floor(v * 100 + 0.5) / 100 end

local function hasBit(v, b) return qdb.hasBit(v or 0, b) end

-- Entrées de donjon de QuestieDB (support/Forever/Zones/dungeons.lua), lues dans le bac à sable :
-- { [areaId] = { nom, zones secondaires, zone parente, { { areaId, x, y }, ... } } }.
-- Expansions.Current = Era : les corrections Wotlk/Cata du fichier ne s'appliquent pas.
local function loadDungeonSupport(dbRoot)
  local modules = { ZoneDB = { private = {} },
                    Expansions = { Era = 1, Classic = 1, Tbc = 2, Wotlk = 3, Cata = 4, MoP = 5, Current = 1 } }
  local function get(_, name) modules[name] = modules[name] or {}; return modules[name] end
  local env = qdb.makeEnv({ QuestieLoader = { ImportModule = get, CreateModule = get },
                            UnitFactionGroup = function() return "Alliance" end }, "dungeons")
  local ok, err = pcall(qdb.runFile, dbRoot .. "/support/Forever/Zones/dungeons.lua", env)
  if not ok then
    io.stderr:write("dungeons.lua illisible : " .. tostring(err) .. "\n")
    return {}
  end
  return modules.ZoneDB.private.dungeons or {}
end

-- Première position d'une liste de spawns { [uiMapId] = { {x, y}, ... } } sur une carte de zone
-- (Type 3 : zone ou ville, jamais une instance), hors capitale de l'autre faction.
local function locate(W, spawns, faction)
  for _, m in ipairs(qdb.sortedKeys(spawns or {})) do
    local info = W.maps[m]
    local owner = CAPITAL[m]
    if info and info.type == 3 and (owner == nil or owner == faction) then
      local p = spawns[m][1]
      if p and p[1] and p[2] then return { m, round2(p[1]), round2(p[2]) } end
    end
  end
  return nil
end

-- PNJ amical (ou neutre) pour la faction, avec une position utilisable -> id, position.
local function npcLocation(W, D, ids, faction)
  for _, id in ipairs(ids or {}) do
    local n = D.npcs[id]
    local fr = n and n.friendly
    if n and (fr == nil or fr:find(LETTER[faction], 1, true)) then
      local at = locate(W, n.spawns, faction)
      if at then return id, at end
    end
  end
  return nil
end

local function objectLocation(W, D, ids, faction)
  for _, id in ipairs(ids or {}) do
    local o = D.objects[id]
    local at = o and locate(W, o.spawns, faction)
    if at then return id, at end
  end
  return nil
end

-- Quête générale utilisable par la faction : connue, nommée, ni liste noire, ni répétable, ni de classe.
local function basicOk(q, faction)
  if not q or not q.name or q.blacklisted then return false end
  if hasBit(q.specialFlags, 1) then return false end     -- répétable
  if qdb.isClassQuest(q) then return false end
  return qdb.racesAllow(q.races, qdb.FACTION_RACES[faction])
end

local function talkOnly(q)
  return #q.objectives.list == 0 and not q.triggerEnd
end

-- Entrée de données d'une quête (positions de départ et de fin, niveaux, masques, préquêtes).
local function questEntry(W, D, q, faction)
  local e = { id = q.id, name = q.name, level = q.level, reqLevel = q.reqLevel }
  if q.races and q.races ~= 0 then e.races = q.races end
  if q.classes and q.classes ~= 0 then e.classes = q.classes end
  if #q.preSingle > 0 then e.pre = q.preSingle end
  if #q.preGroup > 0 then e.preAll = q.preGroup end
  local giver, at = npcLocation(W, D, q.starters.npcs, faction)
  if giver then
    e.giver, e.at = giver, at
  else
    local obj, oat = objectLocation(W, D, q.starters.objects, faction)
    if obj then e.obj, e.at = obj, oat end
  end
  local ender, endAt = npcLocation(W, D, q.finishers.npcs, faction)
  if ender then e.ender, e.endAt = ender, endAt end
  return e
end

---------------------------------------------------------------------------
-- Quêtes d'un donjon pour une faction
---------------------------------------------------------------------------
local function collectQuests(W, D, areas, faction)
  local list, listed = {}, {}
  for _, id in ipairs(qdb.sortedKeys(D.quests)) do
    local q = D.quests[id]
    if areas[q.zoneOrSort] and basicOk(q, faction) then
      local e = questEntry(W, D, q, faction)
      if e.at then
        -- sans objectif (parler à quelqu'un) : l'addon peut l'enchaîner avant une quête qui la demande
        if talkOnly(q) then e.talk = true end
        list[#list + 1] = e; listed[id] = true
      elseif e.endAt and (#q.starters.items > 0 or #q.starters.npcs > 0 or #q.starters.objects > 0) then
        -- commencée dans le donjon (objet ramassé ou PNJ de l'instance) : seulement « faire » et « rendre »
        e.inside, e.item = true, q.starters.items[1]
        list[#list + 1] = e; listed[id] = true
      end
    end
  end
  -- Préquêtes de passage (sans objectif, PNJ placé), jusqu'à MAX_BC_DEPTH niveaux.
  local function addPre(id, depth)
    if listed[id] or depth > MAX_BC_DEPTH then return end
    local q = D.quests[id]
    if not (q and basicOk(q, faction) and talkOnly(q)) then return end
    local e = questEntry(W, D, q, faction)
    if not (e.giver and e.at) then return end
    e.bc = true
    list[#list + 1] = e; listed[id] = true
    for _, p in ipairs(q.preSingle) do addPre(p, depth + 1) end
    for _, p in ipairs(q.preGroup) do addPre(p, depth + 1) end
  end
  local n = #list
  for i = 1, n do
    local e = list[i]
    if not e.inside then
      for _, p in ipairs(e.pre or {}) do addPre(p, 1) end
      for _, p in ipairs(e.preAll or {}) do addPre(p, 1) end
    end
  end
  return list
end

---------------------------------------------------------------------------
-- Écriture
---------------------------------------------------------------------------
local function point(t) return ("{ %d, %s, %s }"):format(t[1], tostring(t[2]), tostring(t[3])) end
local function ids(t) return "{ " .. table.concat(t, ", ") .. " }" end

local function questLine(e)
  local parts = { ("id = %d"):format(e.id) }
  if e.bc then parts[#parts + 1] = "bc = true" end
  if e.talk then parts[#parts + 1] = "talk = true" end
  if e.inside then parts[#parts + 1] = "inside = true" end
  if e.item then parts[#parts + 1] = ("item = %d"):format(e.item) end
  if e.giver then parts[#parts + 1] = ("giver = %d"):format(e.giver) end
  if e.obj then parts[#parts + 1] = ("obj = %d"):format(e.obj) end
  if e.at then parts[#parts + 1] = "at = " .. point(e.at) end
  if e.ender then parts[#parts + 1] = ("ender = %d"):format(e.ender) end
  if e.endAt then parts[#parts + 1] = "endAt = " .. point(e.endAt) end
  parts[#parts + 1] = ("level = %d"):format(e.level or 0)
  parts[#parts + 1] = ("reqLevel = %d"):format(e.reqLevel or 0)
  if e.races then parts[#parts + 1] = ("races = %.0f"):format(e.races) end
  if e.classes then parts[#parts + 1] = ("classes = %d"):format(e.classes) end
  if e.pre then parts[#parts + 1] = "pre = " .. ids(e.pre) end
  if e.preAll then parts[#parts + 1] = "preAll = " .. ids(e.preAll) end
  return ("        { %s }, -- %s"):format(table.concat(parts, ", "), (tostring(e.name):gsub("[\r\n]", " ")))
end

local function main(argv)
  local o = parseArgs(argv)
  local W = world.load(o.data)
  local Ds = {}
  for _, f in ipairs(FACTIONS) do Ds[f] = qdb.load({ db = o.db, questie = o.questie, faction = f }) end
  local support = loadDungeonSupport(o.db)

  local out = {}
  for _, def in ipairs(DUNGEONS) do
    local entry = support[def.area]
    local areas = { [def.area] = true }
    for _, a in ipairs(entry and entry[2] or {}) do areas[a] = true end
    -- Entrée : QuestieDB d'abord, sinon la table manuelle (à vérifier en jeu).
    local entrance, source
    local loc = entry and entry[4] and entry[4][1]
    if type(loc) == "table" and loc[2] and loc[3] then
      local ui = Ds.Alliance.areaToUiMap(loc[1])
      if ui and W.maps[ui] and W.maps[ui].type == 3 then
        entrance, source = { ui, round2(loc[2]), round2(loc[3]) }, "questiedb"
      end
    end
    if not entrance and MANUAL_ENTRANCES[def.area] then
      entrance, source = MANUAL_ENTRANCES[def.area], "manual"
    end
    local d = { key = def.key, area = def.area, min = def.min, max = def.max,
                name = (entry and entry[1]) or Ds.Alliance.areaName[def.area] or def.key,
                entrance = entrance, source = source, quests = {}, factions = {} }
    for _, f in ipairs(FACTIONS) do
      local list = collectQuests(W, Ds[f], areas, f)
      local town = 0
      for _, e in ipairs(list) do if not e.inside and not e.bc then town = town + 1 end end
      local allowed = town > 0 and (def.only == nil or def.only == f)
      if entrance and CAPITAL[entrance[1]] and CAPITAL[entrance[1]] ~= f then allowed = false end
      if allowed then
        d.factions[#d.factions + 1] = f
        d.quests[f] = list
      end
    end
    if entrance and #d.factions > 0 then
      out[#out + 1] = d
    else
      io.stderr:write(("%s ignoré : %s\n"):format(def.key, entrance and "aucune faction" or "pas d'entrée"))
    end
  end

  local lines = {
    "local addonName, Q = ...",
    "-- Généré par tools/routebuilder/build_dungeons.lua. Ne pas modifier à la main.",
    ("-- Source : QuestieDB commit %s, généré le %s."):format(tostring(Ds.Alliance.commit), o.date),
    "-- Donjons de WoW: Forever : zone, niveaux conseillés, factions autorisées, entrée (uiMapID, x, y en 0-100,",
    "-- entranceSource = questiedb ou manual), quêtes par faction : IDs, PNJ (giver) ou objet (obj) de départ et",
    "-- position (at), PNJ de fin (ender, endAt), niveaux, masques de races et de classes, préquêtes (pre = au",
    "-- moins une, preAll = toutes). bc = préquête de passage ; talk = quête sans objectif ; inside = quête",
    "-- prise dans le donjon (objet ramassé, item, ou PNJ de l'instance) : seulement « faire » et « rendre ».",
    "-- Seulement des faits (IDs, niveaux, coordonnées) ; les noms en commentaire viennent de QuestieDB.",
    "Q.DungeonData = {",
  }
  for _, d in ipairs(out) do
    lines[#lines + 1] = ("  { key = %q, name = %q, areaId = %d, minLevel = %d, maxLevel = %d,"):format(
      d.key, d.name, d.area, d.min, d.max)
    local fq = {}
    for _, f in ipairs(d.factions) do fq[#fq + 1] = ("%q"):format(f) end
    lines[#lines + 1] = ("    factions = { %s }, entrance = %s, entranceSource = %q,"):format(
      table.concat(fq, ", "), point(d.entrance), d.source)
    lines[#lines + 1] = "    quests = {"
    for _, f in ipairs(d.factions) do
      lines[#lines + 1] = ("      %s = {"):format(f)
      for _, e in ipairs(d.quests[f]) do lines[#lines + 1] = questLine(e) end
      lines[#lines + 1] = "      },"
    end
    lines[#lines + 1] = "    },"
    lines[#lines + 1] = "  },"
    -- Résumé : clé, niveaux, factions, quêtes en ville / de passage / butin par faction, entrée.
    local counts = {}
    for _, f in ipairs(FACTIONS) do
      local t, b, dr = 0, 0, 0
      for _, e in ipairs(d.quests[f] or {}) do
        if e.inside then dr = dr + 1 elseif e.bc then b = b + 1 else t = t + 1 end
      end
      counts[#counts + 1] = ("%s %d+%dbc+%din"):format(f:sub(1, 1), t, b, dr)
    end
    print(("%-10s %-26s %2d-%-2d %-16s %s  entrée %s (%s)"):format(d.key, d.name, d.min, d.max,
      table.concat(d.factions, "+"), table.concat(counts, "  "), point(d.entrance), d.source))
  end
  lines[#lines + 1] = "}"
  local f = assert(io.open(o.out, "w"))
  f:write(table.concat(lines, "\n"), "\n")
  f:close()
  print("wrote " .. o.out)
end

main(arg or {})
