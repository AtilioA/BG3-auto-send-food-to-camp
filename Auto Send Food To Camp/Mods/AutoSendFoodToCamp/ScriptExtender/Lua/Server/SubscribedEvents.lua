local function SubscribeToEvents()
  if JsonConfig.GENERAL.enabled == true then
    Utils.DebugPrint(2, "Subscribing to events with JSON config: " .. Ext.Json.Stringify(JsonConfig, { Beautify = true }))
    
    -- Moving/looting
    Ext.Osiris.RegisterListener("MovedFromTo", 4, "before", EHandlers.OnMovedFromTo)
    Ext.Osiris.RegisterListener("PreMovedBy", 2, "before", EHandlers.OnPreMovedBy)

    -- Trading
    Ext.Osiris.RegisterListener("TradeEnds", 2, "before", EHandlers.OnTradeEnds)

    -- Ext.Osiris.RegisterListener("TemplateOpening", 3, "before", EHandlers.OnTemplateOpening)
    -- Ext.Osiris.RegisterListener("Moved", 1, "before", EHandlers.OnMoved)
    -- Ext.Osiris.RegisterListener("UseStarted", 2, "before", EHandlers.OnUseStarted)
    -- Ext.Osiris.RegisterListener("UseFinished", 3, "before", EHandlers.OnUseEnded)

    -- TODO:
    -- Ext.Osiris.RegisterListener("RequestCanLoot", 2, "after", EHandlers.OnRequestCanLoot)
    -- Ext.Osiris.RegisterListener("CharacterLootedCharacter", 2, "before", EHandlers.OnCharacterLootedCharacter)
    -- CharacterStoleItem
    -- CharacterPickpocketSuccess
  end
end

return {
  SubscribeToEvents = SubscribeToEvents
}
