local addonName, Q = ...

-- Choix de suite : cartes et recommandation, sans interface (UI/RouteChoicePopup.lua les affiche).
-- Une carte par suite possible (Q.Guides:Choices) : bande de niveaux du chapitre, nombre de quêtes et XP
-- des remises (champ xp des étapes turnin), durée et XP/h simulées (champ sim, tools/routebuilder),
-- trajet déclaré (choices[].travel). Les chiffres viennent du guide ; rien n'est estimé en jeu.
--
-- Score d'une carte = poids × (XP/h relative − pénalités de niveau − pénalité de trajet) :
--   XP/h relative : xpPerHour / meilleur xpPerHour des cartes (0,5 quand le chapitre n'en a pas) ;
--   niveau : 0,5 par niveau sous le minLevel du chapitre, 0,35 par niveau au-dessus de son maxLevel ;
--   trajet : 0,25 par heure de trajet déclaré.
-- La meilleure carte est recommandée ; égalité : la suite par défaut, puis l'id le plus petit.
-- Raison : « xp » (meilleur XP/h d'au moins 5 %), sinon « level » (seule sans écart de niveau ou le
-- plus petit), sinon « travel » (trajet le plus court), sinon « default » (route de Questify).
-- Points forts d'une carte (RouteChoice:Highlights) : donjon de la tranche dont l'entrée est dans la
-- zone (Q.DungeonData), quête de classe qui y commence (Q.ClassQuests, QuestieDB), points de vol des
-- étapes ; rien d'estimé ni d'inventé.
local RouteChoice = {}
Q.RouteChoice = RouteChoice

RouteChoice.WEIGHTS = { xp = 1, under = 0.5, over = 0.35, travel = 0.25 }
local XP_MARGIN = 1.05      -- « meilleur XP/h » : au moins 5 % devant la suivante
local EPS = 1e-9

local function num(v)
  if Q.Util and Q.Util.IsSecret and Q.Util.IsSecret(v) then return nil end
  if type(v) == "number" and v == v then return v end
  return nil
end

-- Niveau du joueur avec la fraction d'XP du niveau en cours (15,4 = niveau 15 à 40 %).
function RouteChoice:PlayerLevel()
  local level = num(Q.Player and Q.Player.level) or 1
  local okXP, xp = pcall(UnitXP, "player")
  local okMax, max = pcall(UnitXPMax, "player")
  xp, max = okXP and num(xp), okMax and num(max)
  if xp and max and max > 0 and xp >= 0 and xp < max then level = level + xp / max end
  return level
end

-- Quêtes rendues dans le chapitre (étapes turnin) et leur XP (champ xp des étapes, simulé). Les étapes
-- réservées à d'autres classes (champ classes) ne comptent pas.
local function questsAndXP(guide)
  local quests, xp = 0, 0
  local classFile = Q.Player and Q.Player.classFile
  for _, s in ipairs(guide.steps or {}) do
    if s.action == "turnin" and Q.Guides.StepForClass(s, classFile) then
      quests = quests + 1
      xp = xp + (num(s.xp) or 0)
    end
  end
  return quests, xp
end

-- Carte d'une suite : -> { id, guide, title, label, mapId, default, minLevel, maxLevel, quests, xp,
--   minutes, xpPerHour, travel, weight, under, over }
-- title : nom du chapitre dans la langue du client (Q.Guides:DisplayTitle) ; label : texte libre de
-- l'entrée de choix (données du générateur, en anglais : pas affiché) ; mapId : carte de la zone
-- (Q.Guides:MainMap), pour l'image de fond.
function RouteChoice:Card(option, level)
  local g, entry = option.guide, option.entry or {}
  local sim = g.sim or {}
  local quests, xp = questsAndXP(g)
  local minLevel, maxLevel = num(g.minLevel) or 1, num(g.maxLevel) or 60
  return {
    id = g.id, guide = g, entry = option.entry, default = option.default == true,
    title = Q.Guides:DisplayTitle(g), label = entry.label, mapId = Q.Guides:MainMap(g),
    minLevel = minLevel, maxLevel = maxLevel,
    quests = quests, xp = xp,
    minutes = num(sim.minutes), xpPerHour = num(sim.xpPerHour),
    travel = entry.travel,
    weight = num(entry.weight) or 1,
    under = math.max(0, minLevel - level),
    over = math.max(0, level - maxLevel),
  }
