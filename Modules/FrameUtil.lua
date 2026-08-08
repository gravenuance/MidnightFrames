local _, MF = ...

MF.FrameSpace = 55
MF.FrameX = 280
MF.FrameXAlt = 225
MF.SizeX = 50
MF.SizeY = 220
MF.SizeYAlt = 210
MF.PetX = 20
MF.PetY = 80
MF.PetSpace = 5
MF.RaidSizeX = 150
MF.RaidSizeY = 35
MF.NumGroupMembers = 0

local powerCurve
local curveType = Enum.LuaCurveType.Linear

function MF.UpdatePowerLabel(frame)
  if not frame.power then return end
  if not MF.UnitExists(frame.unit) then
    frame.power:SetText("")
    return
  end
  if MF.IsNil(powerCurve) then
    local ok, curve = MF.CreateCurve()
    if not ok then return end
    ok = MF.SetCurveType(curve, curveType)
    if not ok then return end
    MF.AddCurvePoint(curve, 0.0, 0)
    MF.AddCurvePoint(curve, 1.0, 100)
    powerCurve = curve
  end
  local ok, power = MF.UnitPowerPercent(frame.unit, powerCurve)
  if not ok or power == nil then
    frame.power:SetText("")
    return
  end
  frame.power:SetText(string.format("%.0f", power))
end

function MF.InInstance()
  local _, instanceType = IsInInstance()
  return instanceType == "party" or instanceType == "raid"
end
