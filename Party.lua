local _, MF      = ...

MF.HideBlizzardFrame("CompactPartyFrame")

local baseName   = "MF_Party"

local MAX_AURAS  = 3

local function CreatePartyFrame(index)
  local unit = "party" .. index
  local name = baseName .. index

  local px, py = MF.GetRosterMemberPoint("party", index)
  local partyFrame = MF.CreateUnitFrame({
    name     = name,
    unit     = unit,
    unitKey  = "party",
    point    = { "CENTER", UIParent, "CENTER", px, py },
    size     = { MF.SizeX, MF.GroupFrameHeight },
    maxAuras = MAX_AURAS,
    iconSize = MF.DefaultSize,
    pvpIcons = true,
    roleIcon = true,
  })
  partyFrame.IsDriverRegistered = false
  MF.RegisterMovableGroupMember("party", partyFrame)

  local function UpdateVisibility()
    if MF.Test.Is("party") then
      if InCombatLockdown() then return end
      UnregisterUnitWatch(partyFrame)
      partyFrame.IsDriverRegistered = false
      partyFrame:Show()
    elseif (MF.NumGroupMembers > 5 or MF.NumGroupMembers == 0) and not InCombatLockdown() then
      UnregisterUnitWatch(partyFrame)
      partyFrame.IsDriverRegistered = false
      partyFrame:Hide()
    elseif not partyFrame.IsDriverRegistered and not InCombatLockdown() then
      RegisterUnitWatch(partyFrame)
      partyFrame.IsDriverRegistered = true
    end
  end

  function partyFrame:UpdateVisibility() UpdateVisibility() end

  partyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  partyFrame:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit)
  partyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  partyFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  partyFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  partyFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  partyFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
  partyFrame:RegisterUnitEvent("UNIT_AURA", unit)
  partyFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

  partyFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

  partyFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  partyFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  partyFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  partyFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
  partyFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")

  partyFrame:RegisterUnitEvent("UNIT_TARGET", unit)

  partyFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
  partyFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")

  partyFrame:RegisterEvent("RAID_TARGET_UPDATE")

  MF.RegisterCastEvents(partyFrame)

  partyFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      MF.NumGroupMembers = GetNumGroupMembers() or 0
      MF.Test.Clear("party")
      UpdateVisibility()
      if MF.UnitExists(unit) then
        MF.ApplyClassColor(partyFrame)
        MF.UpdateHealthBar(partyFrame)
        MF.UpdateAbsorbBar(partyFrame)
        MF.UpdateAuras(partyFrame)
        MF.UpdateTrinket(partyFrame, true)
        MF.UpdateRoleIcon(partyFrame, MF.Test.Is("party"))
        MF.UpdateTargetHighlight(partyFrame)
        MF.UpdateTargetIndicator(partyFrame)
        MF.ResetDR(partyFrame)
        MF.SetRangeAlpha(partyFrame)
        MF.UpdateRaidMark(partyFrame)
        MF.UpdateCastIndicator(partyFrame)
      else
        MF.ResetTargetIndicator(partyFrame)
      end
    end
    if MF.Test.Is("party") or (MF.NumGroupMembers > 5 or MF.NumGroupMembers == 0) then return end
    if event == "PLAYER_TARGET_CHANGED" then
      MF.UpdateTargetHighlight(partyFrame)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MF.UpdateHealthBar(partyFrame)
      MF.SetRangeAlpha(partyFrame)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
      MF.UpdateAbsorbBar(partyFrame)
      MF.SetRangeAlpha(partyFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MF.SetRangeAlpha(partyFrame)
    elseif event == "UNIT_NAME_UPDATE" then
      MF.ApplyClassColor(partyFrame)
    elseif event == "UNIT_AURA" then
      MF.UpdateAuras(partyFrame)
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" or event == "ARENA_COOLDOWNS_UPDATE" then
      MF.UpdateTrinket(partyFrame, true)
    elseif event == "UNIT_TARGET" then
      MF.UpdateTargetIndicator(partyFrame)
    elseif event == "LOSS_OF_CONTROL_ADDED" or event == "LOSS_OF_CONTROL_UPDATE" then
      if arg1 == unit then
        MF.TryAndUpdateDRStateFromLOC(partyFrame, arg2)
      end
    elseif event == "RAID_TARGET_UPDATE" then
      MF.UpdateRaidMark(partyFrame)
    elseif MF.IsCastEvent(event) then
      MF.UpdateCastIndicator(partyFrame)
    end
  end)
end

for i = 1, MF.GroupSize.party do
  CreatePartyFrame(i)
end
