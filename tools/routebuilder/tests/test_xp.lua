-- Tests du modèle d'XP (xp.lua).
local xp = require("xp")

-- Données synthétiques : trois quêtes connues de niveau 10 (médiane 900) et une de niveau 20.
local function fakeD()
  return {
    xp = { [1] = { 10, 800 }, [3] = { 10, 900 }, [4] = { 20, 2000 }, [10] = { 10, 1000 } },
    quests = {
      [10] = { id = 10, level = 10, zoneOrSort = 12, objectives = { list = { { kind = "kill" } } } },
      [11] = { id = 11, level = 10, zoneOrSort = 1581, objectives = { list = {} } },
      [12] = { id = 12, level = 1, zoneOrSort = 1, objectives = { list = {} } },
    },
    dungeonAreas = { [1581] = "The Deadmines" },
  }
end

return {
  level_table = function(t)
    t.eq(xp.LEVEL_XP[1], 400)
    t.eq(xp.LEVEL_XP[10], 7600)
    t.eq(xp.LEVEL_XP[35], 67100)
  end,

  mob_same_level = function(t) t.eq(xp.mobXP(10, 10), 95) end,
  mob_above = function(t) t.eq(xp.mobXP(10, 12), 104) end,
  mob_below_gray = function(t)
    t.eq(xp.mobXP(20, 10), 0)
    t.ok(xp.mobXP(20, 15) > 0 and xp.mobXP(20, 15) < xp.mobXP(20, 20), "reduced below")
  end,

  quest_modifier = function(t)
    local D = fakeD()
    local q = D.quests[10]
    t.eq(xp.questXP(D, q, 15), 1000)
    t.eq(xp.questXP(D, q, 16), 800)
    t.eq(xp.questXP(D, q, 17), 600)
    t.eq(xp.questXP(D, q, 25), 100)
  end,

  estimate_median = function(t)
    t.eq(xp.estimateBase(fakeD(), 10, {}), 900)
  end,

  estimate_dungeon_half = function(t)
    local D = fakeD()
    t.eq(xp.estimateBase(D, 10, { dungeon = true }), 450)
    -- quête inconnue dans une zone de donjon : estimation divisée par deux
    t.eq(xp.questXP(D, D.quests[11], 10), 450)
  end,

  estimate_level1_default = function(t)
    local D = fakeD()
    t.eq(xp.estimateBase(D, 1, {}), 80)
    t.eq(xp.questXP(D, D.quests[12], 1), 80)
  end,

  addxp_levels_up = function(t)
    local s = { level = 1, xp = 0 }
    xp.addXP(s, 1000)
    t.eq(s.level, 2); t.eq(s.xp, 600)
    s = { level = 1, xp = 0 }
    xp.addXP(s, 1400)
    t.eq(s.level, 3); t.eq(s.xp, 100)
  end,
}
