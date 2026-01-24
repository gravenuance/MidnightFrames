local addonName, MVPF   = ...

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
    -- Helpful
    ["HELPFUL CANCELABLE"]        = false,
    ["HELPFUL PLAYER CANCELABLE"] = false,
    ["HELPFUL RAID CANCELABLE"]   = true,

    -- Harmful
    ["HARMFUL"]                   = false,
    ["HARMFUL PLAYER"]            = false,
    ["HARMFUL RAID"]              = true,
  },

  target = {
    -- Helpful
    ["HELPFUL"]                   = false,
    ["HELPFUL PLAYER CANCELABLE"] = true,
    ["HELPFUL RAID CANCELABLE"]   = true,

    -- Harmful
    ["HARMFUL"]                   = false,
    ["HARMFUL PLAYER"]            = true,
    ["HARMFUL RAID"]              = true,
  },

  party = {
    -- Helpful
    ["HELPFUL CANCELABLE"]        = false,
    ["HELPFUL PLAYER CANCELABLE"] = true,
    ["HELPFUL RAID CANCELABLE"]   = false,

    -- Harmful
    ["HARMFUL"]                   = false,
    ["HARMFUL PLAYER"]            = false,
    ["HARMFUL RAID"]              = true,
  },
}

local FILTER_LABELS = {
  ["HELPFUL"]                   = "Helpful (Any)",
  ["HELPFUL CANCELABLE"]        = "Helpful (Any, Cancelable)",
  ["HELPFUL PLAYER"]            = "Helpful (Player)",
  ["HELPFUL PLAYER CANCELABLE"] = "Helpful (Player, Cancelable)",
  ["HELPFUL RAID"]              = "Helpful (Raid)",
  ["HELPFUL RAID CANCELABLE"]   = "Helpful (Raid, Cancelable)",

  ["HARMFUL"]                   = "Harmful (Any)",
  ["HARMFUL PLAYER"]            = "Harmful (Player)",
  ["HARMFUL RAID"]              = "Harmful (Raid)",
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
    desc = {
      type  = "description",
      order = 0,
      name  = "Select which aura filters to track per frame.\n",
    },
  }

  local order = 10

  for unitKey, unitDefaults in pairs(DEFAULT_FILTERS) do
    -- Header per unit (Player, Target, Party)
    args[unitKey .. "Header"] = {
      type  = "header",
      name  = UNIT_LABELS[unitKey] or unitKey,
      order = order,
    }
    order = order + 1

    -- One toggle per filter defined in DEFAULT_FILTERS[unitKey]
    for filterKey, _ in pairs(unitDefaults) do
      local label = FILTER_LABELS[filterKey] or filterKey

      args[unitKey .. "_" .. filterKey] = {
        type  = "toggle",
        name  = label,
        order = order,
        get   = function()
          local f = MVPF_DB.filters[unitKey]
          return f and f[filterKey]
        end,
        set   = function(_, val)
          MVPF_DB.filters[unitKey][filterKey] = val
        end,
      }

      order = order + 1
    end

    order = order + 5 -- spacing between groups
  end

  local Options = {
    type = "group",
    name = "MVPF",
    args = {
      general = {
        type  = "group",
        name  = "Auras",
        order = 1,
        args  = args,
      },
    },
  }

  return Options
end

function MVPF.InitConfigAndOptions()
  MVPF_DB = MVPF_DB or {}
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

  -- Build the Ace3 options table dynamically from DEFAULT_FILTERS
  local Options = BuildOptionsTable()

  AceConfig:RegisterOptionsTable("MVPF", Options)
  AceConfigDialog:AddToBlizOptions("MVPF", "MVPF")
end
