-- Tests des repères des étapes sur la carte du monde et la minicarte (Q.UI.MapPins), posés par
-- les vraies bibliothèques HereBeDragons chargées par le TOC.
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_mappins.lua")

local REF = "Questify_Vanilla_MapPins"

-- Chapitre A_DwarfGnome_01 de la fixture, joueur nain guerrier niveau 1 à Coldridge Valley.
local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end
  opts.beforeLogin = Ext.spy
  local Q = Mock.loadAddon(TOC, opts)
  Mock.advance(0.3)
  return Q
end

local function active(Q, where, order)
  local out = {}
  for _, p in ipairs(Q.UI.MapPins.active) do
    if (not where or p.where == where) and (not order or p.order == order) then out[#out + 1] = p end
  end
  return out
end

local function countPins(Q, where)
  local by = {}
  for _, p in ipairs(Q.UI.MapPins.active) do
    if p.where == where then by[p.order] = (by[p.order] or 0) + 1 end
  end
  return by
end

-- Quête 179 dans le journal : l'étape courante devient « Faire » (loups, 10 points d'apparition).
local function acceptWolfQuest(Q)
  Mock.quests.log[179] = { complete = false, objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
  Mock.fire("QUEST_ACCEPTED", 179)
  Mock.advance(0.3)
end

return {
  libs_load_without_error = function(t)
    local Q = load()
    t.ok(LibStub("HereBeDragons-2.0", true), "HereBeDragons-2.0")
    t.ok(LibStub("HereBeDragons-Pins-2.0", true), "HereBeDragons-Pins-2.0")
    t.ok(LibStub("CallbackHandler-1.0", true), "CallbackHandler-1.0")
    t.eq(HBD_PINS_WORLDMAP_SHOW_PARENT, 1)
    for _, f in ipairs(Mock.missingFiles) do
      t.ok(not f:find("Libs/", 1, true) and not f:find("MapPins", 1, true) and not f:find("StringsMap", 1, true),
        "missing file " .. f)
    end
    -- évènements de zone et minicarte : la bibliothèque tourne sans erreur
    Mock.fire("PLAYER_ENTERING_WORLD", true, false)
    Mock.fire("ZONE_CHANGED_NEW_AREA")
    Mock.advance(2)
    t.eq(Q.Settings:Get("mapPins"), true, "on by default")
    t.eq(#Mock.errors, 0)
  end,

  current_starter_gets_world_pin = function(t)
    local Q = load()
    local first = Mock.callsTo("HBDPins:AddWorldMapIconMap")[1]
    t.ok(first, "a world map pin")
    local ref, frame, mapId, x, y, flag = unpack(first.args)
    t.eq(ref, REF)
    t.eq(mapId, 1426)
    t.ok(x > 0 and x < 1 and y > 0 and y < 1, "0-1 coordinates")
    t.near(x, 0.2993, 0.0001); t.near(y, 0.712, 0.0001)
    t.eq(flag, HBD_PINS_WORLDMAP_SHOW_PARENT)
    -- « ! » jaune au donneur (Sten Stoutarm), numéro 1, plus grand que les suivants
    t.eq(frame.icon:GetTexture(), "Interface\\GossipFrame\\AvailableQuestIcon")
    t.eq(frame.num:GetText(), "1")
    t.eq(frame.pinData.order, 1)
    t.eq(frame.pinData.name, "Sten Stoutarm")
    local nextFrame = active(Q, "world", 3)[1].frame
    t.ok(frame:GetWidth() > nextFrame:GetWidth(), "current step slightly larger")
    t.eq(#Mock.errors, 0)
  end,

  next_steps_get_numbered_pins = function(t)
    local Q = load()
    local by = countPins(Q, "world")
    -- 1 accept 179, 2 accept 233, 3 accept 170 ((accept 1599 réservée aux démonistes, complete et
    -- turnin de quêtes hors du journal : sautées), 4 accept 3361 (niveau 3), 5 goto, 6 accept 3364
    for order = 1, 6 do t.eq(by[order], 1, "one pin for step " .. order) end
    t.eq(by[7], nil, "current step + 5 next only")
    for _, p in ipairs(active(Q, "world")) do
      t.eq(p.frame.num:GetText(), tostring(p.order))
    end
    t.eq(active(Q, "world", 5)[1].style, "point")
    t.eq(active(Q, "world", 3)[1].frame.pinData.name, "Balir Frosthammer")
    -- minicarte : l'étape courante seulement
    local mini = countPins(Q, "minimap")
    t.eq(mini[1], 1)
    for order = 2, 6 do t.eq(mini[order], nil) end
    -- quête acceptée : « Faire » devient l'étape courante, puis « ? » au destinataire
    acceptWolfQuest(Q)
    t.eq(active(Q, "world", 1)[1].style, "objective")
    local turnin = active(Q, "world", 2)[1]
    t.eq(turnin.style, "turnin")
    t.eq(turnin.frame.icon:GetTexture(), "Interface\\GossipFrame\\ActiveQuestIcon", "turn-in ?")
    t.eq(turnin.frame.num:GetText(), "2")
    t.eq(#Mock.errors, 0)
  end,

  complete_step_at_most_eight_points_nearest_first = function(t)
    local Q = load()
    acceptWolfQuest(Q)
    t.eq(Q.Progress:Current().step.action, "complete")
    local pts = active(Q, "world", 1)
    t.eq(#pts, 8, "10 wolf spawns, 8 shown")
    local last = -1
    for _, p in ipairs(pts) do
      local d = Q.Maps:DistanceFromPlayer(p.mapId, p.x, p.y)
      t.ok(d >= last, "nearest first")
      last = d
      t.ok(p.x >= 0 and p.x <= 100, "0-100 inside the addon")
    end
    -- minicarte : les 8 points de l'étape courante, seul le plus proche reste au bord
    local minis = Mock.callsTo("HBDPins:AddMinimapIconMap")
    local fresh = {}
    for i = #minis - 7, #minis do fresh[#fresh + 1] = minis[i] end
    t.eq(#active(Q, "minimap", 1), 8)
    t.eq(fresh[1].args[7], true, "nearest floats on the edge")
    for i = 2, 8 do t.eq(fresh[i].args[7], false) end
    for _, c in ipairs(fresh) do
      t.ok(c.args[4] >= 0 and c.args[4] <= 1 and c.args[5] >= 0 and c.args[5] <= 1, "0-1 coordinates")
    end
    t.eq(#Mock.errors, 0)
  end,

  refresh_removes_previous_pins = function(t)
    local Q = load()
    local w1, m1 = Ext.registered(REF)
    t.ok(w1 > 0 and m1 == 1)
    Mock.calls = {}
    acceptWolfQuest(Q)
    t.ok(Mock.countCalls("HBDPins:RemoveAllWorldMapIcons") >= 1)
    t.ok(Mock.countCalls("HBDPins:RemoveAllMinimapIcons") >= 1)
    local w2, m2 = Ext.registered(REF)
    t.eq(w2, #active(Q, "world"), "nothing left over")
    t.eq(m2, 8)
  end,

  option_off_clears_everything = function(t)
    local Q = load()
    t.ok(#Q.UI.MapPins.active > 0)
    Q.Settings:Set("mapPins", false)
    local w, m = Ext.registered(REF)
    t.eq(w, 0); t.eq(m, 0)
    t.eq(#Q.UI.MapPins.active, 0)
    for _, pool in pairs(Q.UI.MapPins.pools) do
      for _, f in ipairs(pool.frames) do t.ok(not f:IsShown(), "frame hidden") end
    end
    Mock.calls = {}
    Mock.fire("QUEST_ACCEPTED", 179)
    Mock.advance(1)
    t.eq(Mock.countCalls("HBDPins:AddWorldMapIconMap"), 0, "stays off")
    t.eq(Mock.countCalls("HBDPins:AddMinimapIconMap"), 0)
    Q.Settings:Set("mapPins", true)
    Mock.advance(0.3)
    t.ok(#Q.UI.MapPins.active > 0, "back on")
    t.eq(#Mock.errors, 0)
  end,

  questiedb_missing_is_silent = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    Mock.fire("QUEST_ACCEPTED", 179)
    Mock.advance(1)
    t.eq(Mock.countCalls("HBDPins:AddWorldMapIconMap"), 0)
    t.eq(Mock.countCalls("HBDPins:AddMinimapIconMap"), 0)
    t.eq(#Q.UI.MapPins.active, 0)
    t.eq(#Mock.errors, 0)
  end,

  libs_missing_is_silent = function(t)
    local Q = Mock.loadAddon(TOC, {
      extraFiles = { GUIDES }, skipGuides = true,
      beforeLogin = function() LibStub.libs["HereBeDragons-Pins-2.0"] = nil end,
    })
    Mock.advance(0.3)
    Q.Settings:Set("mapPins", false)
    Q.Settings:Set("mapPins", true)
    Mock.advance(0.3)
    t.eq(#Q.UI.MapPins.active, 0)
    t.eq(#Mock.errors, 0)
  end,

  clicking_a_pin_sets_navigation_target = function(t)
    local Q = load()
    local seen
    local orig = Q.Nav.SetManualTarget
    Q.Nav.SetManualTarget = function(self, mapId, x, y, title)
      seen = { mapId, x, y, title }
      return orig(self, mapId, x, y, title)
    end
    local p = active(Q, "world", 1)[1]   -- prendre 179 chez Sten Stoutarm
    Mock.click(p.frame, "LeftButton")
    t.ok(seen, "Q.Nav:SetManualTarget called")
    t.eq(Q.Nav:Status().manual, true)
    t.eq(seen[1], 1426); t.near(seen[2], 29.93, 0.001); t.near(seen[3], 71.2, 0.001)
    t.ok(seen[4]:find("Dwarven Outfitters", 1, true), "step title")
    t.eq(Q.Nav:Status().target.mapId, 1426)
    -- la minicarte aussi
    seen = nil
    Mock.click(active(Q, "minimap", 1)[1].frame, "LeftButton")
    t.ok(seen and seen[1] == 1426)
    t.eq(#Mock.errors, 0)
  end,

  -- Le repère cliqué reste la cible : la minuterie des étapes « complete » (3 s) et le mode zone
  -- ne le remplacent pas ; l'étape suivante, ou un autre clic, reprend la main.
  pin_click_wins_over_ticker_until_next_step = function(t)
    local Q = load()
    acceptWolfQuest(Q)
    t.eq(Q.Progress:Current().step.action, "complete")
    local turnin = active(Q, "world", 2)[1]                   -- « ? » de 179 chez Sten
    Mock.click(turnin.frame, "LeftButton")
    local st = Q.Nav:Status()
    t.eq(st.manual, true)
    t.near(st.target.x, turnin.x, 0.001); t.near(st.target.y, turnin.y, 0.001)
    -- le joueur bouge : la minuterie aurait visé un autre loup
    Mock.player.x, Mock.player.y = 22.6, 79.5
    Mock.advance(10)
    Q:Fire("ZONEMODE_CHANGED")
    st = Q.Nav:Status()
    t.near(st.target.x, turnin.x, 0.001, "ticker and zone mode keep the clicked pin")
    t.near(st.target.y, turnin.y, 0.001)
    -- un autre repère remplace le premier
    local wolf = active(Q, "world", 1)[3]
    Mock.click(wolf.frame, "LeftButton")
    t.near(Q.Nav:Status().target.x, wolf.x, 0.001, "new manual target")
    -- quête complète : nouvelle étape, la cible suit la route de nouveau
    Mock.quests.log[179].complete = true
    Mock.quests.log[179].objectives[1].finished = true
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.eq(Q.Progress:Current().step.action, "turnin")
    st = Q.Nav:Status()
    t.eq(st.manual, false, "step changed: manual target dropped")
    local tg = Q.Targets:ForEntry(Q.Progress:Current())
    t.near(st.target.x, tg.x, 0.001); t.near(st.target.y, tg.y, 0.001)
    t.eq(#Mock.errors, 0)
  end,

  tooltip_shows_step_text_and_name = function(t)
    local Q = load()
    acceptWolfQuest(Q)
    local lines = Ext.captureTooltip()
    local f = active(Q, "world", 1)[1].frame   -- un loup de l'étape courante
    f:GetScript("OnEnter")(f)
    local all = table.concat(lines, "\n")
    t.eq(lines[1], "Ragged Young Wolf")
    t.eq(lines[2], Q.L.MAP_PIN_CURRENT)
    t.ok(all:find("Dwarven Outfitters", 1, true), "step text")
    t.ok(all:find(Q.L.MAP_PIN_CLICK, 1, true), "click hint")
    f = active(Q, "world", 2)[1].frame         -- rendre 179 à Sten Stoutarm
    f:GetScript("OnEnter")(f)
    t.eq(lines[1], "Sten Stoutarm")
    t.eq(lines[2], Q.L.MAP_PIN_UPCOMING:format(2))
    f:GetScript("OnLeave")(f)
    t.eq(#Mock.errors, 0)
  end,

  world_map_shows_pins_on_the_zone = function(t)
    local Q = load()
    WorldMapFrame:Show()
    WorldMapFrame:SetMapID(1426)
    local acquired = Mock.callsTo("WorldMapFrame:AcquirePin")
    t.eq(#acquired, #active(Q, "world"), "every pin drawn on Dun Morogh")
    local found
    for _, c in ipairs(acquired) do
      local icon, x, y = c.args[2], c.args[3], c.args[4]
      t.ok(x >= 0 and x <= 1 and y >= 0 and y <= 1)
      if icon == active(Q, "world", 1)[1].frame then
        found = true
        t.near(x, 0.2993, 0.001); t.near(y, 0.712, 0.001)
        t.ok(icon:IsShown(), "icon shown on the map")
      end
    end
    t.ok(found, "starter pin on the map")
    -- autre zone : rien
    Mock.calls = {}
    WorldMapFrame:SetMapID(1429)
    t.eq(Mock.countCalls("WorldMapFrame:AcquirePin"), 0)
    t.eq(#Mock.errors, 0)
  end,

  no_redraw_in_combat = function(t)
    local Q = load()
    Mock.player.combat = true
    Mock.calls = {}
    acceptWolfQuest(Q)
    t.eq(Mock.countCalls("HBDPins:AddWorldMapIconMap"), 0, "waits for the end of combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    Mock.advance(0.3)
    t.ok(Mock.countCalls("HBDPins:AddWorldMapIconMap") > 0, "drawn after combat")
    t.eq(Q.Progress:Current().step.action, "complete")
    t.eq(#active(Q, "minimap", 1), 8)
    t.eq(#Mock.errors, 0)
  end,

  goto_step_uses_its_own_icon = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "T_pts", faction = "Alliance", minLevel = 1, maxLevel = 60, steps = {
      { "goto", 1426, 46.7, 53.7 }, { "fp", 1455, 55.5, 47.7 }, { "sethearth", 1426, 47.4, 52.5 },
      { "boat", 1437, 4.6, 57.1 }, { "hearth", 1426 }, { "note", "x" } } })
    Q.Progress:SetGuide("T_pts")
    Mock.advance(0.3)
    local by = countPins(Q, "world")
    t.eq(by[1], 1); t.eq(by[2], 1); t.eq(by[3], 1); t.eq(by[4], 1)
    t.eq(by[5], nil, "hearth and note: no position")
    local goto1 = active(Q, "world", 1)[1]
    t.eq(goto1.frame.icon:GetTexture(), Q.Format:ActionIcon("goto"))
    t.near(goto1.x, 46.7, 0.001)
    t.eq(active(Q, "world", 2)[1].mapId, 1455)
    t.eq(#Mock.errors, 0)
  end,

  journal_has_the_option = function(t)
    local Q = load()
    local J = Q.UI.Journal
    J:ShowTab("options")
    local cb = J.checks.mapPins
    t.ok(cb, "checkbox")
    t.eq(cb:GetChecked(), true)
    cb:SetChecked(false)
    Mock.click(cb, "LeftButton")
    t.eq(Q.Settings:Get("mapPins"), false)
    t.eq(#Q.UI.MapPins.active, 0)
  end,
}
