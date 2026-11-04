-- Tests des donjons selon le niveau et la faction (Q.Dungeons, alerte du suivi, fenêtre, journal)
-- et contrôle des données générées (Guides/DungeonData.lua).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local DATA_FILE = "Questify/Guides/DungeonData.lua"

local ALLIANCE = 4294967373
local HORDE = 8589934770

-- Données de test (même forme que le fichier généré) : on ne dépend pas du fichier livré, que le
-- générateur réécrit.
local function testData()
  return {
    { key = "RFC", name = "Ragefire Chasm", areaId = 2437, minLevel = 13, maxLevel = 18,
      factions = { "Horde" }, entrance = { 1454, 52.6, 49 }, entranceSource = "questiedb",
      quests = {
        Horde = {
          { id = 5723, giver = 11833, at = { 1456, 70.14, 29.52 }, ender = 11833, endAt = { 1456, 70.14, 29.52 },
            level = 15, reqLevel = 9, races = HORDE },
          { id = 5761, giver = 3216, at = { 1454, 49.47, 50.59 }, ender = 3216, endAt = { 1454, 49.47, 50.59 },
            level = 16, reqLevel = 9, races = HORDE },
        },
      },
    },
    { key = "DM", name = "The Deadmines", areaId = 1581, minLevel = 17, maxLevel = 26,
      factions = { "Alliance" }, entrance = { 1436, 42.5, 71.7 }, entranceSource = "questiedb",
      quests = {
        Alliance = {
          { id = 166, giver = 234, at = { 1436, 56.33, 47.52 }, ender = 234, endAt = { 1436, 56.33, 47.52 },
            level = 22, reqLevel = 14, races = ALLIANCE, pre = { 155 } },
          { id = 167, giver = 656, at = { 1453, 70.31, 40.82 }, ender = 656, endAt = { 1453, 70.31, 40.82 },
            level = 20, reqLevel = 15, races = ALLIANCE },
          { id = 168, giver = 656, at = { 1453, 70.31, 40.82 }, ender = 656, endAt = { 1453, 70.31, 40.82 },
            level = 18, reqLevel = 14, races = ALLIANCE },
          { id = 2040, giver = 6579, at = { 1453, 62.63, 34.11 }, ender = 6579, endAt = { 1453, 62.63, 34.11 },
            level = 20, reqLevel = 15, races = ALLIANCE },
          { id = 92753, giver = 253092, at = { 1436, 52.48, 52.97 }, ender = 253092, endAt = { 1436, 52.48, 52.97 },
            level = 18, reqLevel = 9, races = ALLIANCE, pre = { 92752 } },
          { id = 92752, bc = true, giver = 11026, at = { 1453, 61.88, 30.56 }, ender = 253092,
            endAt = { 1436, 52.48, 52.97 }, level = 16, reqLevel = 9, races = ALLIANCE },
          { id = 9950, inside = true, ender = 656, endAt = { 1453, 70.31, 40.82 }, level = 20, reqLevel = 14,
            races = ALLIANCE },
        },
      },
    },
  }
end

