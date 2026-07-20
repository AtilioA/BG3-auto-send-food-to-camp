FoodDelivery = {}

---@class DeliveryState
---@field item GUIDSTRING|nil
---@field reason string|nil

---@type DeliveryState
FoodDelivery.ignore_item = {
    item = nil,
    reason = nil
}

---@type DeliveryState
FoodDelivery.awaiting_delivery = {
    item = nil,
    reason = nil
}

-- Add a flag to track moves initiated by this mod
FoodDelivery.is_mod_moving_item = false

FoodDelivery.retainlist = {
    quests = MCM.GetList('ignore_quests'),
    healing = MCM.GetList('ignore_healing'),
    weapons = MCM.GetList('ignore_weapons'),
    user_defined = MCM.GetList('ignore_user_defined'),
}

Ext.ModEvents["BG3MCM"]["MCM_Setting_Saved"]:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end

    if payload.settingId == "ignore_quests" then
        FoodDelivery.retainlist.quests = MCM.GetList('ignore_quests')
    elseif payload.settingId == "ignore_healing" then
        FoodDelivery.retainlist.healing = MCM.GetList('ignore_healing')
    elseif payload.settingId == "ignore_weapons" then
        FoodDelivery.retainlist.weapons = MCM.GetList('ignore_weapons')
    elseif payload.settingId == "ignore_user_defined" then
        FoodDelivery.retainlist.user_defined = MCM.GetList('ignore_user_defined')
    end
end)


--- Delivers the pending food item unless it is currently ignored.
---@return nil
function FoodDelivery.DeliverAwaitingFood()
    if FoodDelivery.awaiting_delivery.item ~= nil and FoodDelivery.awaiting_delivery.item ~= FoodDelivery.ignore_item.item then
        ASFTCPrint(2, "Delivering awaiting food: " .. FoodDelivery.awaiting_delivery.item)
        FoodDelivery.DeliverFood(FoodDelivery.awaiting_delivery.item)
        FoodDelivery.UpdateAwaitingItem(nil, nil)
    end
end

--- Checks whether an item should remain in its current inventory.
---@param foodItem GUIDSTRING The item to check.
---@return boolean isRetainlisted Whether the item is retained by current settings.
function FoodDelivery.IsFoodItemRetainlisted(foodItem)
    local foodItemGuid = VCHelpers.Format:GetTemplateName(foodItem)
    if foodItemGuid == nil then
        ASFTCWarn(1, "Couldn't verify if item is retainlisted. foodItemGuid is nil.")
        return false
    end

    local isQuestItem = FoodDelivery.retainlist.quests[foodItemGuid]
    local isHealingItem = FoodDelivery.retainlist.healing[foodItemGuid]
    local isWeapon = FoodDelivery.retainlist.weapons[foodItemGuid]
    local isUserDefined = FoodDelivery.retainlist.user_defined[foodItemGuid]
    local isWare = VCHelpers.Ware:IsWare(foodItem)
    local isRare = not VCHelpers.Rarity:IsItemRarityEqualOrLower(foodItem,
        MCM.Get('maximum_rarity'))

    if isQuestItem then
        local questList = MCM.GetList('ignore_quests')
        if questList.enabled then
            ASFTCPrint(2, "Moved item is a quest item. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1,
                "Moved item is a quest item but quest items list is disabled in settings. May try to send to chest.")
        end
    else
        ASFTCPrint(1, "Moved item is not a quest item. May try to send to chest.")
    end

    if isHealingItem then
        local healingList = MCM.GetList('ignore_healing')
        if healingList.enabled then
            ASFTCPrint(2, "Moved item is in the healing items list. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1,
                "Moved item is in the healing items list but healing items list is disabled in settings. May try to send to chest.")
        end
    else
        ASFTCPrint(1, "Moved item is not in the healing items list. May try to send to chest.")
    end

    if isWeapon then
        local weaponList = MCM.GetList('ignore_weapons')
        if weaponList.enabled then
            ASFTCPrint(2, "Moved item is in the weapons list. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1,
                "Moved item is in the weapons list but weapons list is disabled in settings. May try to send to chest.")
        end
    else
        ASFTCPrint(1, "Moved item is not in the weapons list. May try to send to chest.")
    end

    if isUserDefined then
        local userDefinedList = MCM.GetList('ignore_user_defined')
        if userDefinedList.enabled then
            ASFTCPrint(2, "Moved item is in the user-defined list. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1,
                "Moved item is in the user-defined list but user-defined list is disabled in settings. May try to send to chest.")
        end
    else
        ASFTCPrint(1, "Moved item is not in the user-defined list. May try to send to chest.")
    end

    if not isRare then
        ASFTCPrint(2, "Moved item is not rarer than " .. MCM.Get('maximum_rarity') .. ". May try to send to chest.")
    else
        ASFTCPrint(1,
            "Moved item is more rare than " ..
            MCM.Get('maximum_rarity') .. ". Not trying to send to chest.")
        return true
    end

    if isWare then
        if MCM.Get('ignore_wares') then
            ASFTCPrint(2, "Moved item is a ware. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1,
                "Moved item is a ware, but ignore.wares is set to false. Trying to send to chest.")
        end
    end

    return false
