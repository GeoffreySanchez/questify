-- Tests de la liste des sorts (Q.SpellList) : états, coût du maître, sorts de quête, résumé, évènement.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

-- Nain (race 3, bit 4), Alliance, Chaman. Rang 1/2/3 de 100 (niveaux 1/8/20), 200 (niveau 4), un sort
-- de race (Orc seulement) et un sort qui exige une chaîne de quêtes (totem).
local SPELLS = {
  SHAMAN = {
    { spellID = 100, level = 1 },
    { spellID = 101, level = 8, supersedes = 100 },
    { spellID = 102, level = 20, supersedes = 101 },
    { spellID = 200, level = 4 },
    { spellID = 300, level = 1, races = 2 },
    { spellID = 400, level = 4 },
  },
}
local CLASSQ = {
  SHAMAN = {
    { key = "SHAMAN_A", title = "Call of Fire", faction = "Alliance", level = 1, quests = { 9101 }, rewards = {} },
    { key = "SHAMAN_H", title = "Call of Fire H", faction = "Horde", level = 1, quests = { 9201 }, rewards = {} },
  },
}
local NAMES = { [100] = "Bolt", [101] = "Bolt", [102] = "Bolt", [200] = "Shield", [300] = "Orc Thing", [400] = "Fire Totem" }
local RANKS = { [100] = "Rank 1", [101] = "Rank 2", [102] = "Rank 3" }

local known, money

local function load(level)
  Ext.install()
  known, money = {}, 100000
  Mock.player.classFile = "SHAMAN"
  Mock.player.level = level or 10
  Mock.player.raceId, Mock.player.faction = 3, "Alliance"
  C_Spell = { GetSpellName = function(id) return NAMES[id] end, GetSpellSubtext = function(id) return RANKS[id] end }
  IsPlayerSpell = function(id) return known[id] == true end
  GetMoney = function() return money end
  return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true,
    beforeLogin = function(Q)
      Q.ClassSpellData = SPELLS
      Q.ClassQuestData = CLASSQ
      Q.SpellQuestData = { [400] = "SHAMAN_A" }
      Q.SpellQuestChains = { [400] = { "SHAMAN_A", "SHAMAN_H" } }
    end })
end

-- Les tests changent l'état du jeu sans évènement : on vide le cache à la main.
local function rowsOf(Q)
  Q.SpellList:Invalidate()
  return Q.SpellList:Rows()
end

local function byId(rows)
  local out = {}
  for _, r in ipairs(rows) do out[r.spellID] = r end
  return out
end

