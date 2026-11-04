-- Tests de l'émetteur de guides, du validateur et des données de quêtes de classe.
local H = require("helpers")
local emit = require("emit")

-- Charge un fichier de guide avec un Q:RegisterGuide factice ; renvoie la définition.
local function loadGuide(src)
  local got
  local Q = {}
  function Q:RegisterGuide(def) got = def end
  local fn = assert(loadstring(src, "=guide"))
  setfenv(fn, {})
  fn("Questify", Q)
  return got
end

-- Copie d'une étape sans les champs internes (préfixe _).
local function clean(step)
  local o = {}
  for k, v in pairs(step) do if type(k) ~= "string" or k:sub(1, 1) ~= "_" then o[k] = v end end
  return o
end

local function deepEq(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deepEq(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function runValidator(args)
  local out = H.tmpdir() .. "/validator_out.txt"
  local status = os.execute(("luajit %s/../validate_guides.lua %s > %q 2>&1"):format(H.ROOT, args, out))
  local f = io.open(out, "rb"); local text = f and f:read("*a") or ""; if f then f:close() end
  local code = status
  if type(status) == "boolean" then code = status and 0 or 1 end
  return code, text
end

return {
  emit_round_trip = function(t)
    local plan = { id = "A_Test_01", title = "Test Valley", faction = "Alliance", races = { "Dwarf", "Gnome" },
                   minLevel = 1, maxLevel = 6, next = "A_Test_02" }
    local steps = {
      { "accept", 179, _c = { name = "Dwarven Outfitters", level = 1, simLevel = 1 } },
      { "complete", 170, at = { 1426, 26.1, 74.3 }, obj = 2 },
      { "turnin", 179, xp = 80, _c = { name = "Dwarven Outfitters", level = 1, simLevel = 2, xp = 80 } },
      { "goto", 1426, 22.6, 71.4, note = "Say \"hi\"" },
      { "fp", 1455, 55.5, 47.75 },
      { "sethearth", 1426, 47.4, 52.5 },
      { "hearth", 1426 },
      { "fly", 1453, note = "Stormwind" },
      { "accept", 96391, optional = true, dungeon = "Hall of Thanes", race = { "Dwarf" } },
      { "level", 6, at = { 1426, 30, 70 }, note = "About 10 more mobs" },
    }
    local src = emit.guide(plan, steps, { quests = { { id = 179, xp = 80 } } }, { commit = "abc123", date = "2026-11-03" })
    t.ok(src:find("Dwarven Outfitters (lvl 1, ~80 xp, sim lvl 1)", 1, true), "quest comment")
    t.ok(src:find("abc123", 1, true) and src:find("2026-11-03", 1, true), "header commit and date")
    t.ok(src:match("^local addonName, Q = %.%.%.\n"), "addon file header")
    local def = loadGuide(src)
    t.eq(def.id, "A_Test_01"); t.eq(def.next, "A_Test_02"); t.eq(def.races[2], "Gnome")
    t.eq(#def.steps, #steps)
    for i, s in ipairs(steps) do
      t.ok(deepEq(def.steps[i], clean(s)), "step " .. i .. " round trip")
    end
  end,

  validator_flags_turnin_without_accept = function(t)
    local dir = H.tmpdir() .. "/guides_bad"
    os.execute(('rm -rf "%s"; mkdir -p "%s/Alliance"'):format(dir, dir))
    local plan = { id = "A_Bad_01", title = "Bad", faction = "Alliance", races = { "Dwarf" }, minLevel = 1, maxLevel = 6 }
    local src = emit.guide(plan, { { "accept", 179 }, { "turnin", 179 }, { "turnin", 170 } }, {}, { commit = "x", date = "d" })
    local f = assert(io.open(dir .. "/Alliance/A_Bad_01.lua", "wb")); f:write(src); f:close()
    f = assert(io.open(dir .. "/Guides.xml", "wb"))
    f:write('<Ui>\n  <Script file="Alliance\\A_Bad_01.lua"/>\n</Ui>\n'); f:close()
    local code, text = runValidator(('--guides "%s"'):format(dir))
    t.ok(code ~= 0, "exit code is not 0: " .. tostring(code))
    t.ok(text:find("turnin 170 without accept", 1, true), text)
    t.ok(text:find("A_Bad_01.lua:%d+"), "file:line prefix")
  end,

  validator_accepts_good_guide = function(t)
    local dir = H.tmpdir() .. "/guides_good"
    os.execute(('rm -rf "%s"; mkdir -p "%s/Alliance"'):format(dir, dir))
    local plan = { id = "A_Good_01", title = "Good", faction = "Alliance", races = { "Dwarf" }, minLevel = 1, maxLevel = 6 }
    local src = emit.guide(plan, { { "accept", 179 }, { "complete", 179, at = { 1426, 30, 74 } }, { "turnin", 179 } },
      {}, { commit = "x", date = "d" })
    local f = assert(io.open(dir .. "/Alliance/A_Good_01.lua", "wb")); f:write(src); f:close()
    f = assert(io.open(dir .. "/Guides.xml", "wb"))
    f:write('<Ui>\n  <Script file="Alliance\\A_Good_01.lua"/>\n</Ui>\n'); f:close()
    local code, text = runValidator(('--guides "%s"'):format(dir))
    t.eq(code, 0, text)
  end,

  -- Tronc commun atteint par deux races : chaque parcours est rejoué. Une quête déjà rendue sur un
  -- parcours ne peut pas être reprise sur ce parcours (filtre `race` exigé), un rendu sans accept est
  -- signalé, un accept sans son prérequis aussi.
  validator_race_paths = function(t)
    local dir = H.tmpdir() .. "/guides_paths"
    os.execute(('rm -rf "%s"; mkdir -p "%s/Alliance"'):format(dir, dir))
    local function write(plan, steps)
      local f = assert(io.open(dir .. "/Alliance/" .. plan.id .. ".lua", "wb"))
      f:write(emit.guide(plan, steps, {}, { commit = "x", date = "d" })); f:close()
    end
    write({ id = "A_P1_01", faction = "Alliance", races = { "Dwarf" }, minLevel = 1, maxLevel = 6, next = "A_T_01" },
      { { "accept", 179 }, { "turnin", 179 } })
    write({ id = "A_P2_01", faction = "Alliance", races = { "NightElf" }, minLevel = 1, maxLevel = 6, next = "A_T_01" },
      { { "accept", 233 } })
    write({ id = "A_T_01", faction = "Alliance", minLevel = 6, maxLevel = 10 },
      { { "accept", 179 }, { "turnin", 179 }, { "turnin", 233 } })
    local f = assert(io.open(dir .. "/Guides.xml", "wb"))
    f:write('<Ui>\n  <Script file="Alliance\\A_P1_01.lua"/>\n  <Script file="Alliance\\A_P2_01.lua"/>\n'
      .. '  <Script file="Alliance\\A_T_01.lua"/>\n</Ui>\n')
    f:close()
    local code, text = runValidator(('--guides "%s"'):format(dir))
    t.ok(code ~= 0, "violation expected")
    t.ok(text:find("A_T_01.lua:%d+ accept 179: accept after turnin %(race path: Dwarf%)"), text)
    t.ok(text:find("A_T_01.lua:%d+ turnin 233 without accept %(race path: Dwarf"), text)
    t.ok(text:find("A_P2_01.lua:%d+ accept 233: no prerequisite"), text)
  end,

  classquests_warlock_alliance = function(t)
    local cq = require("classquests")
    local data = cq.build(H.D("Alliance"))
    t.ok(data.WARLOCK and #data.WARLOCK > 0, "warlock chains")
    local found
    for _, chain in ipairs(data.WARLOCK) do
      for _, q in ipairs(chain.quests) do if q == 1598 then found = chain end end
    end
    t.ok(found, "a WARLOCK chain contains 1598")
    t.eq(found.key, "WARLOCK_1598")
    t.eq(found.faction, "Alliance")
    -- le fichier généré se recharge et expose Q.ClassQuestData
    local src = cq.emit(data, { commit = "x", date = "d" })
    local Q = {}
    local fn = assert(loadstring(src, "=cq")); setfenv(fn, {}); fn("Questify", Q)
    t.ok(Q.ClassQuestData and Q.ClassQuestData.WARLOCK, "loads")
  end,
}
