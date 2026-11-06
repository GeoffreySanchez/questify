-- Tests de la commande cachée /qf demo (UI/Demo.lua) : scènes d'exemple pour les captures en jeu.
-- Les vraies fenêtres s'ouvrent avec des données d'exemple ; rien n'est écrit, aucun bouton n'agit.
local TOC = "Questify/Questify.toc"
local Ext = dofile(Mock.root .. "/tests/mock_ext_comfort.lua")

local function load(opts)
  Ext.install()
  opts = opts or {}
  if opts.skipGuides == nil then opts.skipGuides = false end   -- vrais guides et vraies données
  RaidWarningFrame = Mock.newObject("Frame", "RaidWarningFrame")
  RaidWarningUtil = {
    AddMessage = function(text, color) Mock.record("RaidWarningUtil.AddMessage", text, color) end,
  }
  C_Item.EquipItemByName = function(link, slot) Mock.record("C_Item.EquipItemByName", link, slot) end
  return Mock.loadAddon(TOC, opts)
end

local function qf(msg) SlashCmdList.QUESTIFY(msg) end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- Objets d'exemple connus du client (le premier de chaque liste suffit).
local function stubItems(Q)
  local D = Q.UI.Demo
  local function def(id, name, equipLoc)
    Mock.items[id] = { id = id, name = name, link = "|cff1eff00|Hitem:" .. id .. "::::::::|h[" .. name .. "]|h|r",
      equipLoc = equipLoc, classID = 2, subclassID = 4, itemType = "Armor", minLevel = 1 }
  end
  def(D.ITEMS.upgrade[1], "Exemple d'objet", "INVTYPE_SHIELD")
  def(D.ITEMS.main[1], "Exemple de masse", "INVTYPE_WEAPONMAINHAND")
  def(D.ITEMS.off[1], "Exemple de bouclier", "INVTYPE_SHIELD")
end

local function noErrors(t)
  t.eq(Mock.errors, {}, "no error")
end

local function shown(frame) return frame ~= nil and frame:IsShown() end

