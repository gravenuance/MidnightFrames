local addonName, MF  = ...

local baseName          = "MF_Core"

local pendingPostCombat = {}

-- Queues func for PLAYER_REGEN_ENABLED, or runs it now when out of combat.
-- A later call with the same key replaces the queued one.
function MF.RunAfterCombat(key, func, ...)
  if InCombatLockdown() then
    pendingPostCombat[key] = { func = func, args = { ... } }
  else
    func(...)
  end
end

local function RunOrDefer(key, func, ...)
  if InCombatLockdown() then
    print("In combat. Test will be executed after.")
  end
  MF.RunAfterCombat(key, func, ...)
end

-- Frame files register their construction here instead of building at file
-- load: WoW assigns SavedVariables after the files load and before this
-- addon's ADDON_LOADED, so sizes and positions are only readable from then on.
local initCallbacks = {}

function MF.OnInit(build)
  table.insert(initCallbacks, build)
end

SLASH_MF1       = "/mf"
SlashCmdList.MF = function(msg)
  msg = msg and msg:lower() or ""

  if msg == "" or msg == "options" or msg == "config" then
    MF.OpenOptions()
    return
  end

  if msg == "move" then
    RunOrDefer("MF_move_mode", function() MF.ToggleMoveMode() end)
    return
  end

  for _, kind in ipairs(MF.Test.Kinds) do
    if msg == kind then
      RunOrDefer("MF_" .. kind .. "_test", function()
        MF.Test.Toggle(kind)
        print("MF: " .. kind .. " test mode " .. (MF.Test.Is(kind) and "ON" or "OFF"))
      end)
      return
    end
  end

  print("Usage: /mf [options] | move | target | focus | party | raid | arena | boss")
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

-- Every aura category starts enabled on every unit.
local DEFAULT_FILTERS = {}
for _, unitKey in ipairs(UNIT_ORDER) do
  local enabled = {}
  for _, filterKey in ipairs(MF.FilterOrder) do
    enabled[filterKey] = true
  end
  DEFAULT_FILTERS[unitKey] = enabled
end

local FILTER_LABELS = {
  ["HARMFUL|IMPORTANT"] = "Harmful Important",
  ["HELPFUL|IMPORTANT"] = "Helpful Important",
  ["HARMFUL|CROWD_CONTROL"] = "Harmful Crowd Control",
  ["HELPFUL|CROWD_CONTROL"] = "Helpful Crowd Control",
  ["HELPFUL|BIG_DEFENSIVE"] = "Helpful Big Defensives",
  ["HARMFUL|BIG_DEFENSIVE"] = "Harmful Big Defensives",
  ["HELPFUL|EXTERNAL_DEFENSIVE"] = "Helpful External Defensives",
  ["HARMFUL|EXTERNAL_DEFENSIVE"] = "Harmful External Defensives",
  ["HARMFUL|RAID_PLAYER_DISPELLABLE"] = "Harmful Dispellable",
  ["HELPFUL|RAID_PLAYER_DISPELLABLE"] = "Helpful Dispellable",
  ["HELPFUL|PLAYER|RAID_IN_COMBAT"] = "HoTs",
  ["HARMFUL|PLAYER|RAID_IN_COMBAT"] = "DoTs",
}

-- Options-pane checkbox order (BuildFilterArgs below) - independent of
-- MF.FilterOrder's priority meaning (Modules/AuraLogic.lua). Each entry is a
-- group of filter keys rendered together, top to bottom; HoTs/DoTs trail at
-- the bottom (the single oddball category, least intuitive to a new reader).
-- Any filter key that's in MF.FilterOrder but not listed in any group here
-- still gets shown - just appended after everything below - so a filter
-- added later without updating this list doesn't silently disappear from
-- the options pane.
local FILTER_DISPLAY_GROUPS = {
  { "HARMFUL|IMPORTANT", "HELPFUL|IMPORTANT" },
  { "HARMFUL|EXTERNAL_DEFENSIVE", "HELPFUL|EXTERNAL_DEFENSIVE" },
  { "HARMFUL|BIG_DEFENSIVE", "HELPFUL|BIG_DEFENSIVE" },
  { "HARMFUL|CROWD_CONTROL", "HELPFUL|CROWD_CONTROL" },
  { "HARMFUL|RAID_PLAYER_DISPELLABLE", "HELPFUL|RAID_PLAYER_DISPELLABLE" },
  { "HELPFUL|PLAYER|RAID_IN_COMBAT", "HARMFUL|PLAYER|RAID_IN_COMBAT" },
}

