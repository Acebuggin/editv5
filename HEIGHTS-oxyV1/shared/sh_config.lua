Config = {}

Config.Debug = true -- Enable/disable debug prints

Config.StartLocation = vector4(806.36993408203, -2379.6071777344, 29.097652435303, 86.287933349609) -- Start location for oxy run
Config.StartPedRenderDistance = 50.0 -- How far away the start location ped is visible (lower = better performance)
Config.VehicleSpawnLocation = vector4(801.57, -2375.75, 28.84, 174.36) -- Where the vehicle spawns (should be nearby start location)
Config.StartOxyPayment = 500 -- How much you pay at the start to start the run
Config.RefundOnReturn = true -- If true, players get their initial payment back when returning the vehicle
Config.RefundAmount = 500 -- Amount to refund (can be different from StartOxyPayment if desired)

-- Return Marker Configuration
Config.ReturnMarker = {
    type = 36, -- Marker type (1 = cylinder)
    size = {x = 0.3, y = 0.3, z = 0.3}, -- Marker size
    color = {r = 24, g = 64, b = 244, a = 120}, -- Red color with transparency
    bobUpAndDown = false,
    faceCamera = true,
    rotate = false,
    drawOnEnts = false
}

-- Vehicle Configuration
Config.VehicleModels = { -- Random vehicle models for oxy runs
    'sultan',
    'kuruma',
    'buffalo',
    'exemplar',
    'felon',
    'schafter2',
    'zion',
    'oracle2'
}

-- Reward Configuration
Config.MarkedBillsMin = 255 -- Minimum markedbills per delivery
Config.MarkedBillsMax = 1345 -- Maximum markedbills per delivery

Config.OxyChance = 45 -- %Chance to receive oxy
Config.OxyItem = 'oxy'

Config.Locations = { -- Drop-off locations
    vector4(66.78, -1921.69, 21.39, 319.77),--grove street
    vector4(-1398.94, -340.92, 40.24, 129.68),
    vector4(-1453.09, -952.49, 7.47, 229.32),
    vector4(-1113.82, -1660.59, 4.35, 130.05),
    vector4(157.84, -1038.21, 29.22, 342.42),
    vector4(166.62, -955.68, 29.68, 163.99),
    vector4(295.75, -271.12, 53.98, 338.92),
    vector4(412.61, 53.72, 97.98, 169.29),
    vector4(569.79, 120.94, 98.04, 258.76),
    vector4(189.55, 307.87, 105.39, 187.74),
    vector4(-727.31, -907.59, 19.01, 181.01),
    vector4(1245.37, -1626.86, 53.28, 29.56),
    vector4(1064.94, -2410.12, 30.0, 84.48),
    vector4(-674.55, -724.43, 26.88, 270.62),
    vector4(-762.04, -204.22, 37.27, 123.56),
    vector4(308.04, -1386.09, 31.79, 47.23),
    vector4(-1041.13, -392.04, 37.81, 25.98),
    vector4(-731.69, -291.67, 36.95, 330.53),
    vector4(-835.17, -353.65, 38.68, 265.05),
    vector4(-1062.43, -436.19, 36.63, 121.55),
    vector4(-1147.18, -520.47, 32.73, 215.39),
    vector4(-1174.68, -863.63, 14.11, 34.24),
    vector4(-1688.04, -1040.9, 13.02, 232.85),
    vector4(-1353.48, -621.09, 28.24, 300.64),
    vector4(-1029.98, -814.03, 16.86, 335.74),
    vector4(-893.09, -723.17, 19.78, 91.08),
    vector4(-789.23, -565.2, 30.28, 178.86),
    vector4(-345.48, -1022.54, 30.53, 341.03),
    vector4(218.9, -916.12, 30.69, 6.56),
    vector4(-148.8, -1641.47, 33.13, 225.27),
    vector4(67.1, -1468.28, 29.29, 231.66),
    vector4(57.66, -1072.3, 29.45, 245.38)
}