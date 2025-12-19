local baseName = "MVPF_ArenaFrame"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MVPF_ArenaTestMode = false

local altAlpha = 0.5
local regAlpha = 0.7
local IsDREnabled = false
local c1, c2, c3, c4 = 0.1, 0.9, 0.1, 0.9
local stealthIcon = 132320

local arenaHide = {
    "RoleIcon",
    "Name",
    "Background",
    "HealthBar",
    "TempMaxHealthLoss",
    "CastingBarFrame",
    "PowerBar",
}

local baseFrame = "CompactArenaFrame"
local stealthFrame = "StealthedUnitFrame"

local function HideFrame(frame)
    if frame:IsShown() then
        frame:Hide()
        return
    end
end

local function GetOpponentSpecAndClass(index)
    local specID, gender = GetArenaOpponentSpec(index);
    if specID and specID > 0 then
        local _, _, _, specIcon, _, class = GetSpecializationInfoByID(specID);
        return specIcon, class
    end
end

local function GetClassColors(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then
        return c.r, c.g, c.b
    end
end

local function GetArenaSize()
    -- Use opponent specs first since we know those before the match has started
    local numOpponentSpecs = GetNumArenaOpponentSpecs();
    if numOpponentSpecs and numOpponentSpecs > 0 then
        return numOpponentSpecs;
    end

    -- If we don't know opponent specs, we're probably in an arena which doesn't have a set size
    -- In this case base it on whoever happens to be in the arena
    -- Note we won't know this until the match actually starts
    local numOpponents = GetNumArenaOpponents();
    if numOpponents and numOpponents > 0 then
        return numOpponents;
    end

    return 0;
end

local function SetIconZoom(owner)
    local x1, x2, x3, x4 = owner.GetTexCoord()
    if x1 ~= c1 or x2 ~= c2 or x3 ~= c3 or x4 ~= c4 then
        owner.SetTexCoord(c1, c2, c3, c4)
    end
end

local function UpdateBorder(owner)
    if not owner then return end
    if not owner.Border then
        local parent = owner:GetParent()
        if not parent or not parent.CreateTexture then return end
        local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        b:SetPoint("TOPLEFT", owner, "TOPLEFT", -1, 1)
        b:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 1, -1)

        b:SetBackdrop({
            edgeFile = SOLID_TEXTURE,
            edgeSize = 2
        })
        b:SetBackdropBorderColor(0, 0, 0, 1)
        owner.Border = b
    end
    if owner.GetTexCoord then
        SetIconZoom(owner)
    elseif owner.Icon then
        SetIconZoom(owner.Icon)
    end
end

local function IsMatchEngaged()
    return C_PvP.GetActiveMatchState() == Enum.PvPMatchState.Engaged;
end

local function IsInArena()
    return C_PvP.IsMatchConsideredArena() and (C_PvP.IsMatchActive() or C_PvP.IsMatchComplete());
end

local function IsInPrep()
    return IsInArena() and not IsMatchEngaged() and not C_PvP.IsMatchComplete() and not MVPF_ArenaTestMode
end

local function GetUnitToken(unitIndex)
    return "arena" .. unitIndex;
end

-- check if stealthedarena has a unit
local function HasValidUnitFrame(frame)
    return frame.unitFrame and frame.unitFrame.unitToken and frame.unitFrame.unitIndex;
end -- not HasValidFrame or frame.unitFrame:IsShown()

