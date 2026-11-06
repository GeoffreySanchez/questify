-- Tests des étapes propres à une classe (champ `classes` des étapes) : format et validation (Q.Guides),
-- filtrage des entrées (Q.Progress), progression, journal, mesures, remise à zéro, automatisation,
-- cartes de choix de suite, icône de classe (Q.Format) et chaînes de classe « dans la route »
-- (Q.ClassQuests).
local TOC = "Questify/Questify.toc"
local CLASS = "tests/fixtures/class_steps_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

-- Données de quêtes de classe des tests (le fichier généré n'est pas chargé : skipGuides).
local DATA = {
  WARLOCK = {
    -- 1599 rendue dans C_Class_01, 1598 dans C_Class_02 (étapes du Démoniste) : dans la route
    { key = "WARLOCK_CHAIN", title = "The Stolen Tome", faction = "Alliance", level = 1, quests = { 1599, 1598 },
      rewards = {} },
    -- 9003 n'est rendue par aucune étape : la chaîne n'est qu'en partie dans la route
    { key = "WARLOCK_MIX", title = "Half in the route", level = 1, quests = { 1599, 9003 }, rewards = {} },
    { key = "WARLOCK_LATE", title = "Late chain", level = 10, quests = { 9004 }, rewards = {} },
  },
  MAGE = {
    -- le Mage prend 1598 dans C_Class_02 mais ne la rend pas : pas dans la route
    { key = "MAGE_1598", title = "Mage tome", level = 1, quests = { 1598 }, rewards = {} },
  },
}

local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { CLASS }
  if opts.skipGuides == nil then opts.skipGuides = true end
  if opts.data ~= false then
    local data = opts.data or DATA
    opts.beforeLogin = opts.beforeLogin or function(Q) Q.ClassQuestData = data end
  end
  return Mock.loadAddon(TOC, opts)
end

local function as(classFile) Mock.player.classFile = classFile end

local function keys(Q)
  local out = {}
  for _, e in ipairs(Q.Progress:Entries()) do out[#out + 1] = e.key end
  return out
end

local function accept(id)
  Mock.quests.log[id] = { complete = false, objectives = {} }
  Mock.fire("QUEST_ACCEPTED", id)
end

local function turnIn(id)
  Mock.quests.log[id] = nil
  Mock.quests.completed[id] = true
  Mock.fire("QUEST_TURNED_IN", id)
end

local function stateOf(Q, key)
  for _, r in ipairs(Q.ClassQuests:List()) do if r.chain.key == key then return r.state end end
end

local function alertKeys(Q)
  local out = {}
  for _, r in ipairs(Q.ClassQuests:Alerts()) do out[#out + 1] = r.chain.key end
  return out
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

local function noErrors(t)
  for _, e in ipairs(Mock.errors) do t.ok(false, "unexpected error: " .. tostring(e)) end
end

local function G(n) return "g:C_Class_01:" .. n end

return {
  ---------------------------------------------------------------------------
  -- Format (Q.Guides)
  ---------------------------------------------------------------------------
  normalize_accepts_classes = function(t)
    local Q = load()
    local s = Q.Guides:Normalize({ "accept", 1599, classes = { "WARLOCK" } })
    t.eq(s.classes, { "WARLOCK" })
    t.eq(Q.Guides:Normalize({ "note", "x", classes = { "WARRIOR", "PALADIN" } }).classes, { "WARRIOR", "PALADIN" })
    t.eq(Q.Guides:Normalize({ "note", "x", classes = "MAGE" }).classes, { "MAGE" }, "a single name is wrapped")
    t.eq(Q.Guides:Normalize({ "note", "x" }).classes, nil, "absent: every class")
    t.eq(Q.Guides:Normalize(s).classes, { "WARLOCK" }, "a normalized step normalizes again")
    t.ok(Q.Guides:Normalize(s).classes ~= s.classes, "copied, not shared")
    t.eq(Q.Guides:Get("C_Class_01").steps[2].classes, { "WARLOCK" })
    noErrors(t)
  end,

  normalize_rejects_bad_classes = function(t)
    local Q = load()
    local s, err = Q.Guides:Normalize({ "accept", 1599, classes = { "WARLOK" } })
    t.eq(s, nil)
    t.ok(err and err:find("accept: unknown class 'WARLOK' in classes", 1, true), tostring(err))
    s, err = Q.Guides:Normalize({ "accept", 1599, classes = { "warlock" } })
    t.eq(s, nil, "classFile names are upper case"); t.ok(err:find("'warlock'", 1, true), err)
    s, err = Q.Guides:Normalize({ "note", "x", classes = {} })
    t.eq(s, nil); t.ok(err:find("note: classes must name at least one class", 1, true), err)
    s, err = Q.Guides:Normalize({ "note", "x", classes = { 5 } })
    t.eq(s, nil); t.ok(err:find("note: classes must be a list of class names", 1, true), err)
    s, err = Q.Guides:Normalize({ "note", "x", classes = 5 })
    t.eq(s, nil); t.ok(err:find("classes must be a list of class names", 1, true), err)
    -- un guide avec une étape fautive est ignoré, avec un message clair
    Q:RegisterGuide({ id = "C_Bad", faction = "Alliance", steps = { { "note", "ok" }, { "note", "x", classes = { "WARLOK" } } } })
    t.eq(Q.Guides:Get("C_Bad"), nil)
    t.ok(Mock.printed("step 2: note: unknown class 'WARLOK' in classes"), "clear message")
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Entrées et progression (Q.Progress)
  ---------------------------------------------------------------------------
  entries_keep_only_the_player_class_steps = function(t)
    local Q = load()   -- Guerrier
    t.eq(keys(Q), { G(1), G(6), G(7) }, "no class step for a warrior")
    t.eq(Q.Progress:Entries()[2].index, 6, "guide index kept")
    Mock.reset()
    as("WARLOCK")
    Q = load()
    t.eq(keys(Q), { G(1), G(2), G(4), G(5), G(6), G(7) })
    Mock.reset()
    as("MAGE")
    Q = load()
    t.eq(keys(Q), { G(1), G(3), G(6), G(7) })
    noErrors(t)
  end,

  class_steps_drive_the_current_step = function(t)
    as("WARLOCK")
    local Q = load()
    t.eq(Q.Progress:Current().key, G(1))
    accept(179)
    t.eq(Q.Progress:Current().key, G(2), "Beginnings next")
    accept(1599)
    t.eq(Q.Progress:Current().key, G(4))
    turnIn(1599)
    t.eq(Q.Progress:Current().key, G(6))
    Mock.reset()
    local W = load()   -- Guerrier : les étapes du Démoniste n'existent pas pour lui
    accept(179)
    t.eq(W.Progress:Current().key, G(6))
    t.eq(W.Progress:JumpTo(G(2)), false, "another class step cannot be reached")
    noErrors(t)
  end,

  chapter_end_ignores_other_class_steps = function(t)
    local Q = load()   -- Guerrier
    accept(179)
    turnIn(179)
    t.ok(not Q.Progress:GuideFinished(), "accept 170 left")
    accept(170)
    -- les étapes du Démoniste (ni faites ni sautées pour lui) ne retiennent pas le Guerrier
    t.eq(Q.Progress:Guide().id, "C_Class_02", "next chapter")
    t.eq(keys(Q), { "g:C_Class_02:3" })
    noErrors(t)
  end,

  tracker_counts_only_the_player_steps = function(t)
    local Q = load()   -- Guerrier : la note du Mage n'est pas comptée
    Q.UI.Tracker:Refresh()
    local bar = Q.UI.Tracker.barText:GetText() or ""
    t.eq(bar:sub(1, 3), string.format(Q.L.UI_TRACKER_PROGRESS, 0, 2), bar)
    accept(179)
    Q.UI.Tracker:Refresh()
    bar = Q.UI.Tracker.barText:GetText() or ""
    t.eq(bar:sub(1, 3), string.format(Q.L.UI_TRACKER_PROGRESS, 1, 3), bar)
    noErrors(t)
  end,

  journal_lists_only_the_player_class_steps = function(t)
    Ext.install()
    as("WARLOCK")
    local Q = load()
    local J = Q.UI.Journal
    J:Toggle()
    J:ShowTab("route")
    local shown = {}
    for _, r in ipairs(J.stepRows) do if r:IsShown() and r.entry then shown[#shown + 1] = r.entry.key end end
    t.eq(shown, { G(1), G(2), G(4), G(5), G(6), G(7) })
    noErrors(t)
  end,

  saved_states_keep_guide_indexes = function(t)
    as("WARLOCK")
    local Q = load()
    accept(179)
    Q.Progress:Skip(G(2))
    t.eq(Q.char.skipped[G(2)], true)
    t.eq(Q.Progress:Current().key, G(6))
    local Q2 = Mock.reload()
    t.eq(Q2.char.skipped[G(2)], true, "same key after /reload")
    t.eq(Q2.Progress:Current().key, G(6))
    t.eq(Q2.Progress:ResetGuide("C_Class_01"), true)
    t.eq(Q2.char.skipped[G(2)], nil, "chapter reset clears the class step")
    t.eq(Q2.Progress:Current().key, G(2))
    noErrors(t)
  end,

  slash_reset_keeps_the_class_filter = function(t)
    as("WARLOCK")
    local Q = load()
    accept(179)
    Q.Progress:Skip(G(2))
    SlashCmdList.QUESTIFY("reset")
    StaticPopupDialogs.QUESTIFY_RESET.OnAccept()
    t.eq(next(Q.char.skipped), nil, "wiped")
    t.eq(keys(Q), { G(1), G(2), G(4), G(5), G(6), G(7) }, "still the warlock steps")
    t.eq(Q.Progress:Current().key, G(2))
    noErrors(t)
  end,

  telemetry_export_uses_guide_indexes = function(t)
    as("MAGE")
    local Q = load()
    Mock.advance(10)
    accept(179)                       -- étape 1 faite en 10 s ; courante : la note du Mage (index 3)
    t.eq(Q.Progress:Current().key, G(3))
    Mock.advance(30)
    Q.Progress:MarkDone(G(3))
    t.eq(Q.Telemetry:Export(), "QV1;C_Class_01:1=10,3=30", "index of the step in the guide file")
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Automatisation, choix de suite, mise en forme
  ---------------------------------------------------------------------------
  auto_quest_route_quests_follow_classes = function(t)
    local Q = load()
    t.eq(Q.AutoQuest:IsRouteQuest(179), true)
    t.eq(Q.AutoQuest:IsRouteQuest(1599), false, "warlock step: not the warrior's route")
    t.eq(Q.AutoQuest:IsRouteQuest(1598), false)
    Mock.reset()
    as("WARLOCK")
    Q = load()
    t.eq(Q.AutoQuest:IsRouteQuest(1599), true)
    t.eq(Q.AutoQuest:IsRouteQuest(1598), true)
    Mock.reset()
    as("MAGE")
    Q = load()
    t.eq(Q.AutoQuest:IsRouteQuest(1598), true, "the mage accept step")
    t.eq(Q.AutoQuest:IsRouteQuest(1599), false)
  end,

  route_choice_card_counts_only_the_player_class = function(t)
    local Q = load()
    local card = Q.RouteChoice:Card({ guide = Q.Guides:Get("C_Class_01") }, 1)
    t.eq(card.quests, 1); t.eq(card.xp, 100)
    Mock.reset()
    as("WARLOCK")
    Q = load()
    card = Q.RouteChoice:Card({ guide = Q.Guides:Get("C_Class_01") }, 1)
    t.eq(card.quests, 2); t.eq(card.xp, 400)
  end,

  format_shows_the_class_icon = function(t)
    as("WARLOCK")
    local Q = load()
    CLASS_ICON_TCOORDS = { WARLOCK = { 0.75, 1, 0.25, 0.5 } }
    local list = Q.Progress:Entries()
    local head = Q.Format:StepParts(list[2]).head
    t.eq(head:sub(1, 52), "|TInterface\\TargetingFrame\\UI-Classes-Circles:0:0:0:", head)
    t.ok(head:find(":256:256:192:256:64:128|t ", 1, true), head)
    t.ok(head:find("Beginnings", 1, true), "text after the icon")
    t.ok(not Q.Format:StepParts(list[1]).head:find("|T", 1, true), "no icon on a step for every class")
    t.ok(not Q.Format:StepTitle(list[2]):find("|T", 1, true), "no icon in the short title")
    CLASS_ICON_TCOORDS = nil
    t.ok(not Q.Format:StepParts(list[2]).head:find("|T", 1, true), "no icon without the game table")
    noErrors(t)
  end,

  ---------------------------------------------------------------------------
  -- Chaînes de classe dans la route (Q.ClassQuests)
  ---------------------------------------------------------------------------
  chain_in_the_route_has_no_alert_and_cannot_be_added = function(t)
    as("WARLOCK")
    local Q = load()
    t.eq(stateOf(Q, "WARLOCK_CHAIN"), "inroute", "1599 here, 1598 in the next chapter")
    t.eq(stateOf(Q, "WARLOCK_MIX"), "available", "9003 is not in the route")
    t.eq(alertKeys(Q), { "WARLOCK_MIX" })
    t.eq(Q.ClassQuests:Add("WARLOCK_CHAIN"), false)
    t.eq(Q.ClassQuests:Track("WARLOCK_CHAIN"), false)
    t.eq(#Q.char.inserted, 0, "nothing inserted")
    t.ok(not Q.ClassQuests.IsLate(Q.ClassQuests:List()[1].chain, "inroute"), "never late")
    -- quête dans le journal : toujours dans la route (pas « en cours » avec un bouton Ajouter)
    accept(179); accept(1599)
    t.eq(stateOf(Q, "WARLOCK_CHAIN"), "inroute")
    turnIn(1599)
    t.eq(stateOf(Q, "WARLOCK_CHAIN"), "inroute", "the rest is in a future chapter")
    turnIn(1598)
    t.eq(stateOf(Q, "WARLOCK_CHAIN"), "done")
    noErrors(t)
  end,

  accept_without_turnin_is_not_in_the_route = function(t)
    as("MAGE")
    local Q = load()
    t.eq(stateOf(Q, "MAGE_1598"), "available", "the mage accepts 1598 but never turns it in")
    t.eq(alertKeys(Q), { "MAGE_1598" })
  end,

  skipped_route_step_frees_the_chain = function(t)
    as("WARLOCK")
    local Q = load()
    Q.Progress:Skip(G(5))   -- le joueur passe le rendu de 1599 : la route ne la fera plus
    t.eq(stateOf(Q, "WARLOCK_CHAIN"), "available")
    t.eq(Q.ClassQuests:Add("WARLOCK_CHAIN"), true)
    t.eq(stateOf(Q, "WARLOCK_CHAIN"), "added")
    t.eq(Q.char.inserted[1].tag, "cq:WARLOCK_CHAIN", "kept while the route does not cover it")
    noErrors(t)
  end,

  chain_in_a_chosen_successor_is_in_the_route = function(t)
    as("WARLOCK")
    local Q = load({ data = { WARLOCK = {
      { key = "WARLOCK_TOME", title = "Tome", level = 1, quests = { 1598 }, rewards = {} } } } })
    Q:RegisterGuide({ id = "C_Plain", faction = "Alliance", minLevel = 1, maxLevel = 60, steps = { { "note", "plain" } } })
    Q:RegisterGuide({ id = "C_Fork", faction = "Alliance", minLevel = 1, maxLevel = 60, next = "C_Plain",
      choices = { { id = "C_Plain" }, { id = "C_Class_02" } }, steps = { { "note", "fork" } } })
    Q.Progress:SetGuide("C_Fork")
    t.eq(stateOf(Q, "WARLOCK_TOME"), "available", "default successor: no turn-in of 1598")
    t.eq(Q.Progress:ChooseRoute("C_Fork", "C_Class_02"), true)
    t.eq(stateOf(Q, "WARLOCK_TOME"), "inroute", "the chosen successor turns 1598 in")
    noErrors(t)
  end,

  added_chain_already_in_the_route_is_not_inserted_twice = function(t)
    as("WARLOCK")
    local steps = {}
    for _, id in ipairs({ 1598, 1599 }) do
      steps[#steps + 1] = { action = "accept", questId = id }
      steps[#steps + 1] = { action = "complete", questId = id }
      steps[#steps + 1] = { action = "turnin", questId = id }
    end
    -- sauvegarde d'avant le tissage des quêtes de classe : la chaîne avait été ajoutée à la main
    local Q = load({ savedVariables = { QuestifyCharDB = {
      guideId = "C_Class_01",
      inserted = { { tag = "cq:WARLOCK_CHAIN", steps = steps } },
      classQuests = { added = { WARLOCK_CHAIN = true }, ignored = {}, seen = {} },
    } } })
    t.eq(#Q.char.inserted, 0, "the inserted copy is removed")
    t.eq(Q.char.classQuests.added.WARLOCK_CHAIN, nil)
    t.eq(stateOf(Q, "WARLOCK_CHAIN"), "inroute")
    for _, e in ipairs(Q.Progress:Entries()) do t.eq(e.source, "guide", e.key) end
    t.eq(Q.Progress:Current().key, G(1))
    noErrors(t)
  end,

  journal_shows_in_the_route_state = function(t)
    Ext.install()
    local Q = load()
    Ext.fakeClassQuests(Q, { { chain = Ext.warlockChain(), state = "inroute" } })
    local J = Q.UI.Journal
    J:ShowTab("class")
    local row = J.classRows[1]
    t.ok(row:IsShown())
    t.ok(plain(row.info:GetText()):find(Q.L.UI_CQ_INROUTE, 1, true), plain(row.info:GetText()))
    t.ok(not row.addButton:IsShown(), "no add button")
    t.ok(not row.trackButton:IsShown() and not row.ignoreButton:IsShown() and not row.unignoreButton:IsShown())
    t.eq(Q.L.UI_CQ_INROUTE, "In the route")
    noErrors(t)
  end,

  in_the_route_text_fr = function(t)
    Mock.locale = "frFR"
    local Q = load()
    t.eq(Q.L.UI_CQ_INROUTE, "Dans la route")
  end,

  route_choice_highlights_a_chain_in_the_route = function(t)
    as("WARLOCK")
    local Q = load({ data = { WARLOCK = {
      { key = "WARLOCK_TOME", title = "Tome", faction = "Alliance", level = 1, quests = { 1598 }, rewards = {} } } } })
    t.eq(stateOf(Q, "WARLOCK_TOME"), "inroute")
    Q:RegisterGuide({ id = "T_EL", title = "Elwynn Forest", faction = "Alliance", minLevel = 1, maxLevel = 10,
      steps = { { "goto", 1429, 40, 60 } } })
    local hl = Q.RouteChoice:Highlights(Q.Guides:Get("T_EL"))
    t.eq(#hl, 1)
    t.eq(hl[1].kind, "class"); t.eq(hl[1].key, "WARLOCK_TOME")
    noErrors(t)
  end,
}
