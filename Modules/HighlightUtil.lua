local _, MV = ...
function MV.UpdateTargetHighlight(frame, testFlag)
  if testFlag then return end
  if UnitIsUnit("target", frame.unit) then
    frame.border:SetBackdropBorderColor(1, 1, 1, 1)
  else
    frame.border:SetBackdropBorderColor(0, 0, 0, 1)
  end
end
