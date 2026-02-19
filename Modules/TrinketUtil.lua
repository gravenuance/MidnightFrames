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
        --print("MVPF Trinket: info for", unit, "spellId=", spellId, "start=", startTimeMs, "dur=", durationMs)
        btn.spellId = spellId
        if C_Spell and C_Spell.GetSpellTexture then
          local iconID
          if not spellId then
            iconID = defaultTrinket
            --print("MVPF Trinket: using default icon for", unit, iconID)
          else
            iconID = C_Spell.GetSpellTexture(spellId)
            --print("MVPF Trinket: spell icon for", unit, spellId, iconID)
          end
          if not iconID then
            --print("MVPF Trinket: no iconID, hiding icon for", unit)
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
    end
  end
end

function MV.UpdateTrinket(frame)
  local btn = frame.otherContainer.icons[1]
  if not btn then return end
  if not C_PvP or not C_PvP.GetArenaCrowdControlInfo then
    --print("MVPF Trinket: CPvP API missing, hiding button for", unit)
    if btn then
      btn:Hide()
    end
    return
  end

  local spellId, startTimeMs, durationMs = C_PvP.GetArenaCrowdControlInfo(frame.unit)
  --print("MVPF Trinket: info for", unit, "spellId=", spellId, "start=", startTimeMs, "dur=", durationMs)
  btn.spellId = spellId
  if C_Spell and C_Spell.GetSpellTexture then
    local iconID
    if not spellId then
      iconID = defaultTrinket
      --print("MVPF Trinket: using default icon for", unit, iconID)
    else
      iconID = C_Spell.GetSpellTexture(spellId)
      --print("MVPF Trinket: spell icon for", unit, spellId, iconID)
    end
    if not iconID then
      --print("MVPF Trinket: no iconID, hiding icon for", unit)
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
