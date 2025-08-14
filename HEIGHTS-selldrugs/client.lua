local QBCore = exports['qb-core']:GetCoreObject()

-- Core variables
local sellingPed = nil
local soldPeds = {}
local sellingInProgress = false
local hasDrugs = false
local drugsDebug = false

-- Sales tracking vars
local salesCount = 0
local onCooldown = false
local rejectionChance = Config.RejectionChance

-- Zone system variables
local zoneBlips = {}
local lastZoneNotification = 0

-- Performance optimization variables
local blacklistedModels = {}
local lastCleanup = 0
local nearbyPedCount = 0

-- Statistics variables
local playerStats = {
    totalSales = 0,
    totalRevenue = 0,
    successRate = 0,
    failedSales = 0,
    bestSellingArea = "",
    favoriteDrug = "",
    lastSaleTime = 0,
    salesByDrug = {},
    salesByArea = {}
}

-- Dynamic pricing variables
local currentSupply = {}
local lastSupplyUpdate = 0

-- ========================================
-- ERROR HANDLING & VALIDATION FUNCTIONS
-- ========================================

-- Validate dependencies on script start
function ValidateDependencies()
    local missing = {}
    
    if not exports.ox_inventory then
        table.insert(missing, "ox_inventory")
    end
    
    if not QBCore then
        table.insert(missing, "qb-core")
    end
    
    if #missing > 0 then
        print("^1[ERROR] Missing dependencies: " .. table.concat(missing, ", "))
        return false
    end
    
    return true
end

-- Validate configuration
function ValidateConfig()
    if not Config.Drugs then
        print("^1[ERROR] Config.Drugs is missing!")
        return false
    end
    
    for drugName, drugConfig in pairs(Config.Drugs) do
        if not drugConfig.min or not drugConfig.max then
            print("^1[ERROR] Invalid config for drug: " .. drugName)
            return false
        end
    end
    
    return true
end

-- Safe function wrapper with error handling
function SafeExecute(func, ...)
    local success, result = pcall(func, ...)
    
    if not success then
        print("^1[ERROR] Function execution failed: " .. tostring(result))
        return false, result
    end
    
    return true, result
end

-- ========================================
-- PERFORMANCE OPTIMIZATION FUNCTIONS
-- ========================================

