Ext.Require("Server/Utils.lua")
Ext.Require("Server/Helpers/Inventory.lua")
Ext.Require("Server/Config.lua")
Ext.Require("Server/FoodDelivery.lua")
Ext.Require("Server/EventHandlers.lua")

MOD_UUID = "1c132ec4-4cd2-4c40-aeb9-ff6ee0467da8"
local MODVERSION = Ext.Mod.GetMod(MOD_UUID).Info.ModVersion

if MODVERSION == nil then
    ASFTCPrint(0, "loaded (version unknown)")
else
    -- Remove the last element (build/revision number) from the MODVERSION table
    table.remove(MODVERSION)

    local versionNumber = table.concat(MODVERSION, ".")
    ASFTCPrint(0, "version " .. versionNumber .. " loaded")
end

local EventSubscription = Ext.Require("Server/SubscribedEvents.lua")
EventSubscription.SubscribeToEvents()
