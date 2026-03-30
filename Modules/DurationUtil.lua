local _, MV = ...

function MV.CreateDurationObject(startTime, duration)
  local ok, durationObject = MV.CallExternalFunction(
    {
      namespace = C_DurationUtil,
      functionName = "CreateDuration",
    }
  )
  if not ok then
    print(ok, "DurationObject Result:", durationObject)
    return nil
  end
  local ok2, err = MV.CallExternalFunction(
    {
      namespace = durationObject,
      functionName = "SetTimeFromStart",
      args = { durationObject, startTime, duration },
    }
  )
  if ok2 then return durationObject end
  print(ok2, "SetTimeFromStart Result:", err)
  return nil
end
