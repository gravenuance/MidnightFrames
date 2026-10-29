local t = ...

local function DR()
  return t.newNamespace("Modules/DRLogic.lua").DR
end

t.test("loss-of-control types map onto the DR categories", function()
  local dr = DR()
  t.eq(dr.CategoryForLocType("STUN"), "stun")
  t.eq(dr.CategoryForLocType("STUN_MECHANIC"), "stun")
  t.eq(dr.CategoryForLocType("SILENCE"), "silence")
  t.eq(dr.CategoryForLocType("PACIFYSILENCE"), "silence")
  t.eq(dr.CategoryForLocType("ROOT"), "root")
  t.eq(dr.CategoryForLocType("DISARM"), "disarm")
  t.eq(dr.CategoryForLocType("FEAR"), "disorient")
  t.eq(dr.CategoryForLocType("DISORIENT"), "disorient")
  t.eq(dr.CategoryForLocType("INCAPACITATE"), "incap")
  t.eq(dr.CategoryForLocType("POLYMORPH"), "incap")
  t.eq(dr.CategoryForLocType("SAP"), "incap")
end)

t.test("types with no DR category are not tracked", function()
  local dr = DR()
  t.eq(dr.CategoryForLocType("SCHOOL_INTERRUPT"), nil)
  t.eq(dr.CategoryForLocType("SNARE"), nil)
  t.eq(dr.CategoryForLocType(nil), nil)
  t.eq(dr.CategoryForLocType(42), nil)
end)

t.test("the first stun starts a normal timer", function()
  local dr = DR()
  local categories = {}
  local status, entry = dr.RegisterLossOfControl(categories, "stun", 501, 100)
  t.eq(status, "started")
  t.eq(entry.isImmune, false)
  t.eq(entry.startTime, 100)
  t.eq(entry.duration, 16)
  t.eq(categories.stun, entry)
end)

t.test("an update for the same aura changes nothing", function()
  local dr = DR()
  local categories = {}
  dr.RegisterLossOfControl(categories, "stun", 501, 100)
  local status, entry = dr.RegisterLossOfControl(categories, "stun", 501, 105)
  t.eq(status, "known")
  t.eq(entry.isImmune, false)
  t.eq(entry.startTime, 100, "timer is not restarted")
end)

t.test("a new aura while the category is running is a DR hit", function()
  local dr = DR()
  local categories = {}
  dr.RegisterLossOfControl(categories, "stun", 501, 100)
  local status, entry = dr.RegisterLossOfControl(categories, "stun", 502, 110)
  t.eq(status, "hit")
  t.eq(entry.isImmune, true)
  t.eq(entry.startTime, 110)
end)

t.test("updates of the aura that caused the hit keep it immune without restarting", function()
  local dr = DR()
  local categories = {}
  dr.RegisterLossOfControl(categories, "stun", 501, 100)
  dr.RegisterLossOfControl(categories, "stun", 502, 110)
  local status, entry = dr.RegisterLossOfControl(categories, "stun", 502, 112)
  t.eq(status, "known")
  t.eq(entry.isImmune, true)
  t.eq(entry.startTime, 110)
  status = dr.RegisterLossOfControl(categories, "stun", 501, 113)
  t.eq(status, "known", "the first aura is still known")
end)

t.test("a new aura after the window has expired starts over", function()
  local dr = DR()
  local categories = {}
  dr.RegisterLossOfControl(categories, "stun", 501, 100)
  dr.RegisterLossOfControl(categories, "stun", 502, 110)
  local status, entry = dr.RegisterLossOfControl(categories, "stun", 503, 126)
  t.eq(status, "started", "110 + 16 is not after 126, so the window is over")
  t.eq(entry.isImmune, false)
  t.eq(entry.startTime, 126)
  t.eq(entry.instances[501], nil, "old instances are forgotten")
end)

t.test("an entry whose timer was cleared by its button starts over instead of erroring", function()
  local dr = DR()
  local categories = {}
  dr.RegisterLossOfControl(categories, "stun", 501, 100)
  categories.stun.startTime = nil
  categories.stun.duration = nil
  local status, entry = dr.RegisterLossOfControl(categories, "stun", 502, 105)
  t.eq(status, "started")
  t.eq(entry.isImmune, false)
  t.eq(entry.startTime, 105)
end)

t.test("categories are tracked independently", function()
  local dr = DR()
  local categories = {}
  dr.RegisterLossOfControl(categories, "stun", 501, 100)
  local status, entry = dr.RegisterLossOfControl(categories, "silence", 502, 101)
  t.eq(status, "started")
  t.eq(entry.isImmune, false)
  t.eq(categories.stun.isImmune, false)
end)

t.test("an effect with no aura instance is not tracked", function()
  local dr = DR()
  local categories = {}
  local status, entry = dr.RegisterLossOfControl(categories, "stun", nil, 100)
  t.eq(status, "untracked")
  t.eq(entry, nil)
  t.eq(categories.stun, nil)
end)
