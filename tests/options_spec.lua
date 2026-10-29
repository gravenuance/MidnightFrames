local t = ...

-- Builds the real AceConfig options table from Core.lua against stand-ins for
-- the Ace libraries and WoW globals, then checks its shape and that the
-- controls still read and write the same saved-variable paths.

local captured

local function Stubs()
  local noop = function() end
  local aceDbOptions = { GetOptionsTable = function() return { type = "group", name = "Profiles", args = {} } end }
  local aceConfig = { RegisterOptionsTable = function(_, _, options) captured = options end }
  local aceDialog = { AddToBlizOptions = noop, SetDefaultSize = noop, OpenFrames = {} }
  local libs = {
    ["AceDB-3.0"] = {},
    ["AceDBOptions-3.0"] = aceDbOptions,
    ["AceConfig-3.0"] = aceConfig,
    ["AceConfigDialog-3.0"] = aceDialog,
    ["AceConfigRegistry-3.0"] = { NotifyChange = noop },
  }
  return {
    LibStub = function(name) return libs[name] end,
    StaticPopupDialogs = {},
    StaticPopup_Show = noop,
    SlashCmdList = {},
    InCombatLockdown = function() return false end,
    CreateFrame = function()
      return { RegisterEvent = noop, UnregisterEvent = noop, SetScript = noop }
    end,
    Enum = { LuaCurveType = { Linear = 0, Step = 1 } },
  }
end

local function BuildOptions()
  local MF
  t.withGlobals(Stubs(), function()
    MF = t.newNamespace(
      "Modules/Migrations.lua", "Modules/AuraLogic.lua", "Modules/GroupLogic.lua",
      "Modules/FrameUtil.lua", "Modules/TestUtil.lua", "Core.lua")
    MF.db = { profile = { filters = {}, sizes = {}, positions = {} }, global = {} }
    for _, def in ipairs(MF.SizeDefinitions) do
      MF.db.profile.sizes[def.key] = def.default
    end
    MF.InvalidateFilterCache = function() end
    MF.InitConfigAndOptions()
  end)
  return captured, MF
end

-- Calls fn(path, option) for every option, depth first.
local function Walk(group, path, fn)
  for key, option in pairs(group.args or {}) do
    local optionPath = path .. "/" .. key
    fn(optionPath, option, key)
    if option.type == "group" then
      Walk(option, optionPath, fn)
    end
  end
end

local function WordCount(text)
  local count = 0
  for _ in text:gmatch("%S+") do count = count + 1 end
  return count
end

t.test("the options window is a tree with General, every frame type and Profiles", function()
  local options = BuildOptions()
  t.eq(options.childGroups, "tree")
  for _, key in ipairs({ "general", "player", "pet", "target", "focus", "party", "arena", "boss", "raid", "profiles" }) do
    t.truthy(options.args[key], "missing tab " .. key)
    t.truthy(options.args[key].icon, key .. " has no icon")
  end
end)

t.test("every tooltip is at most twelve words", function()
  local options = BuildOptions()
  Walk(options, "", function(path, option)
    if type(option.desc) == "string" then
      t.truthy(WordCount(option.desc) <= 12, path .. " desc is too long: " .. option.desc)
    end
  end)
end)

t.test("siblings never share an order value", function()
  local options = BuildOptions()
  local function check(group, path)
    local seen = {}
    for key, option in pairs(group.args) do
      if option.order then
        t.falsy(seen[option.order], path .. "/" .. key .. " repeats order " .. option.order)
        seen[option.order] = true
      end
      if option.type == "group" and option.args then
        check(option, path .. "/" .. key)
      end
    end
  end
  check(options, "")
end)

