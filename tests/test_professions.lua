-- Tests des métiers (Q.Professions, Q.UI.ProfessionPicker) : choix, étapes chez les maîtres.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

-- Un mineur dans la vallée (près du joueur), un dépeceur à Elwynn (loin).
local NPCS = {
  [90100] = { name = "Test Miner", minLevel = 10, maxLevel = 10, spawns = { [1] = { { 30.5, 71.0 } } }, zoneID = 1,
    friendlyToFaction = "A", subName = "Miner", npcFlags = 16 },
  [90101] = { name = "Far Skinner", minLevel = 10, maxLevel = 10, spawns = { [12] = { { 40, 60 } } }, zoneID = 12,
    friendlyToFaction = "A", subName = "Skinner", npcFlags = 16 },
}

local known, money, profs, plevel

-- Bouchons locaux (le simulateur reste intact) : argent, métiers du joueur, niveau.
local saved_fns = {}
local function stub(name, fn)
  if saved_fns[name] == nil then saved_fns[name] = { _G[name] } end
  _G[name] = fn
end
local function restore()
  for name, v in pairs(saved_fns) do _G[name] = v[1] end
  saved_fns = {}
end
-- Lignes de compétence : MINING 186, HERBALISM 182.
local function setProf(line, skill, max) profs[#profs + 1] = { line = line, skill = skill, max = max } end

local function load(saved)
  Ext.install()
  known, money, profs, plevel = {}, 100000, {}, 1
  stub("GetMoney", function() return money end)
  stub("UnitLevel", function(u) if u == "player" then return plevel end return 0 end)
  stub("GetProfessions", function() local r = {} for i = 1, #profs do r[i] = i end return unpack(r) end)
  stub("GetProfessionInfo", function(i)
    local p = profs[i]
    return "x", 0, p.skill, p.max, 0, 0, p.line
  end)
  IsPlayerSpell = function(id) return known[id] == true end
  IsTradeskillTrainer = function() return true end
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true, qdb = { npcs = NPCS },
    savedVariables = saved })
  Q.ProfTrainerData.MINING.A = { 90100 }
  Q.ProfTrainerData.SKINNING.A = { 90101 }
  return Q
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- Joueur à `yards` à l'est du maître mineur (90100), sur sa carte.
local function awayFromMiner(Q, yards)
  local m, x, y
  for mapId, list in pairs(Q.QDB:Npc(90100).spawns) do m, x, y = mapId, list[1][1], list[1][2] end
  local unit = Q.Maps:Distance(m, x, y, m, x + 1, y)
  Mock.player.map, Mock.player.x, Mock.player.y = m, x + yards / unit, y
  local _, _, _, d = Q.Maps:Nearest(Q.QDB:Npc(90100).spawns, Mock.player.map, Mock.player.x, Mock.player.y)
  assert(math.abs(d - yards) < 1, "player placed at " .. tostring(d))
end

-- Compte les insertions de l'étape d'un métier (Q.Progress:InsertSteps).
local function countInserts(Q, key)
  local n = { 0 }
  local orig = Q.Progress.InsertSteps
  Q.Progress.InsertSteps = function(self, tag, ...)
    if tag == "prof:" .. key then n[1] = n[1] + 1 end
    return orig(self, tag, ...)
  end
  return n
end

