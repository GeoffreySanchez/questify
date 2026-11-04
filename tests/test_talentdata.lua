-- Vérification des builds fournis (Data/TalentBuilds.lua, généré par tools/talentbuilds/build.lua) :
-- 51 points au plus, chaque talent connu de la forme de l'arbre de sa classe, et le build passe
-- Q.Builds:Validate sur un arbre reconstruit depuis cette forme.
local TOC = "Questify/Questify.toc"

local function load()
  return Mock.loadAddon(TOC, { skipGuides = true })
end

local function elemental(Q)
  for _, b in ipairs(Q.TalentBuildData.SHAMAN or {}) do
    if b.key == "IV_SHAMAN_ELEMENTAL" then return b end
  end
end

return {
  every_official_build_is_valid = function(t)
    local Q = load()
    local count = 0
    for class, list in pairs(Q.TalentBuildData) do
      local shape = Q.TalentShapeData[class]
      t.ok(type(shape) == "table", class .. " shape")
      local tree = Q.TalentTree:FromShape(shape)
      for _, b in ipairs(list) do
        count = count + 1
        local label = class .. " " .. tostring(b.key)
        t.eq(b.class, class, label .. " class")
        t.ok(type(b.specID) == "number", label .. " specID")
        t.ok(type(b.name) == "table" and b.name.enUS and b.name.frFR, label .. " name")
        t.ok(b.official == true and b.source and b.url and b.date, label .. " metadata")
        t.ok(b.kind == "leveling" or b.kind == "dungeon", label .. " kind")
        t.ok(#b.order >= 1 and #b.order <= 51, label .. " length")
        for i, spellID in ipairs(b.order) do
          t.ok(shape[spellID] ~= nil, label .. " spell " .. tostring(spellID) .. " at " .. i .. " unknown")
        end
        local ok, reason, at = Q.Builds:Validate(b, tree)
        t.ok(ok, label .. " invalid: " .. tostring(reason) .. " at " .. tostring(at))
      end
    end
    t.ok(count >= 9, "at least one build per class")
  end,

  all_nine_classes_have_a_shape_and_a_build = function(t)
    local Q = load()
    for _, class in ipairs({ "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK",
        "WARRIOR" }) do
      t.ok(#(Q.TalentBuildData[class] or {}) >= 1, class)
      t.ok(next(Q.TalentShapeData[class] or {}) ~= nil, class .. " shape")
      t.ok(next(Q.TalentIndexData[class] or {}) ~= nil, class .. " index")
    end
  end,

  stale_calculator_builds_are_excluded = function(t)
    local Q = load()
    for _, list in pairs(Q.TalentBuildData) do
      for _, b in ipairs(list) do
        t.ok(b.key ~= "IV_DRUID_FERAL" and b.key ~= "IV_ROGUE_SUBTLETY", b.key)
      end
    end
  end,

  elemental_shaman_known_points = function(t)
    local Q = load()
    local b = elemental(Q)
    t.ok(b, "build IV_SHAMAN_ELEMENTAL")
    t.eq(#b.order, 51)
    t.eq(b.order[1], 16035)   -- niveau 10
    t.eq(b.order[22], 408438) -- Surcharge de la foudre, niveau 31
    t.eq(b.order[31], 16166)  -- Maîtrise de la foudre, niveau 40
    t.eq(b.order[32], 16179)  -- Focalisation des marées, niveau 41
    t.eq(b.source, "Icy Veins")
    t.eq(b.name.frFR, "Élémentaire — Leveling")
    t.eq(b.name.enUS, "Elemental — Leveling")
    t.eq(b.official, true)
  end,

  index_maps_characters_to_known_spells = function(t)
    local Q = load()
    for class, index in pairs(Q.TalentIndexData) do
      for char, spellID in pairs(index) do
        t.ok(Q.TalentShapeData[class][spellID], class .. " " .. char)
      end
    end
  end,

  shape_tree_has_unspent_zero_and_rules = function(t)
    local Q = load()
    local tree = Q.TalentTree:FromShape(Q.TalentShapeData.SHAMAN)
    t.eq(tree.unspent, 0)
    local node = tree.nodes[16035]
    t.ok(node and node.rank == 0 and node.tier == 1, "first node")
    t.eq(tree.byNodeID[node.nodeID], node)
  end,

  adjusted_builds_exist_and_validate = function(t)
    local Q = load()
    local found = {}
    for class, list in pairs(Q.TalentBuildData) do
      local tree = Q.TalentTree:FromShape(Q.TalentShapeData[class])
      for _, b in ipairs(list) do
        if b.adjusted then
          found[#found + 1] = b.key
          t.ok(Q.Builds:Validate(b, tree), b.key .. " adjusted build invalid")
        end
      end
    end
    -- Enhancement n'est pas réparable avec la table relevée (huit points seulement avant le palier 3 de son
    -- arbre : ordre illégal quel que soit le report) ; à rétablir ici quand le relevé sera refait.
    t.ok(#found >= 1, "at least one adjusted build")
  end,

  names_are_generic_and_unique_per_class = function(t)
    local Q = load()
    for class, list in pairs(Q.TalentBuildData) do
      local seen = {}
      for _, b in ipairs(list) do
        for _, lang in ipairs({ "enUS", "frFR" }) do
          local n = b.name[lang]
          t.ok(not n:find("Icy Veins", 1, true) and not n:find("Wowhead", 1, true), b.key .. " " .. lang .. " source in name")
          t.ok(not seen[lang .. n], class .. " duplicate name " .. n)
          seen[lang .. n] = true
        end
      end
    end
  end,

  -- M2 : un build fourni de moins de 51 points le dit dans son nom (« · partial » / « · partiel ») ; les
  -- builds complets non.
  partial_builds_are_named_partial = function(t)
    local Q = load()
    local partial = 0
    for class, list in pairs(Q.TalentBuildData) do
      for _, b in ipairs(list) do
        local short = #b.order < 51
        t.eq(b.name.enUS:find(" · partial", 1, true) ~= nil, short, class .. " " .. b.key .. " enUS")
        t.eq(b.name.frFR:find(" · partiel", 1, true) ~= nil, short, class .. " " .. b.key .. " frFR")
        if short then partial = partial + 1 end
      end
    end
    t.ok(partial >= 3, "Frost, Retribution and Restoration dungeon Wowhead builds")
    local frost
    for _, b in ipairs(Q.TalentBuildData.MAGE) do if b.key == "WOWHEAD_MAGE_FROST" then frost = b end end
    t.ok(frost and frost.name.frFR:find("partiel", 1, true), "Frost Wowhead (24 points)")
  end,

  -- I8 : version du calculateur Icy Veins des index livrés, pour contrôler un lien importé.
  index_version_is_shipped = function(t)
    local Q = load()
    t.eq(Q.TalentIndexVersion, "70755-d1899b7d")
  end,
}