-- Initialize model caching for better performance
function InitializeModelCaching()
    if not Config.Performance.enableModelCaching then
        return
    end
    
    for model, _ in pairs(Config.BlacklistedPeds) do
        blacklistedModels[GetHashKey(model)] = true
    end
    
    print("^2[INFO] Model caching initialized for " .. #blacklistedModels .. " blacklisted models")
end

-- Get dynamic sleep time based on nearby ped count
function GetDynamicSleepTime()
    if not Config.Performance.enableDynamicSleep then
        return Config.Performance.baseSleepTime
    end
    
    local sleepTime = Config.Performance.baseSleepTime - (nearbyPedCount * Config.Performance.sleepReductionPerPed)
    return math.max(Config.Performance.minSleepTime, sleepTime)
end

-- Cleanup sold peds periodically
function CleanupSoldPeds()
    local currentTime = GetGameTimer()
    if currentTime - lastCleanup < Config.Performance.cleanupInterval then
        return
    end
    
    lastCleanup = currentTime
    soldPeds = {}
    print("^3[INFO] Sold peds cache cleaned up")
end

-- ========================================
-- DYNAMIC PRICING FUNCTIONS
-- ========================================

-- Get time-based price multiplier
function GetTimeMultiplier()
    if not Config.DynamicPricing.enabled then
        return 1.0
    end
    
    local hour = GetClockHours()
    return Config.DynamicPricing.timeMultipliers[hour] or 1.0
end

-- Get area-based price multiplier
function GetAreaMultiplier(playerCoords)
    if not Config.DynamicPricing.enabled then
        return 1.0
    end
    
    local area = GetPlayerArea(playerCoords)
    local areaConfig = Config.DynamicPricing.areaMultipliers[area]
    
    if areaConfig then
        return areaConfig.multiplier
    end
    
    return 1.0
end

-- Get supply and demand multiplier
function GetSupplyDemandMultiplier(itemName)
    if not Config.DynamicPricing.enabled or not Config.DynamicPricing.supplyDemand.enabled then
        return 1.0
    end
    
    local currentTime = GetGameTimer()
    if currentTime - lastSupplyUpdate > Config.DynamicPricing.supplyDemand.updateInterval then
        UpdateSupplyLevels()
        lastSupplyUpdate = currentTime
    end
    
    local supply = currentSupply[itemName] or Config.DynamicPricing.supplyDemand.maxSupply
    local maxSupply = Config.DynamicPricing.supplyDemand.maxSupply
    local minSupply = Config.DynamicPricing.supplyDemand.minSupply
    
    -- Calculate multiplier based on supply level
    local supplyRatio = supply / maxSupply
    local minMultiplier = Config.DynamicPricing.supplyDemand.priceMultiplierRange[1]
    local maxMultiplier = Config.DynamicPricing.supplyDemand.priceMultiplierRange[2]
    
    -- Low supply = high prices, high supply = low prices
    local multiplier = maxMultiplier - (supplyRatio * (maxMultiplier - minMultiplier))
    
    return multiplier
end

-- Calculate final price with all multipliers
function CalculateFinalPrice(basePrice, itemName, playerCoords)
    local timeMultiplier = GetTimeMultiplier()
    local areaMultiplier = GetAreaMultiplier(playerCoords)
    local supplyMultiplier = GetSupplyDemandMultiplier(itemName)
    
    local finalPrice = basePrice * timeMultiplier * areaMultiplier * supplyMultiplier
    
    -- Round to nearest dollar
    return math.floor(finalPrice + 0.5)
end

-- Update supply levels (simulated)
function UpdateSupplyLevels()
    for drugName, _ in pairs(Config.Drugs) do
        -- Simulate supply changes (random walk)
        local current = currentSupply[drugName] or Config.DynamicPricing.supplyDemand.maxSupply
        local change = math.random(-10, 10)
        currentSupply[drugName] = math.max(
            Config.DynamicPricing.supplyDemand.minSupply,
            math.min(Config.DynamicPricing.supplyDemand.maxSupply, current + change)
        )
    end
end

-- Get player's current area
function GetPlayerArea(playerCoords)
    local x, y = playerCoords.x, playerCoords.y

    -- Paleto Bay (far north)
    if x > -300 and x < -50 and y > 6200 and y < 6500 then
        return "paleto_bay"
    -- Grapeseed (northeast)
    elseif x > 2100 and x < 2200 and y > 4850 and y < 4950 then
        return "grapeseed"
    -- Sandy Shores (desert, northeast)
    elseif x > 1600 and x < 1700 and y > 3750 and y < 3850 then
        return "sandy_shores"
    -- Fort Zancudo (military base, northwest)
    elseif x > -2150 and x < -2080 and y > 3120 and y < 3150 then
        return "zancudo"
    -- Chumash (west coast)
    elseif x > -3100 and x < -3070 and y > 550 and y < 580 then
        return "chumash"
    -- Vinewood (north city)
    elseif x > 300 and x < 360 and y > -130 and y < -90 then
        return "vinewood"
    -- Mirror Park (east city area)
    elseif x > 1100 and x < 1150 and y > -500 and y < -470 then
        return "mirror_park"
    -- Rockford Hills (wealthy residential area)
    elseif x > -620 and x < -600 and y > -230 and y < -200 then
        return "rockford_hills"
    -- Downtown (central city)
    elseif x > -30 and x < 5 and y > -840 and y < -800 then
        return "downtown"
    -- Davis (south city area)
    elseif x > 180 and x < 210 and y > -1720 and y < -1700 then
        return "davis"
    -- South Los Santos
    elseif x > -80 and x < -60 and y > -1475 and y < -1455 then
        return "south_los_santos"
    -- Vespucci (beach area)
    elseif x > -1190 and x < -1170 and y > -1370 and y < -1350 then
        return "vespucci"
    -- Del Perro (beach area)
    elseif x > -1460 and x < -1440 and y > -755 and y < -735 then
        return "del_perro"
    -- East Los Santos (east city area)
    elseif x > 920 and x < 960 and y > -2070 and y < -2040 then
        return "east_los_santos"
    -- Port of Los Santos
    elseif x > 20 and x < 50 and y > -2550 and y < -2520 then
        return "port_los_santos"
    -- Los Santos International Airport
    elseif x > -1280 and x < -1250 and y > -2640 and y < -2620 then
        return "airport"
    -- Elysian Island Docks
    elseif x > 980 and x < 1000 and y > -3110 and y < -3090 then
        return "elysian_docks"
    -- City (catch-all for Los Santos)
    elseif x > -2000 and x < 3000 and y > -4000 and y < 4000 then
        return "city"
    -- Countryside (catch-all for rest)
    else
        return "countryside"
    end
end

-- ========================================
-- ZONE SYSTEM FUNCTIONS
-- ========================================

-- Zone checking function
function IsPlayerInRestrictedZone()
    if not Config.ZoneSettings or not Config.ZoneSettings.enabled then
        return false, nil
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for _, zone in pairs(Config.RestrictedZones) do
        local distance = #(playerCoords - zone.coords)
        if distance <= zone.radius then
            return true, zone
        end
    end
    
    return false, nil
end

-- Zone notification function with cooldown
function ShowZoneNotification(zone)
    if not Config.ZoneSettings.showZoneNotifications or not Config.ZoneSettings.showZoneMessages then
        return
    end
    
    local currentTime = GetGameTimer()
    if currentTime - lastZoneNotification < Config.ZoneSettings.notificationCooldown then
        return
    end
    
    lastZoneNotification = currentTime
    QBCore.Functions.Notify(zone.message, "error", 5000)
end

-- Create zone blips (optional visual indicators)
function CreateZoneBlips()
    if not Config.ZoneSettings.showZoneBlips then
        return
    end
    
    -- Remove existing blips first
    RemoveZoneBlips()
    
    for _, zone in pairs(Config.RestrictedZones) do
        local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipRotation(blip, 0)
        SetBlipColour(blip, Config.ZoneSettings.zoneBlipSettings.color)
        SetBlipAlpha(blip, 100)
        
        -- Add center blip
        local centerBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(centerBlip, Config.ZoneSettings.zoneBlipSettings.sprite)
        SetBlipColour(centerBlip, Config.ZoneSettings.zoneBlipSettings.color)
        SetBlipScale(centerBlip, Config.ZoneSettings.zoneBlipSettings.scale)
        SetBlipDisplay(centerBlip, Config.ZoneSettings.zoneBlipSettings.display)
        SetBlipAsShortRange(centerBlip, Config.ZoneSettings.zoneBlipSettings.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Restricted Zone: " .. zone.name)
        EndTextCommandSetBlipName(centerBlip)
        
        table.insert(zoneBlips, blip)
        table.insert(zoneBlips, centerBlip)
    end
end

-- Remove zone blips
function RemoveZoneBlips()
    for _, blip in pairs(zoneBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    zoneBlips = {}
end

-- ========================================
-- STATISTICS FUNCTIONS
-- ========================================

-- Update player statistics
function UpdatePlayerStats(success, itemName, price, area)
    if not Config.Statistics.trackPlayerStats then
        return
    end
    
    if success then
        playerStats.totalSales = playerStats.totalSales + 1
        playerStats.totalRevenue = playerStats.totalRevenue + price
        playerStats.lastSaleTime = GetGameTimer()
        
        -- Track by drug
        playerStats.salesByDrug[itemName] = (playerStats.salesByDrug[itemName] or 0) + 1
        
        -- Track by area
        playerStats.salesByArea[area] = (playerStats.salesByArea[area] or 0) + 1
        
        -- Update favorite drug
        local maxSales = 0
        for drug, sales in pairs(playerStats.salesByDrug) do
            if sales > maxSales then
                maxSales = sales
                playerStats.favoriteDrug = drug
            end
        end
        
        -- Update best selling area
        local maxAreaSales = 0
        for areaName, sales in pairs(playerStats.salesByArea) do
            if sales > maxAreaSales then
                maxAreaSales = sales
                playerStats.bestSellingArea = areaName
            end
        end
    else
        playerStats.failedSales = playerStats.failedSales + 1
    end
    
    -- Calculate success rate
    local totalAttempts = playerStats.totalSales + playerStats.failedSales
    if totalAttempts > 0 then
        playerStats.successRate = (playerStats.totalSales / totalAttempts) * 100
    end
    
    -- Send stats to server
    TriggerServerEvent('drug:updatePlayerStats', playerStats)
end

-- ========================================
-- CORE FUNCTIONS
-- ========================================

-- 3D Text Drawing function
function DrawText3D(x, y, z, text)
    SetTextScale(0.31, 0.31)
    SetTextFont(7)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Refresh drug possession status from inventory
function RefreshHasDrugs()
    local success, items = SafeExecute(function()
        return exports.ox_inventory:Items()
    end)
    
    if not success or not items then
        hasDrugs = false
        return
    end

    for name, _ in pairs(Config.Drugs) do
        local item = items[name]
        if item and item.count > 0 then
            hasDrugs = true
            return
        end
    end

    hasDrugs = false
end

-- Get drugs info from inventory with error handling (random selection)
function GetDrugsFromInventory()
    local success, inventory = SafeExecute(function()
        return exports.ox_inventory:Items()
    end)
    
    if not success or not inventory then
        return false, nil, 0
    end

    -- Collect all available drugs
    local availableDrugs = {}
    for name, _ in pairs(Config.Drugs) do
        local item = inventory[name]
        if item and item.count > 0 then
            table.insert(availableDrugs, {
                name = name,
                count = item.count
            })
        end
    end

    -- Return false if no drugs available
    if #availableDrugs == 0 then
        return false, nil, 0
    end

    -- Randomly select a drug
    local randomIndex = math.random(1, #availableDrugs)
    local selectedDrug = availableDrugs[randomIndex]
    
    return true, selectedDrug.name, selectedDrug.count
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

-- Event-based inventory updates
AddEventHandler('ox_inventory:itemCount', function(itemName, totalCount)
    if Config.Drugs[itemName] then
        if totalCount > 0 then
            hasDrugs = true
        else
            -- Check if any other drugs left
            local stillHaveDrugs = false
            local success, items = SafeExecute(function()
                return exports.ox_inventory:Items()
            end)
            
            if success and items then
                for name, _ in pairs(Config.Drugs) do
                    local item = items[name]
                    if item and item.count > 0 then
                        stillHaveDrugs = true
                        break
                    end
                end
            end
            hasDrugs = stillHaveDrugs
        end
    end
end)

-- Handle supply updates from server
RegisterNetEvent('drug:updateSupply', function(supplyLevels)
    currentSupply = supplyLevels
end)

-- ========================================
-- MAIN THREADS
-- ========================================

-- Initialize script
CreateThread(function()
    Wait(1000)
    
    -- Validate dependencies and config
    if not ValidateDependencies() or not ValidateConfig() then
        print("^1[ERROR] Script initialization failed!")
        return
    end
    
    -- Initialize performance optimizations
    InitializeModelCaching()
    
    -- Initialize zone system
    if Config.ZoneSettings and Config.ZoneSettings.enabled then
        CreateZoneBlips()
    end
    
    -- Initialize supply levels
    UpdateSupplyLevels()
    
    -- Initial inventory check
    RefreshHasDrugs()
    
    print("^2[INFO] Drug selling script initialized successfully!")
end)

-- Player loaded event
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    RefreshHasDrugs()
end)

-- Ped scanner loop with performance optimizations
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local sleep = GetDynamicSleepTime()
        sellingPed = nil
        nearbyPedCount = 0

        -- Check if player is in restricted zone
        local inRestrictedZone, currentZone = IsPlayerInRestrictedZone()
        
        -- Cleanup sold peds periodically
        CleanupSoldPeds()
        
        if hasDrugs then
            local nearbyPeds = GetGamePool('CPed')

            for _, ped in pairs(nearbyPeds) do
                if ped ~= playerPed and not IsPedDeadOrDying(ped) and not IsPedAPlayer(ped) then
                    local pedCoords = GetEntityCoords(ped)
                    local dist = #(coords - pedCoords)
                    
                    -- Distance culling for performance
                    if dist > Config.Performance.maxScanDistance then
                        goto continue
                    end
                    
                    -- Fast model check using cached hashes
                    local model = GetEntityModel(ped)
                    if Config.Performance.enableModelCaching and blacklistedModels[model] then
                        goto continue
                    elseif not Config.Performance.enableModelCaching and Config.BlacklistedPeds[model] then
                        goto continue
                    end

                    if dist < Config.ScanDistance and not soldPeds[ped] and not IsPedInAnyVehicle(ped, false) then
                        nearbyPedCount = nearbyPedCount + 1
                        sleep = 0

                        if dist < Config.DrawTextDistance then
                            -- Only show text and allow selling if NOT in restricted zone
                            if not inRestrictedZone then
                                DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 0.3, 'Sell Drugs')
                                if dist < Config.SellDistance then
                                    sellingPed = ped
                                end
                            else
                                -- Show zone notification when in restricted area
                                ShowZoneNotification(currentZone)
                            end
                        end
                    end
                end
                ::continue::
            end
        end

        Wait(sleep)
    end
end)

-- ========================================
-- DRUG SELLING FUNCTIONS
-- ========================================

-- Safe drug selling function with error handling
function SafeTryToSellToPed(ped)
    local success, result = SafeExecute(function()
        return TryToSellToPed(ped)
    end)
    
    if not success then
        print("^1[ERROR] Drug selling failed: " .. tostring(result))
        -- Reset selling state
        sellingInProgress = false
        sellingPed = nil
        return false
    end
    
    return result
end

-- Try to sell drugs to a ped
function TryToSellToPed(ped)
    if soldPeds[ped] or sellingInProgress then return end

    if onCooldown then
        QBCore.Functions.Notify("You need to wait before selling more.", "error")
        return
    end

    -- Check if player is in restricted zone
    local inRestrictedZone, currentZone = IsPlayerInRestrictedZone()
    if inRestrictedZone then
        ShowZoneNotification(currentZone)
        return
    end

    local hasDrugsNow, itemName, itemCount = GetDrugsFromInventory()
    if not hasDrugsNow then
        QBCore.Functions.Notify("You don't have anything to sell.", "error")
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(ped)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local currentArea = GetPlayerArea(playerCoords)

    QBCore.Functions.TriggerCallback('drug:canSellToPed', function(canSell)
        if not canSell then
            QBCore.Functions.Notify("This person already bought from someone else or is busy.", "error")
            sellingInProgress = false
            UpdatePlayerStats(false, itemName, 0, currentArea)
            return
        end

        TriggerServerEvent('drug:setPedBusy', netId, true)
        sellingInProgress = true

        ClearPedTasks(ped)
        FreezeEntityPosition(ped, true)
        TaskTurnPedToFaceEntity(ped, PlayerPedId(), -1)
        TaskLookAtEntity(ped, PlayerPedId(), 5000, 2048, 3)
        Wait(800)

        local reject = math.random() < rejectionChance

        if reject then
            FreezeEntityPosition(ped, false)
            TriggerServerEvent('drug:setPedBusy', netId, false)
            TriggerPolice(ped)

            if math.random() < Config.AggressionChance then
                QBCore.Functions.Notify("They didn't like that... get ready!", "error")
                ArmAndAttackPed(ped)
            else
                QBCore.Functions.Notify("They rejected your offer and walked away.", "error")
                TaskSmartFleePed(ped, PlayerPedId(), 100.0, -1, false, false)
            end

            soldPeds[ped] = true
            sellingPed = nil
            sellingInProgress = false

            salesCount = salesCount + 1
            CheckCooldown()
            UpdatePlayerStats(false, itemName, 0, currentArea)
            return
        end

        local drugCfg = Config.Drugs[itemName]
        local amount = math.random(drugCfg.min, math.min(drugCfg.max, itemCount))
        local basePrice = math.random(drugCfg.priceMin, drugCfg.priceMax)
        local finalPrice = CalculateFinalPrice(basePrice, itemName, playerCoords)
        local total = amount * finalPrice

        RequestAnimDict("mp_common")
        while not HasAnimDictLoaded("mp_common") do Wait(10) end

        TaskPlayAnim(PlayerPedId(), "mp_common", "givetake1_a", 8.0, -8.0, 3000, 0, 0, false, false, false)
        TaskPlayAnim(ped, "mp_common", "givetake1_a", 8.0, -8.0, 3000, 0, 0, false, false, false)
        Wait(3000)

        ClearPedTasks(PlayerPedId())
        ClearPedTasks(ped)
        FreezeEntityPosition(ped, false)

        -- Get current game time
        local gameHour = GetClockHours()
        TriggerServerEvent('drug:sellItem', itemName, amount, total, currentArea, gameHour)
        TriggerServerEvent('drug:registerSoldPed', netId)
        TriggerServerEvent('drug:setPedBusy', netId, false)

        local walkAway = GetEntityCoords(ped) + vector3(math.random(-3,3), math.random(-3,3), 0)
        TaskGoStraightToCoord(ped, walkAway, 1.0, 5000, 0.0, 0.0)
        TaskWanderStandard(ped, 10.0, 10)

        soldPeds[ped] = true
        sellingPed = nil
        sellingInProgress = false

        salesCount = salesCount + 1
        CheckCooldown()
        UpdatePlayerStats(true, itemName, total, currentArea)
        
        -- Show dynamic pricing info
        if Config.DynamicPricing.enabled then
            local timeMultiplier = GetTimeMultiplier()
            local areaMultiplier = GetAreaMultiplier(playerCoords)
            local supplyMultiplier = GetSupplyDemandMultiplier(itemName)
            
            -- Price adjustment notification removed
            -- if timeMultiplier ~= 1.0 or areaMultiplier ~= 1.0 or supplyMultiplier ~= 1.0 then
            --     local priceInfo = string.format("Price adjusted: Time x%.1f, Area x%.1f, Supply x%.1f", 
            --         timeMultiplier, areaMultiplier, supplyMultiplier)
            --     QBCore.Functions.Notify(priceInfo, "primary", 3000)
            -- end
        end
    end, netId)
end

-- Cooldown checker
function CheckCooldown()
    if salesCount >= (Config.MaxSalesBeforeCooldown or 5) then
        onCooldown = true
        rejectionChance = Config.IncreasedRejectionChance or Config.RejectionChance
        QBCore.Functions.Notify("You need to cool down before selling again.", "error")

        CreateThread(function()
            Wait(Config.SellCooldownTime or 2 * 60 * 1000)
            salesCount = 0
            onCooldown = false
            rejectionChance = Config.RejectionChance
            soldPeds = {}
        end)
    end
end

-- Call cops alert
function TriggerPolice(ped)
    local coords = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = streetHash and GetStreetNameFromHashKey(streetHash) or "an unknown street"
    local gender = IsPedMale(PlayerPedId()) and "Male" or "Female"
    local msg = ("%s acting suspicious near %s"):format(gender, street)

    TriggerServerEvent('drug:sendDispatch', {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        message = msg
    })
end

-- Make ped attack player
function ArmAndAttackPed(ped)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 50)

    local weapon = math.random() < 0.5 and `WEAPON_KNIFE` or `WEAPON_PISTOL`
    GiveWeaponToPed(ped, weapon, 999, false, true)
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
end

