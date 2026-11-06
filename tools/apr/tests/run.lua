-- tools/apr/tests/run.lua : lanceur des tests du comparateur APR (LuaJIT, sans données réelles).
-- Usage : luajit tools/apr/tests/run.lua [motif]
-- Chaque fichier tests/test_*.lua renvoie { [nom] = function(t) ... end }.
-- Affiche PASS nom / FAIL nom: message, et sort avec le code 1 au moindre échec.

local here = (arg and arg[0] or ""):match("^(.*)[/\\]tests[/\\]run%.lua$") or "tools/apr"
package.path = here .. "/?.lua;" .. here .. "/tests/?.lua;" .. package.path

local pattern = arg and arg[1]

-- Liste des fichiers de test, triée pour un ordre stable.
local function listTests()
  local files = {}
  local p = io.popen('ls "' .. here .. '/tests"')
  for name in p:lines() do
    if name:match("^test_.*%.lua$") then files[#files + 1] = name end
  end
  p:close()
  table.sort(files)
  return files
end

local function fmt(v)
  if type(v) == "string" then return ("%q"):format(v) end
  return tostring(v)
end

local function makeT()
  local t = {}
  function t.eq(actual, expected, msg)
    if actual ~= expected then
      error(("%sexpected %s, got %s"):format(msg and (msg .. ": ") or "", fmt(expected), fmt(actual)), 2)
    end
  end
  function t.ok(v, msg)
    if not v then error(msg or "expected a true value", 2) end
  end
  function t.fails(fn, msg)
    local ok = pcall(fn)
    if ok then error(msg or "expected an error", 2) end
  end
  return t
end

local passed, failed = 0, 0
for _, file in ipairs(listTests()) do
  local base = file:gsub("%.lua$", "")
  if not pattern or base:find(pattern, 1, true) then
    local chunk, err = loadfile(here .. "/tests/" .. file)
    local suite
    if chunk then
      local ok, res = pcall(chunk)
      if ok then suite = res else err = res end
    end
    if type(suite) ~= "table" then
      failed = failed + 1
      print(("FAIL %s: %s"):format(base, tostring(err or "file did not return a table")))
    else
      local names = {}
      for name in pairs(suite) do names[#names + 1] = name end
      table.sort(names)
      for _, name in ipairs(names) do
        local ok, e = xpcall(function() suite[name](makeT()) end, debug.traceback)
        if ok then
          passed = passed + 1
          print("PASS " .. name)
        else
          failed = failed + 1
          print(("FAIL %s: %s"):format(name, tostring(e)))
        end
      end
    end
  end
end

print(("%d passed, %d failed"):format(passed, failed))
os.exit(failed > 0 and 1 or 0)
