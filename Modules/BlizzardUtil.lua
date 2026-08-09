local _, MF = ...

-- permanently hides a default Blizzard frame, even through combat lockdown
function MF.HideBlizzardFrame(frameName)
  local frame = _G[frameName]
  if not frame then return end

  frame:UnregisterAllEvents()
  RegisterStateDriver(frame, "visibility", "hide")
end
