local _, MVPF = ...

MVPF_TargetTestMode = false

local IsDriverRegistered = false

local MAX_AURAS = 4

local DEFAULT_SIZE = 32

local defaultR, defaultG, defaultB
-- ============================
-- Core secure target unit frame
-- ============================

local f, auraContainer, health = MVPF_Common.CreateUnitFrame({
  name     = "MVPF_TargetFrame",
  unit     = "target",
  point    = { "CENTER", UIParent, "CENTER", 225, 0 },
  size     = { 50, 220 },
  maxAuras = MAX_AURAS,
  iconSize = DEFAULT_SIZE,
})
f:SetAttribute("type2", "togglemenu")
f.unit = "target"

local function UpdateVisibility()
  if InCombatLockdown() then return end
  if MVPF_TargetTestMode then
    UnregisterUnitWatch(f)
    f:Show()
    IsDriverRegistered = false
  elseif not IsDriverRegistered then
    RegisterUnitWatch(f)
    IsDriverRegistered = true
  end
end


local function UpdateHealth()
  if MVPF_TargetTestMode then return end
  MVPF_Common.UpdateHealthBar(health, f.unit)
  if not health or not defaultR then return end
  if MVPF_Common.CheckMultiSpellRange(f.unit) then
    health:SetStatusBarColor(defaultR, defaultG, defaultB, MVPF_Common.RegAlpha)
  else
    health:SetStatusBarColor(defaultR, defaultG, defaultB, MVPF_Common.OtherAlpha)
  end
end

local function SetClassColor()
  local r, g, b = MVPF_Common.GetClassColor(f.unit)
  if not health then return end
  health:SetStatusBarColor(r, g, b, MVPF_Common.RegAlpha)
  defaultR, defaultG, defaultB = r, g, b
end


-- =================
-- Aura update logic
-- =================

local function UpdateAuras()
  if MVPF_TargetTestMode then return end
  if not UnitExists(f.unit) then
    MVPF_Common.UpdateAuras(auraContainer, f.unit, {}, 0)
    return
  end
  local filters = {}
  local cfg = MVPF.GetUnitFilters(f.unit)
  for filter, enabled in pairs(cfg) do
    if enabled then
      table.insert(filters, filter)
    end
  end

  MVPF_Common.UpdateAuras(
    auraContainer,
    f.unit,
    filters,
    MAX_AURAS
  )
end

function f:UpdateHealth() UpdateHealth() end

function f:UpdateAuras() UpdateAuras() end

function f:UpdateVisibility() UpdateVisibility() end

function f:SetClassColor() SetClassColor() end

-- ===================
-- Event-driven wiring
-- ===================

f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("UNIT_MAXHEALTH")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("UNIT_NAME_UPDATE")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

f:SetScript("OnEvent", function(_, event, arg1)
  if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
    MVPF_TargetTestMode = false
    UpdateVisibility()
  end
  if MVPF_TargetTestMode then return end

  if event == "PLAYER_TARGET_CHANGED"
      or (event == "UNIT_NAME_UPDATE" and arg1 == f.unit) then
    UpdateVisibility()
    if not UnitExists(f.unit) then
      return
    end
    SetClassColor()
    UpdateHealth()
    UpdateAuras()
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") and arg1 == f.unit then
    UpdateHealth()
  elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
    UpdateHealth()
  elseif event == "UNIT_AURA" and arg1 == f.unit then
    UpdateAuras()
  end
end)
