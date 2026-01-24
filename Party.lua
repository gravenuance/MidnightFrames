local addonName, MVPF = ...

local baseName        = "MVPF_PartyFrame"
local SOLID_TEXTURE   = "Interface\\Buttons\\WHITE8x8"

MVPF_PartyTestMode    = false



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
    maxAuras = 3,
    iconSize = 26,
  })
  f:SetAttribute("type2", "togglemenu")
  -- Outer border for "arena targeting this party" highlight
  local outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  outerBorder:SetAllPoints(f)
  outerBorder:SetBackdrop({
    edgeFile = SOLID_TEXTURE,
    edgeSize = 5,
  })
  outerBorder:SetBackdropBorderColor(0, 0, 0, 0) -- start hidden
  f.outerBorder = outerBorder

  f.IsDriverRegistered = false

  local function UpdateArenaTargets()
    if MVPF_PartyTestMode then return end

    if not UnitExists(unit) then
      outerBorder:SetBackdropBorderColor(0, 0, 0, 0)
      return
    end

    local count = 0

    -- arena1
    local a1Exists = false
    pcall(function()
      if UnitExists("arena1") then a1Exists = true end
    end)

    local a1TargetExists = false
    pcall(function()
      if UnitExists("arena1target") then a1TargetExists = true end
    end)

    local a1IsUnit = false
    pcall(function()
      if UnitIsUnit("arena1target", unit) then a1IsUnit = true end
    end)

    if a1Exists and a1TargetExists and a1IsUnit then
      count = count + 1
    end

    -- arena2
    local a2Exists = false
    pcall(function()
      if UnitExists("arena2") then a2Exists = true end
    end)

    local a2TargetExists = false
    pcall(function()
      if UnitExists("arena2target") then a2TargetExists = true end
    end)

    local a2IsUnit = false
    pcall(function()
      if UnitIsUnit("arena2target", unit) then a2IsUnit = true end
    end)

    if a2Exists and a2TargetExists and a2IsUnit then
      count = count + 1
    end

    -- arena3
    local a3Exists = false
    pcall(function()
      if UnitExists("arena3") then a3Exists = true end
    end)

    local a3TargetExists = false
    pcall(function()
      if UnitExists("arena3target") then a3TargetExists = true end
    end)

    local a3IsUnit = false
    pcall(function()
      if UnitIsUnit("arena3target", unit) then a3IsUnit = true end
    end)

    if a3Exists and a3TargetExists and a3IsUnit then
      count = count + 1
    end

    if count == 0 then
      outerBorder:SetBackdropBorderColor(0, 0, 0, 0)
    elseif count == 1 then
      outerBorder:SetBackdropBorderColor(1, 0.5, 0, 1)
    else
      outerBorder:SetBackdropBorderColor(1, 0, 0, 1)
    end
  end



  local function UpdateHealth()
    if MVPF_PartyTestMode then return end
    MVPF_Common.UpdateHealthBar(health, unit)
  end

  local function SetClassColor()
    local r, g, b = MVPF_Common.GetClassColor(unit, 0, 0.8, 0)
    if not health then return end
    health:SetStatusBarColor(r, g, b, 0.7)
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
      20
    )
  end

  function f:UpdateHealth() UpdateHealth() end

  function f:UpdateAuras() UpdateAuras() end

  function f:UpdateVisibility() UpdateVisibility() end

  function f:UpdateArenaTargets() UpdateArenaTargets() end

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
  f:RegisterEvent("UNIT_TARGET")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  f:SetScript("OnEvent", function(self, event, arg1)
    if event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
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
    if event == "PLAYER_TARGET_CHANGED"
        or (event == "UNIT_TARGET" and arg1 == "player") then
      UpdateTargetHighlight()
    elseif event == "UNIT_TARGET" and (arg1 == "arena1" or arg1 == "arena2" or arg1 == "arena3") then
      UpdateArenaTargets()
    elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH")
        and arg1 == unit then
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
