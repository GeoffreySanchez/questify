-- Réparation de l'ordre d'un build (tools/talentbuilds/repair.lua) : report stable des points trop tôt.
local function setup()
  local Q = { Util = { IsSecret = function() return false end } }
  assert(loadfile(Mock.root .. "/Questify/Engine/TalentTree.lua"))("Questify", Q)
  assert(loadfile(Mock.root .. "/Questify/Engine/Builds.lua"))("Questify", Q)
  local Repair = dofile(Mock.root .. "/tools/talentbuilds/repair.lua")
  -- A (palier 1, 5 rangs), B (palier 2, 1 rang), C (palier 1, 5 rangs), D (palier 1, 1 rang, requiert C)
  local tree = Q.TalentTree:FromShape({
    [1] = { group = 1, tier = 1, col = 1, maxRanks = 5, requires = {} },
    [2] = { group = 1, tier = 2, col = 1, maxRanks = 1, requires = {} },
    [3] = { group = 1, tier = 1, col = 2, maxRanks = 5, requires = {} },
    [4] = { group = 1, tier = 1, col = 3, maxRanks = 1, requires = { 3 } },
  })
  return Q, Repair, tree
end

return {
  defers_a_point_until_its_tier_opens = function(t)
    local Q, Repair, tree = setup()
    local bad = { 1, 1, 2, 1, 1, 1 }
    t.ok(not Q.Builds:Validate({ order = bad }, tree))
    local fixed, moved = Repair(Q, bad, tree)
    t.eq(fixed, { 1, 1, 1, 1, 1, 2 })
    t.eq(moved, 2)
    t.ok(Q.Builds:Validate({ order = fixed }, tree))
  end,

  defers_a_point_until_its_requirement_is_maxed = function(t)
    local Q, Repair, tree = setup()
    local bad = { 3, 4, 3, 3, 3, 3 }
    local fixed = Repair(Q, bad, tree)
    t.eq(fixed, { 3, 3, 3, 3, 3, 4 })
  end,

  keeps_a_legal_order_unchanged = function(t)
    local Q, Repair, tree = setup()
    local order = { 1, 3, 1 }
    local fixed, moved = Repair(Q, order, tree)
    t.eq(fixed, order)
    t.eq(moved, 0)
  end,

  oldest_pending_first = function(t)
    local Q, Repair, tree = setup()
    -- 4 puis 2 attendent ; 2 devient légal après 5 points de A, 4 après 5 points de C
    local fixed = Repair(Q, { 4, 2, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3 }, tree)
    t.eq(fixed, { 1, 1, 1, 1, 1, 2, 3, 3, 3, 3, 3, 4 })
  end,

  gives_up_when_a_point_never_opens = function(t)
    local Q, Repair, tree = setup()
    t.eq(Repair(Q, { 2, 1 }, tree), nil)
  end,

  keys_differ_per_kind = function(t)
    local makeKey = dofile(Mock.root .. "/tools/talentbuilds/keys.lua")
    local a = makeKey("wowhead", "SHAMAN", "restoration", "leveling")
    local b = makeKey("wowhead", "SHAMAN", "restoration", "pvp")
    local c = makeKey("wowhead", "SHAMAN", "restoration", "raid")
    local d = makeKey("wowhead", "SHAMAN", "restoration", "dungeon")
    t.eq(a, "WOWHEAD_SHAMAN_RESTORATION")
    t.eq(d, "WOWHEAD_SHAMAN_RESTORATION_DUNGEON")
    t.ok(a ~= b and b ~= c and a ~= c and c ~= d and b ~= d, "distinct keys")
  end,
}
