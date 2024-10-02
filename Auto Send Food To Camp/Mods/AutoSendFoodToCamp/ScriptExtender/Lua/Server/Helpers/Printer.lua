ASFTCPrinter = VolitionCabinetPrinter:New { Prefix = "Auto Send Food To Camp", ApplyColor = true, DebugLevel = MCM.Get("debug_level") }

-- Update the Printer debug level when the setting is changed, since the value is only used during the object's creation
Ext.ModEvents["BG3MCM"]["MCM_Setting_Saved"]:Subscribe(function(payload)
    if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
        return
    end

    if payload.settingId == "debug_level" then
        ASFTCPrint(0, "Setting debug level to " .. payload.value)
        ASFTCPrinter.DebugLevel = MCM.Get("debug_level")
    end
end)

function ASFTCPrint(debugLevel, ...)
    ASFTCPrinter:SetFontColor(0, 255, 255)
    ASFTCPrinter:Print(debugLevel, ...)
end

function ASFTCTest(debugLevel, ...)
    ASFTCPrinter:SetFontColor(100, 200, 150)
    ASFTCPrinter:PrintTest(debugLevel, ...)
end

function ASFTCDebug(debugLevel, ...)
    ASFTCPrinter:SetFontColor(200, 200, 0)
    ASFTCPrinter:PrintDebug(debugLevel, ...)
end

function ASFTCWarn(debugLevel, ...)
    ASFTCPrinter:SetFontColor(255, 100, 50)
    ASFTCPrinter:PrintWarning(debugLevel, ...)
end

function ASFTCDump(debugLevel, ...)
    ASFTCPrinter:SetFontColor(190, 150, 225)
    ASFTCPrinter:Dump(debugLevel, ...)
end

function ASFTCDumpArray(debugLevel, ...)
    ASFTCPrinter:DumpArray(debugLevel, ...)
end
