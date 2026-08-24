local _, MF             = ...

local baseName          = "MF_Core"

local pendingPostCombat = {}

local function RunOrDefer(key, func, ...)
  if InCombatLockdown() then
    print("In combat. Test will be executed after.")
    pendingPostCombat[key] = { func = func, args = { ... } }
  else
    func(...)
  end
end

SLASH_MF1       = "/mf"
SlashCmdList.MF = function(msg)
  msg = msg and msg:lower() or ""

  if msg == "" or msg == "options" or msg == "config" then
    MF.OpenOptions()
  elseif msg == "move" then
    RunOrDefer("MF_move_mode", function()
      MF.ToggleMoveMode()
    end)
  elseif msg == "target" then
    RunOrDefer("MF_target_test", function()
      MF.ToggleTestMode("target", not MF_TargetTestMode)
      print("MF: target test mode " .. (MF_TargetTestMode and "ON" or "OFF"))
    end)
  elseif msg == "focus" then
    RunOrDefer("MF_focus_test", function()
      MF.ToggleTestMode("focus", not MF_FocusTestMode)
      print("MF: focus test mode " .. (MF_FocusTestMode and "ON" or "OFF"))
    end)
  elseif msg == "party" then
    RunOrDefer("MF_party_test", function()
      MF.ToggleTestMode("party", not MF_PartyTestMode)
      print("MF: party test mode " .. (MF_PartyTestMode and "ON" or "OFF"))
    end)
  elseif msg == "arena" then
    RunOrDefer("MF_arena_test", function()
      MF.ToggleTestMode("arena", not MF_ArenaTestMode)
      print("MF: arena test mode " .. (MF_ArenaTestMode and "ON" or "OFF"))
    end)
  elseif msg == "boss" then
    RunOrDefer("MF_boss_test", function()
      MF.ToggleTestMode("boss", not MF_BossTestMode)
      print("MF: boss test mode " .. (MF_BossTestMode and "ON" or "OFF"))
    end)
  elseif msg == "raid" then
    RunOrDefer("MF_raid_test", function()
      MF.ToggleTestMode("raid", not MF_RaidTestMode)
      print("MF: raid test mode " .. (MF_RaidTestMode and "ON" or "OFF"))
    end)
  else
    print("Usage: /mf [options] | move | target | focus | party | raid | arena | boss")
  end
end

local DEFAULT_FILTERS = {
  player = {
    ["HARMFUL|IMPORTANT"] = true,
    ["HELPFUL|IMPORTANT"] = true,
    ["HARMFUL|CROWD_CONTROL"] = true,
    ["HELPFUL|CROWD_CONTROL"] = true,
    ["HARMFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|DISPELLABLE"] = true,
    ["HELPFUL|DISPELLABLE"] = true,
    ["PLAYER|RAID_IN_COMBAT"] = true,
  },

  target = {
    ["HARMFUL|IMPORTANT"] = true,
    ["HELPFUL|IMPORTANT"] = true,
    ["HARMFUL|CROWD_CONTROL"] = true,
    ["HELPFUL|CROWD_CONTROL"] = true,
    ["HARMFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|DISPELLABLE"] = true,
    ["HELPFUL|DISPELLABLE"] = true,
    ["PLAYER|RAID_IN_COMBAT"] = true,
  },

  party = {
    ["HARMFUL|IMPORTANT"] = true,
    ["HELPFUL|IMPORTANT"] = true,
    ["HARMFUL|CROWD_CONTROL"] = true,
    ["HELPFUL|CROWD_CONTROL"] = true,
    ["HARMFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|DISPELLABLE"] = true,
    ["HELPFUL|DISPELLABLE"] = true,
    ["PLAYER|RAID_IN_COMBAT"] = true,
  },

  arena = {
    ["HARMFUL|IMPORTANT"] = true,
    ["HELPFUL|IMPORTANT"] = true,
    ["HARMFUL|CROWD_CONTROL"] = true,
    ["HELPFUL|CROWD_CONTROL"] = true,
    ["HARMFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|DISPELLABLE"] = true,
    ["HELPFUL|DISPELLABLE"] = true,
    ["PLAYER|RAID_IN_COMBAT"] = true,
  },

  boss = {
    ["HARMFUL|IMPORTANT"] = true,
    ["HELPFUL|IMPORTANT"] = true,
    ["HARMFUL|CROWD_CONTROL"] = true,
    ["HELPFUL|CROWD_CONTROL"] = true,
    ["HARMFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|DISPELLABLE"] = true,
    ["HELPFUL|DISPELLABLE"] = true,
    ["PLAYER|RAID_IN_COMBAT"] = true,
  },

  raid = {
    ["HARMFUL|IMPORTANT"] = true,
    ["HELPFUL|IMPORTANT"] = true,
    ["HARMFUL|CROWD_CONTROL"] = true,
    ["HELPFUL|CROWD_CONTROL"] = true,
    ["HARMFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|EXTERNAL_DEFENSIVE"] = true,
    ["HARMFUL|DISPELLABLE"] = true,
    ["HELPFUL|DISPELLABLE"] = true,
    ["PLAYER|RAID_IN_COMBAT"] = true,
  }
}

