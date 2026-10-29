-- Offline test runner: `lua5.1 tests/run.lua` from the repo root.
-- Loads every tests/*_spec.lua and runs its tests; exits non-zero on any
-- failure. No WoW client and no external dependencies - specs exercise the
-- pure-logic files (Modules/*Logic.lua, Migrations.lua) through a fake
-- addon namespace.

-- The retail globals list (used by wowlint) has no io/os/package/loadfile,
-- so reach the host Lua's standard library with rawget.
local io, os, package = rawget(_G, "io"), rawget(_G, "os"), rawget(_G, "package")
local loadfile = rawget(_G, "loadfile")

local scriptPath = arg and arg[0] or "tests/run.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]*$") or "."
local rootDir = testsDir .. "/.."

local isWindows = package.config:sub(1, 1) == "\\"

local function ListSpecFiles()
  local command
  if isWindows then
    command = 'dir /b "' .. testsDir:gsub("/", "\\") .. '\\*_spec.lua"'
  else
    command = 'ls "' .. testsDir .. '"'
  end
  local files = {}
  local pipe = assert(io.popen(command))
  for line in pipe:lines() do
    if line:match("_spec%.lua$") then
      files[#files + 1] = line
    end
  end
  pipe:close()
  table.sort(files)
  return files
end

-- Assertions raise at level 2 so the failure points at the spec line.
local t = {}

local function Describe(value)
  if type(value) == "string" then
    return string.format("%q", value)
  end
  return tostring(value)
end

function t.eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%sexpected %s, got %s",
      message and (message .. ": ") or "", Describe(expected), Describe(actual)), 2)
  end
end

function t.truthy(value, message)
  if not value then
    error((message or "expected a truthy value") .. ", got " .. Describe(value), 2)
  end
end

function t.falsy(value, message)
  if value then
    error((message or "expected a falsy value") .. ", got " .. Describe(value), 2)
  end
end

-- Compares two arrays element by element (order matters).
function t.listEq(actual, expected, message)
  local prefix = message and (message .. ": ") or ""
  if #actual ~= #expected then
    error(prefix .. "expected " .. #expected .. " items, got " .. #actual, 2)
  end
  for index = 1, #expected do
    if actual[index] ~= expected[index] then
      error(string.format("%sitem %d: expected %s, got %s",
        prefix, index, Describe(expected[index]), Describe(actual[index])), 2)
    end
  end
end

-- Loads an addon file the way WoW does: the chunk receives (addonName, ns).
function t.load(relativePath, ns)
  local chunk = assert(loadfile(rootDir .. "/" .. relativePath))
  chunk("MidnightFrames", ns)
  return ns
end

-- Fresh namespace with the named files loaded in order.
function t.newNamespace(...)
  local ns = {}
  for _, path in ipairs({ ... }) do
    t.load(path, ns)
  end
  return ns
end

-- Runs fn with the given globals replaced, then restores them.
function t.withGlobals(overrides, fn)
  local saved = {}
  for name, value in pairs(overrides) do
    saved[name] = _G[name]
    _G[name] = value
  end
  local ok, err = pcall(fn)
  for name in pairs(overrides) do
    _G[name] = saved[name]
  end
  if not ok then
    error(err, 0)
  end
end

local results = { passed = 0, failed = 0 }

function t.test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    results.passed = results.passed + 1
    print("PASS  " .. name)
  else
    results.failed = results.failed + 1
    print("FAIL  " .. name)
    print("      " .. tostring(err))
  end
end

local specs = ListSpecFiles()
if #specs == 0 then
  print("no *_spec.lua files found in " .. testsDir)
  os.exit(1)
end

for _, spec in ipairs(specs) do
  print("== " .. spec)
  local chunk, loadError = loadfile(testsDir .. "/" .. spec)
  if not chunk then
    results.failed = results.failed + 1
    print("FAIL  (load) " .. tostring(loadError))
  else
    local ok, err = pcall(chunk, t)
    if not ok then
      results.failed = results.failed + 1
      print("FAIL  (spec body) " .. tostring(err))
    end
  end
end

print(string.format("\n%d passed, %d failed", results.passed, results.failed))
os.exit(results.failed == 0 and 0 or 1)
