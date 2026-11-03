-- Lanceur de tests LuaJIT : luajit tests/run.lua [motif]
-- Exécute chaque tests/test_*.lua ; chaque fichier renvoie { [nom] = function(t) end }.
-- Le motif (recherche simple) filtre sur le nom de fichier ou sur le nom du test.

local write = io.write
local stderr = io.stderr

-- Racine du projet déduite du chemin du script (tests/run.lua -> .)
local script = arg and arg[0] or "tests/run.lua"
local testsDir = script:match("^(.*)/[^/]*$") or "."
local root = testsDir:match("^(.*)/[^/]*$") or "."
if testsDir == "." then root = ".." end

local pattern = arg and arg[1]

dofile(testsDir .. "/wow_mock.lua")
Mock.root = root

-- Liste des fichiers de test
local files = {}
local p = io.popen('ls "' .. testsDir .. '"')
for name in p:lines() do
  if name:match("^test_.*%.lua$") then files[#files + 1] = name end
end
p:close()
table.sort(files)

local function show(v, depth)
  depth = depth or 0
  if type(v) == "string" then return string.format("%q", v) end
  if type(v) ~= "table" then return tostring(v) end
  if depth > 2 then return "{...}" end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = "[" .. show(k, depth + 1) .. "]=" .. show(v[k], depth + 1)
    if #parts > 12 then parts[#parts + 1] = "..."; break end
  end
  return "{" .. table.concat(parts, ", ") .. "}"
end

local function deepEqual(a, b)
  if a == b then return true end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function makeT()
  local t = {}
  function t.eq(actual, expected, msg)
    if not deepEqual(actual, expected) then
      error((msg and (msg .. ": ") or "") .. "expected " .. show(expected) .. ", got " .. show(actual), 2)
    end
  end
  function t.ok(v, msg)
    if not v then error(msg or "expected a true value", 2) end
  end
  function t.fails(fn, msg)
    local ok = pcall(fn)
    if ok then error(msg or "expected an error", 2) end
  end
  function t.near(actual, expected, tol, msg)
    tol = tol or 0.001
    if type(actual) ~= "number" or math.abs(actual - expected) > tol then
      error((msg and (msg .. ": ") or "") .. "expected " .. tostring(expected) .. " ±" .. tol .. ", got " .. tostring(actual), 2)
    end
  end
  return t
end

local passed, failed, failures = 0, 0, {}

for _, file in ipairs(files) do
  local chunk, err = loadfile(testsDir .. "/" .. file)
  local suite
  if chunk then
    local ok, res = pcall(chunk)
    if ok then suite = res else err = res end
  end
  if type(suite) ~= "table" then
    if not pattern or file:find(pattern, 1, true) then
      failed = failed + 1
      local msg = "FAIL " .. file .. ": cannot load: " .. tostring(err)
      failures[#failures + 1] = msg
      write(msg, "\n")
    end
  else
    local names = {}
    for name in pairs(suite) do names[#names + 1] = name end
    table.sort(names)
    local fileMatch = not pattern or file:find(pattern, 1, true)
    for _, name in ipairs(names) do
      if fileMatch or name:find(pattern, 1, true) then
        Mock.reset()
        local ok, e = xpcall(function() suite[name](makeT()) end, function(m)
          return tostring(m) .. "\n" .. debug.traceback("", 2)
        end)
        local label = file:gsub("%.lua$", "") .. "." .. name
        if ok then
          passed = passed + 1
          write("PASS ", label, "\n")
        else
          failed = failed + 1
          local first = tostring(e):match("^[^\n]*") or tostring(e)
          local msg = "FAIL " .. label .. ": " .. first
          failures[#failures + 1] = msg
          write(msg, "\n")
          if os.getenv("VERBOSE") then write(tostring(e), "\n") end
          if #Mock.errors > 0 then
            write("     mock errors:\n")
            for i, me in ipairs(Mock.errors) do
              if i > 5 then break end
              write("       ", tostring(me):match("^[^\n]*") or "", "\n")
            end
          end
        end
      end
    end
  end
end

write(string.format("\n%d passed, %d failed\n", passed, failed))
if failed > 0 then
  stderr:write("\nFailures:\n")
  for _, f in ipairs(failures) do stderr:write("  ", f, "\n") end
  os.exit(1)
end
os.exit(0)
