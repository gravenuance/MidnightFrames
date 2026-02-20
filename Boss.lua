local _, MV = ...
local baseName = "MV_BossFrame"

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

  local f = MV.CreateUnitFrame({
    name     = name,
    unit     = unit,
    point    = { "CENTER", UIParent, "CENTER", 280 + (index - 1) * 55, 0 },
    size     = { 50, 210 },
    maxAuras = MAX_AURAS,
    iconSize = MV.DefaultSize,
  })
  f:SetFrameLevel(10)

  local HAS_REGISTERED_WATCH = false
  local function UpdateVisibility()
    local hasUnit = UnitExists(unit)

    if not InInstance() or not hasUnit then
      if HAS_REGISTERED_WATCH and not InCombatLockdown() then
        UnregisterUnitWatch(f)
        HAS_REGISTERED_WATCH = false
      end
      if not InCombatLockdown() then
        f:Hide()
      end
      return
    end

    if not HAS_REGISTERED_WATCH and not InCombatLockdown() then
      RegisterUnitWatch(f)
      HAS_REGISTERED_WATCH = true
    end
  end

  function f:UpdateVisibility() UpdateVisibility() end

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
      hooksecurefunc(container, "Show", ForceHide)
    end
    for i = 1, MAX_BOSS_FRAMES do
      HideBossFrameAndSpellBar(i)
    end
    container.MV_Hooked = true
  end

  local function SetupBossHooks()
    HideBossContainer()
  end

  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  f:RegisterUnitEvent("UNIT_HEALTH", unit)
  f:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  f:RegisterUnitEvent("UNIT_AURA", unit)
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  f:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
  f:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  f:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  f:SetScript("OnEvent", function(self, event)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      UpdateVisibility()
      SetupBossHooks()
      MV.UpdateHealthBar(f)
      MV.UpdateTargetHighlight(f)
    end
    if not InInstance() then return end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      MV.UpdateHealthBar(f)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.SetRangeAlpha(f)
    elseif event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(f)
    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
      MV.ApplyClassColor(f)
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(f)
    end
  end)
end

for i = 1, MAX_BOSS_FRAMES do
  SetBossFrame(i)
end
