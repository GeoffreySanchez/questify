local addonName, Q = ...

-- Navigation : une seule interface (SetTarget / Clear), quatre fournisseurs (spec § 5.4).
-- Coordonnées reçues en 0-100 avec uiMapID ; chaque fournisseur reçoit son échelle :
-- ShortestPath et TomTom 0-1, WaypointUI 0-100, marqueur natif (UiMapPoint) 0-1.
local Nav = {}
Q.Nav = Nav

local OWNER = "QuestifyVanilla"     -- propriétaire déclaré auprès de ShortestPath
local RECOMPUTE_EVERY = 3           -- secondes : cible d'un « complete » (monstre le plus proche)

local target        -- dernière cible demandée : { mapId, x, y, title }
local applied       -- ce qui est posé chez le fournisseur : { provider, key }
local tomtomUid     -- retour de TomTom:AddWaypoint, à retirer avant le point suivant
local retryPending  -- ShortestPath a refusé (combat) : on retente à la fin du combat
local refusedKey    -- clé de la cible refusée : on ne la renvoie pas avant la fin du combat
local ticker

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

local PROVIDERS = {}

-- ShortestPath : renvoie false en combat. On ne pose rien d'autre : il gère l'affichage.
PROVIDERS.shortestpath = {
  set = function(t)
    local ok = ShortestPathForever.API.Navigate(OWNER, t.mapId, t.x / 100, t.y / 100, t.title, "quest")
    return ok ~= false
  end,
  clear = function()
    if hasShortestPath() and ShortestPathForever.API.Cancel then ShortestPathForever.API.Cancel(OWNER) end
  end,
}

PROVIDERS.waypointui = {
  set = function(t)
    WaypointUIAPI.Navigation.NewUserNavigation({ name = t.title, mapID = t.mapId, x = t.x, y = t.y })
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
    -- Q.API.SetNativeWaypoint : sur une carte refusée, l'ancien point trompeur est retiré ;
    -- API du repère absente : rien à poser, le suivi reste seul guide.
    Q.API.SetNativeWaypoint(t.mapId, t.x / 100, t.y / 100, t.title)
    return true
  end,
  clear = function()
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

-- retry = true : seconde tentative après un refus, on n'en refait pas d'autre.
local function apply(retry)
  local t = target
  if not t then return end
  local provider = currentProvider()
  local key = makeKey(provider, t)
  if applied and applied.provider == provider and applied.key == key then return end
  if not retry and refusedKey == key then return end
  -- le fournisseur a changé (réglage, addon déchargé) : on retire l'ancien point d'abord
  if applied and applied.provider ~= provider then clearApplied() end
  local ok, accepted = Q.SafeCall(PROVIDERS[provider].set, t)
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

-- Status() -> copie de l'état pour /qf check et /qf bug :
-- { target = { mapId, x, y, title } ou nil, provider = fournisseur posé ou nil,
--   wanted = fournisseur qui serait utilisé, retryPending = bool }
function Nav:Status()
  local t = target and { mapId = target.mapId, x = target.x, y = target.y, title = target.title } or nil
  return {
    target = t,
    provider = applied and applied.provider or nil,
    wanted = currentProvider(),
    retryPending = retryPending == true,
  }
end

function Nav:Clear()
  target = nil
  retryPending, refusedKey = false, nil
  clearApplied()
end

-- Recalcule la cible de l'étape donnée (par défaut l'étape courante) et la pose.
function Nav:Refresh(entry)
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
-- quand l'étape en a une, voir Q.Targets)
---------------------------------------------------------------------------
local function needsTicker()
  local cur = Q.Progress:IsEnabled() and Q.Progress:Current()
  return cur and cur.step.action == "complete"
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
end

---------------------------------------------------------------------------
-- Messages et évènements
---------------------------------------------------------------------------
Q:On("STEP_CHANGED", function(entry)
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
