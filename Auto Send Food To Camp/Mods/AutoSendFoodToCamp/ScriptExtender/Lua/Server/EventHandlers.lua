EHandlers = {}

EHandlers.usingCampChest = false


function EHandlers.OnMovedFromTo(movedObject, fromObject, toObject, isTrade)
    if EHandlers.usingCampChest == true then
        ASFTCPrint(2, "Character is using camp chest, won't send anything to chest.")
        return
    end

    if not movedObject or not fromObject or not toObject then
        ASFTCWarn(1, "One or more parameters are nil, won't handle MovedFromTo.")
        return
    end

    ASFTCPrint(2,
        "OnMovedFromTo called: " ..
        movedObject .. " from " .. fromObject .. " to " .. toObject .. " isTrade " .. tostring(isTrade))

    local chestName = VCHelpers.Camp:GetChestTemplateUUID()

    if not chestName then
        ASFTCWarn(1, "Chest name is nil, won't handle MovedFromTo.")
        return
    end

    local isItemFromCampChest = fromObject == chestName
    local isItemInCampChest = Osi.IsInInventoryOf(movedObject, chestName) == 1
    local isItemInContainerInCampChest = Osi.IsInInventoryOf(fromObject, chestName) == 1
    local isItemInHostContainer = Osi.IsInInventoryOf(fromObject, GetHostCharacter()) == 1

    if isItemFromCampChest or isItemInCampChest or isItemInContainerInCampChest then
        ASFTCPrint(2, "Item is from or inside the camp chest. Not trying to send to chest.")
        return
    end

    local isFromObjectInParty = Osi.IsInPartyWith(fromObject, Osi.GetHostCharacter()) == 1
    local isToObjectInParty = Osi.IsInPartyWith(toObject, Osi.GetHostCharacter()) == 1
    local isFromObjectInCamp = VCHelpers.Character:IsCharacterInCamp(fromObject)
    local isToObjectInCamp = VCHelpers.Character:IsCharacterInCamp(toObject)
    local isMovingFromPartyToNotTrade = isFromObjectInParty and isTrade ~= 1
    local isFromObjectCharacter = Osi.IsCharacter(fromObject) == 1
    local isItemBeingMovedFromOtherCharacter = (not isFromObjectInParty and isToObjectInParty) or
        (isFromObjectCharacter and not isFromObjectInParty)

    if (isFromObjectInParty and isFromObjectInCamp) or (isToObjectInParty and isToObjectInCamp) then
        ASFTCPrint(2, "Item is from party and in camp, not trying to send to chest.")
        return
    end

    if isMovingFromPartyToNotTrade then
        ASFTCPrint(2, "Item is being moved from party and not in trade, not trying to send to chest.")
        return
    end

    if isItemBeingMovedFromOtherCharacter then
        ASFTCPrint(2, "Item is being moved from character, trying to send to chest.")
        FoodDelivery.DeliverFood(movedObject, fromObject)
        return
    end

    if (MCMGet('move_bought_food') and isTrade == 1 and VCHelpers.Format:Guid(fromObject) ~= Osi.GetHostCharacter() and not isItemInHostContainer) then
        ASFTCPrint(2, "Got item from trade, trying to send to chest.")
        FoodDelivery.DeliverFood(movedObject, fromObject)
        return
    else
        ASFTCPrint(2, "Host is selling item, not trying to send to chest.")
    end
end

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

function EHandlers.OnRequestCanPickup(character, object, requestID)
    if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
        if EHandlers.usingCampChest == true then
            ASFTCPrint(2, "Character is using camp chest, won't send anything to chest.")
            return
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

function EHandlers.OnUseStarted(character, item)
    if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
        ASFTCPrint(2, "UseStarted: " .. character .. " " .. item)
        local activeCampChests = VCHelpers.Camp:GetAllCampChestUUIDs()
        for _,
        chestUUID in pairs(activeCampChests) do
            if VCHelpers.Format:Guid(item) == chestUUID then
                EHandlers.usingCampChest = true
                break
            end
        end
    end
end

function EHandlers.OnUseEnded(character, item, result)
    if Osi.IsInPartyWith(character, Osi.GetHostCharacter()) == 1 then
        ASFTCPrint(2, "UseEnded: " .. character .. " " .. item .. " " .. result)
        local activeCampChests = VCHelpers.Camp:GetAllCampChestUUIDs()
        for _, chestUUID in pairs(activeCampChests) do
            if VCHelpers.Format:Guid(item) == chestUUID then
                EHandlers.usingCampChest = false
                break
            end
        end
    end
end

return EHandlers
