local _, MF = ...

local ENEMY_DR_RESET_TIME = MF.DR.ResetTime
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
  local ok = MF.SetCooldown(candidate.cooldown, startTime, ENEMY_DR_RESET_TIME)
  if ok then
    MF.SetShowCountdownNumbers(candidate.cooldown, true)
  end
  candidate:Show()
end

-- Blizzard's tray shows its immunity indicator from the DR state it was
-- given, so we mirror that instead of guessing from timestamps. A secret
-- value counts as not immune.
local function IsImmunityShown(item)
  local indicator = item.ImmunityIndicator
  if not indicator then return false end
  return MF.SafeBoolResult(true, indicator:IsShown())
end

-- The DR button already linked to this tray item, else the first free one.
local function ClaimButton(frame, item)
  local linked = item.MF_Button
  if linked and linked.trayItem == item then
    return linked
  end
  local icons = frame.otherContainer and frame.otherContainer.icons
  if not icons then return nil end
  for i = MF.DRStartIndex, #icons do
    local candidate = icons[i]
    if candidate and not candidate.categoryTable and not candidate.trayItem then
      candidate.trayItem = item
      item.MF_Button = candidate
      return candidate
    end
  end
  return nil
end

-- Runs once per Blizzard UpdateOrAddTrayItem (the only tray function that
-- carries the new DR state), after the tray has updated the item.
function MF.OnTrayItemUpdated(tray, state, frame)
  if MF.IsNil(tray) or not frame or not state then
    return
  end
  local category = state.category
  if not MF.IsNumber(category) or MF.IsSecretSafe(category) then
    return
  end
  local item = tray:GetActiveTrayItemForCategory(category)
  if not item then return end

  local button = ClaimButton(frame, item)
  if not button then return end
  local iconTexture = item.Icon and item.Icon:GetTexture()
  SetSafeButton(button, iconTexture, IsImmunityShown(item), GetTime())
end

-- Blizzard finished this item's cooldown and released it: clear only its button.
function MF.OnTrayItemCooldownDone(item)
  local button = item and item.MF_Button
  if button and button.trayItem == item then
    MF.ResetButton(button)
  end
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

-- Frees a DR button: unlinks it from whatever drove it (a Blizzard tray item
-- or a category entry) and hides it.
function MF.ResetButton(button)
  if not button then return end
  if button.trayItem then
    button.trayItem.MF_Button = nil
    button.trayItem = nil
  end
  button.categoryTable = nil
  button:Hide()
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
  if type(category) ~= "string" then return end
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

-- Returns true when the effect started or hit a DR category on this frame.
local function SetDRInfoFromLOC(frame, trackerInfo, now)
  if not MF.IsTable(trackerInfo) and not MF.IsUserData(trackerInfo) then
    return false
  end
  local displayType = GetAndInterpretField(trackerInfo, "displayType")
  if not MF.IsNumber(displayType) or displayType ~= 2 then
    return false
  end
  -- locType and auraInstanceID are NeverSecret in the API documentation.
  local category = MF.DR.CategoryForLocType(GetAndInterpretField(trackerInfo, "locType"))
  if type(category) ~= "string" then
    return false
  end

  local instanceID = GetAndInterpretField(trackerInfo, "auraInstanceID")
  local status, entry = MF.DR.RegisterLossOfControl(frame.categories, category, instanceID, now)
  if status == "started" or status == "hit" then
    entry.icon = CATEGORY_ICON[category]
    return true
  end
  return false
end

function MF.TryAndUpdateDRStateFromLOC(frame)
  if not frame or not frame.unit then return end
  local ok, count = MF.GetActiveLossOfControlDataCountByUnit(frame.unit)
  if not ok then
    return
  end
  if MF.IsNumber(count) and count > 0 then
    local now = GetTime()
    local changed = false
    for index = 1, count do
      local ok2, trackerInfo = MF.GetActiveLossOfControlDataByUnit(frame.unit, index)
      if ok2 and SetDRInfoFromLOC(frame, trackerInfo, now) then
        changed = true
      end
    end
    if changed then
      SetButtons(frame)
    end
  end
end

function MF.HideButton(button)
  if button then
    button:Hide()
    if button.trayItem then
      button.trayItem.MF_Button = nil
      button.trayItem = nil
    end
    if button.categoryTable then
      button.categoryTable.startTime = nil
      button.categoryTable.duration = nil
      button.categoryTable.button = nil
      button.categoryTable = nil
    end
  end
end
