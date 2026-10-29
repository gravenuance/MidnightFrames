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
  t.eq(status, "current")
  t.eq(stored, 2)
  t.eq(sv.global.schemaVersion, 2, "version is written back explicitly")
  t.eq(sv.profiles.Default.sizes.SizeX, 80, "profile data is untouched")
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
  t.eq(sv.global.schemaVersion, 2)
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

t.test("data from a newer version is reported and left alone", function()
  local MF = Migrations()
  local sv = { global = { schemaVersion = 99 }, profiles = { Default = {} } }
  local status, stored = MF.MigrateSavedVariables(sv)
  t.eq(status, "newer")
  t.eq(stored, 99)
  t.eq(sv.global.schemaVersion, 99, "version is not downgraded")
end)
