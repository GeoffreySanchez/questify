local addonName, Q = ...

-- Registre des guides (chapitres). Format fixé par la spec § 5.2, produit par le générateur.
local Guides = {}
Q.Guides = Guides

local registry = {}
local sorted

local VALID = {
  accept = "quest", complete = "quest", turnin = "quest",
  ["goto"] = "point", fp = "point", sethearth = "point", boat = "point",
  hearth = "map", fly = "map",
  level = "level",
  note = "text",
  train = "none",   -- maître de classe le plus proche (étape insérée par Engine/Trainer.lua)
}
Guides.VALID_ACTIONS = VALID

local function isNum(v) return type(v) == "number" and v == v end

local function stringList(v)
  if v == nil then return nil end
  if type(v) == "string" then return { v } end
  if type(v) ~= "table" then return false end
  local out = {}
  for _, s in ipairs(v) do
    if type(s) ~= "string" then return false end
    out[#out + 1] = s
  end
  return out
end

-- Normalize(rawStep) -> step | nil, erreur
-- Forme brute : { "accept", 179 }, { "goto", 1426, 22.6, 71.4 }, { "level", 6 }, { "note", "txt" },
-- { "hearth", 1426 }, { "fly", 1453 }, plus les champs facultatifs (obj, note, race, class,
-- optional, dungeon, at = {mapId, x, y}, xp). Une étape déjà normalisée est recopiée.
function Guides:Normalize(raw)
  if type(raw) ~= "table" then return nil, "step is not a table" end
  local action, a2, a3, a4
  if type(raw.action) == "string" then
    action = raw.action
  else
    action, a2, a3, a4 = raw[1], raw[2], raw[3], raw[4]
  end
  local kind = VALID[action]
  if not kind then return nil, "unknown action '" .. tostring(action) .. "'" end

  local step = { action = action }
  if kind == "quest" then
    local id = raw.questId or a2
    if not isNum(id) then return nil, action .. ": missing quest id" end
    step.questId = id
    if raw.obj ~= nil then
      if not isNum(raw.obj) then return nil, action .. ": obj must be a number" end
      step.obj = raw.obj
    end
  elseif kind == "point" then
    local m, x, y = raw.mapId or a2, raw.x or a3, raw.y or a4
    if not (isNum(m) and isNum(x) and isNum(y)) then return nil, action .. ": needs mapId, x, y" end
    step.mapId, step.x, step.y = m, x, y
  elseif kind == "map" then
    local m = raw.mapId or a2
    if not isNum(m) then return nil, action .. ": needs mapId" end
    step.mapId = m
  elseif kind == "level" then
    local l = raw.level or a2
    if not isNum(l) then return nil, "level: needs a number" end
    step.level = l
  elseif kind == "text" then
    local txt = raw.text or a2
    if type(txt) ~= "string" then return nil, "note: needs a text" end
    step.text = txt
  end

  if raw.note ~= nil then
    if type(raw.note) ~= "string" then return nil, action .. ": note must be a string" end
    step.note = raw.note
  end
  local race = stringList(raw.race)
  if race == false then return nil, action .. ": race must be a list of strings" end
  step.race = race
  local class = stringList(raw.class)
  if class == false then return nil, action .. ": class must be a list of strings" end
  step.class = class
  if raw.optional then step.optional = true end
  if raw.dungeon ~= nil then
    if type(raw.dungeon) ~= "string" then return nil, action .. ": dungeon must be a string" end
    step.dungeon = raw.dungeon
  end
  if raw.at ~= nil then
    local at = raw.at
    if type(at) ~= "table" then return nil, action .. ": at must be {mapId, x, y}" end
    local m, x, y = at.mapId or at[1], at.x or at[2], at.y or at[3]
    if not (isNum(m) and isNum(x) and isNum(y)) then return nil, action .. ": at must be {mapId, x, y}" end
    -- Les deux formes : positionnelle (comme le guide) et nommée.
    step.at = { m, x, y, mapId = m, x = x, y = y }
  end
  if raw.xp ~= nil then
    if not isNum(raw.xp) then return nil, action .. ": xp must be a number" end
    step.xp = raw.xp
  end
  return step
end

local function invalid(id, reason)
  Q:Print(Q.L.GUIDE_INVALID, tostring(id or "?"), tostring(reason))
  return false
end

-- Q:RegisterGuide(def) : valide et enregistre un chapitre ; un guide invalide est ignoré
-- avec un seul message d'erreur.
function Q:RegisterGuide(def)
  if type(def) ~= "table" then return invalid(nil, "not a table") end
  local id = def.id
  if type(id) ~= "string" or id == "" then return invalid(id, "missing id") end
  if type(def.steps) ~= "table" then return invalid(id, "missing steps") end
  if def.faction ~= nil and def.faction ~= "Alliance" and def.faction ~= "Horde" then
    return invalid(id, "faction must be Alliance or Horde")
  end
  local races = stringList(def.races)
  if races == false then return invalid(id, "races must be a list of strings") end
  if def.minLevel ~= nil and not isNum(def.minLevel) then return invalid(id, "minLevel must be a number") end
  if def.maxLevel ~= nil and not isNum(def.maxLevel) then return invalid(id, "maxLevel must be a number") end
  if def.next ~= nil and type(def.next) ~= "string" then return invalid(id, "next must be a guide id") end
  if def.nextByRace ~= nil and type(def.nextByRace) ~= "table" then return invalid(id, "nextByRace must be a table") end

  local steps = {}
  for i, raw in ipairs(def.steps) do
    local step, err = Guides:Normalize(raw)
    if not step then return invalid(id, "step " .. i .. ": " .. tostring(err)) end
    steps[i] = step
  end

  local guide = {}
  for k, v in pairs(def) do guide[k] = v end
  guide.steps = steps
  guide.races = races
  guide.minLevel = def.minLevel or 1
  guide.maxLevel = def.maxLevel or 61
  guide.title = def.title or id
  if registry[id] then Q:Debug("guide replaced", id) end
  registry[id] = guide
  sorted = nil
  return true
end

function Guides:Get(id)
  if id == nil then return nil end
  return registry[id]
end

function Guides:All()
  if not sorted then
    sorted = {}
    for _, g in pairs(registry) do sorted[#sorted + 1] = g end
    table.sort(sorted, function(a, b) return a.id < b.id end)
  end
  local out = {}
  for i, g in ipairs(sorted) do out[i] = g end
  return out
end

local function racesMatch(g, raceKey)
  return g.races == nil or Q.Util.Contains(g.races, raceKey)
end

-- Ordre de préférence : chapitre réservé à la race d'abord, puis ID le plus petit.
local function better(a, b)
  local ra, rb = a.races ~= nil, b.races ~= nil
  if ra ~= rb then return ra end
  return a.id < b.id
end

-- Chapitre de départ pour un personnage.
function Guides:ForPlayer(faction, raceKey, level)
  level = level or 1
  local inBand, best
  for _, g in ipairs(self:All()) do
    if g.faction == faction and racesMatch(g, raceKey) then
      if g.minLevel <= level and level < g.maxLevel then
        if not inBand or better(g, inBand) then inBand = g end
      elseif g.minLevel <= level then
        if not best or g.minLevel > best.minLevel or (g.minLevel == best.minLevel and better(g, best)) then
          best = g
        end
      end
    end
  end
  return inBand or best
end

-- Chapitre suivant : nextByRace[raceKey], sinon next.
function Guides:Next(guide, raceKey)
  if type(guide) ~= "table" then return nil end
  local id = guide.nextByRace and raceKey and guide.nextByRace[raceKey]
  if id and registry[id] then return registry[id] end
  if guide.next then return registry[guide.next] end
  return nil
end
