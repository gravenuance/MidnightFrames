local _, MV = ...

local ENEMY_DR_RESET_TIME = 16
local ENEMY_DR_ORDER = {
  "stun",
  "incap",
  "disorient",
  "silence",
  "disarm",
  "root",
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

local function IsTracked(category)
  for _, key in ipairs(ENEMY_DR_ORDER) do
    if key == category then
      return true
    end
  end
  return false
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

function MV.TryAndUpdateDRState(frame, trackerInfo)
  if not MV.IsTable(trackerInfo) then
    return
  end
  local category = MV.GetField(trackerInfo, "category")
  if not MV.IsString(category) then return end
  category = string.lower(category)
  if category == "incapacitate" then
    category = "incap"
  end
  if not IsTracked(category) then return end
  local startTime = MV.GetField(trackerInfo, "startTime")
  local duration = MV.GetField(trackerInfo, "duration")
  local isImmune = MV.GetField(trackerInfo, "isImmune")
  local showCountdown = MV.GetField(trackerInfo, "showCountdown")

  local expires
  if MV.IsNumber(startTime) and MV.IsNumber(duration) then
    if duration > 0 then
      expires = startTime + duration
    end
  end
  if MV.IsNumber(expires) then
    frame.categories[category] = {
      expiration = expires,
      isImmune = isImmune,
      showCountdown = showCountdown,
      icon = CATEGORY_ICON[category]
    }
  end
  SetButtons(frame)
end
