-- Tests du contrôle qualité des itinéraires (quality.lua), du balayage de l'ordonnancement (prises au hub,
-- rendus au passage, zones d'objectifs en un passage) et des coffres fermés à clé (sim.keyFor).
local H = require("helpers")
local quality = require("quality")
local order = require("order")
local sim = require("sim")

local function P(x) return { x = x } end
local function yards(a, b) return math.abs(a.x - b.x) end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

-- itinéraire synthétique : { kind, x, id, after = {...}, reqLevel, level, log }
local function legs(list)
  local out = {}
  for _, l in ipairs(list) do
    local task = { id = l.id, kind = l.kind, after = l.after or {}, reqLevel = l.reqLevel, itemStart = l.itemStart }
    out[#out + 1] = { kind = l.kind, q = l.q, pos = P(l.x), id = l.id, task = task, level = l.level or 5, log = l.log or 0 }
  end
  return out
end

return {
  -- prise possible au premier passage au hub, faite au retour : missed pickup + avoidable revisit
  quality_missed_pickup_and_revisit = function(t)
    local res = quality.check(legs({
      { kind = "A", id = "A1", q = 1, x = 0 },
      { kind = "O", id = "O1", q = 1, x = 500, after = { "A1" } },
      { kind = "A", id = "A2", q = 2, x = 10 },
    }), { yards = yards })
    t.eq(#res.pickups, 1, "one missed pickup")
    t.eq(res.pickups[1].q, 2)
    t.eq(#res.revisits, 1, "the return visit was avoidable")
  end,

  -- prise bloquée par le niveau au premier passage : pas un défaut
  quality_level_gate_is_not_a_miss = function(t)
    local res = quality.check(legs({
      { kind = "A", id = "A1", q = 1, x = 0, level = 3 },
      { kind = "O", id = "O1", q = 1, x = 500, after = { "A1" }, level = 3 },
      { kind = "A", id = "A2", q = 2, x = 10, reqLevel = 4, level = 4 },
    }), { yards = yards })
    t.eq(quality.count(res), 0, "nothing reported")
  end,

  -- un détour de 60 yd entre deux PNJ du même hub n'est pas un départ
  quality_small_detour_is_same_visit = function(t)
    local res = quality.check(legs({
      { kind = "A", id = "A1", q = 1, x = 0 },
      { kind = "A", id = "A3", q = 3, x = 60 },
      { kind = "A", id = "A2", q = 2, x = 10 },
    }), { yards = yards })
    t.eq(quality.count(res), 0, "same visit")
  end,

  -- zone d'objectifs visitée deux fois, rendu possible au passage
  quality_split_area_and_turnin = function(t)
    local res = quality.check(legs({
      { kind = "A", id = "A1", q = 1, x = 0 },
      { kind = "A", id = "A2", q = 2, x = 0 },
      { kind = "O", id = "O1", q = 1, x = 1000, after = { "A1" } },
      { kind = "T", id = "T1", q = 1, x = 2000, after = { "O1" } },
      { kind = "O", id = "O2", q = 2, x = 1050, after = { "A2" } },
      { kind = "T", id = "T9", q = 9, x = 2030 },
      { kind = "O", id = "O3", q = 3, x = 3000 },
      { kind = "T", id = "T2", q = 2, x = 0, after = { "O2" } },
    }), { yards = yards })
    t.eq(#res.areas, 1, "split area")
    t.eq(res.areas[1].q, 2)
    t.eq(#res.turnins, 1, "turn-in in passing")
    t.eq(res.turnins[1].q, 9)
  end,

  -- balayage : une prise au hub laissée pour un retour est ramenée au premier passage
  order_sweep_pulls_hub_accept = function(t)
    local dist = function(a, b) return math.abs(a.x - b.x) end
    -- A2 n'est prenable qu'au niveau 2 (donné par T1, rendu au hub) : sans balayage, l'or-opt n'a aucun
    -- intérêt à la déplacer ; avec, elle suit le rendu de T1 au hub
    local function tasks()
      return {
        { id = "A1", kind = "A", q = 1, pos = P(0), dur = 5, after = {} },
        { id = "O1", kind = "O", q = 1, pos = P(100), dur = 5, after = { "A1" } },
        { id = "T1", kind = "T", q = 1, pos = P(1), dur = 5, after = { "O1" }, gain = function() return 1000 end },
        { id = "A9", kind = "A", q = 9, pos = P(300), dur = 5, after = {} },
        { id = "O9", kind = "O", q = 9, pos = P(310), dur = 5, after = { "A9" } },
        { id = "T9", kind = "T", q = 9, pos = P(2), dur = 5, after = { "O9" } },
        { id = "A2", kind = "A", q = 2, pos = P(3), dur = 5, after = {}, reqLevel = 2 },
      }
    end
    local LX = { [1] = 1000, [2] = 1000, [3] = 1000 }
    local seq = order.build(tasks(), P(0), dist, { levelXP = LX, level = 1, xp = 0,
      sweep = { hub = 5, turnin = 5, area = 20 } })
    local pos = {}
    for i, x in ipairs(seq) do pos[x.id] = i end
    t.eq(pos.A2, pos.T1 + 1, "A2 accepted right after T1 at the hub")
  end,

  -- coffre fermé à clé : Benedict's Chest s'ouvre avec Benedict's Key, lâchée par Lieutenant Benedict
  key_for_benedicts_chest = function(t)
    local D = H.D("Horde")
    local key = sim.keyFor(D, 3239)
    t.ok(key, "key found")
    t.eq(key and key.name, "Benedict's Key")
    local holder = false
    for _, n in ipairs(key and key.npcs or {}) do if n == 3192 then holder = true end end
    t.ok(holder, "dropped by Lieutenant Benedict")
  end,

  -- guide généré : 830 « The Admiral's Orders » est pris dans le coffre après l'objectif de 784
  generated_830_after_784 = function(t)
    local g = readFile(H.ROOT .. "/../../Questify_Vanilla/Guides/Horde/H_OrcTroll_02.lua") or ""
    local c784 = g:find('{ "complete", 784', 1, true)
    local a830 = g:find('{ "accept", 830', 1, true)
    t.ok(c784 and a830 and c784 < a830, "784 objective before the chest")
  end,

  -- rapports générés : aucun élément « free » (défaut sans contrainte) dans la section Qualité
  generated_reports_have_no_free_quality_item = function(t)
    local dir = H.ROOT .. "/../../docs/routes"
    local p = io.popen('ls "' .. dir .. '"')
    local n = 0
    for name in p:lines() do
      if name:match("^[AH]_.*%.md$") then
        local text = readFile(dir .. "/" .. name) or ""
        n = n + 1
        t.ok(text:find("## Qualité", 1, true), name .. " has a quality section")
        for line in text:gmatch("[^\n]+") do
          if line:match("^| (%a[%a%-]*) |") and line:match("| free |$") then t.ok(false, name .. ": " .. line) end
        end
      end
    end
    p:close()
    t.ok(n > 0, "reports found")
  end,
}
