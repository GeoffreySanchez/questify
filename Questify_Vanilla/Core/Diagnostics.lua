local addonName, Q = ...

-- Diagnostic du client (/qf check) et texte du rapport de bug (/qf bug, alias /qf report).
-- Les vérifications lisent le jeu au moment de l'appel et ne changent rien : aucune quête,
-- aucun repère, aucun réglage n'est modifié. Les points qui ne se vérifient qu'en jeu
-- (README, « Première connexion ») sont ainsi lisibles en une commande, le soir du lancement.
local Diag = {}
Q.Diagnostics = Diag

local L = Q.L

local STATUS_TAG = {
  ok = "|cff40ff40[OK]|r",
  info = "|cff66bbff[i]|r",
  warn = "|cffffd100[!]|r",
  fail = "|cffff5555[X]|r",
}
local PLAIN_TAG = { ok = "[OK]", info = "[i]", warn = "[!]", fail = "[X]" }

---------------------------------------------------------------------------
-- Lecture prudente du client
---------------------------------------------------------------------------
-- Résout "C_QuestLog.GetInfo" depuis les globales ; nil si un maillon manque.
local function resolve(path)
  local v = _G
  for part in path:gmatch("[^%.]+") do
    if type(v) ~= "table" then return nil end
    v = v[part]
  end
  return v
end

