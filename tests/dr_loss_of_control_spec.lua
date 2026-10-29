local t = ...

-- Real rule (warcraft.wiki.gg Diminishing_returns, patch 12.1.0): a category
-- resets 20 seconds after the END of the last effect in it.

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

t.test("types with no or an ambiguous DR category are not tracked", function()
  local dr = DR()
  t.eq(dr.CategoryForLocType("SCHOOL_INTERRUPT"), nil)
  t.eq(dr.CategoryForLocType("SNARE"), nil)
  t.eq(dr.CategoryForLocType("HORROR"), nil, "Psychic Horror is a stun, Mortal Coil an incapacitate")
  t.eq(dr.CategoryForLocType("SLEEP"), nil, "Sleep Walk is a disorient")
  t.eq(dr.CategoryForLocType("BANISH"), nil)
  t.eq(dr.CategoryForLocType(nil), nil)
  t.eq(dr.CategoryForLocType(42), nil)
end)

t.test("the first stun starts a normal timer", function()
  local dr = DR()
  local categories = {}
  local changed = dr.UpdateLossOfControl(categories, { [501] = "stun" }, 100)
  t.eq(changed, true)
  t.eq(categories.stun.isImmune, false)
  t.eq(categories.stun.startTime, 100)
  t.eq(categories.stun.duration, 20)
end)

t.test("the window counts from the end of the effect, not its start", function()
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "disorient" }, 0)
  local changed = dr.UpdateLossOfControl(categories, {}, 8)
  t.eq(changed, true, "the fear ending moves the window")
  t.eq(categories.disorient.startTime, 8)
  t.eq(categories.disorient.duration, 20)
  t.eq(categories.disorient.isImmune, false)
end)

t.test("a second fear 17 s after the first is diminished", function()
  -- fear 0..8, so the window runs to 28; 17 is inside it
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "disorient" }, 0)
  dr.UpdateLossOfControl(categories, {}, 8)
  dr.UpdateLossOfControl(categories, { [502] = "disorient" }, 17)
  t.eq(categories.disorient.isImmune, true)
  t.eq(categories.disorient.startTime, 17)
end)

t.test("a fear after the window from its end has passed starts over", function()
  -- fear 0..8, window to 28
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "disorient" }, 0)
  dr.UpdateLossOfControl(categories, {}, 8)
  dr.UpdateLossOfControl(categories, { [503] = "disorient" }, 29)
  t.eq(categories.disorient.isImmune, false)
  t.eq(categories.disorient.startTime, 29)
  t.eq(categories.disorient.instances[501], nil, "old instances are forgotten")
end)

t.test("a stun outlasting the window keeps the category running", function()
  -- one scan at 0, the next at 25 while the same stun is still active:
  -- 0 + 20 is over, but the effect has not ended, so it is still known
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 0)
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 25)
  t.eq(categories.stun.isImmune, false, "the same stun is not a second hit")
  t.eq(categories.stun.startTime, 25)
end)

t.test("an update while the same aura is active is not a hit", function()
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 100)
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 102)
  t.eq(categories.stun.isImmune, false)
end)

t.test("the hit stays immune until its own window from its end passes", function()
  -- stun A 100..104, stun B 110..112 (hit), window to 132
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 100)
  dr.UpdateLossOfControl(categories, {}, 104)
  dr.UpdateLossOfControl(categories, { [502] = "stun" }, 110)
  dr.UpdateLossOfControl(categories, {}, 112)
  t.eq(categories.stun.isImmune, true)
  t.eq(categories.stun.startTime, 112)
  dr.UpdateLossOfControl(categories, { [503] = "stun" }, 131)
  t.eq(categories.stun.isImmune, true, "131 is before 132")
end)

t.test("a scan with nothing new and nothing ended changes nothing", function()
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 100)
  dr.UpdateLossOfControl(categories, {}, 104)
  local changed = dr.UpdateLossOfControl(categories, {}, 110)
  t.eq(changed, false)
  t.eq(categories.stun.startTime, 104)
end)

t.test("an entry whose timer was cleared by its button starts over instead of erroring", function()
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 100)
  dr.UpdateLossOfControl(categories, {}, 104)
  categories.stun.startTime = nil
  categories.stun.duration = nil
  dr.UpdateLossOfControl(categories, { [502] = "stun" }, 105)
  t.eq(categories.stun.isImmune, false)
  t.eq(categories.stun.startTime, 105)
  t.eq(categories.stun.duration, 20)
end)

t.test("an entry cleared by its button while its effect is active gets its timer back", function()
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 100)
  categories.stun.startTime = nil
  categories.stun.duration = nil
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 103)
  t.eq(categories.stun.isImmune, false)
  t.eq(categories.stun.startTime, 103)
  t.eq(categories.stun.duration, 20)
end)

t.test("an entry cleared by its button stays cleared while nothing is active", function()
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 100)
  dr.UpdateLossOfControl(categories, {}, 104)
  categories.stun.startTime = nil
  categories.stun.duration = nil
  local changed = dr.UpdateLossOfControl(categories, {}, 130)
  t.eq(changed, false)
  t.eq(categories.stun.startTime, nil)
end)

t.test("categories are tracked independently", function()
  local dr = DR()
  local categories = {}
  dr.UpdateLossOfControl(categories, { [501] = "stun" }, 100)
  dr.UpdateLossOfControl(categories, { [501] = "stun", [502] = "silence" }, 101)
  t.eq(categories.silence.isImmune, false)
  t.eq(categories.stun.isImmune, false)
end)

t.test("entries the scan does not own are left alone", function()
  local dr = DR()
  local categories = { stun = { startTime = 50, duration = 20 } }
  dr.UpdateLossOfControl(categories, {}, 60)
  t.eq(categories.stun.startTime, 50)
end)
