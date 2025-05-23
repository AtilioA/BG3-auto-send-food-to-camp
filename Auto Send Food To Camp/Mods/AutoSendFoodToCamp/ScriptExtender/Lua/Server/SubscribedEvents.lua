SubscribedEvents = {}

function SubscribedEvents.SubscribeToEvents()
    local function conditionalWrapper(handler)
        return function(...)
            if MCM.Get("mod_enabled") then
                handler(...)
            else
                ASFTCDebug(1, "Event handling is disabled.")
            end
        end
    end

    ASFTCPrint(2,
        "Subscribing to events with JSON config: " ..
        Ext.Json.Stringify(Mods.BG3MCM.MCMAPI:GetAllModSettings(ModuleUUID)))

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "before", conditionalWrapper(EHandlers.OnLevelGameplayStarted))
    Ext.Osiris.RegisterListener("TimerFinished", 1, "before", conditionalWrapper(EHandlers.OnTimerFinished))

    -- Moving/looting
    Ext.Osiris.RegisterListener("MovedFromTo", 4, "before", conditionalWrapper(EHandlers.OnMovedFromTo))

    -- Item pickup
    Ext.Osiris.RegisterListener("RequestCanPickup", 3, "after", conditionalWrapper(EHandlers.OnRequestCanPickup))
    Ext.Osiris.RegisterListener("PickupFailed", 2, "after", conditionalWrapper(EHandlers.OnPickupFailed))

    Ext.Osiris.RegisterListener("TeleportedToCamp", 1, "before", conditionalWrapper(EHandlers.OnTeleportedToCamp))

    Ext.Osiris.RegisterListener("ToInventory", 5, "after", EHandlers.OnToInventory)

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

return SubscribedEvents
