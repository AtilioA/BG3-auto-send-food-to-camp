Config = VCHelpers.Config:New({
  folderName = "AutoSendFoodToCamp",
  configFilePath = "auto_send_food_to_camp_config.json",
  defaultConfig = {
    GENERAL = {
      enabled = true, -- Toggle the mod on/off
    },
    FEATURES = {
      move_food = true,        -- Move food to the camp chest
      move_beverages = true,   -- Move beverages to the camp chest
      move_bought_food = true, -- Move food bought from merchants to the camp chest
      -- move_stolen_food = false,    -- Move stolen food (right after stealing) to the camp chest
      send_existing_food = {
        enabled = true,            -- Move existing food in the party's inventory to the camp chest
        nested_containers = true,  -- Move food in nested containers (e.g. backpacks, supply sacks) to the camp chest
        create_supply_sack = true, -- Move food to a supply sack inside the chest. It will be created if it doesn't exist.
      },
      ignore = {
        healing = true,      -- Ignore healing items (e.g. Goodberry)
        weapons = false,     -- Ignore weapons (only Salami in the vanilla base game)
        user_defined = true, -- Ignore items defined by the user (in the user_ignored_food_list.json file)
        wares = true,
      }
    },
    DEBUG = {
      level = 0 -- 0 = no debug, 1 = minimal, 2 = verbose debug logs
    }
  },
})

Config:UpdateCurrentConfig()

Config:AddConfigReloadedCallback(function(configInstance)
  ASFTCPrinter.DebugLevel = configInstance:GetCurrentDebugLevel()
  ASFTCPrint(0, "Config reloaded: " .. Ext.Json.Stringify(configInstance:getCfg(), { Beautify = true }))
end)
Config:RegisterReloadConfigCommand("asftc")
