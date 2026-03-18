local _, MV = ...

MV.frameByGUID = {}
MV.GUIDByFrame = {}

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

local function CheckUnits(unit, otherUnit)
  if MV.UnitExists(unit) then
    if MV.IsUnitUnit(unit, otherUnit) then
      return true
    end
  end
  return false
end

local function GetTargetUnit(frame)
  local targetUnit = frame.unit .. "target"
  local tempUnit
  local _, numGroup = MV.CallExternalFunction({
    functionName = "GetNumGroupMembers"
  })
  if MV.IsNumber(numGroup) and numGroup > 5 then
    for index = 1, numGroup do
      tempUnit = raidUnits[index]
      if CheckUnits(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  elseif MV.IsNumber(numGroup) and numGroup <= 5 then
    for index = 1, numGroup - 1 do
      tempUnit = partyUnits[index]
      if CheckUnits(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  end
  if MV.IsArenaInProgress() then
    local arenaSize = MV.GetArenaSize()
    if arenaSize > 0 then
      for index = 1, arenaSize do
        tempUnit = arenaUnits[index]
        if CheckUnits(tempUnit, targetUnit) then
          return tempUnit
        end
      end
    end
  end
  if MV.InInstance() then
    for index = 1, 5 do
      tempUnit = bossUnits[index]
      if CheckUnits(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  end
  return CheckUnits("player", targetUnit) and "player" or nil
end

local function GetTargetByUnit(unit)
  unit = unit:gsub("^%l", string.upper)
  local f = _G["MV_" .. unit]
  if f then
    return f
  end
  return nil
end

function MV.UpdateTargetIndicator(frame)
  if not frame or not frame.unit then return end
  if frame.unit == "player" or MV.IsUnitUnit(frame.unit, "player") then
    return
  end

  local targetUnit = GetTargetUnit(frame)
  if not MV.IsString(targetUnit) then
    MV.ResetTargetIndicator(frame)
    return
  end

  local targetFrame
  if MV.IsUnitUnit(targetUnit, "player") then
    targetFrame = GetTargetByUnit("player")
  else
    targetFrame = GetTargetByUnit(targetUnit)
  end
  if not targetFrame then return end
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

function MV.UpdateTargetIndicatorByGUID(frame)
  if frame.unit == "player" or MV.IsUnitUnit(frame.unit, "player") then
    return
  end
  MV.ResetTargetIndicator(frame)
  local targetUnit = frame.unit .. "target"
  local ok, targetGUID = MV.CallExternalFunction({
    functionName = "UnitGUID",
    args = { targetUnit },
  })
  if not ok then
    print(ok, targetGUID)
  end
  local targetFrame
  if MV.IsUnitUnit(targetUnit, "player") then
    targetFrame = GetTargetByUnit("player")
  else
    targetFrame = MV.frameByGUID[targetGUID]
  end
  if not targetFrame then
    return
  end
  targetFrame.targeted = targetFrame.targeted or {}
  targetFrame.targeted[frame.unit] = true
  targetFrame.innerBorder:SetShown(true)

  frame.targetFrame = targetFrame
end

function MV.SetUnitGUID(frame)
  if MV.UnitExists(frame.unit) then
    local ok, unitGUID = MV.CallExternalFunction({
      functionName = "UnitGUID",
      args = { frame.unit },
    })
    if not ok then
      print(ok, unitGUID)
      return
    end
    MV.frameByGUID[unitGUID] = frame
  end
end

function MV.ResetTargetIndicator(frame)
  if frame.targetFrame and frame.targetFrame.targeted then
    frame.targetFrame.targeted[frame.unit] = nil
    if not next(frame.targetFrame.targeted) then
      frame.targetFrame.innerBorder:SetShown(false)
    end
  end
  frame.targetFrame = nil
end
