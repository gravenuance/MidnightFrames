local _, MF = ...

-- Loaded last in the .toc, after every frame-construction file, so
-- MF.MovableSingles/MF.MovableGroups are fully populated before this runs.

MF.MoveModeActive = false

local GROUP_KEYS = { "party", "arena", "boss", "raid" }

-- test modes we force on while dragging (so group/target frames stay
-- visible with no live target/group), tracked here so ExitMoveMode only
-- turns back off the ones it turned on
local autoEnabledTestModes = {}

-- Several options-window controls show dynamic state (Move Mode's button
-- label, the "currently has no effect on ..." note on position sliders) -
-- nothing redraws them on its own, so anything that changes that state
-- has to ask the dialog to refresh.
local function NotifyOptionsChanged()
  LibStub("AceConfigRegistry-3.0"):NotifyChange("MF")
end

local function GetAbsoluteOffsets(frame)
  local cx, cy = frame:GetCenter()
  if not cx then return nil end
  local ucx, ucy = UIParent:GetCenter()
  return cx - ucx, cy - ucy
end

local function EnableSingleDrag(key, frame)
  if not frame then return end
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    if key == "pet" or key == "focus" then
      -- pet/focus default to a point relative to player/target; switch to
      -- an absolute UIParent point at its current spot so it stops
      -- following its owner frame once dragged
      local x, y = GetAbsoluteOffsets(self)
      if not x then return end
      self:ClearAllPoints()
      self:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
    self:StartMoving()
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if InCombatLockdown() then return end
    local x, y = GetAbsoluteOffsets(self)
    if not x then return end
    local saved = MF.db.profile.positions[key]
    saved.x, saved.y, saved.manual = x, y, true
    MF.ApplyPositionSettings()
    NotifyOptionsChanged()
  end)
end

local function DisableSingleDrag(frame)
  if not frame then return end
  -- in case this fires mid-drag (e.g. the combat watcher below cutting a
  -- drag short), stop it first so the frame doesn't get left following the
  -- mouse with its OnDragStop handler about to be wiped out
  frame:StopMovingOrSizing()
  frame:SetMovable(false)
  frame:RegisterForDrag()
  frame:SetScript("OnDragStart", nil)
  frame:SetScript("OnDragStop", nil)
end

local function EnableGroupDrag(key)
  local handle = MF.MovableGroups[key][1]
  if not handle then return end
  handle:SetMovable(true)
  handle:EnableMouse(true)
  handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    self:StartMoving()
  end)
  handle:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if InCombatLockdown() then return end
    local x, y = GetAbsoluteOffsets(self)
    if not x then return end
    if key == "raid" then
      -- raid1 sits at origin.y + the stack's current top offset, not at
      -- origin.y directly - back that out before saving
      y = y - (MF.RaidStackTopY or 0)
    end
    local saved = MF.db.profile.positions[key]
    saved.x, saved.y, saved.manual = x, y, true
    MF.ApplyPositionSettings()
    if key == "raid" then
      if MF.LayoutRaidFrames then MF.LayoutRaidFrames() end
    else
      MF.ReflowRosterGroup(key)
    end
    NotifyOptionsChanged()
  end)
end

local function DisableGroupDrag(key)
  DisableSingleDrag(MF.MovableGroups[key][1])
end

local function EnterMoveMode()
  autoEnabledTestModes = {}
  for _, key in ipairs(MF.Test.Kinds) do
    if not MF.Test.Is(key) then
      MF.Test.Set(key, true)
      autoEnabledTestModes[key] = true
    end
  end

  EnableSingleDrag("player", MF.MovableSingles.player)
  EnableSingleDrag("target", MF.MovableSingles.target)
  EnableSingleDrag("pet", MF.MovableSingles.pet)
  EnableSingleDrag("focus", MF.MovableSingles.focus)
  for _, key in ipairs(GROUP_KEYS) do
    EnableGroupDrag(key)
  end

  MF.MoveModeActive = true
  NotifyOptionsChanged()
  print("MidnightFrames: Move Mode ON. Drag player/target/pet directly, or the first " ..
      "frame of a group to move the whole group. Type /mf move again to exit.")
end

local function ExitMoveMode()
  DisableSingleDrag(MF.MovableSingles.player)
  DisableSingleDrag(MF.MovableSingles.target)
  DisableSingleDrag(MF.MovableSingles.pet)
  DisableSingleDrag(MF.MovableSingles.focus)
  for _, key in ipairs(GROUP_KEYS) do
    DisableGroupDrag(key)
  end

  for key in pairs(autoEnabledTestModes) do
    MF.Test.Set(key, false)
  end
  autoEnabledTestModes = {}

  MF.MoveModeActive = false
  NotifyOptionsChanged()
  print("MidnightFrames: Move Mode OFF.")
end

function MF.ToggleMoveMode()
  if InCombatLockdown() then
    print("MidnightFrames: can't change Move Mode in combat.")
    return
  end
  if MF.MoveModeActive then
    ExitMoveMode()
  else
    EnterMoveMode()
  end
end

-- Belt-and-suspenders on top of the OnDragStart/OnDragStop combat guards:
-- if combat starts while Move Mode is active (e.g. a mob aggros mid-setup),
-- drop out immediately so nothing stays draggable - these are secure unit
-- buttons and repositioning them in combat throws a protected-call error.
local combatWatcher = CreateFrame("Frame")
combatWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
combatWatcher:SetScript("OnEvent", function()
  if MF.MoveModeActive then
    ExitMoveMode()
    print("MidnightFrames: Move Mode disabled - combat started.")
  end
end)

-- Repositions every registered frame from the current MF.Positions/saved
-- profile - used by "Reset All Positions" and on profile switch, since
-- position changes (unlike sizes) don't need a UI reload to take effect.
-- No-ops in combat, same as every other reposition path here - these are
-- secure unit buttons.
function MF.RepositionAllFrames()
  if InCombatLockdown() then return end
  local function reposition(frame, x, y)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
  end

  reposition(MF.MovableSingles.player, MF.Positions.player.x, MF.Positions.player.y)
  reposition(MF.MovableSingles.target, MF.Positions.target.x, MF.Positions.target.y)

  local petPos = MF.db.profile.positions.pet
  if petPos.manual then
    reposition(MF.MovableSingles.pet, petPos.x, petPos.y)
  elseif MF.MovableSingles.pet and MF.MovableSingles.player then
    MF.MovableSingles.pet:ClearAllPoints()
    MF.MovableSingles.pet:SetPoint("TOPLEFT", MF.MovableSingles.player, "TOPRIGHT", MF.PetSpace, 0)
  end

  local focusPos = MF.db.profile.positions.focus
  if focusPos.manual then
    reposition(MF.MovableSingles.focus, focusPos.x, focusPos.y)
  elseif MF.MovableSingles.focus and MF.MovableSingles.target then
    MF.MovableSingles.focus:ClearAllPoints()
    MF.MovableSingles.focus:SetPoint("TOPRIGHT", MF.MovableSingles.target, "TOPLEFT", -MF.FocusSpace, 0)
  end

  MF.ReflowRosterGroup("party")
  MF.ReflowRosterGroup("arena")
  MF.ReflowRosterGroup("boss")
  if MF.LayoutRaidFrames then
    MF.LayoutRaidFrames()
  end
end