local FILTER_LABELS = {
  ["HARMFUL|IMPORTANT"] = "Harmful Important",
  ["HELPFUL|IMPORTANT"] = "Helpful Important",
  ["HARMFUL|CROWD_CONTROL"] = "Harmful Crowd Control",
  ["HELPFUL|CROWD_CONTROL"] = "Helpful Crowd Control",
  ["HELPFUL|BIG_DEFENSIVE"] = "Helpful Big Defensives",
  ["HARMFUL|BIG_DEFENSIVE"] = "Harmful Big Defensives",
  ["HELPFUL|EXTERNAL_DEFENSIVE"] = "Helpful External Defensives",
  ["HARMFUL|EXTERNAL_DEFENSIVE"] = "Harmful External Defensives",
  ["HARMFUL|DISPELLABLE"] = "Harmful Dispellable",
  ["HELPFUL|DISPELLABLE"] = "Helpful Dispellable",
  ["PLAYER|RAID_IN_COMBAT"] = "HoTs and DoTs",
}

-- Priority order for which filter wins a limited aura-icon slot when more
-- than one matches (AuraUtil.lua's ResolveFilters/AddAuras) - first wins.
-- Player/HoTs-DoTs is most reliable (self-tracked, always relevant) so it
-- goes first here, even though it displays last in the options pane (see
-- FILTER_DISPLAY_GROUPS below) - these two orderings are deliberately not
-- the same list.
local FILTER_ORDER = {
  "PLAYER|RAID_IN_COMBAT",
  "HARMFUL|IMPORTANT",
  "HELPFUL|IMPORTANT",
  "HARMFUL|EXTERNAL_DEFENSIVE",
  "HELPFUL|EXTERNAL_DEFENSIVE",
  "HARMFUL|BIG_DEFENSIVE",
  "HELPFUL|BIG_DEFENSIVE",
  "HARMFUL|CROWD_CONTROL",
  "HELPFUL|CROWD_CONTROL",
  "HARMFUL|DISPELLABLE",
  "HELPFUL|DISPELLABLE",
}
-- AuraUtil.lua uses this same order for aura-slot priority.
MF.FilterOrder = FILTER_ORDER

-- Options-pane checkbox order (BuildFilterArgs below) - independent of
-- FILTER_ORDER's priority meaning above. Each entry is a group of filter
-- keys rendered together, top to bottom; Important/External Defensive/Big
-- Defensive/Crowd Control/Dispellable lead, Player/HoTs-DoTs trails at the
-- bottom (it's the single oddball category, least intuitive to a new
-- reader). Any filter key that's in FILTER_ORDER but not listed in any
-- group here still gets shown - just appended after everything below -
-- so a filter added later without updating this list doesn't silently
-- disappear from the options pane.
local FILTER_DISPLAY_GROUPS = {
  { "HARMFUL|IMPORTANT", "HELPFUL|IMPORTANT" },
  { "HARMFUL|EXTERNAL_DEFENSIVE", "HELPFUL|EXTERNAL_DEFENSIVE" },
  { "HARMFUL|BIG_DEFENSIVE", "HELPFUL|BIG_DEFENSIVE" },
  { "HARMFUL|CROWD_CONTROL", "HELPFUL|CROWD_CONTROL" },
  { "HARMFUL|DISPELLABLE", "HELPFUL|DISPELLABLE" },
  { "PLAYER|RAID_IN_COMBAT" },
}

-- Flattened FILTER_DISPLAY_GROUPS for BuildFilterArgs to iterate, with any
-- filter present in FILTER_ORDER but missing from a group appended last.
local FILTER_DISPLAY_ORDER = {}
do
  local seen = {}
  for _, group in ipairs(FILTER_DISPLAY_GROUPS) do
    for _, filterKey in ipairs(group) do
      table.insert(FILTER_DISPLAY_ORDER, filterKey)
      seen[filterKey] = true
    end
  end
  for _, filterKey in ipairs(FILTER_ORDER) do
    if not seen[filterKey] then
      table.insert(FILTER_DISPLAY_ORDER, filterKey)
    end
  end
end

local UNIT_LABELS = {
  player = "Player",
  target = "Target",
  focus  = "Focus",
  pet    = "Pet",
  party  = "Party",
  arena  = "Arena",
  boss   = "Boss",
  raid   = "Raid",
}

-- no "focus" here - it doesn't track auras (see Focus.lua), so it has no
-- Auras-tab sub-tab; UNIT_LABELS.focus is still used elsewhere (Sizing
-- tab's manually-positioned note)
local UNIT_ORDER = { "player", "target", "party", "arena", "boss", "raid" }

function MF.GetUnitFilters(unit)
  if not MF.db then return {} end
  return MF.db.profile.filters[unit] or {}
end

local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

StaticPopupDialogs["MF_RELOAD_UI"] = {
  text = "MidnightFrames: reload your UI for this change to take effect.",
  button1 = "Reload Now",
  button2 = "Later",
  OnAccept = function() ReloadUI() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = STATICPOPUP_NUMDIALOGS,
}

function MF.PromptReload()
  StaticPopup_Show("MF_RELOAD_UI")
end

-- Frames are built once at load, from the flat MF.* values FrameUtil.lua
-- sets up - so a size change can't reflow existing frames live. Refresh the
-- flat values for the *next* load and prompt for one.
local function OnSizesMayHaveChanged()
  MF.ApplySizeSettings()
  MF.PromptReload()
end

-- MF_DB used to be a plain table ({ version, filters }), not an AceDB
-- profile store. Salvage any existing filter choices before AceDB:New
-- reshapes the saved variable, so upgrading doesn't reset them.
local function MigrateLegacySavedVariables()
  if type(MF_DB) ~= "table" or MF_DB.profiles or not MF_DB.filters then
    return nil
  end
  return MF_DB.filters
end

function MF.InitDB()
  local legacyFilters = MigrateLegacySavedVariables()

  local sizeDefaults = {}
  for _, def in ipairs(MF.SizeDefinitions) do
    sizeDefaults[def.key] = def.default
  end

  local positionDefaults = {}
  for _, key in ipairs({ "player", "target", "pet", "focus", "party", "arena", "boss", "raid" }) do
    positionDefaults[key] = { x = 0, y = 0, manual = false }
  end

  local defaults = {
    profile = {
      filters = DEFAULT_FILTERS,
      sizes = sizeDefaults,
      positions = positionDefaults,
    },
  }

  -- A literal profile name, not AceDB's "true = one profile per character"
  -- shortcut - keeps every character on one shared "Default" profile
  -- unless they explicitly create their own via the Profiles tab's New/
  -- Copy/Delete UI, which still fully supports character-specific setups.
  --
  -- This call runs twice per session: once here (unconditional, at
  -- file-load time - required, since Party/Player/Arena/Boss/Raid/Target/
  -- Focus.lua construct frames immediately at load and need MF.db/MF.*
  -- ready first), and again from the PLAYER_LOGIN handler below. On this
  -- setup the real MF_DB SavedVariables global ends up bound to a
  -- different table by PLAYER_LOGIN than it was at this first call
  -- (confirmed by comparing table identity directly) - without the second
  -- call, every write here lands on an orphaned table that never gets
  -- saved, which is exactly what was happening before this was found:
  -- every option looked like it "worked" in-session but silently reverted
  -- on the next reload. The second call rebinds MF.db to whatever MF_DB
  -- actually is by PLAYER_LOGIN, which is early enough that the options
  -- panel (the only place the user can actually edit anything) is built
  -- against the correct, persistable table.
  MF.db = AceDB:New("MF_DB", defaults, "Default")

  if legacyFilters then
    for unit, filters in pairs(legacyFilters) do
      MF.db.profile.filters[unit] = MF.db.profile.filters[unit] or {}
      for filterKey, val in pairs(filters) do
        MF.db.profile.filters[unit][filterKey] = val
      end
    end
    -- clear the old top-level keys now that they've been migrated in
    MF_DB.filters = nil
    MF_DB.version = nil
  end

  MF.ApplySizeSettings()
  MF.ApplyPositionSettings()

  MF.db.RegisterCallback(MF, "OnProfileChanged", "OnProfileChanged")
  MF.db.RegisterCallback(MF, "OnProfileCopied", "OnProfileChanged")
  MF.db.RegisterCallback(MF, "OnProfileReset", "OnProfileChanged")
end

function MF.OnProfileChanged()
  OnSizesMayHaveChanged()
  MF.InvalidateFilterCache()
  MF.ApplyPositionSettings()
  if MF.RepositionAllFrames then
    MF.RepositionAllFrames()
  end
  AceConfigRegistry:NotifyChange("MF")
end

-- Must run now, synchronously, not deferred to an event: Party/Player/
-- Arena/Boss/Raid/Target.lua call MF.CreateUnitFrame immediately when they
-- load (not on PLAYER_LOGIN), and that needs MF.db and the flat MF.* size
-- values ready first.
MF.InitDB()

local TEST_MODE_TOGGLES = {
  { key = "target", var = "MF_TargetTestMode", unitLabel = "Target" },
  { key = "focus",  var = "MF_FocusTestMode",  unitLabel = "Focus" },
  { key = "party",  var = "MF_PartyTestMode",  unitLabel = "Party" },
  { key = "arena",  var = "MF_ArenaTestMode",  unitLabel = "Arena" },
  { key = "boss",   var = "MF_BossTestMode",   unitLabel = "Boss" },
  { key = "raid",   var = "MF_RaidTestMode",   unitLabel = "Raid" },
}

local function BuildGeneralArgs()
  local args = {
    desc = {
      type = "description",
      order = 1,
      name = "Select which aura filters to track per frame under the Auras tab. " ..
          "Use the buttons below to preview frame layouts without needing a live target. " ..
          "Type /mf any time to reopen this window.",
    },
    testingHeader = { type = "header", name = "Testing", order = 2 },
  }

  local order = 3
  for _, entry in ipairs(TEST_MODE_TOGGLES) do
    args[entry.key .. "Test"] = {
      type = "execute",
      name = function()
        return (_G[entry.var] and "Disable " or "Enable ") .. entry.unitLabel .. " Test Mode"
      end,
      order = order,
      func = function() MF.ToggleTestMode(entry.key, not _G[entry.var]) end,
    }
    order = order + 1
  end

  args.layoutHeader = { type = "header", name = "Layout", order = order }
  order = order + 1

  args.moveMode = {
    type = "execute",
    name = function() return MF.MoveModeActive and "Exit Move Mode" or "Enter Move Mode" end,
    desc = "Drag frames to reposition them. Party/arena/boss/raid move as one locked group; " ..
        "player, target, and pet move individually.",
    order = order,
    func = function() MF.ToggleMoveMode() end,
  }
  order = order + 1

  args.resetPositions = {
    type = "execute",
    name = "Reset All Positions",
    order = order,
    confirm = true,
    confirmText = "Reset every frame/group back to its slider-driven default position?",
    func = function()
      for _, key in ipairs({ "player", "target", "pet", "focus", "party", "arena", "boss", "raid" }) do
        MF.db.profile.positions[key].manual = false
      end
      MF.ApplyPositionSettings()
      if MF.RepositionAllFrames then
        MF.RepositionAllFrames()
      end
      AceConfigRegistry:NotifyChange("MF")
    end,
  }

  return args
end

-- Which position keys (MF.db.profile.positions) a given "position"-group
-- slider stops affecting once that key has been manually placed in Move
-- Mode. Only the keys that actually share one of these sliders need an
-- entry - RosterFrameSpacing, for instance, keeps applying regardless of
-- manual placement (it's intra-group spacing, not the group's origin).
local POSITION_SLIDER_KEYS = {
  RosterFrameOffsetX = { "party", "arena", "boss", "raid" },
  PrimaryFrameOffsetX = { "player", "target" },
  PetSpace = { "pet" },
  FocusSpace = { "focus" },
}

local function ManuallyPositionedNote(positionKeys)
  if not positionKeys then return "" end
  local names = {}
  for _, key in ipairs(positionKeys) do
    local pos = MF.db.profile.positions[key]
    if pos and pos.manual then
      table.insert(names, UNIT_LABELS[key] or key)
    end
  end
  if #names == 0 then return "" end
  return "\n\n|cffff8800Currently has no effect on: " .. table.concat(names, ", ") ..
      " - manually positioned via Move Mode. Reset All Positions (below) restores this slider for them.|r"
end

local SIZING_GROUPS = {
  { key = "size", header = "Frame Sizes" },
  { key = "position", header = "Position & Spacing",
    desc = "Where each frame or group starts out. Dragging something in Move Mode (General tab) " ..
        "overrides its slider here until you use Reset All Positions." },
  { key = "finetune", header = "Fine-Tuning" },
}

local function BuildSizingArgs()
  local args = {
    desc = {
      type = "description",
      order = 1,
      name = "Frames are built once when the UI loads, so changes here need a UI reload to take effect.",
    },
  }

  local order = 2
  for _, groupInfo in ipairs(SIZING_GROUPS) do
    args[groupInfo.key .. "Header"] = { type = "header", name = groupInfo.header, order = order }
    order = order + 1

    if groupInfo.desc then
      args[groupInfo.key .. "GroupDesc"] = { type = "description", name = groupInfo.desc, order = order }
      order = order + 1
    end

    for _, def in ipairs(MF.SizeDefinitions) do
      if def.group == groupInfo.key then
        local positionKeys = POSITION_SLIDER_KEYS[def.key]
        args[def.key] = {
          type = "range",
          name = def.name,
          desc = positionKeys and function() return def.desc .. ManuallyPositionedNote(positionKeys) end or def.desc,
          min = def.min,
          max = def.max,
          step = 1,
          order = order,
          get = function() return MF.db.profile.sizes[def.key] end,
          set = function(_, val)
            MF.db.profile.sizes[def.key] = val
            OnSizesMayHaveChanged()
          end,
        }
        order = order + 1
      end
    end
  end

  args.resetSizes = {
    type = "execute",
    name = "Reset to Defaults",
    order = order,
    confirm = true,
    confirmText = "Reset all sizing options to their defaults?",
    func = function()
      for _, def in ipairs(MF.SizeDefinitions) do
        MF.db.profile.sizes[def.key] = def.default
      end
      OnSizesMayHaveChanged()
      AceConfigRegistry:NotifyChange("MF")
    end,
  }

  return args
end

local function BuildFilterArgs(unitKey)
  local args = {
    desc = {
      type = "description",
      order = 1,
      name = "These are narrow, Blizzard-curated categories, not \"every buff/debuff\" - " ..
          "with none of them checked, every buff and debuff shows instead of nothing.",
    },
  }
  local order = 2
  for _, filterKey in ipairs(FILTER_DISPLAY_ORDER) do
    args[filterKey] = {
      type = "toggle",
      name = FILTER_LABELS[filterKey] or filterKey,
      order = order,
      get = function()
        local f = MF.db.profile.filters[unitKey]
        return f and f[filterKey]
      end,
      set = function(_, val)
        MF.db.profile.filters[unitKey] = MF.db.profile.filters[unitKey] or {}
        MF.db.profile.filters[unitKey][filterKey] = val
        MF.InvalidateFilterCache(unitKey)
      end,
    }
    order = order + 1
  end
  return args
end

local function BuildOptionsTable()
  local auraArgs = {}
  local order = 1
  for _, unitKey in ipairs(UNIT_ORDER) do
    auraArgs[unitKey] = {
      type = "group",
      name = UNIT_LABELS[unitKey] or unitKey,
      order = order,
      args = BuildFilterArgs(unitKey),
    }
    order = order + 1
  end

  local args = {
    general = {
      type = "group",
      name = "General",
      order = 1,
      args = BuildGeneralArgs(),
    },
    sizing = {
      type = "group",
      name = "Sizing",
      order = 2,
      args = BuildSizingArgs(),
    },
    auras = {
      type = "group",
      name = "Auras",
      order = 3,
      childGroups = "tab",
      args = auraArgs,
    },
    profiles = AceDBOptions:GetOptionsTable(MF.db),
  }
  args.profiles.order = 4

  return {
    type = "group",
    name = "MidnightFrames",
    args = args,
  }
end

function MF.InitConfigAndOptions()
  local Options = BuildOptionsTable()
  AceConfig:RegisterOptionsTable("MF", Options)
  -- Blizzard Settings entry, for anyone who goes looking there out of habit -
  -- it just points at /mf, which opens the real (standalone, resizable,
  -- not squeezed into Blizzard's settings frame) window below.
  AceConfigDialog:AddToBlizOptions("MF", "MidnightFrames")
  AceConfigDialog:SetDefaultSize("MF", 520, 520)
end

-- The Blizzard-Settings-embedded panel above is kept for discoverability,
-- but this standalone AceGUI window is the actual polished experience:
-- its own title bar, draggable, resizable, not fighting Blizzard's cramped
-- settings frame for space.
function MF.OpenOptions()
  if AceConfigDialog.OpenFrames["MF"] then
    AceConfigDialog:Close("MF")
  else
    AceConfigDialog:Open("MF")
  end
end

local ef = CreateFrame("Frame", baseName .. "Events")
ef:RegisterEvent("PLAYER_REGEN_ENABLED")
ef:RegisterEvent("PLAYER_LOGIN")
ef:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_REGEN_ENABLED" then
    if InCombatLockdown() then return end

    for key, data in pairs(pendingPostCombat) do
      data.func(unpack(data.args))
      pendingPostCombat[key] = nil
    end
  elseif event == "PLAYER_LOGIN" then
    -- Rebind MF.db: on this setup, the real MF_DB global ends up a
    -- different table by PLAYER_LOGIN than it was when MF.InitDB() first
    -- ran at file-load time (confirmed via identity checks - MF.db.sv and
    -- _G.MF_DB point at two different tables by this point), so anything
    -- written through the first MF.db never reaches what actually gets
    -- saved. Frame construction already ran on whatever the first call
    -- resolved (unavoidable - those files load before this event fires),
    -- but everything the user can actually edit lives in the options
    -- panel, built below, so rebinding here before that happens is enough
    -- to fix persistence for all of it.
    MF.InitDB()
    MF.InitConfigAndOptions()
  end
end)
