local _, MV         = ...

local defaultFrames = _G["CompactRaidFrameContainer"]
local baseName      = "MV_Raid"

MV_RaidTestMode     = false
MV.MaxRaidMembers   = 20

local RaidFrames    = {}

local MAX_AURAS     = 3

local function LayoutRaidFrames()
  local numRaid = GetNumGroupMembers() or 0
  if MV_RaidTestMode then numRaid = MV.MaxRaidMembers end
  if numRaid < 6 or numRaid > MV.MaxRaidMembers then
    return
  end

  local spacingY = MV.RaidSizeY + 5
  local startY = spacingY * math.floor(numRaid / 2)
  local shown = 0

  for index = 1, #RaidFrames do
    local frame = RaidFrames[index]
    local unit = frame.unit
    if MV.UnitExists(unit) or MV_RaidTestMode then
      shown = shown + 1
      if not InCombatLockdown() then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER",
          -MV.FrameX * 1.5,
          startY - (shown - 1) * spacingY)
      end
    end
  end
end

local function CreateRaidFrame(index)
  local unit = "raid" .. index
  local name = baseName .. index

  -- Set up frames
  local raidFrame = MV.CreateUnitFrame({
    name       = name,
    unit       = unit,
    unitKey    = "raid",
    point      = { "CENTER", UIParent, "CENTER", -MV.FrameX * 1.5, 0 },
    size       = { MV.RaidSizeX, MV.RaidSizeY },
    maxAuras   = MAX_AURAS,
    iconSize   = MV.DefaultSizeSmall,
    pvpIcons   = true,
    horizontal = true,
    roleIcon   = true,
  })
  raidFrame.IsDriverRegistered = false

  local function UpdateVisibility()
    if MV_RaidTestMode then
      UnregisterUnitWatch(raidFrame)
      raidFrame.IsDriverRegistered = false
      raidFrame:Show()
      if raidFrame.unit == "raid1" then
        LayoutRaidFrames()
      end
    elseif (MV.NumGroupMembers < 6 or MV.NumGroupMembers == 0 or MV.NumGroupMembers > MV.MaxRaidMembers) and not InCombatLockdown() then
      UnregisterUnitWatch(raidFrame)
      raidFrame.IsDriverRegistered = false
      raidFrame:Hide()
    elseif not raidFrame.IsDriverRegistered and not InCombatLockdown() then
      RegisterUnitWatch(raidFrame)
      raidFrame.IsDriverRegistered = true
    end
  end

  function raidFrame:UpdateVisibility() UpdateVisibility() end

  local function DisableRaidFrames()
    if defaultFrames and defaultFrames:IsShown() then
      if InCombatLockdown() then
        defaultFrames:SetAlpha(0)
        return
      end
      defaultFrames:UnregisterAllEvents()
      defaultFrames:Hide()
    end
  end

  raidFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  raidFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  raidFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  raidFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  raidFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
  raidFrame:RegisterUnitEvent("UNIT_AURA", unit)
  raidFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
  raidFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  raidFrame:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit)
  raidFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  raidFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  raidFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
  raidFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
  raidFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
  raidFrame:RegisterUnitEvent("UNIT_TARGET", unit)
  raidFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
  raidFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
  raidFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

  raidFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      MV_RaidTestMode = false
      UpdateVisibility()
      if MV.UnitExists(unit) then
        MV.ApplyClassColor(raidFrame)
        MV.UpdateHealthBar(raidFrame)
        MV.UpdateAbsorbBar(raidFrame)
        MV.UpdateAuras(raidFrame)
        MV.UpdateTrinket(raidFrame)
        MV.UpdateRoleIcon(raidFrame, MV_RaidTestMode)
        MV.UpdateTargetHighlight(raidFrame)
        MV.UpdateTargetIndicator(raidFrame)
        MV.ResetDR(raidFrame)
        MV.SetRangeAlpha(raidFrame)
      else
        MV.ResetTargetIndicator(raidFrame)
      end
      if raidFrame.unit == "raid1" then
        LayoutRaidFrames()
        DisableRaidFrames()
      end
    end
    if MV_RaidTestMode or (MV.NumGroupMembers < 6 or MV.NumGroupMembers == 0) then return end
    if event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(raidFrame)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MV.UpdateHealthBar(raidFrame)
      MV.SetRangeAlpha(raidFrame)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
      MV.UpdateAbsorbBar(raidFrame)
      MV.SetRangeAlpha(raidFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.SetRangeAlpha(raidFrame)
    elseif event == "UNIT_NAME_UPDATE" then
      MV.ApplyClassColor(raidFrame)
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(raidFrame)
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" or event == "ARENA_COOLDOWNS_UPDATE" then
      if arg1 == unit then
        MV.UpdateTrinket(raidFrame, true)
      end
    elseif event == "UNIT_TARGET" then
      MV.UpdateTargetIndicator(raidFrame)
    elseif event == "LOSS_OF_CONTROL_ADDED" or event == "LOSS_OF_CONTROL_UPDATE" then
      if arg1 == unit then
        MV.TryAndUpdateDRStateFromLOC(raidFrame, arg2)
      end
    end
  end)
  RaidFrames[index] = raidFrame
end

for i = 1, MV.MaxRaidMembers do
  CreateRaidFrame(i)
end
