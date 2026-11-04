-- Tests de la mesure du temps par étape (Q.Telemetry).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  return Mock.loadAddon(TOC, opts)
end

local function accept179()
  Mock.quests.log[179] = { complete = false, objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
  Mock.fire("QUEST_ACCEPTED", 179)
end

local function notes(Q)
  Q:RegisterGuide({ id = "T_notes", faction = "Alliance", minLevel = 1, maxLevel = 60,
    steps = { { "note", "A" }, { "note", "B" }, { "note", "C" } } })
  Q.Progress:SetGuide("T_notes")
  return Q.Progress:Entries()
end

return {
  telemetry_export_format = function(t)
    local Q = load()
    t.ok(Q.Telemetry:Export():find("^QV1;"), "starts with QV1;")
    t.eq(Q.Telemetry:Export(), "QV1;", "nothing measured yet")
    Mock.advance(30)
    accept179()   -- la prise de 179 est faite : l'étape 1 a duré 30 s
    t.eq(Q.Telemetry:Export(), "QV1;A_DwarfGnome_01:1=30")
    Mock.advance(12)
    Mock.quests.log[179].complete = true
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(1)   -- le journal est relu après 0,2 s : l'étape 2 a duré 12,2 s
    t.eq(Q.Telemetry:Export(), "QV1;A_DwarfGnome_01:1=30,2=12")
    t.ok(not Q.Telemetry:Export():find("\n", 1, true), "one line")
  end,

  records_time_of_the_step_left = function(t)
    local Q = load()
    local list = notes(Q)
    Mock.advance(10)
    Q.Progress:MarkDone(list[1].key)
    t.eq(Q.char.telemetry.T_notes[1], 10)
    Mock.advance(20)
    Q.Progress:MarkDone(list[2].key)
    t.eq(Q.char.telemetry.T_notes[2], 20)
    t.eq(Q.char.telemetry.T_notes[3], nil, "step C is still current")
  end,

  slot_is_filled_once = function(t)
    local Q = load()
    local list = notes(Q)
    Mock.advance(10)
    Q.Progress:MarkDone(list[1].key)
    Mock.advance(20)
    Q.Progress:Back()            -- on revient sur A : B est quittée sans être finie
    t.eq(Q.char.telemetry.T_notes[2], nil, "B was left unfinished")
    Mock.advance(99)
    Q.Progress:MarkDone(list[1].key)
    t.eq(Q.char.telemetry.T_notes[1], 10, "kept the first measure")
  end,

  unfinished_steps_are_not_recorded = function(t)
    local Q = load()
    local list = notes(Q)
    -- étape passée par le joueur
    Mock.advance(10)
    Q.Progress:Skip(list[1].key)
    t.eq(Q.char.telemetry.T_notes, nil, "skipped step")
    -- étape dépassée par un saut dans la liste
    Mock.advance(10)
    Q.Progress:JumpTo(list[3].key)
    t.eq(Q.char.telemetry.T_notes, nil, "jumped over")
    -- étape repoussée par une chaîne insérée : elle n'est pas finie
    Mock.advance(10)
    Q.Progress:InsertSteps("cq:X", { { "note", "inserted" } })
    t.eq(Q.char.telemetry.T_notes, nil, "preempted by an inserted chain")
    -- et finie ensuite, elle compte
    Q.Progress:RemoveInserted("cq:X")
    Mock.advance(6)
    Q.Progress:MarkDone(list[3].key)
    t.eq(Q.char.telemetry.T_notes[3], 6)
    t.eq(Q.char.telemetry.T_notes[1], nil); t.eq(Q.char.telemetry.T_notes[2], nil)
  end,

  passed_steps_are_not_recorded = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "T_pass", faction = "Alliance", minLevel = 1, maxLevel = 60,
      steps = { { "note", "before" }, { "accept", 179 }, { "note", "after" } } })
    Q.Progress:SetGuide("T_pass")
    Mock.advance(20)
    accept179()   -- la quête est prise : la note qui la précède est dépassée, pas terminée
    t.eq(Q.Progress:Current().step.text, "after")
    t.eq(Q.char.telemetry.T_pass, nil)
  end,

  setting_off_records_nothing = function(t)
    local Q = load()
    Q.Settings:Set("telemetry", false)
    local list = notes(Q)
    Mock.advance(10)
    Q.Progress:MarkDone(list[1].key)
    t.eq(next(Q.char.telemetry), nil)
    t.eq(Q.Telemetry:Export(), "QV1;")
    -- réactivé : les mesures suivantes comptent
    Q.Settings:Set("telemetry", true)
    Mock.advance(7)
    Q.Progress:MarkDone(list[2].key)
    t.eq(Q.char.telemetry.T_notes[2], 7)
  end,

  inserted_steps_are_not_measured = function(t)
    local Q = load()
    notes(Q)
    Q.char.telemetry = {}   -- on repart de zéro après le changement de chapitre
    Q.Progress:InsertSteps("x", { { "note", "inserted" } })
    Mock.advance(5)
    Q.Progress:MarkDone("i:x:1")
    for guideId in pairs(Q.char.telemetry) do t.eq(guideId, "T_notes", "only guide steps are measured") end
    t.ok(not Q.Telemetry:Export():find("x:", 1, true))
    t.eq(Q.char.telemetry.T_notes, nil, "the guide step was preempted, not finished")
  end,

  export_is_sorted_and_compact = function(t)
    local Q = load()
    Q.char.telemetry = { B = { [10] = 7, [2] = 5, [1] = 3 }, A = { [1] = 1 }, C = {} }
    t.eq(Q.Telemetry:Export(), "QV1;A:1=1;B:1=3,2=5,10=7")
  end,

  measures_survive_reload = function(t)
    local Q = load()
    Mock.advance(8)
    accept179()
    local Q2 = Mock.reload()
    t.eq(Q2.Telemetry:Export(), "QV1;A_DwarfGnome_01:1=8")
  end,

  route_end_is_handled = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "T_one", faction = "Alliance", minLevel = 1, maxLevel = 60, steps = { { "note", "only" } } })
    Q.Progress:SetGuide("T_one")
    Mock.advance(3)
    Q.Progress:MarkDone("g:T_one:1")   -- plus d'étape courante
    t.eq(Q.char.telemetry.T_one[1], 3)
    for _, e in ipairs(Mock.errors) do t.ok(not tostring(e):find("Telemetry.lua", 1, true), tostring(e)) end
  end,
}
