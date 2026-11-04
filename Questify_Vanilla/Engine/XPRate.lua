local addonName, Q = ...

-- XP par heure et temps avant le prochain niveau (en-tête du suivi), option showXPRate.
-- Fenêtre glissante de 15 minutes de jeu actif, découpée en tranches de 10 secondes. Une tranche
-- n'est comptée que si le joueur joue : il bouge, gagne de l'XP ou se bat. Absent (AFK), mort,
-- ou ni XP ni mouvement depuis 5 minutes : le temps ne compte plus, et les 5 minutes d'inactivité
-- sont retirées de la fenêtre. Rien n'est affiché avant 3 minutes de données.
-- Ce fichier porte aussi Q.Comfort, les petits outils communs aux modules de confort
-- (Hearth, Danger, Supplies, Taxi), chargés après lui.
local Comfort = Q.Comfort or {}
Q.Comfort = Comfort

local XPRate = {}
Q.XPRate = XPRate

local L = Q.L

local TICK = 10             -- secondes par tranche
local WINDOW = 15 * 60      -- fenêtre glissante, en secondes de jeu actif
local MIN_DATA = 3 * 60     -- données minimales avant affichage
local IDLE_AFTER = 5 * 60   -- ni XP ni mouvement pendant ce temps : pause
local MOVE_EPS = 0.02       -- écart de position (0-100) compté comme un mouvement

---------------------------------------------------------------------------
-- Outils communs aux modules de confort
---------------------------------------------------------------------------
local function isSecret(v) return Q.Util.IsSecret(v) end

