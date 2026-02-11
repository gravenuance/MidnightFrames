local _, MVPF           = ...

local baseName          = "MVPF_Core"

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
      MVPF_Common.ToggleTestMode("target", not MVPF_TargetTestMode)
      print("MV: target test mode " .. (MVPF_TargetTestMode and "ON" or "OFF"))
    end)
  elseif msg == "party" then
    RunOrDefer("MV_party_test", function()
      MVPF_Common.ToggleTestMode("party", not MVPF_PartyTestMode)
      print("MV: party test mode " .. (MVPF_PartyTestMode and "ON" or "OFF"))
    end)
  elseif msg == "arena" then
    RunOrDefer("MV_arena_test", function()
      MVPF_Common.ToggleTestMode("arena", not MVPF_ArenaTestMode)
      print("MV: arena test mode " .. (MVPF_ArenaTestMode and "ON" or "OFF"))
    end)
  else
    print("Usage: /mv target | party | arena")
  end
end

local ef        = CreateFrame("Frame", baseName .. "Events")
ef:RegisterEvent("PLAYER_REGEN_ENABLED")
ef:RegisterEvent("PLAYER_LOGIN")
ef:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_REGEN_ENABLED" then
    -- optional safety check:
    if InCombatLockdown() then return end

    for key, data in pairs(pendingPostCombat) do
      data.func(unpack(data.args))
      pendingPostCombat[key] = nil
    end
  elseif event == "PLAYER_LOGIN" then
    MVPF.InitConfigAndOptions()
  end
end)

-------------------------------------------------
-- CONFIG + ACE3 OPTIONS
-------------------------------------------------

-- Defaults
local DEFAULT_FILTERS = {
  player = {
    ["HARMFUL|IMPORTANT"]          = true,
    ["HELPFUL|IMPORTANT"]          = true,
    ["HARMFUL|CROWD_CONTROL"]      = true,
    ["HELPFUL|BIG_DEFENSIVE"]      = true,
    ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
    ["PLAYER|RAID_IN_COMBAT"]      = true,
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
    ["HELPFUL|BIG_DEFENSIVE"] = true,
    ["HELPFUL|EXTERNAL_DEFENSIVE"] = true,
    ["PLAYER|RAID_IN_COMBAT"] = true,
  },
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
  ["PLAYER|RAID_IN_COMBAT"] = "Player In Combat (HoTs)",
}

local UNIT_LABELS = {
  player = "Player",
  target = "Target",
  party  = "Party",
}

-- Public accessor for other files
function MVPF.GetUnitFilters(unit)
  if not MVPF_DB or not MVPF_DB.filters then
    return {}
  end
  return MVPF_DB.filters[unit] or {}
end

local _ = LibStub("AceAddon-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function BuildOptionsTable()
  local args = {
    desc = { type = "description", order = 0, name = "Select which aura filters to track per frame." }
  }


  args.testingHeader = { type = "header", name = "Testing", order = 7 }
  args.testing = {
    type = "group",
    name = "Testing",
    inline = true,
    order = 8,
    args = {
      testTarget = {
        type = "execute",
        name = "Toggle Target Test Mode",
        func = function() MVPF_Common.ToggleTestMode("target", not MVPF_TargetTestMode) end
      },
      testParty  = {
        type = "execute",
        name = "Toggle Party Test Mode",
        func = function() MVPF_Common.ToggleTestMode("party", not MVPF_PartyTestMode) end
      },
      testArena  = {
        type = "execute",
        name = "Toggle Arena Test Mode",
        func = function() MVPF_Common.ToggleTestMode("arena", not MVPF_ArenaTestMode) end
      }
    }
  }

  local order = 15
  for unitKey, unitDefaults in pairs(DEFAULT_FILTERS) do
    args[unitKey .. "Header"] = {
      type = "header",
      name = UNIT_LABELS[unitKey] or unitKey,
      order = order
    }
    order = order + 1

    for filterKey in pairs(unitDefaults) do
      args[unitKey .. filterKey] = {
        type = "toggle",
        name = FILTER_LABELS[filterKey] or filterKey,
        order = order,
        get = function()
          local f = MVPF_DB.filters[unitKey]
          return f and f[filterKey]
        end,
        set = function(_, val)
          MVPF_DB.filters[unitKey] = MVPF_DB.filters[unitKey] or {}
          MVPF_DB.filters[unitKey][filterKey] = val
        end
      }
      order = order + 1
    end
    order = order + 4
  end

  return {
    type = "group",
    name = "Auras",
    args = args
  }
end

local CURRENT_VERSION = "4"
function MVPF.InitConfigAndOptions()
  MVPF_DB = MVPF_DB or {}
  MVPF_DB.version = MVPF_DB.version or "1"
  if MVPF_DB.version ~= CURRENT_VERSION then
    wipe(MVPF_DB.filters)
    MVPF_DB.version = CURRENT_VERSION
  end
  MVPF_DB.filters = MVPF_DB.filters or {
    player = {},
    target = {},
    party  = {},
  }

  -- Apply defaults for any missing filter on each unit
  for unit, defaults in pairs(DEFAULT_FILTERS) do
    MVPF_DB.filters[unit] = MVPF_DB.filters[unit] or {}
    for filter, val in pairs(defaults) do
      if MVPF_DB.filters[unit][filter] == nil then
        MVPF_DB.filters[unit][filter] = val
      end
    end
  end

  local Options = BuildOptionsTable()
  AceConfig:RegisterOptionsTable("MVPF", Options)
  AceConfigDialog:AddToBlizOptions("MVPF", "MVPF")
end
