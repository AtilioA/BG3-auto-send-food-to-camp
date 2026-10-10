EHandlers = {}

--- Checks instance containment in any camp chest, including the chest itself.
---@param object GUIDSTRING|nil The inventory endpoint.
---@param campChests EntityHandle[] The current camp chest entities.
---@return boolean
local function IsCampStorage(object, campChests)
    if not object then
        return false
    end

    local entity = VCHelpers.Object:GetEntity(object)
    if not entity then
        return false
    end

    for _, chest in pairs(campChests) do
        if entity == chest or VCHelpers.Inventory:ItemIsInInventory(entity, chest) then
            return true
        end
    end
    return false
end

--- Finds the party character holding an inventory, directly or through containers.
---@param object GUIDSTRING The destination inventory.
---@return Guid|nil
local function GetPartyInventoryOwner(object)
    local entity = VCHelpers.Object:GetEntity(object)
    local host = Osi.GetHostCharacter()
    while entity do
        local guid = entity.Uuid.EntityUuid
        if Osi.IsInPartyWith(guid, host) == 1 then
            return guid
        end
        entity = VCHelpers.Inventory:GetHolder(entity)
    end
    return nil
end

--- Handles the start of gameplay in a level.
---@return nil
function EHandlers.OnLevelGameplayStarted()
    if MCM.Get('send_existing_food') and MCM.Get('create_supply_sack') then
        Osi.TimerLaunch("CreateSupplySackTimer", 1500)
    end
end

--- Creates the configured camp supply sack.
---@return nil
local function CreateSupplySack()
    ASFTCPrint(2, "CreateSupplySack: creating supply sack.")
    AddSupplySackToCampChestIfMissing()
end

--- Handles completed Osiris timers.
---@param timerName string The completed timer name.
---@return nil
function EHandlers.OnTimerFinished(timerName)
    if timerName == "FoodDeliveryTimer" then
        FoodDelivery.DeliverAwaitingFood()
    end

    if timerName == 'CreateSupplySackTimer' then
        CreateSupplySack()
    end
end

--- Determines whether an item movement should trigger food delivery.
---@param character GUIDSTRING The character associated with the movement.
---@param movedObject GUIDSTRING|nil The moved item.
---@param fromObject GUIDSTRING|nil The source inventory owner.
---@param toObject GUIDSTRING|nil The destination inventory owner.
---@param isTrade integer|nil Whether the movement is part of a trade.
---@return boolean shouldProcess Whether the movement should be processed.
function EHandlers.ShouldProcessItemMovement(character, movedObject, fromObject, toObject, isTrade)
    --- Checks whether a traded item should be processed.
    ---@param isFromObjectInParty boolean Whether the source belongs to the party.
    ---@return boolean|nil shouldProcess Whether the trade movement should be processed.
    local function ShouldProcessTradedItem(isFromObjectInParty)
        if isTrade == 1 then
            if isFromObjectInParty then
                ASFTCPrint(2, "Item is being traded from party, not trying to send to chest.")
                return false
            elseif MCM.Get("move_bought_food") then
                ASFTCPrint(2, "Item is being traded to party, trying to send to chest.")
                return true
            end
        else
            return true
        end
    end

    if not movedObject or not fromObject then
        ASFTCWarn(1, "One or more parameters are nil, won't handle movement.")
        return false
    end

    ASFTCPrint(2,
        "ShouldProcessItemMovement called: " ..
        character .. " moved " .. movedObject .. " from " .. (fromObject or "nil") .. " to " .. (toObject or "nil"))

    local isFromObjectInParty = Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) == 1
    local isToObjectInParty = toObject and Osi.IsInPartyWith(toObject, Osi.GetHostCharacter()) == 1 or false

    if isFromObjectInParty and isToObjectInParty then
        ASFTCPrint(2, "Item is being moved between party members, not trying to send to chest.")
        return false
    end

    if VCHelpers.Character:IsCharacterInCamp(fromObject)
        or (toObject and VCHelpers.Character:IsCharacterInCamp(toObject)) then
        ASFTCPrint(2, "Item is being moved from or to camp, not trying to send to chest.")
        return false
    end

    if not VCHelpers.Camp:GetChestTemplateUUID() then
        ASFTCWarn(1, "Chest name is nil, won't handle movement.")
        return false
    end

    local campChests = VCHelpers.Camp:GetAllCampChestEntities()
    if IsCampStorage(fromObject, campChests) or IsCampStorage(toObject, campChests) then
        ASFTCPrint(2, "Item is being moved from or to camp chest, not trying to send to chest.")
        return false
    end

    if not ShouldProcessTradedItem(isFromObjectInParty) then
        ASFTCDebug(2, "Not processing trade item.")
        return false
    end

    if isFromObjectInParty and not isToObjectInParty then
        ASFTCPrint(2, "Item is being moved from party, not trying to send to chest.")
        return false
    end

    return true