local function missingFunctions(paths)
  local out = {}
  for _, p in ipairs(paths) do
    if type(resolve(p)) ~= "function" then out[#out + 1] = p end
  end
  return out
end

-- Valeur d'une API ou nil (erreur, valeur secrète).
local function read(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, ...)
  if not ok or Q.Util.IsSecret(v) then return nil end
  return v
end

local function metadata(addon, field)
  local fn = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local v = read(fn, addon, field)
  if type(v) == "string" and v ~= "" then return v end
  return nil
end

local function cvar(name)
  local fn = (C_CVar and C_CVar.GetCVar) or GetCVar
  return read(fn, name)
end

local function playerMap()
  local map = read(C_Map and C_Map.GetBestMapForUnit, "player")
  if type(map) == "number" and map > 0 then return map end
  return nil
end

local function mapName(map)
  local info = read(C_Map and C_Map.GetMapInfo, map)
  if type(info) == "table" and type(info.name) == "string" then return info.name end
  return nil
end

local function mapLabel(map)
  local name = mapName(map)
  if name then return string.format("%s (%d)", name, map) end
  return tostring(map)
end

local function providerLabel(id)
  if not id then return "-" end
  return Q.Nav and Q.Nav.ProviderLabel and Q.Nav:ProviderLabel(id) or tostring(id)
end

local function onOff(v) return v and L.DIAG_YES or L.DIAG_NO end

---------------------------------------------------------------------------
-- API attendues (seules celles appelées sans garde par l'addon)
---------------------------------------------------------------------------
local API_COMMON = {
  "C_QuestLog.IsQuestFlaggedCompleted", "C_QuestLog.GetQuestObjectives",
  "C_Map.GetBestMapForUnit", "C_Map.GetPlayerMapPosition", "C_Map.GetWorldPosFromMapPos",
  "C_Timer.After", "C_Timer.NewTicker", "InCombatLockdown", "GetBuildInfo",
}
local API_QUESTLOG = {
  "C_QuestLog.GetInfo", "C_QuestLog.GetLogIndexForQuestID", "C_QuestLog.IsComplete",
  "C_QuestLog.GetTitleForQuestID",
}
local API_AUTOMATION = {
  "GetQuestID", "AcceptQuest", "IsQuestCompletable", "CompleteQuest", "GetNumQuestChoices",
  "GetQuestReward", "C_GossipInfo.GetActiveQuests", "C_GossipInfo.SelectActiveQuest",
  "C_GossipInfo.GetAvailableQuests", "C_GossipInfo.SelectAvailableQuest",
}
local API_NAMEPLATES = { "C_NamePlate.GetNamePlateForUnit", "C_NamePlate.GetNamePlates", "UnitGUID" }

local function apiCheck(paths)
  local miss = missingFunctions(paths)
  if #miss == 0 then return "ok", string.format(L.DIAG_API_OK, #paths) end
  return "fail", string.format(L.DIAG_API_MISSING, table.concat(miss, ", "))
end

---------------------------------------------------------------------------
-- Vérifications : chaque fonction renvoie statut ("ok", "info", "warn", "fail"), détail
---------------------------------------------------------------------------
local CHECKS = {}
local function check(id, label, fn) CHECKS[#CHECKS + 1] = { id = id, label = label, fn = fn } end

check("client", "DIAG_CLIENT", function()
  local version, build, _, interface = GetBuildInfo()
  local detail = string.format("%s (%s), interface %s", tostring(version), tostring(build), tostring(interface))
  if Q.IsForever() then return "ok", "Forever " .. detail end
  return "warn", string.format(L.DIAG_CLIENT_UNKNOWN, detail)
end)

check("questiedb", "DIAG_QUESTIEDB", function()
  local status = Q.QDB:Status()
  if status == "ok" then
    return "ok", string.format(L.DIAG_QUESTIEDB_OK, metadata("QuestieDB", "Version") or "?")
  end
  if status == "old" then return "fail", L.QUESTIEDB_TOO_OLD end
  return "fail", L.NEED_QUESTIEDB
end)

check("questlog", "DIAG_QUESTLOG", function()
  local paths = {}
  for _, p in ipairs(API_COMMON) do paths[#paths + 1] = p end
  for _, p in ipairs(API_QUESTLOG) do paths[#paths + 1] = p end
  return apiCheck(paths)
end)

check("automation", "DIAG_AUTOMATION", function()
  local status, detail = apiCheck(API_AUTOMATION)
  if status ~= "ok" then return status, detail end
  local accept, reward = Q.Settings:Get("autoQuest") == true, Q.Settings:Get("autoReward") == true
  return "ok", string.format(L.DIAG_AUTOMATION_OK, onOff(accept), onOff(reward))
end)

check("position", "DIAG_POSITION", function()
  local map = playerMap()
  if not map then return "warn", L.DIAG_POSITION_NO_MAP end
  local pos = read(C_Map.GetPlayerMapPosition, map, "player")
  local x, y
  if type(pos) == "table" and type(pos.GetXY) == "function" then
    local ok, px, py = pcall(pos.GetXY, pos)
    if ok then x, y = px, py end
  end
  if type(x) ~= "number" or type(y) ~= "number" then
    return "warn", string.format(L.DIAG_POSITION_NO_POS, mapLabel(map))
  end
  return "ok", string.format("%s %.1f, %.1f", mapLabel(map), x * 100, y * 100)
end)

check("waypoint", "DIAG_WAYPOINT", function()
  if not Q.API.HasNativeWaypoint() then return "fail", L.DIAG_WAYPOINT_MISSING end
  local warn
  if not (C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint) then warn = L.DIAG_WAYPOINT_NO_3D end
  local st = Q.Nav and Q.Nav:Status() or {}
  local map = st.target and st.target.mapId
  if map and C_Map.CanSetUserWaypointOnMap and read(C_Map.CanSetUserWaypointOnMap, map) == false then
    return "warn", string.format(L.DIAG_WAYPOINT_REFUSED, mapLabel(map))
  end
  if warn then return "warn", warn end
  if st.provider ~= "native" then return "ok", L.DIAG_WAYPOINT_READY end
  -- Questify a posé le repère : le jeu doit le montrer.
  if C_Map.HasUserWaypoint and read(C_Map.HasUserWaypoint) == false then
    return "warn", L.DIAG_WAYPOINT_LOST
  end
  return "ok", L.DIAG_WAYPOINT_PLACED
end)

check("navigation", "DIAG_NAVIGATION", function()
  local d = Q.Nav:Detect()
  local found = {}
  for _, id in ipairs({ "shortestpath", "waypointui", "tomtom" }) do
    if d[id] then found[#found + 1] = providerLabel(id) end
  end
  local installed = #found > 0 and table.concat(found, ", ") or L.DIAG_NONE
  local routing, display = Q.Nav:Active()
  local wanted = Q.Settings:Get("nav.display")
  if wanted ~= "native" and display ~= wanted then
    return "warn", string.format(L.DIAG_NAV_FALLBACK, providerLabel(wanted), providerLabel(display))
  end
  if Q.Settings:Get("nav.routing") == true and not routing then
    return "warn", string.format(L.DIAG_NAV_FALLBACK, providerLabel("shortestpath"), providerLabel(display))
  end
  local st = Q.Nav:Status()
  local using = routing and (providerLabel(routing) .. " > " .. providerLabel(display)) or providerLabel(display)
  if st.target and not st.provider then
    return "warn", string.format(L.DIAG_NAV_NOT_PLACED, using)
  end
  return "ok", string.format(L.DIAG_NAV_OK, using, installed)
end)

check("route", "DIAG_ROUTE", function()
  if not Q.Progress:IsEnabled() then return "fail", L.DIAG_ROUTE_DISABLED end
  local P = Q.Player or {}
  local g = Q.Progress:Guide()
  if not g then
    return "warn", string.format(L.DIAG_ROUTE_NONE, tostring(P.faction), tostring(P.raceKey), tonumber(P.level) or 0)
  end
  local cur = Q.Progress:Current()
  if not cur then return "info", string.format(L.DIAG_ROUTE_FINISHED, g.id) end
  if cur.source == "guide" then
    return "ok", string.format(L.DIAG_ROUTE_STEP, g.id, cur.index, #g.steps)
  end
  return "ok", string.format(L.DIAG_ROUTE_INSERTED, g.id, tostring(cur.tag))
end)

check("targeting", "DIAG_TARGETING", function()
  local keyDown = cvar("ActionButtonUseKeyDown")
  local hasTm = type(SLASH_TARGET_MARKER1) == "string"
  local hasExact = type(SLASH_TARGET_EXACT1) == "string"
  return "info", string.format(L.DIAG_TARGETING_INFO, onOff(hasExact), onOff(hasTm), tostring(keyDown or "?"))
end)

check("nameplates", "DIAG_NAMEPLATES", function()
  if Q.Settings:Get("nameplates") ~= true then return "info", L.DIAG_OFF end
  local miss = missingFunctions(API_NAMEPLATES)
  if #miss > 0 then return "warn", string.format(L.DIAG_API_MISSING, table.concat(miss, ", ")) end
  return "ok", string.format(L.DIAG_API_OK, #API_NAMEPLATES)
end)

check("secrets", "DIAG_SECRETS", function()
  if type(issecretvalue) == "function" then return "info", L.DIAG_SECRETS_ON end
  return "info", L.DIAG_SECRETS_OFF
end)

check("errors", "DIAG_ERRORS", function()
  local n = 0
  for _, e in ipairs(Q:SavedErrors()) do
    if type(e) == "table" and (e.version == nil or e.version == Q.version) then n = n + 1 end
  end
  if n == 0 then return "ok", L.DIAG_ERRORS_NONE end
  return "warn", string.format(L.DIAG_ERRORS_SOME, n)
end)

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
-- Run() -> { { id, label, status, detail }, ... } dans l'ordre ; une vérification qui plante
-- devient « fail » avec son message, sans arrêter les autres.
function Diag:Run()
  local out = {}
  for _, c in ipairs(CHECKS) do
    local ok, status, detail = pcall(c.fn)
    if not ok then
      status, detail = "fail", tostring(status)
    elseif not STATUS_TAG[status] then
      status = "info"
    end
    out[#out + 1] = { id = c.id, label = L[c.label], status = status, detail = tostring(detail or "") }
  end
  return out
end

-- Nombre de problèmes (warn + fail) d'un résultat de Run().
function Diag.Problems(results)
  local n = 0
  for _, r in ipairs(results) do
    if r.status == "warn" or r.status == "fail" then n = n + 1 end
  end
  return n
end

local function line(r, colored)
  local tag = (colored and STATUS_TAG or PLAIN_TAG)[r.status]
  return string.format("%s %s: %s", tag, r.label, r.detail)
end

-- PrintChecks() : résumé dans la discussion. Tout est affiché : l'utilisateur lit chaque ligne.
function Diag:PrintChecks()
  local results = self:Run()
  local problems = Diag.Problems(results)
  if problems == 0 then
    Q:Print(L.DIAG_SUMMARY_OK, #results)
  else
    Q:Print(L.DIAG_SUMMARY_PROBLEMS, problems, #results)
  end
  for _, r in ipairs(results) do Q:Print(line(r, true)) end
  return results
end

---------------------------------------------------------------------------
-- Rapport de bug (texte brut, prêt à coller dans une issue)
---------------------------------------------------------------------------
local SETTING_PATHS = {
  "autoQuest", "autoReward", "dungeonQuests", "nav.display", "nav.routing",
  "tracker.locked", "tracker.scale", "tracker.nextSteps", "tracker.showMobs", "nameplates", "telemetry",
}

-- Toutes les autres options (Q.Settings.defaults, parcours récursif, ordre alphabétique) : une option
-- ajoutée apparaît dans le rapport sans toucher à cette liste (confort, donjons, assistant…).
local function otherSettingPaths()
  local seen, out = {}, {}
  for _, p in ipairs(SETTING_PATHS) do seen[p] = true end
  local function walk(t, prefix, depth)
    if type(t) ~= "table" or depth > 4 then return end
    for k, v in pairs(t) do
      if type(k) == "string" then
        local path = prefix and (prefix .. "." .. k) or k
        if type(v) == "table" then
          walk(v, path, depth + 1)
        elseif not seen[path] then
          out[#out + 1] = path
        end
      end
    end
  end
  walk(Q.Settings and Q.Settings.defaults, nil, 1)
  table.sort(out)
  return out
end

-- Valeur courte : on/off pour les cases à cocher, la valeur sinon.
local function compactValue(v)
  if v == true then return "on" end
  if v == false then return "off" end
  return tostring(v)
end

local function formatTime(t)
  if type(t) ~= "number" or t <= 0 or type(date) ~= "function" then return "?" end
  local ok, s = pcall(date, "%Y-%m-%d %H:%M:%S", t)
  return ok and s or "?"
end

local NEXT_STEPS = 3   -- étapes suivantes non faites listées dans le rapport

local function coords(mapId, x, y)
  return string.format("%s %.1f, %.1f", tostring(mapId), tonumber(x) or 0, tonumber(y) or 0)
end

-- Une étape sur une ligne : clé [état/raison] action, quête, objectif, métier, point, titre affiché.
local function stepText(e)
  if not e then return "-" end
  local s = e.step or {}
  local parts = { tostring(s.action) }
  if s.questId then
    local name = Q.QDB:IsAvailable() and Q.QDB:QuestName(s.questId) or nil
    parts[#parts + 1] = tostring(s.questId)
    if type(name) == "string" and name ~= "" and name:sub(1, 1) ~= "#" then parts[#parts + 1] = "\"" .. name .. "\"" end
  end
  if s.obj then parts[#parts + 1] = "obj " .. tostring(s.obj) end
  if s.prof then parts[#parts + 1] = tostring(s.prof) end
  if s.mapId and s.x and s.y then
    parts[#parts + 1] = "@ " .. coords(s.mapId, s.x, s.y)
  elseif s.at then
    parts[#parts + 1] = "@ " .. coords(s.at.mapId, s.at.x, s.at.y)
  end
  local okTitle, title = pcall(Q.Format.StepTitle, Q.Format, e)
  if okTitle and type(title) == "string" and title ~= "" then parts[#parts + 1] = "- \"" .. title .. "\"" end
  local state, reason = Q.Progress:State(e)
  return string.format("%s [%s%s] %s", tostring(e.key), tostring(state), reason and ("/" .. tostring(reason)) or "",
    table.concat(parts, " "))
end

-- Les NEXT_STEPS étapes non faites qui suivent l'étape courante.
local function nextSteps(cur)
  local out = {}
  if not cur then return out end
  local started = false
  for _, e in ipairs(Q.Progress:Entries()) do
    if started then
      local state = Q.Progress:State(e)
      if state ~= "done" and state ~= "skipped" then
        out[#out + 1] = e
        if #out >= NEXT_STEPS then break end
      end
    elseif e == cur or e.key == cur.key then
      started = true
    end
  end
  return out
end

-- Quêtes du journal : "179*" (* = prête à rendre), séparées par des virgules.
local function questLog()
  local ids = {}
  local n = read(C_QuestLog and C_QuestLog.GetNumQuestLogEntries)
  for i = 1, tonumber(n) or 0 do
    local info = read(C_QuestLog.GetInfo, i)
    if type(info) == "table" and info.questID and not info.isHeader then
      ids[#ids + 1] = tostring(info.questID) .. (read(C_QuestLog.IsComplete, info.questID) and "*" or "")
    end
  end
  return ids
end

local function addonVersion(name)
  local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  local isLoaded = read(loaded, name)
  if isLoaded == false then return "-" end
  return metadata(name, "Version") or (isLoaded and "?" or "-")
end

-- Report() -> texte multi-ligne : version, client, personnage, addons, route (étape courante et
-- suivantes, cible de l'étape), position, navigation, journal de quêtes, réglages, vérifications
-- et erreurs gardées (pile comprise, y compris celles survenues pendant le chargement).
function Diag:Report()
  local out = {}
  local function add(fmt, ...)
    if select("#", ...) > 0 then out[#out + 1] = string.format(fmt, ...) else out[#out + 1] = fmt end
  end
  local P = Q.Player or {}

  add("Questify Vanilla %s - bug report (%s)", tostring(Q.version), formatTime(time and time()))
  local version, build, _, interface = GetBuildInfo()
  add("Client: %s (%s), interface %s, %s", tostring(version), tostring(build), tostring(interface),
    tostring(GetLocale and GetLocale() or "?"))
  add("Character: %s %s %s, level %s", tostring(P.faction), tostring(P.raceKey), tostring(P.classFile), tostring(P.level))

  local addons = {}
  for _, name in ipairs({ "QuestieDB", "TomTom", "WaypointUI", "ShortestPathForever" }) do
    addons[#addons + 1] = name .. " " .. addonVersion(name)
  end
  add("Addons: %s", table.concat(addons, ", "))

  local g = Q.Progress:IsEnabled() and Q.Progress:Guide() or nil
  local cur = g and Q.Progress:Current() or nil
  add("Route: %s", g and string.format("%s \"%s\" (%d steps)", g.id, tostring(g.title), #g.steps) or "-")
  add("Step: %s", stepText(cur))
  for _, e in ipairs(nextSteps(cur)) do add("  next: %s", stepText(e)) end
  local tg = cur and Q.Targets and Q.Targets:ForEntry(cur)
  if type(tg) == "table" then
    add("Step target: %s %s @ %s", tostring(tg.kind), tostring(tg.id or "-"), coords(tg.mapId, tg.x, tg.y))
  end

  local map = playerMap()
  local pos = map and read(C_Map.GetPlayerMapPosition, map, "player")
  local px, py
  if type(pos) == "table" and type(pos.GetXY) == "function" then
    local ok, x, y = pcall(pos.GetXY, pos)
    if ok then px, py = x, y end
  end
  if map and type(px) == "number" and type(py) == "number" then
    add("Position: %s %.1f, %.1f", mapLabel(map), px * 100, py * 100)
  else
    add("Position: %s", map and mapLabel(map) or "-")
  end

  local st = Q.Nav and Q.Nav:Status() or {}
  local t = st.target
  if t then
    add("Target: %s %.1f, %.1f \"%s\" via %s (%s)", mapLabel(t.mapId), t.x, t.y, tostring(t.title),
      tostring(st.wanted), st.provider and "placed" or "not placed")
  else
    add("Target: -")
  end
  local routing, display
  if Q.Nav and Q.Nav.Active then routing, display = Q.Nav:Active() end
  add("Navigation: routing %s, display %s", tostring(routing or "-"), tostring(display or "-"))

  local log = questLog()
  add("Quest log (%d): %s", #log, #log > 0 and table.concat(log, ", ") or "-")

  local settings = {}
  for _, path in ipairs(SETTING_PATHS) do settings[#settings + 1] = path .. "=" .. tostring(Q.Settings:Get(path)) end
  add("Settings: %s", table.concat(settings, " "))
  local options = {}
  for _, path in ipairs(otherSettingPaths()) do
    options[#options + 1] = path .. "=" .. compactValue(Q.Settings:Get(path))
  end
  if #options > 0 then add("Options: %s", table.concat(options, " ")) end

  add("")
  add("Checks:")
  for _, r in ipairs(self:Run()) do add("  " .. line(r, false)) end

  local errors = Q:SavedErrors()
  add("")
  add("Errors (%d):", #errors)
  if #errors == 0 then add("  -") end
  for i = #errors, 1, -1 do
    local e = errors[i]
    if type(e) == "table" then
      add("#%d x%d (%s, %s)", #errors - i + 1, tonumber(e.count) or 1, tostring(e.version or Q.version), formatTime(e.time))
      add("%s", tostring(e.msg))
      if type(e.stack) == "string" and e.stack ~= "" then add("%s", e.stack) end
    end
  end
  return table.concat(out, "\n")
end
