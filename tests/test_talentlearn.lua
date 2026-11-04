-- Tests de l'achat des talents d'un build (Q.TalentLearn) : achats, validation unique, combat, retour arrière.
local TOC = "Questify/Questify.toc"

local function load(opts)
  local Traits = dofile(Mock.root .. "/tests/mock_ext_traits.lua")
  local traits = Traits.install{ groups = { { name = "Élémentaire", talents = { { 16035, 1, 3, 5 } } } } }
  Traits.installLearn(traits, opts)
  local Q = Mock.loadAddon(TOC, { skipGuides = true })
  return Q, traits
end

local function fakeTree() return { configID = 7001, nodes = {} } end
local function due(n)
  local out = {}
  for i = 1, n do out[i] = { spellID = 16035, node = { nodeID = 100 + i, entryID = 200 + i }, rank = i, level = 9 + i } end
  return out
end

return {
  learn_buys_then_commits_once = function(t)
    local Q = load{ savedConfigID = 555 }
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(3)), "ok")
    t.eq(Mock.countCalls("PurchaseRank"), 3)
    t.eq(Mock.countCalls("CommitConfig"), 1)
    t.eq(Mock.countCalls("RollbackConfig"), 0)
    t.eq(Mock.lastCall("PurchaseRank").args, { 7001, 103 })
    t.eq(Mock.lastCall("CommitConfig").args[1], 555)
    t.eq(Mock.lastCall("GetLastSelectedSavedConfigID").args[1], 262)
    t.ok(Q.TalentLearn:IsAvailable())
  end,

  learn_commits_with_nil_saved_config = function(t)
    local Q = load()
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(1)), "ok")
    t.eq(Mock.countCalls("CommitConfig"), 1)
    t.eq(Mock.lastCall("CommitConfig").args[1], nil)
  end,

  learn_refuses_in_combat = function(t)
    local Q = load()
    Mock.player.combat = true
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(2)), "combat")
    t.eq(Mock.countCalls("PurchaseRank"), 0)
    t.eq(Mock.countCalls("CommitConfig"), 0)
    t.ok(Q.TalentLearn:IsAvailable())
  end,

  learn_rolls_back_on_failure = function(t)
    local Q = load{ failPurchaseAt = 2 }
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(3)), "failed")
    t.eq(Mock.countCalls("RollbackConfig"), 1)
    t.eq(Mock.lastCall("RollbackConfig").args[1], 7001)
    t.eq(Mock.countCalls("CommitConfig"), 0)
    t.ok(not Q.TalentLearn:IsAvailable())
    local before = Mock.countCalls("PurchaseRank")
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(3)), "unavailable")
    t.eq(Mock.countCalls("PurchaseRank"), before)
  end,

  learn_rolls_back_on_commit_failure = function(t)
    local Q = load{ failCommit = true }
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(2)), "failed")
    t.eq(Mock.countCalls("RollbackConfig"), 1)
    t.ok(not Q.TalentLearn:IsAvailable())
  end,

  learn_rolls_back_on_error = function(t)
    local Q = load{ throwPurchase = true }
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(2)), "failed")
    t.eq(Mock.countCalls("RollbackConfig"), 1)
    t.ok(not Q.TalentLearn:IsAvailable())
  end,

  learn_unavailable_without_api = function(t)
    local Q = load()
    C_Traits.PurchaseRank = nil
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(1)), "unavailable")
    t.eq(Mock.countCalls("CommitConfig"), 0)
  end,

  learn_nothing_due_does_nothing = function(t)
    local Q = load()
    t.eq(Q.TalentLearn:Learn(fakeTree(), {}), "ok")
    t.eq(Mock.countCalls("CommitConfig"), 0)
  end,

  last_error_on_false_purchase = function(t)
    local Q = load{ failPurchaseAt = 2 }
    Q.TalentLearn:Learn(fakeTree(), due(3))
    t.eq(Q.TalentLearn.lastError, "PurchaseRank 102: false")
  end,

  last_error_on_thrown_commit = function(t)
    local Q = load{ throwCommit = true }
    Q.TalentLearn:Learn(fakeTree(), due(1))
    t.ok(Q.TalentLearn.lastError:find("CommitConfig: ", 1, true) == 1)
    t.ok(Q.TalentLearn.lastError:find("CommitConfig boom", 1, true) ~= nil)
  end,

  report_shows_unavailable_reason = function(t)
    local Q = load{ failPurchaseAt = 1 }
    Q.TalentLearn:Learn(fakeTree(), due(1))
    t.ok(Q.Diagnostics:Report():find("Talent learning: unavailable (PurchaseRank 101: false)", 1, true) ~= nil)
  end,

  -- I4 : points en attente (posés par le joueur) : rien n'est acheté, l'apprentissage reste possible.
  learn_refuses_with_staged_points = function(t)
    local Q, traits = load()
    traits.staged[16035] = 1
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(1)), "staged")
    t.eq(Mock.countCalls("PurchaseRank"), 0)
    t.eq(Mock.countCalls("CommitConfig"), 0)
    t.eq(Mock.countCalls("RollbackConfig"), 0)
    t.ok(Q.TalentLearn:IsAvailable())
  end,

  -- I4 : réussite annoncée à TRAIT_CONFIG_UPDATED de la configuration (fin de la validation), pas avant ;
  -- CONFIG_COMMIT_FAILED : échec, sans couper l'apprentissage pour la session.
  learn_result_follows_commit_events = function(t)
    local Q = load()
    local got = {}
    Q:On("TALENT_COMMIT", function(result, list) got[#got + 1] = { result, #list } end)
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(2)), "ok")
    t.eq(got, {}, "not before the commit ends")
    Mock.fire("TRAIT_CONFIG_UPDATED", 9999)
    t.eq(got, {}, "another configuration")
    Mock.fire("TRAIT_CONFIG_UPDATED", 7001)
    t.eq(got, { { "done", 2 } })
    Mock.fire("TRAIT_CONFIG_UPDATED", 7001)
    t.eq(#got, 1, "once")
    t.eq(Q.TalentLearn:Learn(fakeTree(), due(1)), "ok")
    Mock.fire("CONFIG_COMMIT_FAILED", 7001)
    t.eq(got[2], { "failed", 1 })
    t.ok(Q.TalentLearn:IsAvailable(), "learning not cut for the session")
    t.eq(Mock.countCalls("RollbackConfig"), 0)
    t.ok(Q.Diagnostics:Report():find("CONFIG_COMMIT_FAILED", 1, true), "reason kept for /qf bug")
  end,
}
