local MVPF_Common               = {}

local C_UnitAuras               = C_UnitAuras
local C_CurveUtil               = C_CurveUtil

Enum.DispelType                 = {
  None    = 0,
  Magic   = 1,
  Curse   = 2,
  Disease = 3,
  Poison  = 4,
  Enrage  = 9,
  Bleed   = 11,
}

MVPF_Common.RegAlpha            = 0.7
MVPF_Common.OtherAlpha          = 0.4
local errorMargin               = 0.6

local dispel                    = {}
dispel[Enum.DispelType.None]    = _G.DEBUFF_TYPE_NONE_COLOR
dispel[Enum.DispelType.Magic]   = _G.DEBUFF_TYPE_MAGIC_COLOR
dispel[Enum.DispelType.Curse]   = _G.DEBUFF_TYPE_CURSE_COLOR
dispel[Enum.DispelType.Disease] = _G.DEBUFF_TYPE_DISEASE_COLOR
dispel[Enum.DispelType.Poison]  = _G.DEBUFF_TYPE_POISON_COLOR
dispel[Enum.DispelType.Bleed]   = _G.DEBUFF_TYPE_BLEED_COLOR
dispel[Enum.DispelType.Enrage]  = CreateColor(243 / 255, 95 / 255, 245 / 255, 1)

local RangeSpells               = {}
local RangeSpellsSize           = 0
local RangeSpellsBound          = 0

function MVPF_Common.RegisterRangeSpell(id)
  if RangeSpells and RangeSpells[id] then return end
  RangeSpells[id] = true
  RangeSpellsSize = RangeSpellsSize + 1
  RangeSpellsBound = math.floor(RangeSpellsSize * errorMargin)
end

function MVPF_Common.CheckMultiSpellRange(unit)
  local count = 0
  if RangeSpellsSize == 0 then return true end
  for spell in pairs(RangeSpells) do
    local range = C_Spell.IsSpellInRange(spell, unit)
    --print("Range: ", range)
    if range == true then
      count = count + 1
    end
  end
  --print("Count: ", count, "RangeL: ", RangeSpellsBound)
  return count > RangeSpellsBound
end

function MVPF_Common.PositionLossOfControlFrame()
  local f = LossOfControlFrame
  if not f then
    print("MVPF: LossOfControlFrame not found")
    return
  end

  -- Set size: 150 width, maintain current height ratio
  local _, currentHeight = f:GetSize()
  if currentHeight and currentHeight > 0 then
    local scale = 150 / f:GetWidth()
    f:SetSize(150, currentHeight * scale)
  else
    f:SetWidth(150)
  end

  -- Clear previous anchors and center on UIParent
  f:ClearAllPoints()
  f:SetPoint("CENTER", UIParent, "CENTER", 0, currentHeight)
end

local dispelTypeCurve

local function GetDispelTypeCurve()
  if dispelTypeCurve then
    return dispelTypeCurve
  end

  if not C_CurveUtil or not C_CurveUtil.CreateColorCurve then
    return nil
  end

  local curve = C_CurveUtil.CreateColorCurve()
  curve:SetType(Enum.LuaCurveType.Step)

  for _, dispelIndex in next, Enum.DispelType do
    local color = dispel[dispelIndex]
    if color then
      curve:AddPoint(dispelIndex, color)
    end
  end

  dispelTypeCurve = curve
  return dispelTypeCurve
end

local function MVPF_ApplyAuraDispelBorderColor(btn, unit, auraData)
  local border = btn and btn.border
  if not border then return end

  border:SetVertexColor(0, 0, 0, 1)

  if not auraData then
    return
  end

  local curve = GetDispelTypeCurve()
  if not curve then
    print("MVPF_ApplyAuraDispelBorderColor: no curve object")
    return
  end
  if not C_UnitAuras or not C_UnitAuras.GetAuraDispelTypeColor then
    return
  end
  local ok, dispelTypeColor = pcall(C_UnitAuras.GetAuraDispelTypeColor, unit, auraData.auraInstanceID, curve)
  if ok then
    border:SetVertexColor(dispelTypeColor:GetRGBA())
  end
end

