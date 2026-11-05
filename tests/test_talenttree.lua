-- Tests de la lecture de l'arbre de talents (Q.TalentTree) : groupes, paliers, colonnes, rangs
-- validés, règles de palier et de prérequis.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Traits = dofile(Mock.root .. "/tests/mock_ext_traits.lua")

-- 3 groupes ; groupe 1 : 16035 (palier 1, col 3), 16036 (palier 1, col 1), 16037 (palier 2, col 2,
-- requiert 16036), 16038 (palier 3).
local function groups()
  return {
    { name = "Armes", talents = { { 16035, 1, 3, 5 }, { 16036, 1, 1, 1 }, { 16037, 2, 2, 3, requires = 16036 },
      { 16038, 3, 1, 1 } } },
    { name = "Fureur", talents = { { 29801, 1, 2, 2 }, { 29802, 2, 2, 1 } } },
    { name = "Protection", talents = { { 30001, 1, 1, 1 } } },
  }
end

local function load(opts)
  opts = opts or {}
  opts.groups = opts.groups or groups()
  local traits = Traits.install(opts)
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  return Q, traits
end

return {
  read_maps_groups_tiers_cols = function(t)
    local Q = load({ unspent = 2 })
    local tree = Q.TalentTree:Read()
    t.ok(tree, "arbre lu")
    t.eq(tree.configID, Traits.CONFIG); t.eq(tree.treeID, Traits.TREE)
    t.eq(#tree.groups, 3)
    t.eq(tree.groups[1].name, "Armes"); t.eq(tree.groups[3].name, "Protection")
    local n = tree.nodes[16035]
    t.eq(n.tier, 1); t.eq(n.col, 3); t.eq(n.group, 1)
    t.eq(n.nodeID, 17035); t.eq(n.entryID, 18035); t.eq(n.spellID, 16035); t.eq(n.maxRanks, 5)
    t.eq(tree.nodes[16037].tier, 2); t.eq(tree.nodes[16038].tier, 3)
    t.eq(tree.nodes[16037].col, 2, "colonne parmi les posX du groupe")
    t.eq(tree.nodes[29801].group, 2); t.eq(tree.nodes[29801].col, 1)
    t.eq(tree.byNodeID[17035], n)
    t.eq(tree.nodes[16037].requires, { 17036 })
    t.eq(n.requires, {})
    t.eq(tree.unspent, 2)
  end,

  -- Forever : un nœud appartient aussi à des groupes de palier, et son arbre n'est pas forcément le premier
  -- de ses groupIDs (relevé du chaman : { 11353, 12795, 12796, 11363 }). Lire groupIDs[1] ne gardait que
  -- 7 nœuds sur 50, et tous les builds fournis passaient pour obsolètes (« un talent n'est plus dans l'arbre »).
  read_finds_the_display_group_among_tier_groups = function(t)
    local Q = load()
    local getNodeInfo = C_Traits.GetNodeInfo
    C_Traits.GetNodeInfo = function(c, n)
      local info = getNodeInfo(c, n)
      if info then
        local display = info.groupIDs[1]
        -- groupes de palier avant l'arbre, sauf pour un nœud sur deux (ordre quelconque, comme en jeu)
        if n % 2 == 0 then
          info.groupIDs = { 11300 + n % 7, 12790, display, 12791 }
        else
          info.groupIDs = { display, 12790 }
        end
      end
      return info
    end
    local tree = Q.TalentTree:Read()
    local count = 0
    for _ in pairs(tree.nodes) do count = count + 1 end
    t.eq(count, 7, "every node kept")
    t.eq(tree.nodes[16035].group, 1); t.eq(tree.nodes[16036].group, 1)
    t.eq(tree.nodes[29801].group, 2); t.eq(tree.nodes[29802].group, 2)
    t.eq(tree.nodes[30001].group, 3)
    t.eq(tree.nodes[16037].tier, 2); t.eq(tree.nodes[16037].col, 2)
    t.eq(tree.nodes[16037].requires, { 17036 })
  end,

  -- I4 : l'arbre lu suit l'état courant, points en attente compris (currentRank), comme la monnaie lue.
  read_includes_staged_ranks = function(t)
    local Q = load({ ranks = { [16035] = 2 }, staged = { [16035] = 3 } })
    local tree = Q.TalentTree:Read()
    t.eq(tree.nodes[16035].rank, 3)
    t.eq(tree.nodes[16036].rank, 0)
    t.eq(tree.groups[1].spent, 3)
    -- currentRank absent : rangs achetés, sinon rang actif
    local getNodeInfo = C_Traits.GetNodeInfo
    C_Traits.GetNodeInfo = function(c, n)
      local info = getNodeInfo(c, n)
      if info then info.currentRank = nil end
      return info
    end
    t.eq(Q.TalentTree:Read().nodes[16035].rank, 3, "ranksPurchased")
    C_Traits.GetNodeInfo = function(c, n)
      local info = getNodeInfo(c, n)
      if info then info.currentRank, info.ranksPurchased = nil, nil end
      return info
    end
    t.eq(Q.TalentTree:Read().nodes[16035].rank, 2, "activeRank")
  end,

  -- Simulateur (I4) : points en attente cohérents entre currentRank, la monnaie et ConfigHasStagedChanges.
  simulator_staged_state_is_coherent = function(t)
    local Q, traits = load({ ranks = { [16035] = 1 }, staged = { [16035] = 2 }, unspent = 3 })
    t.eq(C_Traits.ConfigHasStagedChanges(Traits.CONFIG), true)
    t.eq(Q.TalentTree:Read().unspent, 2, "staged point taken from the currency")
    Traits.commit(traits)
    t.eq(C_Traits.ConfigHasStagedChanges(Traits.CONFIG), false)
    t.eq(traits.ranks[16035], 2, "committed")
    t.eq(Q.TalentTree:Read().unspent, 2)
    t.eq(Q.TalentTree:Read().nodes[16035].rank, 2)
  end,

  read_reports_noconfig = function(t)
    local Q, traits = load()
    traits.configID = nil
    local tree, reason = Q.TalentTree:Read()
    t.eq(tree, nil); t.eq(reason, "noconfig")
  end,

  read_reports_noapi = function(t)
    local Q = load()
    C_Traits, C_ClassTalents = nil, nil
    local tree, reason = Q.TalentTree:Read()
    t.eq(tree, nil); t.eq(reason, "noapi")
  end,

  read_reports_empty = function(t)
    local Q = load({ groups = { { name = "Vide", talents = {} } } })
    local tree, reason = Q.TalentTree:Read()
    t.eq(tree, nil); t.eq(reason, "empty")
  end,

  read_ignores_secret_values = function(t)
    local Q = load()
    local getNodeInfo = C_Traits.GetNodeInfo
    C_Traits.GetNodeInfo = function(configID, nodeID)
      local info = getNodeInfo(configID, nodeID)
      if info and nodeID == 17035 then info.maxRanks = Mock.secret(5) end
      return info
    end
    local tree = Q.TalentTree:Read()
    t.ok(tree, "pas d'erreur")
    t.eq(tree.nodes[16035], nil, "nœud illisible absent")
    t.ok(tree.nodes[16036], "les autres restent")
  end,

  rules_tier_and_requires = function(t)
    local Q = load()
    local tree = Q.TalentTree:Read()
    local node = tree.nodes[16037]    -- palier 2 (5 points requis), requiert 16036 (rang max 1)
    local ok, reason = Q.TalentTree:Rules(tree, { [16035] = 3, [16036] = 1 })(node)
    t.eq(ok, false); t.eq(reason, "tier", "4 points dans le groupe")
    ok = Q.TalentTree:Rules(tree, { [16035] = 4, [16036] = 1 })(node)
    t.eq(ok, true, "5 points, requis au max")
    ok, reason = Q.TalentTree:Rules(tree, { [16035] = 5 })(node)
    t.eq(ok, false); t.eq(reason, "requires", "requis pas au max")
    ok = Q.TalentTree:Rules(tree, { [16035] = 5, [29801] = 2 })(tree.nodes[29802])
    t.eq(ok, false, "les points d'un autre groupe ne comptent pas")
    t.ok(Q.TalentTree:Rules(tree, {})(tree.nodes[16035]), "palier 1 toujours permis")
  end,
}
