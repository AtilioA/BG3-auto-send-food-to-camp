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
    quests = ItemList:New("AutoSendFoodToCamp/quest_food_list.json", { ['Quest_CON_OwlBearEgg'] = true }),
    healing = ItemList:New("AutoSendFoodToCamp/healing_food_list.json", {
        ['UNI_CONS_Goodberry'] = true,
        ['GEN_CONS_Berry'] = true,
        ['QUEST_GOB_SuspiciousMeat'] = true,
        ['DEN_UNI_Thieflings_Gruel'] = true,
        ['CONS_FOOD_Fruit_Apple_A'] = false,
    }),
    weapons = ItemList:New("AutoSendFoodToCamp/weapons_food_list.json", {
        ['WPN_HUM_Salami_A'] = true,
    }),
    user_defined = ItemList:New("AutoSendFoodToCamp/user_ignored_food_list.json",
        {
            ["ADD_ITEMS_TEMPLATES_NAMES_HERE. CHECK OTHER FILES FOR EXAMPLES"] = true }),
}

function FoodDelivery.DeliverAwaitingFood()
    if FoodDelivery.awaiting_delivery.item ~= nil and FoodDelivery.awaiting_delivery.item ~= FoodDelivery.ignore_item.item then
        ASFTCPrint(2, "Delivering awaiting food: " .. FoodDelivery.awaiting_delivery.item)
        FoodDelivery.DeliverFood(FoodDelivery.awaiting_delivery.item)
        FoodDelivery.UpdateAwaitingItem(nil, nil)
    end
end

