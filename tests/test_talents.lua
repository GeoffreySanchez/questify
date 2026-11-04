-- Tests des talents (Q.Talents, alerte du suivi, Q.UI.TalentPicker).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

-- Deux arbres de test : { [tab] = { { name, tier, column, maxRank } } }, rangs dans `ranks`.
local TREES = {
  { name = "Arms", talents = { { "Improved Heroic Strike", 1, 1, 3 }, { "Deflection", 1, 2, 5 }, { "Tactical Mastery", 2, 2, 5 } } },
  { name = "Fury", talents = { { "Cruelty", 1, 2, 5 } } },
}
local ranks, opened, traits

local CONFIG, TREE, CURRENCY = 7001, 801, 9001

local function spentRanks()
  local n = 0
  for _, r in pairs(ranks) do n = n + r end
  return n
end

-- API Forever (famille Mainline 12.x, Blizzard_PlayerSpells/Camelot/ClassTalents) : un arbre de
-- classe C_Traits dont les trois arbres classiques sont des groupes de nœuds. Nœud n° tab*100+i ;
-- entrée = nœud + 10000 ; définition = nœud + 20000 ; sort = nœud + 30000. La monnaie de l'arbre
-- vaut niveau - 9 - rangs placés (comme le serveur), sauf traits.quantity imposé.
-- GetNumTalentTabs, GetTalentInfo et UnitCharacterPoints n'existent pas dans Forever.
local function installForever()
  traits = { configID = CONFIG, quantity = nil }
  local nodes, byId = {}, {}
  for tab, tree in ipairs(TREES) do
    for i, tal in ipairs(tree.talents) do
      local n = { id = tab * 100 + i, tab = tab, i = i, t = tal }
      nodes[#nodes + 1] = n
      byId[n.id] = n
    end
  end
  local function rankOf(n) return ranks[n.tab .. ":" .. n.i] or 0 end
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
  GetNumTalentTabs, GetTalentTabInfo, GetNumTalents, GetTalentInfo = nil, nil, nil, nil
  UnitCharacterPoints, GetUnspentTalentPoints = nil, nil
end

-- Ancienne API Classic des arbres (absente de Forever) : seuls les presets (Talents:Find, Next) la
-- lisent encore ; installée par les tests de conseils de build.
local function installLegacyTree()
  GetNumTalentTabs = function() return #TREES end
  GetTalentTabInfo = function(tab) return TREES[tab] and TREES[tab].name end
  GetNumTalents = function(tab) return TREES[tab] and #TREES[tab].talents or 0 end
  GetTalentInfo = function(tab, i)
    local t = TREES[tab] and TREES[tab].talents[i]
    if not t then return nil end
    return t[1], 132000 + i, t[2], t[3], ranks[tab .. ":" .. i] or 0, t[4]
  end
end

local function install(opts)
  ranks = {}
  opened = 0
  installForever()
  if opts and opts.legacy then installLegacyTree() end
  ToggleTalentFrame = function() opened = opened + 1 end
end

local function load(opts)
  Ext.install()
  install(opts)
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  Q.TalentBuildData.WARRIOR = {
    { key = "W_TEST", kind = "leveling", title = { enUS = "Arms leveling", frFR = "Armes montée" },
      order = { { 1, 1, 2 }, { 1, 1, 2 }, { 1, 2, 2 } } },
    { key = "W_DUNGEON", kind = "dungeon", title = { enUS = "Protection dungeons" }, order = { { 1, 1, 1 } } },
  }
  return Q
end

local function levelUp(lvl)
  Mock.player.level = lvl
  Mock.fire("PLAYER_LEVEL_UP", lvl)
  Mock.advance(0.6)
end

return {
  no_alert_before_level_10 = function(t)
    local Q = load()
    levelUp(9)
    t.eq(Q.Talents:Unspent(), 0)
    t.eq(Q.Talents:Alert(), nil)
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
  end,

  level_10_announces_and_asks_for_a_preset = function(t)
    local Q = load({ legacy = true })
    levelUp(10)
    t.eq(Q.Talents:Unspent(), 1, "tree currency")
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(Mock.countPrinted(Q.L.TALENT_FIRST), 1)
    local P = Q.UI.TalentPicker
    t.ok(P.frame and P.frame:IsShown(), "preset asked at level 10")
    t.eq(#P.shownCards, 2, "one card per preset")
    t.eq(P.shownCards[1].kind, "leveling"); t.eq(P.shownCards[2].kind, "dungeon")
    t.eq(#P.shownCards[1].tiles, 8, "rotating planet: world map tiles behind a round mask")
    P.frame:GetScript("OnUpdate")(P.frame, 1)
    t.ok(P.shownCards[2].anims[1]:IsPlaying(), "portal swirls")
    P.shownCards[1]:GetScript("OnClick")(P.shownCards[1])
    t.ok(not P.frame:IsShown())
    t.eq(Q.char.talentPreset, "W_TEST")
    local nxt = Q.Talents:Next()
    t.eq(nxt.name, "Deflection"); t.eq(nxt.rank, 0); t.eq(nxt.tabName, "Arms")
    t.eq(Q.UI.Tracker.talentText:GetText(), string.format(Q.L.UI_TALENT_ALERT_NEXT, "Deflection"))
    t.eq(#Mock.errors, 0)
  end,

  advice_follows_ranks_and_each_level = function(t)
    local Q = load({ legacy = true })
    Q.Talents:Choose("W_TEST")
    levelUp(10)
    ranks["1:2"] = 1
    Mock.fire("CHARACTER_POINTS_CHANGED")
    t.eq(Q.Talents:Alert(), nil, "point spent")
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
    levelUp(11)
    t.eq(Q.Talents:Next().name, "Deflection", "second rank")
    t.eq(Mock.countPrinted(string.format(Q.L.TALENT_LEVEL_ADVICE, "Deflection (Arms, rank 2/5)")), 1)
    ranks["1:2"] = 2
    levelUp(12)
    t.eq(Q.Talents:Next().name, "Tactical Mastery")
  end,

  client_points_api_wins = function(t)
    local Q = load()
    levelUp(12)
    t.eq(Q.Talents:Unspent(), 3, "tree currency")
    UnitCharacterPoints = function() return 0 end
    t.eq(Q.Talents:Unspent(), 0, "client says no point left")
  end,

  click_opens_talent_frame_not_in_combat = function(t)
    local Q = load()
    levelUp(10)
    local A = Q.UI.Tracker.talentAlert
    A:GetScript("OnClick")(A)
    t.eq(opened, 1)
    Mock.player.combat = true
    A:GetScript("OnClick")(A)
    t.eq(opened, 1, "not in combat")
    Mock.player.combat = false
  end,

  unknown_tree_gives_no_advice = function(t)
    local Q = load({ legacy = true })
    Q.TalentBuildData.WARRIOR[1].order = { { 3, 5, 1 } }
    Q.Talents:Choose("W_TEST")
    levelUp(10)
    t.eq(Q.Talents:Next(), nil, "tree of another game version: no wrong advice")
    t.ok(Q.UI.Tracker.talentAlert:IsShown(), "reminder still there")
  end,

  option_off = function(t)
    local Q = load()
    Q.Settings:Set("talentAlert", false)
    levelUp(10)
    t.eq(Q.Talents:Alert(), nil)
    t.eq(Mock.countPrinted(Q.L.TALENT_FIRST), 0)
  end,

  cards_wait_for_end_of_combat = function(t)
    local Q = load()
    Mock.player.combat = true
    levelUp(10)
    local P = Q.UI.TalentPicker
    t.ok(not (P.frame and P.frame:IsShown()), "not in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(P.frame:IsShown(), "after combat")
    Mock.player.combat = true
    Mock.fire("PLAYER_REGEN_DISABLED")
    t.ok(not P.frame:IsShown(), "closed when a fight starts")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(P.frame:IsShown(), "back after the fight")
    P.noneButton:GetScript("OnClick")(P.noneButton)
    t.eq(Q.char.talentPreset, false)
  end,

  -- Forever : points à dépenser lus dans la monnaie de l'arbre C_Traits (pas d'API Classic).
  unspent_from_forever_tree_currency = function(t)
    local Q = load()
    t.eq(GetNumTalentTabs, nil); t.eq(UnitCharacterPoints, nil)
    levelUp(9)
    t.eq(Q.Talents:Unspent(), 0, "before level 10")
    levelUp(10)
    t.eq(Q.Talents:Unspent(), 1)
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(Q.UI.Tracker.talentText:GetText(), string.format(Q.L.UI_TALENT_ALERT, 1))
    ranks["1:2"] = 1
    Mock.fire("TRAIT_TREE_CURRENCY_INFO_UPDATED", TREE)
    t.eq(Q.Talents:Alert(), nil, "point spent")
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
    traits.quantity = 3
    Mock.fire("TRAIT_CONFIG_UPDATED", CONFIG)
    t.eq(Q.Talents:Unspent(), 3, "quantity from the client")
    t.ok(Q.UI.Tracker.talentAlert:IsShown())
    t.eq(#Mock.errors, 0)
  end,

  -- /qf talents : relevé des vrais arbres Forever (nœuds, positions, rangs, sorts, monnaie, groupes).
  dump_records_forever_trees = function(t)
    local Q = load()
    levelUp(12)
    ranks["1:2"] = 2
    SlashCmdList.QUESTIFY("talents")
    t.eq(Mock.countPrinted(string.format(Q.L.UI_SLASH_TALENTS_DUMPED, 4)), 1)
    local d = QuestifyDB.talentDump.forever.WARRIOR
    t.ok(d, "talentDump[forever][WARRIOR]")
    t.eq(d.configID, CONFIG); t.eq(d.locale, "enUS"); t.eq(d.interface, 16001)
    t.eq(#d.nodes, 4)
    local node = d.nodes[2]
    t.eq(node.nodeID, 102); t.eq(node.treeID, TREE)
    t.eq(node.posX, 1200); t.eq(node.posY, 600)
    t.eq(node.maxRanks, 5); t.eq(node.currentRank, 2)
    t.eq(node.groupIDs, { 51 })
    t.eq(node.entries, { { entryID = 10102, definitionID = 20102, spellID = 30102, name = "Deflection", maxRanks = 5 } })
    t.eq(#d.trees, 1)
    t.eq(d.trees[1].currencies, { { traitCurrencyID = CURRENCY, quantity = 1, spent = 2 } })
    t.eq(d.trees[1].groups[1].displayName, "Arms"); t.eq(d.trees[1].groups[2].displayName, "Fury")
    t.eq(#Mock.errors, 0)
  end,

  -- API absente ou sans configuration : 0 avec un message clair, rien d'écrit, rappel muet.
  dump_and_reminder_guarded_without_api = function(t)
    local Q = load()
    levelUp(12)
    C_Traits = nil
    t.eq(Q.Talents:Dump(), 0)
    t.eq(Mock.countPrinted(Q.L.TALENT_DUMP_NO_API), 1)
    t.eq(Q.Talents:Unspent(), 0, "reminder silent")
    t.eq(Q.Talents:Alert(), nil)
    Mock.fire("TRAIT_CONFIG_UPDATED")
    t.ok(not Q.UI.Tracker.talentAlert:IsShown())
    installForever()
    traits.configID = nil                              -- talents pas encore chargés
    SlashCmdList.QUESTIFY("talents")
    t.eq(Mock.countPrinted(Q.L.TALENT_DUMP_NO_CONFIG), 1)
    t.eq(Mock.countPrinted(string.format(Q.L.UI_SLASH_TALENTS_DUMPED, 0)), 0, "no misleading count")
    t.eq(Q.Talents:Unspent(), 0)
    t.eq(QuestifyDB.talentDump, nil, "nothing recorded")
    t.eq(#Mock.errors, 0)
  end,
}
