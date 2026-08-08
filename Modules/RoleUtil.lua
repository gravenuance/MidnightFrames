local _, MF = ...

function MF.UpdateRoleIcon(frame, testFlag)
  if testFlag then return end
  local ok, role = MF.UnitGroupRolesAssigned(frame.unit)
  if not ok or MF.IsSecretSafe(role) then
    frame.roleIcon:Hide()
    return
  end
  if role == "TANK" then
    frame.roleIcon.icon:SetAtlas("UI-LFG-RoleIcon-Tank", true)
    frame.roleIcon:Show()
  elseif role == "HEALER" then
    frame.roleIcon.icon:SetAtlas("UI-LFG-RoleIcon-Healer", true)
    frame.roleIcon:Show()
  else
    frame.roleIcon:Hide()
  end
end
