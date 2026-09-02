local _, MF = ...

-- Highlight border colors, each reused for its border and its glow.
local ALLY_TARGET_R, ALLY_TARGET_G, ALLY_TARGET_B = 0.2, 0.8, 0.2
local MOUSEOVER_R, MOUSEOVER_G, MOUSEOVER_B = 0.694, 0.372, 0.98

-- A larger, softer copy of the border behind it, for a glow/bloom look.
local function AddGlow(borderFrame, r, g, b, bleed, edgeSize, alpha)
  local glow = CreateFrame("Frame", nil, borderFrame, "BackdropTemplate")
  glow:SetPoint("TOPLEFT", -bleed, bleed)
  glow:SetPoint("BOTTOMRIGHT", bleed, -bleed)
  glow:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = edgeSize,
  })
  glow:SetBackdropBorderColor(r, g, b, alpha)
  -- must run after borderFrame's own SetFrameLevel, or this reads the wrong level
  glow:SetFrameLevel(borderFrame:GetFrameLevel() + 1)
  return glow
end

local function CreateAuraButton(parent, index)
  local btn = CreateFrame("Button", parent:GetName() .. "Aura" .. index, parent)
  btn:SetSize(parent.iconSize, parent.iconSize)

  btn.border = btn:CreateTexture(nil, "BACKGROUND")
  btn.border:SetTexture("Interface\\Buttons\\WHITE8x8")
  btn.border:SetVertexColor(0, 0, 0, 1)
  btn.border:SetPoint("TOPLEFT", -1, 1)
  btn.border:SetPoint("BOTTOMRIGHT", 1, -1)

  btn.icon = btn:CreateTexture(nil, "BORDER")
  btn.icon:SetAllPoints(btn)
  btn.icon:SetAlpha(0.8)
  btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(btn)
  btn.cooldown:Hide()

  btn:Hide()
  return btn
end

local function LayoutAuraButtons(container, horizontal)
  for i = 1, container.maxAuras do
    local btn = container.icons[i] or CreateAuraButton(container, i)
    container.icons[i] = btn
    btn:ClearAllPoints()
    if horizontal then
      if i == 1 then
        btn:SetPoint("LEFT", container, "LEFT", 0, 0)
      else
        local prev = container.icons[i - 1]
        btn:SetPoint("LEFT", prev, "RIGHT", 4, 0)
      end
    else
      if i == 1 then
        btn:SetPoint("BOTTOM", container, "BOTTOM", 0, 0)
      else
        local prev = container.icons[i - 1]
        btn:SetPoint("BOTTOM", prev, "TOP", 0, 4)
      end
    end
  end
end

local function CreateGenericButton(parent, index)
  local btn = CreateFrame("Button", parent:GetName() .. "Aura" .. index, parent)
  btn:SetSize(parent.iconSize, parent.iconSize)

  btn.border = btn:CreateTexture(nil, "BACKGROUND", nil, 0)
  btn.border:SetTexture("Interface\\Buttons\\WHITE8x8")
  btn.border:SetVertexColor(0, 0, 0, 1)
  btn.border:SetPoint("TOPLEFT", -1, 1)
  btn.border:SetPoint("BOTTOMRIGHT", 1, -1)

  btn.icon = btn:CreateTexture(nil, "BORDER")
  btn.icon:SetAllPoints(btn)
  btn.icon:SetAlpha(0.8)
  btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(btn)
  btn:Hide()
  return btn
end

local function LayoutPvPButtons(container, horizontal)
  for i = 1, container.maxSlots do
    local btn = container.icons[i] or CreateGenericButton(container, i)
    container.icons[i] = btn
    btn.container = container
    btn:ClearAllPoints()
    if horizontal then
      if i == 1 then
        btn:SetPoint("RIGHT", container, "RIGHT", 0, 0)
      else
        local prev = container.icons[i - 1]
        btn:SetPoint("RIGHT", prev, "LEFT", -4, 0)
        btn.cooldown:SetScript("OnHide", function() MF.HideButton(btn) end)
      end
    else
      if i == 1 then
        btn:SetPoint("TOP", container, "TOP", 0, 0)
      else
        local prev = container.icons[i - 1]
        btn:SetPoint("TOP", prev, "BOTTOM", 0, -4)
        btn.cooldown:SetScript("OnHide", function() MF.HideButton(btn) end)
      end
    end
  end
