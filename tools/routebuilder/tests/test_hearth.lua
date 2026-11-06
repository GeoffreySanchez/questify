-- Tests de la pierre de foyer dans l'ordonnancement (order.hearthCost, order.hearthBundles) et des champs de
-- plan precede / safeLevel, plus la règle des pré-requis rendus depuis le journal (sim.chapter).
local F = require("fixture_zone")
local sim = require("sim")
local order = require("order")

local function P(x) return { x = x } end
-- distance en centièmes de seconde (1 unité de x = 1 s de marche)
local function dist(a, b) return math.abs(a.x - b.x) * 100 end
local function base(o)
  local t = { start = P(0), dist = dist, cd = 3600 * 100, use = 130 * 100, real = 25 * 100, bindDur = 500,
              dur = function() return 0 end, radius = 20 * 100 }
  for k, v in pairs(o or {}) do t[k] = v end
  return t
end

local function indexOf(steps, action, q)
  for i, s in ipairs(steps) do if s[1] == action and s[2] == q then return i end end
end

return {
  -- retour par la pierre : pris si incantation + pénalité + marche depuis l'auberge < marche directe
  hearth_cost_uses_stone_on_long_return = function(t)
    local seq = { { id = "O1", pos = P(1000) }, { id = "T1", pos = P(5) } }
    local walkOnly = order.hearthCost(seq, base())
    t.eq(walkOnly, (1000 + 995) * 100, "no inn: walking only")
    local c, uses, at, fin = order.hearthCost(seq, base({ inn = P(0), ready = 0 }))
    t.eq(uses, 1, "one return")
    t.eq(at[1], 2, "the leg to T1 takes the stone")
    t.eq(c, (1000 + 25 + 5) * 100, "real cost: walk out, cast + load, walk from the inn")
    t.ok(fin.ready > fin.time, "stone on cooldown at the end")
  end,

  -- la pénalité garde la pierre pour un retour qui en vaut la peine ; la recharge interdit un second retour
  hearth_cost_penalty_and_cooldown = function(t)
    local short = { { id = "O1", pos = P(100) }, { id = "T1", pos = P(0) } }
    local _, uses = order.hearthCost(short, base({ inn = P(0), ready = 0 }))
    t.eq(uses, 0, "100 s of walking: not worth the stone")
    local twice = { { id = "O1", pos = P(1000) }, { id = "T1", pos = P(0) }, { id = "O2", pos = P(1000) }, { id = "T2", pos = P(0) } }
    local _, n = order.hearthCost(twice, base({ inn = P(0), ready = 0 }))
    t.eq(n, 1, "second return within the hour: on foot")
  end,

  -- liaison après une tâche : détour vers l'auberge compté, pierre utilisable ensuite
  hearth_cost_bind_after_task = function(t)
    local seq = { { id = "A1", pos = P(500) }, { id = "O1", pos = P(1500) }, { id = "T1", pos = P(510) } }
    local c, uses = order.hearthCost(seq, base({ binds = { A1 = P(505) } }))
    t.eq(uses, 1, "stone bound at the hub, then used")
    t.eq(c, (500 + 5 + 995 + 25 + 5) * 100 + 500, "walk, bind detour and action, out, stone, last steps")
  end,

  -- paquet : un rendu à l'auberge fait après un détour est ramené juste après un retour par la pierre
  hearth_bundle_pulls_inn_tasks_after_return = function(t)
    local tasks = {
      { id = "A1", kind = "A", pos = P(0), after = {} },
      { id = "O1", kind = "O", pos = P(2000), after = { "A1" } },
      { id = "Z", kind = "O", pos = P(300), after = {} },
      { id = "T1", kind = "T", pos = P(0), after = { "O1" } },
    }
    local ids = {}
    for _, x in ipairs(tasks) do ids[x.id] = true end
    local fopts = { logCap = 20, ids = ids }
    local o = base({ inn = P(0), ready = 0 })
    local before = order.hearthCost(tasks, o)
    t.eq(before, (2000 + 25 + 300 + 300) * 100, "stone taken towards Z, T1 reached on foot")
    local out, n = order.hearthBundles(tasks, o, fopts)
    t.eq(n, 1, "one bundle")
    t.eq(out[3].id, "T1", "turn-in right after the return: " .. out[1].id .. out[2].id .. out[3].id .. out[4].id)
    t.eq(order.hearthCost(out, o), (2000 + 25 + 300) * 100, "300 s saved")
    t.ok(order.feasible(out, fopts), "precedence kept")
  end,

  -- plan.precede : la prise demandée passe avant l'objectif d'une autre quête
  plan_precede_orders_tasks = function(t)
    local D, W = F.D(), F.W()
    local plan = F.plan()
    plan.precede = { { "T108", "A101" } }
    local steps, report = sim.chapter(D, W, plan, F.state())
    local tt, a = indexOf(steps, "turnin", 108), indexOf(steps, "accept", 101)
    t.ok(tt and a and tt < a, "turnin 108 before accept 101")
    plan.precede = { { "T999", "A101" } }
    local _, rep2 = sim.chapter(F.D(), F.W(), plan, F.state())
    local warned = false
    for _, w in ipairs(rep2.warnings) do if w:find("precede T999", 1, true) then warned = true end end
    t.ok(warned, "missing task reported")
    t.ok(report, "report")
  end,

  -- plan.safeLevel : l'objectif est fait dès ce niveau (remplace le niveau « sûr » calculé)
  plan_safe_level_replaces_computed_gate = function(t)
    local function gate(safe)
      local D, W = F.D(), F.W()
      D.quests[107].level = 12 -- niveau « sûr » calculé : 11
      local plan = F.plan()
      plan.safeLevel = safe
      local _, report = sim.chapter(D, W, plan, F.state(), { anneal = false })
      for _, l in ipairs(report.legs) do
        if l.kind == "O" and l.q == 107 then return l.task.reqLevel or 0 end
      end
    end
    t.eq(gate(nil), 11, "computed safe level")
    t.eq(gate({ [107] = 3 }), 3, "plan value")
  end,

  -- pré-requis rendu dans ce chapitre depuis le journal du chapitre précédent : la suite reste candidate
  prerequisite_turned_in_from_log = function(t)
    local D, W = F.D(), F.W()
    local state = F.state()
    state.log[103] = true -- 103 faite au chapitre précédent, rendue ici
    local steps, report = sim.chapter(D, W, F.plan(), state)
    for _, d in ipairs(report.dropped) do
      t.ok(not (d.id == 104 and d.reason:find("prerequisite", 1, true)), "104 kept: " .. tostring(d.reason))
    end
    local tt, a = indexOf(steps, "turnin", 103), indexOf(steps, "accept", 104)
    t.ok(tt and a and tt < a, "turn-in of 103 before accept of 104")
  end,
}
