local _, MF                     = ...

MF.DefaultSize                  = 32
MF.DefaultSizeSmall             = 22

Enum.DispelType                 = {
  None    = 0,
  Magic   = 1,
  Curse   = 2,
  Disease = 3,
  Poison  = 4,
  Enrage  = 9,
  Bleed   = 11,
}

local curveType                 = Enum.LuaCurveType.Step

local dispel                    = {}
dispel[Enum.DispelType.None]    = _G.DEBUFF_TYPE_NONE_COLOR
dispel[Enum.DispelType.Magic]   = _G.DEBUFF_TYPE_MAGIC_COLOR
dispel[Enum.DispelType.Curse]   = _G.DEBUFF_TYPE_CURSE_COLOR
dispel[Enum.DispelType.Disease] = _G.DEBUFF_TYPE_DISEASE_COLOR
dispel[Enum.DispelType.Poison]  = _G.DEBUFF_TYPE_POISON_COLOR
dispel[Enum.DispelType.Bleed]   = _G.DEBUFF_TYPE_BLEED_COLOR
dispel[Enum.DispelType.Enrage]  = CreateColor(243 / 255, 95 / 255, 245 / 255, 1)

local dispelTypeCurve

local function GetDispelTypeCurve()
  if not MF.IsNil(dispelTypeCurve) then
    return dispelTypeCurve
  end

  local ok, curve = MF.CreateColorCurve()
  if not ok then return end
  ok = MF.SetCurveType(curve, curveType)
  if not ok then return end
  for _, dispelIndex in next, Enum.DispelType do
    local color = dispel[dispelIndex]
    if color then
      MF.AddCurvePoint(curve, dispelIndex, color)
    end
  end
  dispelTypeCurve = curve
  return dispelTypeCurve
end

local function ApplyAuraDispelBorderColor(btn, unit, auraData)
  local border = btn and btn.border
  if not border then return end

  border:SetVertexColor(0, 0, 0, 1)

  if not auraData then
    return
  end

  local curve = GetDispelTypeCurve()
  if not curve then
    print("No curve object")
    return
  end
  local ok, dispelTypeColor = MF.GetAuraDispelTypeColor(unit, auraData.auraInstanceID, curve)
  if ok then
    border:SetVertexColor(dispelTypeColor:GetRGBA())
  end
end

local function ApplyAuraCooldown(btn, unit, auraData)
  local cd = btn and btn.cooldown
  if not cd then return end

  cd:Hide()

  if not auraData then
    return
  end

  local ok, result = MF.GetAuraDuration(unit, auraData.auraInstanceID)
  if ok then
    ok = MF.SetCooldownFromDurationObject(cd, result, true)
    if ok then
      cd:Show()
    end
  end
end

local function SetAuraTexture(btn, auraData)
  if not btn or not btn.icon then
    return false
  end
  btn.icon:SetTexture(nil)

  if not auraData then
    return false
  end

  local tex = auraData.icon
  if not MF.IsNumber(tex) and not MF.IsString(tex) then
    return false
  end

  btn.icon:SetTexture(tex)
  return true
end

local function GetAndUpdateAuras(container, unit, filters, maxRemaining)
  if not MF.UnitExists(unit) then
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
  maxRemaining = maxRemaining or 4
  local seen = {}

  local function AddAuras(filter)
    -- Secret-vector safety (12.1's aura-container restrictions) is handled
    -- inside MF.GetUnitAuras (SecureUtil.lua) so every caller gets it
    -- automatically instead of re-deriving it at each call site.
    local ok, auraList, totalAuras = MF.GetUnitAuras(
      unit, filter, maxRemaining, Enum.UnitAuraSortRule.BigDefensive, Enum.UnitAuraSortDirection.Reverse
    )
    if not ok or not auraList or totalAuras == 0 then
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

      -- auraInstanceID isn't expected to ever be secret, but table-key
      -- indexing by a secret value is unreliable, so guard it anyway rather
      -- than assume: if it can't be trusted, just skip the dedup check for
      -- this aura instead of risking a bad break/no-op.
      local instanceID = auraData.auraInstanceID
      if MF.IsNumber(instanceID) and not MF.IsSecretSafe(instanceID) then
        if seen[instanceID] then
          break
        else
          seen[instanceID] = true
        end
      end

      if auraData.icon then
        local btn = container.icons[shown]

        if not SetAuraTexture(btn, auraData) then
          break
        end

        btn.unit = unit
        btn.auraFilter = filter
        btn.auraInstanceID = auraData.auraInstanceID
        btn.auraIndex = auraData.auraIndex or auraData.index or listIndex

        ApplyAuraCooldown(btn, unit, auraData)
        ApplyAuraDispelBorderColor(btn, unit, auraData)
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

function MF.UpdateAuras(frame)
  --[[ if not UnitExists(frame.unit) then
    GetAndUpdateAuras(frame.auraContainer, frame.unit, {}, 0)
    return
  end ]]
  local filters = {}
  local cfg = MF.GetUnitFilters(frame.unitKey)

  -- Iterate MF.FilterOrder (not pairs(cfg)) so which enabled filters win the
  -- limited icon slots is deterministic and priority-ranked, rather than
  -- depending on Lua's unspecified hash-table iteration order.
  for _, filter in ipairs(MF.FilterOrder or {}) do
    if cfg[filter] then
      table.insert(filters, filter)
    end
  end

  GetAndUpdateAuras(
    frame.auraContainer,
    frame.unit,
    filters,
    frame.maxAuras
  )
end