end

local function travelMinutes(c) return c.travel and num(c.travel.minutes) or 0 end

-- Avertissement de niveau : "low" (plus d'un demi-niveau sous le chapitre), "high" (au moins un niveau
-- au-dessus : quêtes faciles, peu d'XP), nil sinon.
local function warningOf(c)
  if c.under > 0.5 then return "low" end
  if c.over >= 1 then return "high" end
  return nil
end

-- Raison de la recommandation, comparée aux autres cartes.
local function reasonOf(best, cards)
  local others = {}
  for _, c in ipairs(cards) do if c ~= best then others[#others + 1] = c end end
  if #others == 0 then return "default" end
  if best.xpPerHour then
    local beaten = true
    for _, c in ipairs(others) do
      if c.xpPerHour and best.xpPerHour < c.xpPerHour * XP_MARGIN then beaten = false end
    end
    if beaten then return "xp" end
  end
  local gap = best.under + best.over
  local level = true
  for _, c in ipairs(others) do
    if c.under + c.over <= gap + EPS then level = false end
  end
  if level then return "level" end
  local t = travelMinutes(best)
  local travel = best.travel ~= nil
  for _, c in ipairs(others) do
    if not c.travel or travelMinutes(c) <= t then travel = false end
  end
  if travel then return "travel" end
  return "default"
end

-- Cartes des suites, dans l'ordre déclaré, avec score, une seule recommandée (recommended = true), sa
-- raison (reason) et l'avertissement de niveau de chaque carte (warning).
-- options : liste de Q.Guides:Choices ; level : niveau du joueur (RouteChoice:PlayerLevel par défaut).
function RouteChoice:Rank(options, level)
  level = num(level) or self:PlayerLevel()
  local cards = {}
  for _, o in ipairs(options or {}) do
    if type(o) == "table" and type(o.guide) == "table" then cards[#cards + 1] = self:Card(o, level) end
  end
  if #cards == 0 then return cards end
  local bestXph
  for _, c in ipairs(cards) do
    if c.xpPerHour and (not bestXph or c.xpPerHour > bestXph) then bestXph = c.xpPerHour end
  end
  local W = self.WEIGHTS
  local best
  for _, c in ipairs(cards) do
    local rel = (c.xpPerHour and bestXph and bestXph > 0) and (c.xpPerHour / bestXph) or 0.5
    c.score = c.weight * (W.xp * rel - W.under * c.under - W.over * c.over - W.travel * travelMinutes(c) / 60)
    c.warning = warningOf(c)
    if not best or c.score > best.score + EPS then
      best = c
    elseif math.abs(c.score - best.score) <= EPS then
      if (c.default and not best.default) or (c.default == best.default and c.id < best.id) then best = c end
    end
  end
  best.recommended = true
  best.reason = reasonOf(best, cards)
  return cards
end

---------------------------------------------------------------------------
-- Points forts d'une suite (0 à 3), tirés des données existantes seulement
---------------------------------------------------------------------------
-- Cartes de la zone du chapitre : zones du titre (Q.Guides:TitleParts), cartes qui portent au moins
-- un quart des étapes situées, sinon la carte la plus présente.
local MAP_SHARE = 0.25

function RouteChoice:ZoneMaps(g)
  local set = {}
  if type(g) ~= "table" then return set end
  for _, p in ipairs(Q.Guides:TitleParts(g)) do
    if p.mapId then set[p.mapId] = true end
  end
  local list = Q.Guides:StepMaps(g)
  local total = 0
  for _, e in ipairs(list) do total = total + e.count end
  for i, e in ipairs(list) do
    if i == 1 and next(set) == nil then set[e.mapId] = true end
    if total > 0 and e.count / total >= MAP_SHARE then set[e.mapId] = true end
  end
  return set
end

-- Tranche du chapitre : de minLevel au plus haut de maxLevel et du niveau de fin simulé.
local function band(g)
  local lo = num(g.minLevel) or 1
  local hi = num(g.maxLevel) or lo
  local endLevel = g.sim and num(g.sim.endLevel)
  if endLevel and math.floor(endLevel) > hi then hi = math.floor(endLevel) end
  return lo, hi
end

local function listed(list, v)
  if type(list) ~= "table" then return false end
  for _, x in ipairs(list) do if x == v then return true end end
  return false
end

-- Donjon (Q.DungeonData) ouvert à la faction du joueur, entrée dans la zone, niveaux qui croisent la
-- tranche du chapitre ; le plus bas d'abord.
local function dungeonOf(g, maps, lo, hi)
  local data = Q.DungeonData
  local faction = Q.Player and Q.Player.faction
  if type(data) ~= "table" or type(faction) ~= "string" then return nil end
  local best
  for _, d in ipairs(data) do
    local e = type(d) == "table" and d.entrance
    if type(e) == "table" and num(e[1]) and num(d.minLevel) and num(d.maxLevel)
      and listed(d.factions, faction) and maps[e[1]] and d.minLevel <= hi and d.maxLevel >= lo then
      if not best or d.minLevel < best.minLevel then best = d end
    end
  end
  if not best then return nil end
  local name = Q.Dungeons and Q.Dungeons.Name and Q.Dungeons:Name(best) or tostring(best.name or best.key)
  return { kind = "dungeon", key = best.key, name = name, minLevel = best.minLevel, maxLevel = best.maxLevel }
end

-- Nom de la chaîne dans la langue du client (première quête, QuestieDB), sinon le titre des données.
local function chainTitle(chain)
  local id = type(chain.quests) == "table" and chain.quests[1] or nil
  local name = id and Q.QDB and Q.QDB:QuestName(id)
  if type(name) == "string" and name ~= "" and name:sub(1, 1) ~= "#" then return name end
  return tostring(chain.title or chain.key or "?")
end

-- Un départ (PNJ ou objet du monde, QuestieDB) de la quête placé sur une carte de la zone.
local function startsIn(questId, maps)
  local q = Q.QDB:Quest(questId)
  if not q then return false end
  local function any(ids, getter)
    for _, id in ipairs(ids or {}) do
      local rec = getter(Q.QDB, id)
      if rec and type(rec.spawns) == "table" then
        for m in pairs(rec.spawns) do
          if maps[m] then return true end
        end
      end
    end
    return false
  end
  return any(q.starters.npcs, Q.QDB.Npc) or any(q.starters.objects, Q.QDB.Object)
end

-- Quête de classe (Q.ClassQuests:List) pas faite, pas commencée, pas ignorée (disponible, à venir ou
-- déjà tissée dans la route), de la tranche du chapitre, dont la quête à prendre commence dans la zone.
local USEFUL_STATE = { available = true, upcoming = true, inroute = true }

local function classQuestOf(g, maps, lo, hi)
  local CQ = Q.ClassQuests
  if not (CQ and Q.QDB and Q.QDB:IsAvailable()) then return nil end
  for _, row in ipairs(CQ:List()) do
    local chain = row.chain
    local lvl = num(chain.level) or 1
    if USEFUL_STATE[row.state] and lvl >= lo and lvl <= hi then
      local first = CQ:FirstQuest(chain)
      if first and startsIn(first, maps) then
        return { kind = "class", key = chain.key, title = chainTitle(chain) }
      end
    end
  end
  return nil
end

-- Points de vol des étapes (fp) qui concernent le personnage.
local function fpOf(g)
  local P = Q.Player or {}
  local n = 0
  for _, s in ipairs(g.steps or {}) do
    if s.action == "fp" and (not s.race or listed(s.race, P.raceKey))
      and (not s.class or listed(s.class, P.classFile)) and Q.Guides.StepForClass(s, P.classFile) then
      n = n + 1
    end
  end
  if n == 0 then return nil end
  return { kind = "fp", count = n }
end

-- Highlights(guide) -> { { kind = "dungeon", key, name, minLevel, maxLevel } | { kind = "class", key,
-- title } | { kind = "fp", count } } : au plus un de chaque, dans cet ordre ; liste vide sans donnée.
function RouteChoice:Highlights(g)
  local out = {}
  if type(g) ~= "table" then return out end
  local maps = self:ZoneMaps(g)
  local lo, hi = band(g)
  local d = dungeonOf(g, maps, lo, hi)
  if d then out[#out + 1] = d end
  local c = classQuestOf(g, maps, lo, hi)
  if c then out[#out + 1] = c end
  local f = fpOf(g)
  if f then out[#out + 1] = f end
  return out
end
