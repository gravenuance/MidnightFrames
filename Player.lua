local _, MV = ...

local MAX_AURAS = 4

local playerFrame = MV.CreateUnitFrame({
  name = "MV_Player",
  unit = "player",
  unitKey = "player",
  point = { "CENTER", UIParent, "CENTER", -MV.FrameXAlt, 0 },
  size = { MV.SizeX, MV.SizeY },
  maxAuras = MAX_AURAS,
  iconSize = MV.DefaultSize,
})
RegisterUnitWatch(playerFrame)

-- Center power label on health bar
local power
if playerFrame.health then
  power = playerFrame.health:CreateFontString(nil, "OVERLAY")
  power:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  power:SetPoint("BOTTOM", playerFrame.health, "TOP", 0, -20)
  power:SetJustifyH("CENTER")
  power:SetJustifyV("MIDDLE")
  power:SetAlpha(1)
  playerFrame.power = power
end

local petFrame = MV.CreateUnitFrame({
  name     = "MV_PetFrame",
  unit     = "pet",
  unitKey  = "pet",
  point    = { "TOPLEFT", playerFrame, "TOPRIGHT", MV.PetSpace, 0 },
  size     = { MV.PetX, MV.PetY },
  maxAuras = 0,
  iconSize = 0,
})
RegisterUnitWatch(petFrame)
playerFrame.pet = petFrame

local function UpdateHealthBar()
  MV.UpdateHealthBar(playerFrame)
end

local function UpdatePetHealthBar()
  MV.UpdateHealthBar(petFrame)
end

playerFrame:RegisterEvent("PLAYER_LOGIN")
playerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerFrame:RegisterEvent("PLAYER_ALIVE")
playerFrame:RegisterUnitEvent("UNIT_HEALTH", playerFrame.unit, petFrame.unit)
playerFrame:RegisterUnitEvent("UNIT_MAXHEALTH", playerFrame.unit, petFrame.unit)
playerFrame:RegisterUnitEvent("UNIT_AURA", playerFrame.unit)
playerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
playerFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", playerFrame.unit)
playerFrame:RegisterUnitEvent("UNIT_MAXPOWER", playerFrame.unit)
playerFrame:RegisterEvent("ZONE_CHANGED")
playerFrame:RegisterUnitEvent("UNIT_PET", playerFrame.unit)
playerFrame:RegisterEvent("PLAYER_DEAD")
playerFrame:RegisterEvent("PLAYER_UNGHOST")
playerFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")


playerFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3)
  if event == "PLAYER_LOGIN"
      or event == "PLAYER_ENTERING_WORLD"
      or event == "PLAYER_ALIVE"
      or event == "ZONE_CHANGED" then
    MV.ApplyClassColor(playerFrame)
    UpdateHealthBar()
    UpdatePetHealthBar()
    MV.UpdateAuras(playerFrame)
    MV.UpdateTargetHighlight(playerFrame, false)
    MV.UpdateTargetHighlight(petFrame, false)
    MV.UpdatePowerLabel(playerFrame)
    MV.ResetTargetIndicator(playerFrame)
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    if arg1 == playerFrame.unit then
      UpdateHealthBar()
    elseif arg1 == petFrame.unit then
      UpdatePetHealthBar()
    end
  elseif event == "UNIT_PET" then
    UpdatePetHealthBar()
  elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" then
    UpdateHealthBar()
  elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") then
    MV.UpdatePowerLabel(playerFrame)
  elseif event == "UNIT_AURA" then
    MV.UpdateAuras(playerFrame)
  elseif event == "PLAYER_TARGET_CHANGED" then
    MV.UpdateTargetHighlight(playerFrame, false)
    MV.UpdateTargetHighlight(petFrame, false)
  elseif event == "SPELL_RANGE_CHECK_UPDATE" then
    MV.RegisterRangeSpell(arg1)
  end
end)
