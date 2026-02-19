local _, MV = ...
local baseName = "MV_ArenaFrame"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MV_ArenaTestMode = false

local blizzFrame = "CompactArenaFrame"

local altAlpha = MV.OtherAlpha
local regAlpha = MV.RegAlpha

local MAX_AURAS = 4

local c1, c2, c3, c4 = 0.1, 0.9, 0.1, 0.9 -- Default zoom coords
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
  return IsInArena() and not IsMatchEngaged() and not C_PvP.IsMatchComplete() and not MVPF_ArenaTestMode
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
  local f = MV.CreateUnitFrame({
    name = name,
    unit = unit,
    point = { "CENTER", UIParent, "CENTER", 280 + (index - 1) * 55, 0 },
    size = { 50, 210 },
    maxAuras = MAX_AURAS,
    iconSize = MV.DefaultSize,
    pvpIcons = true,
  })
  f:SetFrameLevel(10) -- base level for MVPF frame
  local function SetAnchor(type, point, relative, x, y, sizeX, sizeY)
    local a = CreateFrame("Frame", baseName .. type, f)
    a:SetSize(sizeX or 1, sizeY or 1)
    a:SetPoint(point, f, relative, x, y)
    return a
  end
  f.statusIconAnchor = SetAnchor("StatusIcon", "CENTER", "CENTER", 0, 0, 36, 36)
  f.statusIconAnchor:SetFrameLevel(f:GetFrameLevel() + 5)
  local function IsInStealth(idx)
    if not IsUnit(idx) then
      return false
    end

    return not ArenaUtil.UnitExists(unit) and IsArenaInProgress()
  end

  local function SetClassColor(alpha)
    local _, c = GetOpponentSpecAndClass(index)
    if c then
      local r, g, b = GetClassColors(c)
      f.health:SetStatusBarColor(r, g, b, alpha or regAlpha)
      return true
    end
    return false
  end

  local function SetStatusIcon()
    if not f.statusIconAnchor.Icon then
      f.statusIconAnchor.Icon = f.statusIconAnchor:CreateTexture(nil, "OVERLAY")
      f.statusIconAnchor.Icon:SetAllPoints(f.statusIconAnchor)
    end

    local icon = f.statusIconAnchor.Icon
    if not icon then
      return false
    end

    local tex

    if IsInPrep() then
      tex = GetOpponentSpecAndClass(index)
    elseif IsArenaInProgress() and IsInStealth(index) then
      tex = stealthIcon
    else
      tex = nil
    end

    if tex then
      icon:SetTexture(tex)
      UpdateBorder(f.statusIconAnchor)
      if f.statusIconAnchor.Border then
        f.statusIconAnchor.Border:SetFrameLevel(f.statusIconAnchor:GetFrameLevel())
        f.statusIconAnchor.Border:Show()
      end
      return true
    else
      icon:SetTexture(nil)
      if f.statusIconAnchor.Border then
        f.statusIconAnchor.Border:Hide()
      end
      return false
    end
  end

  local function UpdateVisibility()
    if MV_ArenaTestMode then
      f:Show()
      return
    end
    if not IsInArena() and not InCombatLockdown() then
      f:Hide()
      return
    end

    local hasIcon = SetStatusIcon()
    f.statusIconAnchor:SetShown(hasIcon)

    if hasIcon then
      SetClassColor(altAlpha)
    else
      SetClassColor(regAlpha)
    end

    if InCombatLockdown() then return end
    f:SetShown(IsUnit(index))
  end
  function f:UpdateVisibility() UpdateVisibility() end

  local function SetMemberFrame(i)
    local mv = _G[baseName .. i]
    if mv then
      mv:UpdateVisibility()
    end
  end

  local function SetFrames()
    for i = 1, GetArenaSize() do
      SetMemberFrame(i)
    end
  end

  local function HookDR(frame)
    local member = unitFrame
    if member and member.SpellDiminishStatusTray and not member.SpellDiminishStatusTray.MVPF_Hooked then
      local tray = member.SpellDiminishStatusTray
      tray.MVPF_Hooked = true
      hooksecurefunc(member.SpellDiminishStatusTray, "TryUpdateOrAddTrayItem", function(self)
        print("Trigger 1")
        MV.UpdateBlizzardDRBackup(self, frame.pvpContainer, MV.DefaultSize)
      end)
      local _, children = pcall(function() return { tray:GetChildren() } end)
      pcall(function()
        for _, child in ipairs(children) do
          hooksecurefunc(child, "SetCategoryInfo", function(self)
            print("Trigger 2")
            MV.UpdateBlizzardDR(self, frame.pvpContainer, MV.DefaultSize)
          end)
        end
      end)
      pcall(function()
        for _, child in ipairs(children) do
          hooksecurefunc(child, "Reset", function(self)
            print("Trigger 3")
            MV.ResetBlizzardButton(self)
          end)
        end
      end)
    end
  end

  -- SET DEFAULTS
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  -- APPROXIMATE RANGE CHECKER
  f:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED") -- Range
  f:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  -- UNIT INFORMATION
  f:RegisterUnitEvent("UNIT_HEALTH", unit)
  f:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  f:RegisterUnitEvent("UNIT_AURA", unit)

  --HIGHLIGHT
  f:RegisterEvent("PLAYER_TARGET_CHANGED") -- Target highlight

  --CHECK STATE CHANGES
  f:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- No payload, must scan all
  f:RegisterEvent("PVP_MATCH_STATE_CHANGED")             -- Start/End of the game
  f:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
  f:RegisterEvent("GROUP_ROSTER_UPDATE")

  --CHECK ARENA UPDATES
  f:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit) -- Triggers for arenaX
  f:RegisterEvent("ARENA_OPPONENT_UPDATE")              -- Unseen = left.

  --CHECK TRINKET UPDATES
  f:RegisterEvent("ARENA_COOLDOWNS_UPDATE") -- Trinket
  f:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")




  f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      MV_ArenaTestMode = false
      UpdateVisibility()
      MV.UpdateHealthBar(f)
      MV.UpdateTargetHighlight(f, MV_ArenaTestMode)
      MV.UpdateAuras(f)
      MV.ResetDR(f)
      MV.ResetAndRequestTrinket(f)
    end
    if not IsInArena() then return end
    if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
      MV.UpdateHealthBar(f)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MV.SetRangeAlpha(f)
    elseif event == "PLAYER_TARGET_CHANGED" then
      MV.UpdateTargetHighlight(f, MV_ArenaTestMode)
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
        MV.ResetAndRequestTrinket(f)
        HookDR(f)
      end
    elseif event == "UNIT_AURA" then
      MV.UpdateAuras(f)
    elseif event == "ARENA_COOLDOWNS_UPDATE" or event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then -- These are the only two needed: Trinket
      if arg1 == unit then
        MV.UpdateTrinket(f)
      end
    end
  end)
end


for i = 1, 3 do
  SetArenaFrame(i)
end