-- ========================================
-- COMMANDS & KEYBINDS
-- ========================================

-- Manual sell command
RegisterCommand('trySell', function()
    if sellingPed and not sellingInProgress then
        SafeTryToSellToPed(sellingPed)
    end
end, false)

RegisterKeyMapping('trySell', 'Sell Drugs to Ped', 'keyboard', 'E')

-- Debug toggle
RegisterCommand('drugsdebug', function()
    drugsDebug = not drugsDebug
    if drugsDebug then
        print("^2[DEBUG] Drug selling debug mode enabled")
        print("^3[DEBUG] Player stats:", json.encode(playerStats))
        print("^3[DEBUG] Current supply:", json.encode(currentSupply))
    else
        print("^1[DEBUG] Drug selling debug mode disabled")
    end
end, false)

-- Statistics command (for all players - shows their own stats)
RegisterCommand('drugstats', function()
    if not Config.Statistics.trackPlayerStats then
        QBCore.Functions.Notify("Statistics tracking is disabled", "error")
        return
    end
    
    OpenPlayerStatsMenu()
end, false)

-- Player statistics menu (for all players)
function OpenPlayerStatsMenu()
    local options = {
        {
            title = '💰 Total Revenue',
            description = '$' .. (playerStats.totalRevenue or 0),
            disabled = true
        },
        {
            title = '📈 Total Sales',
            description = (playerStats.totalSales or 0) .. ' successful sales',
            disabled = true
        },
        {
            title = '❌ Failed Sales',
            description = (playerStats.failedSales or 0) .. ' failed attempts',
            disabled = true
        },
        {
            title = '📊 Success Rate',
            description = string.format('%.1f%%', playerStats.successRate or 0),
            disabled = true
        },
        {
            title = '💊 Favorite Drug',
            description = playerStats.favoriteDrug or 'None',
            disabled = true
        },
        {
            title = '🗺️ Best Area',
            description = playerStats.bestSellingArea or 'None',
            disabled = true
        }
    }
    
    -- Add drug breakdown if available
    if playerStats.salesByDrug and next(playerStats.salesByDrug) then
        table.insert(options, {
            title = '📋 Drug Breakdown',
            description = 'View your sales by drug type',
            onSelect = function()
                OpenPlayerDrugBreakdownMenu()
            end
        })
    end
    
    -- Add area breakdown if available and enabled in config
    if Config.Statistics.showAreaBreakdown and playerStats.salesByArea and next(playerStats.salesByArea) then
        table.insert(options, {
            title = '🗺️ Area Breakdown',
            description = 'View your sales by area',
            onSelect = function()
                OpenPlayerAreaBreakdownMenu()
            end
        })
    end
    
    lib.registerContext({
        id = 'player_stats_menu',
        title = 'Your Drug Sales Statistics',
        options = options
    })
    
    lib.showContext('player_stats_menu')
