local _, MF = ...

-- Diminishing-return decisions that don't touch the WoW API.
MF.DR = {}

-- Seconds a category stays "running" after its last application.
MF.DR.ResetTime = 16

-- C_LossOfControl locType -> the DR category it diminishes in. Types left out
-- (interrupts, snares, taunts, ...) have no DR category.
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
  HORROR        = "disorient",
  INCAPACITATE  = "incap",
  POLYMORPH     = "incap",
  SAP           = "incap",
  SLEEP         = "incap",
  BANISH        = "incap",
}

function MF.DR.CategoryForLocType(locType)
  if type(locType) ~= "string" then
    return nil
  end
  return LOC_TYPE_CATEGORY[locType]
end

-- Registers one loss-of-control effect (identified by its aura instance ID,
-- which is stable across LOSS_OF_CONTROL_UPDATE) against a unit's DR
-- categories. `categories[category]` is the entry the DR buttons render from.
-- Returns "started" (fresh window), "hit" (new aura inside a running window,
-- so the entry becomes immune and its timer restarts), "known" (an aura
-- already counted; nothing changes) or "untracked" (no instance ID to key on),
-- plus the entry for the first three.
function MF.DR.RegisterLossOfControl(categories, category, instanceID, now)
  if type(instanceID) ~= "number" then
    return "untracked"
  end

  -- A button hiding clears the entry's timer (MF.HideButton), so it may be bare.
  local entry = categories[category]
  local running = entry and entry.instances and entry.startTime and entry.duration
      and entry.startTime + entry.duration > now
  if running then
    if entry.instances[instanceID] then
      return "known", entry
    end
    entry.instances[instanceID] = true
    entry.isImmune = true
    entry.startTime = now
    return "hit", entry
  end

  entry = {
    isImmune = false,
    showCountdown = true,
    startTime = now,
    duration = MF.DR.ResetTime,
    instances = { [instanceID] = true },
  }
  categories[category] = entry
  return "started", entry
end
