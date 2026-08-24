local _, MF = ...

-- Every user-adjustable layout number, in one place: the hardcoded value
-- here is both the fallback default and the slider default in the options
-- pane. `group` sorts each into one of the Sizing tab's three sections
-- (see Core.lua's BuildSizingArgs) - "size", "position", or "finetune".
-- Order within this list controls slider order within its section.
--
-- roster = party/arena/boss frames, primary = player/target. Display
-- names avoid "roster" in the UI itself (not a term the game uses) even
-- though it's kept internally.
MF.SizeDefinitions = {
  { key = "RosterFrameSpacing", name = "Party/Arena/Boss Spacing", desc = "Gap between adjacent party/arena/boss frames.", default = 55, min = 0, max = 200, group = "position" },
  { key = "RosterFrameOffsetX", name = "Party/Arena/Boss Distance from Center", desc = "Distance from screen center to the first party/arena/boss frame.", default = 280, min = 0, max = 600, group = "position" },
  { key = "PrimaryFrameOffsetX", name = "Player/Target Distance from Center", desc = "Distance from screen center to the player/target frames.", default = 225, min = 0, max = 600, group = "position" },
  { key = "PetSpace", name = "Pet Frame Gap", desc = "Gap between the player frame and the pet frame.", default = 5, min = 0, max = 50, group = "position" },
  { key = "FocusSpace", name = "Focus Frame Gap", desc = "Gap between the target frame and the focus frame.", default = 5, min = 0, max = 50, group = "position" },
  { key = "SizeX", name = "Frame Width", desc = "Width shared by every non-raid, non-pet frame.", default = 50, min = 20, max = 150, group = "size" },
  { key = "PrimaryFrameHeight", name = "Player/Target Height", desc = "Height of the player and target frames.", default = 220, min = 50, max = 400, group = "size" },
  { key = "GroupFrameHeight", name = "Party/Arena/Boss Height", desc = "Height of the party/arena/boss frames.", default = 210, min = 50, max = 400, group = "size" },
  { key = "PetX", name = "Pet Frame Width", desc = "Width of the pet frame.", default = 20, min = 10, max = 100, group = "size" },
  { key = "PetY", name = "Pet Frame Height", desc = "Height of the pet frame.", default = 80, min = 20, max = 200, group = "size" },
  { key = "FocusX", name = "Focus Frame Width", desc = "Width of the focus frame.", default = 20, min = 10, max = 100, group = "size" },
  { key = "FocusY", name = "Focus Frame Height", desc = "Height of the focus frame.", default = 80, min = 20, max = 200, group = "size" },
  { key = "RaidSizeX", name = "Raid Frame Width", desc = "Width of each raid frame.", default = 150, min = 50, max = 400, group = "size" },
  { key = "RaidSizeY", name = "Raid Frame Height", desc = "Height of each raid frame.", default = 35, min = 15, max = 100, group = "size" },
  { key = "FillInset", name = "Health/Absorb Bar Inset", desc = "How far the health/absorb fill sits inside the frame edge.", default = 4, min = 0, max = 15, group = "finetune" },
  { key = "HighlightInset", name = "Highlight Inset", desc = "How far the ally-target highlight border sits inside the frame edge.", default = 2, min = 0, max = 15, group = "finetune" },
  { key = "AuraOffsetY", name = "Aura Icon Offset", desc = "How far the aura icons sit below the top of a vertical frame.", default = 190, min = 0, max = 400, group = "finetune" },
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

-- Move Mode support: each key below can either follow its slider-driven
-- default formula (manual = false) or an absolute drag override (manual =
-- true). Group keys store their *origin* (where member 1 sits) - other
-- members are derived from it via GetRosterMemberPoint, so dragging a group
-- preserves its internal spacing.
MF.RosterGroupSign = { party = -1, arena = 1, boss = 1 }

MF.Positions = {}
for _, key in ipairs({ "player", "target", "pet", "focus", "party", "arena", "boss", "raid" }) do
  MF.Positions[key] = { x = 0, y = 0 }
end

-- Resolves MF.Positions from the saved profile. Must run before Party/
-- Player/Arena/Boss/Raid/Target.lua load (same constraint as
-- ApplySizeSettings), and again after any drag or slider change.
function MF.ApplyPositionSettings()
  local positions = MF.db and MF.db.profile.positions
  if not positions then return end

  local function resolve(key, defaultX, defaultY)
    local saved = positions[key]
    if saved and saved.manual then
      MF.Positions[key].x = saved.x
      MF.Positions[key].y = saved.y
    else
      MF.Positions[key].x = defaultX
      MF.Positions[key].y = defaultY
    end
  end

  resolve("player", -MF.PrimaryFrameOffsetX, 0)
  resolve("target", MF.PrimaryFrameOffsetX, 0)
  resolve("party", MF.RosterGroupSign.party * MF.RosterFrameOffsetX, 0)
  resolve("arena", MF.RosterGroupSign.arena * MF.RosterFrameOffsetX, 0)
  resolve("boss", MF.RosterGroupSign.boss * MF.RosterFrameOffsetX, 0)
  resolve("raid", -MF.RaidOffsetX, 0)
  -- pet/focus's non-manual case stays relative-parented to player/target
  -- respectively (see Player.lua/Focus.lua), so their defaults here are
  -- unused placeholders.
  resolve("pet", 0, 0)
  resolve("focus", 0, 0)
end

-- Single source of truth for a roster member's point, so construction and
-- MF.ReflowRosterGroup can't drift apart.
function MF.GetRosterMemberPoint(key, index)
  local origin = MF.Positions[key]
  local sign = MF.RosterGroupSign[key]
  return origin.x + sign * (index - 1) * MF.RosterFrameSpacing, origin.y
end

-- Frame registries for Move Mode - populated by each frame-construction
-- file as it creates its frames, so MoveMode.lua never has to guess global
-- frame names.
MF.MovableSingles = {}
MF.MovableGroups = { party = {}, arena = {}, boss = {}, raid = {} }

function MF.RegisterMovable(key, frame)
  MF.MovableSingles[key] = frame
end

function MF.RegisterMovableGroupMember(key, frame)
  table.insert(MF.MovableGroups[key], frame)
end

-- Repositions every registered member of a roster group relative to its
-- current origin. Used after a group drag in Move Mode. These are secure
-- unit buttons - repositioning them in combat throws a protected-call
-- error, so this must stay a no-op there like every other reposition path.
function MF.ReflowRosterGroup(key)
  if InCombatLockdown() then return end
  for index, frame in ipairs(MF.MovableGroups[key]) do
    local x, y = MF.GetRosterMemberPoint(key, index)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
  end
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
