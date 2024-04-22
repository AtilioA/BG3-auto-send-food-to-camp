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
    quests = ItemList:New(Config:GetModFolderPath("quest_food_list.json"), { ['Quest_CON_OwlBearEgg'] = true }),
    healing = ItemList:New(Config:GetModFolderPath("healing_food_list.json"), {
        ['UNI_CONS_Goodberry'] = true,
        ['GEN_CONS_Berry'] = true,
        ['QUEST_GOB_SuspiciousMeat'] = true,
        ['DEN_UNI_Thieflings_Gruel'] = true,
        ['CONS_FOOD_Fruit_Apple_A'] = false,
    }),
    weapons = ItemList:New(Config:GetModFolderPath("weapons_food_list.json"), {
        ['WPN_HUM_Salami_A'] = true,
    }),
    user_defined = ItemList:New(Config:GetModFolderPath("user_ignored_food_list.json"),
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
    local isRare = VCHelpers.Object:IsItemRarityEqualOrLower(foodItemGuid, Config:getCfg().FEATURES.minimum_rarity)

    if isQuestItem then
        ASFTCPrint(2, "Moved item is a quest item. Not trying to send to chest.")
        return true
    else
        ASFTCPrint(1, "Moved item is not a quest item. May try to send to chest.")
    end

    if isHealingItem then
        if Config:getCfg().FEATURES.ignore.healing then
            ASFTCPrint(2, "Moved item is a healing item. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1, "Moved item is a healing item, but ignore.healing is set to false. May try to send to chest.")
        end
    end

    -- Osi.IsWeapon doesn't work for some reason
    if isWeapon then
        if Config:getCfg().FEATURES.ignore.weapons then
            ASFTCPrint(2, "Moved item is a weapon. Not trying to send to chest.")
            return true
        else
            ASFTCPrint(1, "Moved item is a weapon, but ignore.weapons is set to false. May try to send to chest.")
        end
    end

    if isUserDefined then
        if Config:getCfg().FEATURES.ignore.user_defined then
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
            Config:getCfg().FEATURES.minimum_rarity .. ". Not trying to send to chest.")
        return true
    end

    if isWare then
        if Config:getCfg().FEATURES.ignore.wares then
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

function FoodDelivery.MoveToCampChest(item)
    ASFTCPrint(2, tostring(FoodDelivery.ignore_item.item) .. " " .. tostring(FoodDelivery.ignore_item.reason))
    if (FoodDelivery.ignore_item.item == item) then
        ASFTCPrint(2, "Ignoring item: " .. item .. "reason: " .. FoodDelivery.ignore_item.reason)
        FoodDelivery.ignore_item.item = nil
        return
    else
        if not FoodDelivery.IsFoodItemRetainlisted(item) then
            ASFTCPrint(1, "Moving " .. item .. " to camp chest.")
            return Osi.SendToCampChest(item, Osi.GetHostCharacter())
        end
    end
end

function FoodDelivery.SendInventoryFoodToChest(character)
    local campChestSack = CheckForCampChestSupplySack()
    -- Not sure if nil is falsey in Lua, so we'll just be explicit
    local shallow = not Config:getCfg().FEATURES.send_existing_food.nested_containers or false

    local food = GetFoodInInventory(character, shallow)
    if food ~= nil then
        for _, item in ipairs(food) do
            ASFTCPrint(2, "Found food in " .. character .. "'s inventory: " .. item)
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

    if VCHelpers.Object:IsItem(object) then
        if VCHelpers.Food:IsFood(object) then
            if FoodDelivery.IsFoodItemRetainlisted(object) then
                return
            end

            if VCHelpers.Food:IsBeverage(object) then
                if Config:getCfg().FEATURES.move_beverages then
                    shouldMove = true
                    ASFTCPrint(1, object .. " is beverage, will move to camp chest.")
                else
                    shouldMove = false
                    ASFTCPrint(1, object .. " is beverage, won't move to camp chest.")
                end
            else
                if Config:getCfg().FEATURES.move_food then
                    shouldMove = true
                    ASFTCPrint(1, object .. " is food, will move to camp chest.")
                else
                    shouldMove = false
                    ASFTCPrint(1, object .. " is food, won't move to camp chest.")
                end
            end

            if shouldMove then
                local exactamount, totalamount = Osi.GetStackAmount(object)
                ASFTCPrint(2, "Should move " .. object .. " to camp chest.")
                local targetInventory = VCHelpers.Camp:GetChestTemplateUUID()

                -- tfw this is all useless because the supply sack is always used anyways
                if Config:getCfg().FEATURES.send_existing_food.send_to_supply_sack then
                    if campChestSack ~= nil then
                        targetInventory = campChestSack.Guid
                    else
                        -- Try to get the supply sack anyways if it has not been provided
                        local getCampChestSack = CheckForCampChestSupplySack()
                        if getCampChestSack ~= nil then
                            targetInventory = getCampChestSack.Guid
                        else
                            ASFTCPrint(1, "Camp chest supply sack not found.")
                            targetInventory = VCHelpers.Camp:GetChestTemplateUUID()
                        end
                    end
                end

                if targetInventory then
                    Osi.ToInventory(object, targetInventory, totalamount, 1, 1)
                else
                    ASFTCPrint(1, "Target inventory not found, not moving " .. object .. " to camp chest.")
                end
            else
                ASFTCPrint(2, object .. " is not food, won't move to camp chest.")
            end
        end
    else
        ASFTCPrint(2, object .. " is not an item, won't process.")
    end
end

return FoodDelivery
