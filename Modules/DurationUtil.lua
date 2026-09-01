local _, MF = ...

function MF.CreateDurationObject(startTime, duration)
  local ok, durationObject = MF.CreateDuration()
  if not ok then return nil end
  local ok2 = MF.SetTimeFromStart(durationObject, startTime, duration)
  if ok2 then return durationObject end
  return nil
end
