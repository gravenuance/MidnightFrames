local _, MV      = ...

local baseName   = "MV_Party"

MV_PartyTestMode = false

local MAX_AURAS  = 3

local function CreatePartyFrame(index)
  local unit = "party" .. index
  local name = baseName .. index

  -- Set up frames
  local partyFrame = MV.CreateUnitFrame({
    name     = name,
    unit     = unit,
    unitKey  = "party",
    point    = { "CENTER", UIParent, "CENTER", -MV.FrameX - (index - 1) * MV.FrameSpace, 0 },
    size     = { MV.SizeX, MV.SizeYAlt },
    maxAuras = MAX_AURAS,
    iconSize = MV.DefaultSize,
    pvpIcons = true,
    roleIcon = true,
  })
  partyFrame.IsDriverRegistered = false

  local function UpdateVisibility()
    if MV_PartyTestMode then
      UnregisterUnitWatch(partyFrame)
      partyFrame.IsDriverRegistered = false
      partyFrame:Show()
    elseif (MV.NumGroupMembers > 5 or MV.NumGroupMembers == 0) and not InCombatLockdown() then
      UnregisterUnitWatch(partyFrame)
      partyFrame.IsDriverRegistered = false
      partyFrame:Hide()
    elseif not partyFrame.IsDriverRegistered and not InCombatLockdown() then
      RegisterUnitWatch(partyFrame)
      partyFrame.IsDriverRegistered = true
    end
  end

  function partyFrame:UpdateVisibility() UpdateVisibility() end

  --DEFAULTS
  partyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  partyFrame:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit)
  partyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  partyFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  --UNIT FRAMES
  partyFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  partyFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  partyFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
  partyFrame:RegisterUnitEvent("UNIT_AURA", unit)
  partyFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

  -- PLAYER HIGHLIGHT
  partyFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

  -- RANGE CHECK
  partyFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  partyFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  partyFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  -- TRINKET
  partyFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
  partyFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")

  -- UNIT TARGET
  partyFrame:RegisterUnitEvent("UNIT_TARGET", unit)

  -- DR
  partyFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
  partyFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")

  partyFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      MV.NumGroupMembers = GetNumGroupMembers() or 0
      MV_PartyTestMode = false
      UpdateVisibility()
      if MV.UnitExists(unit) then
        MV.ApplyClassColor(partyFrame)
        MV.UpdateHealthBar(partyFrame)
        MV.UpdateAbsorbBar(partyFrame)
        MV.UpdateAuras(partyFrame)
        MV.UpdateTrinket(partyFrame)
        MV.UpdateRoleIcon(partyFrame, MV_PartyTestMode)
        MV.UpdateTargetHighlight(partyFrame)
        MV.UpdateTargetIndicator(partyFrame)
        MV.ResetDR(partyFrame)
        MV.SetRangeAlpha(partyFrame)
      else
        MV.ResetTargetIndicator(partyFrame)
      end
    end
    if MV_PartyTestMode or (MV.NumGroupMembers > 5 or MV.NumGroupMembers == 0) then return end
    if event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(partyFrame)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MV.UpdateHealthBar(partyFrame)
      MV.SetRangeAlpha(partyFrame)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
      MV.UpdateAbsorbBar(partyFrame)
      MV.SetRangeAlpha(partyFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.SetRangeAlpha(partyFrame)
    elseif event == "UNIT_NAME_UPDATE" then
      MV.ApplyClassColor(partyFrame)
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(partyFrame)
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" or event == "ARENA_COOLDOWNS_UPDATE" then
      MV.UpdateTrinket(partyFrame, true)
    elseif event == "UNIT_TARGET" then
      MV.UpdateTargetIndicator(partyFrame)
    elseif event == "LOSS_OF_CONTROL_ADDED" or event == "LOSS_OF_CONTROL_UPDATED" then
      if arg1 == unit then
        MV.TryAndUpdateDRStateFromLOC(partyFrame, arg2)
      end
    end
  end)
end

for i = 1, 4 do
  CreatePartyFrame(i)
end
