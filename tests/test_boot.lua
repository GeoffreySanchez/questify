-- Tests de démarrage : chargement du TOC, messages INIT/LOGIN, absence de QuestieDB.
local TOC = "Questify/Questify.toc"

return {
  loads_and_fires_login = function(t)
    local loginSeen = false
    local Q = Mock.loadAddon(TOC, { beforeLogin = function(Q) Q:On("LOGIN", function() loginSeen = true end) end })
    t.ok(Questify == Q, "global set")
    t.ok(loginSeen, "LOGIN fired")
    t.eq(Q.Settings:Get("nav.display"), "native")
    t.ok(Q.IsForever())
    t.eq(#Mock.errors, 0, "no Lua error")
  end,

  boots_without_questiedb = function(t)
    Mock.addons.QuestieDB = false            -- le mock ne définit alors aucune globale QuestieDB
    local Q = Mock.loadAddon(TOC)
    t.ok(Mock.printed("QuestieDB"), "explains missing dependency")
    t.eq(#Mock.errors, 0, "no Lua error")
    t.eq(Mock.countPrinted("QuestieDB"), 1, "one chat line only")
  end,

  init_fires_before_login_and_saved_state = function(t)
    local order = {}
    local Q = Mock.loadAddon(TOC, {
      extraFiles = {},
      beforeLogin = function(Q)
        order[#order + 1] = Q.char and "char" or "nochar"
        Q:On("LOGIN", function() order[#order + 1] = "login" end)
      end,
    })
    t.eq(order, { "char", "login" })
    t.ok(QuestifyDB == Q.db, "Q.db is the saved table")
    t.ok(QuestifyCharDB == Q.char, "Q.char is the saved table")
    t.eq(type(Q.char.manual), "table")
    t.eq(type(Q.char.skipped), "table")
    t.eq(type(Q.char.inserted), "table")
    t.eq(type(Q.char.classQuests.added), "table")
    t.eq(type(Q.char.classQuests.ignored), "table")
    t.eq(type(Q.char.classQuests.seen), "table")
    t.eq(type(Q.char.telemetry), "table")
    t.eq(Q.Settings:Get("tracker.nextSteps"), 3)
    t.eq(type(Q.db.profiles.Default.settings), "table", "settings live in the Default profile")
    t.eq(Q.db.settings, nil, "no settings table outside the profiles")
  end,

  saved_variables_survive_reload = function(t)
    local Q = Mock.loadAddon(TOC)
    Q.Settings:Set("nav.display", "tomtom")
    Q.char.wizardDone = true
    local Q2 = Mock.reload()
    t.ok(Q2 ~= Q, "new namespace")
    t.eq(Q2.Settings:Get("nav.display"), "tomtom")
    t.eq(Q2.char.wizardDone, true)
  end,

  register_event_dispatches_to_several_handlers = function(t)
    local Q = Mock.loadAddon(TOC)
    local got = {}
    local h1 = function(event, a) got[#got + 1] = "1" .. event .. a end
    local h2 = function(event, a) got[#got + 1] = "2" .. a end
    Q:RegisterEvent("UNIT_AURA", h1)
    Q:RegisterEvent("UNIT_AURA", h2)
    Mock.fire("UNIT_AURA", "x")
    Q:UnregisterEvent("UNIT_AURA", h1)
    Mock.fire("UNIT_AURA", "y")
    t.eq(got, { "1UNIT_AURAx", "2x", "2y" })
  end,

  event_handler_error_does_not_break_others = function(t)
    local Q = Mock.loadAddon(TOC)
    local reached = false
    Q:RegisterEvent("UNIT_AURA", function() error("kaboom") end)
    Q:RegisterEvent("UNIT_AURA", function() reached = true end)
    Mock.fire("UNIT_AURA")
    t.ok(reached, "second handler still runs")
    t.ok(Mock.printed("Questify:"), "error reported with prefix")
    t.eq(Mock.countPrinted("kaboom"), 1)
  end,

  locale_fr_overrides_en = function(t)
    Mock.locale = "frFR"
    local Q = Mock.loadAddon(TOC)
    t.eq(Q.L.NEED_QUESTIEDB, "QuestieDB est requis : installe-le depuis CurseForge.")
    t.eq(Q.L.SOME_MISSING_KEY, "SOME_MISSING_KEY")
    Q:RegisterStrings({ enUS = { X_TEST = "hello" }, frFR = { X_TEST = "bonjour" } })
    t.eq(Q.L.X_TEST, "bonjour")
    Q:RegisterStrings({ enUS = { Y_TEST = "only english" } })
    t.eq(Q.L.Y_TEST, "only english")
  end,

  print_and_debug = function(t)
    local Q = Mock.loadAddon(TOC)
    Q:Print("hello %d", 42)
    t.ok(Mock.printed("|cff33ccffQuestify|r: hello 42"))
    Q:Debug("hidden-line")
    t.ok(not Mock.printed("hidden-line"))
    QuestifyDB.debug = true
    Q:Debug("shown-line", 1)
    t.ok(Mock.printed("shown-line"))
  end,

  toc_files_identical_and_complete = function(t)
    local function read(p)
      local f = assert(io.open(Mock.root .. "/" .. p, "rb")); local s = f:read("*a"); f:close(); return s
    end
    local a = read("Questify/Questify.toc")
    local b = read("Questify/Questify_Camelot.toc")
    t.eq(a, b, "both TOC files identical")
    t.ok(a:find("## Interface: 16001", 1, true), "interface")
    t.ok(a:find("## AddonCompartmentFunc: Questify_OnAddonCompartmentClick", 1, true), "compartment")
    t.ok(a:find("Guides\\Guides.xml", 1, true), "guides xml listed")
    t.ok(a:find("UI\\Slash.lua", 1, true), "complete file list")
    local count = 0
    for line in a:gmatch("[^\r\n]+") do
      if not line:match("^%s*#") and line:match("%S") then
        count = count + 1
        local f = io.open(Mock.root .. "/Questify/" .. line:gsub("\\", "/"):gsub("%s+$", ""), "rb")
        t.ok(f, "listed file exists: " .. line)
        if f then f:close() end
      end
    end
    t.ok(count > 50, "TOC lists its files")
    for _, name in ipairs({ "Engine\\TalentTree.lua", "Engine\\Builds.lua", "Engine\\TalentLearn.lua",
      "Engine\\BuildEditor.lua", "Engine\\BuildCodec.lua", "Engine\\SpellList.lua", "UI\\TalentPopup.lua",
      "UI\\TalentFrameHook.lua", "UI\\BuildWindow.lua", "UI\\BuildPane.lua", "UI\\SpellsPane.lua",
      "Data\\TalentBuilds.lua", "Data\\ClassSpells.lua", "Data\\SpellQuests.lua" }) do
      t.ok(a:find(name, 1, true), "TOC lists " .. name)
    end
    t.ok(not a:find("TalentPicker", 1, true), "old picker not listed")
  end,
}
