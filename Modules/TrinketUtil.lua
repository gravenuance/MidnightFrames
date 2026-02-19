local _, MV          = ...

local defaultTrinket = "Interface\\Icons\\inv_jewelry_trinketpvp_01"

function MV.ResetAndRequestTrinket(frame)
  if frame.otherContainer then
    local btn = frame.otherContainer.icons[1]
    if btn then
      btn:Hide()
      if btn.cooldown then btn.cooldown:Hide() end
      btn.duration = nil
      btn.startTime = nil
      btn.spellId = nil
      if UnitExists(frame.unit) then
        local spellId, startTimeMs, durationMs = C_PvP.GetArenaCrowdControlInfo(frame.unit)
        btn.spellId = spellId
        if C_Spell and C_Spell.GetSpellTexture then
          local iconID
          if not spellId then
            iconID = defaultTrinket
          else
            iconID = C_Spell.GetSpellTexture(spellId)
          end
          if not iconID then
            btn:Hide()
            return
          end
          btn.icon:SetTexture(iconID)
          btn:Show()
        end
        if startTimeMs and durationMs then
          btn.duration = durationMs   --/ 1000
          btn.startTime = startTimeMs --/ 1000
          btn.cooldown:SetCooldown(btn.startTime, btn.duration)
        end
      end
    end
  end
end

function MV.UpdateTrinket(frame)
  local btn = frame.otherContainer.icons[1]
  if not btn then return end
  if not C_PvP or not C_PvP.GetArenaCrowdControlInfo then
    if btn then
      btn:Hide()
    end
    return
  end

  local spellId, startTimeMs, durationMs = C_PvP.GetArenaCrowdControlInfo(frame.unit)
  btn.spellId = spellId
  if C_Spell and C_Spell.GetSpellTexture then
    local iconID
    if not spellId then
      iconID = defaultTrinket
    else
      iconID = C_Spell.GetSpellTexture(spellId)
    end
    if not iconID then
      btn:Hide()
      return
    end
    btn.icon:SetTexture(iconID)
    btn:Show()
  end
  if startTimeMs and durationMs then
    btn.duration = durationMs / 1000
    btn.startTime = startTimeMs / 1000
    btn.cooldown:SetCooldown(btn.startTime, btn.duration)
  end
end
