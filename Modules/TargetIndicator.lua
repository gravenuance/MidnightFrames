local _, MV = ...

local arenaTargetUnits = {}
for i = 1, 5 do
  arenaTargetUnits[i] = "arena" .. i
end

local partyTargetUnits = {}
for i = 1, 4 do
  partyTargetUnits[i] = "party" .. i
end

local raidTargetUnits = {}
for i = 1, 40 do
  raidTargetUnits[i] = "raid" .. i
end

local bossTargetUnits = {}
for i = 1, 5 do
  bossTargetUnits[i] = "boss" .. i
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
  local playerTarget = "playertarget"
  local targetUnit = frame.unit .. "target"
  if not MV.IsString(targetUnit) then return end
  local tempUnit
  if _G.IsInRaid() then
    local _, numGroup = MV.CallExternalFunction({
      functionName = "GetNumGroupMembers"
    })
    if MV.IsNumber(numGroup) then
      for index = 1, numGroup do
        if MV.IsUnitUnit(tempUnit, playerTarget) then
          break
        end
        tempUnit = raidTargetUnits[index]
        if CheckUnits(tempUnit, targetUnit) then
          return tempUnit
        end
      end
    end
  elseif _G.IsInGroup() then
    local _, numGroup = MV.CallExternalFunction({
      functionName = "GetNumGroupMembers"
    })
    if MV.IsNumber(numGroup) then
      for index = 1, numGroup - 1 do
        if MV.IsUnitUnit(tempUnit, playerTarget) then
          break
        end
        tempUnit = partyTargetUnits[index]
        if CheckUnits(tempUnit, targetUnit) then
          return tempUnit
        end
      end
    end
  end
  if MV.IsArenaInProgress() then
    local arenaSize = MV.GetArenaSize()
    if arenaSize > 0 then
      for index = 1, arenaSize do
        tempUnit = arenaTargetUnits[index]
        if CheckUnits(tempUnit, targetUnit) then
          return tempUnit
        end
      end
    end
  end
  if MV.InInstance() then
    for index = 1, 5 do
      tempUnit = bossTargetUnits[index]
      if CheckUnits(tempUnit, targetUnit) then
        return tempUnit
      end
    end
  end
  return false
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
  local targetUnit = GetTargetUnit(frame)
  if not MV.IsString(targetUnit) then return end
  local targetFrame = GetTargetByUnit(targetUnit)
  if targetFrame then
    if targetFrame.targeted then
      targetFrame.targeted[frame.unit] = true
    else
      targetFrame.targeted = { [frame.unit] = true }
    end
    if frame.targetFrame then
      frame.targetFrame.targeted[frame.unit] = nil
      if #frame.targetFrame.targeted == 0 then
        frame.targetFrame.innerBorder:SetShown(false)
      end
    end
    frame.targetFrame = targetFrame
    frame.innerBorder:SetShown(true)
  end
end

function MV.ResetTargetIndicator(frame)
  --frame.outerBorder:SetShown(false)
  frame.innerBorder:SetShown(false)
end
