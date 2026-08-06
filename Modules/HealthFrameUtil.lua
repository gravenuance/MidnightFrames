local _, MV = ...

local C_CurveUtil = _G.C_CurveUtil
local healthCurveType = Enum.LuaCurveType.Linear
local healthCurve

-- Mirrors MV.UpdatePowerLabel's pattern (FrameUtil.lua): UnitHealth/UnitHealthMax
-- can return secret values for units other than the player, so the health bar
-- is driven off UnitHealthPercent through a curve instead of raw absolute
-- numbers. The curve's 0.0->0.0 / 1.0->1.0 mapping lines up with a plain
-- SetMinMaxValues(0, 1), and the result is only ever handed to StatusBar:SetValue
-- (a sanctioned secret-accepting sink) - it's never read, compared, or formatted,
-- so it doesn't matter whether it comes back secret or not.
local function GetHealthCurve()
  if not MV.IsNil(healthCurve) then
    return healthCurve
  end

  local ok, curve = MV.CallExternalFunction({
    namespace = C_CurveUtil,
    functionName = "CreateCurve"
  })
  if not ok then return end
  local ok2 = MV.CallExternalFunction({
    namespace = curve,
    functionName = "SetType",
    args = { curve, healthCurveType },
    argumentValidators = { MV.IsUserData, MV.IsNumber }
  })
  if not ok2 then return end
  curve:AddPoint(0.0, 0.0)
  curve:AddPoint(1.0, 1.0)
  healthCurve = curve
  return healthCurve
end

local function IsDeadOrGhost(unit)
  return MV.UnitExists(unit) and MV.UnitIsDeadOrGhost(unit)
end
local function IsLegalUnit(unit)
  return MV.UnitIsConnected(unit) and MV.UnitExists(unit)
end

local function GetNPCReactionColor(unit)
  local r, g, b = 0, 0.8, 0

  if not IsLegalUnit(unit) then
    return r, g, b
  end

  if IsDeadOrGhost(unit) then
    return 0.4, 0.4, 0.4
  end

  local ok, reaction = MV.UnitReaction(unit)
  if ok and MV.IsNumber(reaction) and not MV.IsSecretSafe(reaction) then
    if reaction >= 5 then
      -- friendly
      return 0, 0.9, 0.2
    elseif reaction == 4 then
      -- neutral
      return 1.0, 0.85, 0.1
    else
      -- hostile
      return 0.85, 0.10, 0.10
    end
  end

  return r, g, b
end

local function GetClassColor(unit, fr, fg, fb)
  local okay, inGroup = MV.CallExternalFunction({
    functionName = "UnitInParty",
    args = { unit },
    argumentValidators = { MV.IsString },
  })
  if MV.UnitIsPlayer(unit) or MV.SafeBoolResult(okay, inGroup) then
    local ok, _, class = MV.UnitClass(unit)
    if ok and MV.IsString(class) and not MV.IsSecretSafe(class) then
      local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
      if c then
        return c.r, c.g, c.b, true
      end
    end
  end


  if MV.UnitExists(unit) then
    local nr, ng, nb = GetNPCReactionColor(unit)
    return nr, ng, nb, true
  end

  return fr or 0, fg or 0.8, fb or 0, false
end

function MV.ApplyClassColor(frame)
  if not frame.health then return end
  local r, g, b = GetClassColor(frame.unit)

  frame.health:SetStatusBarColor(r, g, b, MV.RegAlpha)
  if frame.power then
    local dr, dg, db = r * 0.7, g * 0.7, b * 0.7
    frame.power:SetTextColor(dr, dg, db, 1)
  end
  if frame.pet then
    if frame.pet.health then
      frame.pet.health:SetStatusBarColor(r, g, b, MV.RegAlpha)
    end
  end
end

function MV.UpdateHealthBar(frame)
  frame.health:SetMinMaxValues(0, 1)

  if IsDeadOrGhost(frame.unit) then
    frame.health:SetValue(0)
    return
  elseif not IsLegalUnit(frame.unit) then
    frame.health:SetValue(1)
    return
  end

  local curve = GetHealthCurve()
  if not curve then
    frame.health:SetValue(0)
    return
  end

  local ok, percent = MV.CallExternalFunction({
    functionName = "UnitHealthPercent",
    args = { frame.unit, false, curve },
    argumentValidators = { MV.IsString, MV.IsBoolean, MV.IsUserData }
  })
  if not ok then
    frame.health:SetValue(0)
    return
  end
  frame.health:SetValue(percent)
end

function MV.UpdateAbsorbBar(frame)
  local maxHealth = UnitHealthMax(frame.unit) or 1
  local total = UnitGetTotalAbsorbs(frame.unit) or 0
  frame.absorb:SetMinMaxValues(0, maxHealth)
  frame.absorb:SetValue(total)
end
