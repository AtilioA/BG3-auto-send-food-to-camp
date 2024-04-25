SubscribedEvents = {}

function SubscribedEvents.SubscribeToEvents()
    if BG3MCM:GetConfigValue('enabled', ModuleUUID) == true then
        ASFTCPrint(2,
            "Subscribing to events with JSON config: " .. Ext.Json.Stringify(BG3MCM:GetModSettings(ModuleUUID), { Beautify = true }))

        Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "before", EHandlers.OnLevelGameplayStarted)
        Ext.Osiris.RegisterListener("TimerFinished", 1, "before", EHandlers.OnTimerFinished)

        -- Moving/looting
        Ext.Osiris.RegisterListener("MovedFromTo", 4, "before", EHandlers.OnMovedFromTo)


        -- Item pickup
        Ext.Osiris.RegisterListener("RequestCanPickup", 3, "after", EHandlers.OnRequestCanPickup)
        Ext.Osiris.RegisterListener("PickupFailed", 2, "after", EHandlers.OnPickupFailed)

        if BG3MCM:GetConfigValue('send_existing_food', ModuleUUID) then
            Ext.Osiris.RegisterListener("TeleportedToCamp", 1, "before", EHandlers.OnTeleportedToCamp)
        end


        -- Used to detect camp chest usage
        Ext.Osiris.RegisterListener("UseStarted", 2, "before", EHandlers.OnUseStarted)
        Ext.Osiris.RegisterListener("UseFinished", 3, "before", EHandlers.OnUseEnded)

        -- TODO:
        -- CharacterStoleItem
        -- CharacterPickpocketSuccess

        -- Trading (not necessary because of MovedFromTo?)
        -- Ext.Osiris.RegisterListener("TradeEnds", 2, "before", EHandlers.OnTradeEnds)

        -- Do not use:
        -- Ext.Osiris.RegisterListener("TemplateOpening", 3, "before", EHandlers.OnTemplateOpening)
        -- Ext.Osiris.RegisterListener("Moved", 1, "before", EHandlers.OnMoved)

        -- Ext.Osiris.RegisterListener("DroppedBy", 2, "before", EHandlers.OnDroppedBy)
        -- Ext.Osiris.RegisterListener("PreMovedBy", 2, "after", EHandlers.OnPreMovedBy)
        -- Ext.Osiris.RegisterListener("CharacterStoleItem", 10, "before", EHandlers.OnCharacterStoleItem)
        -- Ext.Osiris.RegisterListener("CharacterPickpocketSuccess", 10, "before", EHandlers.OnCharacterPickpocketSuccess)
    end
end

return SubscribedEvents
