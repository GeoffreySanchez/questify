local addonName, Q = ...

-- Builds de talents : un build est une liste ordonnée de points (un spellID de rang 1 par point, du
-- niveau 10 au niveau 60, 51 points au plus). Tout ici est pur : les fonctions travaillent sur un arbre
-- déjà lu (Q.TalentTree:Read) et ne touchent jamais au jeu. Le nom du build n'est jamais utilisé.
--   build = { key, class, specID, name, source, date, official, order = { spellID, … } }
local Builds = {}
Q.Builds = Builds

local FIRST_LEVEL = 10
local MAX_POINTS = 51

local function copyRanks(tree)
  local ranks = {}
  for spellID, node in pairs(tree.nodes) do ranks[spellID] = node.rank end
  return ranks
end

-- Valide le build point par point sur un arbre vide : -> true | false, raison, index du premier point
-- fautif. Raisons : "toolong" (plus de 51 points), "missing" (spellID absent de l'arbre), "maxrank"
-- (rang max déjà atteint), "tier", "requires" (règles de TalentTree:Rules).
function Builds:Validate(build, tree)
  local order = build.order or {}
  local ranks = {}
  for i, spellID in ipairs(order) do
    if i > MAX_POINTS then return false, "toolong", i end
    local node = tree.nodes[spellID]
    if not node then return false, "missing", i end
    if (ranks[spellID] or 0) >= node.maxRanks then return false, "maxrank", i end
    local ok, reason = Q.TalentTree:Rules(tree, ranks)(node)
    if not ok then return false, reason, i end
    ranks[spellID] = (ranks[spellID] or 0) + 1
  end
  return true
end

-- Points à dépenser maintenant : jusqu'à tree.unspent entrées { spellID, node, rank, level } dans l'ordre
-- du build. Les points déjà couverts par les rangs réels de l'arbre sont sautés, de même que ceux que
-- les règles interdisent pour l'instant ; level = 10 + index - 1 (niveau où le build prend le point).
function Builds:Due(build, tree)
  local due = {}
  local limit = tree.unspent or 0
  if limit <= 0 then return due end
  local current = copyRanks(tree)
  local seen = {}
  for i, spellID in ipairs(build.order or {}) do
    if #due >= limit or i > MAX_POINTS then break end
    local node = tree.nodes[spellID]
    if node then
      seen[spellID] = (seen[spellID] or 0) + 1
      if seen[spellID] > node.rank then
        local have = current[spellID] or 0
        if have < node.maxRanks and Q.TalentTree:Rules(tree, current)(node) then
          current[spellID] = have + 1
          due[#due + 1] = { spellID = spellID, node = node, rank = have + 1, level = FIRST_LEVEL + i - 1 }
        end
      end
    end
  end
  return due
end

-- Vrai si un talent de l'arbre réel a plus de rangs que le build n'en donne sur ses N premiers points,
-- N étant le nombre de points déjà dépensés.
function Builds:Deviates(build, tree)
  local spent = 0
  for _, node in pairs(tree.nodes) do spent = spent + node.rank end
  local given = {}
  for i = 1, math.min(spent, #(build.order or {})) do
    local spellID = build.order[i]
    given[spellID] = (given[spellID] or 0) + 1
  end
  for spellID, node in pairs(tree.nodes) do
    if node.rank > (given[spellID] or 0) then return true end
  end
  return false
end

-- Build tiré des rangs actuels de l'arbre : palier par palier, puis groupe, puis colonne.
function Builds:FromTree(tree, class, specID)
  local list = {}
  for _, node in pairs(tree.nodes) do
    if node.rank > 0 then list[#list + 1] = node end
  end
  table.sort(list, function(a, b)
    if a.tier ~= b.tier then return a.tier < b.tier end
    if a.group ~= b.group then return a.group < b.group end
    if a.col ~= b.col then return a.col < b.col end
    return a.spellID < b.spellID
  end)
  local order = {}
  for _, node in ipairs(list) do
    for _ = 1, node.rank do order[#order + 1] = node.spellID end
  end
  return { class = class, specID = specID, source = "tree", date = type(time) == "function" and time() or 0,
    official = false, order = order }
end

---------------------------------------------------------------------------
-- Stockage : builds fournis (Q.TalentBuildData, jamais copiés dans les sauvegardes), builds perso
-- (Q.db.builds[<CLASSE>], liste commune au compte) et build actif par personnage et groupe de
-- spécialisation (Q.char.builds.active[groupe]).
---------------------------------------------------------------------------
local function plain(v)
  if Q.Util.IsSecret(v) then return nil end
  return v
end

local function playerClass()
  return Q.Player and Q.Player.classFile
end

local function officialList(class)
  local data = Q.TalentBuildData
  local list = type(data) == "table" and data[class]
  return type(list) == "table" and list or {}
end

-- Builds perso de la classe ; create = true crée la liste.
local function personalList(class, create)
  if type(Q.db) ~= "table" then return {} end
  if create then
    if type(Q.db.builds) ~= "table" then Q.db.builds = {} end
    if type(Q.db.builds[class]) ~= "table" then Q.db.builds[class] = {} end
  end
  local all = Q.db.builds
  return type(all) == "table" and type(all[class]) == "table" and all[class] or {}
end

local function charBuilds()
  if type(Q.char) ~= "table" then return { active = {}, picked = {} } end
  if type(Q.char.builds) ~= "table" then Q.char.builds = {} end
  local c = Q.char.builds
  if type(c.active) ~= "table" then c.active = {} end
  if type(c.picked) ~= "table" then c.picked = {} end
  return c
end

local function copyBuild(build)
  local c = {}
  for k, v in pairs(build) do
    if k == "order" then
      c.order = {}
      for i, id in ipairs(v) do c.order[i] = id end
    elseif type(v) == "table" then
      local n = {}
      for kk, vv in pairs(v) do n[kk] = vv end
      c[k] = n
    else
      c[k] = v
    end
  end
  return c
end

-- Nom affiché : builds fournis { enUS, frFR }, builds perso chaîne. Langue du client, puis enUS, puis la clé.
function Builds:Name(build)
  if type(build) ~= "table" then return "" end
  local name = build.name
  if type(name) == "table" then
    local locale = GetLocale and GetLocale() or "enUS"
    return name[locale] or name.enUS or build.key or ""
  end
  if type(name) == "string" and name ~= "" then return name end
  return build.key or ""
end

-- Builds d'une classe : fournis d'abord, puis perso.
function Builds:List(class)
  class = class or playerClass()
  local out = {}
  for _, b in ipairs(officialList(class)) do out[#out + 1] = b end
  for _, b in ipairs(personalList(class)) do out[#out + 1] = b end
  return out
end

-- Build de clé donnée (toutes classes) ou nil.
function Builds:Get(key)
  if key == nil then return nil end
  for _, list in pairs(type(Q.TalentBuildData) == "table" and Q.TalentBuildData or {}) do
    for _, b in ipairs(list) do
      if b.key == key then return b end
    end
  end
  for _, list in pairs(type(Q.db) == "table" and type(Q.db.builds) == "table" and Q.db.builds or {}) do
    for _, b in ipairs(list) do
      if b.key == key then return b end
    end
  end
  return nil
end

local function uniqueKey()
  local base = "u" .. (type(time) == "function" and time() or 0)
  local key, n = base, 1
  while Builds:Get(key) do
    n = n + 1
    key = base .. "_" .. n
  end
  return key
end

-- Enregistre un build perso -> clé. Un build fourni (ou à clé inconnue) devient une copie perso à clé neuve ;
-- un build perso déjà connu est remplacé sur place.
function Builds:Save(build)
  if type(build) ~= "table" then return nil end
  local class = build.class or playerClass()
  if not class then return nil end
  local copy = copyBuild(build)
  copy.class = class
  copy.official = false
  if type(copy.name) == "table" then copy.name = self:Name(build) end
  local list = personalList(class, true)
  local index
  if build.key and not build.official then
    for i, b in ipairs(list) do
      if b.key == build.key then index = i; break end
    end
  end
  if index then
    list[index] = copy
  else
    if not copy.key or build.official or self:Get(copy.key) then copy.key = uniqueKey() end
    list[#list + 1] = copy
  end
  Q:Fire("BUILDS_CHANGED")
  return copy.key
end

-- Supprime un build perso (jamais un fourni) et le retire des builds actifs de ce personnage.
function Builds:Delete(key)
  for _, list in pairs(type(Q.db) == "table" and type(Q.db.builds) == "table" and Q.db.builds or {}) do
    for i, b in ipairs(list) do
      if b.key == key then
        table.remove(list, i)
        local active = charBuilds().active
        for group, k in pairs(active) do
          if k == key then active[group] = nil end
        end
        Q:Fire("BUILDS_CHANGED")
        return true
      end
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Groupes de spécialisation et build actif
---------------------------------------------------------------------------
local function specApi()
  local S = C_SpecializationInfo
  return type(S) == "table" and S or nil
end

local function callNumber(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, ...)
  v = ok and tonumber(plain(v)) or nil
  return v
end

-- { 1 } tant qu'un seul groupe est ouvert, { 1, 2 } sinon.
function Builds:Groups()
  local S = specApi()
  local n = S and callNumber(S.GetNumSpecGroups)
  if n and n >= 2 then return { 1, 2 } end
  return { 1 }
end

function Builds:ActiveGroup()
  local S = specApi()
  local g = S and callNumber(S.GetActiveSpecGroup)
  if g == 1 or g == 2 then return g end
  return 1
end

-- specID de la spécialisation du groupe, ou nil (rien choisi, API absente ou valeur secrète).
local function specIDFor(group)
  local S = specApi()
  if not S then return nil end
  local index = callNumber(S.GetSpecialization, false, false, group)
  if not index or index <= 0 or type(S.GetSpecializationInfo) ~= "function" then return nil end
  local ok, id = pcall(S.GetSpecializationInfo, index)
  id = ok and tonumber(plain(id)) or nil
  if id and id > 0 then return id end
  return nil
end

-- specID de la spécialisation du groupe (groupe actif par défaut), ou nil.
function Builds:SpecID(group)
  return specIDFor(group or self:ActiveGroup())
end

-- Index de spécialisation lu du jeu pour le groupe (GetSpecialization), tel quel, ou nil.
function Builds:SpecIndex(group)
  local S = specApi()
  return S and callNumber(S.GetSpecialization, false, false, group or self:ActiveGroup()) or nil
end

---------------------------------------------------------------------------
-- Build obsolète (I2)
---------------------------------------------------------------------------
-- Résultats de Validate : [clé de build:configID:nombre de nœuds] = raison | false ; vidé à BUILDS_CHANGED.
local checked = {}

local function nodeCount(tree)
  local n = 0
  for _ in pairs(tree.nodes) do n = n + 1 end
  return n
end

-- Raison pour laquelle le build ne convient plus à l'arbre (Validate : "missing", "maxrank", "tier",
-- "requires", "toolong"), ou nil s'il est valide ou sans arbre.
function Builds:Obsolete(build, tree)
  if type(build) ~= "table" or type(tree) ~= "table" or type(tree.nodes) ~= "table" then return nil end
  local id = tostring(build.key or build) .. ":" .. tostring(tree.configID) .. ":" .. nodeCount(tree)
  local hit = checked[id]
  if hit == nil then
    local ok, reason = self:Validate(build, tree)
    hit = (not ok) and (reason or "missing") or false
    checked[id] = hit
  end
  return hit or nil
end

if type(Q.On) == "function" then   -- absent quand tools/talentbuilds charge ce fichier hors du jeu
  Q:On("BUILDS_CHANGED", function() checked = {} end)
end

---------------------------------------------------------------------------
-- Choix d'un build fourni pour une spécialisation (I3, I9)
---------------------------------------------------------------------------
local SOURCE_RANK = { ["icy veins"] = 1, wowhead = 2, questify = 3 }

local function sourceRank(b)
  return type(b.source) == "string" and SOURCE_RANK[b.source:lower()] or 9
end

-- Ordre de préférence : build de montée (kind "leveling"), puis le plus de points (51 d'abord), puis la
-- source (Icy Veins, Wowhead, Questify), puis la clé. L'ordre des données n'y joue pas.
local function preferred(a, b)
  local la, lb = a.kind == "leveling", b.kind == "leveling"
  if la ~= lb then return la end
  local na, nb = #(a.order or {}), #(b.order or {})
  if na ~= nb then return na > nb end
  local ra, rb = sourceRank(a), sourceRank(b)
  if ra ~= rb then return ra < rb end
  return tostring(a.key) < tostring(b.key)
end

-- Groupe (arbre 1 à 3) qui reçoit le plus de points du build, d'après la forme fournie de la classe
-- (Q.TalentShapeData), sinon l'arbre lu ; nil si aucun talent n'est reconnu ou en cas d'égalité.
local function dominantGroup(build, class, tree)
  local shape = type(Q.TalentShapeData) == "table" and Q.TalentShapeData[class] or nil
  local nodes = type(tree) == "table" and type(tree.nodes) == "table" and tree.nodes or {}
  local count = {}
  for _, spellID in ipairs(build.order or {}) do
    local s = type(shape) == "table" and shape[spellID] or nodes[spellID]
    local g = type(s) == "table" and s.group or nil
    if g then count[g] = (count[g] or 0) + 1 end
  end
  local best, bestN, tie = nil, 0, false
  for g, n in pairs(count) do
    if n > bestN then best, bestN, tie = g, n, false
    elseif n == bestN then tie = true end
  end
  if tie then return nil end
  return best
end

-- Builds fournis de la spécialisation du groupe, du préféré au moins bon : ceux qui portent le specID lu ;
-- s'il n'y en a aucun (specID de Mainline différents dans Forever, R14), ceux dont le groupe dominant est
-- l'index de spé (1 à 3).
local function specCandidates(group, tree)
  local class = playerClass()
  if not class then return {} end
  local list, out = officialList(class), {}
  local specID = specIDFor(group)
  if specID then
    for _, b in ipairs(list) do
      if b.specID == specID then out[#out + 1] = b end
    end
  end
  if #out == 0 then
    local index = Builds:SpecIndex(group)
    if index == 1 or index == 2 or index == 3 then
      for _, b in ipairs(list) do
        if dominantGroup(b, class, tree) == index then out[#out + 1] = b end
      end
    end
  end
  table.sort(out, preferred)
  return out
end

-- Build actif du personnage pour le groupe (groupe actif par défaut), ou nil.
function Builds:Active(group)
  group = group or self:ActiveGroup()
  return self:Get(charBuilds().active[group])
end

-- Choisit le build actif du groupe (key nil : aucun). Refuse un build inconnu ("unknown") ou invalide pour
-- l'arbre réel (raison de Validate). tree (facultatif) : arbre déjà lu, sinon TalentTree:Read.
function Builds:SetActive(group, key, tree)
  group = group or self:ActiveGroup()
  if key ~= nil then
    local build = self:Get(key)
    if not build then return false, "unknown" end
    -- Arbre illisible (API ou configuration pas encore prête) : on accepte, la validation se refait quand
    -- l'arbre apparaît.
    tree = tree or (Q.TalentTree and Q.TalentTree:Read())
    if tree then
      local ok, reason = self:Validate(build, tree)
      if not ok then return false, reason end
    end
  end
  charBuilds().active[group] = key
  Q:Fire("BUILDS_CHANGED")
  return true
end

-- Build actif obsolète : le joueur l'a choisi, on ne le change pas ; s'il existe un build fourni valide pour
-- sa spécialisation, on le lui dit (TALENT_OBSOLETE_ACTIVE), une fois par build et par personnage.
local function warnObsolete(self, group, build, tree)
  local c = charBuilds()
  if type(c.warned) ~= "table" then c.warned = {} end
  local key = build.key
  if key == nil or c.warned[key] then return end
  for _, b in ipairs(specCandidates(group, tree)) do
    if not self:Obsolete(b, tree) then
      c.warned[key] = true
      Q:Print(Q.L.TALENT_OBSOLETE_ACTIVE, self:Name(build))
      return
    end
  end
end

-- Build suivi pour le groupe : le build actif s'il existe (obsolète compris, signalé : warnObsolete), sinon
-- le build fourni préféré de la spécialisation du joueur (specCandidates), devenu actif (message
-- TALENT_AUTOPICK, une fois par personnage et groupe). Les builds invalides pour l'arbre sont refusés par
-- SetActive. tree (facultatif) : arbre déjà lu. nil si rien ne convient.
function Builds:AutoPick(group, tree)
  group = group or self:ActiveGroup()
  local active = self:Active(group)
  if active then
    if tree and self:Obsolete(active, tree) then warnObsolete(self, group, active, tree) end
    return active
  end
  for _, b in ipairs(specCandidates(group, tree)) do
    if self:SetActive(group, b.key, tree) then
      local picked = charBuilds().picked
      if not picked[group] then
        picked[group] = true
        Q:Print(Q.L.TALENT_AUTOPICK, self:Name(b))
      end
      return b
    end
  end
  return nil
end