end

-- Player drug breakdown menu (for all players)
function OpenPlayerDrugBreakdownMenu()
    local options = {}
    
    if playerStats.salesByDrug and next(playerStats.salesByDrug) then
        -- Sort drugs by sales count
        local sortedDrugs = {}
        for drug, sales in pairs(playerStats.salesByDrug) do
            table.insert(sortedDrugs, {drug = drug, sales = sales})
        end
        table.sort(sortedDrugs, function(a, b) return a.sales > b.sales end)
        
        for _, drugData in ipairs(sortedDrugs) do
            table.insert(options, {
                title = drugData.drug:upper(),
                description = drugData.sales .. ' sales',
                disabled = true
            })
        end
    else
        table.insert(options, {
            title = 'No Drug Data',
            description = 'No drug sales data available',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'player_drug_breakdown',
        title = 'Your Drug Breakdown',
        menu = 'player_stats_menu',
        options = options
    })
    
    lib.showContext('player_drug_breakdown')
end

-- Player area breakdown menu (for all players)
function OpenPlayerAreaBreakdownMenu()
    local options = {}
    
    if playerStats.salesByArea and next(playerStats.salesByArea) then
        -- Sort areas by sales count
        local sortedAreas = {}
        for area, sales in pairs(playerStats.salesByArea) do
            table.insert(sortedAreas, {area = area, sales = sales})
        end
        table.sort(sortedAreas, function(a, b) return a.sales > b.sales end)
        
        for _, areaData in ipairs(sortedAreas) do
            local areaName = Config.DynamicPricing.areaMultipliers[areaData.area]?.name or areaData.area
            table.insert(options, {
                title = areaName,
                description = areaData.sales .. ' sales',
                disabled = true
            })
        end
    else
        table.insert(options, {
            title = 'No Area Data',
            description = 'No area sales data available',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'player_area_breakdown',
        title = 'Your Area Breakdown',
        menu = 'player_stats_menu',
        options = options
    })
    
    lib.showContext('player_area_breakdown')
