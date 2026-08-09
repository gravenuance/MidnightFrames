local _, MF = ...

-- Every user-adjustable layout number, in one place: the hardcoded value
-- here is both the fallback default and the slider default in the options
-- pane (see Core.lua's BuildSizingArgs). Order controls the order sliders
-- appear in the options pane.
--
-- roster = party/arena/boss frames, primary = player/target
MF.SizeDefinitions = {
  { key = "RosterFrameSpacing", name = "Roster Frame Spacing", desc = "Gap between adjacent party/arena/boss frames.", default = 55, min = 0, max = 200 },
  { key = "RosterFrameOffsetX", name = "Roster Frame Offset X", desc = "Distance from screen center to the first party/arena/boss frame.", default = 280, min = 0, max = 600 },
  { key = "PrimaryFrameOffsetX", name = "Primary Frame Offset X", desc = "Distance from screen center to the player/target frames.", default = 225, min = 0, max = 600 },
  { key = "SizeX", name = "Frame Width", desc = "Width shared by every non-raid, non-pet frame.", default = 50, min = 20, max = 150 },
  { key = "PrimaryFrameHeight", name = "Player/Target Height", desc = "Height of the player and target frames.", default = 220, min = 50, max = 400 },
  { key = "GroupFrameHeight", name = "Group Frame Height", desc = "Height of the party/arena/boss frames.", default = 210, min = 50, max = 400 },
  { key = "PetX", name = "Pet Frame Width", desc = "Width of the pet frame.", default = 20, min = 10, max = 100 },
  { key = "PetY", name = "Pet Frame Height", desc = "Height of the pet frame.", default = 80, min = 20, max = 200 },
  { key = "PetSpace", name = "Pet Frame Gap", desc = "Gap between the player frame and the pet frame.", default = 5, min = 0, max = 50 },
  { key = "RaidSizeX", name = "Raid Frame Width", desc = "Width of each raid frame.", default = 150, min = 50, max = 400 },
  { key = "RaidSizeY", name = "Raid Frame Height", desc = "Height of each raid frame.", default = 35, min = 15, max = 100 },
  { key = "FillInset", name = "Fill Inset", desc = "How far the health/absorb fill sits inside the frame edge.", default = 4, min = 0, max = 15 },
  { key = "HighlightInset", name = "Highlight Inset", desc = "How far the ally-target highlight border sits inside the frame edge.", default = 2, min = 0, max = 15 },
  { key = "AuraOffsetY", name = "Aura Icon Offset", desc = "How far the aura icons sit below the top of a vertical frame.", default = 190, min = 0, max = 400 },
}

-- Set to the hardcoded defaults above so anything that loads before
-- MF.ApplySizeSettings runs (nothing should, but just in case) still gets a
-- sane value instead of nil.
for _, def in ipairs(MF.SizeDefinitions) do
  MF[def.key] = def.default
end

-- Raid frames sit further out than roster frames - derived, not its own
-- setting, so it can't drift out of sync with RosterFrameOffsetX.
MF.RaidOffsetX = MF.RosterFrameOffsetX * 1.5

-- Copies the current profile's saved sizes onto the flat MF.* names every
-- other file reads. Must run before Party/Player/Arena/Boss/Raid/Target.lua
-- load, since those call MF.CreateUnitFrame immediately at load time, not
-- on a later event.
function MF.ApplySizeSettings()
  local sizes = MF.db and MF.db.profile.sizes
  if not sizes then return end
  for _, def in ipairs(MF.SizeDefinitions) do
    MF[def.key] = sizes[def.key]
  end
  MF.RaidOffsetX = MF.RosterFrameOffsetX * 1.5
end

-- live roster count, not a layout constant - kept updated by Party.lua
MF.NumGroupMembers = 0

local powerCurve
local curveType = Enum.LuaCurveType.Linear

function MF.UpdatePowerLabel(frame)
  if not frame.power then return end
  if not MF.UnitExists(frame.unit) then
    frame.power:SetText("")
    return
  end
  if MF.IsNil(powerCurve) then
    local ok, curve = MF.CreateCurve()
    if not ok then return end
    ok = MF.SetCurveType(curve, curveType)
    if not ok then return end
    MF.AddCurvePoint(curve, 0.0, 0)
    MF.AddCurvePoint(curve, 1.0, 100)
    powerCurve = curve
  end
  local ok, power = MF.UnitPowerPercent(frame.unit, powerCurve)
  if not ok or power == nil then
    frame.power:SetText("")
    return
  end
  frame.power:SetText(string.format("%.0f", power))
end

function MF.InInstance()
  local _, instanceType = IsInInstance()
  return instanceType == "party" or instanceType == "raid"
end
