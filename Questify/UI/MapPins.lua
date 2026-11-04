local addonName, Q = ...

-- Repères des étapes sur la carte du monde et la minicarte, posés par HereBeDragons-Pins-2.0
-- (Libs\HereBeDragons). Étape courante (n° 1) et les 5 étapes suivantes non faites :
--   accept   « ! » jaune au donneur de la quête ;
--   turnin   « ? » jaune au destinataire ;
--   complete jusqu'à 8 points d'apparition des objectifs restants, les plus proches d'abord ;
--   goto, fp, sethearth, boat : l'icône de l'étape (celle du suivi) à son point.
-- Chaque repère porte le numéro d'ordre de son étape ; ceux de l'étape courante sont un peu plus
-- grands. La minicarte ne montre que l'étape courante. Survol : texte de l'étape ; clic : cible
-- de navigation (Q.Nav:SetManualTarget : prioritaire jusqu'à l'étape suivante).
-- Mode zone (Engine/ZoneMode.lua) : un repère vert au centre de la zone, en plus des repères
-- numérotés (sur la minicarte seulement hors de la zone).
-- Rien ici n'est protégé, mais le calcul attend la fin du combat (rien d'utile à redessiner
-- pendant). Option « mapPins ». Sans QuestieDB ou sans les bibliothèques : rien, en silence.
-- Coordonnées : 0-100 dans l'addon, 0-1 chez HereBeDragons.
Q.UI = Q.UI or {}
local MapPins = {}
Q.UI.MapPins = MapPins

local REF = "Questify_MapPins"   -- clé de nos repères chez HereBeDragons-Pins
local NEXT_STEPS = 5          -- étapes affichées après l'étape courante
local MAX_POINTS = 8          -- points d'objectif par étape « complete »
local MAX_SCAN = 2000         -- points d'apparition examinés au plus par étape (gros monstres communs)
local REFRESH_DELAY = 0.2     -- secondes : plusieurs messages d'affilée, un seul calcul

local SIZE_ICON, SIZE_ICON_CURRENT = 18, 22
local SIZE_DOT, SIZE_DOT_CURRENT = 10, 13
local SIZE_MINI_ICON, SIZE_MINI_DOT = 16, 11
local SIZE_ZONE, SIZE_MINI_ZONE = 20, 15
local ZONE_COLOR = { 0.25, 0.9, 0.3 }   -- vert du mode zone

local QUEST_ICONS = {
  accept = "Interface\\GossipFrame\\AvailableQuestIcon",
  turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
}
local DOT_TEXTURE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"   -- disque blanc
local SQUARE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local FP_ATLAS = "FlightPath"
local NUMBER_FONT = "NumberFontNormalSmall"

-- Style de repère par action d'étape ; une action absente n'a pas de repère.
local STYLES = {
  accept = "accept",
  turnin = "turnin",
  complete = "objective",
  ["goto"] = "point",
  fp = "point",
  sethearth = "point",
  boat = "point",
}

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function enabled()
  return Q.Settings:Get("mapPins") ~= false
end

-- Bibliothèque HereBeDragons-Pins-2.0, ou nil si elle ne s'est pas chargée.
local function hbdPins()
  local stub = LibStub
  if type(stub) ~= "table" or type(stub.GetLibrary) ~= "function" then return nil end
  local ok, lib = pcall(stub.GetLibrary, stub, "HereBeDragons-Pins-2.0", true)
  if ok and type(lib) == "table" and type(lib.AddWorldMapIconMap) == "function"
    and type(lib.AddMinimapIconMap) == "function" then
    return lib
  end
  return nil
end

-- Appel protégé d'une fonction de la bibliothèque : -> résultat, ou nil (erreur signalée).
local function call(fn, ...)
  local ok, res = pcall(fn, ...)
  if not ok then
    Q:ReportError("MapPins: " .. tostring(res))
    return nil
  end
  return res