end

-- Admin context menu command
RegisterCommand('drugadmin', function()
    if not Config.Admin.enabled then
        QBCore.Functions.Notify("Admin features are disabled", "error")
        return
    end
    
    QBCore.Functions.TriggerCallback('drug:checkAdminPermission', function(hasPermission)
        if hasPermission then
            OpenAdminContextMenu()
        else
            QBCore.Functions.Notify("You don't have permission to access drug admin menu", "error")
        end
    end)
end, false)

-- ========================================
-- ADMIN CONTEXT MENU FUNCTIONS
-- ========================================

-- Open admin context menu
function OpenAdminContextMenu()
    lib.registerContext({
        id = 'drug_admin_main',
        title = 'Drug Sales Admin Panel',
        options = {
            {
                title = '📊 Server Statistics',
                description = 'View overall server sales and revenue',
                onSelect = function()
                    OpenServerStatsMenu()
                end
            },
            {
                title = '👥 Player Statistics',
                description = 'View individual player performance',
                onSelect = function()
                    OpenAdminPlayerStatsMenu()
                end
            },
            {
                title = '💊 Drug Analysis',
                description = 'View sales breakdown by drug type',
                onSelect = function()
                    OpenDrugAnalysisMenu()
                end
            },
            {
                title = '🗺️ Area Analysis',
                description = 'View sales breakdown by area',
                onSelect = function()
                    OpenAreaAnalysisMenu()
                end
            },
            {
                title = '⏰ Time Analysis',
                description = 'View sales by hour of day',
                onSelect = function()
                    OpenTimeAnalysisMenu()
                end
            },
            {
                title = '⚙️ Supply & Demand',
                description = 'View current supply levels and pricing',
                onSelect = function()
                    OpenSupplyMenu()
                end
            },
            {
                title = '🔄 Reset Statistics',
                description = 'Reset all server statistics',
                onSelect = function()
                    OpenResetConfirmMenu()
                end
            }
        }
    })
    
    lib.showContext('drug_admin_main')
