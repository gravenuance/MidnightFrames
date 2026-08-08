local _, MF = ...
local C_UnitAuras = _G.C_UnitAuras
local C_CurveUtil = _G.C_CurveUtil
local C_DurationUtil = _G.C_DurationUtil
local C_PvP = _G.C_PvP
local C_Spell = _G.C_Spell
local C_LossOfControl = _G.C_LossOfControl

-- Secret values can't be compared or boolean-tested by insecure code (a
-- boolean-typed secret can't even be truthiness-tested), so any value that
-- came back from an external API must be run through this before it's used
-- in ==, <, >, arithmetic, string concatenation, or as a table key.
function MF.IsSecretSafe(value)
  if not issecretvalue then
    return false
  end

  local ok, result = pcall(issecretvalue, value)
  if not ok then
    return false
  end
  return result == true
end
local IsSecretSafe = MF.IsSecretSafe

local function IsSecretUnit(unit)
  return type(unit) == "string" and IsSecretSafe(unit)
end

-- Resolves an (ok, value) pair from CallExternalFunction that is expected to
-- be a plain boolean into a definite true/false, refusing to truthiness-test
-- the raw value directly (unsafe if it turns out to be a secret boolean).
function MF.SafeBoolResult(ok, value)
  if not ok or IsSecretSafe(value) then
    return false
  end
  return value == true
end

function MF.IsNil(value)
  if IsSecretSafe(value) then
    return false
  end
  return value == nil
end

function MF.IsOfType(expectedType, value)
  if MF.IsNil(value) then
    return false, (tostring(value) or "nil") .. " must not be nil"
  end
  if type(value) ~= expectedType then
    return false, (tostring(value) or "<non-string>") .. " must be a " .. expectedType .. ", got " .. type(value)
  end
  return true
end

function MF.IsNumber(value)
  return MF.IsOfType("number", value)
end

function MF.IsString(value)
  return MF.IsOfType("string", value)
end

function MF.IsBoolean(value)
  return MF.IsOfType("boolean", value)
end

function MF.IsTable(value)
  return MF.IsOfType("table", value)
end

function MF.IsFunction(value)
  return MF.IsOfType("function", value)
end

function MF.IsUserData(value)
  return MF.IsOfType("userdata", value)
end

function MF.IsOfObjectType(expectedType, value)
  if MF.IsNil(value) then
    return false, (tostring(value) or "nil") .. " must not be nil"
  end
  if not value:IsObjectType(expectedType) then
    return false, (tostring(value) or "<non-string>") .. " must be a " .. expectedType .. ", got " .. type(value)
  end
  return true
end

function MF.IsFrame(value)
  return MF.IsOfObjectType("Frame", value)
end

function MF.IsButton(value)
  return MF.IsOfObjectType("Button", value)
end

function MF.IsTexture(value)
  return MF.IsOfObjectType("Texture", value)
end

-- Shared, never-mutated stand-in for calls with no args, so every no-arg
-- CallExternalFunction call doesn't allocate its own throwaway table.
local NO_ARGS = {}

--@params.args can be nil
--@params.argumentValidators can be nil
--@params.namespace can be nil, accepts a table or userdata
--@params.functionName cannot be nil, must be a string
function MF.CallExternalFunction(params)
  local namespace = params.namespace
  local argumentValidators = params.argumentValidators
  local args = params.args or NO_ARGS

  if MF.IsNil(namespace) then
    namespace = _G
  end
  if MF.IsNil(params.functionName) then
    return false, ("Function cannot be nil.")
  end

  if not (MF.IsTable(namespace) or MF.IsUserData(namespace)) then
    return false, ("Namespace is not valid.")
  end

  local func = namespace[params.functionName]
  if not MF.IsFunction(func) then
    return false, ("Not a valid function.")
  end

  if argumentValidators and MF.IsTable(argumentValidators) then
    for index, validator in ipairs(argumentValidators) do
      if validator then
        local ok, _ = validator(args[index])
        if not ok then
          return false, ("Argument " .. index .. " is not valid.")
        end
      end
    end
  end
  -- 9 slots to cover UnitCastingInfo (name, text, texture, startTimeMS,
  -- endTimeMS, isTradeSkill, castID, notInterruptible, spellID) - the widest
  -- return signature any wrapper in this file needs; existing callers with
  -- fewer return values are unaffected.
  local ok, r1, r2, r3, r4, r5, r6, r7, r8, r9 = pcall(func, unpack(args))
  if not ok then
    local errorMessage = r1
    return false, errorMessage
  end
  return true, r1, r2, r3, r4, r5, r6, r7, r8, r9
end

