-- Tests des monstres à tuer : lignes dans l'étape courante du suivi (Q.UI.Tracker) et boutons
-- sécurisés de ciblage posés par-dessus (Q.UI.MobPanel) : combat, position, modèle 3D.
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

-- Quête 179 dans le journal : le loup (705) lâche la viande demandée.
local function acceptWolves()
  Mock.quests.log[179] = { objectives = { { text = "Tough Wolf Meat: 3/8", finished = false,
    numFulfilled = 3, numRequired = 8 } } }
  Mock.fire("QUEST_ACCEPTED", 179)
end

-- Route courte : loups (179) puis trolls (170), pour changer de monstres sur l'étape courante.
local function loadTwoSteps()
  local Q = load()
  Q:RegisterGuide({ id = "T_two", faction = "Alliance", steps = { { "complete", 179 }, { "complete", 170 } } })
  Q.Progress:SetGuide("T_two")
  return Q
end

local function shownRows(P)
  local n = 0
  for _, r in ipairs(P.rows) do if r:IsShown() then n = n + 1 end end
  return n
end

local function shownMobLines(T)
  local n = 0
  for _, r in ipairs(T.mobRows) do if r.name:IsShown() then n = n + 1 end end
  return n
end

-- Quête 179 terminée et quête 170 (trolls) dans le journal.
local function switchToTroggs()
  Mock.quests.log[179] = { complete = true, objectives = { { text = "Tough Wolf Meat: 8/8", finished = true } } }
  Mock.quests.log[170] = { objectives = {
    { text = "Rockjaw Trogg slain: 0/6", finished = false },
    { text = "Burly Rockjaw Trogg slain: 0/6", finished = false },
  } }
  Mock.fire("QUEST_LOG_UPDATE")
  Mock.advance(0.3)
end

