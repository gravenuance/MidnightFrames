local _, MV = ...

local C_CurveUtil = C_CurveUtil

MV.FrameSpace = 55
MV.FrameX = 280
MV.FrameXAlt = 225
MV.SizeX = 50
MV.SizeY = 220
MV.SizeYAlt = 210
MV.PetX = 20
MV.PetY = 80
MV.PetSpace = 5

local powerCurve
local curveType = Enum.LuaCurveType.Linear

function MV.UpdatePowerLabel(frame)
  if not frame.power then return end
  if not MV.UnitExists(frame.unit) then
    frame.power:SetText("")
    return
  end
  if MV.IsNil(powerCurve) then
    local ok, curve = MV.CallExternalFunction({
      namespace = C_CurveUtil,
      functionName = "CreateCurve"
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
    curve:AddPoint(0.0, 0)
    curve:AddPoint(1.0, 100)
    powerCurve = curve
  end
  local ok, power = MV.CallExternalFunction(
    {
      functionName = "UnitPowerPercent",
      args = { frame.unit, nil, true, powerCurve },
      argumentValidators = { MV.IsString, MV.IsNil, MV.IsBoolean, MV.IsUserData }
    }
  )
  if not ok or power == nil then
    frame.power:SetText("")
    return
  end
  frame.power:SetText(string.format("%.0f", power))
end
