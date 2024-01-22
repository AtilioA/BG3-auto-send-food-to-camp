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
    local food = GetFoodInInventory(character, false)
    if food ~= nil then
      for _, item in ipairs(food) do
        FoodDelivery.DeliverFood(item, character, true)
      end
    end
  end
end

--- Send food to camp chest or supply sack.
---@param object any The item to deliver.
---@param from any The inventory to deliver from.
---@param toSack boolean Whether to deliver to a supply sack or not.
function FoodDelivery.DeliverFood(object, from, toSack)
  local shouldMove = false

  if IsItem(object) then
    if IsFood(object) then
      if IsBeverage(object) then
        if JsonConfig.FEATURES.move_beverages then
          shouldMove = true
          -- Utils.DebugPrint(1, object .. " is beverage, will move to camp chest.")
        else
          shouldMove = false
          -- Utils.DebugPrint(1, object .. " is beverage, won't move to camp chest.")
        end
      else
        if JsonConfig.FEATURES.move_food then
          shouldMove = true
          -- Utils.DebugPrint(1, object .. " is food, will move to camp chest.")
        else
          shouldMove = false
          -- Utils.DebugPrint(1, object .. " is food, won't move to camp chest.")
        end
      end

      if shouldMove then
        Utils.DebugPrint(2, "Should move " .. object .. " to camp chest.")
        if toSack == false then
          FoodDelivery.MoveToCampChest(object)
        else
          local campChestSack = GetCampChestSupplySack()
          if campChestSack == nil then
            Utils.DebugPrint(1, "Could not find or create camp chest supply sack. Sending food to chest.")
            FoodDelivery.MoveToCampChest(object)
            return
          else
            if from == nil then
              FoodDelivery.MoveToCampChest(object)
              return
            else
              local entityObject = GetItemObject(object)
              local entityObjectTID = entityObject.Template.Id

              Utils.DebugPrint(1, "Adding " .. entityObjectTID .. " to camp chest sack: " .. campChestSack.Guid)
              Osi.TemplateAddTo(entityObjectTID, campChestSack.Guid, 1)
              Utils.DebugPrint(1, "Removing " .. entityObjectTID .. " from " .. from)
              Osi.TemplateRemoveFrom(entityObjectTID, from, 1)
              return
            end
          end
        end
      end
    else
      Utils.DebugPrint(2, object .. " is not food, won't move to camp chest.")
    end
  else
    Utils.DebugPrint(2, object .. " is not an item, won't process.")
  end
end

return FoodDelivery
