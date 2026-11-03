-- tools/routebuilder/qdb.lua : chargeur hors jeu de QuestieDB (vue Forever) pour le générateur.
-- Lua 5.1 / LuaJIT. Chaque fichier tiers est lu comme du texte (bytecode refusé) et exécuté avec
-- setfenv() dans un environnement minimal et strict : ni os, ni io, ni require, ni load*, ni dofile,
-- ni debug, ni getfenv. Les chaînes de données `return {...}` sont exécutées dans un environnement vide.
--
-- Vue Forever = données Era converties + couches de corrections Forever (dont les ~988 nouvelles
-- quêtes de src/corrections/Forever/generated/foreverBaseQuest.lua), opérations d'ajout / retrait de
-- tables, puis liste noire de Questie.
--
-- qdb.load{ db = <racine QuestieDB>, faction = "Alliance"|"Horde", questie = <racine Questie>|nil } -> D

local qdb = {}

-- Copies locales de QuestieDB et de Questie dans <racine du projet>/.cache (décision du contrôleur :
-- le bloc-notes de session peut disparaître). La racine est déduite de l'emplacement de ce fichier
-- (tools/routebuilder/qdb.lua) ; à défaut, le dossier courant.
local function projectRoot()
  local src = debug and debug.getinfo and debug.getinfo(1, "S").source or ""
  local dir = src:match("^@(.*)[/\\]tools[/\\]routebuilder[/\\]qdb%.lua$")
  if dir == nil then return "." end
  if dir == "" then return "." end
  return dir
end
local CACHE = projectRoot() .. "/.cache"
qdb.DEFAULT_DB = CACHE .. "/questiedb"
qdb.DEFAULT_QUESTIE = CACHE .. "/questie"

------------------------------------------------------------------------------
-- Bac à sable
------------------------------------------------------------------------------
local function shallowCopy(t) local o = {}; for k, v in pairs(t) do o[k] = v end; return o end

local SAFE_STRING, SAFE_TABLE, SAFE_MATH = shallowCopy(string), shallowCopy(table), shallowCopy(math)
SAFE_STRING.dump = nil

-- Environnement strict : lire une globale inconnue lève une erreur au lieu de renvoyer nil.
function qdb.makeEnv(extra, strictName)
  local env = {
    pairs = pairs, ipairs = ipairs, next = next, type = type, tostring = tostring, tonumber = tonumber,
    select = select, unpack = unpack, error = error, assert = assert, pcall = pcall,
    setmetatable = setmetatable, rawget = rawget, rawequal = rawequal,
    string = SAFE_STRING, table = SAFE_TABLE, math = SAFE_MATH,
  }
  for k, v in pairs(extra or {}) do env[k] = v end
  return setmetatable(env, { __index = function(_, k)
    error(("sandbox(%s): unknown global '%s'"):format(strictName or "?", tostring(k)), 2)
  end })
end

local function readText(path)
  local f = assert(io.open(path, "rb"), "cannot open " .. path)
  local s = f:read("*a"); f:close()
  assert(s:byte(1) ~= 27, "refusing precompiled bytecode: " .. path)
  return s
end
qdb.readText = readText

-- Exécute un fichier tiers (texte) dans l'environnement donné.
function qdb.runFile(path, env, ...)
  local fn, err = loadstring(readText(path), "@" .. path)
  assert(fn, err)
  setfenv(fn, env)
  return fn(...)
end

-- Décode une chaîne `return {...}` dans un environnement VIDE. LuaJIT limite une fonction à 65536
-- constantes : le corps est découpé aux lignes `[id] = ` de premier niveau et chargé par lots.
local function loadEmpty(src, name)
  assert(src:byte(1) ~= 27, "bytecode in " .. name)
  local fn, err = loadstring(src, "=" .. name)
  assert(fn, err)
  setfenv(fn, {})
  local ok, value = pcall(fn)
  assert(ok, value)
  return value
end

