local _, MV = ...

MV_TargetTestMode = false

local IsDriverRegistered = false

local MAX_AURAS = 4

local f = MV.CreateUnitFrame({
  name     = "MV_TargetFrame",
  unit     = "target",
  point    = { "CENTER", UIParent, "CENTER", 225, 0 },
  size     = { 50, 220 },
  maxAuras = MAX_AURAS,
  iconSize = MV.DefaultSize,
})

local function UpdateVisibility()
  if InCombatLockdown() then return end
  if MV_TargetTestMode then
    UnregisterUnitWatch(f)
    f:Show()
    IsDriverRegistered = false
  elseif not IsDriverRegistered then
    RegisterUnitWatch(f)
    IsDriverRegistered = true
  end
end

function f:UpdateVisibility() UpdateVisibility() end

f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterUnitEvent("UNIT_HEALTH", f.unit)
f:RegisterUnitEvent("UNIT_MAXHEALTH", f.unit)
f:RegisterUnitEvent("UNIT_AURA", f.unit)
f:RegisterUnitEvent("UNIT_NAME_UPDATE", f.unit)
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
f:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

f:SetScript("OnEvent", function(_, event, arg1)
  if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
    MV_TargetTestMode = false
    UpdateVisibility()
  end
  if MV_TargetTestMode then return end

  if event == "PLAYER_TARGET_CHANGED"
      or (event == "UNIT_NAME_UPDATE" and arg1 == f.unit) then
    UpdateVisibility()
    if not UnitExists(f.unit) then
      return
    end
    MV.ApplyClassColor(f)
    MV.UpdateHealthBar(f)
    MV.UpdateAuras(f)
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    MV.UpdateHealthBar(f)
  elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
    MV.SetRangeAlpha(f)
  elseif event == "UNIT_AURA" then
    MV.UpdateAuras(f)
  end
end)
