local _, MF       = ...

MF.DefaultTrinket = "Interface\\Icons\\inv_jewelry_trinketpvp_01"

function MF.UpdateTrinket(frame, timer)
  if frame.otherContainer then
    local btn = frame.otherContainer.icons[1]
    if btn then
      btn:Hide()
      if MF.InInstance() then
        return
      end
      if MF.UnitExists(frame.unit) then
        local ok, spellId = MF.GetArenaCrowdControlInfo(frame.unit)
        if ok and MF.IsNumber(spellId) then
          ok, spellId = MF.GetSpellTexture(spellId)
          if ok and not MF.IsNil(spellId) then
            btn.icon:SetTexture(spellId)
          end
        else
          btn.icon:SetTexture(MF.DefaultTrinket)
        end
        if timer then
          local ok3, durationData = MF.GetArenaCrowdControlDuration(frame.unit)
          local applied = false
          if ok3 and not MF.IsNil(durationData) then
            local ok4 = MF.SetCooldownFromDurationObject(btn.cooldown, durationData)
            applied = ok4
          end
          if not applied then
            MF.SetCooldown(btn.cooldown, 0, 0)
          end
        end
        btn:Show()
      end
    end
  end
end