local function MVPF_ApplyAuraCooldown(btn, unit, auraData)
  local cd = btn and btn.cooldown
  if not cd then return end

  cd:Hide()

  if not auraData then
    return
  end

  -- 1) Duration Object (preferred, Midnight-safe)
  if C_UnitAuras and C_UnitAuras.GetAuraDuration and cd.SetCooldownFromDurationObject then
    local ok, duration = pcall(C_UnitAuras.GetAuraDuration, unit, auraData.auraInstanceID)
    if ok then
      ok = pcall(cd.SetCooldownFromDurationObject, cd, duration, true)
      if ok then
        cd:Show()
        return
      end
    end
  end

  -- 2) SetCooldownFromExpirationTime
  if type(cd.SetCooldownFromExpirationTime) == "function"
      and auraData.duration and auraData.expirationTime
  then
    local ok, didSet = pcall(function()
      cd:SetCooldownFromExpirationTime(auraData.expirationTime, auraData.duration)
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

  f.mouseoverBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.mouseoverBorder:SetAllPoints(f)
  f.mouseoverBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.mouseoverBorder:SetBackdropBorderColor(0.39, 0.72, 0.72, 1)
  f.mouseoverBorder:SetFrameLevel(f.border:GetFrameLevel() + 1)
  f.mouseoverBorder:Hide()

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
  if kind == "arena" or kind == "boss" then
    return f, health
  end

  f:SetScript("OnEnter", function(self)
    f.mouseoverBorder:Show()
  end)

  f:SetScript("OnLeave", function(self)
    f.mouseoverBorder:Hide()
  end)
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
  --btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  --btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)

  -- Cooldown
  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(btn)
  btn.cooldown:Hide()

  -- Tooltip handlers
  btn:SetScript("OnEnter", function(self)
    if not self.unit or not self.auraInstanceID or GameTooltip:IsForbidden() then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetUnitAuraByAuraInstanceID(self.unit, self.auraInstanceID)
  end)

  btn:SetScript("OnLeave", function()
    if GameTooltip:IsForbidden() then return end
    GameTooltip:Hide()
  end)

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
    print("MVPF_SetAuraTexture: invalid button")
    return false
  end
  btn.icon:SetTexture(nil)

  if not auraData or not auraData.icon then
    print("MVPF_SetAuraTexture: no aura data or icon")
    return false
  end

  local tex = auraData.icon

  if type(tex) ~= "number" and type(tex) ~= "string" then
    print("MVPF_SetAuraTexture: invalid icon type: " .. tostring(tex))
    return false
  end
  btn.icon:SetTexture(tex)
  return true
end

function MVPF_Common.UpdateAuras(container, unit, filters, maxRemaining)
  if not C_UnitAuras
      or not C_UnitAuras.GetAuraDataByIndex
      or not UnitExists(unit) then
    for i = 1, container.maxAuras do
      local btn = container.icons[i]
      if btn then
        btn:Hide()
        if btn.cooldown then btn.cooldown:Hide() end
      end
    end
    return
  end

  local shown = 1
  maxRemaining = maxRemaining or 8
  local seen = {}

  local function AddAuras(filter)
    local auraList, totalAuras

    if C_UnitAuras and C_UnitAuras.GetUnitAuras then
      local ok, result = pcall(C_UnitAuras.GetUnitAuras, unit, filter, maxRemaining, Enum.UnitAuraSortRule.BigDefensive,
        Enum.UnitAuraSortDirection.Reverse)

      if ok and type(result) == "table" then
        local count = #result

        auraList = result
        totalAuras = count
      end
    end

    if not auraList or totalAuras == 0 then
      return
    end

    for listIndex = 1, totalAuras do
      if shown > container.maxAuras then
        break
      end

      local auraData = auraList[listIndex]
      if not auraData then
        break
      end

      if seen[auraData.auraInstanceID] then
        break
      else
        seen[auraData.auraInstanceID] = true
      end

      if auraData.icon then
        local btn = container.icons[shown]

        if not MVPF_SetAuraTexture(btn, auraData) then
          break
        end

        --local count = auraData.applications or auraData.charges
        --local countText = ""

        --btn.count:SetText(countText)

        btn.unit = unit
        btn.auraFilter = filter
        btn.auraInstanceID = auraData.auraInstanceID
        btn.auraIndex = auraData.auraIndex or auraData.index or listIndex

        MVPF_ApplyAuraCooldown(btn, unit, auraData)
        MVPF_ApplyAuraDispelBorderColor(btn, unit, auraData)
        shown = shown + 1
        btn:Show()
      end
    end
  end

  for _, filter in ipairs(filters) do
    AddAuras(filter)
  end

  for i = shown, container.maxAuras do
    local btn = container.icons[i]
    if btn then
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
    return 0.4, 0.4, 0.4
  end

  if UnitReaction then
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
    return c.r, c.g, c.b, true
  end

  if unit and UnitExists(unit) and not UnitIsPlayer(unit) then
    local nr, ng, nb = MVPF_GetNPCReactionColor(unit)
    return nr, ng, nb, true
  end

  return fr or 0, fg or 0.8, fb or 0, false
end

-- Highlight
function MVPF_Common.UpdateTargetHighlight(frame, unit, testFlag, optionalFrame)
  if testFlag and _G[testFlag] then return end
  if UnitIsUnit("target", unit) then
    frame.border:SetBackdropBorderColor(1, 1, 1, 1)
  elseif optionalFrame and UnitIsUnit("target", optionalFrame.unit) then
    optionalFrame.border:SetBackdropBorderColor(1, 1, 1, 1)
  else
    frame.border:SetBackdropBorderColor(0, 0, 0, 1)
    if optionalFrame then
      optionalFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
    end
  end
end

local function IsDeadOrGhost(unit)
  return UnitExists(unit) and UnitIsDeadOrGhost(unit) and not MVPF_ArenaTestMode
end
local function IsLegalUnit(unit)
  return UnitIsConnected(unit) and UnitExists(unit) and not MVPF_ArenaTestMode
end

-- Update Health
function MVPF_Common.UpdateHealthBar(healthBar, unit)
  local maxHealth = UnitHealthMax(unit) or 1
  if IsDeadOrGhost(unit) then
    healthBar:SetMinMaxValues(0, maxHealth)
    healthBar:SetValue(0)
    return
  elseif not IsLegalUnit(unit) then
    healthBar:SetMinMaxValues(0, 1)
    healthBar:SetValue(1)
    return
  end
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
