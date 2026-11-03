local addonName, Q = ...

-- Seule globale publique de l'addon (macros, débogage).
QuestifyVanilla = Q

Q.addonName = addonName
Q.version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")) or "dev"

local unpack = unpack
local select = select

local PREFIX = "|cff33ccffQuestify Vanilla|r:"
local ERROR_PREFIX = "|cffff5555Questify Vanilla:|r"

---------------------------------------------------------------------------
-- Affichage
---------------------------------------------------------------------------
local function output(msg)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  else
    print(msg)
  end
end

-- Q:Print(fmt, ...) : message dans la fenêtre de discussion, préfixé du nom de l'addon.
function Q:Print(fmt, ...)
  local msg
  if select("#", ...) > 0 then
    local ok, res = pcall(string.format, tostring(fmt), ...)
    msg = ok and res or tostring(fmt)
  else
    msg = tostring(fmt)
  end
  output(PREFIX .. " " .. msg)
end

-- Q:Debug(...) : n'affiche rien sauf si QuestifyVanillaDB.debug est vrai.
function Q:Debug(...)
  if not (QuestifyVanillaDB and QuestifyVanillaDB.debug) then return end
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  output(PREFIX .. " |cff999999[debug]|r " .. table.concat(parts, " "))
end

---------------------------------------------------------------------------
-- Erreurs : chaque erreur distincte n'est affichée qu'une fois.
---------------------------------------------------------------------------
local reported = {}
Q.errorLog = {}

function Q:ReportError(err)
  local msg = tostring(err)
  if reported[msg] then return end
  reported[msg] = true
  self.errorLog[#self.errorLog + 1] = msg
  output(ERROR_PREFIX .. " " .. msg)
end

local function pack(...) return { n = select("#", ...), ... } end

local function errorHandler(err)
  if QuestifyVanillaDB and QuestifyVanillaDB.debug and debugstack then
    return tostring(err) .. "\n" .. tostring(debugstack(2))
  end
  return err
end

-- Q.SafeCall(fn, ...) -> ok, ... : exécute fn sans jamais propager d'erreur à l'interface.
function Q.SafeCall(fn, ...)
  local args = pack(...)
  local res = pack(xpcall(function() return fn(unpack(args, 1, args.n)) end, errorHandler))
  if not res[1] then Q:ReportError(res[2]) end
  return unpack(res, 1, res.n)
end

-- Minuteurs protégés.
function Q:After(seconds, fn)
  if not (C_Timer and C_Timer.After) then return end
  C_Timer.After(seconds, function() Q.SafeCall(fn) end)
end

function Q:NewTicker(seconds, fn, iterations)
  if not (C_Timer and C_Timer.NewTicker) then return nil end
  return C_Timer.NewTicker(seconds, function(ticker) Q.SafeCall(fn, ticker) end, iterations)
end

---------------------------------------------------------------------------
-- Messages internes
---------------------------------------------------------------------------
local listeners = {}

function Q:On(msg, fn)
  local list = listeners[msg]
  if not list then list = {}; listeners[msg] = list end
  list[#list + 1] = fn
  return fn
end

function Q:Off(msg, fn)
  local list = listeners[msg]
  if not list then return end
  for i = #list, 1, -1 do if list[i] == fn then table.remove(list, i) end end
end

function Q:Fire(msg, ...)
  local list = listeners[msg]
  if not list then return end
  local copy = {}
  for i, fn in ipairs(list) do copy[i] = fn end
  for _, fn in ipairs(copy) do Q.SafeCall(fn, ...) end
end

---------------------------------------------------------------------------
-- Évènements du jeu : une seule frame cachée, plusieurs gestionnaires par évènement.
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:Hide()
local handlers = {}
Q.eventFrame = eventFrame

eventFrame:SetScript("OnEvent", function(_, event, ...)
  local list = handlers[event]
  if not list then return end
  local copy = {}
  for i, fn in ipairs(list) do copy[i] = fn end
  for _, fn in ipairs(copy) do Q.SafeCall(fn, event, ...) end
end)

function Q:RegisterEvent(event, fn)
  local list = handlers[event]
  if not list then
    list = {}
    handlers[event] = list
    local ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
    if not ok then Q:Debug("unknown event", event) end
  end
  list[#list + 1] = fn
  return fn
end

function Q:UnregisterEvent(event, fn)
  local list = handlers[event]
  if not list then return end
  for i = #list, 1, -1 do if list[i] == fn then table.remove(list, i) end end
  if #list == 0 then
    handlers[event] = nil
    pcall(eventFrame.UnregisterEvent, eventFrame, event)
  end
end

---------------------------------------------------------------------------
-- Détection de Forever (interface 16000-16999 ; WOW_PROJECT_ID vaut 1 comme Retail)
---------------------------------------------------------------------------
function Q.IsForever()
  local interface = GetBuildInfo and select(4, GetBuildInfo())
  interface = tonumber(interface) or 0
  return interface >= 16000 and interface <= 16999
end

---------------------------------------------------------------------------
-- État sauvegardé et démarrage
---------------------------------------------------------------------------
Q.charDefaults = {
  guideId = nil,
  manual = {},
  skipped = {},
  inserted = {},
  classQuests = { added = {}, ignored = {}, seen = {} },
  telemetry = {},
  wizardDone = nil,
}

local function onAddonLoaded(event, name)
  if name ~= addonName then return end
  Q:UnregisterEvent("ADDON_LOADED", onAddonLoaded)

  if type(QuestifyVanillaDB) ~= "table" then QuestifyVanillaDB = {} end
  if type(QuestifyVanillaCharDB) ~= "table" then QuestifyVanillaCharDB = {} end
  local copy = Q.Util and Q.Util.CopyDefaults
  if copy then
    copy(QuestifyVanillaDB, { settings = (Q.Settings and Q.Settings.defaults) or {}, debug = false })
    copy(QuestifyVanillaCharDB, Q.charDefaults)
  end
  Q.db = QuestifyVanillaDB
  Q.char = QuestifyVanillaCharDB
  Q:Fire("INIT")
end
Q:RegisterEvent("ADDON_LOADED", onAddonLoaded)

Q:RegisterEvent("PLAYER_LOGIN", function()
  Q.loggedIn = true
  -- QuestieDB absent ou trop ancien : une seule ligne d'explication, le moteur reste inactif.
  if not (Q.QDB and Q.QDB:IsAvailable()) then
    local status = Q.QDB and Q.QDB.Status and Q.QDB:Status() or "missing"
    if status == "old" then Q:Print(Q.L.QUESTIEDB_TOO_OLD) else Q:Print(Q.L.NEED_QUESTIEDB) end
  end
  Q:Fire("LOGIN")
end)

Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  Q:Fire("COMBAT_ENDED")
end)
