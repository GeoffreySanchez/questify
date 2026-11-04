-- tests/wow_mock.lua
-- Simulation de l'API WoW Forever (famille Mainline 12.x, Interface 16001) pour les tests LuaJIT.
-- Définit la globale Mock. Chaque test commence par Mock.reset() (fait par tests/run.lua).
--
-- Résumé des points d'entrée :
--   Mock.reset()                         remet tout l'état à zéro (globales comprises)
--   Mock.loadAddon(toc, opts) -> Q       charge l'addon (TOC, Locales, Lua, Guides.xml)
--       opts.extraFiles = {chemins}      fichiers exécutés après le TOC, avant ADDON_LOADED
--       opts.beforeLogin = fn(Q)         appelé juste avant PLAYER_LOGIN
--       opts.qdb = {quests=, npcs=, objects=, items=, zones=}  fusionné sur la fixture de base
--       opts.savedVariables = {QuestifyDB=, QuestifyCharDB=}
--       opts.skipGuides = true         ne charge pas Guides\Guides.xml (guides livrés)
--   Mock.reload(opts) -> Q               simule /reload (conserve les SavedVariables)
--   Mock.fire(event, ...)                déclenche un évènement sur les frames inscrites
--   Mock.advance(seconds)                fait avancer C_Timer et appelle les OnUpdate
--   Mock.click(frame, button)            appelle le script OnClick
--   Mock.printed(s), Mock.countPrinted(s), Mock.prints
--   Mock.calls, Mock.callsTo(name), Mock.countCalls(name), Mock.lastCall(name)
--   Mock.errors                          erreurs non rattrapées + erreurs signalées par Q.SafeCall
--   Mock.missingFiles                    fichiers listés dans le TOC/XML mais absents
--   Mock.secret(v)                       crée une « valeur secrète » (issecretvalue -> true)
--   Mock.strictSecret(v)                 valeur secrète dont toute opération lève une erreur

Mock = Mock or {}
Mock.root = Mock.root or "."

local unpack = unpack or table.unpack
local floor = math.floor

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function deepcopy(v, seen)
  if type(v) ~= "table" then return v end
  seen = seen or {}
  if seen[v] then return seen[v] end
  local out = {}
  seen[v] = out
  for k, val in pairs(v) do out[deepcopy(k, seen)] = deepcopy(val, seen) end
  return out
end
Mock.deepcopy = deepcopy

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

local function normPath(p) return (p:gsub("\\", "/")) end
local function dirname(p) return p:match("^(.*)/[^/]*$") or "." end
local function rootPath(rel)
  rel = normPath(rel)
  if rel:sub(1, 1) == "/" then return rel end
  return Mock.root .. "/" .. rel
end

