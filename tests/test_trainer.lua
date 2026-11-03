-- Tests du maître de classe (Q.Trainer) : sorts à apprendre, alerte du suivi, étape « train ».
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

-- Thran Khorman (912) dans la vallée, un autre maître guerrier (913) loin, à Elwynn.
local TRAINERS = {
  [912] = { name = "Thran Khorman", minLevel = 10, maxLevel = 10, spawns = { [1] = { { 28.83, 67.84 } } },
    zoneID = 1, friendlyToFaction = "A", subName = "Warrior Trainer", npcFlags = 51 },
  [913] = { name = "Lyria Du Lac", minLevel = 40, maxLevel = 40, spawns = { [12] = { { 41.08, 65.77 } } },
    zoneID = 12, friendlyToFaction = "A", subName = "Warrior Trainer", npcFlags = 51 },
}

-- Fenêtre de maître simulée : services = { { name, rank, category, level, cost } }, filtres.
local trainer

local function installTrainerApi()
  trainer = { services = {}, tradeskill = false, filters = { available = true, unavailable = false, used = false },
    filterCalls = {} }
  local function visible()
    local out = {}
    for _, s in ipairs(trainer.services) do
      if trainer.filters[s[3]] then out[#out + 1] = s end
    end
    return out
  end
  GetNumTrainerServices = function() return #visible() end
  GetTrainerServiceInfo = function(i) local s = visible()[i]; if s then return s[1], s[2], s[3] end end
  GetTrainerServiceLevelReq = function(i) local s = visible()[i]; return s and s[4] end
  GetTrainerServiceCost = function(i) local s = visible()[i]; return s and s[5] or 0 end
  GetTrainerServiceTypeFilter = function(f) return trainer.filters[f] end
  SetTrainerServiceTypeFilter = function(f, on)
    trainer.filterCalls[#trainer.filterCalls + 1] = f .. "=" .. tostring(on)
    trainer.filters[f] = on == 1 or on == true
    Mock.fire("TRAINER_UPDATE")
  end
  IsTradeskillTrainer = function() return trainer.tradeskill end
end

local function load()
  Ext.install()
  installTrainerApi()
  return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true, qdb = { npcs = TRAINERS } })
end

local function levelUp(lvl)
  Mock.player.level = lvl
  Mock.fire("PLAYER_LEVEL_UP", lvl)
end

local function talkTo(npcId, services)
  Mock.units.npc = { guid = "Creature-0-1-0-1-" .. npcId .. "-0000ABCD", name = "Trainer" }
  trainer.services = services
  Mock.fire("TRAINER_SHOW")
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

local SERVICES_L2 = {
  { "Battle Shout", "Rank 1", "used", 1, 10 },
  { "Rend", "Rank 1", "available", 4, 100 },        -- niveau 4
  { "Charge", "", "unavailable", 4, 100 },
  { "Thunder Clap", "Rank 1", "unavailable", 6, 100 },
}