end

local function inCombat()
  return InCombatLockdown ~= nil and InCombatLockdown() == true
end

local function validCoord(v)
  return type(v) == "number" and v == v and v >= 0 and v <= 100
end

local function hasAtlas(name)
  local fn = C_Texture and C_Texture.GetAtlasInfo
  if type(fn) ~= "function" then return false end
  local ok, info = pcall(fn, name)
  return ok and info ~= nil
end

---------------------------------------------------------------------------
-- Étapes affichées : la courante puis les NEXT_STEPS suivantes ni faites ni sautées
---------------------------------------------------------------------------
local function window()
  local out = {}
  local cur = Q.Progress:Current()
  if not cur then return out end
  out[1] = cur
  local started = false
  for _, e in ipairs(Q.Progress:Entries()) do
    if started then
      local s = Q.Progress:State(e)
      if s ~= "done" and s ~= "skipped" then
        out[#out + 1] = e
        if #out > NEXT_STEPS then break end
      end
    elseif e == cur then
      started = true
    end
  end
  return out
end
MapPins.Window = function() return window() end

---------------------------------------------------------------------------
-- Points d'une étape
---------------------------------------------------------------------------
-- Cibles des objectifs encore à faire (même choix que Q.Targets pour une étape « complete »).
local function objectiveCands(step)
  local rows = Q.Targets:ObjectiveTargets(step.questId)
  local cands = {}
  if step.obj then
    for _, r in ipairs(rows) do if r.objIndex == step.obj then cands[#cands + 1] = r end end
  elseif Q.Progress:InLog(step.questId) then
    for _, r in ipairs(rows) do
      if not Q.Progress:ObjectiveDone(step.questId, r.objIndex) then cands[#cands + 1] = r end
    end
  end
  if #cands == 0 then cands = rows end
  return cands
end

-- Points d'apparition des objectifs, les plus proches du joueur d'abord (sans position du
-- joueur : les plus proches de la zone d'objectif de l'étape, sinon dans l'ordre des données).
-- -> { { mapId, x, y, name } }, au plus MAX_POINTS.
local function objectivePoints(step)
  local rm, rx, ry = Q.Maps:PlayerPos()
  if not rm and type(step.at) == "table" then rm, rx, ry = step.at[1], step.at[2], step.at[3] end
  local pts, seen, scanned = {}, {}, 0
  for _, c in ipairs(objectiveCands(step)) do
    local key = tostring(c.kind) .. ":" .. tostring(c.id)
    if not seen[key] and scanned < MAX_SCAN then
      seen[key] = true
      local data, name
      if c.kind == "npc" then
        data, name = Q.QDB:Npc(c.id), Q.QDB:NpcName(c.id)
      else
        data, name = Q.QDB:Object(c.id), Q.QDB:ObjectName(c.id)
      end
      local spawns = data and data.spawns
      if type(spawns) == "table" then
        -- ordre stable : carte de référence d'abord, puis les autres par ID
        local maps = {}
        for m in pairs(spawns) do if type(m) == "number" then maps[#maps + 1] = m end end
        table.sort(maps, function(a, b)
          if a == rm then return b ~= rm end
          if b == rm then return false end
          return a < b
        end)
        for _, m in ipairs(maps) do
          for _, p in ipairs(spawns[m]) do
            if scanned >= MAX_SCAN then break end
            scanned = scanned + 1
            local x, y = p[1], p[2]
            if validCoord(x) and validCoord(y) then
              local d = rm and Q.Maps:Distance(rm, rx, ry, m, x, y) or nil
              pts[#pts + 1] = { mapId = m, x = x, y = y, name = name, d = d, seq = #pts + 1 }
            end
          end
        end
      end
    end
  end
  table.sort(pts, function(a, b)
    if a.d and b.d then
      if a.d ~= b.d then return a.d < b.d end
      return a.seq < b.seq
    end
    if a.d then return true end
    if b.d then return false end
    return a.seq < b.seq
  end)
  local out = {}
  for i = 1, math.min(#pts, MAX_POINTS) do out[i] = pts[i] end
  return out
end

local function targetName(tg)
  if tg.kind == "npc" and tg.id then return Q.QDB:NpcName(tg.id) end
  if tg.kind == "object" and tg.id then return Q.QDB:ObjectName(tg.id) end
  return nil
end

-- -> liste de points { mapId, x (0-100), y, name }, style (nil si l'étape n'a pas de repère).
local function pointsFor(entry)
  local step = entry.step
  local style = STYLES[step.action]
  if not style then return {}, nil end
  if style == "objective" then
    local pts = objectivePoints(step)
    if #pts > 0 then return pts, style end
    -- aucun point d'apparition connu : la cible de l'étape (zone d'objectif) seule
  end
  local tg = Q.Targets:ForEntry(entry)
  if not tg or type(tg.mapId) ~= "number" or not validCoord(tg.x) or not validCoord(tg.y) then
    return {}, style
  end
  return { { mapId = tg.mapId, x = tg.x, y = tg.y, name = targetName(tg) } }, style
end
MapPins.PointsFor = function(_, entry) return pointsFor(entry) end

---------------------------------------------------------------------------
-- Cadres des repères (une réserve pour la carte du monde, une pour la minicarte)
---------------------------------------------------------------------------
local function onEnter(self)
  local d = self.pinData
  if not d or not GameTooltip then return end
  Q.SafeCall(function()
    local L = Q.L
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if d.zone then
      -- repère de zone : résumé (titre, quêtes concernées)
      local lines = Q.ZoneMode:SummaryLines(d.zone)
      GameTooltip:AddLine(lines[1] or d.title or "", ZONE_COLOR[1], ZONE_COLOR[2], ZONE_COLOR[3])
      GameTooltip:AddLine(L.ZONE_PIN, 0.7, 0.7, 0.7)
      for i = 2, #lines do GameTooltip:AddLine(lines[i], 1, 1, 1, true) end
      GameTooltip:AddLine(L.MAP_PIN_CLICK, 0.4, 0.8, 1)
      GameTooltip:Show()
      return
    end
    GameTooltip:AddLine(d.name or d.title or "", 1, 0.82, 0)
    if d.order == 1 then
      GameTooltip:AddLine(L.MAP_PIN_CURRENT, 0.7, 0.7, 0.7)
    else
      GameTooltip:AddLine(string.format(L.MAP_PIN_UPCOMING, d.order), 0.7, 0.7, 0.7)
    end
    local text = Q.Format:StepText(d.entry)
    if type(text) == "string" then
      for line in text:gmatch("[^\n]+") do GameTooltip:AddLine(line, 1, 1, 1, true) end
    end
    GameTooltip:AddLine(L.MAP_PIN_CLICK, 0.4, 0.8, 1)
    GameTooltip:Show()
  end)
end

local function onLeave(self)
  if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
end

local function onClick(self)
  local d = self.pinData
  if not d then return end
  Q.SafeCall(function()
    Q.Nav:SetManualTarget(d.mapId, d.x, d.y, d.title)
  end)
end

local function newPin()
  local f = CreateFrame("Button", nil, UIParent)
  f:Hide()
  f:SetSize(SIZE_ICON, SIZE_ICON)
  f:EnableMouse(true)
  f:RegisterForClicks("LeftButtonUp")
  f.border = f:CreateTexture(nil, "BACKGROUND")
  f.border:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetAllPoints(f)
  f.num = f:CreateFontString(nil, "OVERLAY", NUMBER_FONT)
  f.num:SetPoint("CENTER", f, "BOTTOMRIGHT", 1, 1)
  f:SetScript("OnEnter", onEnter)
  f:SetScript("OnLeave", onLeave)
  f:SetScript("OnClick", onClick)
  return f
end

local pools = { world = { frames = {}, used = 0 }, mini = { frames = {}, used = 0 } }
MapPins.pools = pools

local function acquire(kind)
  local pool = pools[kind]
  pool.used = pool.used + 1
  local f = pool.frames[pool.used]
  if not f then
    f = newPin()
    pool.frames[pool.used] = f
  end
  return f
end

-- Rend le dernier cadre pris (repère refusé par la bibliothèque).
local function giveBack(kind)
  local pool = pools[kind]
  local f = pool.frames[pool.used]
  if f then
    f:Hide()
    f.pinData = nil
  end
  pool.used = math.max(pool.used - 1, 0)
end

local function releaseAll()
  for _, pool in pairs(pools) do
    for i = 1, pool.used do
      local f = pool.frames[i]
      f:Hide()
      f.pinData = nil
    end
    pool.used = 0
  end
end

-- Apparence du repère selon le style, l'action, l'étape courante ou non, et la carte.
local function dress(f, style, action, order, onMinimap)
  local current = order == 1
  local icon, border = f.icon, f.border
  icon:SetTexCoord(0, 1, 0, 1)
  icon:SetVertexColor(1, 1, 1, 1)
  border:Hide()
  local size
  if style == "zone" then
    size = onMinimap and SIZE_MINI_ZONE or SIZE_ZONE
    icon:SetTexture(DOT_TEXTURE)
    icon:SetVertexColor(ZONE_COLOR[1], ZONE_COLOR[2], ZONE_COLOR[3], 1)
    border:SetTexture(DOT_TEXTURE)
    border:SetVertexColor(0, 0, 0, 0.85)
    border:SetSize(size + 4, size + 4)
    border:Show()
  elseif style == "objective" then
    if onMinimap then size = SIZE_MINI_DOT else size = current and SIZE_DOT_CURRENT or SIZE_DOT end
    icon:SetTexture(DOT_TEXTURE)
    icon:SetVertexColor(1, 0.82, 0, 1)        -- jaune des quêtes
    border:SetTexture(DOT_TEXTURE)
    border:SetVertexColor(0, 0, 0, 0.85)
    border:SetSize(size + 4, size + 4)
    border:Show()
  else
    if onMinimap then size = SIZE_MINI_ICON else size = current and SIZE_ICON_CURRENT or SIZE_ICON end
    if QUEST_ICONS[style] then
      icon:SetTexture(QUEST_ICONS[style])
    elseif action == "fp" and hasAtlas(FP_ATLAS) then
      icon:SetAtlas(FP_ATLAS)
    else
      local tex = Q.Format:ActionIcon(action)
      icon:SetTexture(tex)
      if type(tex) == "string" and tex:find("^Interface\\Icons\\") then
        -- icône de sort carrée : bords rognés et cadre sombre
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        size = size - 2
        border:SetTexture(SQUARE_TEXTURE)
        border:SetVertexColor(0, 0, 0, 0.85)
        border:SetSize(size + 2, size + 2)
        border:Show()
      end
    end
  end
  f:SetSize(size, size)
  f:SetAlpha(current and 1 or 0.85)
  f.num:SetText(style == "zone" and "" or tostring(order))
end

---------------------------------------------------------------------------
-- Dessin
---------------------------------------------------------------------------
-- Repères posés au dernier dessin : { where = "world"|"minimap", order, style, mapId, x, y, frame }.
MapPins.active = {}

function MapPins:Clear()
  local lib = hbdPins()
  if lib then
    if type(lib.RemoveAllWorldMapIcons) == "function" then call(lib.RemoveAllWorldMapIcons, lib, REF) end
    if type(lib.RemoveAllMinimapIcons) == "function" then call(lib.RemoveAllMinimapIcons, lib, REF) end
  end
  releaseAll()
  self.active = {}
end

local function place(lib, kind, entry, order, style, p, title, floatOnEdge)
  local f = acquire(kind)
  dress(f, style, entry.step.action, order, kind == "mini")
  f.pinData = { entry = entry, order = order, style = style, mapId = p.mapId, x = p.x, y = p.y,
    name = p.name, title = title, zone = p.zone }
  local ok
  if kind == "world" then
    ok = call(lib.AddWorldMapIconMap, lib, REF, f, p.mapId, p.x / 100, p.y / 100,
      HBD_PINS_WORLDMAP_SHOW_PARENT or 1)
  else
    ok = call(lib.AddMinimapIconMap, lib, REF, f, p.mapId, p.x / 100, p.y / 100, false, floatOnEdge)
  end
  if not ok then
    giveBack(kind)
    return
  end
  local list = MapPins.active
  list[#list + 1] = { where = kind == "world" and "world" or "minimap", order = order, style = style,
    mapId = p.mapId, x = p.x, y = p.y, frame = f }
end

-- Repère vert au centre de la zone portée par l'étape courante (Engine/ZoneMode.lua).
function MapPins:PlaceZone(lib)
  local Z = Q.ZoneMode
  if not (Z and Z.Current and Z.IsOwner) then return end
  local z = Z:Current()
  local cur = Q.Progress:Current()
  if type(z) ~= "table" or not cur or not Z:IsOwner(cur) then return end
  local c = z.center
  if type(c.mapId) ~= "number" or not validCoord(c.x) or not validCoord(c.y) then return end
  local title = Z:Title(z)
  local p = { mapId = c.mapId, x = c.x, y = c.y, name = title, zone = z }
  place(lib, "world", cur, 1, "zone", p, title)
  if not z.inside then place(lib, "mini", cur, 1, "zone", p, title, true) end
end

function MapPins:Refresh()
  self:Clear()
  if not enabled() then return end
  local lib = hbdPins()
  if not lib then return end
  if not (Q.QDB and Q.QDB:IsAvailable()) then return end
  if not (Q.Progress and Q.Progress:IsEnabled()) then return end
  -- mode zone : repère vert au centre (minicarte : hors de la zone seulement, au bord)
  local okZ, err = pcall(MapPins.PlaceZone, MapPins, lib)
  if not okZ then Q:ReportError("MapPins: " .. tostring(err)) end
  for order, entry in ipairs(window()) do
    local pts, style = pointsFor(entry)
    if style and #pts > 0 then
      local title = Q.Format:StepTitle(entry)
      for i, p in ipairs(pts) do
        place(lib, "world", entry, order, style, p, title)
        -- minicarte : l'étape courante seulement ; le premier point (le plus proche) reste au bord
        if order == 1 then place(lib, "mini", entry, order, style, p, title, i == 1) end
      end
    end
  end
end

-- Dessine maintenant, ou à la fin du combat.
function MapPins:Update()
  if inCombat() then
    self.afterCombat = true
    return
  end
  self.afterCombat = false
  self:Refresh()
end

local pending = false
local function schedule()
  if inCombat() then
    MapPins.afterCombat = true
    return
  end
  if pending then return end
  pending = true
  Q:After(REFRESH_DELAY, function()
    pending = false
    MapPins:Update()
  end)
end
MapPins.Schedule = function() schedule() end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
for _, msg in ipairs({ "LOGIN", "PROGRESS_UPDATED", "STEP_CHANGED", "GUIDE_CHANGED", "ZONEMODE_CHANGED" }) do
  Q:On(msg, schedule)
end

-- Option coupée : tout est retiré tout de suite (même en combat, c'est sans calcul).
Q:On("SETTINGS_CHANGED", function(path)
  if path ~= "mapPins" then return end
  if enabled() then schedule() else MapPins:Clear() end
end)

Q:On("COMBAT_ENDED", function()
  if MapPins.afterCombat then schedule() end
end)
