-- tools/validate_guides.lua : vérifie les guides générés contre QuestieDB (hors jeu, LuaJIT).
--
-- Usage : luajit tools/validate_guides.lua [--db PATH] [--questie PATH] [--guides DIR]
--   --guides : dossier qui contient Guides.xml (défaut Questify/Guides)
-- Chaque violation est affichée « <fichier>:<ligne> <message> » ; code de sortie 1 s'il y en a une.
--
-- Contrôles par étape : action valide ; quête connue ; quête éligible pour au moins une race du
-- chapitre (ou de la faction) ; coordonnées 0-100 sur une uiMap connue ; étape `fly` avec un `node`
-- (TaxiNodes.ID) connu et situé sur la carte de destination ; champ `classes` (étape propre à certaines
-- classes) : liste non vide de classFile connus (même règle que Q.Guides:Normalize), et pour une étape
-- de quête, chaque classe admise par le masque de classes de la quête.
-- Contrôles par parcours de race (tools/routebuilder/paths.lua, chaque race de chaque chapitre de
-- départ, en suivant next / nextByRace) : prérequis rendus avant l'accept, journal de 20 quêtes au
-- plus, complete / turnin seulement pour une quête du journal, pas d'accept après le rendu ni de
-- répétition d'un chapitre à l'autre, `obj` dans la liste des objectifs, vol vers un point de vol
-- découvert, pierre de foyer liée. Seule la suite par défaut est rejouée : les autres entrées de
-- `choices` ne le sont pas. Avec des étapes `classes` sur le parcours, il est rejoué une fois sans
-- elles (classes sans étape propre) puis une fois par classe nommée, avec les étapes de cette classe :
-- le journal de chaque classe est compté à part.
-- Contrôles des suites (plans.validate, comme build.lua sur plans.lua) : next / nextByRace vers des
-- guides chargés, `choices` de 2 à 4 guides de la même faction avec la suite par défaut ; champ `sim`
-- égal à l'en-tête « -- Simulation : » (tools/routebuilder/backfill.lua).

local here = (arg and arg[0] or ""):match("^(.*)[/\\]validate_guides%.lua$") or "tools"
package.path = here .. "/routebuilder/?.lua;" .. package.path

local qdb = require("qdb")
local world = require("world")
local paths = require("paths")
local plansm = require("plans")
local backfill = require("backfill")

local M = {}

local VALID = { accept = true, complete = true, turnin = true, ["goto"] = true, fp = true, sethearth = true,
                hearth = true, fly = true, boat = true, level = true, note = true }
local QUEST_ACTIONS = { accept = true, complete = true, turnin = true }
local POINT_ACTIONS = { ["goto"] = true, fp = true, sethearth = true, boat = true }

local RACE_BITS = { Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Undead = 16, Tauren = 32, Gnome = 64, Troll = 128 }
local FACTION_RACES = {
  Alliance = { "Human", "Dwarf", "NightElf", "Gnome", "Skyborne" },
  Horde = { "Orc", "Undead", "Tauren", "Troll", "Skyborne" },
}
local function raceBit(race, faction)
  if race == "Skyborne" then return faction == "Horde" and 8589934592 or 4294967296 end
  return RACE_BITS[race]
end

-- Étapes propres à une classe (champ `classes`) : mêmes noms que Q.CLASS_BITS (Data/Constants.lua).
local KNOWN_CLASSES = qdb.CLASS_BITS

local function classNames(v)
  if type(v) == "string" then return { v } end
  if type(v) == "table" then return v end
  return nil
end

-- classesProblem(valeur du champ classes) -> nil si valide (ou absent), sinon le message.
function M.classesProblem(v)
  if v == nil then return nil end
  local list = classNames(v)
  if not list then return "classes must be a list of class names" end
  for _, c in ipairs(list) do
    if type(c) ~= "string" then return "classes must be a list of class names" end
  end
  if #list == 0 then return "classes must name at least one class" end
  for _, c in ipairs(list) do
    if not KNOWN_CLASSES[c] then return ("unknown class '%s' in classes"):format(c) end
  end
  return nil
end

