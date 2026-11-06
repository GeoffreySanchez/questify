-- Tests du lecteur APR (apr.lua) : bac à sable, conditions, normalisation, version, ordre de jeu.
local H = require("helpers")
local apr = require("apr")

local function run(text, limit)
  local env, routes = apr.makeEnv()
  local saved = apr.INSTRUCTION_LIMIT
  if limit then apr.INSTRUCTION_LIMIT = limit end
  local ok, err = apr.runText(text, "test", env)
  apr.INSTRUCTION_LIMIT = saved
  return ok, err, routes
end

return {
  sandbox_runs_route_data = function(t)
    local ok, err, routes = run([[
      local L = LibStub("AceLocale-3.0"):GetLocale("APR")
      APR.RouteQuestStepList["x"] = { label = L["Some Label"] .. " (3-5)", category = APR.CATEGORIES.Leveling,
        conditions = { Class = APR.Classes.Mage, Race = APR.RACES.Scourge },
        steps = { { Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(1411, 10, 20), Range = math.min(3, 4),
                    Note = { string.format(L["FLY_TO"], "a") } } } }
    ]])
    t.ok(ok, err)
    local r = routes.x
    t.eq(r.category, "Leveling")
    t.eq(r.label, "Some Label (3-5)")
    t.eq(r.conditions.Class, 8, "classID of the game")
    t.eq(r.conditions.Race, "Scourge")
    t.eq(r.steps[1].Coord.map, 1411)
    t.eq(r.steps[1].Range, 3)
  end,

  sandbox_refuses_io_os_and_loaders = function(t)
    for _, code in ipairs({ "local f = io.open('x')", "os.execute('true')", "return require", "return loadstring",
                            "return dofile", "return pcall", "return getfenv", "return debug", "return _G",
                            "return APR.Unknown", "return APR.Classes.Necromancer" }) do
      local ok, err = run(code)
      t.ok(not ok, "should fail: " .. code)
      t.ok(tostring(err):find("unknown field", 1, true) or tostring(err):find("nil", 1, true),
           code .. " -> " .. tostring(err))
    end
  end,

  sandbox_string_has_no_dump = function(t)
    local ok, err, routes = run("APR.RouteQuestStepList.d = { string.dump, string.format }")
    t.ok(ok, err)
    t.eq(routes.d[1], nil)
    t.ok(routes.d[2] ~= nil)
  end,

  sandbox_refuses_bytecode = function(t)
    local ok, err = run(string.dump(function() return 1 end))
    t.ok(not ok)
    t.ok(err:find("bytecode", 1, true), err)
  end,

  sandbox_stops_endless_loop = function(t)
    local ok, err = run("while true do end", 100000)
    t.ok(not ok)
    t.ok(err:find("instruction limit", 1, true), err)
  end,

  conditions_are_three_valued = function(t)
    local war = { faction = "Alliance", race = "Human", class = "WARRIOR" }
    t.eq(apr.matches({ Class = "WARRIOR" }, war), true)
    t.eq(apr.matches({ Class = 8 }, war), false, "classID 8 = MAGE")
    t.eq(apr.matches({ Class = { 1, 8 } }, war), true)
    t.eq(apr.matches({ ClassNot = 1 }, war), false)
    t.eq(apr.matches({ Race = "Scourge" }, { race = "Undead" }), true, "Scourge = Undead")
    t.eq(apr.matches({ Faction = "Horde" }, war), false)
    t.eq(apr.matches({ MinLevel = 14 }, war), nil, "level is unknown offline")
    t.eq(apr.matches({ Class = "WARRIOR", IsQuestCompleted = 5 }, war), nil)
    t.eq(apr.matches({ Hardcore = true }, war), false, "normal character")
    t.eq(apr.matches({ Hardcore = false }, war), true)
    t.eq(apr.matches({ AnyOf = { { Race = "NightElf" }, { MinLevel = 14 } } }, war), nil)
    t.eq(apr.matches({ AnyOf = { { Race = "NightElf" }, { Class = "HUNTER" } } }, war), false)
    t.eq(apr.matches({ AnyOf = { { Race = "Human" }, { MinLevel = 14 } } }, war), true)
    t.eq(apr.matches({ AllOf = { { Race = "Human" }, { Class = "MAGE" } } }, war), false)
    t.eq(apr.matches({ Not = { Class = "WARRIOR" } }, war), false)
    t.eq(apr.matches({ Not = { IsQuestCompleted = 1 } }, war), nil)
    t.eq(apr.matches({ Class = "WARRIOR" }, { faction = "Alliance" }), nil, "class not fixed")
    t.ok(apr.allows({ MinLevel = 3 }, war))
    t.ok(not apr.allows({ Class = "MAGE" }, war))
    local cls = apr.classesFor({ AnyOf = { { Class = { "HUNTER", "WARRIOR" } }, { Race = "NightElf", Class = "PRIEST" } } },
                               "Alliance", { "Human", "NightElf" })
    t.ok(cls.HUNTER and cls.WARRIOR and cls.PRIEST and not cls.MAGE)
  end,

  normalize_step_fields = function(t)
    local s = apr.normalizeStep({ PickUp = { 1, 2 }, PickUpDB = { 3 }, DropQuest = 4, Qpart = { [7] = { 1 }, [5] = { 2 } },
      QpartPart = { [6] = { 1 } }, Done = { 8 }, Fillers = { [9] = { 1 } }, LeaveQuests = { 10 },
      UseHS = 8, UseHSIfAvailable = true, Note = { "A", "B" }, Coord = { map = 1429 }, _index = 12 }, 1)
    t.eq(table.concat(s.accept, ","), "1,2,3,4")
    t.eq(table.concat(s.complete, ","), "5,7,6")
    t.eq(table.concat(s.turnin, ","), "8")
    t.eq(table.concat(s.fillers, ","), "9")
    t.eq(table.concat(s.leave, ","), "10")
    t.eq(s.hearth, false); t.eq(s.hearthIfAvailable, true)
    t.eq(s.zone, 1429); t.eq(s.index, 12); t.eq(#s.notes, 2)
    local h = apr.normalizeStep({ UseHS = 1, SetHS = 2, Zone = 1411 }, 3)
    t.eq(h.hearth, true); t.eq(h.setHearth, true); t.eq(h.zone, 1411); t.eq(h.index, 3)
  end,

  route_files_and_load = function(t)
    local files = apr.routeFiles(H.FIX .. "/apr")
    t.eq(#files, 2, "only Routes/Forever/ files")
    local d = apr.load({ root = H.FIX .. "/apr" })
    t.eq(d.files, 2)
    t.eq(#d.order, 6)
    local v = d.routes["Test-Alliance-Valley"]
    t.eq(v.category, "Leveling"); t.eq(v.faction, "Alliance"); t.eq(v.mapID, 9901)
    t.eq(v.band[1], 1); t.eq(v.band[2], 6)
    t.eq(#v.steps, 14)
    t.eq(table.concat(v.next, ","), "Test-Alliance-Hills,Test-Alliance-Mage")
    t.eq(d.routes["Test-Alliance-Dungeon"].band, nil)
    t.eq(d.routes["Test-Alliance-Dungeon"].minLevel, 8)
    t.eq(d.version.commit, nil, "no .git in the fixture")
  end,

  play_order_follows_next_route = function(t)
    local d = apr.load({ root = H.FIX .. "/apr" })
    local rank = apr.playOrder(d)
    t.ok(rank["Test-Alliance-Valley"] < rank["Test-Alliance-Hills"])
    t.ok(rank["Test-Alliance-Valley"] < rank["Test-Alliance-Mage"])
    t.ok(rank["Test-Alliance-Hills"] < rank["Test-Alliance-Far"])
    -- cycle : cassé au plus bas niveau, chaque route reçoit un rang
    local cyc = { order = { "a", "b" }, routes = {
      a = { key = "a", next = { "b" }, band = { 5, 6 }, loadIndex = 1 },
      b = { key = "b", next = { "a" }, band = { 1, 2 }, loadIndex = 2 } } }
    local r2 = apr.playOrder(cyc)
    t.eq(r2.b, 1); t.eq(r2.a, 2)
  end,

  version_from_git_files = function(t)
    local dir = H.tmpdir("version")
    os.execute('mkdir -p "' .. dir .. '/.git/refs/heads" "' .. dir .. '/.git/refs/tags"')
    local sha = ("a"):rep(40)
    H.write(dir .. "/.git/HEAD", "ref: refs/heads/main\n")
    H.write(dir .. "/.git/refs/heads/main", sha .. "\n")
    H.write(dir .. "/.git/refs/tags/v1.2", sha .. "\n")
    H.write(dir .. "/.git/refs/tags/v1.1", ("b"):rep(40) .. "\n")
    H.write(dir .. "/.git/packed-refs", "# pack-refs\n" .. ("c"):rep(40) .. " refs/tags/v0.9\n^" .. sha .. "\n")
    local v = apr.version(dir)
    t.eq(v.commit, sha)
    t.eq(v.tag, "v1.2", "last matching tag (v0.9 annotated, v1.2 lightweight)")
    H.write(dir .. "/.git/HEAD", ("d"):rep(40) .. "\n")
    v = apr.version(dir)
    t.eq(v.commit, ("d"):rep(40), "detached HEAD")
    t.eq(v.tag, nil)
  end,
}
