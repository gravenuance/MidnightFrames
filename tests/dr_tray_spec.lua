local t = ...

-- Drives MF.HookDRTray (Modules/DRUtil.lua) with a fake shaped like Blizzard's
-- SpellDiminishStatusTray: pooled child items, UpdateOrAddTrayItem calling
-- the item's UpdateState, OnTrayItemCooldownDone and RemoveAllTrayItems.
-- Every DR state is a proxy that errors when addon code indexes it, as the
-- real UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED payload is secret.

local env
local payloads = setmetatable({}, { __mode = "k" })

local function Load()
  env = { now = 100, secret = {} }
  return t.newNamespace("Modules/DRLogic.lua", "Modules/SecureUtil.lua", "Modules/DRUtil.lua")
end

local function State(fields)
  local state = setmetatable({}, {
    __index = function() error("addon code indexed the secret DR payload") end,
  })
  payloads[state] = fields
  return state
end

local function WithClient(fn)
  local globals = {
    GetTime = function() return env.now end,
    wipe = function(tbl)
      for key in pairs(tbl) do tbl[key] = nil end
      return tbl
    end,
    hooksecurefunc = function(obj, name, hook)
      local original = obj[name]
      obj[name] = function(...)
        original(...)
        hook(...)
      end
    end,
    issecretvalue = function(value) return value == env.secret end,
    CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end,
  }
  t.withGlobals(globals, fn)
end

local function FakeSlot()
  local slot = { shown = false }
  slot.icon = { SetTexture = function(_, texture) slot.texture = texture end }
  slot.border = {
    SetVertexColor = function(_, r) slot.red = (r == 1) end,
    SetVertexColorFromBoolean = function(_, value, ifTrue, ifFalse)
      slot.borderValue, slot.borderTrue, slot.borderFalse = value, ifTrue, ifFalse
    end,
  }
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

local function FakeItem()
  local item = { shown = false }
  item.Icon = { SetTexture = function(self, texture) self.texture = texture end }
  function item.Icon:GetTexture() return self.texture end
  item.ImmunityIndicator = { shown = false }
  function item.ImmunityIndicator:IsShown() return self.shown end
  item.Cooldown = {}
  function item.Cooldown:GetCooldownTimes() return self.startMs, self.durationMs end
  function item:IsShown() return self.shown end
  function item:Show() self.shown = true end
  function item:Hide() self.shown = false end
  function item:UpdateState(state)
    local fields = payloads[state]
    self.ImmunityIndicator.shown = fields.isImmune
    if fields.secretTimes then
      self.Cooldown.startMs, self.Cooldown.durationMs = env.secret, env.secret
    else
      self.Cooldown.startMs, self.Cooldown.durationMs = fields.startTime * 1000, fields.duration * 1000
    end
  end
  return item
end

local function FakeTray()
  local tray = { children = {}, active = {} }
  function tray:GetChildren() return unpack(self.children) end
  function tray:Acquire()
    for _, child in ipairs(self.children) do
      if not child.inUse then
        child.inUse = true
        return child
      end
    end
    local item = FakeItem()
    item.inUse = true
    self.children[#self.children + 1] = item
    return item
  end
  function tray:Release(item)
    item.inUse = false
    item.isEditModePreview = nil
    item:Hide()
    self.active[item.category] = nil
  end
  function tray:UpdateOrAddTrayItem(state)
    local fields = payloads[state]
    local existing = self.active[fields.category]
    if existing then
      existing:UpdateState(state)
      return
    end
    local item = self:Acquire()
    self.active[fields.category] = item
    item.category = fields.category
    item.Icon:SetTexture(fields.icon)
    item:Show()
    item:UpdateState(state)
  end
  function tray:OnTrayItemCooldownDone(item) self:Release(item) end
  function tray:RemoveAllTrayItems()
    for _, child in ipairs(self.children) do
      if child.inUse then self:Release(child) end
    end
  end
  function tray:AddPreviewItem(category)
    local item = self:Acquire()
    self.active[category] = item
    item.category = category
    item.isEditModePreview = true
    item.Icon:SetTexture("questionMark")
    item:Show()
  end
  return tray
end

local function Stun(fields)
  fields.category, fields.icon = 2, "stunIcon"
  fields.startTime = fields.startTime or env.now
  fields.duration = fields.duration or 20
  return State(fields)
end

local function Silence()
  return State({ category = 6, icon = "silenceIcon", startTime = env.now, duration = 20 })
end

local function Root()
  return State({ category = 0, icon = "rootIcon", startTime = env.now, duration = 20 })
end

t.test("one tray update shows the first stun with a normal border", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
  end)
  local slot = frame.otherContainer.icons[2]
  t.eq(slot.shown, true)
  t.eq(slot.red, false, "first stun is not immune")
  t.eq(slot.texture, "stunIcon")
  t.eq(slot.cdStart, 100)
  t.eq(slot.cdDuration, 20)
end)

