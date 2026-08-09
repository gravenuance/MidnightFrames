local _, MF = ...

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
  return MF.IsUnitUnit(unit, otherUnit)
end

local function GetTargetUnit(frame)
  local targetUnit = frame.unit .. "target"
  local tempUnit
  local numGroup = MF.NumGroupMembers
  if numGroup > 5 then
    for index = 1, numGroup do
      tempUnit = raidUnits[index]
      if CheckUnits(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  elseif numGroup > 0 then
    for index = 1, numGroup - 1 do
      tempUnit = partyUnits[index]
      if CheckUnits(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  end
  if MF.IsArenaInProgress() then
    local arenaSize = MF.GetArenaSize()
    if arenaSize > 0 then
      for index = 1, arenaSize do
        tempUnit = arenaUnits[index]
        if CheckUnits(tempUnit, targetUnit) then
          return tempUnit
        end
      end
    end
  end
  if MF.InInstance() then
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
  local f = _G["MF_" .. unit]
  if f then
    return f
  end
  return nil
end

function MF.UpdateTargetIndicator(frame)
  if not frame or not frame.unit then return end
  if frame.unit == "player" or MF.IsUnitUnit(frame.unit, "player") then
    return
  end

  local targetUnit = GetTargetUnit(frame)
  if not MF.IsString(targetUnit) then
    MF.ResetTargetIndicator(frame)
    return
  end

  local targetFrame
  if MF.IsUnitUnit(targetUnit, "player") then
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

function MF.ResetTargetIndicator(frame)
  if frame.targetFrame and frame.targetFrame.targeted then
    frame.targetFrame.targeted[frame.unit] = nil
    if not next(frame.targetFrame.targeted) then
      frame.targetFrame.innerBorder:SetShown(false)
    end
  end
  frame.targetFrame = nil
end
