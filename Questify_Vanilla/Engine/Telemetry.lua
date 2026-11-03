local addonName, Q = ...

-- Mesure du temps passé par étape (spec § 5.3), enregistrée localement dans
-- Q.char.telemetry[guideId][index] = secondes. `Export()` produit la chaîne à copier.
local Telemetry = {}
Q.Telemetry = Telemetry

local previous   -- { entry, guideId, index, since } : l'étape courante avant le changement

local function parseKey(key)
  local guideId, index = tostring(key):match("^g:(.+):(%d+)$")
  return guideId, tonumber(index)
end

-- Étape courante qui change : le temps écoulé appartient à l'étape qu'on quitte, mais on ne le
-- retient que si elle est terminée (pas sautée, pas dépassée, pas repoussée par une chaîne insérée).
Q:On("STEP_CHANGED", function(entry)
  local now = GetTime()
  local prev = previous
  previous = nil
  if entry and entry.source == "guide" then
    local guideId, index = parseKey(entry.key)
    if guideId then previous = { entry = entry, guideId = guideId, index = index, since = now } end
  end
  if not prev or not Q.char or Q.Settings:Get("telemetry") == false then return end
  -- « passed » : étape dépassée parce qu'une suivante est faite, pas vraiment terminée
  local state, reason = Q.Progress:State(prev.entry)
  if state ~= "done" or reason == "passed" then return end
  local all = Q.char.telemetry
  if type(all) ~= "table" then all = {}; Q.char.telemetry = all end
  local slot = all[prev.guideId]
  if type(slot) ~= "table" then slot = {}; all[prev.guideId] = slot end
  if slot[prev.index] == nil then
    slot[prev.index] = math.max(0, math.floor(now - prev.since + 0.5))
  end
end)

-- Export() -> "QV1;<guideId>:<idx>=<sec>,<idx>=<sec>;<guideId>:..." sur une seule ligne.
-- Chapitres triés par identifiant, étapes par numéro.
function Telemetry:Export()
  local out = { "QV1" }
  local all = Q.char and Q.char.telemetry
  if type(all) ~= "table" then return "QV1;" end
  local ids = {}
  for guideId, slot in pairs(all) do
    if type(guideId) == "string" and type(slot) == "table" and next(slot) ~= nil then ids[#ids + 1] = guideId end
  end
  table.sort(ids)
  for _, guideId in ipairs(ids) do
    local indexes = {}
    for index, sec in pairs(all[guideId]) do
      if type(index) == "number" and type(sec) == "number" then indexes[#indexes + 1] = index end
    end
    table.sort(indexes)
    local pairsText = {}
    for _, index in ipairs(indexes) do
      pairsText[#pairsText + 1] = index .. "=" .. all[guideId][index]
    end
    if #pairsText > 0 then out[#out + 1] = guideId .. ":" .. table.concat(pairsText, ",") end
  end
  local text = table.concat(out, ";")
  if #out == 1 then text = text .. ";" end
  return text
end
