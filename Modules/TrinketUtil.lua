local _, MV       = ...

MV.DefaultTrinket = "Interface\\Icons\\inv_jewelry_trinketpvp_01"

function MV.UpdateTrinket(frame, timer)
  if frame.otherContainer then
    local btn = frame.otherContainer.icons[1]
    if btn then
      btn:Hide()
      if MV.InInstance() then
        return
      end
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
          end
        else
          btn.icon:SetTexture(MV.DefaultTrinket)
        end
        if timer then
          local durationData = C_PvP.GetArenaCrowdControlDuration(frame.unit)
          if durationData then
            btn.cooldown:SetCooldownFromDurationObject(durationData)
          else
            btn.cooldown:SetCooldown(0, 0)
          end
        end
        btn:Show()
      end
    end
  end
end
