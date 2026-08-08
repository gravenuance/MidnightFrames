local _, MF         = ...

MF.HideBlizzardFrame("CompactRaidFrameContainer")
MF.HideBlizzardFrame("CompactRaidFrameManager")

local baseName      = "MF_Raid"

MF_RaidTestMode     = false
MF.MaxRaidMembers   = 20
MF.MustUpdate       = false

local RaidFrames    = {}

local MAX_AURAS     = 3

local function LayoutRaidFrames()
  if InCombatLockdown() then
    MF.MustUpdate = true; return
  end
  local numRaid = GetNumGroupMembers() or 0
  if MF_RaidTestMode then numRaid = MF.MaxRaidMembers end
  if numRaid < 6 or numRaid > MF.MaxRaidMembers then
    return
  end

  local spacingY = MF.RaidSizeY + 5
  local startY = spacingY * math.floor(numRaid / 2)
  local shown = 0

  for index = 1, #RaidFrames do
    local frame = RaidFrames[index]
    local unit = frame.unit
    if MF.UnitExists(unit) or MF_RaidTestMode then
      shown = shown + 1

      frame:ClearAllPoints()
      frame:SetPoint("CENTER", UIParent, "CENTER",
        -MF.FrameX * 1.5,
        startY - (shown - 1) * spacingY)
    end
  end
  MF.MustUpdate = false
end

local function CreateRaidFrame(index)
  local unit = "raid" .. index
  local name = baseName .. index

  local raidFrame = MF.CreateUnitFrame({
    name       = name,
    unit       = unit,
    unitKey    = "raid",
    point      = { "CENTER", UIParent, "CENTER", -MF.FrameX * 1.5, 0 },
    size       = { MF.RaidSizeX, MF.RaidSizeY },
    maxAuras   = MAX_AURAS,
    iconSize   = MF.DefaultSizeSmall,
    pvpIcons   = true,
    horizontal = true,
    roleIcon   = true,
    -- 1 trinket + 4 DR slots. Raid frames are the widest-fanned-out frame
    -- type (up to MF.MaxRaidMembers instances), so this trades a bit of
    -- simultaneous DR-category visibility for meaningfully fewer eagerly
    -- created widgets; arena/party keep the full MF.DRSize default.
    otherSlots = 5,
  })
  raidFrame.IsDriverRegistered = false
  raidFrame.HasBroadcastEvents = false

  -- PLAYER_TARGET_CHANGED / PLAYER_SOFT_ENEMY_CHANGED / PLAYER_SOFT_INTERACT_CHANGED /
  -- SPELL_RANGE_CHECK_UPDATE are broadcast (non-unit) events: with up to 20 raid
  -- frames all listening, every firing re-runs their handlers in every frame,
  -- including ones with no live unit. Only keep them registered on frames whose
  -- unit currently exists, re-evaluated whenever the roster changes.
  local function UpdateBroadcastEvents()
    local shouldRegister = MF.UnitExists(unit)
    if shouldRegister and not raidFrame.HasBroadcastEvents then
      raidFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
      raidFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
      raidFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
      raidFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")
      raidFrame.HasBroadcastEvents = true
    elseif not shouldRegister and raidFrame.HasBroadcastEvents then
      raidFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
      raidFrame:UnregisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
      raidFrame:UnregisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
      raidFrame:UnregisterEvent("SPELL_RANGE_CHECK_UPDATE")
      raidFrame.HasBroadcastEvents = false
    end
  end

  local function UpdateVisibility()
    if MF_RaidTestMode then
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

  --DEFAULTS
  raidFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
  raidFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  raidFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  raidFrame:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit)

  --UNIT FRAMES
  raidFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  raidFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  raidFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
  raidFrame:RegisterUnitEvent("UNIT_AURA", unit)
  raidFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

  -- PLAYER HIGHLIGHT + RANGE CHECK
  -- (PLAYER_TARGET_CHANGED / PLAYER_SOFT_ENEMY_CHANGED / PLAYER_SOFT_INTERACT_CHANGED /
  -- SPELL_RANGE_CHECK_UPDATE are registered conditionally by UpdateBroadcastEvents)

  -- TRINKET
  raidFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
  raidFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")

  -- UNIT TARGET
  raidFrame:RegisterUnitEvent("UNIT_TARGET", unit)

  -- DR
  raidFrame:RegisterEvent("LOSS_OF_CONTROL_ADDED")
  raidFrame:RegisterEvent("LOSS_OF_CONTROL_UPDATE")

  -- Objective update
  raidFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")

  local function OnReset()
    MF_RaidTestMode = false
    UpdateVisibility()
    UpdateBroadcastEvents()
    if MF.UnitExists(unit) then
      MF.ApplyClassColor(raidFrame)
      MF.UpdateHealthBar(raidFrame)
      MF.UpdateAbsorbBar(raidFrame)
      MF.UpdateAuras(raidFrame)
      MF.UpdateTrinket(raidFrame, true)
      MF.UpdateRoleIcon(raidFrame, MF_RaidTestMode)
      MF.UpdateTargetHighlight(raidFrame)
      MF.UpdateTargetIndicator(raidFrame)
      MF.ResetDR(raidFrame)
      MF.SetRangeAlpha(raidFrame)
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
    if MF_RaidTestMode or (MF.NumGroupMembers < 6 or MF.NumGroupMembers == 0) then return end
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
    end
  end)
  RaidFrames[index] = raidFrame
end

for i = 1, MF.MaxRaidMembers do
  CreateRaidFrame(i)
end
