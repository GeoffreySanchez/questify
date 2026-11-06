-- tools/apr/apr.lua : lecture hors jeu des routes Forever d'Azeroth Pilot Reloaded (APR), pour la comparaison.
-- LuaJIT. APR est un addon libre (GPL-3.0, github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded). Ses
-- fichiers sont lus depuis un clone local (~/dev/questify/.cache/apr, hors dépôt) : rien n'est copié ni
-- redistribué, seuls des chiffres et des identifiants de quêtes sortent de la comparaison.
--
-- Bac à sable : chaque fichier de route est lu comme du texte (bytecode refusé), compilé avec loadstring et
-- exécuté avec setfenv() dans un environnement strict qui ne contient que deux bouchons, `LibStub` et `APR`
-- (énumérations, convertisseur de coordonnées factice, table `RouteQuestStepList`), plus des copies de
-- string (sans dump) et de math. Ni os, ni io, ni require, ni load*, ni pcall, ni debug, ni getfenv. Lire une
-- globale inconnue lève une erreur. L'exécution est
-- interprétée (jit.off) avec une limite d'instructions : une boucle sans fin est coupée.
--
-- apr.load{ root = <clone APR> } -> { routes = { [key] = route }, order = { key, ... }, files = n, version }
-- route = { key, file, category, faction, cond, minLevel, band = { lo, hi } | nil, mapID, next = { key, ... },
--           steps = { step, ... } }
-- step  = { index, zone, cond, accept = {id}, complete = {id}, turnin = {id}, fillers = {id}, leave = {id},
--           hearth, hearthIfAvailable, setHearth, getFP, fly, grind, dungeon, notes = { clé, ... } }

local M = {}

