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

-- Quêtes rendues dans le chapitre (étapes turnin) et leur XP (champ xp des étapes, simulé).
local function questsAndXP(guide)
  local quests, xp = 0, 0
  for _, s in ipairs(guide.steps or {}) do
    if s.action == "turnin" then
      quests = quests + 1
      xp = xp + (num(s.xp) or 0)
    end
  end
  return quests, xp
end

-- Carte d'une suite : -> { id, guide, title, default, minLevel, maxLevel, quests, xp, minutes,
--   xpPerHour, travel, weight, under, over }
function RouteChoice:Card(option, level)
  local g, entry = option.guide, option.entry or {}
  local sim = g.sim or {}
  local quests, xp = questsAndXP(g)
  local minLevel, maxLevel = num(g.minLevel) or 1, num(g.maxLevel) or 60
  return {
    id = g.id, guide = g, entry = option.entry, default = option.default == true,
    title = entry.label or g.title or g.id,
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