local function SetArenaFrame(index)
    local unit = "arena" .. index
    local name = baseName .. index
    local memberName = "Member" .. index
    local f, health = MVPF_Common.CreateUnitFrame({
        name = name,
        unit = unit,
        point = { "CENTER", UIParent, "CENTER", 280 + (index - 1) * 55, 0 },
        size = { 50, 210 },
        kind = "arena",
    })

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

    local function IsInStealth()
        local specID = GetArenaOpponentSpec(index)
        if not UnitExists(index) and specID and specID > 0 then
            return true
        end
        return false
    end

    local function UpdateHealth()
        if MVPF_ArenaTestMode then return end
        if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then return end
        MVPF_Common.UpdateHealthBar(health, unit)
    end

    local function SetClassColor(alpha)
        local _, c = GetOpponentSpecAndClass(index)
        if c then
            local r, g, b = GetClassColors(c)
            health:SetStatusBarColor(r, g, b, alpha or regAlpha)
            return true
        end
        return false
    end

    local function UpdateTargetHighlight()
        MVPF_Common.UpdateTargetHighlight(f, unit, "MVPF_ArenaTestMode")
    end

    local function SetStatusIcon()
        if not f.statusIconAnchor.Icon then
            f.statusIconAnchor.Icon = f:CreateTexture(baseName .. "SpecIcon", "ARTWORK")
        end
        if f.statusIconAnchor.Icon then
            if IsInPrep() then
                local s = GetOpponentSpecAndClass(index)
                if s then
                    f.statusIconAnchor.Icon:SetTexture(s)
                end
            else
                f.statusIconAnchor.Icon:SetTexture(stealthIcon)
            end

            UpdateBorder(f.statusIconAnchor)
        end
    end

    local function UpdateVisibility()
        if not IsInArena then
            f:Hide()
            return
        end
        local x = false
        if IsInPrep() then
            SetStatusIcon()
            f.specIconAnchor:Show()
            x = SetClassColor(altAlpha)
        elseif IsInStealth() then
            SetStatusIcon()
            f.specIconAnchor:Show()
        else
            f.specIconAnchor:Hide()
            x = SetClassColor(regAlpha)
        end
        if f:IsShown() ~= x then
            f:SetShown(x)
        end
    end
    --function f:UpdateVisibility() UpdateVisibility() end

    local function UpdateAndFade()
        for i = 1, GetArenaSize() do
            local b = _G[baseName .. i]
            if b then
                b:UpdateVisibility()
                local d = _G[baseFrame .. b.memberName]
                if d then
                    for _, v in ipairs(arenaHide) do
                        local obj = d[v]
                        if obj then
                            if obj.GetAlpha and not obj.GetAlpha() then
                                obj:SetAlpha(0)
                            end
                        end
                    end
                end
            end
        end
    end

    local function UpdateAndHide(frame, index)
        if index then
            local b = _G[baseName .. index]
            if b then
                b.UpdateVisibility()
            end
        else
            for i = 1, GetArenaSize() do
                local b = _G[baseName .. i]
                if b then
                    b:UpdateVisibility()
                end
            end
        end
        HideFrame(frame)
    end

    local function SetIconFrame(childKey, anchorKey)
        for i = 1, GetArenaSize() do
            local b = _G[baseName .. i]
            if b then
                local d = _G[baseFrame .. b.memberName]
                d = d and d[childKey]
                if d then
                    local _, r = d:GetPoint()
                    if r ~= d then
                        d:ClearAllPoints()
                        if d:GetWidth() ~= 36 then
                            d:SetSize(36, 36)
                        end
                        d:SetPoint("CENTER", b[anchorKey], "CENTER", 0, 0)
                        UpdateBorder(d)
                    end
                end
            end
        end
    end

    local function SetAnchor(type, point, relative, x, y, sizeX, sizeY)
        local a = CreateFrame("Frame", baseName .. type, f)
        a:SetSize(sizeX or 1, sizeY or 1)
        a:SetPoint(point, f, relative, x, y)
        return a
    end
    f.trinketAnchor = SetAnchor("Trinket", "TOP", "BOTTOM", 0, -10)
    f.debuffAnchor = SetAnchor("Debuff", "BOTTOM", "BOTTOM", 0, 10)
    f.statusIconAnchor = SetAnchor("SpecIcon", "CENTER", "CENTER", 0, 0, 36, 36)

    -- Prep
    hooksecurefunc(PreMatchArenaUnitFrameMixin, "Update", function(self, i)
        UpdateAndHide(self, i)
    end)

    -- Prep
    hooksecurefunc(ArenaPreMatchFramesContainerMixin, "UpdateShownState", function(self)
        UpdateAndHide(self)
    end)

    -- Trinket
    hooksecurefunc(ArenaUnitFrameCcRemoverMixin, "UpdateShownState", function(self)
        SetIconFrame("CcRemoverFrame", "trinketAnchor")
    end)

    -- Debuff
    hooksecurefunc(ArenaUnitFrameDebuffMixin, "UpdateShownState", function(self)
        SetIconFrame("DebuffFrame", "debuffAnchor")
    end)

    -- Stealth
    hooksecurefunc(StealthedArenaUnitFrameMixin, "UpdateShownState", function(self)
        UpdateAndHide(self)
    end)

    -- Main frames
    hooksecurefunc(CompactArenaFrameMixin, "UpdateVisibility", function(self)
        UpdateAndFade()
    end)

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("UNIT_TARGET")

    f:SetScript("OnEvent", function(self, event, arg1, arg2)
        if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
            if arg1 == unit then
                UpdateHealth()
            end
        elseif (event == "UNIT_TARGET") then
            if arg1 == "player" then
                UpdateTargetHighlight()
            elseif arg1 == "party1" or arg1 == "party2" then
                UpdatePartyTargets()
            end
        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
            if InCombatLockdown() then return end
            UpdateVisibility()
        end
    end)
end

for i = 1, 3 do
    SetArenaFrame(i)
end
