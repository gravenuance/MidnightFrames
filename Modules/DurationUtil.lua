local _, MF = ...

function MF.CreateDurationObject(startTime, duration)
  local ok, durationObject = MF.CreateDuration()
  if not ok then
    print(ok, "DurationObject Result:", durationObject)
    return nil
  end
  local ok2, err = MF.SetTimeFromStart(durationObject, startTime, duration)
  if ok2 then return durationObject end
  print(ok2, "SetTimeFromStart Result:", err)
  return nil
end
