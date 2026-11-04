local addonName, Q = ...

-- Accès aux API du jeu (Forever, Mainline 12.x) regroupés dans Q.API : journal de quêtes, objets,
-- repère natif. Les fonctions vérifient la présence de l'API appelée (un client qui en manque ne
-- fait pas planter l'addon) mais n'ont qu'un seul chemin, celui de Forever.
-- Aucune globale du jeu n'est créée ni remplacée : polyfiller une globale peut casser d'autres addons.
-- Les fonctions du jeu sont lues à chaque appel (jamais mises en cache au chargement).
local API = {}
Q.API = API

---------------------------------------------------------------------------
-- Journal de quêtes
---------------------------------------------------------------------------
-- Index du journal d'une quête (C_QuestLog.GetLogIndexForQuestID), ou nil si elle n'y est pas.
function API.QuestLogIndex(id)
  if type(id) ~= "number" then return nil end
  if not (C_QuestLog and C_QuestLog.GetLogIndexForQuestID) then return nil end
  local idx = C_QuestLog.GetLogIndexForQuestID(id)
  if type(idx) ~= "number" or idx <= 0 then return nil end
  return idx
end

-- Vrai si la quête du journal peut être rendue (C_QuestLog.IsComplete).
function API.IsQuestComplete(id)
  if type(id) ~= "number" then return false end
  if not (C_QuestLog and C_QuestLog.IsComplete) then return false end
  return C_QuestLog.IsComplete(id) == true
end

-- Titre localisé d'une quête connue du client (C_QuestLog.GetTitleForQuestID), ou nil.
function API.QuestTitle(id)
  if type(id) ~= "number" then return nil end
  local fn = C_QuestLog and C_QuestLog.GetTitleForQuestID
  if not fn then return nil end
  local ok, title = pcall(fn, id)
  if ok and type(title) == "string" and title ~= "" then return title end
  return nil
end

---------------------------------------------------------------------------
-- Objets
---------------------------------------------------------------------------
-- Mêmes valeurs que C_Item.GetItemInfo.
function API.GetItemInfo(item)
  local fn = C_Item and C_Item.GetItemInfo
  if not fn then return nil end
  return fn(item)
end

-- Mêmes valeurs que C_Item.GetItemInfoInstant.
function API.GetItemInfoInstant(item)
  local fn = C_Item and C_Item.GetItemInfoInstant
  if not fn then return nil end
  return fn(item)
end

function API.HasItemStats()
  return (C_Item and C_Item.GetItemStats) ~= nil
end

-- Table des statistiques (clés ITEM_MOD_*), ou nil sans API.
function API.GetItemStats(link)
  local fn = C_Item and C_Item.GetItemStats
  if not fn then return nil end
  local stats = fn(link)
  if type(stats) == "table" then return stats end
  return {}
end

---------------------------------------------------------------------------
-- Marqueur natif (repère de carte)
---------------------------------------------------------------------------
-- C_Map.SetUserWaypoint + UiMapPoint + C_SuperTrack (marqueur 3D).
function API.HasNativeWaypoint()
  return C_Map ~= nil and C_Map.SetUserWaypoint ~= nil and type(UiMapPoint) == "table"
    and UiMapPoint.CreateFromCoordinates ~= nil
end

-- SetNativeWaypoint(mapId, x01, y01, title) -> true (posé), false (carte refusée, ancien repère
-- retiré) ou nil (API du repère absente). x et y en 0-1.
function API.SetNativeWaypoint(mapId, x, y, title)
  if not API.HasNativeWaypoint() then return nil end
  local can = true
  if C_Map.CanSetUserWaypointOnMap then can = C_Map.CanSetUserWaypointOnMap(mapId) end
  if not can then
    API.ClearNativeWaypoint()
    return false
  end
  C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapId, x, y))
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
  end
  return true
end

function API.ClearNativeWaypoint()
  if C_Map and C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
end
