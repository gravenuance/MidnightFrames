local _, MV = ...
local baseName = "MV_BossFrame"

MV_BossTestMode = false

local MAX_BOSS_FRAMES = 5
local MAX_AURAS = 4

local blizzContainerName = "BossTargetFrameContainer"
local blizzFrameBase = "Boss"

function InInstance()
  local _, instanceType = IsInInstance()
  return instanceType == "party" or instanceType == "raid"
end

------------------------------------------------------------------------
-- Boss frame creation
------------------------------------------------------------------------

local function SetBossFrame(index)
  local unit = "boss" .. index
  local name = baseName .. index

  local bossFrame = MV.CreateUnitFrame({
    name     = name,
    unit     = unit,
    unitKey  = "boss",
    point    = { "CENTER", UIParent, "CENTER", MV.FrameX + (index - 1) * MV.FrameSpace, 0 },
    size     = { MV.SizeX, MV.SizeYAlt },
    maxAuras = MAX_AURAS,
    iconSize = MV.DefaultSize,
  })
  bossFrame:SetFrameLevel(10)

  local HAS_REGISTERED_WATCH = false
  local function UpdateVisibility()
    local hasUnit = MV.UnitExists(unit)

    if not InInstance() or not hasUnit or MV_BossTestMode then
      if HAS_REGISTERED_WATCH and not InCombatLockdown() then
        UnregisterUnitWatch(bossFrame)
        HAS_REGISTERED_WATCH = false
      end
      if not InCombatLockdown() then
        if MV_BossTestMode then
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
    if frame.MV_Hooked then return end
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
    frame.MV_Hooked = true
  end

  local function HideBossContainer()
    local container = _G[blizzContainerName]
    if not container then return end
    if container.MV_Hooked then return end
    if container.UpdateShownState then
      hooksecurefunc(container, "SetShown", ForceHide)
    end
    for i = 1, MAX_BOSS_FRAMES do
      HideBossFrameAndSpellBar(i)
    end
    container.MV_Hooked = true
  end

  local function SetupBossHooks()
    HideBossContainer()
  end

  bossFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  bossFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  bossFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  bossFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  bossFrame:RegisterUnitEvent("UNIT_AURA", unit)
  bossFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
  bossFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
  bossFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  bossFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  bossFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  bossFrame:SetScript("OnEvent", function(self, event)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      MV_BossTestMode = false
      UpdateVisibility()
      SetupBossHooks()
    end
    if not InInstance() then return end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MV.UpdateHealthBar(bossFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.SetRangeAlpha(bossFrame)
    elseif event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(bossFrame, MV_BossTestMode)
    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
      MV.ApplyClassColor(bossFrame)
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(bossFrame)
    end
  end)
end

for i = 1, MAX_BOSS_FRAMES do
  SetBossFrame(i)
end
