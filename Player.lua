local _, MV = ...

local MAX_AURAS = 4

local f = MV.CreateUnitFrame({
  name = "MV_PlayerFrame",
  unit = "player",
  point = { "CENTER", UIParent, "CENTER", -MV.FrameXAlt, 0 },
  size = { MV.SizeX, MV.SizeY },
  maxAuras = MAX_AURAS,
  iconSize = MV.DefaultSize,
})
RegisterUnitWatch(f)

-- Center power label on health bar
local power
if f.health then
  power = f.health:CreateFontString(nil, "OVERLAY")
  power:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  power:SetPoint("BOTTOM", f.health, "TOP", 0, -20)
  power:SetJustifyH("CENTER")
  power:SetJustifyV("MIDDLE")
  power:SetAlpha(1)
  f.power = power
end

local pet = MV.CreateUnitFrame({
  name     = "MV_PetFrame",
  unit     = "pet",
  point    = { "TOPLEFT", f, "TOPRIGHT", MV.PetSpace, 0 },
  size     = { MV.PetX, MV.PetY },
  maxAuras = 0,
  iconSize = 0,
})
RegisterUnitWatch(pet)
f.pet = pet

local function UpdateHealthBar()
  MV.UpdateHealthBar(f)
end

local function UpdatePetHealthBar()
  MV.UpdateHealthBar(pet)
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterUnitEvent("UNIT_HEALTH", f.unit, pet.unit)
f:RegisterUnitEvent("UNIT_MAXHEALTH", f.unit, pet.unit)
f:RegisterUnitEvent("UNIT_AURA", f.unit)
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterUnitEvent("UNIT_POWER_UPDATE", f.unit)
f:RegisterUnitEvent("UNIT_MAXPOWER", f.unit)
f:RegisterEvent("ZONE_CHANGED")
f:RegisterUnitEvent("UNIT_PET", f.unit)
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_UNGHOST")
f:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")


f:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN"
      or event == "PLAYER_ENTERING_WORLD"
      or event == "PLAYER_ALIVE"
      or event == "ZONE_CHANGED" then
    MV.ApplyClassColor(f)
    UpdateHealthBar()
    UpdatePetHealthBar()
    MV.UpdateAuras(f)
    MV.UpdateTargetHighlight(f, false)
    MV.UpdateTargetHighlight(pet, false)
    MV.UpdatePowerLabel(f)
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    if arg1 == f.unit then
      UpdateHealthBar()
    elseif arg1 == pet.unit then
      UpdatePetHealthBar()
    end
  elseif event == "UNIT_PET" then
    UpdatePetHealthBar()
  elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" then
    UpdateHealthBar()
  elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") then
    MV.UpdatePowerLabel(f)
  elseif event == "UNIT_AURA" then
    MV.UpdateAuras(f)
  elseif event == "PLAYER_TARGET_CHANGED" then
    if arg1 == f.unit then
      MV.UpdateTargetHighlight(f, false)
    elseif arg1 == pet.unit then
      MV.UpdateTargetHighlight(pet, false)
    end
  elseif event == "SPELL_RANGE_CHECK_UPDATE" then
    MV.RegisterRangeSpell(arg1)
  end
end)
