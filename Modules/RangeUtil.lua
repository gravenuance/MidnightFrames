local _, MF           = ...

MF.errorMargin        = 0.6
MF.RegAlpha           = 0.7
MF.OtherAlpha         = 0.4

local RangeSpells     = {}
local RangeSpellsSize = 0
local RangeThreshold  = 0

-- only cache values we know aren't secret
function MF.RegisterRangeSpell(id)
  if RangeSpells and RangeSpells[id] then return end
  RangeSpells[id] = {}
  local ok, helpful = MF.IsSpellHelpful(id)
  if ok and not MF.IsSecretSafe(helpful) then
    RangeSpells[id].helpful = helpful
  end
  ok, helpful = MF.SpellHasRange(id)
  if ok and not MF.IsSecretSafe(helpful) then
    RangeSpells[id].range = helpful
  end
  ok, helpful = MF.IsSpellInRange(id, "player")
  if MF.SafeBoolResult(ok, helpful) then
    RangeThreshold = RangeThreshold + 1
  end
  RangeSpellsSize = RangeSpellsSize + 1
end

local function CheckMultiSpellRange(unit)
  if not MF.UnitExists(unit) then return end
  local count = 0
  local totalRangeCount = 0
  local okay, canAttack = MF.UnitCanAttack(unit)
  if RangeSpellsSize == 0 then
    return true
  end
  for spellId, spell in pairs(RangeSpells) do
    local shouldCheck = true

    if okay then
      if spell.range == false then
        shouldCheck = false
      end

      if shouldCheck and not MF.IsNil(spell.helpful) then
        if canAttack and spell.helpful == true then
          shouldCheck = false
        elseif (not canAttack) and spell.helpful == false then
          shouldCheck = false
        end
      end
    end

    if shouldCheck then
      local ok, range = MF.IsSpellInRange(spellId, unit)

      if ok and not MF.IsSecretSafe(range) then
        if range == true then
          count = count + 1
        end
        totalRangeCount = totalRangeCount + 1
      end
    end
  end
  if totalRangeCount == 0 then
    return false
  end
  local result
  if canAttack then
    result = count > math.floor((RangeSpellsSize - RangeThreshold) * MF.errorMargin)
  else
    result = RangeThreshold > 0 and count > math.floor(RangeThreshold * MF.errorMargin) or false
  end
  return result
end

function MF.SetRangeAlpha(frame)
  if not frame:IsShown() then return end
  local inRange = CheckMultiSpellRange(frame.unit)
  local alpha = inRange and MF.RegAlpha or MF.OtherAlpha
  frame.health:SetAlpha(alpha)
  if frame.healthLiquid then
    frame.healthLiquid:SetAlpha(alpha)
  end
end
