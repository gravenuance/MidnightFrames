local _, MV = ...

MV_TargetTestMode = false

local IsDriverRegistered = false

local MAX_AURAS = 4

local targetFrame = MV.CreateUnitFrame({
  name     = "MV_TargetFrame",
  unit     = "target",
  point    = { "CENTER", UIParent, "CENTER", MV.FrameXAlt, 0 },
  size     = { MV.SizeX, MV.SizeY },
  maxAuras = MAX_AURAS,
  iconSize = MV.DefaultSize,
})

local function UpdateVisibility()
  if InCombatLockdown() then return end
  if MV_TargetTestMode then
    UnregisterUnitWatch(targetFrame)
    targetFrame:Show()
    IsDriverRegistered = false
  elseif not IsDriverRegistered then
    RegisterUnitWatch(targetFrame)
    IsDriverRegistered = true
  end
end

function targetFrame:UpdateVisibility() UpdateVisibility() end

targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetFrame:RegisterUnitEvent("UNIT_HEALTH", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_MAXHEALTH", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_AURA", targetFrame.unit)
targetFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", targetFrame.unit)
targetFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
targetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
targetFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
targetFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
targetFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

targetFrame:SetScript("OnEvent", function(_, event, arg1)
  if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
    MV_TargetTestMode = false
    UpdateVisibility()
  end
  if MV_TargetTestMode then return end
  if event == "PLAYER_TARGET_CHANGED"
      or (event == "UNIT_NAME_UPDATE" and arg1 == targetFrame.unit) then
    UpdateVisibility()
    if UnitExists(targetFrame.unit) then
      MV.ApplyClassColor(targetFrame)
      MV.UpdateHealthBar(targetFrame)
      MV.UpdateAuras(targetFrame)
    end
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    MV.UpdateHealthBar(targetFrame)
  elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
    MV.SetRangeAlpha(targetFrame)
  elseif event == "UNIT_AURA" then
    MV.UpdateAuras(targetFrame)
  end
end)
