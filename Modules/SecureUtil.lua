local _, MV = ...

local function IsSecretSafe(value)
  if not issecretvalue then
    return false
  end

  local ok, result = pcall(issecretvalue, value)
  if not ok then
    return false
  end
  return result == true
end

function MV.IsNil(value)
  if IsSecretSafe(value) then
    return false
  end
  return value == nil
end

function MV.IsOfType(expectedType, value)
  if MV.IsNil(value) then
    return false, (tostring(value) or "nil") .. " must not be nil"
  end
  if type(value) ~= expectedType then
    return false, (tostring(value) or "<non-string>") .. " must be a " .. expectedType .. ", got " .. type(value)
  end
  return true
end

-- Derived helpers
function MV.IsNumber(value)
  return MV.IsOfType("number", value)
end

function MV.IsString(value)
  return MV.IsOfType("string", value)
end

function MV.IsBoolean(value)
  return MV.IsOfType("boolean", value)
end

function MV.IsTable(value)
  return MV.IsOfType("table", value)
end

function MV.IsFunction(value)
  return MV.IsOfType("function", value)
end

function MV.IsUserData(value)
  return MV.IsOfType("userdata", value)
end

--@args can be nil
--@argumentValidators can be nil
--@namespace can be nil
--@params.functionName cannot be nil
function MV.CallExternalFunction(params)
  local namespace = params.namespace
  local argumentValidators = params.argumentValidators
  local args = params.args or {}

  if MV.IsNil(namespace) then
    namespace = _G
  end
  if MV.IsNil(params.functionName) then
    return false, ("Function cannot be nil.")
  end

  if not (MV.IsTable(namespace) or MV.IsUserData(namespace)) then
    return false, ("Namespace is not valid.")
  end

  local func = namespace[params.functionName]
  if not MV.IsFunction(func) then
    return false, ("Not a valid function.")
  end

  if argumentValidators and MV.IsTable(argumentValidators) then
    for index, validator in ipairs(argumentValidators) do
      if validator then
        local ok, _ = validator(args[index])
        if not ok then
          return false, ("Argument not invalid.")
        end
      end
    end
  end
  local ok, r1, r2, r3, r4, r5, r6 = pcall(func, unpack(args))
  if not ok then
    local errorMessage = r1
    return false, errorMessage
  end
  return true, r1, r2, r3, r4, r5, r6
end

function MV.UnitExists(unit)
  local ok, result = MV.CallExternalFunction(
    {
      functionName = "UnitExists",
      args = { unit },
      argumentValidators = { MV.IsString }
    }
  )
  return ok and result
end

function MV.UnitIsDeadOrGhost(unit)
  local ok, result = MV.CallExternalFunction(
    {
      functionName = "UnitIsDeadOrGhost",
      args = { unit },
      argumentValidators = { MV.IsString }
    }
  )
  return ok and result
end

function MV.UnitIsConnected(unit)
  local ok, result = MV.CallExternalFunction(
    {
      functionName = "UnitIsConnected",
      args = { unit },
      argumentValidators = { MV.IsString }
    }
  )
  return ok and result
end

function MV.UnitIsPlayer(unit)
  local ok, result = MV.CallExternalFunction(
    {
      functionName = "UnitIsPlayer",
      args = { unit },
      argumentValidators = { MV.IsString }
    }
  )
  return ok and result
end

function MV.UnitReaction(unit)
  local ok, result = MV.CallExternalFunction(
    {
      functionName = "UnitReaction",
      args = { "player", unit },
      argumentValidators = { MV.IsString, MV.IsString }
    }
  )
  return ok, result
end

function MV.UnitIsUnit(unit)
  local ok, result = MV.CallExternalFunction(
    {
      functionName = "UnitIsUnit",
      args = { "target", unit },
      argumentValidators = { MV.IsString, MV.IsString }
    }
  )
  return ok and result
end

function MV.UnitCanAttack(unit)
  local ok, result = MV.CallExternalFunction(
    {
      functionName = "UnitCanAttack",
      args = { "player", unit },
      argumentValidators = { MV.IsString, MV.IsString }
    }
  )
  return ok, result
end

function MV.UnitClass(unit)
  local ok, r1, r2, r3 = MV.CallExternalFunction(
    {
      functionName = "UnitClass",
      args = { unit },
      argumentValidators = { MV.IsString }
    }
  )
  return ok, r1, r2, r3
end

function MV.GetField(obj, key)
  if not MV.IsTable(obj) and not MV.IsUserData(obj) then
    return false, "Wrong type"
  end
  local ok, value = pcall(function() return obj[key] end)
  return ok, value
end

function MV.IsUnitUnit(unit, otherUnit)
  if MV.IsString(unit) and MV.IsString(otherUnit) then
    local ok, result = MV.CallExternalFunction({
      functionName = "UnitIsUnit",
      args = { unit, otherUnit },
    })
    return ok and result
  end
  return false
end
