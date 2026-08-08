local _, MF = ...

local function IsMatchEngaged()
  local ok, result = MF.GetActiveMatchState()
  if not ok or MF.IsSecretSafe(result) then return false end
  return result == Enum.PvPMatchState.Engaged
end

local function IsMatchComplete()
  local ok, isComplete = MF.IsMatchComplete()
  return MF.SafeBoolResult(ok, isComplete)
end

function MF.IsInArena()
  local ok, asArena = MF.IsMatchConsideredArena()
  if MF.SafeBoolResult(ok, asArena) then
    local ok2, isActive = MF.IsMatchActive()
    if MF.SafeBoolResult(ok2, isActive) then return true end
    if IsMatchComplete() then return true end
  end
  return false
end

function MF.IsInPrep()
  return MF.IsInArena() and not IsMatchEngaged() and not IsMatchComplete() and not MF_ArenaTestMode
end

function MF.IsArenaInProgress()
  return MF.IsInArena() and IsMatchEngaged()
end

function MF.IsUnit(index)
  local ok, specID = MF.GetArenaOpponentSpec(index)
  if not ok or MF.IsSecretSafe(specID) then return false end
  return MF.IsNumber(specID) and specID > 0, specID
end

function MF.GetOpponentSpecAndClass(index)
  local ok, specID = MF.GetArenaOpponentSpec(index)
  if ok then
    local ok2, _, _, _, icon, _, class = MF.GetSpecializationInfoByID(specID)
    if ok2 then return icon, class end
  end
end

function MF.GetArenaSize()
  local ok, totalSpecs = MF.GetNumArenaOpponentSpecs()
  if ok and MF.IsNumber(totalSpecs) and not MF.IsSecretSafe(totalSpecs) and totalSpecs > 0 then
    return totalSpecs
  end

  return 0
end

function MF.IsInStealth(idx, unit)
  if not MF.IsUnit(idx) then
    return false
  end

  local ok, unitExists = MF.ArenaUtilUnitExists(unit)
  if not ok or MF.IsSecretSafe(unitExists) then return false end
  return not unitExists and MF.IsArenaInProgress()
end
