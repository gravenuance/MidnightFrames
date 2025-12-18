local baseName          = "MVPF_Core"

local pendingPostCombat = {}

local function RunOrDefer(key, func, ...)
    if InCombatLockdown() then
        print("In combat. Test will be executed after.")
        pendingPostCombat[key] = { func = func, args = { ... } }
    else
        func(...)
    end
end

SLASH_MV1       = "/mv"
SlashCmdList.MV = function(msg)
    msg = msg and msg:lower() or ""

    if msg == "target" then
        RunOrDefer("MV_target_test", function()
            MVPF_Common.ToggleTestMode("target", not MVPF_TargetTestMode)
            print("MV: target test mode " .. (MVPF_TargetTestMode and "ON" or "OFF"))
        end)
    elseif msg == "party" then
        RunOrDefer("MV_party_test", function()
            MVPF_Common.ToggleTestMode("party", not MVPF_PartyTestMode)
            print("MV: party test mode " .. (MVPF_PartyTestMode and "ON" or "OFF"))
        end)
    elseif msg == "arena" then
        RunOrDefer("MV_arena_test", function()
            MVPF_Common.ToggleTestMode("arena", not MVPF_ArenaTestMode)
            print("MV: arena test mode " .. (MVPF_ArenaTestMode and "ON" or "OFF"))
        end)
    else
        print("Usage: /mv target | party | arena")
    end
end

local ef        = CreateFrame("Frame", baseName .. "Events")
ef:RegisterEvent("PLAYER_REGEN_ENABLED")

ef:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        -- optional safety check:
        if InCombatLockdown() then return end

        for key, data in pairs(pendingPostCombat) do
            data.func(unpack(data.args))
            pendingPostCombat[key] = nil
        end
    end
end)
