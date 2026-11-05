local addonName, Q = ...

-- Navigation : une seule interface (SetTarget / Clear), quatre fournisseurs (spec § 5.4).
-- Coordonnées reçues en 0-100 avec uiMapID ; chaque fournisseur reçoit son échelle :
-- ShortestPath et TomTom 0-1, WaypointUI 0-100, marqueur natif (UiMapPoint) 0-1.
local Nav = {}
Q.Nav = Nav

local OWNER = "Questify"     -- propriétaire déclaré auprès de ShortestPath
local RECOMPUTE_EVERY = 3           -- secondes : cible d'un « complete » (monstre le plus proche)

local target        -- dernière cible demandée : { mapId, x, y, title }
local applied       -- ce qui est posé chez le fournisseur : { provider, key }
local tomtomUid     -- retour de TomTom:AddWaypoint, à retirer avant le point suivant
local retryPending  -- ShortestPath a refusé (combat) : on retente à la fin du combat
local refusedKey    -- clé de la cible refusée : on ne la renvoie pas avant la fin du combat
local manual        -- cible choisie par le joueur (clic sur un repère de la carte) : prioritaire
local ticker
local caveTicker    -- suit l'avancée du joueur vers l'entrée d'une grotte (voir syncCaveTicker)
local CAVE_CHECK_EVERY = 1          -- secondes
local syncCaveTicker                -- défini plus bas, appelé par apply

---------------------------------------------------------------------------
-- Détection (globales, lues à chaque appel : un addon peut se charger après nous)
---------------------------------------------------------------------------
local function hasShortestPath()
  return type(ShortestPathForever) == "table" and type(ShortestPathForever.API) == "table"
    and type(ShortestPathForever.API.Navigate) == "function"
end

local function hasWaypointUI()
  return type(WaypointUIAPI) == "table" and type(WaypointUIAPI.Navigation) == "table"
    and type(WaypointUIAPI.Navigation.NewUserNavigation) == "function"
end

local function hasTomTom()
  return type(TomTom) == "table" and type(TomTom.AddWaypoint) == "function"
end

-- Detect() -> { shortestpath, waypointui, tomtom, native = true }
function Nav:Detect()
  return {
    shortestpath = hasShortestPath(),
    waypointui = hasWaypointUI(),
    tomtom = hasTomTom(),
    native = true,
  }
end

local function routingOn()
  return Q.Settings:Get("nav.routing") == true and hasShortestPath()
end

-- Fournisseur d'affichage effectif : celui du réglage, sinon le marqueur natif s'il manque.
local function displayProvider()
  local wanted = Q.Settings:Get("nav.display")
  if wanted == "waypointui" and hasWaypointUI() then return "waypointui" end
  if wanted == "tomtom" and hasTomTom() then return "tomtom" end
  return "native"
end

-- Active() -> nom du calcul d'itinéraire ("shortestpath") ou nil, fournisseur d'affichage.
-- Quand ShortestPath calcule, c'est lui qui transmet la destination à cet affichage.
function Nav:Active()
  return routingOn() and "shortestpath" or nil, displayProvider()
end

-- Fournisseur réellement utilisé pour poser une cible.
local function currentProvider()
  if routingOn() then return "shortestpath" end
  return displayProvider()
end

local LABELS = {
  shortestpath = "NAV_SHORTESTPATH",
  waypointui = "NAV_WAYPOINTUI",
  tomtom = "NAV_TOMTOM",
  native = "NAV_NATIVE",
}

-- Libellé localisé d'un fournisseur (assistant, options).
function Nav:ProviderLabel(id)
  local key = LABELS[id]
  return key and Q.L[key] or tostring(id)
end

---------------------------------------------------------------------------
-- Pose et retrait chez chaque fournisseur
---------------------------------------------------------------------------
local function tenth(v) return math.floor(v * 10 + 0.5) end

local function makeKey(provider, t)
  return table.concat({ provider, t.mapId, t.title or "", tenth(t.x), tenth(t.y) }, "|")
end

-- WaypointUI remplace l'affichage du repère du jeu : un repère posé sans lui y porte le nom
-- générique « Repère cartographique » (MAP_PIN). Quand il est chargé, le repère du jeu est donc
-- posé par son API (qui pose aussi celui du jeu et le suit), avec le titre de l'étape pour nom.
-- Sans bruitage : la cible d'un « complete » se déplace toutes les quelques secondes.
-- -> true si WaypointUI a posé le repère (nil : carte refusée).
local wuiPosed   -- une navigation WaypointUI a été posée par nous : à effacer au clear, quel que soit
                 -- le réglage d'affichage d'ici là (voir PROVIDERS.shortestpath.clear)

