local _, MF = ...

MF.HideBlizzardFrame("TargetFrame")

local IsDriverRegistered = false

local MAX_AURAS = 4

local targetFrame = MF.CreateUnitFrame({
  name     = "MF_Target",
  unit     = "target",
  unitKey  = "target",
  point    = { "CENTER", UIParent, "CENTER", MF.Positions.target.x, MF.Positions.target.y },
  size     = { MF.SizeX, MF.PrimaryFrameHeight },
  maxAuras = MAX_AURAS,
  iconSize = MF.DefaultSize,
})
MF.RegisterMovable("target", targetFrame)

local function UpdateVisibility()
  if InCombatLockdown() then return end
  if MF.Test.Is("target") then
    UnregisterUnitWatch(targetFrame)
    targetFrame:Show()
    IsDriverRegistered = false
  elseif not IsDriverRegistered then
    RegisterUnitWatch(targetFrame)
    IsDriverRegistered = true
  end
end

function targetFrame:UpdateVisibility() UpdateVisibility() end

targetFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
targetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

targetFrame:RegisterUnitEvent("UNIT_HEALTH", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_MAXHEALTH", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_AURA", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", targetFrame.unit)

targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

targetFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
targetFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
targetFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

targetFrame:RegisterEvent("RAID_TARGET_UPDATE")

MF.RegisterCastEvents(targetFrame)


targetFrame:SetScript("OnEvent", function(_, event, arg1)
  if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
    MF.Test.Clear("target")
    UpdateVisibility()
  end
  if MF.Test.Is("target") then return end
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
  elseif MF.IsCastEvent(event) then
    MF.UpdateCastIndicator(targetFrame)
  end
end)
