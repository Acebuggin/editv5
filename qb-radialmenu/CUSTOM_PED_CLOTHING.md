# Custom Ped Clothing Configuration Guide

## Overview
The qb-radial menu now supports clothing removal for ANY ped model, not just the default `mp_m_freemode_01` and `mp_f_freemode_01` models.

## How It Works
1. The system automatically detects the gender of any ped using the game's native functions
2. For custom peds, it tries to find appropriate "minimal" clothing variations
3. You can configure specific clothing removal values for each custom ped model

## Configuration
Edit the file `config/clothing_peds.lua` to add your custom ped configurations.

### Basic Configuration Example
```lua
Config.CustomPedClothing = {
    -- Example for a custom male ped
    [`s_m_y_cop_01`] = {
        shirt = { drawable = 11, removed = 0 },   -- 0 = bare chest
        pants = { drawable = 4, removed = 61 },   -- 61 = underwear
        shoes = { drawable = 6, removed = 34 }    -- 34 = barefoot
    },
    
    -- Example for a custom female ped
    [`s_f_y_cop_01`] = {
        shirt = { drawable = 11, removed = 74 },  -- 74 = undershirt
        pants = { drawable = 4, removed = 17 },   -- 17 = shorts
        shoes = { drawable = 6, removed = 35 }    -- 35 = barefoot
    },
}
```

### Advanced Configuration with Textures
```lua
[`your_custom_ped`] = {
    shirt = { drawable = 11, removed = 15, texture = 2 },
    pants = { drawable = 4, removed = 14, texture = 1 },
    shoes = { drawable = 6, removed = 34, texture = 0 }
},
```

## Finding the Right Values
To find the correct drawable and texture values for your custom peds:

1. Use a clothing menu or trainer to cycle through the variations
2. Find the variation that represents "removed" clothing (bare chest, underwear, barefoot)
3. Note down the drawable ID and texture ID
4. Add them to the configuration

## Default Behavior
If a custom ped is not configured, the system will automatically try variation 0 for each clothing item, which often works for many ped models.

## Troubleshooting
- If clothing doesn't remove properly, the ped model might not have appropriate "minimal" variations
- Some ped models have fixed clothing that cannot be removed
- Check the game console for any errors related to invalid drawable variations