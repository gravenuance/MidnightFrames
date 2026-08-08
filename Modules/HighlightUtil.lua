local _, MF = ...
function MF.UpdateTargetHighlight(frame, testFlag)
  if testFlag then return end
  if not frame:IsShown() then return end
  if MF.UnitIsUnit(frame.unit) then
    frame.outerBorder:Show()
  else
    frame.outerBorder:Hide()
  end
end
