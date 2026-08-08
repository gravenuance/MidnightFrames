local _, MF = ...

-- notInterruptible comes straight from an event payload / API return, so it
-- must be sanitized before use like everything else in DRUtil/AuraUtil that
-- touches secret-capable cast/cooldown data. Defaults to "interruptible"
-- (false) when unknown, matching DRUtil's SanitizeBoolean(isImmune, false)
-- precedent - assume the non-blocking state rather than the alarming one.
local function SanitizeBoolean(value, default)
  if MF.IsSecretSafe(value) then
    return default
  end
  return value
end

local function ApplyCast(indicator, texture, startTimeMS, endTimeMS, notInterruptible)
  if (MF.IsNumber(texture) or MF.IsString(texture)) and not MF.IsSecretSafe(texture) then
    indicator.icon:SetTexture(texture)
  end

  if notInterruptible then
    indicator.border:SetVertexColor(1, 0, 0, 1)
  else
    indicator.border:SetVertexColor(0, 1, 0, 1)
  end

  indicator.cooldown:Hide()
  if MF.IsNumber(startTimeMS) and MF.IsNumber(endTimeMS)
      and not MF.IsSecretSafe(startTimeMS) and not MF.IsSecretSafe(endTimeMS) then
    local durationObject = MF.CreateDurationObject(startTimeMS / 1000, (endTimeMS - startTimeMS) / 1000)
    if durationObject then
      local ok = MF.SetCooldownFromDurationObject(indicator.cooldown, durationObject, true)
      if ok then
        indicator.cooldown:Show()
      end
    end
  end

  indicator:Show()
end

function MF.UpdateCastIndicator(frame)
  local indicator = frame and frame.castIndicator
  if not indicator then return end

  local ok, name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = MF.UnitCastingInfo(frame.unit)
  if ok and MF.IsString(name) and not MF.IsSecretSafe(name) then
    ApplyCast(indicator, texture, startTimeMS, endTimeMS, SanitizeBoolean(notInterruptible, false))
    return
  end

  local ok2, name2, _, texture2, startTimeMS2, endTimeMS2, _, notInterruptible2 = MF.UnitChannelInfo(frame.unit)
  if ok2 and MF.IsString(name2) and not MF.IsSecretSafe(name2) then
    ApplyCast(indicator, texture2, startTimeMS2, endTimeMS2, SanitizeBoolean(notInterruptible2, false))
    return
  end

  indicator:Hide()
end