-- classVariants(chapitres) -> classes connues nommées par les étapes `classes` du parcours, triées.
function M.classVariants(chapters)
  local seen, out = {}, {}
  for _, ch in ipairs(chapters) do
    for _, s in ipairs(ch.steps or {}) do
      if type(s) == "table" then
        for _, c in ipairs(classNames(s.classes) or {}) do
          if KNOWN_CLASSES[c] and not seen[c] then seen[c] = true; out[#out + 1] = c end
        end
      end
    end
  end
  table.sort(out)
  return out
end

-- stepsForClass(étapes, classe | nil) -> étapes vues par cette classe (nil : seulement les étapes sans
-- `classes`), index d'origine de chacune.
function M.stepsForClass(steps, cls)
  local out, index = {}, {}
  for i, s in ipairs(steps or {}) do
    local keep = true
    local list = type(s) == "table" and classNames(s.classes)
    if list then
      keep = false
      for _, c in ipairs(list) do if cls and c == cls then keep = true end end
    end
    if keep then
      out[#out + 1] = s
      index[#out] = i
    end
  end
  return out, index
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

-- Lignes des étapes : la k-ième ligne qui commence par `{ "action"` dans le bloc steps.
local function stepLines(text)
  local lines, inSteps, n = {}, false, 0
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    n = n + 1
    if line:match("^%s*steps%s*=%s*{") then inSteps = true
    elseif inSteps and line:match('^%s*{%s*"') then lines[#lines + 1] = n end
  end
  return lines
end

local function loadGuide(path)
  local text = readFile(path)
  if not text then return nil, "cannot read file" end
  if text:byte(1) == 27 then return nil, "bytecode refused" end
  local fn, err = loadstring(text, "@" .. path)
  if not fn then return nil, err end
  local defs = {}
  local Q = {}
  function Q:RegisterGuide(def) defs[#defs + 1] = def end
  setfenv(fn, {})
  local ok, e = pcall(fn, "Questify", Q)
  if not ok then return nil, e end
  return defs, nil, stepLines(text), Q, text
end

-- Numéro de la première ligne du texte qui correspond au motif (0 si aucune).
local function lineOf(text, pattern)
  local n = 0
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    n = n + 1
    if line:match(pattern) then return n end
  end
  return 0
end

function M.run(argv)
  local opts = { db = qdb.DEFAULT_DB, questie = qdb.DEFAULT_QUESTIE, guides = "Questify/Guides" }
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--db" then opts.db = argv[i + 1]; i = i + 1
    elseif a == "--questie" then opts.questie = argv[i + 1]; i = i + 1
    elseif a == "--guides" then opts.guides = argv[i + 1]; i = i + 1
    else io.stderr:write("unknown argument " .. a .. "\n"); return 2 end
    i = i + 1
  end
  local violations = {}
  local function bad(file, line, msg) violations[#violations + 1] = ("%s:%d %s"):format(file, line or 0, msg) end

  local xml = readFile(opts.guides .. "/Guides.xml")
  if not xml then
    print(opts.guides .. "/Guides.xml:0 missing Guides.xml")
    return 1
  end
  local files = {}
  for f in xml:gmatch('<Script%s+file%s*=%s*"([^"]+)"') do files[#files + 1] = (f:gsub("\\", "/")) end

  local W = world.load(here .. "/routebuilder/data")
  local Ds = {}
  local function D(faction)
    faction = faction or "Alliance"
    if not Ds[faction] then Ds[faction] = qdb.load({ db = opts.db, questie = opts.questie, faction = faction }) end
    return Ds[faction]
  end

  -- chargement de tous les guides
  local guides, byId = {}, {}
  for _, rel in ipairs(files) do
    local path = opts.guides .. "/" .. rel
    local defs, err, lines, Q, text = loadGuide(path)
    if not defs then
      bad(path, 0, "load error: " .. tostring(err))
    elseif rel:match("ClassQuestData%.lua$") then
      if type(Q.ClassQuestData) ~= "table" then bad(path, 0, "ClassQuestData missing") end
    else
      if #defs ~= 1 then bad(path, 0, ("expected one RegisterGuide call, got %d"):format(#defs)) end
      for _, def in ipairs(defs) do
        if type(def.id) ~= "string" then bad(path, 0, "guide without id")
        elseif byId[def.id] then bad(path, 0, "duplicate guide id " .. def.id)
        else
          local g = { def = def, path = path, lines = lines, text = text }
          guides[#guides + 1] = g
          byId[def.id] = g
        end
      end
    end
  end

  -- suites (next, nextByRace, choices) : même contrôle que build.lua sur plans.lua
  local byFaction = { Alliance = {}, Horde = {} }
  for _, g in ipairs(guides) do table.insert(byFaction[g.def.faction == "Horde" and "Horde" or "Alliance"], g.def) end
  for _, e in ipairs(plansm.validate(byFaction)) do
    local g = byId[e.id]
    local line = g and lineOf(g.text, "^%s*choices%s*=")
    if g and line == 0 then line = lineOf(g.text, "^%s*next") end
    bad(g and g.path or "?", line, e.msg)
  end
  -- champ sim : valeurs de l'en-tête « -- Simulation : » (lu par le jeu, l'en-tête ne l'est pas)
  for _, g in ipairs(guides) do
    local want = backfill.parseSim(g.text)
    local got = g.def.sim
    if want then
      local same = type(got) == "table"
      for k, v in pairs(want) do
        if same and (type(got[k]) ~= "number" or math.abs(got[k] - v) > 1e-9) then same = false end
      end
      if not same then
        bad(g.path, lineOf(g.text, "^%s*sim%s*="), "sim field missing or different from the Simulation header (run tools/routebuilder/backfill.lua)")
      end
    end
  end

  -- quêtes prises / rendues par chapitre (pour les contrôles entre chapitres)
  local accepted, turned = {}, {}
  for _, g in ipairs(guides) do
    accepted[g.def.id], turned[g.def.id] = {}, {}
    for _, s in ipairs(g.def.steps or {}) do
      if type(s) == "table" then
        if s[1] == "accept" then accepted[g.def.id][s[2]] = true end
        if s[1] == "turnin" then turned[g.def.id][s[2]] = true end
      end
    end
  end

  -- Parcours par race : depuis chaque chapitre de départ (races + minLevel 1), on suit
  -- nextByRace[race] puis next, et on rejoue les étapes (paths.replay) : prérequis rendus, journal de
  -- 20 quêtes au plus, pas de complete / turnin hors du journal, pas d'accept après le rendu, index
  -- `obj` valide, vols vers des points de vol découverts, pierre de foyer liée. Une étape d'un
  -- chapitre commun qui n'est pas valide pour une race doit porter un filtre `race` sans elle.
  local onPath = {}
  local pathIssues, issueOrder = {}, {}
  for _, g in ipairs(guides) do
    local def = g.def
    if def.races and (def.minLevel or 1) <= 1 then
      local faction = def.faction == "Horde" and "Horde" or "Alliance"
      for _, race in ipairs(def.races) do
        local chain, seen = {}, {}
        local cur = g
        while cur and not seen[cur.def.id] do
          seen[cur.def.id] = true
          chain[#chain + 1] = cur
          onPath[cur.def.id] = true
          local nid = (cur.def.nextByRace and cur.def.nextByRace[race]) or cur.def.next
          cur = nid and byId[nid] or nil
        end
        local chapters = {}
        for _, cg in ipairs(chain) do
          chapters[#chapters + 1] = { id = cg.def.id, steps = cg.def.steps or {}, minLevel = cg.def.minLevel }
        end
        -- variante false : sans étape de classe ; puis une variante par classe nommée sur le parcours
        local variants = { false }
        for _, c in ipairs(M.classVariants(chapters)) do variants[#variants + 1] = c end
        for _, cls in ipairs(variants) do
          local vchapters, indexes = {}, {}
          for k, ch in ipairs(chapters) do
            local steps, index = M.stepsForClass(ch.steps, cls or nil)
            vchapters[k] = { id = ch.id, steps = steps, minLevel = ch.minLevel }
            indexes[k] = index
          end
          paths.replay(D(faction), W, faction, race, vchapters, function(ci, fsi, msg)
            local cg = chain[ci]
            local si = indexes[ci][fsi]
            local key = cg.path .. ":" .. tostring(si) .. ":" .. msg
            local it = pathIssues[key]
            if not it then
              it = { path = cg.path, line = cg.lines[si], msg = msg, races = {}, raceSeen = {}, classes = {},
                     classSeen = {}, base = false }
              pathIssues[key] = it
              issueOrder[#issueOrder + 1] = key
            end
            if not it.raceSeen[race] then it.raceSeen[race] = true; table.insert(it.races, race) end
            if not cls then
              it.base = true
            elseif not it.classSeen[cls] then
              it.classSeen[cls] = true; table.insert(it.classes, cls)
            end
          end)
        end
      end
    end
  end
  for _, key in ipairs(issueOrder) do
    local it = pathIssues[key]
    -- relevé seulement avec les étapes de certaines classes : on les nomme
    local cls = (not it.base and #it.classes > 0) and (", class: " .. table.concat(it.classes, ",")) or ""
    bad(it.path, it.line, ("%s (race path: %s%s)"):format(it.msg, table.concat(it.races, ","), cls))
  end

  for _, g in ipairs(guides) do
    local def, path = g.def, g.path
    local faction = def.faction
    if faction ~= "Alliance" and faction ~= "Horde" then bad(path, 0, "invalid faction " .. tostring(faction)) end
    local d = D(faction == "Horde" and "Horde" or "Alliance")
    local chapterRaces = def.races or FACTION_RACES[faction] or FACTION_RACES.Alliance
    local seenAccept, seenTurnin = {}, {}
    if type(def.steps) ~= "table" or #def.steps == 0 then bad(path, 0, "guide has no steps") end
    for k, s in ipairs(def.steps or {}) do
      local line = g.lines[k] or 0
      if type(s) ~= "table" then bad(path, line, "step is not a table")
      else
        local action = s[1]
        if not VALID[action] then bad(path, line, "invalid action " .. tostring(action))
        else
          local function checkPoint(m, x, y, label)
            if type(m) ~= "number" or not W.maps[m] or not W.maps[m].continent then
              bad(path, line, ("%s on unknown uiMap %s"):format(label, tostring(m)))
            elseif type(x) ~= "number" or type(y) ~= "number" or x < 0 or x > 100 or y < 0 or y > 100 then
              bad(path, line, ("%s coordinates out of 0-100: %s, %s"):format(label, tostring(x), tostring(y)))
            end
          end
          local classesErr = M.classesProblem(s.classes)
          if classesErr then bad(path, line, classesErr) end
          if s.at then checkPoint(s.at[1], s.at[2], s.at[3], "at") end
          if POINT_ACTIONS[action] then checkPoint(s[2], s[3], s[4], action) end
          if (action == "hearth" or action == "fly") and (type(s[2]) ~= "number" or not W.maps[s[2]]) then
            bad(path, line, action .. " to unknown uiMap " .. tostring(s[2]))
          end
          -- vol : nœud de destination (TaxiNodes.ID = nodeID de C_TaxiMap) présent sur la carte de destination
          if action == "fly" then
            local n = s.node
            if n == nil then bad(path, line, "fly step without node")
            elseif type(n) ~= "number" or not W.taxi.nodes[n] then bad(path, line, "fly to unknown flight node " .. tostring(n))
            else
              local node, m = W.taxi.nodes[n], W.maps[s[2]]
              local x, y
              if m and m.continent == node.continent then x, y = W.fromWorld(s[2], node.wx, node.wy) end
              if not x or x < 0 or x > 100 or y < 0 or y > 100 then
                bad(path, line, ("flight node %d (%s) is not on uiMap %s"):format(n, node.name, tostring(s[2])))
              end
            end
          end
          if action == "level" and type(s[2]) ~= "number" then bad(path, line, "level step without a level") end
          if action == "note" and type(s[2]) ~= "string" then bad(path, line, "note step without text") end
          if QUEST_ACTIONS[action] then
            local qid = s[2]
            local q = type(qid) == "number" and d.quests[qid]
            if not q then
              bad(path, line, "unknown quest " .. tostring(qid))
            else
              local races = s.race or chapterRaces
              local ok = (q.races or 0) == 0
              for _, r in ipairs(races) do
                local b = raceBit(r, faction)
                if b and qdb.hasBit(q.races, b) then ok = true end
              end
              if not ok then bad(path, line, ("quest %d not available to %s"):format(qid, table.concat(races, ","))) end
              -- étape de classe : chaque classe nommée doit pouvoir faire la quête
              if not classesErr and (q.classes or 0) ~= 0 then
                for _, c in ipairs(classNames(s.classes) or {}) do
                  if not qdb.hasBit(q.classes, KNOWN_CLASSES[c]) then
                    bad(path, line, ("quest %d not available to class %s"):format(qid, c))
                  end
                end
              end
              -- guide hors de tout parcours de race : contrôle limité au chapitre lui-même
              if not onPath[def.id] then
                if action == "accept" then
                  if seenTurnin[qid] then bad(path, line, ("accept after turnin of quest %d"):format(qid)) end
                  seenAccept[qid] = true
                else
                  if not seenAccept[qid] and #(q.starters.items or {}) == 0 then
                    bad(path, line, ("%s without accept (quest %d)"):format(action, qid))
                  end
                  if action == "turnin" then seenTurnin[qid] = true end
                end
              end
            end
          end
        end
      end
    end
  end

  for _, v in ipairs(violations) do print(v) end
  if #violations > 0 then
    print(("%d violation(s) in %d guide file(s)"):format(#violations, #guides))
    return 1
  end
  print(("OK: %d guide file(s), no violation"):format(#guides))
  return 0
end

if select(1, ...) == "--as-module" then return M end
os.exit(M.run(arg or {}))
