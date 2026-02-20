local _, MV = ...
local baseName = "MV_ArenaFrame"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MV_ArenaTestMode = false

local blizzFrame = "CompactArenaFrame"

local altAlpha = MV.OtherAlpha
local regAlpha = MV.RegAlpha

local MAX_AURAS = 4

local c1, c2, c3, c4 = 0.1, 0.9, 0.1, 0.9
local stealthIcon = 132320

local function SetIconZoom(owner)
  local x1, x2, x3, x4 = owner:GetTexCoord()
  if x1 ~= c1 or x2 ~= c2 or x3 ~= c3 or x4 ~= c4 then
    owner:SetTexCoord(c1, c2, c3, c4)
  end
end

local function UpdateBorder(owner)
  if not owner then return end

  if not owner.Border then
    local parent = owner:GetParent()
    if not parent or not parent.CreateTexture then return end
    local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    b:SetPoint("TOPLEFT", owner, "TOPLEFT", -1, 1)
    b:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 1, -1)

    b:SetBackdrop({
      edgeFile = SOLID_TEXTURE,
      edgeSize = 2
    })
    b:SetBackdropBorderColor(0, 0, 0, 1)
    owner.Border = b
  end

  if owner.GetTexCoord then
    SetIconZoom(owner)
  elseif owner.Icon then
    SetIconZoom(owner.Icon)
  end
end

local function GetClassColors(class)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then
    return c.r, c.g, c.b
  end
end

local function GetArenaSize()
  local numOpponentSpecs = GetNumArenaOpponentSpecs()
  if numOpponentSpecs and numOpponentSpecs > 0 then
    return numOpponentSpecs
  end

  local numOpponents = GetNumArenaOpponents()
  if numOpponents and numOpponents > 0 then
    return numOpponents
  end

  return 0
end

local function GetOpponentSpecAndClass(index)
  local specID = GetArenaOpponentSpec(index)
  if specID and specID > 0 then
    local _, _, _, specIcon, _, class = GetSpecializationInfoByID(specID)
    return specIcon, class
  end
end

local function IsMatchEngaged()
  return C_PvP.GetActiveMatchState() == Enum.PvPMatchState.Engaged
end

local function IsInArena()
  return C_PvP.IsMatchConsideredArena() and (C_PvP.IsMatchActive() or C_PvP.IsMatchComplete())
end

local function IsInPrep()
  return IsInArena() and not IsMatchEngaged() and not C_PvP.IsMatchComplete() and not MV_ArenaTestMode
end

local function IsArenaInProgress()
  return IsInArena() and IsMatchEngaged()
end

local function IsUnit(index)
  local specID = GetArenaOpponentSpec(index)
  return specID and specID > 0
end

