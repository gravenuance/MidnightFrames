local _, MV = ...

function MV.UpdateRoleIcon(frame, testFlag)
  if testFlag then return end
  local ok, role = MV.CallExternalFunction({
    functionName = "UnitGroupRolesAssigned",
    args = { frame.unit },
    argumentValidators = { MV.IsString }
  })
  if not ok then
    print(ok, "Result:", role)
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
