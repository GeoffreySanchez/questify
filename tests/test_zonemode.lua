-- Tests du mode zone (Q.ZoneMode) : objectifs proches de plusieurs quêtes regroupés en une visite.
-- Fixture calquée sur le fort de Tiragarde (Durotar, uiMap 1411) : « Vanquish the Betrayers »
-- (784 : marins, soldats et le lieutenant Benedict) et « The Admiral's Orders » (830, lancée par
-- l'enveloppe du coffre de Benedict, fermé par la clé que porte Benedict). Points réels de
-- QuestieDB (vue Forever), en partie.
local TOC = "Questify/Questify.toc"
local Ext = dofile(Mock.root .. "/tests/mock_ext_mappins.lua")

local SAILOR, MARINE, BENEDICT, GARTHOK, BOAR = 3128, 3129, 3192, 3139, 90501
local CHEST, ENVELOPE, KEY = 3239, 4881, 4882
local Q784, Q830, QFAR = 784, 830, 90500

local QDB = {
  quests = {
    [Q784] = { name = "Vanquish the Betrayers", startedBy = { { GARTHOK } }, finishedBy = { { GARTHOK } },
      requiredLevel = 3, questLevel = 7, objectives = { { { SAILOR }, { MARINE }, { BENEDICT } } } },
    [Q830] = { name = "The Admiral's Orders", startedBy = { nil, nil, { ENVELOPE } }, finishedBy = { { GARTHOK } },
      requiredLevel = 1, questLevel = 7 },
    [QFAR] = { name = "Far Away Boars", startedBy = { { GARTHOK } }, finishedBy = { { GARTHOK } },
      requiredLevel = 1, questLevel = 6, objectives = { { { BOAR } } } },
  },
  npcs = {
    [SAILOR] = { name = "Kul Tiras Sailor", minLevel = 5, maxLevel = 6, zoneID = 14, spawns = { [14] = {
      { 61.01, 58.75 }, { 55.92, 59.05 }, { 60.22, 59.18 }, { 57.11, 53.12 }, { 55.72, 57.54 }, { 58.77, 60.16 },
      { 56.36, 56.47 }, { 56.41, 58.48 }, { 57.11, 57.24 }, { 57.65, 58.54 }, { 57.8, 58.66 }, { 57.39, 56.76 },
      { 57.92, 57.21 }, { 58.19, 56.79 }, { 58.51, 57.5 }, { 59.38, 58.94 }, { 59.77, 58.06 } } } },
    [MARINE] = { name = "Kul Tiras Marine", minLevel = 6, maxLevel = 7, zoneID = 14, spawns = { [14] = {
      { 60.21, 60.17 }, { 60.75, 59.37 }, { 59.45, 55.47 }, { 59.5, 56.35 }, { 59.59, 56.75 }, { 58.11, 55.53 },
      { 57.51, 55.31 }, { 59.09, 55.59 }, { 59.69, 58.46 }, { 59.42, 58.48 }, { 59.57, 58.18 }, { 58.44, 58.49 },
      { 59.79, 57.85 }, { 59.2, 56.74 }, { 58.95, 58.31 }, { 59.34, 58.3 } } } },
    [BENEDICT] = { name = "Lieutenant Benedict", minLevel = 8, maxLevel = 8, rank = 0, zoneID = 14,
      spawns = { [14] = { { 59.72, 58.27 } } } },
    [GARTHOK] = { name = "Gar'Thok", minLevel = 10, maxLevel = 10, zoneID = 14, spawns = { [14] = { { 51.95, 43.5 } } },
      questStarts = { Q784 }, questEnds = { Q784, Q830 } },
    [BOAR] = { name = "Far Boar", minLevel = 5, maxLevel = 6, zoneID = 14, spawns = { [14] = {
      { 20.1, 20.2 }, { 21.3, 22.4 }, { 19.7, 23.1 }, { 22.0, 21.0 } } } },
  },
  objects = {
    [CHEST] = { name = "Benedict's Chest", zoneID = 14, spawns = { [14] = { { 59.26, 57.65 } } } },
  },
  items = {
    [ENVELOPE] = { name = "Aged Envelope", objectDrops = { CHEST }, class = 12 },
    [KEY] = { name = "Benedict's Key", npcDrops = { BENEDICT }, class = 13 },
  },
}

