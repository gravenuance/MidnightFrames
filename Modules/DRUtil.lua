local _, MV = ...

local ENEMY_DR_RESET_TIME = 16
local ENEMY_DR_ORDER = {
  [2] = "stun",
  [4] = "incap",
  [5] = "disorient",
  [6] = "silence",
  [7] = "disarm",
  [0] = "root",
}

MV.DRFallback = true
MV.DRSize = 5
MV.DRStartIndex = 2

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
  local ok, err = MV.CallExternalFunction({
    namespace = candidate.cooldown,
    functionName = "SetCooldown",
    args = { candidate.cooldown, startTime, 16 },
    argumentValidators = { MV.IsTable, MV.IsNumber, MV.IsNumber }
  })
  if ok then
    MV.CallExternalFunction({
      namespace = candidate.cooldown,
      functionName = "SetShowCountdownNumbers",
      args = { candidate.cooldown, true },
      argumentValidators = { MV.IsTable, MV.IsBoolean }
    })
  end
  candidate:Show()
end

local function CheckTrayButton(button, frame)
  local iconTexture = button.Icon and button.Icon:GetTexture()
  local cooldown = button.Cooldown
  if not cooldown.MV_Hooked then
    cooldown.MV_Hooked = true
    cooldown:HookScript("OnHide", function() if button.MV_Button then MV.ResetButton(button.MV_Button) end end)
  end
  local startTime = GetTime()
  local candidate
  if button.MV_Button then
    candidate = button.MV_Button
    SetSafeButton(candidate, iconTexture, true, startTime)
    return
  end
  for i = MV.DRStartIndex, MV.DRSize do
    candidate = frame.otherContainer.icons and frame.otherContainer.icons[i]
    if candidate and not candidate.categoryTable then
      candidate.categoryTable = button
      button.MV_Button = candidate
      SetSafeButton(candidate, iconTexture, false, startTime)
      return
    end
  end
end

function MV.TryAndUpdateDRStateFromTray(tray, frame)
  if MV.IsNil(tray) or not frame then
    return
  end
  local ok, children = MV.CallExternalFunction(
    {
      namespace = tray,
      args = { tray },
      functionName = "GetLayoutChildren",
    }
  )
  if not ok then return end
  pcall(function()
    for _, child in ipairs(children) do
      if child:GetCategory() then CheckTrayButton(child, frame) end
    end
  end)
end

local function SetTrayButtonIcon(button, candidate)
  button:ClearAllPoints()
  button:SetPoint("CENTER", candidate, "CENTER", 0, 0)
  button:SetSize(MV.DefaultSize, MV.DefaultSize)
  local baseLevel = candidate:GetFrameLevel()
  button:SetFrameStrata(candidate:GetFrameStrata())
  button:SetFrameLevel(baseLevel + 1)
  if button.Icon then
    button.Icon:SetAlpha(0.8)
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  end
end

local function SetTrayButtons(button, frame)
  if not button or not frame then return end
  if button.MV_Button then
    MV.MoveBlizzardButton(button, button.MV_Button)
    return
  end
  local candidate
  for i = MV.DRStartIndex, MV.DRSize do
    candidate = frame.otherContainer.icons and frame.otherContainer.icons[i]
    if candidate and not candidate.categoryTable then
      candidate:SetShown(true)
      candidate.categoryTable = button
      button.MV_Button = candidate
      SetTrayButtonIcon(button, candidate)
      return
    end
  end
end

