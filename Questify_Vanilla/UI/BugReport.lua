local addonName, Q = ...

-- /qf bug : rapport à copier-coller (version de l'addon et du client, QuestieDB, personnage,
-- position, chapitre, étape courante et suivantes, quêtes du journal, réglages de navigation,
-- dernières erreurs). La fenêtre sélectionne le texte : Ctrl + C, puis coller dans la discussion.
Q.UI = Q.UI or {}
local Bug = {}
Q.UI.BugReport = Bug

local L = Q.L

local FRAME_NAME = "QuestifyVanillaBugReport"
local MAX_ERRORS = 10
local NEXT_STEPS = 3

local function call(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b, c, d = pcall(fn, ...)
  if not ok then return nil end
  return a, b, c, d
end

local function plain(v)
  if Q.Util.IsSecret(v) then return "?" end
  return tostring(v)
end

local function addonVersion(name)
  local fn = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  return call(fn, name, "Version") or "?"
end

local function stepLine(e)
  if not e then return "-" end
  local s = e.step
  local state, reason = Q.Progress:State(e)
  local parts = { e.key, s.action }
  if s.questId then parts[#parts + 1] = "q" .. s.questId end
  if s.obj then parts[#parts + 1] = "obj" .. s.obj end
  if s.prof then parts[#parts + 1] = s.prof end
  parts[#parts + 1] = tostring(state) .. (reason and ("/" .. tostring(reason)) or "")
  parts[#parts + 1] = "\"" .. Q.Util.StripColors(Q.Format:StepTitle(e)) .. "\""
  return table.concat(parts, " ")
end

-- Texte du rapport (une ligne par information).
function Bug:Text()
  local P = Q.Player
  local lines = {}
  local function add(fmt, ...) lines[#lines + 1] = string.format(fmt, ...) end
  local version, build, _, iface = call(GetBuildInfo)
  add("Questify Vanilla %s | client %s (%s, interface %s) | %s | %s", tostring(Q.version), tostring(version),
    tostring(build), tostring(iface), (GetLocale and GetLocale()) or "?", Q.IsForever() and "Forever" or "?")
  local qdb = Q.QDB and Q.QDB.Status and Q.QDB:Status() or "?"
  add("QuestieDB %s (%s)", addonVersion("QuestieDB"), tostring(qdb))
  add("Perso : %s %s niveau %s %s", plain(P.raceKey), plain(P.classFile), plain(P.level), plain(P.faction))
  local m, x, y = Q.Maps:PlayerPos()
  add("Position : carte %s %.2f, %.2f", plain(m), tonumber(x) or 0, tonumber(y) or 0)
  local g = Q.Progress:Guide()
  add("Chapitre : %s", g and g.id or "-")
  local cur = Q.Progress:Current()
  add("Étape : %s", stepLine(cur))
  local tg = cur and Q.Targets:ForEntry(cur)
  if tg then add("Cible : %s %s carte %s %.2f, %.2f", tostring(tg.kind), tostring(tg.id or "-"), tostring(tg.mapId), tg.x or 0, tg.y or 0) end
  local started, n = false, 0
  for _, e in ipairs(Q.Progress:Entries()) do
    if started then
      local s = Q.Progress:State(e)
      if s ~= "done" and s ~= "skipped" then
        n = n + 1
        add("  suivante : %s", stepLine(e))
        if n >= NEXT_STEPS then break end
      end
    elseif e == cur then
      started = true
    end
  end
  local log = {}
  local num = call(C_QuestLog and C_QuestLog.GetNumQuestLogEntries) or 0
  for i = 1, num do
    local info = call(C_QuestLog.GetInfo, i)
    if type(info) == "table" and info.questID and not info.isHeader then
      log[#log + 1] = tostring(info.questID) .. (call(C_QuestLog.IsComplete, info.questID) and "*" or "")
    end
  end
  add("Journal (%d) : %s", #log, table.concat(log, ","))
  local routing, display
  if Q.Nav and Q.Nav.Active then routing, display = Q.Nav:Active() end
  add("Navigation : %s / %s", tostring(routing or "-"), tostring(display or "-"))
  local errs = Q.errorLog or {}
  add("Erreurs (%d) :", #errs)
  for i = math.max(1, #errs - MAX_ERRORS + 1), #errs do
    local e = errs[i]
    local msg = type(e) == "table" and e.msg or e
    lines[#lines + 1] = "  " .. tostring(msg):gsub("[\r\n]+", " / ")
  end
  return table.concat(lines, "\n")
end

function Bug:Create()
  if self.frame then return self.frame end
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "BasicFrameTemplateWithInset")
  if not ok or not f then f = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate") end
  self.frame = f
  f:SetSize(560, 360)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  local title = f.TitleText or f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  if not f.TitleText then title:SetPoint("TOP", f, "TOP", 0, -8) end
  title:SetText(L.UI_BUG_TITLE)
  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -30)
  hint:SetText(L.UI_BUG_HINT)
  local scroll = CreateFrame("ScrollFrame", FRAME_NAME .. "Scroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -50)
  scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 14)
  local box = CreateFrame("EditBox", FRAME_NAME .. "Box", scroll)
  box:SetMultiLine(true)
  box:SetAutoFocus(false)
  box:SetFontObject(ChatFontNormal or "GameFontHighlightSmall")
  box:SetWidth(500)
  box:SetScript("OnEscapePressed", function() f:Hide() end)
  -- lecture seule : toute frappe remet le rapport
  box:SetScript("OnTextChanged", function(self, userInput)
    if userInput and Bug.value then self:SetText(Bug.value); self:HighlightText() end
  end)
  scroll:SetScrollChild(box)
  self.box = box
  f:Hide()
  return f
end

function Bug:Show()
  self:Create()
  self.value = self:Text()
  self.box:SetText(self.value)
  self.frame:Show()
  self.box:SetFocus()
  self.box:HighlightText()
end
