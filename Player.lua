local _, MVPF = ...

local MAX_AURAS = 4
-- ==============================
-- Core secure player unit frame
-- ==============================

local f, auraContainer, health = MVPF_Common.CreateUnitFrame({
  name = "MVPF_PlayerFrame",
  unit = "player",
  point = { "CENTER", UIParent, "CENTER", -225, 0 },
  size = { 50, 220 },
  maxAuras = MAX_AURAS,
  iconSize = 26,
})

f:SetAttribute("type2", "togglemenu")

RegisterUnitWatch(f)

-- Center power label on health bar
local powerLabel
if health then
  powerLabel = health:CreateFontString(nil, "OVERLAY")
  powerLabel:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  powerLabel:SetPoint("CENTER", health, "CENTER", 0, 0)
  powerLabel:SetJustifyH("CENTER")
  powerLabel:SetJustifyV("MIDDLE")
  powerLabel:SetAlpha(1)
end

local petFrame, _, petHealth = MVPF_Common.CreateUnitFrame({
  name     = "MVPF_PetFrame",
  unit     = "pet",
  point    = { "BOTTOMLEFT", f, "BOTTOMRIGHT", 5, 0 },
  size     = { 20, 80 },
  maxAuras = 0,
  iconSize = 0,
})

petFrame:SetAttribute("type2", "togglemenu")

RegisterUnitWatch(petFrame)

local function UpdateHealthBar()
  MVPF_Common.UpdateHealthBar(health, "player")
end

local function UpdatePetHealthBar()
  MVPF_Common.UpdateHealthBar(petHealth, "pet")
end

local function ApplyClassColor()
  local r, g, b = MVPF_Common.GetClassColor("player", 0, 0.8, 0)
  if not health then return end

  -- Bar color
  health:SetStatusBarColor(r, g, b, 0.7)
  if petHealth then
    petHealth:SetStatusBarColor(r, g, b, 0.7)
  end

  -- Slightly darker text color
  if powerLabel then
    local dr, dg, db = r * 0.7, g * 0.7, b * 0.7
    powerLabel:SetTextColor(dr, dg, db, 1)
  end
end

local function UpdateTargetHighlight()
  MVPF_Common.UpdateTargetHighlight(f, "player", "MVPF_PlayerTestMode")
end

-- =================
-- Aura update logic
-- =================

local function UpdateAuras()
  if not UnitExists("player") then
    MVPF_Common.UpdateAuras(auraContainer, "player", {}, 0)
    return
  end

  local filters = {}
  local cfg = MVPF.GetUnitFilters("player")

  for filter, enabled in pairs(cfg) do
    if enabled then
      table.insert(filters, filter)
    end
  end
  MVPF_Common.UpdateAuras(
    auraContainer,
    "player",
    filters,
    MAX_AURAS
  )
end

-- ======================
-- Power label update
-- ======================

local function UpdatePowerLabel()
  if not powerLabel or not UnitExists("player") then return end
  local curve = C_CurveUtil.CreateCurve()
  curve:SetType(Enum.LuaCurveType.Linear)
  curve:AddPoint(0.0, 0)
  curve:AddPoint(1.0, 100)
  -- Fetch secret or normal power; do not touch it arithmetically
  local power = UnitPowerPercent("player", nil, true, curve)
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

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_TARGET")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("UNIT_MAXPOWER")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
  if event == "PLAYER_LOGIN"
      or event == "PLAYER_ENTERING_WORLD"
      or event == "PLAYER_ALIVE" then
    ApplyClassColor()
    UpdateHealthBar()
    UpdatePetHealthBar()
    UpdateAuras()
    UpdateTargetHighlight()
    UpdatePowerLabel()
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    if arg1 == "player" then
      UpdateHealthBar()
    elseif arg1 == "pet" then
      UpdatePetHealthBar()
    end
  elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") and arg1 == "player" then
    UpdatePowerLabel()
  elseif event == "UNIT_AURA" and arg1 == "player" then
    UpdateAuras()
  elseif event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_TARGET" and arg1 == "player") then
    UpdateTargetHighlight()
  end
end)