return {
  mobpanel_sets_macro = function(t)
    local Q = load()
    acceptWolves()
    local P, T = Q.UI.MobPanel, Q.UI.Tracker
    local row = P.rows[1]
    t.ok(row, "row 1 exists")
    t.eq(row._template, "SecureActionButtonTemplate")
    t.eq(row:GetObjectType(), "Button")
    t.eq(row:GetAttribute("type"), "macro")
    t.eq(row:GetAttribute("macrotext"), "/cleartarget\n/targetexact Ragged Young Wolf\n/tm !8")
    t.eq(row._clicks, { "AnyUp", "AnyDown" })
    t.ok(row:IsShown(), "visible")
    t.eq(shownRows(P), 1)
    -- affichage dans le suivi, sous l'objectif
    t.eq(shownMobLines(T), 1)
    t.eq(plain(T.mobRows[1].name:GetText()), "Ragged Young Wolf")
    t.ok(plain(T.mobRows[1].level:GetText()):find("1", 1, true), "level range")
    t.ok(plain(T.currentText:GetText()):find("Tough Wolf Meat: 3/8", 1, true), "objective right above")
    t.eq(QuestifyMobPanel, nil, "no separate panel any more")
    t.eq(#Mock.errors, 0)
  end,

  mobs_under_their_own_objective = function(t)
    local Q = loadTwoSteps()
    acceptWolves()
    switchToTroggs()
    local T = Q.UI.Tracker
    local first = plain(T.currentText:GetText())
    t.ok(first:find("Rockjaw Trogg slain: 0/6", 1, true), first)
    t.ok(not first:find("Burly", 1, true), "second objective after the first mob line")
    t.eq(plain(T.mobRows[1].name:GetText()), "Rockjaw Trogg")
    t.ok(T.textChunks[2]:IsShown())
    t.ok(plain(T.textChunks[2]:GetText()):find("Burly Rockjaw Trogg slain: 0/6", 1, true))
    t.eq(plain(T.mobRows[2].name:GetText()), "Burly Rockjaw Trogg")
    local P = Q.UI.MobPanel
    t.ok(P.rows[1]:GetAttribute("macrotext"):find("/targetexact Rockjaw Trogg\n", 1, true))
    t.ok(P.rows[2]:GetAttribute("macrotext"):find("/targetexact Burly Rockjaw Trogg", 1, true))
    t.eq(#Mock.errors, 0)
  end,

  only_current_step_mobs = function(t)
    local Q = load()
    acceptWolves()
    -- loups terminés : l'étape courante devient « Rendre », sans monstre à tuer
    Mock.quests.log[179] = { complete = true, objectives = { { text = "Tough Wolf Meat: 8/8", finished = true } } }
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.eq(shownMobLines(Q.UI.Tracker), 0)
    t.eq(shownRows(Q.UI.MobPanel), 0)
  end,

  button_placed_over_its_line = function(t)
    local Q = load()
    local f = Q.UI.Tracker.frame
    rawset(f, "GetLeft", function() return 300 end)
    rawset(f, "GetTop", function() return 500 end)
    acceptWolves()
    local row = Q.UI.MobPanel.rows[1]
    local p, rel, rp, x, y = row:GetPoint(1)
    t.eq(p, "TOPLEFT"); t.ok(rel == UIParent, "screen coordinates, never anchored to the tracker"); t.eq(rp, "BOTTOMLEFT")
    -- en-tête (44) + titre et objectif (12) ; colonne d'icône (8 + 38 + 2) + retrait (10) - 2
    t.eq(x, 356); t.eq(y, 444)
    t.eq({ row:GetSize() }, { 204 - 10 + 2, 16 })
    t.eq(row:GetParent(), UIParent)
    t.eq(row:GetFrameStrata(), "MEDIUM")
  end,

  no_attribute_change_in_combat = function(t)
    local Q = loadTwoSteps()
    acceptWolves()
    local P = Q.UI.MobPanel
    local before = P.rows[1]:GetAttribute("macrotext")
    Mock.player.combat = true
    switchToTroggs()
    t.eq(P.pending, true, "refresh queued")
    t.eq(P.rows[1]:GetAttribute("macrotext"), before, "row 1 unchanged in combat")
    t.ok(not P.rows[2] or not P.rows[2]:IsShown(), "no new row shown in combat")
    t.eq(plain(Q.UI.Tracker.mobRows[1].name:GetText()), "Rockjaw Trogg", "tracker text follows in combat")
    t.eq(P.rows[1].highlight:GetAlpha(), 0, "stale button: no highlight")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(P.pending, false)
    t.eq(P.rows[1].highlight:GetAlpha(), 1)
    local m1 = P.rows[1]:GetAttribute("macrotext")
    t.ok(m1:find("/targetexact Rockjaw Trogg", 1, true), m1)
    t.ok(P.rows[2]:GetAttribute("macrotext"):find("/targetexact Burly Rockjaw Trogg", 1, true))
    t.eq(#Mock.errors, 0)
  end,

  secure_frames_untouched_in_combat = function(t)
    local Q = loadTwoSteps()
    acceptWolves()
    local P = Q.UI.MobPanel
    local calls = Ext.spyCombat(P.rows)
    Mock.player.combat = true
    switchToTroggs()                                     -- objectifs changés
    Mock.quests.log[170].objectives[1].text = "Rockjaw Trogg slain: 2/6"
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    P.rows[1]:GetScript("OnEnter")(P.rows[1])            -- survol : modèle et infobulle
    Mock.advance(0.3)
    P.rows[1]:GetScript("OnLeave")(P.rows[1])
    Q.Settings:Set("tracker.scale", 1.2)                 -- le suivi change de taille
    Q.Settings:Set("tracker.showMobs", false)            -- les lignes devraient disparaître
    Q.UI.Tracker.moving = true                           -- déplacement du suivi
    Mock.advance(0.1)
    Q.UI.Tracker.moving = false
    t.eq(calls, {}, "no SetPoint/Show/Hide/SetSize/SetAttribute on secure frames in combat")
    t.ok(P.rows[1]:IsShown(), "still shown until combat ends")
    t.eq(shownMobLines(Q.UI.Tracker), 0, "tracker lines gone at once")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(shownRows(P), 0, "hidden after combat")
    t.eq(#Mock.errors, 0)
  end,

  combat_progress_keeps_buttons_valid = function(t)
    local Q = load()
    acceptWolves()
    local P = Q.UI.MobPanel
    Mock.player.combat = true
    Mock.quests.log[179].objectives[1].text = "Tough Wolf Meat: 5/8"
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.ok(plain(Q.UI.Tracker.currentText:GetText()):find("5/8", 1, true), "progress text follows in combat")
    t.eq(P.pending, false, "same line, same mob: nothing to rebuild")
    t.eq(P.rows[1]:GetAttribute("macrotext"), "/cleartarget\n/targetexact Ragged Young Wolf\n/tm !8")
  end,

  rows_not_done_first_and_capped = function(t)
    -- 8 monstres d'objectif dont un terminé : 6 lignes au plus, les objectifs restants d'abord
    local npcs, objectives = {}, {}
    for i = 1, 8 do
      local id = 90000 + i
      npcs[id] = { name = "Mob " .. i, minLevel = 2, maxLevel = 3, spawns = { [1] = { { 30, 70 } } } }
      objectives[i] = { id }
    end
    local Q = load({ qdb = {
      npcs = npcs,
      quests = { [99001] = { name = "Many Mobs", startedBy = { { 658 } }, finishedBy = { { 658 } },
        requiredLevel = 1, questLevel = 1, objectives = { objectives } } },
    } })
    Q:RegisterGuide({ id = "T_mobs", faction = "Alliance", steps = { { "complete", 99001 } } })
    Q.Progress:SetGuide("T_mobs")
    local objs = {}
    for i = 1, 8 do objs[i] = { text = "Mob " .. i .. " slain: 0/2", finished = i == 1 } end
    Mock.quests.log[99001] = { objectives = objs }
    Mock.fire("QUEST_ACCEPTED", 99001)
    local P = Q.UI.MobPanel
    t.eq(shownRows(P), 6, "6 rows max")
    t.eq(shownMobLines(Q.UI.Tracker), 6)
    t.ok(P.rows[1]:GetAttribute("macrotext"):find("Mob 2", 1, true), "not-done rows first")
    for i = 1, 6 do
      t.ok(not P.rows[i]:GetAttribute("macrotext"):find("Mob 1\n", 1, true), "done row pushed out")
    end
  end,

  done_objective_greyed_not_removed = function(t)
    local Q = loadTwoSteps()
    acceptWolves()
    switchToTroggs()
    Mock.quests.log[170].objectives[1] = { text = "Rockjaw Trogg slain: 6/6", finished = true }
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    local T = Q.UI.Tracker
    t.eq(shownMobLines(T), 2, "lines stay: no layout change mid-fight")
    -- couleurs du thème courant (UI/Themes.lua : teintes foncées sur parchemin)
    t.ok(T.mobRows[1].name:GetText():find(Q.Themes:Recolor("|cff808080"), 1, true), "done mob greyed")
    t.ok(T.mobRows[2].name:GetText():find(Q.Themes:Recolor("|cffff6060"), 1, true), "remaining mob in red")
    Q.Settings:Set("tracker.theme", "dark")
    t.ok(T.mobRows[1].name:GetText():find("|cff808080", 1, true), "dark theme: original grey")
    t.ok(T.mobRows[2].name:GetText():find("|cffff6060", 1, true), "dark theme: original red")
  end,

  hidden_when_off = function(t)
    local Q = load()
    local P = Q.UI.MobPanel
    t.eq(shownRows(P), 0, "no objective mob: nothing")
    acceptWolves()
    t.eq(shownRows(P), 1)
    Q.Settings:Set("tracker.showMobs", false)
    t.eq(shownRows(P), 0, "setting off: hidden")
    t.eq(shownMobLines(Q.UI.Tracker), 0)
    Q.Settings:Set("tracker.showMobs", true)
    t.eq(shownRows(P), 1)
  end,

  model_on_hover_with_icon_fallback = function(t)
    local Q = load()
    acceptWolves()
    local P = Q.UI.MobPanel
    local row = P.rows[1]
    row:GetScript("OnEnter")(row)
    local model = QuestifyMobModel
    t.ok(model, "shared model exists")
    t.eq(model:GetObjectType(), "PlayerModel")
    t.eq({ model:GetSize() }, { 160, 160 })
    t.ok(model:IsVisible(), "model shown")
    t.eq(model:GetCreature(), 705)
    t.ok(not P.modelFallback:IsShown(), "no fallback yet")
    Mock.advance(0.3)
    t.ok(P.modelFallback:IsShown(), "icon fallback when the model stays empty")
    t.ok(Ext.tooltipHas("Ragged Young Wolf"), "tooltip with the name")
    t.ok(Ext.tooltipHas("Tough Wolf Meat: 3/8"), "tooltip with the objective")
    row:GetScript("OnLeave")(row)
    t.ok(not model:IsVisible(), "hidden on leave")
    -- avec un modèle connu : pas d'icône de secours
    Mock.modelFileIDs[705] = 123456
    row:GetScript("OnEnter")(row)
    Mock.advance(0.3)
    t.ok(not P.modelFallback:IsShown(), "model found")
    t.ok(model:IsVisible())
    t.eq(#Mock.errors, 0)
  end,

  autotarget_off_by_default = function(t)
    local Q = load()
    acceptWolves()
    local b = QuestifyAutoTarget
    t.ok(b, "hidden button for the key binding")
    t.eq(b._template, "SecureActionButtonTemplate")
    t.eq(b:GetAttribute("type"), "macro")
    t.eq(b:GetAttribute("macrotext"), "", "does nothing while the option is off")
    t.ok(not b:IsShown())
  end,

  autotarget_macro_nearest_and_skull_out_of_combat = function(t)
    local Q = loadTwoSteps()
    acceptWolves()
    Q.Settings:Set("tracker.autoTarget", true)
    t.eq(QuestifyAutoTarget:GetAttribute("macrotext"),
      "/stopmacro [combat]\n/cleartarget\n/targetexact Ragged Young Wolf\n/tm !8")
    switchToTroggs()
    Mock.quests.log[170].objectives[1] = { text = "Rockjaw Trogg slain: 6/6", finished = true }
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.eq(QuestifyAutoTarget:GetAttribute("macrotext"),
      "/stopmacro [combat]\n/cleartarget\n/targetexact Burly Rockjaw Trogg\n"
      .. "/targetexact [noexists] Rockjaw Trogg\n/tm !8", "remaining objective first")
    Q.Settings:Set("tracker.autoTarget", false)
    t.eq(QuestifyAutoTarget:GetAttribute("macrotext"), "")
    t.eq(#Mock.errors, 0)
  end,

  autotarget_untouched_in_combat = function(t)
    local Q = loadTwoSteps()
    acceptWolves()
    Q.Settings:Set("tracker.autoTarget", true)
    local before = QuestifyAutoTarget:GetAttribute("macrotext")
    local calls = Ext.spyCombat({ QuestifyAutoTarget })
    Mock.player.combat = true
    switchToTroggs()
    Q.Settings:Set("tracker.autoTarget", false)
    t.eq(calls, {})
    t.eq(QuestifyAutoTarget:GetAttribute("macrotext"), before)
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(QuestifyAutoTarget:GetAttribute("macrotext"), "")
  end,

  autotarget_macro_length_capped = function(t)
    local Q = load()
    local mobs = {}
    for i = 1, 6 do mobs[i] = { name = string.rep("N", 50) .. i, done = false } end
    local m = Q.UI.MobPanel:BuildAutoMacro(mobs)
    t.ok(#m <= 255, #m)
    t.ok(m:find("/tm !8$"), "skull line kept")
    t.ok(m:find(string.rep("N", 50) .. "1", 1, true))
    t.ok(not m:find(string.rep("N", 50) .. "6", 1, true), "names past the limit left out")
    t.eq(Q.UI.MobPanel:BuildAutoMacro({}), "")
  end,

  autotarget_hint_without_key = function(t)
    local Q = load()
    Q.Settings:Set("tracker.autoTarget", true)
    t.eq(Mock.countPrinted(Q.L.UI_AUTOTARGET_NOKEY), 1)
    Q.Settings:Set("tracker.autoTarget", false)
    Q.Settings:Set("tracker.autoTarget", true)
    t.eq(Mock.countPrinted(Q.L.UI_AUTOTARGET_NOKEY), 1, "once per session")
  end,
}
