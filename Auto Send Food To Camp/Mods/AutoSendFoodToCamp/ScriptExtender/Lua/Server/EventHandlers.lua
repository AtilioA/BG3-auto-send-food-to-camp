EHandlers = {}

function EHandlers.OnLevelGameplayStarted()
    if MCM.Get('send_existing_food') and MCM.Get('create_supply_sack') then
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
function EHandlers.ShouldProcessItemMovement(character, movedObject, fromObject, toObject, isTrade)
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

    local chestName = VCHelpers.Camp:GetChestTemplateUUID()

    if not chestName then
        ASFTCWarn(1, "Chest name is nil, won't handle movement.")
        return false
    end

    local isFromObjectInParty = Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) == 1
    local isToObjectInParty = toObject and Osi.IsInPartyWith(toObject, Osi.GetHostCharacter()) == 1 or false
    local isFromObjectInCamp = VCHelpers.Character:IsCharacterInCamp(fromObject)
    local isToObjectInCamp = VCHelpers.Character:IsCharacterInCamp(toObject)

    if isFromObjectInParty and isToObjectInParty then
        ASFTCPrint(2, "Item is being moved between party members, not trying to send to chest.")
        return false
    end

    if isFromObjectInCamp or isToObjectInCamp then
        ASFTCPrint(2, "Item is being moved from or to camp, not trying to send to chest.")
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

-- Refactored OnMovedFromTo function
function EHandlers.OnMovedFromTo(movedObject, fromObject, toObject, isTrade)
    local shouldSendToChest = EHandlers.ShouldProcessItemMovement(fromObject, movedObject, fromObject, toObject, isTrade)
    if shouldSendToChest then
        FoodDelivery.DeliverFood(movedObject, fromObject)
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