end

-- Server statistics menu
function OpenServerStatsMenu()
    QBCore.Functions.TriggerCallback('drug:getServerStats', function(stats)
        local options = {
            {
                title = '💰 Total Revenue',
                description = '$' .. (stats.totalRevenue or 0),
                disabled = true
            },
            {
                title = '📈 Total Sales',
                description = (stats.totalSales or 0) .. ' transactions',
                disabled = true
            },
            {
                title = '❌ Failed Sales',
                description = (stats.failedSales or 0) .. ' failed attempts',
                disabled = true
            },
            {
                title = '🚨 Police Alerts',
                description = (stats.policeAlerts or 0) .. ' alerts sent',
                disabled = true
            },
            {
                title = '📊 Success Rate',
                description = string.format('%.1f%%', CalculateSuccessRate(stats)),
                disabled = true
            },
            {
                title = '👥 Active Players',
                description = (stats.activePlayers or 0) .. ' players tracked',
                disabled = true
            }
        }
        
        lib.registerContext({
            id = 'drug_server_stats',
            title = 'Server Statistics',
            menu = 'drug_admin_main',
            options = options
        })
        
        lib.showContext('drug_server_stats')
    end)
end

-- Admin player statistics menu
function OpenAdminPlayerStatsMenu()
    QBCore.Functions.TriggerCallback('drug:getPlayerStats', function(playerStatsWithNames)
        local options = {}
        
        if playerStatsWithNames and next(playerStatsWithNames) then
            for playerId, data in pairs(playerStatsWithNames) do
                local playerName = data.name
                local stats = data.stats
                
                table.insert(options, {
                    title = playerName,
                    description = string.format('Sales: %d | Revenue: $%d | Success: %.1f%%', 
                        stats.totalSales or 0, 
                        stats.totalRevenue or 0, 
                        stats.successRate or 0),
                    onSelect = function()
                        OpenPlayerDetailMenu(playerId, stats, playerName)
                    end
                })
            end
        else
            table.insert(options, {
                title = 'No Player Data',
                description = 'No player statistics available',
                disabled = true
            })
        end
        
        lib.registerContext({
            id = 'drug_player_stats',
            title = 'Player Statistics',
            menu = 'drug_admin_main',
            options = options
        })
        
        lib.showContext('drug_player_stats')
    end)
