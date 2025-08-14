Config = {}

-- Drugs you can sell with min/max quantity per transaction and price range per unit
Config.Drugs = {
    xanax = {min = 1, max = 3, priceMin = 150, priceMax = 250},
    cocaine = {min = 1, max = 2, priceMin = 350, priceMax = 500},
    meth = {min = 1, max = 1, priceMin = 450, priceMax = 600},
    weed = {min = 1, max = 5, priceMin = 50, priceMax = 100},
}

-- Peds you do NOT wanna sell to (cops, mission NPCs, etc)
Config.BlacklistedPeds = {
     [`s_m_y_cop_01`] = true,
     [`s_f_y_cop_01`] = true,
     [`s_m_y_hwaycop_01`] = true,
     [`s_m_y_sheriff_01`] = true,
     [`s_m_y_xmech_02`] = true,
     [`mp_f_freemode_01`] = true,
     [`mp_m_freemode_01`] = true,
     [`mp_m_weapexp_01`] = true,
     [`a_m_m_og_boss_01`] = true,
     [`a_m_m_farmer_01`] = true,
     [`a_m_m_rurmeth_01`] = true,
     [`s_m_m_autoshop_02`] = true,
     [`s_m_m_scientist_01`] = true,
     [`cs_chengsr`] = true,
     [`s_m_m_dockwork_01`] = true,
     [`cs_barry`] = true,
     [`a_m_m_hasjew_01`] = true,
     [`g_m_y_mexgoon_02`] = true,
     [`ig_siemonyetarian`] = true,
     [`s_m_y_dealer_01`] = true,
     [`s_m_y_ammucity_01`] = true,
     [`s_m_m_ammucountry`] = true,

     ---animals
     [`a_c_boar`] = true,
     [`a_c_cat_01`] = true,
     [`a_c_chickenhawk`] = true,
     [`a_c_chimp`] = true,
     [`a_c_chop`] = true,
     [`a_c_cormorant`] = true,
     [`a_c_cow`] = true,
     [`a_c_coyote`] = true,
     [`a_c_crow`] = true,
     [`a_c_deer`] = true,
     [`a_c_dolphin`] = true,
     [`a_c_fish`] = true,
     [`a_c_hen`] = true,
     [`a_c_humpback`] = true,
     [`a_c_husky`] = true,
     [`a_c_killerwhale`] = true,
     [`a_c_mtlion`] = true,
     [`a_c_panther`] = true,
     [`a_c_pig`] = true,
     [`a_c_pigeon`] = true,
     [`a_c_poodle`] = true,
     [`a_c_pug`] = true,
     [`a_c_rabbit_01`] = true,
     [`a_c_rat`] = true,
     [`a_c_retriever`] = true,
     [`a_c_rhesus`] = true,
     [`a_c_rottweiler`] = true,
     [`a_c_seagull`] = true,
     [`a_c_sharkhammer`] = true,
     [`a_c_sharktiger`] = true,
     [`a_c_shepherd`] = true,
     [`a_c_stingray`] = true,
     [`a_c_westy`] = true,
     
}

-- Restricted Zones Configuration
-- Define areas where drug sales are prohibited
-- Each zone has: name, coordinates (x, y, z), radius in meters, and optional notification message
Config.RestrictedZones = {
    -- Police Stations
    {
        name = "casino",
        coords = vector3(953.6, 27.75, 75.66),
        radius = 100.0,
        message = "You're too close to the police station to sell drugs safely."
    },
    -- Add more zones as needed
    -- Example format:
    -- {
    --     name = "Zone Name",
    --     coords = vector3(x, y, z),
    --     radius = 30.0,
    --     message = "Custom restriction message"
    -- }
}

-- Zone System Settings
Config.ZoneSettings = {
    -- Enable/disable the zone system entirely
    enabled = true,
    
    -- Show visual indicators for restricted zones (blips on map)
    showZoneBlips = false,
    
    -- Blip settings for restricted zones (only if showZoneBlips is true)
    zoneBlipSettings = {
        sprite = 1,      -- Blip sprite ID
        color = 1,       -- Red color
        scale = 0.8,     -- Blip size
        display = 2,     -- Display mode (2 = show on map and minimap)
        shortRange = true
    },
    
    -- Notification settings
    showZoneNotifications = false,
    
    -- Enable/disable zone messages (set to false to disable all zone messages)
    showZoneMessages = false,
    
    -- Cooldown for zone notifications (in milliseconds) to prevent spam
    notificationCooldown = 5000
}

-- Performance Optimization Settings
Config.Performance = {
    -- Maximum distance to scan for peds (meters)
    maxScanDistance = 100.0,
    
    -- Dynamic sleep adjustment based on nearby ped count
    enableDynamicSleep = true,
    
    -- Base sleep time (milliseconds)
    baseSleepTime = 1500,
    
    -- Sleep reduction per nearby ped (milliseconds)
    sleepReductionPerPed = 50,
    
    -- Minimum sleep time (milliseconds)
    minSleepTime = 500,
    
    -- Enable model caching for better performance
    enableModelCaching = true,
    
    -- Cleanup interval for sold peds (milliseconds)
    cleanupInterval = 300000 -- 5 minutes
}

