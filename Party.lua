local _, MVPF      = ...

local baseName     = "MVPF_PartyFrame"

MVPF_PartyTestMode = false

local MAX_AURAS    = 3
local DEFAULT_SIZE = 32




-- ===========================
-- Create one party unit frame
-- ===========================

local function CreatePartyFrame(index)
  local unit = "party" .. index
  local name = baseName .. index

  local f, auraContainer, health = MVPF_Common.CreateUnitFrame({
    name     = name,
    unit     = unit,
    point    = { "CENTER", UIParent, "CENTER", -280 - (index - 1) * 55, 0 },
    size     = { 50, 210 },
    maxAuras = MAX_AURAS,
    iconSize = DEFAULT_SIZE,
  })
  f:SetAttribute("type2", "togglemenu")

  f.IsDriverRegistered = false

  local defaultR, defaultG, defaultB
  local function UpdateHealth()
    if MVPF_PartyTestMode then return end
    MVPF_Common.UpdateHealthBar(health, unit)
    if not health or not defaultR then return end
    if MVPF_Common.CheckMultiSpellRange(unit) then
      health:SetStatusBarColor(defaultR, defaultG, defaultB, MVPF_Common.RegAlpha)
    else
      health:SetStatusBarColor(defaultR, defaultG, defaultB, MVPF_Common.OtherAlpha)
    end
  end

  local function SetClassColor()
    local r, g, b = MVPF_Common.GetClassColor(unit)
    if not health then return end
    health:SetStatusBarColor(r, g, b, MVPF_Common.RegAlpha)
    defaultR, defaultG, defaultB = r, g, b
  end

  local function UpdateVisibility()
    local numGroup = GetNumGroupMembers() or 0
    if MVPF_PartyTestMode then
      UnregisterUnitWatch(f)
      f.IsDriverRegistered = false
      f:Show()
    elseif (numGroup > 5 or numGroup == 0) and not InCombatLockdown() then
      UnregisterUnitWatch(f)
      f.IsDriverRegistered = false
      f:Hide()
    elseif not f.IsDriverRegistered and not InCombatLockdown() then
      RegisterUnitWatch(f)
      f.IsDriverRegistered = true
    end
  end

  local function UpdateTargetHighlight()
    MVPF_Common.UpdateTargetHighlight(f, unit, "MVPF_PartyTestMode")
  end

  -- ======================
  -- Aura container & icons
  -- ======================

  local function UpdateAuras()
    if MVPF_PartyTestMode then return end
    if not UnitExists(unit) then
      MVPF_Common.UpdateAuras(auraContainer, unit, {}, 0)
      return
    end
    local filters = {}
    local cfg = MVPF.GetUnitFilters("party")
    for filter, enabled in pairs(cfg) do
      if enabled then
        table.insert(filters, filter)
      end
    end

    MVPF_Common.UpdateAuras(
      auraContainer,
      unit,
      filters,
      MAX_AURAS
    )
  end

  function f:UpdateHealth() UpdateHealth() end

  function f:UpdateAuras() UpdateAuras() end

  function f:UpdateVisibility() UpdateVisibility() end

  function f:SetClassColor() SetClassColor() end

  function f:UpdateTargetHighlight() UpdateTargetHighlight() end

  -- ===================
  -- Event-driven wiring
  -- ===================

  f:RegisterEvent("GROUP_ROSTER_UPDATE")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("UNIT_HEALTH")
  f:RegisterEvent("UNIT_MAXHEALTH")
  f:RegisterEvent("UNIT_NAME_UPDATE")
  f:RegisterEvent("UNIT_AURA")
  f:RegisterEvent("PLAYER_TARGET_CHANGED")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  f:RegisterEvent("UNIT_OTHER_PARTY_CHANGED")
  f:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  f:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  f:SetScript("OnEvent", function(_, event, arg1)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      MVPF_PartyTestMode = false
      UpdateVisibility()
      if not UnitExists(unit) then return end
      UpdateTargetHighlight()
      SetClassColor()
      UpdateHealth()
      UpdateAuras()
    end
    if MVPF_PartyTestMode then return end
    if event == "PLAYER_TARGET_CHANGED" then
      UpdateTargetHighlight()
    elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH")
        and arg1 == unit then
      UpdateHealth()
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      UpdateHealth()
    elseif event == "UNIT_NAME_UPDATE" and arg1 == unit then
      SetClassColor()
    elseif event == "UNIT_AURA" and arg1 == unit then
      UpdateAuras()
    end
  end)
end

-- Create frames for party1–party4
for i = 1, 4 do
  CreatePartyFrame(i)
end
