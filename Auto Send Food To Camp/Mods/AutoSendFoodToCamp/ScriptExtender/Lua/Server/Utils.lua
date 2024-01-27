Utils = {}

function Utils.DebugPrint(level, ...)
  if JsonConfig and JsonConfig.DEBUG and JsonConfig.DEBUG.level >= level then
    if (JsonConfig.DEBUG.level == 0) then
      print("[Auto Send Food To Camp]: " .. ...)
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

-- Get the last 36 characters of the UUID (template ID I guess)
function Utils.GetGUID(uuid)
  return string.sub(uuid, -36)
end

function Utils.GetUID(templateuuid)
  -- Matches the part of the string before the last underscore
  local result = string.match(templateuuid, "(.-)_%x+-%x+-%x+-%x+-%x+$")
  return result
end


function Utils.GetPartyMembers()
  local teamMembers = {}

  local allPlayers = Osi.DB_Players:Get(nil)
  for _, player in ipairs(allPlayers) do
    if not string.match(player[1]:lower(), "%f[%A]dummy%f[%A]") then
      teamMembers[#teamMembers + 1] = Utils.GetGUID(player[1])
    end
  end

  return teamMembers
end

function Utils.GetPlayerEntity()
  return Ext.Entity.Get(Osi.GetHostCharacter())
end

return Utils
