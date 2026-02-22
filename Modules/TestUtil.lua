local _, MV = ...
function MV.ToggleTestMode(kind, on)
  if kind == "target" then
    MV_TargetTestMode = on
    local f           = _G["MV_TargetFrame"]
    if f then
      if f.UpdateVisibility then f:UpdateVisibility() end
    end
  elseif kind == "party" then
    MV_PartyTestMode = on
    for i = 1, 4 do
      local f = _G["MV_PartyFrame" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
      end
    end
  elseif kind == "arena" then
    MV_ArenaTestMode = on
    for i = 1, 3 do
      local f = _G["MV_ArenaFrame" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
      end
    end
  elseif kind == "boss" then
    MV_BossTestMode = on
    for i = 1, 5 do
      local f = _G["MV_BossFrame" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
      end
    end
  elseif kind == "raid" then
    MV_RaidTestMode = on
    local f = _G["MV_RaidFrame" .. 1]
    if f then
      if f.UpdateVisibility then f:UpdateVisibility() end
    end
  end
end
