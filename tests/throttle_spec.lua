local t = ...

-- A manual clock: schedule() records the callback, run() fires what's due.
local function Harness()
  local h = { scheduled = {}, applied = {} }
  h.schedule = function(delay, callback)
    h.scheduled[#h.scheduled + 1] = { delay = delay, callback = callback }
  end
  h.apply = function(item) h.applied[#h.applied + 1] = item end
  h.run = function()
    local due = h.scheduled
    h.scheduled = {}
    for _, timer in ipairs(due) do timer.callback() end
  end
  return h
end

local function Queue(h)
  local MF = t.newNamespace("Modules/ThrottleLogic.lua")
  return MF.NewUpdateQueue(h.schedule, 0.25, h.apply)
end

t.test("many requests inside one window schedule a single flush", function()
  local h = Harness()
  local request = Queue(h)
  request("a"); request("b"); request("a"); request("c")
  t.eq(#h.scheduled, 1)
  t.eq(h.scheduled[1].delay, 0.25)
  t.eq(#h.applied, 0, "nothing is applied before the flush")
end)

t.test("a flush applies each queued item once, in request order", function()
  local h = Harness()
  local request = Queue(h)
  request("a"); request("b"); request("a"); request("c")
  h.run()
  t.listEq(h.applied, { "a", "b", "c" })
end)

t.test("a request after a flush schedules a new one", function()
  local h = Harness()
  local request = Queue(h)
  request("a")
  h.run()
  request("a")
  t.eq(#h.scheduled, 1)
  h.run()
  t.listEq(h.applied, { "a", "a" })
end)

t.test("a flush with nothing new applies nothing", function()
  local h = Harness()
  local request = Queue(h)
  request("a")
  h.run()
  h.run()
  t.listEq(h.applied, { "a" })
end)

t.test("an item whose apply failed can be queued again", function()
  local h = Harness()
  local failing = true
  local MF = t.newNamespace("Modules/ThrottleLogic.lua")
  local request = MF.NewUpdateQueue(h.schedule, 0.25, function(item)
    if failing and item == "b" then error("apply failed") end
    h.applied[#h.applied + 1] = item
  end)
  request("a"); request("b"); request("c")
  t.falsy(pcall(h.run))
  failing = false
  request("c")
  h.run()
  t.eq(h.applied[#h.applied], "c", "c is queued and applied after the failed flush")
end)
