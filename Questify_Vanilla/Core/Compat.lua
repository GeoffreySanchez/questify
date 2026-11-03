local addonName, Q = ...

-- Couche de compatibilité entre clients : Forever (Mainline 12.x) et Classic Era (1.15.x).
-- Chaque fonction de Q.API choisit l'API moderne quand elle existe, sinon l'équivalent Era.
-- Aucune globale du jeu n'est créée ni remplacée : polyfiller une globale peut casser d'autres addons.
-- Les fonctions du jeu sont lues à chaque appel (jamais mises en cache au chargement).
local API = {}
Q.API = API

---------------------------------------------------------------------------
-- Client
---------------------------------------------------------------------------
local function interfaceVersion()
  local v = GetBuildInfo and select(4, GetBuildInfo())
  return tonumber(v) or 0
end

-- Classic Era (interface 11500-11599 : 1.15.x).
function Q.IsClassicEra()
  local v = interfaceVersion()
  return v >= 11500 and v <= 11599
end

---------------------------------------------------------------------------
-- Journal de quêtes
---------------------------------------------------------------------------
-- Index du journal d'une quête, ou nil si elle n'y est pas.
-- Forever : C_QuestLog.GetLogIndexForQuestID ; Era : GetQuestLogIndexByID (0 = absente).
function API.QuestLogIndex(id)
  if type(id) ~= "number" then return nil end
  local idx
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
    idx = C_QuestLog.GetLogIndexForQuestID(id)
  elseif GetQuestLogIndexByID then
    idx = GetQuestLogIndexByID(id)
  end
  if type(idx) ~= "number" or idx <= 0 then return nil end
  return idx
end

-- Ligne du journal : { questID, title, isHeader, isComplete (1, -1 ou nil) } ou nil.
-- Era : GetQuestLogTitle(i) renvoie title, level, tag, isHeader, isCollapsed, isComplete,
-- frequency, questID (8e valeur).
local function logEntry(i)
  if C_QuestLog and C_QuestLog.GetInfo then
    local info = C_QuestLog.GetInfo(i)
    if not info then return nil end
    local complete
    if not info.isHeader and info.questID and C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID) then
      complete = 1
    end
    return { questID = info.questID, title = info.title, isHeader = info.isHeader == true, isComplete = complete }
  elseif GetQuestLogTitle then
    local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
    if title == nil and questID == nil then return nil end
    return { questID = questID, title = title, isHeader = isHeader and true or false, isComplete = isComplete }
  end
  return nil
end

