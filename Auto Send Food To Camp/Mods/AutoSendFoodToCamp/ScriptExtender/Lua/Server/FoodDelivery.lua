FoodDelivery = {}

FoodDelivery.ignore_item = {
  item = nil,
  reason = nil
}

FoodDelivery.awaiting_delivery = {
  item = nil,
  reason = nil
}

function FoodDelivery.UpdateIgnoredItem(item, reason)
  FoodDelivery.ignore_item.item = item
  FoodDelivery.ignore_item.reason = reason
end

function FoodDelivery.UpdateAwaitingItem(item, reason)
  FoodDelivery.awaiting_delivery.item = item
  FoodDelivery.awaiting_delivery.reason = reason
end

function FoodDelivery.MoveToCampChest(item)
  Utils.DebugPrint(2, tostring(FoodDelivery.ignore_item.item) .. " " .. tostring(FoodDelivery.ignore_item.reason))
  if (FoodDelivery.ignore_item.item == item) then
    Utils.DebugPrint(2, "Ignoring item: " .. item .. "reason: " .. FoodDelivery.ignore_item.reason)
    FoodDelivery.ignore_item.item = nil
    return
  else
    Utils.DebugPrint(1, "Moving " .. item .. " to camp chest.")
    return Osi.SendToCampChest(item, Osi.GetHostCharacter())
  end
end

function FoodDelivery.SendInventoryFoodToChest()
  local partyMembers = Utils.GetPartyMembers()

  for _, character in ipairs(partyMembers) do
    local food = GetFoodInInventory(character)
    if food ~= nil then
      for _, item in ipairs(food) do
        Utils.DebugPrint(2, "Sending food to chest: " .. item)
        FoodDelivery.DeliverFood(item)
      end
    end
  end
end

function FoodDelivery.DeliverFood(object)
  local shouldMove = false

  if IsItem(object) then
    if IsFood(object) then
      if IsBeverage(object) then
        if JsonConfig.FEATURES.move_beverages then
          shouldMove = true
          Utils.DebugPrint(1, object .. " is beverage, will move to camp chest.")
        else
          shouldMove = false
          Utils.DebugPrint(1, object .. " is beverage, won't move to camp chest.")
        end
      else
        if JsonConfig.FEATURES.move_food then
          shouldMove = true
          Utils.DebugPrint(1, object .. " is food, will move to camp chest.")
        else
          shouldMove = false
          Utils.DebugPrint(1, object .. " is food, won't move to camp chest.")
        end
      end

      if shouldMove then
        Utils.DebugPrint(2, "Should move " .. object .. " to camp chest.")
        FoodDelivery.MoveToCampChest(object)
      end
    else
      Utils.DebugPrint(2, item .. " is not food, won't move to camp chest.")
    end
  else
    Utils.DebugPrint(2, object .. " is not an item, won't process.")
  end
end

return FoodDelivery
