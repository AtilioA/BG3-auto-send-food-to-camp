Config = {}

FolderName = "AutoSendFoodToCamp"
Config.configFilePath = "auto_send_food_to_camp_config.json"

Config.defaultConfig = {
    GENERAL = {
        enabled = true, -- Toggle the mod on/off
    },
    FEATURES = {
        move_food = true,  -- Move food to the camp chest
        move_beverages = true, -- Move beverages to the camp chest
        move_bought_food = true, -- Move food bought from merchants to the camp chest
        -- stolen_items = true, -- TODO: Move stolen items (loose but owned/pickpocketed) to the camp chest. Not feasible/worth it
    },
    DEBUG = {
        level = 0 -- 0 = no debug, 1 = minimal, 2 = verbose logs
    }
}


function Config.GetModPath(filePath)
    return FolderName .. '/' .. filePath
end

-- Load a JSON configuration file and return a table or nil
function Config.LoadConfig(filePath)
    local configFileContent = Ext.IO.LoadFile(Config.GetModPath(filePath))
    if configFileContent and configFileContent ~= "" then
        Utils.DebugPrint(1, "Loaded config file: " .. filePath)
        return Ext.Json.Parse(configFileContent)
    else
        Utils.DebugPrint(1, "File not found: " .. filePath)
        return nil
    end
end

-- Save a config table to a JSON file
function Config.SaveConfig(filePath, config)
    local configFileContent = Ext.Json.Stringify(config, { Beautify = true })
    Ext.IO.SaveFile(Config.GetModPath(filePath), configFileContent)
end

function Config.UpdateConfig(existingConfig, defaultConfig)
    local updated = false
    for key, value in pairs(defaultConfig) do
        if existingConfig[key] == nil then
            existingConfig[key] = value
            updated = true
            Utils.DebugPrint(1, "Added new config option:", key)
        elseif type(value) == "table" then
            -- Recursively update for nested tables
            if Config.UpdateConfig(existingConfig[key], value) then
                updated = true
            end
        end
    end
    return updated
end

function Config.LoadJSONConfig()
    local jsonConfig = Config.LoadConfig(Config.configFilePath)
    if not jsonConfig then
        jsonConfig = Config.defaultConfig
        Config.SaveConfig(Config.configFilePath, jsonConfig)
        Utils.DebugPrint(1, "Default config file loaded.")
    else
        if Config.UpdateConfig(jsonConfig, Config.defaultConfig) then
            Config.SaveConfig(Config.configFilePath, jsonConfig)
            Utils.DebugPrint(1, "Config file updated with new options.")
        else
            Utils.DebugPrint(1, "Config file loaded.")
        end
    end

    return jsonConfig
end

JsonConfig = Config.LoadJSONConfig()

return Config
