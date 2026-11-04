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

local known

local function load(saved)
  Ext.install()
  known = {}
  IsPlayerSpell = function(id) return known[id] == true end
  IsTradeskillTrainer = function() return true end
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true, qdb = { npcs = NPCS },
    savedVariables = saved })
  Q.ProfTrainerData.MINING.A = { 90100 }
  Q.ProfTrainerData.SKINNING.A = { 90101 }
  return Q
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

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

  step_removed_when_learned_or_visited = function(t)
    local Q = load({ QuestifyCharDB = { wizardDone = true } })
    Q.Professions:SetChosen({ MINING = true })
    t.ok(Q.Professions:HasStep("MINING"))
    known[2575] = true
    Mock.advance(5)
    t.ok(not Q.Professions:HasStep("MINING"), "Apprentice Mining known")
    -- autre personnage : visite du maître
    local Q2 = load({ QuestifyCharDB = { wizardDone = true } })
    Q2.Professions:SetChosen({ MINING = true })
    Mock.units.npc = { guid = "Creature-0-1-0-1-90100-0000ABCD", name = "Test Miner" }
    Mock.fire("TRAINER_SHOW")
    t.ok(not Q2.Professions:HasStep("MINING"), "visited")
    t.ok(Q2.Professions:Known("MINING"))
    Mock.advance(5)
    t.ok(not Q2.Professions:HasStep("MINING"), "not inserted again")
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
}
