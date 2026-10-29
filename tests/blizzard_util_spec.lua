local t = ...

-- Showing a hidden Blizzard frame must release our visibility driver rather
-- than pin the frame visible with a "show" driver, and hiding must still work
-- afterwards.

local function Fakes()
  local log = {}
  local frame = {
    UnregisterAllEvents = function() log[#log + 1] = "unregister-events" end,
    RegisterEvent = function(_, event) log[#log + 1] = "event:" .. event end,
    Show = function() log[#log + 1] = "show" end,
  }
  local globals = {
    FakeContainer = frame,
    RegisterStateDriver = function(_, state, value) log[#log + 1] = "driver:" .. state .. "=" .. value end,
    UnregisterStateDriver = function(_, state) log[#log + 1] = "undriver:" .. state end,
  }
  return log, globals
end

t.test("showing releases the visibility driver, shows the frame and re-registers events", function()
  local log, globals = Fakes()
  t.withGlobals(globals, function()
    local MF = t.newNamespace("Modules/BlizzardUtil.lua")
    MF.ShowBlizzardFrame("FakeContainer", { "GROUP_ROSTER_UPDATE", "UNIT_PET" })
  end)
  t.listEq(log, { "undriver:visibility", "show", "event:GROUP_ROSTER_UPDATE", "event:UNIT_PET" })
end)

t.test("hiding after a show registers the hide driver again", function()
  local log, globals = Fakes()
  t.withGlobals(globals, function()
    local MF = t.newNamespace("Modules/BlizzardUtil.lua")
    MF.ShowBlizzardFrame("FakeContainer", {})
    MF.HideBlizzardFrame("FakeContainer")
  end)
  t.listEq(log, { "undriver:visibility", "show", "unregister-events", "driver:visibility=hide" })
end)

t.test("an unknown frame name is ignored", function()
  local log, globals = Fakes()
  t.withGlobals(globals, function()
    local MF = t.newNamespace("Modules/BlizzardUtil.lua")
    MF.ShowBlizzardFrame("NoSuchFrame", { "UNIT_PET" })
    MF.HideBlizzardFrame("NoSuchFrame")
  end)
  t.listEq(log, {})
end)
