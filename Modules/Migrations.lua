local _, MF = ...

-- Bump when the persisted shape of MF_DB changes and add a step to
-- MIGRATIONS below. 1 = pre-AceDB flat { version, filters }. 2 = AceDB
-- profile store.
MF.DB_SCHEMA_VERSION = 2

local function DeepCopy(value)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for key, inner in pairs(value) do
    copy[key] = DeepCopy(inner)
  end
  return copy
end

-- The version recorded in a raw (not yet AceDB-bound) MF_DB table, or nil
-- when nothing usable is saved. The version is never an AceDB default, which
-- AceDB would strip on logout.
function MF.GetStoredSchemaVersion(sv)
  if type(sv) ~= "table" then
    return nil
  end
  local global = sv.global
  if type(global) == "table" and type(global.schemaVersion) == "number" then
    return global.schemaVersion
  end
  if sv.profiles then
    return 2
  end
  if sv.filters then
    return 1
  end
  return nil
end

-- Each step upgrades a raw table from version [n] to [n + 1].
local MIGRATIONS = {
  [1] = function(sv)
    sv.profiles = { Default = { filters = sv.filters } }
    sv.filters = nil
    sv.version = nil
  end,
}

-- Brings a raw MF_DB table up to MF.DB_SCHEMA_VERSION in place, before
-- AceDB binds it. Returns "fresh", "current", "migrated" or "newer", plus
-- the stored version when it isn't "fresh". Newer data is left untouched.
function MF.MigrateSavedVariables(sv)
  local stored = MF.GetStoredSchemaVersion(sv)
  if not stored then
    return "fresh"
  end
  if stored > MF.DB_SCHEMA_VERSION then
    return "newer", stored
  end

  local status = "current"
  if stored < MF.DB_SCHEMA_VERSION then
    -- Only the latest backup is kept.
    sv.migrationBackup = nil
    sv.migrationBackup = { schemaVersion = stored, data = DeepCopy(sv) }
    for version = stored, MF.DB_SCHEMA_VERSION - 1 do
      MIGRATIONS[version](sv)
    end
    status = "migrated"
  end

  sv.global = sv.global or {}
  sv.global.schemaVersion = MF.DB_SCHEMA_VERSION
  return status, stored
end