-- Appel protégé d'une fonction du jeu : nil si elle est absente, échoue, ou renvoie une valeur
-- secrète en premier résultat (les autres résultats sont testés par l'appelant).
local function pack(...) return { n = select("#", ...), ... } end

function Comfort.Call(fn, ...)
  if type(fn) ~= "function" then return nil end
  local res = pack(pcall(fn, ...))
  if not res[1] or isSecret(res[2]) then return nil end
  return unpack(res, 2, res.n)
end

-- Nombre « simple » : nil s'il est secret ou n'est pas un nombre.
function Comfort.Number(v)
  if isSecret(v) or type(v) ~= "number" or v ~= v then return nil end
  return v
end

function Comfort.InCombat()
  if type(InCombatLockdown) ~= "function" then return false end
  local ok, res = pcall(InCombatLockdown)
  return ok and not isSecret(res) and (res == true or res == 1)
end

-- Vrai dans une instance (donjon, champ de bataille) ; inconnu = faux.
function Comfort.InInstance()
  if type(IsInInstance) ~= "function" then return false end
  local ok, inside = pcall(IsInInstance)
  return ok and not isSecret(inside) and (inside == true or inside == 1)
end

-- Option active et QuestieDB disponible : sans QuestieDB (dépendance facultative), les modules de
-- confort ne font rien, en silence.
function Comfort.Enabled(path)
  if not (Q.Settings and Q.Settings:Get(path) ~= false) then return false end
  local qdb = Q.QDB
  if not (qdb and qdb.IsAvailable) then return false end
  local ok, available = pcall(qdb.IsAvailable, qdb)
  return ok and available == true
end

-- Prévient le suivi qu'un texte de confort a changé ("xp", "hearth", "danger", "supplies").
function Comfort.Notify(kind)
  Q:Fire("COMFORT_CHANGED", kind)
end

local function fmt(template, ...)
  local ok, s = pcall(string.format, template, ...)
  if ok then return s end
  return tostring(template)
end
Comfort.Format = fmt

-- 12400 -> "12.4k" (ou "12,4k" en français), 950 -> "950".
function Comfort.ShortNumber(n)
  n = tonumber(n) or 0
  if n < 1000 then return tostring(math.floor(n + 0.5)) end
  local s = string.format("%.1f", n / 1000):gsub("%.0$", "")
  s = s:gsub("%.", L.COMFORT_DECIMAL)
  return fmt(L.COMFORT_THOUSANDS, s)
end

-- Durée lisible : "< 1 min", "38 min", "1 h 05".
function Comfort.FormatDuration(seconds)
  seconds = tonumber(seconds) or 0
  if seconds < 60 then return L.COMFORT_LESS_MINUTE end
  local minutes = math.ceil(seconds / 60)
  if minutes < 60 then return fmt(L.COMFORT_MINUTES, minutes) end
  return fmt(L.COMFORT_HOURS, math.floor(minutes / 60), minutes % 60)
end

---------------------------------------------------------------------------
-- Mesure
---------------------------------------------------------------------------
local buckets = {}     -- tranches actives, la plus récente en dernier : { xp, still }
local pendingXP = 0    -- XP gagnée depuis la dernière tranche
local lastXP, lastMax
local lastPos          -- { map, x, y }
local lastActivity     -- GetTime() du dernier gain d'XP, mouvement ou combat
local lastText
local ticker

local function now() return (GetTime and GetTime()) or 0 end
local function enabled() return Comfort.Enabled("showXPRate") end

-- -> xp, max du joueur, ou nil (API absente ou valeurs secrètes).
local function readXP()
  local xp = Comfort.Number(Comfort.Call(UnitXP, "player"))
  local max = Comfort.Number(Comfort.Call(UnitXPMax, "player"))
  if not (xp and max) then return nil end
  return xp, max
end

local function flagSet(fn)
  local v = Comfort.Call(fn, "player")
  return v == true or v == 1
end

function XPRate:Reset()
  buckets, pendingXP = {}, 0
  lastXP, lastMax, lastPos = nil, nil, nil
  lastActivity = now()
end

-- Gain d'XP depuis la dernière lecture. Montée de niveau : l'XP baisse ou le maximum change (un
-- niveau a toujours un autre maximum). UnitLevel n'est pas utilisé : pendant PLAYER_LEVEL_UP il
-- peut encore renvoyer l'ancien niveau alors que l'XP est déjà la nouvelle.
function XPRate:OnXP()
  local xp, max = readXP()
  if not xp then return end
  if lastXP then
    local gain
    if xp < lastXP or (lastMax and max ~= lastMax) then
      gain = math.max(0, (lastMax or 0) - lastXP) + xp
    else
      gain = xp - lastXP
    end
    if gain > 0 then
      pendingXP = pendingXP + gain
      lastActivity = now()
    end
  end
  lastXP, lastMax = xp, max
end

local function moved()
  local m, x, y = Q.Maps:PlayerPos()
  if not m then return false end
  local p = lastPos
  lastPos = { m, x, y }
  if not p then return false end
  return p[1] ~= m or math.abs(p[2] - x) > MOVE_EPS or math.abs(p[3] - y) > MOVE_EPS
end

-- Une tranche de TICK secondes.
function XPRate:Tick()
  if not enabled() then return end
  if not lastXP then self:OnXP() end
  -- XP illisible (API absente, valeurs secrètes) : rien à mesurer
  if not lastXP or not readXP() then return end
  local gained = pendingXP
  pendingXP = 0
  local t = now()
  local move = moved()
  local fighting = flagSet(UnitAffectingCombat)
  if gained > 0 or move or fighting then lastActivity = t end
  lastActivity = lastActivity or t
  local away = flagSet(UnitIsAFK) or flagSet(UnitIsDeadOrGhost)
  local idle = t - lastActivity >= IDLE_AFTER
  if gained == 0 and (away or idle) then
    -- pause : les tranches immobiles et sans XP de la fin ne comptent pas
    while #buckets > 0 and buckets[#buckets].still do table.remove(buckets) end
  else
    buckets[#buckets + 1] = { xp = gained, still = gained == 0 and not move and not fighting }
    local maxBuckets = WINDOW / TICK
    while #buckets > maxBuckets do table.remove(buckets, 1) end
  end
  self:Changed()
end

-- XP par heure sur la fenêtre, nil tant qu'il y a moins de 3 minutes de données.
function XPRate:Rate()
  local seconds = #buckets * TICK
  if seconds < MIN_DATA then return nil end
  local total = 0
  for _, b in ipairs(buckets) do total = total + b.xp end
  return total * 3600 / seconds
end

-- "12.4k XP/h · level in 38 min", ou nil (option coupée, pas assez de données).
function XPRate:Text()
  if not enabled() then return nil end
  local rate = self:Rate()
  if not rate then return nil end
  local xp, max = readXP()
  if not xp then return nil end
  local rateText = Comfort.ShortNumber(rate)
  if rate > 0 and max > xp then
    return fmt(L.COMFORT_XP_RATE_LEVEL, rateText, Comfort.FormatDuration((max - xp) / rate * 3600))
  end
  return fmt(L.COMFORT_XP_RATE, rateText)
end

-- Somme des XP estimées (step.xp) des rendus de quête encore à faire dans le chapitre.
-- Un rendu dont la quête n'est pas encore dans le journal est « passé » (notinlog) jusqu'à son
-- acceptation : il compte, sauf si l'étape « accept » de la même quête est elle-même passée.
function XPRate:ChapterRemainingXP()
  local P = Q.Progress
  if not (P and P:IsEnabled()) then return 0 end
  local entries = P:Entries()
  local acceptSkipped = {}
  for _, e in ipairs(entries) do
    if e.source == "guide" and e.step.action == "accept" and P:State(e) == "skipped" then
      acceptSkipped[e.step.questId] = true
    end
  end
  local total = 0
  for _, e in ipairs(entries) do
    local step = e.step
    if e.source == "guide" and step.action == "turnin" and type(step.xp) == "number" then
      local s, reason = P:State(e)
      if s ~= "done" and (s ~= "skipped" or (reason == "notinlog" and not acceptSkipped[step.questId])) then
        total = total + step.xp
      end
    end
  end
  return total
end

-- "~4.2k XP left" pour la barre de progression, ou nil.
function XPRate:ChapterText()
  if not enabled() then return nil end
  local total = self:ChapterRemainingXP()
  if total <= 0 then return nil end
  return fmt(L.COMFORT_CHAPTER_XP, Comfort.ShortNumber(total))
end

function XPRate:Changed()
  local text = self:Text()
  if text ~= lastText then
    lastText = text
    Comfort.Notify("xp")
  end
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
lastActivity = now()

Q:On("LOGIN", function()
  XPRate:Reset()
  XPRate:OnXP()
  if not ticker then ticker = Q:NewTicker(TICK, function() XPRate:Tick() end) end
end)

Q:RegisterEvent("PLAYER_XP_UPDATE", function(_, unit)
  if isSecret(unit) then return end
  if unit ~= nil and unit ~= "player" then return end
  XPRate:OnXP()
end)


Q:On("SETTINGS_CHANGED", function(path)
  if path == "showXPRate" then
    if not enabled() then XPRate:Reset() end
    XPRate:Changed()
  end
end)
