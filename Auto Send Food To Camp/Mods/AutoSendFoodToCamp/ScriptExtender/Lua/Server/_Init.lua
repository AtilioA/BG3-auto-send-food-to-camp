Ext.Require("Server/Utils.lua")
Ext.Require("Server/Helpers/Inventory.lua")
Ext.Require("Server/Config.lua")
Ext.Require("Server/EventHandlers.lua")
Ext.Require("Server/FoodDelivery.lua")

MOD_UUID = "1c132ec4-4cd2-4c40-aeb9-ff6ee0467da8"
local MODVERSION = Ext.Mod.GetMod(MOD_UUID).Info.ModVersion

if MODVERSION == nil then
    Utils.DebugPrint(0, "Auto Send Food To Camp loaded (version unknown)")
else
    -- Remove the last element (build/revision number) from the MODVERSION table
    table.remove(MODVERSION)

    local versionNumber = table.concat(MODVERSION, ".")
    Utils.DebugPrint(0, "Auto Send Food To Camp: version " .. versionNumber .. " loaded")
end

local EventSubscription = Ext.Require("Server/SubscribedEvents.lua")
EventSubscription.SubscribeToEvents()
