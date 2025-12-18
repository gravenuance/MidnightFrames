local addonName = ...

local baseName = "MVPF_ArenaFrame"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MVPF_ArenaTestMode = false
MVPF_ArenaPrepMode = {}

-- Arena Prep Check

local function ArenaSlotHasOpponent(index)
    if GetArenaOpponentSpec then
        local specID = GetArenaOpponentSpec(index)
        return specID and specID > 0
    end
    local unit = "arena" .. index
    return UnitExists(unit)
end

local function HideBlizzArenaStuff(index)
    local frame = _G["CompactArenaFrame"]
    if not frame then return end

    -- These are Member specific
    local arenaHide = {
        "RoleIcon",
        "Name",
        "Background",
        "HealthBar",
        "TempMaxHealthLoss",
        "CastingBarFrame",
        "PowerBar",
    }

    local prepHide = {
        "BarTexture",
        "SpecPortraitBorderTexture",
        "ClassNameText",
        "RoleIcon",
        "RoleIconTexture",
        "SpecNameText",
    }

    local stealthHide = {
        "BarTexture",
        "BackgroundTexture",
        "NameText",
        "RoleIconTexture",
    }

    local prematch = frame and frame.PreMatchFramesContainer
    -- Prematch frames
    if prematch then
        local pf = prematch["PreMatchFrame" .. index]
        if pf then
            for _, key in ipairs(prepHide) do
                local obj = pf[key]
                if obj and not obj._mvpfHidden then
                    obj:Hide()
                    hooksecurefunc(obj, "Show", obj.Hide)
                    obj._mvpfHidden = true
                end
            end
        end
    end

    -- Arena member frames (note: globals)
    local member = _G["CompactArenaFrameMember" .. index]
    if member then
        for _, key in ipairs(arenaHide) do
            local obj = member[key]
            if obj then
                obj:SetAlpha(0)
                obj:EnableMouse(false)
            end
        end
    end

    -- Stealthed frames (children of CompactArenaFrame)
    local stealth = frame and frame["StealthedUnitFrame" .. index]
    if stealth then
        for _, key in ipairs(stealthHide) do
            local obj = stealth[key]
            if obj and not obj._mvpfHidden then
                obj:Hide()
                hooksecurefunc(obj, "Show", obj.Hide)
                obj._mvpfHidden = true
            end
        end
    end
end

-- END Arena Prep Check
-- ===========================
-- Create one arena unit frame
-- ===========================

