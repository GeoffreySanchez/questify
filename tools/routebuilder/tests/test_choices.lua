-- Tests des choix de suite (champ choices) et des métriques simulées (champ sim) : émission
-- (emit.lua), contrôle des plans (plans.validate), ajout aux guides existants (backfill.lua) et
-- minutes de trajet (travel.lua). Aucun ne demande QuestieDB.
local H = require("helpers")
local emit = require("emit")
local plansm = require("plans")
local backfill = require("backfill")

-- Charge un texte de guide avec un Q:RegisterGuide factice ; renvoie la définition.
local function loadGuide(src)
  local got
  local Q = {}
  function Q:RegisterGuide(def) got = def end
  local fn = assert(loadstring(src, "=guide"))
  setfenv(fn, {})
  fn("Questify", Q)
  return got
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

local REPORT = { steps = 78, endLevel = 15.554, xpPerHour = 21187.6, time = 7140, quests = {} }
local STEPS = { { "accept", 179 }, { "turnin", 179 } }
local META = { commit = "abc", date = "2026-11-05" }

local function branchPlan()
  return { id = "A_T_03", title = "Loch", faction = "Alliance", races = { "Dwarf", "Gnome" }, minLevel = 11,
           maxLevel = 14, next = "A_T_04",
           choices = {
             { id = "A_T_04", travel = { kind = "walk", minutes = 2 } },
             { id = "A_T_10", races = { "Dwarf" }, label = "Darkshore", travel = { kind = "boat" }, weight = 0.5 },
           } }
end

-- Petite table de plans pour plans.validate : A_X_01 (Nain / Gnome) -> A_X_02 ; A_X_03 ; A_X_04 ; A_X_05 ; H_X_01.
-- edit(plan) modifie A_X_01 (next, nextByRace...).
local function fixture(choices, edit)
  local p = {
    Alliance = {
      { id = "A_X_01", faction = "Alliance", races = { "Dwarf", "Gnome" }, minLevel = 1, maxLevel = 6,
        next = "A_X_02", choices = choices },
      { id = "A_X_02", faction = "Alliance", minLevel = 6, maxLevel = 10 },
      { id = "A_X_03", faction = "Alliance", minLevel = 6, maxLevel = 10 },
      { id = "A_X_04", faction = "Alliance", minLevel = 6, maxLevel = 10 },
      { id = "A_X_05", faction = "Alliance", minLevel = 6, maxLevel = 10 },
    },
    Horde = { { id = "H_X_01", faction = "Horde", minLevel = 6, maxLevel = 10 } },
  }
  if edit then edit(p.Alliance[1]) end
  return p
end

-- A_X_01 suivi par race (sans next).
local function byRace(map) return function(plan) plan.next = nil; plan.nextByRace = map end end

