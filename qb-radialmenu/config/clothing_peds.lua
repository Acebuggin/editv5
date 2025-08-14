-- Custom Ped Clothing Configuration
-- This file allows you to configure how clothing removal works for custom peds
-- Each ped model can have its own specific drawable values for "removed" clothing

Config = Config or {}

Config.CustomPedClothing = {
    -- Example configurations for popular custom peds
    -- You can add your own custom ped models here
    
    -- Example: Custom male ped
    [`PedWorks_AceBuggin`] = {
        shirt = { drawable = 11, removed = 0 },  -- removed = the drawable ID for bare chest/undershirt
        pants = { drawable = 4, removed = 0 },  -- removed = the drawable ID for underwear/shorts
        shoes = { drawable = 6, removed = 0 }   -- removed = the drawable ID for barefoot
    },
    
    -- Example: Custom female ped
    [`jj`] = {
        shirt = { drawable = 11, removed = 0, texture = 0 },
        pants = { drawable = 4, removed = 8, texture = 0 },
        shoes = { drawable = 6, removed = 1, texture = 0 }
    },
    
    -- Add your custom peds below:
    [`sky`] = {
        shirt = { drawable = 11, removed = 0 },
        pants = { drawable = 4, removed = 0 },  -- Added missing pants
        shoes = { drawable = 6, removed = 0 }
    },
}

-- Default configuration for unknown custom peds
-- Setting removed = -1 will make the script try to auto-detect the best variation
Config.CustomPedClothingDefault = {
    shirt = { drawable = 11, removed = -1 },  -- -1 means try variation 0
    pants = { drawable = 4, removed = -1 },   -- -1 means try variation 0
    shoes = { drawable = 6, removed = -1 }    -- -1 means try variation 0
}

-- Advanced: You can also specify texture variations
-- Example of adding more peds individually:
-- Config.CustomPedClothing[`another_ped`] = {
--     shirt = { drawable = 0, removed = 0, texture = 0 },
--     pants = { drawable = 8, removed = 0, texture = 0 },
--     shoes = { drawable = 1, removed = 0, texture = 0 }
-- }