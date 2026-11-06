local addonName, Q = ...

-- Registre des guides (chapitres). Format fixé par la spec § 5.2, produit par le générateur.
local Guides = {}
Q.Guides = Guides

local registry = {}
local sorted
local serial = 0   -- augmente à chaque chapitre enregistré (caches qui dépendent du registre)

local VALID = {
  accept = "quest", complete = "quest", turnin = "quest",
  ["goto"] = "point", fp = "point", sethearth = "point", boat = "point",
  hearth = "map", fly = "map",
  level = "level",
  note = "text",
  train = "none",   -- maître de classe le plus proche (étape insérée par Engine/Trainer.lua)
  trainprof = "prof", -- maître de métier le plus proche (étape insérée par Engine/Professions.lua)
  classquest = "chain", -- offre de quête de classe près du donneur (étape insérée par Engine/ClassQuestOffer.lua)
}
Guides.VALID_ACTIONS = VALID

local function isNum(v) return type(v) == "number" and v == v end

local function stringList(v)
  if v == nil then return nil end
  if type(v) == "string" then return { v } end
  if type(v) ~= "table" then return false end
  local out = {}
  for _, s in ipairs(v) do
    if type(s) ~= "string" then return false end
    out[#out + 1] = s
  end
  return out
end

-- Étapes propres à une classe : classes = { "WARLOCK", "MAGE" } (classFile du jeu, ceux de
-- Q.CLASS_BITS ; un nom seul est accepté). Absent : toutes les classes. Une étape dont `classes` ne
-- contient pas la classe du joueur n'existe pas pour lui (Engine/Progress.lua : ni entrée, ni étape
-- courante, ni progression, ni journal). À ne pas confondre avec `class` (quêtes générales réservées à
-- certaines classes, par exemple « toutes sauf Démoniste ») : l'étape reste dans la liste, passée
-- (raison « class ») pour les autres classes.
-- -> liste copiée, nil (absent) ou false, raison.
local function classList(v)
  if v == nil then return nil end
  local list = stringList(v)
  if list == false then return false, "classes must be a list of class names" end
  if #list == 0 then return false, "classes must name at least one class" end
  local known = Q.CLASS_BITS or {}
  for _, c in ipairs(list) do
    if not known[c] then return false, "unknown class '" .. c .. "' in classes" end
  end
  return list
end

-- StepForClass(step, classFile) -> vrai si l'étape existe pour cette classe (champ `classes` absent ou
-- qui la contient). Classe inconnue : seules les étapes sans `classes`.
function Guides.StepForClass(step, classFile)
  if type(step) ~= "table" or step.classes == nil then return true end
  return classFile ~= nil and Q.Util.Contains(step.classes, classFile)
end

