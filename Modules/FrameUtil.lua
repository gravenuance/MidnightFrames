local _, MV = ...

local C_CurveUtil = C_CurveUtil
local UnitPowerPercent = UnitPowerPercent

function MV.ApplyClassColor(frame)
  local r, g, b = MV.GetClassColor(frame.unit)

  if not frame.health then return end

  frame.health:SetStatusBarColor(r, g, b, MV.RegAlpha)
  if frame.power then
    local dr, dg, db = r * 0.7, g * 0.7, b * 0.7
    frame.power:SetTextColor(dr, dg, db, 1)
  end
  if frame.pet then
    if frame.pet.health then
      frame.pet.health:SetStatusBarColor(r, g, b, MV.RegAlpha)
    end
  end
end

function MV.UpdateAuras(frame)
  if not UnitExists(frame.unit) then
    MV.GetAndUpdateAuras(frame.auraContainer, frame.unit, {}, 0)
    return
  end

  local filters = {}
  local cfg = MV.GetUnitFilters(frame.unit)

  for filter, enabled in pairs(cfg) do
    if enabled then
      table.insert(filters, filter)
    end
  end
  MV.GetAndUpdateAuras(
    frame.auraContainer,
    frame.unit,
    filters,
    frame.maxAuras
  )
end

function MV.UpdatePowerLabel(frame)
  if not frame.power or not UnitExists(frame.unit) then return end
  local curve = C_CurveUtil.CreateCurve()
  curve:SetType(Enum.LuaCurveType.Linear)
  curve:AddPoint(0.0, 0)
  curve:AddPoint(1.0, 100)
  local power = UnitPowerPercent(frame.unit, nil, true, curve)
  if power == nil then
    frame.power:SetText("")
    return
  end
  frame.power:SetText(string.format("%.0f", power))
end
