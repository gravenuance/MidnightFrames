local baseName = "MVPF_ArenaFrame"
local SOLID_TEXTURE = "Interface\\Buttons\\WHITE8x8"

MVPF_ArenaTestMode = false

local altAlpha = 0.5
local regAlpha = 0.7

local arenaElements = {

}

local stealthElements = {

}

local prepElements = {

}

local elementsToMove = {

}

local function hideFrame(frame)
    if frame:IsShown() then
        frame:Hide()
        return
    end
end

local function SecureGetOpponentSpec(index)
    local specID, gender = GetArenaOpponentSpec(index);
    if specID and specID > 0 then
        local _, _, _, specIcon, _, class, className = GetSpecializationInfoByID(specID);
        return specIcon, class, className
    end
end

local function GetArenaSize()
    -- Use opponent specs first since we know those before the match has started
    local numOpponentSpecs = GetNumArenaOpponentSpecs();
    if numOpponentSpecs and numOpponentSpecs > 0 then
        return numOpponentSpecs;
    end

    -- If we don't know opponent specs, we're probably in an arena which doesn't have a set size
    -- In this case base it on whoever happens to be in the arena
    -- Note we won't know this until the match actually starts
    local numOpponents = GetNumArenaOpponents();
    if numOpponents and numOpponents > 0 then
        return numOpponents;
    end

    return 0;
end

local function IsMatchEngaged()
    return C_PvP.GetActiveMatchState() == Enum.PvPMatchState.Engaged;
end

local function IsInArena()
    return C_PvP.IsMatchConsideredArena() and (C_PvP.IsMatchActive() or C_PvP.IsMatchComplete());
end

local function IsInPrep()
    return IsInArena() and not IsMatchEngaged() and not C_PvP.IsMatchComplete() and not MVPF_ArenaTestMode
end

local function GetUnitToken(unitIndex)
    return "arena" .. unitIndex;
end

-- Creates elements prep
hooksecurefunc(PreMatchArenaUnitFrameMixin, "Update", function(self, index)

end)

-- Updates shown state Prep
hooksecurefunc(ArenaPreMatchFramesContainerMixin, "UpdateShownState", function(self)

end)

-- Updates shown state trinket
hooksecurefunc(ArenaUnitFrameCcRemoverMixin, "UpdateShownState", function(self)

end)

hooksecurefunc(ArenaUnitFrameDebuffMixin, "UpdateShownState", function(self)

end)

-- check if stealthedarena has a unit
local function HasValidUnitFrame(frame)
    return frame.unitFrame and frame.unitFrame.unitToken and frame.unitFrame.unitIndex;
end -- not HasValidFrame or frame.unitFrame:IsShown()

hooksecurefunc(StealthedArenaUnitFrameMixin, "UpdateShownState", function(self)

end)

-- main frames
hooksecurefunc(CompactArenaFrameMixin, "UpdateVisibility", function(self)

end)
