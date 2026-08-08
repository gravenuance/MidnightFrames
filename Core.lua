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

local ef        = CreateFrame("Frame", baseName .. "Events")
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

-- Defaults
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

-- Explicit display order. Do not iterate DEFAULT_FILTERS/unitDefaults with
-- pairs() for anything user-facing: Lua does not guarantee hash-table
-- iteration order, so the panel would reshuffle groups/checkboxes on reload.
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
-- Shared with AuraUtil.lua so aura-slot priority (which filters win the
-- limited icon slots when more categories are enabled than maxAuras) matches
-- this same explicit order, instead of Lua's unspecified pairs() order.
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
  if not MF_DB or not MF_DB.filters then
    return {}
  end
  return MF_DB.filters[unit] or {}
end

local _ = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

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
      name = "Select which aura filters to track per frame using the tabs above. " ..
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

local function BuildFilterArgs(unitKey)
  local args = {}
  local order = 1
  for _, filterKey in ipairs(FILTER_ORDER) do
    args[filterKey] = {
      type = "toggle",
      name = FILTER_LABELS[filterKey] or filterKey,
      order = order,
      get = function()
        local f = MF_DB.filters[unitKey]
        return f and f[filterKey]
      end,
      set = function(_, val)
        MF_DB.filters[unitKey] = MF_DB.filters[unitKey] or {}
        MF_DB.filters[unitKey][filterKey] = val
      end,
    }
    order = order + 1
  end
  return args
end

local function BuildOptionsTable()
  local args = {
    general = {
      type = "group",
      name = "General",
      order = 1,
      args = BuildGeneralArgs(),
    },
  }

  local order = 2
  for _, unitKey in ipairs(UNIT_ORDER) do
    args[unitKey] = {
      type = "group",
      name = UNIT_LABELS[unitKey] or unitKey,
      order = order,
      args = BuildFilterArgs(unitKey),
    }
    order = order + 1
  end

  return {
    type = "group",
    name = "Auras",
    childGroups = "tab",
    args = args,
  }
end

local CURRENT_VERSION = "5"
function MF.InitConfigAndOptions()
  MF_DB = MF_DB or {}
  MF_DB.version = MF_DB.version or "1"
  if MF_DB.version ~= CURRENT_VERSION then
    if MF_DB.filters then
      wipe(MF_DB.filters)
    end
    MF_DB.version = CURRENT_VERSION
  end
  MF_DB.filters = MF_DB.filters or {
    player = {},
    target = {},
    party  = {},
    arena  = {},
    boss   = {},
    raid   = {},
  }

  for unit, defaults in pairs(DEFAULT_FILTERS) do
    MF_DB.filters[unit] = MF_DB.filters[unit] or {}
    for filter, val in pairs(defaults) do
      if MF_DB.filters[unit][filter] == nil then
        MF_DB.filters[unit][filter] = val
      end
    end
  end

  local Options = BuildOptionsTable()
  AceConfig:RegisterOptionsTable("MF", Options)
  AceConfigDialog:AddToBlizOptions("MF", "MF")
end
