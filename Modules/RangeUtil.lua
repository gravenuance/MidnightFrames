local _, MV            = ...

MV.errorMargin         = 0.6
MV.RegAlpha            = 0.7
MV.OtherAlpha          = 0.4

local RangeSpells      = {}
local RangeSpellsSize  = 0
local RangeSpellsBound = 0

function MV.RegisterRangeSpell(id)
  if RangeSpells and RangeSpells[id] then return end
  RangeSpells[id] = true
  RangeSpellsSize = RangeSpellsSize + 1
  RangeSpellsBound = math.floor(RangeSpellsSize * MV.errorMargin)
end

local function CheckMultiSpellRange(unit)
  local count = 0
  if RangeSpellsSize == 0 then return true end
  for spell in pairs(RangeSpells) do
    local range = C_Spell.IsSpellInRange(spell, unit)
    --print("Range: ", range)
    if range == true then
      count = count + 1
    end
  end
  --print("Count: ", count, "RangeL: ", RangeSpellsBound)
  return count > RangeSpellsBound
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
