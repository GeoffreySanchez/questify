-- tools/talentbuilds/build.lua : génère Questify/Data/TalentBuilds.lua (builds de talents fournis).
--
-- Usage (depuis la racine du projet) :
--   luajit tools/talentbuilds/build.lua [--out FICHIER] [--raw DOSSIER]
--
-- Sources lues (le dossier raw/ n'est jamais modifié ; dossiers absents ou vides acceptés) :
--   raw/icyveins/capture-*.txt   relevé du calculateur Icy Veins (voir capture.js et README.md)
--   raw/wowhead/*.json, raw/questify/*.json
--       { "source", "class", "spec", "kind": "leveling"|"dungeon"|"pvp"|"raid", "url", "date", "orderSpells": [spellID…] }
-- Un build n'est livré que s'il passe Q.Builds:Validate sur la forme de l'arbre de sa classe ; les autres
-- sont affichés avec la raison. Sortie déterministe (clés triées).

local root = (arg and arg[0] or ""):match("^(.*)/tools/talentbuilds/build%.lua$") or "."

local function parseArgs(argv)
  local o = { out = root .. "/Questify/Data/TalentBuilds.lua", raw = root .. "/tools/talentbuilds/raw" }
  local i = 1
  while i <= #argv do
    if argv[i] == "--out" then o.out = argv[i + 1]; i = i + 2
    elseif argv[i] == "--raw" then o.raw = argv[i + 1]; i = i + 2
    else error("argument inconnu : " .. tostring(argv[i])) end
  end
  return o
end

local opts = parseArgs(arg or {})

-- Moteur de l'addon (fonctions pures) chargé hors jeu.
local makeKey = dofile(root .. "/tools/talentbuilds/keys.lua")
local Repair = dofile(root .. "/tools/talentbuilds/repair.lua")
local Q = { Util = { IsSecret = function() return false end } }
assert(loadfile(root .. "/Questify/Engine/TalentTree.lua"))("Questify", Q)
assert(loadfile(root .. "/Questify/Engine/Builds.lua"))("Questify", Q)

---------------------------------------------------------------------------
-- Spécialisations. Le DB2 ChrSpecialization de Forever (build 1.60.1.70707, tools/routebuilder/data/ChrSpecialization.csv)
-- ne contient que les lignes de classe : aucune spécialisation. Les specID sont donc ceux de la
-- branche Mainline (les mêmes que tests/mock_ext_specrole.lua). À vérifier en jeu (voir README.md).
---------------------------------------------------------------------------
local SPECS = {
  DRUID = {
    balance = { 102, "Balance", "Équilibre" }, feral = { 103, "Feral", "Farouche" },
    ["feral-tank"] = { 103, "Feral (Tank)", "Farouche (tank)" },
    restoration = { 105, "Restoration", "Restauration" } },
  HUNTER = {
    ["beast-mastery"] = { 253, "Beast Mastery", "Maîtrise des bêtes" },
    marksmanship = { 254, "Marksmanship", "Précision" }, survival = { 255, "Survival", "Survie" } },
  MAGE = {
    arcane = { 62, "Arcane", "Arcanes" }, fire = { 63, "Fire", "Feu" }, frost = { 64, "Frost", "Givre" } },
  PALADIN = {
    holy = { 65, "Holy", "Sacré" }, protection = { 66, "Protection", "Protection" },
    retribution = { 70, "Retribution", "Vindicte" } },
  PRIEST = {
    discipline = { 256, "Discipline", "Discipline" }, holy = { 257, "Holy", "Sacré" },
    shadow = { 258, "Shadow", "Ombre" } },
  ROGUE = {
    assassination = { 259, "Assassination", "Assassinat" }, combat = { 260, "Combat", "Combat" },
    subtlety = { 261, "Subtlety", "Finesse" } },
  SHAMAN = {
    elemental = { 262, "Elemental", "Élémentaire" }, enhancement = { 263, "Enhancement", "Amélioration" },
    restoration = { 264, "Restoration", "Restauration" } },
  WARLOCK = {
    affliction = { 265, "Affliction", "Affliction" }, demonology = { 266, "Demonology", "Démonologie" },
    destruction = { 267, "Destruction", "Destruction" } },
  WARRIOR = {
    arms = { 71, "Arms", "Armes" }, fury = { 72, "Fury", "Fureur" }, protection = { 73, "Protection", "Protection" } },
}

local KINDS = {
  leveling = { "Leveling", "Leveling" },
  dungeon = { "Dungeon", "Donjon" },
  pvp = { "PvP", "PvP" },
  raid = { "Raid", "Raid" },
}

-- Version du calculateur Icy Veins dont les index correspondent à la table T relevée (R11) : un lien
-- d'une autre version peut désigner d'autres talents, il est exclu.
local CALC_VERSION = "70755-d1899b7d"

-- Ordre des sources pour départager les variantes d'une même spécialisation (clé = nom en minuscules).
local SOURCE_RANK = { ["icy veins"] = 1, wowhead = 2, questify = 3 }

---------------------------------------------------------------------------
-- Utilitaires
---------------------------------------------------------------------------
local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local function listFiles(dir, pattern)
  local out = {}
  local p = io.popen('ls "' .. dir .. '" 2>/dev/null')
  if not p then return out end
  for name in p:lines() do
    if name:match(pattern) then out[#out + 1] = dir .. "/" .. name end
  end
  p:close()
  table.sort(out)
  return out
end

local MONTHS = { Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6, Jul = 7, Aug = 8, Sep = 9, Oct = 10,
  Nov = 11, Dec = 12 }

local function isoDate(text)
  local m, d, y = text:match("^(%a%a%a)-(%d+)-(%d%d%d%d)$")
  if m and MONTHS[m] then return string.format("%04d-%02d-%02d", tonumber(y), MONTHS[m], tonumber(d)) end
  if text:match("^%d%d%d%d%-%d%d%-%d%d$") then return text end
  return nil
end

-- Lecteur JSON strict et minimal : objets, tableaux, chaînes, nombres, true/false/null. Pas de loadstring.
local function parseJSON(text)
  local pos = 1
  local function fail(msg) error("JSON invalide à l'offset " .. pos .. " : " .. msg, 0) end
  local function skip() pos = text:find("[^ \t\r\n]", pos) or #text + 1 end
  local value
  local function str()
    pos = pos + 1
    local buf = {}
    while true do
      local c = text:sub(pos, pos)
      if c == "" then fail("chaîne non terminée") end
      if c == '"' then pos = pos + 1; return table.concat(buf) end
      if c == "\\" then
        local e = text:sub(pos + 1, pos + 1)
        local map = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
        if map[e] then buf[#buf + 1] = map[e]; pos = pos + 2
        elseif e == "u" then
          local hex = text:match("^%x%x%x%x", pos + 2)
          if not hex then fail("séquence \\u") end
          local cp = tonumber(hex, 16)
          if cp < 0x80 then buf[#buf + 1] = string.char(cp)
          elseif cp < 0x800 then buf[#buf + 1] = string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
          else buf[#buf + 1] = string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64) end
          pos = pos + 6
        else fail("échappement inconnu") end
      elseif c:byte() < 32 then fail("caractère de contrôle")
      else buf[#buf + 1] = c; pos = pos + 1 end
    end
  end
  function value()
    skip()
    local c = text:sub(pos, pos)
    if c == "{" then
      local obj = {}
      pos = pos + 1; skip()
      if text:sub(pos, pos) == "}" then pos = pos + 1; return obj end
      while true do
        skip()
        if text:sub(pos, pos) ~= '"' then fail("clé attendue") end
        local k = str(); skip()
        if text:sub(pos, pos) ~= ":" then fail("':' attendu") end
        pos = pos + 1
        obj[k] = value(); skip()
        local d = text:sub(pos, pos); pos = pos + 1
        if d == "}" then return obj end
        if d ~= "," then fail("',' ou '}' attendu") end
      end
    elseif c == "[" then
      local arr = {}
      pos = pos + 1; skip()
      if text:sub(pos, pos) == "]" then pos = pos + 1; return arr end
      while true do
        arr[#arr + 1] = value(); skip()
        local d = text:sub(pos, pos); pos = pos + 1
        if d == "]" then return arr end
        if d ~= "," then fail("',' ou ']' attendu") end
      end
    elseif c == '"' then return str()
    elseif text:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
    elseif text:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
    elseif text:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
    else
      local n = text:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
      if not n or n == "" then fail("valeur inattendue") end
      pos = pos + #n
      return tonumber(n) or fail("nombre invalide")
    end
  end
  local v = value()
  skip()
  if pos <= #text then fail("texte après la valeur") end
  return v
end

---------------------------------------------------------------------------
-- Relevé Icy Veins
---------------------------------------------------------------------------
local tables = {}  -- [class] = { [char] = { tree, slot, max, spell, requiredSlot } }
local shapes = {}  -- [class] = { [spellID] = { group, tier, col, maxRanks, requires = { spellID } } }
local indexes = {} -- [class] = { [char] = spellID }
local candidates = {}
local rejected = {}

local function reject(label, reason) rejected[#rejected + 1] = label .. " : " .. reason end

local function buildShape(class, entries)
  local shape, index, bySlot = {}, {}, {}
  for char, e in pairs(entries) do
    bySlot[e.tree .. ":" .. e.slot] = e
  end
  for char, e in pairs(entries) do
    if shape[e.spell] then error(class .. " : spellID en double " .. e.spell) end
    local s = { group = e.tree + 1, tier = math.floor(e.slot / 4) + 1, col = e.slot % 4 + 1, maxRanks = e.max,
      requires = {} }
    if e.requiredSlot then
      local req = bySlot[e.tree .. ":" .. e.requiredSlot]
      if not req then error(class .. " : slot requis introuvable pour " .. e.spell) end
      s.requires[1] = req.spell
    end
    shape[e.spell] = s
    index[char] = e.spell
  end
  return shape, index
end

local function loadIcyVeins()
  local pages = {}
  for _, path in ipairs(listFiles(opts.raw .. "/icyveins", "%.txt$")) do
    for line in (readFile(path) or ""):gmatch("[^\r\n]+") do
      local kind, class, rest = line:match("^([TB]) (%u+) (.*)$")
      if kind == "T" then
        local entries = {}
        for tok in rest:gmatch("%S+") do
          local id, tree, slot, max, spell, req = tok:match("^(%w):(%d):(%d+):(%d+):(%d+):(%d*)$")
          if not id then error("ligne T illisible : " .. tok) end
          entries[id] = { tree = tonumber(tree), slot = tonumber(slot), max = tonumber(max),
            spell = tonumber(spell), requiredSlot = req ~= "" and tonumber(req) or nil }
        end
        tables[class] = entries
      elseif kind == "B" then
        local page, date, order, suffix = rest:match("^(%S+) (%S+) (%S+)~(%S+)$")
        if not page then error("ligne B illisible : " .. line) end
        pages[#pages + 1] = { class = class, page = page, date = date, order = order, suffix = suffix }
      end
    end
  end
  for class, entries in pairs(tables) do shapes[class], indexes[class] = buildShape(class, entries) end
  for _, p in ipairs(pages) do
    local label = "Icy Veins " .. p.page
    local specKey = p.page:match("^(.-)%-" .. p.class:lower() .. "%-leveling$")
    local spec = specKey and SPECS[p.class] and SPECS[p.class][specKey]
    local iso = isoDate(p.date)
    if not spec then reject(label, "spécialisation inconnue")
    elseif not iso then reject(label, "date illisible " .. p.date)
    elseif p.suffix ~= CALC_VERSION then reject(label, "version du calculateur " .. p.suffix .. " (attendu " .. CALC_VERSION .. ")")
    else
      local order, bad = {}, nil
      for ch in p.order:gmatch(".") do
        local spell = indexes[p.class] and indexes[p.class][ch]
        if not spell then bad = ch; break end
        order[#order + 1] = spell
      end
      if bad then reject(label, "caractère d'ordre inconnu " .. bad)
      else
        candidates[#candidates + 1] = { label = label, class = p.class, spec = spec, specKey = specKey,
          kind = "leveling", source = "Icy Veins", url = "https://www.icy-veins.com/wow-forever/" .. p.page,
          date = iso, order = order, key = "IV_" .. p.class .. "_" .. specKey:upper():gsub("%-", "_") }
      end
    end
  end
end

---------------------------------------------------------------------------
-- Autres sources (wowhead/, questify/)
---------------------------------------------------------------------------
local function normalize(s) return (tostring(s):lower():gsub("[^%w]", "")) end

local function loadOthers()
  for _, dir in ipairs({ "wowhead", "questify" }) do
    for _, path in ipairs(listFiles(opts.raw .. "/" .. dir, "%.json$")) do
      local label = dir .. "/" .. path:match("[^/]+$")
      local ok, data = pcall(parseJSON, readFile(path) or "")
      if not ok then reject(label, tostring(data))
      elseif type(data) ~= "table" then reject(label, "objet attendu")
      else
        local class = type(data.class) == "string" and data.class:upper() or nil
        local specs = class and SPECS[class]
        local spec, specKey
        if specs then
          for k, s in pairs(specs) do
            if normalize(k) == normalize(data.spec) or normalize(s[2]) == normalize(data.spec) then spec, specKey = s, k end
          end
        end
        local kind = KINDS[data.kind]
        if not spec then reject(label, "classe ou spécialisation inconnue")
        elseif not kind then reject(label, "kind inconnu (leveling, dungeon, pvp ou raid attendu)")
        elseif type(data.source) ~= "string" or data.source == "" then reject(label, "source absente")
        elseif type(data.url) ~= "string" or not isoDate(tostring(data.date)) then reject(label, "url ou date absente")
        elseif type(data.orderSpells) ~= "table" then reject(label, "orderSpells absent")
        else
          local order = {}
          for i, v in ipairs(data.orderSpells) do order[i] = v end
          candidates[#candidates + 1] = { label = label, class = class, spec = spec, specKey = specKey,
            kind = data.kind, source = data.source, url = data.url, date = isoDate(data.date), order = order,
            key = makeKey(data.source, class, specKey, data.kind) }
        end
      end
    end
  end
end

loadIcyVeins()
loadOthers()

---------------------------------------------------------------------------
-- Validation et émission
---------------------------------------------------------------------------
local shipped, seenKeys = {}, {}
local trees = {}
for _, c in ipairs(candidates) do
  local shape = shapes[c.class]
  if not shape then
    reject(c.label, "pas de table du calculateur pour " .. c.class)
  elseif seenKeys[c.key] then
    reject(c.label, "clé en double " .. c.key)
  else
    trees[c.class] = trees[c.class] or Q.TalentTree:FromShape(shape)
    local build = { order = c.order }
    local ok, reason, at = Q.Builds:Validate(build, trees[c.class])
    local adjusted
    if not ok and (reason == "tier" or reason == "requires") then
      local fixed, moved = Repair(Q, c.order, trees[c.class])
      if fixed and Q.Builds:Validate({ order = fixed }, trees[c.class]) then
        c.order, adjusted, ok = fixed, true, true
        print(string.format("ajusté : %s (%d points déplacés)", c.key, moved))
      end
    end
    if ok then
      seenKeys[c.key] = true
      local kindWords = KINDS[c.kind]
      shipped[#shipped + 1] = {
        key = c.key, class = c.class, specID = c.spec[1], kind = c.kind,
        name = { enUS = c.spec[2] .. " — " .. kindWords[1], frFR = c.spec[3] .. " — " .. kindWords[2] },
        source = c.source, url = c.url, date = c.date, official = true, adjusted = adjusted, order = c.order }
    else
      reject(c.label, "invalide (" .. tostring(reason) .. " au point " .. tostring(at) .. ")")
    end
  end
end

table.sort(shipped, function(a, b)
  if a.class ~= b.class then return a.class < b.class end
  if a.specID ~= b.specID then return a.specID < b.specID end
  local ra, rb = SOURCE_RANK[a.source:lower()] or 9, SOURCE_RANK[b.source:lower()] or 9
  if ra ~= rb then return ra < rb end
  if a.kind ~= b.kind then return a.kind < b.kind end
  return a.key < b.key
end)

-- Noms génériques, sans nom de source : le premier build d'une classe, spécialisation et sorte garde le
-- nom de base, les suivants (ordre ci-dessus) prennent « · variante N ». Un build de moins de 51 points
-- (M2) finit par « · partiel » : il ne couvre pas tous les niveaux (Builds:AutoPick le place après les
-- builds complets).
do
  local seen = {}
  for _, b in ipairs(shipped) do
    local k = b.class .. ":" .. b.specID .. ":" .. b.name.enUS
    seen[k] = (seen[k] or 0) + 1
    if seen[k] > 1 then
      b.name.enUS = b.name.enUS .. " · variant " .. seen[k]
      b.name.frFR = b.name.frFR .. " · variante " .. seen[k]
    end
  end
  for _, b in ipairs(shipped) do
    if #b.order < 51 then
      b.name.enUS = b.name.enUS .. " · partial"
      b.name.frFR = b.name.frFR .. " · partiel"
    end
  end
end

local function q(s)
  return '"' .. tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
end

local function sortedKeys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then return a < b end
    return type(a) == "number"
  end)
  return keys
end

local out = {}
local function w(s) out[#out + 1] = s end

w("-- Généré par tools/talentbuilds/build.lua. Ne pas modifier à la main.")
w("local addonName, Q = ...")
w("")
w("-- Builds de talents fournis, par classe : un spellID (rang 1) par point, du niveau 10 au niveau 60.")
w("-- Aucun texte des sources : seulement les spellID, l'ordre, la source, l'adresse et la date.")
w("Q.TalentBuildData = {")
local byClass = {}
for _, b in ipairs(shipped) do
  byClass[b.class] = byClass[b.class] or {}
  table.insert(byClass[b.class], b)
end
for _, class in ipairs(sortedKeys(byClass)) do
  w("  " .. class .. " = {")
  for _, b in ipairs(byClass[class]) do
    w("    { key = " .. q(b.key) .. ", class = " .. q(b.class) .. ", specID = " .. b.specID .. ", kind = " .. q(b.kind) .. ",")
    w("      name = { enUS = " .. q(b.name.enUS) .. ", frFR = " .. q(b.name.frFR) .. " },")
    w("      source = " .. q(b.source) .. ", url = " .. q(b.url) .. ", date = " .. q(b.date) .. ", official = true" .. (b.adjusted and ", adjusted = true" or "") .. ",")
    w("      order = {")
    for i = 1, #b.order, 12 do
      local row = {}
      for j = i, math.min(i + 11, #b.order) do row[#row + 1] = tostring(b.order[j]) end
      w("        " .. table.concat(row, ", ") .. ",")
    end
    w("      } },")
  end
  w("  },")
end
w("}")
w("")
w("-- Table d'index du calculateur Icy Veins (caractère de l'ordre -> spellID), pour lire un lien du calculateur,")
w("-- et version du calculateur relevée (suffixe « ~… » du lien) : un lien d'une autre version est refusé.")
w("Q.TalentIndexVersion = " .. q(CALC_VERSION))
w("Q.TalentIndexData = {")
for _, class in ipairs(sortedKeys(indexes)) do
  local parts = {}
  for _, ch in ipairs(sortedKeys(indexes[class])) do
    parts[#parts + 1] = "[" .. q(ch) .. "] = " .. indexes[class][ch]
  end
  w("  " .. class .. " = { " .. table.concat(parts, ", ") .. " },")
end
w("}")
w("")
w("-- Forme de l'arbre de chaque classe (talent -> groupe, palier, colonne, rangs max, talents requis),")
w("-- pour contrôler un build hors du jeu (Q.TalentTree:FromShape).")
w("Q.TalentShapeData = {")
for _, class in ipairs(sortedKeys(shapes)) do
  w("  " .. class .. " = {")
  for _, spell in ipairs(sortedKeys(shapes[class])) do
    local s = shapes[class][spell]
    local req = {}
    for _, r in ipairs(s.requires) do req[#req + 1] = tostring(r) end
    w(string.format("    [%d] = { group = %d, tier = %d, col = %d, maxRanks = %d, requires = { %s } },",
      spell, s.group, s.tier, s.col, s.maxRanks, table.concat(req, ", ")))
  end
  w("  },")
end
w("}")
w("")

local f = assert(io.open(opts.out, "wb"))
f:write(table.concat(out, "\n"))
f:close()

local perClass = {}
for _, b in ipairs(shipped) do perClass[b.class] = (perClass[b.class] or 0) + 1 end
print(string.format("%d builds livrés, %d rejetés -> %s", #shipped, #rejected, opts.out))
for _, class in ipairs(sortedKeys(perClass)) do print(string.format("  %-8s %d", class, perClass[class])) end
for _, r in ipairs(rejected) do print("  REJETÉ " .. r) end
