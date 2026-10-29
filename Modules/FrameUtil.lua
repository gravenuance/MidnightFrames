local _, MF = ...

-- Every user-adjustable layout number, in one place: the hardcoded value
-- here is both the fallback default and the slider default in the options
-- pane. `group` sorts each into a section of its options tab (see Core.lua's
-- AddSizeSections) - "size", "position" or "finetune". `tabs` lists the
-- options tabs (unit types) that show the slider; a setting shared by several
-- frame types appears on each of their tabs and is the same value on all.
-- Order within this list controls slider order within its section.
--
-- roster = party/arena/boss frames, primary = player/target. Display
-- names avoid "roster" in the UI itself (not a term the game uses) even
-- though it's kept internally.
local GROUP_TABS = { "party", "arena", "boss" }
local PRIMARY_TABS = { "player", "target" }

MF.SizeDefinitions = {
  { key = "RosterFrameSpacing", name = "Spacing", desc = "Gap between frames. Shared by party, arena and boss.", default = 55, min = 0, max = 200, group = "position", tabs = GROUP_TABS },
  { key = "RosterFrameOffsetX", name = "Distance from center", desc = "Shared by party, arena and boss frames.", default = 280, min = 0, max = 600, group = "position", tabs = GROUP_TABS },
  { key = "PrimaryFrameOffsetX", name = "Distance from center", desc = "Shared by player and target frames.", default = 225, min = 0, max = 600, group = "position", tabs = PRIMARY_TABS },
  { key = "PetSpace", name = "Gap", desc = "Space between the player and pet frames.", default = 5, min = 0, max = 50, group = "position", tabs = { "pet" } },
  { key = "FocusSpace", name = "Gap", desc = "Space between the target and focus frames.", default = 5, min = 0, max = 50, group = "position", tabs = { "focus" } },
  { key = "SizeX", name = "Width", desc = "Shared by player, target, party, arena and boss.", default = 50, min = 20, max = 150, group = "size", tabs = { "player", "target", "party", "arena", "boss" } },
  { key = "PrimaryFrameHeight", name = "Height", desc = "Shared by player and target frames.", default = 220, min = 50, max = 400, group = "size", tabs = PRIMARY_TABS },
  { key = "GroupFrameHeight", name = "Height", desc = "Shared by party, arena and boss frames.", default = 210, min = 50, max = 400, group = "size", tabs = GROUP_TABS },
  { key = "PetX", name = "Width", desc = "Width of the pet frame.", default = 20, min = 10, max = 100, group = "size", tabs = { "pet" } },
  { key = "PetY", name = "Height", desc = "Height of the pet frame.", default = 80, min = 20, max = 200, group = "size", tabs = { "pet" } },
  { key = "FocusX", name = "Width", desc = "Width of the focus frame.", default = 20, min = 10, max = 100, group = "size", tabs = { "focus" } },
  { key = "FocusY", name = "Height", desc = "Height of the focus frame.", default = 80, min = 20, max = 200, group = "size", tabs = { "focus" } },
  { key = "RaidSizeX", name = "Width", desc = "Width of each raid frame.", default = 150, min = 50, max = 400, group = "size", tabs = { "raid" } },
  { key = "RaidSizeY", name = "Height", desc = "Height of each raid frame.", default = 35, min = 15, max = 100, group = "size", tabs = { "raid" } },
  { key = "FillInset", name = "Health bar inset", desc = "Distance of the health and absorb bars from the frame edge.", default = 4, min = 0, max = 15, group = "finetune", tabs = { "general" } },
  { key = "HighlightInset", name = "Highlight inset", desc = "Distance of the ally-target highlight from the frame edge.", default = 2, min = 0, max = 15, group = "finetune", tabs = { "general" } },
  { key = "AuraOffsetY", name = "Aura icon offset", desc = "How far aura icons sit below the frame's top edge.", default = 190, min = 0, max = 400, group = "finetune", tabs = { "general" } },
}

-- Set to the hardcoded defaults above so anything that reads them before
-- MF.ApplySizeSettings runs (at ADDON_LOADED) still gets a sane value.
for _, def in ipairs(MF.SizeDefinitions) do
  MF[def.key] = def.default
end

-- How many frames this addon builds per group (party1-4, arena1-3, etc.),
-- not the game's max unit count. Raid uses MF.MaxRaidMembers (Raid.lua).
MF.GroupSize = { party = 4, arena = 3, boss = 5 }

-- Raid frames sit further out than roster frames - derived, not its own
-- setting, so it can't drift out of sync with RosterFrameOffsetX.
MF.RaidOffsetX = MF.RosterFrameOffsetX * 1.5

-- Copies the current profile's saved sizes onto the flat MF.* names every
-- other file reads. Must run before the frame files' MF.OnInit callbacks,
-- which call MF.CreateUnitFrame.
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

-- Resolves MF.Positions from the saved profile. Must run before the frame
-- files' MF.OnInit callbacks (same constraint as ApplySizeSettings), and
-- again after any drag or slider change.
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
-- unit token ("party2", "player") -> its frame, for per-event lookups
MF.FramesByUnit = {}

function MF.RegisterMovable(key, frame)
  MF.MovableSingles[key] = frame
  MF.FramesByUnit[frame.unit] = frame
end

function MF.RegisterMovableGroupMember(key, frame)
  table.insert(MF.MovableGroups[key], frame)
  MF.FramesByUnit[frame.unit] = frame
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
  if not ok or MF.IsNil(power) then
    frame.power:SetText("")
    return
  end
  frame.power:SetText(string.format("%.0f", power))
end

function MF.InInstance()
  local _, instanceType = IsInInstance()
  return instanceType == "party" or instanceType == "raid"
end