function MF.UnitExists(unit)
  if IsSecretUnit(unit) then
    print("Warning: Attempted to check existence of a secret unit. This is not allowed for security reasons.")
    return false
  end

  local ok, result = MF.CallExternalFunction({
    functionName = "UnitExists",
    args = { unit },
    argumentValidators = { MF.IsString },
  })
  return MF.SafeBoolResult(ok, result)
end

function MF.UnitIsDeadOrGhost(unit)
  local ok, result = MF.CallExternalFunction(
    {
      functionName = "UnitIsDeadOrGhost",
      args = { unit },
      argumentValidators = { MF.IsString }
    }
  )
  return MF.SafeBoolResult(ok, result)
end

function MF.UnitIsConnected(unit)
  local ok, result = MF.CallExternalFunction(
    {
      functionName = "UnitIsConnected",
      args = { unit },
      argumentValidators = { MF.IsString }
    }
  )
  return MF.SafeBoolResult(ok, result)
end

function MF.UnitIsPlayer(unit)
  local ok, result = MF.CallExternalFunction(
    {
      functionName = "UnitIsPlayer",
      args = { unit },
      argumentValidators = { MF.IsString }
    }
  )
  return MF.SafeBoolResult(ok, result)
end

function MF.UnitReaction(unit)
  local ok, result = MF.CallExternalFunction(
    {
      functionName = "UnitReaction",
      args = { "player", unit },
      argumentValidators = { MF.IsString, MF.IsString }
    }
  )
  return ok, result
end

function MF.UnitIsUnit(unit)
  local ok, result = MF.CallExternalFunction(
    {
      functionName = "UnitIsUnit",
      args = { "target", unit },
      argumentValidators = { MF.IsString, MF.IsString }
    }
  )
  return MF.SafeBoolResult(ok, result)
end

function MF.UnitCanAttack(unit)
  local ok, result = MF.CallExternalFunction(
    {
      functionName = "UnitCanAttack",
      args = { "player", unit },
      argumentValidators = { MF.IsString, MF.IsString }
    }
  )
  if not ok then
    return false, result
  end
  if IsSecretSafe(result) then
    return false, "UnitCanAttack returned a secret value"
  end

  return true, (result == true)
end

function MF.UnitClass(unit)
  local ok, r1, r2, r3 = MF.CallExternalFunction(
    {
      functionName = "UnitClass",
      args = { unit },
      argumentValidators = { MF.IsString }
    }
  )
  return ok, r1, r2, r3
end

function MF.GetField(obj, key)
  if not MF.IsTable(obj) and not MF.IsUserData(obj) then
    return false, "Wrong type"
  end
  local ok, value = pcall(function() return obj[key] end)
  return ok, value
end

function MF.IsUnitUnit(unit, otherUnit)
  if IsSecretUnit(unit) or IsSecretUnit(otherUnit) then
    print("Warning: Attempted to compare a secret unit. This is not allowed for security reasons.")
    return false
  end

  local ok, result = MF.CallExternalFunction({
    functionName = "UnitIsUnit",
    args = { unit, otherUnit },
    argumentValidators = { MF.IsString, MF.IsString }
  })

  return MF.SafeBoolResult(ok, result)
end

function MF.UnitHealthMax(unit)
  local ok, result = MF.CallExternalFunction(
    {
      functionName = "UnitHealthMax",
      args = { unit },
      argumentValidators = { MF.IsString }
    }
  )
  return ok, result
end

function MF.UnitGetTotalAbsorbs(unit)
  local ok, result = MF.CallExternalFunction(
    {
      functionName = "UnitGetTotalAbsorbs",
      args = { unit },
      argumentValidators = { MF.IsString }
    }
  )
  return ok, result
end

-- Validator arrays are static per call site; hoisted so these run on every
-- UNIT_AURA (per aura button, per frame) without reallocating them per call.
local GET_UNIT_AURAS_VALIDATORS = { MF.IsString, MF.IsString, MF.IsNumber, MF.IsNumber, MF.IsNumber }
local DISPEL_COLOR_VALIDATORS = { MF.IsString, MF.IsNumber, MF.IsUserData }
local AURA_DURATION_VALIDATORS = { MF.IsString, MF.IsNumber }

-- GetUnitAuras is expected to start returning an opaque/secret vector while
-- the unit's aura data is restricted (combat/encounters/PvP, coming in patch
-- 12.1). MF.IsSecretSafe(result) catches that up front so callers only ever
-- get handed a table already confirmed safe to # and index into.
function MF.GetUnitAuras(unit, filter, maxRemaining, sortRule, sortDirection)
  local ok, result = MF.CallExternalFunction({
    namespace = C_UnitAuras,
    functionName = "GetUnitAuras",
    args = { unit, filter, maxRemaining, sortRule, sortDirection },
    argumentValidators = GET_UNIT_AURAS_VALIDATORS
  })
  if not ok or not MF.IsTable(result) or MF.IsSecretSafe(result) then
    return false
  end
  return true, result, #result
