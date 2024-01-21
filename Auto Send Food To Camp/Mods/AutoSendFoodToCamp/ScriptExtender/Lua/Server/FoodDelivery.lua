FoodDelivery = {}

function FoodDelivery.MoveToCampChest(item)
  return Osi.SendToCampChest(item, Osi.GetHostCharacter())
end

function FoodDelivery.DeliverFood(item)
  local shouldMove = false

  if IsFood(item) then
    if IsBeverage(item) then
      if JsonConfig.FEATURES.move_beverages then
        shouldMove = true
        Utils.DebugPrint(1, item .. " is beverage, will move to camp chest.")
      else
        shouldMove = false
        Utils.DebugPrint(1, item .. " is beverage, won't move to camp chest.")
      end
    else
      if JsonConfig.FEATURES.move_food then
        shouldMove = true
        Utils.DebugPrint(1, item .. " is food, will move to camp chest.")
      else
        shouldMove = false
        Utils.DebugPrint(1, item .. " is food, won't move to camp chest.")
      end
    end

    if shouldMove then
      FoodDelivery.MoveToCampChest(item)
    end
  else
    Utils.DebugPrint(2, item .. " is not food, won't move to camp chest.")
  end
end

return FoodDelivery
