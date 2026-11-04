-- tests/mock_ext_traits.lua
-- Simulateur de l'API Forever des talents (C_ClassTalents / C_Traits), partagé par les tests.
--   local Traits = dofile(Mock.root .. "/tests/mock_ext_traits.lua")
-- Deux installations, après Mock.reset() (fait par le lanceur) et avant Mock.loadAddon :
--   Traits.installTabs(TREES, ranks) -> traits   (test_talents : nœuds numérotés par arbre et position)
--   Traits.install{ groups, ranks, staged, unspent } -> traits   (test_talenttree : nœuds par spellID)
-- `traits` : { configID, quantity } ; configID = nil simule des talents pas encore chargés.
--   Traits.commit(traits)   fin de la validation (« Appliquer ») : points en attente validés, TRAIT_CONFIG_UPDATED.

local Traits = {}
local CONFIG, TREE, CURRENCY = 7001, 801, 9001
Traits.CONFIG, Traits.TREE, Traits.CURRENCY = CONFIG, TREE, CURRENCY

local function clearLegacy()
  GetNumTalentTabs, GetTalentTabInfo, GetNumTalents, GetTalentInfo = nil, nil, nil, nil
  UnitCharacterPoints, GetUnspentTalentPoints = nil, nil
end

-- API Forever (famille Mainline 12.x, Blizzard_PlayerSpells/Camelot/ClassTalents) : un arbre de
-- classe C_Traits dont les trois arbres classiques sont des groupes de nœuds. Nœud n° tab*100+i ;
-- entrée = nœud + 10000 ; définition = nœud + 20000 ; sort = nœud + 30000. La monnaie de l'arbre
-- vaut niveau - 9 - rangs placés (comme le serveur), sauf traits.quantity imposé.
-- TREES = { { name, talents = { { nom, palier, colonne, rang max } } } }, ranks[tab .. ":" .. i].
function Traits.installTabs(TREES, ranks)
  local traits = { configID = CONFIG, quantity = nil }
  local nodes, byId = {}, {}
  for tab, tree in ipairs(TREES) do
    for i, tal in ipairs(tree.talents) do
      local n = { id = tab * 100 + i, tab = tab, i = i, t = tal }
      nodes[#nodes + 1] = n
      byId[n.id] = n
    end
  end
  local function rankOf(n) return ranks[n.tab .. ":" .. n.i] or 0 end
  local function spentRanks()
    local n = 0
    for _, r in pairs(ranks) do n = n + r end
    return n
  end
  C_ClassTalents = { GetActiveConfigID = function() return traits.configID end }
  C_Traits = {
    GetConfigInfo = function(id)
      if id ~= traits.configID then return nil end
      return { ID = id, type = 1, name = "", treeIDs = { TREE }, usesSharedActionBars = true }
    end,
    GetTreeNodes = function(treeID)
      local out = {}
      if treeID == TREE then for _, n in ipairs(nodes) do out[#out + 1] = n.id end end
      return out
    end,
    GetNodeInfo = function(configID, nodeID)
      local n = byId[nodeID]
      if configID ~= traits.configID or not n then return nil end
      return { ID = nodeID, posX = n.t[3] * 600, posY = n.t[2] * 600, flags = 0, entryIDs = { nodeID + 10000 },
        currentRank = rankOf(n), activeRank = rankOf(n), ranksPurchased = rankOf(n), maxRanks = n.t[4],
        type = 0, isVisible = true, groupIDs = { 50 + n.tab } }
    end,
    GetEntryInfo = function(_, entryID)
      local n = byId[entryID - 10000]
      if not n then return nil end
      return { definitionID = entryID + 10000, type = 1, maxRanks = n.t[4], isAvailable = true,
        isDisplayError = false, conditionIDs = {} }
    end,
    GetDefinitionInfo = function(definitionID)
      local n = byId[definitionID - 20000]
      return n and { spellID = definitionID + 10000 } or nil
    end,
    GetTreeCurrencyInfo = function(configID, treeID, excludeStaged)
      if configID ~= traits.configID or treeID ~= TREE or excludeStaged ~= false then return {} end
      local q = traits.quantity or math.max(0, Mock.player.level - 9 - spentRanks())
      return { { traitCurrencyID = CURRENCY, quantity = q, spent = spentRanks() } }
    end,
    ConfigHasStagedChanges = function() return false end,
    GetGroupDisplayInfoByTreeID = function(treeID)
      local out = {}
      for tab, tree in ipairs(TREES) do
        out[#out + 1] = { groupID = 50 + tab, treeID = treeID, skillLineID = 0, orderIndex = tab - 1,
          displayName = tree.name, icon = 0 }
      end
      return out
    end,
  }
  C_Spell = { GetSpellName = function(id) local n = byId[id - 30000]; return n and n.t[1] end }
  clearLegacy()
  return traits
end

-- Nœuds identifiés par leur sort de rang 1 : nœud n° = spellID + 1000, entrée + 2000, définition
-- + 3000 ; posY = palier * 600, posX = colonne * 600 + groupe * 3000 ; arête `visibleEdges =
-- { { targetNode } }` portée par le nœud source. Les rangs posés sont opts.ranks[spellID] ; opts.staged
-- [spellID] simule les points en attente (rang courant : comptés par currentRank/ranksPurchased, pas par
-- activeRank) ; comme dans le jeu, ils sont pris sur la monnaie lue avec excludeStagedChanges = false
-- (traits.quantity = points non dépensés sans les points en attente) et ConfigHasStagedChanges les voit.
-- opts.groups = { { name, talents = { { spellID, tier, col, maxRanks, requires = spellID? } } } }.
local function stagedExtra(traits)
  local n = 0
  for spellID, r in pairs(traits.staged) do n = n + math.max(0, r - (traits.ranks[spellID] or 0)) end
  return n
end

function Traits.install(opts)
  local ranks, staged = opts.ranks or {}, opts.staged or {}
  local traits = { configID = CONFIG, quantity = opts.unspent or 0, ranks = ranks, staged = staged }
  local byNode, order = {}, {}
  traits.byNode = byNode
  for g, group in ipairs(opts.groups) do
    for _, tal in ipairs(group.talents) do
      local n = { spellID = tal[1], tier = tal[2], col = tal[3], maxRanks = tal[4], group = g, requires = tal.requires,
        id = tal[1] + 1000 }
      byNode[n.id] = n
      order[#order + 1] = n
    end
  end
  local function edgesFrom(n)
    local out = {}
    for _, m in ipairs(order) do
      if m.requires == n.spellID then out[#out + 1] = { targetNode = m.id } end
    end
    return out
  end
  C_ClassTalents = { GetActiveConfigID = function() return traits.configID end }
  C_Traits = {
    GetConfigInfo = function(id)
      if id ~= traits.configID then return nil end
      return { ID = id, type = 1, name = "", treeIDs = { TREE }, usesSharedActionBars = true }
    end,
    GetTreeNodes = function(treeID)
      local out = {}
      if treeID == TREE then for _, n in ipairs(order) do out[#out + 1] = n.id end end
      return out
    end,
    GetNodeInfo = function(configID, nodeID)
      local n = byNode[nodeID]
      if configID ~= traits.configID or not n then return nil end
      local committed = ranks[n.spellID] or 0
      local pending = staged[n.spellID] or committed
      return { ID = nodeID, posX = n.col * 600 + n.group * 3000, posY = n.tier * 600, flags = 0,
        entryIDs = { n.spellID + 2000 }, currentRank = pending, activeRank = committed, ranksPurchased = pending,
        maxRanks = n.maxRanks, type = 0, isVisible = true, groupIDs = { 50 + n.group }, visibleEdges = edgesFrom(n) }
    end,
    GetEntryInfo = function(_, entryID)
      local n = byNode[entryID - 1000]
      if not n then return nil end
      return { definitionID = n.spellID + 3000, type = 1, maxRanks = n.maxRanks, isAvailable = true,
        isDisplayError = false, conditionIDs = {} }
    end,
    GetDefinitionInfo = function(definitionID)
      local n = byNode[definitionID - 2000]
      return n and { spellID = n.spellID } or nil
    end,
    GetTreeCurrencyInfo = function(configID, treeID, excludeStaged)
      if configID ~= traits.configID or treeID ~= TREE or excludeStaged ~= false then return {} end
      return { { traitCurrencyID = CURRENCY, quantity = math.max(0, traits.quantity - stagedExtra(traits)), spent = 0 } }
    end,
    ConfigHasStagedChanges = function(configID)
      if configID ~= traits.configID then return false end
      for spellID, r in pairs(traits.staged) do
        if r ~= (traits.ranks[spellID] or 0) then return true end
      end
      return false
    end,
    GetGroupDisplayInfoByTreeID = function(treeID)
      local out = {}
      -- orderIndex inversé : le tri par orderIndex doit remettre les groupes dans l'ordre
      for g, group in ipairs(opts.groups) do
        table.insert(out, 1, { groupID = 50 + g, treeID = treeID, skillLineID = 0, orderIndex = g - 1,
          displayName = group.name, icon = 0 })
      end
      return out
    end,
  }
  clearLegacy()
  return traits
end

-- Fin de la validation : les points en attente deviennent des rangs posés (pris sur traits.quantity), puis
-- TRAIT_CONFIG_UPDATED(configID) comme le jeu à la fin de l'incantation d'application.
function Traits.commit(traits)
  local extra = stagedExtra(traits)
  for spellID, r in pairs(traits.staged) do traits.ranks[spellID] = r end
  for spellID in pairs(traits.staged) do traits.staged[spellID] = nil end
  traits.quantity = math.max(0, (traits.quantity or 0) - extra)
  Mock.fire("TRAIT_CONFIG_UPDATED", traits.configID)
end

-- Achat et validation (Task « apprendre », Engine/TalentLearn.lua) : à appeler après install / installTabs.
-- Ajoute C_Traits.PurchaseRank / RollbackConfig, C_ClassTalents.CommitConfig / GetLastSelectedSavedConfigID
-- (appels notés par Mock.record : Mock.countCalls("PurchaseRank") etc.) et une spé active (specID).
-- opts : failPurchaseAt = n (le n-ième achat renvoie false), failCommit = true, throwPurchase = true,
-- savedConfigID, specID (262 par défaut). Renvoie traits, avec traits.purchased = { nodeID, … }.
-- Un achat sur un nœud de Traits.install reste en attente (traits.staged) jusqu'à Traits.commit.
function Traits.installLearn(traits, opts)
  opts = opts or {}
  traits.purchased = {}
  C_Traits.PurchaseRank = function(configID, nodeID)
    Mock.record("PurchaseRank", configID, nodeID)
    if opts.throwPurchase then error("PurchaseRank failed") end
    if opts.failPurchaseAt and #Mock.callsTo("PurchaseRank") == opts.failPurchaseAt then return false end
    traits.purchased[#traits.purchased + 1] = nodeID
    -- nœud connu (Traits.install) : le rang acheté reste en attente jusqu'à Traits.commit
    local n = traits.byNode and traits.byNode[nodeID]
    if n and traits.staged then
      traits.staged[n.spellID] = (traits.staged[n.spellID] or traits.ranks[n.spellID] or 0) + 1
    end
    return true
  end
  C_Traits.RollbackConfig = function(configID)
    Mock.record("RollbackConfig", configID)
    return true
  end
  C_ClassTalents.CommitConfig = function(savedConfigID)
    Mock.record("CommitConfig", savedConfigID)
    if opts.throwCommit then error("CommitConfig boom") end
    return not opts.failCommit
  end
  C_ClassTalents.GetLastSelectedSavedConfigID = function(specID)
    Mock.record("GetLastSelectedSavedConfigID", specID)
    return opts.savedConfigID
  end
  C_SpecializationInfo = C_SpecializationInfo or {}
  C_SpecializationInfo.GetSpecialization = function() return 1 end
  C_SpecializationInfo.GetSpecializationInfo = function() return opts.specID or 262 end
  return traits
end

return Traits
