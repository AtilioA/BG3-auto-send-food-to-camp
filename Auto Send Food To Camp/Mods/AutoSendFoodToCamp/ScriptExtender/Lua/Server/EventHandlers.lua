EHandlers = {}

function EHandlers.OnLevelGameplayStarted()
    if MCMGet('send_existing_food') and MCMGet('create_supply_sack') then
        Osi.TimerLaunch("CreateSupplySackTimer", 1500)
    end
end

local function CreateSupplySack()
    ASFTCPrint(2, "CreateSupplySack: creating supply sack.")
    AddSupplySackToCampChestIfMissing()
end

function EHandlers.OnTimerFinished(timerName)
    if timerName == "FoodDeliveryTimer" then
        FoodDelivery.DeliverAwaitingFood()
    end

    if timerName == 'CreateSupplySackTimer' then
        CreateSupplySack()
    end
end

-- Common helper function for handling logic
function EHandlers.HandleItemMovement(character, movedObject, fromObject, toObject, isTrade)
    if not movedObject or not fromObject then
        ASFTCWarn(1, "One or more parameters are nil, won't handle movement.")
        return false
    end

    ASFTCPrint(2,
        "HandleItemMovement called: " ..
        character .. " moved " .. movedObject .. " from " .. (fromObject or "nil") .. " to " .. (toObject or "nil"))

    local chestName = VCHelpers.Camp:GetChestTemplateUUID()

    if not chestName then
        ASFTCWarn(1, "Chest name is nil, won't handle movement.")
        return false
    end

    local isFromObjectInParty = Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) == 1
    local isFromObjectInCamp = VCHelpers.Character:IsCharacterInCamp(fromObject)
    local isToObjectInParty = toObject and Osi.IsInPartyWith(toObject, Osi.GetHostCharacter()) == 1 or false
    local isToObjectInCamp = VCHelpers.Character:IsCharacterInCamp(toObject)
    local isMovingFromPartyToNotTrade = isFromObjectInParty and isTrade ~= 1
    local isFromObjectCharacter = Osi.IsCharacter(fromObject) == 1
    local isItemBeingMovedFromOtherCharacter = (not isFromObjectInParty and isToObjectInParty) or
        (isFromObjectCharacter and not isFromObjectInParty)

    if isFromObjectInCamp or isToObjectInCamp then
        ASFTCPrint(2, "Item is being moved from or to camp, not trying to send to chest.")
        return false
    end

    if isMovingFromPartyToNotTrade then
        ASFTCPrint(2, "Item is being moved from party and not in trade, not trying to send to chest.")
        return false
    end

    if isItemBeingMovedFromOtherCharacter then
        ASFTCPrint(2, "Item is being moved from character, trying to send to chest.")
        return true
    end

    return true
end

-- Refactored OnMovedFromTo function
function EHandlers.OnMovedFromTo(movedObject, fromObject, toObject, isTrade)
    local shouldSendToChest = EHandlers.HandleItemMovement(fromObject, movedObject, fromObject, toObject,
        isTrade)
    if shouldSendToChest then
        if (MCMGet('move_bought_food') and isTrade == 1 and VCHelpers.Format:Guid(fromObject) ~= Osi.GetHostCharacter() and not Osi.IsInInventoryOf(fromObject, GetHostCharacter()) == 1) then
            ASFTCPrint(2, "Got item from trade, trying to send to chest.")
            FoodDelivery.DeliverFood(movedObject, fromObject)
            return
        else
            ASFTCPrint(2, "Host is selling item, not trying to send to chest.")
        end
    end
end

-- Refactored OnRequestCanPickup function
function EHandlers.OnRequestCanPickup(character, object, requestID)
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

function EHandlers.OnPickupFailed(character, object)
    ASFTCPrint(2, "OnPickupFailed: " .. character .. " " .. object)
    if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
        ASFTCPrint(2, "Character is in party with host.")
    end
end

function EHandlers.OnTeleportedToCamp(character)
    if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
        ASFTCPrint(2, "Sending existing food to chest from " .. character)
        FoodDelivery.SendInventoryFoodToChest(character)
    end
end

return EHandlers
