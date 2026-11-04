local addonName, Q = ...

-- Éditeur de build pur (spec 2.5) : ajoute et retire des points sur une copie de l'ordre d'un build,
-- selon les règles de Builds:Validate. Rien ici ne touche au jeu ni ne modifie le build passé.
--   ed = Q.BuildEditor.new(build, shape)   shape = arbre (TalentTree:Read en jeu, TalentTree:FromShape
--                                          sur Q.TalentShapeData[CLASSE] hors arbre)
--   ed:Add(spellID)       -> true | false, raison ("missing", "maxrank", "tier", "requires", "toolong")
--   ed:RemoveLast(spellID), ed:RemoveAt(index) -> true | false, raison ("missing" : aucun point de ce talent ;
--                           "index" : hors de l'ordre) ; refus quand un point suivant
--                           casserait ("requires", "tier"), l'ordre reste alors inchangé
--   ed:RanksAt(level)     -> { [spellID] = rang }, { [groupe] = points } après les points des niveaux 10..level
--   ed:Order()            -> copie de l'ordre ; ed:Error() -> raison, index | nil (validité de l'ordre)
local BuildEditor = {}
BuildEditor.__index = BuildEditor
Q.BuildEditor = BuildEditor

local FIRST_LEVEL = 10
local MAX_POINTS = 51

function BuildEditor.new(build, shape)
  if type(shape) ~= "table" or type(shape.nodes) ~= "table" then
    error("BuildEditor.new: shape (tree with nodes) required", 2)
  end
  local self = setmetatable({}, BuildEditor)
  self.tree = shape
  self.points = {}
  for i, spellID in ipairs((build and build.order) or {}) do self.points[i] = spellID end
  return self
end

function BuildEditor:Order()
  local out = {}
  for i, spellID in ipairs(self.points) do out[i] = spellID end
  return out
end

function BuildEditor:Error()
  local ok, reason, index = Q.Builds:Validate({ order = self.points }, self.tree)
  if ok then return nil end
  return reason, index
end

local function ranksOf(points, tree, count)
  local ranks, spent = {}, {}
  for i = 1, math.min(count or #points, #points) do
    local node = tree.nodes[points[i]]
    if node then
      ranks[node.spellID] = (ranks[node.spellID] or 0) + 1
      spent[node.group] = (spent[node.group] or 0) + 1
    end
  end
  return ranks, spent
end

function BuildEditor:RanksAt(level)
  return ranksOf(self.points, self.tree, (level or 0) - FIRST_LEVEL + 1)
end

function BuildEditor:Add(spellID)
  if #self.points >= MAX_POINTS then return false, "toolong" end
  local node = self.tree.nodes[spellID]
  if not node then return false, "missing" end
  local ranks = ranksOf(self.points, self.tree)
  if (ranks[spellID] or 0) >= node.maxRanks then return false, "maxrank" end
  local ok, reason = Q.TalentTree:Rules(self.tree, ranks)(node)
  if not ok then return false, reason end
  self.points[#self.points + 1] = spellID
  return true
end

function BuildEditor:RemoveAt(index)
  if type(index) ~= "number" or not self.points[index] then return false, "index" end
  local trial = {}
  for i, spellID in ipairs(self.points) do
    if i ~= index then trial[#trial + 1] = spellID end
  end
  local ok, reason = Q.Builds:Validate({ order = trial }, self.tree)
  if not ok then return false, reason end
  self.points = trial
  return true
end

function BuildEditor:RemoveLast(spellID)
  for i = #self.points, 1, -1 do
    if self.points[i] == spellID then return self:RemoveAt(i) end
  end
  return false, "missing"
end
