-- Aides partagées par les tests du comparateur APR : chemins des données fictives, dossier temporaire.
local H = {}

H.ROOT = (arg and arg[0] or ""):match("^(.*)[/\\]tests[/\\]run%.lua$") or "tools/apr"
H.FIX = H.ROOT .. "/tests/fixtures"

-- Dossier temporaire propre à cette exécution (vidé à chaque appel).
function H.tmpdir(name)
  local dir = os.getenv("TMPDIR") or "/tmp"
  dir = dir:gsub("/$", "") .. "/apr_compare_tests/" .. (name or "tmp")
  os.execute('rm -rf "' .. dir .. '" && mkdir -p "' .. dir .. '"')
  return dir
end

function H.write(path, text)
  local f = assert(io.open(path, "wb"))
  f:write(text); f:close()
end

function H.read(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

return H
