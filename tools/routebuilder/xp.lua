-- tools/routebuilder/xp.lua : modèle d'XP Classic utilisé par la simulation.
local xp = {}

-- XP pour passer du niveau N au niveau N + 1 (table Classic ; 1-35 exigées, 36-59 pour la suite).
xp.LEVEL_XP = {
  400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600,
  8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200,
  25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400,
  50800, 54500, 58600, 62800, 67100, 71600, 76100, 80800, 85700, 90700,
  95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500,
  153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800,
}
xp.MAX_LEVEL = 60

xp.DUNGEON_FACTOR = 0.5  -- Forever : XP des quêtes de donjon −50 %
xp.LEVEL1_DEFAULT = 80
-- Livres de Forever (« Collect 'Stonewrought Design' and bring it to Owen Thadd in Undercity » ; 79953,
-- 81947-81956, 84395-84402, rendus aux bibliothécaires de Stormwind et de Fossoyeuse : nouvelles quêtes sans
-- valeur QuestXP, niveau requis 1, un seul objet ramassé sur un objet du monde nommé « Book ») : valeur
-- prudente, un quart de l'estimation de leur niveau. C'est le palier Classic d'une simple livraison (QuestXP
-- connues : livraisons de niveau 45, premier quartile 970 pour une valeur standard de 3 900). Sans elle, les
-- sept livres d'Oran Snakewrithe comptaient ~46 000 XP estimées en H_29.
xp.BOOK_FACTOR = 0.25

-- Coefficient selon l'écart niveau du joueur − niveau de la quête au moment du rendu.
function xp.modifier(d)
  if d <= 5 then return 1.0
  elseif d == 6 then return 0.8
  elseif d == 7 then return 0.6
  elseif d == 8 then return 0.4
  elseif d == 9 then return 0.2 end
  return 0.1
end

local function floor5(v) return math.floor(v / 5) * 5 end

-- Vrai si la quête est une quête de donjon (zone de donjon connue, ou drapeau posé par le plan).
function xp.isDungeon(D, quest)
  if quest.dungeon then return true end
  local z = quest.zoneOrSort or 0
  return z > 0 and D.dungeonAreas and D.dungeonAreas[z] ~= nil or false
end

local function isDelivery(quest)
  return quest and quest.objectives and #(quest.objectives.list or {}) == 0
end

-- Médianes par niveau de quête, calculées une fois par jeu de données (cache dans D).
local function medians(D)
  if D._xpMedians then return D._xpMedians end
  local all, byKind = {}, { delivery = {}, normal = {} }
  for id, v in pairs(D.xp or {}) do
    local lvl, val = v[1], v[2]
    if lvl and val and val > 0 then
      all[lvl] = all[lvl] or {}
      table.insert(all[lvl], val)
      local q = D.quests and D.quests[id]
      if q then
        local kind = isDelivery(q) and "delivery" or "normal"
        byKind[kind][lvl] = byKind[kind][lvl] or {}
        table.insert(byKind[kind][lvl], val)
      end
    end
  end
  local function med(list)
    table.sort(list)
    local n = #list
    if n == 0 then return nil end
    if n % 2 == 1 then return list[(n + 1) / 2] end
    return (list[n / 2] + list[n / 2 + 1]) / 2
  end
  local out = { all = {}, delivery = {}, normal = {}, count = { delivery = {}, normal = {} } }
  for lvl, list in pairs(all) do out.all[lvl] = med(list) end
  for kind, t in pairs(byKind) do
    for lvl, list in pairs(t) do
      out.count[kind][lvl] = #list
      out[kind][lvl] = med(list)
    end
  end
  D._xpMedians = out
  return out
end

