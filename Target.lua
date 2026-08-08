local _, MF = ...

MF.HideBlizzardFrame("TargetFrame")

MF_TargetTestMode = false

local IsDriverRegistered = false

local MAX_AURAS = 4

local targetFrame = MF.CreateUnitFrame({
  name     = "MF_Target",
  unit     = "target",
  unitKey  = "target",
  point    = { "CENTER", UIParent, "CENTER", MF.FrameXAlt, 0 },
  size     = { MF.SizeX, MF.SizeY },
  maxAuras = MAX_AURAS,
  iconSize = MF.DefaultSize,
})

local function UpdateVisibility()
  if InCombatLockdown() then return end
  if MF_TargetTestMode then
    UnregisterUnitWatch(targetFrame)
    targetFrame:Show()
    IsDriverRegistered = false
  elseif not IsDriverRegistered then
    RegisterUnitWatch(targetFrame)
    IsDriverRegistered = true
  end
end

function targetFrame:UpdateVisibility() UpdateVisibility() end

-- DEFAULTS
targetFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
targetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- UNIT FRAMES
targetFrame:RegisterUnitEvent("UNIT_HEALTH", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_MAXHEALTH", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_AURA", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", targetFrame.unit)

-- PLAYER HIGHLIGHT
targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- RANGE CHECK
targetFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
targetFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
targetFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

-- RAID TARGET MARK
targetFrame:RegisterEvent("RAID_TARGET_UPDATE")

-- CAST INDICATOR
targetFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", targetFrame.unit)


targetFrame:SetScript("OnEvent", function(_, event, arg1)
  if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
    MF_TargetTestMode = false
    UpdateVisibility()
  end
  if MF_TargetTestMode then return end
  if event == "PLAYER_TARGET_CHANGED"
      or (event == "UNIT_NAME_UPDATE" and arg1 == targetFrame.unit) then
    UpdateVisibility()
    if MF.UnitExists(targetFrame.unit) then
      MF.ApplyClassColor(targetFrame)
      MF.UpdateHealthBar(targetFrame)
      MF.UpdateAbsorbBar(targetFrame)
      MF.UpdateAuras(targetFrame)
      MF.SetRangeAlpha(targetFrame)
      MF.UpdateRaidMark(targetFrame)
      MF.UpdateCastIndicator(targetFrame)
    end
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    MF.UpdateHealthBar(targetFrame)
  elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
    MF.UpdateAbsorbBar(targetFrame)
  elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
    MF.SetRangeAlpha(targetFrame)
  elseif event == "UNIT_AURA" then
    MF.UpdateAuras(targetFrame)
  elseif event == "RAID_TARGET_UPDATE" then
    MF.UpdateRaidMark(targetFrame)
  elseif event == "UNIT_SPELLCAST_START"
      or event == "UNIT_SPELLCAST_STOP"
      or event == "UNIT_SPELLCAST_FAILED"
      or event == "UNIT_SPELLCAST_INTERRUPTED"
      or event == "UNIT_SPELLCAST_CHANNEL_START"
      or event == "UNIT_SPELLCAST_CHANNEL_STOP"
      or event == "UNIT_SPELLCAST_INTERRUPTIBLE"
      or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
  then
    MF.UpdateCastIndicator(targetFrame)
  end
end)