function qdb.decodeData(str, name)
  assert(type(str) == "string", name .. " is not a string")
  local body = str:match("^%s*return%s*(%b{})%s*$")
  assert(body, name .. ": expected `return {...}`")
  body = body:sub(2, -2)
  local result, batch, n = {}, {}, 0
  local function flush()
    if #batch == 0 then return end
    for k, v in pairs(loadEmpty("return {" .. table.concat(batch, "\n") .. "\n}", name)) do result[k] = v end
    batch, n = {}, 0
  end
  local depth = 0
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    if n >= 2000 and depth == 0 and line:match("^%s*%[%-?%d+%]%s*=") then flush() end
    batch[#batch + 1] = line; n = n + 1
    -- la profondeur d'accolades hors chaînes et commentaires décide où une entrée se termine
    local code = line:gsub('\\.', ''):gsub('"[^"]*"', ''):gsub("'[^']*'", ''):gsub('%-%-.*$', '')
    local _, opens = code:gsub("{", ""); local _, closes = code:gsub("}", "")
    depth = depth + opens - closes
  end
  flush()
  return result
end

local function makeLoader(modules)
  local function get(_, name) modules[name] = modules[name] or {}; return modules[name] end
  return { ImportModule = get, CreateModule = get }
end

------------------------------------------------------------------------------
-- Couches de corrections (ordre d'application de QuestieDB, src/config.lua pour Forever)
------------------------------------------------------------------------------
-- { fichier, module, type, fonctions statiques, fonctions dynamiques (faction / classe), options }
local PROVIDERS = {
  { "Forever/legacy/classicQuestFixes.lua", "QuestieQuestFixes", "Quest", {"Load"}, {"LoadFactionFixes"} },
  { "Forever/legacy/classicNPCFixes.lua", "QuestieNPCFixes", "Npc", {"Load"}, {"LoadFactionFixes"} },
  { "Forever/legacy/classicItemFixes.lua", "QuestieItemFixes", "Item", {"Load"}, {"LoadFactionFixes"} },
  { "Forever/legacy/classicObjectFixes.lua", "QuestieObjectFixes", "Object", {"Load"}, {"LoadFactionFixes"} },
  { "Forever/legacy/classicQuestReputationFixes.lua", "QuestieClassicQuestReputationFixes", "Quest", {"Load"} },
  { "Forever/legacy/itemStartFixes.lua", "QuestieItemStartFixes", "Item", {"LoadAutomaticQuestStarts"}, nil,
    { noNewEntries = true, noOverwrites = true } },
  { "Forever/generated/foreverBaseNpc.lua", "ForeverBaseNpc", "Npc", {"Load"} },
  { "Forever/generated/foreverBaseObject.lua", "ForeverBaseObject", "Object", {"Load"} },
  { "Forever/generated/foreverBaseQuest.lua", "ForeverBaseQuest", "Quest", {"Load"} },
  { "Forever/generated/foreverBaseItem.lua", "ForeverBaseItem", "Item", {"Load"} },
  { "Forever/traces/foreverQuestTraces.lua", "ForeverQuestTraces", "Quest", {"Load"} },
  { "Forever/traces/foreverNpcTraces.lua", "ForeverNpcTraces", "Npc", {"Load"} },
  { "Forever/traces/foreverItemTraces.lua", "ForeverItemTraces", "Item", {"Load"} },
  { "Forever/traces/foreverObjectTraces.lua", "ForeverObjectTraces", "Object", {"Load"} },
  { "Forever/foreverQuestFixes.lua", "ForeverQuestFixes", "Quest", {"Load"}, {"LoadDynamic"} },
  { "Forever/foreverNPCFixes.lua", "ForeverNpcFixes", "Npc", {"Load"}, {"LoadDynamic"} },
  { "Forever/foreverItemFixes.lua", "ForeverItemFixes", "Item", {"Load"}, {"LoadDynamic"} },
  { "Forever/foreverObjectFixes.lua", "ForeverObjectFixes", "Object", {"Load"}, {"LoadDynamic"} },
}

-- Formes des champs (src/meta/*Meta.lua `structures`).
local STRUCT = {
  Quest = { [2]="questgivers", [3]="questgivers", [8]="stringarray", [9]="trigger", [10]="objectives",
            [12]="idarray", [13]="idarray", [14]="idarray", [15]="idarray", [16]="idarray", [18]="pair",
            [19]="pair", [20]="pair", [21]="idarray", [26]="reputationpairs", [28]="idarray",
            [29]="extraobjectives", [35]="pairs" },
  Npc = { [7]="spawnlist", [8]="waypointlist", [10]="idarray", [11]="idarray" },
  Object = { [2]="idarray", [3]="idarray", [4]="spawnlist", [7]="waypointlist" },
  Item = { [2]="idarray", [3]="idarray", [4]="idarray", [6]="idarray", [14]="idarray", [15]="idarray" },
}
local GROUPED = { questgivers = true, objectives = true, spawnlist = true, waypointlist = true }
local ATOMIC = { pair = true, trigger = true }

local function deepCopy(v)
  if type(v) ~= "table" then return v end
  local o = {}; for k, c in pairs(v) do o[k] = deepCopy(c) end; return o
end
local function deepEq(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deepEq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
local function contains(list, v) for _, x in ipairs(list or {}) do if deepEq(x, v) then return true end end end

-- Portage de TablePatch.Resolve (sans validation) : clé >= 1000 ajoute au champ clé-1000,
-- clé <= 0 retire du champ clé+1000.
local function resolve(datatype, fields, row)
  local ops
  for k, operand in pairs(fields) do
    if type(k) == "number" and (k <= 0 or k >= 1000) then
      local field = k >= 1000 and k - 1000 or k + 1000
      ops = ops or {}; ops[field] = ops[field] or {}
      ops[field][k >= 1000 and "add" or "remove"] = operand
    end
  end
  if not ops then return fields, true end
  local out = {}
  for k, v in pairs(fields) do if type(k) ~= "number" or (k > 0 and k < 1000) then out[k] = v end end
  for field, o in pairs(ops) do
    local shape = STRUCT[datatype][field]
    local add, rem = o.add or {}, o.remove or {}
    if next(add) or next(rem) then
      local result = deepCopy((row and row[field]) or {})
      local grouped = GROUPED[shape]
      local targets = grouped and result or { result }
      local adds = grouped and add or { add }
      local rems = grouped and rem or { rem }
      local touched = {}
      for g in pairs(adds) do touched[g] = true end
      for g in pairs(rems) do touched[g] = true end
      for g in pairs(touched) do
        local cur, a, r = targets[g] or {}, adds[g] or {}, rems[g] or {}
        if ATOMIC[shape] or (shape == "objectives" and g == 4) then
          if next(r) and deepEq(cur, r) then cur = {} end
          if next(a) then cur = deepCopy(a) end
        else
          local kept = {}
          for _, v in ipairs(cur) do if not contains(r, v) then kept[#kept + 1] = v end end
          for _, v in ipairs(a) do if not contains(kept, v) then kept[#kept + 1] = deepCopy(v) end end
          cur = kept
        end
        targets[g] = next(cur) and cur or nil
      end
      out[field] = grouped and targets or targets[1] or {}
    end
  end
  return out, false
end

local function mergeInto(entities, datatype, corrections, options)
  options = options or {}
  local applied = 0
  for id, fields in pairs(corrections) do
    if type(fields) == "table" then
      local row = entities[id]
      local resolved, replacementOnly = resolve(datatype, fields, row)
      if not row and not options.noNewEntries and (replacementOnly or next(resolved) ~= nil) then
        row = {}; entities[id] = row
      end
      if row then
        for k, v in pairs(resolved) do
          if type(k) == "number" and (not options.noOverwrites or row[k] == nil) then
            row[k] = v; applied = applied + 1
          end
        end
      end
    end
  end
  return applied
end

------------------------------------------------------------------------------
-- Aides
------------------------------------------------------------------------------
-- Test de bit arithmétique : les masques Forever dépassent 2^32 (Skyborne bits 32/33).
local function hasBit(mask, bitValue) return math.floor(mask / bitValue) % 2 == 1 end
qdb.hasBit = hasBit

local function sortedKeys(t)
  local ks = {}
  for k in pairs(t) do ks[#ks + 1] = k end
  table.sort(ks)
  return ks
end
qdb.sortedKeys = sortedKeys

local function nz(v) if v == 0 then return nil end; return v end

local function gitCommit(root)
  local ok, head = pcall(readText, root .. "/.git/HEAD")
  if not ok then return "unknown" end
  local ref = head:match("^ref:%s*(%S+)")
  if not ref then return (head:match("%x+") or "unknown") end
  local ok2, sha = pcall(readText, root .. "/.git/" .. ref)
  if ok2 then return sha:match("%x+") or "unknown" end
  local ok3, packed = pcall(readText, root .. "/.git/packed-refs")
  if ok3 then
    for line in packed:gmatch("[^\n]+") do
      local s, r = line:match("^(%x+)%s+(%S+)")
      if r == ref then return s end
    end
  end
  return "unknown"
end

------------------------------------------------------------------------------
-- Chargement
------------------------------------------------------------------------------
function qdb.load(opts)
  opts = opts or {}
  local root = assert(opts.db or qdb.DEFAULT_DB, "db root required")
  local faction = opts.faction
  local log = opts.log or function() end
  local function P(rel) return root .. "/" .. rel end
  local dataDir, prefix, supportDir = "data/Forever", "forever", "support/Forever"

  -- Données brutes des entités
  local ENTITY = {
    Quest = { file = "QuestDB", keys = "questKeys", data = "questData" },
    Npc = { file = "NpcDB", keys = "npcKeys", data = "npcData" },
    Item = { file = "ItemDB", keys = "itemKeys", data = "itemData" },
    Object = { file = "ObjectDB", keys = "objectKeys", data = "objectData" },
  }
  local keys, db = {}, {}
  for _, name in ipairs({ "Quest", "Npc", "Item", "Object" }) do
    local e = ENTITY[name]
    local modules = {}
    local path = P(("%s/%s%s.lua"):format(dataDir, prefix, e.file))
    qdb.runFile(path, qdb.makeEnv({ QuestieLoader = makeLoader(modules) }, name .. "DB"))
    keys[name] = assert(modules.QuestieDB[e.keys], "no keys in " .. path)
    db[name] = qdb.decodeData(modules.QuestieDB[e.data], name .. "Data")
  end
  local QK, NK, OK, IK = keys.Quest, keys.Npc, keys.Object, keys.Item
  local rawQuestIds = {}
  for id in pairs(db.Quest) do rawQuestIds[id] = true end

  -- Énumérations (src/corrections/enum/*.lua)
  local ns = {}
  for _, f in ipairs({ "constants", "items", "quests", "professions", "factions", "zones", "phases",
                       "icons", "waypoints", "expansions" }) do
    qdb.runFile(P("src/corrections/enum/" .. f .. ".lua"), qdb.makeEnv(nil, "enum/" .. f), "QuestieDB", ns)
  end
  local Enum = ns.Enum
  local function pick(name)
    if name ~= "classKeys" and name ~= "npcFlags" and Enum[name] ~= nil then return Enum[name] end
    local v = Enum.byExpansion.Forever[name]
    if v == nil then v = Enum.byExpansion.Classic[name] end
    return v
  end
  local raceKeys, classKeys, npcFlagsEnum = pick("raceKeys"), pick("classKeys"), pick("npcFlags")

  -- Corrections
  local hints = { killCreditObjectiveFirst = {}, objectObjectiveFirst = {}, itemObjectiveFirst = {},
                  eventObjectiveFirst = {}, spellObjectiveFirst = {} }
  local captured = { Quest = {}, Npc = {}, Item = {}, Object = {} }
  local corrModules
  local corrections = opts.corrections ~= false
  if corrections then
    local function authoring(k)
      local o = {}
      for name, idx in pairs(k) do o[name] = idx; o[name .. "_add"] = idx + 1000; o[name .. "_remove"] = idx - 1000 end
      return o
    end
    corrModules = {
      QuestieDB = {
        questKeys = authoring(QK), npcKeys = authoring(NK), itemKeys = authoring(IK), objectKeys = authoring(OK),
        raceKeys = raceKeys, classKeys = classKeys, sortKeys = pick("sortKeys"), specialFlags = pick("specialFlags"),
        factionIDs = pick("factionIDs"), questFlags = pick("questFlags"), npcFlags = npcFlagsEnum,
        itemClasses = pick("itemClasses"), waypointPresets = pick("waypointPresets"),
        questData = captured.Quest, npcData = captured.Npc, itemData = captured.Item, objectData = captured.Object,
      },
      ZoneDB = { zoneIDs = pick("zoneIDs") },
      QuestieProfessions = { professionKeys = pick("professionKeys"), specializationKeys = pick("specializationKeys"),
                             rankNames = pick("rankNames") },
      QuestieCorrections = hints,
      Phasing = { phases = pick("phases") },
      l10n = setmetatable({}, { __call = function(_, text) return text end }),
      Expansions = { Era = 1, Classic = 1, Tbc = 2, Wotlk = 3, Cata = 4, MoP = 5, Current = 1 },
    }
    local env = qdb.makeEnv({
      QuestieLoader = makeLoader(corrModules),
      Questie = shallowCopy(Enum.iconTypes),
      UnitFactionGroup = function() return faction end,
      UnitClassBase = function() return opts.class end,
    }, "corrections")
    for _, spec in ipairs(PROVIDERS) do qdb.runFile(P("src/corrections/" .. spec[1]), env) end
  end

  local function invoke(spec, fnName)
    local module = corrModules[spec[2]]
    local fn = module[fnName]
    if not fn then return nil end
    for _, t in pairs(captured) do for id in pairs(t) do t[id] = nil end end
    local returned = fn(module)
    local merged = {}
    for id, fields in pairs(captured[spec[3]]) do merged[id] = shallowCopy(fields) end
    if type(returned) == "table" then
      for id, fields in pairs(returned) do
        merged[id] = merged[id] or {}
        for k, v in pairs(fields) do merged[id][k] = v end
      end
    end
    return merged
  end

  if corrections then
    local total = 0
    for _, spec in ipairs(PROVIDERS) do
      for _, fnName in ipairs(spec[4]) do
        local c = invoke(spec, fnName)
        if c then total = total + mergeInto(db[spec[3]], spec[3], c, spec[6]) end
      end
    end
    log(("static corrections: %d field writes"):format(total))
  end

  -- Passe dérivée (src/derived/requiredRaces.lua) : faction déduite du PNJ de départ.
  for _, q in pairs(db.Quest) do
    local rr = q[QK.requiredRaces]
    if not rr or rr == 0 then
      local canA, canH = false, false
      local starts = q[QK.startedBy] and q[QK.startedBy][1]
      for _, id in pairs(starts or {}) do
        local npc = db.Npc[id]
        local f = npc and npc[NK.friendlyToFaction]
        if f == "A" or f == "AH" then canA = true end
        if f == "H" or f == "AH" then canH = true end
      end
      if canA ~= canH then q[QK.requiredRaces] = canA and raceKeys.ALL_ALLIANCE or raceKeys.ALL_HORDE end
    end
  end

  -- Corrections dynamiques (faction / classe), seulement quand la faction est donnée.
  if corrections and faction then
    local total = 0
    for _, spec in ipairs(PROVIDERS) do
      for _, fnName in ipairs(spec[5] or {}) do
        local c = invoke(spec, fnName)
        if c then total = total + mergeInto(db[spec[3]], spec[3], c) end
      end
    end
    log(("dynamic corrections (%s): %d field writes"):format(faction, total))
  end

  -- `[champ] = {}` est l'idiome de suppression : une table vide se relit comme nil.
  for _, entities in pairs(db) do
    for _, row in pairs(entities) do
      for k, v in pairs(row) do if type(v) == "table" and next(v) == nil then row[k] = nil end end
    end
  end

  -- Liste noire de Questie (Questie/Database/Corrections/QuestieQuestBlacklist.lua)
  local blacklist = {}
  if opts.blacklist ~= false and opts.questie then
    local modules = {
      Expansions = { Era = 1, Tbc = 2, Wotlk = 3, Cata = 4, MoP = 5, Current = 1 },
      ContentPhases = { activePhases = { TBC = 1, SoD = 1, Anniversary = 1, SoM = 1, MoP = 1 } },
    }
    local env = qdb.makeEnv({ QuestieLoader = makeLoader(modules),
      Questie = { Debug = function() end, DEBUG_DEVELOP = 0 } }, "blacklist")
    qdb.runFile(opts.questie .. "/Database/Corrections/QuestieQuestBlacklist.lua", env)
    for id, v in pairs(modules.QuestieQuestBlacklist:Load()) do if v == true then blacklist[id] = true end end
  end

  -- Zones : AreaTable ID -> UiMapID
  local zoneModules = { ZoneDB = { private = {} } }
  local zoneEnv = qdb.makeEnv({ QuestieLoader = makeLoader(zoneModules) }, "zones")
  local areaFile = P(supportDir .. "/Zones/areaIdToUiMapId.lua")
  qdb.runFile(areaFile, zoneEnv)
  qdb.runFile(P(supportDir .. "/Zones/subZoneToParentZone.lua"), zoneEnv)
  local zp = zoneModules.ZoneDB.private
  local areaToUiMap = qdb.decodeData(zp.areaIdToUiMapId, "areaIdToUiMapId")
  for a, m in pairs(qdb.decodeData(zp.areaIdToUiMapIdOverride, "areaIdToUiMapIdOverride")) do areaToUiMap[a] = m end
  local subToParent = qdb.decodeData(zp.subZoneToParentZone, "subZoneToParentZone")
  for a, p in pairs(qdb.decodeData(zp.subZoneToParentZoneOverride, "subZoneToParentZoneOverride")) do subToParent[a] = p end
  local areaName = {}
  for line in readText(areaFile):gmatch("[^\n]+") do
    local id, name = line:match("^%s*%[(%d+)%]%s*=%s*%d+,%s*%-%-%s*(.-)%s*$")
    if id then areaName[tonumber(id)] = (name:gsub("%s*%->.*$", "")) end
  end

  -- Donjons (support/Forever/Zones/dungeons.lua) : zone de donjon -> nom
  local dungeonAreas = {}
  do
    local dm = { ZoneDB = { private = {} }, Expansions = { Era = 1, Classic = 1, Tbc = 2, Wotlk = 3, Cata = 4, MoP = 5, Current = 1 } }
    local env = qdb.makeEnv({ QuestieLoader = makeLoader(dm), UnitFactionGroup = function() return faction end }, "dungeons")
    local ok = pcall(qdb.runFile, P(supportDir .. "/Zones/dungeons.lua"), env)
    local list = ok and dm.ZoneDB.private.dungeons or {}
    for area, entry in pairs(list) do
      dungeonAreas[area] = entry[1]
      for _, alt in ipairs(entry[2] or {}) do dungeonAreas[alt] = entry[1] end
    end
  end

  local function uiMapOf(area)
    local guard = 0
    while area and guard < 10 do
      local m = areaToUiMap[area]
      if m and m ~= 0 then return m end
      area = subToParent[area]
      guard = guard + 1
    end
    return nil
  end

  -- Taux de loot (Wowhead) item -> pnj -> pourcentage, plus les corrections Era explicites.
  local drops = {}
  do
    local dropModules = {}
    qdb.runFile(P(supportDir .. "/DropTables/classicItemDrops.lua"),
      qdb.makeEnv({ QuestieLoader = makeLoader(dropModules) }, "drops"))
    for item, npcs in pairs(qdb.decodeData(dropModules.QuestieClassicItemDrops.wowheadData, "wowheadData")) do
      local t = {}
      for npc, pct in pairs(npcs) do if type(pct) == "number" and pct > 0 then t[npc] = pct / 100 end end
      drops[item] = t
    end
    local corrModules2 = { DropDB = { correctionKeys = { PSERVER = -2, WOWHEAD = -1 } } }
    local ok = pcall(qdb.runFile, P(supportDir .. "/DropTables/itemDropCorrections.lua"),
      qdb.makeEnv({ QuestieLoader = makeLoader(corrModules2) }, "dropCorrections"))
    local era = ok and corrModules2.QuestieItemDropCorrections and corrModules2.QuestieItemDropCorrections.Era or {}
    for item, npcs in pairs(era) do
      for npc, pct in pairs(npcs) do
        if type(pct) == "number" and pct > 0 then
          drops[item] = drops[item] or {}
          drops[item][npc] = pct / 100
        end
      end
    end
  end

  -- XP des quêtes (support/Forever/QuestXP/xpDB-classic.lua) : [id] = {niveau, xp}
  local xp = {}
  do
    local m = {}
    qdb.runFile(P(supportDir .. "/QuestXP/xpDB-classic.lua"), qdb.makeEnv({ QuestieLoader = makeLoader(m) }, "questxp"))
    for id, v in pairs(m.QuestXP.db or {}) do xp[id] = { v[1], v[2] } end
  end

  ----------------------------------------------------------------------------
  -- Conversion aux formes de Q.QDB (Task 2), spawns indexés par uiMapID
  ----------------------------------------------------------------------------
  local function convSpawns(spawns)
    local out = {}
    for area, pts in pairs(spawns or {}) do
      local ui = uiMapOf(area)
      if ui then
        local list = out[ui] or {}
        local function add(p)
          if type(p) ~= "table" then return end
          if type(p[1]) == "table" then -- chemin de points (waypoints)
            for _, q in ipairs(p) do add(q) end
          elseif type(p[1]) == "number" and type(p[2]) == "number" and p[1] >= 0 and p[2] >= 0 then
            list[#list + 1] = { p[1], p[2] }
          end
        end
        for _, p in ipairs(pts) do add(p) end
        if #list > 0 then out[ui] = list end
      end
    end
    return out
  end

  local D = {
    quests = {}, npcs = {}, objects = {}, items = {}, xp = xp, drops = drops,
    npcFlags = {}, flightMasters = {}, innkeepers = {},
    blacklist = blacklist, newQuests = {}, dungeonAreas = dungeonAreas, areaName = areaName,
    raceKeys = raceKeys, classKeys = classKeys, npcFlagValues = npcFlagsEnum,
    faction = faction, commit = gitCommit(root), root = root,
  }
  function D.areaToUiMap(area) return uiMapOf(area) end

  for id, n in pairs(db.Npc) do
    local flags = n[NK.npcFlags] or 0
    D.npcs[id] = {
      id = id, name = n[NK.name], minLevel = n[NK.minLevel] or 0, maxLevel = n[NK.maxLevel] or 0,
      rank = n[NK.rank] or 0, spawns = convSpawns(n[NK.spawns]), waypoints = convSpawns(n[NK.waypoints]),
      friendly = n[NK.friendlyToFaction], subName = n[NK.subName], npcFlags = flags, zoneID = nz(n[NK.zoneID]),
      questStarts = n[NK.questStarts] or {}, questEnds = n[NK.questEnds] or {},
    }
    D.npcFlags[id] = flags
  end
  for id, o in pairs(db.Object) do
    D.objects[id] = { id = id, name = o[OK.name], spawns = convSpawns(o[OK.spawns]),
      questStarts = o[OK.questStarts] or {}, questEnds = o[OK.questEnds] or {}, zoneID = nz(o[OK.zoneID]) }
  end
  for id, it in pairs(db.Item) do
    D.items[id] = { id = id, name = it[IK.name], npcDrops = it[IK.npcDrops] or {}, objectDrops = it[IK.objectDrops] or {},
      itemDrops = it[IK.itemDrops] or {}, startQuest = nz(it[IK.startQuest]), questRewards = it[IK.questRewards] or {},
      vendors = it[IK.vendors] or {}, class = it[IK.class], subClass = it[IK.subClass],
      requiredLevel = it[IK.requiredLevel], itemLevel = it[IK.itemLevel] }
  end
  for id, q in pairs(db.Quest) do
    local sb, fb, obj = q[QK.startedBy] or {}, q[QK.finishedBy] or {}, q[QK.objectives] or {}
    -- `o.list` suit l'ordre des objectifs du client (même règle que QuestieDB.lua de Questie :
    -- créatures, objets du monde, objets, réputation, crédit de mort, sorts, évènement, avec les
    -- exceptions *ObjectiveFirst qui placent un type en tête). `index` = rang dans le journal du client.
    local o = { creatures = {}, killCredit = {}, objects = {}, items = {}, list = {} }
    local function push(entry, first)
      if first then table.insert(o.list, 1, entry) else o.list[#o.list + 1] = entry end
    end
    for _, c in ipairs(obj[1] or {}) do
      o.creatures[#o.creatures + 1] = c[1]
      push({ kind = "kill", id = c[1], text = c[2] })
    end
    for _, c in ipairs(obj[2] or {}) do
      o.objects[#o.objects + 1] = c[1]
      push({ kind = "object", id = c[1], text = c[2] }, hints.objectObjectiveFirst[id])
    end
    for _, c in ipairs(obj[3] or {}) do
      o.items[#o.items + 1] = c[1]
      push({ kind = "item", id = c[1], text = c[2] }, hints.itemObjectiveFirst[id])
    end
    if obj[4] then
      o.reputation = { faction = obj[4][1], value = obj[4][2] }
      push({ kind = "reputation", id = obj[4][1], value = obj[4][2] })
    end
    for _, k in ipairs(obj[5] or {}) do
      o.killCredit[#o.killCredit + 1] = { npcIds = k[1] or {}, base = k[2], text = k[3] }
      push({ kind = "killCredit", id = k[2], npcIds = k[1] or {}, text = k[3] }, hints.killCreditObjectiveFirst[id])
    end
    for _, s in ipairs(obj[6] or {}) do
      push({ kind = "spell", id = s[1], text = s[2], item = s[3] }, hints.spellObjectiveFirst[id])
    end
    local te = q[QK.triggerEnd]
    if te then push({ kind = "event", text = te[1] }, hints.eventObjectiveFirst[id]) end
    for i, entry in ipairs(o.list) do entry.index = i end
    local extra = {}
    for _, x in ipairs(q[QK.extraObjectives] or {}) do
      extra[#extra + 1] = { spawns = convSpawns(x[1]), text = x[3] }
    end
    local skill = q[QK.requiredSkill]
    D.quests[id] = {
      id = id, name = q[QK.name], level = q[QK.questLevel] or 0, reqLevel = q[QK.requiredLevel] or 0,
      races = q[QK.requiredRaces] or 0, classes = q[QK.requiredClasses] or 0,
      starters = { npcs = sb[1] or {}, objects = sb[2] or {}, items = sb[3] or {} },
      finishers = { npcs = fb[1] or {}, objects = fb[2] or {} },
      objectives = o,
      objectivesText = q[QK.objectivesText],
      triggerEnd = te and { text = te[1], spawns = convSpawns(te[2]) } or nil,
      extraObjectives = extra,
      preSingle = q[QK.preQuestSingle] or {}, preGroup = q[QK.preQuestGroup] or {},
      exclusiveTo = q[QK.exclusiveTo] or {}, childQuests = q[QK.childQuests] or {},
      inGroupWith = q[QK.inGroupWith] or {},
      next = nz(q[QK.nextQuestInChain]), breadcrumbFor = nz(q[QK.breadcrumbForQuestId]),
      breadcrumbs = q[QK.breadcrumbs] or {},
      specialFlags = q[QK.specialFlags] or 0, questFlags = q[QK.questFlags] or 0,
      requiredSkill = type(skill) == "table" and nz(skill[1]) or nil,
      requiredSpell = nz(q[QK.requiredSpell]), requiredSpecialization = nz(q[QK.requiredSpecialization]),
      requiredMinRep = q[QK.requiredMinRep], requiredMaxRep = q[QK.requiredMaxRep],
      requiredMaxLevel = nz(q[QK.requiredMaxLevel]), availableStartingWith = nz(q[QK.availableStartingWith]),
      parentQuest = nz(q[QK.parentQuest]), sourceItem = nz(q[QK.sourceItemId]),
      requiredSourceItems = q[QK.requiredSourceItems] or {},
      zoneOrSort = q[QK.zoneOrSort] or 0,
      blacklisted = blacklist[id] or false,
    }
    if not rawQuestIds[id] then D.newQuests[id] = true end
  end

  -- Maîtres de vol et aubergistes (drapeaux npcFlags de l'énumération Forever)
  local FM, INN = npcFlagsEnum.FLIGHT_MASTER, npcFlagsEnum.INNKEEPER
  for _, id in ipairs(sortedKeys(D.npcs)) do
    local n = D.npcs[id]
    if next(n.spawns) then
      if hasBit(n.npcFlags, FM) then D.flightMasters[#D.flightMasters + 1] = id end
      if hasBit(n.npcFlags, INN) then D.innkeepers[#D.innkeepers + 1] = id end
    end
  end

  -- Liste inverse : quêtes qui ont q comme pré-requis (pour les chaînes).
  D.unlocks = {}
  for _, id in ipairs(sortedKeys(D.quests)) do
    local q = D.quests[id]
    for _, p in ipairs(q.preSingle) do D.unlocks[p] = D.unlocks[p] or {}; table.insert(D.unlocks[p], id) end
    for _, p in ipairs(q.preGroup) do D.unlocks[p] = D.unlocks[p] or {}; table.insert(D.unlocks[p], id) end
  end

  return D
end

-- Masque de races de la faction (somme de bits distincts, jamais bit.band).
qdb.RACE_BITS = { Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Undead = 16, Tauren = 32, Gnome = 64, Troll = 128,
                  SkyborneA = 4294967296, SkyborneH = 8589934592 }
qdb.FACTION_RACES = {
  Alliance = { "Human", "Dwarf", "NightElf", "Gnome", "SkyborneA" },
  Horde = { "Orc", "Undead", "Tauren", "Troll", "SkyborneH" },
}
qdb.CLASS_BITS = { WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16, SHAMAN = 64, MAGE = 128,
                   WARLOCK = 256, DRUID = 1024 }

-- Classes d'un masque (noms de CLASS_BITS, ordre alphabétique).
function qdb.classList(mask)
  local out = {}
  if not mask or mask == 0 then return out end
  local names = {}
  for name in pairs(qdb.CLASS_BITS) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do if hasBit(mask, qdb.CLASS_BITS[name]) then out[#out + 1] = name end end
  return out
end

-- Quête de classe : masque limité à une ou deux classes. Un masque plus large (ex. « toutes sauf
-- Démoniste ») désigne une quête générale réservée à certaines classes.
function qdb.isClassQuest(q)
  local n = #qdb.classList(q.classes)
  return n >= 1 and n <= 2
end

-- Vrai quand le masque (0 = toutes) autorise au moins une des races données (clés de RACE_BITS).
function qdb.racesAllow(mask, raceList)
  if not mask or mask == 0 then return true end
  for _, r in ipairs(raceList) do
    local b = qdb.RACE_BITS[r]
    if b and hasBit(mask, b) then return true end
  end
  return false
end

return qdb
