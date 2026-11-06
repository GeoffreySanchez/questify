-- Tests du journal (onglets Route et Quêtes de classe, bouton Options) et de la fenêtre des quêtes
-- de classe. La fenêtre d'options a ses tests dans test_options.lua.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

local function load(opts)
  Ext.install()
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end   -- routes générées : contenu changeant
  return Mock.loadAddon(TOC, opts)
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

local function shownRows(rows)
  local n = 0
  for _, r in ipairs(rows) do if r:IsShown() then n = n + 1 end end
  return n
end

local function rowForKey(J, key)
  for _, r in ipairs(J.stepRows) do if r:IsShown() and r.entry and r.entry.key == key then return r end end
end

return {
  slash_toggles_journal = function(t)
    local Q = load()
    t.eq(SLASH_QUESTIFY1, "/questify")
    t.eq(SLASH_QUESTIFY2, "/qf")
    SlashCmdList.QUESTIFY("")
    local J = QuestifyJournal
    t.ok(J and J:IsShown(), "journal shown")
    SlashCmdList.QUESTIFY("")
    t.ok(not J:IsShown(), "journal hidden again")
    t.eq(#Mock.errors, 0)
  end,

  journal_frame_layout = function(t)
    local Q = load()
    Q.UI.Journal:Toggle()
    local f = QuestifyJournal
    t.eq(f._template, "ButtonFrameTemplate")
    t.eq({ f:GetSize() }, { 520, 560 })
    t.ok(f:IsMovable(), "movable")
    local special = false
    for _, n in ipairs(UISpecialFrames) do if n == "QuestifyJournal" then special = true end end
    t.ok(special, "closes with Escape (UISpecialFrames)")
    t.eq(Q.UI.Journal.tab, "route", "route tab by default")
    t.eq(#Q.UI.Journal.tabs, 2, "Route and Class quests: options have their own window")
    t.eq(Q.UI.Journal.tabs[2]:GetText(), Q.L.UI_TAB_CLASS)
    t.eq(Q.UI.Journal.panels.options, nil)
    Mock.click(Q.UI.Journal.tabs[2], "LeftButton")
    t.eq(Q.UI.Journal.tab, "class")
    t.ok(Q.UI.Journal.panels.class:IsShown())
    t.ok(not Q.UI.Journal.panels.route:IsShown())
    -- bouton « Options… » : la fenêtre d'options
    local b = Q.UI.Journal.optionsButton
    t.eq(b:GetText(), Q.L.OPT_JOURNAL_OPTIONS)
    Mock.click(b, "LeftButton")
    t.ok(QuestifyOptions and QuestifyOptions:IsShown(), "options window opened")
    -- l'ancien onglet ouvre la fenêtre aussi
    QuestifyOptions:Hide()
    Q.UI.Journal:ShowTab("options")
    t.ok(QuestifyOptions:IsShown())
    t.eq(Q.UI.Journal.tab, "class", "journal tab unchanged")
    t.eq(#Mock.errors, 0)
  end,

  route_tab_lists_faction_chapters = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "H_Test_01", title = "Horde chapter", faction = "Horde", steps = { { "level", 2 } } })
    Q.UI.Journal:ShowTab("route")
    local J = Q.UI.Journal
    local expected = 0
    for _, g in ipairs(Q.Guides:All()) do if g.faction == "Alliance" or g.faction == nil then expected = expected + 1 end end
    t.eq(shownRows(J.chapterRows), expected, "only the player's faction")
    local second
    for _, r in ipairs(J.chapterRows) do
      t.ok(not (r.guide and r.guide.id == "H_Test_01"), "horde chapter hidden")
      if r:IsShown() and r.guide.id == "A_DwarfGnome_02" then second = r end
    end
    t.ok(second, "chapter 2 listed")
    t.ok(plain(second.text:GetText()):find("Dun Morogh", 1, true))
    Mock.click(second, "LeftButton")
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02", "click follows the chapter")
    t.eq(shownRows(J.stepRows), #Q.Progress:Entries(), "step list follows")
    t.eq(#Mock.errors, 0)
  end,

  route_tab_state_icons_and_click = function(t)
    local Q = load()
    local J = Q.UI.Journal
    J:ShowTab("route")
    t.eq(shownRows(J.stepRows), #Q.Progress:Entries())
    local cur = rowForKey(J, "g:A_DwarfGnome_01:1")
    t.eq(cur.state:GetTexture(), J.STATE_ICONS.current, "current = arrow")
    local skipped = rowForKey(J, "g:A_DwarfGnome_01:2")   -- complete 179, pas dans le journal
    t.eq(skipped.state:GetTexture(), J.STATE_ICONS.skipped)
    local r, g, b = skipped.text:GetTextColor()
    t.ok(r < 0.7 and g < 0.7 and b < 0.7, "skipped = grey")
    local blocked = rowForKey(J, "g:A_DwarfGnome_01:9")    -- 3361, niveau 3 requis
    t.eq(blocked.state:GetTexture(), J.STATE_ICONS.blocked, "blocked = lock")
    t.ok(plain(blocked.text:GetText()):find("Requires level 3", 1, true), "reason shown")
    -- étape faite : coche (la liste suit PROGRESS_UPDATED)
    Mock.quests.log[179] = { objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
    Mock.fire("QUEST_ACCEPTED", 179)
    t.eq(rowForKey(J, "g:A_DwarfGnome_01:1").state:GetTexture(), J.STATE_ICONS.done, "done = check")
    t.eq(rowForKey(J, "g:A_DwarfGnome_01:2").state:GetTexture(), J.STATE_ICONS.current)
    -- clic : l'étape 13 devient courante, les étapes passées à la main après elle sont rouvertes
    Q.char.skipped["g:A_DwarfGnome_01:14"] = true
    Mock.click(rowForKey(J, "g:A_DwarfGnome_01:13"), "LeftButton")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:13")
    t.ok(Q.char.skipped["g:A_DwarfGnome_01:2"], "earlier undone entries skipped")
    t.eq(Q.char.skipped["g:A_DwarfGnome_01:1"], nil, "done entries untouched")
    t.eq(Q.char.skipped["g:A_DwarfGnome_01:14"], nil, "later ones unskipped")
    t.eq(rowForKey(J, "g:A_DwarfGnome_01:13").state:GetTexture(), J.STATE_ICONS.current, "list refreshed")
    t.eq(#Mock.errors, 0)
  end,

  class_tab_add_button_calls_add = function(t)
    local Q = load()
    local chain = Ext.warlockChain()
    local other = Ext.warlockChain()
    other.key, other.title = "WARLOCK_IGN", "Ignored chain"
    local done = Ext.warlockChain()
    done.key, done.title = "WARLOCK_DONE", "Done chain"
    Ext.fakeClassQuests(Q, {
      { chain = chain, state = "available" },
      { chain = other, state = "ignored" },
      { chain = done, state = "done" },
    })
    local J = Q.UI.Journal
    J:ShowTab("class")
    t.eq(shownRows(J.classRows), 3)
    local row = J.classRows[1]
    t.ok(plain(row.title:GetText()):find("The Stolen Tome", 1, true))
    t.ok(plain(row.info:GetText()):find(Q.L.UI_CQ_AVAILABLE, 1, true), "state shown")
    t.ok(row.addButton:IsShown() and row.ignoreButton:IsShown(), "available: add + ignore")
    t.eq(row.addButton:GetText(), Q.L.UI_BTN_ADD_ROUTE)
    Mock.click(row.addButton, "LeftButton")
    t.eq(Mock.countCalls("ClassQuests:Add"), 1)
    t.eq(Mock.lastCall("ClassQuests:Add").args[1], "WARLOCK_1598")
    -- après l'ajout la liste est relue : ligne « ajoutée » avec Ignorer seulement
    t.ok(plain(J.classRows[1].info:GetText()):find(Q.L.UI_CQ_ADDED, 1, true), "refreshed")
    t.ok(not J.classRows[1].addButton:IsShown())
    t.ok(J.classRows[1].ignoreButton:IsShown())
    -- chaîne ignorée : Ajouter directement, ou Réactiver
    local ign = J.classRows[3]   -- ignorées en dernier
    t.ok(ign.unignoreButton:IsShown() and ign.addButton:IsShown() and not ign.ignoreButton:IsShown())
    t.eq(ign.unignoreButton:GetText(), Q.L.UI_BTN_UNIGNORE)
    Mock.click(ign.unignoreButton, "LeftButton")
    t.eq(Mock.lastCall("ClassQuests:Unignore").args[1], "WARLOCK_IGN")
    Ext.fakeClassQuests(Q, {
      { chain = chain, state = "added" }, { chain = other, state = "ignored" }, { chain = done, state = "done" },
    })
    J:RefreshClass()
    Mock.click(J.classRows[3].addButton, "LeftButton")
    t.eq(Mock.lastCall("ClassQuests:Add").args[1], "WARLOCK_IGN", "ignored chain added directly")
    -- ajoutée : elle remonte avant les faites
    t.eq(J.classRows[2].chain.key, "WARLOCK_IGN")
    t.ok(plain(J.classRows[2].info:GetText()):find(Q.L.UI_CQ_ADDED, 1, true))
    -- chaîne faite : aucun bouton
    local d = J.classRows[3]
    t.ok(not d.addButton:IsShown() and not d.ignoreButton:IsShown() and not d.unignoreButton:IsShown())
    t.eq(#Mock.errors, 0)
  end,

  class_tab_late_chains_first_with_late_label = function(t)
    local Q = load()
    Mock.player.level = 20
    Mock.fire("PLAYER_LEVEL_UP", 20)
    local normal = Ext.warlockChain()
    normal.key, normal.title, normal.level = "WARLOCK_NEW", "Fresh chain", 20
    local late = Ext.warlockChain()
    late.key, late.title, late.level = "WARLOCK_OLD", "Old chain", 8
    local late2 = Ext.warlockChain()
    late2.key, late2.title, late2.level = "WARLOCK_OLD2", "Older chain", 4
    local ign = Ext.warlockChain()
    ign.key, ign.title, ign.level = "WARLOCK_IGN", "Ignored chain", 4
    local done = Ext.warlockChain()
    done.key, done.title = "WARLOCK_DONE", "Done chain"
    Ext.fakeClassQuests(Q, {
      { chain = done, state = "done" }, { chain = ign, state = "ignored" },
      { chain = normal, state = "available" }, { chain = late, state = "available" },
      { chain = late2, state = "available" },
    })
    local J = Q.UI.Journal
    J:ShowTab("class")
    local order = {}
    for i = 1, 5 do order[i] = J.classRows[i].chain.key end
    t.eq(order, { "WARLOCK_OLD", "WARLOCK_OLD2", "WARLOCK_NEW", "WARLOCK_DONE", "WARLOCK_IGN" },
      "late first, then available, done, ignored")
    t.ok(plain(J.classRows[1].info:GetText()):find(string.format(Q.L.UI_CQ_LATE, 8), 1, true), "late label")
    t.ok(J.classRows[1].info:GetText():find("|cffff", 1, true), "alert colour")
    t.ok(not plain(J.classRows[3].info:GetText()):find(string.format(Q.L.UI_CQ_LATE, 20), 1, true), "not late")
    t.ok(J.classRows[1].addButton:IsShown(), "late chain: add button")
    t.eq(J.classRows[1].addButton:GetText(), Q.L.UI_BTN_ADD_ROUTE)
    -- un clic : ajoutée, message de confirmation
    Mock.click(J.classRows[1].addButton, "LeftButton")
    t.ok(Mock.printed(string.format(Q.L.UI_CQ_ADDED_MSG, "The Stolen Tome")), "confirmation in chat")
    -- chaîne ajoutée : bouton Suivre
    local row
    for _, r in ipairs(J.classRows) do if r:IsShown() and r.chain.key == "WARLOCK_OLD" then row = r end end
    t.ok(row.trackButton:IsShown() and not row.addButton:IsShown(), "added: track button")
    t.eq(row.trackButton:GetText(), Q.L.UI_BTN_TRACK)
    t.eq(#Mock.errors, 0)
  end,

  class_tab_track_button_calls_track = function(t)
    local Q = load()
    Ext.fakeClassQuests(Q, { { chain = Ext.warlockChain(), state = "added" } })
    Q.ClassQuests.Track = function(_, key) Mock.record("ClassQuests:Track", key); return true end
    local J = Q.UI.Journal
    J:ShowTab("class")
    Mock.click(J.classRows[1].trackButton, "LeftButton")
    t.eq(Mock.lastCall("ClassQuests:Track").args[1], "WARLOCK_1598")
    t.eq(#Mock.errors, 0)
  end,

  class_tab_tooltips = function(t)
    local Q = load()
    Ext.fakeClassQuests(Q, { { chain = Ext.warlockChain(), state = "upcoming" } })
    local J = Q.UI.Journal
    J:ShowTab("class")
    local row = J.classRows[1]
    row:GetScript("OnEnter")(row)
    t.ok(Ext.tooltipHas("The Stolen Tome"), "quest names listed")
    t.ok(Ext.tooltipHas("Beginnings"), "second quest listed")
    local item = row.items[1]
    t.ok(item:IsShown(), "reward button")
    item:GetScript("OnEnter")(item)
    t.eq(Mock.lastCall("GameTooltip:SetItemByID").args[1], 6900)
    t.eq(#Mock.errors, 0)
  end,

  class_tab_without_module = function(t)
    local Q = load()
    Q.ClassQuests = nil
    Q.UI.Journal:ShowTab("class")
    t.eq(Q.UI.Journal.classEmpty:GetText(), Q.L.UI_CLASS_UNAVAILABLE)
    t.eq(#Mock.errors, 0)
  end,

  journal_without_questiedb = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    Q.UI.Journal:Toggle()
    t.ok(QuestifyJournal:IsShown())
    t.eq(Q.UI.Journal.routeMessage:GetText(), Q.L.NEED_QUESTIEDB)
    Ext.fakeClassQuests(Q, { { chain = Ext.warlockChain(), state = "available" } })
    Q.UI.Journal:ShowTab("class")
    t.eq(Q.UI.Journal.classEmpty:GetText(), Q.L.NEED_QUESTIEDB, "class tab explains the dependency")
    t.ok(not (Q.UI.Journal.classRows[1] and Q.UI.Journal.classRows[1]:IsShown()), "no chain rows")
    Q.UI.Options:Open()
    for _, s in ipairs(Q.OptionsSchema.SECTIONS) do Q.UI.Options:SelectSection(s.id) end
    t.eq(#Mock.errors, 0)
  end,

  journal_creation_plays_no_close_sound = function(t)
    local Q = load()
    Q.UI.Journal:Toggle()
    local opens, closes = 0, 0
    for _, c in ipairs(Mock.callsTo("PlaySound")) do
      if c.args[1] == "IG_CHARACTER_INFO_OPEN" then opens = opens + 1 end
      if c.args[1] == "IG_CHARACTER_INFO_CLOSE" then closes = closes + 1 end
    end
    t.eq(opens, 1, "open sound once")
    t.eq(closes, 0, "no close sound at creation")
    Q.UI.Journal:Toggle()
    closes = 0
    for _, c in ipairs(Mock.callsTo("PlaySound")) do
      if c.args[1] == "IG_CHARACTER_INFO_CLOSE" then closes = closes + 1 end
    end
    t.eq(closes, 1, "close sound when closed")
  end,

  class_titles_use_quest_names = function(t)
    local Q = load()
    local chain = Ext.warlockChain()
    chain.title = "English data title"
    Ext.fakeClassQuests(Q, { { chain = chain, state = "available" } })
    Q.UI.Journal:ShowTab("class")
    t.eq(Q.UI.Journal.classRows[1].title:GetText(), "The Stolen Tome", "journal row")
    Q.UI.ClassQuestPopup:Show(chain)
    t.eq(Q.UI.ClassQuestPopup.title:GetText(), "The Stolen Tome", "popup")
  end,
}
