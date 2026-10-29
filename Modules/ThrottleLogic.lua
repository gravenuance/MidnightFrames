local _, MF = ...

-- Returns request(item): queues `item` and, if no flush is pending, calls
-- schedule(delay, flush) once. flush() then runs apply(item) for each queued
-- item. A request for an item that's already queued changes nothing.
-- Allocation-free per request once the tables have grown to their peak.
function MF.NewUpdateQueue(schedule, delay, apply)
  local items, queued = {}, {}
  local count = 0
  local scheduled = false

  local function flush()
    scheduled = false
    local pending = count
    count = 0
    -- Clear the flags first so an apply() error can't leave an item stuck
    -- as "already queued".
    for index = 1, pending do
      queued[items[index]] = nil
    end
    for index = 1, pending do
      local item = items[index]
      items[index] = nil
      apply(item)
    end
  end

  return function(item)
    if not queued[item] then
      queued[item] = true
      count = count + 1
      items[count] = item
    end
    if not scheduled then
      scheduled = true
      schedule(delay, flush)
    end
  end
end
