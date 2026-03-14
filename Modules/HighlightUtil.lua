local _, MV = ...
function MV.UpdateTargetHighlight(frame, testFlag)
  if testFlag then return end
  if MV.UnitIsUnit(frame.unit) then
    frame.outerBorder:Show()
  else
    frame.outerBorder:Hide()
  end
end
