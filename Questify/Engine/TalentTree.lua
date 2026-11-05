local addonName, Q = ...

-- Lecture de l'arbre de talents du client (Forever : C_Traits). Chaque talent est identifié par le
-- sort de rang 1 de son entrée (spellID), stable d'une langue et d'une mise à jour à l'autre ; son
-- palier et sa colonne se déduisent de la position du nœud (posY, posX), son groupe (1 à 3, les trois
-- arbres classiques) de l'ordre d'affichage des groupes. Les rangs lus sont ceux de l'état courant de la
-- configuration active, points en attente compris (posés mais pas encore validés par « Appliquer ») : la
-- monnaie lue (Talents:TreeCurrencyUnspent, excludeStagedChanges = false) les compte déjà comme dépensés.
local TalentTree = {}
Q.TalentTree = TalentTree

local POINTS_PER_TIER = 5

local function call(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a = pcall(fn, ...)
  if not ok then return nil end
  return a
end

local function plain(v)
  if Q.Util.IsSecret(v) then return nil end
  local k = type(v)
  if k == "number" or k == "string" or k == "boolean" then return v end
  return nil
end

local function readable(v)
  return type(v) == "table" and not Q.Util.IsSecret(v)
end

local function num(v)
  v = plain(v)
  return type(v) == "number" and v or nil
end

-- Rang courant d'un nœud (I4) : currentRank, points en attente compris ; sinon ranksPurchased (qui les
-- compte aussi), sinon activeRank. Le halo, la bande, l'éditeur et Builds:Due avancent ainsi dès qu'un
-- point est posé, comme la monnaie.
local function currentRank(info)
  return num(info.currentRank) or num(info.ranksPurchased) or num(info.activeRank)
end

