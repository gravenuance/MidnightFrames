local _, MV             = ...

local baseName          = "MV_Core"

local pendingPostCombat = {}

local function RunOrDefer(key, func, ...)
  if InCombatLockdown() then
    print("In combat. Test will be executed after.")
    pendingPostCombat[key] = { func = func, args = { ... } }
  else
    func(...)
  end
end

SLASH_MV1       = "/mv"
SlashCmdList.MV = function(msg)
  msg = msg and msg:lower() or ""

  if msg == "target" then
    RunOrDefer("MV_target_test", function()
      MV.ToggleTestMode("target", not MV_TargetTestMode)
      print("MV: target test mode " .. (MV_TargetTestMode and "ON" or "OFF"))
    end)
  elseif msg == "party" then
    RunOrDefer("MV_party_test", function()
      MV.ToggleTestMode("party", not MV_PartyTestMode)
      print("MV: party test mode " .. (MV_PartyTestMode and "ON" or "OFF"))
    end)
  elseif msg == "arena" then
    RunOrDefer("MV_arena_test", function()
      MV.ToggleTestMode("arena", not MV_ArenaTestMode)
      print("MV: arena test mode " .. (MV_ArenaTestMode and "ON" or "OFF"))
    end)
  elseif msg == "boss" then
    RunOrDefer("MV_boss_test", function()
      MV.ToggleTestMode("boss", not MV_BossTestMode)
      print("MV: boss test mode " .. (MV_BossTestMode and "ON" or "OFF"))
    end)
  elseif msg == "raid" then
    RunOrDefer("MV_raid_test", function()
      MV.ToggleTestMode("raid", not MV_RaidTestMode)
      print("MV: raid test mode " .. (MV_RaidTestMode and "ON" or "OFF"))
    end)
  else
    print("Usage: /mv target | party | raid | arena | boss")
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
    MV.InitConfigAndOptions()
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

local UNIT_LABELS = {
  player = "Player",
  target = "Target",
  party  = "Party",
  arena  = "Arena",
  boss   = "Boss",
  raid   = "Raid",
}

local UNIT_ORDER = { "player", "target", "party", "arena", "boss", "raid" }

function MV.GetUnitFilters(unit)
  if not MV_DB or not MV_DB.filters then
    return {}
  end
  return MV_DB.filters[unit] or {}
end

local _ = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local TEST_MODE_TOGGLES = {
  { key = "target", var = "MV_TargetTestMode", label = "Toggle Target Test Mode" },
  { key = "party",  var = "MV_PartyTestMode",  label = "Toggle Party Test Mode" },
  { key = "arena",  var = "MV_ArenaTestMode",  label = "Toggle Arena Test Mode" },
  { key = "boss",   var = "MV_BossTestMode",   label = "Toggle Boss Test Mode" },
  { key = "raid",   var = "MV_RaidTestMode",   label = "Toggle Raid Test Mode" },
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
      func = function() MV.ToggleTestMode(entry.key, not _G[entry.var]) end,
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
        local f = MV_DB.filters[unitKey]
        return f and f[filterKey]
      end,
      set = function(_, val)
        MV_DB.filters[unitKey] = MV_DB.filters[unitKey] or {}
        MV_DB.filters[unitKey][filterKey] = val
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
function MV.InitConfigAndOptions()
  MV_DB = MV_DB or {}
  MV_DB.version = MV_DB.version or "1"
  if MV_DB.version ~= CURRENT_VERSION then
    if MV_DB.filters then
      wipe(MV_DB.filters)
    end
    MV_DB.version = CURRENT_VERSION
  end
  MV_DB.filters = MV_DB.filters or {
    player = {},
    target = {},
    party  = {},
    arena  = {},
    boss   = {},
    raid   = {},
  }

  for unit, defaults in pairs(DEFAULT_FILTERS) do
    MV_DB.filters[unit] = MV_DB.filters[unit] or {}
    for filter, val in pairs(defaults) do
      if MV_DB.filters[unit][filter] == nil then
        MV_DB.filters[unit][filter] = val
      end
    end
  end

  local Options = BuildOptionsTable()
  AceConfig:RegisterOptionsTable("MV", Options)
  AceConfigDialog:AddToBlizOptions("MV", "MV")
end
