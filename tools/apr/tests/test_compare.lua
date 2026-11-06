-- Tests du comparateur (compare.lua) sur des routes et des guides fictifs (tests/fixtures).
local H = require("helpers")
local apr = require("apr")
local compare = require("compare")

local function keys(s)
  local o = {}
  for k in pairs(s or {}) do o[#o + 1] = k end
  table.sort(o)
  return table.concat(o, ",")
end

local cached
local function fixture(extras)
  local data = apr.load({ root = H.FIX .. "/apr" })
  local chapters = compare.loadGuides(H.FIX .. "/guides")
  extras = extras or {}
  extras.reasons = extras.reasons or compare.loadReasons(H.FIX .. "/reports", chapters)
  extras.classQuests = extras.classQuests or compare.loadClassQuests(H.FIX .. "/guides/ClassQuestData.lua")
  return compare.compare(data, chapters, extras), data, chapters
end
local function base()
  cached = cached or fixture()
  return cached
end
local function result(cmp, id)
  for _, r in ipairs(cmp.results) do if r.chapter.id == id then return r end end
end

return {
  guides_load_in_xml_order = function(t)
    local chapters, commit = compare.loadGuides(H.FIX .. "/guides")
    t.eq(#chapters, 2, "ClassQuestData.lua is not a chapter")
    t.eq(chapters[1].id, "T_01"); t.eq(chapters[2].id, "T_02")
    t.eq(commit, "abc123")
    local st = chapters[1].steps[12]
    t.eq(st.q, 108); t.ok(st.classStep); t.ok(st.classes.WARRIOR)
    t.eq(chapters[1].steps[4].map, 9901, "at = { map, x, y }")
    t.eq(chapters[2].steps[1].map, 9902, "goto map")
    local races = compare.pathRaces(chapters)
    t.eq(table.concat(races.T_02, ","), "Dwarf,Human", "shared chapter: races of the paths through it")
  end,

  matching_and_coverage = function(t)
    local cmp = base()
    local r = result(cmp, "T_01")
    t.eq(#r.routes, 1)
    t.eq(r.routes[1].route.key, "Test-Alliance-Valley")
    t.eq(r.nQ, 4, "108 is a class quest")
    t.eq(r.nQclass, 1)
    t.eq(keys(r.cover.qInMatched), "101,102,106")
    t.eq(keys(r.cover.qAbsentApr), "107")
    t.eq(keys(r.cover.win), "101,102,104,106", "103 is a class quest, 105 hardcore only, 110 after the slice")
    t.eq(keys(r.cover.winAprOnly), "104")
    t.eq(r.window.first, 1); t.eq(r.window.last, 12); t.eq(r.window.total, 13)
    local r2 = result(cmp, "T_02")
    t.eq(r2.routes[1].route.key, "Test-Alliance-Hills", "the mage-only route and the far route are not matched")
    t.eq(#r2.routes, 1)
    t.eq(keys(r2.cover.qElsewhereApr), "110")
    t.eq(keys(r2.cover.winAprOnly), "204,205,206,207,208,209")
  end,

  order_similarity = function(t)
    local r = result(base(), "T_01")
    t.eq(r.order.shared, 8)
    t.eq(r.order.discordant, 2)
    t.eq(r.order.concordant, 26)
    t.ok(math.abs(r.order.tau - 24 / 28) < 1e-9)
    t.eq(#r.order.inversions, 2)
    t.eq(r.order.inversions[1].first, "accept:102")
    t.eq(r.order.inversions[1].second, "accept:101")
    t.eq(result(base(), "T_02").order.tau, 1, "fillers are not events")
  end,

  order_similarity_units = function(t)
    local function ev(list)
      local o = {}
      for _, q in ipairs(list) do o[#o + 1] = { kind = "accept", q = q } end
      return o
    end
    local same = compare.orderSimilarity(ev({ 1, 2, 3, 4 }), ev({ 1, 9, 2, 3, 4 }))
    t.eq(same.tau, 1); t.eq(same.shared, 4)
    local rev = compare.orderSimilarity(ev({ 1, 2, 3, 4 }), ev({ 4, 3, 2, 1 }))
    t.eq(rev.tau, -1); t.eq(rev.discordant, 6)
    t.eq(#rev.inversions, 2, "each event at most once")
    t.eq(rev.inversions[1].first, "accept:1"); t.eq(rev.inversions[1].second, "accept:4")
    t.eq(rev.inversions[1].gapQ, 3); t.eq(rev.inversions[1].gapA, 3)
    local none = compare.orderSimilarity(ev({ 1 }), ev({ 1 }))
    t.eq(none.tau, nil)
  end,

  class_quests_and_hearth = function(t)
    local r = result(base(), "T_01")
    t.eq(keys(r.classA.WARRIOR), "103")
    t.eq(keys(r.classA.MAGE), "")
    t.eq(keys(r.classQ.WARRIOR), "108")
    t.eq(r.classOffered[103], true, "103 is in ClassQuestData.lua")
    t.eq(r.hearth.aprUse.MAGE, 1); t.eq(r.hearth.aprBind.MAGE, 1); t.eq(r.hearth.aprIfAvailable, 1)
    t.eq(keys(r.hearth.aprBindMaps), "9901")
    t.eq(r.hearth.qUse.WARRIOR, 1); t.eq(r.hearth.qBind.DRUID, 1)
  end,

  drop_reasons = function(t)
    local r = result(base(), "T_02")
    local by = r.aprOnlyByReason
    t.eq(keys(by["quest level above the band"]), "204")
    t.eq(keys(by["manual drop (overrides.lua)"]), "205")
    t.eq(keys(by["dungeon quest not picked up"]), "206")
    t.eq(keys(by["not a candidate of the chapter"]), "207,208,209")
    local parsed = compare.parseDropped(H.read(H.FIX .. "/reports/T_02.md"))
    t.eq(parsed[999], nil, "rows after the section are ignored")
    t.eq(compare.reasonCategory("quest level 31 above the band"), "quest level above the band")
    t.eq(compare.reasonCategory("Questie blacklist"), "Questie blacklist")
    t.eq(compare.reasonCategory(nil), "not a candidate of the chapter")
  end,

  verdicts_by_count_and_xp = function(t)
    local cmp = base()
    t.eq(result(cmp, "T_01").verdict, "close")
    t.eq(result(cmp, "T_02").verdict, "apr")
    local withXP = fixture({ xp = function() return 100 end, status = function(_, q) return q == 207 and "blacklisted" or nil end })
    local r1, r2 = result(withXP, "T_01"), result(withXP, "T_02")
    t.eq(r1.xpChapter, 400); t.eq(r1.xpAprOnly, 100); t.eq(r1.xpQOnly, 100); t.eq(r1.verdict, "close")
    t.eq(r2.xpAprOnly, 600); t.eq(r2.verdict, "apr")
    t.eq(keys(r2.aprOnlyByReason["not a candidate of the chapter (QuestieDB: blacklisted)"]), "207")
    local lv = result(fixture({ level = function(_, q) return q == 209 and 13 or (q == 208 and 12 or 5) end }), "T_02")
    t.eq(keys(lv.cover.winAbove), "209", "level 13 > band 10 + 2")
    t.eq(keys(lv.cover.winAprOnly), "204,205,206,207,208")
    local small = fixture({ xp = function(_, q) return q >= 204 and 1 or 100 end })
    t.eq(result(small, "T_02").verdict, "close", "six cheap quests are not a lead")
  end,

  unmatched_routes_and_indoor = function(t)
    local cmp = base()
    local list = cmp.unmatched.Alliance
    t.eq(#list, 1, "class-only and dungeon routes are left out")
    t.eq(list[1].route.key, "Test-Alliance-Far")
    t.eq(list[1].n, 1); t.eq(list[1].done, 0)
    local z = cmp.indoor.Alliance[9901]
    t.eq(z.steps.cave, 1); t.eq(z.steps.building, 0); t.eq(z.steps.floor, 1)
    t.eq(keys(z.quests.cave), "101"); t.eq(keys(z.quests.floor), "102")
    t.eq(cmp.indoor.Horde, nil, "no Horde chapter")
  end,

  indoor_categories = function(t)
    t.eq(keys(compare.indoorCategories("INSIDE_CAVE")), "cave", "INSIDE alone does not make it a building")
    t.eq(keys(compare.indoorCategories("INSIDE_INN")), "building")
    t.eq(keys(compare.indoorCategories("GET_INSIDE")), "building")
    t.eq(keys(compare.indoorCategories("CLIMB_TOWER_STAIRS")), "building,floor")
    t.eq(keys(compare.indoorCategories("CHECK_AUCTION_HOUSE_GEAR_UPGRADE")), "")
    t.eq(keys(compare.indoorCategories("CLICK_TOOLBOX_LAKE_FLOOR")), "")
    t.eq(keys(compare.indoorCategories("FOLLOW_THE_PATH_UP_THE_MOUNTAIN")), "")
  end,

  report_holds_no_apr_text = function(t)
    local cmp, data = fixture()
    local text = compare.render(cmp, { date = "2026-01-01", aprVersion = data.version, aprFiles = data.files,
                                       aprRoutes = #data.order, qdbCommit = "abc123", caves = { [9901] = 2 } },
                                { [9901] = "Valley Map" })
    t.ok(not text:find("Test%-Alliance"), "no APR route key")
    t.ok(not text:find("Fixture"), "no APR label")
    t.ok(not text:find("TEST_"), "no APR note key")
    t.ok(text:find("#1 (Valley Map (9901), 1-6)", 1, true), "route named by rank, map and band")
    t.ok(text:find("| Valley Map (9901) | 1 | 0 | 1 | 101 | none | 102 | 2 |", 1, true), "indoor row")
    t.ok(text:find("- APR clearly ahead: T_02", 1, true))
    t.ok(text:find("| T_01 | 1-6 | #1 | 4 | 3 (75 %) |", 1, true), "chapter row")
  end,

  main_writes_the_report = function(t)
    local dir = H.tmpdir("main")
    local out = dir .. "/APR-COMPARE.md"
    local savedPrint, savedErr = print, io.stderr
    print, io.stderr = function() end, { write = function() end }
    local ok, code = pcall(compare.main, { "--apr", H.FIX .. "/apr", "--guides", H.FIX .. "/guides", "--reports", H.FIX .. "/reports",
                                "--caves", dir .. "/none.lua", "--uimap", dir .. "/none.csv", "--out", out,
                                "--date", "2026-01-01", "--no-xp" })
    local okB, bogus = pcall(compare.main, { "--bogus" })
    print, io.stderr = savedPrint, savedErr
    t.ok(ok, code); t.ok(okB, bogus)
    t.eq(code, 0)
    t.eq(bogus, 2)
    local text = H.read(out)
    t.ok(text and text:find("Generated on 2026-01-01", 1, true))
    t.ok(text:find("XP: not computed", 1, true))
  end,
}
