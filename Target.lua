local addonName = ...

local frameName = "MVPF_TargetFrame"

MVPF_TargetTestMode = false

local IsDriverRegistered = false

-- ============================
-- Core secure target unit frame
-- ============================

local f, auraContainer, health = MVPF_Common.CreateUnitFrame({
    name     = "MVPF_TargetFrame",
    unit     = "target",
    point    = { "CENTER", UIParent, "CENTER", 225, 0 },
    size     = { 50, 220 },
    maxAuras = 4,
    iconSize = 26,
})
RegisterUnitWatch(f)


local function UpdateVisibility()
    if MVPF_TargetTestMode then
        UnregisterUnitWatch(f)
        f:Show()
        IsDriverRegistered = false
    elseif not IsDriverRegistered then
        RegisterUnitWatch(f)
        IsDriverRegistered = true
    end
end
--UpdateVisibility()



local function UpdateHealth()
    if MVPF_TargetTestMode then return end
    MVPF_Common.UpdateHealthBar(health, "target")
end

local function SetClassColor()
    local r, g, b = MVPF_Common.GetClassColor("target", 0, 0.8, 0)
    if not health then return end
    health:SetStatusBarColor(r, g, b, 0.7)
end


-- =================
-- Aura update logic
-- =================

local function UpdateAuras()
    if MVPF_TargetTestMode then return end
    MVPF_Common.UpdateAuras(
        auraContainer,
        "target",
        { "HELPFUL PLAYER", "HARMFUL RAID", "HARMFUL PLAYER", "HELPFUL RAID" },
        20
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

f:SetScript("OnEvent", function(self, event, arg1)
    if (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
        MVPF_TargetTestMode = false
    end
    if MVPF_TargetTestMode then return end

    if event == "PLAYER_TARGET_CHANGED"
        or (event == "UNIT_NAME_UPDATE" and arg1 == "target") then
        UpdateVisibility()
        if not UnitExists("target") then
            return
        end
        SetClassColor()
        UpdateHealth()
        UpdateAuras()
    elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") and arg1 == "target" then
        UpdateHealth()
    elseif event == "UNIT_AURA" and arg1 == "target" then
        UpdateAuras()
    end
end)
