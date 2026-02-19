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
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetUnitAuraByAuraInstanceID(self.unit, self.auraInstanceID)
  end)

  btn:SetScript("OnLeave", function()
    if GameTooltip:IsForbidden() then return end
    GameTooltip:Hide()
  end)

  return btn
end

local function LayoutAuraButtons(container)
  for i = 1, container.maxAuras do
    local btn = container.icons[i] or CreateAuraButton(container, i)
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

local function CreateGenericButton(parent, index)
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

  return btn
end

local function LayoutPvPButtons(container)
  for i = 1, 4 do
    local btn = container.icons[i] or CreateGenericButton(container, i)
    container.icons[i] = btn
    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint("TOP", container, "TOP", 0, 0)
    else
      local prev = container.icons[i - 1]
      btn:SetPoint("TOP", prev, "BOTTOM", 0, -4)
    end
  end
end

function MV.CreateUnitFrame(params)
  local name     = params.name
  local unit     = params.unit
  local point    = params.point
  local size     = params.size or { 50, 220 }
  local maxAuras = params.maxAuras or 4
  local iconSize = params.iconSize or 32
  local pvpIcons = params.pvpIcons or false

  local f        = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
  f:SetSize(size[1], size[2])
  f:SetPoint(point[1], point[2] or UIParent, point[3], point[4], point[5])
  f:SetAttribute("unit", unit)
  f:SetAttribute("*type1", "target")
  f:RegisterForClicks("AnyUp")
  f:SetAttribute("type2", "togglemenu")

  f.unit = unit
  f.maxAuras = maxAuras

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

  -- Mouseover
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
  f.health = CreateFrame("StatusBar", name .. "Health", f)
  f.health:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 4)
  f.health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  f.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
  f.health:SetOrientation("VERTICAL")
  f.health:SetRotatesTexture(true)
  f.health:SetFrameStrata("MEDIUM")
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
  f.auraContainer:SetSize(28, totalHeight)
  f.auraContainer:SetPoint("BOTTOM", f, "TOP", 0, -190)
  f.auraContainer.icons = {}

  LayoutAuraButtons(f.auraContainer)

  if pvpIcons then
    f.secondContainer = CreateFrame("Frame", name .. "Buttons", f)
    f.secondContainer.iconSize = iconSize

    totalHeight = iconSize * 5 + 2 * (5 - 1)
    f.secondContainer:SetSize(28, totalHeight)
    f.secondContainer:SetPoint("TOP", f, "BOTTOM", 0, -10)
    f.secondContainer.icons = {}

    LayoutPvPButtons(f.secondContainer)

    return f
  end

  return f
end
