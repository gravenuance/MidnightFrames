local _, MF = ...

-- Diminishing-return decisions that don't touch the WoW API.
MF.DR = {}

-- Seconds a category keeps diminishing after its last effect ENDS (12.1.0).
MF.DR.ResetTime = 20

-- C_LossOfControl locType -> the DR category it diminishes in. Types left out
-- (interrupts, snares, taunts, ...) have no DR category; HORROR, SLEEP and
-- BANISH are left out too because their spells sit in different categories.
local LOC_TYPE_CATEGORY = {
  STUN          = "stun",
  STUN_MECHANIC = "stun",
  SILENCE       = "silence",
  PACIFYSILENCE = "silence",
  ROOT          = "root",
  FREEZE        = "root",
  DISARM        = "disarm",
  FEAR          = "disorient",
  FEAR_MECHANIC = "disorient",
  CONFUSE       = "disorient",
  DISORIENT     = "disorient",
  INCAPACITATE  = "incap",
  POLYMORPH     = "incap",
  SAP           = "incap",
}

function MF.DR.CategoryForLocType(locType)
  if type(locType) ~= "string" then
    return nil
  end
  return LOC_TYPE_CATEGORY[locType]
end

-- A button hiding clears the entry's timer (MF.HideButton), so it may be bare.
local function IsRunning(entry, now)
  if not entry or not entry.instances or not entry.startTime or not entry.duration then
    return false
  end
  return entry.hasActive or entry.startTime + entry.duration > now
end

local function RestartWindow(entry, now)
  entry.startTime = now
  entry.duration = MF.DR.ResetTime
end

-- Applies one scan of a unit's loss-of-control effects to its DR categories.
-- `active` maps the aura instance ID (stable across updates) of every DR
-- effect active now to its category; `categories[category]` is the entry the
-- DR buttons render from. A new aura inside a running window is a DR hit and
-- makes the entry immune. While an effect is active its window keeps
-- restarting, so it runs ResetTime from the scan that sees the effect gone.
-- Returns true when any entry changed.
function MF.DR.UpdateLossOfControl(categories, active, now)
  local changed = false

  for instanceID, category in pairs(active) do
    local entry = categories[category]
    if not IsRunning(entry, now) then
      entry = { isImmune = false, showCountdown = true, instances = {} }
      categories[category] = entry
      changed = true
    elseif not entry.instances[instanceID] then
      entry.isImmune = true
      changed = true
    end
    entry.instances[instanceID] = true
  end

  for category, entry in pairs(categories) do
    if entry.instances then
      local hasActive = false
      for instanceID in pairs(entry.instances) do
        if active[instanceID] == category then
          hasActive = true
          break
        end
      end
      if hasActive or entry.hasActive then
        RestartWindow(entry, now)
        changed = true
      end
      entry.hasActive = hasActive
    end
  end

  return changed
end