t.test("every size slider key is still offered, each on the tab of its frame", function()
  local options, MF = BuildOptions()
  local placed = {}
  Walk(options, "", function(path, option, key)
    if option.type == "range" then
      placed[key] = (placed[key] or 0) + 1
    end
  end)
  for _, def in ipairs(MF.SizeDefinitions) do
    t.truthy(placed[def.key], def.key .. " is not in the options")
    t.eq(placed[def.key], #def.tabs, def.key .. " tab count")
  end
  t.truthy(options.args.party.args.size.args.GroupFrameHeight)
  t.truthy(options.args.raid.args.size.args.RaidSizeX)
  t.truthy(options.args.pet.args.position.args.PetSpace)
  t.truthy(options.args.general.args.AuraOffsetY)
end)

t.test("action buttons and test toggles keep their keys", function()
  local options = BuildOptions()
  for _, key in ipairs({ "moveMode", "resetPositions", "resetSizes" }) do
    t.eq(options.args.general.args[key].type, "execute", key)
  end
  for _, kind in ipairs({ "target", "focus", "party", "arena", "boss", "raid" }) do
    t.truthy(options.args[kind].args.test.args[kind .. "Test"], kind .. "Test")
  end
  t.eq(options.args.player.args.test, nil, "player has no test mode")
end)

t.test("button names say verb and object", function()
  local options = BuildOptions()
  t.eq(options.args.general.args.resetPositions.name, "Reset all positions")
  t.eq(options.args.general.args.resetSizes.name, "Reset all sizes")
  t.eq(options.args.general.args.moveMode.name(), "Enter Move Mode")
  t.eq(options.args.party.args.test.args.partyTest.name(), "Enable Party Test Mode")
end)

t.test("a size slider reads and writes the same saved value as before", function()
  local options, MF = BuildOptions()
  local slider = options.args.player.args.size.args.SizeX
  t.eq(slider.get(), 50)
  t.withGlobals({ StaticPopup_Show = function() end }, function()
    slider.set(nil, 80)
  end)
  t.eq(MF.db.profile.sizes.SizeX, 80)
  t.eq(options.args.party.args.size.args.SizeX.get(), 80, "shared setting reads the same value")
  t.eq(MF.SizeX, 80, "flat value is refreshed for the next load")
end)

t.test("an aura toggle reads and writes the per-unit filter table", function()
  local options, MF = BuildOptions()
  local toggle = options.args.party.args.auras.args["HARMFUL|IMPORTANT"]
  t.eq(toggle.get(), nil)
  toggle.set(nil, false)
  t.eq(MF.db.profile.filters.party["HARMFUL|IMPORTANT"], false)
  t.eq(toggle.get(), false)
  t.eq(MF.db.profile.filters.raid, nil, "other units are untouched")
end)

t.test("aura toggles are full-size and each row pairs a harmful with its helpful filter", function()
  local options = BuildOptions()
  local sorted = {}
  for key, toggle in pairs(options.args.raid.args.auras.args) do
    t.eq(toggle.width, "normal", key .. " width")
    sorted[#sorted + 1] = { key = key, order = toggle.order }
  end
  table.sort(sorted, function(a, b) return a.order < b.order end)
  t.eq(#sorted, 12)
  -- Two toggles fit per row, so entries 1+2, 3+4, ... share a row.
  for row = 1, #sorted, 2 do
    local first = sorted[row].key:gsub("^%u+|", "")
    local second = sorted[row + 1].key:gsub("^%u+|", "")
    t.eq(first, second, "row " .. ((row + 1) / 2))
    t.truthy(sorted[row].key:find("^HARMFUL") ~= sorted[row + 1].key:find("^HARMFUL"),
      "row " .. ((row + 1) / 2) .. " mixes harmful and helpful")
  end
end)

t.test("every filter in priority order has a toggle on every unit that tracks auras", function()
  local options, MF = BuildOptions()
  for _, unit in ipairs({ "player", "target", "party", "arena", "boss", "raid" }) do
    for _, filter in ipairs(MF.FilterOrder) do
      t.truthy(options.args[unit].args.auras.args[filter], unit .. " " .. filter)
    end
  end
  t.eq(options.args.pet.args.auras, nil)
  t.eq(options.args.focus.args.auras, nil)
end)
