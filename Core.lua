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

  if msg == "target" then
    RunOrDefer("MF_target_test", function()
      MF.ToggleTestMode("target", not MF_TargetTestMode)
      print("MF: target test mode " .. (MF_TargetTestMode and "ON" or "OFF"))
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
    print("Usage: /mf target | party | raid | arena | boss")
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
  ["PLAYER|RAID_IN_COMBAT"] = "HoTs and DoTs",
}

-- Fixed display order, since pairs() order isn't guaranteed.
local FILTER_ORDER = {
  "HARMFUL|IMPORTANT",
  "HELPFUL|IMPORTANT",
  "HARMFUL|CROWD_CONTROL",
  "HELPFUL|CROWD_CONTROL",
  "HARMFUL|BIG_DEFENSIVE",
  "HELPFUL|BIG_DEFENSIVE",
  "HARMFUL|EXTERNAL_DEFENSIVE",
  "HELPFUL|EXTERNAL_DEFENSIVE",
  "PLAYER|RAID_IN_COMBAT",
}
-- AuraUtil.lua uses this same order for aura-slot priority.
MF.FilterOrder = FILTER_ORDER

local UNIT_LABELS = {
  player = "Player",
  target = "Target",
  party  = "Party",
  arena  = "Arena",
  boss   = "Boss",
  raid   = "Raid",
}

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

  local defaults = {
    profile = {
      filters = DEFAULT_FILTERS,
      sizes = sizeDefaults,
    },
  }

  MF.db = AceDB:New("MF_DB", defaults, true)

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

  MF.db.RegisterCallback(MF, "OnProfileChanged", "OnProfileChanged")
  MF.db.RegisterCallback(MF, "OnProfileCopied", "OnProfileChanged")
  MF.db.RegisterCallback(MF, "OnProfileReset", "OnProfileChanged")
end

function MF.OnProfileChanged()
  OnSizesMayHaveChanged()
  AceConfigRegistry:NotifyChange("MF")
end

-- Must run now, synchronously, not deferred to an event: Party/Player/
-- Arena/Boss/Raid/Target.lua call MF.CreateUnitFrame immediately when they
-- load (not on PLAYER_LOGIN), and that needs MF.db and the flat MF.* size
-- values ready first.
MF.InitDB()

local TEST_MODE_TOGGLES = {
  { key = "target", var = "MF_TargetTestMode", label = "Toggle Target Test Mode" },
  { key = "party",  var = "MF_PartyTestMode",  label = "Toggle Party Test Mode" },
  { key = "arena",  var = "MF_ArenaTestMode",  label = "Toggle Arena Test Mode" },
  { key = "boss",   var = "MF_BossTestMode",   label = "Toggle Boss Test Mode" },
  { key = "raid",   var = "MF_RaidTestMode",   label = "Toggle Raid Test Mode" },
}

local function BuildGeneralArgs()
  local args = {
    desc = {
      type = "description",
      order = 1,
      name = "Select which aura filters to track per frame under the Auras tab. " ..
          "Use the buttons below to preview frame layouts without needing a live target.",
    },
    testingHeader = { type = "header", name = "Testing", order = 2 },
  }

  local order = 3
  for _, entry in ipairs(TEST_MODE_TOGGLES) do
    args[entry.key .. "Test"] = {
      type = "execute",
      name = entry.label,
      order = order,
      func = function() MF.ToggleTestMode(entry.key, not _G[entry.var]) end,
    }
    order = order + 1
  end

  return args
end

local function BuildSizingArgs()
  local args = {
    desc = {
      type = "description",
      order = 1,
      name = "Frames are built once when the UI loads, so changes here need a UI reload to take effect.",
    },
  }

  local order = 2
  for _, def in ipairs(MF.SizeDefinitions) do
    args[def.key] = {
      type = "range",
      name = def.name,
      desc = def.desc,
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
  local args = {}
  local order = 1
  for _, filterKey in ipairs(FILTER_ORDER) do
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
  AceConfigDialog:AddToBlizOptions("MF", "MidnightFrames")
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
    MF.InitConfigAndOptions()
  end
end)
