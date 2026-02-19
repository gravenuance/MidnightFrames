local _, MV = ...
function MV.ToggleTestMode(kind, on)
  if kind == "target" then
    MV_TargetTestMode = on
    local f           = _G["MV_TargetFrame"]
    if not f then return end

    if on then
      if f.UpdateVisibility then f:UpdateVisibility() end
    else
      if f.UpdateVisibility then f:UpdateVisibility() end
      if f.UpdateHealth then f:UpdateHealth() end
      if f.UpdateAuras then f:UpdateAuras() end
      if f.SetClassColor then f:SetClassColor() end
    end
  elseif kind == "party" then
    MV_PartyTestMode = on
    for i = 1, 4 do
      local f = _G["MV_PartyFrame" .. i]
      if f then
        if on then
          if f.UpdateVisibility then f:UpdateVisibility() end
        else
          if f.UpdateVisibility then f:UpdateVisibility() end
          if f.UpdateHealth then f:UpdateHealth() end
          if f.UpdateAuras then f:UpdateAuras() end
          if f.UpdateArenaTargets then f:UpdateArenaTargets() end
          if f.UpdateTargetHighlight then f:UpdateTargetHighlight() end
          if f.SetClassColor then f:SetClassColor() end
        end
      end
    end
  elseif kind == "arena" then
    MV_ArenaTestMode = on
    for i = 1, 3 do
      local f = _G["MV_ArenaFrame" .. i]
      if f then
        if on then
          if f.UpdateVisibility then f:UpdateVisibility() end
        else
          if f.UpdateVisibility then f:UpdateVisibility() end
        end
      end
    end
  end
end