end

function MF.CreateUnitFrame(params)
  local name       = params.name
  local unit       = params.unit
  local unitKey    = params.unitKey
  local point      = params.point
  local size       = params.size or { 50, 220 }
  local maxAuras   = params.maxAuras or 4
  local iconSize   = params.iconSize or 32
  local pvpIcons   = params.pvpIcons or false
  local horizontal = params.horizontal or false
  local roleIcon   = params.roleIcon or false
  local otherSlots = params.otherSlots or MF.DRSize

  local f          = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
  f:SetSize(size[1], size[2])
  f:SetPoint(point[1], point[2] or UIParent, point[3], point[4], point[5])
  f:SetAttribute("unit", unit)
  f:SetAttribute("*type1", "target")
  f:RegisterForClicks("AnyUp")
  f:SetAttribute("type2", "togglemenu")

  f.unit = unit
  f.unitKey = unitKey
  f.maxAuras = maxAuras

  f.bg = f:CreateTexture(nil, "BACKGROUND")
  f.bg:SetAllPoints(f)
  f.bg:SetColorTexture(0, 0, 0, 0.6)

  local inset      = 0
  local innerInset = MF.HighlightInset

  f.border         = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.border:SetPoint("TOPLEFT", inset, -inset)
  f.border:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.border:SetBackdropBorderColor(0, 0, 0, 1)

  -- highlight order low to high: inner (ally target) < outer (my target) < mouseover
  f.innerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.innerBorder:SetPoint("TOPLEFT", innerInset, -innerInset)
  f.innerBorder:SetPoint("BOTTOMRIGHT", -innerInset, innerInset)
  f.innerBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.innerBorder:SetBackdropBorderColor(ALLY_TARGET_R, ALLY_TARGET_G, ALLY_TARGET_B, 1)
  f.innerBorder:SetFrameLevel(f.border:GetFrameLevel() + 1)
  AddGlow(f.innerBorder, ALLY_TARGET_R, ALLY_TARGET_G, ALLY_TARGET_B, 2, 6, 0.25)
  f.innerBorder:Hide()

  f.outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.outerBorder:SetPoint("TOPLEFT", inset, -inset)
  f.outerBorder:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.outerBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.outerBorder:SetBackdropBorderColor(1, 1, 1, 1)
  f.outerBorder:SetFrameLevel(f.border:GetFrameLevel() + 2)
  AddGlow(f.outerBorder, 1, 1, 1, 2, 6, 0.26)
  f.outerBorder:Hide()

  f.mouseoverBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.mouseoverBorder:SetPoint("TOPLEFT", inset, -inset)
  f.mouseoverBorder:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.mouseoverBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.mouseoverBorder:SetBackdropBorderColor(MOUSEOVER_R, MOUSEOVER_G, MOUSEOVER_B, 1)
  f.mouseoverBorder:SetFrameLevel(f.border:GetFrameLevel() + 3)
  AddGlow(f.mouseoverBorder, MOUSEOVER_R, MOUSEOVER_G, MOUSEOVER_B, 3, 8, 0.30)
  f.mouseoverBorder:Hide()

  f.health = CreateFrame("StatusBar", name .. "Health", f)
  f.health:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", MF.FillInset, MF.FillInset)
  f.health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -MF.FillInset, -MF.FillInset)
  f.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
  if not horizontal then
    f.health:SetOrientation("VERTICAL")
  end
  f.health:SetRotatesTexture(true)
  f.health:SetFrameStrata("MEDIUM")
  MF.ApplyHealthGradient(f.health, 0.25, 0.88, 0.82)
  f.health:SetAlpha(0.8)
  f.health:SetFrameLevel(f:GetFrameLevel() + 1)

  -- shimmer overlay bar, mirrors f.health's value so it never has to read the real percent
  f.healthLiquid = CreateFrame("StatusBar", name .. "HealthLiquid", f)
  f.healthLiquid:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", MF.FillInset, MF.FillInset)
  f.healthLiquid:SetPoint("TOPRIGHT", f, "TOPRIGHT", -MF.FillInset, -MF.FillInset)
  f.healthLiquid:SetStatusBarTexture("Interface\\AddOns\\MidnightFrames\\Media\\HealthLiquid.tga")
  if not horizontal then
    f.healthLiquid:SetOrientation("VERTICAL")
  end
  f.healthLiquid:SetRotatesTexture(true)
  f.healthLiquid:SetFrameStrata("MEDIUM")
  f.healthLiquid:SetFrameLevel(f.health:GetFrameLevel() + 1)
  f.healthLiquid:SetMinMaxValues(0, 1)
  f.healthLiquid:SetValue(1)
  do
    local liquidTexture = f.healthLiquid:GetStatusBarTexture()
    liquidTexture:SetTexture(
      "Interface\\AddOns\\MidnightFrames\\Media\\HealthLiquid.tga", "REPEAT", "REPEAT")
    liquidTexture:SetBlendMode("ADD")
  end
  MF.TintHealthLiquid(f.healthLiquid, 0.25, 0.88, 0.82)

  -- scrolls the texture for a flowing look; unverified whether vertical
  -- frames need the axes swapped (no live client to test rotated bars)
  f.healthLiquid.scrollOffset = 0
  f.healthLiquid.scrollElapsed = 0
  f.healthLiquid:SetScript("OnUpdate", function(self, elapsed)
    self.scrollElapsed = self.scrollElapsed + elapsed
    if self.scrollElapsed < 0.05 then return end
    self.scrollElapsed = 0
    self.scrollOffset = (self.scrollOffset + 0.010) % 1
    local tex = self:GetStatusBarTexture()
    if horizontal then
      tex:SetTexCoord(self.scrollOffset, self.scrollOffset + 1, 0, 1)
    else
      tex:SetTexCoord(0, 1, self.scrollOffset, self.scrollOffset + 1)
    end
  end)

  f.absorb = CreateFrame("StatusBar", name .. "Absorb", f)
  f.absorb:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", MF.FillInset, MF.FillInset)
  f.absorb:SetPoint("TOPRIGHT", f, "TOPRIGHT", -MF.FillInset, -MF.FillInset)
  f.absorb:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  if not horizontal then
    f.absorb:SetOrientation("VERTICAL")
  end
  f.absorb:SetRotatesTexture(true)
  f.absorb:SetFrameStrata("MEDIUM")
  f.absorb:SetStatusBarColor(0.2, 0.45, 0.85, 0.6)
  f.absorb:SetFrameLevel(f.healthLiquid:GetFrameLevel() + 1)
  f.absorb:SetMinMaxValues(0, 1)
  f.absorb:SetValue(0)

  if roleIcon then
    f.roleIcon = CreateFrame("Frame", name .. "RoleIcon", f)
    f.roleIcon:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.roleIcon:SetSize(iconSize, iconSize)
    f.roleIcon:SetFrameStrata("MEDIUM")
    f.roleIcon:SetFrameLevel(f.absorb:GetFrameLevel() + 1)
    f.roleIcon.icon = f.roleIcon:CreateTexture(nil, "ARTWORK")
    f.roleIcon.icon:SetAllPoints(f.roleIcon)
    f.roleIcon:Hide()
  end

  if horizontal then
    f.orbIcon = CreateFrame("Frame", name .. "OrbIcon", f)
    f.orbIcon:SetPoint("LEFT", f, "RIGHT", 10, 0)
    f.orbIcon:SetSize(iconSize, iconSize)
    f.orbIcon:SetFrameStrata("MEDIUM")
    f.orbIcon:SetFrameLevel(f.absorb:GetFrameLevel() + 1)
    f.orbIcon.icon = f.orbIcon:CreateTexture(nil, "ARTWORK")
    f.orbIcon.icon:SetAllPoints(f.orbIcon)
    f.orbIcon.icon:SetAtlas("UI-LFG-RoleIcon-Leader", true)
    f.orbIcon:Hide()
  end

  -- raid mark centers on the health bar's top-right corner; confirmed clear
  -- of roleIcon/orbIcon/auraContainer on every frame type
  local cornerIconSize = math.floor(iconSize / 2)

  f.raidMark = CreateFrame("Frame", name .. "RaidMark", f)
  f.raidMark:SetSize(cornerIconSize, cornerIconSize)
  f.raidMark:SetPoint("CENTER", f.health, "TOPRIGHT", 0, 0)
  f.raidMark:SetFrameStrata("MEDIUM")
  f.raidMark:SetFrameLevel(f.mouseoverBorder:GetFrameLevel() + 1)
  f.raidMark.icon = f.raidMark:CreateTexture(nil, "OVERLAY")
  f.raidMark.icon:SetAllPoints(f.raidMark)
  f.raidMark.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
  f.raidMark:Hide()

  -- cast indicator mirrors the raid mark on the top-left corner. Skipped on
  -- raid frames since their aura icons already sit there. Sized up a bit and
  -- nudged off-center so it doesn't collide with the next frame's raid mark.
  if not horizontal then
    local castIconSize = math.floor(cornerIconSize * 1.2)
    f.castIndicator = CreateFrame("Frame", name .. "CastIndicator", f)
    f.castIndicator:SetSize(castIconSize, castIconSize)
    f.castIndicator:SetPoint("CENTER", f.health, "TOPLEFT", castIconSize * 0.35, 0)
    f.castIndicator:SetFrameStrata("MEDIUM")
    f.castIndicator:SetFrameLevel(f.mouseoverBorder:GetFrameLevel() + 1)
    f.castIndicator.border = f.castIndicator:CreateTexture(nil, "BACKGROUND")
    f.castIndicator.border:SetTexture("Interface\\Buttons\\WHITE8x8")
    f.castIndicator.border:SetVertexColor(0, 1, 0, 1)
    f.castIndicator.border:SetPoint("TOPLEFT", -1, 1)
    f.castIndicator.border:SetPoint("BOTTOMRIGHT", 1, -1)
    f.castIndicator.icon = f.castIndicator:CreateTexture(nil, "ARTWORK")
    f.castIndicator.icon:SetAllPoints(f.castIndicator)
    f.castIndicator.cooldown = CreateFrame("Cooldown", nil, f.castIndicator, "CooldownFrameTemplate")
    f.castIndicator.cooldown:SetAllPoints(f.castIndicator)
    f.castIndicator.cooldown:Hide()
    f.castIndicator:Hide()
  end

  f:SetScript("OnEnter", function(self)
    self.mouseoverBorder:Show()
  end)

  f:SetScript("OnLeave", function(self)
    self.mouseoverBorder:Hide()
  end)

  f.auraContainer = CreateFrame("Frame", name .. "Auras", f)
  f.auraContainer.maxAuras = maxAuras
  f.auraContainer.iconSize = iconSize
  local totalHeight = iconSize * maxAuras + 2 * (maxAuras - 1)
  if horizontal then
    f.auraContainer:SetSize(totalHeight, 28)
    f.auraContainer:SetPoint("LEFT", f, "LEFT", 10, 0)
  else
    f.auraContainer:SetSize(28, totalHeight)
    f.auraContainer:SetPoint("BOTTOM", f, "TOP", 0, -MF.AuraOffsetY)
  end
  f.auraContainer:SetFrameLevel(f.absorb:GetFrameLevel() + 1)
  f.auraContainer.icons = {}
  LayoutAuraButtons(f.auraContainer, horizontal)

  if pvpIcons then
    f.otherContainer = CreateFrame("Frame", name .. "Buttons", f)
    f.otherContainer.iconSize = iconSize
    f.otherContainer.maxSlots = otherSlots
    totalHeight = iconSize * otherSlots + 2 * (otherSlots - 1)
    if horizontal then
      f.otherContainer:SetSize(totalHeight, 28)
      f.otherContainer:SetPoint("RIGHT", f, "LEFT", -10, 0)
    else
      f.otherContainer:SetSize(28, totalHeight)
      f.otherContainer:SetPoint("TOP", f, "BOTTOM", 0, -10)
    end


    f.otherContainer.icons = {}
    f.categories = {}

    LayoutPvPButtons(f.otherContainer, horizontal)

    return f
  end

  return f
end