function MV.TryAndUpdateDRStateFromHooks(tray, frame)
  if MV.IsNil(tray) or not frame then
    return
  end
  local ok, children = MV.CallExternalFunction(
    {
      namespace = tray,
      args = { tray },
      functionName = "GetLayoutChildren",
    }
  )
  if not ok then return end
  pcall(function()
    for _, child in ipairs(children) do
      if child:GetCategory() then SetTrayButtons(child, frame) end
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
    local ok, result = MV.CallExternalFunction({
      namespace = button.cooldown,
      functionName = "SetCooldown",
      args = { button.cooldown, button.startTime, button.duration },
      argumentValidators = { MV.IsTable, MV.IsNumber, MV.IsNumber }
    })
    if ok then
      MV.CallExternalFunction({
        namespace = button.cooldown,
        functionName = "SetShowCountdownNumbers",
        args = { button.cooldown, showCountdown },
        argumentValidators = { MV.IsTable, MV.IsBoolean }
      })
      button:Show()
    else
      print(ok, "Result:", result)
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

    if not MV.IsNumber(startTime) and not MV.IsNumber(duration) then
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
        for i = MV.DRStartIndex, MV.DRSize do
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

function MV.ResetButton(button)
  if button and button.categoryTable then
    if button.categoryTable.MV_Button then
      button.categoryTable.MV_Button = nil
    end
    button.categoryTable = nil
    button:Hide()
  end
end

function MV.ResetDR(frame)
  if MV.IsTable(frame.categories) then
    wipe(frame.categories)
  end
  if frame.otherContainer then
    for i = MV.DRStartIndex, MV.DRSize do
      local candidate = frame.otherContainer.icons[i]
      MV.ResetButton(candidate)
    end
  end
end

local function GetAndInterpretField(table, field)
  local ok, result = MV.GetField(table, field)
  if ok then
    return result
  else
    print(ok, "Result:", result)
    return nil
  end
end

local function IsTracked(category)
  local result = GetAndInterpretField(ENEMY_DR_ORDER, category)
  if not MV.IsNil(result) then return result end
  return false
end

function MV.TryAndUpdateDRStateFromEvent(frame, trackerInfo)
  if not MV.IsTable(trackerInfo) and not MV.IsUserData(trackerInfo) then
    return
  end
  if not frame or not frame.unit then return end
  local category = GetAndInterpretField(trackerInfo, "category")
  local ok, info = MV.IsNumber(category)
  if not ok then
    print(ok, info)
    return
  end
  category = IsTracked(category)
  if not MV.IsString(category) then return end
  local startTime = GetAndInterpretField(trackerInfo, "startTime")
  local duration = GetAndInterpretField(trackerInfo, "duration")
  local isImmune = GetAndInterpretField(trackerInfo, "isImmune")
  local showCountdown = GetAndInterpretField(trackerInfo, "showCountdown")

  if MV.IsNumber(startTime) and MV.IsNumber(duration) then
    frame.categories[category] = {
      duration = duration,
      startTime = startTime,
      isImmune = isImmune,
      showCountdown = showCountdown,
      icon = CATEGORY_ICON[category]
    }
  end
  SetButtons(frame)
end

local function SetDRInfoFromLOC(frame, trackerInfo)
  if not MV.IsTable(trackerInfo) and not MV.IsUserData(trackerInfo) then
    return
  end
  local displayType = GetAndInterpretField(trackerInfo, "displayType")
  if not MV.IsNumber(displayType) or displayType ~= 2 then
    return
  end
  local category = GetAndInterpretField(trackerInfo, "locType")
  if MV.IsString(category) and issecretvalue(category) then
    return
  end
  local ok, info = MV.IsString(category)
  if not ok then
    print(ok, info)
    return
  end

  local startTime = GetTime()
  local duration = ENEMY_DR_RESET_TIME
  local iconTexture = GetAndInterpretField(trackerInfo, "iconTexture")

  local categoriesEntry = frame.categories[category]
  if MV.IsTable(categoriesEntry) or MV.IsUserData(categoriesEntry) then
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

function MV.TryAndUpdateDRStateFromLOC(frame)
  if not frame or not frame.unit then return end
  local ok, count = MV.CallExternalFunction({
    namespace = _G.C_LossOfControl,
    functionName = "GetActiveLossOfControlDataCountByUnit",
    args = { frame.unit },
    argumentValidators = { MV.IsString }
  })
  if not ok then
    print(ok, "Result:", count)
    return
  end
  if MV.IsNumber(count) and count > 0 then
    for index = 1, count do
      local ok2, trackerInfo = MV.CallExternalFunction({
        namespace = _G.C_LossOfControl,
        functionName = "GetActiveLossOfControlDataByUnit",
        args = { frame.unit, index },
        argumentValidators = { MV.IsString, MV.IsNumber }
      })
      if ok2 then
        SetDRInfoFromLOC(frame, trackerInfo)
      else
        print(ok2, "Result:", trackerInfo)
      end
    end
  end
end

function MV.HideButton(button)
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
