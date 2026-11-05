-- Tests du moteur de progression (Q.Progress, Q.Player).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end   -- fixtures seules, pas les guides livrés
  return Mock.loadAddon(TOC, opts)
end

-- Enregistre un petit guide de test et le sélectionne.
local function useGuide(Q, id, steps)
  Q:RegisterGuide({ id = id, faction = "Alliance", minLevel = 1, maxLevel = 60, steps = steps })
  Q.Progress:SetGuide(id)
  return Q.Progress:Entries()
end

local function entry(Q, key)
  for _, e in ipairs(Q.Progress:Entries()) do if e.key == key then return e end end
end

local function accept179()
  Mock.quests.log[179] = { complete = false, objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
  Mock.fire("QUEST_ACCEPTED", 179)
end

return {
  player_context = function(t)
    local Q = load()
    t.eq(Q.Player.faction, "Alliance"); t.eq(Q.Player.raceKey, "Dwarf"); t.eq(Q.Player.raceBit, 4)
    t.eq(Q.Player.classFile, "WARRIOR"); t.eq(Q.Player.classBit, 1); t.eq(Q.Player.level, 1)
    Mock.player.level = 2
    Mock.fire("PLAYER_LEVEL_UP", 2)
    t.eq(Q.Player.level, 2)
  end,

  player_context_ignores_secret_values = function(t)
    UnitLevel = function() return Mock.strictSecret(5) end
    UnitFactionGroup = function() return Mock.strictSecret("Alliance") end
    local Q = load()
    t.eq(Q.Player.level, 1, "secret level ignored")
    t.eq(Q.Player.faction, nil, "secret faction ignored")
    t.eq(Q.Player.raceKey, "Dwarf")
    Mock.fire("PLAYER_LEVEL_UP", Mock.strictSecret(2))
    t.eq(Q.Player.level, 1, "secret event argument ignored")
    t.eq(#Mock.errors, 0)
  end,

  secret_map_and_unit_do_not_complete_steps = function(t)
    local Q = load()
    local list = useGuide(Q, "T_SecretMap", { { "hearth", 1432 }, { "note", "x" } })
    C_Map.GetBestMapForUnit = function() return Mock.strictSecret(1432) end
    Mock.fire("ZONE_CHANGED_NEW_AREA")
    t.eq(Q.Progress:State(list[1]), "active", "secret map ignored")
    Mock.fire("UNIT_SPELLCAST_SUCCEEDED", Mock.strictSecret("player"), "Cast-1", 8690)
    Mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", Mock.strictSecret(8690))
    t.eq(Q.Progress:State(list[1]), "active", "secret unit or spell ignored")
    t.eq(#Mock.errors, 0)
  end,

  auto_selects_guide_on_login = function(t)
    local Q = load()
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_01")
    t.eq(Q.char.guideId, "A_DwarfGnome_01")
    Mock.reset()
    Mock.player.level = 7
    Q = load()
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02")
  end,

  saved_guide_is_kept = function(t)
    local Q = load({ savedVariables = { QuestifyCharDB = { guideId = "A_DwarfGnome_02" } } })
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02")
  end,

  entries_shape = function(t)
    local Q = load()
    local list = Q.Progress:Entries()
    t.eq(#list, 19)
    t.eq(list[1].key, "g:A_DwarfGnome_01:1"); t.eq(list[1].index, 1); t.eq(list[1].source, "guide")
    t.eq(list[1].step.action, "accept"); t.eq(list[1].step.questId, 179)
    t.ok(Q.Progress:Entries() == list, "cached list")
  end,

  accept_then_complete_then_turnin = function(t)
    local Q = load()
    local list = Q.Progress:Entries()
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:1")
    t.eq(Q.Progress:State(list[2]), "skipped", "complete is skipped while not in the log")
    accept179()
    t.eq(Q.Progress:State(list[1]), "done")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:2", "advances past accept 179")
    Mock.quests.log[179].complete = true
    Mock.quests.log[179].objectives[1].finished = true
    Mock.fire("QUEST_LOG_UPDATE")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:2", "log updates are throttled")
    Mock.advance(0.3)
    t.eq(Q.Progress:State(list[2]), "done", "complete step done")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:3")
    Mock.quests.completed[179] = true
    Mock.quests.log[179] = nil
    Mock.fire("QUEST_TURNED_IN", 179, 100, 0)
    t.eq(Q.Progress:State(list[3]), "done", "turnin done")
    t.eq(Q.Progress:State(list[1]), "done", "accept still done after turn-in")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:4", "next is accept 233")
    t.eq(next(Q.char.manual), nil, "game-state done is not stored")
    t.eq(next(Q.char.skipped), nil)
  end,

  turned_in_cache_covers_server_delay = function(t)
    local Q = load()
    accept179()
    -- QUEST_TURNED_IN arrive avant que IsQuestFlaggedCompleted soit vrai
    Mock.quests.log[179] = nil
    Mock.fire("QUEST_TURNED_IN", 179, 100, 0)
    t.ok(Q.Progress:IsTurnedIn(179))
    t.eq(Q.Progress:State(Q.Progress:Entries()[3]), "done")
  end,

  abandoned_quest_skips_followups = function(t)
    local Q = load()
    local list = Q.Progress:Entries()
    accept179()
    t.eq(Q.Progress:State(list[1]), "done")
    t.eq(Q.Progress:State(list[2]), "active")
    Mock.quests.log[179] = nil
    Mock.fire("QUEST_REMOVED", 179)
    t.eq(Q.Progress:State(list[2]), "skipped")
    t.eq(Q.Progress:State(list[3]), "skipped")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:1", "back to accept")
  end,

  character_mid_route = function(t)
    Mock.quests.completed[179] = true
    Mock.quests.completed[170] = true
    local Q = load()
    local list = Q.Progress:Entries()
    t.eq(Q.Progress:State(list[1]), "done"); t.eq(Q.Progress:State(list[3]), "done")
    t.eq(Q.Progress:State(list[5]), "done", "accept 170 done because turned in")
    t.eq(Q.Progress:State(list[7]), "done"); t.eq(Q.Progress:State(list[8]), "done")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:4")
  end,

  class_filter_skipped = function(t)
    local Q = load()
    local e = Q.Progress:Entries()[6]
    t.eq(e.step.questId, 1599)
    local s, r = Q.Progress:State(e)
    t.eq(s, "skipped"); t.eq(r, "class")
    Mock.reset()
    Mock.player.classFile = "WARLOCK"
    Q = load()
    t.eq(Q.Progress:State(Q.Progress:Entries()[6]), "active")
  end,

  race_filter_and_ineligible_skipped = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Race", { { "accept", 179, race = { "Human" } }, { "accept", 6387 }, { "note", "x" } })
    local s, r = Q.Progress:State(list[1])
    t.eq(s, "skipped"); t.eq(r, "race")
    Mock.reset()
    Mock.player.raceId = 1   -- Humain : 6387 est réservée aux Nains et Gnomes
    Q = load()
    list = useGuide(Q, "T_Race", { { "accept", 6387 }, { "note", "x" } })
    s, r = Q.Progress:State(list[1])
    t.eq(s, "skipped"); t.eq(r, "ineligible")
  end,

  level_blocked_is_current = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Level", { { "accept", 3364 }, { "note", "after" } })
    local s, r = Q.Progress:State(list[1])
    t.eq(s, "blocked"); t.eq(r, "level 4")
    t.eq(Q.Progress:Current(), list[1])
    Mock.player.level = 4
    Mock.fire("PLAYER_LEVEL_UP", 4)
    t.eq(Q.Progress:State(list[1]), "active")
  end,

  unknown_quest_is_active_not_error = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Unknown", { { "accept", 999999 }, { "complete", 999999 }, { "turnin", 999999 } })
    t.eq(Q.Progress:State(list[1]), "active")
    t.eq(Q.Progress:Current(), list[1])
    t.eq(#Mock.errors, 0)
    Q.Progress:Skip(list[1].key)
    t.eq(Q.Progress:State(list[1]), "skipped", "the player can skip it")
  end,

  prereq_skipped_skips_dependents = function(t)
    local Q = load()
    local list = Q.Progress:Entries()
    Q.Progress:Skip(list[1].key)
    local s, r = Q.Progress:State(list[4])
    t.eq(s, "skipped", "233 needs 179, which was skipped"); t.eq(r, "prereq")
    t.eq(Q.Progress:State(list[5]), "skipped", "170 too")
    t.eq(Q.char.skipped[list[1].key], true, "player skip is stored")
  end,

  prereq_pending_keeps_active = function(t)
    local Q = load()
    local list = Q.Progress:Entries()
    t.eq(Q.Progress:State(list[4]), "active", "233 waits for 179, still planned")
  end,

  optional_skipped_when_dungeon_quests_off = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Opt", { { "accept", 179, optional = true, dungeon = "Gnomeregan" }, { "note", "x" } })
    t.eq(Q.Progress:State(list[1]), "active")
    Q.Settings:Set("dungeonQuests", false)
    local s, r = Q.Progress:State(list[1])
    t.eq(s, "skipped"); t.eq(r, "optional")
    t.eq(Q.Progress:Current(), list[2])
  end,

  inserted_first = function(t)
    Mock.player.classFile = "WARLOCK"
    local Q = load()
    Q.Progress:InsertSteps("cq:1599", { { "accept", 1599 } })
    t.eq(Q.Progress:Current().key, "i:cq:1599:1")
    local e = Q.Progress:Entries()[1]
    t.eq(e.source, "inserted"); t.eq(e.tag, "cq:1599"); t.eq(e.index, 1)
    t.eq(Q.char.inserted[1].tag, "cq:1599")
    Q.Progress:RemoveInserted("cq:1599")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_01:1")
    t.eq(#Q.char.inserted, 0)
  end,

  inserted_steps_survive_reload = function(t)
    Mock.player.classFile = "WARLOCK"
    local Q = load()
    Q.Progress:InsertSteps("cq:1599", { { "accept", 1599 }, { "dance" }, { "turnin", 1599 } })
    t.eq(#Q.Progress:Entries(), 21, "invalid inserted step dropped")
    local Q2 = Mock.reload()
    t.eq(Q2.Progress:Current().key, "i:cq:1599:1")
    t.eq(Q2.Progress:Entries()[2].key, "i:cq:1599:2")
  end,

  step_changed_fires_once_per_change = function(t)
    local Q = load()
    local n, last = 0, nil
    Q:On("STEP_CHANGED", function(e) n = n + 1; last = e end)
    accept179()
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.eq(n, 1)
    t.eq(last.key, "g:A_DwarfGnome_01:2")
  end,

  progress_updated_on_recompute = function(t)
    local Q = load()
    local n = 0
    Q:On("PROGRESS_UPDATED", function() n = n + 1 end)
    for _ = 1, 5 do Mock.fire("QUEST_LOG_UPDATE") end
    Mock.advance(0.3)
    t.eq(n, 1, "QUEST_LOG_UPDATE throttled")
    Mock.fire("QUEST_ACCEPTED", 12345)
    t.eq(n, 2)
  end,

  manual_skip_and_back = function(t)
    local Q = load()
    local cur = Q.Progress:Current()
    Q.Progress:Skip(cur.key)
    t.ok(Q.Progress:Current().key ~= cur.key, "skip advances")
    Q.Progress:Back()
    t.eq(Q.Progress:Current().key, cur.key, "back returns to it")
    t.eq(Q.Progress:State(cur), "active")
    t.eq(Q.char.skipped[cur.key], nil)
  end,

  mark_done_and_back = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Notes", { { "note", "a" }, { "note", "b" } })
    t.eq(Q.Progress:Current(), list[1], "note is manual only")
    Q.Progress:MarkDone(list[1].key)
    t.eq(Q.Progress:State(list[1]), "done")
    t.eq(Q.Progress:Current(), list[2])
    t.eq(Q.char.manual[list[1].key], true)
    Q.Progress:Back()
    t.eq(Q.Progress:Current(), list[1])
  end,

  chapter_rollover = function(t)
    local Q = load()
    local changed
    Q:On("GUIDE_CHANGED", function(g) changed = g and g.id end)
    local keys = {}
    for _, e in ipairs(Q.Progress:Entries()) do keys[#keys + 1] = e.key end
    for _, k in ipairs(keys) do Q.Progress:MarkDone(k) end
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02")
    t.eq(changed, "A_DwarfGnome_02")
    t.eq(Q.Progress:Current().key, "g:A_DwarfGnome_02:1")
  end,

  -- Un clic droit de trop sur la dernière étape finit le chapitre et bascule au suivant. Rechoisi dans
  -- le journal (SetGuide(id, true)), un chapitre fini reste courant : le joueur y rouvre l'étape passée
  -- (/qf back, clic sur l'étape) ; la bascule reprend quand il est de nouveau fini. Avant, le journal le
  -- renvoyait aussitôt au chapitre suivant. Sans `true` (choix automatique), la bascule enchaîne.
  finished_chapter_chosen_again_stays = function(t)
    local Q = load()
    local keys = {}
    for _, e in ipairs(Q.Progress:Entries()) do
      if e.source == "guide" then keys[#keys + 1] = e.key end
    end
    for _, k in ipairs(keys) do Q.Progress:Skip(k) end
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02", "rolled over")
    Q.Progress:SetGuide("A_DwarfGnome_01", true)
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_01", "stays on the chosen chapter")
    t.eq(Q.Progress:Current(), nil)
    t.eq(Mock.countPrinted(Q.L.ROUTE_END), 0, "not the end of the route")
    local reopened = Q.Progress:Back()
    t.eq(reopened and reopened.key, keys[#keys], "last skipped step reopened")
    t.eq(Q.Progress:Current().key, keys[#keys])
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_01")
    Q.Progress:Skip(keys[#keys])
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02", "finished again: normal rollover")

    -- clic sur une étape du chapitre rechoisi (journal) : elle redevient l'étape courante
    Q.Progress:SetGuide("A_DwarfGnome_01", true)
    t.ok(Q.Progress:JumpTo(keys[#keys]))
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_01")
    t.eq(Q.Progress:Current().key, keys[#keys])

    -- choix automatique (connexion, /qf reset) : un chapitre fini enchaîne comme avant
    for _, k in ipairs(keys) do Q.Progress:Skip(k) end
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02")
    Q.Progress:SetGuide("A_DwarfGnome_01")
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02", "automatic choice rolls over")
  end,

  route_end_message = function(t)
    local Q = load({ savedVariables = { QuestifyCharDB = { guideId = "A_DwarfGnome_02" } } })
    local keys = {}
    for _, e in ipairs(Q.Progress:Entries()) do keys[#keys + 1] = e.key end
    for _, k in ipairs(keys) do Q.Progress:MarkDone(k) end
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02", "no next chapter")
    t.eq(Q.Progress:Current(), nil)
    t.eq(Mock.countPrinted(Q.L.ROUTE_END), 1, "printed once")
    Mock.fire("QUEST_ACCEPTED", 1)
    t.eq(Mock.countPrinted(Q.L.ROUTE_END), 1, "still once")
  end,

  goto_done_within_15_yards = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Goto", {
      { "goto", 1426, 29.95, 71.2 },   -- 2,5 yards du joueur
      { "goto", 1426, 40, 71.2 },      -- loin
      { "note", "end" },
    })
    t.eq(Q.Progress:State(list[1]), "done")
    t.eq(Q.Progress:Current(), list[2])
    Mock.advance(1.1)
    t.eq(Q.Progress:Current(), list[2], "still far")
    Mock.player.x = 40.1
    Mock.advance(1.1)
    t.eq(Q.Progress:Current(), list[3], "1 s ticker detects arrival")
    Mock.player.x = 10
    Mock.advance(1.1)
    t.eq(Q.Progress:State(list[2]), "done", "leaving does not undo")
    t.eq(next(Q.char.manual), nil, "position done-ness is not stored")
  end,

  passed_location_steps_count_done = function(t)
    Mock.quests.log[179] = { complete = false, objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
    local Q = load()
    local list = useGuide(Q, "T_Passed", {
      { "goto", 1426, 80, 20 },
      { "note", "talk to Sten" },
      { "accept", 179 },
      { "goto", 1426, 60, 60 },
      { "complete", 179 },
    })
    local s, r = Q.Progress:State(list[1])
    t.eq(s, "done"); t.eq(r, "passed")
    t.eq(Q.Progress:State(list[2]), "done")
    t.eq(Q.Progress:Current(), list[4], "next location after the last progress")
  end,

  level_step = function(t)
    local Q = load()
    local list = useGuide(Q, "T_LevelStep", { { "level", 2 }, { "note", "x" } })
    t.eq(Q.Progress:State(list[1]), "active")
    Mock.player.level = 2
    Mock.fire("PLAYER_LEVEL_UP", 2)
    t.eq(Q.Progress:State(list[1]), "done")
  end,

  fp_on_taximap_opened = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Fp", { { "fp", 1426, 30.2, 71.2 }, { "fp", 1426, 70, 20 }, { "note", "x" } })
    t.eq(Q.Progress:State(list[1]), "active", "walking near is not enough")
    Mock.fire("TAXIMAP_OPENED")
    t.eq(Q.Progress:State(list[1]), "done", "opened within 30 yards")
    t.eq(Q.Progress:Current(), list[2])
    Mock.fire("TAXIMAP_OPENED")
    t.eq(Q.Progress:State(list[2]), "active", "too far from the second flight master")
  end,

  sethearth_on_bound = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Hs", { { "sethearth", 1426, 30.4, 71.2 }, { "note", "x" } })
    Mock.fire("HEARTHSTONE_BOUND")
    t.eq(Q.Progress:State(list[1]), "done")
  end,

  hearth_and_fly_on_map_change = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Hearth", { { "hearth", 1432 }, { "fly", 1426 }, { "note", "x" } })
    t.eq(Q.Progress:Current(), list[1])
    Mock.player.map = 1432
    Mock.fire("ZONE_CHANGED_NEW_AREA")
    t.eq(Q.Progress:State(list[1]), "done")
    t.eq(Q.Progress:Current(), list[2])
    Mock.player.map = 1426
    Mock.fire("ZONE_CHANGED_NEW_AREA")
    t.eq(Q.Progress:State(list[2]), "done")
  end,

  hearth_within_same_map_uses_spell = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Hearth2", { { "hearth", 1426 }, { "note", "x" } })
    t.eq(Q.Progress:Current(), list[1], "already on the map: wait for the hearth")
    Mock.fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-0", 8690)
    t.eq(Q.Progress:State(list[1]), "active", "another unit's hearth is ignored")
    Mock.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 8690)
    t.eq(Q.Progress:State(list[1]), "done")
  end,

  reentrant_update_no_spurious_step_changed = function(t)
    local Q = load()
    local log = {}
    Q:On("STEP_CHANGED", function(e) log[#log + 1] = e and e.key or "nil" end)
    local fired = false
    Q:On("PROGRESS_UPDATED", function()
      if not fired then
        fired = true
        Q.Progress:Skip(Q.Progress:Current().key)   -- un module modifie l'état pendant le message
      end
    end)
    accept179()
    t.eq(log, { "g:A_DwarfGnome_01:3" }, "only the real new step")
    t.eq(#Mock.errors, 0)
  end,

  inserted_chain_removed_from_progress_handler = function(t)
    Mock.player.classFile = "WARLOCK"
    local Q = load()
    -- tag hors « cq: » : seul le gestionnaire du test retire l'insertion
    Q.Progress:InsertSteps("test:chain", { { "accept", 1599 } })
    local log = {}
    Q:On("STEP_CHANGED", function(e) log[#log + 1] = e and e.key or "nil" end)
    -- même schéma que les quêtes de classe : la chaîne finie est retirée pendant PROGRESS_UPDATED
    Q:On("PROGRESS_UPDATED", function()
      for _, e in ipairs(Q.Progress:Entries()) do
        if e.tag == "test:chain" and Q.Progress:State(e) == "done" then
          Q.Progress:RemoveInserted("test:chain")
          return
        end
      end
    end)
    Mock.quests.log[1599] = { complete = false, objectives = {} }
    Mock.fire("QUEST_ACCEPTED", 1599)
    t.eq(log, { "g:A_DwarfGnome_01:1" })
    t.eq(#Q.char.inserted, 0)
  end,

  step_changed_nil_at_route_end = function(t)
    local Q = load()
    local list = useGuide(Q, "T_End", { { "note", "only" } })
    local log = {}
    Q:On("STEP_CHANGED", function(e) log[#log + 1] = e and e.key or "nil" end)
    Q.Progress:MarkDone(list[1].key)
    t.eq(log, { "nil" }, "a genuine route end still reports nil")
  end,

  reset_guide_reopens_reached_goto = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Reset", {
      { "goto", 1426, 29.95, 71.2 },   -- atteint tout de suite (2,5 yards)
      { "note", "a" },
      { "note", "b" },
    })
    t.eq(Q.Progress:State(list[1]), "done")
    Mock.player.x = 60                  -- le joueur s'éloigne : l'étape reste validée
    Mock.advance(1.1)
    t.eq(Q.Progress:State(list[1]), "done")
    local updates, changed = 0, nil
    Q:On("PROGRESS_UPDATED", function() updates = updates + 1 end)
    Q:On("STEP_CHANGED", function(e) changed = e and e.key end)
    t.ok(Q.Progress:ResetGuide())
    t.eq(Q.Progress:State(list[1]), "active", "session latch cleared")
    t.eq(Q.Progress:Current(), list[1])
    t.ok(updates >= 1, "PROGRESS_UPDATED fired")
    t.eq(changed, list[1].key, "STEP_CHANGED fired with the reopened step")
  end,

  reset_guide_clears_manual_and_keeps_other_guides = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Reset2", { { "note", "a" }, { "note", "b" }, { "note", "c" } })
    Q.Progress:MarkDone(list[1].key)
    Q.Progress:Skip(list[2].key)
    Q.char.manual["g:A_DwarfGnome_02:1"] = true
    Q.char.skipped["g:A_DwarfGnome_01:4"] = true
    Q.char.skipped["i:cq:WARLOCK_1598:1"] = true
    Q.char.manual["g:T_Reset2x:1"] = true          -- préfixe proche, autre guide
    t.eq(Q.Progress:Current(), list[3])
    t.ok(Q.Progress:ResetGuide(nil))                -- nil = guide courant
    t.eq(Q.char.manual[list[1].key], nil, "manual mark cleared")
    t.eq(Q.char.skipped[list[2].key], nil, "skip cleared")
    t.eq(Q.Progress:Current(), list[1])
    t.eq(Q.char.manual["g:A_DwarfGnome_02:1"], true, "other guide untouched")
    t.eq(Q.char.skipped["g:A_DwarfGnome_01:4"], true, "other guide untouched")
    t.eq(Q.char.skipped["i:cq:WARLOCK_1598:1"], true, "inserted steps untouched")
    t.eq(Q.char.manual["g:T_Reset2x:1"], true, "similar prefix untouched")
    -- guide explicite, différent du guide courant
    Q.Progress:MarkDone(list[1].key)
    t.ok(Q.Progress:ResetGuide("A_DwarfGnome_02"))
    t.eq(Q.char.manual["g:A_DwarfGnome_02:1"], nil, "named guide cleared")
    t.eq(Q.char.manual[list[1].key], true, "current guide untouched by a reset of another guide")
    t.eq(Q.Progress:Guide().id, "T_Reset2", "reset does not change the selected chapter")
  end,

  reset_guide_without_guide = function(t)
    Mock.player.raceId = 1   -- Humain : aucun chapitre de fixture, pas de guide courant
    local Q = load()
    t.eq(Q.Progress:Guide(), nil)
    t.eq(Q.Progress:ResetGuide(), false)
    t.eq(#Mock.errors, 0)
  end,

  jump_to_makes_step_current = function(t)
    local Q = load()
    local list = Q.Progress:Entries()
    local changes = 0
    Q:On("STEP_CHANGED", function() changes = changes + 1 end)
    t.ok(Q.Progress:JumpTo(list[13].key))
    t.eq(Q.Progress:Current(), list[13])
    t.eq(Q.char.skipped[list[1].key], true, "earlier undone steps skipped")
    t.eq(changes, 1, "one recompute")
    t.ok(Q.Progress:JumpTo(list[1].key))
    t.eq(Q.Progress:Current(), list[1])
    t.eq(next(Q.char.skipped), nil, "later steps unskipped")
    t.eq(Q.Progress:JumpTo("g:nope:1"), false)
  end,

  no_questiedb_no_progress = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    t.eq(Q.Progress:Current(), nil)
    t.eq(#Q.Progress:Entries(), 0)
    Mock.fire("QUEST_ACCEPTED", 179)
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(1)
    t.eq(#Mock.errors, 0)
  end,

  -- Index d'objectif faux dans le guide : la quête complète valide quand même l'étape.
  complete_with_wrong_objective_index_done_when_quest_complete = function(t)
    local Q = load()
    local list = useGuide(Q, "T_WrongObj", { { "complete", 179, obj = 3 }, { "note", "after" } })
    accept179()
    Mock.advance(0.3)
    t.eq(Q.Progress:State(list[1]), "active", "objective 3 does not exist, quest not complete")
    Mock.quests.log[179].complete = true
    Mock.quests.log[179].objectives[1].finished = true
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.eq(Q.Progress:State(list[1]), "done", "complete quest: step done before the turn-in")
    t.eq(Q.Progress:Current(), list[2])
    t.eq(#Mock.errors, 0)
  end,
}
