local _, MV = ...

function MV.ResetDR(frame)
  if frame.pvpContainer then
    for i = 2, 4 do
      local btn = frame.pvpContainer.icons[i]
      if btn then
        btn.enabled = false
        btn:Hide()
        if btn.btn then
          btn.btn:Hide()
        end
      end
    end
  end
end

function MV.ResetBlizzardButton(button)
  if button.MVPF_Button then
    local btn = button.MVPF_Button
    btn.enabled = false
    btn:Hide()
    button.MVPF_Button = nil
  end
end

function MV.MoveBlizzardButton(button, candidate, size)
  button:ClearAllPoints()
  button:SetPoint("CENTER", candidate, "CENTER", 0, 0)
  button:SetSize(size, size)
  local baseLevel = candidate:GetFrameLevel()
  button:SetFrameStrata(candidate:GetFrameStrata())
  button:SetFrameLevel(baseLevel + 1)
  if button.Icon then
    button.Icon:SetAlpha(0.8)
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  end
end

function MV.UpdateBlizzardDR(button, container, size)
  if not button or not container then return end
  if button.MVPF_Button then
    MV.MoveBlizzardButton(button, button.MVPF_Button, size)
    return
  end
  local candidate
  for i = 2, 4 do
    candidate = container.icons and container.icons[i]
    if candidate and not candidate.enabled then
      candidate.enabled = true
      candidate:Show()
      candidate.btn = button
      button.MVPF_Button = candidate
      MV.MoveBlizzardButton(button, candidate, size)
      return
    end
  end
  if not candidate then
    button:Hide()
  end
end

function MV.UpdateBlizzardDRBackup(tray, container, size)
  if not tray or not container then
    return
  end
  local _, children = pcall(function() return { tray:GetChildren() } end)
  pcall(function()
    for _, child in ipairs(children) do
      if not child:GetCategory() then break end
      MV.UpdateBlizzardDR(child, container, size)
    end
  end)
end
