local _, MV                     = ...
local C_UnitAuras               = _G.C_UnitAuras
local C_CurveUtil               = _G.C_CurveUtil

MV.DefaultSize                  = 32
MV.DefaultSizeSmall             = 22

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
  if not MV.IsNil(dispelTypeCurve) then
    return dispelTypeCurve
  end

  local ok, curve = MV.CallExternalFunction({
    namespace = C_CurveUtil,
    functionName = "CreateColorCurve"
  }
  )
  if not ok then return end
  ok, _ = MV.CallExternalFunction({
    namespace = curve,
    functionName = "SetType",
    args = { curve, curveType },
    argumentValidators = { MV.IsUserData, MV.IsNumber }
  })
  if not ok then return end
  for _, dispelIndex in next, Enum.DispelType do
    local color = dispel[dispelIndex]
    if color then
      ok, _ = MV.CallExternalFunction({
        namespace = curve,
        functionName = "AddPoint",
        args = { curve, dispelIndex, color },
        argumentValidators = { MV.IsUserData, MV.IsNumber, MV.IsTable }
      })
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
  local ok, dispelTypeColor = MV.CallExternalFunction({
    namespace = C_UnitAuras,
    functionName = "GetAuraDispelTypeColor",
    args = { unit, auraData.auraInstanceID, curve },
    argumentValidators = { MV.IsString, MV.IsNumber, MV.IsUserData }
  })
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

  local ok, result = MV.CallExternalFunction(
    {
      namespace = C_UnitAuras,
      functionName = "GetAuraDuration",
      args = { unit, auraData.auraInstanceID },
      argumentValidators = { MV.IsString, MV.IsNumber }
    }
  )
  if ok then
    ok, result = MV.CallExternalFunction(
      {
        namespace = cd,
        functionName = "SetCooldownFromDurationObject",
        args = { cd, result, true },
        argumentValidators = { MV.IsTable, MV.IsUserData, MV.IsBoolean },
      }
    )
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
  if not MV.IsNumber(tex) and not MV.IsString(tex) then
    return false
  end

  btn.icon:SetTexture(tex)
  return true
end

local function GetAndUpdateAuras(container, unit, filters, maxRemaining)
  if not MV.UnitExists(unit) then
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
    local auraList, totalAuras

    local ok, result = MV.CallExternalFunction({
      namespace = C_UnitAuras,
      functionName = "GetUnitAuras",
      args = { unit, filter, maxRemaining, Enum.UnitAuraSortRule.BigDefensive, Enum.UnitAuraSortDirection.Reverse },
      argumentValidators = { MV.IsString, MV.IsString, MV.IsNumber, MV.IsNumber, MV.IsNumber }
    })
    if ok and MV.IsTable(result) then
      local count = #result
      auraList = result
      totalAuras = count
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

function MV.UpdateAuras(frame)
  --[[ if not UnitExists(frame.unit) then
    GetAndUpdateAuras(frame.auraContainer, frame.unit, {}, 0)
    return
  end ]]
  local filters = {}
  local cfg = MV.GetUnitFilters(frame.unitKey)

  for filter, enabled in pairs(cfg) do
    if enabled then
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