end

--- Processes a moved item for possible food delivery.
---@param movedObject GUIDSTRING The moved item.
---@param fromObject GUIDSTRING The source inventory owner.
---@param toObject GUIDSTRING|nil The destination inventory owner.
---@param isTrade integer|nil Whether the movement is part of a trade.
---@return nil
local function processMovedItem(movedObject, fromObject, toObject, isTrade)
    local shouldSendToChest = EHandlers.ShouldProcessItemMovement(fromObject, movedObject, fromObject, toObject, isTrade)
    if shouldSendToChest then
        FoodDelivery.DeliverFood(movedObject, fromObject)
    end
end

--- Handles an Osiris item movement event.
---@param movedObject GUIDSTRING The moved item.
---@param fromObject GUIDSTRING The source inventory owner.
---@param toObject GUIDSTRING The destination inventory owner.
---@param isTrade integer Whether the movement is part of a trade.
---@return nil
function EHandlers.OnMovedFromTo(movedObject, fromObject, toObject, isTrade)
    processMovedItem(movedObject, fromObject, toObject, isTrade)
end

--- Handles an Osiris pickup request.
---@param character GUIDSTRING|nil The character requesting the pickup.
---@param object GUIDSTRING|nil The requested item.
---@param requestID integer The pickup request identifier.
---@return boolean|nil
function EHandlers.OnRequestCanPickup(character, object, requestID)
    if not character or not object then
        ASFTCWarn(1, "One or more parameters are nil, won't handle movement.")
        return
    end

    if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
        local isFromObjectInCamp = VCHelpers.Character:IsCharacterInCamp(character)
        local isToObjectInCamp = VCHelpers.Character:IsCharacterInCamp(object)
        if isFromObjectInCamp or isToObjectInCamp then
            ASFTCPrint(2, "Item is being moved from or to camp, not trying to send to chest.")
            return false
        end

        ASFTCPrint(2, "OnRequestCanPickup: " .. character .. " " .. object .. " " .. requestID)
        FoodDelivery.UpdateAwaitingItem(object, "RequestCanPickup")
        Osi.TimerLaunch("FoodDeliveryTimer", 500)
    end
end

--- Handles a failed Osiris pickup.
---@param character GUIDSTRING The character attempting the pickup.
---@param object GUIDSTRING The item that was not picked up.
---@return nil
function EHandlers.OnPickupFailed(character, object)
    ASFTCPrint(2, "OnPickupFailed: " .. character .. " " .. object)
    if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
        ASFTCPrint(2, "Character is in party with host.")
    end
end

--- Handles a character teleporting to camp.
---@param character GUIDSTRING The teleported character.
---@return nil
function EHandlers.OnTeleportedToCamp(character)
    if MCM.Get('send_existing_food') and Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
        ASFTCPrint(2, "Sending existing food to chest from " .. character)
        FoodDelivery.SendInventoryFoodToChest(character)
    end
end

--- Handles an Osiris inventory transfer.
---@param object GUIDSTRING The transferred item.
---@param targetObject GUIDSTRING The destination inventory owner.
---@param _amount integer The transferred item count.
---@param _showNotification integer Whether to show a transfer notification.
---@param _clearOriginalOwner integer Whether to clear the original owner.
---@return nil
function EHandlers.OnToInventory(object, targetObject, _amount, _showNotification, _clearOriginalOwner)
    -- Check if this move was initiated by this mod - if so, skip processing
    if FoodDelivery.is_mod_moving_item then
        ASFTCDebug(2, "Ignoring ToInventory event for item moved by us: " .. object)
        return
    end

    if not MCM.Get('send_items_moved_automatically') then
        return
    end

    -- Carried containers are not characters; resolve the destination's party owner through its ancestry.
    if not GetPartyInventoryOwner(targetObject) then
        ASFTCDebug(2, "Destination inventory is not held by a party member.")
        return
    end

    processMovedItem(object, object, targetObject, nil)
end

return EHandlers
