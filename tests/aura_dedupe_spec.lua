local t = ...

local function Auras(...)
  local list = {}
  for index, id in ipairs({ ... }) do
    list[index] = { auraInstanceID = id }
  end
  return list
end

local function Logic()
  return t.newNamespace("Modules/AuraLogic.lua")
end

t.test("an already-collected aura is skipped and the rest of the list is still read", function()
  local MF = Logic()
  local seen = { [20] = true }
  local list = Auras(10, 20, 30)
  t.eq(MF.NextUnseenAuraIndex(list, 3, 1, seen), 1)
  t.eq(MF.NextUnseenAuraIndex(list, 3, 2, seen), 3)
  t.eq(MF.NextUnseenAuraIndex(list, 3, 4, seen), nil)
end)

t.test("a duplicate at the very start of the list does not hide the auras behind it", function()
  local MF = Logic()
  local seen = { [10] = true }
  t.eq(MF.NextUnseenAuraIndex(Auras(10, 20), 2, 1, seen), 2)
end)

t.test("returned auras are recorded so a later filter skips them", function()
  local MF = Logic()
  local seen = {}
  MF.NextUnseenAuraIndex(Auras(10, 20), 2, 1, seen)
  t.eq(seen[10], true)
  t.eq(seen[20], nil, "only the aura actually returned is recorded")
end)

t.test("the same aura repeated inside one list is returned once", function()
  local MF = Logic()
  local seen = {}
  local list = Auras(7, 7, 8)
  t.eq(MF.NextUnseenAuraIndex(list, 3, 1, seen), 1)
  t.eq(MF.NextUnseenAuraIndex(list, 3, 2, seen), 3)
end)

t.test("an empty list or a start past the end yields nothing", function()
  local MF = Logic()
  t.eq(MF.NextUnseenAuraIndex({}, 0, 1, {}), nil)
  t.eq(MF.NextUnseenAuraIndex(Auras(1), 1, 2, {}), nil)
end)

t.test("a secret instance ID is returned and never used as a table key", function()
  local secret = {}
  t.withGlobals({ issecretvalue = function(value) return value == secret end }, function()
    local MF = Logic()
    local seen = setmetatable({}, { __newindex = function() error("secret used as key") end })
    local list = { { auraInstanceID = secret }, { auraInstanceID = secret } }
    t.eq(MF.NextUnseenAuraIndex(list, 2, 1, seen), 1)
    t.eq(MF.NextUnseenAuraIndex(list, 2, 2, seen), 2)
  end)
end)
