local _, MF = ...

-- Permanently hides one of Blizzard's default frames. RegisterStateDriver
-- hooks the frame's visibility into the same secure state-driver system
-- Blizzard itself uses (compare RegisterUnitWatch elsewhere in this addon)
-- instead of calling :Hide() directly or hooksecurefunc-ing Show/
-- UpdateShownState: the driver is evaluated by the secure environment, so it
-- holds through combat lockdown, /reload, and any future Blizzard code that
-- tries to :Show() the frame again - no InCombatLockdown() branching or
-- per-event re-hide logic required.
function MF.HideBlizzardFrame(frameName)
  local frame = _G[frameName]
  if not frame then return end

  frame:UnregisterAllEvents()
  RegisterStateDriver(frame, "visibility", "hide")
end
