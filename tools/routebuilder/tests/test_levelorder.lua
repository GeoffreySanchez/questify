-- Tests du farm compté dans l'ordonnancement (plan.strictLevel -> opts.grindCost), du nœud de
-- destination des étapes `fly` (émetteur, validateur) et des étapes d'arrivée `arrive.via`.
local H = require("helpers")
local order = require("order")
local emit = require("emit")

local function P(x) return { x = x } end
local dist = function(a, b) return math.abs(a.x - b.x) end
local LEVEL_XP = { [1] = 1000, [2] = 1000, [3] = 1000, [4] = 1000, [5] = 1000 }

-- Deux quêtes à droite donnent les niveaux 2 et 3 ; un objectif tout près du départ demande le
-- niveau 4, jamais atteint : l'impasse le marque `needLevel` (farm avant).
local function scenario()
  return {
    { id = "A1", kind = "A", q = 1, pos = P(10), dur = 5, after = {} },
    { id = "T1", kind = "T", q = 1, pos = P(20), dur = 5, after = { "A1" }, gain = function() return 1000 end },
    { id = "A2", kind = "A", q = 2, pos = P(30), dur = 5, after = {} },
    { id = "T2", kind = "T", q = 2, pos = P(40), dur = 5, after = { "A2" }, gain = function() return 1000 end },
    { id = "O3", kind = "O", q = 3, pos = P(5), dur = 5, after = {}, reqLevel = 4, safeLevel = true },
  }
end

local function indexOf(seq, id)
  for i, t in ipairs(seq) do if t.id == id then return i end end
end

-- XP manquante, 1 s par point : farmer du niveau 1 au niveau 4 coûte 3000 s, du niveau 3, 1000 s.
local function grindCost(level, xp, target)
  local s, l, x = 0, level, xp
  while l < target do s = s + (LEVEL_XP[l] - x); l, x = l + 1, 0 end
  return s
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

local function runValidator(dir)
  local out = H.tmpdir() .. "/validator_node_out.txt"
  local status = os.execute(("luajit %s/../validate_guides.lua --guides %q > %q 2>&1"):format(H.ROOT, dir, out))
  local code = status
  if type(status) == "boolean" then code = status and 0 or 1 end
  return code, readFile(out) or ""
end

return {
  -- Sans coût de farm, or-opt avance la tâche à farmer au départ (quelques mètres gagnés, 3 niveaux à
  -- farmer au lieu d'un) ; avec opts.grindCost, elle reste après les quêtes qui donnent les niveaux.
  order_grind_cost_keeps_gated_task_late = function(t)
    local free = order.build(scenario(), P(0), dist, { levelXP = LEVEL_XP, level = 1, xp = 0 })
    t.eq(indexOf(free, "O3"), 1, "without grind cost the gated task jumps to the start")
    local seq = order.build(scenario(), P(0), dist, { levelXP = LEVEL_XP, level = 1, xp = 0, grindCost = grindCost })
    t.eq(indexOf(seq, "O3"), #seq, "with grind cost the gated task stays last")
    t.ok(seq[#seq].needLevel, "the gated task is marked needLevel")
    t.ok(order.feasible(seq, { levelXP = LEVEL_XP, level = 1, xp = 0, ids = { A1 = true, T1 = true, A2 = true, T2 = true, O3 = true } }),
      "sequence feasible")
  end,

  -- Le farm compte comme du trajet : une tâche à farmer est retardée quand le détour coûte moins que le
  -- farm économisé, et seulement dans ce cas.
  order_grind_cost_tradeoff = function(t)
    -- farm très bon marché (0,001 s par point) : la marche l'emporte, la tâche va au départ
    local cheap = function(l, x, target) return grindCost(l, x, target) / 1000 end
    local seq = order.build(scenario(), P(0), dist, { levelXP = LEVEL_XP, level = 1, xp = 0, grindCost = cheap })
    t.eq(indexOf(seq, "O3"), 1, "cheap grind: walking decides")
  end,

  -- Sans grindCost, order.feasible garde son contrat : un seul booléen.
  order_feasible_returns_boolean = function(t)
    local seq = scenario()
    t.eq(select("#", order.feasible(seq, { levelXP = LEVEL_XP })), 1, "one value")
  end,

  -- `node` est écrit juste avant `note` sur une étape fly.
  emit_fly_node = function(t)
    t.eq(emit.step({ "fly", 1453, note = "Stormwind, Elwynn", node = 2 }),
      '{ "fly", 1453, node = 2, note = "Stormwind, Elwynn" }')
  end,

  -- Validateur : nœud absent, inconnu, ou sur une autre carte que la destination.
  validator_checks_fly_node = function(t)
    local dir = H.tmpdir() .. "/guides_fly_node"
    os.execute(('rm -rf "%s"; mkdir -p "%s/Alliance"'):format(dir, dir))
    local plan = { id = "A_Fly_01", title = "Fly", faction = "Alliance", minLevel = 1, maxLevel = 6 }
    local steps = {
      { "fly", 1453, node = 2, note = "Stormwind, Elwynn" },     -- correct : Stormwind
      { "fly", 1455, note = "Ironforge, Dun Morogh" },            -- sans node
      { "fly", 1455, node = 2, note = "Stormwind, Elwynn" },      -- nœud de Stormwind, carte d'Ironforge
      { "fly", 1455, node = 999999 },                             -- nœud inconnu
    }
    local src = emit.guide(plan, steps, {}, { commit = "x", date = "d" })
    local f = assert(io.open(dir .. "/Alliance/A_Fly_01.lua", "wb")); f:write(src); f:close()
    f = assert(io.open(dir .. "/Guides.xml", "wb"))
    f:write('<Ui>\n  <Script file="Alliance\\A_Fly_01.lua"/>\n</Ui>\n'); f:close()
    local code, text = runValidator(dir)
    t.ok(code ~= 0, "exit code is not 0")
    t.ok(text:find("fly step without node", 1, true), text)
    t.ok(text:find("flight node 2 (Stormwind, Elwynn) is not on uiMap 1455", 1, true), text)
    t.ok(text:find("fly to unknown flight node 999999", 1, true), text)
    local lines = 0
    for _ in text:gmatch("A_Fly_01%.lua:%d+ [^\n]*node") do lines = lines + 1 end
    t.eq(lines, 3, "exactly the three bad steps flagged")
  end,

  -- Les vols générés portent le nœud TaxiNodes de leur destination, situé sur la carte de l'étape.
  generated_fly_steps_have_node = function(t)
    local W = H.W()
    local g = readFile(H.ROOT .. "/../../Questify/Guides/Alliance/A_DwarfGnome_03.lua")
    t.ok(g, "guide readable")
    local n = 0
    for m, node in (g or ""):gmatch('{ "fly", (%d+), node = (%d+),') do
      n = n + 1
      local nd = W.taxi.nodes[tonumber(node)]
      t.ok(nd, "node " .. node .. " exists")
      local x, y = W.fromWorld(tonumber(m), nd.wx, nd.wy)
      t.ok(x and x >= 0 and x <= 100 and y >= 0 and y <= 100, "node " .. node .. " on map " .. m)
    end
    t.ok(n >= 1, "at least one fly step")
  end,
}
