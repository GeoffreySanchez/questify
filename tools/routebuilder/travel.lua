-- tools/routebuilder/travel.lua : durée du trajet de la fin d'un chapitre vers chacun de ses choix de
-- suite (champ `choices` de plans.lua), calculée avec le code de trajet du générateur (sim.route :
-- marche dans une région, vols entre points de vol connus, liaisons de transport.lua), sans QuestieDB :
-- les positions sont relues dans les guides et les rapports déjà générés.
--
-- Usage : luajit tools/routebuilder/travel.lua <planId> [--guides DIR] [--report DIR]
--   Affiche, pour chaque choix, le genre de trajet et les minutes calculés, à reporter dans plans.lua
--   (travel = { kind = ..., minutes = ... }). Code de sortie 1 si plans.lua donne d'autres valeurs.
--
-- Données :
--   départ  : `at` de la dernière étape du guide du chapitre si elle en a une, sinon dernière tâche de
--             l'itinéraire de son rapport (<report>/<planId>.md, colonnes Map et x, y) ;
--   arrivée : première tâche de l'itinéraire du rapport du chapitre cible, à défaut son `entry` ;
--   race    : race simulée du rapport (« Simulated race: »), à défaut la première race du plan ;
--   vols    : points de vol découverts (étapes `fp`) dans les guides du parcours de cette race, jusqu'au
--             chapitre compris (plans.pathFor) ;
--   foyer   : ignoré (la recharge de la pierre n'est pas connue hors simulation).
-- Minutes = secondes du trajet / 60, arrondies à l'entier le plus proche (comme les en-têtes de guide).

local here = (arg and arg[0] or ""):match("^(.*)[/\\]travel%.lua$") or "tools/routebuilder"
package.path = here .. "/?.lua;" .. package.path

local world = require("world")
local sim = require("sim")
local plansm = require("plans")

local travel = {}
travel.DATA = here .. "/data"

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

local function hasRace(list, race)
  for _, r in ipairs(list or {}) do if r == race then return true end end
  return false
end

-- Dossier d'un guide sous Questify/Guides (même règle que build.lua).
function travel.folderFor(plan)
  if plan.id:find("_Skyborne_", 1, true) then return "Skyborne" end
  return plan.faction
end

-- Définition d'un guide généré (Q:RegisterGuide factice, environnement vide) ou nil.
function travel.loadGuide(path)
  local text = readFile(path)
  if not text or text:byte(1) == 27 then return nil end
  local fn = loadstring(text, "@" .. path)
  if not fn then return nil end
  local def
  local Q = {}
  function Q:RegisterGuide(d) def = d end
  setfenv(fn, {})
  if not pcall(fn, "Questify", Q) then return nil end
  return def
end

-- Rapport Markdown d'un chapitre : race simulée et itinéraire { { kind, q, m, x, y }, ... }.
function travel.readReport(path)
  local text = readFile(path)
  if not text then return nil end
  local out = { race = text:match("Simulated race: (%w+)%."), itinerary = {} }
  local inIt = false
  for line in text:gmatch("[^\r\n]+") do
    if line:match("^## ") then inIt = line == "## Itinerary" end
    if inIt then
      local cells = {}
      for c in line:gmatch("|([^|]*)") do cells[#cells + 1] = c:match("^%s*(.-)%s*$") end
      local x, y = (cells[6] or ""):match("^([%d%.%-]+), ([%d%.%-]+)$")
      if tonumber(cells[1]) and tonumber(cells[5]) and x then
        out.itinerary[#out.itinerary + 1] = { kind = cells[2], q = tonumber(cells[3]), m = tonumber(cells[5]),
                                              x = tonumber(x), y = tonumber(y) }
      end
    end
  end
  return out
end

-- Genre de trajet d'un tronçon de sim.route (valeurs de `travel.kind`).
local function legKind(leg)
  if leg.kind == "link" then
    local l = leg.link
    if l.kind == "portal" then return "portal" end
    if l.id and l.id:match("^tram_") then return "tram" end
    if l.id and l.id:match("^zep_") then return "zeppelin" end
    return "boat"
  end
  return leg.kind -- walk, fly, hearth
end

-- Trajet de `from` à `to` ({ mapId, x, y }) pour une faction et une race, avec les points de vol connus
-- `fps` (positions { mapId, x, y } des étapes fp). Renvoie secondes, genre principal (premier tronçon
-- qui n'est pas de la marche, sinon "walk") et tronçons ; nil si aucun trajet.
function travel.estimate(W, faction, race, from, to, fps)
  local a = sim.mkPos(W, from[1], from[2], from[3])
  local b = sim.mkPos(W, to[1], to[2], to[3])
  if not a or not b then return nil end
  local known, fms = {}, {}
  for i, p in ipairs(fps or {}) do
    local pos = sim.mkPos(W, p[1], p[2], p[3])
    local node, d
    if pos then node, d = W.nearestTaxi(pos.c, pos.wx, pos.wy, faction) end
    if node and d <= 100 and not known[node.id] then
      known[node.id] = true
      fms[#fms + 1] = { npc = i, pos = pos, node = node.id }
    end
  end
  local ctx = { W = W, faction = faction,
                state = { race = race, knownTaxi = known, hearth = nil, hearthReadyAt = 0, time = 0 } }
  local legs
  -- marche courte : directe, sans chercher de vol ni de liaison (comme sim.travel)
  if sim.regionOf(a) == sim.regionOf(b) and sim.yards(a, b) / sim.CONST.WALK <= sim.CONST.ROUTE_MIN then
    legs = { { kind = "walk", time = sim.yards(a, b) / sim.CONST.WALK, from = a, to = b } }
  else
    legs = sim.route(ctx, a, b, fms)
  end
  if not legs then return nil end
  local seconds, kind = 0, nil
  for _, leg in ipairs(legs) do
    seconds = seconds + leg.time
    if not kind and leg.kind ~= "walk" then kind = legKind(leg) end
  end
  return seconds, kind or "walk", legs
end

-- Trajets d'un plan vers chacun de ses choix. opts = { guides = DIR, report = DIR, W = monde }.
-- Renvoie { { id, kind, minutes, seconds, legs, declared = entrée de plans.lua }, ... } ou nil, erreur.
function travel.forPlan(planId, opts)
  opts = opts or {}
  local guides, report = opts.guides or "Questify/Guides", opts.report or "docs/routes"
  local plan, faction = plansm.find(planId)
  if not plan then return nil, "unknown plan " .. tostring(planId) end
  if not plan.choices then return nil, planId .. " has no choices" end
  local rep = travel.readReport(report .. "/" .. planId .. ".md")
  if not rep or #rep.itinerary == 0 then return nil, "no itinerary in " .. report .. "/" .. planId .. ".md" end
  local race = rep.race or (plan.races and plan.races[1])
  if not race then return nil, "no simulated race for " .. planId end
  local W = opts.W or world.load(travel.DATA)
  -- points de vol découverts sur le parcours de la race, jusqu'au chapitre compris
  local fps = {}
  local def
  for _, p in ipairs(plansm.pathFor(faction, race)) do
    local d = travel.loadGuide(guides .. "/" .. travel.folderFor(p) .. "/" .. p.id .. ".lua")
    if not d then return nil, "cannot load guide " .. p.id end
    for _, s in ipairs(d.steps or {}) do
      if s[1] == "fp" and (not s.race or hasRace(s.race, race)) then fps[#fps + 1] = { s[2], s[3], s[4] } end
    end
    if p.id == planId then def = d; break end
  end
  if not def then return nil, planId .. " is not on the " .. race .. " path" end
  local last = def.steps[#def.steps]
  local from = last and last.at or rep.itinerary[#rep.itinerary]
  from = { from.m or from[1], from.x or from[2], from.y or from[3] }
  local out = {}
  for _, c in ipairs(plan.choices) do
    local target = plansm.find(c.id)
    local trep = travel.readReport(report .. "/" .. c.id .. ".md")
    local first = trep and trep.itinerary[1]
    local to = first and { first.m, first.x, first.y } or (target and target.entry)
    local r = { id = c.id, declared = c, from = from, to = to }
    if to then
      local seconds, kind, legs = travel.estimate(W, faction, race, from, to, fps)
      if seconds then
        r.seconds, r.kind, r.legs = seconds, kind, legs
        r.minutes = math.floor(seconds / 60 + 0.5)
      end
    end
    out[#out + 1] = r
  end
  return out
end

local function fmtPos(p) return ("%s %.1f, %.1f"):format(tostring(p.m or p[1]), p.x or p[2], p.y or p[3]) end

function travel.main(argv)
  local planId, opts = nil, {}
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--guides" then opts.guides = argv[i + 1]; i = i + 1
    elseif a == "--report" then opts.report = argv[i + 1]; i = i + 1
    elseif not planId and a:sub(1, 1) ~= "-" then planId = a
    else io.stderr:write("unknown argument " .. tostring(a) .. "\n"); return 2 end
    i = i + 1
  end
  if not planId then
    print("usage: luajit tools/routebuilder/travel.lua <planId> [--guides DIR] [--report DIR]")
    return 2
  end
  local res, err = travel.forPlan(planId, opts)
  if not res then io.stderr:write(err .. "\n"); return 1 end
  local differs = false
  for _, r in ipairs(res) do
    if not r.seconds then
      print(("%-18s no route"):format(r.id))
      differs = true
    else
      local legs = {}
      for _, l in ipairs(r.legs) do
        legs[#legs + 1] = ("%s %ds -> %s"):format(legKind(l), math.floor(l.time + 0.5), fmtPos(l.to))
      end
      local d = r.declared.travel or {}
      local same = d.kind == r.kind and d.minutes == r.minutes
      if not same then differs = true end
      print(("%-18s kind %-8s %4d s = %d min  (plans.lua: %s %s)%s"):format(r.id, r.kind, math.floor(r.seconds + 0.5),
        r.minutes, tostring(d.kind), tostring(d.minutes), same and "" or "  DIFFERS"))
      print(("%-18s from %s: %s"):format("", fmtPos(r.from), table.concat(legs, "; ")))
    end
  end
  return differs and 1 or 0
end

-- require("travel") (tests, backfill) : module ; luajit tools/routebuilder/travel.lua : commande.
if select(1, ...) == "--as-module" or not (arg and arg[0] and arg[0]:match("travel%.lua$")) then return travel end
os.exit(travel.main(arg or {}))
