local t = ...

-- Drives Core.lua's event frame (ADDON_LOADED start-up and the post-combat
-- queue) against stand-ins for the WoW globals: one failing callback must
-- not stop the others, and the error must still reach the error handler.

local function Load()
  local noop = function() end
  local libs = {
    ["AceDB-3.0"] = {},
    ["AceDBOptions-3.0"] = {},
    ["AceConfig-3.0"] = {},
    ["AceConfigDialog-3.0"] = {},
    ["AceConfigRegistry-3.0"] = {},
  }
  local env = {
    inCombat = false,
    handler = nil,
    reported = {},
  }
  local globals = {
    LibStub = function(name) return libs[name] end,
    SlashCmdList = {},
    StaticPopupDialogs = {},
    Enum = { LuaCurveType = { Linear = 0, Step = 1 } },
    InCombatLockdown = function() return env.inCombat end,
    geterrorhandler = function()
      return function(err) env.reported[#env.reported + 1] = tostring(err) end
    end,
    CreateFrame = function()
      return {
        RegisterEvent = noop,
        UnregisterEvent = noop,
        SetScript = function(_, _, handler) env.handler = handler end,
      }
    end,
  }
  t.withGlobals(globals, function()
    env.MF = t.newNamespace(
      "Modules/Migrations.lua", "Modules/AuraLogic.lua", "Modules/GroupLogic.lua",
      "Modules/FrameUtil.lua", "Modules/TestUtil.lua", "Core.lua")
  end)
  env.globals = globals
  return env
end

-- Runs fn with the stand-in globals active (the handlers read them at call time).
local function Fire(env, event, ...)
  local args = { ... }
  t.withGlobals(env.globals, function()
    env.handler({ UnregisterEvent = function() end }, event, unpack(args))
  end)
end

t.test("one failing init callback does not stop the others or the options", function()
  local env = Load()
  local MF = env.MF
  local ran = {}
  MF.InitDB = function() ran[#ran + 1] = "db" end
  MF.InitConfigAndOptions = function() ran[#ran + 1] = "options" end
  MF.OnInit(function() ran[#ran + 1] = "first" end)
  MF.OnInit(function() error("init boom") end)
  MF.OnInit(function() ran[#ran + 1] = "third" end)

  Fire(env, "ADDON_LOADED", "MidnightFrames")

  t.listEq(ran, { "db", "first", "third", "options" })
  t.eq(#env.reported, 1)
  t.truthy(env.reported[1]:find("init boom", 1, true))
end)

t.test("one failing post-combat entry does not drop the others", function()
  local env = Load()
  local MF = env.MF
  local ran = {}
  env.inCombat = true
  t.withGlobals(env.globals, function()
    MF.RunAfterCombat("a", function() ran[#ran + 1] = "a" end)
    MF.RunAfterCombat("b", function() error("queue boom") end)
    MF.RunAfterCombat("c", function() ran[#ran + 1] = "c" end)
  end)
  env.inCombat = false

  Fire(env, "PLAYER_REGEN_ENABLED")

  table.sort(ran)
  t.listEq(ran, { "a", "c" })
  t.eq(#env.reported, 1)
  t.truthy(env.reported[1]:find("queue boom", 1, true))
end)

t.test("post-combat entries get the arguments they were queued with", function()
  local env = Load()
  local MF = env.MF
  local seen
  env.inCombat = true
  t.withGlobals(env.globals, function()
    MF.RunAfterCombat("k", function(x, y) seen = x .. y end, "one", "two")
  end)
  env.inCombat = false

  Fire(env, "PLAYER_REGEN_ENABLED")

  t.eq(seen, "onetwo")
end)
