local _, MF = ...
local baseName = "MF_Boss"

MF_BossTestMode = false

local MAX_BOSS_FRAMES = 5
local MAX_AURAS = 4

local blizzContainerName = "BossTargetFrameContainer"
local blizzFrameBase = "Boss"

local function SetBossFrame(index)
  local unit = "boss" .. index
  local name = baseName .. index

  local bossFrame = MF.CreateUnitFrame({
    name     = name,
    unit     = unit,
    unitKey  = "boss",
    point    = { "CENTER", UIParent, "CENTER", MF.FrameX + (index - 1) * MF.FrameSpace, 0 },
    size     = { MF.SizeX, MF.SizeYAlt },
    maxAuras = MAX_AURAS,
    iconSize = MF.DefaultSize,
  })
  bossFrame:SetFrameLevel(10)

  local HAS_REGISTERED_WATCH = false
  local function UpdateVisibility()
    local hasUnit = MF.UnitExists(unit)

    if not MF.InInstance() or not hasUnit or MF_BossTestMode then
      if HAS_REGISTERED_WATCH and not InCombatLockdown() then
        UnregisterUnitWatch(bossFrame)
        HAS_REGISTERED_WATCH = false
      end
      if not InCombatLockdown() then
        if MF_BossTestMode then
          bossFrame:Show()
        else
          bossFrame:Hide()
        end
      end
      return
    end

    if not HAS_REGISTERED_WATCH and not InCombatLockdown() then
      RegisterUnitWatch(bossFrame)
      HAS_REGISTERED_WATCH = true
    end
  end

  function bossFrame:UpdateVisibility() UpdateVisibility() end

  local function ForceHide(frame)
    frame:SetAlpha(0)
  end

  local function HideBossFrameAndSpellBar(index)
    local frame = _G[blizzFrameBase .. index .. "TargetFrame"]
    if not frame then return end
    if frame.MF_Hooked then return end
    local spellBar = frame.spellBar or _G[frame:GetName() .. "SpellBar"] or
        _G[blizzFrameBase .. index .. "TargetFrameSpellBar"]
    if spellBar then
      if spellBar.UpdateShownState then
        hooksecurefunc(spellBar, "UpdateShownState", ForceHide)
      end
    end
    if frame.UpdateShownState then
      hooksecurefunc(frame, "UpdateShownState", ForceHide)
    end
    if frame.OnShow then
      hooksecurefunc(frame, "OnShow", ForceHide)
    end
    frame.MF_Hooked = true
  end

  local function HideBossContainer()
    local container = _G[blizzContainerName]
    if not container then return end
    if container.MF_Hooked then return end
    if container.SetShown then
      hooksecurefunc(container, "SetShown", ForceHide)
    end
    for i = 1, MAX_BOSS_FRAMES do
      HideBossFrameAndSpellBar(i)
    end
    container.MF_Hooked = true
  end

  local function SetupBossHooks()
    HideBossContainer()
  end

  -- DEFAULTS
  bossFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  bossFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  bossFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")

  -- UNIT FRAMES
  bossFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  bossFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  bossFrame:RegisterUnitEvent("UNIT_AURA", unit)
  bossFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

  -- PLAYER HIGHLIGHT
  bossFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

  -- RANGE CHECK
  bossFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  bossFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  bossFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  -- RAID TARGET MARK
  bossFrame:RegisterEvent("RAID_TARGET_UPDATE")

  -- CAST INDICATOR
  bossFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
  bossFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
  bossFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
  bossFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
  bossFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
  bossFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
  bossFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", unit)
  bossFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit)


  bossFrame:SetScript("OnEvent", function(self, event)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      MF_BossTestMode = false
      UpdateVisibility()
      SetupBossHooks()
      MF.ResetTargetIndicator(bossFrame)
      -- Mirrors Arena/Party/Raid.lua: if the boss unit already exists here
      -- (e.g. /reload or reconnect mid-pull), populate the frame immediately
      -- instead of leaving it blank until the next native UNIT_HEALTH/
      -- UNIT_AURA/etc. event happens to fire.
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
    if not MF.InInstance() then return end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MF.UpdateHealthBar(bossFrame)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
      MF.UpdateAbsorbBar(bossFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MF.SetRangeAlpha(bossFrame)
    elseif event == "PLAYER_TARGET_CHANGED" then
      MF.UpdateTargetHighlight(bossFrame, MF_BossTestMode)
    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
      MF.ApplyClassColor(bossFrame)
      MF.UpdateRaidMark(bossFrame)
    elseif event == "UNIT_AURA" then
      MF.UpdateAuras(bossFrame)
    elseif event == "RAID_TARGET_UPDATE" then
      MF.UpdateRaidMark(bossFrame)
    elseif event == "UNIT_SPELLCAST_START"
        or event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_CHANNEL_START"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_INTERRUPTIBLE"
        or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
    then
      MF.UpdateCastIndicator(bossFrame)
    end
  end)
end

for i = 1, MAX_BOSS_FRAMES do
  SetBossFrame(i)
end
