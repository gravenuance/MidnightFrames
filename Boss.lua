local _, MF = ...
local baseName = "MF_Boss"

local MAX_BOSS_FRAMES = MF.GroupSize.boss
local MAX_AURAS = 4

local function SetBossFrame(index)
  local unit = "boss" .. index
  local name = baseName .. index

  local bx, by = MF.GetRosterMemberPoint("boss", index)
  local bossFrame = MF.CreateUnitFrame({
    name     = name,
    unit     = unit,
    unitKey  = "boss",
    point    = { "CENTER", UIParent, "CENTER", bx, by },
    size     = { MF.SizeX, MF.GroupFrameHeight },
    maxAuras = MAX_AURAS,
    iconSize = MF.DefaultSize,
  })
  bossFrame:SetFrameLevel(10)
  MF.RegisterMovableGroupMember("boss", bossFrame)

  -- Inside an instance the watch shows the frame whenever the boss unit
  -- exists, including on a pull, which no event of ours is needed for. It is
  -- taken off for test mode and outside instances. Registered here when
  -- already inside, so a reload mid-pull needn't wait for combat to end.
  local hasWatch = MF.InInstance()
  if hasWatch then
    RegisterUnitWatch(bossFrame)
  end

  local function UpdateVisibility()
    if InCombatLockdown() then
      MF.RunAfterCombat(name .. "Visibility", UpdateVisibility)
      return
    end
    local mode = MF.BossFrameMode(MF.InInstance(), MF.Test.Is("boss"))
    if mode == "watch" then
      if not hasWatch then
        RegisterUnitWatch(bossFrame)
        hasWatch = true
      end
      return
    end
    if hasWatch then
      UnregisterUnitWatch(bossFrame)
      hasWatch = false
    end
    if mode == "test" then
      bossFrame:Show()
    else
      bossFrame:Hide()
    end
  end

  function bossFrame:UpdateVisibility() UpdateVisibility() end

  local function RefreshAll()
    if MF.UnitExists(unit) then
      MF.ApplyClassColor(bossFrame)
      MF.UpdateHealthBar(bossFrame)
      MF.UpdateAbsorbBar(bossFrame)
      MF.UpdateAuras(bossFrame)
      MF.SetRangeAlpha(bossFrame)
      MF.UpdateRaidMark(bossFrame)
      MF.UpdateCastIndicator(bossFrame)
    end
  end

  bossFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  bossFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  bossFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")

  bossFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  bossFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  bossFrame:RegisterUnitEvent("UNIT_AURA", unit)
  bossFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

  bossFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

  bossFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  bossFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  bossFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  bossFrame:RegisterEvent("RAID_TARGET_UPDATE")

  MF.RegisterCastEvents(bossFrame)

  bossFrame:SetScript("OnEvent", function(_, event)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      MF.Test.Clear("boss")
      UpdateVisibility()
      MF.ResetTargetIndicator(bossFrame)
      -- fill in the frame right away if we reload mid-pull
      RefreshAll()
    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
      -- the watch shows the frame; this fills it in
      RefreshAll()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MF.UpdateHealthBar(bossFrame)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
      MF.UpdateAbsorbBar(bossFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MF.SetRangeAlpha(bossFrame)
    elseif event == "PLAYER_TARGET_CHANGED" then
      MF.UpdateTargetHighlight(bossFrame, MF.Test.Is("boss"))
    elseif event == "UNIT_AURA" then
      MF.UpdateAuras(bossFrame)
    elseif event == "RAID_TARGET_UPDATE" then
      MF.UpdateRaidMark(bossFrame)
    elseif MF.IsCastEvent(event) then
      MF.UpdateCastIndicator(bossFrame)
    end
  end)
end

MF.OnInit(function()
  MF.HideBlizzardFrame("BossTargetFrameContainer")
  for i = 1, MAX_BOSS_FRAMES do
    SetBossFrame(i)
  end
end)
