local _, MF = ...

local testAura = "Interface\\Icons\\Spell_Nature_Rejuvenation"
local testTrinket = "Interface\\Icons\\INV_Misc_PocketWatch_01"
local testCast = "Interface\\Icons\\Spell_Fire_Fireball02"

local TEST_RAID_MARK = 8 -- Skull

-- One entry per toggleable frame group. `name` is an exact frame global
-- (single frames); `prefix` + a count source covers the indexed groups.
local UNIT_CONFIG = {
  target = { name = "MF_Target" },
  focus  = { name = "MF_Focus" },
  party  = { prefix = "MF_Party", sizeKey = "party" },
  arena  = { prefix = "MF_Arena", sizeKey = "arena" },
  boss   = { prefix = "MF_Boss", sizeKey = "boss" },
  raid   = { prefix = "MF_Raid", countKey = "MaxRaidMembers" },
}

-- Stable order, for callers that iterate every toggle.
MF.Test = { Kinds = { "target", "focus", "party", "arena", "boss", "raid" } }

local state = {}
for _, kind in ipairs(MF.Test.Kinds) do
  state[kind] = false
end

function MF.Test.Is(kind)
  return state[kind] == true
end

-- Pure state reset, no frame side effects - for the per-frame event
-- handlers that clear test mode on zone change and then refresh
-- themselves. Set/Toggle below are the ones that redraw.
function MF.Test.Clear(kind)
  if state[kind] ~= nil then
    state[kind] = false
  end
end

local function FrameCount(cfg)
  if cfg.countKey then
    return MF[cfg.countKey] or 0
  end
  if cfg.sizeKey then
    return (MF.GroupSize and MF.GroupSize[cfg.sizeKey]) or 0
  end
  return 0
end

local function EachFrame(kind, fn)
  local cfg = UNIT_CONFIG[kind]
  if not cfg then return end
  if cfg.name then
    local f = _G[cfg.name]
    if f then fn(f) end
    return
  end
  for i = 1, FrameCount(cfg) do
    local f = _G[cfg.prefix .. i]
    if f then fn(f) end
  end
end

local function SetTestIcons(frame, test)
  local auraIcon = frame.auraContainer and frame.auraContainer.icons[1]
  if auraIcon then
    auraIcon:SetShown(test)
    auraIcon.icon:SetTexture(testAura)
  end
  if frame.otherContainer then
    frame.otherContainer.icons[1]:SetShown(test)
    frame.otherContainer.icons[1].icon:SetTexture(testTrinket)
  end
  if frame.raidMark then
    if test then
      SetRaidTargetIconTexture(frame.raidMark.icon, TEST_RAID_MARK)
    end
    frame.raidMark:SetShown(test)
  end
  if frame.castIndicator then
    if test then
      frame.castIndicator.icon:SetTexture(testCast)
      frame.castIndicator.border:SetVertexColor(0, 1, 0, 1)
    end
    frame.castIndicator:SetShown(test)
  end
  frame.innerBorder:SetShown(test)
  frame.outerBorder:SetShown(test)
end

function MF.Test.Set(kind, on)
  if state[kind] == nil then return end
  on = on == true
  state[kind] = on

  EachFrame(kind, function(f)
    if f.UpdateVisibility then f:UpdateVisibility() end
    SetTestIcons(f, on)
    if kind == "raid" and f.orbIcon then
      f.orbIcon:SetShown(on)
    end
  end)

  -- the options window's test-mode buttons show current on/off state in
  -- their label - refresh regardless of who toggled (slash command, the
  -- button itself, or Move Mode auto-enabling one)
  LibStub("AceConfigRegistry-3.0"):NotifyChange("MF")
end

function MF.Test.Toggle(kind)
  MF.Test.Set(kind, not MF.Test.Is(kind))
end
