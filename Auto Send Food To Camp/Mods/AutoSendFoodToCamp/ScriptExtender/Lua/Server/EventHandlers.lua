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

---@class InventoryTransfer
---@field object Guid
---@field target Guid
---@field source GUIDSTRING
---@field process boolean
---@field template Guid|nil
---@field quantity integer|nil
---@field addedItems table<Guid, GUIDSTRING>
---@field handledItems table<Guid, boolean>

-- Each native ToInventory call has its own record, including reentrant calls.
---@type InventoryTransfer[]
local inventoryTransfers = {}

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
---@param campChests EntityHandle[]|nil The current camp chest entities, if already resolved.
---@return boolean shouldProcess Whether the movement should be processed.
function EHandlers.ShouldProcessItemMovement(character, movedObject, fromObject, toObject, isTrade, campChests)
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

    campChests = campChests or VCHelpers.Camp:GetAllCampChestEntities()
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
    local transfer = inventoryTransfers[#inventoryTransfers]
    local guid = VCHelpers.Format:Guid(movedObject)
    if transfer and VCHelpers.Format:Guid(toObject) == transfer.target
        and (guid == transfer.object or transfer.addedItems[guid]) then
        transfer.handledItems[guid] = true
    end
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
--- Records the actual added stack, which can differ from the requested item.
---@param object GUIDSTRING The item added to the destination.
---@param inventoryHolder GUIDSTRING The destination inventory.
---@param _addType string The inventory addition type.
---@return nil
function EHandlers.OnAddedTo(object, inventoryHolder, _addType)
    local transfer = inventoryTransfers[#inventoryTransfers]
    if transfer and transfer.process
        and (VCHelpers.Format:Guid(inventoryHolder) == transfer.target
            or VCHelpers.Inventory:ItemIsInInventory(inventoryHolder, transfer.target))
        and VCHelpers.Format:Guid(Osi.GetTemplate(object)) == transfer.template then
        transfer.addedItems[VCHelpers.Format:Guid(object)] = object
    end
end

--- Delivers completed scripted acquisitions
---@param object GUIDSTRING The requested item.
---@param targetObject GUIDSTRING The destination inventory.
---@param _amount integer The requested item count.
---@param _showNotification integer Whether to show a transfer notification.
---@param _clearOriginalOwner integer Whether to clear the original owner.
---@return nil
function EHandlers.OnToInventory(object, targetObject, _amount, _showNotification, _clearOriginalOwner)
    local transfer = table.remove(inventoryTransfers)
    if not transfer or not transfer.process then
        return
    end

    local arrived = VCHelpers.Inventory:ItemIsInInventory(object, targetObject)
    local entity = VCHelpers.Object:GetEntity(object)
    if entity and not arrived then
        local remaining = Osi.GetStackAmount(object)
        -- A split can leave the original stack behind
        if not remaining or not transfer.quantity or remaining >= transfer.quantity then
            ASFTCDebug(2, "Scripted transfer did not move the requested stack: " .. object)
            return
        end
    end

    -- AddedTo identifies split or merged stacks; the original is safe only after verified arrival.
    if not next(transfer.addedItems) and arrived then
        transfer.addedItems[transfer.object] = object
    end

    if not next(transfer.addedItems) then
        ASFTCDebug(2, "No completed scripted acquisition observed: " .. object)
        return
    end

    local campChests = VCHelpers.Camp:GetAllCampChestEntities()
    for guid, item in pairs(transfer.addedItems) do
        if not transfer.handledItems[guid]
            and VCHelpers.Inventory:ItemIsInInventory(item, targetObject)
            and not IsCampStorage(item, campChests) then
            ASFTCDebug(2, "Processing scripted acquisition: " .. item)
            FoodDelivery.DeliverFood(item, transfer.source)
        end
    end
end

return EHandlers
