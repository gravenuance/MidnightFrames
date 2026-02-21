local _, MV = ...
local function IsDeadOrGhost(unit)
  return MV.UnitExists(unit) and MV.UnitIsDeadOrGhost(unit)
end
local function IsLegalUnit(unit)
  return MV.UnitIsConnected(unit) and MV.UnitExists(unit)
end

local function GetNPCReactionColor(unit)
  local r, g, b = 0, 0.8, 0

  if not IsLegalUnit(unit) then
    return r, g, b
  end

  if IsDeadOrGhost(unit) then
    return 0.4, 0.4, 0.4
  end

  local ok, reaction = MV.UnitReaction(unit)
  if ok then
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

local function GetClassColor(unit, fr, fg, fb)
  if MV.UnitIsPlayer(unit) then
    local ok, _, class = MV.UnitClass(unit)
    if ok then
      local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
      if c then
        return c.r, c.g, c.b, true
      end
    end
  end


  if MV.UnitExists(unit) then
    local nr, ng, nb = GetNPCReactionColor(unit)
    return nr, ng, nb, true
  end

  return fr or 0, fg or 0.8, fb or 0, false
end

function MV.ApplyClassColor(frame)
  if not frame.health then return end
  local r, g, b = GetClassColor(frame.unit)

  frame.health:SetStatusBarColor(r, g, b, MV.RegAlpha)
  if frame.power then
    local dr, dg, db = r * 0.7, g * 0.7, b * 0.7
    frame.power:SetTextColor(dr, dg, db, 1)
  end
  if frame.pet then
    if frame.pet.health then
      frame.pet.health:SetStatusBarColor(r, g, b, MV.RegAlpha)
    end
  end
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
