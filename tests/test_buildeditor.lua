-- Tests de l'éditeur de build pur (Q.BuildEditor) : ajout et retrait de points selon les règles.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local A, ALAC, C, OVER, OTHER = 100, 101, 102, 103, 200

-- Groupe 1 : A (palier 1, 5 rangs), C (palier 1, 5 rangs), Alacrity (palier 2, 3 rangs), Overload (palier
-- 3, requiert Alacrity). Groupe 2 : OTHER (palier 2).
local SHAPE = {
  [A] = { group = 1, tier = 1, col = 1, maxRanks = 5, requires = {} },
  [C] = { group = 1, tier = 1, col = 2, maxRanks = 5, requires = {} },
  [ALAC] = { group = 1, tier = 2, col = 1, maxRanks = 3, requires = {} },
  [OVER] = { group = 1, tier = 3, col = 1, maxRanks = 3, requires = { ALAC } },
  [OTHER] = { group = 2, tier = 2, col = 1, maxRanks = 1, requires = {} },
}

local function load()
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  return Q, Q.TalentTree:FromShape(SHAPE)
end

local function rep(id, n, into)
  into = into or {}
  for _ = 1, n do into[#into + 1] = id end
  return into
end

-- A x5, Alacrity x3, C x5 : 13 points, puis Overload au 14e.
local function full()
  local o = rep(A, 5)
  rep(ALAC, 3, o); rep(C, 5, o); o[#o + 1] = OVER
  return o
end

return {
  add_respects_rules = function(t)
    local Q, tree = load()
    local ed = Q.BuildEditor.new({ order = {} }, tree)
    local ok, reason = ed:Add(999)
    t.ok(not ok and reason == "missing", "unknown spell")
    ok, reason = ed:Add(ALAC)
    t.ok(not ok and reason == "tier", "tier 2 needs 5 points")
    for _ = 1, 5 do t.ok(ed:Add(A)) end
    ok, reason = ed:Add(A)
    t.ok(not ok and reason == "maxrank", "max rank")
    t.ok(ed:Add(ALAC), "tier 2 open")
    ok, reason = ed:Add(OVER)
    t.ok(not ok and reason == "tier", "tier 3 needs 10 points")
    for _ = 1, 2 do ed:Add(ALAC) end
    for _ = 1, 2 do ed:Add(C) end
    ok, reason = ed:Add(OVER)
    t.ok(ok, "tier 3 open, requirement at max rank")
    t.eq(#ed:Order(), 11)
    -- requis pas au rang max
    local ed2 = Q.BuildEditor.new({ order = {} }, tree)
    for _ = 1, 5 do ed2:Add(A) end
    for _ = 1, 2 do ed2:Add(ALAC) end
    for _ = 1, 3 do ed2:Add(C) end
    ok, reason = ed2:Add(OVER)
    t.ok(not ok and reason == "requires", "requires max rank")
  end,

  add_refuses_past_51_points = function(t)
    local Q = load()
    local shape = {}
    for i = 1, 11 do shape[1000 + i] = { group = 1, tier = 1, col = 1, maxRanks = 5, requires = {} } end
    local tree = Q.TalentTree:FromShape(shape)
    local ed = Q.BuildEditor.new({ order = {} }, tree)
    local n = 0
    for i = 1, 11 do
      for _ = 1, 5 do
        if ed:Add(1000 + i) then n = n + 1 end
      end
    end
    t.eq(n, 51)
    local ok, reason = ed:Add(1001)
    t.ok(not ok, "refused")
    t.eq(reason, "toolong", "cap checked first")
    ok, reason = ed:Add(1011)
    t.eq(reason, "toolong")
  end,

  does_not_mutate_passed_build = function(t)
    local Q, tree = load()
    local b = { order = rep(A, 2) }
    local ed = Q.BuildEditor.new(b, tree)
    ed:Add(A)
    t.eq(#b.order, 2)
    t.eq(#ed:Order(), 3)
    local copy = ed:Order()
    copy[1] = 999
    t.eq(ed:Order()[1], A, "Order returns a copy")
  end,

  remove_at_shifts_levels = function(t)
    local Q, tree = load()
    local ed = Q.BuildEditor.new({ order = rep(A, 3) }, tree)
    ed:Add(C)
    -- index 4 = niveau 13 ; retirer l'index 1 décale C au niveau 12
    local before = ed:RanksAt(13)
    t.eq(before[C], 1)
    t.eq(before[A], 3)
    t.eq(ed:RanksAt(12)[C], nil)
    local ok = ed:RemoveAt(1)
    t.ok(ok)
    t.eq(#ed:Order(), 3)
    t.eq(ed:RanksAt(12)[C], 1, "C now at level 12")
    t.eq(ed:RanksAt(12)[A], 2)
    local ok2, reason = ed:RemoveAt(10)
    t.ok(not ok2 and reason == "index", "out of range")
    t.eq(#ed:Order(), 3)
  end,

  ranks_at_level_view = function(t)
    local Q, tree = load()
    local ed = Q.BuildEditor.new({ order = { A, A, C, A, A, A, ALAC, OTHER } }, tree)
    local ranks, spent = ed:RanksAt(9)
    t.eq(next(ranks), nil, "before level 10 nothing")
    t.eq(next(spent), nil)
    ranks, spent = ed:RanksAt(10)
    t.eq(ranks[A], 1)
    t.eq(spent[1], 1)
    ranks, spent = ed:RanksAt(14)
    t.eq(ranks[A], 4); t.eq(ranks[C], 1)
    t.eq(spent[1], 5)
    ranks, spent = ed:RanksAt(60)
    t.eq(ranks[ALAC], 1); t.eq(ranks[OTHER], 1)
    t.eq(spent[1], 7); t.eq(spent[2], 1)
  end,

  remove_breaking_later_points_refused = function(t)
    local Q, tree = load()
    local ed = Q.BuildEditor.new({ order = full() }, tree)
    t.eq(ed:Error(), nil, "valid build")
    local ok, reason = ed:RemoveLast(ALAC)
    t.ok(not ok and reason == "requires", "Overload follows: " .. tostring(reason))
    t.eq(#ed:Order(), 14, "order unchanged")
    -- retirer un A casse le palier de Alacrity
    ok, reason = ed:RemoveLast(A)
    t.ok(not ok and reason == "tier", "tier broken: " .. tostring(reason))
    t.eq(#ed:Order(), 14)
    -- retirer le dernier point (Overload) : permis, puis Alacrity aussi
    t.ok(ed:RemoveLast(OVER))
    t.ok(ed:RemoveLast(ALAC))
    t.eq(#ed:Order(), 12)
    local ok2, reason2 = ed:RemoveLast(OVER)
    t.ok(not ok2 and reason2 == "missing", "nothing to remove")
  end,

  new_without_shape_errors_clearly = function(t)
    local Q = load()
    local ok, err = pcall(Q.BuildEditor.new, { order = {} }, nil)
    t.ok(not ok and tostring(err):find("shape"), "clear error")
  end,

  error_reports_first_bad_point = function(t)
    local Q, tree = load()
    local ed = Q.BuildEditor.new({ order = { A, 999, A } }, tree)
    local reason, index = ed:Error()
    t.eq(reason, "missing"); t.eq(index, 2)
    t.eq(ed:RanksAt(12)[A], 2, "unknown spells are ignored in the view")
  end,
}
