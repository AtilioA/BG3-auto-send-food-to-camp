setmetatable(Mods[Ext.Mod.GetMod(ModuleUUID).Info.Directory], { __index = Mods.VolitionCabinet, Mods.BG3MCM })

local deps = {
    VCModuleUUID = "f97b43be-7398-4ea5-8fe2-be7eb3d4b5ca",
    MCMModuleUUID = "755a8a72-407f-4f0d-9a33-274ac0f0b53d"
}
if not Ext.Mod.IsModLoaded(deps.VCModuleUUID) then
    Ext.Utils.Print(
        "Volition Cabinet is missing and is a hard requirement. PLEASE MAKE SURE IT IS ENABLED IN YOUR MOD MANAGER.")
end

if not Ext.Mod.IsModLoaded(deps.MCMModuleUUID) then
    Ext.Utils.Print(
        "BG3 Mod Configuration Menu is missing and is a hard requirement. PLEASE MAKE SURE IT IS ENABLED IN YOUR MOD MANAGER.")
end

---Ext.Require files at the path
---@param path string
---@param files string[]
function RequireFiles(path, files)
    for _, file in pairs(files) do
        Ext.Require(string.format("%s%s.lua", path, file))
    end
end

RequireFiles("Server/", {
    "Helpers/_Init",
    "FoodDelivery",
    "EventHandlers",
    "SubscribedEvents",
})

local MODVERSION = Ext.Mod.GetMod(ModuleUUID).Info.ModVersion
if MODVERSION == nil then
    ASFTCWarn(0, "Volitio's Auto Send Food To Camp loaded (version unknown)")
else
    -- Remove the last element (build/revision number) from the MODVERSION table
    table.remove(MODVERSION)

    local versionNumber = table.concat(MODVERSION, ".")
    ASFTCPrint(0, "Volitio's Auto Send Food To Camp version " .. versionNumber .. " loaded")
end

SubscribedEvents.SubscribeToEvents()
