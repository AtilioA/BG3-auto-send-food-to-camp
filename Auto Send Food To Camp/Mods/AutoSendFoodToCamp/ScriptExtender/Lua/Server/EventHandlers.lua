Ext.Require("Server/Helpers/Food.lua")

EHandlers = {}

local usingCampChest = false

-- function EHandlers.OnDroppedBy(object, mover)
--   if Osi.IsInPartyWith(mover, Osi.GetHostCharacter()) == 1 then
--     if IsFood(object) then
--       Utils.DebugPrint(2, "OnDroppedBy: " .. object .. " " .. mover)
--       FoodDelivery.UpdateIgnoredItem(object, "DroppedBy")
--     end
--   end
-- end

function EHandlers.OnMovedFromTo(movedObject, fromObject, toObject, isTrade)
  if usingCampChest == true then
    Utils.DebugPrint(2, "Character is using camp chest, not sending anything to chest.")
    return
  end

  -- if FoodDelivery.ignore_item.item == movedObject then
  --   Utils.DebugPrint(2, "Ignoring item: " .. movedObject)
  --   FoodDelivery.UpdateIgnoredItem(nil, nil)
  --   return
  -- end

  Utils.DebugPrint(2,
    "OnMovedFromTo called: " .. movedObject .. " from " .. fromObject .. " to " .. toObject .. " isTrade " .. isTrade)

  local chestName = Utils.GetChestUUID()

  -- if (Osi.IsPublicDomain(movedObject) == 1) then
  --   Utils.DebugPrint(2, "Moved item is public domain.")
  --   return
  -- else
  -- if not JsonConfig.FEATURES.stolen_items then
  --   Utils.DebugPrint(1, "Stolen items are disabled; not sending to chest.")
  -- end
  -- end

  -- Don't try to move if the item is already from the camp chest
  if (fromObject == chestName) then
    Utils.DebugPrint(2, "fromObject is camp chest. Not trying to send to chest.")
    -- TODO: check if the item is in a container in the chest. This will also cause problems even if we don't use 'pickup'
    return
  end


  -- Don't try to move items that are being moved from the party
  if (Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) and isTrade ~= 1) then
    Utils.DebugPrint(2, "fromObject is in party with host. Not trying to send to chest.")
    return
  end

  if not Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) and Osi.IsInPartyWith(toObject, Osi.GetHostCharacter()) == 1 then
    Utils.DebugPrint(2, "Moved item from outside party to party member, trying to send to chest.")
    FoodDelivery.DeliverFood(movedObject, fromObject, true)
    return
  end

  -- Do not send items to the chest if we are selling them in a trade
  if JsonConfig.FEATURES.move_bought_food then
    Utils.DebugPrint(2,
      "isTrade: " .. isTrade .. " fromObject: " .. fromObject .. " HostCharacter: " .. Osi.GetHostCharacter())
    if isTrade == 1 and Utils.GetGUID(fromObject) ~= Osi.GetHostCharacter() then
      Utils.DebugPrint(2, "Got item from trade, trying to send to chest.")
      FoodDelivery.DeliverFood(movedObject, fromObject, true)
      return
    end
  end
end


function EHandlers.OnLevelGameplayStarted()
  if JsonConfig.FEATURES.send_existing_food then
    Osi.TimerLaunch("CreateSupplySackTimer", 1500)
  end
end

-- Used to handle loose items. NOTE: will also be called when moving items in the game world, such as when moving, throwing, dropping.
-- function EHandlers.OnPreMovedBy(item, character)
--   if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
--     Utils.DebugPrint(2, "OnPreMovedBy: " .. item .. " " .. character)
--   end
-- end

function EHandlers.OnTimerFinished(timerName)
  if timerName == "FoodDeliveryTimer" then
    -- Utils.DebugPrint(2, "OnTimerFinished: Awaiting delivery: " .. tostring(FoodDelivery.awaiting_delivery.item))
    -- Utils.DebugPrint(2, "OnTimerFinished: Ignoring item: " .. tostring(FoodDelivery.ignore_item.item))
    if FoodDelivery.awaiting_delivery.item ~= nil and FoodDelivery.awaiting_delivery.item ~= FoodDelivery.ignore_item.item then
      -- Utils.DebugPrint(2, "OnTimerFinished: Delivering food: " .. FoodDelivery.awaiting_delivery.item)
      FoodDelivery.DeliverFood(FoodDelivery.awaiting_delivery.item)
      FoodDelivery.UpdateAwaitingItem(nil, nil)
    end
    -- FoodDelivery.UpdateIgnoredItem(nil, nil)
  end

  if timerName == 'CreateSupplySackTimer' then
    Utils.DebugPrint(2, "CreateSupplySackTimer: creating supply sack.")
    AddSupplySackToCampChestIfMissing()
  end
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
      Utils.DebugPrint(2, "Character is using camp chest, not sending anything to chest.")
      return
    end

    local objectEntity = GetItemObject(object)
    -- if objectEntity ~= nil then
    --   -- _D(objectEntity)
    -- end
    -- local campChestGuid = Utils.GetGUID(Utils.GetChestUUID())
    -- Utils.DebugPrint(2, objectEntity.Template.Id)
    -- Osi.TemplateAddTo(objectEntity.Template.Id, Osi.GetHostCharacter(), 50, 1)

    -- Utils.DebugPrint(2, "OnRequestCanPickup: " .. character .. " " .. object .. " " .. requestID)
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

-- function EHandlers.OnCharacterStoleItem(character, item, itemRootTemplate, x, y, z, oldOwner, srcContainer, amount,
--                                         goldValue)
--   Utils.DebugPrint(2,
--     "OnCharacterStoleItem: " ..
--     character ..
--     " " ..
--     item ..
--     " " ..
--     itemRootTemplate ..
--     " " .. x .. " " .. y .. " " .. z .. " " .. oldOwner .. " " .. srcContainer .. " " .. amount .. " " .. goldValue)
--   if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
--     Utils.DebugPrint(2, "Character is in party with host.")
--   end
-- end


-- TODO: create flag to check if is using the camp chest
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
