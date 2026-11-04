-- Tests de l'XP par heure dans l'en-tête du suivi (Q.XPRate, Engine/XPRate.lua).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_comfort.lua")

local function load(opts)
  Ext.install()
  opts = opts or {}
  if opts.setup then opts.setup() end
  opts.extraFiles = opts.extraFiles or { GUIDES }
  opts.skipGuides = true
  return Mock.loadAddon(TOC, opts)
end

-- n tranches de 10 s : le joueur bouge et gagne `gain` XP par tranche.
local function play(n, gain, still)
  for _ = 1, n do
    if gain and gain > 0 then
      Mock.comfort.xp = Mock.comfort.xp + gain
      Mock.fire("PLAYER_XP_UPDATE", "player")
    end
    if not still then Mock.player.x = Mock.player.x + 0.1 end
    Mock.advance(10)
  end
end

return {
  rate_and_time_to_level_after_three_minutes = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    play(17, 20)
    t.eq(Q.XPRate:Text(), nil, "blank before 3 minutes")
    t.ok(not T.xpLine:IsShown(), "no header line yet")
    play(1, 20)
    t.near(Q.XPRate:Rate(), 7200, 0.01)
    -- 360/1000 XP, 7200 XP/h : 640 XP en 320 s -> 6 min
    local expected = string.format(Q.L.COMFORT_XP_RATE_LEVEL, "7.2k", "6 min")
    t.eq(Q.XPRate:Text(), expected)
    t.ok(T.xpLine:IsShown(), "header line shown")
    t.eq(T.xpLine:GetText(), expected)
    play(1, 20)
    t.ok(T.xpLine:GetText() ~= nil, "updated in place")
    t.eq(#Mock.errors, 0)
  end,

  french_number_format = function(t)
    Mock.locale = "frFR"
    local Q = load()
    play(18, 20)
    t.eq(Q.XPRate:Text(), "7,2k XP/h · niveau dans 6 min")
  end,

  level_up_counts_the_whole_gain = function(t)
    local Q = load({ setup = function() Mock.comfort.xp, Mock.comfort.xpMax = 990, 1000 end })
    play(17, 0)
    Mock.comfort.xp, Mock.comfort.xpMax = 30, 1400   -- +10 jusqu'au niveau, puis +30
    Mock.fire("PLAYER_XP_UPDATE", "player")
    play(1, 0)
    t.near(Q.XPRate:Rate(), 40 * 3600 / 180, 0.01)
  end,

  idle_five_minutes_pauses = function(t)
    local Q = load()
    play(18, 20)
    t.near(Q.XPRate:Rate(), 7200, 0.01)
    play(35, 0, true)            -- immobile, sans XP : la pause efface les 5 minutes
    t.near(Q.XPRate:Rate(), 7200, 0.01)
    -- absent (AFK) : rien ne compte
    Mock.comfort.afk = true
    play(10)
    t.near(Q.XPRate:Rate(), 7200, 0.01)
  end,

  dead_pauses = function(t)
    local Q = load()
    play(18, 20)
    Mock.comfort.dead = true
    play(20, 0)
    t.near(Q.XPRate:Rate(), 7200, 0.01)
  end,

  combat_counts_as_playing = function(t)
    local Q = load()
    play(18, 20)
    Mock.player.combat = true
    play(32, 0, true)            -- combat immobile sans XP : le temps compte
    t.ok(Q.XPRate:Rate() < 7200, "combat time counted")
    t.eq(#Mock.errors, 0)
  end,

  option_off = function(t)
    local Q = load()
    play(18, 20)
    t.ok(Q.XPRate:Text())
    Q.Settings:Set("showXPRate", false)
    t.eq(Q.XPRate:Text(), nil)
    t.ok(not Q.UI.Tracker.xpLine:IsShown(), "line hidden")
    play(20, 20)
    t.eq(Q.XPRate:Text(), nil)
  end,

  chapter_remaining_xp_in_progress_bar = function(t)
    local Q = load({
      beforeLogin = function(Q)
        Q:RegisterGuide({ id = "T_XP", title = "XP", faction = "Alliance", minLevel = 1, maxLevel = 6, steps = {
          { "accept", 179 }, { "turnin", 179, xp = 1500 }, { "turnin", 170, xp = 2700 }, { "turnin", 233, xp = 50 },
        } })
        Q.char.guideId = "T_XP"
      end,
    })
    Q.char.skipped["g:T_XP:4"] = true
    Q.Progress.Invalidate()
    Q.Progress:Update()
    t.eq(Q.XPRate:ChapterRemainingXP(), 4200)
    t.eq(Q.XPRate:ChapterText(), string.format(Q.L.COMFORT_CHAPTER_XP, "4.2k"))
    t.ok(Q.UI.Tracker.barText:GetText():find("4.2k", 1, true), "shown in the progress bar")
    Q.Settings:Set("showXPRate", false)
    t.ok(not Q.UI.Tracker.barText:GetText():find("4.2k", 1, true), "option off")
  end,

  missing_api_is_silent = function(t)
    UnitXP, UnitXPMax = nil, nil
    local Q = load()
    UnitXP, UnitXPMax, UnitIsAFK, UnitIsDeadOrGhost, UnitAffectingCombat = nil, nil, nil, nil, nil
    play(30, 20)
    t.eq(Q.XPRate:Text(), nil)
    t.eq(#Mock.errors, 0)
  end,

  secret_values_are_ignored = function(t)
    local Q = load()
    UnitXP = function() return Mock.strictSecret(100) end
    UnitXPMax = function() return Mock.strictSecret(1000) end
    UnitIsAFK = function() return Mock.strictSecret(false) end
    Mock.fire("PLAYER_XP_UPDATE", Mock.strictSecret("player"))
    Mock.fire("PLAYER_XP_UPDATE", "player")
    play(30)
    t.eq(Q.XPRate:Rate(), nil)
    t.eq(Q.XPRate:Text(), nil)
    t.eq(#Mock.errors, 0)
  end,

  without_questiedb_does_nothing = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    play(30, 20)
    t.eq(Q.XPRate:Text(), nil)
    t.eq(Q.XPRate:ChapterText(), nil)
    t.ok(not Q.UI.Tracker.xpLine:IsShown())
    t.eq(#Mock.errors, 0)
  end,
}
