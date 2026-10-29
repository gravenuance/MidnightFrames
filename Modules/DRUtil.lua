local _, MF = ...

local ENEMY_DR_RESET_TIME = MF.DR.ResetTime

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

-- Our links to Blizzard's tray objects live here, never in their tables.
local buttonForTrayItem = setmetatable({}, { __mode = "k" })
local hookedTrayItems = setmetatable({}, { __mode = "k" })
local hookedTrays = setmetatable({}, { __mode = "k" })

local immuneColor, normalColor

local function UnlinkTrayItem(button)
  local item = button.trayItem
  if item then
    if buttonForTrayItem[item] == button then
      buttonForTrayItem[item] = nil
    end
    button.trayItem = nil
  end
end

-- The immunity flag can be secret in a restricted arena; only
-- SetVertexColorFromBoolean may consume it then.
local function SetImmunityBorder(border, immune)
  if not MF.IsSecretSafe(immune) then
    if immune == true then
      border:SetVertexColor(1, 0, 0, 1)
    else
      border:SetVertexColor(0, 1, 0, 1)
    end
    return
  end
  if not border.SetVertexColorFromBoolean or not CreateColor then
    border:SetVertexColor(0, 1, 0, 1)
    return
  end
  immuneColor = immuneColor or CreateColor(1, 0, 0, 1)
  normalColor = normalColor or CreateColor(0, 1, 0, 1)
  border:SetVertexColorFromBoolean(immune, immuneColor, normalColor)
end

-- SetCooldown rejects secrets from addon code, so a secret tray timer is
-- replaced by a full window from now.
local function ReadTrayTimer(item)
  local cooldown = item.Cooldown
  if cooldown and cooldown.GetCooldownTimes then
    local startMs, durationMs = cooldown:GetCooldownTimes()
    if MF.IsNumber(startMs) and MF.IsNumber(durationMs)
        and not MF.IsSecretSafe(startMs) and not MF.IsSecretSafe(durationMs)
        and durationMs > 0 then
      return startMs / 1000, durationMs / 1000
    end
  end
  return GetTime(), ENEMY_DR_RESET_TIME
end

-- The DR button already linked to this tray item, else the first free one.
local function ClaimButton(frame, item)
  local linked = buttonForTrayItem[item]
  if linked and linked.trayItem == item then
    return linked
  end
  local icons = frame.otherContainer and frame.otherContainer.icons
  if not icons then return nil end
  for i = MF.DRStartIndex, #icons do
    local candidate = icons[i]
    if candidate and not candidate.categoryTable and not candidate.trayItem then
      candidate.trayItem = item
      buttonForTrayItem[item] = candidate
      return candidate
    end
  end
  return nil
end

-- Mirrors one tray item after Blizzard gave it a new DR state. Icon and
-- immunity are copied from the item's widgets, which accept secret values,
-- so the secret state payload itself is never read.
local function SyncTrayItem(item, frame)
  local button = ClaimButton(frame, item)
  if not button then return end
  if button.icon and item.Icon then
    button.icon:SetTexture(item.Icon:GetTexture())
  end
  if button.border then
    local indicator = item.ImmunityIndicator
    SetImmunityBorder(button.border, indicator and indicator:IsShown())
  end
  local startTime, duration = ReadTrayTimer(item)
  if MF.SetCooldown(button.cooldown, startTime, duration) then
    MF.SetShowCountdownNumbers(button.cooldown, true)
  end
  button:Show()
end

-- Tray items are pooled children of the tray; each is hooked once. An item
-- hooked here for the first time already ran UpdateState (Blizzard acquires
-- and updates it before UpdateOrAddTrayItem returns), so it is synced now.
-- Edit Mode previews never get a DR state and are skipped.
local function HookTrayItems(frame, ...)
  for index = 1, select("#", ...) do
    local item = select(index, ...)
    if not hookedTrayItems[item] and item.UpdateState and item.ImmunityIndicator then
      hookedTrayItems[item] = true
      hooksecurefunc(item, "UpdateState", function(self) SyncTrayItem(self, frame) end)
      if item:IsShown() and not item.isEditModePreview then
        SyncTrayItem(item, frame)
      end
    end
  end
end

-- Blizzard finished this item's cooldown and released it: clear only its button.
function MF.OnTrayItemCooldownDone(item)
  local button = item and buttonForTrayItem[item]
  if button and button.trayItem == item then
    MF.ResetButton(button)
  end
end

-- Mirrors a Blizzard SpellDiminishStatusTray onto `frame`'s DR buttons.
-- Safe to call repeatedly; each tray is hooked once.
function MF.HookDRTray(tray, frame)
  if not tray or not frame or hookedTrays[tray] then return end
  if not tray.UpdateOrAddTrayItem or not tray.OnTrayItemCooldownDone
      or not tray.RemoveAllTrayItems or not tray.GetChildren then
    return
  end
  hookedTrays[tray] = true

  hooksecurefunc(tray, "UpdateOrAddTrayItem", function(self)
    HookTrayItems(frame, self:GetChildren())
  end)
  hooksecurefunc(tray, "OnTrayItemCooldownDone", function(_, item)
    MF.OnTrayItemCooldownDone(item)
  end)
  -- the tray hiding releases every item without OnTrayItemCooldownDone
  hooksecurefunc(tray, "RemoveAllTrayItems", function()
    MF.ResetDR(frame)
  end)
  HookTrayItems(frame, tray:GetChildren())
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
    local icon          = categoryTable.icon or CATEGORY_ICON[category]
    local button       = categoryTable.button

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
  UnlinkTrayItem(button)
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

-- Reused for every scan: aura instance ID -> DR category of each active effect.
local activeLossOfControl = {}

local function CollectLossOfControl(trackerInfo)
  if not MF.IsTable(trackerInfo) and not MF.IsUserData(trackerInfo) then
    return
  end
  local displayType = GetAndInterpretField(trackerInfo, "displayType")
  if not MF.IsNumber(displayType) or MF.IsSecretSafe(displayType) or displayType ~= 2 then
    return
  end
  -- locType and auraInstanceID are NeverSecret in the API documentation.
  local category = MF.DR.CategoryForLocType(GetAndInterpretField(trackerInfo, "locType"))
  local instanceID = GetAndInterpretField(trackerInfo, "auraInstanceID")
  if type(category) == "string" and type(instanceID) == "number" then
    activeLossOfControl[instanceID] = category
  end
end

-- Scans even when nothing is active: an effect ending starts its DR window.
function MF.TryAndUpdateDRStateFromLOC(frame)
  if not frame or not frame.unit then return end
  local ok, count = MF.GetActiveLossOfControlDataCountByUnit(frame.unit)
  if not ok or not MF.IsNumber(count) or MF.IsSecretSafe(count) then
    return
  end
  wipe(activeLossOfControl)
  for index = 1, count do
    local ok2, trackerInfo = MF.GetActiveLossOfControlDataByUnit(frame.unit, index)
    if ok2 then
      CollectLossOfControl(trackerInfo)
    end
  end
  if MF.DR.UpdateLossOfControl(frame.categories, activeLossOfControl, GetTime()) then
    SetButtons(frame)
  end
end

function MF.HideButton(button)
  if button then
    button:Hide()
    UnlinkTrayItem(button)
    if button.categoryTable then
      button.categoryTable.startTime = nil
      button.categoryTable.duration = nil
      button.categoryTable.button = nil
      button.categoryTable = nil
    end
  end
end
