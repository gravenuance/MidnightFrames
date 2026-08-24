local _, MF = ...

MF.HideBlizzardFrame("FocusFrame")

-- Mirrors Target.lua closely - focus is a full unit frame like target, just
-- sized/positioned to parallel the pet frame (small, docked to a corner of
-- its "owner" frame - pet to player's top-right, focus to target's
-- top-left - until manually dragged in Move Mode). No aura tracking though
-- (maxAuras = 0, matching pet) - the frame is too small to fit icons.

MF_FocusTestMode = false

local IsDriverRegistered = false

local targetFrame = _G["MF_Target"]

local focusPos = MF.db.profile.positions.focus
local focusPoint
if focusPos.manual then
  focusPoint = { "CENTER", UIParent, "CENTER", focusPos.x, focusPos.y }
else
  focusPoint = { "TOPRIGHT", targetFrame, "TOPLEFT", -MF.FocusSpace, 0 }
end

local focusFrame = MF.CreateUnitFrame({
  name     = "MF_Focus",
  unit     = "focus",
  unitKey  = "focus",
  point    = focusPoint,
  size     = { MF.FocusX, MF.FocusY },
  maxAuras = 0,
  iconSize = MF.DefaultSize,
})
MF.RegisterMovable("focus", focusFrame)

local function UpdateVisibility()
  if InCombatLockdown() then return end
  if MF_FocusTestMode then
    UnregisterUnitWatch(focusFrame)
    focusFrame:Show()
    IsDriverRegistered = false
  elseif not IsDriverRegistered then
    RegisterUnitWatch(focusFrame)
    IsDriverRegistered = true
  end
end

function focusFrame:UpdateVisibility() UpdateVisibility() end

focusFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
focusFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

focusFrame:RegisterUnitEvent("UNIT_HEALTH", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_MAXHEALTH", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", focusFrame.unit)

focusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")

focusFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
focusFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
focusFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

focusFrame:RegisterEvent("RAID_TARGET_UPDATE")

focusFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", focusFrame.unit)
focusFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", focusFrame.unit)


focusFrame:SetScript("OnEvent", function(_, event, arg1)
  if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
    MF_FocusTestMode = false
    UpdateVisibility()
  end
  if MF_FocusTestMode then return end
  if event == "PLAYER_FOCUS_CHANGED"
      or (event == "UNIT_NAME_UPDATE" and arg1 == focusFrame.unit) then
    UpdateVisibility()
    if MF.UnitExists(focusFrame.unit) then
      MF.ApplyClassColor(focusFrame)
      MF.UpdateHealthBar(focusFrame)
      MF.UpdateAbsorbBar(focusFrame)
      MF.SetRangeAlpha(focusFrame)
      MF.UpdateRaidMark(focusFrame)
      MF.UpdateCastIndicator(focusFrame)
    end
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    MF.UpdateHealthBar(focusFrame)
  elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
    MF.UpdateAbsorbBar(focusFrame)
  elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
    MF.SetRangeAlpha(focusFrame)
  elseif event == "RAID_TARGET_UPDATE" then
    MF.UpdateRaidMark(focusFrame)
  elseif event == "UNIT_SPELLCAST_START"
      or event == "UNIT_SPELLCAST_STOP"
      or event == "UNIT_SPELLCAST_FAILED"
      or event == "UNIT_SPELLCAST_INTERRUPTED"
      or event == "UNIT_SPELLCAST_CHANNEL_START"
      or event == "UNIT_SPELLCAST_CHANNEL_STOP"
      or event == "UNIT_SPELLCAST_INTERRUPTIBLE"
      or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
  then
    MF.UpdateCastIndicator(focusFrame)
  end
end)