t.test("the border turns red only once Blizzard's immunity indicator shows", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    local slot = frame.otherContainer.icons[2]
    t.eq(slot.red, false)

    env.now = 105
    tray:UpdateOrAddTrayItem(Stun({ isImmune = true, startTime = 105, duration = 24 }))
    t.eq(slot.red, true, "second stun in the window is immune")
    t.eq(slot.cdStart, 105, "timer follows the tray's new state")
    t.eq(slot.cdDuration, 24)
    t.eq(frame.otherContainer.icons[3].shown, false, "same category keeps its slot")
  end)
end)

t.test("syncing the same unchanged item again never turns it red", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
  end)
  t.eq(frame.otherContainer.icons[2].red, false)
end)

t.test("two categories take two slots", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    tray:UpdateOrAddTrayItem(Silence())
  end)
  t.eq(frame.otherContainer.icons[2].texture, "stunIcon")
  t.eq(frame.otherContainer.icons[3].texture, "silenceIcon")
end)

t.test("a finished cooldown clears only that item's button", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    tray:UpdateOrAddTrayItem(Silence())
    tray:OnTrayItemCooldownDone(tray.active[2])
  end)
  t.eq(frame.otherContainer.icons[2].shown, false, "stun button is cleared")
  t.eq(frame.otherContainer.icons[3].shown, true, "silence button is untouched")
end)

t.test("a slot and a pooled item freed by a finished cooldown are reused", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(3)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    tray:OnTrayItemCooldownDone(tray.active[2])
    tray:UpdateOrAddTrayItem(Root())
  end)
  t.eq(#tray.children, 1, "the fake reused its pooled item")
  t.eq(frame.otherContainer.icons[2].shown, true)
  t.eq(frame.otherContainer.icons[2].texture, "rootIcon")
end)

t.test("the tray hiding frees every button", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    tray:UpdateOrAddTrayItem(Silence())
    tray:RemoveAllTrayItems()
  end)
  t.eq(frame.otherContainer.icons[2].shown, false)
  t.eq(frame.otherContainer.icons[3].shown, false)
end)

t.test("an update with no free button is ignored without error", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(2)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    tray:UpdateOrAddTrayItem(Silence())
  end)
  t.eq(frame.otherContainer.icons[1].shown, false, "trinket slot is never used")
  t.eq(frame.otherContainer.icons[2].texture, "stunIcon")
end)

t.test("a secret immunity flag goes to the border untouched", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = env.secret }))
  end)
  local slot = frame.otherContainer.icons[2]
  t.eq(slot.borderValue, env.secret)
  t.eq(slot.borderTrue.r, 1, "true is red")
  t.eq(slot.borderFalse.g, 1, "false is green")
  t.eq(slot.shown, true)
end)

t.test("a secret tray timer becomes a full window from now", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false, secretTimes = true }))
  end)
  t.eq(frame.otherContainer.icons[2].cdStart, 100)
  t.eq(frame.otherContainer.icons[2].cdDuration, 20)
end)

t.test("Edit Mode preview items are not mirrored", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:AddPreviewItem(6)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
  end)
  t.eq(frame.otherContainer.icons[2].texture, "stunIcon")
  t.eq(frame.otherContainer.icons[3].shown, false, "the preview got no button")
end)

t.test("items already in the tray when it is hooked are mirrored", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    tray:UpdateOrAddTrayItem(Stun({ isImmune = true }))
    MF.HookDRTray(tray, frame)
  end)
  t.eq(frame.otherContainer.icons[2].shown, true)
  t.eq(frame.otherContainer.icons[2].red, true)
end)

t.test("hooking the same tray again adds no second set of hooks", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  local updateOrAdd
  WithClient(function()
    MF.HookDRTray(tray, frame)
    updateOrAdd = tray.UpdateOrAddTrayItem
    MF.HookDRTray(tray, frame)
  end)
  t.eq(tray.UpdateOrAddTrayItem, updateOrAdd)
end)

t.test("no fields are written into Blizzard's tray or items", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  local function Keys(tbl)
    local keys = {}
    for key in pairs(tbl) do keys[key] = true end
    return keys
  end
  WithClient(function()
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    local item = tray.active[2]
    local trayKeys, itemKeys = Keys(tray), Keys(item)
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Silence())
    tray:OnTrayItemCooldownDone(item)
    MF.ResetDR(frame)
    for key in pairs(tray) do
      t.eq(trayKeys[key], true, "new tray field " .. tostring(key))
    end
    for key in pairs(item) do
      t.eq(itemKeys[key], true, "new item field " .. tostring(key))
    end
  end)
end)

t.test("resetting the frame frees every button for the next update", function()
  local MF = Load()
  local tray, frame = FakeTray(), FakeFrame(4)
  WithClient(function()
    MF.HookDRTray(tray, frame)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
    MF.ResetDR(frame)
    t.eq(frame.otherContainer.icons[2].shown, false)
    tray:UpdateOrAddTrayItem(Stun({ isImmune = false }))
  end)
  t.eq(frame.otherContainer.icons[2].shown, true)
end)

t.test("a missing or partial tray is ignored", function()
  local MF = Load()
  WithClient(function()
    MF.HookDRTray(nil, FakeFrame(4))
    MF.HookDRTray({}, FakeFrame(4))
  end)
end)