-- Flattened FILTER_DISPLAY_GROUPS for BuildFilterArgs to iterate, with any
-- filter present in MF.FilterOrder but missing from a group appended last.
local FILTER_DISPLAY_ORDER = {}
do
  local seen = {}
  for _, group in ipairs(FILTER_DISPLAY_GROUPS) do
    for _, filterKey in ipairs(group) do
      table.insert(FILTER_DISPLAY_ORDER, filterKey)
      seen[filterKey] = true
    end
  end
  for _, filterKey in ipairs(MF.FilterOrder) do
    if not seen[filterKey] then
      table.insert(FILTER_DISPLAY_ORDER, filterKey)
    end
  end
end

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
}

function MF.PromptReload()
  StaticPopup_Show("MF_RELOAD_UI")
end

-- Frames are built once at ADDON_LOADED, from the flat MF.* values
-- FrameUtil.lua sets up - so a size change can't reflow existing frames
-- live. Refresh the flat values for the *next* load and prompt for one.
local function OnSizesMayHaveChanged()
  MF.ApplySizeSettings()
  MF.PromptReload()
end

function MF.InitDB()
  -- Migrate the raw saved table first (Modules/Migrations.lua), then bind it.
  local status, storedVersion = MF.MigrateSavedVariables(MF_DB)
  if status == "newer" then
    print("MidnightFrames: settings are from a newer version (" .. storedVersion .. "); some may reset.")
  end

  local sizeDefaults = {}
  for _, def in ipairs(MF.SizeDefinitions) do
    sizeDefaults[def.key] = def.default
  end

  local positionDefaults = {}
  for _, key in ipairs({ "player", "target", "pet", "focus", "party", "arena", "boss", "raid" }) do
    positionDefaults[key] = { x = 0, y = 0, manual = false }
  end

  -- No global.schemaVersion default: AceDB strips values equal to their
  -- default on logout, so the version would never be saved.
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
  -- Must run from ADDON_LOADED: before it, MF_DB is still the empty global
  -- AceDB creates, and WoW then replaces it with the saved table.
  MF.db = AceDB:New("MF_DB", defaults, "Default")

  -- A fresh install has nothing to migrate; record the version explicitly.
  if status == "fresh" then
    MF.db.global.schemaVersion = MF.DB_SCHEMA_VERSION
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

local TEST_KINDS = {}
for _, kind in ipairs(MF.Test.Kinds) do
  TEST_KINDS[kind] = true
end

-- Tooltips only where the label alone doesn't say what the filter shows.
local FILTER_DESCS = {
  ["HARMFUL|RAID_PLAYER_DISPELLABLE"] = "Debuffs you can dispel.",
  ["HELPFUL|RAID_PLAYER_DISPELLABLE"] = "Buffs you can dispel.",
  ["HELPFUL|PLAYER|RAID_IN_COMBAT"] = "Your own heals over time.",
  ["HARMFUL|PLAYER|RAID_IN_COMBAT"] = "Your own damage over time.",
}

-- Options window styling, defined once. The accent is the default health-bar
-- teal; harmful/helpful tints keep the two aura directions apart at a glance
-- (the words stay in the label, so colour is never the only cue).
local COLOR_ACCENT  = "|cff40e0d1"
local COLOR_HARMFUL = "|cffff7070"
local COLOR_HELPFUL = "|cff70ff70"

