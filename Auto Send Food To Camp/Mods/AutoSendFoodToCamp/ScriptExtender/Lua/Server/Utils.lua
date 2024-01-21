Utils = {}

function Utils.DebugPrint(level, ...)
  if JsonConfig and JsonConfig.DEBUG and JsonConfig.DEBUG.level >= level then
    if (JsonConfig.DEBUG.level == 0) then
      print(...)
    else
      print("[Auto Send Food To Camp][DEBUG LEVEL " .. level .. "]: " .. ...)
    end
  end
end

-- Is that the UUID? The UID + UUID? What's that even called?
function Utils.GetChestUUID()
  local chestName = Osi.DB_Camp_UserCampChest:Get(nil, nil)[1][2]
  return chestName
end

-- Get the last 36 characters of the UUID
function Utils.GetGUID(uuid)
  return string.sub(uuid, -36)
end

return Utils
