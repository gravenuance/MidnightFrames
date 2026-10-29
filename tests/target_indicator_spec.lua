local t = ...

-- Drives Modules/TargetIndicator.lua with a fake UnitIsUnit and fake unit
-- frames (only innerBorder:SetShown matters).

local function FakeFrame(unit)
  local frame = { unit = unit }
  frame.innerBorder = { shown = false }
  function frame.innerBorder:SetShown(shown) self.shown = shown end
  return frame
end

-- `same` lists the unit pairs that are the same unit, e.g. { "player|party1target" }.
local function Run(same, fn)
  local pairsSame = {}
  for _, pair in ipairs(same) do
    pairsSame[pair] = true
    local a, b = pair:match("^(.-)|(.*)$")
    pairsSame[b .. "|" .. a] = true
  end
  local current = pairsSame
  t.withGlobals({
    UnitIsUnit = function(a, b) return a == b or current[a .. "|" .. b] == true end,
    UnitExists = function() return true end,
  }, function()
    local MF = t.newNamespace("Modules/SecureUtil.lua")
    MF.NumGroupMembers = 0
    MF.IsArenaInProgress = function() return false end
    MF.GetArenaSize = function() return 0 end
    MF.InInstance = function() return false end
    MF.MovableSingles = {}
    MF.MovableGroups = { party = {}, arena = {}, boss = {}, raid = {} }
    MF.FramesByUnit = {}
    t.load("Modules/TargetIndicator.lua", MF)
    fn(MF, function(newSame)
      current = {}
      for _, pair in ipairs(newSame) do
        local a, b = pair:match("^(.-)|(.*)$")
        current[pair] = true
        current[b .. "|" .. a] = true
      end
    end)
  end)
end

local function Register(MF, key, frame)
  MF.MovableSingles[key] = frame
  MF.FramesByUnit[frame.unit] = frame
end

t.test("a frame targeting the player lights the player frame", function()
  Run({ "player|party1target" }, function(MF)
    local player, party1 = FakeFrame("player"), FakeFrame("party1")
    Register(MF, "player", player)
    MF.UpdateTargetIndicator(party1)
    t.eq(player.innerBorder.shown, true)
    t.eq(party1.targetFrame, player)
  end)
end)

t.test("retargeting moves the highlight and clears the old frame", function()
  Run({ "player|party1target" }, function(MF, setSame)
    local player, party2, party1 = FakeFrame("player"), FakeFrame("party2"), FakeFrame("party1")
    Register(MF, "player", player)
    MF.MovableGroups.party[2] = party2
    MF.FramesByUnit.party2 = party2
    MF.NumGroupMembers = 3
    MF.UpdateTargetIndicator(party1)
    t.eq(player.innerBorder.shown, true)

    setSame({ "party2|party1target" })
    MF.UpdateTargetIndicator(party1)
    t.eq(party2.innerBorder.shown, true)
    t.eq(player.innerBorder.shown, false)
  end)
end)

t.test("switching to a target with no frame of ours clears the old highlight", function()
  Run({ "player|party1target" }, function(MF, setSame)
    local player, party1 = FakeFrame("player"), FakeFrame("party1")
    Register(MF, "player", player)
    MF.UpdateTargetIndicator(party1)
    t.eq(player.innerBorder.shown, true)

    -- party1 now targets boss1, which has no MidnightFrames frame here
    MF.InInstance = function() return true end
    setSame({ "boss1|party1target" })
    MF.UpdateTargetIndicator(party1)
    t.eq(player.innerBorder.shown, false, "old highlight is cleared")
    t.eq(party1.targetFrame, nil)
  end)
end)

t.test("two frames on one target keep it lit until both look away", function()
  Run({ "player|party1target", "player|party2target" }, function(MF, setSame)
    local player, party1, party2 = FakeFrame("player"), FakeFrame("party1"), FakeFrame("party2")
    Register(MF, "player", player)
    MF.UpdateTargetIndicator(party1)
    MF.UpdateTargetIndicator(party2)

    MF.InInstance = function() return true end
    setSame({ "player|party2target" })
    MF.UpdateTargetIndicator(party1)
    t.eq(player.innerBorder.shown, true, "party2 still targets the player")
    setSame({})
    MF.UpdateTargetIndicator(party2)
    t.eq(player.innerBorder.shown, false)
  end)
end)

t.test("the player's own frame is never indicated", function()
  Run({ "player|playertarget" }, function(MF)
    local player = FakeFrame("player")
    Register(MF, "player", player)
    MF.UpdateTargetIndicator(player)
    t.eq(player.innerBorder.shown, false)
  end)
end)
