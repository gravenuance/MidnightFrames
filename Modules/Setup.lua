local _, MF = ...

-- Soft-bloom approximation for the highlight borders: a larger, softer-alpha
-- BackdropTemplate ring layered behind the crisp 2px border, bleeding a few
-- pixels past it. WoW textures have no real blur, so this isn't a true
-- gaussian glow - it's a second edge, thicker and more transparent, using the
-- exact same BackdropTemplate technique already proven throughout this file
-- rather than something unproven (blend-mode-layered textures). Parented to
-- the border frame itself so it shows/hides for free whenever the border
-- does, with no changes needed anywhere the borders are already toggled.
local function AddGlow(borderFrame, r, g, b, bleed, edgeSize, alpha)
  local glow = CreateFrame("Frame", nil, borderFrame, "BackdropTemplate")
  glow:SetPoint("TOPLEFT", -bleed, bleed)
  glow:SetPoint("BOTTOMRIGHT", bleed, -bleed)
  glow:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = edgeSize,
  })
  glow:SetBackdropBorderColor(r, g, b, alpha)
  -- Explicit rather than relying on the implicit child-defaults-to-parent+1
  -- behavior: still call this AFTER borderFrame's own SetFrameLevel has
  -- already been set to its final value (see call sites), since this reads
  -- borderFrame's level at the moment AddGlow runs, not continuously.
  glow:SetFrameLevel(borderFrame:GetFrameLevel() + 1)
  return glow
end

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

  -- Highlight stacking order (low to high): inner (ally-targeted) < outer (my
  -- target) < mouseover - mouseover is the active, momentary signal, so it
  -- should always read on top of the more ambient/persistent target and
  -- ally-target state, never get buried by them. Each border's SetFrameLevel
  -- MUST run before its AddGlow call - the glow is a child, and an unset-
  -- level child snapshots its default level (parent's level *at creation
  -- time*) rather than tracking the parent's level live, so calling AddGlow
  -- first silently glued the glow to the parent's pre-adjustment level
  -- instead of its real, final one. (That ordering bug is exactly why the
  -- outer glow was landing above the mouseover highlight instead of below it.)

  -- Inner border
  f.innerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.innerBorder:SetPoint("TOPLEFT", innerInset, -innerInset)
  f.innerBorder:SetPoint("BOTTOMRIGHT", -innerInset, innerInset)
  f.innerBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.innerBorder:SetBackdropBorderColor(0.2, 0.8, 0.2, 1)
  f.innerBorder:SetFrameLevel(f.border:GetFrameLevel() + 1)
  AddGlow(f.innerBorder, 0.2, 0.8, 0.2, 2, 6, 0.25)
  f.innerBorder:Hide()

  -- Outer border. Glow sized to match mouseover's bloom exactly (bleed/edge
  -- below) so target and mouseover read as the same weight of highlight -
  -- alpha stays a touch lower than mouseover's so mouseover still reads as
  -- the "brighter" of the two when both are visible. With the ordering fix
  -- above, this now correctly layers below the mouseover highlight instead
  -- of painting over it.
  f.outerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.outerBorder:SetPoint("TOPLEFT", inset, -inset)
  f.outerBorder:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.outerBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.outerBorder:SetBackdropBorderColor(1, 1, 1, 1)
  f.outerBorder:SetFrameLevel(f.border:GetFrameLevel() + 2)
  AddGlow(f.outerBorder, 1, 1, 1, 3, 8, 0.26)
  f.outerBorder:Hide()

  -- Mouseover border (on edge, above everything else - see stacking-order
  -- note above)
  f.mouseoverBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
  f.mouseoverBorder:SetPoint("TOPLEFT", inset, -inset)
  f.mouseoverBorder:SetPoint("BOTTOMRIGHT", -inset, inset)
  f.mouseoverBorder:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 2,
  })
  f.mouseoverBorder:SetBackdropBorderColor(0.694, 0.372, 0.98, 1)
  f.mouseoverBorder:SetFrameLevel(f.border:GetFrameLevel() + 3)
  AddGlow(f.mouseoverBorder, 0.694, 0.372, 0.98, 3, 8, 0.30)
  f.mouseoverBorder:Hide()

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
  MF.ApplyHealthGradient(f.health, 0.25, 0.88, 0.82)
  f.health:SetAlpha(0.8)
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

  -- Raid target mark (skull/cross/etc.) and cast indicator share one corner
  -- treatment: centered ON a health-bar corner (not tucked inside it) so only
  -- one quadrant of the icon ever overlaps the bar - health-color legibility
  -- takes priority over either indicator, which just needs to be glanceable.
  -- Sized off iconSize so both scale down naturally on the small raid frames
  -- instead of needing their own per-frame-type constant.
  local cornerIconSize = math.floor(iconSize / 2)

  -- Top-right corner. Confirmed clear on every frame type: roleIcon is always
  -- CENTER-anchored, orbIcon/otherContainer sit entirely outside the frame,
  -- and auraContainer never reaches this corner (BOTTOM-anchored well below
  -- it on vertical frames, LEFT-anchored on horizontal/raid frames).
  f.raidMark = CreateFrame("Frame", name .. "RaidMark", f)
  f.raidMark:SetSize(cornerIconSize, cornerIconSize)
  f.raidMark:SetPoint("CENTER", f.health, "TOPRIGHT", 0, 0)
  f.raidMark:SetFrameStrata("MEDIUM")
  -- Above every highlight border, including mouseover (its old level -
  -- f.absorb:GetFrameLevel()+1 - worked out to the same f.border-relative
  -- offset as mouseoverBorder's, so which one painted on top was undefined
  -- instead of guaranteed to be this).
  f.raidMark:SetFrameLevel(f.mouseoverBorder:GetFrameLevel() + 1)
  f.raidMark.icon = f.raidMark:CreateTexture(nil, "OVERLAY")
  f.raidMark.icon:SetAllPoints(f.raidMark)
  f.raidMark.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
  f.raidMark:Hide()

  -- Top-left corner, mirroring the mark - a radial cast indicator instead of
  -- a bar (no orientation problem to solve, reuses the same Cooldown-sweep
  -- language as the aura/DR/trinket icons). Raid frames are excluded: their
  -- auraContainer is LEFT-anchored across roughly the frame's left half (see
  -- below), which overlaps this corner the same way it would have broken a
  -- mirrored raid mark there.
  --
  -- Sized a bit larger than the raid mark, and nudged right of dead-center
  -- on the corner (rather than centered exactly on it like the mark) - at
  -- default frame spacing, two adjacent frames are only a few pixels apart,
  -- so a corner badge centered exactly on the top-left point bled far enough
  -- left to collide with the neighboring frame's top-right raid mark, which
  -- bleeds the same distance right from its own corner.
  if not horizontal then
    local castIconSize = math.floor(cornerIconSize * 1.2)
    f.castIndicator = CreateFrame("Frame", name .. "CastIndicator", f)
    f.castIndicator:SetSize(castIconSize, castIconSize)
    f.castIndicator:SetPoint("CENTER", f.health, "TOPLEFT", castIconSize * 0.35, 0)
    f.castIndicator:SetFrameStrata("MEDIUM")
    -- Same reasoning as f.raidMark above: must sit above every highlight
    -- border, mouseover included.
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