-- Normalize(rawStep) -> step | nil, erreur
-- Forme brute : { "accept", 179 }, { "goto", 1426, 22.6, 71.4 }, { "level", 6 }, { "note", "txt" },
-- { "hearth", 1426 }, { "fly", 1453 }, plus les champs facultatifs (obj, note, race, class, classes,
-- optional, dungeon, at = {mapId, x, y}, xp, node). Une étape déjà normalisée est recopiée.
function Guides:Normalize(raw)
  if type(raw) ~= "table" then return nil, "step is not a table" end
  local action, a2, a3, a4
  if type(raw.action) == "string" then
    action = raw.action
  else
    action, a2, a3, a4 = raw[1], raw[2], raw[3], raw[4]
  end
  local kind = VALID[action]
  if not kind then return nil, "unknown action '" .. tostring(action) .. "'" end

  local step = { action = action }
  if kind == "quest" then
    local id = raw.questId or a2
    if not isNum(id) then return nil, action .. ": missing quest id" end
    step.questId = id
    if raw.obj ~= nil then
      if not isNum(raw.obj) then return nil, action .. ": obj must be a number" end
      step.obj = raw.obj
    end
  elseif kind == "point" then
    local m, x, y = raw.mapId or a2, raw.x or a3, raw.y or a4
    if not (isNum(m) and isNum(x) and isNum(y)) then return nil, action .. ": needs mapId, x, y" end
    step.mapId, step.x, step.y = m, x, y
  elseif kind == "map" then
    local m = raw.mapId or a2
    if not isNum(m) then return nil, action .. ": needs mapId" end
    step.mapId = m
  elseif kind == "level" then
    local l = raw.level or a2
    if not isNum(l) then return nil, "level: needs a number" end
    step.level = l
  elseif kind == "prof" then
    local prof = raw.prof or a2
    if type(prof) ~= "string" or prof == "" then return nil, "trainprof: needs a profession" end
    step.prof = prof
    if raw.rank ~= nil then
      if not isNum(raw.rank) then return nil, "trainprof: rank must be a number" end
      step.rank = raw.rank
    end
  elseif kind == "chain" then
    local key = raw.key or a2
    if type(key) ~= "string" or key == "" then return nil, "classquest: needs a chain key" end
    step.key = key
  elseif kind == "text" then
    local txt = raw.text or a2
    if type(txt) ~= "string" then return nil, "note: needs a text" end
    step.text = txt
  end

  if raw.note ~= nil then
    if type(raw.note) ~= "string" then return nil, action .. ": note must be a string" end
    step.note = raw.note
  end
  local race = stringList(raw.race)
  if race == false then return nil, action .. ": race must be a list of strings" end
  step.race = race
  local class = stringList(raw.class)
  if class == false then return nil, action .. ": class must be a list of strings" end
  step.class = class
  local classes, classesErr = classList(raw.classes)
  if classes == false then return nil, action .. ": " .. classesErr end
  step.classes = classes
  if raw.optional then step.optional = true end
  if raw.dungeon ~= nil then
    if type(raw.dungeon) ~= "string" then return nil, action .. ": dungeon must be a string" end
    step.dungeon = raw.dungeon
  end
  if raw.at ~= nil then
    local at = raw.at
    if type(at) ~= "table" then return nil, action .. ": at must be {mapId, x, y}" end
    local m, x, y = at.mapId or at[1], at.x or at[2], at.y or at[3]
    if not (isNum(m) and isNum(x) and isNum(y)) then return nil, action .. ": at must be {mapId, x, y}" end
    -- Les deux formes : positionnelle (comme le guide) et nommée.
    step.at = { m, x, y, mapId = m, x = x, y = y }
  end
  if raw.xp ~= nil then
    if not isNum(raw.xp) then return nil, action .. ": xp must be a number" end
    step.xp = raw.xp
  end
  -- Point de vol exact (ID TaxiNodes, le même que nodeID de C_TaxiMap), surtout sur les étapes « fly ».
  if raw.node ~= nil then
    if not isNum(raw.node) then return nil, action .. ": node must be a number" end
    step.node = raw.node
  end
  return step
end

local function invalid(id, reason)
  Q:Print(Q.L.GUIDE_INVALID, tostring(id or "?"), tostring(reason))
  return false
end

-- Choix de suite (tools/routebuilder, champ choices) : 1 à 4 entrées
--   { id = <chapitre>, races = { <raceKey>, ... }?, label = <texte>?, weight = <nombre>?,
--     travel = { kind = <"walk"|"fly"|"boat"|"zeppelin"|"tram"|"portal"|"hearth">, minutes = <nombre>? }? }
-- -> copie normalisée, nil (absent) ou false, raison.
local TRAVEL_KINDS = { walk = true, fly = true, boat = true, zeppelin = true, tram = true, portal = true,
  hearth = true }
Guides.TRAVEL_KINDS = TRAVEL_KINDS

local function choiceList(v)
  if v == nil then return nil end
  if type(v) ~= "table" then return false, "choices must be a list" end
  if #v < 1 or #v > 4 then return false, "choices must have 1 to 4 entries" end
  local out = {}
  for i, raw in ipairs(v) do
    if type(raw) ~= "table" or type(raw.id) ~= "string" or raw.id == "" then
      return false, "choices[" .. i .. "]: missing id"
    end
    local races = stringList(raw.races)
    if races == false then return false, "choices[" .. i .. "]: races must be a list of strings" end
    if raw.label ~= nil and type(raw.label) ~= "string" then return false, "choices[" .. i .. "]: label must be a string" end
    if raw.weight ~= nil and not isNum(raw.weight) then return false, "choices[" .. i .. "]: weight must be a number" end
    local travel
    if raw.travel ~= nil then
      local t = raw.travel
      if type(t) ~= "table" or not TRAVEL_KINDS[t.kind] then
        return false, "choices[" .. i .. "]: travel.kind must be walk, fly, boat, zeppelin, tram, portal or hearth"
      end
      if t.minutes ~= nil and not isNum(t.minutes) then
        return false, "choices[" .. i .. "]: travel.minutes must be a number"
      end
      travel = { kind = t.kind, minutes = t.minutes }
    end
    out[i] = { id = raw.id, races = races, label = raw.label, weight = raw.weight, travel = travel }
  end
  return out
