local _, MV      = ...

local baseName   = "MV_PartyFrame"

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
  })
  partyFrame.IsDriverRegistered = false

  local function UpdateVisibility()
    local numGroup = GetNumGroupMembers() or 0
    if MV_PartyTestMode then
      UnregisterUnitWatch(partyFrame)
      partyFrame.IsDriverRegistered = false
      partyFrame:Show()
    elseif (numGroup > 5 or numGroup == 0) and not InCombatLockdown() then
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
  partyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  partyFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  partyFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  partyFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
  partyFrame:RegisterUnitEvent("UNIT_AURA", unit)
  partyFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
  partyFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  partyFrame:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit)
  partyFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  partyFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  partyFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
  partyFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
  partyFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")

  partyFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      MV_PartyTestMode = false
      UpdateVisibility()
      if UnitExists(unit) then
        MV.UpdateTargetHighlight(partyFrame)
        MV.ApplyClassColor(partyFrame)
        MV.UpdateHealthBar(partyFrame)
        MV.UpdateAuras(partyFrame)
        MV.ResetDR(partyFrame)
        MV.UpdateTrinket(partyFrame)
      end
    end
    if MV_PartyTestMode then return end
    if event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(partyFrame)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MV.UpdateHealthBar(partyFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.UpdateHealthBar(partyFrame)
    elseif event == "UNIT_NAME_UPDATE" then
      MV.ApplyClassColor(partyFrame)
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(partyFrame)
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" or event == "ARENA_COOLDOWNS_UPDATE" then
      if arg1 == unit then
        MV.UpdateTrinket(partyFrame, true)
      end
    end
  end)
end

for i = 1, 4 do
  CreatePartyFrame(i)
end