local QDB_EXTRA = {
  quests = {
    [166] = { name = "The Defias Brotherhood", startedBy = { { 234 } }, finishedBy = { { 234 } }, requiredLevel = 14,
      questLevel = 22, requiredRaces = ALLIANCE, preQuestSingle = { 155 }, zoneOrSort = 1581 },
    [167] = { name = "Oh Brother. . .", startedBy = { { 656 } }, finishedBy = { { 656 } }, requiredLevel = 15,
      questLevel = 20, requiredRaces = ALLIANCE, zoneOrSort = 1581 },
    [168] = { name = "Collecting Memories", startedBy = { { 656 } }, finishedBy = { { 656 } }, requiredLevel = 14,
      questLevel = 18, requiredRaces = ALLIANCE, zoneOrSort = 1581 },
    [2040] = { name = "Underground Assault", startedBy = { { 6579 } }, finishedBy = { { 6579 } }, requiredLevel = 15,
      questLevel = 20, requiredRaces = ALLIANCE, zoneOrSort = 1581 },
    [92752] = { name = "Explosive Consultation", startedBy = { { 11026 } }, finishedBy = { { 253092 } },
      requiredLevel = 9, questLevel = 16, requiredRaces = ALLIANCE, zoneOrSort = 40 },
    [92753] = { name = "Destruction in Deadmines", startedBy = { { 253092 } }, finishedBy = { { 253092 } },
      requiredLevel = 9, questLevel = 18, requiredRaces = ALLIANCE, preQuestSingle = { 92752 }, zoneOrSort = 1581 },
    [9950] = { name = "Inside Quest", startedBy = { { 9951 } }, finishedBy = { { 656 } }, requiredLevel = 14,
      questLevel = 20, requiredRaces = ALLIANCE, zoneOrSort = 1581 },
    [5723] = { name = "Testing an Enemy's Strength", startedBy = { { 11833 } }, finishedBy = { { 11833 } },
      requiredLevel = 9, questLevel = 15, requiredRaces = HORDE, zoneOrSort = 2437 },
    [5761] = { name = "Slaying the Beast", startedBy = { { 3216 } }, finishedBy = { { 3216 } },
      requiredLevel = 9, questLevel = 16, requiredRaces = HORDE, zoneOrSort = 2437 },
  },
  npcs = {
    [656] = { name = "Wilder Thistlenettle", spawns = { [1519] = { { 70.31, 40.82 } } }, friendlyToFaction = "A" },
    [6579] = { name = "Shoni the Shilent", spawns = { [1519] = { { 62.63, 34.11 } } }, friendlyToFaction = "A" },
    [234] = { name = "Gryan Stoutmantle", spawns = { [40] = { { 56.33, 47.52 } } }, friendlyToFaction = "A" },
    [11026] = { name = "Sprite Jumpsprocket", spawns = { [1519] = { { 61.88, 30.56 } } }, friendlyToFaction = "A" },
    [253092] = { name = "Alba Fairmoon", spawns = { [40] = { { 52.48, 52.97 } } }, friendlyToFaction = "A" },
    [11833] = { name = "Rahauro", spawns = { [1638] = { { 70.14, 29.52 } } }, friendlyToFaction = "H" },
    [3216] = { name = "Neeru Fireblade", spawns = { [1637] = { { 49.47, 50.59 } } }, friendlyToFaction = "H" },
  },
  zones = { areaIdToUiMapId = { [1637] = 1454, [1638] = 1456 } },
}

local function setupMaps()
  Mock.maps[1454] = { name = "Orgrimmar", continent = 1, left = 3000, top = 1000, width = 1400, height = 935, parent = 1414 }
  Mock.maps[1456] = { name = "Thunder Bluff", continent = 1, left = -2000, top = 3000, width = 1040, height = 695,
    parent = 1414 }
end

local function load(opts)
  opts = opts or {}
  setupMaps()
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end
  opts.qdb = opts.qdb or QDB_EXTRA
  local data = opts.data or testData()
  opts.data = nil
  opts.beforeLogin = function(Q) Q.DungeonData = data end
  return Mock.loadAddon(TOC, opts)
end

local function alliance(level)
  Mock.player.raceId, Mock.player.faction, Mock.player.level = 3, "Alliance", level or 17
end

local function horde(level)
  Mock.player.raceId, Mock.player.faction, Mock.player.level = 2, "Horde", level or 13
  Mock.player.map, Mock.player.x, Mock.player.y = 1411, 50, 50
end

