local _, MF = ...

-- Every UNIT_SPELLCAST_* event the cast indicator reacts to, in one place.
-- The six vertical unit frames (player/target/focus/party/arena/boss) all
-- watch this same set; raid frames have no cast indicator and skip it.
local CAST_EVENTS = {
  "UNIT_SPELLCAST_START",
  "UNIT_SPELLCAST_STOP",
  "UNIT_SPELLCAST_FAILED",
  "UNIT_SPELLCAST_INTERRUPTED",
  "UNIT_SPELLCAST_CHANNEL_START",
  "UNIT_SPELLCAST_CHANNEL_STOP",
  "UNIT_SPELLCAST_INTERRUPTIBLE",
  "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}

local castEventLookup = {}
for _, castEvent in ipairs(CAST_EVENTS) do
  castEventLookup[castEvent] = true
end

function MF.RegisterCastEvents(frame)
  for _, castEvent in ipairs(CAST_EVENTS) do
    frame:RegisterUnitEvent(castEvent, frame.unit)
  end
end

function MF.IsCastEvent(event)
  return castEventLookup[event] == true
end

-- defaults to "interruptible" when we can't tell
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
