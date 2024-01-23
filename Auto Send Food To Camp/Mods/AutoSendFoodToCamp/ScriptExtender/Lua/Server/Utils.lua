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

-- Get the last 36 characters of the UUID (template ID I guess)
function Utils.GetGUID(uuid)
  return string.sub(uuid, -36)
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

-- function PrintTable(tbl, indent)
--   if not indent then indent = 0 end
--   for k, v in pairs(tbl) do
--     local formatting = string.rep("  ", indent) .. k .. ": "
--     if type(v) == "table" then
--       print(formatting)
--       PrintTable(v, indent + 1)
--     else
--       -- Convert to string to safely handle userdata and other non-string types
--       print(formatting .. tostring(v))
--     end
--   end
-- end


return Utils