local function ids(rows)
  local out = {}
  for _, r in ipairs(rows) do out[#out + 1] = r.spellID end
  return out
end

return {
  known_from_game = function(t)
    local Q = load(10)
    known[100] = true
    local rows = rowsOf(Q)
    local r = byId(rows)
    -- rang 1 connu : il reste affiché (plus haut rang connu), rang 2 à apprendre ; rang 3 trop haut
    t.eq(r[100].state, "known")
    t.eq(r[101].state, "now")
    t.eq(r[102].state, "soon")
    t.eq(r[200].state, "now")
    t.eq(r[100].rank, "Rank 1")
    t.eq(r[100].name, "Bolt")
    t.eq(r[300], nil, "Orc-only spell dropped for a Dwarf")
    -- une fois le rang 2 connu, le rang 1 disparaît
    known[101] = true
    t.eq(ids(rowsOf(Q)), { 200, 400, 101, 102 }, "highest known rank only, ordered by level")
    known[200] = true
    t.eq(byId(rowsOf(Q))[200].state, "known")
    t.eq(#Mock.errors, 0)
  end,

  cost_from_trainer_cache_else_nil = function(t)
    local Q = load(10)
    Q.char.trainer = { services = {
      { name = "Bolt", rank = "Rank 2", level = 8, cost = 500 },
      { name = "Shield", level = 4, cost = 120 },
    } }
    local r = byId(rowsOf(Q))
    t.eq(r[101].cost, 500, "match by name and rank")
    t.eq(r[200].cost, 120, "match by name, no rank")
    t.eq(r[102].cost, nil, "not in the cache: unknown")
    t.eq(r[100].cost, nil)
    -- spellID gardé par le relevé : prioritaire sur le nom
    Q.char.trainer.services = { { name = "Other", rank = "Rank 9", level = 8, cost = 77, spellID = 101 } }
    t.eq(byId(rowsOf(Q))[101].cost, 77, "spellID match wins")
  end,

  trainer_full_list_overrides_data = function(t)
    local Q = load(5)
    -- le maître annonce le rang 2 au niveau 4 (la donnée dit 8) : son niveau gagne
    Q.char.trainer = { services = { { name = "Bolt", rank = "Rank 2", level = 4, cost = 90, spellID = 101 } } }
    local r = byId(rowsOf(Q))
    t.eq(r[101].level, 4)
    t.eq(r[101].state, "now")
    t.eq(r[101].cost, 90)
  end,

  quest_spell_states = function(t)
    local Q = load(10)
    local function row() return byId(rowsOf(Q))[400] end
    -- chaîne à venir/disponible : état "quest"
    local r = row()
    t.eq(r.state, "quest")
    t.eq(r.chainKey, "SHAMAN_A", "the Alliance chain for an Alliance player")
    t.eq(r.questState, "available")
    Mock.quests.log[9101] = { complete = false, objectives = {} }
    t.eq(row().questState, "inlog")
    -- chaîne terminée : le sort suit son état normal
    Mock.quests.log[9101] = nil
    Mock.quests.completed[9101] = true
    Mock.fire("QUEST_TURNED_IN", 9101)
    r = row()
    t.eq(r.state, "now")
    t.eq(r.questState, "done")
    known[400] = true
    t.eq(row().state, "known")
  end,

  quest_spell_horde_key_and_upcoming = function(t)
    local Q = load(2)
    Mock.player.faction, Mock.player.raceId = "Horde", 2
    Q.Progress:RefreshPlayer(2)
    local r = byId(rowsOf(Q))[400]
    t.ok(r, "row present")
    t.eq(r.chainKey, "SHAMAN_H", "the Horde chain for a Horde player")
    t.eq(r.state, "quest")
  end,

  summary_counts_now = function(t)
    local Q = load(10)
    Q.char.trainer = { services = {
      { name = "Bolt", rank = "Rank 2", level = 8, cost = 500 },
      { name = "Shield", level = 4, cost = 120 },
      { name = "Bolt", rank = "Rank 3", level = 20, cost = 9000 },
    } }
    known[100] = true
    Q.SpellList:Invalidate()
    local s = Q.SpellList:Summary()
    t.eq(s.now, 2, "Bolt 2 and Shield")
    t.eq(s.cost, 620, "Bolt 3 is soon: not counted")
    t.eq(s.money, 100000)
    t.eq(s.trainer, nil, "no trainer known for the data")
    money = 5
    Q.SpellList:Invalidate()
    t.eq(Q.SpellList:Summary().money, 5)
  end,

  summary_nearest_trainer = function(t)
    local Q = load(10)
    Q.ClassTrainerData = { SHAMAN = { A = { 912 }, H = {} } }
    Q.QDB.Npc = function(_, id)
      if id == 912 then return { name = "Thran", spawns = { [1426] = { { 40, 75 } } } } end
    end
    Q.QDB.NpcName = function(_, id) return id == 912 and "Thran" or nil end
    Q.SpellList:Invalidate()
    local s = Q.SpellList:Summary()
    t.ok(s.trainer, "trainer found")
    t.eq(s.trainer.name, "Thran")
    t.ok(type(s.trainer.zone) == "string")
    t.ok(type(s.trainer.distance) == "number" and s.trainer.distance > 0, "distance in yards")
  end,

  event_relayed_and_debounced = function(t)
    local Q = load(10)
    local n = 0
    Q:On("SPELLS_CHANGED", function() n = n + 1 end)
    Mock.fire("SPELLS_CHANGED")
    Mock.fire("TRAINER_UPDATE")
    Mock.fire("PLAYER_MONEY")
    t.eq(n, 0, "debounced")
    Mock.advance(Q.Trainer.UPDATE_DELAY + 0.05)
    t.eq(n, 1, "one internal event for a burst")
    Mock.fire("PLAYER_LEVEL_UP", 11)
    Mock.fire("LEARNED_SPELL_IN_SKILL_LINE", 100)
    Mock.advance(Q.Trainer.UPDATE_DELAY + 0.05)
    t.eq(n, 2)
    t.eq(#Mock.errors, 0)
  end,

  trainer_reading_keeps_spellid = function(t)
    local Q = load(10)
    GetNumTrainerServices = function() return 2 end
    GetTrainerServiceInfo = function(i)
      if i == 1 then return "Bolt", "available", 1, 8, "Rank 2" end
      return "Unknown", "available", 1, 8, ""
    end
    GetTrainerServiceCost = function() return 500, false end
    IsTradeskillTrainer = function() return false end
    Mock.fire("TRAINER_SHOW")
    local s = Q.char.trainer.services
    t.eq(s[1].spellID, 101, "resolved from class data by name and rank")
    t.eq(s[2].spellID, nil)
  end,

  known_wins_over_pending_quest = function(t)
    local Q = load(10)
    known[400] = true   -- appris (autre voie) alors que la chaîne est encore « available »
    local r = byId(rowsOf(Q))[400]
    t.eq(r.state, "known", "R28: known, not quest")
    t.eq(r.questState, "available")
    t.eq(r.chainKey, "SHAMAN_A")
  end,

  upcoming_and_ignored_map_to_upcoming = function(t)
    local Q = load(10)
    CLASSQ.SHAMAN[1].level = 30   -- chaîne pas encore accessible
    t.eq(byId(rowsOf(Q))[400].questState, "upcoming", "upcoming")
    CLASSQ.SHAMAN[1].level = 1
    Q.ClassQuests:Ignore("SHAMAN_A")
    local r = byId(rowsOf(Q))[400]
    t.eq(r.questState, "upcoming", "ignored")
    t.eq(r.state, "quest")
    Q.ClassQuests:Unignore("SHAMAN_A")
  end,

  rows_cached_until_an_event = function(t)
    local Q = load(10)
    local calls = 0
    C_Spell.GetSpellName = function(id) calls = calls + 1; return NAMES[id] end
    local first = Q.SpellList:Rows()
    local sum = Q.SpellList:Summary()
    t.ok(calls > 0)
    local n = calls
    t.ok(Q.SpellList:Rows() == first, "same table")
    t.ok(Q.SpellList:Summary() == sum, "same summary")
    t.eq(calls, n, "no game call without an event")
    known[100] = true
    Mock.fire("SPELLS_CHANGED")
    local after = Q.SpellList:Rows()
    t.ok(calls > n, "event invalidates")
    t.eq(byId(after)[100].state, "known")
    n = calls
    Q:Fire("TRAINER_CHANGED")
    Q.SpellList:Rows()
    t.ok(calls > n, "TRAINER_CHANGED invalidates")
    n = calls
    Q:Fire("CLASSQUESTS_CHANGED")
    Q.SpellList:Rows()
    t.ok(calls > n, "CLASSQUESTS_CHANGED invalidates")
  end,

  -- M6 : une lecture pendant le délai de l'évènement (état du jeu pas encore à jour) ne reste pas en cache :
  -- le rappel différé remet le cache à sale avant SPELLS_CHANGED.
  deferred_event_redirties_the_cache = function(t)
    local Q = load(10)
    local seen
    Q:On("SPELLS_CHANGED", function() seen = byId(Q.SpellList:Rows())[100].state end)
    Mock.fire("LEARNED_SPELL_IN_SKILL_LINE", 100)
    t.ok(byId(Q.SpellList:Rows())[100].state ~= "known", "read during the delay: not known yet")
    known[100] = true                -- le jeu met IsPlayerSpell à jour un peu après l'évènement
    Mock.advance(Q.Trainer.UPDATE_DELAY + 0.05)
    t.eq(seen, "known", "listeners read fresh rows")
  end,
}
