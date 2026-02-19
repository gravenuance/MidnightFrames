local _, MV = ...
local function IsDeadOrGhost(unit)
  return UnitExists(unit) and UnitIsDeadOrGhost(unit) and not MVPF_ArenaTestMode
end
local function IsLegalUnit(unit)
  return UnitIsConnected(unit) and UnitExists(unit) and not MVPF_ArenaTestMode
end

local function GetNPCReactionColor(unit)
  local r, g, b = 0, 0.8, 0

  if not UnitExists(unit) then
    return r, g, b
  end

  if UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) then
    return 0.4, 0.4, 0.4
  end

  if UnitReaction then
    local reaction = UnitReaction("player", unit)
    if reaction then
      if reaction >= 5 then
        -- friendly
        return 0, 0.9, 0.2
      elseif reaction == 4 then
        -- neutral
        return 1.0, 0.85, 0.1
      else
        -- hostile
        return 0.85, 0.10, 0.10
      end
    end
  end

  return r, g, b
end

function MV.GetClassColor(unit, fr, fg, fb)
  local _, class = UnitClass(unit)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then
    return c.r, c.g, c.b, true
  end

  if unit and UnitExists(unit) and not UnitIsPlayer(unit) then
    local nr, ng, nb = GetNPCReactionColor(unit)
    return nr, ng, nb, true
  end

  return fr or 0, fg or 0.8, fb or 0, false
end

function MV.UpdateHealthBar(frame)
  local maxHealth = UnitHealthMax(frame.unit) or 1
  if IsDeadOrGhost(frame.unit) then
    frame.health:SetMinMaxValues(0, maxHealth)
    frame.health:SetValue(0)
    return
  elseif not IsLegalUnit(frame.unit) then
    frame.health:SetMinMaxValues(0, 1)
    frame.health:SetValue(1)
    return
  end
  local curHealth = UnitHealth(frame.unit) or 1
  frame.health:SetMinMaxValues(0, maxHealth)
  frame.health:SetValue(curHealth)
end
