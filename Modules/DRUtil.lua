local _, MF = ...

local ENEMY_DR_RESET_TIME = 16
local ENEMY_DR_ORDER = {
  [2] = "stun",
  [4] = "incap",
  [5] = "disorient",
  [6] = "silence",
  [7] = "disarm",
  [0] = "root",
}

MF.DRFallback = true
-- 1 trinket slot + 1 per tracked DR category; can be overridden via params.otherSlots
MF.DRSize = 7
MF.DRStartIndex = 2

local CATEGORY_ICON = {
  stun = "Interface\\Icons\\Ability_Rogue_CheapShot",
  incap = "Interface\\Icons\\Ability_Rogue_Sap",
  disorient = "Interface\\Icons\\Spell_Shadow_MindSteal",
  silence = "Interface\\Icons\\Ability_Rogue_Garrote",
  disarm = "Interface\\Icons\\Ability_Warrior_Disarm",
  root = "Interface\\Icons\\Spell_Nature_StrangleVines",
}

local function SetSafeButton(candidate, icon, immunity, startTime)
  if candidate.icon and icon then
    candidate.icon:SetTexture(icon)
  end
  if candidate.border then
    if immunity then
      candidate.border:SetVertexColor(1, 0, 0, 1)
    else
      candidate.border:SetVertexColor(0, 1, 0, 1)
    end
  end
  local ok = MF.SetCooldown(candidate.cooldown, startTime, 16)
  if ok then
    MF.SetShowCountdownNumbers(candidate.cooldown, true)
  end
  candidate:Show()
end

local function CheckTrayButton(button, frame)
  local iconTexture = button.Icon and button.Icon:GetTexture()
  local cooldown = button.Cooldown
  if not cooldown.MF_Hooked then
    cooldown.MF_Hooked = true
    cooldown:HookScript("OnHide", function() if button.MF_Button then MF.ResetButton(button.MF_Button) end end)
  end
  local startTime = GetTime()
  local candidate
  if button.MF_Button then
    candidate = button.MF_Button
    -- reapplied before the window expired = stacked hit, not a fresh one
    local wasActive = candidate.lastStartTime and (candidate.lastStartTime + ENEMY_DR_RESET_TIME) > startTime
    candidate.lastStartTime = startTime
    SetSafeButton(candidate, iconTexture, wasActive, startTime)
    return
  end
  for i = MF.DRStartIndex, #frame.otherContainer.icons do
    candidate = frame.otherContainer.icons and frame.otherContainer.icons[i]
    if candidate and not candidate.categoryTable then
      candidate.categoryTable = button
      candidate.lastStartTime = startTime
      button.MF_Button = candidate
      SetSafeButton(candidate, iconTexture, false, startTime)
      return
    end
  end
end

function MF.TryAndUpdateDRStateFromTray(tray, frame)
  if MF.IsNil(tray) or not frame then
    return
  end
  local ok, children = MF.GetLayoutChildren(tray)
  if not ok then return end
  pcall(function()
    for _, child in ipairs(children) do
      if child:GetCategory() then CheckTrayButton(child, frame) end
    end
  end)
end

local function SetButtonIcon(button, icon, showCountdown, isImmune)
  if button.icon and icon then
    button.icon:SetTexture(icon)
    if button.border and isImmune then
      button.border:SetVertexColor(1, 0, 0, 1)
    else
      button.border:SetVertexColor(0, 1, 0, 1)
    end
  end

  if button.duration and button.duration > 0 then
    local ok = MF.SetCooldown(button.cooldown, button.startTime, button.duration)
    if ok then
      MF.SetShowCountdownNumbers(button.cooldown, showCountdown)
      button:Show()
    end
  end
end

local function SetButtons(frame)
  if not frame then
    return
  end

  local now = GetTime()

  for category, categoryTable in pairs(frame.categories) do
    local startTime     = categoryTable.startTime
    local duration      = categoryTable.duration
    local isImmune      = categoryTable.isImmune
    local showCountdown = categoryTable.showCountdown
    local icon          = categoryTable.icon
    local button        = categoryTable.button

    if not MF.IsNumber(startTime) and not MF.IsNumber(duration) then
      if button then
        button:Hide()
        button.categoryTable = nil
      end
      frame.categories[category] = nil
    elseif startTime + duration <= now then
      if button then
        button:Hide()
        button.categoryTable = nil
      end
      frame.categories[category] = nil
    else
      if button then
        button.startTime = startTime
        button.duration = duration
        SetButtonIcon(button, icon, showCountdown, isImmune)
      else
        for i = MF.DRStartIndex, #frame.otherContainer.icons do
          local candidate = frame.otherContainer.icons[i]
          if not candidate.categoryTable then
            button = candidate
            categoryTable.button = button
            button.categoryTable = categoryTable
            button.startTime = startTime
            button.duration = duration
            SetButtonIcon(button, icon, showCountdown, isImmune)
            break
          end
        end
      end
    end
  end
