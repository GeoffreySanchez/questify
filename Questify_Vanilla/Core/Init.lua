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
-- Erreurs : chaque erreur distincte n'est affichée qu'une fois dans la discussion.
-- Elles sont aussi gardées, avec leur pile d'appels, dans QuestifyVanillaDB.errors
-- (les 20 plus récentes) : /qf bug les retrouve après /reload ou une déconnexion.
---------------------------------------------------------------------------
local MAX_SAVED_ERRORS = 20
local MAX_STACK_CHARS = 2000

local reported = {}     -- [msg] = entrée de la session
local lastStack         -- pile capturée par errorHandler, reprise par ReportError
local hintShown         -- conseil « /qf bug » : une fois par session
Q.errorLog = {}         -- erreurs de la session : { msg, stack, count, time, saved }

local function now()
  return (time and time()) or 0
end

-- Liste sauvegardée, ou nil tant que les SavedVariables ne sont pas chargées.
local function savedErrors()
  local db = QuestifyVanillaDB
  if type(db) ~= "table" then return nil end
  if type(db.errors) ~= "table" then db.errors = {} end
  return db.errors
end

-- Ajoute l'erreur à la liste sauvegardée, ou compte une répétition (la plus récente à la fin).
local function saveError(e)
  local list = savedErrors()
  if not list then return end
  for i = #list, 1, -1 do
    local old = list[i]
    if type(old) == "table" and old.msg == e.msg and old.version == Q.version then
      old.count = (tonumber(old.count) or 1) + 1
      old.time = e.time
      if i ~= #list then
        table.remove(list, i)
        list[#list + 1] = old
      end
      e.saved = true
      return
    end
  end
  list[#list + 1] = { msg = e.msg, stack = e.stack, count = e.count or 1, time = e.time, version = Q.version }
  while #list > MAX_SAVED_ERRORS do table.remove(list, 1) end
  e.saved = true
end

-- Erreurs survenues avant le chargement des SavedVariables : enregistrées à l'INIT.
local function flushErrors()
  for _, e in ipairs(Q.errorLog) do
    if not e.saved then saveError(e) end
  end
end

function Q:ReportError(err)
  local msg = tostring(err)
  local e = reported[msg]
  if e then
    lastStack = nil
    e.count = e.count + 1
    e.time = now()
    e.saved = false
    saveError(e)
    return
  end
  -- pile de Q.SafeCall, sinon celle de l'appelant direct (lecture QuestieDB protégée…)
  local stack = lastStack or (debugstack and tostring(debugstack(2))) or nil
  lastStack = nil
  if type(stack) == "string" and #stack > MAX_STACK_CHARS then stack = stack:sub(1, MAX_STACK_CHARS) end
  e = { msg = msg, stack = stack, count = 1, time = now() }
  reported[msg] = e
  self.errorLog[#self.errorLog + 1] = e
  saveError(e)
  if QuestifyVanillaDB and QuestifyVanillaDB.debug and stack then
    output(ERROR_PREFIX .. " " .. msg .. "\n" .. stack)
  else
    output(ERROR_PREFIX .. " " .. msg)
  end
  if not hintShown then
    hintShown = true
    output(ERROR_PREFIX .. " " .. tostring(Q.L and Q.L.ERROR_REPORT_HINT))
  end
end

-- Erreurs gardées (sauvegardées si possible, sinon celles de la session), la plus récente en dernier.
function Q:SavedErrors()
  local list = savedErrors()
  if list then return list end
  return self.errorLog
end

-- Vide la liste sauvegardée (/qf bug clear). Les erreurs déjà vues restent muettes jusqu'au
-- prochain /reload ; une répétition est de nouveau enregistrée.
function Q:ClearErrors()
  local db = QuestifyVanillaDB
  if type(db) == "table" then db.errors = {} end
end

local function pack(...) return { n = select("#", ...), ... } end

-- Garde la pile d'appels d'une erreur nouvelle pour le journal (une erreur répétée à chaque
-- image ne la recalcule pas) ; le message reste celui de l'erreur.
local function errorHandler(err)
  if debugstack and not reported[tostring(err)] then lastStack = tostring(debugstack(2)) end
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
  rewardRole = "auto",   -- Automation/Rewards.lua : profil de récompense du personnage
  specRoleAnswered = {}, -- Automation/SpecRole.lua : spécialisations pour lesquelles « Non » a été répondu
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
  flushErrors()
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