local function Colored(color, text)
  return color .. text .. "|r"
end

-- Tree entries, in display order. Every frame type has its own entry; the
-- icons are stock game textures.
local TAB_ORDER = { "player", "pet", "target", "focus", "party", "arena", "boss", "raid" }
local TAB_ICONS = {
  general  = "Interface\\Icons\\INV_Misc_Gear_01",
  player   = "Interface\\Icons\\Spell_Holy_PowerWordShield",
  pet      = "Interface\\Icons\\Ability_Hunter_BeastCall",
  target   = "Interface\\Icons\\Ability_Hunter_SniperShot",
  focus    = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
  party    = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
  arena    = "Interface\\Icons\\Achievement_Arena_2v2_1",
  boss     = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
  raid     = "Interface\\Icons\\INV_Misc_GroupLooking",
  profiles = "Interface\\Icons\\INV_Misc_Note_01",
}

local SIZE_SECTIONS = {
  { key = "size", title = "Size" },
  { key = "position", title = "Position" },
  { key = "finetune", title = "Fine-tuning" },
}

local function NewCounter()
  local value = 0
  return function()
    value = value + 1
    return value
  end
end

local function SectionName(title)
  return Colored(COLOR_ACCENT, title)
end

local function ShowsTab(def, tabKey)
  for _, tab in ipairs(def.tabs) do
    if tab == tabKey then return true end
  end
  return false
end

-- One range per size definition shown on `tabKey` in the given section.
local function BuildSizeRanges(tabKey, sectionKey, nextOrder)
  local ranges = {}
  for _, def in ipairs(MF.SizeDefinitions) do
    if def.group == sectionKey and ShowsTab(def, tabKey) then
      ranges[def.key] = {
        type = "range",
        name = def.name,
        desc = def.desc,
        min = def.min,
        max = def.max,
        step = 1,
        order = nextOrder(),
        width = "full",
        get = function() return MF.db.profile.sizes[def.key] end,
        set = function(_, val)
          MF.db.profile.sizes[def.key] = val
          OnSizesMayHaveChanged()
        end,
      }
    end
  end
  return ranges
end

local function HasEntries(tbl)
  return next(tbl) ~= nil
end

local function BuildTestToggle(kind)
  return {
    type = "execute",
    name = function()
      return (MF.Test.Is(kind) and "Disable " or "Enable ") .. (UNIT_LABELS[kind] or kind) .. " Test Mode"
    end,
    desc = "Show placeholder frames while adjusting the layout.",
    width = "double",
    order = 1,
    func = function() MF.Test.Toggle(kind) end,
  }
end

local function FilterLabel(filterKey)
  local color = filterKey:find("^HARMFUL") and COLOR_HARMFUL or COLOR_HELPFUL
  return Colored(color, FILTER_LABELS[filterKey] or filterKey)
end

