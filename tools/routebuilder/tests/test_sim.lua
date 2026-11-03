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
}