end

-- Métriques simulées du chapitre (tools/routebuilder, champ sim) : { steps, endLevel, xpPerHour, minutes }.
local SIM_FIELDS = { "steps", "endLevel", "xpPerHour", "minutes" }

local function simTable(v)
  if v == nil then return nil end
  if type(v) ~= "table" then return false, "sim must be a table" end
  local out = {}
  for _, k in ipairs(SIM_FIELDS) do
    if v[k] ~= nil then
      if not isNum(v[k]) then return false, "sim." .. k .. " must be a number" end
      out[k] = v[k]
    end
  end
  return out
end

-- Q:RegisterGuide(def) : valide et enregistre un chapitre ; un guide invalide est ignoré
-- avec un seul message d'erreur.
function Q:RegisterGuide(def)
  if type(def) ~= "table" then return invalid(nil, "not a table") end
  local id = def.id
  if type(id) ~= "string" or id == "" then return invalid(id, "missing id") end
  if type(def.steps) ~= "table" then return invalid(id, "missing steps") end
  if def.faction ~= nil and def.faction ~= "Alliance" and def.faction ~= "Horde" then
    return invalid(id, "faction must be Alliance or Horde")
  end
  local races = stringList(def.races)
  if races == false then return invalid(id, "races must be a list of strings") end
  if def.minLevel ~= nil and not isNum(def.minLevel) then return invalid(id, "minLevel must be a number") end
  if def.maxLevel ~= nil and not isNum(def.maxLevel) then return invalid(id, "maxLevel must be a number") end
  if def.next ~= nil and type(def.next) ~= "string" then return invalid(id, "next must be a guide id") end
  if def.nextByRace ~= nil and type(def.nextByRace) ~= "table" then return invalid(id, "nextByRace must be a table") end
  local choices, choiceErr = choiceList(def.choices)
  if choices == false then return invalid(id, choiceErr) end
  local sim, simErr = simTable(def.sim)
  if sim == false then return invalid(id, simErr) end

  local steps = {}
  for i, raw in ipairs(def.steps) do
    local step, err = Guides:Normalize(raw)
    if not step then return invalid(id, "step " .. i .. ": " .. tostring(err)) end
    steps[i] = step
  end

  local guide = {}
  for k, v in pairs(def) do guide[k] = v end
  guide.steps = steps
  guide.races = races
  guide.choices = choices
  guide.sim = sim
  guide.minLevel = def.minLevel or 1
  guide.maxLevel = def.maxLevel or 61
  guide.title = def.title or id
  if registry[id] then Q:Debug("guide replaced", id) end
  registry[id] = guide
  sorted = nil
  serial = serial + 1
  return true
end

-- Serial() -> nombre qui change à chaque chapitre enregistré ou remplacé.
function Guides:Serial()
  return serial
end

function Guides:Get(id)
  if id == nil then return nil end
  return registry[id]
end

