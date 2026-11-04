-- Tests de l'alerte élites / danger (Q.Danger, Engine/Danger.lua).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_comfort.lua")

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- Étape courante « complete 179 » (quête dans le journal, objectif en cours).
local function load(noQuest)
  Ext.install()
  if not noQuest then
    Mock.quests.log[179] = { objectives = { { text = "Dwarven Outfitters", finished = false } } }
  end
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  return Q
end

local ELITE = { name = "Rockjaw Bonesnapper", level = 3, classification = "elite", npcId = 1117 }
local HIGH = { name = "Wendigo", level = 4, npcId = 1135 }

local function warnTexts(Q)
  local out = {}
  for _, line in ipairs(Q.UI.Tracker.warnLines) do
    if line:IsShown() then out[#out + 1] = plain(line:GetText()) end
  end
  return out
end

return {
  elite_nearby_warns_in_tracker_and_chat = function(t)
    local Q = load()
    t.eq(Q.Progress:Current().step.action, "complete")
    Ext.addPlate("nameplate1", ELITE)
    local expected = string.format(Q.L.COMFORT_DANGER_ELITE, "Rockjaw Bonesnapper", "3")
    t.eq(plain(Q.Danger:Line()), expected)
    t.eq(warnTexts(Q), { expected })
    t.eq(Mock.countPrinted(string.format(Q.L.COMFORT_DANGER_CHAT_ELITE, "Rockjaw Bonesnapper", "3")), 1)
    Ext.removePlate("nameplate1")
    t.eq(Q.Danger:Line(), nil)
    t.eq(warnTexts(Q), {})
    t.eq(#Mock.errors, 0)
  end,

  three_levels_above_is_dangerous = function(t)
    local Q = load()
    Ext.addPlate("nameplate1", { name = "Wolf", level = 3 })   -- 2 niveaux au-dessus : rien
    t.eq(Q.Danger:Line(), nil)
    Ext.addPlate("nameplate2", HIGH)
    t.eq(plain(Q.Danger:Line()), string.format(Q.L.COMFORT_DANGER_HIGH, "Wendigo", "4"))
    -- l'élite passe devant
    Ext.addPlate("nameplate3", ELITE)
    t.eq(plain(Q.Danger:Line()), string.format(Q.L.COMFORT_DANGER_ELITE, "Rockjaw Bonesnapper", "3"))
    -- niveau inconnu (crâne) : dangereux
    Ext.removePlate("nameplate2")
    Ext.removePlate("nameplate3")
    Ext.addPlate("nameplate4", { name = "Boss", level = -1, npcId = 99 })
    t.eq(plain(Q.Danger:Line()), string.format(Q.L.COMFORT_DANGER_HIGH, "Boss", "??"))
    t.eq(Mock.countPrinted("Wendigo"), 0, "higher level only: tracker line, no chat")
    t.eq(Mock.countPrinted("Boss"), 0)
  end,

  -- Monstre seulement 3 niveaux au-dessus : ligne du suivi, jamais de message dans la discussion.
  high_level_mob_gets_tracker_line_only = function(t)
    local Q = load()
    Ext.addPlate("nameplate1", HIGH)
    t.eq(plain(Q.Danger:Line()), string.format(Q.L.COMFORT_DANGER_HIGH, "Wendigo", "4"))
    t.eq(warnTexts(Q), { string.format(Q.L.COMFORT_DANGER_HIGH, "Wendigo", "4") })
    Ext.removePlate("nameplate1")
    Mock.advance(301)
    Ext.addPlate("nameplate2", HIGH)
    Mock.units.target = HIGH
    Mock.fire("PLAYER_TARGET_CHANGED")
    t.eq(#Mock.prints, 0, "no chat line for a mob that is only higher level")
    t.eq(#Mock.errors, 0)
  end,

  -- Rare : ligne du suivi et un message par PNJ (npcID) toutes les 5 minutes.
  rare_warns_once_per_npc_id = function(t)
    local Q = load()
    local RARE = { name = "Timber", level = 3, classification = "rare", npcId = 1132 }
    Ext.addPlate("nameplate1", RARE)
    t.eq(plain(Q.Danger:Line()), string.format(Q.L.COMFORT_DANGER_RARE, "Timber", "3"))
    local msg = string.format(Q.L.COMFORT_DANGER_CHAT_RARE, "Timber", "3")
    t.eq(Mock.countPrinted(msg), 1)
    Ext.addPlate("nameplate2", RARE)
    t.eq(Mock.countPrinted(msg), 1, "same npc id: once per 5 minutes")
    -- élite passe devant le rare dans le suivi
    Ext.addPlate("nameplate3", ELITE)
    t.eq(plain(Q.Danger:Line()), string.format(Q.L.COMFORT_DANGER_ELITE, "Rockjaw Bonesnapper", "3"))
    Ext.removePlate("nameplate3")
    Ext.addPlate("nameplate4", { name = "Timber", level = 3, classification = "rare", npcId = 1133 })
    t.eq(Mock.countPrinted(msg), 2, "another npc id")
    Mock.advance(301)
    Ext.removePlate("nameplate1")
    Ext.addPlate("nameplate1", RARE)
    t.eq(Mock.countPrinted(msg), 3, "again after 5 minutes")
    t.eq(#Mock.errors, 0)
  end,

  ignores_friends_players_and_dead = function(t)
    local Q = load()
    Ext.addPlate("nameplate1", { name = "Guard", level = 30, classification = "elite", hostile = false })
    Ext.addPlate("nameplate2", { name = "Corpse", level = 9, classification = "elite", dead = true })
    Ext.addPlate("nameplate3", { name = "Pet", level = 9, playerControlled = true })
    t.eq(Q.Danger:Line(), nil)
    t.eq(#Mock.prints, 0)
  end,

  one_chat_line_per_mob_per_five_minutes = function(t)
    local Q = load()
    local msg = string.format(Q.L.COMFORT_DANGER_CHAT_ELITE, "Rockjaw Bonesnapper", "3")
    Ext.addPlate("nameplate1", ELITE)
    Ext.removePlate("nameplate1")
    Ext.addPlate("nameplate2", ELITE)
    t.eq(Mock.countPrinted(msg), 1)
    Ext.removePlate("nameplate2")
    Mock.advance(301)
    Ext.addPlate("nameplate1", ELITE)
    t.eq(Mock.countPrinted(msg), 2)
  end,

  target_is_checked = function(t)
    local Q = load()
    Mock.units.target = HIGH
    Mock.fire("PLAYER_TARGET_CHANGED")
    t.eq(plain(Q.Danger:Line()), string.format(Q.L.COMFORT_DANGER_HIGH, "Wendigo", "4"))
    t.eq(#Mock.prints, 0, "tracker line only")
    Mock.units.target = nil
    Mock.fire("PLAYER_TARGET_CHANGED")
    t.eq(Q.Danger:Line(), nil)
  end,

  only_on_complete_steps = function(t)
    local Q = load(true)
    t.eq(Q.Progress:Current().step.action, "accept")
    Ext.addPlate("nameplate1", ELITE)
    t.eq(Q.Danger:Line(), nil, "accept step")
    t.eq(#Mock.prints, 0)
  end,

  nothing_in_instances = function(t)
    local Q = load()
    Mock.player.instance = true
    Ext.addPlate("nameplate1", ELITE)
    t.eq(Q.Danger:Line(), nil, "instance")
    t.eq(#Mock.prints, 0)
  end,

  option_off = function(t)
    local Q = load()
    Ext.addPlate("nameplate1", ELITE)
    t.ok(Q.Danger:Line())
    Q.Settings:Set("dangerAlert", false)
    t.eq(Q.Danger:Line(), nil)
    t.eq(warnTexts(Q), {})
    Ext.addPlate("nameplate2", HIGH)
    t.eq(Q.Danger:Line(), nil)
  end,

  combat_no_chat_until_it_ends = function(t)
    local Q = load()
    Mock.player.combat = true
    Ext.addPlate("nameplate1", ELITE)
    t.ok(Q.Danger:Line(), "tracker line in combat")
    t.eq(#Mock.prints, 0, "no chat in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(Mock.countPrinted(string.format(Q.L.COMFORT_DANGER_CHAT_ELITE, "Rockjaw Bonesnapper", "3")), 1)
    t.eq(#Mock.errors, 0)
  end,

  missing_api_is_silent = function(t)
    local Q = load()
    UnitClassification, UnitCanAttack = nil, nil
    Ext.addPlate("nameplate1", ELITE)
    t.eq(Q.Danger:Line(), nil)
    Ext.install()
    UnitLevel = nil
    Ext.addPlate("nameplate2", HIGH)
    t.eq(Q.Danger:Line(), nil)
    t.eq(#Mock.errors, 0)
    t.eq(#Mock.prints, 0)
  end,

  secret_values_are_ignored = function(t)
    local Q = load()
    Ext.addPlate("nameplate1", { name = "Ghost", level = Mock.strictSecret(9), classification = Mock.strictSecret("elite") })
    t.eq(Q.Danger:Line(), nil)
    -- élite au nom secret : ligne sans nom, pas de message faute de clé (ni npcID ni nom)
    Ext.addPlate("nameplate2", { name = Mock.strictSecret("Ghost"), level = 3, classification = "elite" })
    t.eq(plain(Q.Danger:Line()), string.format(Q.L.COMFORT_DANGER_ELITE, Q.L.COMFORT_DANGER_UNKNOWN, "3"))
    t.eq(#Mock.prints, 0)
    UnitCanAttack = function() return Mock.strictSecret(true) end
    Ext.addPlate("nameplate3", HIGH)
    t.eq(#Mock.errors, 0)
  end,

  without_questiedb_does_nothing = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    local before = #Mock.prints
    Ext.addPlate("nameplate1", ELITE)
    t.eq(Q.Danger:Line(), nil)
    t.eq(#Mock.prints, before)
    t.eq(#Mock.errors, 0)
  end,
}