-- Dynamic Pricing System
Config.DynamicPricing = {
    -- Enable/disable dynamic pricing
    enabled = true,
    
    -- Time-based pricing multipliers
    timeMultipliers = {
        [22] = 1.3, -- 10 PM - 6 AM: 30% higher prices
        [23] = 1.3,
        [0] = 1.3,
        [1] = 1.3,
        [2] = 1.3,
        [3] = 1.3,
        [4] = 1.3,
        [5] = 1.3,
        [6] = 1.3,
        [7] = 0.8, -- 7 AM - 9 AM: 20% lower prices
        [8] = 0.8,
        [9] = 0.8,
        [10] = 1.0, -- 10 AM - 9 PM: Normal prices
        [11] = 1.0,
        [12] = 1.0,
        [13] = 1.0,
        [14] = 1.0,
        [15] = 1.0,
        [16] = 1.0,
        [17] = 1.0,
        [18] = 1.0,
        [19] = 1.0,
        [20] = 1.0,
        [21] = 1.0
    },
    
    -- Area-based pricing multipliers
    areaMultipliers = {
        ["vinewood"] = {multiplier = 1.5, name = "Vinewood"},
        ["rockford_hills"] = {multiplier = 1.6, name = "Rockford Hills"},
        ["downtown"] = {multiplier = 1.2, name = "Downtown"},
        ["davis"] = {multiplier = 1.1, name = "Davis"},
        ["south_los_santos"] = {multiplier = 1.0, name = "South Los Santos"},
        ["east_los_santos"] = {multiplier = 1.0, name = "East Los Santos"},
        ["mirror_park"] = {multiplier = 1.0, name = "Mirror Park"},
        ["vespucci"] = {multiplier = 1.1, name = "Vespucci"},
        ["del_perro"] = {multiplier = 1.1, name = "Del Perro"},
        ["port_los_santos"] = {multiplier = 1.1, name = "Port of Los Santos"},
        ["airport"] = {multiplier = 0.9, name = "Los Santos International Airport"},
        ["elysian_docks"] = {multiplier = 1.1, name = "Elysian Island Docks"},
        ["chumash"] = {multiplier = 0.9, name = "Chumash"},
        ["zancudo"] = {multiplier = 0.8, name = "Fort Zancudo"},
        ["sandy_shores"] = {multiplier = 0.8, name = "Sandy Shores"},
        ["grapeseed"] = {multiplier = 0.8, name = "Grapeseed"},
        ["paleto_bay"] = {multiplier = 0.9, name = "Paleto Bay"},
        ["city"] = {multiplier = 1.0, name = "Los Santos"},
        ["countryside"] = {multiplier = 0.7, name = "Countryside"},
        ["unknown"] = {multiplier = 1.0, name = "Unknown Area"}
    },
    
    -- Supply and demand settings
    supplyDemand = {
        enabled = true,
        updateInterval = 300000, -- 5 minutes
        maxSupply = 100,
        minSupply = 0,
        priceMultiplierRange = {0.6, 1.5} -- Min 60%, Max 150% of base price
    }
}

-- Statistics Tracking Settings
Config.Statistics = {
    -- Enable/disable statistics tracking
    enabled = true,
    
    -- Track individual player statistics
    trackPlayerStats = true,
    
    -- Track server-wide statistics
    trackServerStats = true,
    
    -- Save statistics to file
    saveToFile = true,
    
    -- Statistics update interval (milliseconds)
    updateInterval = 60000, -- 1 minute
    
    -- Reset statistics daily
    dailyReset = true,
    
    -- Reset time (24-hour format)
    resetTime = "00:00",
    
    -- Enable/disable area breakdown feature
    showAreaBreakdown = false
}

-- Admin Settings
Config.Admin = {
    -- Enable/disable admin features
    enabled = true,
    
    -- List of citizen IDs that can access admin menu
    -- Add your citizen IDs here (you can find your citizen ID in-game with /id or similar commands)
    allowedCitizenIds = {
        "XGM40430",
        "UUK23530", -- Replace with actual citizen IDs
        -- Add more citizen IDs as needed
    },
    
    
    -- Alternative: Use ace permissions instead of citizen IDs
    -- Set to true to use ace permissions, false to use citizen IDs
    useAcePermissions = false,
    
    -- Ace permission name (only used if useAcePermissions is true)
    acePermission = "drugstats"
}

-- Distances in meters
Config.SellDistance = 2.5
Config.DrawTextDistance = 2.5
Config.ScanDistance = 2.5

-- Chances (between 0 and 1)
Config.RejectionChance = 0.3
Config.AggressionChance = 0.7

-- New: limits and cooldown to avoid spam selling
Config.MaxSalesBeforeCooldown = 7
Config.SellCooldown = 120000 -- 2 minutes cooldown in ms
