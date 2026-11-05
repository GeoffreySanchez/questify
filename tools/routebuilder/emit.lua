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

-- Métriques simulées d'un chapitre, arrondies comme l'en-tête « -- Simulation : » :
-- { steps, endLevel, xpPerHour, minutes }, ou nil sans simulation (report.xpPerHour absent).
function emit.simOf(report, steps)
  if not (report and report.xpPerHour) then return nil end
  return { steps = report.steps or #(steps or {}), endLevel = report.endLevel or 0,
           xpPerHour = math.floor(report.xpPerHour + 0.5), minutes = math.floor((report.time or 0) / 60 + 0.5) }
end

-- Commentaire d'en-tête (lu par les humains) et champ `sim` (lu par le jeu) : mêmes quatre valeurs.
function emit.simComment(s)
  return ("-- Simulation : %d étapes, niveau final %.2f, ~%d xp/h, %d min."):format(s.steps, s.endLevel, s.xpPerHour, s.minutes)
end

function emit.simLine(s)
  return ("  sim = { steps = %d, endLevel = %.2f, xpPerHour = %d, minutes = %d },"):format(s.steps, s.endLevel,
    s.xpPerHour, s.minutes)
end

-- Une entrée de choices -> `{ id = "A_01", races = {...}, label = "...", travel = { kind = "boat", minutes = 7 }, weight = 2 }`
-- (champs absents omis, toujours dans cet ordre).
function emit.choice(c)
  local parts = { "id = " .. value(c.id) }
  if c.races ~= nil then parts[#parts + 1] = "races = " .. value(c.races) end
  if c.label ~= nil then parts[#parts + 1] = "label = " .. value(c.label) end
  if c.travel ~= nil then
    local tp = { "kind = " .. value(c.travel.kind) }
    if c.travel.minutes ~= nil then tp[#tp + 1] = "minutes = " .. value(c.travel.minutes) end
    parts[#parts + 1] = "travel = { " .. table.concat(tp, ", ") .. " }"
  end
  if c.weight ~= nil then parts[#parts + 1] = "weight = " .. value(c.weight) end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

-- Bloc `choices` d'un plan (une entrée par ligne) : liste de lignes, vide sans choices.
function emit.choicesLines(plan)
  if not plan.choices then return {} end
  local out = { "  choices = {" }
  for _, c in ipairs(plan.choices) do out[#out + 1] = "    " .. emit.choice(c) .. "," end
  out[#out + 1] = "  },"
  return out
end

-- emit.guide(plan, steps, report, meta) -> texte du fichier
--   meta = { commit = "<sha QuestieDB>", date = "AAAA-MM-JJ", summary = "..." }
-- Champs de Q:RegisterGuide, dans l'ordre : id, title, faction, races, minLevel / maxLevel, next,
-- nextByRace, choices, sim, steps (tools/routebuilder/backfill.lua insère choices et sim au même endroit).
function emit.guide(plan, steps, report, meta)
  meta = meta or {}
  report = report or {}
  local xpByQuest = {}
  for _, q in ipairs(report.quests or {}) do xpByQuest[q.id] = q.xp end
  local out = {}
  local function w(s) out[#out + 1] = s end
  local sim = emit.simOf(report, steps)
  w("local addonName, Q = ...")
  w("-- Généré par tools/routebuilder (générateur de routes de Questify). Ne pas modifier à la main :")
  w("-- corriger tools/routebuilder/plans.lua ou overrides.lua, puis relancer tools/routebuilder/build.lua.")
  w(("-- Source : QuestieDB commit %s, généré le %s."):format(meta.commit or "unknown", meta.date or os.date("%Y-%m-%d")))
  if sim then w(emit.simComment(sim)) end
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
  for _, line in ipairs(emit.choicesLines(plan)) do w(line) end
  if sim then w(emit.simLine(sim)) end
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