local function SetArenaFrame(index)
  local unit = "arena" .. index
  local unitFrame = _G[blizzFrame .. "Member" .. index]
  local name = baseName .. index
  local arenaFrame = MV.CreateUnitFrame({
    name = name,
    unit = unit,
    unitKey = "arena",
    point = { "CENTER", UIParent, "CENTER", MV.FrameX + (index - 1) * MV.FrameSpace, 0 },
    size = { MV.SizeX, MV.SizeYAlt },
    maxAuras = MAX_AURAS,
    iconSize = MV.DefaultSize,
    pvpIcons = true,
  })
  arenaFrame:SetFrameLevel(10)
  local function SetAnchor(type, point, relative, x, y, sizeX, sizeY)
    local anchor = CreateFrame("Frame", baseName .. type, arenaFrame)
    anchor:SetSize(sizeX or 1, sizeY or 1)
    anchor:SetPoint(point, arenaFrame, relative, x, y)
    return anchor
  end
  arenaFrame.statusIconAnchor = SetAnchor("StatusIcon", "CENTER", "CENTER", 0, 0, 36, 36)
  arenaFrame.statusIconAnchor:SetFrameLevel(arenaFrame:GetFrameLevel() + 5)

  local function IsInStealth(idx)
    if not IsUnit(idx) then
      return false
    end

    return not ArenaUtil.UnitExists(unit) and IsArenaInProgress()
  end

  local function SetClassColor(alpha)
    local _, class = GetOpponentSpecAndClass(index)
    if class then
      local r, g, b = GetClassColors(class)
      arenaFrame.health:SetStatusBarColor(r, g, b, alpha or regAlpha)
      return true
    end
    return false
  end

  local function SetStatusIcon()
    if not arenaFrame.statusIconAnchor.Icon then
      arenaFrame.statusIconAnchor.Icon = arenaFrame.statusIconAnchor:CreateTexture(nil, "OVERLAY")
      arenaFrame.statusIconAnchor.Icon:SetAllPoints(arenaFrame.statusIconAnchor)
    end

    local icon = arenaFrame.statusIconAnchor.Icon
    if not icon then
      return false
    end

    local texture

    if IsInPrep() then
      texture = GetOpponentSpecAndClass(index)
    elseif IsArenaInProgress() and IsInStealth(index) then
      texture = stealthIcon
    else
      texture = nil
    end

    if texture then
      icon:SetTexture(texture)
      UpdateBorder(arenaFrame.statusIconAnchor)
      if arenaFrame.statusIconAnchor.Border then
        arenaFrame.statusIconAnchor.Border:SetFrameLevel(arenaFrame.statusIconAnchor:GetFrameLevel())
        arenaFrame.statusIconAnchor.Border:Show()
      end
      return true
    else
      icon:SetTexture(nil)
      if arenaFrame.statusIconAnchor.Border then
        arenaFrame.statusIconAnchor.Border:Hide()
      end
      return false
    end
  end

  local function UpdateVisibility()
    if MV_ArenaTestMode then
      arenaFrame:Show()
      return
    end
    if not IsInArena() and not InCombatLockdown() then
      arenaFrame:Hide()
      return
    end

    local hasIcon = SetStatusIcon()
    arenaFrame.statusIconAnchor:SetShown(hasIcon)

    if hasIcon then
      SetClassColor(altAlpha)
    else
      SetClassColor(regAlpha)
    end

    if InCombatLockdown() then return end
    arenaFrame:SetShown(IsUnit(index))
  end
  function arenaFrame:UpdateVisibility() UpdateVisibility() end

  local function SetMemberFrame(i)
    local addonFrame = _G[baseName .. i]
    if addonFrame then
      addonFrame:UpdateVisibility()
    end
  end

  local function SetFrames()
    for i = 1, GetArenaSize() do
      SetMemberFrame(i)
    end
  end

  local function HookDR(frame)
    local member = unitFrame
    if member and member.SpellDiminishStatusTray and not member.SpellDiminishStatusTray.MV_Hooked then
      local tray = member.SpellDiminishStatusTray
      tray.MV_Hooked = true
      hooksecurefunc(member.SpellDiminishStatusTray, "TryUpdateOrAddTrayItem", function(self)
        MV.UpdateBlizzardDRBackup(self, frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "UpdateOrAddTrayItem", function(self)
        MV.UpdateBlizzardDRBackup(self, frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "RefreshTrayLayout", function(self)
        MV.UpdateBlizzardDRBackup(self, frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "AddNewItemToTray", function(self)
        MV.UpdateBlizzardDRBackup(self, frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "RemoveCategoryFromOrder", function()
        MV.ResetTray(frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "OnTrayItemCooldownDone", function()
        MV.ResetTray(frame)
      end)
    end
  end

  -- SET DEFAULTS
  arenaFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  arenaFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  -- APPROXIMATE RANGE CHECKER
  arenaFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED") -- Range
  arenaFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  arenaFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  -- UNIT INFORMATION
  arenaFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  arenaFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  arenaFrame:RegisterUnitEvent("UNIT_AURA", unit)

  --HIGHLIGHT
  arenaFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- Target highlight

  --CHECK STATE CHANGES
  arenaFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- No payload, must scan all
  arenaFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")             -- Start/End of the game
  arenaFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
  arenaFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

  --CHECK ARENA UPDATES
  arenaFrame:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit) -- Triggers for arenaX
  arenaFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")              -- Unseen = left.

  --CHECK TRINKET UPDATES
  arenaFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE") -- Trinket
  arenaFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")




  arenaFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      MV_ArenaTestMode = false
      UpdateVisibility()
      MV.UpdateHealthBar(arenaFrame)
      MV.UpdateTargetHighlight(arenaFrame, MV_ArenaTestMode)
      MV.UpdateAuras(arenaFrame)
      MV.ResetDR(arenaFrame)
      MV.ResetAndRequestTrinket(arenaFrame)
    end
    if not IsInArena() then return end
    if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
      MV.UpdateHealthBar(arenaFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.SetRangeAlpha(arenaFrame)
    elseif event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(arenaFrame, MV_ArenaTestMode)
    elseif event == "PVP_MATCH_STATE_CHANGED"
        or event == "GROUP_ROSTER_UPDATE"
        or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS"
        or event == "UPDATE_BATTLEFIELD_SCORE"
    then
      SetFrames()
    elseif event == "ARENA_OPPONENT_UPDATE"
        or event == "UNIT_OTHER_PARTY_CHANGED"
    then
      if arg1 == unit then
        SetMemberFrame(index)
        MV.ResetAndRequestTrinket(arenaFrame)
        HookDR(arenaFrame)
      end
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(arenaFrame)
    elseif event == "ARENA_COOLDOWNS_UPDATE" or event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then -- These are the only two needed: Trinket
      if arg1 == unit then
        MV.UpdateTrinket(arenaFrame)
      end
    end
  end)
end


for i = 1, 3 do
  SetArenaFrame(i)
end
