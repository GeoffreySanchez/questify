local addonName, Q = ...

-- Donjons selon le niveau et la faction : table précalculée par tools/routebuilder/build_dungeons.lua
-- (Q.DungeonData, chargée après ce fichier par Guides\DungeonData.lua : relue à chaque appel), état
-- par personnage, alerte du suivi, ajout à la route (prendre les quêtes en ville, aller à l'entrée,
-- faire, rendre) et abandon. Même schéma que les quêtes de classe (Engine/ClassQuests.lua).
--
-- Règle de faction stricte : un donjon n'est proposé qu'à une faction listée dans ses données, qui y
-- a au moins une quête à prendre en ville, et jamais dans une capitale de l'autre faction. Le Gouffre
-- de Ragefeu (Orgrimmar) reste Horde seulement, même si les données changeaient.
--
-- Sans QuestieDB, sans données ou avec l'option dungeonSuggest coupée (alerte seulement), le module
-- ne fait rien et ne lève jamais d'erreur.
local Dungeons = {}
Q.Dungeons = Dungeons

local TAG_PREFIX = "dg:"
local MAX_CHAIN = 3       -- préquêtes de passage enchaînées au plus

-- Zone du donjon -> seule faction autorisée (garde-fou indépendant des données).
local LOCKED_FACTION = { [2437] = "Horde" }   -- Gouffre de Ragefeu
-- Capitales : une faction n'est jamais envoyée dans une capitale de l'autre.
local CAPITAL = { [1453] = "Alliance", [1455] = "Alliance", [1457] = "Alliance",
                  [1454] = "Horde", [1456] = "Horde", [1458] = "Horde" }

---------------------------------------------------------------------------
-- État sauvegardé
---------------------------------------------------------------------------
-- Q.char.dungeons = { added = {[key]=true}, ignored = {...}, seen = {...} }
local function saved()
  local c = Q.char
  if type(c) ~= "table" then return nil end
  if type(c.dungeons) ~= "table" then c.dungeons = {} end
  local s = c.dungeons
  for _, k in ipairs({ "added", "ignored", "seen" }) do
    if type(s[k]) ~= "table" then s[k] = {} end
  end
  return s
end

-- DUNGEONS_CHANGED : suivi, journal et Automation/AutoQuest.lua (qui relit alors les étapes insérées
-- pour la prise et le rendu automatiques des quêtes).
local function notify()
  Q:Fire("DUNGEONS_CHANGED")
end

local function enabled()
  return Q.Progress ~= nil and Q.Progress:IsEnabled() and Q.QDB ~= nil and Q.QDB:IsAvailable()
end

---------------------------------------------------------------------------
-- Données
---------------------------------------------------------------------------
local function isPoint(p)
  return type(p) == "table" and type(p[1]) == "number" and type(p[2]) == "number" and type(p[3]) == "number"
end

local function validDungeon(d)
  return type(d) == "table" and type(d.key) == "string" and type(d.minLevel) == "number"
    and type(d.maxLevel) == "number" and isPoint(d.entrance) and type(d.quests) == "table"
end

local function isQuest(e) return type(e) == "table" and type(e.id) == "number" end

-- Quête à prendre en ville (ni de passage, ni prise dans le donjon).
local function isTown(e) return isQuest(e) and not e.bc and not e.inside and isPoint(e.at) end

local function questsOf(d, faction)
  local list = type(faction) == "string" and d.quests[faction]
  if type(list) ~= "table" then return {} end
  return list
end

-- Faction autorisée : listée dans les données, au moins une quête en ville, pas de verrou ni de
-- capitale adverse.
local function factionAllowed(d, faction)
  if type(faction) ~= "string" then return false end
  local lock = LOCKED_FACTION[d.areaId]
  if lock and lock ~= faction then return false end
  local owner = CAPITAL[d.entrance[1]]
  if owner and owner ~= faction then return false end
  local listed = false
  for _, f in ipairs(type(d.factions) == "table" and d.factions or {}) do
    if f == faction then listed = true end
  end
  if not listed then return false end
  for _, e in ipairs(questsOf(d, faction)) do
    if isTown(e) then return true end
  end
  return false
end