-- Don't move items that are in the retainlist according to settings
function FoodDelivery.IsFoodItemRetainlisted(foodItem)
    local foodItemGuid = VCHelpers.Format:GetTemplateName(foodItem)
    if foodItemGuid == nil then
        ASFTCWarn(1, "Couldn't verify if item is retainlisted. foodItemGuid is nil.")
        return false
    end

    local isQuestItem = FoodDelivery.retainlist.quests:Contains(foodItemGuid)
    local isHealingItem = FoodDelivery.retainlist.healing:Contains(foodItemGuid)
    local isWeapon = FoodDelivery.retainlist.weapons:Contains(foodItemGuid)
    local isUserDefined = FoodDelivery.retainlist.user_defined:Contains(foodItemGuid)
    local isWare = VCHelpers.Ware:IsWare(foodItem)
    local isRare = not VCHelpers.Rarity:IsItemRarityEqualOrLower(foodItem,
        MCMAPI:GetConfigValue('maximum_rarity', ModuleUUID))

    if isQuestItem then
        ASFTCPrint(2, "Moved item is a quest item. Not trying to send to chest.")
        return true
    else
        ASFTCPrint(1, "Moved item is not a quest item. May try to send to chest.")
    end

    if isHealingItem then
        if MCMAPI:GetConfigValue('ignore_healing', ModuleUUID) then
            ASFTCPrint(2, "Moved item is a healing item. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1, "Moved item is a healing item, but ignore.healing is set to false. May try to send to chest.")
        end
    end

    -- Osi.IsWeapon doesn't work for some reason
    if isWeapon then
        if MCMAPI:GetConfigValue('ignore_weapons', ModuleUUID) then
            ASFTCPrint(2, "Moved item is a weapon. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1, "Moved item is a weapon, but ignore.weapons is set to false. May try to send to chest.")
        end
    end

    if isUserDefined then
        if MCMAPI:GetConfigValue('ignore_user_defined', ModuleUUID) then
            ASFTCPrint(2, "Moved item is user defined. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1,
                "Moved item is user defined, but ignore.user_defined is set to false. May try to send to chest.")
        end
    end

    if not isRare then
        ASFTCPrint(2, "Moved item is not rare. May try to send to chest.")
    else
        ASFTCPrint(1,
            "Moved item is more rare than " ..
            MCMAPI:GetConfigValue('maximum_rarity', ModuleUUID) .. ". Not trying to send to chest.")
        return true
    end

    if isWare then
        if MCMAPI:GetConfigValue('ignore_wares', ModuleUUID) then
            ASFTCPrint(2, "Moved item is a ware. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1, "Moved item is a ware, but ignore.wares is set to false. Trying to send to chest.")
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

--- Move an item to the camp chest if it's not ignored.
---@param item GUIDSTRING The item to move.
function FoodDelivery.MoveToCampChest(item)
    ASFTCPrint(2, tostring(FoodDelivery.ignore_item.item) .. " " .. tostring(FoodDelivery.ignore_item.reason))

    if FoodDelivery.ignore_item.item == item then
        ASFTCPrint(2, "Ignoring item: " .. item .. "reason: " .. FoodDelivery.ignore_item.reason)
        FoodDelivery.ignore_item.item = nil
        return
    end

    if not FoodDelivery.IsFoodItemRetainlisted(item) then
        ASFTCPrint(1, "Moving " .. item .. " to camp chest.")
        return Osi.SendToCampChest(item, Osi.GetHostCharacter())
    end
end

--- Send food from a character's inventory to the camp chest.
---@param character GUIDSTRING The character to send food from.
function FoodDelivery.SendInventoryFoodToChest(character)
    local campChestSack = CheckForCampChestSupplySack()
    local shallow = not MCMAPI:GetConfigValue('nested_containers', ModuleUUID) or false
    local minFoodToKeep = MCMAPI:GetConfigValue('minimum_food_to_keep', ModuleUUID) or 0

    local inventoryFood = VCHelpers.Food:GetFoodInInventory(character, shallow)
    if inventoryFood == nil then
        ASFTCPrint(2, "No food items found in " .. character .. "'s inventory.")
        return
    end

    -- Filter out items that are on the retain list and calculate total food count
    local foodToSend = {}
    local totalFoodCount = 0
    for _, item in ipairs(inventoryFood) do
        if not FoodDelivery.IsFoodItemRetainlisted(item) then
            local _, itemQuantity = Osi.GetStackAmount(item)
            totalFoodCount = totalFoodCount + itemQuantity
            table.insert(foodToSend, item)
        end
    end

    local foodToKeepCount = math.min(totalFoodCount, minFoodToKeep)
    local nFoodToSend = totalFoodCount - foodToKeepCount

    ASFTCPrint(2, "Found " .. totalFoodCount .. " food items in " .. character .. "'s inventory.")
    ASFTCPrint(2, "Keeping " .. foodToKeepCount .. " food items in the inventory.")
    ASFTCPrint(2, "Sending " .. nFoodToSend .. " food items to the camp chest.")

    -- Deliver the food items, keeping the specified number in the inventory
    -- NOTE: Due to how DeliverFood works, it will not account stacks correctly, but this is good enough
    local foodSentCount = 0
    for _, item in ipairs(foodToSend) do
        local _, itemQuantity = Osi.GetStackAmount(item)
        if foodSentCount < nFoodToSend then
            local sendQuantity = math.min(itemQuantity, nFoodToSend - foodSentCount)
            FoodDelivery.DeliverFood(item, character, campChestSack)
            foodSentCount = foodSentCount + sendQuantity
        end
        if foodSentCount >= nFoodToSend then
            break
        end
    end
end

--- Send food to camp chest or supply sack.
---@param object GUIDSTRING The item to deliver.
---@param from GUIDSTRING The inventory to deliver from.
---@param campChestSack? GUIDSTRING The supply sack to deliver to.
function FoodDelivery.DeliverFood(object, from, campChestSack)
    local shouldMove = FoodDelivery.ShouldMoveItem(object)
    if shouldMove then
        FoodDelivery.MoveItemToCampChest(object, from, campChestSack)
    else
        ASFTCPrint(2, object .. " should not be moved to camp chest.")
    end
end

--- Check if an item should be moved to the camp chest.
---@param object GUIDSTRING The item to check.
function FoodDelivery.ShouldMoveItem(object)
    ASFTCPrint(2, "Checking if item should be moved: " .. object)

    if not VCHelpers.Object:IsItem(VCHelpers.Format:Guid(object)) then
        ASFTCPrint(2, object .. " is not an item, won't move")
        return false
    end

    if not VCHelpers.Food:IsFood(object) then
        ASFTCPrint(2, object .. " is not food, won't move")
        return false
    end

    if FoodDelivery.IsFoodItemRetainlisted(object) then
        ASFTCPrint(2, object .. " is on the retainlist, won't move")
        return false
    end

    if VCHelpers.Food:IsBeverage(object) then
        local shouldMoveBeverages = MCMAPI:GetConfigValue('move_beverages', ModuleUUID)
        ASFTCPrint(2,
            object .. " is a food item (beverage). Config value 'move_beverages' is " .. tostring(shouldMoveBeverages))
        return shouldMoveBeverages
    else
        local shouldMoveFood = MCMAPI:GetConfigValue('move_food', ModuleUUID)
        ASFTCPrint(2, object .. " is a food item. Config value 'move_food' is " .. tostring(shouldMoveFood))
        return shouldMoveFood
    end
end

--- Move an item to the camp chest.
---@param object GUIDSTRING The item to move.
---@param from GUIDSTRING The inventory to move from.
---@param campChestSack? GUIDSTRING The optional supply sack/inventory to move to.
function FoodDelivery.MoveItemToCampChest(object, from, campChestSack)
    local exactamount, totalamount = Osi.GetStackAmount(object)
    ASFTCPrint(2, "Should move " .. object .. " to camp chest.")

    local targetInventory = FoodDelivery.GetFoodDeliveryTargetInventory(campChestSack)
    if targetInventory == nil then
        ASFTCPrint(1, "No target inventory found for food delivery, defaulting to camp chest.")
        targetInventory = VCHelpers.Camp:GetChestTemplateUUID()
    end

    Osi.ToInventory(object, targetInventory, totalamount, 1, 1)
end

--- Get the target inventory for food delivery.
---@param campChestSack? GUIDSTRING The optional supply sack to deliver to.
---@return GUIDSTRING|nil - The target inventory. Supply sack if provided or camp chest otherwise.
function FoodDelivery.GetFoodDeliveryTargetInventory(campChestSack)
    -- tfw this is all useless because the supply sack is always used anyways
    if not MCMAPI:GetConfigValue('send_to_supply_sack', ModuleUUID) then
        return nil
    end

    ASFTCPrint(2, "Sending food to supply sack")
    if campChestSack ~= nil then
        ASFTCPrint(2, "Using provided supply sack")
        return campChestSack
    end

    ASFTCPrint(2, "Supply sack not provided, trying to find one")
    local getCampChestSack = CheckForCampChestSupplySack()
    if getCampChestSack ~= nil then
        ASFTCPrint(2, "Found supply sack")
        return getCampChestSack
    end

    ASFTCPrint(1, "Camp chest supply sack not found.")
    ASFTCPrint(2, "Sending food to camp chest instead")
    return VCHelpers.Camp:GetChestTemplateUUID()
end

return FoodDelivery
