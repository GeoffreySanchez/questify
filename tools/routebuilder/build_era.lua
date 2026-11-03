-- tools/routebuilder/build_era.lua : route courte Classic Era (Nain / Gnome 1-12) pour tester l'addon.
--
-- Usage (depuis la racine du projet) :
--   luajit tools/routebuilder/build_era.lua [--db PATH] [--questie PATH] [--out DIR] [--report DIR]
--          [--date AAAA-MM-JJ] [--no-validate] [--validate-only]
--
--   --out     dossier des guides (défaut Questify_Vanilla/Guides) : <out>/Era/<planId>.lua,
--             <out>/Era/ClassQuestDataEra.lua et <out>/GuidesEra.xml
--   --report  rapports Markdown (défaut docs/routes_era)
--   --validate-only  ne régénère rien : valide les guides Era déjà écrits (utilisé par tools/package.sh)
--
-- Réutilise en lecture seule les modules du flux E (qdb, world, sim, emit, paths, classquests, build) :
--   - données QuestieDB vue Era (qdb_era.lua : redirection des fichiers Forever vers Classic) ;
--   - tables DB2 Classic Era 1.15.9.70576 de wago.tools dans data_era/ ;
--   - validation : tools/validate_guides.lua exécuté sur ces guides, avec la vue Era et data_era.
-- Aucun fichier du flux E n'est modifié ; les redirections ne vivent que dans ce processus.

local here = (arg and arg[0] or ""):match("^(.*)[/\\]build_era%.lua$") or "tools/routebuilder"
package.path = here .. "/?.lua;" .. package.path

local qdb = require("qdb")
local qdbEra = require("qdb_era")
local world = require("world")
local sim = require("sim")
local emit = require("emit")
local cq = require("classquests")
local paths = require("paths")
local build = assert(loadfile(here .. "/build.lua"))("--as-module")

local DUN_MOROGH, IRONFORGE = 1426, 1455

-- Plans Era (même forme que plans.lua). Identifiants préfixés ERA_ : jamais chargés sur Forever.
local PLANS = {
  {
    id = "ERA_A_DwarfGnome_01", title = "Coldridge Valley", faction = "Alliance", races = { "Dwarf", "Gnome" },
    zones = { DUN_MOROGH }, bounds = { [DUN_MOROGH] = { 19, 57, 38, 85 } }, endZones = { DUN_MOROGH },
    minLevel = 1, maxLevel = 6, entry = { DUN_MOROGH, 29.93, 71.20 }, next = "ERA_A_DwarfGnome_02",
  },
  {
    id = "ERA_A_DwarfGnome_02", title = "Dun Morogh", faction = "Alliance", races = { "Dwarf", "Gnome" },
    zones = { DUN_MOROGH, IRONFORGE }, endZones = { DUN_MOROGH, IRONFORGE },
    minLevel = 6, maxLevel = 12, entry = { DUN_MOROGH, 46.7, 53.8 },
    flightPaths = { "Ironforge, Dun Morogh" },
  },
}

local function parseArgs(argv)
  local o = { db = qdb.DEFAULT_DB, questie = qdb.DEFAULT_QUESTIE, out = "Questify_Vanilla/Guides",
              report = "docs/routes_era", date = os.date("%Y-%m-%d"), validate = true }
  local i = 1
  while i <= #argv do
    local a, v = argv[i], argv[i + 1]
    if a == "--db" then o.db = v
    elseif a == "--questie" then o.questie = v
    elseif a == "--out" then o.out = v
    elseif a == "--report" then o.report = v
    elseif a == "--date" then o.date = v
    elseif a == "--no-validate" then o.validate = false; i = i - 1
    elseif a == "--validate-only" then o.validateOnly = true; i = i - 1
    else error("unknown argument " .. tostring(a)) end
    i = i + 2
  end
  return o
end

local function writeFile(path, text)
  local f = assert(io.open(path, "wb"), "cannot write " .. path)
  f:write(text); f:close()
end

local function mkdir(path) os.execute("mkdir -p " .. build.shq(path)) end

-- En-tête de emit.guide : on indique le bon script à relancer.
local function eraHeader(text)
  text = text:gsub("corriger tools/routebuilder/plans%.lua ou overrides%.lua, puis relancer tools/routebuilder/build%.lua%.",
    "corriger les plans de tools/routebuilder/build_era.lua, puis le relancer (route Classic Era).")
  return text
end

local function fmtTime(s) return ("%d min"):format(math.floor(s / 60 + 0.5)) end

