-- tools/routebuilder/backfill.lua : ajoute aux guides déjà générés les champs `choices` et `sim` que
-- emit.lua écrit désormais, sans relancer build.lua (qui demande QuestieDB et réécrit tous les guides).
--
-- Usage : luajit tools/routebuilder/backfill.lua [--guides DIR] [--check]
--   --guides : dossier qui contient Guides.xml (défaut Questify/Guides)
--   --check  : n'écrit rien ; code de sortie 1 si un guide serait modifié
--
-- Pour chaque guide listé dans Guides.xml qui porte l'en-tête « -- Simulation : » (guides générés) :
--   * `sim = { steps, endLevel, xpPerHour, minutes }`, valeurs relues dans cet en-tête ;
--   * si le plan du chapitre (plans.lua) a des `choices`, le bloc `choices = { ... }` ;
-- écrits par emit.lua (emit.choicesLines, emit.simLine) juste avant `steps = {`, à la place où build.lua
-- les écrit. Un bloc `choices` ou une ligne `sim` déjà présents dans l'en-tête de Q:RegisterGuide sont
-- d'abord retirés : un second passage ne change rien, et un choix retiré de plans.lua disparaît du guide.
-- Les fins de ligne du fichier (CRLF ou LF) sont conservées. Les plans sont d'abord contrôlés
-- (plans.validate) : rien n'est écrit si un plan est invalide.

local here = (arg and arg[0] or ""):match("^(.*)[/\\]backfill%.lua$") or "tools/routebuilder"
package.path = here .. "/?.lua;" .. package.path

local emit = require("emit")
local plansm = require("plans")

local backfill = {}

local SIM_HEADER = "^%-%- Simulation : (%d+) étapes, niveau final ([%d%.]+), ~(%d+) xp/h, (%d+) min%.$"

-- Valeurs de l'en-tête « -- Simulation : » d'un texte de guide, ou nil.
function backfill.parseSim(text)
  for line in text:gmatch("[^\r\n]+") do
    local steps, level, xph, minutes = line:match(SIM_HEADER)
    if steps then
      return { steps = tonumber(steps), endLevel = tonumber(level), xpPerHour = tonumber(xph),
               minutes = tonumber(minutes) }, line
    end
    if line:match("^Q:RegisterGuide") then break end
  end
  return nil
end

-- Texte d'un guide avec ses champs `choices` (plan.choices) et `sim` (en-tête) à jour.
-- plan : plan du chapitre ou nil (aucun choix). Renvoie le nouveau texte (identique si rien ne change),
-- ou nil, raison si le fichier n'est pas un guide généré reconnu.
function backfill.apply(text, plan)
  local sim, header = backfill.parseSim(text)
  if not sim then return nil, "no simulation header" end
  -- l'en-tête doit être exactement celui qu'écrirait emit.lua (sinon le format a changé : rien n'est touché)
  if emit.simComment(sim) ~= header then return nil, "unexpected simulation header: " .. header end
  local eol = text:find("\r\n", 1, true) and "\r\n" or "\n"
  local lines = {}
  for line in (text .. (text:sub(-#eol) == eol and "" or eol)):gmatch("(.-)" .. eol) do lines[#lines + 1] = line end
  local reg, stepsAt
  for i, line in ipairs(lines) do
    if not reg and line:match("^Q:RegisterGuide%(%{%s*$") then reg = i
    elseif reg and line:match("^  steps = %{%s*$") then stepsAt = i; break end
  end
  if not reg or not stepsAt then return nil, "no Q:RegisterGuide({ ... steps = { block" end
  -- en-tête de Q:RegisterGuide sans l'ancien bloc choices ni l'ancienne ligne sim
  local head, i = {}, reg + 1
  while i < stepsAt do
    local line = lines[i]
    if line:match("^  choices = %{%s*$") then
      local j = i + 1
      while j < stepsAt and not lines[j]:match("^  %},%s*$") do j = j + 1 end
      if j >= stepsAt then return nil, "unterminated choices block" end
      i = j + 1
    elseif line:match("^  sim = %{.*%},%s*$") then
      i = i + 1
    else
      head[#head + 1] = line
      i = i + 1
    end
  end
  for _, line in ipairs(emit.choicesLines(plan or {})) do head[#head + 1] = line end
  head[#head + 1] = emit.simLine(sim)
  local out = {}
  for k = 1, reg do out[#out + 1] = lines[k] end
  for _, line in ipairs(head) do out[#out + 1] = line end
  for k = stepsAt, #lines do out[#out + 1] = lines[k] end
  local result = table.concat(out, eol)
  if text:sub(-#eol) == eol then result = result .. eol end
  return result
end

-- Identifiant du chapitre (`  id = "..."` dans Q:RegisterGuide).
function backfill.guideId(text)
  return text:match('\n  id = "([^"]+)",')
end

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

-- Passe sur les guides de Guides.xml. Renvoie la liste { path, status } (status : "updated",
-- "unchanged", "skipped: <raison>") ; check = true : aucun fichier écrit.
function backfill.run(guidesDir, check)
  local xml = readFile(guidesDir .. "/Guides.xml")
  if not xml then return nil, "missing " .. guidesDir .. "/Guides.xml" end
  local res = {}
  for rel in xml:gmatch('<Script%s+file%s*=%s*"([^"]+)"') do
    rel = rel:gsub("\\", "/")
    local path = guidesDir .. "/" .. rel
    local text = readFile(path)
    if not text then
      res[#res + 1] = { path = path, status = "skipped: cannot read" }
    else
      local id = backfill.guideId(text)
      local plan = id and plansm.find(id)
      local new, why = backfill.apply(text, plan)
      if not new then
        res[#res + 1] = { path = path, status = "skipped: " .. why }
      elseif new == text then
        res[#res + 1] = { path = path, status = "unchanged" }
      else
        if not check then
          local f = assert(io.open(path, "wb"), "cannot write " .. path)
          f:write(new); f:close()
        end
        res[#res + 1] = { path = path, status = check and "would update" or "updated" }
      end
    end
  end
  return res
end

function backfill.main(argv)
  local dir, check = "Questify/Guides", false
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--guides" then dir = argv[i + 1]; i = i + 1
    elseif a == "--check" then check = true
    else io.stderr:write("unknown argument " .. tostring(a) .. "\n"); return 2 end
    i = i + 1
  end
  local errs = plansm.validate(plansm)
  if #errs > 0 then
    for _, e in ipairs(errs) do io.stderr:write(("plans.lua: %s: %s\n"):format(e.id, e.msg)) end
    return 1
  end
  local res, err = backfill.run(dir, check)
  if not res then io.stderr:write(err .. "\n"); return 1 end
  local changed = 0
  for _, r in ipairs(res) do
    if r.status ~= "unchanged" then print(("%-12s %s"):format(r.status, r.path)) end
    if r.status == "updated" or r.status == "would update" then changed = changed + 1 end
  end
  print(("%d guide file(s) %s, %d listed in Guides.xml"):format(changed, check and "to update" or "updated", #res))
  return (check and changed > 0) and 1 or 0
end

-- require("backfill") (tests) : module ; luajit tools/routebuilder/backfill.lua : commande.
if select(1, ...) == "--as-module" or not (arg and arg[0] and arg[0]:match("backfill%.lua$")) then return backfill end
os.exit(backfill.main(arg or {}))
