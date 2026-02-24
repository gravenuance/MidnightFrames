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

local CATEGORY_ICON = {
  stun = "Interface\\Icons\\Ability_Rogue_CheapShot",
  incap = "Interface\\Icons\\Ability_Rogue_Sap",
  disorient = "Interface\\Icons\\Spell_Shadow_MindSteal",
  silence = "Interface\\Icons\\Ability_Rogue_Garrote",
  disarm = "Interface\\Icons\\Ability_Warrior_Disarm",
  root = "Interface\\Icons\\Spell_Nature_StrangleVines",
}

function MV.ResetDR(frame)
  if frame.otherContainer then
    for i = 2, 5 do
      local btn = frame.otherContainer.icons[i]
      if btn then
        btn.enabled = false
        btn:Hide()
        if btn.blizzButton then
          btn.blizzButton:Hide()
          btn.blizzButton.MV_Button = nil
          btn.blizzButton = nil
        end
      end
    end
  end
end

function MV.ResetTray(frame)
  if frame.otherContainer then
    for i = 2, 5 do
      local btn = frame.otherContainer.icons[i]
      if btn then
        if btn.blizzButton then
          if not btn.blizzButton:IsShown() then
            btn:Hide()
            btn.blizzButton.MV_Button = nil
            btn.blizzButton = nil
            btn.enabled = false
          end
        else
          btn:Hide()
        end
      end
    end
  end
end

function MV.ResetBlizzardButton(button)
  print("ResetBlizzardButton")
  if button.MV_Button then
    local btn = button.MV_Button
    print(btn.enabled)
    btn.enabled = false
    local container = btn.container
    if container then
      for i = 2, 5 do
        if container.icons[i] and not container.icons[i].enabled then
          print("Hiding ", i, "because: ", container.icons[i].enabled and "ON" or "OFF")
          btn = container.icons[i]
          btn:Hide()
          btn.blizzButton.MV_Button = nil
          btn.blizzButton = nil
        end
      end
    end
  end
end

function MV.MoveBlizzardButton(button, candidate)
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

function MV.UpdateBlizzardDR(button, frame)
  if not button or not frame then return end
  if not button:IsShown() then return end
  if button.MV_Button then
    MV.MoveBlizzardButton(button, button.MV_Button)
    return
  end
  local candidate
  for i = 2, 5 do
    candidate = frame.otherContainer.icons and frame.otherContainer.icons[i]
    if candidate and not candidate.enabled then
      candidate.enabled = true
      candidate:Show()
      candidate.blizzButton = button
      button.MV_Button = candidate
      MV.MoveBlizzardButton(button, candidate)
      return
    end
  end
end

function MV.UpdateBlizzardDRBackup(tray, frame)
  if not tray or not frame then
    return
  end

  local ok, children = MV.CallExternalFunction(
    {
      namespace = tray,
      args = { tray },
      functionName = "GetChildren",
    }
  )
  if not ok then return end
  pcall(function()
    for _, child in ipairs(children) do
      if not child:GetCategory() then break end
      MV.UpdateBlizzardDR(child, frame)
    end
  end)
end

local function SetButtonIcon(button, icon, expires, now, showCountdown, isImmune)
  if button.icon and icon then
    button.icon:SetTexture(icon)
    if button.immune and isImmune then
      button.immune:Show()
    else
      button.immune:Hide()
    end
    button:Show()
  end
  local duration = expires - now
  if duration > 0 then
    local ok = MV.CallExternalFunction({
      namespace = button.cooldown,
      functionName = "SetCooldownFromExpirationTime",
      args = { button.cooldown, expires, duration },
      argumentValidators = { MV.IsUserData, MV.IsNumber, MV.IsNumber }
    })
    if ok then
      MV.CallExternalFunction({
        namespace = button.cooldown,
        functionName = "SetShowCountdownNumbers",
        args = { button.cooldown, showCountdown },
        argumentValidators = { MV.IsUserData, MV.IsBoolean }
      })
    end
  end
end