end

function MF.GetAuraDispelTypeColor(unit, auraInstanceID, curve)
  return MF.CallExternalFunction({
    namespace = C_UnitAuras,
    functionName = "GetAuraDispelTypeColor",
    args = { unit, auraInstanceID, curve },
    argumentValidators = DISPEL_COLOR_VALIDATORS
  })
end

function MF.GetAuraDuration(unit, auraInstanceID)
  return MF.CallExternalFunction({
    namespace = C_UnitAuras,
    functionName = "GetAuraDuration",
    args = { unit, auraInstanceID },
    argumentValidators = AURA_DURATION_VALIDATORS
  })
end

-- Cooldown widget wrappers (Cooldown:SetCooldown / :SetShowCountdownNumbers /
-- :SetCooldownFromDurationObject) - shared by DRUtil, TrinketUtil and AuraUtil,
-- which all drive the same handful of Blizzard Cooldown widget methods.
function MF.SetCooldown(cooldown, start, duration)
  return MF.CallExternalFunction({
    namespace = cooldown,
    functionName = "SetCooldown",
    args = { cooldown, start, duration },
    argumentValidators = { MF.IsTable, MF.IsNumber, MF.IsNumber }
  })
end

function MF.SetShowCountdownNumbers(cooldown, show)
  return MF.CallExternalFunction({
    namespace = cooldown,
    functionName = "SetShowCountdownNumbers",
    args = { cooldown, show },
    argumentValidators = { MF.IsTable, MF.IsBoolean }
  })
end

-- forceShowDrawEdge is optional: TrinketUtil's caller omits it (2-arg call),
-- AuraUtil's passes true (3-arg call) - preserve both call shapes rather than
-- always sending a 3rd literal nil, since "argument omitted" and "argument
-- explicitly nil" aren't guaranteed equivalent for this API.
function MF.SetCooldownFromDurationObject(cooldown, durationObject, forceShowDrawEdge)
  if forceShowDrawEdge == nil then
    return MF.CallExternalFunction({
      namespace = cooldown,
      functionName = "SetCooldownFromDurationObject",
      args = { cooldown, durationObject },
      argumentValidators = { MF.IsTable, MF.IsUserData }
    })
  end
  return MF.CallExternalFunction({
    namespace = cooldown,
    functionName = "SetCooldownFromDurationObject",
    args = { cooldown, durationObject, forceShowDrawEdge },
    argumentValidators = { MF.IsTable, MF.IsUserData, MF.IsBoolean }
  })
end

-- C_CurveUtil wrappers - shared by AuraUtil (dispel-color curve), FrameUtil
-- (power curve) and HealthFrameUtil (health curve).
function MF.CreateCurve()
  return MF.CallExternalFunction({
    namespace = C_CurveUtil,
    functionName = "CreateCurve"
  })
end

function MF.CreateColorCurve()
  return MF.CallExternalFunction({
    namespace = C_CurveUtil,
    functionName = "CreateColorCurve"
  })
end

function MF.SetCurveType(curve, curveType)
  return MF.CallExternalFunction({
    namespace = curve,
    functionName = "SetType",
    args = { curve, curveType },
    argumentValidators = { MF.IsUserData, MF.IsNumber }
  })
end

-- value's type varies by caller (a plain number for the health/power curves,
-- a Color object for the dispel-type curve), so only curve/key are validated.
function MF.AddCurvePoint(curve, key, value)
  return MF.CallExternalFunction({
    namespace = curve,
    functionName = "AddPoint",
    args = { curve, key, value },
    argumentValidators = { MF.IsUserData, MF.IsNumber }
  })
end

function MF.CreateDuration()
  return MF.CallExternalFunction({
    namespace = C_DurationUtil,
    functionName = "CreateDuration"
  })
end

function MF.SetTimeFromStart(durationObject, startTime, duration)
  return MF.CallExternalFunction({
    namespace = durationObject,
    functionName = "SetTimeFromStart",
    args = { durationObject, startTime, duration }
  })
end

function MF.GetActiveMatchState()
  return MF.CallExternalFunction({ namespace = C_PvP, functionName = "GetActiveMatchState" })
end

function MF.IsMatchComplete()
  return MF.CallExternalFunction({ namespace = C_PvP, functionName = "IsMatchComplete" })
end

function MF.IsMatchConsideredArena()
  return MF.CallExternalFunction({ namespace = C_PvP, functionName = "IsMatchConsideredArena" })
end

