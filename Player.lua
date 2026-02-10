local _, MVPF = ...

local MAX_AURAS = 4

local C_CurveUtil = C_CurveUtil
local UnitPowerPercent = UnitPowerPercent

local DEFAULT_SIZE = 32
-- ==============================
-- Core secure player unit frame
-- ==============================

local f, auraContainer, health = MVPF_Common.CreateUnitFrame({
  name = "MVPF_PlayerFrame",
  unit = "player",
  point = { "CENTER", UIParent, "CENTER", -225, 0 },
  size = { 50, 220 },
  maxAuras = MAX_AURAS,
  iconSize = DEFAULT_SIZE,
})
f.unit = "player"

f:SetAttribute("type2", "togglemenu")

RegisterUnitWatch(f)

-- Center power label on health bar
local powerLabel
if health then
  powerLabel = health:CreateFontString(nil, "OVERLAY")
  powerLabel:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  powerLabel:SetPoint("BOTTOM", health, "TOP", 0, -20)
  powerLabel:SetJustifyH("CENTER")
  powerLabel:SetJustifyV("MIDDLE")
  powerLabel:SetAlpha(1)
end

local petFrame, _, petHealth = MVPF_Common.CreateUnitFrame({
  name     = "MVPF_PetFrame",
  unit     = "pet",
  point    = { "TOPLEFT", f, "TOPRIGHT", 5, 0 },
  size     = { 20, 80 },
  maxAuras = 0,
  iconSize = 0,
})

petFrame.unit = "pet"

petFrame:SetAttribute("type2", "togglemenu")

RegisterUnitWatch(petFrame)

local function UpdateHealthBar()
  MVPF_Common.UpdateHealthBar(health, f.unit)
end

local function UpdatePetHealthBar()
  MVPF_Common.UpdateHealthBar(petHealth, petFrame.unit)
end

local function ApplyClassColor()
  local r, g, b = MVPF_Common.GetClassColor(f.unit)

  if not health then return end

  -- Bar color
  health:SetStatusBarColor(r, g, b, MVPF_Common.RegAlpha)
  if petHealth then
    petHealth:SetStatusBarColor(r, g, b, MVPF_Common.RegAlpha)
  end

  -- Slightly darker text color
  if powerLabel then
    local dr, dg, db = r * 0.7, g * 0.7, b * 0.7
    powerLabel:SetTextColor(dr, dg, db, 1)
  end
end

local function UpdateTargetHighlight()
  MVPF_Common.UpdateTargetHighlight(f, f.unit, "MVPF_PlayerTestMode", petFrame)
end

-- =================
-- Aura update logic
-- =================

local function UpdateAuras()
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

-- ======================
-- Power label update
-- ======================

local function UpdatePowerLabel()
  if not powerLabel or not UnitExists(f.unit) then return end
  local curve = C_CurveUtil.CreateCurve()
  curve:SetType(Enum.LuaCurveType.Linear)
  curve:AddPoint(0.0, 0)
  curve:AddPoint(1.0, 100)
  -- Fetch secret or normal power; do not touch it arithmetically
  local power = UnitPowerPercent(f.unit, nil, true, curve)
  if power == nil then
    powerLabel:SetText("")
    return
  end
  -- Convert to string without doing math; concatenation is allowed
  powerLabel:SetText(string.format("%.0f", power))
end

-- ===================
-- Event-driven wiring
-- ===================

--local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("UNIT_MAXHEALTH")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_TARGET")
f:RegisterEvent("UNIT_POWER_UPDATE")
f:RegisterEvent("UNIT_MAXPOWER")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("UNIT_PET")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_UNGHOST")
f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")


f:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN"
      or event == "PLAYER_ENTERING_WORLD"
      or event == "PLAYER_ALIVE"
      or event == "ZONE_CHANGED" then
    ApplyClassColor()
    UpdateHealthBar()
    UpdatePetHealthBar()
    UpdateAuras()
    UpdateTargetHighlight()
    UpdatePowerLabel()
    MVPF_Common.PositionLossOfControlFrame()
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    if arg1 == f.unit then
      UpdateHealthBar()
    elseif arg1 == petFrame.unit then
      UpdatePetHealthBar()
    end
  elseif event == "UNIT_PET" and arg1 == f.unit then
    UpdatePetHealthBar()
  elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" then
    UpdateHealthBar()
  elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") and arg1 == f.unit then
    UpdatePowerLabel()
  elseif event == "UNIT_AURA" and arg1 == f.unit then
    UpdateAuras()
  elseif event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_TARGET" and arg1 == f.unit) then
    UpdateTargetHighlight()
  elseif event == "SPELL_RANGE_CHECK_UPDATE" then
    MVPF_Common.RegisterRangeSpell(arg1)
  end
end)
