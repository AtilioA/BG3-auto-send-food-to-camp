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

function FoodDelivery.SendInventoryFoodToChest(character)
  local campChestSack = GetCampChestSupplySack()
  -- Not sure if nil is falsey in Lua, so we'll just be explicit
  local shallow = not JsonConfig.FEATURES.send_existing_food.nested_containers or false

  local food = GetFoodInInventory(character, shallow)
  if food ~= nil then
    for _, item in ipairs(food) do
      Utils.DebugPrint(2, "Found food in " .. character .. "'s inventory: " .. item)
      FoodDelivery.DeliverFood(item, character, campChestSack)
    end
  end
end

--- Send food to camp chest or supply sack.
---@param object any The item to deliver.
---@param from any The inventory to deliver from.
---@param campChestSack any The supply sack to deliver to.
function FoodDelivery.DeliverFood(object, from, campChestSack)
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
        local exactamount, totalamount = Osi.GetStackAmount(object)
        Utils.DebugPrint(2, "Should move " .. object .. " to camp chest.")
        local targetInventory

        if campChestSack ~= nil then
          targetInventory = campChestSack.Guid
        else
          -- Try to get the supply sack anyways if it has not been provided
          local getCampChestSack = GetCampChestSupplySack()
          if getCampChestSack ~= nil then
            targetInventory = getCampChestSack.Guid
          else
            Utils.DebugPrint(1, "Camp chest supply sack not found.")
            targetInventory = Utils.GetChestUUID()
          end
        end

        if targetInventory then
          Osi.ToInventory(object, targetInventory, totalamount, 1, 1)
        else
          Utils.DebugPrint(1, "Target inventory not found, not moving " .. object .. " to camp chest.")
        end
      else
        Utils.DebugPrint(2, object .. " is not food, won't move to camp chest.")
      end
    end
  else
    Utils.DebugPrint(2, object .. " is not an item, won't process.")
  end
end

return FoodDelivery
