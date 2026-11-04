-- Tests de la mise en forme des étapes (Q.Format).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end   -- fixtures seules, pas les guides livrés
  return Mock.loadAddon(TOC, opts)
end

local function useGuide(Q, id, steps)
  Q:RegisterGuide({ id = id, faction = "Alliance", minLevel = 1, maxLevel = 60, steps = steps })
  Q.Progress:SetGuide(id)
  return Q.Progress:Entries()
end

return {
  format_accept_fr = function(t)
    Mock.locale = "frFR"
    local Q = load()
    local text = Q.Format:StepText(Q.Progress:Entries()[1])
    t.ok(text:find("Dwarven Outfitters", 1, true), "quest name")
    t.ok(text:find("Sten Stoutarm", 1, true), "giver name")
    t.ok(text:find("Prendre", 1, true), "French template")
    t.eq(text, "Prendre |cffffd100Dwarven Outfitters|r auprès de |cff00ff96Sten Stoutarm|r")
  end,

  format_accept_en = function(t)
    local Q = load()
    t.eq(Q.Format:StepText(Q.Progress:Entries()[1]),
      "Accept |cffffd100Dwarven Outfitters|r from |cff00ff96Sten Stoutarm|r")
  end,

  format_turnin_and_titles_fr = function(t)
    Mock.locale = "frFR"
    local Q = load()
    local list = Q.Progress:Entries()
    t.eq(Q.Format:StepText(list[14]), "Rendre |cffffd100Coldridge Valley Mail Delivery|r à |cff00ff96Talin Keeneye|r")
    t.eq(Q.Format:StepTitle(list[1]), "Prendre : Dwarven Outfitters")
    t.eq(Q.Format:StepTitle(list[14]), "Rendre : Coldridge Valley Mail Delivery")
    t.eq(Q.Format:StepTitle(list[2]), "Dwarven Outfitters")
    t.ok(not Q.Format:StepTitle(list[1]):find("|c", 1, true), "titles carry no color codes")
  end,

  format_complete_lists_objectives = function(t)
    Mock.locale = "frFR"
    local Q = load()
    Mock.quests.log[179] = { complete = false, objectives = { { text = "Viande de loup coriace : 3/8", finished = false } } }
    Mock.fire("QUEST_ACCEPTED", 179)
    local text = Q.Format:StepText(Q.Progress:Current())
    t.ok(text:find("^Faire : |cffffd100Dwarven Outfitters|r"), "complete template")
    t.ok(text:find("Viande de loup coriace : 3/8", 1, true), "objective line from the client log")
  end,

  format_complete_with_obj_shows_only_that_line = function(t)
    local Q = load()
    Mock.quests.log[3361] = { complete = false, objectives = {
      { text = "Felix's Box: 0/1", finished = false },
      { text = "Felix's Chest: 0/1", finished = false },
      { text = "Felix's Bucket of Bolts: 0/1", finished = false },
    } }
    local text = Q.Format:StepText(Q.Progress:Entries()[10])
    t.ok(text:find("Felix's Chest: 0/1", 1, true))
    t.ok(not text:find("Felix's Box: 0/1", 1, true))
  end,

  format_complete_not_in_log_lists_targets = function(t)
    local Q = load()
    local text = Q.Format:StepText(Q.Progress:Entries()[7])   -- complete 170, pas encore prise
    t.ok(text:find("|cffff6060Rockjaw Trogg|r", 1, true), "mob names in red")
    t.ok(text:find("|cffff6060Burly Rockjaw Trogg|r", 1, true))
    local wolves = Q.Format:StepText(Q.Progress:Entries()[2])
    t.ok(wolves:find("Tough Wolf Meat", 1, true), "item objective")
    local felix = Q.Format:StepText(Q.Progress:Entries()[11])
    t.ok(felix:find("|cff66bbffFelix's Box|r", 1, true), "world objects in blue")
  end,

  format_other_actions_fr = function(t)
    Mock.locale = "frFR"
    local Q = load()
    local list = useGuide(Q, "T_Fmt", {
      { "goto", 1426, 22.6, 71.4, note = "Camp de Talin" },
      { "fp", 1455, 55.5, 47.7 }, { "sethearth", 1426, 47.4, 52.5 }, { "hearth", 1426 },
      { "fly", 1432 }, { "boat", 1437, 4.6, 57.1 }, { "level", 6 }, { "note", "Acheter à boire" },
    })
    t.eq(Q.Format:StepText(list[1]), "Aller au point indiqué\n|cff999999Camp de Talin|r")
    t.eq(Q.Format:StepText(list[2]), "Prendre le point de vol")
    t.eq(Q.Format:StepText(list[3]), "Lier la pierre de foyer ici")
    t.eq(Q.Format:StepText(list[4]), "Utiliser la pierre de foyer")
    t.eq(Q.Format:StepText(list[5]), "Prendre un vol vers Loch Modan")
    t.eq(Q.Format:StepText(list[6]), "Prendre le bateau")
    t.eq(Q.Format:StepText(list[7]), "Tuer des monstres jusqu'au niveau 6")
    t.eq(Q.Format:StepText(list[8]), "Acheter à boire")
    t.eq(Q.Format:StepTitle(list[1]), "Camp de Talin")
    t.eq(Q.Format:StepTitle(list[5]), "Prendre un vol vers Loch Modan")
  end,

  format_unknown_quest_uses_id = function(t)
    local Q = load()
    local list = useGuide(Q, "T_Unk", { { "accept", 999999 }, { "complete", 999999 } })
    t.eq(Q.Format:StepText(list[1]), "Accept |cffffd100#999999|r")
    t.eq(Q.Format:StepTitle(list[1]), "Accept: #999999")
    t.ok(Q.Format:StepText(list[2]):find("#999999", 1, true))
    t.eq(#Mock.errors, 0)
  end,

  format_object_giver_and_dungeon_tag = function(t)
    local Q = load({ qdb = { quests = {
      [90050] = { name = "Strange Box", startedBy = { nil, { 148499 } }, finishedBy = { nil, { 178084 } } },
    } } })
    local list = useGuide(Q, "T_Obj", { { "accept", 90050, dungeon = "Gnomeregan", optional = true }, { "turnin", 90050 } })
    local text = Q.Format:StepText(list[1])
    t.ok(text:find("|cff66bbffFelix's Box|r", 1, true), "object giver in blue")
    t.ok(text:find("Gnomeregan", 1, true), "dungeon tag")
    t.ok(Q.Format:StepText(list[2]):find("|cff66bbffFelix's Chest|r", 1, true))
  end,

  action_icons_are_builtin = function(t)
    local Q = load()
    t.eq(Q.Format:ActionIcon("accept"), "Interface\\GossipFrame\\AvailableQuestIcon")
    t.eq(Q.Format:ActionIcon("turnin"), "Interface\\GossipFrame\\ActiveQuestIcon")
    t.eq(Q.Format:ActionIcon("fp"), "Interface\\Minimap\\Tracking\\FlightMaster")
    t.eq(Q.Format:ActionIcon("fly"), "Interface\\Minimap\\Tracking\\FlightMaster")
    t.eq(Q.Format:ActionIcon("hearth"), "Interface\\Icons\\INV_Misc_Rune_01")
    t.eq(Q.Format:ActionIcon("sethearth"), "Interface\\Icons\\INV_Misc_Rune_01")
    t.eq(Q.Format:ActionIcon("goto"), "Interface\\Icons\\Ability_Rogue_Sprint")
    for _, a in ipairs({ "complete", "boat", "level", "note", "nonsense" }) do
      t.ok(Q.Format:ActionIcon(a):find("^Interface\\"), a)
    end
  end,

  reason_text = function(t)
    Mock.locale = "frFR"
    local Q = load()
    t.eq(Q.Format:Reason("level 4"), "Niveau 4 requis")
    t.eq(Q.Format:Reason("unknown"), "Quête inconnue de QuestieDB")
    t.eq(Q.Format:Reason(nil), "")
    -- chaque raison renvoyée par Progress:State a un texte
    for _, r in ipairs({ "manual", "race", "class", "optional", "ineligible", "prereq", "notinlog",
      "reached", "passed", "error" }) do
      local text = Q.Format:Reason(r)
      t.ok(text ~= r and text ~= "" and not text:find("REASON_", 1, true), "text for " .. r)
    end
    t.eq(Q.Format:Reason("passed"), "Étape déjà dépassée")
  end,

  targets_title_uses_format = function(t)
    Mock.locale = "frFR"
    local Q = load()
    local tg = Q.Targets:ForEntry(Q.Progress:Entries()[1])
    t.eq(tg.title, "Prendre : Dwarven Outfitters")
  end,
}
