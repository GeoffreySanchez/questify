-- Tests du suivi sous la minimap (Q.UI.Tracker).
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

return {
  tracker_shows_current_step = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    t.ok(T.frame and T.frame == QuestifyTracker, "frame named QuestifyTracker")
    t.ok(T.frame:IsShown())
    t.ok(plain(T.currentText:GetText()):find("Dwarven Outfitters", 1, true), "current step text")
    t.ok(plain(T.currentText:GetText()):find("Sten Stoutarm", 1, true), "giver in text")
    t.eq(T.currentIcon:GetTexture(), Q.Format:ActionIcon("accept"))
    t.eq(T.title:GetText(), "Coldridge Valley")
    t.eq(T.levels:GetText(), "1-6")
    local lo, hi = T.bar:GetMinMaxValues()
    t.eq(lo, 0)
    t.ok(hi > 0, "progress total")
    t.eq(T.bar:GetValue(), 0)
    t.eq(T.barText:GetText(), "0/" .. hi)
    t.eq(#Mock.errors, 0)
  end,

  tracker_missing_questiedb_message = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    local T = Q.UI.Tracker
    t.ok(T.frame:IsShown(), "frame still shown")
    t.ok(T.message:IsShown(), "message shown")
    t.eq(T.message:GetText(), Q.L.NEED_QUESTIEDB)
    t.ok(not T.current:IsShown(), "no current step")
    t.ok(not T.title:IsShown(), "no header")
    t.ok(not T.bar:IsShown(), "no progress bar")
    t.eq(#Mock.errors, 0)
  end,

  tracker_default_anchor_minimap_without_objective_tracker = function(t)
    local Q = load()
    local f = Q.UI.Tracker.frame
    local p, rel, rp, x, y = f:GetPoint(1)
    t.eq(p, "TOPRIGHT"); t.ok(rel == MinimapCluster); t.eq(rp, "BOTTOMRIGHT"); t.eq(x, 0); t.eq(y, -10)
    t.ok(f:IsMovable(), "movable while unlocked")
  end,

  tracker_default_anchor_left_of_objective_tracker = function(t)
    ObjectiveTrackerFrame = CreateFrame("Frame", "ObjectiveTrackerFrame", UIParent)
    local Q = load()
    local p, rel, rp, x, y = Q.UI.Tracker.frame:GetPoint(1)
    t.eq(p, "TOPRIGHT"); t.ok(rel == ObjectiveTrackerFrame, "beside Blizzard's tracker, not over it")
    t.eq(rp, "TOPLEFT"); t.eq(x, -8); t.eq(y, 0)
  end,

  tracker_drag_saves_uiparent_point_and_scale_keeps_it = function(t)
    local Q = load()
    local f = Q.UI.Tracker.frame
    -- après un déplacement : coin haut gauche à (300, 500) en unités d'UIParent
    rawset(f, "GetLeft", function() return 300 end)
    rawset(f, "GetTop", function() return 500 end)
    f:GetScript("OnDragStop")(f)
    t.eq(Q.Settings:Get("tracker.point"), { "TOPLEFT", "BOTTOMLEFT", 300, 500 })
    local p, rel, rp, x, y = f:GetPoint(1)
    t.eq(p, "TOPLEFT"); t.ok(rel == UIParent); t.eq(rp, "BOTTOMLEFT"); t.eq(x, 300); t.eq(y, 500)
    -- nouvelle taille : décalages divisés par l'échelle, le coin reste au même endroit à l'écran
    Q.Settings:Set("tracker.scale", 1.25)
    t.eq(f:GetScale(), 1.25)
    local _, _, _, x2, y2 = f:GetPoint(1)
    t.near(x2, 240, 0.001); t.near(y2, 400, 0.001)
    -- après /reload
    local Q2 = Mock.reload()
    local p3, rel3, rp3, x3, y3 = Q2.UI.Tracker.frame:GetPoint(1)
    t.eq(p3, "TOPLEFT"); t.ok(rel3 == UIParent); t.eq(rp3, "BOTTOMLEFT")
    t.near(x3, 240, 0.001); t.near(y3, 400, 0.001)
    t.eq(Q2.UI.Tracker.frame:GetScale(), 1.25)
  end,

  tracker_locked_is_not_movable = function(t)
    local Q = load()
    Q.Settings:Set("tracker.locked", true)
    local f = Q.UI.Tracker.frame
    t.ok(not f:IsMovable(), "locked")
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 5, 5)
    f:GetScript("OnDragStop")(f)
    t.eq(Q.Settings:Get("tracker.point"), nil, "nothing saved while locked")
    Q.Settings:Set("tracker.locked", false)
    t.ok(f:IsMovable(), "unlocked again")
  end,

  tracker_next_steps_small_grey = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    local shown = 0
    for _, line in ipairs(T.nextLines) do if line.text:IsShown() then shown = shown + 1 end end
    t.eq(shown, 3, "settings.tracker.nextSteps = 3")
    -- étapes 2 et 3 (complete/turnin 179) ne sont pas encore dans le journal : passées
    t.ok(plain(T.nextLines[1].text:GetText()):find("Coldridge Valley Mail Delivery", 1, true), "next = accept 233")
    t.eq(T.nextLines[1].text._template, "GameFontDisableSmall", "small grey font")
    Q.Settings:Set("tracker.nextSteps", 1)
    shown = 0
    for _, line in ipairs(T.nextLines) do if line.text:IsShown() then shown = shown + 1 end end
    t.eq(shown, 1)
  end,

  tracker_clicks_skip_back_markdone = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    local first = Q.Progress:Current().key
    Mock.click(T.current, "RightButton")
    t.ok(Q.Progress:Current().key ~= first, "right-click skips")
    t.ok(Q.char.skipped[first], "skipped flag")
    Mock.player.shift = true
    Mock.click(T.current, "RightButton")
    Mock.player.shift = false
    t.eq(Q.Progress:Current().key, first, "shift+right-click goes back")
    -- clic gauche sur une étape de quête : rien
    Mock.click(T.current, "LeftButton")
    t.eq(Q.Progress:Current().key, first, "left-click on accept does nothing")
    -- clic gauche sur une étape goto : marquée faite
    Q:RegisterGuide({ id = "T_goto", faction = "Alliance", steps = {
      { "goto", 1426, 50, 50 }, { "note", "Read the sign" }, { "level", 10 } } })
    Q.Progress:SetGuide("T_goto")
    t.eq(Q.Progress:Current().key, "g:T_goto:1")
    Mock.click(T.current, "LeftButton")
    t.eq(Q.Progress:Current().key, "g:T_goto:2", "goto marked done")
    t.ok(plain(T.currentText:GetText()):find("Read the sign", 1, true))
    Mock.click(T.current, "LeftButton")
    t.eq(Q.Progress:Current().key, "g:T_goto:3", "note marked done")
    t.eq(#Mock.errors, 0)
  end,

  -- Bateau, vol, foyer, point de vol, lien du foyer : un clic gauche les valide aussi (quais
  -- estimés, trajet pris autrement que prévu), avec l'aide dans l'infobulle.
  tracker_left_click_validates_travel_steps = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    Q:RegisterGuide({ id = "T_travel", faction = "Alliance", steps = {
      { "boat", 1437, 4.6, 57.1 }, { "fly", 1432 }, { "hearth", 1426 }, { "fp", 1426, 70, 20 },
      { "sethearth", 1426, 30.4, 71.2 }, { "level", 10 } } })
    Q.Progress:SetGuide("T_travel")
    for i, action in ipairs({ "boat", "fly", "hearth", "fp", "sethearth" }) do
      local cur = Q.Progress:Current()
      t.eq(cur.key, "g:T_travel:" .. i)
      t.eq(cur.step.action, action)
      Mock.tooltip.lines = {}
      T.current:GetScript("OnEnter")(T.current)
      t.ok(Ext.tooltipHas(Q.L.UI_TRACKER_HINT_DONE), action .. ": hint in the tooltip")
      Mock.click(T.current, "LeftButton")
      t.eq(Q.char.manual[cur.key], true, action .. " marked done")
    end
    t.eq(Q.Progress:Current().key, "g:T_travel:6")
    t.eq(#Mock.errors, 0)
  end,

  tracker_distance_every_half_second = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    local d1 = T.distance:GetText()
    t.ok(d1 and d1:find("yd", 1, true), "distance shown: " .. tostring(d1))
    Mock.player.x = 39.9                -- ~ 492 yards plus loin
    Mock.advance(0.2)
    t.eq(T.distance:GetText(), d1, "not yet updated")
    Mock.advance(0.4)
    local d2 = T.distance:GetText()
    t.ok(d2 ~= d1, "updated after 0.5 s")
    local n1, n2 = tonumber(d1:match("(%d+) yd")), tonumber(d2:match("(%d+) yd"))
    t.ok(n1 and n2 and n2 > n1 + 100, "farther: " .. tostring(d1) .. " -> " .. tostring(d2))
    Mock.player.instance = true         -- position inconnue : pas de distance
    Mock.advance(0.5)
    t.eq(T.distance:GetText(), "")
  end,

  tracker_refreshes_on_progress = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    Mock.quests.log[179] = { objectives = { { text = "Tough Wolf Meat: 2/8", finished = false } } }
    Mock.fire("QUEST_ACCEPTED", 179)
    local txt = plain(T.currentText:GetText())
    t.ok(txt:find("Tough Wolf Meat: 2/8", 1, true), "complete step with objectives: " .. txt)
    t.eq(T.currentIcon:GetTexture(), Q.Format:ActionIcon("complete"))
    Mock.quests.log[179] = nil
    Mock.quests.completed[179] = true
    Mock.fire("QUEST_TURNED_IN", 179, 100, 0)
    t.ok(plain(T.currentText:GetText()):find("Coldridge Valley Mail Delivery", 1, true), "moved on")
    t.ok(T.bar:GetValue() >= 3, "progress counted")
  end,

  tracker_blocked_step_shows_reason = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    Q.Progress:JumpTo("g:A_DwarfGnome_01:15")   -- accept 3364, niveau 4 requis
    t.ok(plain(T.currentText:GetText()):find("Requires level 4", 1, true), plain(T.currentText:GetText()))
  end,

  tracker_class_alert_opens_popup = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    Ext.fakeClassQuests(Q, {})
    Q:Fire("CLASSQUESTS_CHANGED")
    t.ok(not T.alert:IsShown(), "no alert without available class quests")
    local chain = Ext.warlockChain()
    Ext.fakeClassQuests(Q, { { chain = chain, state = "available" } })
    Q:Fire("CLASSQUESTS_CHANGED")
    t.ok(T.alert:IsShown(), "alert shown")
    t.ok(plain(T.alertText:GetText()):find("The Stolen Tome", 1, true))
    t.ok(T.alertPulse:IsPlaying(), "pulsing glow")
    t.eq(T.alertPulse:GetLooping(), "BOUNCE")
    Mock.click(T.alert, "LeftButton")
    t.ok(QuestifyClassQuestPopup and QuestifyClassQuestPopup:IsShown(), "popup shown")
    t.eq(Q.UI.ClassQuestPopup.chain, chain)
    t.eq(#Mock.errors, 0)
  end,

  tracker_class_alert_accepts_bare_chains = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    local a, b = Ext.warlockChain(), Ext.warlockChain()
    b.key, b.title = "WARLOCK_X", "Other chain"
    Ext.fakeClassQuests(Q, { { chain = a, state = "available" }, { chain = b, state = "available" } }, true)
    Q:Fire("CLASSQUESTS_CHANGED")
    t.ok(T.alert:IsShown())
    t.eq(plain(T.alertText:GetText()), string.format(Q.L.UI_CLASS_ALERT_MANY, 2), "count shown")
    Mock.click(T.alert, "LeftButton")
    t.eq(Q.UI.ClassQuestPopup.chain, a, "first alert opened")
    t.eq(Q.UI.ClassQuestPopup.counter:GetText(), string.format(Q.L.UI_POPUP_COUNTER, 1, 2))
    -- fermée sans choisir : le clic suivant ouvre l'alerte suivante, puis on revient à la première
    Mock.click(T.alert, "LeftButton")
    t.eq(Q.UI.ClassQuestPopup.chain, b, "next unseen alert")
    t.eq(Q.UI.ClassQuestPopup.counter:GetText(), string.format(Q.L.UI_POPUP_COUNTER, 2, 2))
    Mock.click(T.alert, "LeftButton")
    t.eq(Q.UI.ClassQuestPopup.chain, a, "wraps around")
    -- la première est choisie : elle n'est plus en alerte, le clic ouvre l'autre
    Mock.click(Q.UI.ClassQuestPopup.ignoreButton, "LeftButton")
    t.eq(plain(T.alertText:GetText()), string.format(Q.L.UI_CLASS_ALERT_ONE, "The Stolen Tome"))
    Mock.click(T.alert, "LeftButton")
    t.eq(Q.UI.ClassQuestPopup.chain, b)
    t.ok(not Q.UI.ClassQuestPopup.counter:IsShown(), "no counter for a single alert")
    t.eq(#Mock.errors, 0)
  end,

  tracker_class_alert_says_late = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    Mock.player.level = 20
    Mock.fire("PLAYER_LEVEL_UP", 20)
    local a, b = Ext.warlockChain(), Ext.warlockChain()
    b.key, b.title, b.level, b.quests = "WARLOCK_X", "Other chain", 20, { 999999 }
    Ext.fakeClassQuests(Q, { { chain = a, state = "available" } })
    Q:Fire("CLASSQUESTS_CHANGED")
    t.eq(plain(T.alertText:GetText()), string.format(Q.L.UI_CLASS_ALERT_LATE_ONE, "The Stolen Tome"))
    Ext.fakeClassQuests(Q, { { chain = a, state = "available" }, { chain = b, state = "available" } })
    Q:Fire("CLASSQUESTS_CHANGED")
    t.eq(plain(T.alertText:GetText()), string.format(Q.L.UI_CLASS_ALERT_LATE_ONE, "The Stolen Tome"),
      "one late chain among others: its name")
    local a2 = Ext.warlockChain()
    a2.key, a2.level = "WARLOCK_Y", 5
    Ext.fakeClassQuests(Q, { { chain = a, state = "available" }, { chain = a2, state = "available" } })
    Q:Fire("CLASSQUESTS_CHANGED")
    t.eq(plain(T.alertText:GetText()), string.format(Q.L.UI_CLASS_ALERT_LATE_MANY, 2))
    -- aucune en retard : texte habituel
    Ext.fakeClassQuests(Q, { { chain = b, state = "available" } })
    Q:Fire("CLASSQUESTS_CHANGED")
    t.eq(plain(T.alertText:GetText()), string.format(Q.L.UI_CLASS_ALERT_ONE, "Other chain"))
    t.eq(#Mock.errors, 0)
  end,

  tracker_class_alert_uses_quest_name = function(t)
    local Q = load()
    local chain = Ext.warlockChain()
    chain.title, chain.quests = "English data title", { 1599 }
    Ext.fakeClassQuests(Q, { { chain = chain, state = "available" } })
    Q:Fire("CLASSQUESTS_CHANGED")
    t.eq(plain(Q.UI.Tracker.alertText:GetText()), string.format(Q.L.UI_CLASS_ALERT_ONE, "Beginnings"),
      "client quest name, not the generated English title")
    chain.quests = { 999999 }                       -- quête inconnue : titre des données
    Q:Fire("CLASSQUESTS_CHANGED")
    t.eq(plain(Q.UI.Tracker.alertText:GetText()), string.format(Q.L.UI_CLASS_ALERT_ONE, "English data title"))
  end,

  tracker_without_class_module = function(t)
    local Q = load()
    Q.ClassQuests = nil
    Q:Fire("CLASSQUESTS_CHANGED")
    t.ok(not Q.UI.Tracker.alert:IsShown())
    t.eq(#Mock.errors, 0)
  end,

  tracker_route_done_message = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    Q:RegisterGuide({ id = "T_end", faction = "Alliance", steps = { { "level", 1 } } })
    Q.Progress:SetGuide("T_end")
    t.eq(Q.Progress:Current(), nil)
    t.eq(T.currentText:GetText(), Q.L.UI_TRACKER_DONE)
    t.eq(T.distance:GetText(), "")
    t.eq(#Mock.errors, 0)
  end,

  tracker_french_strings = function(t)
    Mock.locale = "frFR"
    local Q = load()
    t.ok(plain(Q.UI.Tracker.currentText:GetText()):find("Prendre", 1, true), "french step text")
    t.eq(Q.L.UI_MOB_LEVEL, "Niveau %s")
  end,

  tracker_resize_grip_changes_width = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    local f = T.frame
    local cx = 500
    GetCursorPosition = function() return cx, 300 end
    t.eq(f:GetWidth(), 260)
    t.ok(T.grip:IsShown(), "grip while unlocked")
    T.grip:GetScript("OnMouseDown")(T.grip, "LeftButton")
    t.eq(Q.Settings:Get("tracker.point")[1], "TOPLEFT", "top-left corner fixed before resizing")
    cx = 580
    T.grip:GetScript("OnUpdate")(T.grip, 0.02)
    t.eq(f:GetWidth(), 340, "live width")
    t.eq(T.currentText:GetWidth(), 340 - 16 - 38 - 2, "text follows the width")
    cx = 2000
    T.grip:GetScript("OnUpdate")(T.grip, 0.02)
    t.eq(f:GetWidth(), 480, "max width")
    T.grip:GetScript("OnMouseUp")(T.grip, "LeftButton")
    t.eq(Q.Settings:Get("tracker.width"), 480, "saved")
    local Q2 = Mock.reload()
    t.eq(Q2.UI.Tracker.frame:GetWidth(), 480, "kept after /reload")
    Q2.Settings:Set("tracker.locked", true)
    t.ok(not Q2.UI.Tracker.grip:IsShown(), "no grip when locked")
    t.eq(#Mock.errors, 0)
  end,
}
