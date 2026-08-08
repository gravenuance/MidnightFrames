local _, MF = ...

function MF.UpdateRaidMark(frame)
  if not frame or not frame.raidMark then return end

  local ok, index = MF.GetRaidTargetIndex(frame.unit)
  if ok and MF.IsNumber(index) and not MF.IsSecretSafe(index) then
    SetRaidTargetIconTexture(frame.raidMark.icon, index)
    frame.raidMark:Show()
  else
    frame.raidMark:Hide()
  end
end