end

-- Player detail menu
function OpenPlayerDetailMenu(playerId, stats, playerName)
    local options = {
        {
            title = '💰 Total Revenue',
            description = '$' .. (stats.totalRevenue or 0),
            disabled = true
        },
        {
            title = '📈 Total Sales',
            description = (stats.totalSales or 0) .. ' successful sales',
            disabled = true
        },
        {
            title = '❌ Failed Sales',
            description = (stats.failedSales or 0) .. ' failed attempts',
            disabled = true
        },
        {
            title = '📊 Success Rate',
            description = string.format('%.1f%%', stats.successRate or 0),
            disabled = true
        },
        {
            title = '💊 Favorite Drug',
            description = stats.favoriteDrug or 'None',
            disabled = true
        },
        {
            title = '🗺️ Best Area',
            description = stats.bestSellingArea or 'None',
            disabled = true
        }
    }
    
    -- Add drug breakdown
    if stats.salesByDrug and next(stats.salesByDrug) then
        table.insert(options, {
            title = '📋 Drug Breakdown',
            description = 'View sales by drug type',
            onSelect = function()
                OpenPlayerDrugBreakdown(playerId, stats.salesByDrug, playerName)
            end
        })
    end
    
    -- Add area breakdown if enabled in config
    if Config.Statistics.showAreaBreakdown and stats.salesByArea and next(stats.salesByArea) then
        table.insert(options, {
            title = '🗺️ Area Breakdown',
            description = 'View sales by area',
            onSelect = function()
                OpenPlayerAreaBreakdown(playerId, stats.salesByArea, playerName)
            end
        })
    end
    
    lib.registerContext({
        id = 'drug_player_detail',
        title = playerName .. ' - Details',
        menu = 'drug_player_stats',
        options = options
    })
    
    lib.showContext('drug_player_detail')
end

-- Drug analysis menu
function OpenDrugAnalysisMenu()
    QBCore.Functions.TriggerCallback('drug:getDrugAnalysis', function(drugStats)
        local options = {}
        
        if drugStats and next(drugStats) then
            -- Sort drugs by sales count
            local sortedDrugs = {}
            for drug, sales in pairs(drugStats) do
                table.insert(sortedDrugs, {drug = drug, sales = sales})
            end
            table.sort(sortedDrugs, function(a, b) return a.sales > b.sales end)
            
            for _, drugData in ipairs(sortedDrugs) do
                table.insert(options, {
                    title = drugData.drug:upper(),
                    description = drugData.sales .. ' sales',
                    disabled = true
                })
            end
        else
            table.insert(options, {
                title = 'No Drug Data',
                description = 'No drug sales data available',
                disabled = true
            })
        end
        
        lib.registerContext({
            id = 'drug_analysis',
            title = 'Drug Analysis',
            menu = 'drug_admin_main',
            options = options
        })
        
        lib.showContext('drug_analysis')
    end)
end

-- Area analysis menu
function OpenAreaAnalysisMenu()
    QBCore.Functions.TriggerCallback('drug:getAreaAnalysis', function(areaStats)
        local options = {}
        
        if areaStats and next(areaStats) then
            -- Sort areas by sales count
            local sortedAreas = {}
            for area, sales in pairs(areaStats) do
                table.insert(sortedAreas, {area = area, sales = sales})
            end
            table.sort(sortedAreas, function(a, b) return a.sales > b.sales end)
            
            for _, areaData in ipairs(sortedAreas) do
                local areaName = Config.DynamicPricing.areaMultipliers[areaData.area]?.name or areaData.area
                table.insert(options, {
                    title = areaName,
                    description = areaData.sales .. ' sales',
                    disabled = true
                })
            end
        else
            table.insert(options, {
                title = 'No Area Data',
                description = 'No area sales data available',
                disabled = true
            })
        end
        
        lib.registerContext({
            id = 'drug_area_analysis',
            title = 'Area Analysis',
            menu = 'drug_admin_main',
            options = options
        })
        
        lib.showContext('drug_area_analysis')
    end)
