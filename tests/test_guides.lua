-- Tests du registre de guides (Q.Guides, Q:RegisterGuide).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load() return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true }) end

return {
  normalize_forms = function(t)
    local Q = load()
    t.eq(Q.Guides:Normalize({ "goto", 1426, 22.6, 71.4 }).mapId, 1426)
    t.eq(Q.Guides:Normalize({ "complete", 170, obj = 2 }).obj, 2)
    local a = Q.Guides:Normalize({ "accept", 179 })
    t.eq(a.action, "accept"); t.eq(a.questId, 179)
    local g = Q.Guides:Normalize({ "goto", 1426, 22.6, 71.4, note = "camp" })
    t.eq(g.x, 22.6); t.eq(g.y, 71.4); t.eq(g.note, "camp")
    t.eq(Q.Guides:Normalize({ "level", 6 }).level, 6)
    t.eq(Q.Guides:Normalize({ "note", "txt" }).text, "txt")
    t.eq(Q.Guides:Normalize({ "hearth", 1426 }).mapId, 1426)
    t.eq(Q.Guides:Normalize({ "fly", 1453 }).mapId, 1453)
    local c = Q.Guides:Normalize({ "complete", 170, at = { 1426, 26.1, 74.3 }, xp = 120, optional = true, dungeon = "Deadmines" })
    t.eq(c.at.mapId, 1426); t.eq(c.at.x, 26.1); t.eq(c.at.y, 74.3); t.eq(c.at[1], 1426)
    t.eq(c.xp, 120); t.eq(c.optional, true); t.eq(c.dungeon, "Deadmines")
    t.eq(Q.Guides:Normalize({ "accept", 1599, class = "WARLOCK" }).class, { "WARLOCK" }, "string filter wrapped")
    local again = Q.Guides:Normalize(a)
    t.eq(again.action, "accept"); t.eq(again.questId, 179)
  end,

  normalize_rejects_bad_steps = function(t)
    local Q = load()
    local s, err = Q.Guides:Normalize({ "dance", 1 })
    t.eq(s, nil); t.ok(err and err:find("dance", 1, true))
    t.eq(Q.Guides:Normalize({ "accept" }), nil, "missing quest id")
    t.eq(Q.Guides:Normalize({ "goto", 1426, 20 }), nil, "missing y")
    t.eq(Q.Guides:Normalize({ "level" }), nil)
    t.eq(Q.Guides:Normalize({ "note" }), nil)
    t.eq(Q.Guides:Normalize({ "complete", 170, at = { 1426, 20 } }), nil, "bad at")
    t.eq(Q.Guides:Normalize("accept"), nil)
  end,

  invalid_guide_ignored = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "X", steps = { { "dance", 1 } } })
    t.eq(Q.Guides:Get("X"), nil)
    t.ok(Mock.printed("X"))
    t.eq(Mock.countPrinted("Invalid guide X"), 1, "one error line")
    Q:RegisterGuide({ steps = {} })
    Q:RegisterGuide("nope")
    t.eq(#Mock.errors, 0)
  end,

  registered_guides_listed = function(t)
    local Q = load()
    local all = Q.Guides:All()
    t.eq(#all, 2)
    t.eq(all[1].id, "A_DwarfGnome_01"); t.eq(all[2].id, "A_DwarfGnome_02")
    local g = Q.Guides:Get("A_DwarfGnome_01")
    t.eq(g.title, "Coldridge Valley"); t.eq(g.minLevel, 1); t.eq(g.maxLevel, 6)
    t.eq(g.steps[7].at.x, 26.1)
    t.eq(g.steps[1].action, "accept")
  end,

  picks_chapter_by_level = function(t)
    local Q = load()
    t.eq(Q.Guides:ForPlayer("Alliance", "Dwarf", 1).id, "A_DwarfGnome_01")
    t.eq(Q.Guides:ForPlayer("Alliance", "Dwarf", 7).id, "A_DwarfGnome_02")
    t.eq(Q.Guides:ForPlayer("Alliance", "Human", 7), nil)
    t.eq(Q.Guides:ForPlayer("Alliance", "Gnome", 6).id, "A_DwarfGnome_02", "maxLevel is exclusive")
    t.eq(Q.Guides:ForPlayer("Alliance", "Dwarf", 25).id, "A_DwarfGnome_02", "highest minLevel <= level")
    t.eq(Q.Guides:ForPlayer("Horde", "Dwarf", 1), nil, "faction must match")
  end,

  picks_race_specific_first = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "A_00_Trunk", faction = "Alliance", minLevel = 1, maxLevel = 6, steps = { { "note", "x" } } })
    t.eq(Q.Guides:ForPlayer("Alliance", "Dwarf", 2).id, "A_DwarfGnome_01", "race-specific beats lower id")
    t.eq(Q.Guides:ForPlayer("Alliance", "Human", 2).id, "A_00_Trunk", "trunk chapter for other races")
  end,

  next_chapter = function(t)
    local Q = load()
    t.eq(Q.Guides:Next(Q.Guides:Get("A_DwarfGnome_01"), "Dwarf").id, "A_DwarfGnome_02")
    t.eq(Q.Guides:Next(Q.Guides:Get("A_DwarfGnome_02"), "Dwarf"), nil)
    Q:RegisterGuide({ id = "A_Start", faction = "Alliance", minLevel = 1, maxLevel = 5,
      next = "A_DwarfGnome_02", nextByRace = { Gnome = "A_DwarfGnome_01" }, steps = { { "note", "x" } } })
    t.eq(Q.Guides:Next(Q.Guides:Get("A_Start"), "Gnome").id, "A_DwarfGnome_01")
    t.eq(Q.Guides:Next(Q.Guides:Get("A_Start"), "Dwarf").id, "A_DwarfGnome_02")
  end,
}