local function setViaWaypointUI(t)
  if not hasWaypointUI() then return false end
  local ok, res = pcall(WaypointUIAPI.Navigation.NewUserNavigation, {
    name = t.title ~= "" and t.title or nil, mapID = t.mapId, x = t.x, y = t.y, suppressAudio = true,
  })
  if not ok then Q:Debug("WaypointUI NewUserNavigation", res) end
  if ok and res ~= nil then wuiPosed = true end
  return ok and res ~= nil
end

local function clearWaypointUI()
  wuiPosed = false
  if hasWaypointUI() and type(WaypointUIAPI.Navigation.ClearUserNavigation) == "function" then
    pcall(WaypointUIAPI.Navigation.ClearUserNavigation)
  end
end

-- ShortestPath ne confie un virage à WaypointUI (avec le nom de la destination) que si celui-ci
-- suit déjà une navigation ; sinon il pose à chaque virage un repère du jeu sans nom, que WaypointUI
-- affiche « Repère cartographique ». Avec un affichage WaypointUI ou natif, on lui en donne donc une
-- avant de lancer le calcul (pas avec TomTom, choisi pour ne pas avoir ce repère).
local function waypointUIWithRouting()
  return hasWaypointUI() and displayProvider() ~= "tomtom"
end

local PROVIDERS = {}

