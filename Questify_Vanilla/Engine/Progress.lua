local addonName, Q = ...

-- Moteur de progression : état de chaque étape (spec § 5.3), étape courante, chapitres.
-- L'état « fait » issu du jeu (journal, position, niveau) n'est jamais enregistré : seuls les
-- choix du joueur (étape cochée ou passée) vont dans Q.char.
local Progress = {}
Q.Progress = Progress

-- Contexte du personnage, rafraîchi au LOGIN et à PLAYER_LEVEL_UP.
Q.Player = Q.Player or {}

local GOTO_RADIUS = 15        -- yards
local FP_RADIUS = 30
local HEARTH_RADIUS = 40
local LOG_THROTTLE = 0.2      -- secondes
local HEARTH_SPELLS = { [8690] = true }

local QUEST_ACTIONS = { accept = true, complete = true, turnin = true }
-- Étapes de lieu ou manuelles : comptées faites quand une étape de quête plus loin l'est déjà.
local PASSABLE = { ["goto"] = true, boat = true, fp = true, sethearth = true, hearth = true, fly = true, note = true }

local turnedIn = {}     -- cache de session rempli par QUEST_TURNED_IN
local reached = {}      -- étapes de lieu atteintes pendant la session : [key] = true
local hold = {}         -- étapes rouvertes par Back() : pas de validation auto tant que le joueur est sur place
local activation = {}   -- hearth/fly : { map, serial } au moment où l'étape devient courante
local zoneSerial = 0
local entriesCache
local cache             -- { states = {[key] = {state, reason}}, current = entry }
local lastKey
local endPrinted = {}
local ticker
local logPending = false

---------------------------------------------------------------------------
-- Contexte
---------------------------------------------------------------------------
-- Valeur issue d'une unité ou d'un évènement : nil si secrète (testé avant tout usage).
local function plain(v)
  if Q.Util.IsSecret(v) then return nil end
  return v
end

local function refreshPlayer(level)
  local P = Q.Player
  P.faction = UnitFactionGroup and plain((UnitFactionGroup("player"))) or nil
  local _, raceFile, raceId = UnitRace("player")
  raceFile, raceId = plain(raceFile), plain(raceId)
  local race = raceId and Q.RACE_BY_ID[raceId]
  P.raceId = raceId
  P.raceKey = race and race.key or raceFile
  P.raceBit = race and race.bit or nil
  local _, classFile = UnitClass("player")
  classFile = plain(classFile)
  P.classFile = classFile
  P.classBit = classFile and Q.CLASS_BITS[classFile] or nil
  local unitLevel = tonumber(plain(UnitLevel("player"))) or 1
  P.level = math.max(tonumber(plain(level)) or 0, unitLevel)
end
Progress.RefreshPlayer = function(_, level) refreshPlayer(level) end

local EMPTY_CHAR = { manual = {}, skipped = {}, inserted = {} }
local function charState()
  local c = Q.char
  if not c then return EMPTY_CHAR end
  c.manual = c.manual or {}
  c.skipped = c.skipped or {}
  c.inserted = c.inserted or {}
  return c
end

function Progress:IsEnabled()
  return Q.loggedIn == true and Q.char ~= nil and Q.QDB:IsAvailable()
end

local function invalidate()
  entriesCache = nil
  cache = nil
end
Progress.Invalidate = invalidate

---------------------------------------------------------------------------
-- État des quêtes (client)
---------------------------------------------------------------------------
function Progress:IsTurnedIn(id)
  if type(id) ~= "number" then return false end
  if turnedIn[id] then return true end
  return C_QuestLog.IsQuestFlaggedCompleted(id) == true
end

function Progress:InLog(id)
  if type(id) ~= "number" then return false end
  return Q.API.QuestLogIndex(id) ~= nil
end

function Progress:IsComplete(id)
  if type(id) ~= "number" then return false end
  return Q.API.IsQuestComplete(id)
end

function Progress:ObjectiveDone(id, i)
  if type(id) ~= "number" or type(i) ~= "number" then return false end
  local objs = C_QuestLog.GetQuestObjectives(id)
  local o = objs and objs[i]
  return o ~= nil and o.finished == true
