local baseName = "MVPF_BossFrame"

local MAX_BOSS_FRAMES = 5

local blizzContainerName = "BossTargetFrameContainer"
local blizzFrameBase = "Boss" -- Boss1TargetFrame, Boss2TargetFrame, ...

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

  local f, health = MVPF_Common.CreateUnitFrame({
    name  = name,
    unit  = unit,
    point = { "CENTER", UIParent, "CENTER", 280 + (index - 1) * 55, 0 },
    size  = { 50, 210 },
    kind  = "boss",
  })

  f:SetFrameLevel(10)


  local function UpdateHealth()
    MVPF_Common.UpdateHealthBar(health, unit)
  end

  local function UpdateTargetHighlight()
    MVPF_Common.UpdateTargetHighlight(f, unit)
  end

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

  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  f:RegisterEvent("UNIT_HEALTH")
  f:RegisterEvent("UNIT_MAXHEALTH")
  f:RegisterEvent("UNIT_TARGET")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")

  f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      UpdateHealth()
      UpdateVisibility()
      UpdateTargetHighlight()
    end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      if arg1 == unit then
        UpdateHealth()
      end
    elseif event == "PLAYER_TARGET_CHANGED"
        or (event == "UNIT_TARGET" and arg1 == "player") then
      UpdateTargetHighlight()
    end
  end)
end

------------------------------------------------------------------------
-- Hide Blizzard boss frames & container
------------------------------------------------------------------------

local function HideBossFrameAndSpellBar(index)
  local frame = _G[blizzFrameBase .. index .. "TargetFrame"]
  if not frame then return end

  -- Hide spellbar
  local spellBar = frame.spellBar or _G[frame:GetName() .. "SpellBar"] or
      _G[blizzFrameBase .. index .. "TargetFrameSpellBar"]
  if spellBar and not spellBar.MVPF_Hooked then
    spellBar.MVPF_Hooked = true
    spellBar:Hide()
    spellBar:SetAlpha(0)
    spellBar.Show = spellBar.Hide
    hooksecurefunc(spellBar, "Show", spellBar.Hide)
  end

  -- Hide the boss unit frame itself
  if not frame.MVPF_Hooked then
    frame.MVPF_Hooked = true

    frame:Hide()
    frame:SetAlpha(0)

    local function ForceHide(self)
      self:Hide()
      self:SetAlpha(0)
    end

    hooksecurefunc(frame, "Show", ForceHide)

    if frame.UpdateShownState then
      hooksecurefunc(frame, "UpdateShownState", ForceHide)
    end
  end
end

local function HideBossContainer()
  local container = _G[blizzContainerName]
  if not container then return end

  if not container.MVPF_Hooked then
    container.MVPF_Hooked = true

    container:Hide()
    container:SetAlpha(0)

    local function ForceHide(self)
      self:Hide()
      self:SetAlpha(0)
    end

    hooksecurefunc(container, "Show", ForceHide)

    if container.UpdateShownState then
      hooksecurefunc(container, "UpdateShownState", ForceHide)
    end
  end

  -- Hide all children boss frames/spellbars
  for i = 1, MAX_BOSS_FRAMES do
    HideBossFrameAndSpellBar(i)
  end
end

------------------------------------------------------------------------
-- Loader: create MVPF boss frames + keep Blizzard hidden
------------------------------------------------------------------------

local function MVPF_SetupBossHooks()
  HideBossContainer()
  local container = _G[blizzContainerName]
  if container and not container.MVPF_OnShowHooked then
    container.MVPF_OnShowHooked = true
    hooksecurefunc(container, "Show", function(self)
      HideBossContainer()
    end)
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("ZONE_CHANGED_NEW_AREA")
loader:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
loader:SetScript("OnEvent", function()
  MVPF_SetupBossHooks()
  for i = 1, MAX_BOSS_FRAMES do
    local f = _G[baseName .. i]
    if f and f.UpdateVisibility then
      f:UpdateVisibility()
    end
  end
end)

for i = 1, MAX_BOSS_FRAMES do
  SetBossFrame(i)
end