-- Valeurs distinctes d'une liste, triées, -> { [valeur] = rang à partir de 1 }.
local function rankOf(values)
  local list, seen = {}, {}
  for _, v in ipairs(values) do
    if not seen[v] then seen[v] = true; list[#list + 1] = v end
  end
  table.sort(list)
  local out = {}
  for i, v in ipairs(list) do out[v] = i end
  return out
end

-- Groupe d'affichage du nœud : parmi ses groupIDs, celui qui est un des trois arbres (displayGroups). Un
-- nœud de Forever appartient aussi à des groupes de palier (relevé du chaman : { 11353, 12795, 12796, 11363 },
-- arbre 11363 en dernier), dans un ordre quelconque : le premier groupID n'est pas forcément l'arbre.
local function displayGroupOf(groupIDs, displayGroups)
  for _, g in ipairs(groupIDs) do
    local id = num(g)
    if id and displayGroups[id] then return id end
  end
  return nil
end

-- Nœud lisible ou nil : tout ce qui vient du jeu passe par plain() avant d'être comparé.
local function readNode(configID, nodeID, displayGroups)
  local info = call(C_Traits.GetNodeInfo, configID, nodeID)
  if not readable(info) or info.isVisible == false then return nil end
  local posX, posY, maxRanks, rank = num(info.posX), num(info.posY), num(info.maxRanks), currentRank(info)
  if not (posX and posY and maxRanks and rank) then return nil end
  local entryIDs, groupIDs = info.entryIDs, info.groupIDs
  if not readable(entryIDs) or not readable(groupIDs) then return nil end
  local entryID, groupID = num(entryIDs[1]), displayGroupOf(groupIDs, displayGroups)
  if not (entryID and groupID) then return nil end
  local entry = call(C_Traits.GetEntryInfo, configID, entryID)
  if not readable(entry) then return nil end
  local definitionID = num(entry.definitionID)
  local def = definitionID and call(C_Traits.GetDefinitionInfo, definitionID)
  if not readable(def) then return nil end
  local spellID = num(def.spellID)
  if not spellID then return nil end
  local targets = {}
  if readable(info.visibleEdges) then
    for _, edge in ipairs(info.visibleEdges) do
      local target = readable(edge) and num(edge.targetNode)
      if target then targets[#targets + 1] = target end
    end
  end
  return { nodeID = nodeID, entryID = entryID, spellID = spellID, maxRanks = maxRanks, rank = rank,
    requires = {}, posX = posX, posY = posY, groupID = groupID, targets = targets }
end

-- Groupes de l'arbre dans l'ordre d'affichage : { { groupID, name, spent } }.
local function readGroups(treeID)
  local list = call(C_Traits.GetGroupDisplayInfoByTreeID, treeID)
  local out = {}
  if not readable(list) then return out end
  for _, g in ipairs(list) do
    local groupID = readable(g) and num(g.groupID)
    if groupID then
      out[#out + 1] = { groupID = groupID, name = plain(g.displayName) or "?", spent = 0,
        order = num(g.orderIndex) or #out }
    end
  end
  table.sort(out, function(a, b) return a.order < b.order end)
  for _, g in ipairs(out) do g.order = nil end
  return out
end

-- Arbre de la configuration active.
--   -> { configID, treeID, groups = { { groupID, name, spent } }, nodes = { [spellID] = node },
--        byNodeID = { [nodeID] = node }, unspent }
--      node = { nodeID, entryID, spellID, group, tier, col, maxRanks, rank, requires = { nodeID } }
--   ou nil, raison : "noapi" (API absente), "noconfig" (pas de configuration active), "empty" (aucun
--   nœud lisible).
function TalentTree:Read()
  if type(C_ClassTalents) ~= "table" or type(C_Traits) ~= "table" then return nil, "noapi" end
  for _, name in ipairs({ "GetConfigInfo", "GetTreeNodes", "GetNodeInfo", "GetEntryInfo", "GetDefinitionInfo",
      "GetGroupDisplayInfoByTreeID" }) do
    if type(C_Traits[name]) ~= "function" then return nil, "noapi" end
  end
  local configID = num(call(C_ClassTalents.GetActiveConfigID))
  if not configID then return nil, "noconfig" end
  local config = call(C_Traits.GetConfigInfo, configID)
  if not readable(config) or not readable(config.treeIDs) then return nil, "noconfig" end
  local treeID = num(config.treeIDs[1])
  if not treeID then return nil, "noconfig" end

  local groups = readGroups(treeID)
  local groupIndex = {}
  for i, g in ipairs(groups) do groupIndex[g.groupID] = i end

  local raw = {}
  local nodeIDs = call(C_Traits.GetTreeNodes, treeID)
  if readable(nodeIDs) then
    for _, nodeID in ipairs(nodeIDs) do
      nodeID = num(nodeID)
      local node = nodeID and readNode(configID, nodeID, groupIndex)
      if node and groupIndex[node.groupID] then raw[#raw + 1] = node end
    end
  end
  if #raw == 0 then return nil, "empty" end

  -- palier : rang du posY parmi ceux de l'arbre ; colonne : rang du posX parmi ceux du groupe
  local ys, xsByGroup = {}, {}
  for _, n in ipairs(raw) do
    ys[#ys + 1] = n.posY
    local xs = xsByGroup[n.groupID] or {}
    xsByGroup[n.groupID] = xs
    xs[#xs + 1] = n.posX
  end
  local tierOf = rankOf(ys)
  local colOf = {}
  for groupID, xs in pairs(xsByGroup) do colOf[groupID] = rankOf(xs) end

  local tree = { configID = configID, treeID = treeID, groups = groups, nodes = {}, byNodeID = {} }
  for _, n in ipairs(raw) do
    n.group, n.tier, n.col = groupIndex[n.groupID], tierOf[n.posY], colOf[n.groupID][n.posX]
    tree.nodes[n.spellID] = n
    tree.byNodeID[n.nodeID] = n
    groups[n.group].spent = groups[n.group].spent + n.rank
  end
  for _, n in ipairs(raw) do
    for _, target in ipairs(n.targets) do
      local to = tree.byNodeID[target]
      if to then to.requires[#to.requires + 1] = n.nodeID end
    end
    n.targets, n.posX, n.posY, n.groupID = nil, nil, nil, nil
  end
  for _, n in ipairs(raw) do table.sort(n.requires) end

  tree.unspent = Q.Talents and Q.Talents:TreeCurrencyUnspent() or 0
  return tree
end

-- Règles d'un point à prendre, d'après les rangs que le plan vise (ranksBySpell[spellID], 0 par défaut)
-- : un palier n demande (n - 1) * 5 points dans son groupe ; un talent requis doit être au rang max.
-- -> fonction(node) -> true | false, "tier" | "requires".
function TalentTree:Rules(tree, ranksBySpell)
  ranksBySpell = ranksBySpell or {}
  local spent = {}
  for spellID, node in pairs(tree.nodes) do
    spent[node.group] = (spent[node.group] or 0) + (ranksBySpell[spellID] or 0)
  end
  return function(node)
    if (spent[node.group] or 0) < (node.tier - 1) * POINTS_PER_TIER then return false, "tier" end
    for _, nodeID in ipairs(node.requires) do
      local from = tree.byNodeID[nodeID]
      if from and (ranksBySpell[from.spellID] or 0) < from.maxRanks then return false, "requires" end
    end
    return true
  end
end

-- Arbre sans joueur, bâti sur la forme d'une classe (Q.TalentShapeData[CLASSE]) : tous les rangs à 0,
-- aucun point à dépenser. Mêmes champs que Read ; le nodeID est synthétisé depuis le spellID (stable),
-- et requires liste des nodeID. Sert aux tests hors jeu et à l'éditeur de builds.
--   shape = { [spellID] = { group, tier, col, maxRanks, requires = { spellID } } }
function TalentTree:FromShape(shape)
  local tree = { configID = 0, treeID = 0, groups = {}, nodes = {}, byNodeID = {}, unspent = 0 }
  local maxGroup = 0
  for spellID, s in pairs(shape or {}) do
    local node = { nodeID = spellID, entryID = spellID, spellID = spellID, maxRanks = s.maxRanks, rank = 0,
      requires = {}, group = s.group, tier = s.tier, col = s.col }
    for _, req in ipairs(s.requires or {}) do node.requires[#node.requires + 1] = req end
    table.sort(node.requires)
    tree.nodes[spellID] = node
    tree.byNodeID[spellID] = node
    if s.group > maxGroup then maxGroup = s.group end
  end
  for g = 1, maxGroup do tree.groups[g] = { groupID = g, name = tostring(g), spent = 0 } end
  return tree
end
