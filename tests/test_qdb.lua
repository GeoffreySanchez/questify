-- Tests de la façade QuestieDB (Q.QDB) et des cartes (Q.Maps).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"

local function load(opts) return Mock.loadAddon(TOC, opts) end

return {
  quest_shape = function(t)
    local Q = load()
    local q = Q.QDB:Quest(179)
    t.eq(q.name, "Dwarven Outfitters")
    t.eq(q.starters.npcs[1], 658)
    t.eq(q.objectives.items[1], 750)
    t.eq(q.id, 179); t.eq(q.level, 1); t.eq(q.reqLevel, 1)
    t.eq(q.races, 4294967373); t.eq(q.classes, nil, "0 becomes nil")
    t.eq(q.finishers.npcs[1], 658)
    t.eq(#q.starters.objects, 0); t.eq(#q.starters.items, 0)
    t.eq(#q.preSingle, 0); t.eq(#q.preGroup, 0); t.eq(#q.exclusiveTo, 0)
    t.eq(q.next, nil); t.eq(q.breadcrumbFor, nil); t.eq(q.specialFlags, 8); t.eq(q.requiredSkill, nil)
    t.ok(Q.QDB:Quest(179) == q, "cached")
  end,

  quest_objectives_creatures_and_killcredit = function(t)
    local Q = load({ qdb = { quests = {
      [90001] = { name = "Kill credit test", startedBy = { { 658 } }, finishedBy = { { 658 } },
        objectives = { { { 707, "Trogg" } }, { { 148499 } }, nil, { 47, 250 }, { { { 705, 946 }, 705, "Wolves slain" } } } },
    } } })
    local q = Q.QDB:Quest(170)
    t.eq(q.objectives.creatures, { 707, 724 })
    t.eq(q.preSingle, { 179 })
    local k = Q.QDB:Quest(90001)
    t.eq(k.objectives.creatures, { 707 })
    t.eq(k.objectives.objects, { 148499 })
    t.eq(k.objectives.killCredit[1].npcIds, { 705, 946 })
    t.eq(k.objectives.killCredit[1].base, 705)
    t.eq(k.objectives.killCredit[1].text, "Wolves slain")
    t.eq(k.objectives.reputation, { 47, 250 })
  end,

  npc_spawns_uimap = function(t)
    local Q = load()
    local n = Q.QDB:Npc(658)
    t.ok(n.spawns[1426] and math.abs(n.spawns[1426][1][1] - 29.93) < 0.01)
    t.eq(n.name, "Sten Stoutarm"); t.eq(n.minLevel, 5); t.eq(n.maxLevel, 5)
    t.eq(n.spawns[1], nil, "area ids are converted")
    local elwynn = Q.QDB:Npc(459)
    t.ok(elwynn.spawns[1429], "Elwynn area 12 -> uiMap 1429")
  end,

  object_and_item = function(t)
    local Q = load()
    local o = Q.QDB:Object(148499)
    t.eq(o.name, "Felix's Box")
    t.ok(o.spawns[1426] and o.spawns[1426][1][1] == 20.88)
    local i = Q.QDB:Item(750)
    t.eq(i.name, "Tough Wolf Meat")
    t.eq(i.npcDrops, { 705 })
    t.eq(i.objectDrops, {})
    t.eq(Q.QDB:Item(10438).objectDrops, { 148499 })
    t.eq(Q.QDB:Npc(999999), nil); t.eq(Q.QDB:Object(999999), nil); t.eq(Q.QDB:Item(999999), nil)
  end,

  eligibility = function(t)
    local Q = load()
    t.ok(Q.QDB:IsEligible(179, 4, 1))
    t.ok(not Q.QDB:IsEligible(6387, 1, 1), "Dwarf/Gnome only, Human refused")
    t.ok(Q.QDB:IsEligible(6387, 64, 1), "Gnome accepted")
    t.ok(not Q.QDB:IsEligible(1599, 4, 1), "Warlock only, Warrior refused")
    t.ok(Q.QDB:IsEligible(1599, 4, 256), "Warlock accepted")
    t.ok(Q.QDB:IsEligible(179, 4294967296, 1), "Skyborne Alliance accepted")
    t.ok(not Q.QDB:IsEligible(179, 8589934592, 1), "Skyborne Horde refused")
    t.ok(Q.QDB:IsEligible(999999, 4, 1), "unknown quest never blocks")
  end,

  prereqs = function(t)
    local Q = load()
    t.ok(not Q.QDB:PrereqsMet(170, function() return false end))
    t.ok(Q.QDB:PrereqsMet(170, function(id) return id == 179 end))
    t.ok(Q.QDB:PrereqsMet(179, function() return false end), "no prereq")
  end,

  prereqs_group_and_exclusive = function(t)
    local Q = load({ qdb = { quests = {
      [90010] = { name = "Group", preQuestGroup = { 179, 233 } },
      [90011] = { name = "Excl", exclusiveTo = { 170 } },
      [90012] = { name = "A", exclusiveTo = { 90013 } },
      [90013] = { name = "B", exclusiveTo = { 90012 } },
      [90014] = { name = "Needs A", preQuestGroup = { 90012 } },
    } } })
    t.ok(not Q.QDB:PrereqsMet(90010, function(id) return id == 179 end), "group needs all")
    t.ok(Q.QDB:PrereqsMet(90010, function(id) return id == 179 or id == 233 end))
    t.ok(not Q.QDB:PrereqsMet(90011, function(id) return id == 170 end), "exclusive done blocks")
    t.ok(Q.QDB:PrereqsMet(90011, function() return false end))
    t.ok(Q.QDB:PrereqsMet(90014, function(id) return id == 90013 end), "exclusive sibling counts as done")
  end,

  unknown_quest_nil = function(t)
    local Q = load()
    t.eq(Q.QDB:Quest(999999), nil); t.eq(Q.QDB:QuestName(999999), "#999999")
    t.eq(Q.QDB:Quest("abc"), nil)
    t.eq(#Mock.errors, 0)
  end,

  quest_name_fallbacks = function(t)
    local Q = load()
    t.eq(Q.QDB:QuestName(179), "Dwarven Outfitters")
    Mock.titles[888888] = "Client Title"
    t.eq(Q.QDB:QuestName(888888), "Client Title")
    t.eq(Q.QDB:NpcName(658), "Sten Stoutarm")
    t.eq(Q.QDB:NpcName(999999), "#999999")
    t.eq(Q.QDB:ObjectName(148499), "Felix's Box")
    t.eq(Q.QDB:ItemName(750), "Tough Wolf Meat")
  end,

  unavailable_without_questiedb = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    t.ok(not Q.QDB:IsAvailable())
    t.eq(Q.QDB:Status(), "missing")
    t.eq(Q.QDB:Quest(179), nil)
    t.eq(Q.QDB:Npc(658), nil)
    t.eq(Q.QDB:QuestName(179), "#179")
    t.eq(Q.Maps:AreaToUiMap(1), nil)
    t.eq(#Mock.errors, 0)
  end,

  getall_error_reported_and_not_cached = function(t)
    -- IDs que rien d'autre ne lit au démarrage (aucune entrée en cache avant le test)
    local Q = load({ qdb = {
      quests = { [90060] = { name = "Fresh quest" } },
      npcs = { [90061] = { name = "Fresh npc" } },
    } })
    local real = LibQuestieDB.Quest.GetAll
    LibQuestieDB.Quest.GetAll = function() error("decode failure") end
    t.eq(Q.QDB:Quest(90060), nil)
    t.eq(Q.QDB:Quest(90060), nil)
    t.eq(Mock.countPrinted("decode failure"), 1, "reported once")
    LibQuestieDB.Quest.GetAll = real
    t.eq(Q.QDB:Quest(90060).name, "Fresh quest", "not negative-cached")
    local realNpc = LibQuestieDB.Npc.GetAll
    LibQuestieDB.Npc.GetAll = function() error("npc failure") end
    t.eq(Q.QDB:Npc(90061), nil)
    LibQuestieDB.Npc.GetAll = realNpc
    t.eq(Q.QDB:Npc(90061).name, "Fresh npc")
    t.eq(Mock.countPrinted("npc failure"), 1)
  end,

  zonedb_parse_error_reported_and_not_cached = function(t)
    local Q = load()
    local zdb = LibQuestieDB.Support.Get("ZoneDB")
    local saved = zdb.private.subZoneToParentZone
    zdb.private.subZoneToParentZone = "return {"          -- chaîne invalide
    -- 131 n'a pas de correspondance directe : la table des sous-zones est nécessaire
    t.eq(Q.Maps:AreaToUiMap(131), nil)
    t.eq(Mock.countPrinted("ZoneDB.subZoneToParentZone"), 1, "reported once")
    zdb.private.subZoneToParentZone = saved
    t.eq(Q.Maps:AreaToUiMap(131), 1426, "neither the table nor the area result was cached")
  end,

  boots_with_old_questiedb_contract = function(t)
    Mock.qdbContract = 3                     -- RequireContract(4) échoue
    local Q = load()
    t.ok(not Q.QDB:IsAvailable(), "contract 3 refused")
    t.eq(Q.QDB:Status(), "old")
    t.ok(Mock.printed("QuestieDB"), "explains outdated dependency")
    t.eq(Mock.countPrinted("QuestieDB"), 1, "one chat line only")
    t.eq(#Mock.errors, 0, "no Lua error")
  end,

  available_prints_nothing = function(t)
    local Q = load()
    t.ok(Q.QDB:IsAvailable())
    t.eq(Q.QDB:Status(), "ok")
    t.ok(not Mock.printed("QuestieDB"), "no dependency message")
  end,

  area_to_uimap = function(t)
    local Q = load()
    t.eq(Q.Maps:AreaToUiMap(1), 1426)
    t.eq(Q.Maps:AreaToUiMap(6176), 1426, "Coldridge Valley override -> Dun Morogh")
    t.eq(Q.Maps:AreaToUiMap(131), 1426, "Kharanos subzone -> Dun Morogh")
    t.eq(Q.Maps:AreaToUiMap(800), 1426, "nested subzone, recursive")
    t.eq(Q.Maps:AreaToUiMap(9), 1429, "Northshire -> Elwynn")
    t.eq(Q.Maps:AreaToUiMap(2257), nil, "override 0 suppresses")
    t.eq(Q.Maps:AreaToUiMap(424242), nil, "unknown area")
  end,

  player_pos_and_distance = function(t)
    local Q = load()
    local m, x, y = Q.Maps:PlayerPos()
    t.eq(m, 1426); t.near(x, 29.9); t.near(y, 71.2)
    -- 1 % de Dun Morogh en x = 49,25 yards
    t.near(Q.Maps:Distance(1426, 10, 50, 1426, 11, 50), 49.25, 0.01)
    t.near(Q.Maps:Distance(1426, 10, 50, 1426, 10, 51), 32.83, 0.01)
    t.ok(Q.Maps:Distance(1426, 50, 50, 1432, 50, 50) > 0, "same continent across zones")
    t.eq(Q.Maps:Distance(1426, 50, 50, 1411, 50, 50), nil, "nil across continents")
    t.eq(Q.Maps:Distance(1426, 50, 50, 99999, 50, 50), nil, "unknown map")
    Mock.player.instance = true
    t.eq(Q.Maps:PlayerPos(), nil, "nil in an instance")
  end,

  player_pos_ignores_secret_values = function(t)
    local Q = load()
    C_Map.GetBestMapForUnit = function() return Mock.strictSecret(1426) end
    t.eq(Q.Maps:PlayerPos(), nil, "secret map")
    C_Map.GetBestMapForUnit = function() return 1426 end
    C_Map.GetPlayerMapPosition = function()
      return { GetXY = function() return Mock.strictSecret(0.3), Mock.strictSecret(0.7) end }
    end
    t.eq(Q.Maps:PlayerPos(), nil, "secret x")
    C_Map.GetPlayerMapPosition = function()
      return { GetXY = function() return 0.3, Mock.strictSecret(0.7) end }
    end
    t.eq(Q.Maps:PlayerPos(), nil, "secret y")
    t.eq(#Mock.errors, 0)
  end,

  world_pos_axes_match_client = function(t)
    local Q = load()
    -- Client : X monde croît vers le nord, Y monde vers l'ouest (x carte = est, y carte = sud).
    local _, raw = C_Map.GetWorldPosFromMapPos(1426, CreateVector2D(0.25, 0.40))
    local wx, wy = raw:GetXY()
    local c, ax, ay = Q.Maps:WorldPos(1426, 25, 40)
    t.eq(c, 0); t.near(ax, wx, 1e-6); t.near(ay, wy, 1e-6)
    local _, nx = Q.Maps:WorldPos(1426, 25, 30)
    t.ok(nx > ax, "moving north increases world X")
    local _, _, ey = Q.Maps:WorldPos(1426, 35, 40)
    t.ok(ey < ay, "moving east decreases world Y")
    -- Points hors diagonale sur une carte non carrée (4925 x 3283) : un axe inversé échoue ici.
    t.near(Q.Maps:Distance(1426, 20, 30, 1426, 30, 30), 492.5, 0.01, "pure east move")
    t.near(Q.Maps:Distance(1426, 20, 30, 1426, 20, 40), 328.3, 0.01, "pure south move")
    t.near(Q.Maps:Distance(1426, 20, 30, 1426, 30, 40), math.sqrt(492.5 ^ 2 + 328.3 ^ 2), 0.01, "diagonal")
  end,

  world_pos_general_affine = function(t)
    -- Transformation quelconque (rotation + cisaillement) : l'ajustement 2x2 doit la retrouver.
    C_Map.GetWorldPosFromMapPos = function(_, pos)
      local x, y = pos:GetXY()
      return 0, CreateVector2D(1000 + 50 * x - 300 * y, 2000 - 400 * x + 20 * y)
    end
    local Q = load()
    local _, ax, ay = Q.Maps:WorldPos(1426, 37, 61)
    t.near(ax, 1000 + 50 * 0.37 - 300 * 0.61, 1e-6)
    t.near(ay, 2000 - 400 * 0.37 + 20 * 0.61, 1e-6)
  end,

  world_pos_failure_not_cached = function(t)
    local saved = Mock.maps[1426]
    Mock.maps[1426] = nil                      -- données de carte pas encore disponibles
    local Q = load()
    t.eq(Q.Maps:Distance(1426, 10, 50, 1426, 11, 50), nil)
    Mock.maps[1426] = saved
    Mock.advance(Q.Maps.FAIL_RETRY + 1)
    t.near(Q.Maps:Distance(1426, 10, 50, 1426, 11, 50), 49.25, 0.01, "retried after a transient failure")
    t.eq(#Mock.errors, 0)
  end,

  -- Carte sans position monde : échec gardé ~30 s (pas trois appels à chaque WorldPos), puis retenté.
  world_pos_failure_negative_cache = function(t)
    local Q = load()
    local calls = 0
    local orig = C_Map.GetWorldPosFromMapPos
    C_Map.GetWorldPosFromMapPos = function(...) calls = calls + 1; return orig(...) end
    for _ = 1, 10 do t.eq(Q.Maps:WorldPos(9999, 50, 50), nil) end
    t.eq(calls, 1, "one client call for ten lookups")
    Mock.advance(Q.Maps.FAIL_RETRY - 1)
    t.eq(Q.Maps:WorldPos(9999, 50, 50), nil)
    t.eq(calls, 1, "still cached before the delay")
    Mock.advance(2)
    t.eq(Q.Maps:WorldPos(9999, 50, 50), nil)
    t.eq(calls, 2, "retried after the delay")
    -- les autres cartes ne sont pas touchées
    t.ok(Q.Maps:WorldPos(1426, 50, 50), "known map still works")
    t.eq(#Mock.errors, 0)
  end,

  nearest_spawn = function(t)
    local Q = load()
    local spawns = { [1426] = { { 80, 80 }, { 30, 72 }, { 10, 10 } } }
    local m, x, y, d = Q.Maps:Nearest(spawns, 1426, 29.9, 71.2)
    t.eq(m, 1426); t.eq(x, 30); t.eq(y, 72); t.ok(d and d < 30)
    local m2, x2, _, d2 = Q.Maps:Nearest({ [1411] = { { 40, 40 } } }, 1426, 29.9, 71.2)
    t.eq(m2, 1411); t.eq(x2, 40); t.eq(d2, nil, "other continent: first spawn, no distance")
    t.eq(Q.Maps:Nearest({}, 1426, 1, 1), nil)
    local m3 = Q.Maps:Nearest(spawns, nil, nil, nil)
    t.eq(m3, 1426, "no player position: first spawn")
  end,

  opts_qdb_merges_over_fixture = function(t)
    local Q = load({ qdb = {
      quests = { [179] = { requiredLevel = 3 } },
      npcs = { [90100] = { name = "New Npc", spawns = { [38] = { { 10, 20 } } } } },
      zones = { areaIdToUiMapId = { [5000] = 1432 } },
    } })
    t.eq(Q.QDB:Quest(179).reqLevel, 3, "field overridden")
    t.eq(Q.QDB:Quest(179).name, "Dwarven Outfitters", "other fields kept")
    t.eq(Q.QDB:Npc(90100).spawns[1432][1][2], 20)
    t.eq(Q.Maps:AreaToUiMap(5000), 1432)
  end,

  questiedb_mock_semantics = function(t)
    load()
    t.eq(QuestDB.Get(179, "requiredClasses"), 0, "numeric nil reads 0")
    t.eq(QuestDB.Get(179, "preQuestSingle"), nil, "table nil reads nil")
    t.eq(QuestDB.Get(233, "objectives"), {}, "objectives never nil")
    t.eq(QuestDB.Get(999999, "requiredLevel"), nil, "unknown id is nil everywhere")
    t.eq(QuestDB.Get(179, 1), "Dwarven Outfitters", "positional key")
    t.eq(QuestDB.name(179), "Dwarven Outfitters", "named getter")
    local a = NpcDB.spawns(658); a[1] = nil
    t.ok(NpcDB.spawns(658)[1], "reads are copies")
    local v = QuestDB.GetAll(179, { "name", "sourceItemId", "preQuestGroup" })
    t.eq(v.n, 3); t.eq(v[1], "Dwarven Outfitters"); t.eq(v[2], 0); t.eq(v[3], nil)
    t.eq(QuestDB.GetAll(999999, { "name" }), nil)
    t.eq(LibQuestieDB.RequireContract(4), true)
    t.eq(LibQuestieDB.RequireContract(5), false)
    t.eq(type(LibQuestieDB.Support.Get("ZoneDB").private.areaIdToUiMapId), "string")
  end,
}
