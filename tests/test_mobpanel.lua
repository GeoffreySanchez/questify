-- Tests de la liste des monstres d'objectif (Q.UI.MobPanel) : boutons sécurisés, combat, modèle 3D.
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
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
    local P = Q.UI.MobPanel
    local row = P.rows[1]
    t.ok(row, "row 1 exists")
    t.eq(row._template, "SecureActionButtonTemplate")
    t.eq(row:GetObjectType(), "Button")
    t.eq(row:GetAttribute("type"), "macro")
    local m = row:GetAttribute("macrotext")
    t.ok(m:find("/targetexact Ragged Young Wolf", 1, true), m)
    t.ok(m:find("/tm !8", 1, true), m)
    t.eq(m, "/cleartarget\n/targetexact Ragged Young Wolf\n/tm !8")
    t.eq(row._clicks, { "AnyUp", "AnyDown" })
    t.ok(row:IsShown() and P.frame:IsShown(), "visible")
    t.eq(plain(row.name:GetText()), "Ragged Young Wolf")
    t.ok(plain(row.level:GetText()):find("1", 1, true), "level range")
    t.ok(plain(row.objective:GetText()):find("Tough Wolf Meat: 3/8", 1, true), "objective text")
    t.ok(P.frame == QuestifyVanillaMobPanel)
    t.eq(#Mock.errors, 0)
  end,

  no_attribute_change_in_combat = function(t)
    local Q = load()
    acceptWolves()
    local P = Q.UI.MobPanel
    local before = P.rows[1]:GetAttribute("macrotext")
    Mock.player.combat = true
    switchToTroggs()
    t.eq(P.pending, true, "refresh queued")
    t.eq(P.rows[1]:GetAttribute("macrotext"), before, "row 1 unchanged in combat")
    t.ok(not P.rows[2] or not P.rows[2]:IsShown() or P.rows[2]:GetAttribute("macrotext") == nil,
      "no new row shown in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(P.pending, false)
    local m1 = P.rows[1]:GetAttribute("macrotext")
    t.ok(m1:find("/targetexact Rockjaw Trogg", 1, true), m1)
    t.ok(P.rows[2]:GetAttribute("macrotext"):find("/targetexact Burly Rockjaw Trogg", 1, true))
    t.eq(#Mock.errors, 0)
  end,

  secure_frames_untouched_in_combat = function(t)
    local Q = load()
    acceptWolves()
    local P = Q.UI.MobPanel
    local frames = { P.frame }
    for _, r in ipairs(P.rows) do frames[#frames + 1] = r end
    local calls = Ext.spyCombat(frames)
    Mock.player.combat = true
    switchToTroggs()                                     -- objectifs changés
    Mock.quests.log[170].objectives[1].text = "Rockjaw Trogg slain: 2/6"
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    P.rows[1]:GetScript("OnEnter")(P.rows[1])            -- survol : modèle et infobulle
    Mock.advance(0.3)
    P.rows[1]:GetScript("OnLeave")(P.rows[1])
    Q.Settings:Set("tracker.scale", 1.2)                 -- le suivi change de taille
    Q.Settings:Set("tracker.showMobs", false)            -- la liste devrait se cacher
    Q.UI.Tracker.moving = true                           -- déplacement du suivi
    Mock.advance(0.1)
    Q.UI.Tracker.moving = false
    t.eq(calls, {}, "no SetPoint/Show/Hide/SetSize/SetAttribute on secure frames in combat")
    t.ok(P.frame:IsShown(), "still shown until combat ends")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(not P.frame:IsShown(), "hidden after combat")
    t.eq(#Mock.errors, 0)
  end,

  combat_updates_progress_text_only = function(t)
    local Q = load()
    acceptWolves()
    local P = Q.UI.MobPanel
    Mock.player.combat = true
    Mock.quests.log[179].objectives[1].text = "Tough Wolf Meat: 5/8"
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.ok(plain(P.rows[1].objective:GetText()):find("5/8", 1, true), "progress text follows in combat")
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
    local shown = 0
    for _, r in ipairs(P.rows) do if r:IsShown() then shown = shown + 1 end end
    t.eq(shown, 6, "6 rows max")
    t.ok(P.rows[1]:GetAttribute("macrotext"):find("Mob 2", 1, true), "not-done rows first")
    for i = 1, 6 do
      t.ok(not P.rows[i]:GetAttribute("macrotext"):find("Mob 1\n", 1, true), "done row pushed out")
    end
  end,

  hidden_without_mobs_or_when_off = function(t)
    local Q = load()
    local P = Q.UI.MobPanel
    t.ok(not P.frame:IsShown(), "no objective mob: hidden")
    acceptWolves()
    t.ok(P.frame:IsShown())
    Q.Settings:Set("tracker.showMobs", false)
    t.ok(not P.frame:IsShown(), "setting off: hidden")
    Q.Settings:Set("tracker.showMobs", true)
    t.ok(P.frame:IsShown())
  end,

  anchored_to_screen_not_to_tracker = function(t)
    local Q = load()
    acceptWolves()
    local _, rel = Q.UI.MobPanel.frame:GetPoint(1)
    t.ok(rel == UIParent, "secure rows never make the tracker protected")
  end,

  model_on_hover_with_icon_fallback = function(t)
    local Q = load()
    acceptWolves()
    local P = Q.UI.MobPanel
    local row = P.rows[1]
    row:GetScript("OnEnter")(row)
    local model = QuestifyVanillaMobModel
    t.ok(model, "shared model exists")
    t.eq(model:GetObjectType(), "PlayerModel")
    t.eq({ model:GetSize() }, { 160, 160 })
    t.ok(model:IsVisible(), "model shown")
    t.eq(model:GetCreature(), 705)
    t.ok(not P.modelFallback:IsShown(), "no fallback yet")
    Mock.advance(0.3)
    t.ok(P.modelFallback:IsShown(), "icon fallback when the model stays empty")
    t.ok(Ext.tooltipHas("Ragged Young Wolf"), "tooltip with the name")
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
}
