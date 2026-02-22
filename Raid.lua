local _, MV        = ...

local baseName     = "MV_RaidFrame"

MV_RaidTestMode    = false

local RaidFrames   = {}

local MAX_AURAS    = 3

local visibleUnits = 0

local function LayoutRaidFrames()
  if visibleUnits < 6 then return end
  local placed = math.floor(visibleUnits / 2)
  for key, frame in pairs(RaidFrames) do
    if MV.UnitExists(frame.unit) then
      frame:ClearAllPoints()
      frame:SetPoint("CENTER", UIParent, "CENTER", -MV.FrameX * 1.5, placed * (MV.RaidSizeY + 5))
      placed = placed - 1
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
  })
  raidFrame.IsDriverRegistered = false

  local function UpdateVisibility()
    local ok, numRaid = MV.CallExternalFunction({
      functionName = "GetNumGroupMembers"
    })
    if not ok then numRaid = 0 end
    if MV_RaidTestMode then
      UnregisterUnitWatch(raidFrame)
      raidFrame.IsDriverRegistered = false
      raidFrame:Show()
    elseif (numRaid < 6 or numRaid == 0) and not InCombatLockdown() then
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

  raidFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      MV_RaidTestMode = false
      UpdateVisibility()
      visibleUnits = visibleUnits - 1
      if MV.UnitExists(unit) then
        MV.UpdateTargetHighlight(raidFrame)
        MV.ApplyClassColor(raidFrame)
        MV.UpdateHealthBar(raidFrame)
        MV.UpdateAuras(raidFrame)
        MV.ResetDR(raidFrame)
        MV.UpdateTrinket(raidFrame)
        visibleUnits = visibleUnits + 1
        LayoutRaidFrames()
      end
    end
    if MV_RaidTestMode then return end
    if event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(raidFrame)
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MV.UpdateHealthBar(raidFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.UpdateHealthBar(raidFrame)
    elseif event == "UNIT_NAME_UPDATE" then
      MV.ApplyClassColor(raidFrame)
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(raidFrame)
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" or event == "ARENA_COOLDOWNS_UPDATE" then
      if arg1 == unit then
        MV.UpdateTrinket(raidFrame, true)
      end
    end
  end)
  RaidFrames[index] = raidFrame
end

for i = 1, 20 do
  CreateRaidFrame(i)
end