return {
  fallback_even_levels_before_first_visit = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    t.eq(Q.Trainer:Alert(), nil, "level 1: nothing")
    t.ok(not T.trainerAlert:IsShown())
    levelUp(2)
    local a = Q.Trainer:Alert()
    t.ok(a and a.known == false, "level 2: probably new spells")
    t.ok(T.trainerAlert:IsShown())
    t.eq(T.trainerText:GetText(), Q.L.UI_TRAINER_ALERT_MAYBE)
    t.eq(Mock.countPrinted(Q.L.TRAINER_MAYBE_SPELLS), 1)
    levelUp(3)
    t.ok(Q.Trainer:Alert(), "still to do at level 3")
    t.eq(Mock.countPrinted(Q.L.TRAINER_MAYBE_SPELLS), 1, "one message per level")
    t.eq(#Mock.errors, 0)
  end,

  click_inserts_step_to_nearest_trainer = function(t)
    local Q = load()
    levelUp(2)
    local T = Q.UI.Tracker
    T.trainerAlert:GetScript("OnClick")(T.trainerAlert, "LeftButton")
    local cur = Q.Progress:Current()
    t.eq(cur.step.action, "train")
    t.eq(cur.source, "inserted")
    t.ok(not T.trainerAlert:IsShown(), "alert replaced by the step")
    local tg = Q.Targets:ForEntry(cur)
    t.eq(tg.kind, "npc"); t.eq(tg.id, 912, "the trainer in the valley, not the one in Elwynn")
    t.ok(plain(T.currentText:GetText()):find("Thran Khorman", 1, true), plain(T.currentText:GetText()))
    t.eq(T.currentIcon:GetTexture(), Q.Format:ActionIcon("train"))
    t.eq(Q.Format:StepTitle(cur), Q.L.TITLE_TRAIN)
    t.eq(#Mock.errors, 0)
  end,

  visit_reads_spells_and_clears_step = function(t)
    local Q = load()
    levelUp(4)
    Q.Trainer:Go()
    talkTo(912, SERVICES_L2)
    t.ok(not Q.Trainer:HasStep(), "visit done: step removed")
    t.ok(Q.Progress:Current().step.action ~= "train")
    t.eq(trainer.filters, { available = true, unavailable = false, used = false }, "window filters restored")
    local a = Q.Trainer:Alert()
    t.ok(a and a.known, "exact list now")
    t.eq(a.count, 2, "Rend and Charge (level 4)")
    t.eq(a.cost, 200)
    t.eq(a.names, { "Rend (Rank 1)", "Charge" })
    t.eq(Q.UI.Tracker.trainerText:GetText(), string.format(Q.L.UI_TRAINER_ALERT, 2))
    -- les deux sorts appris
    SERVICES_L2[2][3], SERVICES_L2[3][3] = "used", "used"
    Mock.fire("TRAINER_UPDATE")
    t.eq(Q.Trainer:Alert(), nil, "nothing left at level 4")
    levelUp(5)
    t.eq(Q.Trainer:Alert(), nil, "nothing new at level 5")
    levelUp(6)
    local a6 = Q.Trainer:Alert()
    t.eq(a6 and a6.count, 1, "Thunder Clap at level 6")
    t.eq(Mock.countPrinted(string.format(Q.L.TRAINER_NEW_SPELLS, 1)), 1)
    SERVICES_L2[2][3], SERVICES_L2[3][3] = "available", "unavailable"
    t.eq(#Mock.errors, 0)
  end,

  other_trainers_ignored = function(t)
    local Q = load()
    levelUp(2)
    trainer.tradeskill = true
    talkTo(1681, { { "Mining", "", "available", 5, 10 } })
    t.eq(Q.char.trainer.services, nil, "profession trainer ignored")
    trainer.tradeskill = false
    talkTo(460, { { "Immolate", "Rank 1", "available", 1, 10 } })   -- maître démoniste
    t.eq(Q.char.trainer.services, nil, "other class trainer ignored")
    t.ok(Q.Trainer:Alert() and not Q.Trainer:Alert().known, "still the guess")
  end,

  snooze_until_next_level = function(t)
    local Q = load()
    levelUp(2)
    local T = Q.UI.Tracker
    T.trainerAlert:GetScript("OnClick")(T.trainerAlert, "RightButton")
    t.ok(not T.trainerAlert:IsShown(), "hidden")
    t.eq(Q.Trainer:HasStep(), false, "no step on right-click")
    levelUp(3)
    t.ok(T.trainerAlert:IsShown(), "back at the next level")
  end,

  tooltip_lists_spells_and_cost = function(t)
    local Q = load()
    levelUp(4)
    talkTo(912, SERVICES_L2)
    local T = Q.UI.Tracker
    T.trainerAlert:GetScript("OnEnter")(T.trainerAlert)
    t.ok(Ext.tooltipHas("Rend (Rank 1)"))
    t.ok(Ext.tooltipHas(Q.L.UI_TRAINER_HINT_GO))
    t.ok(Ext.tooltipHas(Q.L.UI_TRAINER_HINT_SNOOZE))
  end,

  option_off = function(t)
    local Q = load()
    levelUp(2)
    Q.Settings:Set("trainerAlert", false)
    t.eq(Q.Trainer:Alert(), nil)
    t.ok(not Q.UI.Tracker.trainerAlert:IsShown())
  end,

  trainer_ids_by_class_and_faction = function(t)
    local Q = load()
    local ids = Q.Trainer:TrainerIds()
    t.ok(#ids > 5, "generated list for Alliance warriors")
    t.ok(Q.Trainer:IsClassTrainer(912))
    t.ok(not Q.Trainer:IsClassTrainer(460), "warlock trainer")
    Mock.player.faction = "Horde"
    Mock.fire("PLAYER_LEVEL_UP", 1)
    t.ok(not Q.Trainer:IsClassTrainer(912), "Alliance trainer for a Horde warrior")
  end,
}