local function BuildFilterArgs(unitKey)
  local args = {}
  local nextOrder = NewCounter()
  for _, filterKey in ipairs(FILTER_DISPLAY_ORDER) do
    args[filterKey] = {
      type = "toggle",
      name = FilterLabel(filterKey),
      desc = FILTER_DESCS[filterKey],
      order = nextOrder(),
      width = "half",
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
  end
  return args
end

-- Test mode, then Size / Position / Auras for whichever of those the frame
-- type has. Sections are inline groups so related controls stay boxed.
local function BuildUnitArgs(tabKey)
  local args = {}
  local nextOrder = NewCounter()

  if TEST_KINDS[tabKey] then
    args.test = {
      type = "group",
      inline = true,
      name = SectionName("Test Mode"),
      order = nextOrder(),
      args = { [tabKey .. "Test"] = BuildTestToggle(tabKey) },
    }
  end

  for _, section in ipairs(SIZE_SECTIONS) do
    local ranges = BuildSizeRanges(tabKey, section.key, NewCounter())
    if HasEntries(ranges) then
      args[section.key] = {
        type = "group",
        inline = true,
        name = SectionName(section.title),
        order = nextOrder(),
        args = ranges,
      }
    end
  end

  if DEFAULT_FILTERS[tabKey] then
    args.auras = {
      type = "group",
      inline = true,
      name = SectionName("Auras"),
      order = nextOrder(),
      args = BuildFilterArgs(tabKey),
    }
  end

  return args
end

local function ResetAllPositions()
  for _, key in ipairs({ "player", "target", "pet", "focus", "party", "arena", "boss", "raid" }) do
    MF.db.profile.positions[key].manual = false
  end
  MF.ApplyPositionSettings()
  if MF.RepositionAllFrames then
    MF.RepositionAllFrames()
  end
  AceConfigRegistry:NotifyChange("MF")
end

local function ResetAllSizes()
  for _, def in ipairs(MF.SizeDefinitions) do
    MF.db.profile.sizes[def.key] = def.default
  end
  OnSizesMayHaveChanged()
  AceConfigRegistry:NotifyChange("MF")
end

local function BuildGeneralArgs()
  local nextOrder = NewCounter()
  local args = {
    layoutHeader = { type = "header", name = SectionName("Layout"), order = nextOrder() },
    moveMode = {
      type = "execute",
      name = function() return MF.MoveModeActive and "Exit Move Mode" or "Enter Move Mode" end,
      desc = "Drag frames where you want them.",
      order = nextOrder(),
      func = function() MF.ToggleMoveMode() end,
    },
    resetPositions = {
      type = "execute",
      name = "Reset all positions",
      desc = "Put every frame back at its default position.",
      order = nextOrder(),
      confirm = true,
      confirmText = "Reset every frame to its default position?",
      func = ResetAllPositions,
    },
    resetSizes = {
      type = "execute",
      name = "Reset all sizes",
      desc = "Restore every size and spacing to its default.",
      order = nextOrder(),
      confirm = true,
      confirmText = "Reset all sizes and spacing to their defaults?",
      func = ResetAllSizes,
    },
    finetuneHeader = { type = "header", name = SectionName("Fine-tuning"), order = nextOrder() },
  }
  for key, range in pairs(BuildSizeRanges("general", "finetune", nextOrder)) do
    args[key] = range
  end
  return args
end

local function BuildOptionsTable()
  local args = {
    general = {
      type = "group",
      name = "General",
      icon = TAB_ICONS.general,
      order = 1,
      args = BuildGeneralArgs(),
    },
  }

  local order = 1
  for _, tabKey in ipairs(TAB_ORDER) do
    order = order + 1
    args[tabKey] = {
      type = "group",
      name = UNIT_LABELS[tabKey] or tabKey,
      icon = TAB_ICONS[tabKey],
      order = order,
      args = BuildUnitArgs(tabKey),
    }
  end

  args.profiles = AceDBOptions:GetOptionsTable(MF.db)
  args.profiles.order = order + 1
  args.profiles.icon = TAB_ICONS.profiles

  return {
    type = "group",
    name = "MidnightFrames",
    childGroups = "tree",
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
  AceConfigDialog:SetDefaultSize("MF", 680, 560)
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
ef:RegisterEvent("ADDON_LOADED")
ef:RegisterEvent("PLAYER_REGEN_ENABLED")
ef:SetScript("OnEvent", function(self, event, loadedAddon)
  if event == "ADDON_LOADED" then
    if loadedAddon ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    MF.InitDB()
    for _, build in ipairs(initCallbacks) do
      build()
    end
    MF.InitConfigAndOptions()
  elseif event == "PLAYER_REGEN_ENABLED" then
    if InCombatLockdown() then return end

    -- Swap first so a callback that queues more work isn't lost mid-iteration.
    local queued = pendingPostCombat
    pendingPostCombat = {}
    for _, data in pairs(queued) do
      data.func(unpack(data.args))
    end
  end
end)
