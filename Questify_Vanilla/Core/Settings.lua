local addonName, Q = ...

local Settings = {}
Q.Settings = Settings

-- Valeurs par défaut (copiées dans QuestifyVanillaDB.settings à l'INIT).
Settings.defaults = {
  autoQuest = true,
  autoReward = true,
  dungeonQuests = true,
  nav = { routing = false, display = "native" },
  tracker = { locked = false, scale = 1, nextSteps = 3, showMobs = true, autoTarget = false },
  nameplates = true,
  telemetry = true,
}

local function split(path)
  local parts = {}
  for p in tostring(path):gmatch("[^%.]+") do parts[#parts + 1] = p end
  return parts
end

local function walk(t, parts)
  for _, p in ipairs(parts) do
    if type(t) ~= "table" then return nil end
    t = t[p]
  end
  return t
end

-- Get("nav.display") : valeur enregistrée, sinon valeur par défaut.
function Settings:Get(path)
  local parts = split(path)
  local saved = Q.db and Q.db.settings
  if saved then
    local v = walk(saved, parts)
    if v ~= nil then return v end
  end
  return walk(self.defaults, parts)
end

-- Set("nav.display", "tomtom") : enregistre puis envoie "SETTINGS_CHANGED"(path, value).
function Settings:Set(path, value)
  if not Q.db then return end
  Q.db.settings = Q.db.settings or {}
  local parts = split(path)
  if #parts == 0 then return end
  local t = Q.db.settings
  for i = 1, #parts - 1 do
    local p = parts[i]
    if type(t[p]) ~= "table" then t[p] = {} end
    t = t[p]
  end
  t[parts[#parts]] = value
  Q:Fire("SETTINGS_CHANGED", path, value)
end
