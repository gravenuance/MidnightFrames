local _, MV      = ...

local baseName   = "MV_PartyFrame"

MV_PartyTestMode = false

local MAX_AURAS  = 3

local function CreatePartyFrame(index)
  local unit = "party" .. index
  local name = baseName .. index

  -- Set up frames
  local f = MV.CreateUnitFrame({
    name     = name,
    unit     = unit,
    point    = { "CENTER", UIParent, "CENTER", -MV.FrameX - (index - 1) * MV.FrameSpace, 0 },
    size     = { MV.SizeX, MV.SizeYAlt },
    maxAuras = MAX_AURAS,
    iconSize = MV.DefaultSize,
    pvpIcons = true,
  })
  f.IsDriverRegistered = false

  local function UpdateVisibility()
    local numGroup = GetNumGroupMembers() or 0
    if MV_PartyTestMode then
      UnregisterUnitWatch(f)
      f.IsDriverRegistered = false
      f:Show()
    elseif (numGroup > 5 or numGroup == 0) and not InCombatLockdown() then
      UnregisterUnitWatch(f)
      f.IsDriverRegistered = false
      f:Hide()
    elseif not f.IsDriverRegistered and not InCombatLockdown() then
      RegisterUnitWatch(f)
      f.IsDriverRegistered = true
    end
  end

  function f:UpdateVisibility() UpdateVisibility() end

  f:RegisterEvent("GROUP_ROSTER_UPDATE")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterUnitEvent("UNIT_HEALTH", unit)
  f:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  f:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
  f:RegisterUnitEvent("UNIT_AURA", unit)
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  f:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit)
  f:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  f:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
  f:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
  f:RegisterEvent("ARENA_COOLDOWNS_UPDATE")

  f:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      MV_PartyTestMode = false
      UpdateVisibility()
      if not UnitExists(unit) then return end
      MV.UpdateTargetHighlight(f)
      MV.ApplyClassColor(f)
      MV.UpdateHealthBar(f)
      MV.UpdateAuras(f)
      MV.ResetDR(f)
      MV.ResetAndRequestTrinket(f)
    end
    if MV_PartyTestMode then return end
    if event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(f)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MV.UpdateHealthBar(f)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.UpdateHealthBar(f)
    elseif event == "UNIT_NAME_UPDATE" then
      MV.ApplyClassColor(f)
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(f)
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" or event == "ARENA_COOLDOWNS_UPDATE" then
      if arg1 == unit then
        MV.UpdateTrinket(f)
      end
    end
  end)
end

for i = 1, 4 do
  CreatePartyFrame(i)
end
