-- Tests des builds de talents (Q.Builds) : validation, points dus, écart, build tiré de l'arbre.
local TOC = "Questify/Questify.toc"

-- Arbre Chaman réduit : Concussion 5 rangs (palier 1), Elemental Alacrity (palier 2, 3 rangs), Call of
-- Thunder (palier 3), Lightning Overload (palier 5 requiert Alacrity), Lava Burst absent.
local function treeWith(ranks, unspent)
  ranks = ranks or {}
  local defs = {
    { 16035, 1, 3, 5, 1 }, { 16039, 1, 2, 5, 2 }, { 16578, 2, 3, 3, 3 }, { 16120, 3, 2, 1, 4 },
    { 408438, 3, 3, 3, 5, requires = 3 },
  }
  local tree = { configID = 1, treeID = 1, groups = { { groupID = 1, name = "Élémentaire", spent = 0 } },
    nodes = {}, byNodeID = {}, unspent = unspent or 0 }
  for _, d in ipairs(defs) do
    local node = { nodeID = 100 + d[5], entryID = 200 + d[5], spellID = d[1], group = 1, tier = d[2],
      col = d[3], maxRanks = d[4], rank = ranks[d[1]] or 0, requires = d.requires and { 100 + d.requires } or {} }
    tree.nodes[d[1]] = node
    tree.byNodeID[node.nodeID] = node
  end
  return tree
end

