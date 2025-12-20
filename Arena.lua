local baseName = "MVPF_ArenaFrame"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MVPF_ArenaTestMode = false

local blizzFrame = "CompactArenaFrame"

local altAlpha = 0.4
local regAlpha = 0.7

local c1, c2, c3, c4 = 0.1, 0.9, 0.1, 0.9
local stealthIcon = 132320

local arenaKeepList = {
    DebuffFrame = true,
    CcRemoverFrame = true,
}

local function GetOpponentSpecAndClass(index)
    local specID = GetArenaOpponentSpec(index)
    if specID and specID > 0 then
        local _, _, _, specIcon, _, class = GetSpecializationInfoByID(specID)
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
    local numOpponentSpecs = GetNumArenaOpponentSpecs()
    if numOpponentSpecs and numOpponentSpecs > 0 then
        return numOpponentSpecs
    end

    local numOpponents = GetNumArenaOpponents()
    if numOpponents and numOpponents > 0 then
        return numOpponents
    end

    return 0
end

local function SetIconZoom(owner)
    local x1, x2, x3, x4 = owner:GetTexCoord()
    if x1 ~= c1 or x2 ~= c2 or x3 ~= c3 or x4 ~= c4 then
        owner:SetTexCoord(c1, c2, c3, c4)
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
    return C_PvP.GetActiveMatchState() == Enum.PvPMatchState.Engaged
end

local function IsInArena()
    return C_PvP.IsMatchConsideredArena() and (C_PvP.IsMatchActive() or C_PvP.IsMatchComplete())
end

local function IsInPrep()
    return IsInArena() and not IsMatchEngaged() and not C_PvP.IsMatchComplete() and not MVPF_ArenaTestMode
end

local function IsArenaInProgress()
    return IsInArena() and IsMatchEngaged()
end

local function IsInStealth(index)
    local unit   = "arena" .. index
    local specID = GetArenaOpponentSpec(index)

    -- Must be a real opponent slot
    if not specID or specID <= 0 then
        return false
    end

    -- In an active match, “no unit yet” for a real slot means stealthed
    if IsArenaInProgress() and not UnitExists(unit) then
        return true
    end

    return false
end

