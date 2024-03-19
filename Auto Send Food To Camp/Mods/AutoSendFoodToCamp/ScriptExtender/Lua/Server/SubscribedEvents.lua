SubscribedEvents = {}

function SubscribedEvents.SubscribeToEvents()
  if Config:getCfg().GENERAL.enabled == true then
    ASFTCPrint(2, "Subscribing to events with JSON config: " .. Ext.Json.Stringify(Config:getCfg(), { Beautify = true }))

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "before", EHandlers.OnLevelGameplayStarted)
    Ext.Osiris.RegisterListener("TimerFinished", 1, "before", EHandlers.OnTimerFinished)

    -- Moving/looting
    Ext.Osiris.RegisterListener("MovedFromTo", 4, "before", EHandlers.OnMovedFromTo)


    -- Item pickup
    Ext.Osiris.RegisterListener("RequestCanPickup", 3, "after", EHandlers.OnRequestCanPickup)
    Ext.Osiris.RegisterListener("PickupFailed", 2, "after", EHandlers.OnPickupFailed)

    if Config:getCfg().FEATURES.send_existing_food.enabled then
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
