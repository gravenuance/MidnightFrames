local _, MV           = ...

MV.errorMargin        = 0.6
MV.RegAlpha           = 0.7
MV.OtherAlpha         = 0.4

local RangeSpells     = {}
local RangeSpellsSize = 0

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
  RangeSpellsSize = RangeSpellsSize + 1
end

local function CheckMultiSpellRange(unit)
  local count = 0
  local totalRangeCount = 0
  local okay, canAttack = MV.UnitCanAttack(unit)
  if RangeSpellsSize == 0 then return true end
  for spellId, spell in pairs(RangeSpells) do
    if okay then
      if not MV.IsNil(spell.range) then
        if not spell.range then return end
      end
      if not MV.IsNil(spell.helpful) then
        if canAttack and spell.helpful then break end
        if not canAttack and not spell.helpful then break end
        print(spellId, spell.helpful)
      end
    end
    local ok, range = MV.CallExternalFunction(
      {
        namespace = C_Spell,
        functionName = "IsSpellInRange",
        args = { spellId, unit },
        argumentValidators = { MV.IsNumber, MV.IsString },
      }
    )
    if ok then
      if range == true then
        count = count + 1
      end
      totalRangeCount = totalRangeCount + 1
    end
  end
  local result = totalRangeCount > 0 and count > math.floor(totalRangeCount * MV.errorMargin)
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
