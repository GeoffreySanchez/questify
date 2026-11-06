-- tools/apr/compare.lua : compare les chapitres Questify (Questify/Guides) aux routes Forever d'APR.
-- LuaJIT. Usage (depuis la racine du projet) :
--   luajit tools/apr/compare.lua [--apr DIR] [--guides DIR] [--caves FILE] [--uimap FILE] [--out FILE]
--                                [--date YYYY-MM-DD]
-- APR est lu à l'exécution depuis son clone local (tools/apr/apr.lua, bac à sable) ; la sortie
-- (docs/routes/APR-COMPARE.md) ne contient que des chiffres et des identifiants de quêtes, jamais de texte
-- ni de nom de route d'APR : une route APR y est désignée par son rang dans l'ordre de jeu, sa carte
-- (uiMapID) et sa bande de niveaux.
--
-- Pour chaque chapitre : routes APR correspondantes (même faction, races compatibles, catégorie leveling,
-- au moins 4 classes, assez de quêtes en commun), couverture dans les deux sens, similarité d'ordre sur les
-- événements communs (accept / complete / turnin), quêtes de classe, pierre de foyer. Puis les notes
-- d'intérieur d'APR (grotte, bâtiment, étage) par zone, et les routes APR sans chapitre Questify.

local function scriptDir()
  local src = debug.getinfo(1, "S").source or ""
  return src:match("^@(.*)[/\\]compare%.lua$") or "tools/apr"
end
local HERE = scriptDir()
if not package.path:find(HERE .. "/?.lua", 1, true) then package.path = HERE .. "/?.lua;" .. package.path end
local apr = require("apr")

local M = {}

local function projectRoot()
  local dir = HERE:match("^(.*)[/\\]tools[/\\]apr$")
  if dir == nil or dir == "" then return "." end
  return dir
end
M.ROOT = projectRoot()