function Guides:All()
  if not sorted then
    sorted = {}
    for _, g in pairs(registry) do sorted[#sorted + 1] = g end
    table.sort(sorted, function(a, b) return a.id < b.id end)
  end
  local out = {}
  for i, g in ipairs(sorted) do out[i] = g end
  return out
end

local function racesMatch(g, raceKey)
  return g.races == nil or Q.Util.Contains(g.races, raceKey)
end

-- Ordre de préférence : chapitre réservé à la race d'abord, puis ID le plus petit.
local function better(a, b)
  local ra, rb = a.races ~= nil, b.races ~= nil
  if ra ~= rb then return ra end
  return a.id < b.id
end

-- Chapitre de départ pour un personnage.
function Guides:ForPlayer(faction, raceKey, level)
  level = level or 1
  local inBand, best
  for _, g in ipairs(self:All()) do
    if g.faction == faction and racesMatch(g, raceKey) then
      if g.minLevel <= level and level < g.maxLevel then
        if not inBand or better(g, inBand) then inBand = g end
      elseif g.minLevel <= level then
        if not best or g.minLevel > best.minLevel or (g.minLevel == best.minLevel and better(g, best)) then
          best = g
        end
      end
    end
  end
  return inBand or best
end

-- Chapitre suivant : nextByRace[raceKey], sinon next.
function Guides:Next(guide, raceKey)
  if type(guide) ~= "table" then return nil end
  local id = guide.nextByRace and raceKey and guide.nextByRace[raceKey]
  if id and registry[id] then return registry[id] end
  if guide.next then return registry[guide.next] end
  return nil
end

-- Une suite convient-elle au personnage ? Chapitre enregistré, même faction (ou sans faction), races du
-- chapitre et de l'entrée de choix. Race ou faction inconnue : pas de filtre sur ce critère.
local function eligible(target, entry, raceKey, faction)
  if not target then return false end
  if faction and target.faction and target.faction ~= faction then return false end
  if raceKey and not racesMatch(target, raceKey) then return false end
  if raceKey and entry and entry.races and not Q.Util.Contains(entry.races, raceKey) then return false end
  return true
end

---------------------------------------------------------------------------
-- Titres affichés et cartes d'un chapitre
---------------------------------------------------------------------------
-- Les titres des guides générés sont en anglais (« Westfall », « Ashenvale and Stonetalon Mountains »,
-- « Coldridge Valley »). Affichage dans la langue du client, partie par partie (« X and Y ») :
--   (a) zone connue (ZONE_MAPS) : nom de la carte donné par le jeu (C_Map.GetMapInfo) ;
--   (b) sinon titre de sous-zone traduit dans les textes du client (clé « CHAPTER:<titre> », par
--       exemple Locales/StringsUI.lua pour le français) ;
--   (c) sinon la partie telle quelle.
-- Parties jointes par L.LIST_AND ; aucune partie traduite : le titre entier, tel quel.
local ZONE_MAPS = {
  ["Ashenvale"] = 1440, ["Darkshore"] = 1439, ["Dun Morogh"] = 1426, ["Durotar"] = 1411,
  ["Duskwood"] = 1431, ["Elwynn Forest"] = 1429, ["Hillsbrad Foothills"] = 1424, ["Loch Modan"] = 1432,
  ["Mulgore"] = 1412, ["Redridge Mountains"] = 1433, ["Silverpine Forest"] = 1421,
  ["Stonetalon Mountains"] = 1442, ["Teldrassil"] = 1438, ["The Barrens"] = 1413,
  ["Thousand Needles"] = 1441, ["Tirisfal Glades"] = 1420, ["Westfall"] = 1436, ["Wetlands"] = 1437,
  ["Zephras Isle"] = 2521,
  -- zones 30-60 (uiMapID Classic, tirés de QuestieDB)
  ["Alterac Mountains"] = 1416, ["Arathi Highlands"] = 1417, ["Badlands"] = 1418, ["Blasted Lands"] = 1419,
  ["Western Plaguelands"] = 1422, ["Eastern Plaguelands"] = 1423, ["The Hinterlands"] = 1425,
  ["Searing Gorge"] = 1427, ["Burning Steppes"] = 1428, ["Stranglethorn Vale"] = 1434,
  ["Swamp of Sorrows"] = 1435, ["Desolace"] = 1443, ["Feralas"] = 1444, ["Dustwallow Marsh"] = 1445,
  ["Tanaris"] = 1446, ["Azshara"] = 1447, ["Felwood"] = 1448, ["Un'Goro Crater"] = 1449, ["Silithus"] = 1451,
  ["Winterspring"] = 1452,
}
Guides.ZONE_MAPS = ZONE_MAPS

local function guideOf(g)
  if type(g) == "table" then return g end
  return registry[g]
end

-- Nom d'une carte dans la langue du client, ou nil.
local function mapName(mapId)
  if not (C_Map and type(C_Map.GetMapInfo) == "function") then return nil end
  local ok, info = pcall(C_Map.GetMapInfo, mapId)
  if not ok or type(info) ~= "table" then return nil end
  local name = info.name
  if Q.Util and Q.Util.IsSecret and Q.Util.IsSecret(name) then return nil end
  if type(name) == "string" and name ~= "" then return name end
  return nil
end

local function splitTitle(title)
  local parts, start = {}, 1
  while true do
    local i, j = title:find(" and ", start, true)
    if not i then parts[#parts + 1] = title:sub(start); break end
    parts[#parts + 1] = title:sub(start, i - 1)
    start = j + 1
  end
  return parts
end

-- TitleParts(guide | id) -> { { text, source = "map" | "table" | "raw", mapId }, ... } : parties du
-- titre telles qu'affichées ; mapId = carte de la zone quand la partie en est une (même sans nom).
function Guides:TitleParts(g)
  g = guideOf(g)
  local out = {}
  if not g then return out end
  local title = tostring(g.title or g.id or "")
  for _, part in ipairs(splitTitle(title)) do
    local mapId = ZONE_MAPS[part]
    local name = mapId and mapName(mapId)
    if name then
      out[#out + 1] = { text = name, source = "map", mapId = mapId }
    else
      local tr = rawget(Q.L, "CHAPTER:" .. part)
      if type(tr) == "string" and tr ~= "" then
        out[#out + 1] = { text = tr, source = "table", mapId = mapId }
      else
        out[#out + 1] = { text = part, source = "raw", mapId = mapId }
      end
    end
  end
  return out
end

-- DisplayTitle(guide | id) -> titre du chapitre dans la langue du client (suivi, journal, choix de
-- suite, messages). Chapitre inconnu : l'id tel quel ; nil : "".
function Guides:DisplayTitle(g)
  if g == nil then return "" end
  local guide = guideOf(g)
  if not guide then return tostring(g) end
  local parts = self:TitleParts(guide)
  local texts, translated = {}, false
  for i, p in ipairs(parts) do
    texts[i] = p.text
    if p.source ~= "raw" then translated = true end
  end
  if not translated then return tostring(guide.title or guide.id) end
  if #texts == 1 then return texts[1] end
  local sep = " " .. tostring(rawget(Q.L, "LIST_AND") or "and") .. " "
  return table.concat(texts, sep)
end

-- StepMaps(guide | id) -> { { mapId, count }, ... } : cartes des étapes du chapitre (goto, fp, foyer,
-- bateau, at des objectifs), de la plus présente à la moins présente (égalité : plus petit id).
local stepMapsCache = setmetatable({}, { __mode = "k" })

function Guides:StepMaps(g)
  g = guideOf(g)
  if not g then return {} end
  local cached = stepMapsCache[g]
  if cached then return cached end
  local counts = {}
  for _, s in ipairs(g.steps or {}) do
    local m
    if VALID[s.action] == "point" then m = s.mapId
    elseif type(s.at) == "table" then m = s.at.mapId end
    if isNum(m) then counts[m] = (counts[m] or 0) + 1 end
  end
  local list = {}
  for m, n in pairs(counts) do list[#list + 1] = { mapId = m, count = n } end
  table.sort(list, function(a, b)
    if a.count ~= b.count then return a.count > b.count end
    return a.mapId < b.mapId
  end)
  stepMapsCache[g] = list
  return list
end

-- MainMap(guide | id) -> uiMapID de la zone du chapitre : celle de la première partie du titre si
-- c'est une zone connue, sinon la carte la plus présente dans les étapes ; nil sans information.
function Guides:MainMap(g)
  g = guideOf(g)
  if not g then return nil end
  local first = self:TitleParts(g)[1]
  if first and first.mapId then return first.mapId end
  local top = self:StepMaps(g)[1]
  return top and top.mapId or nil
end

-- Suites possibles d'un chapitre pour un personnage, dans l'ordre déclaré :
--   { { guide, entry, default } } ; entry = l'entrée de choices (nil pour la suite par défaut ajoutée) ;
--   default = vrai pour la suite par défaut (Guides:Next).
-- Sans choices : la suite par défaut seule (comme Guides:Next, sans filtre), ou une liste vide en fin de
-- route. Avec choices : les entrées qui conviennent au personnage ; la suite par défaut est ajoutée en
-- tête si elle convient et n'y est pas déjà.
function Guides:Choices(guide, raceKey, faction)
  local out = {}
  if type(guide) ~= "table" then return out end
  local def = self:Next(guide, raceKey)
  if not guide.choices then
    if def then out[1] = { guide = def, default = true } end
    return out
  end
  local seen = {}
  for _, entry in ipairs(guide.choices) do
    local target = registry[entry.id]
    if not seen[entry.id] and eligible(target, entry, raceKey, faction) then
      seen[entry.id] = true
      out[#out + 1] = { guide = target, entry = entry, default = def ~= nil and target == def }
    end
  end
  if def and not seen[def.id] and eligible(def, nil, raceKey, faction) then
    table.insert(out, 1, { guide = def, default = true })
  end
  return out
end
