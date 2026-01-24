local MVPF_Common = {}

local CUnitAuras = C_UnitAuras

local MVPF_DISPEL_ALPHA = 0.85
local MVPF_DISPEL_NAME_TO_ID = {
  Magic   = 1,
  Curse   = 2,
  Disease = 3,
  Poison  = 4,
}

local function MVPF_ApplyAuraDispelBorderColor(btn, auraData)
  local border = btn and btn.border
  if not border then return end

  border:SetVertexColor(0, 0, 0, 1)

  if not CUnitAuras or not CUnitAuras.GetAuraDispelTypeColor then
    return
  end
  if not auraData then
    return
  end

  local dispelTypeID
  do
    local ok, id = pcall(function()
      local id2 = auraData.dispelTypeID or auraData.dispelType
      if type(id2) == "number" then
        return id2
      end
      local name = auraData.dispelName or auraData.debuffType
      if type(name) == "string" then
        local enum = Enum and Enum.DispelType
        local fromEnum = enum and enum[name]
        if type(fromEnum) == "number" then
          return fromEnum
        end
        return MVPF_DISPEL_NAME_TO_ID[name]
      end
      return nil
    end)
    if ok then
      dispelTypeID = id
    end
  end

  if type(dispelTypeID) ~= "number" then
    return
  end

  local r, g, b, a
  do
    local ok, c1, c2, c3, c4 = pcall(CUnitAuras.GetAuraDispelTypeColor, dispelTypeID)
    if ok then
      if type(c1) == "table" then
        if c1.GetRGBA then
          local ok2, rr, gg, bb, aa = pcall(c1.GetRGBA, c1)
          if ok2 then
            r, g, b, a = rr, gg, bb, aa
          end
        elseif c1.r and c1.g and c1.b then
          r, g, b, a = c1.r, c1.g, c1.b, c1.a
        end
      else
        r, g, b, a = c1, c2, c3, c4
      end
    end
  end

  if type(r) == "number" and type(g) == "number" and type(b) == "number" then
    pcall(border.SetVertexColor, border, r, g, b, type(a) == "number" and a or 1)
    border:SetAlpha(MVPF_DISPEL_ALPHA)
  end
end

local function MVPF_ApplyAuraCooldown(btn, unit, aura)
  local cd = btn and btn.cooldown
  if not cd then return end

  cd:Hide()

  if not aura then
    return
  end

  -- 1) Duration Object (preferred, Midnight-safe)
  if CUnitAuras
      and type(CUnitAuras.GetUnitAuraDuration) == "function"
      and type(cd.SetCooldownFromDurationObject) == "function"
      and aura.auraInstanceID
  then
    local ok, durationObj = pcall(CUnitAuras.GetUnitAuraDuration, unit, aura.auraInstanceID)
    if ok and durationObj then
      local ok2 = pcall(cd.SetCooldownFromDurationObject, cd, durationObj, true)
      if ok2 then
        cd:Show()
        return
      end
    end
  end

  -- 2) SetCooldownFromExpirationTime without doing math ourselves.
  if type(cd.SetCooldownFromExpirationTime) == "function"
      and aura.duration and aura.expirationTime
  then
    local ok, didSet = pcall(function()
      cd:SetCooldownFromExpirationTime(aura.expirationTime, aura.duration)
      return true
    end)
    if ok and didSet then
      cd:Show()
      return
    end
  end

  -- 3) Legacy math fallback only when both are plain numbers (non-secret).
  if type(aura.duration) == "number" and type(aura.expirationTime) == "number" then
    local ok, didSet = pcall(function()
      local start = aura.expirationTime - aura.duration
      cd:SetCooldown(start, aura.duration)
      return true
    end)
    if ok and didSet then
      cd:Show()
      return
    end
  end
end

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

