-- Tests de la simulation de chapitre (sim.lua) et de l'ordonnancement (order.lua) sur la zone synthétique.
local F = require("fixture_zone")
local sim = require("sim")
local order = require("order")

local function run(opts)
  local D, W = F.D(), F.W()
  local state = F.state()
  local steps, report = sim.chapter(D, W, F.plan(), state, opts)
  return steps, report, state
end

-- index de la première étape (action, quête)
local function indexOf(steps, action, q)
  for i, s in ipairs(steps) do
    if s[1] == action and s[2] == q then return i end
  end
end

local function dropped(report, q)
  for _, d in ipairs(report.dropped) do if d.id == q then return d.reason end end
end

local function stepsText(steps)
  local out = {}
  for i, s in ipairs(steps) do
    local parts = {}
    for k = 1, #s do parts[#parts + 1] = tostring(s[k]) end
    out[i] = table.concat(parts, " ")
  end
  return table.concat(out, " | ")
end

return {
  respects_precedence = function(t)
    local steps = run()
    for _, q in ipairs({ 101, 102, 103, 104, 107, 108 }) do
      local a, c, tt = indexOf(steps, "accept", q), indexOf(steps, "complete", q), indexOf(steps, "turnin", q)
      t.ok(a and c and tt, "quest " .. q .. " has accept, complete and turnin: " .. stepsText(steps))
      t.ok(a < c and c < tt, "A < O < T for " .. q)
    end
    t.ok(indexOf(steps, "turnin", 103) < indexOf(steps, "accept", 104), "chain: T103 before A104")
    t.ok(indexOf(steps, "turnin", 105) < indexOf(steps, "accept", 107), "breadcrumb before its target")
  end,

  drops_far_low_xp = function(t)
    local steps, report = run()
    local r = dropped(report, 106)
    t.ok(r == "far" or r == "low ratio", "106 dropped: " .. tostring(r))
    t.eq(indexOf(steps, "accept", 106), nil)
  end,

  keeps_breadcrumb = function(t)
    local steps, report = run()
    t.eq(dropped(report, 105), nil)
    t.ok(indexOf(steps, "accept", 105) and indexOf(steps, "turnin", 105), "breadcrumb in route")
  end,

  log_cap = function(t)
    local steps = run({ logCap = 3 })
    local open, maxOpen = {}, 0
    for _, s in ipairs(steps) do
      if s[1] == "accept" then open[s[2]] = true end
      if s[1] == "turnin" then open[s[2]] = nil end
      local n = 0
      for _ in pairs(open) do n = n + 1 end
      if n > maxOpen then maxOpen = n end
    end
    t.ok(maxOpen <= 3, "max open quests " .. maxOpen)
    t.ok(indexOf(steps, "turnin", 108), "route still complete")
  end,

  hub_batching = function(t)
    local steps = run()
    local hub1 = { [101] = true, [102] = true, [103] = true, [105] = true, [106] = true }
    for i = 1, 3 do
      t.eq(steps[i][1], "accept", "step " .. i .. ": " .. stepsText(steps))
      t.ok(hub1[steps[i][2]], "hub 1 quest")
    end
  end,

  inserts_fp = function(t)
    local steps, _, state = run()
    local fp
    for _, s in ipairs(steps) do if s[1] == "fp" then fp = s end end
    t.ok(fp, "fp step: " .. stepsText(steps))
    t.eq(fp[2], F.MAP)
    t.ok(math.abs(fp[3] - 40) < 0.01 and math.abs(fp[4] - 40) < 0.01, "at the flight master")
    t.ok(state.knownTaxi[501], "node known afterwards")
  end,

  deterministic = function(t)
    local a = stepsText((run()))
    local b = stepsText((run()))
    t.eq(a, b)
  end,

  report_and_state = function(t)
    local _, report, state = run()
    t.ok(report.xpPerHour > 0, "xp/h")
    t.ok(report.endLevel >= 2, "levels up")
    t.ok(state.done[101] and state.done[108], "done quests recorded")
    t.ok(state.time > 0, "time advanced")
    t.ok(#report.quests >= 6, "kept quests listed")
  end,

  accept_waits_for_required_level = function(t)
    local D, W = F.D(), F.W()
    D.quests[104].reqLevel = 5
    local steps, report = sim.chapter(D, W, F.plan(), F.state())
    local i = indexOf(steps, "accept", 104)
    if not i then
      -- quête terminale trop haute : sautée (pas de farm en cours de chapitre), raison dans le rapport
      t.ok(dropped(report, 104) and dropped(report, 104):find("required level", 1, true), "104 skipped with a reason")
      t.eq(indexOf(steps, "turnin", 104), nil, "no turnin of a skipped quest")
      return
    end
    local okLevel = steps[i]._c.simLevel >= 5
    for k = 1, i - 1 do if steps[k][1] == "level" and steps[k][2] >= 5 then okLevel = true end end
    t.ok(okLevel, "accepted at level 5 or after a level step: " .. stepsText(steps))
  end,

  order_nearest_and_constraints = function(t)
    local function P(x) return { x = x } end
    local dist = function(a, b) return math.abs(a.x - b.x) end
    local tasks = {
      { id = "A1", kind = "A", q = 1, pos = P(0), dur = 5, after = {} },
      { id = "O1", kind = "O", q = 1, pos = P(100), dur = 50, after = { "A1" } },
      { id = "T1", kind = "T", q = 1, pos = P(0), dur = 5, after = { "O1" } },
      { id = "A2", kind = "A", q = 2, pos = P(0), dur = 5, after = { "T1" } },
      { id = "O2", kind = "O", q = 2, pos = P(10), dur = 50, after = { "A2" } },
      { id = "T2", kind = "T", q = 2, pos = P(0), dur = 5, after = { "O2" } },
    }
    local seq = order.build(tasks, P(0), dist, { logCap = 20 })
    local pos = {}
    for i, task in ipairs(seq) do pos[task.id] = i end
    t.ok(pos.A1 < pos.O1 and pos.O1 < pos.T1 and pos.T1 < pos.A2, "precedence kept")
    t.eq(#seq, 6)
  end,

  -- Lot L : une quête de donjon prise au passage (jamais rendue) n'ouvre pas sa suite hors du donjon.
  dungeon_pickup_is_not_a_prerequisite = function(t)
    local D, W = F.D(), F.W()
    D.dungeonAreas[9100] = "Fixture Deeps"
    local deep = D.quests[103]
    D.quests[110] = { }
    for k, v in pairs(deep) do D.quests[110][k] = v end
    D.quests[110].id, D.quests[110].name, D.quests[110].zoneOrSort = 110, "Into the Deeps", 9100
    D.quests[111] = { }
    for k, v in pairs(D.quests[101]) do D.quests[111][k] = v end
    D.quests[111].id, D.quests[111].name, D.quests[111].preSingle = 111, "Back from the Deeps", { 110 }
    D.xp[111] = { 4, 900 }
    D.unlocks[110] = { 111 }
    local plan = F.plan()
    plan.dungeons = { "Fixture Deeps" }
    local steps, report = sim.chapter(D, W, plan, F.state())
    local i = indexOf(steps, "accept", 110)
    t.ok(i, "dungeon quest picked up: " .. stepsText(steps))
    t.eq(steps[i].optional, true); t.eq(steps[i].dungeon, "Fixture Deeps")
    t.eq(indexOf(steps, "turnin", 110), nil, "never turned in")
    t.eq(indexOf(steps, "accept", 111), nil, "follow-up not offered")
    t.eq(dropped(report, 111), "prerequisite unavailable")
  end,

  -- Lot L : quêtes « event » (specialFlags 2) sans point d'exploration : récit chez le donneur ou objectif
  -- placé par QuestieDB gardés ; escortes écartées.
  event_quests_kept_unless_escort = function(t)
    local D, W = F.D(), F.W()
    local function copy(id, newId, fields)
      local q = {}
      for k, v in pairs(D.quests[id]) do q[k] = v end
      q.id = newId
      for k, v in pairs(fields) do q[k] = v end
      D.quests[newId] = q
      D.xp[newId] = { 3, 400 }
    end
    -- récit : objectif « tuer » le donneur lui-même (PNJ amical) -> objectif « parler »
    copy(101, 112, { name = "Listen to Giver One", specialFlags = 2, objectivesText = { "Listen as Giver One tells his story." },
      objectives = { creatures = { 1001 }, killCredit = {}, objects = {}, items = {}, list = { { kind = "kill", id = 1001, index = 1 } } } })
    -- récit sans objectif, rendu au donneur
    copy(101, 113, { name = "In a Moment", specialFlags = 2, objectivesText = { "Speak with Giver One in a moment." },
      objectives = { creatures = {}, killCredit = {}, objects = {}, items = {}, list = {} } })
    -- escorte sans point d'arrivée
    copy(101, 114, { name = "Wolf Escort", specialFlags = 2, objectivesText = { "Escort the old wolf back to Giver One." } })
    local steps, report = sim.chapter(D, W, F.plan(), F.state())
    for _, q in ipairs({ 112, 113 }) do
      t.ok(indexOf(steps, "accept", q) and indexOf(steps, "turnin", q), "event quest " .. q .. " kept: " .. stepsText(steps))
    end
    local c = steps[indexOf(steps, "complete", 113)]
    t.ok(c and c.at and math.abs(c.at[2] - 20) < 0.01 and math.abs(c.at[3] - 20) < 0.01, "113 waits at the giver")
    t.eq(dropped(report, 114), "event (escort)")
    t.eq(indexOf(steps, "accept", 114), nil)
  end,

  escort_text = function(t)
    local function q(text) return { objectivesText = { text } } end
    t.ok(sim.isEscort(q("Escort Kinelory safely to Quae.")))
    t.ok(sim.isEscort(q("Protect Kanati Greycloud from the centaur attack.")))
    t.ok(sim.isEscort(q("Defend Gor'shak.")))
    t.ok(sim.isEscort(q("Show Tooga the way back to his wife, Torta.")))
    t.ok(sim.isEscort(q("Lead Ringo to Spraggle Frock.")))
    t.ok(not sim.isEscort(q("Listen as Kalaran Windblade tells his story.")))
    t.ok(not sim.isEscort(q("Defeat Dashel Stonefist in Stormwind.")))
    t.ok(not sim.isEscort(q("Discover the location of the Northern Crystal Pylon in Un'Goro Crater.")))
  end,
  -- Lot L : quête d'un autre parcours de race ("foreign", build.mergeStates) rendue dans le chapitre, sans XP
  -- pour la race simulée ni « faite » pour elle.
  foreign_quest_turned_in_without_xp = function(t)
    local D, W = F.D(), F.W()
    local q = {}
    for k, v in pairs(D.quests[105]) do q[k] = v end
    q.id, q.name, q.breadcrumbFor = 120, "Letter from Elsewhere", nil
    q.finishers = { npcs = { 1001 }, objects = {} }
    D.quests[120] = q
    D.xp[120] = { 3, 400 }
    local state = F.state()
    state.log[120] = "foreign"
    local steps, report = sim.chapter(D, W, F.plan(), state)
    t.ok(indexOf(steps, "turnin", 120), "turned in: " .. stepsText(steps))
    for _, r in ipairs(report.quests) do t.ok(r.id ~= 120, "no XP for the simulated race") end
    t.eq(state.log[120], nil, "left the log")
    t.eq(state.done[120], nil, "not done for the simulated race")
  end,
}
