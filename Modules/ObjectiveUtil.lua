local _, MV = ...

function MV.UpdateOrbs(frame, unitId, identifier)
  if not frame or not frame.unit then return end
  if frame.unit == "player" or MV.IsUnitUnit(frame.unit, "player") then
    return
  end
  if MV.IsUnitUnit(frame.unit, unitId) and identifier == "seen" then
    frame.orbIcon:SetShown(true)
    frame.bgUnit = unitId
  elseif frame.bgUnit == unitId and identifier == "cleared" then
    frame.bgUnit = nil
    frame.orbIcon:Hide()
  end
end

function MV.ResetOrbs(frame)
  if frame.orbIcon:IsShown() then
    frame.bgUnit = nil
    frame.orbIcon:Hide()
  end
end
