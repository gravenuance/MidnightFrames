local _, MV = ...

function MV.UpdateOrbs(frame, unitId)
  if not frame or not frame.unit then return end
  if frame.unit == "player" or MV.IsUnitUnit(frame.unit, "player") then
    return
  end
  if MV.IsUnitUnit(frame.unit, unitId) then
    local shouldShow = not frame.orbIcon:IsShown()
    frame.orbIcon:SetShown(shouldShow)
  else
    frame.orbIcon:Hide()
  end
end

function MV.ResetOrbs(frame)
  if frame.orbIcon:IsShown() then
    frame.orbIcon:Hide()
  end
end