-- ShortestPath : renvoie false en combat. On ne pose rien d'autre : il gère l'affichage.
-- `via` : points à rejoindre d'abord (entrée ou sortie de grotte, voir apply), une seule route.
PROVIDERS.shortestpath = {
  set = function(t, via)
    if waypointUIWithRouting() then setViaWaypointUI(via and via[1] or t) end
    local api = ShortestPathForever.API
    if via and #via > 0 and type(api.NavigateRoute) ~= "function" then
      -- pas de route à étapes : au moins l'entrée (jamais la cible, que le calcul poserait au-dessus)
      local v = via[1]
      return api.Navigate(OWNER, v.mapId, v.x / 100, v.y / 100, v.title, "quest") ~= false
    end
    if via and #via > 0 then
      local stops = {}
      for i, v in ipairs(via) do
        stops[i] = { map = v.mapId, x = v.x / 100, y = v.y / 100, title = v.title }
      end
      stops[#stops + 1] = { map = t.mapId, x = t.x / 100, y = t.y / 100, title = t.title, kind = "quest" }
      return api.NavigateRoute(OWNER, stops) ~= false
    end
    local ok = api.Navigate(OWNER, t.mapId, t.x / 100, t.y / 100, t.title, "quest")
    return ok ~= false
  end,
  clear = function()
    if hasShortestPath() and ShortestPathForever.API.Cancel then ShortestPathForever.API.Cancel(OWNER) end
    if wuiPosed or waypointUIWithRouting() then clearWaypointUI() end
  end,
}

PROVIDERS.waypointui = {
  set = function(t)
    WaypointUIAPI.Navigation.NewUserNavigation({ name = t.title, mapID = t.mapId, x = t.x, y = t.y,
      suppressAudio = true })
    return true
  end,
  clear = function()
    if hasWaypointUI() and WaypointUIAPI.Navigation.ClearUserNavigation then
      WaypointUIAPI.Navigation.ClearUserNavigation()
    end
  end,
}

PROVIDERS.tomtom = {
  set = function(t)
    if tomtomUid and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(tomtomUid) end
    tomtomUid = nil
    tomtomUid = TomTom:AddWaypoint(t.mapId, t.x / 100, t.y / 100,
      { title = t.title, crazy = true, persistent = false, minimap = true, world = true })
    return true
  end,
  clear = function()
    if tomtomUid and hasTomTom() and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(tomtomUid) end
    tomtomUid = nil
  end,
}

PROVIDERS.native = {
  set = function(t)
    if setViaWaypointUI(t) then return true end
    -- WaypointUI a refusé : son ancien repère nommé ne doit pas rester affiché
    clearWaypointUI()
    -- Q.API.SetNativeWaypoint : sur une carte refusée, l'ancien point trompeur est retiré ;
    -- API du repère absente : rien à poser, le suivi reste seul guide.
    Q.API.SetNativeWaypoint(t.mapId, t.x / 100, t.y / 100, t.title)
    return true
  end,
  clear = function()
    clearWaypointUI()
    Q.API.ClearNativeWaypoint()
  end,
}

-- Retire ce que nous avons posé (aucun appel si rien n'est posé).
local function clearApplied()
  local a = applied
  applied = nil
  if not a then return end
  local p = PROVIDERS[a.provider]
  if p then Q.SafeCall(p.clear) end
end

---------------------------------------------------------------------------
-- Grottes (Nav/Caves.lua) : une cible dans une grotte connue se rejoint par son entrée, et on
-- ressort par l'entrée d'une grotte avant d'aller ailleurs. Sans hauteur, un calcul d'itinéraire
-- peut poser la cible sur la montagne au-dessus de la grotte, et une flèche pointe à travers la
-- roche. Dans la grotte de la cible (ou à son entrée), la flèche directe remplace le calcul.
---------------------------------------------------------------------------
local caveWatch    -- vrai tant qu'une grotte entre en jeu : la minuterie suit l'avancée du joueur
local cavePos      -- { mapId, x, y } du joueur au dernier calcul du plan
local CAVE_MOVE_YARDS = 3           -- en dessous, le plan ne peut pas avoir changé

-- Le joueur a-t-il bougé depuis le dernier calcul du plan ? (position inconnue : oui)
local function playerMovedSinceCavePlan()
  local pm, px, py = Q.Maps:PlayerPos()
  if not pm then return cavePos ~= nil end   -- inconnue : on ne relance qu'au changement d'état
  if not cavePos then return true end
  if pm ~= cavePos.mapId then return true end
  local d = Q.Maps:Distance(pm, px, py, cavePos.mapId, cavePos.x, cavePos.y)
  return d == nil or d > CAVE_MOVE_YARDS
end

local function cavePlan(t)
  local C = Q.Caves
  if not (C and C.Plan) then return nil end
  local ok, plan = pcall(C.Plan, C, t.mapId, t.x, t.y)
  if not ok then
    Q:Debug("Caves:Plan", plan)
    return nil
  end
  return plan
end

local function caveTitle(stop, title)
  local base = stop.kind == "exit" and Q.L.NAV_CAVE_EXIT or Q.L.NAV_CAVE_ENTER
  if title and title ~= "" then return base .. " — " .. title end
  return base
end

-- retry = true : seconde tentative après un refus, on n'en refait pas d'autre.
local function apply(retry)
  local t = target
  if not t then return end
  local plan = cavePlan(t)
  local pm, px, py = Q.Maps:PlayerPos()
  cavePos = pm and { mapId = pm, x = px, y = py } or nil
  caveWatch = plan ~= nil
  syncCaveTicker()
  local provider = currentProvider()
  if plan and plan.direct and provider == "shortestpath" then provider = displayProvider() end
  local via
  if plan and #plan.stops > 0 then
    via = {}
    for i, s in ipairs(plan.stops) do
      via[i] = { mapId = s.mapId, x = s.x, y = s.y, title = caveTitle(s, t.title) }
    end
  end
  -- un affichage sans calcul d'itinéraire montre le premier point du détour, puis la cible
  local shown = t
  if via and provider ~= "shortestpath" then shown = via[1] end
  -- la vraie cible est toujours mémorisée (`target`, que la minuterie et le passage à l'entrée relisent) ;
  -- le point n'est reposé que si le point affiché ou son titre change (pour ShortestPath, le point
  -- affiché est la cible elle-même, dernier arrêt de la route).
  local key = makeKey(provider, shown) .. (plan and ("|" .. plan.key) or "")
  if applied and applied.provider == provider and applied.key == key then return end
  if not retry and refusedKey == key then return end
  -- le fournisseur a changé (réglage, addon déchargé, grotte) : on retire l'ancien point d'abord
  if applied and applied.provider ~= provider then clearApplied() end
  local ok, accepted
  if provider == "shortestpath" then
    ok, accepted = Q.SafeCall(PROVIDERS.shortestpath.set, t, via)
  else
    ok, accepted = Q.SafeCall(PROVIDERS[provider].set, shown)
  end
  if ok and accepted then
    applied = { provider = provider, key = key }
    retryPending, refusedKey = false, nil
  elseif ok and provider == "shortestpath" then
    -- refus (combat) : la cible reste mémorisée, on retente une fois à la fin du combat
    retryPending, refusedKey = not retry, key
  end
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
-- SetTarget(mapId, x, y, title) : x et y en 0-100.
function Nav:SetTarget(mapId, x, y, title)
  if type(mapId) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then
    self:Clear()
    return
  end
  target = { mapId = mapId, x = x, y = y, title = type(title) == "string" and title or "" }
  apply()
end

-- Cible choisie par le joueur (clic sur un repère de la carte) : elle reste posée jusqu'au
-- prochain changement d'étape ou au prochain choix ; la minuterie des étapes « complete » et le
-- mode zone ne la remplacent pas.
function Nav:SetManualTarget(mapId, x, y, title)
  if type(mapId) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return false end
  manual = true
  self:SetTarget(mapId, x, y, title)
  return true
end

function Nav:HasManualTarget()
  return manual == true
end

-- Status() -> copie de l'état pour /qf check et /qf bug :
-- { target = { mapId, x, y, title } ou nil, provider = fournisseur posé ou nil,
--   wanted = fournisseur qui serait utilisé, retryPending = bool,
--   manual = bool (cible choisie sur la carte), cave = bool (grotte en jeu, voir Nav/Caves.lua) }
function Nav:Status()
  local t = target and { mapId = target.mapId, x = target.x, y = target.y, title = target.title } or nil
  return {
    target = t,
    provider = applied and applied.provider or nil,
    wanted = currentProvider(),
    retryPending = retryPending == true,
    manual = manual == true,
    cave = caveWatch == true,
  }
end

function Nav:Clear()
  target = nil
  manual = nil
  retryPending, refusedKey = false, nil
  caveWatch = nil
  syncCaveTicker()
  clearApplied()
end

-- Recalcule la cible de l'étape donnée (par défaut l'étape courante) et la pose. Une cible
-- choisie par le joueur reste en place (voir SetManualTarget).
function Nav:Refresh(entry)
  if manual then return end
  if entry == nil then entry = Q.Progress:Current() end
  if not entry then
    self:Clear()
    return
  end
  local tg = Q.Targets:ForEntry(entry)
  if tg then
    self:SetTarget(tg.mapId, tg.x, tg.y, tg.title)
  else
    self:Clear()
  end
end

---------------------------------------------------------------------------
-- Minuterie : la cible d'un « complete » suit le monstre le plus proche (dans la zone d'objectif
-- quand l'étape en a une, voir Q.Targets) ; en mode zone (Engine/ZoneMode.lua), l'objectif
-- prioritaire le plus proche, quelle que soit l'action de l'étape qui porte la zone.
---------------------------------------------------------------------------
local function zoneOwner(cur)
  local Z = Q.ZoneMode
  if not (Z and Z.IsOwner) then return false end
  local ok, owner = pcall(Z.IsOwner, Z, cur)
  return ok and owner == true
end

local function needsTicker()
  local cur = Q.Progress:IsEnabled() and Q.Progress:Current()
  if not cur then return false end
  return cur.step.action == "complete" or zoneOwner(cur)
end

local function syncTicker()
  if needsTicker() then
    if not ticker then
      ticker = Q:NewTicker(RECOMPUTE_EVERY, function()
        if needsTicker() then Nav:Refresh() end
      end)
    end
  elseif ticker then
    ticker:Cancel()
    ticker = nil
  end
  syncCaveTicker()
end

-- Grotte en jeu : chaque seconde, on regarde si le joueur a atteint l'entrée (ou est ressorti)
-- pour passer au point suivant. Seul le plan est recalculé, pas la cible de l'étape.
function syncCaveTicker()
  local C = Q.Caves
  if target and (caveWatch or (C and C.HasData and C:HasData())) then
    if not caveTicker then
      caveTicker = Q:NewTicker(CAVE_CHECK_EVERY, function()
        local changed = false
        if target and Q.Caves and Q.Caves.Track then
          local ok, res = Q.SafeCall(Q.Caves.Track, Q.Caves)
          changed = ok and res == true
        end
        -- entré ou sorti d'une grotte (même cible dehors : arrêt « sortie » à montrer), ou déplacement
        if target and (changed or (caveWatch and playerMovedSinceCavePlan())) then apply() end
        if not target and caveTicker then
          caveTicker:Cancel()
          caveTicker = nil
        end
      end)
    end
  elseif caveTicker then
    caveTicker:Cancel()
    caveTicker = nil
  end
end

---------------------------------------------------------------------------
-- Messages et évènements
---------------------------------------------------------------------------
Q:On("STEP_CHANGED", function(entry)
  manual = nil   -- nouvelle étape : la cible de l'étape reprend la main
  Nav:Refresh(entry)
  syncTicker()
end)

Q:On("PROGRESS_UPDATED", function()
  syncTicker()
end)

-- Au cas où l'étape courante est déjà connue quand nous démarrons : la déduplication évite
-- tout appel en double.
Q:On("LOGIN", function()
  if Q.Progress:IsEnabled() then Nav:Refresh() end
  syncTicker()
end)

-- Mode zone : zone formée ou finie, entrée ou sortie, objectif en tête changé.
Q:On("ZONEMODE_CHANGED", function()
  if Q.Progress:IsEnabled() then Nav:Refresh() end
  syncTicker()
end)

-- Fin de combat : seule relance de ShortestPath refusé.
Q:On("COMBAT_ENDED", function()
  if retryPending and target then
    retryPending = false
    apply(true)
  end
end)

-- Réglages `nav.*` : on retire l'ancien fournisseur puis on repose la cible.
Q:On("SETTINGS_CHANGED", function(path)
  if type(path) ~= "string" or (path ~= "nav" and path:sub(1, 4) ~= "nav.") then return end
  clearApplied()
  retryPending, refusedKey = false, nil
  apply()
end)
