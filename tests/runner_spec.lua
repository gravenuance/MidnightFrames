local t = ...

-- The runner's own assertions: a harness that can't fail proves nothing.

t.test("eq passes on equal values and raises on different ones", function()
  t.eq(2, 2)
  local ok, err = pcall(t.eq, 2, 3)
  t.falsy(ok)
  t.truthy(tostring(err):find("expected 3, got 2", 1, true))
end)

t.test("listEq compares length and every item in order", function()
  t.listEq({ "a", "b" }, { "a", "b" })
  t.falsy(pcall(t.listEq, { "a" }, { "a", "b" }))
  t.falsy(pcall(t.listEq, { "a", "c" }, { "a", "b" }))
end)

t.test("withGlobals restores globals even when the body fails", function()
  _G.MF_TEST_GLOBAL = "before"
  local ok = pcall(t.withGlobals, { MF_TEST_GLOBAL = "during" }, function()
    t.eq(_G.MF_TEST_GLOBAL, "during")
    error("boom")
  end)
  t.falsy(ok)
  t.eq(_G.MF_TEST_GLOBAL, "before")
  _G.MF_TEST_GLOBAL = nil
end)