-- Estimation de l'XP de base d'une quête sans valeur connue.
-- flags = { dungeon = bool, kind = "delivery"|"normal"|nil }.
function xp.estimateBase(D, questLevel, flags)
  flags = flags or {}
  local m = medians(D)
  local v
  -- même type de quête (livraison / avec objectifs) si l'échantillon est suffisant
  if flags.kind and (m.count[flags.kind][questLevel] or 0) >= 5 then v = m[flags.kind][questLevel] end
  v = v or m.all[questLevel]
  if not v then
    if questLevel <= 1 then v = xp.LEVEL1_DEFAULT
    else
      -- niveau sans échantillon : interpolation sur les niveaux voisins
      local lo, hi
      for d = 1, 10 do
        lo = lo or m.all[questLevel - d]
        hi = hi or m.all[questLevel + d]
      end
      v = (lo and hi) and (lo + hi) / 2 or lo or hi or xp.LEVEL1_DEFAULT
    end
  end
  if flags.dungeon then v = v * xp.DUNGEON_FACTOR end
  return floor5(v)
end

-- Livre de Forever (voir BOOK_FACTOR) : niveau requis 1 au plus, un seul objectif (objet), départ par un
-- objet du monde nommé « Book » dans QuestieDB.
function xp.isBook(D, quest)
  if (quest.reqLevel or 0) > 1 then return false end
  local list = quest.objectives and quest.objectives.list or {}
  if #list ~= 1 or list[1].kind ~= "item" then return false end
  for _, id in ipairs(quest.starters and quest.starters.objects or {}) do
    local o = D.objects and D.objects[id]
    if o and o.name == "Book" then return true end
  end
  return false
end

-- XP de base (avant modificateur de niveau) d'une quête.
function xp.baseXP(D, quest)
  local known = D.xp and D.xp[quest.id]
  local dungeon = xp.isDungeon(D, quest)
  if known and known[2] then
    local v = known[2]
    if dungeon then v = v * xp.DUNGEON_FACTOR end
    return floor5(v), true
  end
  local v = xp.estimateBase(D, quest.level or 1, { dungeon = dungeon, kind = isDelivery(quest) and "delivery" or "normal" })
  if xp.isBook(D, quest) then v = floor5(v * xp.BOOK_FACTOR) end
  return v, false
end

-- XP reçue en rendant la quête au niveau playerLevel.
function xp.questXP(D, quest, playerLevel)
  local base = xp.baseXP(D, quest)
  local d = playerLevel - (quest.level or playerLevel)
  return floor5(base * xp.modifier(d))
end

-- « Différence zéro » de Classic selon le niveau du joueur.
function xp.zeroDiff(level)
  if level <= 7 then return 5
  elseif level <= 9 then return 6
  elseif level <= 11 then return 7
  elseif level <= 15 then return 8
  elseif level <= 19 then return 9
  elseif level <= 29 then return 10
  elseif level <= 39 then return 11
  elseif level <= 44 then return 12
  elseif level <= 49 then return 13
  elseif level <= 54 then return 14
  elseif level <= 59 then return 15 end
  return 16
end

-- Niveau gris de Classic : un mob de ce niveau ou en dessous ne rapporte rien.
function xp.grayLevel(level)
  if level <= 5 then return 0
  elseif level <= 39 then return level - 5 - math.floor(level / 10)
  elseif level <= 59 then return level - 1 - math.floor(level / 5) end
  return level - 9
end

-- XP d'un mob (non élite, sans repos).
function xp.mobXP(playerLevel, mobLevel)
  if mobLevel <= xp.grayLevel(playerLevel) then return 0 end
  local base = playerLevel * 5 + 45
  local diff = mobLevel - playerLevel
  local v
  if diff >= 0 then v = base * (1 + 0.05 * diff)
  else v = base * (1 - (-diff) / xp.zeroDiff(playerLevel)) end
  if v < 0 then v = 0 end
  return math.floor(v)
end

-- Ajoute de l'XP à l'état simulé, avec passages de niveau.
function xp.addXP(state, amount)
  state.xp = (state.xp or 0) + amount
  while state.level < xp.MAX_LEVEL and xp.LEVEL_XP[state.level] and state.xp >= xp.LEVEL_XP[state.level] do
    state.xp = state.xp - xp.LEVEL_XP[state.level]
    state.level = state.level + 1
  end
  if state.level >= xp.MAX_LEVEL then state.xp = 0 end
  return state
end

-- Niveau fractionnaire (ex. 5.42) pour les rapports.
function xp.fractional(state)
  local need = xp.LEVEL_XP[state.level]
  if not need then return state.level end
  return state.level + state.xp / need
end

return xp