function MVPF_SetAuraTexture(btn, auraData)
  if not btn or not btn.icon then
    return
  end

  -- Default/fallback icon if anything goes wrong
  local fallback = "Interface\\Icons\\INV_Misc_QuestionMark"

  -- Clear previous texture state explicitly
  btn.icon:SetTexture(nil)

  -- No aura or no icon: use fallback and bail
  if not auraData or not auraData.icon then
    btn.icon:SetTexture(fallback)
    return
  end

  local tex = auraData.icon

  -- Normalize common cases: numeric file IDs or string paths
  if type(tex) ~= "number" and type(tex) ~= "string" then
    btn.icon:SetTexture(fallback)
    return
  end

  -- Protected call so a bad ID/path cannot error the whole addon
  local ok = pcall(btn.icon.SetTexture, btn.icon, tex)
  if not ok then
    btn.icon:SetTexture(fallback)
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

  if not UnitExists(unit) then
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
  maxRemaining = maxRemaining or 20

  local function AddAuras(filter)
    -- Prefer list API when available (Midnight-style, secure)
    local auraList, totalAuras

    if C_UnitAuras and C_UnitAuras.GetUnitAuras then
      local ok, result = pcall(C_UnitAuras.GetUnitAuras, unit, filter, nil, nil)

      if ok and type(result) == "table" then
        local count = #result

        auraList = result
        totalAuras = count
      end
    end

    -- Fallback to GetAuraDataByIndex for non-Midnight / older clients
    if not auraList then
      auraList = {}
      totalAuras = 0
      local index = 1
      while shown + totalAuras < container.maxAuras do
        local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
        if not aura then break end
        auraList[#auraList + 1] = aura
        totalAuras = totalAuras + 1
        index = index + 1
      end
    end

    if not auraList or totalAuras == 0 then
      return
    end

    for listIndex = 1, totalAuras do
      if shown >= container.maxAuras then
        break
      end

      local auraData = auraList[listIndex]
      if not auraData then
        break
      end

      if auraData.icon then
        shown = shown + 1
        local btn = container.icons[shown]

        --btn.icon:SetTexture(auraData.icon)
        MVPF_SetAuraTexture(btn, auraData)

        local count = auraData.applications or auraData.charges
        local countText = ""

        -- Never compare; only show if it is a plain number
        --if type(count) == "number" then
        --    countText = tostring(count)
        --end

        btn.count:SetText(countText)

        btn.unit = unit
        btn.auraFilter = filter
        btn.auraInstanceID = auraData.auraInstanceID
        btn.auraIndex = auraData.auraIndex or auraData.index or listIndex

        MVPF_ApplyAuraCooldown(btn, unit, auraData)
        MVPF_ApplyAuraDispelBorderColor(btn, auraData)

        btn:Show()
      end
    end
  end

  for _, filter in ipairs(filters) do
    AddAuras(filter)
  end

  for i = shown + 1, container.maxAuras do
    local btn = container.icons[i]
    if btn then
      --MVPF_Debug("314: Hiding leftover slot", i, "for unit", unit)
      btn:Hide()
      if btn.cooldown then btn.cooldown:Hide() end
    end
  end
end

local function MVPF_GetNPCReactionColor(unit)
  local r, g, b = 0, 0.8, 0

  if not UnitExists(unit) then
    return r, g, b
  end

  if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
    return 0.4, 0.4, 0.4 -- dead/ghost gray (like MSUF)
  end

  if UnitReaction then
    -- reaction relative to player: 1-3 hostile, 4 neutral, 5-8 friendly
    local reaction = UnitReaction("player", unit)
    if reaction then
      if reaction >= 5 then
        -- friendly
        return 0, 0.9, 0.2
      elseif reaction == 4 then
        -- neutral
        return 1.0, 0.85, 0.1
      else
        -- hostile
        return 0.85, 0.10, 0.10
      end
    end
  end

  return r, g, b
end

-- Set Raid Color
function MVPF_Common.GetClassColor(unit, fr, fg, fb)
  local _, class = UnitClass(unit)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then
    return c.r, c.g, c.b
  end
  -- 2) For non-player units, fall back to reaction-based NPC colors
  if unit and UnitExists(unit) and not UnitIsPlayer(unit) then
    local nr, ng, nb = MVPF_GetNPCReactionColor(unit)
    return nr, ng, nb
  end

  -- 3) Final fallback
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
