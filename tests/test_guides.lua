-- Tests du registre de guides (Q.Guides, Q:RegisterGuide).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load() return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true }) end

return {
  normalize_forms = function(t)
    local Q = load()
    t.eq(Q.Guides:Normalize({ "goto", 1426, 22.6, 71.4 }).mapId, 1426)
    t.eq(Q.Guides:Normalize({ "complete", 170, obj = 2 }).obj, 2)
    local a = Q.Guides:Normalize({ "accept", 179 })
    t.eq(a.action, "accept"); t.eq(a.questId, 179)
    local g = Q.Guides:Normalize({ "goto", 1426, 22.6, 71.4, note = "camp" })
    t.eq(g.x, 22.6); t.eq(g.y, 71.4); t.eq(g.note, "camp")
    t.eq(Q.Guides:Normalize({ "level", 6 }).level, 6)
    t.eq(Q.Guides:Normalize({ "note", "txt" }).text, "txt")
    t.eq(Q.Guides:Normalize({ "hearth", 1426 }).mapId, 1426)
    t.eq(Q.Guides:Normalize({ "fly", 1453 }).mapId, 1453)
    local c = Q.Guides:Normalize({ "complete", 170, at = { 1426, 26.1, 74.3 }, xp = 120, optional = true, dungeon = "Deadmines" })
    t.eq(c.at.mapId, 1426); t.eq(c.at.x, 26.1); t.eq(c.at.y, 74.3); t.eq(c.at[1], 1426)
    t.eq(c.xp, 120); t.eq(c.optional, true); t.eq(c.dungeon, "Deadmines")
    t.eq(Q.Guides:Normalize({ "accept", 1599, class = "WARLOCK" }).class, { "WARLOCK" }, "string filter wrapped")
    local again = Q.Guides:Normalize(a)
    t.eq(again.action, "accept"); t.eq(again.questId, 179)
  end,

  normalize_rejects_bad_steps = function(t)
    local Q = load()
    local s, err = Q.Guides:Normalize({ "dance", 1 })
    t.eq(s, nil); t.ok(err and err:find("dance", 1, true))
    t.eq(Q.Guides:Normalize({ "accept" }), nil, "missing quest id")
    t.eq(Q.Guides:Normalize({ "goto", 1426, 20 }), nil, "missing y")
    t.eq(Q.Guides:Normalize({ "level" }), nil)
    t.eq(Q.Guides:Normalize({ "note" }), nil)
    t.eq(Q.Guides:Normalize({ "complete", 170, at = { 1426, 20 } }), nil, "bad at")
    t.eq(Q.Guides:Normalize("accept"), nil)
  end,

  invalid_guide_ignored = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "X", steps = { { "dance", 1 } } })
    t.eq(Q.Guides:Get("X"), nil)
    t.ok(Mock.printed("X"))
    t.eq(Mock.countPrinted("Invalid guide X"), 1, "one error line")
    Q:RegisterGuide({ steps = {} })
    Q:RegisterGuide("nope")
    t.eq(#Mock.errors, 0)
  end,

  registered_guides_listed = function(t)
    local Q = load()
    local all = Q.Guides:All()
    t.eq(#all, 2)
    t.eq(all[1].id, "A_DwarfGnome_01"); t.eq(all[2].id, "A_DwarfGnome_02")
    local g = Q.Guides:Get("A_DwarfGnome_01")
    t.eq(g.title, "Coldridge Valley"); t.eq(g.minLevel, 1); t.eq(g.maxLevel, 6)
    t.eq(g.steps[7].at.x, 26.1)
    t.eq(g.steps[1].action, "accept")
  end,

  picks_chapter_by_level = function(t)
    local Q = load()
    t.eq(Q.Guides:ForPlayer("Alliance", "Dwarf", 1).id, "A_DwarfGnome_01")
    t.eq(Q.Guides:ForPlayer("Alliance", "Dwarf", 7).id, "A_DwarfGnome_02")
    t.eq(Q.Guides:ForPlayer("Alliance", "Human", 7), nil)
    t.eq(Q.Guides:ForPlayer("Alliance", "Gnome", 6).id, "A_DwarfGnome_02", "maxLevel is exclusive")
    t.eq(Q.Guides:ForPlayer("Alliance", "Dwarf", 25).id, "A_DwarfGnome_02", "highest minLevel <= level")
    t.eq(Q.Guides:ForPlayer("Horde", "Dwarf", 1), nil, "faction must match")
  end,

  picks_race_specific_first = function(t)
    local Q = load()
    Q:RegisterGuide({ id = "A_00_Trunk", faction = "Alliance", minLevel = 1, maxLevel = 6, steps = { { "note", "x" } } })
    t.eq(Q.Guides:ForPlayer("Alliance", "Dwarf", 2).id, "A_DwarfGnome_01", "race-specific beats lower id")
    t.eq(Q.Guides:ForPlayer("Alliance", "Human", 2).id, "A_00_Trunk", "trunk chapter for other races")
  end,

  next_chapter = function(t)
    local Q = load()
    t.eq(Q.Guides:Next(Q.Guides:Get("A_DwarfGnome_01"), "Dwarf").id, "A_DwarfGnome_02")
    t.eq(Q.Guides:Next(Q.Guides:Get("A_DwarfGnome_02"), "Dwarf"), nil)
    Q:RegisterGuide({ id = "A_Start", faction = "Alliance", minLevel = 1, maxLevel = 5,
      next = "A_DwarfGnome_02", nextByRace = { Gnome = "A_DwarfGnome_01" }, steps = { { "note", "x" } } })
    t.eq(Q.Guides:Next(Q.Guides:Get("A_Start"), "Gnome").id, "A_DwarfGnome_01")
    t.eq(Q.Guides:Next(Q.Guides:Get("A_Start"), "Dwarf").id, "A_DwarfGnome_02")
  end,

  -- Client anglais : zones par le nom des cartes du jeu (mock : noms anglais), sous-zones et titres
  -- inconnus tels quels, « X and Y » joint par L.LIST_AND.
  display_title_english_client = function(t)
    local Q = load()
    local function reg(id, title)
      Q:RegisterGuide({ id = id, title = title, faction = "Alliance", steps = { { "note", "x" } } })
      return Q.Guides:Get(id)
    end
    t.eq(Q.Guides:DisplayTitle(Q.Guides:Get("A_DwarfGnome_01")), "Coldridge Valley")
    t.eq(Q.Guides:DisplayTitle("A_DwarfGnome_02"), "Dun Morogh", "by id")
    C_Map.GetMapInfo = function(id)
      if id == 1436 then return { name = "Westfall (map)" } end
      if id == 1440 then return { name = "Ashenvale (map)" } end
    end
    t.eq(Q.Guides:DisplayTitle(reg("T_W", "Westfall")), "Westfall (map)", "zone name from the game")
    t.eq(Q.Guides:DisplayTitle(reg("T_AS", "Ashenvale and Stonetalon Mountains")),
      "Ashenvale (map) and Stonetalon Mountains", "missing map name: the English part")
    t.eq(Q.Guides:DisplayTitle(reg("T_X", "Horde chapter")), "Horde chapter")
    t.eq(Q.Guides:DisplayTitle(nil), "")
    t.eq(Q.Guides:DisplayTitle("NOPE"), "NOPE")
    C_Map.GetMapInfo = nil
    t.eq(Q.Guides:DisplayTitle("T_W"), "Westfall", "no map API")
  end,

  -- Client français, guides livrés : aucun titre de chapitre n'est rendu en anglais quand le jeu donne
  -- les noms de cartes (noms officiels du client français, ici simulés). Chaque partie du titre vient
  -- d'une carte du jeu ou de la table des sous-zones, jamais du titre anglais.
  display_title_french_client_shipped_guides = function(t)
    Mock.locale = "frFR"
    local Q = Mock.loadAddon(TOC, {})
    local FR = {
      [1439] = "Sombrivage", [1440] = "Orneval", [1442] = "Les Serres-Rocheuses", [1433] = "Les Carmines",
      [1431] = "Bois de la Pénombre", [1437] = "Les Paluns", [1424] = "Contreforts de Hautebrande",
      [1426] = "Dun Morogh", [1432] = "Loch Modan", [1436] = "Marche de l'Ouest", [1429] = "Forêt d'Elwynn",
      [1438] = "Teldrassil", [1413] = "Les Tarides", [1441] = "Mille pointes", [1411] = "Durotar",
      [1412] = "Mulgore", [1420] = "Clairières de Tirisfal", [1421] = "Forêt des Pins-Argentés",
      [2521] = "Île de Zephras",
      -- zones des chapitres 30-60 (noms du client français)
      [1434] = "Vallée de Strangleronce", [1443] = "Désolace", [1435] = "Marais des Chagrins",
      [1416] = "Montagnes d'Alterac", [1417] = "Hautes-terres d'Arathi", [1445] = "Marécage d'Âprefange",
      [1418] = "Terres ingrates", [1446] = "Tanaris", [1444] = "Féralas", [1427] = "Gorge des Vents brûlants",
      [1419] = "Terres foudroyées", [1422] = "Maleterres de l'Ouest", [1448] = "Gangrebois", [1447] = "Azshara",
      [1449] = "Cratère d'Un'Goro", [1452] = "Berceau-de-l'Hiver", [1428] = "Steppes ardentes",
      [1423] = "Maleterres de l'Est", [1451] = "Silithus", [1425] = "Les Hinterlands",
    }
    C_Map.GetMapInfo = function(id) return FR[id] and { mapID = id, name = FR[id] } or nil end
    local expected = {
      A_01 = "Sombrivage",
      A_02 = "Orneval et Les Serres-Rocheuses",
      A_03 = "Les Carmines et Bois de la Pénombre",
      A_04 = "Les Paluns",
      A_05 = "Contreforts de Hautebrande",
      A_DwarfGnome_01 = "Vallée de Froidecrête",
      A_DwarfGnome_02 = "Dun Morogh",
      A_DwarfGnome_03 = "Loch Modan",
      A_DwarfGnome_04 = "Marche de l'Ouest",
      A_Human_01 = "Comté-du-Nord",
      A_Human_02 = "Forêt d'Elwynn",
      A_Human_03 = "Marche de l'Ouest",
      A_NightElf_01 = "Sombrevallon",
      A_NightElf_02 = "Teldrassil",
      A_NightElf_03 = "Sombrivage",
      H_01 = "Les Tarides",
      H_02 = "Les Serres-Rocheuses et Les Tarides",
      H_03 = "Orneval et Les Serres-Rocheuses",
      H_04 = "Tarides du Sud et Mille pointes",
      H_05 = "Contreforts de Hautebrande",
      H_OrcTroll_01 = "Vallée des Épreuves",
      H_OrcTroll_02 = "Durotar",
      H_Tauren_01 = "Camp Narache",
      H_Tauren_02 = "Mulgore",
      H_Undead_01 = "Le Glas",
      H_Undead_02 = "Clairières de Tirisfal",
      H_Undead_03 = "Forêt des Pins-Argentés",
      A_Skyborne_01 = "Île de Zephras",
      H_Skyborne_01 = "Île de Zephras",
    }
    -- Chapitres 30-60 (lot H) : titres faits de noms de zones. Une zone connue du moteur
    -- (Guides.ZONE_MAPS) est traduite ; les autres restent en anglais tant que ZONE_MAPS
    -- (Engine/Guides.lua) ne les liste pas (relevé dans le rapport du lot H).
    local function expectedFor(g)
      if expected[g.id] then return expected[g.id], true end
      local texts, translated = {}, false
      for part in (tostring(g.title) .. " and "):gmatch("(.-) and ") do
        local id = Q.Guides.ZONE_MAPS[part]
        local fr = id and FR[id]
        if fr then translated = true end
        texts[#texts + 1] = fr or part
      end
      -- aucune partie traduite : le titre anglais entier (Guides:DisplayTitle)
      if not translated then return g.title, false end
      return table.concat(texts, " et "), false
    end
    local all = Q.Guides:All()
    t.ok(#all >= 29, "shipped chapters: " .. #all)
    local high = 0
    for _, g in ipairs(all) do
      local want, strict = expectedFor(g)
      if not strict then
        high = high + 1
        t.ok((g.minLevel or 0) >= 30, "expected French title for " .. g.id .. " (" .. tostring(g.title) .. ")")
      end
      t.eq(Q.Guides:DisplayTitle(g), want, g.id)
      for _, part in ipairs(Q.Guides:TitleParts(g)) do
        if strict or part.mapId then
          t.ok(part.source ~= "raw", g.id .. ": '" .. part.text .. "' left in English")
        else
          -- partie d'un chapitre 30-60 : un nom de zone (anglais), jamais un sous-titre libre
          t.ok(part.text:match("^[%u][%a' ]+$") ~= nil, g.id .. ": title part '" .. part.text .. "'")
        end
      end
    end
    t.eq(#all - high, 29, "29 chapters 1-30")
    t.eq(#Mock.errors, 0)
  end,

  -- Client français sans noms de cartes (API absente) : les sous-zones restent traduites, les zones
  -- gardent le titre anglais (le titre entier quand aucune partie n'est traduite).
  display_title_french_client_without_map_names = function(t)
    Mock.locale = "frFR"
    local Q = load()
    C_Map.GetMapInfo = function() return nil end
    t.eq(Q.Guides:DisplayTitle("A_DwarfGnome_01"), "Vallée de Froidecrête")
    t.eq(Q.Guides:DisplayTitle("A_DwarfGnome_02"), "Dun Morogh")
    Q:RegisterGuide({ id = "T_AS", title = "Ashenvale and Stonetalon Mountains", steps = { { "note", "x" } } })
    t.eq(Q.Guides:DisplayTitle("T_AS"), "Ashenvale and Stonetalon Mountains", "nothing translated: the title")
  end,

  -- Carte principale d'un chapitre : celle de la première zone du titre, sinon la carte la plus présente
  -- dans les étapes ; les cartes des titres livrés sont bien celles de leurs étapes.
  chapter_maps_from_title_and_steps = function(t)
    local Q = Mock.loadAddon(TOC, {})
    t.eq(Q.Guides:MainMap("A_03"), 1433, "Redridge Mountains")
    -- « Southern Barrens » n'est pas un nom de zone : carte la plus présente des étapes (Tarides ou Mille pointes,
    -- selon la régénération des guides)
    local h4 = Q.Guides:StepMaps("H_04")
    t.eq(Q.Guides:MainMap("H_04"), h4[1].mapId, "Southern Barrens: the most used map of the steps")
    t.ok(h4[1].mapId == 1413 or h4[1].mapId == 1441, "H_04: The Barrens or Thousand Needles")
    t.eq(Q.Guides:MainMap("A_DwarfGnome_01"), 1426, "Coldridge Valley: Dun Morogh")
    local sm = Q.Guides:StepMaps("A_03")
    -- carte la plus présente d'abord (le nombre exact d'étapes change à chaque régénération des guides)
    t.eq(sm[1].mapId, 1431); t.ok(sm[2] == nil or sm[1].count >= sm[2].count, "sorted by count")
    t.eq(Q.Guides:MainMap("NOPE"), nil)
    for _, g in ipairs(Q.Guides:All()) do
      local used = {}
      for _, e in ipairs(Q.Guides:StepMaps(g)) do used[e.mapId] = true end
      for _, part in ipairs(Q.Guides:TitleParts(g)) do
        if part.mapId then t.ok(used[part.mapId], g.id .. ": map " .. part.mapId .. " not in its steps") end
      end
    end
  end,
}
