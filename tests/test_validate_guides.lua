-- Tests du champ `classes` dans tools/validate_guides.lua : contrôle du format (même règle que
-- Q.Guides:Normalize), rejeu des parcours de race classe par classe. Les fonctions pures tournent
-- partout ; le contrôle complet lit le clone QuestieDB de .cache/ et ne tourne que s'il est présent
-- (absent en CI).
local ROOT = Mock.root

local function validator()
  package.path = ROOT .. "/tools/routebuilder/?.lua;" .. package.path
  local chunk = assert(loadfile(ROOT .. "/tools/validate_guides.lua"))
  return chunk("--as-module")
end

local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return "" end
  local s = f:read("*a"); f:close()
  return s
end

local function writeFile(path, text)
  local f = assert(io.open(path, "wb")); f:write(text); f:close()
end

-- Fichier de guide au format des guides générés (une étape par ligne).
local function guideSource(id, races, steps)
  local lines = {
    "local addonName, Q = ...", "", "Q:RegisterGuide({",
    ('  id = "%s",'):format(id), '  title = "Test",', '  faction = "Alliance",',
    ('  races = { "%s" },'):format(table.concat(races, '", "')), "  minLevel = 1, maxLevel = 6,", "  steps = {",
  }
  for _, s in ipairs(steps) do lines[#lines + 1] = "    " .. s .. "," end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "})"
  return table.concat(lines, "\n") .. "\n"
end

return {
  classes_field_check = function(t)
    local V = validator()
    t.eq(V.classesProblem(nil), nil, "absent: every class")
    t.eq(V.classesProblem({ "WARLOCK" }), nil)
    t.eq(V.classesProblem({ "WARRIOR", "PALADIN" }), nil)
    t.eq(V.classesProblem("MAGE"), nil, "a single name")
    t.eq(V.classesProblem({ "WARLOK" }), "unknown class 'WARLOK' in classes")
    t.eq(V.classesProblem({ "warlock" }), "unknown class 'warlock' in classes")
    t.eq(V.classesProblem({}), "classes must name at least one class")
    t.eq(V.classesProblem({ 5 }), "classes must be a list of class names")
    t.eq(V.classesProblem(5), "classes must be a list of class names")
  end,

  class_variants_and_filtered_steps = function(t)
    local V = validator()
    local chapters = {
      { id = "A", steps = { { "accept", 1 }, { "accept", 2, classes = { "WARLOCK", "MAGE" } } } },
      { id = "B", steps = { { "note", "x", classes = "PRIEST" }, { "turnin", 2, classes = { "WARLOCK" } } } },
    }
    t.eq(V.classVariants(chapters), { "MAGE", "PRIEST", "WARLOCK" })
    t.eq(V.classVariants({ { id = "C", steps = { { "accept", 1 } } } }), {}, "no class step")
    local steps, index = V.stepsForClass(chapters[1].steps, nil)
    t.eq(#steps, 1); t.eq(index, { 1 }, "without class: the steps for every class")
    steps, index = V.stepsForClass(chapters[1].steps, "MAGE")
    t.eq(#steps, 2); t.eq(index, { 1, 2 })
    steps, index = V.stepsForClass(chapters[2].steps, "PRIEST")
    t.eq(#steps, 1); t.eq(index, { 1 }, "a single name")
    steps, index = V.stepsForClass(chapters[2].steps, "MAGE")
    t.eq(#steps, 0)
  end,

  -- Contrôle complet (QuestieDB de .cache/) : étapes de classe valides, dont 21 quêtes prises en même
  -- temps par deux classes (11 et 10 : le journal de 20 quêtes ne déborde pour aucune) ; nom de classe
  -- inconnu, classe sans droit à la quête, rendu sans prise pour une seule classe ou pour toutes.
  validator_checks_class_steps = function(t)
    package.path = ROOT .. "/tools/routebuilder/?.lua;" .. package.path
    local qdb = require("qdb")
    if not exists(qdb.DEFAULT_DB .. "/QuestieDB.toc") then return end   -- pas de clone QuestieDB (CI) : sauté
    local D = qdb.load({ db = qdb.DEFAULT_DB, questie = qdb.DEFAULT_QUESTIE, faction = "Alliance" })
    -- 21 quêtes sans préquête, sans classe ni exclusion, ouvertes aux Gnomes
    local picked = {}
    for _, id in ipairs(qdb.sortedKeys(D.quests)) do
      local q = D.quests[id]
      if #picked < 21 and (q.classes or 0) == 0 and #q.preGroup == 0 and #q.preSingle == 0
        and #q.exclusiveTo == 0 and qdb.hasBit(q.races, qdb.RACE_BITS.Gnome) then
        picked[#picked + 1] = id
      end
    end
    t.eq(#picked, 21)
    local good = { '{ "accept", 1599, classes = { "WARLOCK" } }', '{ "turnin", 1599, classes = { "WARLOCK" } }' }
    for i, id in ipairs(picked) do
      local cls = i <= 11 and "WARLOCK" or "MAGE"
      good[#good + 1] = ('{ "accept", %d, classes = { "%s" } }'):format(id, cls)
    end
    for i, id in ipairs(picked) do
      local cls = i <= 11 and "WARLOCK" or "MAGE"
      good[#good + 1] = ('{ "turnin", %d, classes = { "%s" } }'):format(id, cls)
    end
    local bad = {
      '{ "accept", 1599, classes = { "WARLOK" } }',   -- 1
      '{ "accept", 1598, classes = { "MAGE" } }',     -- 2
      '{ "turnin", 1598 }',                           -- 3 : sans prise pour les autres classes
      '{ "turnin", 179, classes = { "PRIEST" } }',    -- 4 : sans prise pour le Prêtre seulement
    }
    local dir = (os.getenv("TMPDIR") or "/tmp"):gsub("/$", "") .. "/questify_validate_classes"
    os.execute(('rm -rf "%s"; mkdir -p "%s/Alliance"'):format(dir, dir))
    writeFile(dir .. "/Alliance/A_Good_01.lua", guideSource("A_Good_01", { "Gnome" }, good))
    writeFile(dir .. "/Alliance/A_Bad_01.lua", guideSource("A_Bad_01", { "Dwarf" }, bad))
    writeFile(dir .. "/Guides.xml", '<Ui>\n  <Script file="Alliance\\A_Good_01.lua"/>\n'
      .. '  <Script file="Alliance\\A_Bad_01.lua"/>\n</Ui>\n')
    local out = dir .. "/out.txt"
    os.execute(('cd "%s" && luajit tools/validate_guides.lua --guides "%s" > "%s" 2>&1'):format(ROOT, dir, out))
    local text = readFile(out)
    t.ok(not text:find("A_Good_01", 1, true), "class steps of two classes are valid:\n" .. text)
    t.ok(text:find("A_Bad_01.lua:10 unknown class 'WARLOK' in classes", 1, true), text)
    t.ok(text:find("A_Bad_01.lua:11 quest 1598 not available to class MAGE", 1, true), text)
    t.ok(text:find("A_Bad_01.lua:12 turnin 1598 without accept (race path: Dwarf)", 1, true), text)
    t.ok(text:find("A_Bad_01.lua:13 turnin 179 without accept (race path: Dwarf, class: PRIEST)", 1, true), text)
    t.ok(text:find("violation", 1, true), text)
  end,
}