local function keys(rows)
  local out = {}
  for _, r in ipairs(rows) do out[#out + 1] = r.dungeon.key end
  return out
end

local function stateOf(Q, key)
  for _, r in ipairs(Q.Dungeons:List()) do if r.dungeon.key == key then return r.state end end
end

local function tagged(Q, tag)
  local out = {}
  for _, e in ipairs(Q.Progress:Entries()) do if e.tag == tag then out[#out + 1] = e end end
  return out
end

local function turnIn(id)
  Mock.quests.log[id] = nil
  Mock.quests.completed[id] = true
  Mock.fire("QUEST_TURNED_IN", id)
end

local function accept(id, complete)
  Mock.quests.log[id] = { complete = complete == true, objectives = {} }
  Mock.fire("QUEST_ACCEPTED", id)
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

local function noErrors(t)
  for _, e in ipairs(Mock.errors) do t.ok(false, "unexpected error: " .. tostring(e)) end
end

return {
  ragefire_never_listed_for_alliance = function(t)
    for _, level in ipairs({ 13, 15, 18, 30 }) do
      Mock.reset()
      alliance(level)
      local Q = load()
      for _, k in ipairs(keys(Q.Dungeons:List())) do t.ok(k ~= "RFC", "Ragefire listed for Alliance at " .. level) end
      t.eq(Q.Dungeons:Add("RFC"), false, "Ragefire cannot be added by Alliance")
    end
    noErrors(t)
  end,

  ragefire_stays_horde_only_with_wrong_data = function(t)
    -- données fautives qui ouvriraient le Gouffre de Ragefeu à l'Alliance : le garde-fou tient
    alliance(15)
    local data = testData()
    data[1].factions = { "Horde", "Alliance" }
    data[1].quests.Alliance = { { id = 167, giver = 656, at = { 1453, 70.31, 40.82 }, reqLevel = 9 } }
    local Q = load({ data = data })
    for _, k in ipairs(keys(Q.Dungeons:List())) do t.ok(k ~= "RFC", "Ragefire listed for Alliance") end
    t.eq(Q.Dungeons:Add("RFC"), false)
    noErrors(t)
  end,

  ragefire_listed_for_horde_13_to_18 = function(t)
    for level = 13, 18 do
      Mock.reset()
      horde(level)
      local Q = load()
      t.eq(stateOf(Q, "RFC"), "available", "level " .. level)
      local alerts = Q.Dungeons:Alerts()
      t.eq(#alerts, 1, "alert at level " .. level)
      t.eq(alerts[1].dungeon.key, "RFC")
      for _, k in ipairs(keys(Q.Dungeons:List())) do t.ok(k ~= "DM", "Deadmines has no Horde quest") end
    end
    Mock.reset(); horde(10)
    t.eq(stateOf(load(), "RFC"), "upcoming", "too low")
    Mock.reset(); horde(12)
    t.eq(stateOf(load(), "RFC"), "available", "one level below the range")
    Mock.reset(); horde(19)
    t.eq(stateOf(load(), "RFC"), "past", "level passed")
    noErrors(t)
  end,

  deadmines_available_for_alliance_17 = function(t)
    alliance(17)
    local Q = load()
    t.eq(keys(Q.Dungeons:List()), { "DM" })
    t.eq(stateOf(Q, "DM"), "available")
    local alerts = Q.Dungeons:Alerts()
    t.eq(#alerts, 1)
    t.eq(alerts[1].dungeon.key, "DM")
    Mock.reset(); alliance(14)
    t.eq(stateOf(load(), "DM"), "upcoming", "level 14 is below 17 - 1")
    noErrors(t)
  end,

  add_inserts_accept_goto_and_turnin_steps = function(t)
    alliance(17)
    local Q = load()
    local changed = 0
    Q:On("DUNGEONS_CHANGED", function() changed = changed + 1 end)
    t.eq(Q.Dungeons:Add("DM"), true)
    t.eq(changed, 1)
    t.eq(Q.char.dungeons.added.DM, true)
    t.eq(Q.char.dungeons.seen.DM, true, "an added dungeon no longer alerts")
    if Q.AutoQuest and Q.AutoQuest.IsRouteQuest then
      t.ok(Q.AutoQuest:IsRouteQuest(167), "automatic accept and turn-in know the dungeon quests")
    end
    t.eq(stateOf(Q, "DM"), "added")
    local steps = tagged(Q, "dg:DM")
    t.ok(#steps > 0, "steps inserted")
    local cur = Q.Progress:Current()
    t.eq(cur.key, "i:dg:DM:1", "dungeon steps come first")
    -- accept ... goto ... complete ... turnin
    local phase, gotoStep = 1, nil
    local order = { accept = 1, ["goto"] = 2, complete = 3, turnin = 4 }
    local accepted, turned = {}, {}
    for _, e in ipairs(steps) do
      local a = e.step.action
      local p = order[a]
      -- les préquêtes de passage se rendent avant l'entrée
      if a == "turnin" and phase == 1 then p = 1 end
      t.ok(p and p >= phase, "step order: " .. tostring(a))
      phase = p
      if a == "goto" then gotoStep = e.step end
      if a == "accept" then accepted[e.step.questId] = true end
      if a == "turnin" and phase == 4 then turned[e.step.questId] = true end
    end
    t.ok(gotoStep, "goto step")
    t.eq({ gotoStep.mapId, gotoStep.x, gotoStep.y }, { 1436, 42.5, 71.7 })
    t.eq(gotoStep.note, string.format(Q.L.DUNGEON_GOTO_NOTE, "The Deadmines"))
    for _, id in ipairs({ 167, 168, 2040, 92752, 92753 }) do t.ok(accepted[id], "accept " .. id) end
    t.ok(not accepted[166], "166 needs 155, which cannot be chained")
    t.ok(not accepted[9950], "a quest picked up in the dungeon has no accept step")
    for _, id in ipairs({ 167, 168, 2040, 92753, 9950 }) do t.ok(turned[id], "turn in " .. id) end
    -- la préquête de passage est rendue avant de prendre la quête qui la demande
    local iTurn, iAccept
    for i, e in ipairs(steps) do
      if e.step.action == "turnin" and e.step.questId == 92752 then iTurn = i end
      if e.step.action == "accept" and e.step.questId == 92753 then iAccept = i end
    end
    t.ok(iTurn and iAccept and iTurn < iAccept, "breadcrumb before its follow-up")
    -- regroupement par ville : chaque carte de prise n'apparaît qu'en un seul bloc
    local seen, last = {}, nil
    for _, e in ipairs(steps) do
      if e.step.action == "accept" then
        local qd
        for _, d in ipairs(testData()[2].quests.Alliance) do if d.id == e.step.questId then qd = d end end
        local m = qd.at[1]
        if m ~= last then
          t.ok(not seen[m], "accepts grouped by city (map " .. m .. ")")
          seen[m] = true
          last = m
        end
      end
    end
    noErrors(t)
  end,

  added_dungeon_quest_is_auto_accepted = function(t)
    alliance(17)
    local Q = load()
    -- l'ensemble des quêtes de la route est construit avant l'ajout (mis en cache)
    t.eq(Q.AutoQuest:IsRouteQuest(167), false)
    Mock.questFrame.questId = 167
    Mock.fire("QUEST_DETAIL")
    t.eq(Mock.countCalls("AcceptQuest"), 0, "not a route quest yet")
    local classChanged = 0
    Q:On("CLASSQUESTS_CHANGED", function() classChanged = classChanged + 1 end)
    t.eq(Q.Dungeons:Add("DM"), true)
    t.eq(classChanged, 0, "Add does not pretend class quests changed")
    Mock.fire("QUEST_DETAIL")
    t.eq(Mock.countCalls("AcceptQuest"), 1, "dungeon quest accepted automatically")
    Q.Dungeons:Ignore("DM")
    t.eq(Q.AutoQuest:IsRouteQuest(167), false, "ignored dungeon: back to manual")
    noErrors(t)
  end,

  ignore_removes_the_steps = function(t)
    alliance(17)
    local Q = load()
    Q.Dungeons:Add("DM")
    t.ok(#Q.char.inserted == 1)
    t.eq(Q.Dungeons:Ignore("DM"), true)
    t.eq(#Q.char.inserted, 0, "steps removed")
    t.eq(#tagged(Q, "dg:DM"), 0)
    t.eq(stateOf(Q, "DM"), "ignored")
    t.eq(#Q.Dungeons:Alerts(), 0)
    t.eq(Q.Dungeons:Unignore("DM"), true)
    t.eq(stateOf(Q, "DM"), "available")
    t.eq(#Q.Dungeons:Alerts(), 0, "seen: the alert does not come back")
    t.eq(Q.Dungeons:Ignore("NOPE"), false)
    noErrors(t)
  end,

  dungeon_removes_itself_when_everything_is_turned_in = function(t)
    alliance(17)
    local Q = load()
    Q.Dungeons:Add("DM")
    for _, id in ipairs({ 167, 168, 2040, 92752, 92753 }) do accept(id, true) end
    t.eq(#Q.char.inserted, 1, "still quests to turn in")
    for _, id in ipairs({ 167, 168, 2040, 92752, 92753 }) do turnIn(id) end
    t.eq(#Q.char.inserted, 0, "removed once every quest step is done or skipped")
    t.eq(Q.char.dungeons.added.DM, nil)
    -- 166 reste à faire mais sa préquête manque : rien à prendre pour l'instant
    t.eq(stateOf(Q, "DM"), "upcoming", "166 is still to do (its pre-quest is missing)")
    turnIn(166)
    t.eq(stateOf(Q, "DM"), "done")
    noErrors(t)
  end,

  option_off_means_no_alert = function(t)
    alliance(17)
    local Q = load()
    t.ok(Q.UI.Tracker.dungeonAlert:IsShown(), "alert line shown")
    Q.Settings:Set("dungeonSuggest", false)
    t.eq(Q.Dungeons:Alerts(), {})
    t.ok(not Q.UI.Tracker.dungeonAlert:IsShown(), "alert line hidden")
    t.eq(#Q.Dungeons:List(), 1, "the journal still lists the dungeon")
    Q.Settings:Set("dungeonSuggest", true)
    t.ok(Q.UI.Tracker.dungeonAlert:IsShown(), "alert back")
    noErrors(t)
  end,

  silent_without_questiedb = function(t)
    alliance(17)
    Mock.addons.QuestieDB = false
    local Q = load()
    t.eq(Q.Dungeons:List(), {})
    t.eq(Q.Dungeons:Alerts(), {})
    t.eq(Q.Dungeons:Add("DM"), false)
    t.eq(Q.Dungeons:Ignore("DM"), false)
    t.ok(not Q.UI.Tracker.dungeonAlert:IsShown())
    Q.UI.Journal:ShowTab("class")
    noErrors(t)
  end,

  survives_missing_or_broken_data = function(t)
    alliance(17)
    local Q = load()
    Q.DungeonData = nil
    t.eq(Q.Dungeons:List(), {})
    Q.DungeonData = { "garbage", { key = 5 }, { key = "X", minLevel = 1, maxLevel = 5, entrance = { 1 }, quests = {} },
      { key = "Y", minLevel = 1, maxLevel = 60, entrance = { 1436, 1, 1 }, factions = { "Alliance" },
        quests = { Alliance = { "bad", { id = "x" }, { id = 1, at = "nope" } } } } }
    t.eq(Q.Dungeons:List(), {})
    t.eq(Q.Dungeons:Alerts(), {})
    t.eq(Q.Dungeons:Add("Y"), false)
    Q.UI.Tracker:Refresh()
    Q.UI.Journal:ShowTab("class")
    noErrors(t)
  end,

  tracker_alert_opens_the_popup = function(t)
    alliance(17)
    local Q = load()
    local T = Q.UI.Tracker
    t.ok(T.dungeonAlert:IsShown())
    t.eq(plain(T.dungeonText:GetText()), string.format(Q.L.DUNGEON_ALERT_ONE, "The Deadmines", 17, 26))
    t.ok(T.dungeonPulse:IsPlaying(), "pulsing glow")
    Mock.click(T.dungeonAlert, "LeftButton")
    local P = Q.UI.DungeonPopup
    t.ok(P.frame:IsShown(), "popup shown")
    t.eq(P.dungeon.key, "DM")
    t.eq(P.title:GetText(), "The Deadmines")
    t.ok(plain(P.level:GetText()):find("17", 1, true), "level range")
    t.ok(plain(P.entrance:GetText()):find("Westfall", 1, true), "entrance zone")
    local found = false
    for _, fs in ipairs(P.lines) do
      if fs:IsShown() and plain(fs:GetText()):find("Wilder Thistlenettle", 1, true) then found = true end
    end
    t.ok(found, "quest giver listed")
    Mock.click(P.addButton, "LeftButton")
    t.ok(not P.frame:IsShown(), "popup closed")
    t.eq(stateOf(Q, "DM"), "added")
    t.ok(not T.dungeonAlert:IsShown(), "alert gone")
    t.eq(Q.Progress:Current().tag, "dg:DM")
    -- la classe : l'alerte de quête de classe reste indépendante
    t.ok(T.alert ~= T.dungeonAlert)
    noErrors(t)
  end,

  popup_ignore_choice = function(t)
    alliance(17)
    local Q = load()
    Q.UI.Tracker:OpenDungeonAlert()
    Mock.click(Q.UI.DungeonPopup.ignoreButton, "LeftButton")
    t.eq(stateOf(Q, "DM"), "ignored")
    t.eq(#Q.char.inserted, 0)
    t.ok(not Q.UI.Tracker.dungeonAlert:IsShown())
    noErrors(t)
  end,

  journal_lists_dungeons_with_actions = function(t)
    alliance(17)
    local Q = load()
    local J = Q.UI.Journal
    J:ShowTab("class")
    t.ok(J.dungeonHeader:IsShown(), "section header")
    local row = J.dungeonRows[1]
    t.ok(row and row:IsShown(), "dungeon row")
    t.eq(row.title:GetText(), "The Deadmines")
    t.ok(plain(row.info:GetText()):find(Q.L.DUNGEON_STATE_AVAILABLE, 1, true), "state shown")
    t.ok(row.addButton:IsShown() and row.ignoreButton:IsShown())
    Mock.click(row.addButton, "LeftButton")
    t.eq(stateOf(Q, "DM"), "added")
    t.ok(plain(J.dungeonRows[1].info:GetText()):find(Q.L.DUNGEON_STATE_ADDED, 1, true), "refreshed")
    Mock.click(J.dungeonRows[1].ignoreButton, "LeftButton")
    t.ok(J.dungeonRows[1].unignoreButton:IsShown(), "Réactiver")
    Mock.click(J.dungeonRows[1].unignoreButton, "LeftButton")
    t.eq(stateOf(Q, "DM"), "available")
    -- option dans la fenêtre d'options (Classe et donjons)
    Q.UI.Options:Open("class")
    local w = Q.UI.Options:Widget("dungeonSuggest")
    t.ok(w and w.check, "option checkbox")
    t.eq(w.check:GetChecked(), true)
    noErrors(t)
  end,

  no_alert_when_the_route_already_has_the_quests = function(t)
    alliance(17)
    local data = testData()
    -- 3361 est prise par le chapitre de la fixture : la route s'occupe déjà de ce donjon
    data[2].quests.Alliance = { { id = 3361, giver = 8416, at = { 1426, 28.55, 67.64 }, reqLevel = 1 } }
    local Q = load({ data = data })
    Q.Progress:SetGuide("A_DwarfGnome_01")
    t.eq(stateOf(Q, "DM"), "available")
    t.eq(#Q.Dungeons:Alerts(), 0)
    -- un autre chapitre sans cette quête : l'alerte revient
    Q.Progress:SetGuide("A_DwarfGnome_02")
    t.eq(#Q.Dungeons:Alerts(), 1)
    noErrors(t)
  end,

  added_dungeon_survives_reload = function(t)
    alliance(17)
    local Q = load()
    Q.Dungeons:Add("DM")
    local data = testData()
    local Q2 = Mock.reload({ extraFiles = { GUIDES }, skipGuides = true, qdb = QDB_EXTRA,
      beforeLogin = function(q) q.DungeonData = data end })
    t.eq(stateOf(Q2, "DM"), "added")
    t.eq(Q2.Progress:Current().key, "i:dg:DM:1")
  end,

  real_data_smoke_and_faction_rule = function(t)
    -- Données livrées, QuestieDB de la fixture (quêtes inconnues : jamais bloquées) : aucun donjon ne
    -- lève d'erreur, le Gouffre de Ragefeu n'apparaît jamais côté Alliance, chaque donjon proposé
    -- s'ajoute puis s'ignore.
    local real = {}
    assert(loadfile(Mock.root .. "/" .. DATA_FILE))("Questify", real)
    for _, side in ipairs({ "Alliance", "Horde" }) do
      Mock.reset()
      if side == "Alliance" then alliance(10) else horde(10) end
      local Q = load({ data = real.DungeonData })
      local listedOnce = {}
      for level = 10, 45 do
        Mock.player.level = level
        Mock.fire("PLAYER_LEVEL_UP", level)
        for _, row in ipairs(Q.Dungeons:List()) do
          local d = row.dungeon
          listedOnce[d.key] = true
          t.ok(not (side == "Alliance" and d.areaId == 2437), "Ragefire listed for Alliance at " .. level)
          local allowed = false
          for _, f in ipairs(d.factions) do if f == side then allowed = true end end
          t.ok(allowed, d.key .. " listed for a faction it does not allow")
          if row.state == "available" then
            t.eq(Q.Dungeons:Add(d.key), true, d.key .. " added at " .. level)
            t.ok(#tagged(Q, "dg:" .. d.key) > 0, d.key .. " steps")
            t.eq(Q.Dungeons:Ignore(d.key), true)
            Q.Dungeons:Unignore(d.key)
          end
        end
        Q.UI.Tracker:Refresh()
      end
      t.ok(listedOnce[side == "Alliance" and "DM" or "RFC"], "starter dungeon listed for " .. side)
      t.ok(listedOnce.WC, "Wailing Caverns listed for " .. side)
    end
    noErrors(t)
  end,

  generated_data_is_sane = function(t)
    local Q = {}
    local chunk = assert(loadfile(Mock.root .. "/" .. DATA_FILE))
    chunk("Questify", Q)
    local data = Q.DungeonData
    t.eq(type(data), "table")
    t.ok(#data >= 10, "dungeons generated")
    local seenKeys, rfc = {}, nil
    for _, d in ipairs(data) do
      t.eq(type(d.key), "string")
      t.ok(not seenKeys[d.key], "unique key " .. d.key)
      seenKeys[d.key] = true
      t.eq(type(d.name), "string")
      t.eq(type(d.areaId), "number")
      t.ok(type(d.minLevel) == "number" and type(d.maxLevel) == "number" and d.minLevel <= d.maxLevel,
        d.key .. " level range")
      t.ok(type(d.entrance) == "table" and type(d.entrance[1]) == "number" and type(d.entrance[2]) == "number"
        and type(d.entrance[3]) == "number", d.key .. " entrance")
      t.ok(d.entrance[2] >= 0 and d.entrance[2] <= 100 and d.entrance[3] >= 0 and d.entrance[3] <= 100,
        d.key .. " entrance in 0-100")
      t.ok(type(d.factions) == "table" and #d.factions > 0, d.key .. " factions")
      for _, f in ipairs(d.factions) do
        t.ok(f == "Alliance" or f == "Horde", "faction name")
        local list = d.quests[f]
        t.ok(type(list) == "table" and #list > 0, d.key .. " quests for " .. f)
        local town = 0
        for _, e in ipairs(list) do
          t.eq(type(e.id), "number")
          if not e.inside then
            t.ok(type(e.at) == "table" and type(e.at[1]) == "number", d.key .. " quest " .. e.id .. " giver position")
            t.ok(type(e.giver) == "number" or type(e.obj) == "number", d.key .. " quest " .. e.id .. " starter")
            if not e.bc then town = town + 1 end
          else
            t.ok(type(e.endAt) == "table", d.key .. " inside quest " .. e.id .. " turn-in position")
          end
        end
        t.ok(town > 0, d.key .. " has a quest to pick up in town for " .. f)
      end
      if d.areaId == 2437 then rfc = d end
    end
    t.ok(rfc, "Ragefire Chasm generated")
    t.eq(rfc.factions, { "Horde" }, "Ragefire is Horde only")
    t.eq(rfc.quests.Alliance, nil, "no Alliance quest listed for Ragefire")
    for _, e in ipairs(rfc.quests.Horde) do
      t.ok(e.races == nil or e.races ~= ALLIANCE, "no Alliance-only quest in Ragefire")
    end
  end,
}
