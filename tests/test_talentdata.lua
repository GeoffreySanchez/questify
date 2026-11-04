-- Vérification des presets livrés (Data/TalentBuilds.lua) : 51 points du niveau 10 au 60, jamais
-- plus que le rang max, paliers respectés (5 points par palier dans l'arbre avant le suivant).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"

return {
  presets_are_consistent = function(t)
    local Q = Mock.loadAddon(TOC, { skipGuides = true })
    for class, list in pairs(Q.TalentBuildData) do
      for _, p in ipairs(list) do
        local label = class .. " " .. tostring(p.key)
        t.ok(p.kind == "leveling" or p.kind == "dungeon", label .. " kind")
        t.ok(type(p.title) == "table" and p.title.enUS and p.title.frFR, label .. " titles")
        t.eq(#p.order, 51, label .. " points")
        local ranks, perTab = {}, {}
        for i, pos in ipairs(p.order) do
          local tab, tier, col, maxRank = pos[1], pos[2], pos[3], pos[4]
          local k = tab .. ":" .. tier .. ":" .. col
          ranks[k] = (ranks[k] or 0) + 1
          t.ok(ranks[k] <= maxRank, label .. " point " .. i .. " over max rank (" .. tostring(pos[5]) .. ")")
          t.ok((perTab[tab] or 0) >= (tier - 1) * 5, label .. " point " .. i .. " tier " .. tier .. " not open (" .. tostring(pos[5]) .. ")")
          perTab[tab] = (perTab[tab] or 0) + 1
        end
        -- un même talent garde la même position partout
        local where = {}
        for _, pos in ipairs(p.order) do
          local k = pos[1] .. ":" .. pos[2] .. ":" .. pos[3]
          if where[k] then t.eq(where[k], pos[5], label .. " two talents at " .. k) end
          where[k] = pos[5]
        end
      end
    end
  end,

  presets_of_the_character_class = function(t)
    local Q = Mock.loadAddon(TOC, { skipGuides = true })
    t.eq(#Q.Talents:Presets(), #(Q.TalentBuildData[Q.Player.classFile] or {}))
    Q.TalentBuildData[Q.Player.classFile] = { { key = "T1", kind = "leveling", order = {} } }
    t.eq(#Q.Talents:Presets(), 1, "presets of the character class")
    Q.TalentBuildData[Q.Player.classFile] = nil
    t.eq(#Q.Talents:Presets(), 0, "no preset for this class")
  end,
}