end

-- Time analysis menu
function OpenTimeAnalysisMenu()
    QBCore.Functions.TriggerCallback('drug:getTimeAnalysis', function(timeStats)
        local options = {}
        
        if timeStats and next(timeStats) then
            -- Sort by hour
            local sortedHours = {}
            for hour, sales in pairs(timeStats) do
                table.insert(sortedHours, {hour = tonumber(hour), sales = sales})
            end
            table.sort(sortedHours, function(a, b) return a.hour < b.hour end)
            
            for _, timeData in ipairs(sortedHours) do
                local timeLabel = string.format('%02d:00', timeData.hour)
                table.insert(options, {
                    title = timeLabel,
                    description = timeData.sales .. ' sales',
                    disabled = true
                })
            end
        else
            table.insert(options, {
                title = 'No Time Data',
                description = 'No time-based sales data available',
                disabled = true
            })
        end
        
        lib.registerContext({
            id = 'drug_time_analysis',
            title = 'Time Analysis',
            menu = 'drug_admin_main',
            options = options
        })
        
        lib.showContext('drug_time_analysis')
    end)
end

-- Supply and demand menu
function OpenSupplyMenu()
    QBCore.Functions.TriggerCallback('drug:getSupplyLevels', function(supplyLevels)
        local options = {}
        
        if supplyLevels and next(supplyLevels) then
            for drug, supply in pairs(supplyLevels) do
                local maxSupply = Config.DynamicPricing.supplyDemand.maxSupply
                local percentage = math.floor((supply / maxSupply) * 100)
                local status = percentage > 80 and "🟢 High" or percentage > 40 and "🟡 Medium" or "🔴 Low"
                
                table.insert(options, {
                    title = drug:upper(),
                    description = string.format('%d/%d (%d%%) - %s', supply, maxSupply, percentage, status),
                    disabled = true
                })
            end
        else
            table.insert(options, {
                title = 'No Supply Data',
                description = 'No supply data available',
                disabled = true
            })
        end
        
        lib.registerContext({
            id = 'drug_supply',
            title = 'Supply & Demand',
            menu = 'drug_admin_main',
            options = options
        })
        
        lib.showContext('drug_supply')
    end)
end

-- Reset confirmation menu
function OpenResetConfirmMenu()
    lib.registerContext({
        id = 'drug_reset_confirm',
        title = 'Reset Statistics',
        menu = 'drug_admin_main',
        options = {
            {
                title = '⚠️ Confirm Reset',
                description = 'This will permanently delete all statistics',
                onSelect = function()
                    TriggerServerEvent('drug:resetStatistics')
                    QBCore.Functions.Notify('Statistics have been reset', 'success')
                    lib.hideContext()
                end
            },
            {
                title = '❌ Cancel',
                description = 'Go back without resetting',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })
    
    lib.showContext('drug_reset_confirm')
end

-- Player drug breakdown menu
function OpenPlayerDrugBreakdown(playerId, drugStats, playerName)
    local options = {}
    
    if drugStats and next(drugStats) then
        -- Sort drugs by sales count
        local sortedDrugs = {}
        for drug, sales in pairs(drugStats) do
            table.insert(sortedDrugs, {drug = drug, sales = sales})
        end
        table.sort(sortedDrugs, function(a, b) return a.sales > b.sales end)
        
        for _, drugData in ipairs(sortedDrugs) do
            table.insert(options, {
                title = drugData.drug:upper(),
                description = drugData.sales .. ' sales',
                disabled = true
            })
        end
    else
        table.insert(options, {
            title = 'No Drug Data',
            description = 'No drug sales data available',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'drug_player_drug_breakdown',
        title = playerName .. ' - Drug Breakdown',
        menu = 'drug_player_detail',
        options = options
    })
    
    lib.showContext('drug_player_drug_breakdown')
end

-- Player area breakdown menu
function OpenPlayerAreaBreakdown(playerId, areaStats, playerName)
    local options = {}
    
    if areaStats and next(areaStats) then
        -- Sort areas by sales count
        local sortedAreas = {}
        for area, sales in pairs(areaStats) do
            table.insert(sortedAreas, {area = area, sales = sales})
        end
        table.sort(sortedAreas, function(a, b) return a.sales > b.sales end)
        
        for _, areaData in ipairs(sortedAreas) do
            local areaName = Config.DynamicPricing.areaMultipliers[areaData.area]?.name or areaData.area
            table.insert(options, {
                title = areaName,
                description = areaData.sales .. ' sales',
                disabled = true
            })
        end
    else
        table.insert(options, {
            title = 'No Area Data',
            description = 'No area sales data available',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'drug_player_area_breakdown',
        title = playerName .. ' - Area Breakdown',
        menu = 'drug_player_detail',
        options = options
    })
    
    lib.showContext('drug_player_area_breakdown')
end

-- Helper function to calculate success rate
function CalculateSuccessRate(stats)
    local totalAttempts = (stats.totalSales or 0) + (stats.failedSales or 0)
    if totalAttempts > 0 then
        return ((stats.totalSales or 0) / totalAttempts) * 100
    end
    return 0
end
