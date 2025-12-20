local MVPF_Common = {}

-- Creates a basic vertical unit frame with background, border, health, and auraContainer.
-- params:
--   name       = global frame name
--   unit       = unit id ("player", "target", "party1", "arena1")
--   point      = {anchor, relFrame, relPoint, x, y}
--   size       = {w, h}
--   maxAuras   = number of aura buttons
--   iconSize   = aura icon size
function MVPF_Common.CreateUnitFrame(params)
    local name     = params.name
    local unit     = params.unit
    local point    = params.point
    local size     = params.size or { 50, 220 }
    local maxAuras = params.maxAuras or 4
    local iconSize = params.iconSize or 26
    local kind     = params.kind or "none"

    local f        = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
    f:SetSize(size[1], size[2])
    f:SetPoint(point[1], point[2] or UIParent, point[3], point[4], point[5])
    f:SetAttribute("unit", unit)
    f:SetAttribute("*type1", "target")
    f:RegisterForClicks("AnyUp")

    -- Background
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.bg:SetColorTexture(0, 0, 0, 0.6)

    -- Border
    f.border = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.border:SetAllPoints(f)
    f.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    f.border:SetBackdropBorderColor(0, 0, 0, 1)

    -- Health bar
    local health = CreateFrame("StatusBar", name .. "Health", f)
    health:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 4)
    health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    health:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    health:SetOrientation("VERTICAL")
    health:SetRotatesTexture(true)
    health:SetFrameStrata("MEDIUM")
    health:SetFrameLevel(f:GetFrameLevel() + 1)
    f.health = health
    if kind == "arena" then
        return f, health
    end
    -- Aura container
    local auraContainer = CreateFrame("Frame", name .. "Auras", f)
    auraContainer.maxAuras = maxAuras
    auraContainer.iconSize = iconSize

    local totalHeight = iconSize * maxAuras + 2 * (maxAuras - 1)
    auraContainer:SetSize(28, totalHeight)
    auraContainer:SetPoint("BOTTOM", f, "TOP", 0, -190)
    auraContainer.icons = {}

    MVPF_Common.LayoutAuraButtons(auraContainer)

    return f, auraContainer, health
end

function MVPF_Common.CreateAuraButton(parent, index)
    local btn = CreateFrame("Button", parent:GetName() .. "Aura" .. index, parent)
    btn:SetSize(parent.iconSize, parent.iconSize)

    -- Border behind the icon
    btn.border = btn:CreateTexture(nil, "BACKGROUND")
    btn.border:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.border:SetVertexColor(0, 0, 0, 1)
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)

    -- Icon above border
    btn.icon = btn:CreateTexture(nil, "BORDER")
    btn.icon:SetAllPoints(btn)
    btn.icon:SetAlpha(0.8)
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Count text
    btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)

    -- Cooldown
    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints(btn)
    btn.cooldown:Hide()

    return btn
end

function MVPF_Common.LayoutAuraButtons(container)
    for i = 1, container.maxAuras do
        local btn = container.icons[i] or MVPF_Common.CreateAuraButton(container, i)
        container.icons[i] = btn
        btn:ClearAllPoints()
        if i == 1 then
            btn:SetPoint("BOTTOM", container, "BOTTOM", 0, 0)
        else
            local prev = container.icons[i - 1]
            btn:SetPoint("BOTTOM", prev, "TOP", 0, 4)
        end
    end
end

function MVPF_Common.UpdateAuras(container, unit, filters, maxRemaining)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        for i = 1, container.maxAuras do
            local btn = container.icons[i]
            if btn then
                btn:Hide()
                if btn.cooldown then btn.cooldown:Hide() end
            end
        end
        return
    end

    local shown = 0
    local now = GetTime()
    maxRemaining = maxRemaining or 20

    local function AddAuras(filter)
        local index = 1
        while shown < container.maxAuras do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
            if not aura then break end

            if aura.icon and aura.duration and aura.duration > 0
                and aura.expirationTime and aura.expirationTime > 0 then
                local remaining = aura.expirationTime - now
                if remaining > 0 and remaining <= maxRemaining then
                    shown = shown + 1
                    local btn = container.icons[shown]

                    btn.icon:SetTexture(aura.icon)
                    local count = aura.applications or aura.charges or 0
                    btn.count:SetText(count > 1 and count or "")

                    local start = aura.expirationTime - aura.duration
                    btn.cooldown:SetCooldown(start, aura.duration)
                    btn.cooldown:Show()
                    btn:Show()
                end
            end

            index = index + 1
        end
    end

    for _, filter in ipairs(filters) do
        AddAuras(filter)
    end

    for i = shown + 1, container.maxAuras do
        local btn = container.icons[i]
        if btn then
            btn:Hide()
            if btn.cooldown then btn.cooldown:Hide() end
        end
    end
end

-- Set Raid Color
function MVPF_Common.GetClassColor(unit, fr, fg, fb)
    local _, class = UnitClass(unit)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then
        return c.r, c.g, c.b
    end
    return fr or 0, fg or 0.8, fb or 0
end

-- Highlight
function MVPF_Common.UpdateTargetHighlight(frame, unit, testFlag)
    if testFlag and _G[testFlag] then return end
    if UnitIsUnit("target", unit) then
        frame.border:SetBackdropBorderColor(1, 1, 1, 1)
    else
        frame.border:SetBackdropBorderColor(0, 0, 0, 1)
    end
end

-- Update Health
function MVPF_Common.UpdateHealthBar(healthBar, unit)
    local maxHealth = UnitHealthMax(unit) or 1
    local curHealth = UnitHealth(unit) or 1
    healthBar:SetMinMaxValues(0, maxHealth)
    healthBar:SetValue(curHealth)
end

-- testing
-- type: "player", "target", "party", "arena"
function MVPF_Common.ToggleTestMode(kind, on)
    if kind == "target" then
        MVPF_TargetTestMode = on
        local f             = _G["MVPF_TargetFrame"]
        if not f then return end

        if on then
            if f.UpdateVisibility then f:UpdateVisibility() end
        else
            if f.UpdateVisibility then f:UpdateVisibility() end
            if f.UpdateHealth then f:UpdateHealth() end
            if f.UpdateAuras then f:UpdateAuras() end
            if f.SetClassColor then f:SetClassColor() end
        end
    elseif kind == "party" then
        MVPF_PartyTestMode = on
        for i = 1, 4 do
            local f = _G["MVPF_PartyFrame" .. i]
            if f then
                if on then
                    if f.UpdateVisibility then f:UpdateVisibility() end
                else
                    if f.UpdateVisibility then f:UpdateVisibility() end
                    if f.UpdateHealth then f:UpdateHealth() end
                    if f.UpdateAuras then f:UpdateAuras() end
                    if f.UpdateArenaTargets then f:UpdateArenaTargets() end
                    if f.UpdateTargetHighlight then f:UpdateTargetHighlight() end
                    if f.SetClassColor then f:SetClassColor() end
                end
            end
        end
    elseif kind == "arena" then
        MVPF_ArenaTestMode = on
        for i = 1, 3 do
            local f = _G["MVPF_ArenaFrame" .. i]
            if f then
                if on then
                    if f.UpdateVisibility then f:UpdateVisibility() end
                else
                    if f.UpdateVisibility then f:UpdateVisibility() end
                end
            end
        end
    end
end

_G.MVPF_Common = MVPF_Common