-- Seuils de correspondance chapitre <-> route APR.
M.MIN_SHARED = 3          -- quêtes communes au minimum
M.SHARE_OF_CHAPTER = 0.10 -- ... et au moins 10 % des quêtes du chapitre
M.SHARE_OF_ROUTE = 0.25   -- ... ou 25 % des quêtes de la route
M.CLASS_QUEST_MAX = 3     -- quête de classe : ouverte à 3 classes au plus
M.GENERIC_MIN = 4         -- étape « générale » : ouverte à 4 classes au moins
M.BAND_SLACK = 2          -- bande de la route APR à 2 niveaux au plus de celle du chapitre
-- Résumé : un addon est « nettement devant » s'il fait au moins AHEAD_MIN quêtes de plus que l'autre sur la
-- même tranche (quêtes absentes de tout l'autre addon), et au moins AHEAD_SHARE des quêtes du chapitre.
M.AHEAD_MIN = 5
M.AHEAD_SHARE = 0.15

local QUEST_KINDS = { "accept", "complete", "turnin" }
local IS_QUEST = { accept = true, complete = true, turnin = true }
local MAP_KINDS = { ["goto"] = true, fp = true, sethearth = true, boat = true, hearth = true, fly = true }

------------------------------------------------------------------------------
-- Petits outils
------------------------------------------------------------------------------
local function readText(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  if s:byte(1) == 27 then return nil end
  return s
end

local function set(list) local s = {}; for _, v in ipairs(list or {}) do s[v] = true end; return s end
local function count(s) local n = 0; for _ in pairs(s) do n = n + 1 end; return n end
local function sortedKeys(s) local o = {}; for k in pairs(s) do o[#o + 1] = k end; table.sort(o); return o end
local function inter(a, b) local o = {}; for k in pairs(a) do if b[k] then o[k] = true end end; return o end
local function minus(a, b) local o = {}; for k in pairs(a) do if not b[k] then o[k] = true end end; return o end

function M.pct(n, d)
  if not d or d == 0 then return "-" end
  return ("%d %%"):format(math.floor(n * 100 / d + 0.5))
end

local function ids(s)
  local o = sortedKeys(s)
  if #o == 0 then return "none" end
  return table.concat(o, ", ")
end

------------------------------------------------------------------------------
-- Guides Questify (lecture dans un environnement vide, comme tools/routebuilder/travel.lua)
------------------------------------------------------------------------------
function M.loadGuideText(text, name)
  if text:byte(1) == 27 then return nil, "bytecode refused" end
  local fn, err = loadstring(text, "=" .. name)
  if not fn then return nil, err end
  local defs = {}
  local Q = {}
  function Q:RegisterGuide(d) defs[#defs + 1] = d end
  setfenv(fn, {})
  local ok, e = pcall(fn, "Questify", Q)
  if not ok then return nil, e end
  return defs[1]
end

local function classSet(v)
  if type(v) == "string" then return { [v] = true } end
  if type(v) == "table" then return set(v) end
  return nil
end

function M.normalizeGuideStep(s, i)
  local st = { index = i, kind = s[1], note = s.note }
  if IS_QUEST[st.kind] and type(s[2]) == "number" then st.q = s[2] end
  if MAP_KINDS[st.kind] and type(s[2]) == "number" then st.map = s[2] end
  if type(s.at) == "table" and type(s.at[1]) == "number" then st.map = s.at[1] end
  -- `classes` (étape propre à des classes) ou `class` (étape sautée pour les autres classes)
  st.classes = classSet(s.classes) or classSet(s.class)
  st.classStep = s.classes ~= nil
  return st
end

function M.normalizeGuide(def, file)
  local steps = {}
  for i, s in ipairs(def.steps or {}) do
    if type(s) == "table" then steps[#steps + 1] = M.normalizeGuideStep(s, i) end
  end
  return {
    id = def.id, title = def.title, faction = def.faction, races = def.races,
    minLevel = def.minLevel, maxLevel = def.maxLevel, file = file, steps = steps,
    next = def.next, nextByRace = type(def.nextByRace) == "table" and def.nextByRace or nil,
  }
end

-- Races qui passent par chaque chapitre : depuis les chapitres de race (champ `races`), en suivant
-- nextByRace[race] puis next. Un chapitre partagé (sans `races`) reçoit les races de ses parcours.
function M.pathRaces(chapters)
  local byId, out = {}, {}
  for _, ch in ipairs(chapters) do byId[ch.id] = ch end
  for _, ch in ipairs(chapters) do
    for _, race in ipairs(type(ch.races) == "table" and ch.races or {}) do
      local cur, seen = ch, {}
      while cur and not seen[cur.id] do
        seen[cur.id] = true
        out[cur.id] = out[cur.id] or {}
        out[cur.id][race] = true
        local nxt = cur.nextByRace and cur.nextByRace[race] or cur.next
        cur = nxt and byId[nxt]
      end
    end
  end
  local lists = {}
  for id, s in pairs(out) do lists[id] = sortedKeys(s) end
  return lists
end

-- loadGuides(dir) -> chapitres dans l'ordre de Guides.xml (sans ClassQuestData.lua), commit QuestieDB
function M.loadGuides(dir)
  local xml = readText(dir .. "/Guides.xml")
  if not xml then error("missing " .. dir .. "/Guides.xml") end
  local chapters, qdbCommit = {}, nil
  for f in xml:gmatch('<Script%s+file%s*=%s*"([^"]+)"') do
    f = f:gsub("\\", "/")
    local text = readText(dir .. "/" .. f)
    if text and text:find("RegisterGuide", 1, true) then
      local def, err = M.loadGuideText(text, f)
      if not def then error(f .. ": " .. tostring(err)) end
      chapters[#chapters + 1] = M.normalizeGuide(def, f)
      qdbCommit = qdbCommit or text:match("QuestieDB commit (%x+)")
    end
  end
  return chapters, qdbCommit
end

-- Grottes livrées (Questify/Data/Caves.lua) : nombre d'entrées par carte.
function M.loadCaves(path)
  local text = path and readText(path)
  if not text then return {} end
  local fn = loadstring(text, "=Caves.lua")
  if not fn then return {} end
  local Q = {}
  setfenv(fn, {})
  if not pcall(fn, "Questify", Q) then return {} end
  local byMap = {}
  for _, c in ipairs(type(Q.CaveData) == "table" and Q.CaveData or {}) do
    if type(c) == "table" and type(c.mapId) == "number" then byMap[c.mapId] = (byMap[c.mapId] or 0) + 1 end
  end
  return byMap
end

-- Noms des cartes (UiMap.csv du générateur, colonnes Name_lang,ID,...) ; facultatif.
function M.loadMapNames(path)
  local text = path and readText(path)
  local names = {}
  if not text then return names end
  for line in text:gmatch("[^\r\n]+") do
    local name, id = line:match('^"(.-)",(%d+),')
    if not name then name, id = line:match("^([^,]*),(%d+),") end
    if name and id then names[tonumber(id)] = name end
  end
  return names
end

-- Quêtes des chaînes de classe proposées par Questify (Questify/Guides/ClassQuestData.lua), par faction.
function M.loadClassQuests(path)
  local text = path and readText(path)
  local out = { Alliance = {}, Horde = {} }
  if not text then return out end
  local fn = loadstring(text, "=ClassQuestData.lua")
  if not fn then return out end
  local Q = {}
  setfenv(fn, {})
  if not pcall(fn, "Questify", Q) then return out end
  for _, chains in pairs(type(Q.ClassQuestData) == "table" and Q.ClassQuestData or {}) do
    for _, chain in ipairs(type(chains) == "table" and chains or {}) do
      for f, s in pairs(out) do
        if type(chain) == "table" and (chain.faction == nil or chain.faction == f) then
          for _, q in ipairs(type(chain.quests) == "table" and chain.quests or {}) do s[q] = true end
        end
      end
    end
  end
  return out
end

-- Raisons d'abandon du générateur : section « ## Dropped quests » de docs/routes/<chapitre>.md.
function M.parseDropped(text)
  local out, inSection = {}, false
  for line in (text or ""):gmatch("[^\r\n]+") do
    if line:match("^## ") then inSection = line:match("^## Dropped quests") ~= nil
    elseif inSection then
      local q, reason = line:match("^|%s*(%d+)%s*|.*|%s*([^|]-)%s*|%s*$")
      if q then out[tonumber(q)] = reason end
    end
  end
  return out
end

-- Catégorie courte d'une raison d'abandon (les raisons libres viennent de tools/routebuilder/overrides.lua).
M.REASON_PATTERNS = {
  { "^quest level %d+ above the band", "quest level above the band" },
  { "^quest level %d+ below the band", "quest level below the band" },
  { "^required level %d+ above the band", "required level above the band" },
  { "^required level %d+ not reached in time", "required level not reached in time" },
  { "^dungeon quest", "dungeon quest not picked up" },
  { "^exclusive with %d+", "exclusive with another quest" },
  { "^class quest", "class quest (ClassQuestData.lua)" },
}
M.REASON_FIXED = set({ "Questie blacklist", "seasonal or event quest", "requires a profession", "level band reached",
  "prerequisite unavailable", "finisher outside the chapter zones", "objective item source not in zone", "repeatable",
  "far", "prerequisite dropped", "event", "low ratio", "objective npc not in zone", "exploration point not in zone",
  "objective object not in zone" })

function M.reasonCategory(reason)
  if not reason then return "not a candidate of the chapter" end
  for _, p in ipairs(M.REASON_PATTERNS) do if reason:match(p[1]) then return p[2] end end
  if M.REASON_FIXED[reason] then return reason end
  return "manual drop (overrides.lua)"
end

function M.loadReasons(dir, chapters)
  local out = {}
  for _, ch in ipairs(chapters) do out[ch.id] = M.parseDropped(dir and readText(dir .. "/" .. ch.id .. ".md")) end
  return out
end

-- XP des quêtes d'après QuestieDB (vue Forever du générateur, lecture seule de tools/routebuilder).
-- -> extras.xp, extras.status, ou nil et l'erreur si QuestieDB ou le générateur sont indisponibles.
function M.questieExtras(opts, factions)
  local rb = M.ROOT .. "/tools/routebuilder/?.lua"
  if not package.path:find(rb, 1, true) then package.path = rb .. ";" .. package.path end
  local ok, qdb = pcall(require, "qdb")
  if not ok then return nil, qdb end
  local ok2, xpm = pcall(require, "xp")
  if not ok2 then return nil, xpm end
  local Ds = {}
  for _, f in ipairs(factions) do
    local okL, D = pcall(qdb.load, { db = opts.db or qdb.DEFAULT_DB, questie = opts.questie or qdb.DEFAULT_QUESTIE,
                                      faction = f })
    if not okL then return nil, D end
    Ds[f] = D
  end
  local function xp(f, q, lo, hi)
    local D = Ds[f]
    local quest = D and D.quests[q]
    if not quest then return nil end
    local lvl = (type(quest.level) == "number" and quest.level > 0) and quest.level or (lo or 1)
    -- joueur dans la bande du chapitre, au plus près du niveau de la quête
    local pl = math.max(lo or lvl, math.min(lvl, hi or lvl))
    return xpm.questXP(D, quest, pl)
  end
  local function level(f, q)
    local quest = Ds[f] and Ds[f].quests[q]
    return quest and type(quest.level) == "number" and quest.level > 0 and quest.level or nil
  end
  local function status(f, q)
    local D = Ds[f]
    local quest = D and D.quests[q]
    if not quest then return "unknown" end
    if quest.blacklisted then return "blacklisted" end
    return nil
  end
  return { xp = xp, status = status, level = level }
end

------------------------------------------------------------------------------
-- Notes d'intérieur d'APR : classement par mots de la clé de note (jamais recopiée)
------------------------------------------------------------------------------
M.INDOOR_WORDS = {
  cave = { "CAVE", "CAVES", "CAVERN", "CAVERNS", "MINE", "TUNNEL", "CRYPT", "BURROW", "BARROW", "UNDERGROUND",
           "GROTTO", "LAIR", "HOLLOW", "DEN" },
  building = { "BUILDING", "HOUSE", "INN", "BARN", "TOWER", "BUNKER", "CHURCH", "ABBEY", "CHAPEL", "CELLAR",
               "BASEMENT", "HUT", "BARRACKS", "TAVERN", "SHOP", "HEADQUARTERS", "LIGHTHOUSE", "MILL",
               "FARMHOUSE", "HULL", "DECK", "KEEP_INSIDE" },
  floor = { "UPSTAIRS", "DOWNSTAIRS", "STAIRS", "STAIRCASE", "FLOOR", "BALCONY", "ROOF", "ELEVATOR", "RAMP",
            "UPPER", "LOWER", "LOWEST", "ATTIC", "LEDGE" },
}
-- « INSIDE » seul : bâtiment, sauf si la note parle déjà d'une grotte.
M.WEAK_BUILDING = { INSIDE = true }
-- Expressions qui ne désignent pas un intérieur.
M.INDOOR_EXCLUDE = { "AUCTION_HOUSE", "LAKE_FLOOR", "SEA_FLOOR", "OCEAN_FLOOR", "FOREST_FLOOR" }

local WORD_CAT = {}
for cat, words in pairs(M.INDOOR_WORDS) do for _, w in ipairs(words) do WORD_CAT[w] = cat end end

-- indoorCategories(clé de note) -> { cave = true, building = true, floor = true } (partiel)
function M.indoorCategories(key)
  local out = {}
  if type(key) ~= "string" then return out end
  local k = "_" .. key:upper() .. "_"
  for _, ex in ipairs(M.INDOOR_EXCLUDE) do k = k:gsub("_" .. ex .. "_", "_") end
  local weak = false
  for w in k:gmatch("[^_]+") do
    if WORD_CAT[w] then out[WORD_CAT[w]] = true end
    if M.WEAK_BUILDING[w] then weak = true end
  end
  if weak and not out.cave then out.building = true end
  return out
end

------------------------------------------------------------------------------
-- Vue APR pour un contexte (faction, races)
------------------------------------------------------------------------------
local function raceList(faction, races)
  if type(races) == "table" and #races > 0 then return races end
  return apr.FACTION_RACES[faction] or {}
end

-- Ctx : mémoïse, par route, les étapes admises pour une faction et un ensemble de races.
function M.newContext(data, faction, races)
  local ctx = { data = data, faction = faction, races = raceList(faction, races), cache = {} }
  return ctx
end

local function routeAllowed(ctx, r)
  if r.faction and r.faction ~= ctx.faction then return false end
  for _, race in ipairs(ctx.races) do
    if apr.allows(r.cond, { faction = ctx.faction, race = race }) then return true end
  end
  return false
end

-- infos(ctx, route) -> { [i] = { ok, classes, ncls } } pour chaque étape
function M.stepInfos(ctx, r)
  local c = ctx.cache[r.key]
  if c then return c end
  c = {}
  for i, s in ipairs(r.steps) do
    local ok = false
    for _, race in ipairs(ctx.races) do
      if apr.allows(s.cond, { faction = ctx.faction, race = race }) then ok = true; break end
    end
    local cls = ok and apr.classesFor(s.cond, ctx.faction, ctx.races) or {}
    c[i] = { ok = ok, classes = cls, ncls = count(cls) }
  end
  ctx.cache[r.key] = c
  return c
end

local function stepQuests(s, out)
  out = out or {}
  for _, k in ipairs(QUEST_KINDS) do for _, q in ipairs(s[k]) do out[q] = true end end
  return out
end

-- Bande de la route APR (étiquette, sinon niveau minimal) qui chevauche [lo - BAND_SLACK, hi + BAND_SLACK].
function M.bandOverlaps(r, lo, hi)
  if not lo or not hi then return true end
  local rlo = r.band and r.band[1] or r.minLevel
  local rhi = r.band and r.band[2] or nil
  if rlo and rlo > hi + M.BAND_SLACK then return false end
  if rhi and rhi < lo - M.BAND_SLACK then return false end
  return true
end

-- Route candidate : leveling, faction et races compatibles, ouverte à au moins GENERIC_MIN classes.
function M.isCandidate(ctx, r)
  if r.category ~= "Leveling" then return false end
  if not routeAllowed(ctx, r) then return false end
  return count(apr.classesFor(r.cond, ctx.faction, ctx.races)) >= M.GENERIC_MIN
end

function M.routeQuests(ctx, r)
  local infos, qs = M.stepInfos(ctx, r), {}
  for i, s in ipairs(r.steps) do if infos[i].ok then stepQuests(s, qs) end end
  return qs
end

-- Toutes les quêtes d'APR ouvertes à une faction (toutes catégories, sans filtre de race ni de classe).
function M.factionQuests(data, faction)
  local qs = {}
  for _, k in ipairs(data.order) do
    local r = data.routes[k]
    if not r.faction or r.faction == faction then
      for _, s in ipairs(r.steps) do
        if apr.allows(s.cond, { faction = faction }) then stepQuests(s, qs) end
      end
    end
  end
  return qs
end

------------------------------------------------------------------------------
-- Ordre : similarité sur les événements communs
------------------------------------------------------------------------------
-- events(list of { kind, q }) -> clés "kind:q" dans l'ordre, première occurrence seulement
local function firstPositions(events)
  local pos, n = {}, 0
  for _, e in ipairs(events) do
    local key = e.kind .. ":" .. e.q
    if not pos[key] then n = n + 1; pos[key] = n end
  end
  return pos
end

-- orderSimilarity(evQ, evA) -> { shared, concordant, discordant, same, tau, inversions = { ... } }
function M.orderSimilarity(evQ, evA, maxInversions)
  local pQ, pA = firstPositions(evQ), firstPositions(evA)
  local keys = {}
  for k in pairs(pQ) do if pA[k] then keys[#keys + 1] = k end end
  table.sort(keys, function(a, b) return pQ[a] < pQ[b] end)
  local n = #keys
  local rQ, rA = {}, {}
  for i, k in ipairs(keys) do rQ[k] = i end
  local byA = {}
  for i = 1, n do byA[i] = keys[i] end
  table.sort(byA, function(a, b) return pA[a] < pA[b] end)
  for i, k in ipairs(byA) do rA[k] = i end
  local C, D, disc = 0, 0, {}
  for i = 1, n - 1 do
    local a = keys[i]
    for j = i + 1, n do
      local b = keys[j]
      if rA[a] < rA[b] then C = C + 1
      else
        D = D + 1
        local gQ, gA = rQ[b] - rQ[a], rA[a] - rA[b]
        disc[#disc + 1] = { first = a, second = b, gapQ = gQ, gapA = gA, cost = math.min(gQ, gA) }
      end
    end
  end
  table.sort(disc, function(x, y)
    if x.cost ~= y.cost then return x.cost > y.cost end
    if x.gapQ + x.gapA ~= y.gapQ + y.gapA then return x.gapQ + x.gapA > y.gapQ + y.gapA end
    if x.first ~= y.first then return x.first < y.first end
    return x.second < y.second
  end)
  -- paires les plus coûteuses, chaque événement au plus une fois
  local used, inv = {}, {}
  for _, d in ipairs(disc) do
    if #inv >= (maxInversions or 5) then break end
    if not used[d.first] and not used[d.second] then
      used[d.first] = true; used[d.second] = true
      inv[#inv + 1] = d
    end
  end
  local total = C + D
  return {
    shared = n, concordant = C, discordant = D,
    same = total > 0 and C / total or nil,
    tau = total > 0 and (C - D) / total or nil,
    inversions = inv,
  }
end

------------------------------------------------------------------------------
-- Comparaison d'un chapitre
------------------------------------------------------------------------------
local function chapterQuests(ch)
  local qs = {}
  for _, st in ipairs(ch.steps) do if st.q then qs[st.q] = true end end
  return qs
end

local function questClassSets(ch)
  local all, out = set(apr.CLASSES), {}
  for _, st in ipairs(ch.steps) do
    if st.q then
      local cls = st.classes or all
      out[st.q] = out[st.q] or {}
      for c in pairs(cls) do out[st.q][c] = true end
    end
  end
  return out
end

-- Quêtes de classe par classe : { [class] = { [q] = true } } (quête ouverte à CLASS_QUEST_MAX classes au plus).
local function classQuests(questClasses)
  local out = {}
  for _, c in ipairs(apr.CLASSES) do out[c] = {} end
  for q, cls in pairs(questClasses) do
    local n = count(cls)
    if n > 0 and n <= M.CLASS_QUEST_MAX then
      for c in pairs(cls) do if out[c] then out[c][q] = true end end
    end
  end
  return out
end

local function isClassQuest(cls, q, classIds)
  local n = count(cls)
  return (n > 0 and n <= M.CLASS_QUEST_MAX) or (classIds and classIds[q]) or false
end

-- XP d'un ensemble de quêtes (extras.xp absent : nil).
local function xpOf(extras, faction, s, ch)
  if not extras.xp then return nil end
  local total = 0
  for q in pairs(s) do total = total + (extras.xp(faction, q, ch.minLevel, ch.maxLevel) or 0) end
  return total
end

-- compareChapter(data, ch, opts) ; opts = { rank, questifyAll = { [faction] = set }, aprAll = { [faction] = set },
-- extras = { xp = function(faction, q, lo, hi) -> xp|nil, status = function(faction, q) -> "blacklisted" |
-- "unknown" | nil, reasons = { [chapterId] = { [q] = raison } }, classQuests = { [faction] = { [q] = true } } } }
function M.compareChapter(data, ch, opts)
  local extras = opts.extras or {}
  local ctx = M.newContext(data, ch.faction, ch.races or (opts.pathRaces and opts.pathRaces[ch.id]))
  opts.contexts = opts.contexts or {}
  local ckey = ch.faction .. "|" .. table.concat(ctx.races, ",")
  if opts.contexts[ckey] then ctx = opts.contexts[ckey] else opts.contexts[ckey] = ctx end
  local classIds = extras.classQuests and extras.classQuests[ch.faction] or {}

  local Qall = chapterQuests(ch)
  local qClasses = questClassSets(ch)
  local Q, Qclass = {}, {}
  for q in pairs(Qall) do
    if isClassQuest(qClasses[q], q, classIds) then Qclass[q] = true else Q[q] = true end
  end
  local nQ = count(Q)
  local res = { chapter = ch, nQ = nQ, nQclass = count(Qclass), questsAll = Qall, races = ctx.races, routes = {} }

  -- 1. routes correspondantes (sur les quêtes générales du chapitre)
  for _, k in ipairs(data.order) do
    local r = data.routes[k]
    if M.isCandidate(ctx, r) and M.bandOverlaps(r, ch.minLevel, ch.maxLevel) then
      local rq = M.routeQuests(ctx, r)
      local shared = count(inter(Q, rq))
      local nR = count(rq)
      if shared >= M.MIN_SHARED and (shared >= M.SHARE_OF_CHAPTER * nQ or shared >= M.SHARE_OF_ROUTE * nR) then
        res.routes[#res.routes + 1] = { route = r, shared = shared, quests = rq, n = nR, rank = opts.rank[k] }
      end
    end
  end
  table.sort(res.routes, function(a, b) return a.rank < b.rank end)
  if #res.routes == 0 then return res end

  -- 2. séquence APR (routes dans l'ordre de jeu) et tranche [premier, dernier] événement commun
  local seq = {}
  for _, m in ipairs(res.routes) do
    local infos = M.stepInfos(ctx, m.route)
    for i, s in ipairs(m.route.steps) do
      if infos[i].ok then seq[#seq + 1] = { step = s, info = infos[i], route = m } end
    end
  end
  local first, last
  for i, e in ipairs(seq) do
    for q in pairs(stepQuests(e.step)) do
      if Q[q] then first = first or i; last = i; break end
    end
  end
  res.window = { first = first, last = last, size = last - first + 1, total = #seq }

  -- 3. couverture (quêtes générales ; les quêtes de classe sont comptées à part)
  local matched = {}
  for _, m in ipairs(res.routes) do for q in pairs(m.quests) do matched[q] = true end end
  local aprAll = opts.aprAll[ch.faction]
  local qAll = opts.questifyAll[ch.faction]
  local winAll, winClasses = {}, {}
  for i = first, last do
    local e = seq[i]
    for q in pairs(stepQuests(e.step)) do
      winAll[q] = true
      winClasses[q] = winClasses[q] or {}
      for c in pairs(e.info.classes) do winClasses[q][c] = true end
    end
  end
  -- quêtes APR d'un niveau nettement au-dessus du chapitre (QuestieDB) : hors de la même tranche
  local win, above = {}, {}
  local maxLevel = ch.maxLevel and (ch.maxLevel + M.BAND_SLACK)
  for q in pairs(winAll) do
    if not isClassQuest(winClasses[q], q, classIds) then
      local lvl = extras.level and not Q[q] and extras.level(ch.faction, q)
      if lvl and maxLevel and lvl > maxLevel then above[q] = true else win[q] = true end
    end
  end
  res.cover = {
    qInMatched = inter(Q, matched),
    qInApr = inter(Q, aprAll),
    qAbsentApr = minus(Q, aprAll),
    qElsewhereApr = minus(inter(Q, aprAll), matched),
    win = win,
    winInChapter = inter(win, Q),
    winOtherChapter = minus(inter(win, qAll), Q),
    winAprOnly = minus(win, qAll),
    winAbove = above,
  }

  -- APR-only : raison du générateur (rapport du chapitre), statut QuestieDB
  local reasons = extras.reasons and extras.reasons[ch.id] or {}
  local byReason = {}
  for q in pairs(res.cover.winAprOnly) do
    local why = M.reasonCategory(reasons[q])
    local st = extras.status and extras.status(ch.faction, q)
    if st then why = why .. " (QuestieDB: " .. st .. ")" end
    byReason[why] = byReason[why] or {}
    byReason[why][q] = true
  end
  res.aprOnlyByReason = byReason

  -- 4. ordre (étapes générales seulement : ouvertes à GENERIC_MIN classes ou plus)
  local evQ, evA = {}, {}
  for _, st in ipairs(ch.steps) do
    if st.q and (not st.classes or count(st.classes) >= M.GENERIC_MIN) then
      evQ[#evQ + 1] = { kind = st.kind, q = st.q }
    end
  end
  for i = first, last do
    local e = seq[i]
    if e.info.ncls >= M.GENERIC_MIN then
      for _, kind in ipairs(QUEST_KINDS) do
        for _, q in ipairs(e.step[kind]) do evA[#evA + 1] = { kind = kind, q = q } end
      end
    end
  end
  res.order = M.orderSimilarity(evQ, evA, 5)

  -- 5. quêtes de classe (APR : conditions de classe des étapes de la tranche)
  res.classQ = classQuests(qClasses)
  res.classA = classQuests(winClasses)
  res.classOffered = classIds

  -- 6. pierre de foyer, par classe (APR : étapes de la tranche ouvertes à cette classe)
  local h = { aprUse = {}, aprBind = {}, aprBindMaps = {}, aprIfAvailable = 0, qUse = {}, qBind = {}, qBindMaps = {} }
  for _, c in ipairs(apr.CLASSES) do h.aprUse[c], h.aprBind[c], h.qUse[c], h.qBind[c] = 0, 0, 0, 0 end
  for i = first, last do
    local e = seq[i]
    for c in pairs(e.info.classes) do
      if e.step.hearth or e.step.hearthIfAvailable then h.aprUse[c] = h.aprUse[c] + 1 end
      if e.step.setHearth then h.aprBind[c] = h.aprBind[c] + 1 end
    end
    if e.step.setHearth and e.step.zone then h.aprBindMaps[e.step.zone] = true end
    if e.step.hearthIfAvailable and e.info.ncls >= M.GENERIC_MIN then h.aprIfAvailable = h.aprIfAvailable + 1 end
  end
  local all = set(apr.CLASSES)
  for _, st in ipairs(ch.steps) do
    for c in pairs(st.classes or all) do
      if st.kind == "hearth" then h.qUse[c] = h.qUse[c] + 1 end
      if st.kind == "sethearth" then h.qBind[c] = h.qBind[c] + 1 end
    end
    if st.kind == "sethearth" and st.map then h.qBindMaps[st.map] = true end
  end
  res.hearth = h

  -- 7. verdict : XP (QuestieDB) si connue, sinon nombre de quêtes
  local aOnly, qOnly = count(res.cover.winAprOnly), count(res.cover.qAbsentApr)
  res.aOnly, res.qOnly = aOnly, qOnly
  res.xpChapter = xpOf(extras, ch.faction, Q, ch)
  res.xpAprOnly = xpOf(extras, ch.faction, res.cover.winAprOnly, ch)
  res.xpQOnly = xpOf(extras, ch.faction, res.cover.qAbsentApr, ch)
  if res.xpChapter and res.xpChapter > 0 then
    local diff = res.xpAprOnly - res.xpQOnly
    local margin = M.AHEAD_SHARE * res.xpChapter
    if diff >= margin and aOnly >= M.AHEAD_MIN then res.verdict = "apr"
    elseif -diff >= margin and qOnly >= M.AHEAD_MIN then res.verdict = "questify"
    else res.verdict = "close" end
  else
    if aOnly >= qOnly + M.AHEAD_MIN and aOnly >= M.AHEAD_SHARE * nQ then res.verdict = "apr"
    elseif qOnly >= aOnly + M.AHEAD_MIN and qOnly >= M.AHEAD_SHARE * nQ then res.verdict = "questify"
    else res.verdict = "close" end
  end
  return res
end

------------------------------------------------------------------------------
-- Notes d'intérieur par zone (routes leveling d'APR ouvertes à la faction)
------------------------------------------------------------------------------
function M.indoorByZone(data, faction)
  local zones = {}
  for _, k in ipairs(data.order) do
    local r = data.routes[k]
    if r.category == "Leveling" and (not r.faction or r.faction == faction) then
      for _, s in ipairs(r.steps) do
        if s.zone and #s.notes > 0 and apr.allows(s.cond, { faction = faction }) then
          local cats = {}
          for _, n in ipairs(s.notes) do for c in pairs(M.indoorCategories(n)) do cats[c] = true end end
          if next(cats) then
            local z = zones[s.zone] or { steps = { cave = 0, building = 0, floor = 0 },
                                         quests = { cave = {}, building = {}, floor = {} } }
            zones[s.zone] = z
            local qs = stepQuests(s)
            for c in pairs(cats) do
              z.steps[c] = z.steps[c] + 1
              for q in pairs(qs) do z.quests[c][q] = true end
            end
          end
        end
      end
    end
  end
  return zones
end

------------------------------------------------------------------------------
-- Comparaison complète
------------------------------------------------------------------------------
-- compare(data, chapters, extras) ; extras : voir compareChapter (tout est facultatif).
function M.compare(data, chapters, extras)
  extras = extras or {}
  local rank = apr.playOrder(data)
  local questifyAll, aprAll, maps = {}, {}, {}
  for _, ch in ipairs(chapters) do
    local f = ch.faction
    questifyAll[f] = questifyAll[f] or {}
    maps[f] = maps[f] or {}
    for q in pairs(chapterQuests(ch)) do questifyAll[f][q] = true end
    for _, st in ipairs(ch.steps) do if st.map then maps[f][st.map] = true end end
    aprAll[f] = aprAll[f] or M.factionQuests(data, f)
  end
  local opts = { rank = rank, questifyAll = questifyAll, aprAll = aprAll, extras = extras,
                  pathRaces = M.pathRaces(chapters) }
  local results = {}
  for _, ch in ipairs(chapters) do results[#results + 1] = M.compareChapter(data, ch, opts) end

  -- routes leveling générales sans chapitre Questify, par faction
  local unmatched = {}
  for f in pairs(questifyAll) do
    local used = {}
    for _, r in ipairs(results) do
      if r.chapter.faction == f then for _, m in ipairs(r.routes) do used[m.route.key] = true end end
    end
    local ctx = M.newContext(data, f, nil)
    local list = {}
    for _, k in ipairs(data.order) do
      local r = data.routes[k]
      if not used[k] and M.isCandidate(ctx, r) then
        local rq = M.routeQuests(ctx, r)
        list[#list + 1] = { route = r, rank = rank[k], n = count(rq), done = count(inter(rq, questifyAll[f])) }
      end
    end
    table.sort(list, function(a, b) return a.rank < b.rank end)
    unmatched[f] = list
  end

  -- APR-only, toutes tranches confondues (une quête au bord de deux chapitres n'est comptée qu'une fois)
  local aprOnly = {}
  for _, r in ipairs(results) do
    if r.cover then
      local f = r.chapter.faction
      aprOnly[f] = aprOnly[f] or {}
      for q in pairs(r.cover.winAprOnly) do aprOnly[f][q] = true end
    end
  end

  local indoor = {}
  for f in pairs(questifyAll) do indoor[f] = M.indoorByZone(data, f) end
  return { results = results, rank = rank, questifyAll = questifyAll, aprAll = aprAll, maps = maps,
           unmatched = unmatched, indoor = indoor, aprOnly = aprOnly, hasXP = extras.xp ~= nil }
end

------------------------------------------------------------------------------
-- Rapport Markdown
------------------------------------------------------------------------------
local function band(r)
  if r.band then return r.band[1] .. "-" .. r.band[2] end
  if r.minLevel then return r.minLevel .. "+" end
  return "?"
end

local function mapLabel(id, names) return names[id] and ("%s (%d)"):format(names[id], id) or tostring(id) end

local function routeLabel(m, names)
  local r = m.route
  return ("#%d (%s, %s)"):format(m.rank, r.mapID and mapLabel(r.mapID, names) or "?", band(r))
end

local function mapList(s, names)
  local o = {}
  for _, id in ipairs(sortedKeys(s)) do o[#o + 1] = mapLabel(id, names) end
  return #o > 0 and table.concat(o, ", ") or "none"
end

local function fmt2(x) return x and ("%.2f"):format(x) or "-" end

local function thousands(n)
  if not n then return "-" end
  local s = tostring(math.floor(n + 0.5))
  local out = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
  return (out:gsub("^ ", ""))
end

-- Plage par classe : « 2 » si toutes les classes ont la même valeur, sinon « 1-3 ».
local function classRange(byClass)
  local lo, hi
  for _, c in ipairs(apr.CLASSES) do
    local v = byClass[c] or 0
    lo = (not lo or v < lo) and v or lo
    hi = (not hi or v > hi) and v or hi
  end
  if lo == hi then return tostring(lo) end
  return lo .. "-" .. hi
end

local function classDetail(byClass)
  local o = {}
  for _, c in ipairs(apr.CLASSES) do o[#o + 1] = c .. " " .. (byClass[c] or 0) end
  return table.concat(o, ", ")
end

local FACTIONS = { "Alliance", "Horde" }

function M.render(cmp, meta, names)
  names = names or {}
  local out = {}
  local function w(s) out[#out + 1] = s or "" end
  local v = meta.aprVersion or {}

  w("# Questify vs APR Forever: comparison")
  w()
  w(("Generated on %s by `luajit tools/apr/compare.lua`. APR (Azeroth Pilot Reloaded, free software under GPL-3.0) %s, commit `%s`, read at run time from a local clone (`.cache/apr`, outside the repository) through a sandbox: nothing from APR is copied here. This page holds only counts, map IDs and quest IDs; an APR route is named by its rank in APR's play order (`nextRoute` graph), its map and its level band.")
    :format(meta.date or "?", v.tag or "(no tag)", v.commit or "?"))
  w()
  w(("Questify: %d chapters from `Questify/Guides/Guides.xml` (QuestieDB commit `%s`). APR: %d route files of the Forever client list, %d routes.%s")
    :format(#cmp.results, meta.qdbCommit or "?", meta.aprFiles or 0, meta.aprRoutes or 0,
            cmp.hasXP and " XP: QuestieDB Forever view of the route builder (quest XP for a player in the chapter's band, nearest to the quest level)." or " XP: not computed (QuestieDB not available)."))
  w()

  -- Résumé
  local groups = { apr = {}, questify = {}, close = {}, none = {} }
  for _, r in ipairs(cmp.results) do
    local id = r.chapter.id
    if #r.routes == 0 then groups.none[#groups.none + 1] = id
    else
      local item
      if cmp.hasXP then
        item = ("%s (APR-only %d quest%s / %s XP, Questify-only %d / %s XP, chapter %s XP)"):format(id, r.aOnly,
          r.aOnly == 1 and "" or "s", thousands(r.xpAprOnly), r.qOnly, thousands(r.xpQOnly), thousands(r.xpChapter))
      else
        item = ("%s (APR-only %d, Questify-only %d)"):format(id, r.aOnly, r.qOnly)
      end
      groups[r.verdict][#groups[r.verdict] + 1] = item
    end
  end
  w("## Summary")
  w()
  if cmp.hasXP then
    w(("A side is **clearly ahead** on a chapter when, on the same slice of the route, the quests that only it does (that the other addon does nowhere for the faction) are worth at least %d %% of the chapter's quest XP more than the other side's, with at least %d such quests. \"APR-only\": general quests (not class quests) that APR does in the slice and no Questify chapter of the faction does, except those of a level more than %d above the chapter's band. \"Questify-only\": general quests of the chapter that no APR route of the faction does. Only quest XP is compared: travel time, kill time and grinding are not.")
      :format(math.floor(M.AHEAD_SHARE * 100 + 0.5), M.AHEAD_MIN, M.BAND_SLACK))
  else
    w(("A side is **clearly ahead** on a chapter when, on the same slice of the route, it does at least %d general quests more than the other that the other addon never does for the faction, and at least %d %% of the chapter's quest count. Quest count is a proxy: XP and time are not compared.")
      :format(M.AHEAD_MIN, math.floor(M.AHEAD_SHARE * 100 + 0.5)))
  end
  w()
  w("- APR clearly ahead: " .. (#groups.apr > 0 and table.concat(groups.apr, "; ") or "none"))
  w("- Questify clearly ahead: " .. (#groups.questify > 0 and table.concat(groups.questify, "; ") or "none"))
  w("- Close: " .. (#groups.close > 0 and table.concat(groups.close, "; ") or "none"))
  if #groups.none > 0 then w("- No APR counterpart: " .. table.concat(groups.none, ", ")) end
  w()
  -- APR-only par raison du générateur, toutes tranches confondues
  for _, f in ipairs(FACTIONS) do
    local all = cmp.aprOnly[f]
    if all and next(all) then
      local reasonOf, xpTotal = {}, {}
      for _, r in ipairs(cmp.results) do
        if r.chapter.faction == f and r.aprOnlyByReason then
          for why, s in pairs(r.aprOnlyByReason) do
            for q in pairs(s) do reasonOf[q] = reasonOf[q] or why end
          end
        end
      end
      local byWhy = {}
      for q, why in pairs(reasonOf) do byWhy[why] = (byWhy[why] or 0) + 1 end
      local whys = sortedKeys(byWhy)
      table.sort(whys, function(a, b) if byWhy[a] ~= byWhy[b] then return byWhy[a] > byWhy[b] end return a < b end)
      local parts = {}
      for _, why in ipairs(whys) do parts[#parts + 1] = ("%s %d"):format(why, byWhy[why]) end
      w(("%s: %d distinct APR-only quests over all slices. Why our route builder left them out (its chapter report, `docs/routes/<chapter>.md`): %s.")
        :format(f, count(all), table.concat(parts, "; ")))
      w()
    end
  end

  -- Tableau principal
  w("## Chapters")
  w()
  w(("Matching: APR leveling routes of the same faction, open to a race of the chapter and to at least %d classes, whose level band is within %d levels of the chapter's, sharing at least %d general quests with the chapter and at least %d %% of them or %d %% of the route's quests. The APR *slice* runs from the first to the last APR step that names a general quest of the chapter, over the matched routes in play order. Class quests (open to at most %d classes at APR, or in a chain of `ClassQuestData.lua`) are left out of the coverage columns and counted on their own.")
    :format(M.GENERIC_MIN, M.BAND_SLACK, M.MIN_SHARED, math.floor(M.SHARE_OF_CHAPTER * 100 + 0.5), math.floor(M.SHARE_OF_ROUTE * 100 + 0.5), M.CLASS_QUEST_MAX))
  w()
  w("| Chapter | Band | APR routes | Quests | Q in matched APR | Q anywhere in APR | APR slice in chapter | APR-only | Q-only | Order: same pairs | Kendall tau | Class quests APR / Q | Hearth use APR / Q | Hearth bind APR / Q |")
  w("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
  for _, r in ipairs(cmp.results) do
    local ch = r.chapter
    local bandQ = ("%s-%s"):format(ch.minLevel or "?", ch.maxLevel or "?")
    if #r.routes == 0 then
      w(("| %s | %s | none | %d | - | - | - | - | - | - | - | - | - | - |"):format(ch.id, bandQ, r.nQ))
    else
      local rl = {}
      for _, m in ipairs(r.routes) do rl[#rl + 1] = "#" .. m.rank end
      local cA, cQ = {}, {}
      for _, c in ipairs(apr.CLASSES) do cA[c] = count(r.classA[c]); cQ[c] = count(r.classQ[c]) end
      local c = r.cover
      local h = r.hearth
      w(("| %s | %s | %s | %d | %d (%s) | %d (%s) | %d / %d (%s) | %d | %d | %s | %s | %s / %s | %s / %s | %s / %s |"):format(
        ch.id, bandQ, table.concat(rl, ", "), r.nQ,
        count(c.qInMatched), M.pct(count(c.qInMatched), r.nQ), count(c.qInApr), M.pct(count(c.qInApr), r.nQ),
        count(c.winInChapter), count(c.win), M.pct(count(c.winInChapter), count(c.win)),
        r.aOnly, r.qOnly,
        r.order.same and M.pct(r.order.concordant, r.order.concordant + r.order.discordant) or "-",
        fmt2(r.order.tau), classRange(cA), classRange(cQ),
        classRange(h.aprUse), classRange(h.qUse), classRange(h.aprBind), classRange(h.qBind)))
    end
  end
  w()
  w("Quests: general quests of the chapter. Class quests, hearth use and hearth bind are per class (`a-b` = lowest-highest over the 9 classes; one number when every class has the same). Hearth use at APR includes the \"use it if it is ready\" steps. Order: first `accept`, `complete` and `turnin` of each quest, steps open to at least " .. M.GENERIC_MIN .. " classes, compared on the events present on both sides (Kendall tau: 1 = same order, 0 = unrelated, -1 = reversed).")
  w()

  -- Détails
  w("## Details per chapter")
  for _, r in ipairs(cmp.results) do
    local ch = r.chapter
    w()
    w(("### %s — %s (%s-%s)"):format(ch.id, ch.title or "?", ch.minLevel or "?", ch.maxLevel or "?"))
    w()
    if #r.routes == 0 then
      w("No APR leveling route shares enough quests with this chapter.")
    else
      local rl = {}
      for _, m in ipairs(r.routes) do rl[#rl + 1] = ("%s: %d shared of %d"):format(routeLabel(m, names), m.shared, m.n) end
      w(("- Races: %s. APR routes: %s. Slice: %d of %d steps."):format(table.concat(r.races, ", "),
        table.concat(rl, "; "), r.window.size, r.window.total))
      local c = r.cover
      w(("- Questify -> APR: %d of %d general quests in the matched routes (%s), %d anywhere in APR (%s).")
        :format(count(c.qInMatched), r.nQ, M.pct(count(c.qInMatched), r.nQ), count(c.qInApr), M.pct(count(c.qInApr), r.nQ)))
      w("  - Absent from APR (Questify-only): " .. ids(c.qAbsentApr) ..
        (r.xpQOnly and (" (%s XP)"):format(thousands(r.xpQOnly)) or ""))
      w("  - In another APR route: " .. ids(c.qElsewhereApr))
      w(("- APR -> Questify (slice): %d of %d general quests in this chapter (%s).")
        :format(count(c.winInChapter), count(c.win), M.pct(count(c.winInChapter), count(c.win))))
      w("  - In another Questify chapter: " .. ids(c.winOtherChapter))
      w("  - In no Questify chapter (APR-only): " .. ids(c.winAprOnly) ..
        (r.xpAprOnly and (" (%s XP)"):format(thousands(r.xpAprOnly)) or ""))
      if next(c.winAbove) then
        w(("  - Left out, quest level above %d (band + %d): %s"):format(ch.maxLevel + M.BAND_SLACK, M.BAND_SLACK, ids(c.winAbove)))
      end
      local whys = sortedKeys(r.aprOnlyByReason)
      for _, why in ipairs(whys) do
        w(("    - %s: %s"):format(why, ids(r.aprOnlyByReason[why])))
      end
      local o = r.order
      if o.same then
        w(("- Order: %d shared events, %d of %d pairs in the same order (%s), Kendall tau %s.")
          :format(o.shared, o.concordant, o.concordant + o.discordant, M.pct(o.concordant, o.concordant + o.discordant), fmt2(o.tau)))
      else
        w(("- Order: %d shared events, not enough to compare."):format(o.shared))
      end
      if #o.inversions > 0 then
        w("  Most costly inversions (each event once; gap = distance in ranks among the shared events):")
        w()
        w("  | Questify does first | then | Questify gap | APR does them the other way, gap |")
        w("  |---|---|---|---|")
        for _, d in ipairs(o.inversions) do
          w(("  | %s | %s | %d | %d |"):format((d.first:gsub(":", " ")), (d.second:gsub(":", " ")), d.gapQ, d.gapA))
        end
        w()
      end
      local rows = {}
      for _, cl in ipairs(apr.CLASSES) do
        local a, q = r.classA[cl], r.classQ[cl]
        if next(a) or next(q) then
          local done = inter(a, r.questsAll)
          local offered = minus(inter(a, r.classOffered or {}), done)
          rows[#rows + 1] = ("  | %s | %d | %d | %d | %d | %s |"):format(cl, count(a), count(q), count(done),
            count(offered), ids(minus(minus(a, done), offered)))
        end
      end
      if #rows > 0 then
        w("- Class quests:")
        w()
        w("  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |")
        w("  |---|---|---|---|---|---|")
        for _, row in ipairs(rows) do w(row) end
        w()
      else
        w("- Class quests: none on either side.")
      end
      local h = r.hearth
      w(("- Hearthstone: APR uses it %s times (%s; %d \"if ready\" steps open to all) and binds it %s times (maps %s); Questify uses it %s times and binds it %s times (maps %s).")
        :format(classRange(h.aprUse), classDetail(h.aprUse), h.aprIfAvailable, classRange(h.aprBind),
                mapList(h.aprBindMaps, names), classRange(h.qUse), classRange(h.qBind), mapList(h.qBindMaps, names)))
    end
  end
  w()

  -- Notes d'intérieur
  w("## Indoor notes per zone (APR) and Questify cave entrances")
  w()
  w("APR steps of leveling routes with a note about a cave (cave, mine, tunnel, crypt...), a building (inside, inn, tower, barn...) or a floor (upstairs, downstairs, ramp, elevator...), on the maps our guides use; the notes are classified by keyword, never copied. A step can count in several categories. \"Our quests\": quest IDs of those steps that a Questify chapter of the faction also does: there an entrance or a floor hint may be missing on our side. Cave entrances: entries of `Questify/Data/Caves.lua` on that map.")
  for _, f in ipairs(FACTIONS) do
    local zones = cmp.indoor[f]
    if zones then
      w()
      w("### " .. f)
      w()
      w("| Map | Cave steps | Building steps | Floor steps | Our quests: cave | Our quests: building | Our quests: floor | Questify cave entrances |")
      w("|---|---|---|---|---|---|---|---|")
      local qAll = cmp.questifyAll[f]
      local other = 0
      for _, map in ipairs(sortedKeys(zones)) do
        local z = zones[map]
        if cmp.maps[f][map] then
          w(("| %s | %d | %d | %d | %s | %s | %s | %d |"):format(mapLabel(map, names), z.steps.cave, z.steps.building,
            z.steps.floor, ids(inter(z.quests.cave, qAll)), ids(inter(z.quests.building, qAll)),
            ids(inter(z.quests.floor, qAll)), meta.caves and meta.caves[map] or 0))
        else
          other = other + 1
        end
      end
      w()
      w(("Other maps with indoor notes at APR (no Questify step there yet): %d."):format(other))
    end
  end
  w()

  -- Routes sans chapitre
  w("## APR leveling routes without a Questify chapter")
  w()
  w("General leveling routes (open to at least " .. M.GENERIC_MIN .. " classes) that no chapter of the faction matches: ground still to cover (levels 30-60), or a zone or variant our route skips.")
  for _, f in ipairs(FACTIONS) do
    local list = cmp.unmatched[f]
    if list then
      w()
      w(("### %s (%d routes)"):format(f, #list))
      w()
      w("| APR route | Quests | Done by a Questify chapter |")
      w("|---|---|---|")
      for _, m in ipairs(list) do w(("| %s | %d | %d |"):format(routeLabel(m, names), m.n, m.done)) end
    end
  end
  w()
  return table.concat(out, "\n")
end

------------------------------------------------------------------------------
-- Ligne de commande
------------------------------------------------------------------------------
function M.main(argv)
  local opts = {
    apr = M.ROOT .. "/.cache/apr",
    guides = M.ROOT .. "/Questify/Guides",
    caves = M.ROOT .. "/Questify/Data/Caves.lua",
    uimap = M.ROOT .. "/tools/routebuilder/data/UiMap.csv",
    reports = M.ROOT .. "/docs/routes",
    db = M.ROOT .. "/.cache/questiedb",
    questie = M.ROOT .. "/.cache/questie",
    out = M.ROOT .. "/docs/routes/APR-COMPARE.md",
    date = os.date("%Y-%m-%d"),
  }
  local noXP = false
  local i = 1
  while i <= #argv do
    local a = argv[i]
    local name = a:match("^%-%-(%w+)$")
    if a == "--no-xp" then noXP = true; i = i + 1
    elseif name and opts[name] ~= nil and argv[i + 1] then opts[name] = argv[i + 1]; i = i + 2
    else io.stderr:write("unknown argument " .. a .. "\n"); return 2 end
  end
  local data = apr.load({ root = opts.apr })
  local chapters, qdbCommit = M.loadGuides(opts.guides)
  local factions, seen = {}, {}
  for _, ch in ipairs(chapters) do
    if not seen[ch.faction] then seen[ch.faction] = true; factions[#factions + 1] = ch.faction end
  end
  local extras = {
    reasons = M.loadReasons(opts.reports, chapters),
    classQuests = M.loadClassQuests(opts.guides .. "/ClassQuestData.lua"),
  }
  if not noXP then
    local q, err = M.questieExtras(opts, factions)
    if q then extras.xp, extras.status, extras.level = q.xp, q.status, q.level
    else io.stderr:write("XP not computed: " .. tostring(err) .. "\n") end
  end
  local cmp = M.compare(data, chapters, extras)
  local text = M.render(cmp, {
    date = opts.date, aprVersion = data.version, aprFiles = data.files, aprRoutes = #data.order,
    qdbCommit = qdbCommit, caves = M.loadCaves(opts.caves),
  }, M.loadMapNames(opts.uimap))
  local f = assert(io.open(opts.out, "wb"))
  f:write(text); f:close()
  local counts = { apr = 0, questify = 0, close = 0, none = 0 }
  for _, r in ipairs(cmp.results) do
    local k = #r.routes == 0 and "none" or r.verdict
    counts[k] = counts[k] + 1
  end
  print(("%d chapters: APR ahead %d, Questify ahead %d, close %d, no counterpart %d -> %s")
    :format(#cmp.results, counts.apr, counts.questify, counts.close, counts.none, opts.out))
  return 0
end

if arg and arg[0] and arg[0]:match("compare%.lua$") then os.exit(M.main(arg)) end

return M
