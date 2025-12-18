local addonName = ...

local frameName = "MVPF_TargetFrame"

MVPF_TargetTestMode = false

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
        -- In test mode, force shown (safe out of combat; you can keep this if you only toggle test out of combat)
        f:Show()
        return
    end

    -- In normal mode, do NOT touch visibility; RegisterUnitWatch controls it.
    -- You can still early-return if no target to skip work:
    if not UnitExists("target") then
        return
    end
end
--UpdateVisibility()



local function UpdateHealth()
    if MVPF_TargetTestMode then return end
    MVPF_Common.UpdateHealthBar(health, "target")
end

local function ApplyClassColor()
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

-- ===================
-- Event-driven wiring
-- ===================

local ef = CreateFrame("Frame", frameName .. "Events", f)
ef:RegisterEvent("PLAYER_TARGET_CHANGED")
ef:RegisterEvent("UNIT_HEALTH")
ef:RegisterEvent("UNIT_MAXHEALTH")
ef:RegisterEvent("UNIT_AURA")
ef:RegisterEvent("UNIT_NAME_UPDATE")

ef:SetScript("OnEvent", function(self, event, arg1)
    if MVPF_TargetTestMode then return end

    if event == "PLAYER_TARGET_CHANGED"
        or (event == "UNIT_NAME_UPDATE" and arg1 == "target") then
        if not UnitExists("target") then
            return
        end
        ApplyClassColor()
        UpdateHealth()
        UpdateAuras()
    elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") and arg1 == "target" then
        UpdateHealth()
    elseif event == "UNIT_AURA" and arg1 == "target" then
        UpdateAuras()
    end
end)