local function rep(spellID, n, into)
  into = into or {}
  for _ = 1, n do into[#into + 1] = spellID end
  return into
end

local function build(order) return { order = order } end

local function deepcopy(v)
  if type(v) ~= "table" then return v end
  local o = {}
  for k, x in pairs(v) do o[k] = deepcopy(x) end
  return o
end

local function installGroups(num, active)
  C_SpecializationInfo.GetNumSpecGroups = function() return num end
  C_SpecializationInfo.GetActiveSpecGroup = function() return active end
end

-- Builds fournis de test (même format que Data/TalentBuilds.lua).
local function injectData(Q)
  Q.TalentBuildData = {
    SHAMAN = {
      { key = "ele1", class = "SHAMAN", specID = 262, name = { enUS = "Elemental EN", frFR = "Élémentaire FR" },
        source = "test", url = "x", date = "2026-01-01", official = true, order = { 16035, 16035 } },
      { key = "enh1", class = "SHAMAN", specID = 263, name = { enUS = "Enhancement EN", frFR = "Amélioration FR" },
        source = "test", url = "x", date = "2026-01-01", official = true, order = { 16035 } },
    },
  }
  -- un second build Élémentaire, et un build périmé (spellID absent de l'arbre)
  table.insert(Q.TalentBuildData.SHAMAN, { key = "ele2", class = "SHAMAN", specID = 262,
    name = { enUS = "Elemental 2" }, official = true, order = { 16039 } })
  table.insert(Q.TalentBuildData.SHAMAN, { key = "bad", class = "SHAMAN", specID = 262,
    name = { enUS = "Bad" }, official = true, order = { 999999 } })
end

-- Chaman niveau 30, spé Élémentaire (index 1), groupes de spé simulés.
local function loadSpec(num, active)
  local Ext = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")
  Mock.player.classFile = "SHAMAN"; Mock.player.level = 30
  Ext.install()
  Mock.spec.index = 1
  installGroups(num or 2, active or 1)
  local Q = Mock.loadAddon(TOC, { skipGuides = true })
  injectData(Q)
  return Q, Ext
end

local function load()
  return Mock.loadAddon(TOC, { skipGuides = true })
end

-- Classe et spé données (index 1 à 3), avec les builds fournis réels (Data/TalentBuilds.lua) ; specIDs
-- [index] = specID lu par GetSpecializationInfo ; arbre illisible (SetActive accepte, la forme fournie sert).
local function loadReal(class, index, specIDs)
  local Ext = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")
  Mock.player.classFile = class; Mock.player.level = 30
  Ext.install()
  Mock.spec.index = index
  installGroups(1, 1)
  C_SpecializationInfo.GetSpecializationInfo = function(i) return specIDs[i] or 0 end
  local Q = Mock.loadAddon(TOC, { skipGuides = true })
  Q.TalentTree.Read = function() return nil, "noapi" end
  Q.char.builds = { active = {}, picked = {} }
  return Q
end

local function official(key, specID, kind, n, source, spell)
  local order = {}
  for i = 1, n do order[i] = spell or 16035 end
  return { key = key, class = "SHAMAN", specID = specID, kind = kind, name = { enUS = key }, source = source,
    official = true, order = order }
end

return {
  validate_ok = function(t)
    local Q = load()
    local order = rep(16035, 5)
    rep(16039, 5, order); rep(16578, 3, order)
    t.eq({ Q.Builds:Validate(build(order), treeWith()) }, { true })
  end,

  validate_missing_reports_index = function(t)
    local Q = load()
    local order = rep(16035, 5)
    order[6] = 51505
    t.eq({ Q.Builds:Validate(build(order), treeWith()) }, { false, "missing", 6 })
  end,

  validate_maxrank = function(t)
    local Q = load()
    t.eq({ Q.Builds:Validate(build(rep(16035, 6)), treeWith()) }, { false, "maxrank", 6 })
  end,

  validate_tier = function(t)
    local Q = load()
    t.eq({ Q.Builds:Validate(build({ 16578 }), treeWith()) }, { false, "tier", 1 })
  end,

  validate_requires = function(t)
    local Q = load()
    local order = rep(16035, 5)
    rep(16039, 5, order); rep(16578, 2, order); rep(16120, 1, order); order[#order + 1] = 408438
    t.eq({ Q.Builds:Validate(build(order), treeWith()) }, { false, "requires", 14 })
  end,

  validate_toolong = function(t)
    local Q = load()
    local tree = treeWith()
    local big = {}
    for i = 1, 52 do big[i] = 16035 end
    t.eq({ Q.Builds:Validate(build(big), tree) }, { false, "maxrank", 6 })
    local ok, reason, index = Q.Builds:Validate(build(big), (function()
      local tr = treeWith(); tr.nodes[16035].maxRanks = 99; return tr end)())
    t.eq({ ok, reason, index }, { false, "toolong", 52 })
  end,

  due_lists_unspent_points_in_order = function(t)
    local Q = load()
    local tree = treeWith({ [16035] = 3 }, 1)
    local due = Q.Builds:Due(build(rep(16035, 5)), tree)
    t.eq(#due, 1)
    t.eq(due[1].spellID, 16035); t.eq(due[1].rank, 4); t.eq(due[1].level, 13)
    t.eq(due[1].node, tree.nodes[16035])
  end,

  due_five_points = function(t)
    local Q = load()
    local due = Q.Builds:Due(build(rep(16035, 5)), treeWith({}, 5))
    t.eq(#due, 5)
    for i, d in ipairs(due) do t.eq(d.rank, i); t.eq(d.level, 9 + i) end
  end,

  due_skips_impossible = function(t)
    local Q = load()
    -- 16578 (palier 2) impossible tant que le groupe n'a pas 5 points : sauté, le point suivant passe
    local due = Q.Builds:Due(build({ 16578, 16035 }), treeWith({}, 1))
    t.eq(#due, 1)
    t.eq(due[1].spellID, 16035); t.eq(due[1].level, 11)
  end,

  deviates_when_off_build = function(t)
    local Q = load()
    local b = build(rep(16035, 5))
    t.eq(Q.Builds:Deviates(b, treeWith({ [16035] = 3 })), false)
    t.eq(Q.Builds:Deviates(b, treeWith({ [16035] = 2, [16039] = 1 })), true)
    t.eq(Q.Builds:Deviates(b, treeWith()), false)
  end,

  fromtree_roundtrip_validates = function(t)
    local Q = load()
    local tree = treeWith({ [16035] = 5, [16039] = 5, [16578] = 3, [16120] = 1, [408438] = 2 })
    local b = Q.Builds:FromTree(tree, "SHAMAN", 262)
    t.eq(#b.order, 16)
    t.eq(b.official, false); t.eq(b.class, "SHAMAN"); t.eq(b.specID, 262)
    t.eq(b.order[1], 16039, "palier 1 par colonne")
    t.eq({ Q.Builds:Validate(b, tree) }, { true })
    t.eq(Q.Builds:Deviates(b, tree), false)
  end,

  -- Stockage, build actif, choix automatique (tâche 3)
  save_official_makes_copy = function(t)
    local Q, Ext = loadSpec()
    local list = Q.Builds:List("SHAMAN")
    t.eq(#list, 4)
    t.eq(list[1].key, "ele1", "fournis d'abord")
    local copy = { key = "ele1", class = "SHAMAN", specID = 262, official = true, name = "Mon build", order = { 16035 } }
    local key = Q.Builds:Save(copy)
    t.ok(key ~= "ele1" and key:match("^u"), "nouvelle clé")
    t.eq(#Q.TalentBuildData.SHAMAN, 4, "fournis intacts")
    t.eq(#Q.db.builds.SHAMAN, 1)
    local saved = Q.Builds:Get(key)
    t.eq(saved.official, false); t.eq(saved.name, "Mon build"); t.eq(saved.order, { 16035 })
    t.eq(Q.Builds:Get("ele1").official, true)
    -- une clé personnelle enregistrée deux fois : mise à jour, pas de doublon
    saved.name = "Renommé"
    t.eq(Q.Builds:Save(saved), key)
    t.eq(#Q.db.builds.SHAMAN, 1)
    t.eq(Q.Builds:Get(key).name, "Renommé")
    -- deux builds dans la même seconde : clés distinctes
    local k2 = Q.Builds:Save({ class = "SHAMAN", order = {} })
    t.ok(k2 ~= key)
    t.eq(#Q.Builds:List("SHAMAN"), 6)
  end,

  active_is_per_character_and_group = function(t)
    local Q, Ext = loadSpec()
    local fired = 0
    Q:On("BUILDS_CHANGED", function() fired = fired + 1 end)
    t.eq({ Q.Builds:SetActive(1, "ele1") }, { true })
    t.eq({ Q.Builds:SetActive(2, "ele2") }, { true })
    t.ok(fired >= 2, "BUILDS_CHANGED")
    t.eq(Q.Builds:Active(1).key, "ele1"); t.eq(Q.Builds:Active(2).key, "ele2")
    t.eq(Q.char.builds.active[1], "ele1")
    -- autre personnage, même compte
    local db, char1 = deepcopy(QuestifyDB), deepcopy(QuestifyCharDB)
    Mock.reset(); Ext.install()
    Mock.player.classFile = "SHAMAN"; Mock.player.level = 30
    Mock.spec.index = 1
    installGroups(2, 1)
    local Q2 = Mock.loadAddon(TOC, { skipGuides = true, savedVariables = { QuestifyDB = db } })
    injectData(Q2)
    t.eq(Q2.Builds:Active(1), nil, "pas de build actif sur l'autre perso")
    t.eq(Q2.Builds:Active(2), nil)
    Q2.Builds:SetActive(1, "ele2")
    t.eq(Q2.Builds:Active(1).key, "ele2")
    -- le premier personnage garde le sien
    Mock.reset(); Ext.install()
    Mock.player.classFile = "SHAMAN"; Mock.player.level = 30
    installGroups(2, 1)
    local Q3 = Mock.loadAddon(TOC, { skipGuides = true, savedVariables = { QuestifyDB = db, QuestifyCharDB = char1 } })
    injectData(Q3)
    t.eq(Q3.Builds:Active(1).key, "ele1")
  end,

  setactive_refuses_obsolete = function(t)
    local Q = loadSpec()
    local tree = treeWith()
    Q.TalentTree.Read = function() return tree end
    local ok, reason = Q.Builds:SetActive(1, "bad")
    t.eq(ok, false); t.eq(reason, "missing")
    t.eq(Q.Builds:Active(1), nil)
    t.eq({ Q.Builds:SetActive(1, "nope") }, { false, "unknown" })
    -- arbre illisible : accepté (validé plus tard, quand l'arbre apparaît)
    Q.TalentTree.Read = function() return nil, "noapi" end
    t.eq({ Q.Builds:SetActive(1, "bad") }, { true })
    t.eq(Q.Builds:Active(1).key, "bad")
  end,

  autopick_matches_spec = function(t)
    local Q = loadSpec()
    Q.TalentTree.Read = function() return nil, "noapi" end
    local b = Q.Builds:AutoPick(1)
    t.eq(b.key, "ele1", "spé Élémentaire")
    t.eq(b.specID, 262)
    t.eq(Q.Builds:Active(1).key, "ele1")
    t.eq(Mock.countPrinted("Talent build followed"), 1)
    t.eq(Q.Builds:AutoPick(1).key, "ele1")
    t.eq(Mock.countPrinted("Talent build followed"), 1, "message une seule fois")
    -- le joueur change de build actif : AutoPick respecte son choix
    Q.Builds:SetActive(1, "ele2")
    t.eq(Q.Builds:AutoPick(1).key, "ele2")
    -- spé sans build fourni : rien
    Mock.spec.index = 3
    t.eq(Q.Builds:AutoPick(2), nil)
  end,

  groups_single_when_locked = function(t)
    local Q = loadSpec(1, 1)
    t.eq(Q.Builds:Groups(), { 1 })
    t.eq(Q.Builds:ActiveGroup(), 1)
    local Q2 = loadSpec(2, 2)
    t.eq(Q2.Builds:Groups(), { 1, 2 })
    t.eq(Q2.Builds:ActiveGroup(), 2)
    C_SpecializationInfo.GetNumSpecGroups = nil
    t.eq(Q2.Builds:Groups(), { 1 })
  end,

  personal_builds_shared_by_class_on_account = function(t)
    local Q, Ext = loadSpec()
    local key = Q.Builds:Save({ class = "SHAMAN", specID = 262, name = "Perso", order = { 16035 } })
    local db = deepcopy(QuestifyDB)
    Mock.reset(); Ext.install()
    Mock.player.classFile = "SHAMAN"; Mock.player.level = 30
    Mock.spec.index = 1
    installGroups(1, 1)
    local Q2 = Mock.loadAddon(TOC, { skipGuides = true, savedVariables = { QuestifyDB = db } })
    injectData(Q2)
    t.eq(Q2.Builds:Get(key).name, "Perso")
    t.eq(#Q2.Builds:List("SHAMAN"), 5)
    t.eq(#Q2.Builds:List("MAGE"), 0)
    t.ok(Q2.Builds:Delete(key))
    t.eq(Q2.Builds:Get(key), nil)
    t.eq(#Q2.Builds:List("SHAMAN"), 4)
    t.eq(Q2.Builds:Delete("ele1"), false, "fourni non supprimable")
  end,

  name_by_locale = function(t)
    local Q = loadSpec()
    t.eq(Q.Builds:Name(Q.Builds:Get("ele1")), "Elemental EN")
    Mock.locale = "frFR"
    t.eq(Q.Builds:Name(Q.Builds:Get("ele1")), "Élémentaire FR")
    Mock.locale = "deDE"
    t.eq(Q.Builds:Name(Q.Builds:Get("ele1")), "Elemental EN")
    t.eq(Q.Builds:Name({ key = "k" }), "k")
    t.eq(Q.Builds:Name({ name = "Perso" }), "Perso")
  end,

  fromtree_deterministic = function(t)
    local Q = load()
    local tree = treeWith({ [16035] = 1, [16039] = 1 })
    tree.nodes[16035].col = 1; tree.nodes[16039].col = 1
    for _ = 1, 5 do
      t.eq(Q.Builds:FromTree(tree, "SHAMAN", 262).order, { 16035, 16039 })
    end
  end,

  -- I3 : Farouche -> build de montée (pas le build tank de donjon rangé avant lui) ; Vindicte -> le build
  -- de 51 points (pas le build Wowhead de 45).
  autopick_prefers_leveling_then_full_builds = function(t)
    local Q = loadReal("DRUID", 2, { 102, 103, 105 })
    local b = Q.Builds:AutoPick(1)
    t.eq(b.kind, "leveling", "Feral: leveling build")
    t.eq(b.key, "WOWHEAD_DRUID_FERAL")
    Mock.reset()
    Q = loadReal("PALADIN", 3, { 65, 66, 70 })
    b = Q.Builds:AutoPick(1)
    t.eq(#b.order, 51, "Retribution: full build")
    t.eq(b.key, "QUESTIFY_PALADIN_RETRIBUTION")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I3 : ordre de préférence sans tenir compte de l'ordre des données : leveling, points, source, clé.
  autopick_preference_order = function(t)
    local Q = loadSpec()
    Q.TalentTree.Read = function() return nil, "noapi" end
    local function pick(list)
      Q.TalentBuildData = { SHAMAN = list }
      Q.char.builds = { active = {}, picked = {} }
      return Q.Builds:AutoPick(1).key
    end
    t.eq(pick({ official("dungeon", 262, "dungeon", 51, "Icy Veins"), official("lev", 262, "leveling", 10, "questify") }),
      "lev", "leveling first")
    t.eq(pick({ official("short", 262, "leveling", 45, "Icy Veins"), official("full", 262, "leveling", 51, "questify") }),
      "full", "more points next")
    t.eq(pick({ official("q", 262, "leveling", 51, "questify"), official("w", 262, "leveling", 51, "wowhead"),
      official("iv", 262, "leveling", 51, "Icy Veins") }), "iv", "Icy Veins, then Wowhead, then Questify")
    t.eq(pick({ official("q", 262, "leveling", 51, "questify"), official("w", 262, "leveling", 51, "wowhead") }), "w")
    t.eq(pick({ official("b", 262, "leveling", 51, "wowhead"), official("a", 262, "leveling", 51, "wowhead") }), "a",
      "then key")
  end,

  -- I9 : specID du jeu inconnu des builds fournis -> index de spé = groupe qui reçoit le plus de points.
  autopick_falls_back_on_spec_index = function(t)
    local Q = loadReal("SHAMAN", 1, { 9001, 9002, 9003 })
    local b = Q.Builds:AutoPick(1)
    t.ok(b, "a build is picked")
    t.eq(b.key, "IV_SHAMAN_ELEMENTAL", "index 1 -> Elemental tree")
    Mock.reset()
    Q = loadReal("SHAMAN", 3, { 9001, 9002, 9003 })
    b = Q.Builds:AutoPick(1)
    t.eq(b and b.key, "IV_SHAMAN_RESTORATION", "index 3 -> Restoration tree")
    t.eq(Q.Builds:SpecIndex(1), 3)
    t.eq(Q.Builds:SpecID(1), 9003)
    local report = Q.Diagnostics:Report()
    t.ok(report:find("Talent spec: group 1, index 3, specID 9003", 1, true), "spec index and specID in /qf bug")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I9 : le repli ne joue pas quand un build fourni porte le specID lu.
  autopick_spec_id_wins_over_index = function(t)
    local Q = loadReal("SHAMAN", 1, { 264, 263, 262 })
    t.eq(Q.Builds:AutoPick(1).key, "IV_SHAMAN_RESTORATION", "specID 264 read at index 1")
  end,

  -- I2 : build actif obsolète : reconnu (cache), gardé (le joueur l'a choisi), signalé une fois par build
  -- quand un build fourni valide existe pour la spé.
  obsolete_active_build_kept_and_reported_once = function(t)
    local Q = loadSpec()
    local tree = treeWith({}, 2)
    Q.db.builds = { SHAMAN = { { key = "u1", class = "SHAMAN", name = "Mine", official = false,
      order = { 51505, 16035 } } } }
    Q.char.builds = { active = { [1] = "u1" }, picked = {} }
    t.eq(Q.Builds:Obsolete(Q.Builds:Get("u1"), tree), "missing")
    t.eq(Q.Builds:Obsolete(Q.Builds:Get("ele1"), tree), nil)
    Mock.prints = {}
    t.eq(Q.Builds:AutoPick(1, tree).key, "u1", "not changed on its own")
    local msg = string.format(Q.L.TALENT_OBSOLETE_ACTIVE, "Mine")
    t.eq(Mock.countPrinted(msg), 1, "told once")
    Q.Builds:AutoPick(1, tree)
    t.eq(Mock.countPrinted(msg), 1, "not twice")
    -- aucun build fourni valide pour la spé : rien à proposer, rien dit
    Q.char.builds.warned = nil
    Q.TalentBuildData = { SHAMAN = { official("gone", 262, "leveling", 3, "wowhead", 51505) } }
    Mock.prints = {}
    Q.Builds:AutoPick(1, tree)
    t.eq(Mock.countPrinted(msg), 0)
  end,

  -- I2 : la validation du build actif est gardée en cache (clé de build, configID, nombre de nœuds) et
  -- refaite quand les builds changent.
  obsolete_check_is_cached = function(t)
    local Q = loadSpec()
    local tree = treeWith({}, 1)
    local calls = 0
    local validate = Q.Builds.Validate
    Q.Builds.Validate = function(self, ...) calls = calls + 1; return validate(self, ...) end
    local b = Q.Builds:Get("ele1")
    Q.Builds:Obsolete(b, tree); Q.Builds:Obsolete(b, tree)
    t.eq(calls, 1, "cached")
    tree.configID = 2
    Q.Builds:Obsolete(b, tree)
    t.eq(calls, 2, "new config")
    tree.nodes[999] = { nodeID = 999, spellID = 999, group = 1, tier = 1, col = 4, maxRanks = 1, rank = 0, requires = {} }
    Q.Builds:Obsolete(b, tree)
    t.eq(calls, 3, "node count changed")
    Q:Fire("BUILDS_CHANGED")
    Q.Builds:Obsolete(b, tree)
    t.eq(calls, 4, "builds changed")
  end,
}
