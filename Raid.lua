local _, MF         = ...

MF.HideBlizzardFrame("CompactRaidFrameContainer")
MF.HideBlizzardFrame("CompactRaidFrameManager")

local baseName      = "MF_Raid"

MF.MaxRaidMembers   = 20
MF.MustUpdate       = false

local RaidFrames    = {}

local MAX_AURAS     = 3

local function LayoutRaidFrames()
  if InCombatLockdown() then
    MF.MustUpdate = true; return
  end
  local numRaid = GetNumGroupMembers() or 0
  if MF.Test.Is("raid") then numRaid = MF.MaxRaidMembers end
  if numRaid < 6 or numRaid > MF.MaxRaidMembers then
    return
  end

  local spacingY = MF.RaidSizeY + 5
  local startY = spacingY * math.floor(numRaid / 2)
  local shown = 0

  -- exposed so Move Mode's raid drag handler can back the group's origin Y
  -- out of raid1's dragged position (raid1 sits at origin.y + startY, not
  -- at origin.y directly, because of this stack-centering math)
  MF.RaidStackTopY = startY

  for index = 1, #RaidFrames do
    local frame = RaidFrames[index]
    local unit = frame.unit
    if MF.UnitExists(unit) or MF.Test.Is("raid") then
      shown = shown + 1

      frame:ClearAllPoints()
      frame:SetPoint("CENTER", UIParent, "CENTER",
        MF.Positions.raid.x,
        MF.Positions.raid.y + startY - (shown - 1) * spacingY)
    end
  end
  MF.MustUpdate = false
end
-- exposed for Move Mode's raid drag handler
MF.LayoutRaidFrames = LayoutRaidFrames

local function CreateRaidFrame(index)
  local unit = "raid" .. index
  local name = baseName .. index

  local raidFrame = MF.CreateUnitFrame({
    name       = name,
    unit       = unit,
    unitKey    = "raid",
    point      = { "CENTER", UIParent, "CENTER", MF.Positions.raid.x, MF.Positions.raid.y },
    size       = { MF.RaidSizeX, MF.RaidSizeY },
    maxAuras   = MAX_AURAS,
    iconSize   = MF.DefaultSizeSmall,
    pvpIcons   = true,
    horizontal = true,
    roleIcon   = true,
    -- fewer DR slots than arena/party since raid can have up to 20 frames
    otherSlots = 5,
  })
  raidFrame.IsDriverRegistered = false
  raidFrame.HasBroadcastEvents = false
  MF.RegisterMovableGroupMember("raid", raidFrame)

  -- these events aren't tied to a unit, so only listen on frames that have one - avoids 20 frames all reacting to one event
  local function UpdateBroadcastEvents()
    local shouldRegister = MF.UnitExists(unit)
    if shouldRegister and not raidFrame.HasBroadcastEvents then
      raidFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
      raidFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
      raidFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
      raidFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
      raidFrame:RegisterEvent("RAID_TARGET_UPDATE")
      raidFrame.HasBroadcastEvents = true
    elseif not shouldRegister and raidFrame.HasBroadcastEvents then
      raidFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
      raidFrame:UnregisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
      raidFrame:UnregisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
      raidFrame:UnregisterEvent("SPELL_RANGE_CHECK_UPDATE")
      raidFrame:UnregisterEvent("RAID_TARGET_UPDATE")
      raidFrame.HasBroadcastEvents = false
    end
  end

  local function UpdateVisibility()
    if MF.Test.Is("raid") then
      if InCombatLockdown() then return end
      UnregisterUnitWatch(raidFrame)
      raidFrame.IsDriverRegistered = false
      raidFrame:Show()
      if raidFrame.unit == "raid1" then
        LayoutRaidFrames()
      end
    elseif (MF.NumGroupMembers < 6 or MF.NumGroupMembers == 0 or MF.NumGroupMembers > MF.MaxRaidMembers) and not InCombatLockdown() then
      UnregisterUnitWatch(raidFrame)
      raidFrame.IsDriverRegistered = false
      raidFrame:Hide()
    elseif not raidFrame.IsDriverRegistered and not InCombatLockdown() then
      RegisterUnitWatch(raidFrame)
      raidFrame.IsDriverRegistered = true
    end
  end

  function raidFrame:UpdateVisibility() UpdateVisibility() end

  raidFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  raidFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  raidFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  raidFrame:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit)

  raidFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  raidFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  raidFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
  raidFrame:RegisterUnitEvent("UNIT_AURA", unit)
  raidFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

  -- target highlight/range events are registered conditionally, see UpdateBroadcastEvents

  raidFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
  raidFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")

  raidFrame:RegisterUnitEvent("UNIT_TARGET", unit)

  raidFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
  raidFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")

  raidFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")

  local function OnReset()
    MF.Test.Clear("raid")
    UpdateVisibility()
    UpdateBroadcastEvents()
    if MF.UnitExists(unit) then
      MF.ApplyClassColor(raidFrame)
      MF.UpdateHealthBar(raidFrame)
      MF.UpdateAbsorbBar(raidFrame)
      MF.UpdateAuras(raidFrame)
      MF.UpdateTrinket(raidFrame, true)
      MF.UpdateRoleIcon(raidFrame, MF.Test.Is("raid"))
      MF.UpdateTargetHighlight(raidFrame)
      MF.UpdateTargetIndicator(raidFrame)
      MF.ResetDR(raidFrame)
      MF.SetRangeAlpha(raidFrame)
      MF.UpdateRaidMark(raidFrame)
    else
      MF.ResetTargetIndicator(raidFrame)
    end
    if raidFrame.unit == "raid1" then
      LayoutRaidFrames()
    end
  end

  raidFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      OnReset()
      if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        MF.ResetOrbs(raidFrame)
      end
    end
    if MF.Test.Is("raid") or (MF.NumGroupMembers < 6 or MF.NumGroupMembers == 0) then return end
    if MF.MustUpdate then
      LayoutRaidFrames()
    end
    if event == "PLAYER_TARGET_CHANGED" then
      MF.UpdateTargetHighlight(raidFrame)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MF.UpdateHealthBar(raidFrame)
      MF.SetRangeAlpha(raidFrame)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
      MF.UpdateAbsorbBar(raidFrame)
      MF.SetRangeAlpha(raidFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MF.SetRangeAlpha(raidFrame)
    elseif event == "UNIT_NAME_UPDATE" then
      MF.ApplyClassColor(raidFrame)
    elseif event == "UNIT_AURA" then
      MF.UpdateAuras(raidFrame)
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" or event == "ARENA_COOLDOWNS_UPDATE" then
      MF.UpdateTrinket(raidFrame, true)
    elseif event == "UNIT_TARGET" then
      MF.UpdateTargetIndicator(raidFrame)
    elseif event == "LOSS_OF_CONTROL_ADDED" or event == "LOSS_OF_CONTROL_UPDATE" then
      if arg1 == unit then
        MF.TryAndUpdateDRStateFromLOC(raidFrame, arg2)
      end
    elseif event == "ARENA_OPPONENT_UPDATE" then
      MF.UpdateOrbs(raidFrame, arg1, arg2)
    elseif event == "RAID_TARGET_UPDATE" then
      MF.UpdateRaidMark(raidFrame)
    end
  end)
  RaidFrames[index] = raidFrame
end

for i = 1, MF.MaxRaidMembers do
  CreateRaidFrame(i)
end