end

local function isTurnedIn(id) return Progress:IsTurnedIn(id) end

---------------------------------------------------------------------------
-- Guide courant
---------------------------------------------------------------------------
function Progress:Guide()
  return Q.Guides:Get(charState().guideId)
end

-- Change de chapitre et recalcule (envoie "GUIDE_CHANGED").
function Progress:SetGuide(id)
  local g = Q.Guides:Get(id)
  if not g or not Q.char then return false end
  Q.char.guideId = id
  invalidate()
  Q:Fire("GUIDE_CHANGED", g)
  self:Update()
  return true
end

---------------------------------------------------------------------------
-- Liste des entrées : étapes insérées d'abord, puis celles du chapitre.
---------------------------------------------------------------------------
function Progress:Entries()
  if entriesCache then return entriesCache end
  local list = {}
  local c = charState()
  for _, group in ipairs(c.inserted) do
    if type(group) == "table" and type(group.tag) == "string" and type(group.steps) == "table" then
      for j, step in ipairs(group.steps) do
        list[#list + 1] = { key = "i:" .. group.tag .. ":" .. j, step = step, index = j, source = "inserted", tag = group.tag }
      end
    end
  end
  local g = self:Guide()
  if g then
    for i, step in ipairs(g.steps) do
      list[#list + 1] = { key = "g:" .. g.id .. ":" .. i, step = step, index = i, source = "guide" }
    end
  end
  entriesCache = list
  return list
end

---------------------------------------------------------------------------
-- Calcul des états
---------------------------------------------------------------------------
local COMPUTING = {}

local function newContext(entries)
  local ctx = { memo = {}, byQuest = {} }
  for _, e in ipairs(entries) do
    local id = e.step.questId
    if id then
      local list = ctx.byQuest[id]
      if not list then list = {}; ctx.byQuest[id] = list end
      list[#list + 1] = e
    end
  end
  return ctx
end

local computeBase

-- Un prérequis est « en cours » s'il est dans le journal ou prévu par une étape non sautée.
local function prereqPending(ctx, p)
  if Progress:InLog(p) then return true end
  local list = ctx.byQuest[p]
  if list then
    for _, e in ipairs(list) do
      if computeBase(ctx, e) ~= "skipped" then return true end
    end
  end
  return false
end

-- Prérequis impossible : ni rendu, ni prévu, ou non éligible pour ce personnage.
local function prereqDead(ctx, p)
  if Progress:IsTurnedIn(p) then return false end
  local P = Q.Player
  if not Q.QDB:IsEligible(p, P.raceBit, P.classBit) then return true end
  return not prereqPending(ctx, p)
end

local function exclusiveSiblingDone(p)
  local pq = Q.QDB:Quest(p)
  if pq then
    for _, x in ipairs(pq.exclusiveTo) do
      if Progress:IsTurnedIn(x) then return true end
    end
  end
  return false
end

-- Vrai quand les prérequis manquants ne pourront jamais être faits (sautés ou impossibles).
local function prereqsBlockedForever(ctx, q)
  for _, x in ipairs(q.exclusiveTo) do
    if Progress:IsTurnedIn(x) then return true end
  end
  if #q.preSingle > 0 then
    local anyDone, allDead = false, true
    for _, p in ipairs(q.preSingle) do
      if Progress:IsTurnedIn(p) then
        anyDone = true
      elseif not prereqDead(ctx, p) then
        allDead = false
      end
    end
    if not anyDone and allDead then return true end
  end
  for _, p in ipairs(q.preGroup) do
    if not Progress:IsTurnedIn(p) and not exclusiveSiblingDone(p) and prereqDead(ctx, p) then return true end
  end
  return false
end

local function filterSkip(step)
  local P = Q.Player
  if step.race and not Q.Util.Contains(step.race, P.raceKey) then return "race" end
  if step.class and not Q.Util.Contains(step.class, P.classFile) then return "class" end
  if step.optional and Q.Settings:Get("dungeonQuests") == false then return "optional" end
  return nil
end

local function evaluate(ctx, e)
  local c = charState()
  local step = e.step
  local a = step.action
  local P = Q.Player
  if c.manual[e.key] then return "done", "manual" end
  if c.skipped[e.key] then return "skipped", "manual" end
  local f = filterSkip(step)
  if f then return "skipped", f end

  if a == "accept" then
    local id = step.questId
    if Progress:InLog(id) or Progress:IsTurnedIn(id) then return "done" end
    local q = Q.QDB:Quest(id)
    if not q then return "active", "unknown" end
    if not Q.QDB:IsEligible(id, P.raceBit, P.classBit) then return "skipped", "ineligible" end
    if not Q.QDB:PrereqsMet(id, isTurnedIn) and prereqsBlockedForever(ctx, q) then
      return "skipped", "prereq"
    end
    if q.reqLevel and q.reqLevel > (P.level or 1) then return "blocked", "level " .. q.reqLevel end
    return "active"
  elseif a == "complete" then
    local id = step.questId
    if Progress:IsTurnedIn(id) then return "done" end
    if not Progress:InLog(id) then return "skipped", "notinlog" end
    if step.obj then
      if Progress:ObjectiveDone(id, step.obj) then return "done" end
    elseif Progress:IsComplete(id) then
      return "done"
    end
    return "active"
  elseif a == "turnin" then
    local id = step.questId
    if Progress:IsTurnedIn(id) then return "done" end
    if not Progress:InLog(id) then return "skipped", "notinlog" end
    return "active"
  elseif a == "level" then
    if (P.level or 1) >= (step.level or 0) then return "done" end
    return "active"
  elseif a == "note" then
    return "active"
  end
  -- goto, boat, fp, sethearth, hearth, fly : validées pendant qu'elles sont courantes
  if reached[e.key] then return "done", "reached" end
  return "active"
end

computeBase = function(ctx, e)
  local m = ctx.memo[e.key]
  if m == COMPUTING then return "active" end
  if m then return m[1], m[2] end
  ctx.memo[e.key] = COMPUTING
  local ok, s, r = pcall(evaluate, ctx, e)
  if not ok then
    Q:ReportError(s)
    s, r = "active", "error"
  end
  ctx.memo[e.key] = { s, r }
  return s, r
end

local function distanceTo(m, x, y)
  return Q.Maps:DistanceFromPlayer(m, x, y)
end

local function isNear(step, radius)
  local d = distanceTo(step.mapId, step.x, step.y)
  return d ~= nil and d <= radius
end

-- Validation des étapes de lieu quand elles deviennent courantes.
local function checkReached(e)
  local step = e.step
  local a = step.action
  if a == "goto" or a == "boat" then
    local near = isNear(step, GOTO_RADIUS)
    if hold[e.key] then
      if not near then hold[e.key] = nil end
      return false
    end
    return near
  elseif a == "hearth" or a == "fly" then
    local map = Q.Maps:PlayerMap()   -- nil si secret
    local act = activation[e.key]
    if not act then
      activation[e.key] = { map = map, serial = zoneSerial }
      return false
    end
    if map ~= nil and map == step.mapId and (act.map ~= step.mapId or zoneSerial > act.serial) then
      return true
    end
  end
  return false
end

function Progress:Recompute()
  local entries = self:Entries()
  local ctx = newContext(entries)
  local states = {}
  for _, e in ipairs(entries) do
    local s, r = computeBase(ctx, e)
    states[e.key] = { s, r }
  end
  -- Règle « dépassée » : dans un même bloc (chapitre ou insertion), une étape de lieu ou une
  -- note suivie d'une étape de quête déjà faite est considérée comme faite.
  local evidence = {}
  for i = #entries, 1, -1 do
    local e = entries[i]
    local seg = e.source == "guide" and "g" or ("i:" .. tostring(e.tag))
    local st = states[e.key]
    local a = e.step.action
    if PASSABLE[a] then
      if st[1] == "active" and evidence[seg] then st[1], st[2] = "done", "passed" end
    elseif QUEST_ACTIONS[a] and st[1] == "done" then
      evidence[seg] = true
    end
  end
  -- Étape courante : la première ni faite ni sautée (une étape bloquée compte).
  local current
  for _, e in ipairs(entries) do
    local st = states[e.key]
    if st[1] == "active" or st[1] == "blocked" then
      if PASSABLE[e.step.action] and checkReached(e) then
        reached[e.key] = true
        st[1], st[2] = "done", "reached"
      else
        current = e
        break
      end
    end
  end
  cache = { states = states, current = current }
  return cache
end

function Progress:State(entry)
  if type(entry) ~= "table" or not entry.key then return nil end
  if not cache then self:Recompute() end
  local st = cache.states[entry.key]
  if st then return st[1], st[2] end
  -- Entrée qui n'est plus dans la liste : évaluation isolée.
  local ctx = newContext(self:Entries())
  return computeBase(ctx, entry)
end

function Progress:Current()
  if not cache then self:Recompute() end
  return cache.current
end

-- Vrai quand toutes les étapes du chapitre sont faites ou sautées.
function Progress:GuideFinished()
  if not cache then self:Recompute() end
  local any = false
  for _, e in ipairs(self:Entries()) do
    if e.source == "guide" then
      any = true
      local s = cache.states[e.key][1]
      if s ~= "done" and s ~= "skipped" then return false end
    end
  end
  return any
end

---------------------------------------------------------------------------
-- Mise à jour et messages
---------------------------------------------------------------------------
local function checkRollover()
  local visited = {}
  while true do
    local g = Progress:Guide()
    if not g or visited[g.id] then return end
    visited[g.id] = true
    if not Progress:GuideFinished() then return end
    local nxt = Q.Guides:Next(g, Q.Player.raceKey)
    if nxt and not visited[nxt.id] then
      Q.char.guideId = nxt.id
      invalidate()
      Q:Fire("GUIDE_CHANGED", nxt)
      Progress:Recompute()
    else
      if not endPrinted[g.id] then
        endPrinted[g.id] = true
        Q:Print(Q.L.ROUTE_END)
      end
      return
    end
  end
end

local function updateTicker()
  local cur = cache and cache.current
  local a = cur and cur.step.action
  local need = a == "goto" or a == "boat"
  if need and not ticker then
    ticker = Q:NewTicker(1, function()
      local c = cache and cache.current
      if c and (c.step.action == "goto" or c.step.action == "boat") then
        local near = isNear(c.step, GOTO_RADIUS)
        -- étape rouverte par Back() : on attend que le joueur s'éloigne avant de la revalider
        if (hold[c.key] and not near) or (not hold[c.key] and near) then Progress:Update() end
      end
    end)
  elseif not need and ticker then
    ticker:Cancel()
    ticker = nil
  end
end

local updating, dirty = false, false

-- Recalcule tout, enchaîne les chapitres, envoie "PROGRESS_UPDATED" puis "STEP_CHANGED" si
-- l'étape courante change.
function Progress:Update()
  if not self:IsEnabled() then return end
  if updating then
    dirty = true
    return
  end
  updating = true
  local function recompute()
    local ok, err = pcall(function()
      self:Recompute()
      checkRollover()
    end)
    if not ok then Q:ReportError(err) end
  end
  local guard = 0
  repeat
    dirty = false
    guard = guard + 1
    recompute()
    Q:Fire("PROGRESS_UPDATED")
    -- Un gestionnaire a modifié l'état (Skip, RemoveInserted…) : on recalcule d'abord, sans
    -- annoncer d'étape intermédiaire (le cache peut être vide à ce moment).
    if not dirty then
      local cur = self:Current()
      local key = cur and cur.key
      if key ~= lastKey then
        lastKey = key
        Q:Fire("STEP_CHANGED", cur)
      end
    end
  until not dirty or guard >= 5
  if dirty then
    -- garde-fou : modifications en boucle ; on annonce l'état final une seule fois
    dirty = false
    recompute()
    local cur = self:Current()
    local key = cur and cur.key
    if key ~= lastKey then
      lastKey = key
      Q:Fire("STEP_CHANGED", cur)
    end
    dirty = false
  end
  updating = false
  updateTicker()
end

---------------------------------------------------------------------------
-- Actions du joueur
---------------------------------------------------------------------------
function Progress:Skip(key)
  if type(key) ~= "string" or not Q.char then return end
  local c = charState()
  c.skipped[key] = true
  c.manual[key] = nil
  cache = nil
  self:Update()
end

function Progress:MarkDone(key)
  if type(key) ~= "string" or not Q.char then return end
  local c = charState()
  c.manual[key] = true
  c.skipped[key] = nil
  cache = nil
  self:Update()
end

-- Revient en arrière : rouvre l'étape la plus proche avant l'étape courante que le joueur a
-- cochée, passée, ou qui a été validée par la position.
function Progress:Back()
  local entries = self:Entries()
  local cur = self:Current()
  local start = #entries
  if cur then
    for i, e in ipairs(entries) do
      if e == cur then start = i - 1; break end
    end
  end
  local c = charState()
  for i = start, 1, -1 do
    local e = entries[i]
    local k = e.key
    if c.manual[k] or c.skipped[k] or reached[k] then
      c.manual[k] = nil
      c.skipped[k] = nil
      if reached[k] then hold[k] = true end
      reached[k] = nil
      activation[k] = nil
      cache = nil
      self:Update()
      return e
    end
  end
  return nil
end

-- Rend l'étape `key` courante (clic dans le journal) : les étapes non faites avant elle sont
-- passées, les étapes passées par le joueur après elle sont rouvertes. Un seul recalcul.
function Progress:JumpTo(key)
  if type(key) ~= "string" or not Q.char then return false end
  local entries = self:Entries()
  local target
  for _, e in ipairs(entries) do
    if e.key == key then target = e; break end
  end
  if not target then return false end
  if not cache then self:Recompute() end
  local c = charState()
  local before = true
  for _, e in ipairs(entries) do
    local k = e.key
    if e == target then
      before = false
      c.skipped[k] = nil
      c.manual[k] = nil
      if reached[k] then hold[k] = true end
      reached[k] = nil
      activation[k] = nil
    elseif before then
      local s = cache.states[k] and cache.states[k][1]
      if s == "active" or s == "blocked" then c.skipped[k] = true end
    else
      c.skipped[k] = nil
    end
  end
  cache = nil
  self:Update()
  return true
end

local function clearKeys(prefix)
  local c = charState()
  local plen = #prefix
  for _, t in ipairs({ c.manual, c.skipped, reached, hold, activation }) do
    local keys = {}
    for k in pairs(t) do
      if type(k) == "string" and k:sub(1, plen) == prefix then keys[#keys + 1] = k end
    end
    for _, k in ipairs(keys) do t[k] = nil end
  end
end

-- Réinitialise la progression d'un chapitre (guide courant si guideId est nil) : efface les
-- étapes cochées ou passées par le joueur (Q.char.manual / skipped) et les validations de
-- session (reached, hold, activation) de ses seules clés "g:<guideId>:<i>", puis recalcule par
-- le chemin normal (PROGRESS_UPDATED, puis STEP_CHANGED si l'étape courante change).
-- Les autres chapitres et les étapes insérées ne sont pas touchés.
function Progress:ResetGuide(guideId)
  if not Q.char then return false end
  local id = guideId or charState().guideId
  if type(id) ~= "string" or id == "" then return false end
  clearKeys("g:" .. id .. ":")
  endPrinted[id] = nil
  cache = nil
  self:Update()
  return true
end

-- Insère des étapes (quêtes de classe…) avant la route ; un tag existant est remplacé.
function Progress:InsertSteps(tag, steps)
  if type(tag) ~= "string" or tag == "" or type(steps) ~= "table" or not Q.char then return false end
  local norm = {}
  for _, raw in ipairs(steps) do
    local s, err = Q.Guides:Normalize(raw)
    if s then norm[#norm + 1] = s else Q:Debug("InsertSteps", tag, err) end
  end
  local c = charState()
  local replaced = false
  for _, group in ipairs(c.inserted) do
    if group.tag == tag then
      group.steps = norm
      replaced = true
      break
    end
  end
  if replaced then clearKeys("i:" .. tag .. ":") end
  if not replaced then c.inserted[#c.inserted + 1] = { tag = tag, steps = norm } end
  invalidate()
  self:Update()
  return true
end

function Progress:RemoveInserted(tag)
  if type(tag) ~= "string" or not Q.char then return false end
  local c = charState()
  local found = false
  for i = #c.inserted, 1, -1 do
    if c.inserted[i].tag == tag then
      table.remove(c.inserted, i)
      found = true
    end
  end
  clearKeys("i:" .. tag .. ":")
  invalidate()
  self:Update()
  return found
end

-- Valide la première étape `action` à partir de l'étape courante, dans le rayon donné.
local function latchNearby(action, radius)
  if not cache then Progress:Recompute() end
  local cur = cache.current
  if not cur then return false end
  local started = false
  for _, e in ipairs(Progress:Entries()) do
    if e == cur then started = true end
    if started and e.step.action == action then
      local s = cache.states[e.key][1]
      if s ~= "done" and s ~= "skipped" and isNear(e.step, radius) then
        reached[e.key] = true
        cache = nil
        return true
      end
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
local function update() Progress:Update() end

Q:On("LOGIN", function()
  refreshPlayer()
  if not Progress:IsEnabled() then return end
  local c = charState()
  if not (c.guideId and Q.Guides:Get(c.guideId)) then
    local P = Q.Player
    local g = Q.Guides:ForPlayer(P.faction, P.raceKey, P.level)
    if g then
      Progress:SetGuide(g.id)
      return
    end
  end
  invalidate()
  Progress:Update()
end)

Q:On("SETTINGS_CHANGED", function(path)
  if path == "dungeonQuests" then
    cache = nil
    Progress:Update()
  end
end)

Q:RegisterEvent("QUEST_ACCEPTED", update)
Q:RegisterEvent("QUEST_REMOVED", update)
Q:RegisterEvent("QUEST_TURNED_IN", function(_, questId)
  if type(questId) == "number" then turnedIn[questId] = true end
  Progress:Update()
end)
Q:RegisterEvent("QUEST_LOG_UPDATE", function()
  if logPending or not Progress:IsEnabled() then return end
  logPending = true
  Q:After(LOG_THROTTLE, function()
    logPending = false
    Progress:Update()
  end)
end)
Q:RegisterEvent("PLAYER_LEVEL_UP", function(_, level)
  refreshPlayer(level)
  cache = nil
  Progress:Update()
end)
Q:RegisterEvent("HEARTHSTONE_BOUND", function()
  if not Progress:IsEnabled() then return end
  latchNearby("sethearth", HEARTH_RADIUS)
  Progress:Update()
end)
Q:RegisterEvent("TAXIMAP_OPENED", function()
  if not Progress:IsEnabled() then return end
  latchNearby("fp", FP_RADIUS)
  Progress:Update()
end)
Q:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
  zoneSerial = zoneSerial + 1
  Progress:Update()
end)
Q:RegisterEvent("PLAYER_ENTERING_WORLD", function()
  zoneSerial = zoneSerial + 1
  Progress:Update()
end)
-- Pierre de foyer : frame dédiée limitée au joueur (RegisterUnitEvent), pour ne pas passer par
-- le répartiteur commun à chaque sort lancé par une autre unité.
local function onSpellcast(unit, spellId)
  if Q.Util.IsSecret(unit) or unit ~= "player" then return end
  if Q.Util.IsSecret(spellId) or not HEARTH_SPELLS[spellId] then return end
  if not Progress:IsEnabled() then return end
  local cur = Progress:Current()
  if cur and cur.step.action == "hearth" then
    reached[cur.key] = true
    cache = nil
    Progress:Update()
  end
end

local spellFrame = CreateFrame("Frame")
spellFrame:Hide()
if not (spellFrame.RegisterUnitEvent and pcall(spellFrame.RegisterUnitEvent, spellFrame, "UNIT_SPELLCAST_SUCCEEDED", "player")) then
  pcall(spellFrame.RegisterEvent, spellFrame, "UNIT_SPELLCAST_SUCCEEDED")
end
spellFrame:SetScript("OnEvent", function(_, _, unit, _, spellId)
  if Q.Util.IsSecret(unit) or unit ~= "player" then return end
  Q.SafeCall(onSpellcast, unit, spellId)
end)
