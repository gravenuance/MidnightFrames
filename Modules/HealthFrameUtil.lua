local _, MF = ...

local healthCurveType = Enum.LuaCurveType.Linear
local healthCurve

-- Mirrors MF.UpdatePowerLabel's pattern (FrameUtil.lua): UnitHealth/UnitHealthMax
-- can return secret values for units other than the player, so the health bar
-- is driven off UnitHealthPercent through a curve instead of raw absolute
-- numbers. The curve's 0.0->0.0 / 1.0->1.0 mapping lines up with a plain
-- SetMinMaxValues(0, 1), and the result is only ever handed to StatusBar:SetValue
-- (a sanctioned secret-accepting sink) - it's never read, compared, or formatted,
-- so it doesn't matter whether it comes back secret or not.
local function GetHealthCurve()
  if not MF.IsNil(healthCurve) then
    return healthCurve
  end

  local ok, curve = MF.CreateCurve()
  if not ok then return end
  local ok2 = MF.SetCurveType(curve, healthCurveType)
  if not ok2 then return end
  MF.AddCurvePoint(curve, 0.0, 0.0)
  MF.AddCurvePoint(curve, 1.0, 1.0)
  healthCurve = curve
  return healthCurve
end

local function IsDeadOrGhost(unit)
  return MF.UnitExists(unit) and MF.UnitIsDeadOrGhost(unit)
end
local function IsLegalUnit(unit)
  return MF.UnitIsConnected(unit) and MF.UnitExists(unit)
end

local function GetNPCReactionColor(unit)
  local r, g, b = 0, 0.8, 0

  if not IsLegalUnit(unit) then
    return r, g, b
  end

  if IsDeadOrGhost(unit) then
    return 0.4, 0.4, 0.4
  end

  local ok, reaction = MF.UnitReaction(unit)
  if ok and MF.IsNumber(reaction) and not MF.IsSecretSafe(reaction) then
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
  local okay, inGroup = MF.UnitInParty(unit)
  if MF.UnitIsPlayer(unit) or MF.SafeBoolResult(okay, inGroup) then
    local ok, _, class = MF.UnitClass(unit)
    if ok and MF.IsString(class) and not MF.IsSecretSafe(class) then
      local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
      if c then
        return c.r, c.g, c.b, true
      end
    end
  end


  if MF.UnitExists(unit) then
    local nr, ng, nb = GetNPCReactionColor(unit)
    return nr, ng, nb, true
  end

  return fr or 0, fg or 0.8, fb or 0, false
end

function MF.ApplyClassColor(frame)
  if not frame.health then return end
  local r, g, b = GetClassColor(frame.unit)

  frame.health:SetStatusBarColor(r, g, b, MF.RegAlpha)
  if frame.power then
    local dr, dg, db = r * 0.7, g * 0.7, b * 0.7
    frame.power:SetTextColor(dr, dg, db, 1)
  end
  if frame.pet then
    if frame.pet.health then
      frame.pet.health:SetStatusBarColor(r, g, b, MF.RegAlpha)
    end
  end
end

function MF.UpdateHealthBar(frame)
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

  local ok, percent = MF.UnitHealthPercent(frame.unit, curve)
  if not ok then
    frame.health:SetValue(0)
    return
  end
  frame.health:SetValue(percent)
end

function MF.UpdateAbsorbBar(frame)
  -- Same secrecy concern as UnitHealth/UnitHealthMax above: go through the
  -- SecureUtil-wrapped calls instead of the raw globals so a secret/erroring
  -- result can't propagate an uncaught error into this frame's event
  -- handler. The fallback is an explicit type check rather than `x or
  -- default`, since truthiness-testing a secret value directly is unsafe.
  local ok1, maxHealth = MF.UnitHealthMax(frame.unit)
  if not ok1 or not MF.IsNumber(maxHealth) then
    maxHealth = 1
  end

  local ok2, total = MF.UnitGetTotalAbsorbs(frame.unit)
  if not ok2 or not MF.IsNumber(total) then
    total = 0
  end

  frame.absorb:SetMinMaxValues(0, maxHealth)
  frame.absorb:SetValue(total)
end
