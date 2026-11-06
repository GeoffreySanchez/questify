-- tools/routebuilder/build.lua : génère les guides de Questify depuis QuestieDB (hors jeu).
--
-- Usage :
--   luajit tools/routebuilder/build.lua [--db PATH] [--questie PATH] [--faction Alliance|Horde|all]
--          [--only <planId>] [--report DIR] [--out DIR] [--overrides FILE] [--date AAAA-MM-JJ]
--
--   --out      dossier des guides (défaut Questify/Guides) : <out>/<Alliance|Horde|Skyborne>/<planId>.lua,
--              <out>/Guides.xml (tous les guides présents, puis ClassQuestData.lua) et <out>/ClassQuestData.lua
--   --report   dossier des rapports Markdown (défaut docs/routes) : <report>/<planId>.md
--   --only     ne réécrit que ce chapitre (les chapitres précédents sont simulés pour l'état du personnage)
--
-- Affiche une ligne de résumé par chapitre.

local here = (arg and arg[0] or ""):match("^(.*)[/\\]build%.lua$") or "tools/routebuilder"
package.path = here .. "/?.lua;" .. package.path

local qdb = require("qdb")
local world = require("world")
local sim = require("sim")
local plansm = require("plans")
local emit = require("emit")
local cq = require("classquests")
local paths = require("paths")
local quality = require("quality")

local build = {}

local function parseArgs(argv)
  local o = { db = qdb.DEFAULT_DB, questie = qdb.DEFAULT_QUESTIE, faction = "all", report = "docs/routes",
              out = "Questify/Guides", overrides = here .. "/overrides.lua", date = os.date("%Y-%m-%d") }
  local i = 1
  while i <= #argv do
    local a, v = argv[i], argv[i + 1]
    if a == "--db" then o.db = v
    elseif a == "--questie" then o.questie = v
    elseif a == "--faction" then o.faction = v
    elseif a == "--only" then o.only = v
    elseif a == "--report" then o.report = v
    elseif a == "--out" then o.out = v
    elseif a == "--overrides" then o.overrides = v
    elseif a == "--date" then o.date = v
    elseif a == "--help" or a == "-h" then o.help = true; i = i - 1
    elseif a == "--jit" then o.jit = true; i = i - 1
    else error("unknown argument " .. tostring(a)) end
    i = i + 2
  end
  return o
end

-- Fichier de corrections manuelles : données pures, environnement vide.
function build.loadOverrides(path)
  local f = io.open(path, "rb")
  if not f then return { force = {}, drop = {}, pin = {}, insertAfter = {} } end
  local text = f:read("*a"); f:close()
  assert(text:byte(1) ~= 27, "bytecode refused: " .. path)
  local fn = assert(loadstring(text, "@" .. path))
  setfenv(fn, {})
  local ov = fn() or {}
  ov.force, ov.drop, ov.pin, ov.insertAfter = ov.force or {}, ov.drop or {}, ov.pin or {}, ov.insertAfter or {}
  return ov
end

-- Applique insertAfter : étape ajoutée après le turnin d'une quête (0 = en tête).
function build.applyInserts(planId, steps, ov)
  for _, ins in ipairs(ov.insertAfter[planId] or {}) do
    local at = ins.afterQuestTurnin == 0 and 0 or nil
    if not at then
      for i, s in ipairs(steps) do if s[1] == "turnin" and s[2] == ins.afterQuestTurnin then at = i end end
    end
    if at then table.insert(steps, at + 1, ins.step)
    else io.stderr:write(("overrides: %s has no turnin of %s, insert skipped\n"):format(planId, tostring(ins.afterQuestTurnin))) end
  end
end

local function raceBit(race, faction)
  if race == "Skyborne" then return faction == "Horde" and qdb.RACE_BITS.SkyborneH or qdb.RACE_BITS.SkyborneA end
  return qdb.RACE_BITS[race]
end

local function newState(race, faction)
  return { level = 1, xp = 0, pos = nil, done = {}, log = {}, knownTaxi = {}, hearth = nil, hearthReadyAt = 0,
           time = 0, race = race, raceBits = raceBit(race, faction), classBit = nil }
end

local function folderFor(plan)
  if plan.id:find("_Skyborne_", 1, true) then return "Skyborne" end
  return plan.faction
end

-- Chemin passé au shell entre apostrophes (les apostrophes du chemin sont échappées).
local function shq(path) return "'" .. tostring(path):gsub("'", "'\\''") .. "'" end
build.shq = shq

local function mkdir(path) os.execute("mkdir -p " .. shq(path)) end

local function writeFile(path, text)
  local f = assert(io.open(path, "wb"), "cannot write " .. path)
  f:write(text); f:close()
end

local function fileExists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

-- Copie d'un état de simulation (tables au premier niveau copiées).
local function copyState(st)
  local o = {}
  for k, v in pairs(st) do
    if type(v) == "table" then
      local t = {}
      for a, b in pairs(v) do t[a] = b end
      o[k] = t
    else o[k] = v end
  end
  return o
end
build.copyState = copyState

local function count(t)
  local n = 0
  for _ in pairs(t or {}) do n = n + 1 end
  return n
end

-- État du tronc commun au chapitre où arrivent plusieurs parcours de race : celui du parcours
-- principal (quêtes faites, journal, position), avec le niveau le plus bas, les seuls points de vol
-- connus de tous les parcours, la pierre de foyer seulement si elle est liée au même endroit partout.
-- Quêtes du journal d'un autre parcours absentes du parcours principal :
--   * quête ordinaire (rendu reporté dans le tronc, ex. 1358 Sample for Helbrim, prise par le Mort-vivant
--     à Fossoyeuse et rendue aux Tarides) : ajoutée au journal du tronc avec la valeur "foreign", pour que
--     le tronc la rende (le rejeu des parcours filtre l'étape sur ce parcours ; XP non comptée pour la race
--     simulée). Sans cela, elle restait dans le journal de ce parcours jusqu'au niveau 60 ;
--   * quête de donjon prise au passage : place réservée dans le journal (logPad) quand ce parcours en a plus
--     que le parcours principal n'a de quêtes absentes du sien (le parcours le plus chargé compte). Les deux
--     listes sont gardées par parcours dans logPadQuests ({ pad = ids, base = ids }) pour recalculer la
--     place à l'abandon des quêtes de donjon (sim.releaseDungeonQuests, même règle que paths.replay).
local function sortedIds(t)
  local ids = {}
  for id in pairs(t) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

function build.mergeStates(base, others)
  local m = copyState(base)
  local pads = {}
  for _, e in ipairs(base.logPadQuests or {}) do pads[#pads + 1] = e end
  for _, st in ipairs(others) do
    if st.level < m.level or (st.level == m.level and st.xp < m.xp) then m.level, m.xp = st.level, st.xp end
    for node in pairs(base.knownTaxi) do if not st.knownTaxi[node] then m.knownTaxi[node] = nil end end
    local a, b = m.hearth, st.hearth
    if not (a and b and a[1] == b[1] and math.abs(a[2] - b[2]) < 0.5 and math.abs(a[3] - b[3]) < 0.5) then m.hearth = nil end
    m.hearthReadyAt = math.max(m.hearthReadyAt or 0, st.hearthReadyAt or 0)
    local pad, only = {}, {}
    for _, id in ipairs(sortedIds(st.log)) do
      if not base.log[id] then
        if st.log[id] == "dungeon" then pad[#pad + 1] = id
        elseif not m.log[id] then m.log[id] = "foreign" end
      end
    end
    for _, id in ipairs(sortedIds(base.log)) do
      if not st.log[id] then only[#only + 1] = id end
    end
    pads[#pads + 1] = { pad = pad, base = only }
  end
  m.logPadQuests = pads
  local n = 0
  for _, e in ipairs(pads) do n = math.max(n, #e.pad - #e.base) end
  m.logPad = n
  return m
end

-- Simule les chapitres d'une faction.
--   1. Chapitres propres à une race (plan.races) : simulés pour la première race de leur chapitre de
--      départ (Nain pour Nain/Gnome, Orc pour Orc/Troll) ; l'état à l'entrée du tronc est noté.
--   2. Tronc commun : simulé une fois, dans l'ordre du parcours principal ; à chaque chapitre où
--      arrivent d'autres parcours, l'état est fusionné (build.mergeStates).
--   3. Filtres de race (build.raceFilters) : chaque parcours de race est rejoué (paths.replay) ; une
--      étape d'un chapitre partagé qui n'est pas valide pour une race reçoit un filtre `race` sans elle.
function build.simulateFaction(D, W, faction, ov, only)
  local list = plansm[faction]
  -- --only sur un chapitre propre à une race : seul le parcours de cette race jusqu'au chapitre est simulé
  local onlyPlan = only and plansm.find(only)
  local onlyLead
  if onlyPlan and onlyPlan.races then
    for _, p in ipairs(list) do
      if p.races and p.minLevel == 1 then
        for _, q in ipairs(plansm.pathFor(faction, p.races[1])) do if q.id == only then onlyLead = p.races[1] end end
      end
      if onlyLead then break end
    end
  end
  local leads = {}
  for _, p in ipairs(list) do
    if p.races and p.minLevel == 1 then leads[#leads + 1] = p.races[1] end
  end
  local results, order = {}, {}
  -- cartes des deux chapitres suivants sur le parcours de la race (rendus reportés)
  local function carryZones(plan, race)
    local path = plansm.pathFor(faction, race)
    local out, after = {}, nil
    for i, p in ipairs(path) do
      if p.id == plan.id then after = i end
    end
    if not after then return nil end
    for k = after + 1, math.min(after + 2, #path) do
      for _, m in ipairs(path[k].zones or {}) do out[#out + 1] = m end
      for _, m in ipairs(path[k].endZones or {}) do out[#out + 1] = m end
    end
    return out
  end
  -- point de départ du trajet vers le chapitre suivant du parcours (quai d'arrivée ou entrée)
  local function nextEntry(plan, race)
    local path = plansm.pathFor(faction, race)
    for i, p in ipairs(path) do
      local n = p.id == plan.id and path[i + 1]
      if n then return (n.arrive and n.arrive.via) or n.entry end
    end
  end
  local function run(plan, state, race, exitTo)
    local steps, report = sim.chapter(D, W, plan, state, { overrides = ov, carryZones = carryZones(plan, race),
      exitTo = exitTo, nextEntry = exitTo or nextEntry(plan, race) })
    build.applyInserts(plan.id, steps, ov)
    report.simRace = race
    results[plan.id] = { plan = plan, steps = steps, report = report }
    order[#order + 1] = plan.id
  end
  local entries, trunk, inTrunk = {}, {}, {}
  if onlyLead then
    local state = newState(onlyLead, faction)
    for _, plan in ipairs(plansm.pathFor(faction, onlyLead)) do
      if not plan.races then break end
      run(plan, state, onlyLead)
      if plan.id == only then break end
    end
    build.raceFilters(D, W, faction, results)
    return results, order
  end
  -- Point où le parcours principal entre dans le tronc ; un autre parcours qui rejoint le même
  -- chapitre depuis une autre région (Mort-vivant, Skyborne) y est conduit à la fin de son dernier
  -- chapitre de départ, avec ses propres points de vol (étapes valides pour lui).
  local joinPos = {}
  for _, lead in ipairs(leads) do
    local state = newState(lead, faction)
    local entered = false
    local path = plansm.pathFor(faction, lead)
    for i, plan in ipairs(path) do
      if plan.races then
        if not results[plan.id] then
          local nextPlan = path[i + 1]
          local exitTo
          if nextPlan and not nextPlan.races and lead ~= leads[1] then
            exitTo = joinPos[nextPlan.id] or nextPlan.entry
          end
          run(plan, state, lead, exitTo)
          if nextPlan and not nextPlan.races and lead == leads[1] and state.pos then
            joinPos[nextPlan.id] = { state.pos[1], state.pos[2], state.pos[3] }
          end
        end
      else
        if not entered then
          entered = true
          entries[plan.id] = entries[plan.id] or {}
          table.insert(entries[plan.id], { race = lead, state = state })
        end
        if not inTrunk[plan.id] then inTrunk[plan.id] = true; trunk[#trunk + 1] = plan end
      end
    end
  end
  local tstate, simRace
  for _, plan in ipairs(trunk) do
    local arriving, others = entries[plan.id] or {}, {}
    for k, e in ipairs(arriving) do
      if not tstate and k == 1 then tstate = copyState(e.state); simRace = e.race
      else others[#others + 1] = e.state end
    end
    if #others > 0 then
      local pad = tstate.logPad or 0
      tstate = build.mergeStates(tstate, others)
      tstate.logPad = math.max(pad, tstate.logPad or 0)
    end
    -- logPad reste pour la suite du tronc : les quêtes de donjon prises sans rendu (Ruins of
    -- Lordaeron pour les Morts-vivants...) occupent le journal de l'autre parcours jusqu'au bout
    run(plan, tstate, simRace)
  end
  build.raceFilters(D, W, faction, results)
  return results, order
end

-- Races de la faction (chapitres de départ), dans l'ordre des plans.
local function factionRaces(faction, list)
  local out = {}
  for _, p in ipairs(list or plansm[faction]) do
    if p.races and p.minLevel == 1 then for _, r in ipairs(p.races) do out[#out + 1] = r end end
  end
  return out
end
build.factionRaces = factionRaces

-- Filtres de race des chapitres partagés (voir build.simulateFaction, point 3). Les étapes valides
-- pour aucune race sont retirées. Renvoie la liste des problèmes des chapitres propres à une seule race
-- (laissés au validateur).
function build.raceFilters(D, W, faction, results, list)
  list = list or plansm[faction]
  local races = factionRaces(faction, list)
  local pathOf, through = {}, {}
  for _, race in ipairs(races) do
    pathOf[race] = plansm.pathIn(list, race)
    for _, plan in ipairs(pathOf[race]) do
      through[plan.id] = through[plan.id] or {}
      table.insert(through[plan.id], race)
    end
  end
  local leftover = {}
  local changed = true
  local guard = 0
  while changed and guard < 50 do
    changed, guard = false, guard + 1
    leftover = {}
    for _, race in ipairs(races) do
      local chapters = {}
      for _, plan in ipairs(pathOf[race]) do
        local r = results[plan.id]
        chapters[#chapters + 1] = { id = plan.id, steps = r and r.steps or {}, minLevel = plan.minLevel }
      end
      paths.replay(D, W, faction, race, chapters, function(ci, si, msg)
        local plan = pathOf[race][ci]
        local step = chapters[ci].steps[si]
        local via = through[plan.id] or {}
        if #via > 1 then
          local base = step.race or via
          local keep = {}
          for _, r in ipairs(base) do if r ~= race and paths.hasRace(via, r) then keep[#keep + 1] = r end end
          step.race = keep
          step._filtered = step._filtered or {}
          step._filtered[#step._filtered + 1] = race .. ": " .. msg
          changed = true
        else
          leftover[#leftover + 1] = ("%s[%s] step %d: %s"):format(plan.id, race, si, msg)
        end
      end)
    end
  end
  -- étapes sans aucune race : retirées ; filtre égal à toutes les races du chapitre : retiré
  for id, r in pairs(results) do
    local via = through[id] or {}
    local kept = {}
    for _, s in ipairs(r.steps) do
      if s.race and #s.race == 0 then
        r.report.warnings[#r.report.warnings + 1] = ("step removed (valid for no race): %s %s"):format(tostring(s[1]), tostring(s[2]))
      else
        if s.race and #via > 0 then
          local all = true
          for _, v in ipairs(via) do if not paths.hasRace(s.race, v) then all = false end end
          if all and #s.race >= #via and not r.plan.races then s.race = nil end
        end
        if s._filtered then
          for _, f in ipairs(s._filtered) do
            r.report.warnings[#r.report.warnings + 1] = ("race filter on %s %s (%s)"):format(tostring(s[1]), tostring(s[2]), f)
          end
          s._filtered = nil
        end
        kept[#kept + 1] = s
      end
    end
    r.steps = kept
  end
  return leftover
end

local function fmtTime(s) return ("%d min"):format(math.floor(s / 60 + 0.5)) end

-- Rapport Markdown d'un chapitre.
function build.reportText(D, plan, steps, report, meta)
  local out = {}
  local function w(s) out[#out + 1] = s or "" end
  w(("# %s — %s"):format(plan.id, plan.title or ""))
  w()
  w(("Generated on %s from QuestieDB commit `%s` by `tools/routebuilder/build.lua`. Simulated race: %s."):format(
    meta.date, meta.commit, report.simRace or "?"))
  w()
  w("| Item | Value |")
  w("|---|---|")
  w(("| Level band | %d-%d |"):format(plan.minLevel, plan.maxLevel))
  w(("| Simulated level | %.2f -> %.2f |"):format(report.startLevel or 0, report.endLevel or 0))
  w(("| Time | %s |"):format(fmtTime(report.time or 0)))
  w(("| XP gained | %d |"):format(report.xp or 0))
  w(("| XP/h | %d |"):format(math.floor((report.xpPerHour or 0) + 0.5)))
  w(("| Steps | %d |"):format(#steps))
  w(("| Quests turned in | %d |"):format(#(report.quests or {})))
  w(("| Hubs | %d |"):format(report.hubs or 0))
  w(("| Median ratio (XP/s) | %.2f |"):format(report.medianRatio or 0))
  if report.grindMobs then w(("| Grinding (level steps) | ~%d mobs |"):format(report.grindMobs)) end
  if report.widened then w(("| Level band | %s |"):format(report.widened)) end
  if report.hearthPlan then w(("| Hearthstone | %s |"):format(report.hearthPlan)) end
  w()
  w("## Kept quests (turn-in order)")
  w()
  w("XP marked `est.` is an estimate (no QuestXP value: new Forever quest).")
  w()
  w("| # | Quest | Name | Lvl | XP | Sim lvl |")
  w("|---|---|---|---|---|---|")
  for i, q in ipairs(report.quests or {}) do
    w(("| %d | %d | %s | %d | %d%s | %d |"):format(i, q.id, q.name or "?", q.level or 0, q.xp or 0,
      q.estimated and " est." or "", q.simLevel or 0))
  end
  w()
  w("## Dropped quests")
  w()
  if #(report.dropped or {}) == 0 then w("None.") else
    w("| Quest | Name | Lvl | Reason |")
    w("|---|---|---|---|")
    for _, d in ipairs(report.dropped) do
      local q = D.quests[d.id] or {}
      w(("| %d | %s | %s | %s |"):format(d.id, q.name or "?", tostring(q.level or "?"), d.reason))
    end
  end
  w()
  w("## Candidate ratios")
  w()
  w("Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;")
  w("marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are")
  w(("below %.2f × the median ratio, or when an objective is more than %d yd from every hub."):format(sim.CONST.LOW_RATIO, sim.CONST.FAR))
  w()
  w("| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |")
  w("|---|---|---|---|---|---|---|---|---|---|---|")
  for _, c in ipairs(report.candidates or {}) do
    w(("| %d | %s | %d | %d | %d | %d | %d | %.2f | %.2f | %d | %s |"):format(c.id, c.name or "?", c.level or 0,
      math.floor(c.value or 0), math.floor(c.bonus or 0), math.floor(c.isolatedTime or 0), math.floor(c.marginalTime or 0),
      c.ratio or 0, c.marginalRatio or 0, c.sites or 0, c.dropped or ""))
  end
  w()
  w("## Itinerary")
  w()
  w("One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line")
  w("yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within")
  w("150 yd of an earlier task after the route went more than 600 yd away from it.")
  w()
  w("| # | Task | Quest | Name | Map | x, y | Leg yd | Return |")
  w("|---|---|---|---|---|---|---|---|")
  local legs = report.legs or {}
  local total = 0
  for i, l in ipairs(legs) do
    local ret = ""
    for j = i - 2, 1, -1 do
      local e = legs[j]
      local d = l.pos and e.pos and l.pos.c == e.pos.c and math.sqrt((l.pos.wx - e.pos.wx) ^ 2 + (l.pos.wy - e.pos.wy) ^ 2) or math.huge
      if d <= 150 then
        local far = 0
        for k = j + 1, i - 1 do
          local f = legs[k]
          if f.pos and f.pos.c == l.pos.c then
            local dk = math.sqrt((f.pos.wx - l.pos.wx) ^ 2 + (f.pos.wy - l.pos.wy) ^ 2)
            if dk > far then far = dk end
          end
        end
        if far > 600 then ret = ("near #%d (went %d yd away)"):format(j, math.floor(far)) end
        break
      end
    end
    if l.yards then total = total + l.yards end
    w(("| %d | %s | %s | %s | %s | %.1f, %.1f | %s | %s |"):format(i, l.kind, tostring(l.q or ""), l.name or "",
      tostring(l.pos and l.pos.m or ""), l.pos and l.pos.x or 0, l.pos and l.pos.y or 0,
      l.yards and tostring(math.floor(l.yards)) or "", ret))
  end
  w()
  w(("Walking between tasks: %d yd (~%d min at 7 yd/s)."):format(math.floor(total), math.floor(total / 7 / 60 + 0.5)))
  w()
  w(quality.markdown(report.quality, legs))
  w("## Logistics")
  w()
  local any = false
  for i, s in ipairs(steps) do
    if s[1] ~= "accept" and s[1] ~= "complete" and s[1] ~= "turnin" then
      any = true
      local parts = {}
      for k = 1, #s do parts[#parts + 1] = tostring(s[k]) end
      w(("- step %d: `%s`%s"):format(i, table.concat(parts, " "), s.note and (" — " .. s.note) or ""))
    end
  end
  if not any then w("None.") end
  w()
  w("## Warnings")
  w()
  if #(report.warnings or {}) == 0 then w("None.") else
    for _, x in ipairs(report.warnings) do w("- " .. x) end
  end
  w()
  return table.concat(out, "\n")
end

-- Vrai si le fichier a été écrit par ce générateur (en-tête de emit.guide).
local function isGenerated(path)
  local f = io.open(path, "rb")
  if not f then return false end
  local head = f:read(400) or ""
  f:close()
  return head:find("Généré par tools/routebuilder", 1, true) ~= nil
end

-- Réécrit Guides.xml : les guides des plans présents dans out (ordre des plans), puis les fichiers
-- ajoutés à la main (non générés), puis ClassQuestData.lua. Un guide généré qui n'a plus de plan
-- (chapitre renommé ou supprimé) n'est plus chargé ; il est signalé.
function build.writeXml(out)
  local entries = {}
  local seen = {}
  for _, faction in ipairs({ "Alliance", "Horde" }) do
    for _, p in ipairs(plansm[faction]) do
      local rel = folderFor(p) .. "/" .. p.id .. ".lua"
      if fileExists(out .. "/" .. rel) and not seen[rel] then entries[#entries + 1] = rel; seen[rel] = true end
    end
  end
  -- fichiers présents mais absents des plans (ajoutés à la main), par ordre alphabétique
  for _, folder in ipairs({ "Alliance", "Horde", "Skyborne" }) do
    local extra = {}
    local p = io.popen("ls " .. shq(out .. "/" .. folder) .. " 2>/dev/null")
    for name in p:lines() do
      local rel = folder .. "/" .. name
      if name:match("%.lua$") and not seen[rel] then
        if isGenerated(out .. "/" .. rel) then
          io.stderr:write(("Guides.xml: %s is a generated guide without a plan, not listed\n"):format(rel))
        else extra[#extra + 1] = rel end
      end
    end
    p:close()
    table.sort(extra)
    for _, rel in ipairs(extra) do entries[#entries + 1] = rel; seen[rel] = true end
  end
  local lines = { '<Ui xmlns="http://www.blizzard.com/wow/ui/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
                  '    xsi:schemaLocation="http://www.blizzard.com/wow/ui/ ..\\FrameXML\\UI.xsd">',
                  '  <!-- Fichier réécrit par tools/routebuilder/build.lua : un <Script> par guide, puis ClassQuestData.lua. -->' }
  for _, rel in ipairs(entries) do lines[#lines + 1] = ('  <Script file="%s"/>'):format((rel:gsub("/", "\\"))) end
  lines[#lines + 1] = '  <Script file="ClassQuestData.lua"/>'
  lines[#lines + 1] = "</Ui>"
  writeFile(out .. "/Guides.xml", table.concat(lines, "\n") .. "\n")
  return #entries
end

function build.main(argv)
  local o = parseArgs(argv)
  if o.help then
    print("usage: luajit tools/routebuilder/build.lua [--db PATH] [--questie PATH] [--faction Alliance|Horde|all]")
    print("       [--only <planId>] [--report DIR] [--out DIR] [--overrides FILE] [--date YYYY-MM-DD] [--jit]")
    return 0
  end
  -- Suites des plans (next, nextByRace, choices) contrôlées avant de charger QuestieDB et de simuler.
  -- Seule la suite par défaut est simulée ; les autres choix ne sont pas rejoués.
  local errs = plansm.validate(plansm)
  if #errs > 0 then
    for _, e in ipairs(errs) do io.stderr:write(("plans.lua: %s: %s\n"):format(e.id, e.msg)) end
    io.stderr:write(("build stopped: %d error(s) in tools/routebuilder/plans.lua\n"):format(#errs))
    return 1
  end
  -- Interpréteur par défaut (résultat identique d'une exécution à l'autre) ; --jit pour aller plus vite.
  if jit and not o.jit then jit.off() end
  local factions = (o.faction == "all") and { "Alliance", "Horde" } or { o.faction }
  if o.only then
    local _, f = plansm.find(o.only)
    assert(f, "unknown plan " .. o.only)
    factions = { f }
  end
  local ov = build.loadOverrides(o.overrides)
  local W = world.load(here .. "/data")
  local Ds = {}
  local function D(f)
    if not Ds[f] then Ds[f] = qdb.load({ db = o.db, questie = o.questie, faction = f }) end
    return Ds[f]
  end
  mkdir(o.out)
  mkdir(o.report)
  local written = 0
  for _, faction in ipairs(factions) do
    local d = D(faction)
    local meta = { commit = d.commit, date = o.date }
    local results, order = build.simulateFaction(d, W, faction, ov, o.only)
    for _, id in ipairs(order) do
      local r = results[id]
      if not o.only or id == o.only then
        local dir = o.out .. "/" .. folderFor(r.plan)
        mkdir(dir)
        writeFile(dir .. "/" .. id .. ".lua", emit.guide(r.plan, r.steps, r.report, meta))
        writeFile(o.report .. "/" .. id .. ".md", build.reportText(d, r.plan, r.steps, r.report, meta))
        written = written + 1
        local rep = r.report
        local qa = rep.quality
        print(("%-18s steps %3d  quests %3d  dropped %3d  lvl %5.2f -> %5.2f  xp/h %6d  %s  quality R%d P%d A%d T%d%s"):format(id, #r.steps,
          #rep.quests, #rep.dropped, rep.startLevel or 0, rep.endLevel or 0, math.floor(rep.xpPerHour + 0.5),
          fmtTime(rep.time or 0), qa and #qa.revisits or 0, qa and #qa.pickups or 0, qa and #qa.areas or 0,
          qa and #qa.turnins or 0, (rep.endLevel or 0) < r.plan.maxLevel - 1 and "  [below maxLevel-1]" or ""))
      end
    end
  end
  -- données des quêtes de classe (les deux factions), puis Guides.xml
  local data = cq.merge(cq.build(D("Alliance")), cq.build(D("Horde")))
  writeFile(o.out .. "/ClassQuestData.lua", cq.emit(data, { commit = D("Alliance").commit, date = o.date }))
  local n = build.writeXml(o.out)
  print(("wrote %d guide file(s); Guides.xml lists %d guide(s) + ClassQuestData.lua"):format(written, n))
  return 0
end

if select(1, ...) == "--as-module" then return build end
os.exit(build.main(arg or {}))
