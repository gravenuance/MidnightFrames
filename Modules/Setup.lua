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

  -- Tooltip handlers
  btn:SetScript("OnEnter", function(self)
    if not self.unit or not self.auraInstanceID or GameTooltip:IsForbidden() then
      return
    end
    MV.CallExternalFunction(
      {
        namespace = GameTooltip,
        functionName = "SetOwner",
        args = { GameTooltip, self, "ANCHOR_BOTTOMRIGHT" },
        argumentValidators = { MV.IsUserData, MV.IsUserData, MV.IsString }
      }
    )
    MV.CallExternalFunction(
      {
        namespace = GameTooltip,
        functionName = "SetUnitAuraByAuraInstanceID",
        args = { GameTooltip, self.unit, self.auraInstanceID },
        argumentValidators = { MV.IsUserData, MV.IsString, MV.IsNumber }
      }
    )
  end)

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

  -- Above the border
  btn.immune = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
  btn.immune:SetTexture("Interface\\Buttons\\WHITE8x8")
  btn.immune:SetVertexColor(1, 0, 0, 1)
  btn.immune:SetPoint("TOPLEFT", -1, 1)
  btn.immune:SetPoint("BOTTOMRIGHT", 1, -1)
  btn.immune:Hide()

  -- Icon above border
  btn.icon = btn:CreateTexture(nil, "BORDER")
  btn.icon:SetAllPoints(btn)
  btn.icon:SetAlpha(0.8)
  btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  -- Cooldown
  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(btn)
  btn.cooldown:Hide()
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

  local inset      = 0  -- on the frame edge
  local innerInset = 2  -- 2px inside
  local outerInset = -2 -- 2px outside

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
  f.outerBorder:SetPoint("TOPLEFT", outerInset, -outerInset)
  f.outerBorder:SetPoint("BOTTOMRIGHT", -outerInset, outerInset)
  f.outerBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.outerBorder:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
  f.outerBorder:SetFrameLevel(f.border:GetFrameLevel() - 1)
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
