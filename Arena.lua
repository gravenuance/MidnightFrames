local _, MVPF = ...
local baseName = "MVPF_ArenaFrame"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MVPF_ArenaTestMode = false

local blizzFrame = "CompactArenaFrame"
local CompactArenaFrame = _G[blizzFrame]
local CompactArenaFrameTitle = _G[blizzFrame .. "Title"]

local altAlpha = MVPF_Common.OtherAlpha
local regAlpha = MVPF_Common.RegAlpha

local DEFAULT_SIZE = 32

local MAX_AURAS = 4

local c1, c2, c3, c4 = 0.1, 0.9, 0.1, 0.9 -- Default zoom coords
local stealthIcon = 132320

local arenaKeepList = {
  DebuffFrame = true,
  CcRemoverFrame = true,
  SpellDiminishStatusTray = true,
}

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
  local unitStealthFrame = CompactArenaFrame and CompactArenaFrame["StealthedUnitFrame" .. index]
  local name = baseName .. index
  local f, auraContainer, health, pvpContainer = MVPF_Common.CreateUnitFrame({
    name = name,
    unit = unit,
    point = { "CENTER", UIParent, "CENTER", 280 + (index - 1) * 55, 0 },
    size = { 50, 210 },
    maxAuras = MAX_AURAS,
    iconSize = DEFAULT_SIZE,
    pvpIcons = true,
  })
  f:SetFrameLevel(10) -- base level for MVPF frame
  f.pvpContainer = pvpContainer
  local defaultR, defaultG, defaultB
  local DRCategories = {}
  local function SetAnchor(type, point, relative, x, y, sizeX, sizeY)
    local a = CreateFrame("Frame", baseName .. type, f)
    a:SetSize(sizeX or 1, sizeY or 1)
    a:SetPoint(point, f, relative, x, y)
    return a
  end

  --f.trinketAnchor = SetAnchor("Trinket", "TOP", "BOTTOM", 0, -30)
  --f.debuffAnchor = SetAnchor("Debuff", "BOTTOM", "BOTTOM", 0, 30)
  f.statusIconAnchor = SetAnchor("StatusIcon", "CENTER", "CENTER", 0, 0, 36, 36)
  --f.diminishAnchor = SetAnchor("Diminish", "BOTTOM", "BOTTOM", 0, 90)
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
      health:SetStatusBarColor(r, g, b, alpha or regAlpha)
      defaultR, defaultG, defaultB = r, g, b
      return true
    end
    return false
  end

  local function UpdateHealth()
    MVPF_Common.UpdateHealthBar(health, unit)
    if not health or not defaultR then return end
    if MVPF_Common.CheckMultiSpellRange(unit) then
      health:SetStatusBarColor(defaultR, defaultG, defaultB, MVPF_Common.RegAlpha)
    else
      health:SetStatusBarColor(defaultR, defaultG, defaultB, MVPF_Common.OtherAlpha)
    end
  end

  local function UpdateTargetHighlight()
    MVPF_Common.UpdateTargetHighlight(f, unit, "MVPF_ArenaTestMode")
  end

  local function UpdateAuras()
    if MVPF_ArenaTestMode then return end
    if not UnitExists(unit) then
      MVPF_Common.UpdateAuras(auraContainer, unit, {}, 0)
      return
    end
    local filters = {}
    local cfg = MVPF.GetUnitFilters("arena")
    for filter, enabled in pairs(cfg) do
      if enabled then
        table.insert(filters, filter)
      end
    end

    MVPF_Common.UpdateAuras(
      auraContainer,
      unit,
      filters,
      MAX_AURAS
    )
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
    if MVPF_ArenaTestMode then
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
        MVPF_Common.UpdateBlizzardDRBackup(self, frame.pvpContainer, DEFAULT_SIZE)
      end)
      local _, children = pcall(function() return { tray:GetChildren() } end)
      pcall(function()
        for _, child in ipairs(children) do
          hooksecurefunc(child, "SetCategoryInfo", function(self)
            MVPF_Common.UpdateBlizzardDR(self, frame.pvpContainer, DEFAULT_SIZE)
          end)
        end
      end)
      pcall(function()
        for _, child in ipairs(children) do
          hooksecurefunc(child, "Reset", function(self)
            MVPF_Common.ResetBlizzardButton(self)
          end)
        end
      end)
    end
  end

  f:RegisterEvent("PLAYER_ENTERING_WORLD") -- Reset values
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  f:RegisterEvent("UNIT_HEALTH")
  f:RegisterEvent("UNIT_MAXHEALTH")
  f:RegisterEvent("UNIT_AURA")

  f:RegisterEvent("PLAYER_TARGET_CHANGED")               -- Target highlight

  f:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS") -- No payload, must scan all
  f:RegisterEvent("PVP_MATCH_STATE_CHANGED")             -- Start/End of the game
  f:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
  f:RegisterEvent("GROUP_ROSTER_UPDATE")

  f:RegisterEvent("UNIT_OTHER_PARTY_CHANGED") -- Triggers for arenaX
  f:RegisterEvent("ARENA_OPPONENT_UPDATE")    -- Unseen = left.

  f:RegisterEvent("ARENA_COOLDOWNS_UPDATE")   -- Trinket
  f:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")

  f:RegisterEvent("UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED") -- DR

  f:RegisterEvent("LOSS_OF_CONTROL_UPDATE")                     -- Big Debuff
  f:RegisterEvent("LOSS_OF_CONTROL_ADDED")

  f:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED") -- Range
  f:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
  f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")


  f:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      MVPF_ArenaTestMode = false
      UpdateHealth()
      UpdateVisibility()
      UpdateTargetHighlight()
      UpdateAuras()
      MVPF_Common.ResetDR(pvpContainer)
      MVPF_Common.ResetAndRequestTrinket(pvpContainer, unit)
    end
    if not IsInArena() then return end
    if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
      if arg1 == unit then
        UpdateHealth()
      end
    elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "SPELL_RANGE_CHECK_UPDATE" then
      UpdateHealth()
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_SOFT_INTERACT_CHANGED" then
      UpdateTargetHighlight()
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
        MVPF_Common.ResetAndRequestTrinket(pvpContainer, unit)
        HookDR(f)
      end
    elseif event == "UNIT_AURA" and arg1 == unit then
      --print("MVPF Arena:", event, "for", unit)
      UpdateAuras()
    elseif event == "UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED" -- Only one needed for DR
    then
      if arg1 == unit then
        --print("MVPF Arena:", event, "for", unit)
        --MVPF_Common.UpdateDR(arg2, pvpContainer, DRCategories)
      end
    elseif event == "ARENA_COOLDOWNS_UPDATE" or event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then -- These are the only two needed: Trinket
      if arg1 == unit then
        --print("MVPF Arena:", event, "for", unit)
        MVPF_Common.UpdateTrinket(pvpContainer, unit)
      end
      --[[ elseif event == "LOSS_OF_CONTROL_UPDATE" or event == "LOSS_OF_CONTROL_ADDED" -- Only two needed for the Debuff
    then
      if arg1 == unit then

      end ]]
    end
  end)
end


for i = 1, 3 do
  SetArenaFrame(i)
end
