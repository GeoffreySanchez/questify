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

-- Fenêtre de maître simulée : services = { { name, rank, type, level, cost } }, filtres.
-- Signature Mainline de GetTrainerServiceInfo (Blizzard_TrainerUI/Mainline) : nom, type, icône,
-- niveau requis, sous-texte (rang), catégorie. GetTrainerServiceLevelReq n'existe pas dans Forever.
-- Changer un filtre relance TRAINER_UPDATE, comme le client.
local trainer

local function installTrainerApi()
  trainer = { services = {}, tradeskill = false, filters = { available = true, unavailable = true, used = false },
    filterCalls = {}, reads = 0 }
  local function visible()
    local out = {}
    for _, s in ipairs(trainer.services) do
      if trainer.filters[s[3]] or s[3] == "header" then out[#out + 1] = s end
    end
    return out
  end
  GetNumTrainerServices = function()
    trainer.reads = trainer.reads + 1
    if trainer.onRead then trainer.onRead() end
    return #visible()
  end
  GetTrainerServiceInfo = function(i)
    local s = visible()[i]
    if s then return s[1], s[3], 136000 + i, s[4], s[2], "" end
  end
  GetTrainerServiceLevelReq = nil
  GetTrainerServiceCost = function(i) local s = visible()[i]; return s and s[5] or 0, false end
  GetTrainerServiceTypeFilter = function(f) return trainer.filters[f] end
  SetTrainerServiceTypeFilter = function(f, on)
    trainer.filterCalls[#trainer.filterCalls + 1] = f .. "=" .. tostring(on)
    trainer.filters[f] = on == 1 or on == true
    Mock.fire("TRAINER_UPDATE")
  end
  IsTradeskillTrainer = function() return trainer.tradeskill end
end

local money = 100000

local function load()
  Ext.install()
  installTrainerApi()
  money = 100000
  GetMoney = function() return money end
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
  { "Abilities", "", "header", nil, 0 },
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
    t.eq(trainer.filterCalls, {}, "window filters never touched")
    local a = Q.Trainer:Alert()
    t.ok(a and a.known, "exact list now")
    t.eq(a.count, 2, "Rend and Charge (level 4)")
    t.eq(a.cost, 200)
    t.eq(a.names, { "Rend (Rank 1)", "Charge" })
    t.eq(Q.UI.Tracker.trainerText:GetText(), string.format(Q.L.UI_TRAINER_ALERT, 2))
    -- les deux sorts appris (TRAINER_UPDATE : une relecture différée)
    SERVICES_L2[3][3], SERVICES_L2[4][3] = "used", "used"
    Mock.fire("TRAINER_UPDATE")
    Mock.advance(Q.Trainer.UPDATE_DELAY + 0.05)
    t.eq(Q.Trainer:Alert(), nil, "nothing left at level 4")
    levelUp(5)
    t.eq(Q.Trainer:Alert(), nil, "nothing new at level 5")
    levelUp(6)
    local a6 = Q.Trainer:Alert()
    t.eq(a6 and a6.count, 1, "Thunder Clap at level 6")
    t.eq(Mock.countPrinted(string.format(Q.L.TRAINER_NEW_SPELLS, 1)), 1)
    SERVICES_L2[3][3], SERVICES_L2[4][3] = "available", "unavailable"
    t.eq(trainer.filterCalls, {}, "window filters never touched")
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

  only_affordable_spells_counted = function(t)
    local Q = load()
    levelUp(4)
    money = 150
    talkTo(912, SERVICES_L2)
    local a = Q.Trainer:Alert()
    t.eq(a.count, 1, "one spell at 100 c out of two")
    t.eq(a.total, 2)
    t.eq(a.missing, 100)
    money = 50
    Mock.fire("PLAYER_MONEY")
    t.eq(Q.Trainer:Alert(), nil, "not enough gold: no alert")
    t.ok(not Q.UI.Tracker.trainerAlert:IsShown())
    money = 500
    Mock.fire("PLAYER_MONEY")
    t.eq(Q.Trainer:Alert().count, 2)
  end,

  guess_needs_estimated_gold = function(t)
    local Q = load()
    money = 5
    levelUp(2)
    t.eq(Q.Trainer:Alert(), nil, "5 c: not even the cheapest spell")
    money = 20
    Mock.fire("PLAYER_MONEY")
    t.ok(Q.Trainer:Alert(), "10 c estimated at level 2")
  end,

  -- Après une première visite, l'alerte revient à chaque niveau où un sort de la liste arrive
  -- (niveau requis lu en 4e retour de GetTrainerServiceInfo).
  alert_fires_again_at_next_level_after_first_visit = function(t)
    local Q = load()
    levelUp(4)
    local list = {
      { "Battle Shout", "Rank 1", "used", 1, 10 },
      { "Rend", "Rank 1", "used", 4, 100 },
      { "Thunder Clap", "Rank 1", "unavailable", 6, 100 },
      { "Hamstring", "", "unavailable", 8, 100 },
    }
    talkTo(912, list)
    t.eq(Q.Trainer:Alert(), nil, "everything learned at level 4")
    Mock.fire("TRAINER_CLOSED")
    levelUp(5)
    t.eq(Q.Trainer:Alert(), nil, "nothing new at level 5")
    levelUp(6)
    local a = Q.Trainer:Alert()
    t.ok(a and a.known, "level 6: alert again from the read list")
    t.eq(a.count, 1); t.eq(a.names, { "Thunder Clap (Rank 1)" })
    t.ok(Q.UI.Tracker.trainerAlert:IsShown())
    t.eq(Mock.countPrinted(string.format(Q.L.TRAINER_NEW_SPELLS, 1)), 1)
    -- deuxième visite : sort appris, l'alerte revient encore au niveau 8
    list[3][3], list[4][3] = "used", "unavailable"
    talkTo(912, list)
    t.eq(Q.Trainer:Alert(), nil)
    Mock.fire("TRAINER_CLOSED")
    levelUp(8)
    local a8 = Q.Trainer:Alert()
    t.eq(a8 and a8.names, { "Hamstring" }, "third wave")
    t.eq(Mock.countPrinted(string.format(Q.L.TRAINER_NEW_SPELLS, 1)), 2, "one message per wave")
    t.eq(#Mock.errors, 0)
  end,

  -- La lecture ne change jamais les filtres de la fenêtre, et TRAINER_UPDATE ne peut pas boucler.
  reading_services_changes_no_filter_and_cannot_loop = function(t)
    local Q = load()
    levelUp(4)
    talkTo(912, SERVICES_L2)
    t.eq(trainer.filterCalls, {}, "no filter change on TRAINER_SHOW")
    t.eq(trainer.filters, { available = true, unavailable = true, used = false })
    local before = trainer.reads
    for _ = 1, 5 do Mock.fire("TRAINER_UPDATE") end
    t.eq(trainer.reads, before, "nothing read synchronously")
    Mock.advance(Q.Trainer.UPDATE_DELAY + 0.05)
    t.eq(trainer.reads, before + 1, "five updates -> one read")
    -- client qui relance TRAINER_UPDATE pendant chaque lecture : ignoré, pas de boucle
    trainer.onRead = function() Mock.fire("TRAINER_UPDATE") end
    Mock.fire("TRAINER_UPDATE")
    Mock.advance(5)
    t.eq(trainer.reads, before + 2, "an update fired during our own read is ignored")
    trainer.onRead = nil
    t.eq(trainer.filterCalls, {})
    -- fenêtre fermée : pas de lecture (la liste du client serait vide)
    Mock.fire("TRAINER_CLOSED")
    Mock.fire("TRAINER_UPDATE")
    Mock.advance(1)
    t.eq(trainer.reads, before + 2)
    t.ok(Q.Trainer:Alert(), "list kept after closing")
    t.eq(#Mock.errors, 0)
  end,
}