-- Race et classe du personnage (masques des données, puis QuestieDB).
local function eligible(e)
  local P = Q.Player
  if not Q.Util.MaskAllows(e.races, P.raceBit) then return false end
  if not Q.Util.MaskAllows(e.classes, P.classBit) then return false end
  return Q.QDB:IsEligible(e.id, P.raceBit, P.classBit)
end

-- Quêtes en ville du donjon que ce personnage peut faire (hors niveau et préquêtes).
local function townQuests(d)
  local out = {}
  for _, e in ipairs(questsOf(d, Q.Player.faction)) do
    if isTown(e) and eligible(e) then out[#out + 1] = e end
  end
  return out
end

-- Donjons proposés au personnage : faction autorisée et au moins une quête faisable par sa race.
local function dungeonsForPlayer()
  local out = {}
  local data = Q.DungeonData
  if type(data) ~= "table" then return out end
  local faction = Q.Player and Q.Player.faction
  for _, d in ipairs(data) do
    if validDungeon(d) and factionAllowed(d, faction) and #townQuests(d) > 0 then out[#out + 1] = d end
  end
  return out
end

local function findDungeon(key)
  if type(key) ~= "string" then return nil end
  for _, d in ipairs(dungeonsForPlayer()) do
    if d.key == key then return d end
  end
  return nil
end

---------------------------------------------------------------------------
-- Nom localisé (C_Map.GetAreaInfo), sinon le nom anglais des données
---------------------------------------------------------------------------
function Dungeons:Name(d)
  if type(d) ~= "table" then return "?" end
  if type(d.areaId) == "number" and C_Map and C_Map.GetAreaInfo then
    local ok, name = pcall(C_Map.GetAreaInfo, d.areaId)
    if ok and not Q.Util.IsSecret(name) and type(name) == "string" and name ~= "" then return name end
  end
  return tostring(d.name or d.key or "?")
end

---------------------------------------------------------------------------
-- Plan : quêtes à prendre maintenant (avec leurs préquêtes de passage), quêtes à faire et à rendre
---------------------------------------------------------------------------
local function isTurnedIn(id) return Q.Progress:IsTurnedIn(id) end

local function reqLevel(e)
  local q = Q.QDB:Quest(e.id)
  return (q and q.reqLevel) or tonumber(e.reqLevel) or 1
end

local function prereqLists(e)
  local q = Q.QDB:Quest(e.id)
  if q then return q.preSingle, q.preGroup, q.exclusiveTo end
  return type(e.pre) == "table" and e.pre or {}, type(e.preAll) == "table" and e.preAll or {}, {}
end

-- Préquêtes faites : règle de QuestieDB, ou celle des données quand QuestieDB ne connaît pas la quête
-- (pre = au moins une rendue, preAll = toutes rendues).
local function prereqsMet(e)
  if Q.QDB:Quest(e.id) then return Q.QDB:PrereqsMet(e.id, isTurnedIn) end
  local single = type(e.pre) == "table" and e.pre or {}
  if #single > 0 then
    local any = false
    for _, p in ipairs(single) do
      if isTurnedIn(p) then any = true; break end
    end
    if not any then return false end
  end
  for _, p in ipairs(type(e.preAll) == "table" and e.preAll or {}) do
    if not isTurnedIn(p) then return false end
  end
  return true
end

-- Quête utilisable maintenant par le personnage (hors préquêtes).
local function usableNow(e)
  if isTurnedIn(e.id) or not eligible(e) then return false end
  return reqLevel(e) <= (Q.Player.level or 1)
end

-- Étapes qui débloquent la quête e par ses préquêtes de passage (bc ou talk), en ajoutant les quêtes
-- prises à `took` : liste d'étapes, ou nil si une préquête manque et ne peut pas être enchaînée.
local function unlockSteps(e, byId, depth, took)
  local single, group, exclusive = prereqLists(e)
  for _, x in ipairs(exclusive) do
    if isTurnedIn(x) then return nil end
  end
  local steps = {}
  local function bring(p)
    if isTurnedIn(p) or took[p] then return true end
    local pe = byId[p]
    if not (pe and (pe.bc or pe.talk) and isPoint(pe.at) and usableNow(pe)) then return false end
    if Q.Progress:InLog(p) then
      steps[#steps + 1] = { "turnin", p }
      took[p] = true
      return true
    end
    if not prereqsMet(pe) then
      if depth >= MAX_CHAIN then return false end
      local sub = unlockSteps(pe, byId, depth + 1, took)
      if not sub then return false end
      for _, s in ipairs(sub) do steps[#steps + 1] = s end
    end
    steps[#steps + 1] = { "accept", p }
    steps[#steps + 1] = { "turnin", p }
    took[p] = true
    return true
  end
  if #single > 0 then
    local any = false
    for _, p in ipairs(single) do
      if isTurnedIn(p) then any = true; break end
    end
    if not any then
      for _, p in ipairs(single) do
        if bring(p) then any = true; break end
      end
    end
    if not any then return nil end
  end
  for _, p in ipairs(group) do
    if not bring(p) then return nil end
  end
  return steps
end

-- plan(d) -> {
--   units = { { steps = {...}, start = {m,x,y}, finish = {m,x,y}, quest = e }, ... },  -- à prendre en ville
--   active = { e, ... },   -- quêtes à faire puis rendre (prises par les unités, déjà dans le journal,
--                          -- ou prises dans le donjon)
--   locked = { [id] = "level" | "prereq" },
-- }
local function plan(d)
  local list = questsOf(d, Q.Player.faction)
  local byId, preOf = {}, {}
  for _, e in ipairs(list) do
    if isQuest(e) then
      byId[e.id] = e
      for _, p in ipairs(type(e.pre) == "table" and e.pre or {}) do preOf[p] = true end
      for _, p in ipairs(type(e.preAll) == "table" and e.preAll or {}) do preOf[p] = true end
    end
  end
  local res = { units = {}, active = {}, locked = {} }
  local used = {}
  local function consider(e)
    if used[e.id] or isTurnedIn(e.id) or not eligible(e) then return end
    if Q.Progress:InLog(e.id) then
      used[e.id] = true
      res.active[#res.active + 1] = e
      return
    end
    if reqLevel(e) > (Q.Player.level or 1) then
      res.locked[e.id] = "level"
      return
    end
    local steps = {}
    local took = {}
    if not prereqsMet(e) then
      local sub = unlockSteps(e, byId, 1, took)
      if not sub then
        res.locked[e.id] = "prereq"
        return
      end
      steps = sub
    end
    steps[#steps + 1] = { "accept", e.id }
    for id in pairs(took) do used[id] = true end
    used[e.id] = true
    local first = byId[steps[1][2]] or e
    res.units[#res.units + 1] = { steps = steps, start = first.at, finish = e.at, quest = e }
    res.active[#res.active + 1] = e
  end
  -- Les quêtes demandées par d'autres viennent après : elles peuvent être enchaînées avant celles-ci.
  for _, e in ipairs(list) do
    if isTown(e) and not preOf[e.id] then consider(e) end
  end
  for _, e in ipairs(list) do
    if isTown(e) and preOf[e.id] then consider(e) end
  end
  -- Quêtes prises dans le donjon : « faire » et « rendre » seulement (sautées hors du journal).
  for _, e in ipairs(list) do
    if isQuest(e) and e.inside and not used[e.id] and not isTurnedIn(e.id) and eligible(e) then
      used[e.id] = true
      res.active[#res.active + 1] = e
    end
  end
  return res
end
Dungeons.Plan = function(_, d) return plan(d) end

---------------------------------------------------------------------------
-- Ordre : le plus proche d'abord, en finissant la carte (ville) en cours avant d'en changer
---------------------------------------------------------------------------
-- items = { { start = {m,x,y}, finish = {m,x,y}, ... } } ; m, x, y = point de départ (peut être nil).
local function orderNearest(items, m, x, y)
  local left, out = {}, {}
  for i, it in ipairs(items) do left[i] = it end
  while #left > 0 do
    local bestI, bestTier, bestD
    for i, it in ipairs(left) do
      local p = it.start
      local tier = (isPoint(p) and p[1] == m) and 0 or 1
      local dist
      if m and isPoint(p) then dist = Q.Maps:Distance(m, x, y, p[1], p[2], p[3]) end
      dist = dist or math.huge
      if not bestI or tier < bestTier or (tier == bestTier and dist < bestD) then
        bestI, bestTier, bestD = i, tier, dist
      end
    end
    local it = table.remove(left, bestI)
    out[#out + 1] = it
    local f = isPoint(it.finish) and it.finish or it.start
    if isPoint(f) then m, x, y = f[1], f[2], f[3] end
  end
  return out
end

---------------------------------------------------------------------------
-- États
---------------------------------------------------------------------------
-- Quêtes du donjon déjà prévues par le chapitre courant (la route s'occupe alors du donjon).
local function routeQuests()
  local set = {}
  for _, e in ipairs(Q.Progress:Entries()) do
    if e.source == "guide" and e.step and e.step.action == "accept" and type(e.step.questId) == "number" then
      set[e.step.questId] = true
    end
  end
  return set
end

local function inRoute(d, set)
  for _, e in ipairs(townQuests(d)) do
    if set[e.id] then return true end
  end
  return false
end

-- done, added, ignored, puis selon le niveau : past (dépassé), upcoming (à venir ou rien à prendre),
-- available (niveau entre min - 1 et max, au moins une quête à prendre ou en cours).
local function stateOf(d, s)
  local all = townQuests(d)
  local done = true
  for _, e in ipairs(all) do
    if not isTurnedIn(e.id) then done = false; break end
  end
  if done then return "done" end
  if s.added[d.key] then return "added" end
  if s.ignored[d.key] then return "ignored" end
  local level = Q.Player.level or 1
  if level > d.maxLevel then return "past" end
  if level < d.minLevel - 1 then return "upcoming" end
  local p = plan(d)
  if #p.units > 0 then return "available" end
  for _, e in ipairs(p.active) do
    if not e.inside then return "available" end
  end
  return "upcoming"
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
-- List() -> { { dungeon, state }, ... } par niveau croissant.
function Dungeons:List()
  local out = {}
  local s = enabled() and saved()
  if not s then return out end
  local list = dungeonsForPlayer()
  table.sort(list, function(a, b)
    if a.minLevel ~= b.minLevel then return a.minLevel < b.minLevel end
    return a.key < b.key
  end)
  for _, d in ipairs(list) do
    local ok, state = pcall(stateOf, d, s)
    if ok then
      out[#out + 1] = { dungeon = d, state = state }
    else
      Q:ReportError(state)
    end
  end
  return out
end

-- Alerts() -> donjons conseillés pas encore vus (option dungeonSuggest), hors donjons dont la route
-- prend déjà les quêtes.
function Dungeons:Alerts()
  local out = {}
  if Q.Settings:Get("dungeonSuggest") == false then return out end
  local s = enabled() and saved()
  if not s then return out end
  local set
  for _, row in ipairs(self:List()) do
    if row.state == "available" and not s.seen[row.dungeon.key] then
      set = set or routeQuests()
      if not inRoute(row.dungeon, set) then out[#out + 1] = row end
    end
  end
  return out
end

function Dungeons:MarkSeen(key)
  local s = saved()
  if s and type(key) == "string" then s.seen[key] = true end
end

-- Details(d) -> { { id, giver, obj, at, ok = vrai si à prendre maintenant, reason = "level" | "prereq" |
-- "log" (déjà dans le journal), level = niveau requis }, ... } pour la fenêtre et le journal.
function Dungeons:Details(d)
  local out = {}
  if not (enabled() and validDungeon(d)) then return out end
  local p = plan(d)
  local taken, active = {}, {}
  for _, u in ipairs(p.units) do taken[u.quest.id] = true end
  for _, e in ipairs(p.active) do active[e.id] = true end
  for _, e in ipairs(townQuests(d)) do
    if not isTurnedIn(e.id) then
      local row = { id = e.id, giver = e.giver, obj = e.obj, at = e.at, level = reqLevel(e) }
      if taken[e.id] then
        row.ok = true
      elseif active[e.id] then
        row.ok, row.reason = true, "log"
      else
        row.ok, row.reason = false, p.locked[e.id] or "prereq"
      end
      out[#out + 1] = row
    end
  end
  return out
end

-- Add(key) : insère avant la route les quêtes à prendre (la plus proche d'abord, ville par ville),
-- l'entrée du donjon, puis « faire » et « rendre » pour chaque quête.
function Dungeons:Add(key)
  local s = saved()
  if not s or not enabled() then return false end
  local d = findDungeon(key)
  if not d then return false end
  local p = plan(d)
  local hasQuest = #p.units > 0
  for _, e in ipairs(p.active) do
    if not e.inside then hasQuest = true end
  end
  if not hasQuest then return false end
  local name = self:Name(d)
  local steps = {}
  local pm, px, py = Q.Maps:PlayerPos()
  for _, u in ipairs(orderNearest(p.units, pm, px, py)) do
    for _, st in ipairs(u.steps) do
      steps[#steps + 1] = { st[1], st[2], dungeon = name }
    end
  end
  local ent = d.entrance
  steps[#steps + 1] = { "goto", ent[1], ent[2], ent[3], note = string.format(Q.L.DUNGEON_GOTO_NOTE, name) }
  for _, e in ipairs(p.active) do
    if not e.talk then steps[#steps + 1] = { "complete", e.id, dungeon = name } end
  end
  -- Rendus : d'abord ceux qui se font dans le donjon (PNJ de fin sans position), puis du plus proche
  -- de l'entrée au plus loin.
  local inside, outside = {}, {}
  for _, e in ipairs(p.active) do
    if isPoint(e.endAt) then
      outside[#outside + 1] = { start = e.endAt, quest = e }
    else
      inside[#inside + 1] = e
    end
  end
  for _, e in ipairs(inside) do steps[#steps + 1] = { "turnin", e.id, dungeon = name } end
  for _, it in ipairs(orderNearest(outside, ent[1], ent[2], ent[3])) do
    steps[#steps + 1] = { "turnin", it.quest.id, dungeon = name }
  end
  -- l'état est enregistré avant l'insertion : celle-ci déclenche déjà des mises à jour
  s.added[d.key] = true
  s.ignored[d.key] = nil
  s.seen[d.key] = true
  Q.Progress:InsertSteps(TAG_PREFIX .. d.key, steps)
  notify()
  return true
end

-- Ignore(key) : retire les étapes insérées et mémorise le choix.
function Dungeons:Ignore(key)
  local s = saved()
  if not s or not enabled() or not findDungeon(key) then return false end
  s.ignored[key] = true
  s.added[key] = nil
  s.seen[key] = true
  Q.Progress:RemoveInserted(TAG_PREFIX .. key)
  notify()
  return true
end

-- Unignore(key) : le donjon redevient conseillé (ou à venir).
function Dungeons:Unignore(key)
  local s = saved()
  if not s or type(key) ~= "string" or not s.ignored[key] then return false end
  s.ignored[key] = nil
  notify()
  return true
end

---------------------------------------------------------------------------
-- Un donjon ajouté se retire de lui-même quand il ne lui reste aucune étape de quête à faire
-- (toutes rendues ou sautées) ; l'étape d'entrée seule ne le retient pas.
---------------------------------------------------------------------------
local QUEST_ACTIONS = { accept = true, complete = true, turnin = true }

Q:On("PROGRESS_UPDATED", function()
  if not enabled() then return end
  local s = saved()
  if not s then return end
  local groups, order = {}, {}
  for _, e in ipairs(Q.Progress:Entries()) do
    local tag = e.tag
    if type(tag) == "string" and tag:sub(1, #TAG_PREFIX) == TAG_PREFIX then
      local g = groups[tag]
      if not g then g = { open = false }; groups[tag] = g; order[#order + 1] = tag end
      if QUEST_ACTIONS[e.step.action] then
        local state = Q.Progress:State(e)
        if state == "active" or state == "blocked" then g.open = true end
      end
    end
  end
  local changed = false
  for _, tag in ipairs(order) do
    if not groups[tag].open then
      Q.Progress:RemoveInserted(tag)
      s.added[tag:sub(#TAG_PREFIX + 1)] = nil
      changed = true
    end
  end
  if changed then notify() end
end)

Q:On("SETTINGS_CHANGED", function(path)
  if path == "dungeonSuggest" then Q:Fire("DUNGEONS_CHANGED") end
end)
