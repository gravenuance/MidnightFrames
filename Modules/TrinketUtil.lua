local _, MV       = ...

MV.DefaultTrinket = "Interface\\Icons\\inv_jewelry_trinketpvp_01"

function MV.UpdateTrinket(frame, timer)
  if frame.otherContainer then
    local btn = frame.otherContainer.icons[1]
    if btn then
      btn:Hide()
      if MV.UnitExists(frame.unit) then
        local ok, spellId = MV.CallExternalFunction(
          {
            namespace = C_PvP,
            functionName = "GetArenaCrowdControlInfo",
            args = { frame.unit },
            argumentValidators = { MV.IsString }
          }
        )
        if ok and MV.IsNumber(spellId) then
          ok, spellId = MV.CallExternalFunction(
            {
              namespace = C_Spell,
              functionName = "GetSpellTexture",
              args = { spellId },
              argumentValidators = { MV.IsNumber }
            }
          )
          if ok and not MV.IsNil(spellId) then
            btn.icon:SetTexture(spellId)
            if timer then
              local startTime = GetTime()
              if MV.IsNil(btn.endTime) or btn.endTime < startTime then
                local duration = 120
                btn.endTime = startTime + duration
                if spellId then
                  btn.cooldown:SetHideCountdownNumbers(false)
                  btn.cooldown:SetCooldown(startTime, duration, 1000)
                end
              end
            end
          end
        else
          btn.icon:SetTexture(MV.DefaultTrinket)
        end
        btn:Show()
      end
    end
  end
end
