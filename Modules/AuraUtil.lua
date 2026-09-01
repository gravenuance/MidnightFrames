local _, MF                     = ...

MF.DefaultSize                  = 32
MF.DefaultSizeSmall             = 22

-- local shim: the client exposes Enum.AuraDispelType, not Enum.DispelType
local DispelType                = {
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
dispel[DispelType.None]         = _G.DEBUFF_TYPE_NONE_COLOR
dispel[DispelType.Magic]        = _G.DEBUFF_TYPE_MAGIC_COLOR
dispel[DispelType.Curse]        = _G.DEBUFF_TYPE_CURSE_COLOR
dispel[DispelType.Disease]      = _G.DEBUFF_TYPE_DISEASE_COLOR
dispel[DispelType.Poison]       = _G.DEBUFF_TYPE_POISON_COLOR
dispel[DispelType.Bleed]        = _G.DEBUFF_TYPE_BLEED_COLOR
dispel[DispelType.Enrage]       = CreateColor(243 / 255, 95 / 255, 245 / 255, 1)

local dispelTypeCurve

local function GetDispelTypeCurve()
  if not MF.IsNil(dispelTypeCurve) then
    return dispelTypeCurve
  end

  local ok, curve = MF.CreateColorCurve()
  if not ok then return end
  ok = MF.SetCurveType(curve, curveType)
  if not ok then return end
  for _, dispelIndex in next, DispelType do
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

-- Resolving a unit's enabled-filter list only changes when its checkboxes
-- change (Core.lua's Auras tab) or the profile switches - cache it instead
-- of rebuilding on every UNIT_AURA, which is the hottest event this addon
-- handles (fires per stack/refresh, on up to ~36 visible frames at once).
local resolvedFilterCache = {}

function MF.InvalidateFilterCache(unitKey)
  if unitKey then
    resolvedFilterCache[unitKey] = nil
  else
    wipe(resolvedFilterCache)
  end
end

local function ResolveFilters(unitKey)
  local cached = resolvedFilterCache[unitKey]
  if cached then return cached end

  local cfg = MF.GetUnitFilters(unitKey)
  local filters = {}
  -- fixed order so which filters win the limited icon slots is predictable
  for _, filter in ipairs(MF.FilterOrder or {}) do
    if cfg[filter] then
      table.insert(filters, filter)
    end
  end

  -- the curated categories (IMPORTANT/CROWD_CONTROL/etc.) are narrow,
  -- Blizzard-tagged subsets, not "every buff" - with none of them checked
  -- there's nothing to narrow down from, so fall back to plain HELPFUL/
  -- HARMFUL (everything) instead of showing nothing
  if #filters == 0 then
    filters = { "HELPFUL", "HARMFUL" }
  end

  resolvedFilterCache[unitKey] = filters
  return filters
end

function MF.UpdateAuras(frame)
  GetAndUpdateAuras(
    frame.auraContainer,
    frame.unit,
    ResolveFilters(frame.unitKey),
    frame.maxAuras
  )
end