local function CreateArenaFrame(index)
    local unit = "arena" .. index
    local name = baseName .. index
    local var = {
        attached = false,
        EnableArenaDR = false,
        stealthAlpha = 0.5,
        normalAlpha = 0.7,
    }

    local f, health = MVPF_Common.CreateUnitFrame({
        name     = name,
        unit     = unit,
        point    = { "CENTER", UIParent, "CENTER", 280 + (index - 1) * 55, 0 },
        size     = { 50, 210 },
        maxAuras = 3,
        iconSize = 26,
        kind     = "arena",
    })

    RegisterUnitWatch(f)

    local auraAnchor = CreateFrame("Frame", nil, f)
    auraAnchor:SetSize(28, 100)
    auraAnchor:SetPoint("BOTTOM", f, "TOP", 0, -190)
    f.auraAnchor = auraAnchor

    local trinketAnchor = CreateFrame("Frame", nil, f)
    trinketAnchor:SetSize(36, 36)
    trinketAnchor:SetPoint("TOP", f, "BOTTOM", 0, -8)
    f.trinketAnchor = trinketAnchor

    -- Arena Prep Colors

    local function ApplyPrepClassColor()
        local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(index)
        if specID and specID > 0 then
            local _, _, _, _, _, class = GetSpecializationInfoByID(specID)
            if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
                local c = RAID_CLASS_COLORS[class]
                health:SetStatusBarColor(c.r, c.g, c.b, var.stealthAlpha)
                return
            end
        end
        health:SetStatusBarColor(0.4, 0.4, 0.4, 0.5)
    end

    -- TARGET HIGHLIGHT BORDER

    local outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    outerBorder:SetAllPoints(f)
    outerBorder:SetBackdrop({
        edgeFile = SOLID_TEXTURE,
        edgeSize = 5,
    })
    outerBorder:SetBackdropBorderColor(0, 0, 0, 0)
    f.outerBorder = outerBorder

    local function UpdatePartyTargets()
        if MVPF_ArenaTestMode then return end
        if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then return end
        if not UnitExists(unit) then
            outerBorder:SetBackdropBorderColor(0, 0, 0, 0)
            return
        end

        local count = 0
        if UnitExists("party1") and UnitExists("party1target") and UnitIsUnit("party1target", unit) then
            count = count + 1
        end
        if UnitExists("party2") and UnitExists("party2target") and UnitIsUnit("party2target", unit) then
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
        if MVPF_ArenaTestMode then return end
        if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then return end
        MVPF_Common.UpdateHealthBar(health, unit)
    end

    local function ApplyClassColor(alpha)
        local r, g, b = MVPF_Common.GetClassColor(unit, 0, 0.8, 0)
        health:SetStatusBarColor(r, g, b, alpha or var.normalAlpha)
    end

    local function UpdateVisibility()
        local _, instanceType = IsInInstance()
        if instanceType ~= "arena" then
            f:Hide()
            MVPF_ArenaPrepMode[index] = false
            return
        end
        if InCombatLockdown() then return end

        if MVPF_ArenaPrepMode[index] then
            UnregisterUnitWatch(f)
            f:Show()
            return
        else
            RegisterUnitWatch(f)
        end
    end

    local function UpdateTargetHighlight()
        MVPF_Common.UpdateTargetHighlight(f, unit, "MVPF_ArenaTestMode")
    end

    -- Blizzard widgets attach

    local function ZoomIcon(tex)
        if tex then
            tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end
    end

    -- Generic border helpers (idempotent, no method overrides)

    local function EnsureBorder(owner)
        if not owner or owner.Border then return end

        -- Parent must be a Frame, not a Texture
        local parent = owner:GetParent()
        if not parent or not parent.CreateTexture then return end

        local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        b:SetPoint("TOPLEFT", owner, "TOPLEFT", -1, 1)
        b:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 1, -1)

        b:SetBackdrop({
            edgeFile = SOLID_TEXTURE,
            edgeSize = 2,
        })
        b:SetBackdropBorderColor(0, 0, 0, 1)
        b:Hide()

        owner.Border = b
    end

    local function UpdateBorder(owner, shown)
        if owner and owner.Border then
            owner.Border:SetShown(shown and true or false)
        end
    end

    local function AttachMidnightAuras()
        local caf = _G["CompactArenaFrameMember" .. index]
        if not caf then return end

        local f1 = caf.DebuffFrame
        local f2 = caf.Debuff1
        local f3 = caf.Debuff2
        local f4 = caf.Debuff3
        local spacing = 5

        if f1 then
            f1:ClearAllPoints()
            f1:SetPoint("BOTTOM", f.auraAnchor, "BOTTOM", 0, 0)
            ZoomIcon(f1.Icon)
            EnsureBorder(f1)
            UpdateBorder(f1, f1:IsShown())
        end

        local prev = f1
        for _, frm in ipairs({ f2, f3, f4 }) do
            if frm and prev then
                frm:ClearAllPoints()
                frm:SetPoint("BOTTOM", prev, "TOP", 0, spacing)
                ZoomIcon(frm.Icon)
                EnsureBorder(frm)
                UpdateBorder(frm, frm:IsShown())
                prev = frm
            end
        end
    end

    local function AttachMidnightDR(caf)
        if not var.EnableArenaDR then return end
        local drTray = caf and caf.DebuffFrame
        if not drTray then return end

        drTray:EnableMouse(false)
        drTray:ClearAllPoints()
        drTray:SetPoint("CENTER", f.auraAnchor, "CENTER", 0, 0)
        drTray:SetFrameLevel(f:GetFrameLevel() + 5)

        for i = 1, drTray:GetNumChildren() do
            local btn = select(i, drTray:GetChildren())
            if btn and btn.Icon then
                ZoomIcon(btn.Icon)
            end
        end

        EnsureBorder(drTray)
        UpdateBorder(drTray, drTray:IsShown())
    end

    local function AttachMidnightTrinket()
        if InCombatLockdown() then return end -- if CcRemoverFrame is secure
        local caf = _G["CompactArenaFrameMember" .. index]
        if not caf or not caf.CcRemoverFrame then return end

        local trinket = caf.CcRemoverFrame
        trinket:ClearAllPoints()
        trinket:SetPoint("CENTER", f.trinketAnchor, "CENTER", 0, 0)
        trinket:SetScale(1.3)
        trinket:SetSize(38, 38)

        local tex = trinket.Icon or trinket.Texture
        ZoomIcon(tex)
        EnsureBorder(trinket)
        UpdateBorder(trinket, trinket:IsShown())
    end


    local function AttachPrepSpecPortrait(frame)
        local prematch = frame and frame.PreMatchFramesContainer
        if not prematch then return end

        local pf = prematch["PreMatchFrame" .. index]
        if not pf or not pf.SpecPortraitTexture then return end

        local tex = pf.SpecPortraitTexture
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", f, "CENTER", 0, 0)
        tex:SetSize(30, 30)
        ZoomIcon(tex)

        EnsureBorder(tex)
        UpdateBorder(tex, tex:IsShown())
    end

    local function AttachStealthIcon(frame)
        local sFrame = frame and frame["StealthedUnitFrame" .. index]
        if not sFrame or not sFrame.StealthIcon then return end

        local icon = sFrame.StealthIcon
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", f, "CENTER", 0, 8)
        icon:SetSize(30, 30)
        ZoomIcon(icon)

        EnsureBorder(icon)
        UpdateBorder(icon, icon:IsShown())
    end

    local function ResetAttach()
        var.attached = false
        f.outerBorder:SetBackdropBorderColor(0, 0, 0, 0)
    end

    local function AttachEverything()
        if var.attached then return end
        var.attached = true

        local frame = _G["CompactArenaFrame"]
        local caf = _G["CompactArenaFrameMember" .. index]

        if not frame or not caf then
            print("Nothing to attach.")
            return
        end

        HideBlizzArenaStuff(index)

        AttachStealthIcon(frame)
        AttachPrepSpecPortrait(frame)
        AttachMidnightDR(caf)
    end

    f.ResetAttach = ResetAttach
    f.AttachEverything = AttachEverything
    f.AttachMidnightAuras = AttachMidnightAuras

    hooksecurefunc("CompactArenaFrame_Generate", function()
        for i = 1, 3 do
            local myFrame = _G[baseName .. i]
            if myFrame then
                myFrame:ResetAttach()
                myFrame:AttachEverything(i)
            end
        end
    end)
    hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
        local name = frame and frame:GetName()
        local index = name and name:match("^CompactArenaFrameMember(%d+)$")
        if not index then return end
        index = tonumber(index)
        local myFrame = _G[baseName .. index]
        if myFrame and myFrame.AttachEverything then
            myFrame:AttachMidnightAuras(frame)
        end
    end)
    -- hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
    --     -- Only react for arena members
    --     local name = frame and frame:GetName()
    --     local index = name and name:match("^CompactArenaFrameMember(%d+)$")
    --     if not index then return end

    --     index = tonumber(index)
    --     local myFrame = _G[baseName .. index]
    --     if myFrame and myFrame.AttachEverything then
    --         myFrame:AttachEverything(index)
    --     end
    -- end)


    function f:UpdateHealth() UpdateHealth() end

    function f:UpdateVisibility() UpdateVisibility() end

    -- Event wiring

    local ef = CreateFrame("Frame", name .. "Events", f)
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    ef:RegisterEvent("ARENA_OPPONENT_UPDATE")
    ef:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    ef:RegisterEvent("UNIT_HEALTH")
    ef:RegisterEvent("UNIT_MAXHEALTH")
    ef:RegisterEvent("UNIT_AURA")
    ef:RegisterEvent("UNIT_NAME_UPDATE")
    ef:RegisterEvent("PLAYER_TARGET_CHANGED")
    ef:RegisterEvent("UNIT_TARGET")

    ef:SetScript("OnEvent", function(_, event, arg1, arg2)
        if MVPF_ArenaTestMode then return end

        local _, instanceType = IsInInstance()
        if instanceType ~= "arena" then
            ResetAttach()
            f:Hide()
            return
        end

        if event == "PLAYER_ENTERING_WORLD"
            or event == "ZONE_CHANGED_NEW_AREA" then
            MVPF_ArenaPrepMode[index] = false
            ResetAttach()
            AttachEverything()
            UpdateVisibility()
            ApplyClassColor()
            UpdateHealth()
            UpdateTargetHighlight()
            return
        end

        if event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
            MVPF_ArenaPrepMode[index] = ArenaSlotHasOpponent(index)
            AttachEverything()
            UpdateVisibility()
            ApplyPrepClassColor()
            return
        end

        if event == "ARENA_OPPONENT_UPDATE" then
            local unitID, reason = arg1, arg2
            if unitID ~= unit then return end
            MVPF_ArenaPrepMode[index] = false
            if reason == "cleared" then
                ResetAttach()
            elseif reason == "unseen" then
                ApplyClassColor(var.stealthAlpha)
                outerBorder:SetBackdropBorderColor(0, 0, 0, 0)
            else
                ApplyClassColor()
            end
            AttachEverything()
            AttachMidnightTrinket()
            UpdateVisibility()
            UpdateHealth()
            return
        end

        if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
            if arg1 == unit then
                UpdateHealth()
            end
            return
        end

        if event == "UNIT_TARGET" and (arg1 == "party1" or arg1 == "party2") then
            UpdatePartyTargets()
            return
        end

        if event == "UNIT_AURA" then
            AttachMidnightAuras()
            return
        end

        if event == "PLAYER_TARGET_CHANGED"
            or (event == "UNIT_TARGET" and arg1 == "player") then
            UpdateTargetHighlight()
            return
        end
    end)
end

-- Create frames for arena1–arena3

for i = 1, 3 do
    CreateArenaFrame(i)
end
