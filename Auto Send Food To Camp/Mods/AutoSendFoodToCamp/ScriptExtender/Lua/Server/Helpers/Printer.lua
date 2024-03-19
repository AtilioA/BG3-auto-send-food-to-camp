ASFTCPrinter = VolitionCabinetPrinter:New { Prefix = "Auto Send Food To Camp", ApplyColor = true, DebugLevel = Config:GetCurrentDebugLevel() }

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
