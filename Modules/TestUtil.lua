local _, MF = ...

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

function MF.ToggleTestMode(kind, on)
  if kind == "target" then
    MF_TargetTestMode = on
    local f           = _G["MF_Target"]
    if f then
      if f.UpdateVisibility then f:UpdateVisibility() end
      SetTestIcons(f, MF_TargetTestMode)
    end
  elseif kind == "party" then
    MF_PartyTestMode = on
    for i = 1, 4 do
      local f = _G["MF_Party" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
        SetTestIcons(f, MF_PartyTestMode)
      end
    end
  elseif kind == "arena" then
    MF_ArenaTestMode = on
    for i = 1, 3 do
      local f = _G["MF_Arena" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
        SetTestIcons(f, MF_ArenaTestMode)
      end
    end
  elseif kind == "boss" then
    MF_BossTestMode = on
    for i = 1, 5 do
      local f = _G["MF_Boss" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
        SetTestIcons(f, MF_BossTestMode)
      end
    end
  elseif kind == "raid" then
    MF_RaidTestMode = on
    for i = 1, MF.MaxRaidMembers do
      local f = _G["MF_Raid" .. i]
      if f then
        if f.UpdateVisibility then f:UpdateVisibility() end
        SetTestIcons(f, MF_RaidTestMode)
        if f.orbIcon then
          f.orbIcon:SetShown(MF_RaidTestMode)
        end
      end
    end
  end
end
