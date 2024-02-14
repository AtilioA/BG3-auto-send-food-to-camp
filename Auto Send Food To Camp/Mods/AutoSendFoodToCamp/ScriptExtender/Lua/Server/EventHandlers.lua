Ext.Require("Server/Helpers/Food.lua")

EHandlers = {}

local usingCampChest = false

function EHandlers.OnMovedFromTo(movedObject, fromObject, toObject, isTrade)
  if usingCampChest == true then
    Utils.DebugPrint(2, "Character is using camp chest, won't send anything to chest.")
    return
  end

  Utils.DebugPrint(2,
    "OnMovedFromTo called: " .. movedObject .. " from " .. fromObject .. " to " .. toObject .. " isTrade " .. isTrade)

  local chestName = Utils.GetChestUUID()

  -- Don't try to move if the item is already from the camp chest
  -- Check if the moved item is already inside the camp chest or a container within it
  if fromObject == chestName or Osi.IsInInventoryOf(movedObject, chestName) == 1 or Osi.IsInInventoryOf(fromObject, chestName) == 1 then
    Utils.DebugPrint(2, "Item is from or inside the camp chest. Not trying to send to chest.")
    return
  end

  local isInPartyWithHost = Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) == 1
  local isMovingFromPartyToNotTrade = isInPartyWithHost and isTrade ~= 1
  local isItemBeingMovedFromCharacter = not isInPartyWithHost and
      Osi.IsInPartyWith(toObject, Osi.GetHostCharacter()) == 1 or
      (Osi.IsCharacter(fromObject) == 1 and not isInPartyWithHost)

  if (isMovingFromPartyToNotTrade) then
    Utils.DebugPrint(2, "Item is being moved from party and not in trade, not trying to send to chest.")
    return
  end

  if isItemBeingMovedFromCharacter then
    Utils.DebugPrint(2, "Item is being moved from character, trying to send to chest.")
    FoodDelivery.DeliverFood(movedObject, fromObject)
    return
  end

  if (JsonConfig.FEATURES.move_bought_food and isTrade == 1 and Utils.GetGUID(fromObject) ~= Osi.GetHostCharacter()) then
    Utils.DebugPrint(2, "Got item from trade, trying to send to chest.")
    FoodDelivery.DeliverFood(movedObject, fromObject)
    return
  end
end

function EHandlers.OnLevelGameplayStarted()
  if JsonConfig.FEATURES.send_existing_food.enabled and JsonConfig.FEATURES.send_existing_food.create_supply_sack then
    Osi.TimerLaunch("CreateSupplySackTimer", 1500)
  end
end

function EHandlers.OnTimerFinished(timerName)
  if timerName == "FoodDeliveryTimer" then
    DeliverAwaitingFood()
  end

  if timerName == 'CreateSupplySackTimer' then
    CreateSupplySack()
  end
end

function DeliverAwaitingFood()
  if FoodDelivery.awaiting_delivery.item ~= nil and FoodDelivery.awaiting_delivery.item ~= FoodDelivery.ignore_item.item then
    Utils.DebugPrint(2, "Delivering awaiting food: " .. FoodDelivery.awaiting_delivery.item)
    FoodDelivery.DeliverFood(FoodDelivery.awaiting_delivery.item)
    FoodDelivery.UpdateAwaitingItem(nil, nil)
  end
end

function CreateSupplySack()
  Utils.DebugPrint(2, "CreateSupplySackTimer: creating supply sack.")
  AddSupplySackToCampChestIfMissing()
end

-- REVIEW: we might have to handle this (already handled by OnMovedFromTo)
-- function EHandlers.OnTradeEnds(character, trader)
--   Utils.DebugPrint(2, "OnTradeEnds: " .. character .. " " .. trader)
--   if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
--     Utils.DebugPrint(2, "Character is in party with host.")
--   end
-- end

function EHandlers.OnRequestCanPickup(character, object, requestID)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    if usingCampChest == true then
      Utils.DebugPrint(2, "Character is using camp chest, won't send anything to chest.")
      return
    end

    Utils.DebugPrint(2, "OnRequestCanPickup: " .. character .. " " .. object .. " " .. requestID)
    FoodDelivery.UpdateAwaitingItem(object, "RequestCanPickup")
    Osi.TimerLaunch("FoodDeliveryTimer", 500)
  end
end

function EHandlers.OnPickupFailed(character, object)
  Utils.DebugPrint(2, "OnPickupFailed: " .. character .. " " .. object)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    Utils.DebugPrint(2, "Character is in party with host.")
  end
end

function EHandlers.OnTeleportedToCamp(character)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    Utils.DebugPrint(2, "Sending existing food to chest from " .. character)
    FoodDelivery.SendInventoryFoodToChest(character)
  end
end

function EHandlers.OnUseStarted(character, item)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    Utils.DebugPrint(2, "UseStarted: " .. character .. " " .. item)
    if item == Utils.GetChestUUID() then
      usingCampChest = true
    end
  end
end

function EHandlers.OnUseEnded(character, item, result)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    Utils.DebugPrint(2, "UseEnded: " .. character .. " " .. item .. " " .. result)
    if item == Utils.GetChestUUID() then
      usingCampChest = false
    end
  end
end

-- function EHandlers.OnTemplateOpening(ITEMROOT, ITEM, CHARACTER)
--   Utils.DebugPrint(2, "OnTemplateOpening: " .. ITEMROOT .. " " .. ITEM .. " " .. CHARACTER)
-- end

-- function EHandlers.OnCharacterLootedCharacter(player, lootedCharacter)
--   Utils.DebugPrint(2, "OnCharacterLootedCharacter: " .. player .. " " .. lootedCharacter)
-- end

return EHandlers
