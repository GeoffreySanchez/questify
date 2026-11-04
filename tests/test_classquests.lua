-- Tests des quêtes de classe (Q.ClassQuests) : liste, alerte, ajout, abandon, fin de chaîne.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

-- Données de test : on ne dépend pas du fichier généré, que le générateur réécrit.
local ALLIANCE = 4294967373
local DATA = {
  WARLOCK = {
    { key = "WARLOCK_1598", title = "The Stolen Tome", faction = "Alliance", races = ALLIANCE, level = 1,
      quests = { 1598, 1599 }, rewards = { [1598] = { items = { 6785 }, xp = 355 }, [1599] = { items = {}, xp = 355 } } },
    { key = "WARLOCK_HORDE", title = "Horde chain", faction = "Horde", level = 1, quests = { 9001 }, rewards = {} },
    { key = "WARLOCK_HUMAN", title = "Human only", faction = "Alliance", races = 1, level = 1, quests = { 9002 },
      rewards = {} },
    { key = "WARLOCK_LATE", title = "Late chain", faction = "Alliance", level = 10, quests = { 9003 }, rewards = {} },
    -- 3365 demande 3364 (préquête) : disponible seulement quand 3364 est rendue
    { key = "WARLOCK_PREREQ", title = "Needs 3364", level = 1, quests = { 3365 }, rewards = {} },
  },
  MAGE = {
    { key = "MAGE_1", title = "Mage chain", level = 1, quests = { 9100 }, rewards = {} },
  },
}

local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  opts.beforeLogin = function(Q) Q.ClassQuestData = DATA end
  return Mock.loadAddon(TOC, opts)
end

local function warlock() Mock.player.classFile = "WARLOCK" end

