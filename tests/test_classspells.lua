-- Vérification des sorts de classe (Data/ClassSpells.lua et Data/SpellQuests.lua, générés par
-- tools/spells/build_spells.lua) : volume, niveaux, rangs, liens vers les chaînes de quêtes de classe.
local TOC = "Questify/Questify.toc"

local function load()
  return Mock.loadAddon(TOC, { skipGuides = true, extraFiles = { "Questify/Guides/ClassQuestData.lua" } })
end

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

return {
  every_class_has_enough_spells = function(t)
    local Q = load()
    t.ok(type(Q.ClassSpellData) == "table", "ClassSpellData")
    for _, class in ipairs(CLASSES) do
      local list = Q.ClassSpellData and Q.ClassSpellData[class]
      t.ok(type(list) == "table" and #list >= 20, class .. " has at least 20 spells")
    end
  end,

  levels_are_between_1_and_60 = function(t)
    local Q = load()
    for class, list in pairs(Q.ClassSpellData or {}) do
      for _, s in ipairs(list) do
        t.ok(type(s.spellID) == "number", class .. " spellID")
        t.ok(type(s.level) == "number" and s.level >= 1 and s.level <= 60, class .. " " .. tostring(s.spellID) .. " level")
      end
    end
  end,

  shaman_lightning_bolt_is_level_1 = function(t)
    local Q = load()
    local found
    for _, s in ipairs((Q.ClassSpellData or {}).SHAMAN or {}) do
      if s.spellID == 403 then found = s end
    end
    t.ok(found ~= nil, "Lightning Bolt listed")
    t.eq(found and found.level, 1, "Lightning Bolt level")
  end,

  supersedes_points_to_a_spell_of_the_same_class = function(t)
    local Q = load()
    local count = 0
    for class, list in pairs(Q.ClassSpellData or {}) do
      local ids = {}
      for _, s in ipairs(list) do ids[s.spellID] = s end
      for _, s in ipairs(list) do
        if s.supersedes then
          count = count + 1
          local prev = ids[s.supersedes]
          t.ok(prev ~= nil, class .. " " .. s.spellID .. " supersedes " .. tostring(s.supersedes))
          t.ok(prev == nil or prev.level <= s.level, class .. " " .. s.spellID .. " rank order")
        end
      end
    end
    t.ok(count > 0, "some spells have ranks")
  end,

  -- chainKey = « ce sort EXIGE cette chaîne de quêtes » (totems du Chaman), pas « appris par la quête ».
  spell_quest_links_use_existing_chain_keys = function(t)
    local Q = load()
    local keys = {}
    for _, list in pairs(Q.ClassQuestData) do
      for _, chain in ipairs(list) do keys[chain.key] = true end
    end
    t.ok(next(keys) ~= nil, "ClassQuestData loaded")
    t.ok(type(Q.SpellQuestData) == "table", "SpellQuestData")
    local n = 0
    for spellID, key in pairs(Q.SpellQuestData) do
      n = n + 1
      t.ok(keys[key], tostring(spellID) .. " chain " .. tostring(key))
    end
    for spellID, list in pairs(Q.SpellQuestChains) do
      t.ok(Q.SpellQuestData[spellID] == list[1], tostring(spellID) .. " primary chain is first")
      for _, key in ipairs(list) do t.ok(keys[key], tostring(spellID) .. " chain " .. tostring(key)) end
    end
    t.ok(n > 0, "some spells need a quest chain")
    t.ok(Q.SpellQuestChains[3599] == Q.SpellQuestChains[6363], "one shared table per chain")
  end,

  searing_totem_needs_call_of_fire = function(t)
    local Q = load()
    t.eq(Q.SpellQuestData[3599], "SHAMAN_94449", "Searing Totem needs Call of Fire")
  end,

  -- M3 : Sentry Totem est un totem d'air : il demande Call of Air, pas Call of Earth.
  sentry_totem_needs_call_of_air = function(t)
    local Q = load()
    t.eq(Q.SpellQuestData[6495], "SHAMAN_94789", "Sentry Totem needs Call of Air")
    t.eq(Q.SpellQuestData[8071], "SHAMAN_94373", "Stoneskin Totem still needs Call of Earth")
  end,

  no_talent_spell_in_the_spell_list = function(t)
    local Q = load()
    for class, list in pairs(Q.ClassSpellData) do
      local talents = Q.TalentShapeData[class] -- clés : spellID du rang 1 de chaque talent
      t.ok(type(talents) == "table", class .. " shape")
      local n = 0
      for _, s in ipairs(list) do
        n = n + 1
        t.ok(not talents[s.spellID], class .. " talent " .. s.spellID .. " in spell list")
      end
      t.ok(n > 0, class .. " non-empty")
    end
  end,

  mage_level_1_is_fireball_and_no_talent = function(t)
    local Q = load()
    local ids = {}
    for _, s in ipairs(Q.ClassSpellData.MAGE) do
      if s.level == 1 then ids[#ids + 1] = s.spellID end
    end
    local set = {}
    for _, id in ipairs(ids) do set[id] = true end
    t.ok(set[133], "Fireball at level 1")
    for _, bad in ipairs({ 12472, 12484, 29077, 12355, 12494, 11129 }) do t.ok(not set[bad], "no " .. bad) end
  end,

  shaman_level_1_has_lightning_bolt_and_no_mana_tide = function(t)
    local Q = load()
    local set, all = {}, {}
    for _, s in ipairs(Q.ClassSpellData.SHAMAN) do
      all[s.spellID] = true
      if s.level == 1 then set[s.spellID] = true end
    end
    t.ok(set[403], "Lightning Bolt at level 1")
    for _, bad in ipairs({ 16190, 17354, 17359, 1325256, 425336 }) do t.ok(not all[bad], "no " .. bad) end
  end,

  a_spell_has_at_most_one_successor = function(t)
    local Q = load()
    -- liste blanche des remplacés que la DB2 donne explicitement à plusieurs sorts (vide)
    local allowed = {}
    for class, list in pairs(Q.ClassSpellData) do
      local seen = {}
      for _, s in ipairs(list) do
        if s.supersedes and not allowed[s.supersedes] then
          t.ok(not seen[s.supersedes], class .. " " .. s.supersedes .. " superseded by " .. tostring(seen[s.supersedes]) .. " and " .. s.spellID)
          seen[s.supersedes] = s.spellID
        end
      end
    end
    local function find(class, id)
      for _, s in ipairs(Q.ClassSpellData[class]) do if s.spellID == id then return s end end
    end
    t.eq(find("MAGE", 10151).supersedes, 10150, "Fireball 10151 follows 10150")
    t.eq(find("MAGE", 25306).supersedes, nil, "Fireball 25306 is a separate entry")
    t.eq(find("MAGE", 28271).supersedes, nil, "Polymorph form 28271 is a separate entry")
  end,

  racial_class_spells_carry_a_race_mask = function(t)
    local Q = load()
    local feedback
    for _, s in ipairs(Q.ClassSpellData.PRIEST) do
      if s.spellID == 13896 then feedback = s end
    end
    t.ok(feedback ~= nil, "Feedback listed")
    t.ok(feedback and feedback.races and Q.Util.HasBit(feedback.races, 1), "Feedback mask includes Human")
    local free = 0
    for _, s in ipairs(Q.ClassSpellData.PRIEST) do
      if s.races == nil then free = free + 1 end
    end
    t.ok(free > 50, "most priest spells are not race-restricted")
  end,
}
