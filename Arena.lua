local _, MF = ...
local baseName = "MF_Arena"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MF_ArenaTestMode = false

local blizzFrame = "CompactArenaFrame"

local altAlpha = MF.OtherAlpha
local regAlpha = MF.RegAlpha

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
  if not MF.IsString(class) or MF.IsSecretSafe(class) then
    return
  end
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then
    return c.r, c.g, c.b
  end
end

local function SetArenaFrame(index)
  local unit = "arena" .. index
  local unitFrame = _G[blizzFrame .. "Member" .. index]
  local name = baseName .. index
  local arenaFrame = MF.CreateUnitFrame({
    name = name,
    unit = unit,
    unitKey = "arena",
    point = { "CENTER", UIParent, "CENTER", MF.RosterFrameOffsetX + (index - 1) * MF.RosterFrameSpacing, 0 },
    size = { MF.SizeX, MF.GroupFrameHeight },
    maxAuras = MAX_AURAS,
    iconSize = MF.DefaultSize,
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

  local function SetClassColor(alpha)
    local _, class = MF.GetOpponentSpecAndClass(index)
    if class then
      local r, g, b = GetClassColors(class)
      if r then
        MF.ApplyHealthGradient(arenaFrame.health, r, g, b)
        MF.TintHealthLiquid(arenaFrame.healthLiquid, r, g, b)
        local a = alpha or regAlpha
        arenaFrame.health:SetAlpha(a)
        arenaFrame.healthLiquid:SetAlpha(a)
        return true
      end
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

    if MF.IsInPrep() then
      texture = MF.GetOpponentSpecAndClass(index)
    elseif MF.IsArenaInProgress() and MF.IsInStealth(index, unit) then
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
    if MF_ArenaTestMode then
      if InCombatLockdown() then return end
      arenaFrame:Show()
      return
    end
    if not MF.IsInArena() and not InCombatLockdown() then
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
    arenaFrame:SetShown(MF.IsUnit(index))
  end
  function arenaFrame:UpdateVisibility() UpdateVisibility() end

  local function SetMemberFrame(i)
    local addonFrame = _G[baseName .. i]
    if addonFrame then
      addonFrame:UpdateVisibility()
    end
  end

  local function SetFrames()
    for i = 1, MF.GetArenaSize() do
      SetMemberFrame(i)
    end
  end

  local function HookDR(frame)
    if not MF.DRFallback then return end

    local member = unitFrame
    if member and member.SpellDiminishStatusTray and not member.SpellDiminishStatusTray.MF_Hooked then
      local tray = member.SpellDiminishStatusTray
      tray.MF_Hooked = true
      hooksecurefunc(member.SpellDiminishStatusTray, "TryUpdateOrAddTrayItem", function()
        MF.TryAndUpdateDRStateFromTray(member.SpellDiminishStatusTray, frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "UpdateOrAddTrayItem", function()
        MF.TryAndUpdateDRStateFromTray(member.SpellDiminishStatusTray, frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "RefreshTrayLayout", function()
        MF.TryAndUpdateDRStateFromTray(member.SpellDiminishStatusTray, frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "AddNewItemToTray", function()
        MF.TryAndUpdateDRStateFromTray(member.SpellDiminishStatusTray, frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "RemoveCategoryFromOrder", function()
        MF.ResetDR(frame)
      end)
      hooksecurefunc(member.SpellDiminishStatusTray, "OnTrayItemCooldownDone", function()
        MF.ResetDR(frame)
      end)
    end
  end

  arenaFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  arenaFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  arenaFrame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
  arenaFrame:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  arenaFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

  arenaFrame:RegisterUnitEvent("UNIT_HEALTH", unit)
  arenaFrame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
  arenaFrame:RegisterUnitEvent("UNIT_AURA", unit)
  arenaFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

  arenaFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

  -- no payload, so we rescan everyone
  arenaFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
  arenaFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
  arenaFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
  arenaFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

  -- fires with no payload when an opponent leaves
  arenaFrame:RegisterUnitEvent("UNIT_OTHER_PARTY_CHANGED", unit)
  arenaFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")

  arenaFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
  arenaFrame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")

  arenaFrame:RegisterUnitEvent("UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED", unit)

  arenaFrame:RegisterEvent("RAID_TARGET_UPDATE")

  arenaFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
  arenaFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
  arenaFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
  arenaFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
  arenaFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
  arenaFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
  arenaFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", unit)
  arenaFrame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit)

  arenaFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      MF_ArenaTestMode = false
      UpdateVisibility()
      MF.UpdateHealthBar(arenaFrame)
      MF.UpdateAbsorbBar(arenaFrame)
      MF.UpdateAuras(arenaFrame)
      MF.UpdateTrinket(arenaFrame)
      MF.UpdateTargetHighlight(arenaFrame, MF_ArenaTestMode)
      MF.ResetDR(arenaFrame)
      MF.SetRangeAlpha(arenaFrame)
      MF.UpdateRaidMark(arenaFrame)
      MF.UpdateCastIndicator(arenaFrame)
      HookDR(arenaFrame)
    end
    if not MF.IsInArena() then return end
    if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
      MF.UpdateHealthBar(arenaFrame)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
      MF.UpdateAbsorbBar(arenaFrame)
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      MF.SetRangeAlpha(arenaFrame)
    elseif event == "PLAYER_TARGET_CHANGED" then
      MF.UpdateTargetHighlight(arenaFrame, MF_ArenaTestMode)
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
        MF.UpdateTrinket(arenaFrame, true)
        MF.ResetDR(arenaFrame)
        MF.UpdateRaidMark(arenaFrame)
        MF.UpdateCastIndicator(arenaFrame)
        HookDR(arenaFrame)
      end
    elseif event == "UNIT_AURA" then
      MF.UpdateAuras(arenaFrame)
    elseif event == "ARENA_COOLDOWNS_UPDATE" or event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then
      MF.UpdateTrinket(arenaFrame, true)
    elseif event == "UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED" then
      if not MF.DRFallback then
        MF.TryAndUpdateDRStateFromEvent(arenaFrame, arg2)
      end
    elseif event == "RAID_TARGET_UPDATE" then
      MF.UpdateRaidMark(arenaFrame)
    elseif event == "UNIT_SPELLCAST_START"
        or event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_CHANNEL_START"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_INTERRUPTIBLE"
        or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
    then
      MF.UpdateCastIndicator(arenaFrame)
    end
  end)
end


for i = 1, 3 do
  SetArenaFrame(i)
end