local function SetArenaFrame(index)
    local unit = "arena" .. index
    local name = baseName .. index
    local f, health = MVPF_Common.CreateUnitFrame({
        name = name,
        unit = unit,
        point = { "CENTER", UIParent, "CENTER", 280 + (index - 1) * 55, 0 },
        size = { 50, 210 },
        kind = "arena",
    })
    f:SetFrameLevel(10) -- base level for MVPF frame

    local function SetAnchor(type, point, relative, x, y, sizeX, sizeY)
        local a = CreateFrame("Frame", baseName .. type, f)
        a:SetSize(sizeX or 1, sizeY or 1)
        a:SetPoint(point, f, relative, x, y)
        return a
    end

    f.trinketAnchor = SetAnchor("Trinket", "TOP", "BOTTOM", 0, -30)
    f.debuffAnchor = SetAnchor("Debuff", "BOTTOM", "BOTTOM", 0, 30)
    f.statusIconAnchor = SetAnchor("StatusIcon", "CENTER", "CENTER", 0, 0, 36, 36)
    f.statusIconAnchor:SetFrameLevel(f:GetFrameLevel() + 5)

    local outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    outerBorder:SetAllPoints(f)
    outerBorder:SetBackdrop({
        edgeFile = SOLID_TEXTURE,
        edgeSize = 5,
    })
    outerBorder:SetBackdropBorderColor(0, 0, 0, 0)
    outerBorder:SetFrameLevel(f:GetFrameLevel())
    f.outerBorder = outerBorder


    local function IsLegalUnit()
        return UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitExists(unit) and not MVPF_ArenaTestMode
    end

    local function UpdatePartyTargets()
        if not IsLegalUnit() then
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
    local function IsUnit(idx)
        local specID = GetArenaOpponentSpec(idx)
        return specID and specID > 0
    end

    local function UpdateHealth()
        if not IsLegalUnit() then return end
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
            f.statusIconAnchor.Icon = f.statusIconAnchor:CreateTexture(nil, "OVERLAY")
            f.statusIconAnchor.Icon:SetAllPoints(f.statusIconAnchor)
        end

        local icon = f.statusIconAnchor.Icon
        if not icon then
            return false
        end

        local tex

        if IsInPrep() then
            tex = GetOpponentSpecAndClass(index)
        elseif IsArenaInProgress() and IsInStealth(index) then
            tex = stealthIcon
        else
            tex = nil
        end

        if tex then
            icon:SetTexture(tex)
            UpdateBorder(f.statusIconAnchor)
            if f.statusIconAnchor.Border then
                f.statusIconAnchor.Border:SetFrameLevel(f.statusIconAnchor:GetFrameLevel())
                f.statusIconAnchor.Border:Show()
            end
            return true
        else
            icon:SetTexture(nil)
            if f.statusIconAnchor.Border then
                f.statusIconAnchor.Border:Hide()
            end
            return false
        end
    end

    local function UpdateVisibility()
        if MVPF_ArenaTestMode then
            f:Show()
            return
        end
        if not IsInArena() then
            f:Hide()
            return
        end

        local hasIcon = SetStatusIcon()
        f.statusIconAnchor:SetShown(hasIcon)

        if hasIcon then
            SetClassColor(altAlpha)
        else
            SetClassColor(regAlpha)
        end

        if InCombatLockdown() then return end
        f:SetShown(IsUnit(index))
    end
    function f:UpdateVisibility() UpdateVisibility() end

    local function SetFrames()
        local frame = _G["CompactArenaFrame"]
        for i = 1, GetArenaSize() do
            local mv = _G[baseName .. i]
            if mv then
                mv:UpdateVisibility()
            end
            if IsArenaInProgress() then
                if IsInStealth(i) then
                    local stealth = frame and frame["StealthedUnitFrame" .. i]
                    if stealth and stealth:IsShown() then
                        stealth:Hide()
                    end
                end
                local member = _G[blizzFrame .. "Member" .. i]
                if member then
                    if member.CastingBarFrame then
                        local cb = member.CastingBarFrame

                        -- Stop future updates
                        cb:UnregisterAllEvents()

                        -- Make it a no-op
                        cb.Show = cb.Hide
                        cb:Hide()
                    end
                    local children = { member:GetChildren() }
                    for _, child in ipairs(children) do
                        local field
                        -- map child object back to its field name
                        for k, v in pairs(member) do
                            if v == child then
                                field = k
                                break
                            end
                        end
                        if field and not arenaKeepList[field] then
                            local obj = child
                            --print("Hiding")
                            if obj.GetAlpha and obj:GetAlpha() ~= 0 then
                                obj:SetAlpha(0)
                            end

                            -- Visibility
                            if obj.IsShown and obj:IsShown() then
                                obj:Hide()
                                hooksecurefunc(obj, "Show", obj.Hide)
                            end

                            -- Text region
                            if obj.Text then
                                obj.Text:SetAlpha(0)
                            end

                            -- Normal texture (buttons, statusbars)
                            if obj.GetNormalTexture then
                                local tex = obj:GetNormalTexture()
                                if tex then
                                    tex:SetTexture(nil)
                                    tex:SetAlpha(0)
                                end
                            end

                            -- Generic Icon field
                            if obj.Icon and obj.Icon.GetTexture then
                                obj.Icon:SetTexture(nil)
                                obj.Icon:SetAlpha(0)
                            end
                        end
                    end
                    -- Regions: textures/fontstrings parented directly to member or its
                    -- non‑kept children
                    local regions = { member:GetRegions() }
                    for _, region in ipairs(regions) do
                        if region:IsObjectType("Texture") or region:IsObjectType("FontString") then
                            local parent = region:GetParent()
                            local keep = false

                            -- If region belongs to a kept child, do not touch it
                            if parent and parent ~= member then
                                for k, v in pairs(member) do
                                    if v == parent and arenaKeepList[k] then
                                        keep = true
                                        break
                                    end
                                end
                            end

                            if not keep then
                                region:SetAlpha(0)
                                region:Hide()
                                -- Optional: strip texture
                                if region:IsObjectType("Texture") then
                                    region:SetTexture(nil)
                                end
                            end
                        end
                    end
                end
            end
            if IsInPrep() then
                local prematch = frame and frame.PreMatchFramesContainer
                if prematch then
                    --print("Hiding Pre")
                    local pf = prematch["PreMatchFrame" .. i]
                    if pf and pf:IsShown() then
                        pf:Hide()
                    end
                end
            end
        end
    end

    local function SetIconFrame(childKey, anchorKey)
        for i = 1, GetArenaSize() do
            local b = _G[baseName .. i]
            if b then
                local member = _G[blizzFrame .. "Member" .. i]
                local d = member and member[childKey]
                local anchor = b[anchorKey]
                if d and anchor then
                    d:ClearAllPoints()
                    d:SetSize(36, 36)
                    d:SetPoint("CENTER", anchor, "CENTER", 0, 0)
                    UpdateBorder(d)
                    local h = b.health or b.HealthBar
                    local baseLevel = h and h:GetFrameLevel() or b:GetFrameLevel()
                    d:SetFrameStrata("HIGH")
                    d:SetFrameLevel(baseLevel + 10)


                    local icon = d.Icon or d.Texture or (d.GetNormalTexture and d:GetNormalTexture())
                    local hasIcon = icon and icon:GetTexture()
                    if hasIcon ~= nil then
                        icon:SetDrawLayer("OVERLAY", 7)
                    end
                    anchor:SetShown(hasIcon ~= nil)
                    if d.Border then
                        d.Border:SetShown(hasIcon ~= nil)
                    end
                elseif anchor then
                    anchor:Hide()
                end
            end
        end
    end

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("UNIT_TARGET")
    f:RegisterEvent("ARENA_OPPONENT_UPDATE")
    f:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    f:RegisterEvent("PVP_MATCH_STATE_CHANGED")

    f:SetScript("OnEvent", function(self, event, arg1)
        if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
            MVPF_ArenaTestMode = false
            UpdateHealth()
            UpdateVisibility()
            UpdatePartyTargets()
            UpdateTargetHighlight()
        end
        if not IsInArena then return end
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
        elseif event == "PVP_MATCH_STATE_CHANGED"
            or event == "ARENA_OPPONENT_UPDATE"
            or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS"
        then
            SetFrames()
        end
    end)

    if not MVPF_Arena_SetFrames then
        MVPF_Arena_SetIconFrame = SetIconFrame
        MVPF_Arena_SetFrames = SetFrames
    end
