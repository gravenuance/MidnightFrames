local _, MF = ...

-- Captured at load; nil outside the client, where nothing is ever secret.
local issecretvalue = _G.issecretvalue

-- Index of the first aura at or after fromIndex whose auraInstanceID hasn't
-- been collected yet, recording it in `seen`; nil once the list runs out. An
-- ID that is secret or not a number can't be a table key, so it's never
-- treated as a duplicate.
function MF.NextUnseenAuraIndex(auraList, count, fromIndex, seen)
  for index = fromIndex, count do
    local aura = auraList[index]
    if not aura then
      return nil
    end
    local instanceID = aura.auraInstanceID
    if (issecretvalue and issecretvalue(instanceID)) or type(instanceID) ~= "number" then
      return index
    end
    if not seen[instanceID] then
      seen[instanceID] = true
      return index
    end
  end
  return nil
end

-- Priority order for which filter wins a limited aura-icon slot when more
-- than one matches (AuraUtil.lua's ResolveFilters/AddAurasForFilter) - first
-- wins. Player HoTs/DoTs are most reliable (self-tracked, always relevant),
-- so they go first, even though the options pane lists them last.
-- RAID_IN_COMBAT needs HELPFUL or HARMFUL beside it to return anything.
MF.FilterOrder = {
  "HELPFUL|PLAYER|RAID_IN_COMBAT",
  "HARMFUL|PLAYER|RAID_IN_COMBAT",
  "HARMFUL|IMPORTANT",
  "HELPFUL|IMPORTANT",
  "HARMFUL|EXTERNAL_DEFENSIVE",
  "HELPFUL|EXTERNAL_DEFENSIVE",
  "HARMFUL|BIG_DEFENSIVE",
  "HELPFUL|BIG_DEFENSIVE",
  "HARMFUL|CROWD_CONTROL",
  "HELPFUL|CROWD_CONTROL",
  "HARMFUL|RAID_PLAYER_DISPELLABLE",
  "HELPFUL|RAID_PLAYER_DISPELLABLE",
}