local OUTSIDE = { 52.0, 44.0 }   -- Razor Hill, loin du fort
local INSIDE = { 58.6, 57.4 }    -- dans la cour du fort

local function place(pos)
  Mock.player.map, Mock.player.x, Mock.player.y = 1411, pos[1], pos[2]
end

local bags

-- Joueur orc à Durotar ; `settings` est appliqué avant la connexion. steps : route de test.
local function load(opts)
  opts = opts or {}
  Mock.player.raceId, Mock.player.faction, Mock.player.level = 2, "Horde", 7
  place(opts.pos or OUTSIDE)
  bags = {}
  local settings = opts.settings
  local Q = Mock.loadAddon(TOC, {
    skipGuides = true,
    qdb = QDB,
    beforeLogin = function(Q)
      Ext.spy()
      C_Item.GetItemCount = function(id) return bags[id] or 0 end
      for path, value in pairs(settings or {}) do Q.Settings:Set(path, value) end
      if opts.keys then Q.ZoneMode.KEYS = opts.keys end
    end,
  })
  Mock.quests.log[Q784] = { objectives = {
    { text = "Kul Tiras Sailor slain: 0/10", finished = false },
    { text = "Kul Tiras Marine slain: 0/8", finished = false },
    { text = "Lieutenant Benedict slain: 0/1", finished = false },
  } }
  Mock.quests.log[QFAR] = { objectives = { { text = "Far Boar slain: 0/6", finished = false } } }
  Q:RegisterGuide({ id = "T_Tiragarde", faction = "Horde", minLevel = 6, maxLevel = 12, steps = opts.steps or {
    { "complete", Q784, at = { 1411, 57.04, 57.49 } },
    { "accept", Q830, at = { 1411, 59.26, 57.65 }, note = "Loot Aged Envelope to start the quest" },
    { "complete", QFAR, at = { 1411, 20.8, 21.6 } },
    { "turnin", Q784 },
    { "turnin", Q830 },
  } })
  Q.Progress:SetGuide("T_Tiragarde")
  Mock.advance(1.1)
  return Q
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- Texte complet de l'étape courante du suivi (morceaux de texte et lignes de monstres, dans l'ordre).
local function trackerText(T)
  local parts = {}
  for _, chunk in ipairs(T.textChunks) do
    if chunk:IsShown() then parts[#parts + 1] = plain(chunk:GetText()) end
  end
  return table.concat(parts, "\n")
end

local function mobLines(T)
  local out = {}
  for _, row in ipairs(T.mobRows) do
    if row.name:IsShown() then out[#out + 1] = plain(row.name:GetText()) end
  end
  return out
end

local function waypoint()
  local p = Mock.userWaypoint
  if not p then return nil end
  return p.uiMapID, p.position.x * 100, p.position.y * 100
end

local function order(Q)
  local out = {}
  for _, o in ipairs(Q.ZoneMode:Objectives()) do out[#out + 1] = o.name end
  return out
end

local function setObjective(questId, i, text, finished)
  Mock.quests.log[questId].objectives[i] = { text = text, finished = finished }
  Mock.fire("QUEST_LOG_UPDATE")
  Mock.advance(0.3)
  Mock.advance(1.1)
end

local function goInside()
  place(INSIDE)
  Mock.advance(1.1)
end

return {
  zone_formed_from_overlapping_steps = function(t)
    local Q = load()
    local z = Q.ZoneMode:Current()
    t.ok(z, "zone formed")
    t.eq(Q.Settings:Get("zoneMode"), true, "on by default")
    t.eq(z.center.mapId, 1411)
    t.eq(z.center[1], 1411)
    t.ok(z.center.x > 56 and z.center.x < 60 and z.center.y > 55 and z.center.y < 59, "centre in the keep")
    t.ok(z.radius >= 60 and z.radius <= 250, "radius clamped")
    t.eq(#z.entries, 2, "complete 784 + accept 830")
    t.eq(z.questCount, 2)
    t.eq(#z.objectives, 4, "sailors, marines, Benedict, chest")
    local kinds = {}
    for _, o in ipairs(z.objectives) do
      kinds[o.name] = o.kind
      t.ok(o.questId ~= QFAR, "far quest not merged")
      t.ok(#o.points > 0, "points inside the zone")
      t.eq(o.done, false)
      t.eq(o.priority, ({ object = 1, named = 2, mob = 3, item = 3 })[o.kind])
    end
    t.eq(kinds["Benedict's Chest"], "object")
    t.eq(kinds["Lieutenant Benedict"], "named", "single spawn = named")
    t.eq(kinds["Kul Tiras Sailor"], "mob")
    t.eq(kinds["Kul Tiras Marine"], "mob")
    t.eq(z.name, "Durotar", "map name until the sub-zone is known")
    t.eq(z.inside, false)
    t.eq(#Mock.errors, 0)
  end,

  outside_nav_targets_centre_and_tracker_shows_zone_line = function(t)
    local Q = load()
    local z = Q.ZoneMode:Current()
    local m, x, y = waypoint()
    t.eq(m, 1411)
    t.near(x, z.center.x, 0.01); t.near(y, z.center.y, 0.01)
    local tg = Q.Targets:ForEntry(Q.Progress:Current())
    t.eq(tg.kind, "zone")
    t.eq(tg.title, "Zone: Durotar")
    local T = Q.UI.Tracker
    local text = trackerText(T)
    t.ok(text:find("Zone: Durotar — 4 objectives (2 quests)", 1, true), "zone line: " .. text)
    t.ok(text:find("Vanquish the Betrayers", 1, true) and text:find("The Admiral's Orders", 1, true), "quests listed")
    t.eq(T.currentIcon:GetTexture(), T.ZONE_ICON, "green dot")
    t.eq(#mobLines(T), 0, "no mob rows outside")
    -- étapes regroupées dans la zone : pas répétées dans les étapes suivantes
    local nextText = plain(T.nextLines[1].text:GetText())
    t.ok(not nextText:find("Admiral", 1, true), "accept 830 inside the zone: " .. nextText)
    -- repère vert au centre, en plus des repères numérotés
    local zonePins, numbered = 0, 0
    for _, p in ipairs(Q.UI.MapPins.active) do
      if p.style == "zone" then
        zonePins = zonePins + 1
        t.near(p.x, z.center.x, 0.01)
      else
        numbered = numbered + 1
      end
    end
    t.eq(zonePins, 2, "world map and minimap")
    t.ok(numbered > 0, "numbered pins kept")
    t.eq(#Mock.errors, 0)
  end,

  inside_named_before_locked_chest_then_mobs = function(t)
    local Q = load()
    goInside()
    local z = Q.ZoneMode:Current()
    t.eq(z.inside, true)
    local names = order(Q)
    t.eq(names[1], "Lieutenant Benedict", "key holder first")
    t.eq(names[2], "Benedict's Chest", "chest waits for its key")
    t.ok((names[3] == "Kul Tiras Sailor" or names[3] == "Kul Tiras Marine")
      and (names[4] == "Kul Tiras Sailor" or names[4] == "Kul Tiras Marine"), "regular mobs last")
    local list = Q.ZoneMode:Objectives()
    t.eq(list[2].blocked.item, KEY)
    t.ok(list[3].distance <= list[4].distance, "nearest first at equal priority")
    -- flèche : Benedict
    local m, x, y = waypoint()
    t.eq(m, 1411); t.near(x, 59.72, 0.01); t.near(y, 58.27, 0.01)
    -- suivi : groupes dans l'ordre à suivre, monstres ciblables (nommé d'abord)
    local T = Q.UI.Tracker
    local text = trackerText(T)
    local gNamed = text:find("Elites and named", 1, true)
    local gObj = text:find("Objects", 1, true)
    local gMobs = text:find("Monsters", 1, true)
    t.ok(gNamed and gObj and gMobs and gNamed < gObj and gObj < gMobs, "groups in order: " .. text)
    t.ok(text:find("Loot Aged Envelope (Benedict's Chest) (needs Benedict's Key)", 1, true), "chest line: " .. text)
    t.ok(text:find("Kul Tiras Sailor slain: 0/10", 1, true), "progress text")
    local rows = mobLines(T)
    t.eq(rows[1], "Lieutenant Benedict", "named first")
    t.eq(#rows, 3)
    t.eq(T.currentIcon:GetTexture(), T.ZONE_ICON)
    -- clé ramassée : le coffre passe en tête
    bags[KEY] = 1
    Mock.fire("BAG_UPDATE_DELAYED")
    Mock.advance(1.1)
    t.eq(order(Q)[1], "Benedict's Chest", "key in bags: chest first")
    m, x, y = waypoint()
    t.near(x, 59.26, 0.01); t.near(y, 57.65, 0.01)
    t.eq(#Mock.errors, 0)
  end,

  inside_chest_first_without_key_data = function(t)
    local Q = load({ keys = {} })
    goInside()
    local names = order(Q)
    t.eq(names[1], "Benedict's Chest", "objects first")
    t.eq(names[2], "Lieutenant Benedict", "then named")
    t.eq(Q.ZoneMode:Objectives()[1].blocked, nil)
    local m, x, y = waypoint()
    t.near(x, 59.26, 0.01); t.near(y, 57.65, 0.01)
    t.eq(#Mock.errors, 0)
  end,

  key_holder_added_when_its_quest_is_not_in_the_zone = function(t)
    -- 784 absente de la route : Benedict est ajouté pour la clé du coffre
    local Q = load({ steps = {
      { "accept", Q830, at = { 1411, 59.26, 57.65 } },
      { "complete", QFAR, at = { 1411, 20.8, 21.6 } },
    } })
    local z = Q.ZoneMode:Current()
    t.ok(z, "chest + key holder form a zone")
    t.eq(#z.objectives, 2)
    goInside()
    local list = Q.ZoneMode:Objectives()
    t.eq(list[1].name, "Lieutenant Benedict")
    t.eq(list[1].key, true)
    t.eq(Q.ZoneMode:ProgressText(list[1]), "Loot Benedict's Key (Lieutenant Benedict)")
    t.eq(list[2].name, "Benedict's Chest")
    t.eq(#Mock.errors, 0)
  end,

  done_objectives_drop_out = function(t)
    local Q = load()
    goInside()
    setObjective(Q784, 3, "Lieutenant Benedict slain: 1/1", true)
    bags[KEY] = 1
    Mock.fire("BAG_UPDATE_DELAYED")
    Mock.advance(1.1)
    local names = order(Q)
    t.eq(#names, 3)
    for _, n in ipairs(names) do t.ok(n ~= "Lieutenant Benedict", "Benedict gone") end
    t.eq(names[1], "Benedict's Chest")
    local text = trackerText(Q.UI.Tracker)
    t.ok(not text:find("Elites and named", 1, true), "empty group hidden")
    -- enveloppe ramassée : le coffre sort de la liste, il reste les monstres d'une seule quête
    bags[ENVELOPE] = 1
    Mock.fire("BAG_UPDATE_DELAYED")
    Mock.advance(1.1)
    names = order(Q)
    t.eq(#names, 2, "zone continues until its last objective")
    t.ok(Q.ZoneMode:Current(), "still a zone")
    t.eq(#Mock.errors, 0)
  end,

  key_holder_stays_until_key_looted = function(t)
    local Q = load()
    goInside()
    setObjective(Q784, 3, "Lieutenant Benedict slain: 1/1", true)
    local first = Q.ZoneMode:Objectives()[1]
    t.eq(first.name, "Lieutenant Benedict", "key still to loot")
    t.eq(first.key, true)
    bags[KEY] = 1
    Mock.fire("BAG_UPDATE_DELAYED")
    Mock.advance(1.1)
    t.eq(Q.ZoneMode:Objectives()[1].name, "Benedict's Chest")
    t.eq(#Mock.errors, 0)
  end,

  zone_ends_when_everything_is_done = function(t)
    local Q = load()
    goInside()
    Mock.quests.log[Q784].complete = true
    for i, name in ipairs({ "Kul Tiras Sailor slain: 10/10", "Kul Tiras Marine slain: 8/8",
      "Lieutenant Benedict slain: 1/1" }) do
      Mock.quests.log[Q784].objectives[i] = { text = name, finished = true }
    end
    Mock.quests.log[Q830] = { objectives = {} }
    Mock.fire("QUEST_ACCEPTED", Q830)
    Mock.advance(1.1)
    t.eq(Q.ZoneMode:Current(), nil, "zone over")
    local cur = Q.Progress:Current()
    t.eq(cur.step.questId, QFAR, "next step resumes")
    local m, x, y = waypoint()
    t.eq(m, 1411); t.near(x, 20.8, 0.01); t.near(y, 21.6, 0.01)
    local T = Q.UI.Tracker
    t.ok(not trackerText(T):find("Zone", 1, true), "normal step text")
    t.eq(T.currentIcon:GetTexture(), Q.Format:ActionIcon("complete"))
    local zonePins = 0
    for _, p in ipairs(Q.UI.MapPins.active) do if p.style == "zone" then zonePins = zonePins + 1 end end
    t.eq(zonePins, 0)
    t.eq(#Mock.errors, 0)
  end,

  leaving_far_sends_arrow_back_to_centre = function(t)
    local Q = load()
    goInside()
    local z = Q.ZoneMode:Current()
    t.eq(z.inside, true)
    -- juste au-delà du rayon : toujours dedans (marge jusqu'à 2 × rayon)
    local cx = z.center.x
    local yardsPerPct = 5287 / 100
    place({ cx + (z.radius * 1.5) / yardsPerPct, z.center.y })
    Mock.advance(1.1)
    t.eq(Q.ZoneMode:Current().inside, true, "hysteresis")
    place({ cx + (z.radius * 2.3) / yardsPerPct, z.center.y })
    Mock.advance(1.1)
    z = Q.ZoneMode:Current()
    t.eq(z.inside, false, "left the zone")
    local m, x, y = waypoint()
    t.near(x, z.center.x, 0.01); t.near(y, z.center.y, 0.01)
    t.ok(trackerText(Q.UI.Tracker):find("objectives (2 quests)", 1, true))
    t.eq(#Mock.errors, 0)
  end,

  sub_zone_name_learned_inside = function(t)
    local Q = load()
    GetSubZoneText = function() return "Tiragarde Keep" end
    place({ Q.ZoneMode:Current().center.x, Q.ZoneMode:Current().center.y })
    Mock.advance(1.1)
    t.eq(Q.ZoneMode:Current().name, "Tiragarde Keep")
    t.ok(trackerText(Q.UI.Tracker):find("Zone: Tiragarde Keep", 1, true))
    t.eq(#Mock.errors, 0)
  end,

  nameplates_cover_zone_mobs_named_icon = function(t)
    local Q = load()
    goInside()
    local function addPlate(unit, npcId)
      Mock.units[unit] = { npcId = npcId, name = "x", level = 7, hostile = true }
      local plate = CreateFrame("Frame", nil, WorldFrame)
      Mock.nameplates[unit] = plate
      Mock.fire("NAME_PLATE_UNIT_ADDED", unit)
    end
    addPlate("nameplate1", BENEDICT)
    addPlate("nameplate2", SAILOR)
    local N = Q.UI.Nameplates
    t.ok(N.icons.nameplate1 and N.icons.nameplate2, "icons on zone mobs")
    t.eq(N.icons.nameplate1.texture:GetTexture(), "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", "named icon")
    t.eq(N.icons.nameplate2.texture:GetTexture(), "Interface\\GossipFrame\\AvailableQuestIcon")
    t.eq(#Mock.errors, 0)
  end,

  option_off_gives_old_behaviour = function(t)
    local Q = load({ settings = { zoneMode = false } })
    t.eq(Q.ZoneMode:Current(), nil)
    local m, x, y = waypoint()
    t.eq(m, 1411); t.near(x, 57.04, 0.01); t.near(y, 57.49, 0.01)
    local T = Q.UI.Tracker
    local text = trackerText(T)
    t.ok(not text:find("Zone", 1, true), "no zone line")
    t.ok(text:find("Vanquish the Betrayers", 1, true))
    t.eq(T.currentIcon:GetTexture(), Q.Format:ActionIcon("complete"))
    for _, p in ipairs(Q.UI.MapPins.active) do t.ok(p.style ~= "zone", "no zone pin") end
    goInside()
    t.eq(Q.ZoneMode:Current(), nil)
    t.eq(Q.Targets:ForEntry(Q.Progress:Current()).kind ~= "zone", true)
    -- option rallumée puis coupée : la zone revient puis disparaît aussitôt
    Q.Settings:Set("zoneMode", true)
    t.ok(Q.ZoneMode:Current(), "zone back")
    t.eq(Q.Targets:ForEntry(Q.Progress:Current()).kind, "zone")
    Q.Settings:Set("zoneMode", false)
    t.eq(Q.ZoneMode:Current(), nil)
    t.ok(not trackerText(T):find("Zone", 1, true))
    t.eq(#Mock.errors, 0)
  end,

  far_second_quest_not_merged = function(t)
    local Q = load({ steps = {
      { "complete", QFAR, at = { 1411, 20.8, 21.6 } },
      { "complete", Q784, at = { 1411, 57.04, 57.49 } },
    } })
    -- étape courante : les sangliers, seuls (une quête, un objectif) ; 784 est trop loin
    t.eq(Q.ZoneMode:Current(), nil, "no zone")
    t.ok(Q.Targets:ForEntry(Q.Progress:Current()).kind ~= "zone")
    t.eq(#Mock.errors, 0)
  end,

  single_quest_regular_mobs_keep_old_behaviour = function(t)
    local Q = load()
    Mock.quests.log[Q784].objectives[3] = { text = "Lieutenant Benedict slain: 1/1", finished = true }
    -- 784 seule (le coffre sorti de la route) : marins et soldats d'une seule quête, pas de zone
    Q:RegisterGuide({ id = "T_Plain", faction = "Horde", steps = { { "complete", Q784, at = { 1411, 57.04, 57.49 } } } })
    Q.Progress:SetGuide("T_Plain")
    Mock.advance(1.1)
    t.eq(Q.ZoneMode:Current(), nil)
    t.eq(#Mock.errors, 0)
  end,

  elite_rank_counts_as_named = function(t)
    QDB.npcs[MARINE].rank = 1
    local ok, err = pcall(function()
      local Q = load()
      t.eq(Q.ZoneMode:NpcRank(MARINE), 1)
      local kinds = Q.ZoneMode:NpcKinds()
      t.eq(kinds[MARINE], "named", "elite marine")
      t.eq(kinds[SAILOR], "mob")
    end)
    QDB.npcs[MARINE].rank = nil
    if not ok then error(err, 0) end
  end,

  french_zone_line = function(t)
    Mock.locale = "frFR"
    local Q = load()
    local text = trackerText(Q.UI.Tracker)
    t.ok(text:find("Zone : Durotar — 4 objectifs (2 quêtes)", 1, true), "French zone line: " .. text)
    goInside()
    text = trackerText(Q.UI.Tracker)
    t.ok(text:find("Élites et nommés", 1, true) and text:find("Objets", 1, true) and text:find("Monstres", 1, true),
      "French groups: " .. text)
    t.eq(#Mock.errors, 0)
  end,

  journal_has_the_option = function(t)
    local Q = load()
    local J = Q.UI.Journal
    J:ShowTab("options")
    local cb = J.checks.zoneMode
    t.ok(cb, "checkbox")
    t.eq(cb:GetChecked(), true)
    cb:SetChecked(false)
    Mock.click(cb, "LeftButton")
    t.eq(Q.Settings:Get("zoneMode"), false)
    t.eq(Q.ZoneMode:Current(), nil)
    t.ok(not trackerText(Q.UI.Tracker):find("Zone", 1, true), "tracker back to the step")
    t.eq(#Mock.errors, 0)
  end,

  combat_changes_touch_no_secure_frame = function(t)
    local Q = load()
    goInside()
    Mock.player.combat = true
    local rows = Q.UI.MobPanel.rows
    t.ok(#rows > 0, "targeting buttons placed out of combat")
    local before = {}
    for i, r in ipairs(rows) do before[i] = r:GetAttribute("macrotext") end
    -- en combat : Benedict tué, clé ramassée, la liste change ; les boutons sécurisés ne bougent pas
    bags[KEY] = 1
    Mock.fire("BAG_UPDATE_DELAYED")
    setObjective(Q784, 3, "Lieutenant Benedict slain: 1/1", true)
    for i, r in ipairs(rows) do t.eq(r:GetAttribute("macrotext"), before[i], "no attribute change in combat") end
    t.eq(Q.UI.MobPanel.pending, true, "rows marked pending until combat ends")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(Q.UI.MobPanel.pending, false)
    t.ok(not rows[1]:GetAttribute("macrotext"):find("Benedict", 1, true), "rows rebuilt after combat")
    t.eq(#Mock.errors, 0)
  end,

  missing_position_is_silent = function(t)
    local Q = load()
    Mock.player.x, Mock.player.y = nil, nil
    Mock.advance(3.1)
    local z = Q.ZoneMode:Current()
    t.ok(z, "zone kept")
    t.eq(z.inside, false)
    t.eq(Q.Targets:ForEntry(Q.Progress:Current()).kind, "zone")
    t.eq(#Mock.errors, 0)
  end,
}