end

local function MVPF_HookArenaMembers()
    for i = 1, 3 do
        local member = _G["CompactArenaFrameMember" .. i]
        local stealth = _G["CompactArenaFrame"]
        stealth = stealth["StealthedUnitFrame" .. i]

        if stealth then
            if not stealth.MVPF_Hooked then
                stealth.MVPF_Hooked = true
                hooksecurefunc(stealth, "UpdateShownState", function(self)
                    --print("MVPF: StealthedUnitFrame:UpdateShownState", i)
                    if MVPF_Arena_SetFrames then
                        MVPF_Arena_SetFrames()
                    end
                end)
            end
        end
        if member then
            if member.CcRemoverFrame and not member.CcRemoverFrame.MVPF_Hooked then
                member.CcRemoverFrame.MVPF_Hooked = true
                hooksecurefunc(member.CcRemoverFrame, "UpdateShownState", function(self)
                    --print("MVPF: CcRemoverFrame:UpdateShownState", i)
                    if MVPF_Arena_SetIconFrame then
                        MVPF_Arena_SetIconFrame("CcRemoverFrame", "trinketAnchor")
                    end
                end)
            end

            if member.DebuffFrame and not member.DebuffFrame.MVPF_Hooked then
                member.DebuffFrame.MVPF_Hooked = true
                hooksecurefunc(member.DebuffFrame, "UpdateShownState", function(self)
                    --print("MVPF: DebuffFrame:UpdateShownState", i)
                    if MVPF_Arena_SetIconFrame then
                        MVPF_Arena_SetIconFrame("DebuffFrame", "debuffAnchor")
                    end
                end)
            end

            if member and member.CastingBarFrame and not member.CastingBarFrame.MVPF_Hooked then
                local cb = member.CastingBarFrame
                cb.MVPF_Hooked = true

                hooksecurefunc(cb, "Show", cb.Hide) -- any future Show becomes Hide
            end
        end
    end
end

local function MVPF_SetupArenaHooks()
    if CompactArenaFrame and not CompactArenaFrame.MVPF_Hooked then
        CompactArenaFrame.MVPF_Hooked = true
        hooksecurefunc(CompactArenaFrame, "UpdateVisibility", function(self)
            MVPF_SetupArenaHooks()
            if MVPF_Arena_SetFrames then
                MVPF_Arena_SetFrames()
            end
        end)
    end
end



local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    MVPF_SetupArenaHooks()
    MVPF_HookArenaMembers()
end)

for i = 1, 3 do
    SetArenaFrame(i)
end
