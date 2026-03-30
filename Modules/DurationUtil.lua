local _, MV = ...

function MV.CreateDurationObject(startTime, duration)
  local ok, durationObject = MV.CallExternalFunction(
    {
      namespace = "C_DurationUtil",
      functionName = "CreateDuration",
      args = { startTime, duration },
      argumentValidators = { MV.IsNumber, MV.IsNumber }
    }
  )
  if not ok then
    print(ok, "Result:", durationObject)
    return nil
  end
  ok = MV.CallExternalFunction(
    {
      namespace = durationObject,
      functionName = "SetTimeFromStart",
      args = { durationObject, startTime, duration },
      argumentValidators = { MV.IsTable, MV.IsNumber, MV.IsNumber }
    }
  )
  if ok then return durationObject end
  return nil
end