-- classFile du jeu, dans l'ordre des classID (1-11, sans Chevalier de la mort ni Moine).
M.CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
M.CLASS_BY_ID = { [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST",
                  [7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [11] = "DRUID" }
-- Noms de l'énumération des classes côté route (classID du jeu).
local CLASS_ENUM = { Warrior = 1, Paladin = 2, Hunter = 3, Rogue = 4, Priest = 5, ["Death Knight"] = 6,
                     Shaman = 7, Mage = 8, Warlock = 9, Monk = 10, Druid = 11, ["Demon Hunter"] = 12, Evoker = 13 }

-- Races jouables par faction (clés de Questify ; « Scourge » côté APR = « Undead » ici).
M.FACTION_RACES = {
  Alliance = { "Human", "Dwarf", "NightElf", "Gnome", "Skyborne" },
  Horde = { "Orc", "Undead", "Tauren", "Troll", "Skyborne" },
}
local RACE_ALIAS = { Scourge = "Undead" }
function M.raceKey(r) return RACE_ALIAS[r] or r end

M.INSTRUCTION_LIMIT = 200000000

------------------------------------------------------------------------------
-- Bac à sable
------------------------------------------------------------------------------
local function strict(t, name)
  return setmetatable(t, { __index = function(_, k)
    error(("sandbox(%s): unknown field '%s'"):format(name, tostring(k)), 2)
  end })
end

-- Énumération dont chaque champ vaut son propre nom (catégories, extensions, races...).
local function nameEnum()
  return setmetatable({}, { __index = function(_, k) return k end })
end

local function copy(t) local o = {}; for k, v in pairs(t) do o[k] = v end; return o end
local SAFE_STRING, SAFE_MATH = copy(string), copy(math)
SAFE_STRING.dump = nil

-- Coordonnée factice : seule la carte (uiMapID) nous sert.
local function coord(_, zone, x, y) return { map = zone, x = x, y = y } end

function M.makeEnv()
  local routes = {}
  local L = nameEnum()
  local locale = { GetLocale = function() return L end }
  local APR = strict({
    RouteQuestStepList = routes,
    EXPANSIONS = nameEnum(), GAME_VERSIONS = nameEnum(), CATEGORIES = nameEnum(),
    PREFAB_TYPES = nameEnum(), RACES = nameEnum(),
    Classes = strict((function() local c = {}; for k, v in pairs(CLASS_ENUM) do c[k] = v end; return c end)(),
                     "APR.Classes"),
    worldCoordinateConverter = strict({
      ConvertMapCoordinate = coord,
      ConvertMapTrigger = coord,
      GetMixedAreaCenter = function(_, zone) return { map = zone } end,
      GetMixedAreaRadius = function() return 0 end,
    }, "APR.worldCoordinateConverter"),
  }, "APR")
  local env = strict({ LibStub = function() return locale end, APR = APR,
                       string = SAFE_STRING, math = SAFE_MATH }, "global")
  return env, routes
end

local function readText(path)
  local f = io.open(path, "rb")
  if not f then return nil, "cannot open " .. path end
  local s = f:read("*a"); f:close()
  if s:byte(1) == 27 then return nil, "refusing precompiled bytecode: " .. path end
  return s
end
M.readText = readText

-- Exécute le texte d'un fichier de route dans l'environnement donné. -> true | nil, erreur
function M.runText(text, name, env)
  if text:byte(1) == 27 then return nil, "refusing precompiled bytecode: " .. name end
  local fn, err = loadstring(text, "=" .. name)
  if not fn then return nil, err end
  setfenv(fn, env)
  if jit and jit.off then jit.off(fn, true) end
  local limit = M.INSTRUCTION_LIMIT
  debug.sethook(function() error("instruction limit reached in " .. name, 2) end, "", limit)
  local ok, e = pcall(fn)
  debug.sethook()
  if not ok then return nil, tostring(e) end
  return true
end

------------------------------------------------------------------------------
-- Conditions (lecture statique : seuls faction, race, classe et hardcore sont connus)
------------------------------------------------------------------------------
local function className(v)
  if type(v) == "number" then return M.CLASS_BY_ID[v] end
  if type(v) == "string" then return v:upper() end
  return nil
end

local function valueMatches(expected, actual, normalize)
  if type(expected) == "table" then
    for _, v in ipairs(expected) do if normalize(v) == actual then return true end end
    return false
  end
  return normalize(expected) == actual
end

-- Champs de condition reconnus ailleurs (niveau, quêtes, objets...) : inconnus hors jeu.
M.CONDITION_FIELDS = {
  "Faction", "Race", "Class", "ClassNot", "Hardcore", "AnyOf", "AllOf", "Not", "MinLevel", "MaxLevel", "Level",
  "BeLvl", "SkipForLvl", "Gender", "Money", "VendorMoney", "EquippedItemStat", "EquippedItem", "ItemCount",
  "ClassSpec", "Zones", "OnlyInZones", "SkipInZones", "AlliedRace", "Event", "InterfaceVersion",
  "InterfaceVersionExact", "HasAchievement", "DontHaveAchievement", "HasAura", "DontHaveAura", "HasSpell",
  "DontHaveSpell", "IsQuestReadyForTurnIn", "IsQuestOnQuest", "IsQuestNotOnQuest", "ReputationLevel",
  "SkipForReputation", "IsQuestCompleted", "IsQuestUncompleted", "IsOneOfQuestsCompleted",
  "IsOneOfQuestsUncompleted", "IsQuestsCompleted", "IsQuestsUncompleted", "Skill", "SkipForPrimaryProfessions",
}

-- matches(cond, ch) -> true | false | nil (inconnu). ch = { faction, race, class } ; un champ absent de ch
-- est inconnu. Les conditions de niveau, de quêtes, d'objets... sont inconnues (nil). Les autres champs
-- de l'étape (PickUp, Coord...) sont ignorés.
local CONDITION_SET = {}
for _, f in ipairs(M.CONDITION_FIELDS) do CONDITION_SET[f] = true end

function M.matches(cond, ch)
  if type(cond) ~= "table" then return true end
  ch = ch or {}
  local anyUnknown = false
  for field, v in pairs(cond) do
    if CONDITION_SET[field] then
      local r
      if field == "Faction" then
        if ch.faction then r = (v == ch.faction) end
      elseif field == "Race" then
        if ch.race then r = valueMatches(v, ch.race, M.raceKey) end
      elseif field == "Class" then
        if ch.class then r = valueMatches(v, ch.class, className) end
      elseif field == "ClassNot" then
        if ch.class then r = not valueMatches(v, ch.class, className) end
      elseif field == "Hardcore" then
        r = (v == false) -- personnage normal (pas hardcore)
      elseif field == "AnyOf" and type(v) == "table" then
        local any, unk = false, false
        for _, alt in ipairs(v) do
          local m = M.matches(alt, ch)
          if m == true then any = true elseif m == nil then unk = true end
        end
        if any then r = true elseif not unk then r = false end
      elseif field == "AllOf" and type(v) == "table" then
        local bad, unk = false, false
        for _, alt in ipairs(v) do
          local m = M.matches(alt, ch)
          if m == false then bad = true elseif m == nil then unk = true end
        end
        if bad then r = false elseif not unk then r = true end
      elseif field == "Not" and type(v) == "table" then
        local m = M.matches(v, ch)
        if m ~= nil then r = not m end
      end
      -- r == nil : champ inconnu hors jeu (niveau, quête, objet...) ou caractéristique non fixée
      if r == false then return false end
      if r == nil then anyUnknown = true end
    end
  end
  if anyUnknown then return nil end
  return true
end

-- allows(cond, ch) : la condition n'exclut pas ce personnage (inconnu = admis).
function M.allows(cond, ch) return M.matches(cond, ch) ~= false end

-- classesFor(cond, faction, races) -> ensemble des classes admises pour au moins une des races.
function M.classesFor(cond, faction, races)
  local out = {}
  for _, c in ipairs(M.CLASSES) do
    for _, r in ipairs(races or { false }) do
      if M.allows(cond, { faction = faction, race = r or nil, class = c }) then out[c] = true; break end
    end
  end
  return out
end

------------------------------------------------------------------------------
-- Normalisation des étapes
------------------------------------------------------------------------------
local function idList(v, out)
  out = out or {}
  if type(v) == "number" then out[#out + 1] = v
  elseif type(v) == "table" then
    for _, x in ipairs(v) do if type(x) == "number" then out[#out + 1] = x end end
  end
  return out
end

-- { [questId] = { objectifs } } -> identifiants triés ; la forme liste { questId, ... } est aussi admise.
local function keyList(v, out)
  out = out or {}
  if type(v) == "number" then out[#out + 1] = v; return out end
  if type(v) ~= "table" then return out end
  if v[1] ~= nil then return idList(v, out) end
  local ks = {}
  for k in pairs(v) do if type(k) == "number" then ks[#ks + 1] = k end end
  table.sort(ks)
  for _, k in ipairs(ks) do out[#out + 1] = k end
  return out
end

local function stepZone(s)
  if type(s.Zone) == "number" then return s.Zone end
  if type(s.Coord) == "table" and type(s.Coord.map) == "number" then return s.Coord.map end
  if type(s.ZoneStepTrigger) == "table" and type(s.ZoneStepTrigger.map) == "number" then return s.ZoneStepTrigger.map end
  return nil
end

function M.normalizeStep(s, i)
  local accept = idList(s.PickUp); idList(s.PickUpDB, accept); idList(s.DropQuest, accept)
  local complete = keyList(s.Qpart); keyList(s.QpartPart, complete); keyList(s.QpartDB, complete)
  local turnin = idList(s.Done); idList(s.DoneDB, turnin)
  local leave = idList(s.LeaveQuests); idList(s.LeaveQuest, leave)
  local notes = {}
  if type(s.Note) == "table" then for _, n in ipairs(s.Note) do if type(n) == "string" then notes[#notes + 1] = n end end
  elseif type(s.Note) == "string" then notes[1] = s.Note end
  return {
    index = s._index or i,
    zone = stepZone(s),
    cond = s,
    accept = accept, complete = complete, turnin = turnin,
    fillers = keyList(s.Fillers), leave = leave,
    hearth = s.UseHS ~= nil and not s.UseHSIfAvailable,
    hearthIfAvailable = s.UseHS ~= nil and s.UseHSIfAvailable ~= nil,
    setHearth = s.SetHS ~= nil,
    getFP = s.GetFP ~= nil, fly = s.UseFlightPath ~= nil,
    grind = type(s.Grind) == "number" and s.Grind or nil,
    dungeon = s.Dungeon ~= nil or s.InstanceQuest ~= nil or s.EnterInstance ~= nil,
    notes = notes,
  }
end

local function bandOf(label)
  if type(label) ~= "string" then return nil end
  local lo, hi = label:match("%((%d+)%s*%-%s*(%d+)%)%s*$")
  if lo then return { tonumber(lo), tonumber(hi) } end
  return nil
end

function M.normalizeRoute(key, def, file, loadIndex)
  local cond = type(def.conditions) == "table" and def.conditions or {}
  local nexts = {}
  for _, n in ipairs(type(def.nextRoute) == "table" and def.nextRoute or {}) do
    if type(n) == "string" then nexts[#nexts + 1] = n
    elseif type(n) == "table" and type(n.route) == "string" then nexts[#nexts + 1] = n.route end
  end
  local steps = {}
  for i, s in ipairs(type(def.steps) == "table" and def.steps or {}) do
    if type(s) == "table" then steps[#steps + 1] = M.normalizeStep(s, i) end
  end
  return {
    key = key, file = file, loadIndex = loadIndex,
    category = type(def.category) == "string" and def.category or nil,
    faction = type(cond.Faction) == "string" and cond.Faction or nil,
    cond = cond,
    minLevel = type(cond.MinLevel) == "number" and cond.MinLevel or nil,
    band = bandOf(def.label),
    mapID = type(def.mapID) == "number" and def.mapID or nil,
    next = nexts,
    steps = steps,
  }
end

------------------------------------------------------------------------------
-- Chargement d'un clone
------------------------------------------------------------------------------
-- Liste des fichiers de route chargés par le client Forever (RouteList_Camelot.xml), dans l'ordre.
function M.routeFiles(root)
  local xml = readText(root .. "/Routes/RouteList_Camelot.xml")
  if not xml then return nil, "missing Routes/RouteList_Camelot.xml in " .. root end
  local files = {}
  for f in xml:gmatch('<Script%s+file%s*=%s*"([^"]+)"') do
    f = f:gsub("\\", "/")
    if f:match("^Routes/Forever/") then files[#files + 1] = f end
  end
  return files
end

-- Version du clone sans git : HEAD (.git/HEAD, refs, packed-refs) et étiquette qui pointe dessus.
function M.version(root)
  local gitDir = root .. "/.git"
  local head = readText(gitDir .. "/HEAD")
  if not head then return { commit = nil, tag = nil } end
  head = head:gsub("%s+$", "")
  local packed = readText(gitDir .. "/packed-refs") or ""
  local function resolve(ref)
    local loose = readText(gitDir .. "/" .. ref)
    if loose then return (loose:gsub("%s+$", "")) end
    for sha, name in packed:gmatch("(%x+) ([^\n]+)") do if name == ref then return sha end end
    return nil
  end
  local commit = head:match("^ref: (.+)$") and resolve(head:match("^ref: (.+)$")) or head
  local tags = {}
  -- étiquettes empaquetées (« ^sha » : étiquette annotée déréférencée)
  local last
  for line in (packed .. "\n"):gmatch("([^\n]*)\n") do
    local sha, name = line:match("^(%x+) refs/tags/(.+)$")
    if sha then last = name; if sha == commit then tags[#tags + 1] = name end
    else
      local peeled = line:match("^%^(%x+)$")
      if peeled and last and peeled == commit then tags[#tags + 1] = last end
    end
  end
  local p = io.popen('ls "' .. gitDir .. '/refs/tags" 2>/dev/null')
  if p then
    for name in p:lines() do
      local sha = readText(gitDir .. "/refs/tags/" .. name)
      if sha and sha:gsub("%s+$", "") == commit then tags[#tags + 1] = name end
    end
    p:close()
  end
  table.sort(tags)
  return { commit = commit, tag = tags[#tags] }
end

-- load{ root, files = { chemin relatif, ... } | nil } -> données APR normalisées
function M.load(opts)
  local root = assert(opts.root, "apr.load: root")
  local files = opts.files
  if not files then
    local err
    files, err = M.routeFiles(root)
    if not files then error(err) end
  end
  local out = { routes = {}, order = {}, files = 0, version = M.version(root) }
  for _, rel in ipairs(files) do
    local text, err = readText(root .. "/" .. rel)
    if not text then error(err) end
    local env, defs = M.makeEnv()
    local ok, e = M.runText(text, rel, env)
    if not ok then error(e) end
    out.files = out.files + 1
    local keys = {}
    for k in pairs(defs) do if type(k) == "string" then keys[#keys + 1] = k end end
    table.sort(keys)
    for _, k in ipairs(keys) do
      if type(defs[k]) == "table" and not out.routes[k] then
        out.order[#out.order + 1] = k
        out.routes[k] = M.normalizeRoute(k, defs[k], rel, #out.order)
      end
    end
  end
  return out
end

------------------------------------------------------------------------------
-- Ordre de jeu des routes : graphe nextRoute, tri topologique (niveau puis ordre de chargement à égalité)
------------------------------------------------------------------------------
local function levelKey(r) return (r.band and r.band[1]) or r.minLevel or 0 end

function M.playOrder(data)
  local indeg, keys = {}, {}
  for _, k in ipairs(data.order) do indeg[k] = 0; keys[#keys + 1] = k end
  for _, k in ipairs(keys) do
    for _, n in ipairs(data.routes[k].next) do if indeg[n] then indeg[n] = indeg[n] + 1 end end
  end
  local function better(a, b)
    local ra, rb = data.routes[a], data.routes[b]
    if levelKey(ra) ~= levelKey(rb) then return levelKey(ra) < levelKey(rb) end
    return ra.loadIndex < rb.loadIndex
  end
  local rank, done, n = {}, {}, 0
  while n < #keys do
    local pick
    for _, k in ipairs(keys) do
      if not done[k] and indeg[k] == 0 and (not pick or better(k, pick)) then pick = k end
    end
    if not pick then -- cycle : on le casse au plus bas niveau
      for _, k in ipairs(keys) do if not done[k] and (not pick or better(k, pick)) then pick = k end end
    end
    done[pick] = true; n = n + 1; rank[pick] = n
    for _, nx in ipairs(data.routes[pick].next) do if indeg[nx] then indeg[nx] = indeg[nx] - 1 end end
  end
  return rank
end

return M
