-- Tests de la navigation (Q.Nav) : fournisseurs, repli, déduplication, combat.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

-- Charge l'addon ; `settings` est appliqué avant la connexion, donc avant la première cible.
local function load(settings, opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  opts.beforeLogin = function(Q)
    for path, value in pairs(settings or {}) do Q.Settings:Set(path, value) end
  end
  return Mock.loadAddon(TOC, opts)
end

local function useGuide(Q, id, steps)
  Q:RegisterGuide({ id = id, faction = "Alliance", minLevel = 1, maxLevel = 60, steps = steps })
  Q.Progress:SetGuide(id)
end

local function accept179()
  Mock.quests.log[179] = { complete = false, objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
  Mock.fire("QUEST_ACCEPTED", 179)
end

-- Aucune erreur venue de notre fichier (les erreurs des autres flux ne nous concernent pas).
local function noNavErrors(t)
  for _, e in ipairs(Mock.errors) do
    t.ok(not tostring(e):find("Navigation.lua", 1, true), "Navigation error: " .. tostring(e))
  end
end

return {
  native_by_default = function(t)
    local Q = load()
    local calls = Mock.callsTo("C_Map.SetUserWaypoint")
    t.eq(#calls, 1, "one native waypoint at login")
    local point = calls[1].args[1]
    t.eq(point.uiMapID, 1426)
    t.near(point.position.x, 0.2993, 0.001)
    t.near(point.position.y, 0.712, 0.001)
    t.eq(Mock.lastCall("C_SuperTrack.SetSuperTrackedUserWaypoint").args[1], true)
    t.eq(Mock.countCalls("TomTom:AddWaypoint"), 0)
    noNavErrors(t)
  end,

  tomtom_replaces_previous = function(t)
    Mock.addons.TomTom = true
    local Q = load({ ["nav.display"] = "tomtom" })
    t.eq(Mock.countCalls("TomTom:AddWaypoint"), 1, "first step")
    t.eq(Mock.countCalls("TomTom:RemoveWaypoint"), 0)
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 0, "no native marker")
    local first = Mock.lastCall("TomTom:AddWaypoint").args
    t.eq(first[1], 1426); t.near(first[2], 0.2993, 0.001); t.near(first[3], 0.712, 0.001)
    t.eq(first[4].crazy, true); t.eq(first[4].persistent, false)
    t.ok(first[4].title:find("Dwarven Outfitters", 1, true), "title")
    accept179()   -- l'étape courante devient « complete 179 » : autre cible
    t.eq(Mock.countCalls("TomTom:AddWaypoint"), 2)
    local removed = Mock.callsTo("TomTom:RemoveWaypoint")
    t.eq(#removed, 1)
    t.eq(removed[1].args[1].uid, 1, "the previous uid is removed")
    noNavErrors(t)
  end,

  waypointui_uses_0_100 = function(t)
    Mock.addons.WaypointUI = true
    local Q = load({ ["nav.display"] = "waypointui" })
    local call = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation")
    t.ok(call, "WaypointUI called")
    local arg = call.args[1]
    t.eq(arg.x, 29.93); t.eq(arg.y, 71.2); t.eq(arg.mapID, 1426)
    t.ok(arg.name:find("Dwarven Outfitters", 1, true), "name")
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 0)
  end,

  -- Repère du jeu avec WaypointUI chargé : posé par WaypointUI, qui affiche le titre de l'étape
  -- au lieu de « Repère cartographique ».
  native_with_waypointui_names_the_pin = function(t)
    Mock.addons.WaypointUI = true
    local Q = load()
    local call = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation")
    t.ok(call, "WaypointUI called")
    local arg = call.args[1]
    t.eq(arg.mapID, 1426); t.eq(arg.x, 29.93); t.eq(arg.y, 71.2)
    t.ok(arg.name:find("Dwarven Outfitters", 1, true), "step title as name")
    t.eq(arg.suppressAudio, true, "no sound on every target update")
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 0, "WaypointUI sets the game pin itself")
    t.eq(select(2, Q.Nav:Active()), "native")
    accept179()   -- autre étape, autre titre
    t.ok(Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation").args[1].name ~= arg.name, "renamed")
    Q.Nav:Clear()
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.ClearUserNavigation"), 1)
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1)
    noNavErrors(t)
  end,

  native_with_waypointui_refused_map = function(t)
    Mock.addons.WaypointUI = true
    local Q = load()
    Q.Nav:SetTarget(99999, 10, 10, "Nowhere")   -- carte sans repère possible : WaypointUI renvoie nil
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 0)
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.ClearUserNavigation"), 1, "old named pin removed")
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1, "no stale marker left")
    noNavErrors(t)
  end,

  missing_provider_falls_back_native = function(t)
    local Q = load({ ["nav.display"] = "tomtom" })
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 1)
    t.eq(Mock.countCalls("TomTom:AddWaypoint"), 0)
    local routing, display = Q.Nav:Active()
    t.eq(routing, nil); t.eq(display, "native")
    -- WaypointUI absent : même repli
    Mock.reset()
    local Q2 = load({ ["nav.display"] = "waypointui" })
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 1)
    t.eq(select(2, Q2.Nav:Active()), "native")
  end,

  shortestpath_retries_after_combat = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.navigateResult = false
    local Q = load({ ["nav.routing"] = true })
    local first = Mock.callsTo("ShortestPathForever.API.Navigate")
    t.eq(#first, 1, "refused in combat")
    local a = first[1].args
    t.eq(a[1], "Questify"); t.eq(a[2], 1426)
    t.near(a[3], 0.2993, 0.0001); t.near(a[4], 0.712, 0.0001)
    t.ok(a[5]:find("Dwarven Outfitters", 1, true), "title"); t.eq(a[6], "quest")
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 0, "ShortestPath only")
    Mock.navigateResult = true
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(Mock.countCalls("ShortestPathForever.API.Navigate"), 2, "retried once")
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(Mock.countCalls("ShortestPathForever.API.Navigate"), 2, "nothing left to retry")
    noNavErrors(t)
  end,

  shortestpath_retry_is_only_once = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.navigateResult = false
    local Q = load({ ["nav.routing"] = true })
    Mock.fire("PLAYER_REGEN_ENABLED")
    Mock.fire("PLAYER_REGEN_ENABLED")
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(Mock.countCalls("ShortestPathForever.API.Navigate"), 2, "one retry, no more")
  end,

  shortestpath_does_nothing_else = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.addons.TomTom = true
    local Q = load({ ["nav.routing"] = true, ["nav.display"] = "tomtom" })
    t.eq(Mock.countCalls("ShortestPathForever.API.Navigate"), 1)
    t.eq(Mock.countCalls("TomTom:AddWaypoint"), 0, "ShortestPath handles the display")
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 0)
    local routing, display = Q.Nav:Active()
    t.eq(routing, "shortestpath"); t.eq(display, "tomtom")
  end,

  -- Calcul ShortestPath + WaypointUI : une navigation WaypointUI nommée est lancée d'abord, pour que
  -- ShortestPath lui confie ses virages (avec le nom) au lieu de poser des repères sans nom.
  shortestpath_seeds_a_named_waypointui_navigation = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    local Q = load({ ["nav.routing"] = true, ["nav.display"] = "waypointui" })
    local seed = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation")
    t.ok(seed, "WaypointUI navigation started")
    t.ok(seed.args[1].name:find("Dwarven Outfitters", 1, true), "named after the step")
    t.eq(seed.args[1].suppressAudio, true)
    t.eq(seed.args[1].mapID, 1426); t.eq(seed.args[1].x, 29.93); t.eq(seed.args[1].y, 71.2)
    local nav = Mock.lastCall("ShortestPathForever.API.Navigate")
    t.ok(nav, "ShortestPath still computes the route")
    local pos = {}
    for i, c in ipairs(Mock.calls) do pos[c] = i end
    t.ok(pos[seed] < pos[nav], "seeded before the route starts")
    Q.Nav:Clear()
    t.eq(Mock.countCalls("ShortestPathForever.API.Cancel"), 1)
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.ClearUserNavigation"), 1)
    noNavErrors(t)

    -- affichage « Repère du jeu » : même chose ; TomTom : rien chez WaypointUI
    Mock.reset()
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    load({ ["nav.routing"] = true })
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation"), 1)
    Mock.reset()
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    Mock.addons.TomTom = true
    load({ ["nav.routing"] = true, ["nav.display"] = "tomtom" })
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation"), 0)
  end,

  -- ShortestPath confie ses virages à WaypointUI en coordonnées 0-1, que l'API de WaypointUI lit en 0-100 :
  -- le virage tombait au coin nord-ouest de la carte (« Trajet vers … 2129 yds » pour un PNJ à 65 yd).
  -- Avec les deux addons, NewUserNavigation est enveloppée : 0-1 converti, 0-100 inchangé.
  waypointui_input_scaled_for_shortestpath_turns = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    local Q = load({ ["nav.routing"] = true })
    local nav = WaypointUIAPI.Navigation
    -- le virage tel que ShortestPath le transmet (C_Map, 0-1)
    local res = nav.NewUserNavigation({ name = "Trajet vers Rejold", mapID = 1426, x = 0.3019, y = 0.4573 })
    local call = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation").args[1]
    t.near(call.x, 30.19, 0.0001); t.near(call.y, 45.73, 0.0001)
    t.eq(call.name, "Trajet vers Rejold"); t.eq(call.mapID, 1426)
    t.ok(res, "WaypointUI's return value passed through")
    -- un appel en 0-100 (le nôtre, ou un autre addon) passe tel quel
    nav.NewUserNavigation({ name = "Camp", mapID = 1426, x = 22.6, y = 71.4 })
    call = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation").args[1]
    t.eq(call.x, 22.6); t.eq(call.y, 71.4)
    -- enveloppée une seule fois, même après d'autres cibles
    local wrapped = nav.NewUserNavigation
    Q.Nav:SetTarget(1426, 22.6, 71.4, "Camp")
    t.eq(nav.NewUserNavigation, wrapped, "not wrapped twice")
    -- la navigation nommée de Questify reste en 0-100
    t.eq(Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation").args[1].x, 22.6)
    noNavErrors(t)
  end,

  -- Les virages de ShortestPath passent en silence (WaypointUI sonnait à chaque virage), et un virage
  -- identique au précédent, que WaypointUI suit encore, n'est pas reposé.
  shortestpath_turns_are_silent_and_not_repeated = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    load({ ["nav.routing"] = true })
    local nav = WaypointUIAPI.Navigation
    local current
    nav.IsUserNavigationTracked = function() return current ~= nil end
    nav.GetUserNavigation = function() return current end
    local function turn(x, y)
      return nav.NewUserNavigation({ name = "Trajet vers Rejold", mapID = 1426, x = x, y = y })
    end
    local before = Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation")
    current = turn(0.3019, 0.4573)
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation"), before + 1)
    t.eq(Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation").args[1].suppressAudio, true, "silent")
    local same = turn(0.3019, 0.4573)
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation"), before + 1, "same turn not re-placed")
    t.eq(same, current, "current navigation returned")
    current = turn(0.3050, 0.4600)
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation"), before + 2, "next turn placed")
    current = nil                                -- WaypointUI ne suit plus rien : le même virage repasse
    turn(0.3050, 0.4600)
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation"), before + 3)
    noNavErrors(t)
  end,

  -- WaypointUI suit déjà une navigation (un virage, ou le repère du jeu qu'il adopte) : à chaque nouvelle
  -- cible, Questify ne repose pas la sienne avant le calcul (le repère sautait cible -> virage).
  shortestpath_does_not_reseed_a_tracking_waypointui = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    load({ ["nav.routing"] = true })
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation"), 1, "first target: seeded")
    WaypointUIAPI.Navigation.IsUserNavigationTracked = function() return true end
    local navs = Mock.countCalls("ShortestPathForever.API.Navigate")
    accept179()                                   -- nouvelle cible
    t.eq(Mock.countCalls("ShortestPathForever.API.Navigate"), navs + 1, "routed to the new target")
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.NewUserNavigation"), 1, "not re-seeded")
    noNavErrors(t)
  end,

  -- WaypointUI seul (sans ShortestPath) : son API n'est pas touchée.
  waypointui_untouched_without_shortestpath = function(t)
    Mock.addons.WaypointUI = true
    load()
    WaypointUIAPI.Navigation.NewUserNavigation({ name = "Corner", mapID = 1426, x = 0.5, y = 0.5 })
    local call = Mock.lastCall("WaypointUIAPI.Navigation.NewUserNavigation").args[1]
    t.eq(call.x, 0.5); t.eq(call.y, 0.5)
  end,

  routing_without_shortestpath_uses_display = function(t)
    local Q = load({ ["nav.routing"] = true })
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 1)
    t.eq((Q.Nav:Active()), nil)
  end,

  dedupe_same_target = function(t)
    local Q = load()
    local before = Mock.countCalls("C_Map.SetUserWaypoint")
    Q.Nav:SetTarget(1426, 22.6, 71.4, "Camp")
    Q.Nav:SetTarget(1426, 22.6, 71.4, "Camp")
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before + 1, "same target once")
    Q.Nav:SetTarget(1426, 22.61, 71.4, "Camp")   -- même dixième
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before + 1, "rounded to 0.1")
    Q.Nav:SetTarget(1426, 22.8, 71.4, "Camp")
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before + 2, "moved by 0.2")
    Q.Nav:SetTarget(1426, 22.8, 71.4, "Other title")
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before + 3, "new title")
    Q.Nav:SetTarget(1432, 22.8, 71.4, "Other title")
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before + 4, "new map")
  end,

  clear_clears_the_provider_in_use = function(t)
    local Q = load()
    Q.Nav:Clear()
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1)
    Q.Nav:Clear()
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1, "nothing left to clear")

    Mock.reset()
    Mock.addons.TomTom = true
    local Q2 = load({ ["nav.display"] = "tomtom" })
    Q2.Nav:Clear()
    t.eq(Mock.countCalls("TomTom:RemoveWaypoint"), 1)

    Mock.reset()
    Mock.addons.WaypointUI = true
    local Q3 = load({ ["nav.display"] = "waypointui" })
    Q3.Nav:Clear()
    t.eq(Mock.countCalls("WaypointUIAPI.Navigation.ClearUserNavigation"), 1)

    Mock.reset()
    Mock.addons.ShortestPathForever = true
    local Q4 = load({ ["nav.routing"] = true })
    Q4.Nav:Clear()
    local cancel = Mock.lastCall("ShortestPathForever.API.Cancel")
    t.ok(cancel and cancel.args[1] == "Questify", "Cancel(owner)")
  end,

  clears_when_there_is_no_current_step = function(t)
    local Q = load()
    -- guide vide : plus d'étape courante
    useGuide(Q, "empty", { { "level", 1 } })
    t.eq(Q.Progress:Current(), nil)
    t.ok(Mock.countCalls("C_Map.ClearUserWaypoint") >= 1, "cleared")
    local sets = Mock.countCalls("C_Map.SetUserWaypoint")
    Q.Nav:Refresh()
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), sets)
  end,

  step_without_target_clears = function(t)
    local Q = load()
    useGuide(Q, "t_note", { { "note", "Read this" }, { "accept", 179 } })
    t.eq(Q.Progress:Current().step.action, "note")
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1, "a note has no target")
  end,

  settings_change_switches_provider = function(t)
    Mock.addons.TomTom = true
    local Q = load()
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 1)
    Q.Settings:Set("nav.display", "tomtom")
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1, "old provider cleared")
    t.eq(Mock.countCalls("TomTom:AddWaypoint"), 1, "target re-applied")
    Q.Settings:Set("nav.display", "native")
    t.eq(Mock.countCalls("TomTom:RemoveWaypoint"), 1)
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 2)
    Q.Settings:Set("tracker.locked", true)   -- réglage étranger : rien ne bouge
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 2)
    noNavErrors(t)
  end,

  settings_change_enables_routing = function(t)
    Mock.addons.ShortestPathForever = true
    local Q = load()
    t.eq(Mock.countCalls("ShortestPathForever.API.Navigate"), 0)
    Q.Settings:Set("nav.routing", true)
    t.eq(Mock.countCalls("ShortestPathForever.API.Navigate"), 1)
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1, "native marker removed")
    Q.Settings:Set("nav.routing", false)
    t.eq(Mock.countCalls("ShortestPathForever.API.Cancel"), 1)
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), 2)
  end,

  detect_lists_installed_providers = function(t)
    local Q = load()
    t.eq(Q.Nav:Detect(), { shortestpath = false, waypointui = false, tomtom = false, native = true })
    Mock.reset()
    Mock.addons.TomTom = true
    Mock.addons.ShortestPathForever = true
    local Q2 = load()
    t.eq(Q2.Nav:Detect(), { shortestpath = true, waypointui = false, tomtom = true, native = true })
    t.eq(Q2.Nav:ProviderLabel("native"), "Built-in waypoint")
  end,

  step_target_follows_the_current_step = function(t)
    local Q = load()
    accept179()
    local call = Mock.lastCall("C_Map.SetUserWaypoint").args[1]
    -- cible du « complete 179 » : un loup, pas Sten Stoutarm
    t.ok(math.abs(call.position.x - 0.2993) > 0.001 or math.abs(call.position.y - 0.712) > 0.001, "moved to a wolf")
    local title = Q.Targets:ForEntry(Q.Progress:Current()).title
    t.ok(title and title ~= "", "has a title")
  end,

  complete_target_is_recomputed_every_3s = function(t)
    local Q = load()
    accept179()
    local before = Mock.countCalls("C_Map.SetUserWaypoint")
    Mock.advance(6)
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before, "same nearest wolf: deduplicated")
    -- le joueur traverse la vallée : le loup le plus proche change
    Mock.player.x, Mock.player.y = 22.6, 79.5
    Mock.advance(2)
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before, "not yet")
    Mock.advance(1)
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before + 1, "recomputed after 3 s")
    t.near(Mock.lastCall("C_Map.SetUserWaypoint").args[1].position.x, 0.2257, 0.001)
    noNavErrors(t)
  end,

  spawn_under_the_player_skipped = function(t)
    local Q = load()
    accept179()
    Mock.player.x, Mock.player.y = 22.58, 78.22   -- sur un point d'apparition de loup (22.57, 78.23)
    Mock.advance(3)
    local x = Mock.lastCall("C_Map.SetUserWaypoint").args[1].position.x
    t.ok(math.abs(x - 0.2257) > 0.001, "next wolf, not the one under the player")
    noNavErrors(t)
  end,

  site_step_follows_nearest_mob_once_inside = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "T_site", faction = "Alliance", steps = { { "complete", 179, at = { 1426, 30.0, 72.0 } } } })
    Mock.quests.log[179] = { objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
    Q.Progress:SetGuide("T_site")
    Mock.player.x, Mock.player.y = 45.0, 50.0      -- loin de la zone : centre de la zone
    Mock.advance(3)
    local tg = Q.Targets:ForEntry(Q.Progress:Current())
    t.eq(tg.kind, "area"); t.near(tg.x, 30.0, 0.001)
    Mock.player.x, Mock.player.y = 30.1, 72.1      -- dans la zone : le loup le plus proche
    tg = Q.Targets:ForEntry(Q.Progress:Current())
    t.eq(tg.kind, "npc"); t.eq(tg.id, 705)
    noNavErrors(t)
  end,

  no_recompute_for_other_steps = function(t)
    local Q = load()
    local before = Mock.countCalls("C_Map.SetUserWaypoint")
    Mock.player.x, Mock.player.y = 26.0, 74.0
    Mock.advance(30)
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before, "accept steps are not tracked")
    -- et le minuteur s'arrête quand on quitte une étape « complete »
    accept179()
    Mock.quests.completed[179] = true
    Mock.quests.log[179] = nil
    Mock.fire("QUEST_TURNED_IN", 179)
    local after = Mock.countCalls("C_Map.SetUserWaypoint")
    Mock.player.x, Mock.player.y = 22.6, 78.0
    Mock.advance(30)
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), after)
  end,

  native_skips_maps_without_waypoints = function(t)
    local Q = load()
    local before = Mock.countCalls("C_Map.SetUserWaypoint")
    Q.Nav:SetTarget(99999, 10, 10, "Nowhere")   -- carte inconnue : pas de marqueur possible
    t.eq(Mock.countCalls("C_Map.SetUserWaypoint"), before)
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1, "no stale marker left")
  end,

  invalid_target_clears = function(t)
    local Q = load()
    Q.Nav:SetTarget(nil, 10, 10, "x")
    t.eq(Mock.countCalls("C_Map.ClearUserWaypoint"), 1)
    noNavErrors(t)
  end,
}
