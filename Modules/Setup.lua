local _, MV = ...

local function CreateAuraButton(parent, index)
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

  -- Cooldown
  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(btn)
  btn.cooldown:Hide()

  btn:SetScript("OnLeave", function()
    if GameTooltip:IsForbidden() then return end
    GameTooltip:Hide()
  end)
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

  -- Border behind the icon
  btn.border = btn:CreateTexture(nil, "BACKGROUND", nil, 0)
  btn.border:SetTexture("Interface\\Buttons\\WHITE8x8")
  btn.border:SetVertexColor(0, 0, 0, 1)
  btn.border:SetPoint("TOPLEFT", -1, 1)
  btn.border:SetPoint("BOTTOMRIGHT", 1, -1)

  -- Icon above border
  btn.icon = btn:CreateTexture(nil, "BORDER")
  btn.icon:SetAllPoints(btn)
  btn.icon:SetAlpha(0.8)
  btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  -- Cooldown
  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(btn)
  btn:Hide()
  return btn
end

local function LayoutPvPButtons(container, horizontal)
  for i = 1, 5 do
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
        btn.cooldown:SetScript("OnHide", function() MV.HideButton(btn) end)
      end
    else
      if i == 1 then
        btn:SetPoint("TOP", container, "TOP", 0, 0)
      else
        local prev = container.icons[i - 1]
        btn:SetPoint("TOP", prev, "BOTTOM", 0, -4)
        btn.cooldown:SetScript("OnHide", function() MV.HideButton(btn) end)
      end
    end
  end
end

function MV.CreateUnitFrame(params)
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

  -- Background
  f.bg = f:CreateTexture(nil, "BACKGROUND")
  f.bg:SetAllPoints(f)
  f.bg:SetColorTexture(0, 0, 0, 0.6)

  local inset      = 0 -- on the frame edge
  local innerInset = 2 -- 2px inside

  -- Base border (on edge)
  f.border         = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.border:SetPoint("TOPLEFT", inset, -inset)
  f.border:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.border:SetBackdropBorderColor(0, 0, 0, 1)

  -- Mouseover border (on edge, above base)
  f.mouseoverBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.mouseoverBorder:SetPoint("TOPLEFT", inset, -inset)
  f.mouseoverBorder:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.mouseoverBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.mouseoverBorder:SetBackdropBorderColor(0.694, 0.372, 0.98, 1)
  f.mouseoverBorder:SetFrameLevel(f.border:GetFrameLevel() + 1)
  f.mouseoverBorder:Hide()

  -- Inner border
  f.innerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.innerBorder:SetPoint("TOPLEFT", innerInset, -innerInset)
  f.innerBorder:SetPoint("BOTTOMRIGHT", -innerInset, innerInset)
  f.innerBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.innerBorder:SetBackdropBorderColor(0.2, 0.8, 0.2, 1)
  f.innerBorder:Hide()

  -- Outer border
  f.outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.outerBorder:SetPoint("TOPLEFT", inset, -inset)
  f.outerBorder:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.outerBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.outerBorder:SetBackdropBorderColor(1, 1, 1, 1)
  f.outerBorder:SetFrameLevel(f.border:GetFrameLevel() + 2)
  f.outerBorder:Hide()

  -- Health bar
  f.health = CreateFrame("StatusBar", name .. "Health", f)
  f.health:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 4)
  f.health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  f.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
  if not horizontal then
    f.health:SetOrientation("VERTICAL")
  end
  f.health:SetRotatesTexture(true)
  f.health:SetFrameStrata("MEDIUM")
  f.health:SetStatusBarColor(0.25, 0.88, 0.82, 0.8)
  f.health:SetFrameLevel(f:GetFrameLevel() + 1)

  f.absorb = CreateFrame("StatusBar", name .. "Absorb", f)
  f.absorb:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 4)
  f.absorb:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  f.absorb:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  if not horizontal then
    f.absorb:SetOrientation("VERTICAL")
  end
  f.absorb:SetRotatesTexture(true)
  f.absorb:SetFrameStrata("MEDIUM")
  f.absorb:SetStatusBarColor(0.2, 0.45, 0.85, 0.6)
  f.absorb:SetFrameLevel(f.health:GetFrameLevel() + 1)
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

  f:SetScript("OnEnter", function(self)
    self.mouseoverBorder:Show()
  end)

  f:SetScript("OnLeave", function(self)
    self.mouseoverBorder:Hide()
  end)

  -- Aura container
  f.auraContainer = CreateFrame("Frame", name .. "Auras", f)
  f.auraContainer.maxAuras = maxAuras
  f.auraContainer.iconSize = iconSize
  local totalHeight = iconSize * maxAuras + 2 * (maxAuras - 1)
  if horizontal then
    f.auraContainer:SetSize(totalHeight, 28)
    f.auraContainer:SetPoint("LEFT", f, "LEFT", 10, 0)
  else
    f.auraContainer:SetSize(28, totalHeight)
    f.auraContainer:SetPoint("BOTTOM", f, "TOP", 0, -190)
  end
  f.auraContainer:SetFrameLevel(f.absorb:GetFrameLevel() + 1)
  f.auraContainer.icons = {}
  LayoutAuraButtons(f.auraContainer, horizontal)

  if pvpIcons then
    f.otherContainer = CreateFrame("Frame", name .. "Buttons", f)
    f.otherContainer.iconSize = iconSize
    totalHeight = iconSize * 5 + 2 * (5 - 1)
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
