local addonName     = ...

local baseName      = "MVPF_PartyFrame"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MVPF_PartyTestMode  = false

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
    -- Outer border for "arena targeting this party" highlight
    local outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    outerBorder:SetAllPoints(f)
    outerBorder:SetBackdrop({
        edgeFile = SOLID_TEXTURE,
        edgeSize = 5,
    })
    outerBorder:SetBackdropBorderColor(0, 0, 0, 0) -- start hidden
    f.outerBorder = outerBorder

    local function UpdateArenaTargets()
        if MVPF_PartyTestMode then return end
        if not UnitExists(unit) then
            outerBorder:SetBackdropBorderColor(0, 0, 0, 0)
            return
        end

        local count = 0

        if UnitExists("arena1") and UnitExists("arena1target")
            and UnitIsUnit("arena1target", unit) then
            count = count + 1
        end
        if UnitExists("arena2") and UnitExists("arena2target")
            and UnitIsUnit("arena2target", unit) then
            count = count + 1
        end
        if UnitExists("arena3") and UnitExists("arena3target")
            and UnitIsUnit("arena3target", unit) then
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

    local function ApplyClassColor()
        local r, g, b = MVPF_Common.GetClassColor(unit, 0, 0.8, 0)
        if not health then return end
        health:SetStatusBarColor(r, g, b, 0.7)
    end

    local function UpdateVisibility()
        local numGroup = GetNumGroupMembers() or 0
        if numGroup > 5 then
            f:Hide()
            return
        end

        if UnitExists(unit) then
            f:Show()
        else
            f:Hide()
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
        MVPF_Common.UpdateAuras(
            auraContainer,
            unit,
            { "HARMFUL RAID", "HELPFUL PLAYER" },
            20
        )
    end

    function f:UpdateHealth() UpdateHealth() end

    function f:UpdateAuras() UpdateAuras() end

    function f:UpdateVisibility() UpdateVisibility() end

    -- ===================
    -- Event-driven wiring
    -- ===================

    local ef = CreateFrame("Frame", name .. "Events", f)
    ef:RegisterEvent("GROUP_ROSTER_UPDATE")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:RegisterEvent("UNIT_HEALTH")
    ef:RegisterEvent("UNIT_MAXHEALTH")
    ef:RegisterEvent("UNIT_NAME_UPDATE")
    ef:RegisterEvent("UNIT_AURA")
    ef:RegisterEvent("PLAYER_TARGET_CHANGED")
    ef:RegisterEvent("UNIT_TARGET")

    ef:SetScript("OnEvent", function(self, event, arg1)
        if MVPF_PartyTestMode then return end

        if event == "PLAYER_TARGET_CHANGED"
            or (event == "UNIT_TARGET" and arg1 == "player") then
            UpdateTargetHighlight()
        end

        if event == "UNIT_TARGET" and (arg1 == "arena1" or arg1 == "arena2" or arg1 == "arena3") then
            UpdateArenaTargets()
        end

        if event == "GROUP_ROSTER_UPDATE"
            or event == "PLAYER_ENTERING_WORLD" then
            UpdateVisibility()
            UpdateTargetHighlight()
            if not UnitExists(unit) then return end
            ApplyClassColor()
            UpdateHealth()
            UpdateAuras()
        elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH")
            and arg1 == unit then
            UpdateHealth()
        elseif event == "UNIT_NAME_UPDATE" and arg1 == unit then
            ApplyClassColor()
        elseif event == "UNIT_AURA" and arg1 == unit then
            UpdateAuras()
        end
    end)
end

-- Create frames for party1–party4
for i = 1, 4 do
    CreatePartyFrame(i)
end
