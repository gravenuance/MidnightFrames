local _, MF = ...

local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit

local arenaUnits = {}
for i = 1, 5 do
  arenaUnits[i] = "arena" .. i
end

local partyUnits = {}
for i = 1, 4 do
  partyUnits[i] = "party" .. i
end

local raidUnits = {}
for i = 1, 40 do
  raidUnits[i] = "raid" .. i
end

local bossUnits = {}
for i = 1, 5 do
  bossUnits[i] = "boss" .. i
end

-- UNIT_TARGET fires for every tracked frame, so this stays call-only: no
-- wrapper tables, and the unit tokens are built once.
local function IsSameUnit(unit, otherUnit)
  return MF.PlainBool(UnitIsUnit(unit, otherUnit))
end

-- The group/arena/boss unit that `frame`'s unit is targeting, if any.
local function GetTargetUnit(frame)
  local targetUnit = frame.targetToken
  if not targetUnit then
    targetUnit = frame.unit .. "target"
    frame.targetToken = targetUnit
  end
  if not MF.PlainBool(UnitExists(targetUnit)) then
    return nil
  end

  local tempUnit
  local numGroup = MF.NumGroupMembers
  if numGroup > 5 then
    for index = 1, numGroup do
      tempUnit = raidUnits[index]
      if IsSameUnit(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  elseif numGroup > 0 then
    for index = 1, numGroup - 1 do
      tempUnit = partyUnits[index]
      if IsSameUnit(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  end
  if MF.IsArenaInProgress() then
    local arenaSize = MF.GetArenaSize()
    if arenaSize > 0 then
      for index = 1, arenaSize do
        tempUnit = arenaUnits[index]
        if IsSameUnit(tempUnit, targetUnit) then
          return tempUnit
        end
      end
    end
  end
  if MF.InInstance() then
    for index = 1, 5 do
      tempUnit = bossUnits[index]
      if IsSameUnit(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  end
  return IsSameUnit("player", targetUnit) and "player" or nil
end

function MF.UpdateTargetIndicator(frame)
  if not frame or not frame.unit then return end
  if frame.unit == "player" or IsSameUnit(frame.unit, "player") then
    return
  end

  local targetUnit = GetTargetUnit(frame)
  if not targetUnit then
    MF.ResetTargetIndicator(frame)
    return
  end

  -- The player can be reached through more than one token (raid5 is the
  -- player), so any hit on the player lights the player frame.
  local targetFrame
  if IsSameUnit(targetUnit, "player") then
    targetFrame = MF.FramesByUnit.player
  else
    targetFrame = MF.FramesByUnit[targetUnit]
  end
  if not targetFrame then
    MF.ResetTargetIndicator(frame)
    return
  end
  targetFrame.targeted = targetFrame.targeted or {}
  targetFrame.targeted[frame.unit] = true
  targetFrame.innerBorder:SetShown(true)

  if frame.targetFrame and frame.targetFrame ~= targetFrame then
    frame.targetFrame.targeted[frame.unit] = nil
    if not next(frame.targetFrame.targeted) then
      frame.targetFrame.innerBorder:SetShown(false)
    end
  end

  frame.targetFrame = targetFrame
end

function MF.ResetTargetIndicator(frame)
  if frame.targetFrame and frame.targetFrame.targeted then
    frame.targetFrame.targeted[frame.unit] = nil
    if not next(frame.targetFrame.targeted) then
      frame.targetFrame.innerBorder:SetShown(false)
    end
  end
  frame.targetFrame = nil
end
