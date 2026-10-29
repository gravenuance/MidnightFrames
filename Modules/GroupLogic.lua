local _, MF = ...

-- MidnightFrames draws at most this many raid frames. Bigger groups fall
-- back to Blizzard's raid frames (see Raid.lua).
MF.MaxRaidMembers = 20

-- Whether Blizzard's raid container should be visible instead of ours.
-- Test mode draws our own raid frames, so Blizzard's stay hidden then.
function MF.ShouldShowBlizzardRaid(numMembers, raidTestMode)
  if raidTestMode or type(numMembers) ~= "number" then
    return false
  end
  return numMembers > MF.MaxRaidMembers
end

-- How the boss frames are driven: "test" shows them anywhere, "watch" lets the
-- unit watch show each one while its boss exists (instances only, so world and
-- quest bosses don't get frames), "hidden" keeps them hidden.
function MF.BossFrameMode(inInstance, bossTestMode)
  if bossTestMode then
    return "test"
  end
  return inInstance and "watch" or "hidden"
end
