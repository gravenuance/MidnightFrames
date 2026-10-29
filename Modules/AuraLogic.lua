local _, MF = ...

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