return {
  picker_once_after_wizard = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Mock.advance(4)
    local P = Q.UI.ProfessionPicker
    t.ok(P.frame and P.frame:IsShown(), "asked at login")
    P.laterButton:GetScript("OnClick")(P.laterButton)
    t.ok(not P.frame:IsShown())
    t.eq(Q.Professions:Chosen(), nil, "later: nothing saved")
  end,

  not_before_wizard = function(t)
    local Q = load()
    Mock.advance(4)
    local P = Q.UI.ProfessionPicker
    t.ok(not (P.frame and P.frame:IsShown()), "wizard first")
  end,

  picker_after_wizard_closed = function(t)
    local Q = load()
    local P, W = Q.UI.ProfessionPicker, Q.UI.Wizard
    Mock.advance(4)
    t.ok(W:IsShown(), "wizard open")
    P.AutoShow()
    t.ok(not (P.frame and P.frame:IsShown()), "never while the wizard is open")
    QuestifyWizard:Hide()                    -- croix : l'assistant n'est pas terminé
    t.eq(Q.char.wizardDone, nil)
    Mock.advance(1)
    t.ok(P.frame and P.frame:IsShown(), "asked once the wizard is closed")
    P.laterButton:GetScript("OnClick")(P.laterButton)
    -- une fois par session : ni une nouvelle fermeture de l'assistant ni LOGIN ne la rouvrent
    SlashCmdList.QUESTIFY("wizard")
    QuestifyWizard:Hide()
    Q:Fire("LOGIN")
    Mock.advance(5)
    t.ok(not P.frame:IsShown(), "once per session")
    t.eq(#Mock.errors, 0)
  end,

  picker_after_wizard_finished = function(t)
    local Q = load()
    local P, W = Q.UI.ProfessionPicker, Q.UI.Wizard
    Mock.advance(4)
    while W.page < W.NUM_PAGES do Mock.click(W.nextButton, "LeftButton") end
    Mock.click(W.finishButton, "LeftButton")
    Mock.advance(1)
    t.ok(P.frame and P.frame:IsShown(), "asked after Finish")
    t.eq(Mock.countCalls("StaticPopup_Show"), 0)
    t.eq(#Mock.errors, 0)
  end,

  two_primaries_max = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    local P = Q.UI.ProfessionPicker
    P:Show()
    for _, key in ipairs({ "MINING", "SKINNING", "HERBALISM" }) do
      local cb = P.checks[key]
      cb:SetChecked(true)
      cb:GetScript("OnClick")(cb)
    end
    t.ok(P.checks.MINING:GetChecked() and P.checks.SKINNING:GetChecked())
    t.ok(not P.checks.HERBALISM:GetChecked(), "third primary refused")
    t.eq(P.warn:GetText(), Q.L.UI_PROF_MAX)
    P.checks.COOKING:SetChecked(true)
    P.okButton:GetScript("OnClick")(P.okButton)
    t.eq(Q.Professions:Chosen(), { MINING = true, SKINNING = true, COOKING = true })
    t.ok(Mock.countPrinted("Mining") >= 1)
  end,

  step_inserted_near_a_trainer_only = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true, SKINNING = true })
    local cur = Q.Progress:Current()
    t.eq(cur.step.action, "trainprof")
    t.eq(cur.step.prof, "MINING")
    t.ok(not Q.Professions:HasStep("SKINNING"), "skinning trainer too far")
    local T = Q.UI.Tracker
    t.ok(plain(T.currentText:GetText()):find("Mining", 1, true), plain(T.currentText:GetText()))
    t.ok(plain(T.currentText:GetText()):find("Test Miner", 1, true))
    local tg = Q.Targets:ForEntry(cur)
    t.eq(tg.id, 90100)
    t.eq(Q.Format:StepTitle(cur), string.format(Q.L.TITLE_TRAINPROF, "Mining"))
    t.eq(#Mock.errors, 0)
  end,

  step_removed_when_learned = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    known[2575] = true
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "Apprentice Mining known")
    restore()
  end,

  step_removed_when_in_profession_list = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    setProf(186, 1, 75)
    Mock.fire("SKILL_LINES_CHANGED")
    t.ok(not Q.Professions:HasStep("MINING"), "game confirms the profession")
    t.ok(Q.Professions:Known("MINING"))
    restore()
  end,

  no_step_without_money_then_step_when_money_arrives = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    money = 0
    Q.Professions:SetChosen({ MINING = true })
    t.ok(not Q.Professions:HasStep("MINING"), "0 copper: no marker")
    money = 9
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "9 copper: still no")
    money = 10
    Mock.fire("PLAYER_MONEY")
    t.ok(Q.Professions:HasStep("MINING"), "10 copper: marker")
    t.eq(#Mock.errors, 0)
    restore()
  end,

  visit_without_paying_does_not_learn = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    money = 0
    Q.Professions:SetChosen({ MINING = true })
    Mock.units.npc = { guid = "Creature-0-1-0-1-90100-0000ABCD", name = "Test Miner" }
    Mock.fire("TRAINER_SHOW")
    t.ok(not Q.Professions:Known("MINING"), "a visit is not learning")
    -- ancien état sauvegardé : ne suffit plus
    Q.char.profLearned = { MINING = true }
    t.ok(not Q.Professions:Known("MINING"), "legacy profLearned ignored")
    money = 10
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"), "step comes back with the money")
    restore()
  end,

  skipped_step_returns_on_next_visit_to_town = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    local cur = Q.Progress:Current()
    t.eq(cur.step.action, "trainprof")
    local home = { Mock.player.map, Mock.player.x, Mock.player.y }
    Q.Progress:Skip(cur.key)
    Mock.advance(5)
    t.ok(Q.Progress:Current().step.action ~= "trainprof", "skipped stays skipped near the trainer")
    -- le joueur s'éloigne : l'étape passée est retirée
    Mock.player.map, Mock.player.x, Mock.player.y = 12, 90, 90
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "dropped once away")
    -- retour en ville : réinsérée une fois
    Mock.player.map, Mock.player.x, Mock.player.y = home[1], home[2], home[3]
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"), "back in town: reinserted")
    t.eq(Q.Progress:Current().step.action, "trainprof")
    restore()
  end,

  next_rank_step = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    -- apprenti appris : compétence 50, niveau 10, 5 pa
    known[2575] = true
    setProf(186, 49, 75); plevel = 10; money = 500
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "skill 49: nothing")
    profs[1].skill = 50
    money = 499
    Mock.fire("SKILL_LINES_CHANGED")
    t.ok(not Q.Professions:HasStep("MINING"), "not enough money: nothing")
    money = 500
    Mock.fire("PLAYER_MONEY")
    t.ok(Q.Professions:HasStep("MINING"), "journeyman step")
    local cur = Q.Progress:Current()
    t.eq(cur.step.rank, 2)
    t.eq(Q.Format:StepTitle(cur), string.format(Q.L.TITLE_TRAINPROF, "Mining (" .. Q.L.PROF_RANK_2 .. ")"))
    -- niveau trop bas : rien
    local Q2 = load({ QuestifyCharDB = { wizardDone = true } })
    Q2.Professions:SetChosen({ MINING = true })
    known[2575] = true
    setProf(186, 60, 75); plevel = 9; money = 500
    Mock.advance(5)
    t.ok(not Q2.Professions:HasStep("MINING"), "level 9: nothing")
    -- rang appris (maximum 150) : étape retirée
    plevel = 10
    Mock.advance(5)
    t.ok(Q2.Professions:HasStep("MINING"))
    profs[1].max = 150
    Mock.fire("SKILL_LINES_CHANGED")
    t.ok(not Q2.Professions:HasStep("MINING"), "rank confirmed by the game")
    t.eq(#Mock.errors, 0)
    restore()
  end,

  unchosen_profession_steps_removed = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    Q.Professions:SetChosen({})
    t.ok(not Q.Professions:HasStep("MINING"))
    t.ok(Q.Progress:Current().step.action ~= "trainprof")
  end,

  -- 12.x : LEARNED_SPELL_IN_SKILL_LINE remplace LEARNED_SPELL_IN_TAB (absent de Forever).
  learned_spell_in_skill_line_checks_at_once = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    known[2575] = true
    Mock.fire("LEARNED_SPELL_IN_SKILL_LINE", 2575, 3, false)
    t.ok(not Q.Professions:HasStep("MINING"), "checked on the event, without waiting for the ticker")
    t.eq(#(Mock.eventFrames["LEARNED_SPELL_IN_TAB"] or {}), 0, "removed event not registered")
    t.eq(#Mock.errors, 0)
  end,

  step_dropped_when_money_disappears = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    money = 10
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    money = 3
    Mock.fire("PLAYER_MONEY")
    t.ok(not Q.Professions:HasStep("MINING"), "no money: marker gone")
    restore()
  end,

  untouched_step_dropped_when_leaving_then_back = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    local home = { Mock.player.map, Mock.player.x, Mock.player.y }
    Mock.player.map, Mock.player.x, Mock.player.y = 12, 90, 90
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "left town: step removed")
    Mock.player.map, Mock.player.x, Mock.player.y = home[1], home[2], home[3]
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"), "back with money: step again")
    restore()
  end,

  getprofessions_with_holes = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    setProf(356, 1, 75); setProf(185, 1, 75)
    GetProfessions = function() return nil, nil, nil, 1, 2 end
    t.ok(Q.Professions:Known("FISHING") and Q.Professions:Known("COOKING"))
    restore()
  end,

  trainer_cost_recorded = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    stub("GetNumTrainerServices", function() return 1 end)
    stub("GetTrainerServiceInfo", function() return "Apprentice Mining" end)
    stub("GetTrainerServiceCost", function() return 25 end)
    Q.Professions:SetChosen({ MINING = true })
    money = 10
    Mock.units.npc = { guid = "Creature-0-1-0-1-90100-0000ABCD", name = "Test Miner" }
    Mock.fire("TRAINER_SHOW")
    t.eq(Q.Professions:RankCost(1, "MINING"), 25, "recorded cost preferred")
    t.eq(Q.Professions:RankCost(2, "MINING"), 500, "table otherwise")
    t.ok(not Q.Professions:HasStep("MINING"), "10 copper < recorded 25")
    restore()
  end,

  trainer_cost_rank_in_subtext = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    -- Mainline : nom, type, icône, niveau requis, sous-texte (le rang)
    stub("GetNumTrainerServices", function() return 1 end)
    stub("GetTrainerServiceInfo", function() return "Mining", "available", nil, 10, "Journeyman" end)
    stub("GetTrainerServiceCost", function() return 750 end)
    Q.Professions:SetChosen({ MINING = true })
    Mock.units.npc = { guid = "Creature-0-1-0-1-90100-0000ABCD", name = "Test Miner" }
    Mock.fire("TRAINER_SHOW")
    t.eq(Q.Professions:RankCost(2, "MINING"), 750, "rank read from the subtext")
    t.eq(Q.Professions:RankCost(1, "MINING"), 10, "table for the other ranks")
    restore()
  end,

  rank_rules_w4_r1 = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ COOKING = true, HERBALISM = true })
    known[2550] = true; known[2366] = true
    setProf(185, 125, 150); setProf(182, 200, 225); plevel = 35; money = 100000
    t.eq(Q.Professions:WantedRank("COOKING"), nil, "secondary: no Expert")
    t.eq(Q.Professions:WantedRank("HERBALISM"), nil, "primary: no Artisan")
    profs[2].skill, profs[2].max = 125, 150
    t.eq(Q.Professions:WantedRank("HERBALISM"), 3, "primary Expert")
    restore()
  end,

  -- I3 : hystérésis. Insertion à 400 yd ou moins ; retrait (et oubli du « passer ») seulement au-delà
  -- de 800 yd. Entre les deux, rien ne bouge.
  hysteresis_between_400_and_800_yards = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    Q.Progress:Skip(Q.Progress:Current().key)
    local inserts = countInserts(Q, "MINING")
    for i = 1, 4 do
      local yards = i % 2 == 1 and 420 or 380
      awayFromMiner(Q, yards)
      Mock.advance(5)
      t.ok(Q.Professions:HasStep("MINING"), "oscillating at " .. yards .. " yd: step kept")
      t.ok(Q.Progress:Current().step.action ~= "trainprof", "skipped state kept at " .. yards .. " yd")
    end
    t.eq(inserts[1], 0, "never reinserted while oscillating")
    awayFromMiner(Q, 790)
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"), "790 yd: untouched")
    awayFromMiner(Q, 820)
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "beyond 800 yd: removed")
    awayFromMiner(Q, 600)
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "600 yd on the way back: not yet")
    awayFromMiner(Q, 380)
    Mock.advance(5)
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"), "back within 400 yd: reinserted")
    t.eq(inserts[1], 1, "reinserted once")
    t.eq(Q.Progress:Current().step.action, "trainprof", "the skip was forgotten")
    t.eq(#Mock.errors, 0)
    restore()
  end,

  -- I3 : au changement de zone, l'étape part dès qu'on est à plus de 400 yd (pas d'attente des 800).
  zone_change_drops_the_step_beyond_400_yards = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    Q.Progress:Skip(Q.Progress:Current().key)
    awayFromMiner(Q, 100)
    Mock.fire("ZONE_CHANGED_NEW_AREA")
    t.ok(Q.Professions:HasStep("MINING"), "zone change near the trainer: kept")
    t.ok(Q.Progress:Current().step.action ~= "trainprof", "and still skipped")
    awayFromMiner(Q, 600)
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"), "600 yd: kept")
    Mock.fire("ZONE_CHANGED_NEW_AREA")
    t.ok(not Q.Professions:HasStep("MINING"), "zone change at 600 yd: removed")
    -- en combat : le changement de zone est retenu pour le prochain contrôle
    awayFromMiner(Q, 100)
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"))
    awayFromMiner(Q, 600)
    Mock.player.combat = true
    Mock.fire("ZONE_CHANGED_NEW_AREA")
    Mock.player.combat = false
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "zone change seen in combat applied afterwards")
    restore()
  end,

  -- I3 : sans l'argent, l'étape part tout de suite, même entre 400 et 800 yd.
  money_gone_between_400_and_800_yards_removes_the_step = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    awayFromMiner(Q, 600)
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"))
    money = 3
    Mock.fire("PLAYER_MONEY")
    t.ok(not Q.Professions:HasStep("MINING"), "no money: removed at once")
    restore()
  end,

  -- I4 : pas de nouvelle étape tant que le joueur est dans une grotte ; une étape déjà là reste.
  no_new_step_inside_a_cave = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    local saved = Q.Caves.PlayerCave
    local cave = "test_den"
    Q.Caves.PlayerCave = function() return cave end
    Q.Professions:SetChosen({ MINING = true })
    t.ok(not Q.Professions:HasStep("MINING"), "inside a cave: not inserted")
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "still inside: not inserted")
    cave = nil
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"), "outside: inserted")
    cave = "test_den"
    Mock.advance(5)
    t.ok(Q.Professions:HasStep("MINING"), "back in the cave: the step is not removed")
    Q.Caves.PlayerCave = saved
    restore()
  end,

  -- M4 : maximum 25 (moins qu'un rang) pour un métier connu : aucune étape, et aucune recherche de
  -- maître sans rang voulu.
  known_profession_with_max_25_gets_no_step = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    setProf(186, 1, 25)
    Mock.fire("SKILL_LINES_CHANGED")
    t.eq(Q.Professions:WantedRank("MINING"), nil)
    t.ok(not Q.Professions:HasStep("MINING"), "no step")
    local lookups = 0
    local orig = Q.QDB.Npc
    Q.QDB.Npc = function(self, id)
      if id == 90100 then lookups = lookups + 1 end
      return orig(self, id)
    end
    Mock.advance(5)
    t.eq(lookups, 0, "no trainer lookup without a wanted rank")
    Q.QDB.Npc = orig
    restore()
  end,
}
