-- Tests de l'autodiagnostic (/qf check), du rapport de bug (/qf bug, alias /qf report) et du journal d'erreurs.
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local EARLY = "tests/fixtures/early_error_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

local function load(opts)
  Ext.install()
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end
  return Mock.loadAddon(TOC, opts)
end

local function qf(msg) SlashCmdList.QUESTIFYVANILLA(msg) end

local function byId(results)
  local out = {}
  for _, r in ipairs(results) do out[r.id] = r end
  return out
end

local function run(Q) return byId(Q.Diagnostics:Run()) end

local function readFile(p)
  local f = assert(io.open(Mock.root .. "/" .. p, "rb"))
  local s = f:read("*a")
  f:close()
  return s
end

return {
  check_forever_all_ok = function(t)
    local Q = load()
    qf("check")
    local results = Q.Diagnostics:Run()
    t.eq(Q.Diagnostics.Problems(results), 0, "no problem on a healthy Forever client")
    local r = byId(results)
    t.eq(r.client.status, "ok")
    t.ok(r.client.detail:find("Forever", 1, true))
    t.eq(r.questiedb.status, "ok")
    t.eq(r.questlog.status, "ok")
    t.eq(r.automation.status, "ok")
    t.eq(r.position.status, "ok")
    t.eq(r.waypoint.status, "ok")
    t.eq(r.waypoint.detail, Q.L.DIAG_WAYPOINT_PLACED, "pin of the current step is placed")
    t.eq(r.route.status, "ok")
    t.ok(r.route.detail:find("A_DwarfGnome_01", 1, true))
    t.eq(r.errors.status, "ok")
    t.ok(Mock.printed("Self-check: " .. #results .. " checks, no problem found."))
    t.ok(Mock.printed("[OK] Game client: Forever 1.60.1"), "every line is printed")
    t.eq(#Mock.errors, 0)
  end,

  check_reports_missing_game_functions = function(t)
    local Q = load()
    AcceptQuest = nil
    C_SuperTrack = nil
    C_QuestLog.GetTitleForQuestID = nil
    local r = run(Q)
    t.eq(r.automation.status, "fail")
    t.ok(r.automation.detail:find("AcceptQuest", 1, true), "names the missing function")
    t.eq(r.questlog.status, "fail")
    t.ok(r.questlog.detail:find("C_QuestLog.GetTitleForQuestID", 1, true))
    t.eq(r.waypoint.status, "warn")
    t.eq(r.waypoint.detail, Q.L.DIAG_WAYPOINT_NO_3D)
    qf("check")
    t.ok(Mock.printed("3 problem(s)"), "summary counts the problems")
  end,

  check_waypoint_refused_and_lost = function(t)
    local Q = load()
    Mock.userWaypoint = nil                       -- le jeu a retiré le repère posé par Questify
    t.eq(run(Q).waypoint.detail, Q.L.DIAG_WAYPOINT_LOST)
    Q.Nav:SetTarget(99999, 50, 50, "Nowhere")     -- carte inconnue : le jeu refuse le repère
    local r = run(Q)
    t.eq(r.waypoint.status, "warn")
    t.ok(r.waypoint.detail:find("99999", 1, true), "names the refused map")
    t.eq(#Mock.errors, 0)
  end,

  check_navigation_fallback = function(t)
    local Q = load()
    Q.Settings:Set("nav.display", "tomtom")       -- TomTom choisi mais absent
    local r = run(Q)
    t.eq(r.navigation.status, "warn")
    t.ok(r.navigation.detail:find("TomTom", 1, true))
    Q.Settings:Set("nav.display", "native")
    Q.Settings:Set("nav.routing", true)           -- ShortestPath choisi mais absent
    t.eq(run(Q).navigation.status, "warn")
  end,

  check_navigation_with_tomtom = function(t)
    Mock.addons.TomTom = true
    local Q = load()
    Q.Settings:Set("nav.display", "tomtom")
    local r = run(Q)
    t.eq(r.navigation.status, "ok")
    t.ok(r.navigation.detail:find("TomTom", 1, true))
    t.eq(r.waypoint.detail, Q.L.DIAG_WAYPOINT_READY, "no native pin while TomTom shows the step")
  end,

  check_route_missing_and_qdb_missing = function(t)
    Mock.player.raceId = 1                        -- Humain : pas de chapitre dans la fixture
    local Q = load()
    local r = run(Q)
    t.eq(r.route.status, "warn")
    t.ok(r.route.detail:find("Human", 1, true))
    Mock.reset()
    Mock.addons.QuestieDB = false
    Q = load()
    r = run(Q)
    t.eq(r.questiedb.status, "fail")
    t.eq(r.route.status, "fail")
    t.eq(#Mock.errors, 0)
  end,

  check_unknown_client = function(t)
    local Q = load()
    GetBuildInfo = function() return "11.2.5", "63906", "Oct 7 2026", 110205 end
    local r = run(Q)
    t.eq(r.client.status, "warn", "only Forever is supported")
    t.ok(r.client.detail:find("110205", 1, true))
    t.eq(#Mock.errors, 0)
  end,

  check_failing_probe_does_not_stop_others = function(t)
    local Q = load()
    Q.Nav.Detect = function() error("detect exploded") end
    local results = Q.Diagnostics:Run()
    local r = byId(results)
    t.eq(r.navigation.status, "fail")
    t.ok(r.navigation.detail:find("detect exploded", 1, true))
    t.eq(r.errors.status, "ok", "later checks still run")
  end,

  errors_saved_with_stack_counted_and_hinted = function(t)
    local Q = load()
    for _ = 1, 3 do Q.SafeCall(function() error("boom") end) end
    t.eq(Mock.countPrinted("boom"), 1, "printed once")
    t.eq(Mock.countPrinted(Q.L.ERROR_REPORT_HINT), 1, "hint printed once")
    local list = QuestifyVanillaDB.errors
    t.eq(#list, 1)
    t.eq(list[1].count, 3)
    t.eq(list[1].version, Q.version)
    t.ok(type(list[1].stack) == "string" and list[1].stack:find("traceback", 1, true), "stack kept")
    t.ok(not list[1].msg:find("traceback", 1, true), "message without the stack")
    Q.SafeCall(function() error("second") end)
    t.eq(Mock.countPrinted(Q.L.ERROR_REPORT_HINT), 1, "hint once per session")
    t.eq(#QuestifyVanillaDB.errors, 2)
    t.ok(QuestifyVanillaDB.errors[2].msg:find("second", 1, true), "most recent last")
    t.eq(run(Q).errors.status, "warn")
  end,

  errors_survive_reload = function(t)
    local Q = load()
    Q.SafeCall(function() error("kept across reload") end)
    Q = Mock.reload()
    local list = Q:SavedErrors()
    t.eq(#list, 1)
    t.ok(list[1].msg:find("kept across reload", 1, true))
    t.eq(Mock.countPrinted(Q.L.ERROR_REPORT_HINT), 1, "loading saved errors prints nothing")
  end,

  errors_capped_and_old_versions_ignored = function(t)
    local Q = load({ savedVariables = { QuestifyVanillaDB = {
      errors = { { msg = "from 0.0.9", count = 4, time = 1, version = "0.0.9" } },
    } } })
    t.eq(run(Q).errors.status, "ok", "errors of another version are not counted")
    for i = 1, 25 do Q:ReportError("err " .. i) end
    local list = QuestifyVanillaDB.errors
    t.eq(#list, 20, "20 errors at most")
    t.eq(list[20].msg, "err 25")
    t.eq(list[1].msg, "err 6")
  end,

  errors_before_saved_variables_are_kept = function(t)
    local Q = load({ extraFiles = { GUIDES, EARLY } })
    local list = QuestifyVanillaDB.errors
    t.eq(#list, 1)
    t.eq(list[1].msg, "early error before saved variables")
  end,

  debug_mode_prints_stack = function(t)
    local Q = load({ savedVariables = { QuestifyVanillaDB = { debug = true } } })
    Q.SafeCall(function() error("loud") end)
    t.ok(Mock.printed("stack traceback"), "stack in the chat in debug mode")
  end,

  report_window_text = function(t)
    local Q = load()
    Q.SafeCall(function() error("boom in report") end)
    qf("report")
    t.ok(QuestifyVanillaReport:IsShown())
    local text = Q.UI.Report.box:GetText()
    t.ok(text:find("Questify Vanilla " .. Q.version .. " - bug report", 1, true), "title line")
    t.ok(text:find("Client: 1.60.1 (70291), interface 16001, enUS", 1, true), "client line")
    t.ok(text:find("Character: Alliance Dwarf WARRIOR, level 1", 1, true), "character line")
    t.ok(text:find("Route: A_DwarfGnome_01", 1, true), "route line")
    t.ok(text:find("Step: g:A_DwarfGnome_01:1", 1, true), "step line")
    t.ok(text:find("Target: Dun Morogh (1426)", 1, true), "target line")
    t.ok(text:find("nav.display=native", 1, true), "settings line")
    t.ok(text:find("[OK] QuestieDB", 1, true), "checks without colors")
    t.ok(not text:find("|c", 1, true), "plain text only")
    t.ok(text:find("Errors (1):", 1, true))
    t.ok(text:find("boom in report", 1, true))
    t.ok(text:find("traceback", 1, true), "stack included")
  end,

  bug_report_has_route_context = function(t)
    local Q = load()
    Mock.quests.log[179] = { title = "Dwarven Outfitters", complete = true }
    Q:ReportError("Interface/AddOns/Questify_Vanilla/X.lua:1: boom")
    qf("bug")
    t.ok(QuestifyVanillaReport:IsShown(), "/qf bug opens the report window")
    local text = Q.UI.Report.box:GetText()
    for _, needle in ipairs({ "Addons: QuestieDB", "WARRIOR", "(1426)", "Route: A_DwarfGnome_01", "accept 179",
      "  next: g:A_DwarfGnome_01:", "Step target: ", "Navigation: routing -, display native",
      "Quest log (1): 179*", "boom" }) do
      t.ok(text:find(needle, 1, true), needle)
    end
    t.eq(#Mock.errors, 1, "only the error we reported")
  end,

  report_alias_and_check_alias = function(t)
    local Q = load()
    qf("report")
    t.ok(QuestifyVanillaReport:IsShown(), "/qf report is an alias")
    Q.UI.Report:Hide()
    qf("diag")
    t.ok(Mock.printed("Self-check:"), "/qf diag is an alias of /qf check")
  end,

  report_is_read_only_and_refreshed = function(t)
    local Q = load()
    qf("report")
    local box = Q.UI.Report.box
    local first = box:GetText()
    box:SetText("typed by the player")
    box:GetScript("OnTextChanged")(box, true)
    t.eq(box:GetText(), first, "typing restores the report")
    Q.SafeCall(function() error("new error") end)
    qf("bug")
    t.ok(box:GetText():find("new error", 1, true), "text rebuilt on every opening")
  end,

  report_clear = function(t)
    local Q = load()
    Q.SafeCall(function() error("to clear") end)
    qf("bug  CLEAR ")
    t.eq(#Q:SavedErrors(), 0)
    t.ok(Mock.printed(Q.L.REPORT_CLEARED))
    t.ok(not (QuestifyVanillaReport and QuestifyVanillaReport:IsShown()), "clear does not open the window")
  end,

  report_survives_a_failing_diagnostic = function(t)
    local Q = load()
    Q.Diagnostics.Report = function() error("report exploded") end
    qf("report")
    t.ok(Q.UI.Report.box:GetText():find("report exploded", 1, true))
  end,

  report_button_in_options = function(t)
    local Q = load()
    qf("options")
    Q.UI.Journal.reportButton:Click()
    t.ok(QuestifyVanillaReport:IsShown())
  end,

  help_lists_new_commands = function(t)
    local Q = load()
    qf("whatever")
    t.ok(Mock.printed("/qf check, /qf bug"))
  end,

  french_strings_complete = function(t)
    local captured
    local fake = { RegisterStrings = function(_, tables) captured = tables end }
    assert(loadfile(Mock.root .. "/Questify_Vanilla/Locales/StringsDiag.lua"))("Questify_Vanilla", fake)
    for k in pairs(captured.enUS) do t.ok(captured.frFR[k], "frFR has " .. k) end
    for k in pairs(captured.frFR) do t.ok(captured.enUS[k], "enUS has " .. k) end
    -- chaque clé utilisée par le diagnostic et la fenêtre existe
    Mock.locale = "frFR"
    local Q = load()
    for _, file in ipairs({ "Questify_Vanilla/Core/Diagnostics.lua", "Questify_Vanilla/UI/Report.lua",
                            "Questify_Vanilla/UI/Slash.lua", "Questify_Vanilla/Core/Init.lua" }) do
      local src = readFile(file)
      for key in src:gmatch("L%.([%u%d_]+)") do t.ok(rawget(Q.L, key), file .. ": " .. key) end
      for key in src:gmatch("\"(DIAG_[%u%d_]+)\"") do t.ok(rawget(Q.L, key), file .. ": " .. key) end
    end
    qf("check")
    t.ok(Mock.printed("Autodiagnostic"), "French summary")
  end,
}