end

function MF.ResetButton(button)
  if button and button.categoryTable then
    if button.categoryTable.MF_Button then
      button.categoryTable.MF_Button = nil
    end
    button.categoryTable = nil
    button:Hide()
  end
end

function MF.ResetDR(frame)
  if MF.IsTable(frame.categories) then
    wipe(frame.categories)
  end
  if frame.otherContainer then
    for i = MF.DRStartIndex, #frame.otherContainer.icons do
      local candidate = frame.otherContainer.icons[i]
      MF.ResetButton(candidate)
    end
  end
end

local function GetAndInterpretField(table, field)
  local ok, result = MF.GetField(table, field)
  if ok then
    return result
  end
  return nil
end

local function IsTracked(category)
  local result = GetAndInterpretField(ENEMY_DR_ORDER, category)
  if not MF.IsNil(result) then return result end
  return false
end

local function SanitizeBoolean(value, default)
  if MF.IsSecretSafe(value) then
    return default
  end
  return value
end

function MF.TryAndUpdateDRStateFromEvent(frame, trackerInfo)
  if not MF.IsTable(trackerInfo) and not MF.IsUserData(trackerInfo) then
    return
  end
  if not frame or not frame.unit then return end
  local category = GetAndInterpretField(trackerInfo, "category")
  local ok = MF.IsNumber(category)
  if not ok then
    return
  end
  if MF.IsSecretSafe(category) then return end
  category = IsTracked(category)
  if not MF.IsString(category) then return end
  local startTime = GetAndInterpretField(trackerInfo, "startTime")
  local duration = GetAndInterpretField(trackerInfo, "duration")
  local isImmune = GetAndInterpretField(trackerInfo, "isImmune")
  local showCountdown = GetAndInterpretField(trackerInfo, "showCountdown")

  if MF.IsNumber(startTime) and MF.IsNumber(duration)
      and not MF.IsSecretSafe(startTime) and not MF.IsSecretSafe(duration) then
    frame.categories[category] = {
      duration = duration,
      startTime = startTime,
      isImmune = SanitizeBoolean(isImmune, false),
      showCountdown = SanitizeBoolean(showCountdown, true),
      icon = CATEGORY_ICON[category]
    }
  end
  SetButtons(frame)
end

local function SetDRInfoFromLOC(frame, trackerInfo)
  if not MF.IsTable(trackerInfo) and not MF.IsUserData(trackerInfo) then
    return
  end
  local displayType = GetAndInterpretField(trackerInfo, "displayType")
  if not MF.IsNumber(displayType) or displayType ~= 2 then
    return
  end
  local category = GetAndInterpretField(trackerInfo, "locType")
  if MF.IsString(category) and issecretvalue(category) then
    return
  end
  local ok = MF.IsString(category)
  if not ok then
    return
  end

  local startTime = GetTime()
  local duration = ENEMY_DR_RESET_TIME
  local iconTexture = GetAndInterpretField(trackerInfo, "iconTexture")

  local categoriesEntry = frame.categories[category]
  if MF.IsTable(categoriesEntry) or MF.IsUserData(categoriesEntry) then
    if categoriesEntry.startTime and categoriesEntry.duration then
      local existingExpiration = categoriesEntry.startTime + categoriesEntry.duration
      if existingExpiration > startTime then
        frame.categories[category].isImmune = true
      end
    end
  else
    frame.categories[category] = {
      icon = iconTexture,
      isImmune = false,
      showCountdown = true,
    }
  end
  frame.categories[category].duration = duration
  frame.categories[category].startTime = startTime
  SetButtons(frame)
end

function MF.TryAndUpdateDRStateFromLOC(frame)
  if not frame or not frame.unit then return end
  local ok, count = MF.GetActiveLossOfControlDataCountByUnit(frame.unit)
  if not ok then
    return
  end
  if MF.IsNumber(count) and count > 0 then
    for index = 1, count do
      local ok2, trackerInfo = MF.GetActiveLossOfControlDataByUnit(frame.unit, index)
      if ok2 then
        SetDRInfoFromLOC(frame, trackerInfo)
      end
    end
  end
end

function MF.HideButton(button)
  if button then
    button:Hide()
    if button.categoryTable then
      button.categoryTable.startTime = nil
      button.categoryTable.duration = nil
      button.categoryTable.button = nil
      button.categoryTable = nil
    end
  end
end
