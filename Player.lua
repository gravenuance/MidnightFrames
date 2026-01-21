local addonName = ...

-- ==============================
-- Core secure player unit frame
-- ==============================

local f, auraContainer, health = MVPF_Common.CreateUnitFrame({
    name = "MVPF_PlayerFrame",
    unit = "player",
    point = { "CENTER", UIParent, "CENTER", -225, 0 },
    size = { 50, 220 },
    maxAuras = 4,
    iconSize = 26,
})

f:SetAttribute("type2", "togglemenu")

RegisterUnitWatch(f)

-- Center power label on health bar
local powerLabel = health:CreateFontString(nil, "OVERLAY")
powerLabel:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
powerLabel:SetPoint("CENTER", health, "CENTER", 0, 0)
powerLabel:SetJustifyH("CENTER")
powerLabel:SetJustifyV("MIDDLE")
powerLabel:SetAlpha(1)

local function UpdateHealthBar()
    MVPF_Common.UpdateHealthBar(health, "player")
end

local function ApplyClassColor()
    local r, g, b = MVPF_Common.GetClassColor("player", 0, 0.8, 0)
    if not health then return end

    -- Bar color
    health:SetStatusBarColor(r, g, b, 0.7)

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

    MVPF_Common.UpdateAuras(
        auraContainer,
        "player",
        { "HELPFUL RAID", "HARMFUL RAID" },
        20
    )
end

-- ======================
-- Power label update
-- ======================

local function UpdatePowerLabel()
    if not powerLabel or not UnitExists("player") then return end

    -- Fetch secret or normal power; do not touch it arithmetically
    local power = UnitPower("player")
    if power == nil then
        powerLabel:SetText("")
        return
    end

    -- Convert to string without doing math; concatenation is allowed
    powerLabel:SetText(tostring(power))
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
        UpdateAuras()
        UpdateTargetHighlight()
        UpdatePowerLabel()
    elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") and arg1 == "player" then
        UpdateHealthBar()
    elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") and arg1 == "player" then
        UpdatePowerLabel()
    elseif event == "UNIT_AURA" and arg1 == "player" then
        UpdateAuras()
    elseif event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_TARGET" and arg1 == "player") then
        UpdateTargetHighlight()
    end
end)