function MV.ResetDRButtons(frame)
  if MV.IsTable(frame.categories) then
    wipe(frame.categories)
  end
  for i = 2, 5 do
    local candidate = frame.otherContainer.icons[i]
    if not candidate.categoryTable then
      candidate.categoryTable = nil
      candidate:Hide()
      break
    end
  end
end

local function SetButtons(frame)
  if not frame then
    return
  end

  local now = GetTime()

  for category, categoryTable in pairs(frame.categories) do
    local expires       = categoryTable.expiration
    local isImmune      = categoryTable.isImmune
    local showCountdown = categoryTable.showCountdown
    local icon          = categoryTable.icon
    local button        = categoryTable.button

    if not MV.IsNumber(expires) then
      if button then
        button:Hide()
        button.categoryTable = nil
      end
      frame.categories[category] = nil
    elseif expires <= now then
      if button then
        button:Hide()
        button.categoryTable = nil
      end
      frame.categories[category] = nil
    else
      if button then
        SetButtonIcon(button, icon, expires, now, showCountdown, isImmune)
      else
        for i = 2, 5 do
          local candidate = frame.otherContainer.icons[i]
          if not candidate.categoryTable then
            button = candidate
            categoryTable.button = button
            button.categoryTable = categoryTable
            SetButtonIcon(button, icon, expires, now, showCountdown, isImmune)
            break
          end
        end
      end
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

function MV.TryAndUpdateDRState(frame, trackerInfo)
  if not MV.IsTable(trackerInfo) and not MV.IsUserData(trackerInfo) then
    return
  end
  local category = GetAndInterpretField(trackerInfo, "category")
  local ok, info = MV.IsNumber(category)
  if not ok then
    print(ok, info)
    return
  end
  category = IsTracked(category)
  if not MV.IsString(category) then return end
  print("It is tracked")
  local startTime = GetAndInterpretField(trackerInfo, "startTime")
  local duration = GetAndInterpretField(trackerInfo, "duration")
  local isImmune = GetAndInterpretField(trackerInfo, "isImmune")
  local showCountdown = GetAndInterpretField(trackerInfo, "showCountdown")
  print("Got all the information")

  local expires = nil
  if MV.IsNumber(startTime) and MV.IsNumber(duration) then
    if duration > 0 then
      expires = startTime + duration
    end
    print("Setting expiration")
  end
  if MV.IsNumber(expires) then
    print("Creating category")
    frame.categories[category] = {
      expiration = expires,
      isImmune = isImmune,
      showCountdown = showCountdown,
      icon = CATEGORY_ICON[category]
    }
  end
  SetButtons(frame)
end

local function SetDRInfo(frame, trackerInfo)
  if not MV.IsTable(trackerInfo) and not MV.IsUserData(trackerInfo) then
    return
  end
  local displayType = GetAndInterpretField(trackerInfo, "displayType")
  if not MV.IsNumber(displayType) or displayType ~= 2 then
    return
  end
  local category = GetAndInterpretField(trackerInfo, "locType")
  local ok, info = MV.IsString(category)
  if not ok then
    print(ok, info)
    return
  end

  local startTime = GetAndInterpretField(trackerInfo, "startTime")
  local duration = GetAndInterpretField(trackerInfo, "duration")
  local iconTexture = GetAndInterpretField(trackerInfo, "iconTexture")

  local expires = nil
  if MV.IsNumber(startTime) and MV.IsNumber(duration) then
    if duration > 0 then
      expires = startTime + duration
    end
  end
  if MV.IsNumber(expires) then
    if frame.categories[category] and frame.categories[category].expiration > expires then
      frame.categories[category].isImmune = true
      frame.categories[category].expiration = expires
    else
      frame.categories[category] = {
        expiration = expires,
        icon = iconTexture,
        isImmune = false,
        showCountdown = true,
      }
    end
  end
  SetButtons(frame)
end

function MV.TryAndUpdateDRStateLOC(frame)
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
        SetDRInfo(frame, trackerInfo)
      else
        print(ok2, "Result:", trackerInfo)
      end
    end
  end
end
