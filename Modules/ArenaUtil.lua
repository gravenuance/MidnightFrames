local _, MV = ...

local function IsMatchEngaged()
  local ok, result = MV.CallExternalFunction({
    namespace = C_PvP,
    functionName = "GetActiveMatchState",
  })
  if not ok or MV.IsSecretSafe(result) then return false end
  return result == Enum.PvPMatchState.Engaged
end

local function IsMatchComplete()
  local ok, isComplete = MV.CallExternalFunction({
    namespace = C_PvP,
    functionName = "IsMatchComplete",
  })
  return MV.SafeBoolResult(ok, isComplete)
end

function MV.IsInArena()
  local ok, asArena = MV.CallExternalFunction({
    namespace = C_PvP,
    functionName = "IsMatchConsideredArena",
  })
  if MV.SafeBoolResult(ok, asArena) then
    local ok2, isActive = MV.CallExternalFunction({
      namespace = C_PvP,
      functionName = "IsMatchActive",
    })
    if MV.SafeBoolResult(ok2, isActive) then return true end
    if IsMatchComplete() then return true end
  end
  return false
end

function MV.IsInPrep()
  return MV.IsInArena() and not IsMatchEngaged() and not IsMatchComplete() and not MV_ArenaTestMode
end

function MV.IsArenaInProgress()
  return MV.IsInArena() and IsMatchEngaged()
end

function MV.IsUnit(index)
  local ok, specID = MV.CallExternalFunction({
    functionName = "GetArenaOpponentSpec",
    args = { index },
    argumentValidators = { MV.IsNumber }
  })
  if not ok or MV.IsSecretSafe(specID) then return false end
  return MV.IsNumber(specID) and specID > 0, specID
end

function MV.GetOpponentSpecAndClass(index)
  local ok, specID = MV.CallExternalFunction({
    functionName = "GetArenaOpponentSpec",
    args = { index },
    argumentValidators = { MV.IsNumber },
  })
  if ok then
    local ok2, _, _, _, icon, _, class = MV.CallExternalFunction({
      functionName = "GetSpecializationInfoByID",
      args = { specID },
      argumentValidators = { MV.IsNumber }
    })
    if ok2 then return icon, class end
  end
end

function MV.GetArenaSize()
  local ok, totalSpecs = MV.CallExternalFunction({
    functionName = "GetNumArenaOpponentSpecs"
  })
  if ok and MV.IsNumber(totalSpecs) and not MV.IsSecretSafe(totalSpecs) and totalSpecs > 0 then
    return totalSpecs
  end

  return 0
end

function MV.IsInStealth(idx, unit)
  if not MV.IsUnit(idx) then
    return false
  end

  local ok, unitExists = MV.CallExternalFunction({
    namespace = _G.ArenaUtil,
    functionName = "UnitExists",
    args = { unit },
    argumentValidators = { MV.IsString }
  })
  if not ok or MV.IsSecretSafe(unitExists) then return false end
  return not unitExists and MV.IsArenaInProgress()
end
