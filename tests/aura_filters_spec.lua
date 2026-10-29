local t = ...

-- The tokens C_UnitAuras.GetUnitAuras accepts, from AuraUtil.AuraFilters in
-- the retail 12.1.5 FrameXML.
local VALID_TOKENS = {
  HELPFUL = true, HARMFUL = true, RAID = true, INCLUDE_NAME_PLATE_ONLY = true,
  PLAYER = true, CANCELABLE = true, NOT_CANCELABLE = true, MAW = true,
  EXTERNAL_DEFENSIVE = true, CROWD_CONTROL = true, RAID_IN_COMBAT = true,
  RAID_PLAYER_DISPELLABLE = true, BIG_DEFENSIVE = true, IMPORTANT = true,
}

local function Tokens(filter)
  local tokens = {}
  for token in filter:gmatch("[^|]+") do
    tokens[#tokens + 1] = token
  end
  return tokens
end

t.test("every filter key uses only tokens the aura API accepts", function()
  local MF = t.newNamespace("Modules/AuraLogic.lua")
  for _, filter in ipairs(MF.FilterOrder) do
    for _, token in ipairs(Tokens(filter)) do
      t.truthy(VALID_TOKENS[token], filter .. " has invalid token " .. token)
    end
  end
end)

t.test("every filter key names exactly one of HELPFUL or HARMFUL", function()
  local MF = t.newNamespace("Modules/AuraLogic.lua")
  for _, filter in ipairs(MF.FilterOrder) do
    local direction = 0
    for _, token in ipairs(Tokens(filter)) do
      if token == "HELPFUL" or token == "HARMFUL" then
        direction = direction + 1
      end
    end
    t.eq(direction, 1, filter)
  end
end)

t.test("the filter list is the twelve expected keys, player auras first", function()
  local MF = t.newNamespace("Modules/AuraLogic.lua")
  t.listEq(MF.FilterOrder, {
    "HELPFUL|PLAYER|RAID_IN_COMBAT",
    "HARMFUL|PLAYER|RAID_IN_COMBAT",
    "HARMFUL|IMPORTANT",
    "HELPFUL|IMPORTANT",
    "HARMFUL|EXTERNAL_DEFENSIVE",
    "HELPFUL|EXTERNAL_DEFENSIVE",
    "HARMFUL|BIG_DEFENSIVE",
    "HELPFUL|BIG_DEFENSIVE",
    "HARMFUL|CROWD_CONTROL",
    "HELPFUL|CROWD_CONTROL",
    "HARMFUL|RAID_PLAYER_DISPELLABLE",
    "HELPFUL|RAID_PLAYER_DISPELLABLE",
  })
end)
