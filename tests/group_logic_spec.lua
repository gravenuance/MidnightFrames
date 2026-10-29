local t = ...

local function Logic()
  return t.newNamespace("Modules/GroupLogic.lua")
end

t.test("our raid frames are capped at twenty members", function()
  t.eq(Logic().MaxRaidMembers, 20)
end)

t.test("a group of up to twenty keeps Blizzard's raid frames hidden", function()
  local MF = Logic()
  t.eq(MF.ShouldShowBlizzardRaid(0, false), false)
  t.eq(MF.ShouldShowBlizzardRaid(5, false), false)
  t.eq(MF.ShouldShowBlizzardRaid(6, false), false)
  t.eq(MF.ShouldShowBlizzardRaid(20, false), false)
end)

t.test("a group of more than twenty shows Blizzard's raid frames", function()
  local MF = Logic()
  t.eq(MF.ShouldShowBlizzardRaid(21, false), true)
  t.eq(MF.ShouldShowBlizzardRaid(40, false), true)
end)

t.test("raid test mode keeps Blizzard's raid frames hidden at any size", function()
  local MF = Logic()
  t.eq(MF.ShouldShowBlizzardRaid(25, true), false)
end)

t.test("boss frames follow their unit watch only inside an instance", function()
  local MF = Logic()
  t.eq(MF.BossFrameMode(true, false), "watch")
  t.eq(MF.BossFrameMode(false, false), "hidden")
end)

t.test("boss test mode shows the frames anywhere", function()
  local MF = Logic()
  t.eq(MF.BossFrameMode(false, true), "test")
  t.eq(MF.BossFrameMode(true, true), "test")
end)

t.test("a missing member count is treated as not in a group", function()
  local MF = Logic()
  t.eq(MF.ShouldShowBlizzardRaid(nil, false), false)
end)
