local _, MV = ...

function MV.ResetDR(frame)
  if frame.otherContainer then
    for i = 2, 5 do
      local btn = frame.otherContainer.icons[i]
      if btn then
        btn.enabled = false
        btn:Hide()
        if btn.blizzButton then
          btn.blizzButton:Hide()
          btn.blizzButton.MV_Button = nil
          btn.blizzButton = nil
        end
      end
    end
  end
end

function MV.ResetTray(frame)
  if frame.otherContainer then
    for i = 2, 5 do
      local btn = frame.otherContainer.icons[i]
      if btn then
        if btn.blizzButton then
          if not btn.blizzButton:IsShown() then
            btn:Hide()
            btn.blizzButton.MV_Button = nil
            btn.blizzButton = nil
            btn.enabled = false
          end
        else
          btn:Hide()
        end
      end
    end
  end
end

function MV.ResetBlizzardButton(button)
  print("ResetBlizzardButton")
  if button.MV_Button then
    local btn = button.MV_Button
    print(btn.enabled)
    btn.enabled = false
    local container = btn.container
    if container then
      for i = 2, 5 do
        if container.icons[i] and not container.icons[i].enabled then
          print("Hiding ", i, "because: ", container.icons[i].enabled and "ON" or "OFF")
          btn = container.icons[i]
          btn:Hide()
          btn.blizzButton.MV_Button = nil
          btn.blizzButton = nil
        end
      end
    end
  end
end

function MV.MoveBlizzardButton(button, candidate)
  button:ClearAllPoints()
  button:SetPoint("CENTER", candidate, "CENTER", 0, 0)
  button:SetSize(MV.DefaultSize, MV.DefaultSize)
  local baseLevel = candidate:GetFrameLevel()
  button:SetFrameStrata(candidate:GetFrameStrata())
  button:SetFrameLevel(baseLevel + 1)
  if button.Icon then
    button.Icon:SetAlpha(0.8)
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  end
end

function MV.UpdateBlizzardDR(button, frame)
  if not button or not frame then return end
  if not button:IsShown() then return end
  if button.MV_Button then
    MV.MoveBlizzardButton(button, button.MV_Button)
    return
  end
  local candidate
  for i = 2, 5 do
    candidate = frame.otherContainer.icons and frame.otherContainer.icons[i]
    if candidate and not candidate.enabled then
      candidate.enabled = true
      candidate:Show()
      candidate.blizzButton = button
      button.MV_Button = candidate
      MV.MoveBlizzardButton(button, candidate)
      return
    end
  end
end

function MV.UpdateBlizzardDRBackup(tray, frame)
  if not tray or not frame then
    return
  end
  local _, children = pcall(function() return { tray:GetChildren() } end)
  pcall(function()
    for _, child in ipairs(children) do
      if not child:GetCategory() then break end
      MV.UpdateBlizzardDR(child, frame)
    end
  end)
end