function MF.IsMatchActive()
  return MF.CallExternalFunction({ namespace = C_PvP, functionName = "IsMatchActive" })
end

function MF.GetArenaOpponentSpec(index)
  return MF.CallExternalFunction({
    functionName = "GetArenaOpponentSpec",
    args = { index },
    argumentValidators = { MF.IsNumber }
  })
end

function MF.GetSpecializationInfoByID(specID)
  return MF.CallExternalFunction({
    functionName = "GetSpecializationInfoByID",
    args = { specID },
    argumentValidators = { MF.IsNumber }
  })
end

function MF.GetNumArenaOpponentSpecs()
  return MF.CallExternalFunction({ functionName = "GetNumArenaOpponentSpecs" })
end

-- Wraps Blizzard's ArenaUtil.UnitExists namespace API - distinct from
-- MF.UnitExists above, which wraps the global UnitExists function.
function MF.ArenaUtilUnitExists(unit)
  return MF.CallExternalFunction({
    namespace = _G.ArenaUtil,
    functionName = "UnitExists",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

function MF.GetArenaCrowdControlInfo(unit)
  return MF.CallExternalFunction({
    namespace = C_PvP,
    functionName = "GetArenaCrowdControlInfo",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

function MF.GetArenaCrowdControlDuration(unit)
  return MF.CallExternalFunction({
    namespace = C_PvP,
    functionName = "GetArenaCrowdControlDuration",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

function MF.GetSpellTexture(spellId)
  return MF.CallExternalFunction({
    namespace = C_Spell,
    functionName = "GetSpellTexture",
    args = { spellId },
    argumentValidators = { MF.IsNumber }
  })
end

function MF.IsSpellHelpful(id)
  return MF.CallExternalFunction({
    namespace = C_Spell,
    functionName = "IsSpellHelpful",
    args = { id },
    argumentValidators = { MF.IsNumber }
  })
end

function MF.SpellHasRange(id)
  return MF.CallExternalFunction({
    namespace = C_Spell,
    functionName = "SpellHasRange",
    args = { id },
    argumentValidators = { MF.IsNumber }
  })
end

function MF.IsSpellInRange(id, unit)
  return MF.CallExternalFunction({
    namespace = C_Spell,
    functionName = "IsSpellInRange",
    args = { id, unit },
    argumentValidators = { MF.IsNumber, MF.IsString }
  })
end

function MF.GetRaidTargetIndex(unit)
  return MF.CallExternalFunction({
    functionName = "GetRaidTargetIndex",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

-- name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID,
-- notInterruptible, spellID - the 9-value signature CallExternalFunction's
-- r1..r9 capture above exists specifically to carry in full.
function MF.UnitCastingInfo(unit)
  return MF.CallExternalFunction({
    functionName = "UnitCastingInfo",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

-- name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible,
-- spellID - one fewer field than UnitCastingInfo (no castID).
function MF.UnitChannelInfo(unit)
  return MF.CallExternalFunction({
    functionName = "UnitChannelInfo",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

function MF.UnitGroupRolesAssigned(unit)
  return MF.CallExternalFunction({
    functionName = "UnitGroupRolesAssigned",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

function MF.UnitInParty(unit)
  return MF.CallExternalFunction({
    functionName = "UnitInParty",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

function MF.UnitHealthPercent(unit, curve)
  return MF.CallExternalFunction({
    functionName = "UnitHealthPercent",
    args = { unit, false, curve },
    argumentValidators = { MF.IsString, MF.IsBoolean, MF.IsUserData }
  })
end

function MF.UnitPowerPercent(unit, curve)
  return MF.CallExternalFunction({
    functionName = "UnitPowerPercent",
    args = { unit, nil, true, curve },
    argumentValidators = { MF.IsString, MF.IsNil, MF.IsBoolean, MF.IsUserData }
  })
end

function MF.GetActiveLossOfControlDataCountByUnit(unit)
  return MF.CallExternalFunction({
    namespace = C_LossOfControl,
    functionName = "GetActiveLossOfControlDataCountByUnit",
    args = { unit },
    argumentValidators = { MF.IsString }
  })
end

function MF.GetActiveLossOfControlDataByUnit(unit, index)
  return MF.CallExternalFunction({
    namespace = C_LossOfControl,
    functionName = "GetActiveLossOfControlDataByUnit",
    args = { unit, index },
    argumentValidators = { MF.IsString, MF.IsNumber }
  })
end

-- tray varies per call site (each frame's own SpellDiminishStatusTray), so
-- unlike the C_-namespace wrappers above this takes the namespace as a param.
function MF.GetLayoutChildren(tray)
  return MF.CallExternalFunction({
    namespace = tray,
    functionName = "GetLayoutChildren",
    args = { tray }
  })
end
