local t = ...

local function Migrations()
  return t.newNamespace("Modules/Migrations.lua")
end

t.test("nothing saved yet is fresh", function()
  local MF = Migrations()
  local status = MF.MigrateSavedVariables(nil)
  t.eq(status, "fresh")
  status = MF.MigrateSavedVariables({})
  t.eq(status, "fresh")
end)

t.test("an AceDB store with no recorded version counts as version 2", function()
  local MF = Migrations()
  local sv = { profiles = { Default = { sizes = { SizeX = 80 } } } }
  local status, stored = MF.MigrateSavedVariables(sv)
  t.eq(status, "migrated")
  t.eq(stored, 2)
  t.eq(sv.global.schemaVersion, 3, "version is written back explicitly")
  t.eq(sv.profiles.Default.sizes.SizeX, 80, "profile data is untouched")
end)

t.test("data already at the current version is left as it is", function()
  local MF = Migrations()
  local sv = {
    global = { schemaVersion = 3 },
    profiles = { Default = { filters = { player = { ["HARMFUL|IMPORTANT"] = false } } } },
  }
  local status, stored = MF.MigrateSavedVariables(sv)
  t.eq(status, "current")
  t.eq(stored, 3)
  t.eq(sv.migrationBackup, nil, "no backup when nothing migrated")
  t.eq(sv.profiles.Default.filters.player["HARMFUL|IMPORTANT"], false)
end)

t.test("a pre-AceDB flat table is detected as version 1 and reshaped", function()
  local MF = Migrations()
  local sv = { version = 1, filters = { player = { ["HARMFUL|IMPORTANT"] = false } } }
  local status, stored = MF.MigrateSavedVariables(sv)
  t.eq(status, "migrated")
  t.eq(stored, 1)
  t.eq(sv.profiles.Default.filters.player["HARMFUL|IMPORTANT"], false)
  t.eq(sv.filters, nil, "old top-level filters are removed")
  t.eq(sv.version, nil, "old top-level version is removed")
  t.eq(sv.global.schemaVersion, 3)
end)

t.test("a forward migration keeps one independent backup of the old data", function()
  local MF = Migrations()
  local sv = { version = 1, filters = { player = { ["HARMFUL|IMPORTANT"] = false } } }
  MF.MigrateSavedVariables(sv)
  t.eq(sv.migrationBackup.schemaVersion, 1)
  t.eq(sv.migrationBackup.data.filters.player["HARMFUL|IMPORTANT"], false)
  sv.profiles.Default.filters.player["HARMFUL|IMPORTANT"] = true
  t.eq(sv.migrationBackup.data.filters.player["HARMFUL|IMPORTANT"], false, "backup is a copy")
end)

t.test("a second migration replaces the backup instead of nesting it", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 2 }, profiles = { Default = {} },
    migrationBackup = { schemaVersion = 1, data = { filters = {} } } }
  MF.MigrateSavedVariables(sv)
  t.eq(sv.migrationBackup.schemaVersion, 2)
  t.eq(sv.migrationBackup.data.migrationBackup, nil)
end)

t.test("data from a newer version is reported and left alone", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 99 }, profiles = { Default = {} } }
  local status, stored = MF.MigrateSavedVariables(sv)
  t.eq(status, "newer")
  t.eq(stored, 99)
  t.eq(sv.global.schemaVersion, 99, "version is not downgraded")
end)

-- Version 2 -> 3: filter keys the aura API rejects are renamed.

t.test("a disabled dispellable filter keeps its choice under the valid key", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 2 }, profiles = { Default = { filters = {
    player = { ["HARMFUL|DISPELLABLE"] = false, ["HELPFUL|DISPELLABLE"] = false },
  } } } }
  MF.MigrateSavedVariables(sv)
  local player = sv.profiles.Default.filters.player
  t.eq(player["HARMFUL|RAID_PLAYER_DISPELLABLE"], false)
  t.eq(player["HELPFUL|RAID_PLAYER_DISPELLABLE"], false)
  t.eq(player["HARMFUL|DISPELLABLE"], nil)
  t.eq(player["HELPFUL|DISPELLABLE"], nil)
end)

t.test("a disabled HoTs-and-DoTs filter disables both split filters", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 2 }, profiles = { Default = { filters = {
    raid = { ["PLAYER|RAID_IN_COMBAT"] = false },
  } } } }
  MF.MigrateSavedVariables(sv)
  local raid = sv.profiles.Default.filters.raid
  t.eq(raid["HELPFUL|PLAYER|RAID_IN_COMBAT"], false)
  t.eq(raid["HARMFUL|PLAYER|RAID_IN_COMBAT"], false)
  t.eq(raid["PLAYER|RAID_IN_COMBAT"], nil)
end)

t.test("filter migration covers every unit in every profile and keeps other keys", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 2 }, profiles = {
    Default = { filters = { party = { ["HARMFUL|IMPORTANT"] = false, ["HARMFUL|DISPELLABLE"] = false } } },
    Raider = { filters = { boss = { ["PLAYER|RAID_IN_COMBAT"] = false } } },
  } }
  MF.MigrateSavedVariables(sv)
  local party = sv.profiles.Default.filters.party
  t.eq(party["HARMFUL|IMPORTANT"], false)
  t.eq(party["HARMFUL|RAID_PLAYER_DISPELLABLE"], false)
  t.eq(sv.profiles.Raider.filters.boss["HELPFUL|PLAYER|RAID_IN_COMBAT"], false)
end)

t.test("a filter the user never touched gains no new keys", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 2 }, profiles = { Default = { filters = {
    player = { ["HARMFUL|IMPORTANT"] = false },
  } } } }
  MF.MigrateSavedVariables(sv)
  t.eq(sv.profiles.Default.filters.player["HARMFUL|RAID_PLAYER_DISPELLABLE"], nil)
  t.eq(sv.profiles.Default.filters.player["HELPFUL|PLAYER|RAID_IN_COMBAT"], nil)
end)

t.test("a profile without filters migrates without error", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 2 }, profiles = { Default = { sizes = { SizeX = 80 } } } }
  local status = MF.MigrateSavedVariables(sv)
  t.eq(status, "migrated")
  t.eq(sv.profiles.Default.sizes.SizeX, 80)
end)

t.test("an existing value under the new key wins over the old key", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 2 }, profiles = { Default = { filters = {
    player = { ["HARMFUL|DISPELLABLE"] = false, ["HARMFUL|RAID_PLAYER_DISPELLABLE"] = true },
  } } } }
  MF.MigrateSavedVariables(sv)
  t.eq(sv.profiles.Default.filters.player["HARMFUL|RAID_PLAYER_DISPELLABLE"], true)
end)

t.test("a version 1 table is carried all the way to the current filter keys", function()
  local MF = Migrations()
  local sv = { version = 1, filters = { target = { ["PLAYER|RAID_IN_COMBAT"] = false } } }
  MF.MigrateSavedVariables(sv)
  t.eq(sv.profiles.Default.filters.target["HELPFUL|PLAYER|RAID_IN_COMBAT"], false)
  t.eq(sv.profiles.Default.filters.target["HARMFUL|PLAYER|RAID_IN_COMBAT"], false)
  t.eq(sv.global.schemaVersion, 3)
end)
