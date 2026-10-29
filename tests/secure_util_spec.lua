local t = ...

-- SecureUtil captures the C_* namespaces when it loads, so each test loads a
-- fresh copy against its own stand-ins.

local function Load(globals)
  local MF
  t.withGlobals(globals, function()
    MF = t.newNamespace("Modules/SecureUtil.lua")
  end)
  return MF
end

t.test("C_PvP wrappers report the value of a working API", function()
  local MF = Load({ C_PvP = { IsMatchActive = function() return true end,
                              GetActiveMatchState = function() return 3 end } })
  local ok, active = MF.IsMatchActive()
  t.eq(ok, true)
  t.eq(active, true)
  local stateOk, state = MF.GetActiveMatchState()
  t.eq(stateOk, true)
  t.eq(state, 3)
end)

t.test("C_PvP wrappers report failure when the API is missing", function()
  local MF = Load({ C_PvP = {} })
  t.eq(MF.IsMatchActive(), false)
  t.eq(MF.IsMatchComplete(), false)
  t.eq(MF.IsMatchConsideredArena(), false)
  t.eq(MF.GetActiveMatchState(), false)
end)

t.test("C_PvP wrappers report failure instead of raising when the API errors", function()
  local MF = Load({ C_PvP = { IsMatchActive = function() error("boom") end } })
  local ok = MF.IsMatchActive()
  t.eq(ok, false)
end)

t.test("aura wrappers refuse a non-number aura instance ID without calling the API", function()
  local calls = 0
  local MF = Load({ C_UnitAuras = {
    GetAuraDuration = function() calls = calls + 1 return "duration" end,
    GetAuraDispelTypeColor = function() calls = calls + 1 return "color" end,
  } })
  t.eq(MF.GetAuraDuration("party1", nil), false)
  t.eq(MF.GetAuraDuration("party1", "12"), false)
  t.eq(MF.GetAuraDispelTypeColor("party1", nil, {}), false)
  t.eq(MF.GetAuraDispelTypeColor("party1", {}, {}), false)
  t.eq(calls, 0)
end)

t.test("aura wrappers pass a number ID straight through to the API", function()
  local MF = Load({ C_UnitAuras = {
    GetAuraDuration = function(unit, id) return unit .. id end,
    GetAuraDispelTypeColor = function(unit, id, curve) return unit .. id .. curve end,
  } })
  local ok, duration = MF.GetAuraDuration("party1", 7)
  t.eq(ok, true)
  t.eq(duration, "party17")
  local colorOk, color = MF.GetAuraDispelTypeColor("party1", 7, "c")
  t.eq(colorOk, true)
  t.eq(color, "party17c")
end)

t.test("aura wrappers report failure when the API is missing", function()
  local MF = Load({ C_UnitAuras = {} })
  t.eq(MF.GetAuraDuration("party1", 7), false)
  t.eq(MF.GetAuraDispelTypeColor("party1", 7, {}), false)
  local MFWithoutNamespace = Load({ C_UnitAuras = false })
  t.eq(MFWithoutNamespace.GetAuraDuration("party1", 7), false)
end)