-- Vrai si une erreur de plans.validate contient le texte.
local function rejects(t, p, text)
  local errs = plansm.validate(p)
  local all = {}
  for _, e in ipairs(errs) do
    all[#all + 1] = e.id .. ": " .. e.msg
    if e.msg:find(text, 1, true) then return end
  end
  error(("expected an error containing %q, got: %s"):format(text, #all > 0 and table.concat(all, " | ") or "none"), 2)
end

local function C(id, kind) return { id = id, travel = kind and { kind = kind } or nil } end

return {
  emit_writes_choices_and_sim = function(t)
    local src = emit.guide(branchPlan(), STEPS, REPORT, META)
    local expected = table.concat({
      "  next = \"A_T_04\",",
      "  choices = {",
      "    { id = \"A_T_04\", travel = { kind = \"walk\", minutes = 2 } },",
      "    { id = \"A_T_10\", races = { \"Dwarf\" }, label = \"Darkshore\", travel = { kind = \"boat\" }, weight = 0.5 },",
      "  },",
      "  sim = { steps = 78, endLevel = 15.55, xpPerHour = 21188, minutes = 119 },",
      "  steps = {",
    }, "\n")
    t.ok(src:find(expected, 1, true), "choices then sim, between next and steps:\n" .. src)
    t.ok(src:find("\n-- Simulation : 78 étapes, niveau final 15.55, ~21188 xp/h, 119 min.\n", 1, true), "header comment unchanged")
    local def = loadGuide(src)
    t.eq(#def.choices, 2)
    t.eq(def.choices[1].id, "A_T_04"); t.eq(def.choices[1].travel.kind, "walk"); t.eq(def.choices[1].travel.minutes, 2)
    t.eq(def.choices[2].races[1], "Dwarf"); t.eq(def.choices[2].label, "Darkshore"); t.eq(def.choices[2].weight, 0.5)
    t.eq(def.choices[2].travel.minutes, nil)
    t.eq(def.sim.steps, 78); t.eq(def.sim.endLevel, 15.55); t.eq(def.sim.xpPerHour, 21188); t.eq(def.sim.minutes, 119)
    t.eq(#def.steps, 2)
  end,

  emit_nextbyrace_then_choices = function(t)
    local plan = branchPlan()
    plan.next, plan.nextByRace = nil, { Gnome = "A_T_04", Dwarf = "A_T_04" }
    local src = emit.guide(plan, STEPS, { endLevel = 16, xpPerHour = 10, time = 60 }, META)
    t.ok(src:find("  nextByRace = { Dwarf = \"A_T_04\", Gnome = \"A_T_04\" },\n  choices = {\n", 1, true), src)
    -- niveau entier : deux décimales comme l'en-tête
    t.ok(src:find("  sim = { steps = 2, endLevel = 16.00, xpPerHour = 10, minutes = 1 },\n  steps = {", 1, true), src)
  end,

  emit_without_choices_or_simulation = function(t)
    local plan = branchPlan()
    plan.choices = nil
    local src = emit.guide(plan, STEPS, {}, META)
    t.ok(not src:find("choices", 1, true), "no choices")
    t.ok(not src:find("sim =", 1, true) and not src:find("-- Simulation", 1, true), "no sim without simulation")
    local def = loadGuide(src)
    t.eq(def.choices, nil); t.eq(def.sim, nil)
  end,

  -- Plans réels : valides, et le premier embranchement (Loch Modan) propose la suite par défaut.
  validate_real_plans = function(t)
    local errs = plansm.validate(plansm)
    local msgs = {}
    for _, e in ipairs(errs) do msgs[#msgs + 1] = e.id .. ": " .. e.msg end
    t.eq(#errs, 0, table.concat(msgs, " | "))
    local p = plansm.find("A_DwarfGnome_03")
    t.eq(p.choices[1].id, p.next, "default successor first")
    t.eq(p.choices[2].id, "A_01")
    -- pathFor ne suit que la suite par défaut
    local ids = {}
    for _, q in ipairs(plansm.pathFor("Alliance", "Dwarf")) do ids[#ids + 1] = q.id end
    t.eq(table.concat(ids, ","), "A_DwarfGnome_01,A_DwarfGnome_02,A_DwarfGnome_03,A_DwarfGnome_04,A_01,A_02,A_03,A_04,A_05,"
      .. "A_08,A_07,A_09,A_10,A_11,A_12,A_13,A_15,A_16,A_17,A_18,A_19,A_20,A_21,A_22,A_28,A_24,A_26,A_27,A_23,A_29,A_30")
  end,

  validate_accepts_good_choices = function(t)
    local errs = plansm.validate(fixture({ C("A_X_02", "walk"), C("A_X_03", "boat"),
      { id = "A_X_04", races = { "Gnome" }, label = "x", weight = 2, travel = { kind = "tram", minutes = 0 } }, C("A_X_05") }))
    t.eq(#errs, 0, errs[1] and errs[1].msg)
    -- nextByRace : chaque race a sa suite par défaut dans les choix
    errs = plansm.validate(fixture({ C("A_X_02"), { id = "A_X_03", races = { "Gnome" } } },
      byRace({ Dwarf = "A_X_02", Gnome = "A_X_03" })))
    t.eq(#errs, 0, errs[1] and errs[1].msg)
  end,

  validate_rejects_unknown_id = function(t)
    rejects(t, fixture({ C("A_X_02"), C("A_Nope") }), '"A_Nope" is not a known chapter')
    rejects(t, fixture({ C("A_X_02"), { travel = { kind = "walk" } } }), "choices[2]: missing id")
  end,

  validate_rejects_other_faction = function(t)
    rejects(t, fixture({ C("A_X_02"), C("H_X_01") }), '"H_X_01" is a Horde chapter, this one is Alliance')
  end,

  validate_rejects_entry_count = function(t)
    rejects(t, fixture({ C("A_X_02") }), "choices has 1 entries (2 to 4 expected)")
    rejects(t, fixture({ C("A_X_02"), C("A_X_03"), C("A_X_04"), C("A_X_05"), C("A_X_01") }), "choices has 5 entries")
    rejects(t, fixture("A_X_02"), "choices must be a list")
  end,

  validate_rejects_duplicate_id = function(t)
    rejects(t, fixture({ C("A_X_02"), C("A_X_03"), C("A_X_03") }), 'choices[3]: duplicate id "A_X_03"')
    rejects(t, fixture({ C("A_X_02"), C("A_X_01") }), "cannot be its own choice")
  end,

  validate_rejects_missing_default = function(t)
    rejects(t, fixture({ C("A_X_03"), C("A_X_04") }), 'default successor next = "A_X_02" is not in choices')
    rejects(t, fixture({ { id = "A_X_02", races = { "Dwarf" } }, C("A_X_03") }), 'is not offered to Gnome')
    rejects(t, fixture({ C("A_X_02"), C("A_X_03") }, byRace({ Dwarf = "A_X_02", Gnome = "A_X_04" })),
      'default successor nextByRace.Gnome = "A_X_04" is not in choices')
    rejects(t, fixture({ C("A_X_02"), C("A_X_03") }, byRace(nil)), "choices without a default successor")
  end,

  validate_rejects_travel_kind = function(t)
    rejects(t, fixture({ C("A_X_02", "walk"), C("A_X_03", "ship") }), "choices[2]: travel.kind ship is not one of walk, fly")
    rejects(t, fixture({ C("A_X_02"), { id = "A_X_03", travel = "boat" } }), "choices[2]: travel.kind")
    rejects(t, fixture({ C("A_X_02"), { id = "A_X_03", travel = { kind = "boat", minutes = 6.5 } } }), "whole number of minutes")
  end,

  validate_rejects_bad_fields = function(t)
    rejects(t, fixture({ C("A_X_02"), { id = "A_X_03", races = { "Orc" } } }), "race Orc does not play this chapter")
    rejects(t, fixture({ C("A_X_02"), { id = "A_X_03", weight = 0 } }), "weight must be a positive number")
    rejects(t, fixture({ C("A_X_02"), { id = "A_X_03", label = 3 } }), "label must be a string")
    rejects(t, fixture(nil, function(plan) plan.next = "A_Gone" end), 'next "A_Gone" is not a known chapter')
  end,

  -- build.lua s'arrête sur des plans invalides, avant de charger QuestieDB.
  build_stops_on_invalid_plans = function(t)
    local build = assert(loadfile(H.ROOT .. "/build.lua"))("--as-module")
    local p = plansm.find("A_DwarfGnome_03")
    local saved = p.choices
    p.choices = { C("A_DwarfGnome_04"), C("H_01") }
    local stderr, said = io.stderr, {}
    io.stderr = { write = function(_, s) said[#said + 1] = s end } -- messages gardés pour le contrôle
    local ok, code = pcall(build.main, { "--db", "/nonexistent" })
    io.stderr = stderr
    p.choices = saved
    t.ok(table.concat(said):find('A_DwarfGnome_03: choices[2]: "H_01" is a Horde chapter', 1, true), table.concat(said))
    t.ok(ok, "no QuestieDB load: " .. tostring(code))
    t.eq(code, 1)
  end,

  -- backfill : le guide d'avant (sans choices ni sim) devient exactement ce qu'écrit emit.lua, en LF
  -- comme en CRLF ; un second passage ne change rien.
  backfill_matches_emit_and_is_idempotent = function(t)
    local plan = branchPlan()
    local want = emit.guide(plan, STEPS, REPORT, META)
    local old = want:gsub("  choices = {\n.-\n  },\n", ""):gsub("  sim = {[^\n]*\n", "")
    t.ok(not old:find("choices", 1, true) and not old:find("  sim =", 1, true), "old format")
    t.eq(backfill.apply(old, plan), want, "LF")
    t.eq(backfill.apply(want, plan), want, "second pass")
    local crlf = want:gsub("\n", "\r\n")
    t.eq(backfill.apply(old:gsub("\n", "\r\n"), plan), crlf, "CRLF")
    t.eq(backfill.apply(crlf, plan), crlf, "CRLF second pass")
    -- sans plan (ou plan sans choices) : seule la ligne sim, et un ancien bloc choices est retiré
    local noChoices = emit.guide((function() local q = branchPlan(); q.choices = nil; return q end)(), STEPS, REPORT, META)
    t.eq(backfill.apply(want, nil), noChoices, "stale choices removed")
    t.eq(backfill.apply(old, nil), noChoices, "sim only")
  end,

  backfill_skips_files_without_simulation = function(t)
    local src = emit.guide(branchPlan(), STEPS, {}, META)
    local res, why = backfill.apply(src, branchPlan())
    t.eq(res, nil); t.eq(why, "no simulation header")
    -- en-tête lisible mais pas au format d'emit.lua (une seule décimale) : fichier laissé tel quel
    local odd = emit.guide(branchPlan(), STEPS, REPORT, META):gsub("niveau final 15%.55", "niveau final 15.5")
    res, why = backfill.apply(odd, branchPlan())
    t.eq(res, nil, "header not written by emit.lua")
    t.ok(why and why:find("unexpected simulation header", 1, true), tostring(why))
  end,

  -- Guides livrés : déjà complétés (un passage ne change rien) et `sim` égal à l'en-tête.
  backfill_shipped_guides_up_to_date = function(t)
    local dir = H.ROOT .. "/../../Questify/Guides"
    local xml = readFile(dir .. "/Guides.xml")
    t.ok(xml, "Guides.xml")
    local n = 0
    for rel in xml:gmatch('<Script%s+file%s*=%s*"([^"]+)"') do
      rel = rel:gsub("\\", "/")
      local text = readFile(dir .. "/" .. rel)
      local sim = text and backfill.parseSim(text)
      if sim then
        n = n + 1
        local id = backfill.guideId(text)
        t.eq(backfill.apply(text, plansm.find(id)), text, rel .. " (run tools/routebuilder/backfill.lua)")
        local def = loadGuide(text)
        for k, v in pairs(sim) do t.eq(def.sim[k], v, rel .. " sim." .. k) end
        local p = plansm.find(id)
        t.eq(def.choices ~= nil, p ~= nil and p.choices ~= nil, rel .. " choices")
      end
    end
    t.ok(n >= 29, "generated guides found: " .. n)
  end,

  -- Minutes de trajet de plans.lua = calcul de travel.lua (sim.route) sur les guides et rapports livrés.
  travel_minutes_match_generated_guides = function(t)
    local travel = require("travel")
    local W = H.W()
    local root = H.ROOT .. "/../.."
    local checked = 0
    for _, faction in ipairs({ "Alliance", "Horde" }) do
      for _, p in ipairs(plansm[faction]) do
        if p.choices then
          local res, err = travel.forPlan(p.id, { guides = root .. "/Questify/Guides", report = root .. "/docs/routes", W = W })
          t.ok(res, err)
          for _, r in ipairs(res) do
            local d = r.declared.travel
            if d and d.minutes then
              checked = checked + 1
              t.eq(r.kind, d.kind, p.id .. " -> " .. r.id .. " kind")
              t.eq(r.minutes, d.minutes, p.id .. " -> " .. r.id .. " minutes")
            end
          end
        end
      end
    end
    t.ok(checked >= 2, "A_DwarfGnome_03 choices checked")
  end,
}