local function keys(rows)
  local out = {}
  for _, r in ipairs(rows) do out[#out + 1] = r.chain.key end
  return out
end

local function stateOf(Q, key)
  for _, r in ipairs(Q.ClassQuests:List()) do if r.chain.key == key then return r.state end end
end

local function turnIn(id)
  Mock.quests.log[id] = nil
  Mock.quests.completed[id] = true
  Mock.fire("QUEST_TURNED_IN", id)
end

local function noCQErrors(t)
  for _, e in ipairs(Mock.errors) do
    local s = tostring(e)
    t.ok(not (s:find("ClassQuests.lua", 1, true) or s:find("Telemetry.lua", 1, true)), "class quest error: " .. s)
  end
end

return {
  warlock_chain_listed_for_warlock_only = function(t)
    warlock()
    local Q = load()
    -- Alliance et Nain : ni la chaîne Horde, ni celle des seuls Humains
    t.eq(keys(Q.ClassQuests:List()), { "WARLOCK_1598", "WARLOCK_LATE", "WARLOCK_PREREQ" })
    Mock.reset()   -- guerrier par défaut
    local Q2 = load()
    t.eq(Q2.ClassQuests:List(), {})
    Mock.reset()
    Mock.player.classFile = "MAGE"
    local Q3 = load()
    t.eq(keys(Q3.ClassQuests:List()), { "MAGE_1" })
  end,

  list_filters_faction_and_races = function(t)
    warlock()
    Mock.player.raceId, Mock.player.faction = 1, "Alliance"   -- Humain
    local Q = load()
    t.eq(keys(Q.ClassQuests:List()), { "WARLOCK_1598", "WARLOCK_HUMAN", "WARLOCK_LATE", "WARLOCK_PREREQ" })
    Mock.reset()
    warlock()
    Mock.player.raceId, Mock.player.faction = 2, "Horde"      -- Orc
    local Q2 = load()
    t.eq(keys(Q2.ClassQuests:List()), { "WARLOCK_HORDE", "WARLOCK_PREREQ" }, "a chain without faction is for everyone")
  end,

  list_states = function(t)
    warlock()
    local Q = load()
    t.eq(stateOf(Q, "WARLOCK_1598"), "available")
    t.eq(stateOf(Q, "WARLOCK_LATE"), "upcoming", "level 10 needed")
    t.eq(stateOf(Q, "WARLOCK_PREREQ"), "upcoming", "prerequisite 3364 not done")
    turnIn(3364)
    t.eq(stateOf(Q, "WARLOCK_PREREQ"), "available", "prerequisite done")
    Mock.player.level = 10
    Mock.fire("PLAYER_LEVEL_UP", 10)
    t.eq(stateOf(Q, "WARLOCK_LATE"), "available")
    -- quête dans le journal : en cours, même si la chaîne est ajoutée
    Mock.quests.log[1598] = { complete = false, objectives = {} }
    Mock.fire("QUEST_ACCEPTED", 1598)
    t.eq(stateOf(Q, "WARLOCK_1598"), "inprogress")
    Q.ClassQuests:Add("WARLOCK_1598")
    t.eq(stateOf(Q, "WARLOCK_1598"), "inprogress", "in progress wins over added")
    -- dernière quête rendue : faite
    turnIn(1598); turnIn(1599)
    t.eq(stateOf(Q, "WARLOCK_1598"), "done")
    t.eq(#Q.ClassQuests:Alerts(), 2, "late and prereq chains are available, 1598 is done")
  end,

  available_raises_alert_once = function(t)
    warlock()
    local Q = load()
    local alerts = Q.ClassQuests:Alerts()
    t.eq(#alerts, 1)
    t.eq(alerts[1].chain.key, "WARLOCK_1598"); t.eq(alerts[1].state, "available")
    Q.ClassQuests:MarkSeen("WARLOCK_1598")
    t.eq(#Q.ClassQuests:Alerts(), 0, "seen")
    t.eq(Q.char.classQuests.seen.WARLOCK_1598, true)
    -- l'alerte ne revient pas quand une autre chaîne devient disponible : seule la nouvelle sort
    Mock.player.level = 10
    Mock.fire("PLAYER_LEVEL_UP", 10)
    local after = Q.ClassQuests:Alerts()
    t.eq(#after, 1); t.eq(after[1].chain.key, "WARLOCK_LATE")
  end,

  add_inserts_steps_before_route = function(t)
    warlock()
    local Q = load()
    local before = Q.Progress:Current().key
    t.ok(before:sub(1, 2) == "g:", "route step first")
    local changed = 0
    Q:On("CLASSQUESTS_CHANGED", function() changed = changed + 1 end)
    t.eq(Q.ClassQuests:Add("WARLOCK_1598"), true)
    local cur = Q.Progress:Current()
    t.eq(cur.key:sub(1, 5), "i:cq:", "chain steps come first")
    t.eq(cur.key, "i:cq:WARLOCK_1598:1")
    t.eq(cur.step.action, "accept"); t.eq(cur.step.questId, 1598)
    t.eq(changed, 1)
    t.eq(Q.char.classQuests.added.WARLOCK_1598, true)
    t.eq(stateOf(Q, "WARLOCK_1598"), "added")
    -- 3 étapes par quête
    local n = 0
    for _, e in ipairs(Q.Progress:Entries()) do if e.tag == "cq:WARLOCK_1598" then n = n + 1 end end
    t.eq(n, 6)
    -- et la navigation y va : cible du PNJ de prise (Drusilla La Salle, Elwynn)
    local target = Q.Targets:ForEntry(cur)
    t.eq(target.id, 459)
    noCQErrors(t)
  end,

  add_skips_quests_already_turned_in = function(t)
    warlock()
    local Q = load()
    turnIn(1598)
    t.eq(Q.ClassQuests:Add("WARLOCK_1598"), true)
    local n = 0
    for _, e in ipairs(Q.Progress:Entries()) do
      if e.tag == "cq:WARLOCK_1598" then n = n + 1; t.eq(e.step.questId, 1599) end
    end
    t.eq(n, 3)
  end,

  add_refuses_unknown_and_other_class_chains = function(t)
    warlock()
    local Q = load()
    t.eq(Q.ClassQuests:Add("NOPE"), false)
    t.eq(Q.ClassQuests:Add("MAGE_1"), false, "not the player's class")
    t.eq(Q.ClassQuests:Add("WARLOCK_HORDE"), false, "not the player's faction")
    t.eq(Q.ClassQuests:Add(nil), false)
    turnIn(1598); turnIn(1599)
    t.eq(Q.ClassQuests:Add("WARLOCK_1598"), false, "nothing left to do")
    t.eq(#Q.char.inserted, 0)
  end,

  ignore_removes_steps = function(t)
    warlock()
    local Q = load()
    Q.ClassQuests:Add("WARLOCK_1598")
    local changed = 0
    Q:On("CLASSQUESTS_CHANGED", function() changed = changed + 1 end)
    t.eq(Q.ClassQuests:Ignore("WARLOCK_1598"), true)
    t.eq(Q.Progress:Current().key:sub(1, 2), "g:", "back to the route")
    t.eq(#Q.char.inserted, 0)
    t.eq(Q.char.classQuests.ignored.WARLOCK_1598, true)
    t.eq(Q.char.classQuests.added.WARLOCK_1598, nil)
    t.eq(stateOf(Q, "WARLOCK_1598"), "ignored")
    t.eq(#Q.ClassQuests:Alerts(), 0, "an ignored chain does not alert")
    t.eq(changed, 1)
    -- ignorer sans avoir ajouté fonctionne aussi
    t.eq(Q.ClassQuests:Ignore("WARLOCK_LATE"), true)
    t.eq(stateOf(Q, "WARLOCK_LATE"), "ignored")
    t.eq(Q.ClassQuests:Ignore("NOPE"), false)
  end,

  unignore_lists_again = function(t)
    warlock()
    local Q = load()
    Q.ClassQuests:Ignore("WARLOCK_1598")
    t.eq(stateOf(Q, "WARLOCK_1598"), "ignored")
    local changed = 0
    Q:On("CLASSQUESTS_CHANGED", function() changed = changed + 1 end)
    t.eq(Q.ClassQuests:Unignore("WARLOCK_1598"), true)
    t.eq(stateOf(Q, "WARLOCK_1598"), "available")
    t.eq(Q.char.classQuests.ignored.WARLOCK_1598, nil)
    t.eq(#Q.ClassQuests:Alerts(), 1, "listed again")
    t.eq(changed, 1)
    t.eq(Q.ClassQuests:Unignore("WARLOCK_1598"), false, "was not ignored")
    -- Add après Ignore : sort de la liste des ignorées
    Q.ClassQuests:Ignore("WARLOCK_1598")
    Q.ClassQuests:Add("WARLOCK_1598")
    t.eq(Q.char.classQuests.ignored.WARLOCK_1598, nil)
    t.eq(stateOf(Q, "WARLOCK_1598"), "added")
  end,

  chain_done_removes_insert = function(t)
    warlock()
    local Q = load()
    Q.ClassQuests:Add("WARLOCK_1598")
    local changed = 0
    Q:On("CLASSQUESTS_CHANGED", function() changed = changed + 1 end)
    -- première quête faite : la chaîne reste (la seconde n'est pas rendue)
    Mock.quests.log[1598] = { complete = true, objectives = {} }
    Mock.fire("QUEST_ACCEPTED", 1598)
    turnIn(1598)
    t.eq(#Q.char.inserted, 1)
    t.eq(changed, 0)
    Mock.quests.log[1599] = { complete = true, objectives = {} }
    Mock.fire("QUEST_ACCEPTED", 1599)
    turnIn(1599)
    t.eq(#Q.char.inserted, 0, "inserted steps removed")
    t.eq(changed, 1, "CLASSQUESTS_CHANGED fired")
    t.eq(Q.Progress:Current().key:sub(1, 2), "g:", "the route resumes")
    t.eq(stateOf(Q, "WARLOCK_1598"), "done")
    t.eq(Q.char.classQuests.added.WARLOCK_1598, nil)
    noCQErrors(t)
  end,

  chain_finishes_when_its_last_quest_is_turned_in = function(t)
    warlock()
    local Q = load()
    Q.ClassQuests:Add("WARLOCK_1598")
    local changed = 0
    Q:On("CLASSQUESTS_CHANGED", function() changed = changed + 1 end)
    -- la dernière quête est rendue sans passer par les premières étapes (rendue ailleurs, par exemple)
    turnIn(1599)
    t.eq(#Q.char.inserted, 0, "inserted steps removed")
    t.eq(changed, 1)
    t.eq(stateOf(Q, "WARLOCK_1598"), "done")
    t.eq(Q.char.classQuests.added.WARLOCK_1598, nil)
    t.eq(Q.Progress:Current().key:sub(1, 2), "g:")
  end,

  chain_finishes_when_the_remaining_steps_are_skipped = function(t)
    warlock()
    local Q = load()
    Q.ClassQuests:Add("WARLOCK_1598")
    local changed = 0
    Q:On("CLASSQUESTS_CHANGED", function() changed = changed + 1 end)
    -- le joueur passe les étapes une à une : la chaîne reste tant qu'il en reste une à faire.
    -- (« faire » et « rendre » de 1599 sont sautées d'office : la quête n'est pas dans le journal)
    for i = 1, 3 do
      Q.Progress:Skip("i:cq:WARLOCK_1598:" .. i)
      t.eq(#Q.char.inserted, 1, "still one step to do after " .. i)
    end
    t.eq(changed, 0)
    Q.Progress:Skip("i:cq:WARLOCK_1598:4")
    t.eq(#Q.char.inserted, 0, "nothing left to do")
    t.eq(changed, 1)
    t.eq(Q.char.classQuests.added.WARLOCK_1598, nil)
    t.eq(Q.Progress:Current().key:sub(1, 2), "g:")
    noCQErrors(t)
  end,

  chain_with_an_active_step_stays = function(t)
    warlock()
    local Q = load()
    Q.ClassQuests:Add("WARLOCK_1598")
    turnIn(1598)   -- la première quête est faite, la seconde reste à faire
    t.eq(#Q.char.inserted, 1)
    t.eq(Q.Progress:Current().key, "i:cq:WARLOCK_1598:4")
  end,

  added_chain_survives_reload = function(t)
    warlock()
    local Q = load()
    Q.ClassQuests:Add("WARLOCK_1598")
    local Q2 = Mock.reload()
    t.eq(stateOf(Q2, "WARLOCK_1598"), "added")
    t.eq(Q2.Progress:Current().key, "i:cq:WARLOCK_1598:1")
    Q2.ClassQuests:MarkSeen("WARLOCK_1598")
    local Q3 = Mock.reload()
    t.eq(Q3.char.classQuests.seen.WARLOCK_1598, true)
  end,

  list_is_empty_without_questiedb = function(t)
    warlock()
    Mock.addons.QuestieDB = false
    local Q = load()
    t.eq(Q.ClassQuests:List(), {})
    t.eq(Q.ClassQuests:Alerts(), {})
    t.eq(Q.ClassQuests:Add("WARLOCK_1598"), false)
  end,

  survives_missing_or_broken_data = function(t)
    warlock()
    local Q = load()
    Q.ClassQuestData = nil
    t.eq(Q.ClassQuests:List(), {})
    Q.ClassQuestData = { WARLOCK = { "garbage", { key = 5 }, { key = "NOQUESTS" } } }
    t.eq(Q.ClassQuests:List(), {})
    noCQErrors(t)
  end,

  shipped_data_has_the_expected_shape = function(t)
    -- Le fichier livré (placeholder ou généré) respecte le contrat de données.
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES } })
    local data = Q.ClassQuestData
    t.eq(type(data), "table")
    local count = 0
    for classFile, chains in pairs(data) do
      t.eq(type(classFile), "string")
      for _, chain in ipairs(chains) do
        count = count + 1
        t.eq(type(chain.key), "string"); t.eq(type(chain.title), "string"); t.eq(type(chain.level), "number")
        t.ok(chain.faction == nil or chain.faction == "Alliance" or chain.faction == "Horde", "faction")
        t.ok(chain.races == nil or type(chain.races) == "number", "races")
        t.ok(type(chain.quests) == "table" and #chain.quests > 0, "quests")
        for _, id in ipairs(chain.quests) do t.eq(type(id), "number") end
        t.eq(type(chain.rewards), "table")
        for id, reward in pairs(chain.rewards) do
          t.eq(type(id), "number"); t.eq(type(reward.items), "table")
          t.ok(reward.xp == nil or type(reward.xp) == "number", "xp")
        end
      end
    end
    t.ok(count > 0, "at least one chain")
    t.ok(data.WARLOCK ~= nil, "a Warlock chain")
  end,
}
