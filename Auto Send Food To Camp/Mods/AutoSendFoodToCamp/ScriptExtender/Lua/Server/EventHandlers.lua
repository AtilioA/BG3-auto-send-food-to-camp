Ext.Require("Server/Helpers/Food.lua")

EHandlers = {}

EHandlers.usingCampChest = false


function CreateSupplySack()
  ASFTCPrint(2, "CreateSupplySackTimer: creating supply sack.")
  AddSupplySackToCampChestIfMissing()
end

function EHandlers.OnMovedFromTo(movedObject, fromObject, toObject, isTrade)
  if EHandlers.usingCampChest == true then
    ASFTCPrint(2, "Character is using camp chest, won't send anything to chest.")
    return
  end

  ASFTCPrint(2,
    "OnMovedFromTo called: " .. movedObject .. " from " .. fromObject .. " to " .. toObject .. " isTrade " .. isTrade)

  local chestName = Helpers.Camp:GetChestTemplateUUID()

  -- Don't try to move if the item is already from the camp chest
  -- Check if the moved item is already inside the camp chest or a container within it
  if fromObject == chestName or Osi.IsInInventoryOf(movedObject, chestName) == 1 or Osi.IsInInventoryOf(fromObject, chestName) == 1 then
    ASFTCPrint(2, "Item is from or inside the camp chest. Not trying to send to chest.")
    return
  end

  local isInPartyWithHost = Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) == 1
  local isMovingFromPartyToNotTrade = isInPartyWithHost and isTrade ~= 1
  local isItemBeingMovedFromCharacter = not isInPartyWithHost and
      Osi.IsInPartyWith(toObject, Osi.GetHostCharacter()) == 1 or
      (Osi.IsCharacter(fromObject) == 1 and not isInPartyWithHost)

  if (isMovingFromPartyToNotTrade) then
    ASFTCPrint(2, "Item is being moved from party and not in trade, not trying to send to chest.")
    return
  end

  if isItemBeingMovedFromCharacter then
    ASFTCPrint(2, "Item is being moved from character, trying to send to chest.")
    FoodDelivery.DeliverFood(movedObject, fromObject)
    return
  end

  if (Config:getCfg().FEATURES.move_bought_food and isTrade == 1 and Helpers.Format:GUID(fromObject) ~= Osi.GetHostCharacter()) then
    ASFTCPrint(2, "Got item from trade, trying to send to chest.")
    FoodDelivery.DeliverFood(movedObject, fromObject)
    return
  end
end

function EHandlers.OnLevelGameplayStarted()
  if Config:getCfg().FEATURES.send_existing_food.enabled and Config:getCfg().FEATURES.send_existing_food.create_supply_sack then
    Osi.TimerLaunch("CreateSupplySackTimer", 1500)
  end
end

function EHandlers.OnTimerFinished(timerName)
  if timerName == "FoodDeliveryTimer" then
    FoodDelivery.DeliverAwaitingFood()
  end

  if timerName == 'CreateSupplySackTimer' then
    CreateSupplySack()
  end
end

function EHandlers.OnRequestCanPickup(character, object, requestID)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    if EHandlers.usingCampChest == true then
      ASFTCPrint(2, "Character is using camp chest, won't send anything to chest.")
      return
    end

    ASFTCPrint(2, "OnRequestCanPickup: " .. character .. " " .. object .. " " .. requestID)
    FoodDelivery.UpdateAwaitingItem(object, "RequestCanPickup")
    Osi.TimerLaunch("FoodDeliveryTimer", 500)
  end
end

function EHandlers.OnPickupFailed(character, object)
  ASFTCPrint(2, "OnPickupFailed: " .. character .. " " .. object)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    ASFTCPrint(2, "Character is in party with host.")
  end
end

function EHandlers.OnTeleportedToCamp(character)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    ASFTCPrint(2, "Sending existing food to chest from " .. character)
    FoodDelivery.SendInventoryFoodToChest(character)
  end
end

function EHandlers.OnUseStarted(character, item)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    ASFTCPrint(2, "UseStarted: " .. character .. " " .. item)
    if item == Helpers.Camp:GetChestTemplateUUID() then
      EHandlers.usingCampChest = true
    end
  end
end

function EHandlers.OnUseEnded(character, item, result)
  if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
    ASFTCPrint(2, "UseEnded: " .. character .. " " .. item .. " " .. result)
    if item == Helpers.Camp:GetChestTemplateUUID() then
      EHandlers.usingCampChest = false
    end
  end
end

return EHandlers
