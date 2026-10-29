local _, MF = ...

-- permanently hides a default Blizzard frame, even through combat lockdown
function MF.HideBlizzardFrame(frameName)
  local frame = _G[frameName]
  if not frame then return end

  frame:UnregisterAllEvents()
  RegisterStateDriver(frame, "visibility", "hide")
end

-- Undoes MF.HideBlizzardFrame. Hiding dropped every event registration and
-- they can't be read back, so the caller names the ones the frame needs.
-- Releases the hide driver instead of pinning the frame visible, so
-- Blizzard's own visibility rules apply again.
-- Not for use in combat: it changes a protected frame.
function MF.ShowBlizzardFrame(frameName, events)
  local frame = _G[frameName]
  if not frame then return end

  UnregisterStateDriver(frame, "visibility")
  frame:Show()
  for _, event in ipairs(events) do
    frame:RegisterEvent(event)
  end
end
