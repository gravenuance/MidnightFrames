local _, MF = ...

function MF.UpdateOrbs(frame, unitId, identifier)
  if not frame or not frame.unit then return end
  if frame.unit == "player" or MF.IsUnitUnit(frame.unit, "player") then
    return
  end
  if MF.IsSecretSafe(unitId) or MF.IsSecretSafe(identifier) then
    return
  end
  if MF.IsUnitUnit(frame.unit, unitId) and identifier == "seen" then
    frame.orbIcon:SetShown(true)
    frame.bgUnit = unitId
  elseif frame.bgUnit == unitId and identifier == "cleared" then
    frame.bgUnit = nil
    frame.orbIcon:Hide()
  end
end

function MF.ResetOrbs(frame)
  if frame.orbIcon:IsShown() then
    frame.bgUnit = nil
    frame.orbIcon:Hide()
  end
end
