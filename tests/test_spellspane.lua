-- Tests de l'onglet « Sorts à apprendre » (UI/SpellsPane.lua) : bandeau, filtres, lignes de quête,
-- étape « train », pastille de l'onglet.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")
local Spec = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")
local Traits = dofile(Mock.root .. "/tests/mock_ext_traits.lua")
local PS = dofile(Mock.root .. "/tests/mock_ext_playerspells.lua")

local TRAINERS = {
  [912] = { name = "Thran Khorman", minLevel = 10, maxLevel = 10, spawns = { [1] = { { 28.83, 67.84 } } },
    zoneID = 1, friendlyToFaction = "A", subName = "Warrior Trainer", npcFlags = 51 },
}
local SPELLS = { WARRIOR = {
  { spellID = 100, level = 1 },
  { spellID = 101, level = 8, supersedes = 100 },
  { spellID = 200, level = 4 },
  { spellID = 300, level = 12 },
  { spellID = 400, level = 4 },
} }
local CHAIN_LEVEL = 10
local CLASSQ = { WARRIOR = {
  { key = "WARRIOR_A", title = "Call of Fire", faction = "Alliance", level = CHAIN_LEVEL, quests = { 9101, 9102 },
    rewards = {} },
} }
local NAMES = { [100] = "Strike", [101] = "Strike", [200] = "Shield", [300] = "Cleave", [400] = "Fire Totem" }
local RANKS = { [100] = "Rank 1", [101] = "Rank 2" }
local known

-- opts : level, combat, noTrain
local function load(opts)
  opts = opts or {}
  Ext.install()
  Spec.install()
  Mock.spec.index = 1
  known = {}
  Mock.player.classFile = "WARRIOR"; Mock.player.level = opts.level or 10
  Mock.player.raceId, Mock.player.faction = 3, "Alliance"
  Mock.player.combat = opts.combat == true
  C_Spell = { GetSpellName = function(id) return NAMES[id] end, GetSpellSubtext = function(id) return RANKS[id] end,
    GetSpellTexture = function(id) return 900000 + id end }
  IsPlayerSpell = function(id) return known[id] == true end
  GetMoney = function() return 100000 end
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true, qdb = { npcs = TRAINERS },
    beforeLogin = function(Q)
      Q.ClassSpellData = SPELLS
      Q.ClassQuestData = CLASSQ
      Q.SpellQuestData = { [400] = "WARRIOR_A" }
    end })
  Q.SpellList:Invalidate()
  return Q
end

local function open(Q)
  Q.UI.BuildWindow:Open("spells")
  return Q.UI.SpellsPane
end

local function line(P, id)
  for _, f in ipairs(P.ui.lines) do
    if f:IsShown() and f.spellID == id then return f end
  end
end

