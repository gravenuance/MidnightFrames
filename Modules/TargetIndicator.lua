local _, MV = ...

local arenaTargetUnits = {}
for i = 1, 5 do
  arenaTargetUnits[i] = "arena" .. i .. "target"
end

local partyTargetUnits = {}
for i = 1, 4 do
  partyTargetUnits[i] = "party" .. i .. "target"
end

local raidTargetUnits = {}
for i = 1, 40 do
  raidTargetUnits[i] = "raid" .. i .. "target"
end

local nameplateTargetUnits = {}
for i = 1, 40 do
  nameplateTargetUnits[i] = "nameplate" .. i .. "target"
end

local bossTargetUnits = {}
for i = 1, 5 do
  bossTargetUnits[i] = "boss" .. i .. "target"
end

local function CheckUnits(unit, otherUnit, sourceHostile, targets)
  if MV.UnitExists(unit) then
    if MV.IsUnitUnit(unit, otherUnit) then
      if sourceHostile then
        targets.enemies = targets.enemies + 1
      else
        targets.friendly = targets.friendly + 1
      end
    end
  end
end

function MV.CountTargetUnits(frame)
  local ok, result = MV.UnitCanAttack(frame.unit)
  if not ok then
    print(result)
    return
  end
  local targets = {
    enemies = 0,
    friendly = 0,
  }
  local tempUnit
  local _, raid = MV.CallExternalFunction({
    functionName = "IsInRaid"
  })
  if raid then
    local _, numGroup = MV.CallExternalFunction({
      functionName = "GetNumGroupMembers"
    })
    if MV.IsNumber(numGroup) then
      for index = 1, numGroup do
        tempUnit = raidTargetUnits[index]
        CheckUnits(tempUnit, frame.unit, result, targets)
      end
    end
  end
  local _, group = MV.CallExternalFunction({
    functionName = "IsInGroup"
  })
  if group then
    local _, numGroup = MV.CallExternalFunction({
      functionName = "GetNumGroupMembers"
    })
    if MV.IsNumber(numGroup) then
      for index = 1, numGroup - 1 do
        tempUnit = partyTargetUnits[index]
        CheckUnits(tempUnit, frame.unit, result, targets)
      end
    end
  end
  if MV.IsArenaInProgress() then
    local arenaSize = MV.GetArenaSize()
    if arenaSize > 0 then
      for index = 1, arenaSize do
        tempUnit = arenaTargetUnits[index]
        CheckUnits(tempUnit, frame.unit, not result, targets)
      end
    end
  end
  if MV.InInstance() then
    for index = 1, 5 do
      tempUnit = bossTargetUnits[index]
      CheckUnits(tempUnit, frame.unit, not result, targets)
    end
  end
  frame.outerBorder:SetShown(targets.enemies > 0)
  frame.innerBorder:SetShown(targets.friendly > 0)
end
