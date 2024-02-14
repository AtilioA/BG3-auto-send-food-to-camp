FoodDelivery = {}

FoodDelivery.ignore_item = {
  item = nil,
  reason = nil
}

FoodDelivery.awaiting_delivery = {
  item = nil,
  reason = nil
}

FoodDelivery.retainlist = {
  quests = { ['Quest_CON_OwlBearEgg'] = '374111f7-6756-4f5f-b6e3-e45e8d25def0' },
  healing = {
    ['UNI_CONS_Goodberry'] = 'de6b186e-839e-41d0-87af-a1a9d9327785',
    ['GEN_CONS_Berry'] = 'b0943b65-5766-414a-903d-28de8790370a',
    ['QUEST_GOB_SuspiciousMeat'] = 'f57ad063-af4c-411c-9c91-9ca02cd57dd4',
    ['DEN_UNI_Thieflings_Gruel'] = 'f91f8f13-44d0-4fd0-8cc1-1ec08356f98a'
    -- ['CONS_FOOD_Fruit_Apple_A'] = 'e8bbe73a-e1dc-4d2e-910f-318db7aee382',
  },
  weapons = {
    ['WPN_HUM_Salami_A'] = 'e082f373-81ec-4f4b-818b-9ee86952e2fa'
  }
}

-- Don't move items that are in the retainlist according to settings
function FoodDelivery.IsFoodItemRetainlisted(foodItem)
  local foodItemGuid = Utils.GetUID(foodItem)
  if foodItemGuid == nil then
    Utils.DebugPrint(1, "[ERROR] Couldn't verify if item is retainlisted. foodItemGuid is nil.")
    return false
  end

  local isQuestItem = FoodDelivery.retainlist.quests[foodItemGuid]
  local isHealingItem = FoodDelivery.retainlist.healing[foodItemGuid]
  local isWeapon = FoodDelivery.retainlist.weapons[foodItemGuid]
  -- local isWeapon = Osi.IsWeapon(foodItemGuid) == 1

  if isQuestItem then
    Utils.DebugPrint(2, "Moved item is a quest item. Not trying to send to chest.")
    return true
  else
    Utils.DebugPrint(2, "Moved item is not a quest item. May try to send to chest.")
  end

  if isHealingItem then
    if JsonConfig.FEATURES.ignore.healing then
      Utils.DebugPrint(2, "Moved item is a healing item. Not trying to send to chest.")
      return true
    else
      Utils.DebugPrint(2, "Moved item is a healing item, but ignore.healing is set to false. May try to send to chest.")
      return false
    end
  end

  if isWeapon then
    if JsonConfig.FEATURES.ignore.weapons then
      Utils.DebugPrint(2, "Moved item is a weapon. Not trying to send to chest.")
      return true
    else
      Utils.DebugPrint(2, "Moved item is a weapon, but ignore.weapons is set to false. Trying to send to chest.")
      return false
    end
  end

  return false
end

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
    if not FoodDelivery.IsFoodItemRetainlisted(item) then
      Utils.DebugPrint(1, "Moving " .. item .. " to camp chest.")
      return Osi.SendToCampChest(item, Osi.GetHostCharacter())
    end
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
      if not FoodDelivery.IsFoodItemRetainlisted(item) then
        FoodDelivery.DeliverFood(item, character, campChestSack)
      end
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
      if FoodDelivery.IsFoodItemRetainlisted(object) then
        return
      end

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
        local targetInventory = Utils.GetChestUUID()

        -- tfw this is all useless because the supply sack is always used anyways
        if JsonConfig.FEATURES.send_existing_food.send_to_supply_sack then
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
