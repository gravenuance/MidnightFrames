local _, MV                     = ...
local C_UnitAuras               = C_UnitAuras
local C_CurveUtil               = C_CurveUtil

MV.DefaultSize                  = 32

Enum.DispelType                 = {
  None    = 0,
  Magic   = 1,
  Curse   = 2,
  Disease = 3,
  Poison  = 4,
  Enrage  = 9,
  Bleed   = 11,
}

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

local function ApplyAuraDispelBorderColor(btn, unit, auraData)
  local border = btn and btn.border
  if not border then return end

  border:SetVertexColor(0, 0, 0, 1)

  if not auraData then
    return
  end

  local curve = GetDispelTypeCurve()
  if not curve then
    print("MV: No curve object.")
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

local function ApplyAuraCooldown(btn, unit, auraData)
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

local function SetAuraTexture(btn, auraData)
  if not btn or not btn.icon then
    print("MV_SetAuraTexture: invalid button")
    return false
  end
  btn.icon:SetTexture(nil)

  if not auraData or not auraData.icon then
    print("MV_SetAuraTexture: no aura data or icon")
    return false
  end

  local tex = auraData.icon

  if type(tex) ~= "number" and type(tex) ~= "string" then
    print("MV_SetAuraTexture: invalid icon type: " .. tostring(tex))
    return false
  end
  btn.icon:SetTexture(tex)
  return true
end

function MV.GetAndUpdateAuras(container, unit, filters, maxRemaining)
  if not C_UnitAuras
      or not C_UnitAuras.GetUnitAuras
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
