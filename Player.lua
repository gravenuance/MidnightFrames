local _, MF = ...

MF.HideBlizzardFrame("PlayerFrame")

local MAX_AURAS = 4

local playerFrame = MF.CreateUnitFrame({
  name = "MF_Player",
  unit = "player",
  unitKey = "player",
  point = { "CENTER", UIParent, "CENTER", MF.Positions.player.x, MF.Positions.player.y },
  size = { MF.SizeX, MF.PrimaryFrameHeight },
  maxAuras = MAX_AURAS,
  iconSize = MF.DefaultSize,
  roleIcon = true,
})
RegisterUnitWatch(playerFrame)
MF.RegisterMovable("player", playerFrame)

local power
if playerFrame.health then
  -- parented to absorb (topmost of health/healthLiquid/absorb) so it renders above all three
  power = playerFrame.absorb:CreateFontString(nil, "OVERLAY")
  power:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  power:SetPoint("BOTTOM", playerFrame.health, "TOP", 0, -20)
  power:SetJustifyH("CENTER")
  power:SetJustifyV("MIDDLE")
  power:SetAlpha(0.75)
  playerFrame.power = power
end

local petPos = MF.db.profile.positions.pet
local petPoint
if petPos.manual then
  petPoint = { "CENTER", UIParent, "CENTER", petPos.x, petPos.y }
else
  petPoint = { "TOPLEFT", playerFrame, "TOPRIGHT", MF.PetSpace, 0 }
end

local petFrame = MF.CreateUnitFrame({
  name     = "MF_PetFrame",
  unit     = "pet",
  unitKey  = "pet",
  point    = petPoint,
  size     = { MF.PetX, MF.PetY },
  maxAuras = 0,
  iconSize = 0,
})
RegisterUnitWatch(petFrame)
playerFrame.pet = petFrame
MF.RegisterMovable("pet", petFrame)

local function UpdateHealthBar()
  MF.UpdateHealthBar(playerFrame)
end

local function UpdatePetHealthBar()
  MF.UpdateHealthBar(petFrame)
end

playerFrame:RegisterEvent("PLAYER_LOGIN")
playerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
playerFrame:RegisterEvent("PLAYER_ALIVE")
playerFrame:RegisterEvent("ZONE_CHANGED")

playerFrame:RegisterUnitEvent("UNIT_HEALTH", playerFrame.unit, petFrame.unit)
playerFrame:RegisterUnitEvent("UNIT_MAXHEALTH", playerFrame.unit, petFrame.unit)
playerFrame:RegisterUnitEvent("UNIT_AURA", playerFrame.unit)
playerFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", playerFrame.unit)
playerFrame:RegisterEvent("PLAYER_DEAD")
playerFrame:RegisterEvent("PLAYER_UNGHOST")

playerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

playerFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", playerFrame.unit)
playerFrame:RegisterUnitEvent("UNIT_MAXPOWER", playerFrame.unit)

playerFrame:RegisterUnitEvent("UNIT_PET", playerFrame.unit)

playerFrame:RegisterEvent("SPELL_RANGE_CHECK_UPDATE")

playerFrame:RegisterEvent("RAID_TARGET_UPDATE")

MF.RegisterCastEvents(playerFrame)



playerFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3)
  if event == "PLAYER_LOGIN"
      or event == "PLAYER_ENTERING_WORLD"
      or event == "PLAYER_ALIVE"
      or event == "ZONE_CHANGED" then
    MF.ApplyClassColor(playerFrame)
    UpdateHealthBar()
    UpdatePetHealthBar()
    MF.UpdateAbsorbBar(playerFrame)
    MF.UpdateAuras(playerFrame)
    MF.UpdateTargetHighlight(playerFrame, false)
    MF.UpdateTargetHighlight(petFrame, false)
    MF.UpdatePowerLabel(playerFrame)
    MF.ResetTargetIndicator(playerFrame)
    MF.UpdateRoleIcon(playerFrame, false)
    MF.UpdateRaidMark(playerFrame)
    MF.UpdateCastIndicator(playerFrame)
  elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
    if arg1 == playerFrame.unit then
      UpdateHealthBar()
    elseif arg1 == petFrame.unit then
      UpdatePetHealthBar()
    end
  elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
    MF.UpdateAbsorbBar(playerFrame)
  elseif event == "UNIT_PET" then
    UpdatePetHealthBar()
  elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" then
    UpdateHealthBar()
  elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") then
    MF.UpdatePowerLabel(playerFrame)
  elseif event == "UNIT_AURA" then
    MF.UpdateAuras(playerFrame)
  elseif event == "PLAYER_TARGET_CHANGED" then
    MF.UpdateTargetHighlight(playerFrame, false)
    MF.UpdateTargetHighlight(petFrame, false)
  elseif event == "SPELL_RANGE_CHECK_UPDATE" then
    MF.RegisterRangeSpell(arg1)
  elseif event == "RAID_TARGET_UPDATE" then
    MF.UpdateRaidMark(playerFrame)
  elseif MF.IsCastEvent(event) then
    MF.UpdateCastIndicator(playerFrame)
  end
end)
