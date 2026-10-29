local _, MF = ...
local C_UnitAuras = _G.C_UnitAuras
local C_CurveUtil = _G.C_CurveUtil
local C_DurationUtil = _G.C_DurationUtil
local C_PvP = _G.C_PvP
local C_Spell = _G.C_Spell
local C_LossOfControl = _G.C_LossOfControl

-- True when `value` is "secret" (WoW blocks reading/comparing these), so
-- callers can check before using it. issecretvalue never throws, and is read
-- at call time so a client without it (or a test) still works.
function MF.IsSecretSafe(value)
  local isSecret = _G.issecretvalue
  if not isSecret then
    return false
  end
  return isSecret(value) == true
end
local IsSecretSafe = MF.IsSecretSafe

local function IsSecretUnit(unit)
  return type(unit) == "string" and IsSecretSafe(unit)
end

-- turns an (ok, value) pair into a plain true/false, safely
function MF.SafeBoolResult(ok, value)
  if not ok or IsSecretSafe(value) then
    return false
  end
  return value == true
end

-- A boolean API result as a plain true/false: secret and non-boolean
-- results count as false.
function MF.PlainBool(value)
  if IsSecretSafe(value) then
    return false
  end
  return value == true
end
local PlainBool = MF.PlainBool

-- The unit and aura wrappers below call the API directly (no pcall, no
-- argument tables): they run on every UNIT_HEALTH/UNIT_AURA/UNIT_TARGET for
-- every visible frame. Callers pass unit tokens we built ourselves.
local UnitExists = _G.UnitExists
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsConnected = _G.UnitIsConnected
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsUnit = _G.UnitIsUnit
local UnitReaction = _G.UnitReaction
local UnitCanAttack = _G.UnitCanAttack
local UnitClass = _G.UnitClass
local UnitHealthMax = _G.UnitHealthMax
local UnitGetTotalAbsorbs = _G.UnitGetTotalAbsorbs
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitInParty = _G.UnitInParty
local UnitHealthPercent = _G.UnitHealthPercent
local UnitPowerPercent = _G.UnitPowerPercent
local GetRaidTargetIndex = _G.GetRaidTargetIndex

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

local NO_ARGS = {}

-- params.functionName is required; everything else is optional
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
  -- 9 return values covers the widest call we make (UnitCastingInfo)
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
  if type(unit) ~= "string" then
    return false
  end
  return PlainBool(UnitExists(unit))
end

function MF.UnitIsDeadOrGhost(unit)
  if type(unit) ~= "string" then
    return false
  end
  return PlainBool(UnitIsDeadOrGhost(unit))
end

function MF.UnitIsConnected(unit)
  if type(unit) ~= "string" then
    return false
  end
  return PlainBool(UnitIsConnected(unit))
end

function MF.UnitIsPlayer(unit)
  if type(unit) ~= "string" then
    return false
  end
  return PlainBool(UnitIsPlayer(unit))
end

function MF.UnitReaction(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, UnitReaction("player", unit)
end

-- True when `unit` is the player's current target.
function MF.UnitIsUnit(unit)
  if type(unit) ~= "string" then
    return false
  end
  return PlainBool(UnitIsUnit("target", unit))
end

function MF.UnitCanAttack(unit)
  if type(unit) ~= "string" then
    return false, "unit must be a string"
  end
  local result = UnitCanAttack("player", unit)
  if IsSecretSafe(result) then
    return false, "UnitCanAttack returned a secret value"
  end

  return true, (result == true)
end

-- returns ok, then UnitClass's own results (localized name, class file, class ID)
function MF.UnitClass(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, UnitClass(unit)
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
  if type(unit) ~= "string" or type(otherUnit) ~= "string" then
    return false
  end
  return PlainBool(UnitIsUnit(unit, otherUnit))
end

function MF.UnitHealthMax(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, UnitHealthMax(unit)
end

function MF.UnitGetTotalAbsorbs(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, UnitGetTotalAbsorbs(unit)
end

-- aura data can come back secret when restricted (combat/PvP), so check that first
function MF.GetUnitAuras(unit, filter, maxRemaining, sortRule, sortDirection)
  local result = C_UnitAuras.GetUnitAuras(unit, filter, maxRemaining, sortRule, sortDirection)
  if IsSecretSafe(result) or type(result) ~= "table" then
    return false
  end
  return true, result, #result
end

function MF.GetAuraDispelTypeColor(unit, auraInstanceID, curve)
  return true, C_UnitAuras.GetAuraDispelTypeColor(unit, auraInstanceID, curve)
end

function MF.GetAuraDuration(unit, auraInstanceID)
  return true, C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
end

function MF.SetCooldown(cooldown, start, duration)
  if type(cooldown) ~= "table" or type(start) ~= "number" or type(duration) ~= "number" then
    return false
  end
  cooldown:SetCooldown(start, duration)
  return true
end

function MF.SetShowCountdownNumbers(cooldown, show)
  if type(cooldown) ~= "table" or type(show) ~= "boolean" then
    return false
  end
  cooldown:SetShowCountdownNumbers(show)
  return true
end

-- forceShowDrawEdge is optional - keep the 2-arg and 3-arg calls separate,
-- since "omitted" and "explicitly nil" aren't always the same to this API
function MF.SetCooldownFromDurationObject(cooldown, durationObject, forceShowDrawEdge)
  if type(cooldown) ~= "table" or type(durationObject) ~= "userdata" then
    return false
  end
  if forceShowDrawEdge == nil then
    cooldown:SetCooldownFromDurationObject(durationObject)
    return true
  end
  if type(forceShowDrawEdge) ~= "boolean" then
    return false
  end
  cooldown:SetCooldownFromDurationObject(durationObject, forceShowDrawEdge)
  return true
end

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
  return true, C_PvP.GetActiveMatchState()
end

function MF.IsMatchComplete()
  return true, C_PvP.IsMatchComplete()
end

function MF.IsMatchConsideredArena()
  return true, C_PvP.IsMatchConsideredArena()
end

function MF.IsMatchActive()
  return true, C_PvP.IsMatchActive()
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

-- wraps ArenaUtil.UnitExists, not the same as MF.UnitExists above
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
  if type(id) ~= "number" or type(unit) ~= "string" then
    return false
  end
  return true, C_Spell.IsSpellInRange(id, unit)
end

function MF.GetRaidTargetIndex(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, GetRaidTargetIndex(unit)
end

-- returns ok, then: name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID
function MF.UnitCastingInfo(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, UnitCastingInfo(unit)
end

-- same as UnitCastingInfo but no castID
function MF.UnitChannelInfo(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, UnitChannelInfo(unit)
end

function MF.UnitGroupRolesAssigned(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, UnitGroupRolesAssigned(unit)
end

function MF.UnitInParty(unit)
  if type(unit) ~= "string" then
    return false
  end
  return true, UnitInParty(unit)
end

function MF.UnitHealthPercent(unit, curve)
  if type(unit) ~= "string" or type(curve) ~= "userdata" then
    return false
  end
  return true, UnitHealthPercent(unit, false, curve)
end

function MF.UnitPowerPercent(unit, curve)
  if type(unit) ~= "string" or type(curve) ~= "userdata" then
    return false
  end
  return true, UnitPowerPercent(unit, nil, true, curve)
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
