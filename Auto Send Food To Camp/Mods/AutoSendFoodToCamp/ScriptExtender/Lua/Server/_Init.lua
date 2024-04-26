setmetatable(Mods[Ext.Mod.GetMod(ModuleUUID).Info.Directory], { __index = Mods.VolitionCabinet, Mods.BG3MCM })

---Ext.Require files at the path
---@param path string
---@param files string[]
function RequireFiles(path, files)
    for _, file in pairs(files) do
        Ext.Require(string.format("%s%s.lua", path, file))
    end
end

local deps = {
    VCModuleUUID = "f97b43be-7398-4ea5-8fe2-be7eb3d4b5ca",
    MCMModuleUUID = "755a8a72-407f-4f0d-9a33-274ac0f0b53d"
}
for _, depUUID in pairs(deps) do
    if Ext.Mod.IsModLoaded(depUUID) == false then
        local depName = Ext.Mod.GetMod(depUUID).Info.Name
        ASFTCWarn(0, "Requirement '" .. depName .. "' is missing. Please make sure it is enabled in your mod manager.")
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