end

--- Updates the item currently excluded from delivery.
---@param item GUIDSTRING|nil The ignored item, or nil to clear it.
---@param reason string|nil The reason for ignoring the item.
---@return nil
function FoodDelivery.UpdateIgnoredItem(item, reason)
    FoodDelivery.ignore_item.item = item
    FoodDelivery.ignore_item.reason = reason
end

--- Updates the item awaiting delivery.
---@param item GUIDSTRING|nil The pending item, or nil to clear it.
---@param reason string|nil The reason delivery is pending.
---@return nil
function FoodDelivery.UpdateAwaitingItem(item, reason)
    FoodDelivery.awaiting_delivery.item = item
    FoodDelivery.awaiting_delivery.reason = reason
end

--- Send food from a character's inventory to the camp chest.
---@param character GUIDSTRING The character to send food from.
---@return nil
function FoodDelivery.SendInventoryFoodToChest(character)
    local campChestSack = CheckForCampChestSupplySack()
    local shallow = not MCM.Get('nested_containers') or false
    local minFoodToKeep = MCM.Get('minimum_food_to_keep') or 0

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
---@param from GUIDSTRING|nil The inventory to deliver from.
---@param campChestSack CampSupplySack|nil The supply sack to deliver to.
---@return nil
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
---@return boolean shouldMove Whether the item should be moved.
function FoodDelivery.ShouldMoveItem(object)
    ASFTCPrint(2, "Checking if item should be sent to camp chest: " .. object)

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

    if VCHelpers.Food:IsConsumableFood(object) then
        local moveAlcohol = MCM.Get('move_alcohol')
        local moveConsumables = MCM.Get('move_consumables')

        ASFTCPrint(2, object .. " is a consumable item. " ..
            "move_consumables=" .. tostring(moveConsumables) .. ", " ..
            "move_alcohol=" .. tostring(moveAlcohol))

        -- Check if item is alcoholic and gate on the appropriate setting
        local isAlcoholic = VCHelpers.Food:IsAlcoholicItem(object)
        if isAlcoholic then
            return moveAlcohol
        else
            return moveConsumables
        end
    else
        local shouldMoveFood = MCM.Get('move_food')
        ASFTCPrint(2, object .. " is a food item. Config value 'move_food' is " .. tostring(shouldMoveFood))
        return shouldMoveFood
    end
end

--- Move an item to the camp chest.
---@param object GUIDSTRING|nil The item to move.
---@param from GUIDSTRING|nil The inventory to move from.
---@param campChestSack CampSupplySack|nil The optional supply sack to move to.
---@return nil
function FoodDelivery.MoveItemToCampChest(object, from, campChestSack)
    if object == nil then
        return
    end

    local _exactamount, totalamount = Osi.GetStackAmount(object)
    if totalamount == nil then
        totalamount = 1
    end

    ASFTCPrint(2, "Should move " .. object .. " to camp chest.")
    local ticksToWait = MCM.Get('ticks_to_wait_before_delivery')
    if ticksToWait == nil then
        ticksToWait = 1
    end

    local targetInventory = FoodDelivery.GetFoodDeliveryTargetInventory(campChestSack)
    if type(targetInventory) ~= "string" or targetInventory == "" then
        ASFTCWarn(0, "Invalid food delivery target inventory: expected a non-empty string.")
        return
    end

    -- REVIEW: possibly duplicating items
    VCHelpers.Timer:OnTicks(ticksToWait, function()
        FoodDelivery.is_mod_moving_item = true

        -- Osi can't be trusted
        xpcall(function()
                ASFTCPrint(2, "Moving " .. object .. " to " .. targetInventory .. " with amount " .. totalamount)
                Osi.ToInventory(object, targetInventory, totalamount, 0, 0)
            end,
            function(err)
                ASFTCWarn(0, "Error moving item to inventory: " .. tostring(err))
            end)

        FoodDelivery.is_mod_moving_item = false
    end)
end

--- Get the target inventory for food delivery.
---@param campChestSack CampSupplySack|nil The optional supply sack to deliver to.
---@return GUIDSTRING|nil targetInventory The supply sack or camp chest inventory.
function FoodDelivery.GetFoodDeliveryTargetInventory(campChestSack)
    -- tfw this is all useless because the supply sack is always used anyways
    if not MCM.Get('send_to_supply_sack') then
        ASFTCPrint(1, "No target inventory found for food delivery, defaulting to camp chest.")
        return VCHelpers.Camp:GetChestTemplateUUID()
    end

    ASFTCPrint(2, "Sending food to camp chest")
    if campChestSack ~= nil then
        ASFTCPrint(2, "Using provided supply sack")
        return campChestSack.Guid
    end

    ASFTCPrint(3, "Supply sack not provided, trying to find one")
    local getCampChestSack = CheckForCampChestSupplySack()
    if getCampChestSack ~= nil then
        ASFTCPrint(2, "Found supply sack in camp chest to send food to.")
        return getCampChestSack.Guid
    end

    ASFTCPrint(1, "Camp chest supply sack not found, sending food to camp chest instead")
    return VCHelpers.Camp:GetChestTemplateUUID()
end

return FoodDelivery
