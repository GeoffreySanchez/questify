-- Aides partagées par les tests : chargement unique (mis en cache) des données réelles.
local H = {}

H.ROOT = (arg and arg[0] or ""):match("^(.*)[/\\]tests[/\\]run%.lua$") or "tools/routebuilder"

local cacheD, cacheW = {}, nil

-- Données QuestieDB (vue Forever) pour une faction, chargées une seule fois par exécution.
function H.D(faction)
  faction = faction or "Alliance"
  if not cacheD[faction] then
    local qdb = require("qdb")
    cacheD[faction] = qdb.load({ db = qdb.DEFAULT_DB, questie = qdb.DEFAULT_QUESTIE, faction = faction })
  end
  return cacheD[faction]
end

-- Géométrie du monde (tables DB2 de tools/routebuilder/data).
function H.W()
  if not cacheW then cacheW = require("world").load(H.ROOT .. "/data") end
  return cacheW
end

-- Dossier temporaire propre à cette exécution.
function H.tmpdir()
  local dir = os.getenv("TMPDIR") or "/tmp"
  dir = dir:gsub("/$", "") .. "/routebuilder_tests"
  os.execute('mkdir -p "' .. dir .. '"')
  return dir
end

return H
