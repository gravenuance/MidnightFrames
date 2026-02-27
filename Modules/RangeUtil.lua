local _, MV           = ...

MV.errorMargin        = 0.6
MV.RegAlpha           = 0.7
MV.OtherAlpha         = 0.4

local RangeSpells     = {}
local RangeSpellsSize = 0
local RangeThreshold  = 0

function MV.RegisterRangeSpell(id)
  if RangeSpells and RangeSpells[id] then return end
  RangeSpells[id] = {}
  local ok, helpful = MV.CallExternalFunction({
    namespace = C_Spell,
    functionName = "IsSpellHelpful",
    args = { id },
    argumentValidators = { MV.IsNumber }
  })
  if ok then
    RangeSpells[id].helpful = helpful
  end
  ok, helpful = MV.CallExternalFunction({
    namespace = C_Spell,
    functionName = "SpellHasRange",
    args = { id },
    argumentValidators = { MV.IsNumber }
  })
  if ok then
    RangeSpells[id].range = helpful
  end
  ok, helpful = MV.CallExternalFunction(
    {
      namespace = C_Spell,
      functionName = "IsSpellInRange",
      args = { id, "player" },
      argumentValidators = { MV.IsNumber, MV.IsString },
    }
  )
  if ok then
    if helpful then
      RangeThreshold = RangeThreshold + 1
    end
  end
  RangeSpellsSize = RangeSpellsSize + 1
end

local function CheckMultiSpellRange(unit)
  if not MV.UnitExists(unit) then return end
  local count = 0
  local totalRangeCount = 0
  local okay, canAttack = MV.UnitCanAttack(unit)
  if RangeSpellsSize == 0 then
    return true
  end
  for spellId, spell in pairs(RangeSpells) do
    local shouldCheck = true

    if okay then
      if spell.range == false then
        shouldCheck = false
      end

      if shouldCheck and not MV.IsNil(spell.helpful) then
        if canAttack and spell.helpful == true then
          shouldCheck = false
        elseif (not canAttack) and spell.helpful == false then
          shouldCheck = false
        end
      end
    end

    if shouldCheck then
      local ok, range = MV.CallExternalFunction({
        namespace = C_Spell,
        functionName = "IsSpellInRange",
        args = { spellId, unit },
        argumentValidators = { MV.IsNumber, MV.IsString },
      })

      if ok then
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
    result = count > math.floor((RangeSpellsSize - RangeThreshold) * MV.errorMargin)
  else
    result = RangeThreshold > 0 and count > math.floor(RangeThreshold * MV.errorMargin) or false
  end
  return result
end

function MV.SetRangeAlpha(frame)
  local r, g, b = frame.health:GetStatusBarColor()
  if r == nil then return end
  local inRange = CheckMultiSpellRange(frame.unit)
  if inRange then
    frame.health:SetStatusBarColor(r, g, b, MV.RegAlpha)
  else
    frame.health:SetStatusBarColor(r, g, b, MV.OtherAlpha)
  end
end
