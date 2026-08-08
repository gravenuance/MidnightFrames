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

-- Deep: darker/richer toward the back of the fill. Bright: lifted toward
-- white at the leading edge. Same base hue throughout (class color, hostile
-- red, whatever GetClassColor produced) - just two derived shades instead of
-- one flat tone, for a bit of depth instead of a flat fill.
local function DeriveGradientShades(r, g, b)
  local deepR, deepG, deepB = r * 0.35, g * 0.35, b * 0.35
  local brightR = r + (1 - r) * 0.55
  local brightG = g + (1 - g) * 0.55
  local brightB = b + (1 - b) * 0.55
  return deepR, deepG, deepB, brightR, brightG, brightB
end

-- Alpha is deliberately NOT part of this: it used to be baked into
-- SetStatusBarColor's 4th argument and re-read/re-applied by MF.SetRangeAlpha
-- (RangeUtil.lua) on every range check. A gradient texture has no equivalent
-- "read the current color back" operation, so alpha (range-in/out-of-range,
-- prep/stealth dimming in Arena.lua) is now its own concern, applied via
-- statusBar:SetAlpha() independently of color. See MF.SetRangeAlpha and
-- Arena.lua's SetClassColor for the two other callers this affects.
--
-- CAVEAT: SetGradient's orientation parameter operates in the status bar
-- texture's own coordinate space. Vertical frames combine
-- SetOrientation("VERTICAL") with SetRotatesTexture(true) (see Setup.lua),
-- and it wasn't possible to confirm against a live client whether the
-- rotation changes which SetGradient orientation string produces a visually
-- vertical gradient. This reads statusBar:GetOrientation() directly (the
-- simpler, more likely mapping) - if a vertical frame's gradient renders
-- sideways in-game, swap the two branches below.
function MF.ApplyHealthGradient(statusBar, r, g, b)
  if not statusBar then return end
  local texture = statusBar:GetStatusBarTexture()
  if not texture then return end

  local deepR, deepG, deepB, brightR, brightG, brightB = DeriveGradientShades(r, g, b)
  local orientation = statusBar:GetOrientation()
  texture:SetGradient(orientation, CreateColor(deepR, deepG, deepB), CreateColor(brightR, brightG, brightB))
end

function MF.ApplyClassColor(frame)
  if not frame.health then return end
  local r, g, b = GetClassColor(frame.unit)

  MF.ApplyHealthGradient(frame.health, r, g, b)
  frame.health:SetAlpha(MF.RegAlpha)
  if frame.power then
    local dr, dg, db = r * 0.7, g * 0.7, b * 0.7
    frame.power:SetTextColor(dr, dg, db, 1)
  end
  if frame.pet then
    if frame.pet.health then
      MF.ApplyHealthGradient(frame.pet.health, r, g, b)
      frame.pet.health:SetAlpha(MF.RegAlpha)
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
