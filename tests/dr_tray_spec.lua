local t = ...

-- Drives the DR tray mirroring in Modules/DRUtil.lua with fakes shaped like
-- Blizzard's SpellDiminishStatusTray (GetActiveTrayItemForCategory) and its
-- items (Icon, Cooldown, ImmunityIndicator), and like our own DR buttons.

local env

local function Load()
  env = { now = 100 }
  return t.newNamespace("Modules/DRLogic.lua", "Modules/SecureUtil.lua", "Modules/DRUtil.lua")
end

local function WithClient(fn, extraGlobals)
  local globals = {
    GetTime = function() return env.now end,
    wipe = function(tbl)
      for key in pairs(tbl) do tbl[key] = nil end
      return tbl
    end,
  }
  for name, value in pairs(extraGlobals or {}) do
    globals[name] = value
  end
  t.withGlobals(globals, fn)
end

local function FakeSlot()
  local slot = { shown = false }
  slot.icon = { SetTexture = function(_, texture) slot.texture = texture end }
  slot.border = { SetVertexColor = function(_, r) slot.red = (r == 1) end }
  slot.cooldown = {
    SetCooldown = function(_, start, duration) slot.cdStart, slot.cdDuration = start, duration end,
    SetShowCountdownNumbers = function() end,
  }
  function slot:Show() self.shown = true end
  function slot:Hide() self.shown = false end
  return slot
end

-- icons[1] is the trinket slot; DR slots start at MF.DRStartIndex (2).
local function FakeFrame(slotCount)
  local icons = {}
  for index = 1, slotCount do
    icons[index] = FakeSlot()
  end
  return { otherContainer = { icons = icons }, categories = {} }
end

local function FakeItem(texture)
  local item = {
    Icon = { GetTexture = function() return texture end },
    Cooldown = { HookScript = function() end },
    ImmunityIndicator = { shown = false },
  }
  function item.ImmunityIndicator:IsShown() return self.shown end
  return item
end

local function FakeTray(items)
  local tray = { items = items }
  function tray:GetActiveTrayItemForCategory(category) return self.items[category] end
  return tray
end

t.test("one tray update shows the first stun with a normal border", function()
  local MF = Load()
  local stun = FakeItem("stunIcon")
  local tray = FakeTray({ [2] = stun })
  local frame = FakeFrame(4)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
  end)
  local slot = frame.otherContainer.icons[2]
  t.eq(slot.shown, true)
  t.eq(slot.red, false, "first stun is not immune")
  t.eq(slot.texture, "stunIcon")
  t.eq(slot.cdStart, 100)
  t.eq(slot.cdDuration, 16)
end)

t.test("the border turns red only once Blizzard's immunity indicator shows", function()
  local MF = Load()
  local stun = FakeItem("stunIcon")
  local tray = FakeTray({ [2] = stun })
  local frame = FakeFrame(4)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    local slot = frame.otherContainer.icons[2]
    t.eq(slot.red, false)

    env.now = 105
    stun.ImmunityIndicator.shown = true
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    t.eq(slot.red, true, "second stun in the window is immune")
    t.eq(slot.cdStart, 105, "timer restarts on the second stun")
    t.eq(frame.otherContainer.icons[3].shown, false, "same category keeps its slot")

    env.now = 140
    stun.ImmunityIndicator.shown = false
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    t.eq(slot.red, false, "a later fresh stun is normal again")
  end)
end)

t.test("syncing the same unchanged item again never turns it red", function()
  local MF = Load()
  local tray = FakeTray({ [2] = FakeItem("stunIcon") })
  local frame = FakeFrame(4)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
  end)
  t.eq(frame.otherContainer.icons[2].red, false)
end)

t.test("two categories take two slots", function()
  local MF = Load()
  local tray = FakeTray({ [2] = FakeItem("stunIcon"), [6] = FakeItem("silenceIcon") })
  local frame = FakeFrame(4)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    MF.OnTrayItemUpdated(tray, { category = 6 }, frame)
  end)
  t.eq(frame.otherContainer.icons[2].texture, "stunIcon")
  t.eq(frame.otherContainer.icons[3].texture, "silenceIcon")
end)

t.test("a finished cooldown clears only that item's button", function()
  local MF = Load()
  local stun, silence = FakeItem("stunIcon"), FakeItem("silenceIcon")
  local tray = FakeTray({ [2] = stun, [6] = silence })
  local frame = FakeFrame(4)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    MF.OnTrayItemUpdated(tray, { category = 6 }, frame)
    MF.OnTrayItemCooldownDone(stun, frame)
  end)
  t.eq(frame.otherContainer.icons[2].shown, false, "stun button is cleared")
  t.eq(frame.otherContainer.icons[3].shown, true, "silence button is untouched")
  t.eq(stun.MF_Button, nil)
end)

t.test("a slot freed by a finished cooldown is reused", function()
  local MF = Load()
  local stun = FakeItem("stunIcon")
  local root = FakeItem("rootIcon")
  local tray = FakeTray({ [2] = stun, [0] = root })
  local frame = FakeFrame(3)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    MF.OnTrayItemCooldownDone(stun, frame)
    MF.OnTrayItemUpdated(tray, { category = 0 }, frame)
  end)
  t.eq(frame.otherContainer.icons[2].texture, "rootIcon")
end)

t.test("an update with no free button is ignored without error", function()
  local MF = Load()
  local tray = FakeTray({ [2] = FakeItem("stunIcon"), [6] = FakeItem("silenceIcon") })
  local frame = FakeFrame(2)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    MF.OnTrayItemUpdated(tray, { category = 6 }, frame)
  end)
  t.eq(frame.otherContainer.icons[1].shown, false, "trinket slot is never used")
end)

t.test("a secret immunity flag counts as not immune", function()
  local secret = {}
  local MF = Load()
  local stun = FakeItem("stunIcon")
  stun.ImmunityIndicator.IsShown = function() return secret end
  local tray = FakeTray({ [2] = stun })
  local frame = FakeFrame(4)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
  end, { issecretvalue = function(value) return value == secret end })
  t.eq(frame.otherContainer.icons[2].red, false)
end)

t.test("an update whose category is secret or missing is ignored", function()
  local secret = {}
  local MF = Load()
  local tray = FakeTray({ [2] = FakeItem("stunIcon") })
  local frame = FakeFrame(4)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = secret }, frame)
    MF.OnTrayItemUpdated(tray, {}, frame)
    MF.OnTrayItemUpdated(tray, nil, frame)
  end, { issecretvalue = function(value) return value == secret end })
  t.eq(frame.otherContainer.icons[2].shown, false)
end)

t.test("resetting the frame frees every button for the next sync", function()
  local MF = Load()
  local stun = FakeItem("stunIcon")
  local tray = FakeTray({ [2] = stun })
  local frame = FakeFrame(4)
  WithClient(function()
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
    MF.ResetDR(frame)
    t.eq(frame.otherContainer.icons[2].shown, false)
    t.eq(stun.MF_Button, nil)
    MF.OnTrayItemUpdated(tray, { category = 2 }, frame)
  end)
  t.eq(frame.otherContainer.icons[2].shown, true)
end)
