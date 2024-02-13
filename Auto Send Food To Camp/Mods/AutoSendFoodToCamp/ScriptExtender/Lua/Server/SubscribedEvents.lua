local function SubscribeToEvents()
  if JsonConfig.GENERAL.enabled == true then
    Utils.DebugPrint(2, "Subscribing to events with JSON config: " .. Ext.Json.Stringify(JsonConfig, { Beautify = true }))

    Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "before", EHandlers.OnLevelGameplayStarted)

    -- Moving/looting
    Ext.Osiris.RegisterListener("MovedFromTo", 4, "before", EHandlers.OnMovedFromTo)

    Ext.Osiris.RegisterListener("TimerFinished", 1, "before", EHandlers.OnTimerFinished)

    -- Trading
    -- Ext.Osiris.RegisterListener("TradeEnds", 2, "before", EHandlers.OnTradeEnds)

    Ext.Osiris.RegisterListener("RequestCanPickup", 3, "after", EHandlers.OnRequestCanPickup)
    Ext.Osiris.RegisterListener("PickupFailed", 2, "after", EHandlers.OnPickupFailed)

    if JsonConfig.FEATURES.send_existing_food.enabled then
      Ext.Osiris.RegisterListener("TeleportedToCamp", 1, "before", EHandlers.OnTeleportedToCamp)
    end

    -- Ext.Osiris.RegisterListener("TemplateOpening", 3, "before", EHandlers.OnTemplateOpening)
    -- Ext.Osiris.RegisterListener("Moved", 1, "before", EHandlers.OnMoved)
    Ext.Osiris.RegisterListener("UseStarted", 2, "before", EHandlers.OnUseStarted)
    Ext.Osiris.RegisterListener("UseFinished", 3, "before", EHandlers.OnUseEnded)

    -- Do not use:
    -- Ext.Osiris.RegisterListener("DroppedBy", 2, "before", EHandlers.OnDroppedBy)
    -- Ext.Osiris.RegisterListener("PreMovedBy", 2, "after", EHandlers.OnPreMovedBy)
    -- Ext.Osiris.RegisterListener("CharacterStoleItem", 10, "before", EHandlers.OnCharacterStoleItem)
    -- Ext.Osiris.RegisterListener("CharacterPickpocketSuccess", 10, "before", EHandlers.OnCharacterPickpocketSuccess)

    -- TODO:
    -- Ext.Osiris.RegisterListener("CharacterLootedCharacter", 2, "before", EHandlers.OnCharacterLootedCharacter)
    -- CharacterStoleItem
    -- CharacterPickpocketSuccess
  end
end

return {
  SubscribeToEvents = SubscribeToEvents
}
