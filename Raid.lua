local _, MV         = ...

local defaultFrames = _G["CompactRaidFrameContainer"]
local baseName      = "MV_Raid"

MV_RaidTestMode     = false
MV.MaxRaidMembers   = 20
MV.MustUpdate       = false

local RaidFrames    = {}

local MAX_AURAS     = 3

local function LayoutRaidFrames()
  if InCombatLockdown() then
    MV.MustUpdate = true; return
  end
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

      frame:ClearAllPoints()
      frame:SetPoint("CENTER", UIParent, "CENTER",
        -MV.FrameX * 1.5,
        startY - (shown - 1) * spacingY)
    end
  end
  MV.MustUpdate = false
end

local function CreateRaidFrame(index)
  local unit = "raid" .. index
  local name = baseName .. index

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
    -- 1 trinket + 4 DR slots. Raid frames are the widest-fanned-out frame
    -- type (up to MV.MaxRaidMembers instances), so this trades a bit of
    -- simultaneous DR-category visibility for meaningfully fewer eagerly
    -- created widgets; arena/party keep the full MV.DRSize default.
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
    local shouldRegister = MV.UnitExists(unit)
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
    if MV_RaidTestMode then
      if InCombatLockdown() then return end
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
      defaultFrames:UnregisterAllEvents()
      if InCombatLockdown() then
        defaultFrames:SetAlpha(0)
      else
        defaultFrames:Hide()
      end
    end
  end

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
    MV_RaidTestMode = false
    UpdateVisibility()
    UpdateBroadcastEvents()
    if MV.UnitExists(unit) then
      MV.ApplyClassColor(raidFrame)
      MV.UpdateHealthBar(raidFrame)
      MV.UpdateAbsorbBar(raidFrame)
      MV.UpdateAuras(raidFrame)
      MV.UpdateTrinket(raidFrame, true)
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

  raidFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      OnReset()
      if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        MV.ResetOrbs(raidFrame)
      end
    end
    if MV_RaidTestMode or (MV.NumGroupMembers < 6 or MV.NumGroupMembers == 0) then return end
    if MV.MustUpdate then
      LayoutRaidFrames()
    end
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
      MV.UpdateTrinket(raidFrame, true)
    elseif event == "UNIT_TARGET" then
      MV.UpdateTargetIndicator(raidFrame)
    elseif event == "LOSS_OF_CONTROL_ADDED" or event == "LOSS_OF_CONTROL_UPDATE" then
      if arg1 == unit then
        MV.TryAndUpdateDRStateFromLOC(raidFrame, arg2)
      end
    elseif event == "ARENA_OPPONENT_UPDATE" then
      MV.UpdateOrbs(raidFrame, arg1, arg2)
    end
  end)
  RaidFrames[index] = raidFrame
end

for i = 1, MV.MaxRaidMembers do
  CreateRaidFrame(i)
end