local function warnTexts(Q)
  local out = {}
  for _, line in ipairs(Q.UI.Tracker.warnLines or {}) do
    if line:IsShown() then out[#out + 1] = plain(line:GetText()) end
  end
  return out
end

local function centerTexts()
  local out = {}
  for _, c in ipairs(Mock.callsTo("RaidWarningUtil.AddMessage")) do out[#out + 1] = c.args[1] end
  return out
end

return {
  -- /qf demo seul : la liste des scènes dans la discussion ; la commande reste absente de l'aide.
  demo_lists_scenes_and_is_hidden = function(t)
    local Q = load()
    qf("demo")
    for _, name in ipairs(Q.UI.Demo.SCENES) do
      t.ok(Mock.printed("/qf demo " .. name), "listed: " .. name)
    end
    t.ok(Mock.printed("/qf demo all"), "all listed")
    t.ok(Mock.printed("/qf demo off"), "off listed")
    qf("help")
    t.ok(not Q.L.UI_SLASH_HELP:lower():find("demo", 1, true), "absent from the help")
    for _, key in ipairs({ "UI_SLASH_HELP", "UI_MINIMAP_TIP", "UI_MINIMAP_MENU" }) do
      t.ok(not tostring(Q.L[key]):lower():find("demo", 1, true), key)
    end
    t.eq(#Mock.errors, 0)
  end,

  demo_unknown_scene_lists_them = function(t)
    local Q = load()
    qf("demo nothing")
    t.ok(Mock.printed(string.format(Q.L.UI_DEMO_UNKNOWN, "nothing")))
    noErrors(t)
  end,

  -- Chaque scène s'ouvre sans erreur et montre quelque chose.
  classquest_scene_opens_the_real_window = function(t)
    local Q = load()
    qf("demo classquest")
    local P = Q.UI.ClassQuestPopup
    t.ok(shown(P.frame), "window shown")
    t.ok(P.chain and P.chain.demo, "demo chain")
    t.eq(P.title:GetText(), P.ChainTitle(P.chain))
    t.ok(P.chain.key:find("^WARRIOR_"), "chain of the player's class: " .. tostring(P.chain.key))
    t.ok(#Q.UI.Tracker.ClassAlerts() == 1, "the tracker shows the alert too")
    noErrors(t)
  end,

  classlate_scene_shows_the_overdue_alert = function(t)
    local Q = load()
    Mock.player.level = 20
    Mock.fire("PLAYER_LEVEL_UP", 20)
    qf("demo classlate")
    local Tk = Q.UI.Tracker
    t.ok(shown(Tk.alert), "alert shown")
    t.eq(Tk.alertText:GetText(), string.format(Q.L.UI_CLASS_ALERT_LATE_ONE, Tk.ClassAlerts()[1] and
      Q.UI.ClassQuestPopup.ChainTitle(Tk.ClassAlerts()[1])))
    t.ok(not shown(Q.UI.ClassQuestPopup.frame), "window not opened by itself")
    -- un clic sur l'alerte ouvre la fenêtre, toujours en démonstration
    Tk:OpenAlert()
    t.ok(shown(Q.UI.ClassQuestPopup.frame))
    t.ok(Q.UI.ClassQuestPopup.chain.demo)
    noErrors(t)
  end,

  dungeon_scene_opens_the_faction_dungeon = function(t)
    local Q = load()
    qf("demo dungeon")
    local P = Q.UI.DungeonPopup
    t.ok(shown(P.frame), "window shown")
    t.eq(P.dungeon.key, "DM", "Alliance: The Deadmines")
    t.ok(P.dungeon.demo)
    t.eq(P.title:GetText(), P.DungeonName(P.dungeon))
    t.ok(#Q.UI.Tracker.DungeonAlerts() == 1, "alert in the tracker")
    Q.Player.faction = "Horde"
    qf("demo dungeon")
    t.eq(P.dungeon.key, "RFC", "Horde: Ragefire Chasm")
    noErrors(t)
  end,

  upgrade_and_pair_scenes = function(t)
    local Q = load()
    stubItems(Q)
    local P = Q.UI.UpgradePopup
    qf("demo upgrade")
    t.ok(shown(P.frame), "announcement shown")
    t.ok(P.current.demo)
    t.ok(P.text:GetText():find("Exemple d'objet", 1, true), "item named")
    qf("demo pair")
    t.ok(shown(P.frame))
    t.ok(P.current.pair and P.current.demo, "pair announcement")
    t.eq(P.text:GetText(), string.format(Q.L.UI_UPGRADE_TEXT_PAIR, Mock.items[Q.UI.Demo.ITEMS.main[1]].link,
      Mock.items[Q.UI.Demo.ITEMS.off[1]].link))
    noErrors(t)
  end,

  -- Objet pas encore connu du client : on attend son chargement, puis on affiche ; jamais connu : un message.
  upgrade_scene_waits_for_the_item = function(t)
    local Q = load()
    local P = Q.UI.UpgradePopup
    qf("demo upgrade")
    t.ok(not shown(P.frame), "nothing yet")
    stubItems(Q)
    Mock.advance(1)
    t.ok(shown(P.frame), "shown once loaded")
    qf("demo off")
    Mock.reset()
    Q = load()
    P = Q.UI.UpgradePopup
    qf("demo upgrade")
    Mock.advance(30)
    t.ok(not shown(P.frame), "never loaded: nothing shown")
    t.ok(Mock.printed(Q.L.UI_DEMO_WHY_ITEM), "says why")
    noErrors(t)
  end,

  route_scene_shows_the_loch_modan_choice = function(t)
    local Q = load()
    qf("demo route")
    local P = Q.UI.RouteChoicePopup
    t.ok(P:IsShown(), "window shown")
    t.eq(#P.cards, 2, "two cards")
    t.eq(P.fromId, "A_DwarfGnome_03")
    local rec = 0
    for _, c in ipairs(P.cards) do if c.recommended then rec = rec + 1 end end
    t.eq(rec, 1, "one recommended card, ranked as in real life")
    t.eq(P.subtitle:GetText(), string.format(Q.L.UI_ROUTECHOICE_SUBTITLE, Q.Guides:DisplayTitle("A_DwarfGnome_03")))
    noErrors(t)
  end,

  supplies_scene_shows_line_message_and_chat = function(t)
    local Q = load()
    qf("demo supplies")
    local lines = {}
    for _, l in ipairs(Q.Supplies:Lines()) do lines[#lines + 1] = plain(l) end
    local slots = string.format(Q.L.COMFORT_SLOTS_FREE, 4, 64)
    t.eq(lines, { string.format(Q.L.COMFORT_BAGS_FULL, slots), Q.L.COMFORT_NO_DRINK })
    local msg = string.format(Q.L.COMFORT_SUPPLY_ALERT, slots .. Q.L.COMFORT_LIST_SEP .. Q.L.COMFORT_PART_DRINK)
    t.eq(centerTexts(), { msg })
    t.ok(Mock.printed(msg), "chat line")
    t.eq(warnTexts(Q), lines, "tracker lines")
    noErrors(t)
  end,

  cave_scene_places_the_titled_waypoint = function(t)
    local Q = load()
    qf("demo cave")
    local st = Q.Nav:Status()
    local cave
    for _, c in ipairs(Q.CaveData) do if c.key == "dunmorogh_grizzled_den" then cave = c end end
    t.ok(cave, "real cave data")
    t.eq(st.target.mapId, cave.mapId)
    t.eq(st.target.x, cave.entrance[1])
    t.eq(st.target.y, cave.entrance[2])
    t.eq(st.target.title, Q.L.NAV_CAVE_ENTER .. " — The Grizzled Den")
    noErrors(t)
  end,

  profession_scene_shows_the_step_text_without_inserting_it = function(t)
    local Q = load()
    local before = Mock.deepcopy(Q.char.inserted)
    qf("demo profession")
    local title = Q.Format:StepTitle({ step = { action = "trainprof", prof = "HERBALISM", rank = 2 } })
    t.ok(Mock.printed(title), "title in the chat")
    local found = false
    for _, text in ipairs(warnTexts(Q)) do
      if text:find(Q.Professions:Name("HERBALISM"), 1, true) and text:find(Q.L.PROF_RANK_2, 1, true) then found = true end
    end
    t.ok(found, "step text in the tracker")
    t.eq(Q.char.inserted, before, "no step inserted into the route")
    noErrors(t)
  end,

  -- Aucune écriture dans la progression ni dans les réglages, scène après scène.
  no_scene_writes_progress = function(t)
    local Q = load()
    stubItems(Q)
    -- tables créées à la demande par la lecture des modules : on les fait exister avant la photo
    Q.ClassQuests:Alerts()
    Q.Dungeons:Alerts()
    Q.UI.Tracker:Refresh()
    Mock.advance(10)   -- minuteries du démarrage (assistant, relevés) avant la photo
    local char, db = Mock.deepcopy(Q.char), Mock.deepcopy(QuestifyDB)
    for _, name in ipairs(Q.UI.Demo.SCENES) do
      qf("demo " .. name)
      Mock.advance(1)
      t.eq(Q.char, char, "Q.char unchanged after " .. name)
      t.eq(QuestifyDB, db, "QuestifyDB unchanged after " .. name)
    end
    qf("demo off")
    t.eq(Q.char, char, "Q.char unchanged after off")
    t.eq(QuestifyDB, db, "QuestifyDB unchanged after off")
    noErrors(t)
  end,

  -- Les boutons des fenêtres ferment sans agir.
  buttons_are_inert = function(t)
    local Q = load()
    stubItems(Q)
    local char = Mock.deepcopy(Q.char)
    local function inert(label)
      t.eq(Q.char, char, label .. ": nothing written")
    end
    local cq, dg = Q.UI.ClassQuestPopup, Q.UI.DungeonPopup
    qf("demo classquest")
    Mock.click(cq.addButton)
    t.ok(not shown(cq.frame), "class window closed")
    inert("class add")
    qf("demo classquest")
    Mock.click(cq.ignoreButton)
    t.ok(not shown(cq.frame))
    inert("class ignore")
    t.eq(#Q.UI.Tracker.ClassAlerts(), 1, "the alert is still there")

    qf("demo dungeon")
    Mock.click(dg.addButton)
    t.ok(not shown(dg.frame), "dungeon window closed")
    inert("dungeon add")
    qf("demo dungeon")
    Mock.click(dg.ignoreButton)
    t.ok(not shown(dg.frame))
    inert("dungeon ignore")

    local up = Q.UI.UpgradePopup
    qf("demo upgrade")
    Mock.click(up.frame, "LeftButton")
    t.eq(Mock.countCalls("C_Item.EquipItemByName"), 0, "nothing equipped")
    t.ok(not shown(up.frame), "announcement closed")
    qf("demo pair")
    Mock.click(up.frame, "LeftButton")
    Mock.advance(2)
    t.eq(Mock.countCalls("C_Item.EquipItemByName"), 0, "pair: nothing equipped")

    local rp = Q.UI.RouteChoicePopup
    for _, which in ipairs({ "card", "keep", "later" }) do
      qf("demo route")
      if which == "card" then Mock.click(rp.cardFrames[1].frame)
      elseif which == "keep" then Mock.click(rp.keepButton)
      else Mock.click(rp.laterButton) end
      t.ok(not rp:IsShown(), "route window closed by " .. which)
      inert("route " .. which)
      t.eq(Q.Progress:PendingChoice(), nil)
    end
    t.eq(#Mock.callsTo("RaidWarningUtil.AddMessage"), 0)
    noErrors(t)
  end,

  -- En combat : un message, rien d'ouvert.
  refused_in_combat = function(t)
    local Q = load()
    local nav = Q.Nav:Status().target
    Mock.player.combat = true
    for _, name in ipairs(Q.UI.Demo.SCENES) do
      qf("demo " .. name)
    end
    t.eq(Mock.countPrinted(Q.L.UI_DEMO_COMBAT), #Q.UI.Demo.SCENES, "message each time")
    t.ok(not shown(Q.UI.ClassQuestPopup.frame))
    t.ok(not shown(Q.UI.DungeonPopup.frame))
    t.ok(not shown(Q.UI.UpgradePopup.frame))
    t.ok(not Q.UI.RouteChoicePopup:IsShown())
    t.eq(Q.Supplies:Lines(), {})
    t.eq(Q.Nav:Status().target, nav, "waypoint untouched")
    noErrors(t)
  end,

  -- Début de combat pendant une scène : tout se range.
  combat_closes_the_demo = function(t)
    local Q = load()
    qf("demo route")
    t.ok(Q.UI.RouteChoicePopup:IsShown())
    Mock.player.combat = true
    Mock.fire("PLAYER_REGEN_DISABLED")
    t.ok(not Q.UI.RouteChoicePopup:IsShown())
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(not Q.UI.RouteChoicePopup:IsShown(), "not reopened after the fight")
    noErrors(t)
  end,

  -- /qf demo off : fenêtres fermées, lignes, alertes et repère comme avant.
  off_restores_the_previous_state = function(t)
    local Q = load()
    stubItems(Q)
    Q.Nav:SetTarget(1426, 30, 70, "Avant")
    local nav = Q.Nav:Status().target
    local alertsBefore = #Q.UI.Tracker.ClassAlerts()
    for _, name in ipairs(Q.UI.Demo.SCENES) do
      qf("demo " .. name)
      qf("demo off")
      t.ok(not shown(Q.UI.ClassQuestPopup.frame), name .. ": class window")
      t.ok(not shown(Q.UI.DungeonPopup.frame), name .. ": dungeon window")
      t.ok(not shown(Q.UI.UpgradePopup.frame), name .. ": upgrade window")
      t.ok(not Q.UI.RouteChoicePopup:IsShown(), name .. ": route window")
      t.eq(Q.Supplies:Lines(), {}, name .. ": lines")
      t.eq(#Q.UI.Tracker.ClassAlerts(), alertsBefore, name .. ": class alerts")
      t.eq(#Q.UI.Tracker.DungeonAlerts(), 0, name .. ": dungeon alerts")
      t.eq(Q.Nav:Status().target, nav, name .. ": waypoint")
      t.eq(warnTexts(Q), {}, name .. ": tracker warnings")
    end
    t.ok(Mock.printed(Q.L.UI_DEMO_OFF))
    -- sans repère avant : rien après
    Q.Nav:Clear()
    qf("demo cave")
    qf("demo off")
    t.eq(Q.Nav:Status().target, nil, "no waypoint left")
    noErrors(t)
  end,

  -- Les méthodes remplacées sont rendues telles quelles.
  off_gives_the_original_functions_back = function(t)
    local Q = load()
    local fns = { Q.Supplies.Lines, Q.ClassQuests.Alerts, Q.ClassQuests.IsLate, Q.Dungeons.Alerts }
    for _, name in ipairs({ "supplies", "classlate", "dungeon", "profession" }) do
      qf("demo " .. name)
      qf("demo off")
    end
    t.ok(Q.Supplies.Lines == fns[1] and Q.ClassQuests.Alerts == fns[2] and Q.ClassQuests.IsLate == fns[3]
      and Q.Dungeons.Alerts == fns[4], "originals restored")
  end,

  -- all / next : une scène à la fois.
  all_and_next_walk_through_the_scenes = function(t)
    local Q = load()
    stubItems(Q)
    local D = Q.UI.Demo
    qf("demo all")
    t.ok(Mock.printed(string.format(Q.L.UI_DEMO_STEP, D.SCENES[1], 1, #D.SCENES)), "first scene named")
    t.ok(shown(Q.UI.ClassQuestPopup.frame), "first scene shown")
    qf("demo next")
    t.ok(not shown(Q.UI.ClassQuestPopup.frame), "previous scene closed")
    t.ok(Mock.printed(string.format(Q.L.UI_DEMO_STEP, D.SCENES[2], 2, #D.SCENES)))
    for _ = 3, #D.SCENES do qf("demo next") end
    t.ok(Mock.printed(string.format(Q.L.UI_DEMO_STEP, D.SCENES[#D.SCENES], #D.SCENES, #D.SCENES)))
    qf("demo next")
    t.ok(Mock.printed(Q.L.UI_DEMO_LAST), "end of the sequence")
    qf("demo off")
    qf("demo next")
    t.ok(Mock.printed(Q.L.UI_DEMO_NO_SEQUENCE), "next without a sequence")
    noErrors(t)
  end,

  -- Donnée ou API absente : la scène le dit, rien ne plante.
  missing_data_is_reported_not_raised = function(t)
    local Q = load()
    Q.ClassQuestData = nil
    Q.DungeonData = nil
    Q.CaveData = nil
    Q.Professions = nil
    for _, name in ipairs({ "classquest", "classlate", "dungeon", "route", "cave", "profession" }) do
      qf("demo " .. name)
    end
    t.ok(Mock.countPrinted(string.format(Q.L.UI_DEMO_MISSING, "classquest", Q.L.UI_DEMO_WHY_DATA)) == 1)
    t.ok(Mock.countPrinted(Q.L.UI_DEMO_WHY_DATA) >= 4, "each missing scene says why")
    noErrors(t)
  end,

  -- Textes visibles dans les deux langues.
  demo_texts_exist_in_both_languages = function(t)
    local f = assert(io.open(Mock.root .. "/Questify/Locales/StringsUI.lua", "rb"))
    local src = f:read("*a"); f:close()
    local en, fr = src:match("enUS = (.-)\n  frFR = (.*)$")
    t.ok(en and fr, "two blocks")
    local keys = {}
    for key in en:gmatch("(UI_DEMO_[%w_]+) =") do keys[key] = true end
    local n = 0
    for key in pairs(keys) do
      n = n + 1
      t.ok(fr:find(key .. " =", 1, true), key .. " in frFR")
    end
    t.ok(n >= 12, "demo texts present: " .. n)
    local _, count = en:gsub("UI_DEMO_", "")
    local _, countFr = fr:gsub("UI_DEMO_", "")
    t.eq(count, countFr, "same number of keys")
  end,

  -- Aucun chemin personnel, nom ou adresse dans le module.
  module_has_no_personal_data = function(t)
    local f = assert(io.open(Mock.root .. "/Questify/UI/Demo.lua", "rb"))
    local src = f:read("*a"); f:close()
    t.ok(not src:find("/Users/", 1, true))
    t.ok(not src:find("@", 1, true) or not src:find("%w@%w"), "no address")
  end,
}
