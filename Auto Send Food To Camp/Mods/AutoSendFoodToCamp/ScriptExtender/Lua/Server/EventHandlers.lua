Ext.Require("Server/Helpers/Food.lua")

EHandlers = {}

function EHandlers.OnMovedFromTo(movedObject, fromObject, toObject, isTrade)
  Utils.DebugPrint(2,
    "OnMovedFromTo called: " .. movedObject .. " from " .. fromObject .. " to " .. toObject .. " isTrade " .. isTrade)

  local chestName = Utils.GetChestUUID()

  -- Don't try to move if the item is already from the camp chest
  if (fromObject == chestName) then
    Utils.DebugPrint(2, "fromObject is camp chest. Not trying to send to chest.")
    return
  end

  -- Don't try to move items that are being moved from the party
  if (Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter())) then
    Utils.DebugPrint(2, "fromObject is in party with host. Not trying to send to chest.")
    return
  end

  if not Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) and Osi.IsInPartyWith(toObject, Osi.GetHostCharacter()) == 1 then
    Utils.DebugPrint(2, "Moved item from outside party to party member, trying to send to chest.")
    FoodDelivery.DeliverFood(movedObject)
  end
end

-- Used to handle loose items. NOTE: will also be called when moving items in the game world, such as when moving, throwing, dropping.
function EHandlers.OnPreMovedBy(item, character)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    Utils.DebugPrint(2, "OnPreMovedBy: " .. item .. " " .. character)
    FoodDelivery.DeliverFood(item)
  end
end

-- TODO: we might have to handle this (might be already handled by OnMovedFromTo!)
function EHandlers.OnTradeEnds(character, trader)
  Utils.DebugPrint(2, "OnTradeEnds: " .. character .. " " .. trader)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    Utils.DebugPrint(2, "Character is in party with host.")
  end
end

-- function EHandlers.OnUseStarted(character, item)
--   if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
--     Utils.DebugPrint(3, "UseStarted: " .. character .. " " .. item)
--   end
-- end

-- function EHandlers.OnUseEnded(character, item, result)
--   if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
--     Utils.DebugPrint(2, "UseEnded: " .. character .. " " .. item .. " " .. result)
--   end
-- end

-- function EHandlers.OnTemplateOpening(ITEMROOT, ITEM, CHARACTER)
--   Utils.DebugPrint(2, "OnTemplateOpening: " .. ITEMROOT .. " " .. ITEM .. " " .. CHARACTER)
-- end

-- function EHandlers.OnRequestCanLoot(looter, target)
--   Utils.DebugPrint(2, "OnRequestCanLoot: " .. looter .. " " .. target)
--   if Osi.IsInPartyWith(looter, Osi.GetHostCharacter()) == 1 then
--     Utils.DebugPrint(2, "Looter is in party with host.")
--     if Osi.IsInPartyWith(target, Osi.GetHostCharacter()) == 1 then
--       Utils.DebugPrint(2, "Target is in party with host.")
--     end
--   end
-- end

-- function EHandlers.OnCharacterLootedCharacter(player, lootedCharacter)
--   Utils.DebugPrint(2, "OnCharacterLootedCharacter: " .. player .. " " .. lootedCharacter)
-- end

return EHandlers