-- Valide les guides écrits avec tools/validate_guides.lua (flux E, inchangé) : qdb.load et
-- world.load sont redirigés vers la vue Era le temps de l'appel.
local function validate(o, files)
  local dir = here .. "/data_era/validate"
  mkdir(dir)
  -- chemins relatifs à <dir> (le validateur lit <dir>/<fichier>)
  local up = "../../../../"
  local lines = { "<Ui>" }
  for _, rel in ipairs(files) do lines[#lines + 1] = ('  <Script file="%s%s/%s"/>'):format(up, o.out, rel) end
  lines[#lines + 1] = "</Ui>"
  writeFile(dir .. "/Guides.xml", table.concat(lines, "\n") .. "\n")
  local M = assert(loadfile("tools/validate_guides.lua"))("--as-module")
  local origLoad, origWorld = qdb.load, world.load
  qdb.load = function(opts) return qdbEra.load(opts) end
  world.load = function(d)
    if d:match("routebuilder/data$") then d = here .. "/data_era" end
    return origWorld(d)
  end
  local ok, rc = pcall(M.run, { "--db", o.db, "--questie", o.questie, "--guides", dir })
  qdb.load, world.load = origLoad, origWorld
  if not ok then error(rc, 0) end
  return rc
end

local function main(argv)
  local o = parseArgs(argv)
  if jit then jit.off() end
  if o.validateOnly then
    local files = {}
    for _, plan in ipairs(PLANS) do files[#files + 1] = "Era/" .. plan.id .. ".lua" end
    return validate(o, files)
  end
  local W = world.load(here .. "/data_era")
  local DA = qdbEra.load({ db = o.db, questie = o.questie, faction = "Alliance" })
  local meta = { commit = DA.commit .. " (vue Classic Era)", date = o.date }
  local ov = { force = {}, drop = {}, pin = {}, insertAfter = {} }

  -- Simulation : parcours Nain (premier race du chapitre de départ), puis filtres de race Gnome.
  local state = { level = 1, xp = 0, pos = nil, done = {}, log = {}, knownTaxi = {}, hearth = nil, hearthReadyAt = 0,
                  time = 0, race = "Dwarf", raceBits = qdb.RACE_BITS.Dwarf, classBit = nil }
  local results = {}
  for _, plan in ipairs(PLANS) do
    local steps, report = sim.chapter(DA, W, plan, state, { overrides = ov })
    report.simRace = "Dwarf"
    results[plan.id] = { plan = plan, steps = steps, report = report }
  end
  local leftover = build.raceFilters(DA, W, "Alliance", results, PLANS)
  for _, l in ipairs(leftover) do io.stderr:write("race path issue: " .. l .. "\n") end

  local eraDir = o.out .. "/Era"
  mkdir(eraDir)
  mkdir(o.report)
  local files = {}
  for _, plan in ipairs(PLANS) do
    local r = results[plan.id]
    local rel = "Era/" .. plan.id .. ".lua"
    writeFile(o.out .. "/" .. rel, eraHeader(emit.guide(plan, r.steps, r.report, meta)))
    writeFile(o.report .. "/" .. plan.id .. ".md", build.reportText(DA, plan, r.steps, r.report, meta))
    files[#files + 1] = rel
    local rep = r.report
    print(("%-20s steps %3d  quests %3d  dropped %3d  lvl %5.2f -> %5.2f  xp/h %6d  %s"):format(plan.id, #r.steps,
      #rep.quests, #rep.dropped, rep.startLevel or 0, rep.endLevel or 0, math.floor((rep.xpPerHour or 0) + 0.5),
      fmtTime(rep.time or 0)))
  end

  -- Quêtes de classe recalculées sur les données Era (les deux factions).
  local DH = qdbEra.load({ db = o.db, questie = o.questie, faction = "Horde" })
  local data = cq.merge(cq.build(DA), cq.build(DH))
  local cqText = cq.emit(data, { commit = meta.commit, date = o.date })
  writeFile(eraDir .. "/ClassQuestDataEra.lua", cqText)

  local xml = { '<Ui xmlns="http://www.blizzard.com/wow/ui/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
                '    xsi:schemaLocation="http://www.blizzard.com/wow/ui/ ..\\FrameXML\\UI.xsd">',
                '  <!-- Fichier réécrit par tools/routebuilder/build_era.lua : guides Classic Era, puis leurs quêtes de classe. -->' }
  for _, rel in ipairs(files) do xml[#xml + 1] = ('  <Script file="%s"/>'):format((rel:gsub("/", "\\"))) end
  xml[#xml + 1] = '  <Script file="Era\\ClassQuestDataEra.lua"/>'
  xml[#xml + 1] = "</Ui>"
  writeFile(o.out .. "/GuidesEra.xml", table.concat(xml, "\n") .. "\n")
  print(("wrote %d Era guide(s), Era/ClassQuestDataEra.lua and GuidesEra.xml"):format(#files))

  if o.validate then
    local rc = validate(o, files)
    if rc ~= 0 then return rc end
  end
  return 0
end

os.exit(main(arg or {}))