local function pushError(err)
  Mock.errors[#Mock.errors + 1] = tostring(err)
  if os.getenv("MOCK_VERBOSE") then io.stderr:write("[mock error] ", tostring(err), "\n") end
end
Mock.pushError = pushError

local function record(name, ...)
  local entry = { name = name, args = { ... }, n = select("#", ...) }
  entry[1] = name
  entry[2] = entry.args
  Mock.calls[#Mock.calls + 1] = entry
  return entry
end
Mock.record = record

function Mock.callsTo(name)
  local out = {}
  for _, c in ipairs(Mock.calls) do if c.name == name then out[#out + 1] = c end end
  return out
end
function Mock.countCalls(name) return #Mock.callsTo(name) end
function Mock.lastCall(name)
  local list = Mock.callsTo(name)
  return list[#list]
end

local function stripColors(s)
  return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function capture(line)
  Mock.prints[#Mock.prints + 1] = line
  if os.getenv("MOCK_PRINT") then io.stdout:write("[chat] ", line, "\n") end
end

function Mock.printed(substr)
  return Mock.countPrinted(substr) > 0
end
function Mock.countPrinted(substr)
  local n = 0
  for _, line in ipairs(Mock.prints) do
    if line:find(substr, 1, true) or stripColors(line):find(substr, 1, true) then n = n + 1 end
  end
  return n
end

-- Valeurs secrètes (restrictions Midnight)
local secrets = setmetatable({}, { __mode = "k" })
function Mock.secret(v)
  local s = setmetatable({ value = v }, { __tostring = function() return "<secret>" end })
  secrets[s] = true
  return s
end

-- Valeur secrète stricte : comme sur le client Midnight, toute opération dessus (comparaison
-- entre deux valeurs secrètes, concaténation, index, arithmétique, appel, tostring) lève une
-- erreur. Seul issecretvalue peut l'examiner. Lua 5.1 n'appelle __eq qu'entre deux tables qui
-- partagent la même métaméthode, d'où une métatable commune ; « v == nil » et type(v) ne
-- peuvent pas être interceptés.
local function refuseSecret() error("attempt to use a secret value", 2) end
local STRICT_SECRET_MT = {}
for _, k in ipairs({ "__eq", "__lt", "__le", "__concat", "__index", "__newindex", "__call", "__len",
  "__unm", "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__tostring" }) do
  STRICT_SECRET_MT[k] = refuseSecret
end
function Mock.strictSecret(v)
  local s = setmetatable({}, STRICT_SECRET_MT)
  rawset(s, "_secretValue", v)
  secrets[s] = true
  return s
end

---------------------------------------------------------------------------
-- Objets d'interface (frames) permissifs
---------------------------------------------------------------------------
local Object = {}
local ObjectMT = {}

-- Une clé inconnue commençant par une majuscule renvoie un objet enfant appelable
-- (méthode inconnue = no-op qui renvoie nil, enfant de modèle = frame factice).
-- Une clé inconnue en minuscule renvoie nil (champs personnalisés de l'addon).
ObjectMT.__index = function(self, k)
  local m = Object[k]
  if m ~= nil then return m end
  if type(k) == "string" and k:match("^%u") then
    local child = Mock.newObject("Frame", nil, nil)
    rawset(self, k, child)
    return child
  end
  return nil
end
ObjectMT.__call = function() return nil end
ObjectMT.__tostring = function(self) return "MockObject(" .. tostring(rawget(self, "_name") or rawget(self, "_type")) .. ")" end

local function isMock(o) return type(o) == "table" and getmetatable(o) == ObjectMT end
Mock.isMock = isMock

function Mock.newObject(objType, name, parent, template)
  local o = setmetatable({}, ObjectMT)
  rawset(o, "_type", objType or "Frame")
  rawset(o, "_scripts", {})
  rawset(o, "_attrs", {})
  rawset(o, "_events", {})
  rawset(o, "_shown", true)
  rawset(o, "_points", {})
  rawset(o, "_children", {})
  rawset(o, "_regions", {})
  rawset(o, "_alpha", 1)
  rawset(o, "_width", 0)
  rawset(o, "_height", 0)
  rawset(o, "_scale", 1)
  rawset(o, "_template", template)
  rawset(o, "_anims", {})
  if isMock(parent) then
    rawset(o, "_parent", parent)
    local list = rawget(parent, "_children")
    list[#list + 1] = o
  end
  if type(name) == "string" then
    if name:find("$parent", 1, true) then
      local pn = isMock(parent) and rawget(parent, "_name") or ""
      name = name:gsub("%$parent", pn)
    end
    rawset(o, "_name", name)
    _G[name] = o
  end
  return o
end

local function runScript(self, name, ...)
  local fn = self._scripts[name]
  if fn then
    local ok, err = pcall(fn, self, ...)
    if not ok then pushError(err) end
  end
end

function Object:GetName() return self._name end
function Object:GetObjectType() return self._type end
function Object:IsObjectType(t) return self._type == t end
function Object:GetParent() return self._parent end
function Object:SetParent(p) rawset(self, "_parent", p) end
function Object:GetDebugName() return self._name or self._type end

function Object:SetScript(name, fn) self._scripts[name] = fn end
function Object:GetScript(name) return self._scripts[name] end
function Object:HasScript() return true end
function Object:HookScript(name, fn)
  local old = self._scripts[name]
  self._scripts[name] = function(...)
    if old then old(...) end
    return fn(...)
  end
end

function Object:RegisterEvent(ev)
  if not self._events[ev] then
    self._events[ev] = true
    local list = Mock.eventFrames[ev]
    if not list then list = {}; Mock.eventFrames[ev] = list end
    list[#list + 1] = self
  end
end
function Object:RegisterUnitEvent(ev) return self:RegisterEvent(ev) end
function Object:UnregisterEvent(ev)
  self._events[ev] = nil
  local list = Mock.eventFrames[ev]
  if list then
    for i = #list, 1, -1 do if list[i] == self then table.remove(list, i) end end
  end
end
function Object:UnregisterAllEvents()
  for ev in pairs(self._events) do self:UnregisterEvent(ev) end
end
function Object:IsEventRegistered(ev) return self._events[ev] == true end

function Object:SetAttribute(k, v)
  self._attrs[k] = v
  runScript(self, "OnAttributeChanged", k, v)
end
function Object:GetAttribute(k) return self._attrs[k] end

function Object:Show()
  local was = self._shown
  rawset(self, "_shown", true)
  if not was then runScript(self, "OnShow") end
end
function Object:Hide()
  local was = self._shown
  rawset(self, "_shown", false)
  if was then runScript(self, "OnHide") end
end
function Object:SetShown(b) if b then self:Show() else self:Hide() end end
function Object:IsShown() return self._shown == true end
function Object:IsVisible()
  local o = self
  while isMock(o) do
    if rawget(o, "_shown") == false then return false end
    o = rawget(o, "_parent")
  end
  return true
end

function Object:SetPoint(...) local pts = self._points; pts[#pts + 1] = { ... } end
function Object:ClearAllPoints() rawset(self, "_points", {}) end
function Object:GetNumPoints() return #self._points end
function Object:GetPoint(i) local p = self._points[i or 1]; if p then return unpack(p) end end
function Object:SetAllPoints(rel) rawset(self, "_points", { { "TOPLEFT", rel }, { "BOTTOMRIGHT", rel } }) end

function Object:SetSize(w, h) rawset(self, "_width", w or 0); rawset(self, "_height", h or w or 0) end
function Object:GetSize() return self._width, self._height end
function Object:SetWidth(w) rawset(self, "_width", w or 0) end
function Object:GetWidth() return self._width end
function Object:SetHeight(h) rawset(self, "_height", h or 0) end
function Object:GetHeight() return self._height end
function Object:SetScale(s) rawset(self, "_scale", s or 1) end
function Object:GetScale() return self._scale end
function Object:GetEffectiveScale() return self._scale end
function Object:GetLeft() return 0 end
function Object:GetRight() return self._width end
function Object:GetTop() return 0 end
function Object:GetBottom() return 0 end
function Object:GetCenter() return 0, 0 end
function Object:GetFrameLevel() return self._level or 1 end
function Object:SetFrameLevel(l) rawset(self, "_level", l) end
function Object:GetFrameStrata() return self._strata or "MEDIUM" end
function Object:SetFrameStrata(s) rawset(self, "_strata", s) end
function Object:SetID(id) rawset(self, "_id", id) end
function Object:GetID() return self._id or 0 end

local function addRegion(self, kind, name, layer, template)
  local r = Mock.newObject(kind, name, self, template)
  rawset(r, "_layer", layer)
  local regs = self._regions
  regs[#regs + 1] = r
  return r
end
function Object:CreateFontString(name, layer, template) return addRegion(self, "FontString", name, layer, template) end
function Object:CreateTexture(name, layer, template) return addRegion(self, "Texture", name, layer, template) end
function Object:CreateMaskTexture(name, layer) return addRegion(self, "MaskTexture", name, layer) end
function Object:CreateLine(name, layer) return addRegion(self, "Line", name, layer) end
function Object:CreateAnimationGroup(name)
  local g = Mock.newObject("AnimationGroup", name, self)
  local list = self._anims
  list[#list + 1] = g
  return g
end
function Object:CreateAnimation(animType, name)
  local a = Mock.newObject(animType or "Animation", name, self)
  local list = self._anims
  list[#list + 1] = a
  return a
end
function Object:GetAnimations() return unpack(self._anims) end
function Object:Play() rawset(self, "_playing", true); runScript(self, "OnPlay") end
function Object:Stop() rawset(self, "_playing", false); runScript(self, "OnStop") end
function Object:Pause() rawset(self, "_playing", false) end
function Object:IsPlaying() return self._playing == true end
function Object:SetLooping(l) rawset(self, "_looping", l) end
function Object:GetLooping() return self._looping or "NONE" end
function Object:SetOffset(x, y) rawset(self, "_offset", { x, y }) end
function Object:GetOffset() local o = self._offset; if o then return o[1], o[2] end return 0, 0 end
function Object:SetDuration(d) rawset(self, "_duration", d) end
function Object:GetDuration() return self._duration or 0 end

function Object:SetText(t)
  if t ~= nil then t = tostring(t) end
  rawset(self, "_text", t)
end
function Object:GetText() return self._text end
function Object:SetFormattedText(fmt, ...) self:SetText(string.format(fmt, ...)) end
function Object:GetStringWidth() return #(self._text or "") * 6 end
function Object:GetStringHeight() return 12 end
function Object:SetTextColor(r, g, b, a) rawset(self, "_textColor", { r, g, b, a }) end
function Object:GetTextColor() local c = self._textColor or { 1, 1, 1, 1 }; return unpack(c) end
function Object:SetTexture(tex) rawset(self, "_texture", tex) end
function Object:GetTexture() return self._texture end
function Object:SetAtlas(a) rawset(self, "_atlas", a) end
function Object:GetAtlas() return self._atlas end
function Object:SetVertexColor(r, g, b, a) rawset(self, "_vertex", { r, g, b, a }) end
function Object:GetVertexColor() local c = self._vertex or { 1, 1, 1, 1 }; return unpack(c) end
function Object:SetAlpha(a) rawset(self, "_alpha", a) end
function Object:GetAlpha() return self._alpha end

function Object:Click(button, down) runScript(self, "OnClick", button or "LeftButton", down) end
function Object:SetChecked(b) rawset(self, "_checked", b and true or false) end
function Object:GetChecked() return self._checked == true end
function Object:SetValue(v) rawset(self, "_value", v); runScript(self, "OnValueChanged", v) end
function Object:GetValue() return self._value or 0 end
function Object:SetMinMaxValues(a, b) rawset(self, "_minmax", { a, b }) end
function Object:GetMinMaxValues() local m = self._minmax or { 0, 1 }; return m[1], m[2] end
function Object:Enable() rawset(self, "_disabled", false) end
function Object:Disable() rawset(self, "_disabled", true) end
function Object:SetEnabled(b) rawset(self, "_disabled", not b) end
function Object:IsEnabled() return self._disabled ~= true end
function Object:RegisterForClicks(...) rawset(self, "_clicks", { ... }) end
function Object:RegisterForDrag(...) rawset(self, "_drag", { ... }) end
function Object:EnableMouse(b) rawset(self, "_mouse", b ~= false) end
function Object:IsMouseEnabled() return self._mouse == true end
function Object:SetMovable(b) rawset(self, "_movable", b and true or false) end
function Object:IsMovable() return self._movable == true end
function Object:GetChildren() return unpack(self._children) end
function Object:GetNumChildren() return #self._children end
function Object:GetRegions() return unpack(self._regions) end
function Object:SetScrollChild(c) rawset(self, "_scrollChild", c) end
function Object:GetScrollChild() return self._scrollChild end
function Object:SetCreature(id) rawset(self, "_creature", id) end
function Object:GetCreature() return self._creature end
function Object:GetModelFileID()
  local id = self._creature
  if id and Mock.modelFileIDs then return Mock.modelFileIDs[id] end
  return nil
end
function Object:ClearModel() rawset(self, "_creature", nil) end
function Object:AddMessage(msg) capture(tostring(msg)) end

-- Fonction publique pour les tests : clic sur un bouton
function Mock.click(frame, button, down)
  if isMock(frame) then frame:Click(button, down) end
end

---------------------------------------------------------------------------
-- Données de base
---------------------------------------------------------------------------
local RACES = {
  [1] = { "Human", "Human" }, [2] = { "Orc", "Orc" }, [3] = { "Dwarf", "Dwarf" },
  [4] = { "Night Elf", "NightElf" }, [5] = { "Undead", "Scourge" }, [6] = { "Tauren", "Tauren" },
  [7] = { "Gnome", "Gnome" }, [8] = { "Troll", "Troll" },
  [95] = { "Skyborne", "Skyborne" }, [96] = { "Skyborne", "Skyborne" },
}
local CLASSES = {
  WARRIOR = { "Warrior", 1 }, PALADIN = { "Paladin", 2 }, HUNTER = { "Hunter", 3 }, ROGUE = { "Rogue", 4 },
  PRIEST = { "Priest", 5 }, SHAMAN = { "Shaman", 7 }, MAGE = { "Mage", 8 }, WARLOCK = { "Warlock", 9 },
  DRUID = { "Druid", 11 },
}

-- Géométrie linéaire des cartes, avec les axes du client : X monde croît vers le nord, Y monde
-- vers l'ouest, alors que x carte croît vers l'est et y carte vers le sud.
-- top / left = X / Y monde du coin haut-gauche ; width (est-ouest) et height (nord-sud) en yards.
-- monde = (top - y * height, left - x * width), x et y en 0-1.
local function defaultMaps()
  return {
    [1426] = { name = "Dun Morogh", continent = 0, left = 0, top = 0, width = 4925, height = 3283, parent = 1415 },
    [1455] = { name = "Ironforge", continent = 0, left = 2300, top = 700, width = 790, height = 527, parent = 1415 },
    [1432] = { name = "Loch Modan", continent = 0, left = 4700, top = -300, width = 2758, height = 1839, parent = 1415 },
    [1437] = { name = "Wetlands", continent = 0, left = 3800, top = -3500, width = 4135, height = 2756, parent = 1415 },
    [1429] = { name = "Elwynn Forest", continent = 0, left = -2000, top = 9000, width = 3470, height = 2314, parent = 1415 },
    [1453] = { name = "Stormwind City", continent = 0, left = -2300, top = 8000, width = 1737, height = 1158, parent = 1415 },
    [1436] = { name = "Westfall", continent = 0, left = -3500, top = 11000, width = 3500, height = 2333, parent = 1415 },
    [1415] = { name = "Eastern Kingdoms", continent = 0, left = -20000, top = -20000, width = 40000, height = 40000 },
    [1411] = { name = "Durotar", continent = 1, left = 0, top = 0, width = 5287, height = 3525, parent = 1414 },
    [1438] = { name = "Teldrassil", continent = 1, left = -4000, top = -9000, width = 5091, height = 3393, parent = 1414 },
    [1414] = { name = "Kalimdor", continent = 1, left = -20000, top = -20000, width = 40000, height = 40000 },
  }
end

---------------------------------------------------------------------------
-- QuestieDB factice (sémantique de docs/api.md : 0 pour les nombres, copies de tables…)
---------------------------------------------------------------------------
local QDB_META = {
  Quest = {
    names = { "name", "startedBy", "finishedBy", "requiredLevel", "questLevel", "requiredRaces", "requiredClasses",
      "objectivesText", "triggerEnd", "objectives", "sourceItemId", "preQuestGroup", "preQuestSingle", "childQuests",
      "inGroupWith", "exclusiveTo", "zoneOrSort", "requiredSkill", "requiredMinRep", "requiredMaxRep",
      "requiredSourceItems", "nextQuestInChain", "questFlags", "specialFlags", "parentQuest", "reputationReward",
      "breadcrumbForQuestId", "breadcrumbs", "extraObjectives", "requiredSpell", "requiredSpecialization",
      "requiredMaxLevel", "availableUntilCompleted", "availableStartingWith", "requiredRanks", "disabledByQuest" },
    types = { "string", "table", "table", "number", "number", "number", "number", "table", "table", "table", "number",
      "table", "table", "table", "table", "table", "number", "table", "table", "table", "table", "number", "number",
      "number", "number", "table", "number", "table", "table", "number", "number", "number", "number", "number",
      "table", "number" },
    neverNil = { startedBy = true, finishedBy = true, objectives = true },
    zeroPair = { requiredSkill = true, requiredMinRep = true, requiredMaxRep = true },
  },
  Npc = {
    names = { "name", "minLevelHealth", "maxLevelHealth", "minLevel", "maxLevel", "rank", "spawns", "waypoints", "zoneID",
      "questStarts", "questEnds", "factionID", "friendlyToFaction", "subName", "npcFlags" },
    types = { "string", "number", "number", "number", "number", "number", "table", "table", "number", "table", "table",
      "number", "string", "string", "number" },
    placeholder = { minLevelHealth = 0, maxLevelHealth = 1 },
  },
  Object = {
    names = { "name", "questStarts", "questEnds", "spawns", "zoneID", "factionID", "waypoints" },
    types = { "string", "table", "table", "table", "number", "number", "table" },
  },
  Item = {
    names = { "name", "npcDrops", "objectDrops", "itemDrops", "startQuest", "questRewards", "flags", "foodType",
      "itemLevel", "requiredLevel", "ammoType", "class", "subClass", "vendors", "relatedQuests", "teachesSpell" },
    types = { "string", "table", "table", "table", "number", "table", "number", "number", "number", "number", "number",
      "number", "number", "table", "table", "number" },
  },
}
for _, meta in pairs(QDB_META) do
  meta.keys = {}
  for i, n in ipairs(meta.names) do meta.keys[n] = i end
end

-- Convertit une ligne de fixture (champs nommés ou positionnels) en champs nommés.
local function normalizeRow(meta, row)
  local out = {}
  for k, v in pairs(row) do
    if type(k) == "number" then
      local n = meta.names[k]
      if n then out[n] = v end
    else
      out[k] = v
    end
  end
  return out
end

local function makeEntity(kind, rows)
  local meta = QDB_META[kind]
  local E = {}
  local function fieldName(key)
    if type(key) == "number" then return meta.names[key] end
    if type(key) == "string" and meta.keys[key] then return key end
    return nil
  end
  local function read(id, key)
    if type(id) ~= "number" then return nil end
    local row = rows[id]
    if row == nil then return nil end
    local f = fieldName(key)
    if not f then return nil end
    if meta.placeholder and meta.placeholder[f] ~= nil then return meta.placeholder[f] end
    local v = row[f]
    local t = meta.types[meta.keys[f]]
    if t == "number" then
      if type(v) == "number" then return v end
      return 0
    elseif t == "string" then
      return v
    end
    if type(v) ~= "table" or next(v) == nil then
      if meta.neverNil and meta.neverNil[f] then return {} end
      return nil
    end
    if meta.zeroPair and meta.zeroPair[f] and v[1] == 0 and v[2] == 0 then return nil end
    return deepcopy(v)
  end
  E.Get = read
  E.GetRaw = read
  function E.GetAll(id, keys)
    if type(id) ~= "number" or rows[id] == nil or type(keys) ~= "table" then return nil end
    local out = { n = #keys }
    for i, k in ipairs(keys) do out[i] = read(id, k) end
    return out
  end
  function E.Exists(id) return type(id) == "number" and rows[id] ~= nil end
  function E.GetAllIds(hashmap)
    local ids = {}
    for id in pairs(rows) do ids[#ids + 1] = id end
    table.sort(ids)
    if hashmap then
      local map = {}
      for _, id in ipairs(ids) do map[id] = true end
      return map
    end
    return ids
  end
  function E.IdsByName(name)
    local out = {}
    for id, row in pairs(rows) do if row.name == name then out[#out + 1] = id end end
    if #out == 0 then return nil end
    table.sort(out)
    return out
  end
  function E.BuildNameIndex() end
  for _, n in ipairs(meta.names) do
    E[n] = function(id) return read(id, n) end
  end
  return E
end

local function serializeMap(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  local parts = { "return {" }
  for _, k in ipairs(keys) do parts[#parts + 1] = string.format("  [%d] = %d,", k, t[k]) end
  parts[#parts + 1] = "}"
  return table.concat(parts, "\n")
end

local function loadFixture(extra)
  local path = rootPath("tests/fixtures/qdb_fixture.lua")
  local chunk = assert(loadfile(path))
  local base = chunk()
  local data = { quests = {}, npcs = {}, objects = {}, items = {}, zones = {} }
  local kinds = { quests = "Quest", npcs = "Npc", objects = "Object", items = "Item" }
  for section, kind in pairs(kinds) do
    for id, row in pairs(base[section] or {}) do data[section][id] = normalizeRow(QDB_META[kind], row) end
  end
  for name, map in pairs(base.zones or {}) do data.zones[name] = deepcopy(map) end
  if extra then
    for section, kind in pairs(kinds) do
      for id, row in pairs(extra[section] or {}) do
        local merged = data[section][id] or {}
        for k, v in pairs(normalizeRow(QDB_META[kind], row)) do merged[k] = deepcopy(v) end
        data[section][id] = merged
      end
    end
    for name, map in pairs(extra.zones or {}) do
      data.zones[name] = data.zones[name] or {}
      for k, v in pairs(map) do data.zones[name][k] = v end
    end
  end
  return data
end

local function installQuestieDB(extra)
  local data = loadFixture(extra)
  Mock.qdbData = data
  local Quest = makeEntity("Quest", data.quests)
  local Npc = makeEntity("Npc", data.npcs)
  local Obj = makeEntity("Object", data.objects)
  local Item = makeEntity("Item", data.items)
  local private = {}
  for name, map in pairs(data.zones) do private[name] = serializeMap(map) end
  local zoneDB = { private = private, zoneIDs = { DUN_MOROGH = 1, ELWYNN_FOREST = 12, LOCH_MODAN = 38 } }
  local contract = Mock.qdbContract
  local lib = {
    contractVersion = contract,
    minSupportedContract = 1,
    readMode = "baked",
    Quest = Quest, Npc = Npc, Object = Obj, Item = Item,
    Meta = {
      QuestMeta = { questKeys = QDB_META.Quest.keys },
      NpcMeta = { npcKeys = QDB_META.Npc.keys },
      ObjectMeta = { objectKeys = QDB_META.Object.keys },
      ItemMeta = { itemKeys = QDB_META.Item.keys },
      Quest = { names = QDB_META.Quest.names, types = QDB_META.Quest.types, fieldCount = #QDB_META.Quest.names },
      Npc = { names = QDB_META.Npc.names, types = QDB_META.Npc.types, fieldCount = #QDB_META.Npc.names },
      Object = { names = QDB_META.Object.names, types = QDB_META.Object.types, fieldCount = #QDB_META.Object.names },
      Item = { names = QDB_META.Item.names, types = QDB_META.Item.types, fieldCount = #QDB_META.Item.names },
    },
    Support = {},
    Enum = {
      raceMaskById = { [1] = 1, [2] = 2, [3] = 4, [4] = 8, [5] = 16, [6] = 32, [7] = 64, [8] = 128,
        [95] = 4294967296, [96] = 8589934592 },
      factionRaceMasks = { Alliance = 4294967373, Horde = 8589934770 },
      classKeys = { WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16, SHAMAN = 64, MAGE = 128,
        WARLOCK = 256, DRUID = 1024, ALL_CLASSES = 1535 },
      npcFlags = { VENDOR = 128, FLIGHT_MASTER = 8192, INNKEEPER = 65536 },
    },
    l10n = {
      currentLocale = "enUS",
      IsAvailable = function() return false end,
      SetLocale = function() end,
    },
  }
  function lib.RequireContract(v)
    if type(v) ~= "number" or v ~= v or v == math.huge or v < 1 or floor(v) ~= v then
      return false, "QuestieDB: invalid contract requirement"
    end
    if v >= lib.minSupportedContract and v <= lib.contractVersion then return true end
    return false, string.format("QuestieDB: contract %d required, this QuestieDB supports %d-%d", v,
      lib.minSupportedContract, lib.contractVersion)
  end
  function lib.Support.Get(name)
    if name == "ZoneDB" then return zoneDB end
    return nil
  end
  function lib.Support.GetAll() return { ZoneDB = zoneDB } end
  function lib.InvalidateCache() end
  LibQuestieDB = lib
  QuestDB, NpcDB, ObjectDB, ItemDB = Quest, Npc, Obj, Item
end

---------------------------------------------------------------------------
-- Addons de navigation factices (selon Mock.addons)
---------------------------------------------------------------------------
local function installNavAddons()
  if Mock.addons.TomTom then
    local nextUid = 0
    TomTom = {
      AddWaypoint = function(self, map, x, y, opts)
        record("TomTom:AddWaypoint", map, x, y, opts)
        nextUid = nextUid + 1
        return { uid = nextUid, map, x, y, title = opts and opts.title }
      end,
      RemoveWaypoint = function(self, uid) record("TomTom:RemoveWaypoint", uid) end,
    }
  end
  if Mock.addons.WaypointUI then
    WaypointUIAPI = {
      Navigation = {
        NewUserNavigation = function(t) record("WaypointUIAPI.Navigation.NewUserNavigation", t) end,
        ClearUserNavigation = function() record("WaypointUIAPI.Navigation.ClearUserNavigation") end,
      },
    }
  end
  if Mock.addons.ShortestPathForever then
    ShortestPathForever = {
      API = {
        Navigate = function(owner, map, x, y, title, kind)
          record("ShortestPathForever.API.Navigate", owner, map, x, y, title, kind)
          return Mock.navigateResult
        end,
        NavigateRoute = function(owner, points)
          record("ShortestPathForever.API.NavigateRoute", owner, points)
          return Mock.navigateResult
        end,
        Cancel = function(owner) record("ShortestPathForever.API.Cancel", owner) end,
      },
    }
  end
end

---------------------------------------------------------------------------
-- Minuteurs
---------------------------------------------------------------------------
local timerSeq = 0
local function addTimer(delay, fn, interval, iterations, handle)
  timerSeq = timerSeq + 1
  local t = { due = Mock.now + math.max(delay or 0, 0), fn = fn, interval = interval, left = iterations,
    handle = handle, seq = timerSeq }
  Mock.timers[#Mock.timers + 1] = t
  return t
end

local function newHandle()
  local h = { _cancelled = false }
  function h:Cancel() self._cancelled = true end
  function h:IsCancelled() return self._cancelled end
  return h
end

function Mock.advance(seconds)
  local target = Mock.now + (seconds or 0)
  local guard = 0
  while true do
    guard = guard + 1
    if guard > 100000 then pushError("Mock.advance: too many timers"); break end
    local best, bestIdx
    for i, t in ipairs(Mock.timers) do
      if t.due <= target + 1e-9 and (not best or t.due < best.due or (t.due == best.due and t.seq < best.seq)) then
        best, bestIdx = t, i
      end
    end
    if not best then break end
    table.remove(Mock.timers, bestIdx)
    if not (best.handle and best.handle._cancelled) then
      if best.due > Mock.now then Mock.now = best.due end
      local ok, err
      if best.handle then ok, err = pcall(best.fn, best.handle) else ok, err = pcall(best.fn) end
      if not ok then pushError(err) end
      if best.interval and not (best.handle and best.handle._cancelled) then
        local left = best.left and (best.left - 1) or nil
        if left == nil or left > 0 then
          local nt = addTimer(best.interval, best.fn, best.interval, left, best.handle)
          nt.due = best.due + best.interval
        end
      end
    end
  end
  Mock.now = target
  local frames = {}
  for _, f in ipairs(Mock.frames) do frames[#frames + 1] = f end
  for _, f in ipairs(frames) do
    if f._scripts.OnUpdate and f:IsVisible() then runScript(f, "OnUpdate", seconds or 0) end
  end
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
function Mock.fire(event, ...)
  local list = Mock.eventFrames[event]
  if not list then return end
  local copy = {}
  for i, f in ipairs(list) do copy[i] = f end
  for _, f in ipairs(copy) do
    if f._events[event] then
      local s = f._scripts.OnEvent
      if s then
        local ok, err = pcall(s, f, event, ...)
        if not ok then pushError(err) end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Installation de l'API WoW
---------------------------------------------------------------------------
local function sortedLogIds()
  local ids = {}
  for id in pairs(Mock.quests.log) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

local function vector(x, y)
  return { x = x, y = y, GetXY = function(self) return self.x, self.y end }
end

local function itemInfo(item)
  local info = Mock.items[item]
  if not info and type(item) == "string" then
    local id = tonumber(item:match("item:(%d+)"))
    info = id and Mock.items[id]
  end
  return info
end

---------------------------------------------------------------------------
-- Bibliothèques embarquées (Libs\ : LibStub, CallbackHandler-1.0, HereBeDragons-2.0 et -Pins-2.0) :
-- le strict nécessaire pour qu'elles se chargent et tournent sans erreur dans chaque test.
-- Carte du monde réduite au MapCanvas (fournisseurs de données, réserves de repères), minicarte
-- avec zoom et rayon de vue, position monde du joueur (UnitPosition) calculée comme
-- C_Map.GetWorldPosFromMapPos.
--   WorldMapFrame:SetMapID(id)   affiche une carte : les fournisseurs redessinent leurs repères
--   Mock.callsTo("WorldMapFrame:AcquirePin")   repères posés sur la carte du monde
---------------------------------------------------------------------------
local function newPool(createFunc, resetFunc)
  local pool = { active = {}, inactive = {}, createFunc = createFunc, resetFunc = resetFunc }
  function pool:Acquire()
    local obj = table.remove(self.inactive)
    local new = false
    if not obj then
      obj = self.createFunc(self)
      new = true
    end
    self.active[obj] = true
    return obj, new
  end
  function pool:Release(obj)
    if not self.active[obj] then return false end
    self.active[obj] = nil
    if self.resetFunc then self.resetFunc(self, obj) end
    self.inactive[#self.inactive + 1] = obj
    return true
  end
  function pool:ReleaseAll()
    for obj in pairs(self.active) do self:Release(obj) end
  end
  function pool:EnumerateActive() return pairs(self.active) end
  function pool:GetNumActive()
    local n = 0
    for _ in pairs(self.active) do n = n + 1 end
    return n
  end
  return pool
end

local function newWorldMap()
  local map = Mock.newObject("Frame", "WorldMapFrame", UIParent)
  rawset(map, "_shown", false)   -- fermée, comme en jeu
  local canvas = Mock.newObject("Frame", "WorldMapFrameCanvas", map)
  rawset(map, "pinPools", {})
  rawset(map, "dataProviders", {})
  rawset(map, "GetCanvas", function() return canvas end)
  rawset(map, "GetMapID", function(self) return rawget(self, "_mapID") end)
  rawset(map, "SetMapID", function(self, id)
    rawset(self, "_mapID", id)
    for p in pairs(self.dataProviders) do
      if p.OnMapChanged then p:OnMapChanged() end
    end
  end)
  rawset(map, "AddDataProvider", function(self, p)
    self.dataProviders[p] = true
    p:OnAdded(self)
  end)
  rawset(map, "RemoveDataProvider", function(self, p)
    p:RemoveAllData()
    self.dataProviders[p] = nil
    p:OnRemoved(self)
  end)
  rawset(map, "AcquirePin", function(self, template, ...)
    local pool = self.pinPools[template]
    if not pool then
      pool = newPool(function() return CreateFrame("Frame", nil, canvas) end)
      self.pinPools[template] = pool
    end
    local pin, new = pool:Acquire()
    pin.pinTemplate = template
    pin.owningMap = self
    if new and pin.OnLoad then pin:OnLoad() end
    pin:Show()
    if pin.OnAcquired then pin:OnAcquired(...) end
    record("WorldMapFrame:AcquirePin", template, ...)
    return pin
  end)
  rawset(map, "RemovePin", function(self, pin)
    local pool = self.pinPools[pin.pinTemplate]
    if pool then pool:Release(pin) end
  end)
  rawset(map, "RemoveAllPinsByTemplate", function(self, template)
    local pool = self.pinPools[template]
    if pool then pool:ReleaseAll() end
  end)
  rawset(map, "EnumeratePinsByTemplate", function(self, template)
    local pool = self.pinPools[template]
    if pool then return pool:EnumerateActive() end
    return function() end
  end)
  rawset(map, "GetNumActivePinsByTemplate", function(self, template)
    local pool = self.pinPools[template]
    return pool and pool:GetNumActive() or 0
  end)
  return map
end

function Mock.installMapLibsApi(P)
  local cvars = { rotateMinimap = "0", minimapZoom = "0", minimapInsideZoom = "0" }
  securecallfunction = function(fn, ...) return fn(...) end
  IsLoggedIn = function() return false end   -- les fichiers de l'addon se chargent avant PLAYER_LOGIN
  GetCVar = function(name) return cvars[name] end
  GetPlayerFacing = function() return 0 end
  -- Position monde : X vers le nord, Y vers l'ouest, puis z et l'instance (continent).
  UnitPosition = function(unit)
    if unit ~= "player" or P().instance or not P().x or not P().y then return nil end
    local m = Mock.maps[P().map]
    if not m then return nil end
    return m.top - (P().y / 100) * m.height, m.left - (P().x / 100) * m.width, 0, m.continent
  end
  C_Minimap = { GetViewRadius = function() return 233 end }
  rawset(Minimap, "GetZoom", function() return 0 end)
  rawset(Minimap, "SetZoom", function() end)
  C_Map.GetMapChildrenInfo = function(mapID)
    local out = {}
    for id, m in pairs(Mock.maps) do
      if m.parent == mapID then
        out[#out + 1] = { mapID = id, name = m.name, mapType = m.parent and 3 or 2, parentMapID = m.parent or 0 }
      end
    end
    table.sort(out, function(a, b) return a.mapID < b.mapID end)
    return out
  end
  C_Map.GetMapGroupID = function() return nil end
  C_Map.GetMapGroupMembersInfo = function() return nil end
  C_Map.GetMapRectOnMap = function() return nil end

  MapCanvasDataProviderMixin = {
    OnAdded = function(self, map) self.owningMap = map end,
    OnRemoved = function(self) self.owningMap = nil end,
    GetMap = function(self) return self.owningMap end,
    RemoveAllData = function() end,
    RefreshAllData = function() end,
    OnShow = function() end,
    OnHide = function() end,
    OnMapChanged = function(self) self:RefreshAllData() end,
  }
  MapCanvasPinMixin = {
    OnLoad = function() end,
    OnAcquired = function() end,
    OnReleased = function() end,
    GetMap = function(self) return self.owningMap end,
    SetPosition = function(self, x, y) self.normalizedX, self.normalizedY = x, y end,
    GetPosition = function(self) return self.normalizedX, self.normalizedY end,
    UseFrameLevelType = function(self, t) self.pinFrameLevelType = t end,
    SetScalingLimits = function() end,
  }
  CreateUnsecuredRegionPoolInstance = function(_, createFunc, resetFunc)
    return newPool(createFunc, resetFunc)
  end
  WorldMapFrame = newWorldMap()
end

local function installApi()
  local P = function() return Mock.player end

  -- Lua / utilitaires WoW
  print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    capture(table.concat(parts, " "))
  end
  wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  tinsert, tremove = table.insert, table.remove
  format, strfind, strsub, strlen, strlower, strupper, strrep, strmatch, gsub, gmatch, strbyte, strchar =
    string.format, string.find, string.sub, string.len, string.lower, string.upper, string.rep, string.match,
    string.gsub, string.gmatch, string.byte, string.char
  floor, ceil, abs, max, min, sqrt, mod = math.floor, math.ceil, math.abs, math.max, math.min, math.sqrt, math.fmod
  strtrim = function(s, chars)
    chars = chars and ("[" .. chars:gsub("%p", "%%%0") .. "]") or "%s"
    return (s:gsub("^" .. chars .. "+", ""):gsub(chars .. "+$", ""))
  end
  strsplit = function(sep, s, limit)
    local out, start = {}, 1
    while true do
      if limit and #out == limit - 1 then out[#out + 1] = s:sub(start); break end
      local i, j = s:find(sep, start, true)
      if not i then out[#out + 1] = s:sub(start); break end
      out[#out + 1] = s:sub(start, i - 1)
      start = j + 1
    end
    return unpack(out)
  end
  strjoin = function(sep, ...) return table.concat({ ... }, sep) end
  tContains = function(t, v) for _, x in pairs(t) do if x == v then return true end end return false end
  CopyTable = function(t) return deepcopy(t) end
  Mixin = function(obj, ...)
    for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do obj[k] = v end end
    return obj
  end
  CreateFromMixins = function(...) return Mixin({}, ...) end
  debugstack = function() return debug.traceback("", 2) end
  geterrorhandler = function() return function(err) pushError(err) end end
  seterrorhandler = function() end
  securecall = function(fn, ...) return fn(...) end
  hooksecurefunc = function(a, b, c)
    local tbl, name, fn = _G, a, b
    if type(a) == "table" then tbl, name, fn = a, b, c end
    local old = tbl[name]
    tbl[name] = function(...)
      local r = { old(...) }
      fn(...)
      return unpack(r)
    end
  end
  issecretvalue = function(v) return secrets[v] == true end
  canaccessvalue = function(v) return secrets[v] ~= true end
  GetTime = function() return Mock.now end
  time = function() return 1762300800 + floor(Mock.now) end
  date = os.date
  GetLocale = function() return Mock.locale end
  GetBuildInfo = function() return "1.60.1", "70291", "Oct 30 2026", Mock.interface end
  GetRealmName = function() return "Testrealm" end
  GetCursorPosition = function() return 0, 0 end
  GetScreenWidth = function() return 1920 end
  GetScreenHeight = function() return 1080 end
  PlaySound = function(id) record("PlaySound", id) end
  SOUNDKIT = setmetatable({}, { __index = function(_, k) return k end })
  RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { r = 1, g = 1, b = 1, colorStr = "ffffffff" } end })
  NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
  HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }
  GRAY_FONT_COLOR = { r = 0.5, g = 0.5, b = 0.5 }
  ITEM_MOD_STRENGTH_SHORT, ITEM_MOD_AGILITY_SHORT, ITEM_MOD_STAMINA_SHORT = "Strength", "Agility", "Stamina"
  ITEM_MOD_INTELLECT_SHORT, ITEM_MOD_SPIRIT_SHORT = "Intellect", "Spirit"
  ITEM_MOD_DAMAGE_PER_SECOND_SHORT, RESISTANCE0_NAME = "Damage Per Second", "Armor"
  SlashCmdList = {}
  -- Fonctions utilitaires de l'interface Blizzard (sans effet dans les tests)
  local noop = function() end
  ButtonFrameTemplate_HidePortrait, ButtonFrameTemplate_HideAttic, ButtonFrameTemplate_HideButtonBar = noop, noop, noop
  PanelTemplates_SetNumTabs, PanelTemplates_SetTab, PanelTemplates_TabResize, PanelTemplates_UpdateTabs =
    noop, noop, noop, noop
  SetPortraitToTexture, CloseDropDownMenus, GameTooltip_Hide = noop, noop, noop
  IsInGroup = function() return false end
  GetNumGroupMembers = function() return 0 end
  Settings = {
    RegisterCanvasLayoutCategory = function(frame, name)
      record("Settings.RegisterCanvasLayoutCategory", frame, name)
      return { ID = name, GetID = function(self) return self.ID end }
    end,
    RegisterAddOnCategory = function(cat) record("Settings.RegisterAddOnCategory", cat) end,
    OpenToCategory = function(id) record("Settings.OpenToCategory", id) end,
  }
  StaticPopupDialogs = {}
  StaticPopup_Show = function(name, ...) record("StaticPopup_Show", name, ...); return Mock.newObject("Frame") end
  StaticPopup_Hide = function(name) record("StaticPopup_Hide", name) end
  UISpecialFrames = {}

  -- Frames globales
  CreateFrame = function(frameType, name, parent, template, id)
    local f = Mock.newObject(frameType or "Frame", name, parent, template)
    if id then f:SetID(id) end
    Mock.frames[#Mock.frames + 1] = f
    return f
  end
  UIParent = Mock.newObject("Frame", "UIParent")
  WorldFrame = Mock.newObject("Frame", "WorldFrame")
  Minimap = Mock.newObject("Minimap", "Minimap", UIParent)
  MinimapCluster = Mock.newObject("Frame", "MinimapCluster", UIParent)
  GameTooltip = Mock.newObject("GameTooltip", "GameTooltip", UIParent)
  DEFAULT_CHAT_FRAME = Mock.newObject("ScrollingMessageFrame", "DEFAULT_CHAT_FRAME", UIParent)
  ChatFrame1 = DEFAULT_CHAT_FRAME

  -- Personnage
  UnitRace = function(unit)
    if unit ~= "player" then local u = Mock.units[unit]; return u and u.race, u and u.race, u and u.raceId end
    local r = RACES[P().raceId] or { "Unknown", "Unknown" }
    return r[1], r[2], P().raceId
  end
  UnitClass = function(unit)
    local cf = P().classFile
    if unit ~= "player" then local u = Mock.units[unit]; cf = u and u.classFile end
    local c = cf and CLASSES[cf]
    if not c then return nil end
    return c[1], cf, c[2]
  end
  UnitLevel = function(unit)
    if unit == "player" then return P().level end
    local u = Mock.units[unit]
    return u and u.level or 0
  end
  UnitFactionGroup = function(unit)
    if unit == "player" then return P().faction, P().faction end
    local u = Mock.units[unit]
    return u and u.faction, u and u.faction
  end
  UnitName = function(unit)
    if unit == "player" then return P().name end
    local u = Mock.units[unit]
    return u and u.name
  end
  UnitGUID = function(unit)
    if unit == "player" then return "Player-1-00000001" end
    local u = Mock.units[unit]
    return u and u.guid
  end
  UnitCreatureID = function(unit)
    local u = Mock.units[unit]
    return u and u.npcId
  end
  UnitExists = function(unit) return unit == "player" or Mock.units[unit] ~= nil end
  UnitIsDead = function(unit) local u = Mock.units[unit]; return u and u.dead or false end
  UnitCanAttack = function(_, unit) local u = Mock.units[unit]; return u and u.hostile ~= false end
  UnitIsPlayer = function(unit) return unit == "player" end
  UnitAffectingCombat = function(unit) return unit == "player" and P().combat end
  InCombatLockdown = function() return P().combat == true end
  IsShiftKeyDown = function() return P().shift == true end
  IsControlKeyDown = function() return P().ctrl == true end
  IsAltKeyDown = function() return P().alt == true end
  GetBindLocation = function() return P().bind or "Coldridge Valley" end
  IsInInstance = function() return P().instance == true, P().instance and "party" or "none" end

  -- Addons
  C_AddOns = {
    IsAddOnLoaded = function(name)
      if name == "Questify" then return true, true end
      local v = Mock.addons[name] == true
      return v, v
    end,
    GetAddOnMetadata = function(name, field)
      if name == "Questify" then return Mock.tocMeta[field] end
      return nil
    end,
    GetNumAddOns = function() return 0 end,
    LoadAddOn = function(name) return Mock.addons[name] == true end,
  }

  -- Minuteurs
  C_Timer = {
    After = function(delay, fn) addTimer(delay, fn) end,
    NewTimer = function(delay, fn)
      local h = newHandle()
      addTimer(delay, fn, nil, nil, h)
      return h
    end,
    NewTicker = function(interval, fn, iterations)
      local h = newHandle()
      addTimer(interval, fn, interval, iterations, h)
      return h
    end,
  }

  -- Journal de quêtes
  C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return Mock.quests.completed[id] == true end,
    GetAllCompletedQuestIDs = function()
      local ids = {}
      for id, v in pairs(Mock.quests.completed) do if v then ids[#ids + 1] = id end end
      table.sort(ids)
      return ids
    end,
    GetNumQuestLogEntries = function() local n = #sortedLogIds(); return n, n end,
    GetInfo = function(i)
      local id = sortedLogIds()[i]
      if not id then return nil end
      local q = Mock.quests.log[id]
      return { questID = id, title = q.title or Mock.titles[id], isHeader = false, level = q.level,
        isComplete = q.complete and 1 or nil, questLogIndex = i }
    end,
    GetLogIndexForQuestID = function(id)
      for i, qid in ipairs(sortedLogIds()) do if qid == id then return i end end
      return nil
    end,
    GetQuestIDForLogIndex = function(i) return sortedLogIds()[i] end,
    IsComplete = function(id) local q = Mock.quests.log[id]; return q ~= nil and q.complete == true end,
    ReadyForTurnIn = function(id) local q = Mock.quests.log[id]; return q ~= nil and q.complete == true end,
    GetQuestObjectives = function(id)
      local q = Mock.quests.log[id]
      local out = {}
      if q and q.objectives then
        for i, o in ipairs(q.objectives) do
          out[i] = { text = o.text, type = o.type or "monster", finished = o.finished == true,
            numFulfilled = o.numFulfilled or (o.finished and 1 or 0), numRequired = o.numRequired or 1 }
        end
      end
      return out
    end,
    GetTitleForQuestID = function(id)
      local q = Mock.quests.log[id]
      return (q and q.title) or Mock.titles[id]
    end,
    GetQuestTagInfo = function() return nil end,
    GetSelectedQuest = function() return nil end,
  }

  -- PNJ de quêtes, gossip
  AcceptQuest = function() record("AcceptQuest") end
  CompleteQuest = function() record("CompleteQuest") end
  GetQuestReward = function(i) record("GetQuestReward", i) end
  DeclineQuest = function() record("DeclineQuest") end
  GetQuestID = function() return Mock.questFrame.questId or 0 end
  GetNumQuestChoices = function() return Mock.questFrame.numChoices or #Mock.questFrame.choices end
  GetNumQuestRewards = function() return Mock.questFrame.numRewards or 0 end
  IsQuestCompletable = function() return Mock.questFrame.completable == true end
  GetQuestItemLink = function(kind, i)
    if kind == "choice" then local c = Mock.questFrame.choices[i]; return c and (c.link or c) end
    return nil
  end
  GetNumActiveQuests = function() return #Mock.greeting.active end
  GetActiveQuestID = function(i) local q = Mock.greeting.active[i]; return q and q.questID end
  GetActiveTitle = function(i) local q = Mock.greeting.active[i]; return q and q.title, q and q.isComplete end
  SelectActiveQuest = function(i) record("SelectActiveQuest", i) end
  GetNumAvailableQuests = function() return #Mock.greeting.available end
  GetAvailableQuestInfo = function(i)
    local q = Mock.greeting.available[i]
    if not q then return nil end
    return q.isTrivial or false, q.frequency or 0, q.isRepeatable or false, q.isLegendary or false, q.questID
  end
  GetAvailableTitle = function(i) local q = Mock.greeting.available[i]; return q and q.title end
  SelectAvailableQuest = function(i) record("SelectAvailableQuest", i) end
  C_GossipInfo = {
    GetAvailableQuests = function() return deepcopy(Mock.gossip.available) end,
    GetActiveQuests = function() return deepcopy(Mock.gossip.active) end,
    GetNumAvailableQuests = function() return #Mock.gossip.available end,
    GetNumActiveQuests = function() return #Mock.gossip.active end,
    SelectAvailableQuest = function(id) record("C_GossipInfo.SelectAvailableQuest", id) end,
    SelectActiveQuest = function(id) record("C_GossipInfo.SelectActiveQuest", id) end,
    GetOptions = function() return deepcopy(Mock.gossip.options or {}) end,
    SelectOption = function(id) record("C_GossipInfo.SelectOption", id) end,
    CloseGossip = function() record("C_GossipInfo.CloseGossip") end,
  }

  -- Objets
  C_Item = {
    GetItemInfo = function(item)
      local i = itemInfo(item)
      if not i then return nil end
      return i.name, i.link or item, i.quality or 1, i.itemLevel or 1, i.minLevel or 0, i.itemType, i.itemSubType,
        i.stackCount or 1, i.equipLoc or "", i.texture or 134400, i.sellPrice or 0, i.classID, i.subclassID,
        i.bindType or 0, 0, nil, false
    end,
    GetItemStats = function(item)
      local i = itemInfo(item)
      return i and deepcopy(i.stats or {}) or {}
    end,
    GetItemNameByID = function(id) local i = Mock.items[id]; return i and i.name end,
    GetItemIconByID = function(id) local i = Mock.items[id]; return i and i.texture or 134400 end,
    GetItemInfoInstant = function(item)
      local i = itemInfo(item)
      if not i then return nil end
      return i.id or item, i.itemType, i.itemSubType, i.equipLoc or "", i.texture or 134400, i.classID, i.subclassID
    end,
    RequestLoadItemDataByID = function() end,
  }
  GetInventoryItemLink = function(unit, slot)
    if unit ~= "player" then return nil end
    return Mock.inventory[slot]
  end
  GetInventoryItemID = function(unit, slot)
    local link = unit == "player" and Mock.inventory[slot]
    return link and tonumber(tostring(link):match("item:(%d+)"))
  end
  C_SkillInfo = { GetSkillLineInfo = function() return nil end }
  C_TooltipInfo = setmetatable({}, { __index = function() return function() return nil end end })
  TooltipDataProcessor = { AddTooltipPostCall = function() end }
  Enum = setmetatable({ TooltipDataType = { Unit = 2, Item = 0 },
    UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4, Micro = 5, Orphan = 6 } }, {
    __index = function() return setmetatable({}, { __index = function() return 0 end }) end,
  })

  -- Cartes et position
  CreateVector2D = vector
  UiMapPoint = {
    CreateFromCoordinates = function(mapID, x, y, z)
      return { uiMapID = mapID, position = vector(x, y), z = z }
    end,
    CreateFromVector2D = function(mapID, pos, z) return { uiMapID = mapID, position = pos, z = z } end,
  }
  C_Map = {
    GetBestMapForUnit = function(unit)
      if unit ~= "player" then return nil end
      return P().map
    end,
    GetPlayerMapPosition = function(mapID, unit)
      if unit ~= "player" or P().instance or mapID ~= P().map or not P().x then return nil end
      return vector(P().x / 100, P().y / 100)
    end,
    GetWorldPosFromMapPos = function(mapID, pos)
      local m = Mock.maps[mapID]
      if not m or not pos then return nil end
      local x, y = pos.x, pos.y
      if pos.GetXY then x, y = pos:GetXY() end
      return m.continent, vector(m.top - y * m.height, m.left - x * m.width)
    end,
    GetMapInfo = function(mapID)
      local m = Mock.maps[mapID]
      if not m then return nil end
      return { mapID = mapID, name = m.name, mapType = m.parent and 3 or 2, parentMapID = m.parent or 0 }
    end,
    CanSetUserWaypointOnMap = function(mapID) return Mock.maps[mapID] ~= nil end,
    SetUserWaypoint = function(point) Mock.userWaypoint = point; record("C_Map.SetUserWaypoint", point) end,
    ClearUserWaypoint = function() Mock.userWaypoint = nil; record("C_Map.ClearUserWaypoint") end,
    HasUserWaypoint = function() return Mock.userWaypoint ~= nil end,
  }
  C_SuperTrack = {
    SetSuperTrackedUserWaypoint = function(b) record("C_SuperTrack.SetSuperTrackedUserWaypoint", b) end,
    IsSuperTrackingUserWaypoint = function() return false end,
  }
  C_TaxiMap = { GetAllTaxiNodes = function() return {} end }

  -- Barres de nom
  C_NamePlate = {
    GetNamePlates = function()
      local out = {}
      for _, p in pairs(Mock.nameplates) do out[#out + 1] = p end
      return out
    end,
    GetNamePlateForUnit = function(unit) return Mock.nameplates[unit] end,
  }

  Mock.installMapLibsApi(P)
end

---------------------------------------------------------------------------
-- Remise à zéro
---------------------------------------------------------------------------
local baseline
local function wipeGlobals()
  if not baseline then
    baseline = {}
    for k in pairs(_G) do baseline[k] = true end
  end
  local toRemove = {}
  for k in pairs(_G) do if not baseline[k] then toRemove[#toRemove + 1] = k end end
  for _, k in ipairs(toRemove) do _G[k] = nil end
end

local function resetRuntime()
  wipeGlobals()
  Mock.frames = {}
  Mock.eventFrames = {}
  Mock.timers = {}
  Mock.tocMeta = {}
  installApi()
end

function Mock.reset()
  Mock.now = 0
  Mock.locale = "enUS"
  Mock.interface = 16001
  Mock.player = { raceId = 3, classFile = "WARRIOR", level = 1, faction = "Alliance", map = 1426, x = 29.9, y = 71.2,
    combat = false, shift = false, name = "Testeur", instance = false }
  Mock.quests = { log = {}, completed = {} }
  Mock.titles = {}
  Mock.calls = {}
  Mock.addons = { QuestieDB = true, TomTom = false, WaypointUI = false, ShortestPathForever = false }
  Mock.errors = {}
  Mock.prints = {}
  Mock.missingFiles = {}
  Mock.gossip = { available = {}, active = {}, options = {} }
  Mock.greeting = { available = {}, active = {} }
  Mock.questFrame = { questId = 0, numChoices = nil, completable = false, choices = {} }
  Mock.items = {}
  Mock.inventory = {}
  Mock.units = {}
  Mock.nameplates = {}
  Mock.modelFileIDs = {}
  Mock.maps = defaultMaps()
  Mock.qdbContract = 4
  Mock.navigateResult = true
  Mock.userWaypoint = nil
  Mock.ns = nil
  Mock.lastToc = nil
  Mock.lastOpts = nil
  resetRuntime()
end

---------------------------------------------------------------------------
-- Chargement de l'addon
---------------------------------------------------------------------------
local ADDON = "Questify"

local function runFile(path, ns)
  local full = rootPath(path)
  local f = io.open(full, "rb")
  if not f then
    Mock.missingFiles[#Mock.missingFiles + 1] = path
    return false
  end
  f:close()
  local chunk, err = loadfile(full)
  if not chunk then pushError(err); return false end
  local ok, rerr = pcall(chunk, ADDON, ns)
  if not ok then pushError(rerr); return false end
  return true
end

local function runXml(path, ns)
  local full = rootPath(path)
  local src = readFile(full)
  if not src then
    Mock.missingFiles[#Mock.missingFiles + 1] = path
    return
  end
  src = src:gsub("<!%-%-.-%-%->", "")
  local dir = dirname(normPath(path))
  for tag, file in src:gmatch("<%s*(%a+)%s+file%s*=%s*\"([^\"]+)\"") do
    local sub = dir .. "/" .. normPath(file)
    if tag == "Script" then runFile(sub, ns)
    elseif tag == "Include" then runXml(sub, ns) end
  end
end

function Mock.loadAddon(toc, opts)
  opts = opts or {}
  Mock.lastToc, Mock.lastOpts = toc, opts
  local src = readFile(rootPath(toc))
  if not src then error("TOC not found: " .. tostring(toc), 2) end
  local tocDir = dirname(normPath(toc))

  if opts.savedVariables then
    for k, v in pairs(opts.savedVariables) do _G[k] = deepcopy(v) end
  end
  if Mock.addons.QuestieDB then installQuestieDB(opts.qdb) end
  installNavAddons()

  local ns = {}
  Mock.ns = ns
  local files = {}
  for line in src:gmatch("[^\r\n]+") do
    local key, value = line:match("^##%s*([^:]+):%s*(.-)%s*$")
    if key then
      Mock.tocMeta[key] = value
    elseif not line:match("^%s*#") and line:match("%S") then
      files[#files + 1] = tocDir .. "/" .. normPath((line:gsub("^%s+", ""):gsub("%s+$", "")))
    end
  end
  for _, path in ipairs(files) do
    -- opts.skipGuides : n'exécute pas le dossier Guides/ (guides livrés, ClassQuestData), pour
    -- tester le moteur sur les seules fixtures.
    if not (opts.skipGuides and path:find("/Guides/", 1, true)) then
      if path:match("%.xml$") then runXml(path, ns) else runFile(path, ns) end
    end
  end
  for _, path in ipairs(opts.extraFiles or {}) do runFile(path, ns) end

  -- Erreurs rattrapées par Q.SafeCall : elles comptent aussi dans Mock.errors.
  if type(ns.ReportError) == "function" then
    local original = ns.ReportError
    ns.ReportError = function(self, err, ...)
      pushError(err)
      return original(self, err, ...)
    end
  end

  Mock.fire("ADDON_LOADED", ADDON)
  if opts.beforeLogin then
    local ok, err = pcall(opts.beforeLogin, ns)
    if not ok then error(err, 0) end
  end
  Mock.fire("PLAYER_LOGIN")
  return ns
end

-- Simule /reload : conserve les SavedVariables et l'état du personnage, recrée tout le reste.
function Mock.reload(opts)
  local saved = {
    QuestifyDB = deepcopy(QuestifyDB),
    QuestifyCharDB = deepcopy(QuestifyCharDB),
  }
  local toc = Mock.lastToc or "Questify/Questify.toc"
  local o = {}
  for k, v in pairs(opts or Mock.lastOpts or {}) do o[k] = v end
  o.savedVariables = saved
  resetRuntime()
  return Mock.loadAddon(toc, o)
end

Mock.reset()