local function shownIds(P)
  local out = {}
  for _, f in ipairs(P.ui.lines) do
    if f:IsShown() and f.spellID then out[#out + 1] = f.spellID end
  end
  return out
end

local function headers(P)
  local n = 0
  for _, f in ipairs(P.ui.lines) do
    if f:IsShown() and f.kind == "header" then n = n + 1 end
  end
  return n
end

local function entries(Q, tag)
  local out = {}
  for _, e in ipairs(Q.Progress:Entries()) do
    if e.tag == tag then out[#out + 1] = e end
  end
  return out
end

local function addMarker(Q)
  Q.Progress:InsertSteps("zzz", { { "train" } })
end

return {
  route_button_inserts_train_step = function(t)
    local Q = load()
    local P = open(Q)
    Q.char.trainer = { services = {}, visitLevel = 10 }   -- liste relevée : rien d'apprenable
    t.ok(not Q.Trainer:Learnable(), "nothing learnable: Go would refuse")
    P.ui.route:Click()
    local cur = Q.Progress:Current()
    t.eq(cur.step.action, "train")
    t.eq(cur.source, "inserted")
    t.ok(Q.Trainer:HasStep())
    t.eq(Q.Targets:ForEntry(cur).id, 912)
    t.eq(#Mock.errors, 0)
  end,

  go_keeps_forced_step = function(t)
    local Q = load({ level = 10 })
    t.ok(Q.Trainer:GoNearest())
    t.ok(Q.Trainer:Go(), "learnable at an even level: Go inserts again")
    Q.char.trainer.services = {}; Q.char.trainer.visitLevel = 10   -- plus rien d'apprenable
    Q.Trainer:Sync()
    t.ok(Q.Trainer:HasStep(), "still requested: Sync keeps it")
  end,

  route_button_ignored_in_combat = function(t)
    local Q = load()
    local P = open(Q)
    Mock.player.combat = true
    P.ui.route:Click()
    t.ok(not Q.Trainer:HasStep())
    Mock.player.combat = false
    t.eq(#Mock.errors, 0)
  end,

  track_button_moves_steps_first = function(t)
    local Q = load()
    Mock.quests.log[9101] = { complete = false, objectives = {} }
    addMarker(Q)                       -- groupe inséré avant la chaîne
    Q.ClassQuests:Add("WARRIOR_A")
    t.eq(Q.Progress:Entries()[1].tag, "zzz", "chain behind the other group")
    Q.SpellList:Invalidate()
    local P = open(Q)
    local f = line(P, 400)
    t.eq(f.action:GetText(), Q.L.SPELLS_QUEST_TRACK)
    f.action:Click()
    t.eq(Q.Progress:Entries()[1].tag, "cq:WARRIOR_A", "chain steps first")
    t.eq(#entries(Q, "zzz"), 1, "other group kept")
    t.eq(Q.Progress:Current().tag, "cq:WARRIOR_A", "navigation follows the chain")
    t.eq(#Mock.errors, 0)
  end,

  track_button_adds_when_not_inserted = function(t)
    local Q = load()
    Mock.quests.log[9101] = { complete = false, objectives = {} }
    Q.SpellList:Invalidate()
    local P = open(Q)
    t.eq(#entries(Q, "cq:WARRIOR_A"), 0)
    addMarker(Q)                       -- un autre groupe existe déjà : la chaîne doit passer devant
    line(P, 400).action:Click()
    t.ok(#entries(Q, "cq:WARRIOR_A") > 0, "added")
    t.eq(Q.Progress:Entries()[1].tag, "cq:WARRIOR_A", "chain first, ahead of the existing group")
    t.eq(#entries(Q, "zzz"), 1)
    t.eq(Q.Progress:Current().tag, "cq:WARRIOR_A")
    t.eq(#Mock.errors, 0)
  end,

  get_button_adds_chain = function(t)
    local Q = load()
    local P = open(Q)
    local f = line(P, 400)
    t.eq(f.action:GetText(), Q.L.SPELLS_QUEST_GET)
    t.ok(f.action:IsEnabled())
    f.action:Click()
    t.ok(#entries(Q, "cq:WARRIOR_A") > 0)
    t.eq(Q.Progress:Current().tag, "cq:WARRIOR_A")
    t.eq(#Mock.errors, 0)
  end,

  rank_label_localised = function(t)
    Mock.locale = "frFR"
    local Q = load()
    local P = open(Q)
    t.eq(line(P, 101).rank:GetText(), "rang 2")
    t.eq(line(P, 101).row.rankNum, 2)
  end,

  quest_click_failure_says_so = function(t)
    local Q = load()
    local P = open(Q)
    local f = line(P, 400)
    Q.ClassQuests:Ignore("WARRIOR_A")   -- la ligne garde son état affiché, mais la chaîne est ignorée
    Q.ClassQuests.Add = function() return false end
    f.action:Click()
    t.eq(P.ui.msg:GetText(), Q.L.SPELLS_QUEST_FAILED)
    t.eq(#entries(Q, "cq:WARRIOR_A"), 0)
    t.ok(Q.L.SPELLS_QUEST_FAILED ~= "SPELLS_QUEST_FAILED")
  end,

  quest_buttons_ignored_in_combat = function(t)
    local Q = load()
    local P = open(Q)
    Mock.player.combat = true
    line(P, 400).action:Click()
    t.eq(#entries(Q, "cq:WARRIOR_A"), 0)
    Mock.player.combat = false
  end,

  upcoming_quest_button_disabled = function(t)
    local Q = load({ level = 5 })
    local P = open(Q)
    local f = line(P, 400)
    t.eq(f.action:GetText(), string.format(Q.L.SPELLS_QUEST_UPCOMING, CHAIN_LEVEL))
    t.ok(not f.action:IsEnabled(), "disabled")
    f.action:Click()
    t.eq(#entries(Q, "cq:WARRIOR_A"), 0, "no-op")
    t.eq(#Mock.errors, 0)
  end,

  rows_show_icon_name_rank_level_cost_state = function(t)
    local Q = load()
    known[100] = true
    Q.char.trainer = { services = { { name = "Shield", level = 4, cost = 120 } } }
    Q.SpellList:Invalidate()
    local P = open(Q)
    local f = line(P, 100)
    t.eq(f.icon:GetTexture(), 900100)
    t.ok(f.name:GetText():find("Strike", 1, true))
    t.eq(f.rank:GetText(), string.format(Q.L.SPELLS_RANK, 1))
    t.eq(line(P, 101).rank:GetText(), string.format(Q.L.SPELLS_RANK, 2))
    t.eq(line(P, 200).rank:GetText(), "", "single-rank spell: no label")
    t.eq(f.level:GetText(), string.format(Q.L.SPELLS_LEVEL, 1))
    t.eq(f.cost:GetText(), Q.L.SPELLS_NO_COST)
    t.eq(f.state:GetText(), Q.L.SPELLS_STATE_KNOWN)
    local g = line(P, 200)
    t.ok(g.cost:GetText() ~= Q.L.SPELLS_NO_COST, "known cost shown")
    t.eq(g.state:GetText(), Q.L.SPELLS_STATE_NOW)
    t.eq(line(P, 300).state:GetText(), string.format(Q.L.SPELLS_STATE_SOON, 12))
    t.ok(headers(P) >= 3, "level headers")
    t.eq(#Mock.errors, 0)
  end,

  filters = function(t)
    local Q = load()
    known[100] = true
    local P = open(Q)
    t.eq(shownIds(P), { 100, 200, 400, 101, 300 }, "all, by level")
    P:SetFilter("now")
    t.eq(shownIds(P), { 200, 101 })
    P:SetFilter("known")
    t.eq(shownIds(P), { 100 })
    P:SetFilter("soon")
    t.eq(shownIds(P), { 400, 300 }, "soon and quest")
    P:SetFilter("all")
    t.eq(#shownIds(P), 5)
    -- les puces sont des boutons
    P.ui.chips.known:Click()
    t.eq(P.state.filter, "known")
    t.eq(#Mock.errors, 0)
  end,

  banner_shows_trainer_summary_and_refreshes = function(t)
    local Q = load()
    local P = open(Q)
    local txt = P.ui.trainer:GetText()
    t.ok(txt:find("Thran Khorman", 1, true), txt)
    t.ok(P.ui.summary:GetText():find("3", 1, true), P.ui.summary:GetText())
    -- un sort appris : l'évènement redessine
    known[200] = true
    Mock.fire("SPELLS_CHANGED")
    Mock.advance(Q.Trainer.UPDATE_DELAY + 0.05)
    t.eq(line(P, 200).state:GetText(), Q.L.SPELLS_STATE_KNOWN)
    t.eq(#Mock.errors, 0)
  end,

  showing_pane_invalidates_cache = function(t)
    local Q = load()
    local P = open(Q)
    local n = 0
    local orig = Q.SpellList.Invalidate
    Q.SpellList.Invalidate = function(self) n = n + 1; return orig(self) end
    Q.UI.BuildWindow:Open("build")
    Q.UI.BuildWindow:Open("spells")
    t.ok(n >= 1, "Invalidate called on show")
  end,

  built_after_combat = function(t)
    local Q = load({ combat = true })
    Q.UI.BuildWindow:Open("spells")   -- différé
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    local P = Q.UI.SpellsPane
    t.ok(P.ui, "built after combat")
    t.ok(line(P, 200))
    t.eq(#Mock.errors, 0)
  end,

  pill_count_matches_summary = function(t)
    local w
    -- fenêtre du jeu simulée après le chargement : on relit le crochet
    local Qh
    do
      Ext.install(); Spec.install(); Mock.spec.index = 1
      known = {}
      Mock.player.classFile = "WARRIOR"; Mock.player.level = 10
      Mock.player.raceId, Mock.player.faction = 3, "Alliance"
      Traits.install({ groups = { { name = "G", talents = { { 16035, 1, 3, 5 } } } }, ranks = {}, unspent = 0 })
      C_Spell = { GetSpellName = function(id) return NAMES[id] end, GetSpellTexture = function() return 1 end }
      IsPlayerSpell = function(id) return known[id] == true end
      GetMoney = function() return 100000 end
      PlayerSpellsUtil = { ToggleClassTalentFrame = function() end }
      w = PS.install({ nodes = { 17035 } })
      Qh = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true, qdb = { npcs = TRAINERS },
        beforeLogin = function(Q) Q.ClassSpellData = SPELLS; Q.ClassQuestData = CLASSQ; Q.SpellQuestData = {} end })
      Qh.UI.TalentPopup:Hide()
    end
    local hook = Qh.UI.TalentFrameHook
    PS.open(w)
    local pill = hook.tabs[3].qfPill
    Qh.SpellList:Invalidate()
    Mock.fire("SPELLS_CHANGED")
    Mock.advance(Qh.Trainer.UPDATE_DELAY + 0.05)
    local now = Qh.SpellList:Summary().now
    t.ok(now > 0)
    t.ok(pill:IsShown(), "pill shown")
    t.eq(pill.text:GetText(), tostring(now))
    -- tout appris : la pastille se retire sur l'évènement
    known[200], known[101], known[300], known[400], known[100] = true, true, true, true, true
    Qh.SpellList:Invalidate()
    t.ok(pill:IsShown(), "unchanged before the event")
    t.eq(pill.text:GetText(), tostring(now), "text unchanged before the event")
    Mock.fire("SPELLS_CHANGED")
    Mock.advance(Qh.Trainer.UPDATE_DELAY + 0.05)
    t.ok(not pill:IsShown(), "pill hidden")
    t.eq(#Mock.errors, 0)
  end,
}
