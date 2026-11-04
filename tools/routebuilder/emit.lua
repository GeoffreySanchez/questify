-- tools/routebuilder/emit.lua : écriture des fichiers de guides (format du § 5.2 de la spec).
-- Une étape par ligne, suivie d'un commentaire « -- <nom> (lvl <niveau>, ~<xp> xp, sim lvl <n>) ».

local emit = {}

-- Ordre d'écriture des champs nommés d'une étape.
local FIELD_ORDER = { "obj", "at", "xp", "race", "class", "optional", "dungeon", "node", "note" }

local function num(v)
  if v == math.floor(v) and math.abs(v) < 1e15 then return ("%d"):format(v) end
  local s = ("%.2f"):format(v):gsub("0+$", ""):gsub("%.$", "")
  return s
end

local function value(v)
  local t = type(v)
  if t == "number" then return num(v)
  elseif t == "string" then
    local s = ("%q"):format(v):gsub("\\\n", "\\n")
    return s
  elseif t == "boolean" then return tostring(v)
  elseif t == "table" then
    local parts = {}
    for i = 1, #v do parts[#parts + 1] = value(v[i]) end
    return "{ " .. table.concat(parts, ", ") .. " }"
  end
  error("cannot emit value of type " .. t)
end
emit.value = value

-- Une étape -> texte Lua ` { "accept", 179, at = {...} }` (sans les champs internes _xxx).
function emit.step(step)
  local parts = {}
  for i = 1, #step do parts[#parts + 1] = value(step[i]) end
  local known = {}
  for _, k in ipairs(FIELD_ORDER) do
    known[k] = true
    if step[k] ~= nil then parts[#parts + 1] = k .. " = " .. value(step[k]) end
  end
  -- champs supplémentaires éventuels (ordre alphabétique, pour un résultat stable)
  local extra = {}
  for k in pairs(step) do
    if type(k) == "string" and not known[k] and k:sub(1, 1) ~= "_" then extra[#extra + 1] = k end
  end
  table.sort(extra)
  for _, k in ipairs(extra) do parts[#parts + 1] = k .. " = " .. value(step[k]) end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

local LOGISTIC = {
  fp = "point de vol", sethearth = "lier la pierre de foyer", hearth = "pierre de foyer", fly = "vol",
  boat = "bateau", level = "farm de niveau", ["goto"] = "déplacement",
}

-- Commentaire de fin de ligne.
local function comment(step, xpByQuest)
  local c = step._c
  if c and c.name then
    local xp = c.xp or xpByQuest[step[2]] or 0
    -- nom tiré des données tierces : caractères de contrôle remplacés (un saut de ligne sortirait du commentaire)
    local name = tostring(c.name):gsub("[%c]", " ")
    return ("-- %s (lvl %s, ~%d xp, sim lvl %d)"):format(name, tostring(c.level), xp, c.simLevel or 0)
  end
  if LOGISTIC[step[1]] then return "-- " .. LOGISTIC[step[1]] end
  return nil
end

-- emit.guide(plan, steps, report, meta) -> texte du fichier
--   meta = { commit = "<sha QuestieDB>", date = "AAAA-MM-JJ", summary = "..." }
function emit.guide(plan, steps, report, meta)
  meta = meta or {}
  report = report or {}
  local xpByQuest = {}
  for _, q in ipairs(report.quests or {}) do xpByQuest[q.id] = q.xp end
  local out = {}
  local function w(s) out[#out + 1] = s end
  w("local addonName, Q = ...")
  w("-- Généré par tools/routebuilder (générateur de routes de Questify Vanilla). Ne pas modifier à la main :")
  w("-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.")
  w(("-- Source : QuestieDB commit %s, généré le %s."):format(meta.commit or "unknown", meta.date or os.date("%Y-%m-%d")))
  if report.xpPerHour then
    w(("-- Simulation : %d étapes, niveau final %.2f, ~%d xp/h, %d min."):format(report.steps or #steps,
      report.endLevel or 0, math.floor(report.xpPerHour + 0.5), math.floor((report.time or 0) / 60 + 0.5)))
  end
  w("Q:RegisterGuide({")
  w(("  id = %s,"):format(value(plan.id)))
  w(("  title = %s,"):format(value(plan.title or plan.id)))
  w(("  faction = %s,"):format(value(plan.faction)))
  if plan.races then w(("  races = %s,"):format(value(plan.races))) end
  w(("  minLevel = %d, maxLevel = %d,"):format(plan.minLevel, plan.maxLevel))
  if plan.next then w(("  next = %s,"):format(value(plan.next))) end
  if plan.nextByRace then
    local keys = {}
    for k in pairs(plan.nextByRace) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = ("%s = %s"):format(k, value(plan.nextByRace[k])) end
    w(("  nextByRace = { %s },"):format(table.concat(parts, ", ")))
  end
  w("  steps = {")
  for _, s in ipairs(steps) do
    local line = "    " .. emit.step(s) .. ","
    local c = comment(s, xpByQuest)
    if c then line = line .. " " .. c end
    w(line)
  end
  w("  },")
  w("})")
  return table.concat(out, "\n") .. "\n"
end

return emit