-- Toutes les lignes du journal (en-têtes compris), dans l'ordre du client.
function API.QuestLogEntries()
  local out = {}
  local n = 0
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
    n = C_QuestLog.GetNumQuestLogEntries() or 0
  elseif GetNumQuestLogEntries then
    n = GetNumQuestLogEntries() or 0
  end
  for i = 1, n do
    local e = logEntry(i)
    if e then out[#out + 1] = e end
  end
  return out
end

-- Vrai si la quête est dans le journal.
function API.IsOnQuest(id)
  if type(id) ~= "number" then return false end
  return API.QuestLogIndex(id) ~= nil
end

-- Vrai si la quête du journal peut être rendue.
-- Era : 6e valeur de GetQuestLogTitle (1 = terminée, -1 = échouée). Une quête sans objectif
-- (« va parler à ») renvoie nil alors qu'elle peut être rendue : on la compte terminée.
function API.IsQuestComplete(id)
  if type(id) ~= "number" then return false end
  if C_QuestLog and C_QuestLog.IsComplete then return C_QuestLog.IsComplete(id) == true end
  local idx = API.QuestLogIndex(id)
  if not idx then return false end
  local e = logEntry(idx)
  if not e or e.isHeader then return false end
  if e.isComplete == 1 then return true end
  if e.isComplete == -1 then return false end
  local objs = C_QuestLog and C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(id)
  return type(objs) == "table" and #objs == 0
end

-- Titre localisé d'une quête connue du client, ou nil.
-- Forever : C_QuestLog.GetTitleForQuestID ; Era : C_QuestLog.GetQuestInfo, puis le journal.
function API.QuestTitle(id)
  if type(id) ~= "number" then return nil end
  local fn = C_QuestLog and (C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo)
  if fn then
    local ok, title = pcall(fn, id)
    if ok and type(title) == "string" and title ~= "" then return title end
  end
  local idx = API.QuestLogIndex(id)
  local e = idx and logEntry(idx)
  if e and type(e.title) == "string" and e.title ~= "" then return e.title end
  return nil
end

---------------------------------------------------------------------------
-- Fenêtre de quêtes sans dialogue (QUEST_GREETING)
---------------------------------------------------------------------------
-- -> questID (ou nil), titre. Forever : GetActiveQuestID / 5e valeur de GetAvailableQuestInfo.
-- Era : ces fonctions n'existent pas ou ne donnent pas l'ID ; seul le titre est connu.
function API.GreetingQuest(index, isActive)
  local id, title
  if isActive then
    if GetActiveQuestID then id = GetActiveQuestID(index) end
    if GetActiveTitle then title = GetActiveTitle(index) end
  else
    if GetAvailableQuestInfo then id = select(5, GetAvailableQuestInfo(index)) end
    if GetAvailableTitle then title = GetAvailableTitle(index) end
  end
  if type(id) ~= "number" or id <= 0 then id = nil end
  if type(title) ~= "string" or title == "" then title = nil end
  return id, title
end

---------------------------------------------------------------------------
-- Objets
---------------------------------------------------------------------------
-- Mêmes valeurs que GetItemInfo. Forever : C_Item.GetItemInfo ; Era ancien : GetItemInfo global.
function API.GetItemInfo(item)
  local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  if not fn then return nil end
  return fn(item)
end

-- Mêmes valeurs que GetItemInfoInstant.
function API.GetItemInfoInstant(item)
  local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not fn then return nil end
  return fn(item)
end

function API.HasItemStats()
  return (C_Item and C_Item.GetItemStats) ~= nil or GetItemStats ~= nil
end

-- Table des statistiques (clés ITEM_MOD_*), ou nil sans API. Era : GetItemStats global.
function API.GetItemStats(link)
  local fn = (C_Item and C_Item.GetItemStats) or GetItemStats
  if not fn then return nil end
  local stats = fn(link)
  if type(stats) == "table" then return stats end
  return {}
end

---------------------------------------------------------------------------
-- Marqueur natif (repère de carte)
---------------------------------------------------------------------------
-- Forever : C_Map.SetUserWaypoint + UiMapPoint + C_SuperTrack (marqueur 3D).
-- Era 1.15 : ni repère de carte ni marqueur 3D (aucune de ces API) : on se replie proprement.
function API.HasNativeWaypoint()
  return C_Map ~= nil and C_Map.SetUserWaypoint ~= nil and type(UiMapPoint) == "table"
    and UiMapPoint.CreateFromCoordinates ~= nil
end

-- SetNativeWaypoint(mapId, x01, y01, title) -> true (posé), false (carte refusée, ancien repère
-- retiré) ou nil (pas de repère natif sur ce client). x et y en 0-1.
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

---------------------------------------------------------------------------
-- Textes propres à Era
---------------------------------------------------------------------------
Q:RegisterStrings({
  enUS = {
    NAV_NO_NATIVE_ERA = "Classic Era has no built-in map pin or 3D marker: install TomTom and choose it in /qf wizard.",
  },
  frFR = {
    NAV_NO_NATIVE_ERA = "Classic Era n'a ni repère de carte ni marqueur 3D : installe TomTom et choisis-le dans /qf wizard.",
  },
})

-- Sur Era, le « repère du jeu » n'existe pas : l'assistant le dit au lieu de le promettre.
if Q.IsClassicEra() then
  Q:RegisterStrings({
    enUS = { UI_NAV_NATIVE_DESC = "Classic Era has no map pin: only the tracker shows the step. TomTom is recommended." },
    frFR = { UI_NAV_NATIVE_DESC = "Classic Era n'a pas de repère de carte : seul le suivi affiche l'étape. TomTom est conseillé." },
  })
end
