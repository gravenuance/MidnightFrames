local _, MV = ...

local testAura = "Interface\\Icons\\Spell_Nature_Rejuvenation"
local testTrinket = "Interface\\Icons\\INV_Misc_PocketWatch_01"

local function SetTestIcons(frame, test)
  frame.auraContainer.icons[1]:SetShown(test)
  frame.auraContainer.icons[1].icon:SetTexture(testAura)
  if frame.otherContainer then
    frame.otherContainer.icons[1]:SetShown(test)
    frame.otherContainer.icons[1].icon:SetTexture(testTrinket)
  end
  frame.innerBorder:SetShown(test)
  frame.outerBorder:SetShown(test)
end

function MV.ToggleTestMode(kind, on)
  if kind == "target" then
    MV_TargetTestMode = on
    local f           = _G["MV_TargetFrame"]
    if f then
      if f.UpdateVisibility then f:UpdateVisibility() end
      SetTestIcons(f, MV_TargetTestMode)
    end
  elseif kind == "party" then
    MV_PartyTestMode = on
    for i = 1, 4 do
      local f = _G["MV_PartyFrame" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
        SetTestIcons(f, MV_PartyTestMode)
      end
    end
  elseif kind == "arena" then
    MV_ArenaTestMode = on
    for i = 1, 3 do
      local f = _G["MV_ArenaFrame" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
        SetTestIcons(f, MV_ArenaTestMode)
      end
    end
  elseif kind == "boss" then
    MV_BossTestMode = on
    for i = 1, 5 do
      local f = _G["MV_BossFrame" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
        SetTestIcons(f, MV_BossTestMode)
      end
    end
  elseif kind == "raid" then
    MV_RaidTestMode = on
    for i = 1, MV.MaxRaidMembers do
      local f = _G["MV_RaidFrame" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
        SetTestIcons(f, MV_RaidTestMode)
      end
    end
  end
end
