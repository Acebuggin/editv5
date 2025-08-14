local QBCore = exports['qb-core']:GetCoreObject()

-- Track sold and busy peds globally by network ID
local soldPedsGlobal = {}
local busyPedsGlobal = {}

-- Server-wide statistics
local serverStats = {
    totalSales = 0,
    totalRevenue = 0,
    salesByDrug = {},
    salesByArea = {},
    salesByHour = {},
    failedSales = 0,
    policeAlerts = 0,
    playerStats = {} -- Individual player statistics
}

-- Supply and demand tracking
local serverSupply = {}
local lastSupplyUpdate = 0

-- ========================================
-- ERROR HANDLING & VALIDATION
-- ========================================

-- Validate dependencies
function ValidateServerDependencies()
    if not QBCore then
        print("^1[ERROR] QBCore not found!")
        return false
    end
    
    return true
end

-- Safe function execution
function SafeExecute(func, ...)
    local success, result = pcall(func, ...)
    
    if not success then
        print("^1[ERROR] Server function execution failed: " .. tostring(result))
        return false, result
    end
    
    return true, result
end

-- ========================================
-- STATISTICS FUNCTIONS
-- ========================================

-- Update server statistics
function UpdateServerStats(itemName, amount, price, area, success, gameHour)
    if not Config.Statistics.trackServerStats then
        return
    end
    
    if success then
        serverStats.totalSales = serverStats.totalSales + 1
        serverStats.totalRevenue = serverStats.totalRevenue + price
        
        -- Track by drug type
        serverStats.salesByDrug[itemName] = (serverStats.salesByDrug[itemName] or 0) + 1
        
        -- Track by area
        serverStats.salesByArea[area] = (serverStats.salesByArea[area] or 0) + 1
        
        -- Track by hour (using game time from client)
        if gameHour then
            serverStats.salesByHour[gameHour] = (serverStats.salesByHour[gameHour] or 0) + 1
        end
    else
        serverStats.failedSales = serverStats.failedSales + 1
    end
end

-- Update player statistics
function UpdatePlayerStats(source, stats)
    if not Config.Statistics.trackPlayerStats then
        return
    end
    
    local playerId = tostring(source)
    serverStats.playerStats[playerId] = stats
end

-- Save statistics to file
function SaveStatistics()
    if not Config.Statistics.saveToFile then
        return
    end
    
    local success, result = SafeExecute(function()
        local file = io.open("drug_statistics.json", "w")
        if file then
            file:write(json.encode(serverStats))
            file:close()
            return true
        end
        return false
    end)
    
    if success then
        print("^2[INFO] Statistics saved to file")
    else
        print("^1[ERROR] Failed to save statistics")
    end
end

-- Load statistics from file
function LoadStatistics()
    if not Config.Statistics.saveToFile then
        return
    end
    
    local success, result = SafeExecute(function()
        local file = io.open("drug_statistics.json", "r")
        if file then
            local content = file:read("*all")
            file:close()
            local stats = json.decode(content)
            if stats then
                serverStats = stats
                return true
            end
        end
        return false
    end)
    
    if success then
        print("^2[INFO] Statistics loaded from file")
    else
        print("^3[INFO] No existing statistics file found, starting fresh")
    end
end

-- Reset statistics daily
function CheckDailyReset()
    if not Config.Statistics.dailyReset then
        return
    end
    
    local currentTime = os.date("*t")
    local resetHour, resetMinute = string.match(Config.Statistics.resetTime, "(%d+):(%d+)")
    
    if currentTime.hour == tonumber(resetHour) and currentTime.min == tonumber(resetMinute) then
        serverStats = {
            totalSales = 0,
            totalRevenue = 0,
            salesByDrug = {},
            salesByArea = {},
            salesByHour = {},
            failedSales = 0,
            policeAlerts = 0,
            playerStats = {}
        }
        print("^2[INFO] Daily statistics reset")
    end
end

-- ========================================
-- SUPPLY & DEMAND FUNCTIONS
-- ========================================

-- Update supply levels based on sales
function UpdateSupplyLevels(itemName, amount)
    if not Config.DynamicPricing.supplyDemand.enabled then
        return
    end
    
    local currentTime = GetGameTimer()
    if currentTime - lastSupplyUpdate > Config.DynamicPricing.supplyDemand.updateInterval then
        -- Simulate natural supply changes
        for drugName, _ in pairs(Config.Drugs) do
            local current = serverSupply[drugName] or Config.DynamicPricing.supplyDemand.maxSupply
            local change = math.random(-5, 5)
            serverSupply[drugName] = math.max(
                Config.DynamicPricing.supplyDemand.minSupply,
                math.min(Config.DynamicPricing.supplyDemand.maxSupply, current + change)
            )
        end
        lastSupplyUpdate = currentTime
    end
    
    -- Reduce supply based on sales
    if itemName then
        local current = serverSupply[itemName] or Config.DynamicPricing.supplyDemand.maxSupply
        serverSupply[itemName] = math.max(
            Config.DynamicPricing.supplyDemand.minSupply,
            current - amount
        )
    end
end

-- Get current supply levels
function GetSupplyLevels()
    return serverSupply
end

-- ========================================
-- MAIN THREADS
-- ========================================

-- Initialize server
CreateThread(function()
    Wait(2000)
    
    if not ValidateServerDependencies() then
        print("^1[ERROR] Server initialization failed!")
        return
    end
    
    -- Load existing statistics
    LoadStatistics()
    
    -- Initialize supply levels
    for drugName, _ in pairs(Config.Drugs) do
        serverSupply[drugName] = Config.DynamicPricing.supplyDemand.maxSupply
    end
    
    print("^2[INFO] Drug selling server initialized successfully!")
end)

-- Statistics management thread
CreateThread(function()
    while true do
        Wait(Config.Statistics.updateInterval)
        
        -- Check for daily reset
        CheckDailyReset()
        
        -- Save statistics periodically
        SaveStatistics()
    end
end)

-- Reset sold peds cache every 10 minutes
CreateThread(function()
    while true do
        Wait(10 * 60 * 1000) -- 10 minutes
        soldPedsGlobal = {}
        print("^3[INFO] Sold peds cache reset")
    end
end)

-- ========================================
-- EVENT HANDLERS
-- ========================================

-- Handle drug sales with enhanced tracking
RegisterNetEvent('drug:sellItem', function(itemName, amount, price, area, gameHour)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        local success, result = SafeExecute(function()
            local item = Player.Functions.GetItemByName(itemName)
            if item and item.amount >= amount then
                Player.Functions.RemoveItem(itemName, amount)
                Player.Functions.AddMoney('cash', price)
                
                -- Update supply levels
                UpdateSupplyLevels(itemName, amount)
                
                -- Update statistics with game time
                UpdateServerStats(itemName, amount, price, area, true, gameHour)
                
                -- Notify client - removed "you sold" notification
                -- TriggerClientEvent('QBCore:Notify', src, 'You sold ' .. amount .. 'x ' .. itemName .. ' for $' .. price, 'success')
                
                -- Send supply update to client
                TriggerClientEvent('drug:updateSupply', src, GetSupplyLevels())
                
                return true
            else
                TriggerClientEvent('QBCore:Notify', src, 'You do not have enough items', 'error')
                UpdateServerStats(itemName, amount, 0, area, false, gameHour)
                return false
            end
        end)
        
        if not success then
            print("^1[ERROR] Drug sale processing failed for player " .. src)
            TriggerClientEvent('QBCore:Notify', src, 'Transaction failed due to server error', 'error')
        end
    end
end)

-- Enhanced dispatch system
RegisterNetEvent('drug:sendDispatch', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player and data and data.x and data.y and data.z and data.message then
        -- Update police alert statistics
        serverStats.policeAlerts = serverStats.policeAlerts + 1
        
        local success, result = SafeExecute(function()
            exports["lb-tablet"]:AddDispatch({
                priority = 'high',
                code = '10-99',
                title = 'Local witnessed something suspicious',
                description = data.message,
                location = { label = 'Last Known Location', coords = vector3(data.x, data.y, data.z) },
                time = 300,
                job = 'police',
                sound = 'notification.mp3',
                blip = { sprite = 161, color = 1, size = 1.0, label = 'Suspicious Activity' }
            })
        end)
        
        if not success then
            print("^1[ERROR] Failed to send dispatch for player " .. src)
        end
    end
end)

-- Register ped as sold
RegisterNetEvent('drug:registerSoldPed', function(netId)
    if not soldPedsGlobal[netId] then
        soldPedsGlobal[netId] = true
        busyPedsGlobal[netId] = nil -- Free busy flag just in case
    end
end)

-- Check if ped can be sold to (not sold AND not busy)
QBCore.Functions.CreateCallback('drug:canSellToPed', function(source, cb, netId)
    if soldPedsGlobal[netId] or busyPedsGlobal[netId] then
        cb(false)
    else
        cb(true)
    end
end)

-- Mark ped as busy or free
RegisterNetEvent('drug:setPedBusy', function(netId, busy)
    if not netId then return end

    if busy then
        busyPedsGlobal[netId] = true
    else
        busyPedsGlobal[netId] = nil
    end
end)

-- Update player statistics from client
RegisterNetEvent('drug:updatePlayerStats', function(stats)
    local src = source
    UpdatePlayerStats(src, stats)
end)

-- ========================================
-- ADMIN COMMANDS & EXPORTS
-- ========================================

-- Admin command to view server statistics
RegisterCommand('serverdrugstats', function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, "drugstats") then
        local stats = string.format(
            "Server Stats - Total Sales: %d | Revenue: $%d | Failed: %d | Police Alerts: %d",
            serverStats.totalSales,
            serverStats.totalRevenue,
            serverStats.failedSales,
            serverStats.policeAlerts
        )
        
        if source == 0 then
            print("^2[STATS] " .. stats)
        else
            TriggerClientEvent('QBCore:Notify', source, stats, "primary", 8000)
        end
        
        -- Show top selling drugs
        local topDrugs = {}
        for drug, sales in pairs(serverStats.salesByDrug) do
            table.insert(topDrugs, {drug = drug, sales = sales})
        end
        table.sort(topDrugs, function(a, b) return a.sales > b.sales end)
        
        if #topDrugs > 0 then
            local drugStats = "Top Drugs: "
            for i = 1, math.min(3, #topDrugs) do
                drugStats = drugStats .. topDrugs[i].drug .. "(" .. topDrugs[i].sales .. ") "
            end
            
            if source == 0 then
                print("^3[STATS] " .. drugStats)
            else
                TriggerClientEvent('QBCore:Notify', source, drugStats, "primary", 5000)
            end
        end
    end
end, false)

-- ========================================
-- CALLBACK FUNCTIONS FOR CONTEXT MENU
-- ========================================

-- Check admin permission for context menu
QBCore.Functions.CreateCallback('drug:checkAdminPermission', function(source, cb)
    if not Config.Admin.enabled then
        cb(false)
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    if Config.Admin.useAcePermissions then
        -- Use ace permissions
        cb(IsPlayerAceAllowed(source, Config.Admin.acePermission))
    else
        -- Use citizen ID list
        local hasPermission = false
        for _, allowedId in pairs(Config.Admin.allowedCitizenIds) do
            if citizenId == allowedId then
                hasPermission = true
                break
            end
        end
        cb(hasPermission)
    end
end)

-- Get server statistics for context menu
QBCore.Functions.CreateCallback('drug:getServerStats', function(source, cb)
    if not CheckAdminPermission(source) then
        cb({})
        return
    end
    
    local stats = {
        totalSales = serverStats.totalSales,
        totalRevenue = serverStats.totalRevenue,
        failedSales = serverStats.failedSales,
        policeAlerts = serverStats.policeAlerts,
        activePlayers = 0
    }
    
    -- Count active players
    for playerId, _ in pairs(serverStats.playerStats) do
        stats.activePlayers = stats.activePlayers + 1
    end
    
    cb(stats)
end)

-- Get player statistics for context menu
QBCore.Functions.CreateCallback('drug:getPlayerStats', function(source, cb)
    if not CheckAdminPermission(source) then
        cb({})
        return
    end
    
    -- Add player names to the stats
    local playerStatsWithNames = {}
    for playerId, stats in pairs(serverStats.playerStats) do
        local playerName = "Unknown Player"
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if Player then
            playerName = Player.PlayerData.name or Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        end
        
        playerStatsWithNames[playerId] = {
            name = playerName,
            stats = stats
        }
    end
    
    cb(playerStatsWithNames)
end)

-- Get drug analysis for context menu
QBCore.Functions.CreateCallback('drug:getDrugAnalysis', function(source, cb)
    if not CheckAdminPermission(source) then
        cb({})
        return
    end
    
    cb(serverStats.salesByDrug)
end)

-- Get area analysis for context menu
QBCore.Functions.CreateCallback('drug:getAreaAnalysis', function(source, cb)
    if not CheckAdminPermission(source) then
        cb({})
        return
    end
    
    cb(serverStats.salesByArea)
end)

-- Get time analysis for context menu
QBCore.Functions.CreateCallback('drug:getTimeAnalysis', function(source, cb)
    if not CheckAdminPermission(source) then
        cb({})
        return
    end
    
    cb(serverStats.salesByHour)
end)

-- Get supply levels for context menu
QBCore.Functions.CreateCallback('drug:getSupplyLevels', function(source, cb)
    if not CheckAdminPermission(source) then
        cb({})
        return
    end
    
    cb(serverSupply)
end)

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Check admin permission helper function
function CheckAdminPermission(source)
    if not Config.Admin.enabled then
        return false
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return false
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    if Config.Admin.useAcePermissions then
        -- Use ace permissions
        return IsPlayerAceAllowed(source, Config.Admin.acePermission)
    else
        -- Use citizen ID list
        for _, allowedId in pairs(Config.Admin.allowedCitizenIds) do
            if citizenId == allowedId then
                return true
            end
        end
        return false
    end
end

-- ========================================
-- EVENT HANDLERS FOR CONTEXT MENU
-- ========================================

-- Reset statistics event
RegisterNetEvent('drug:resetStatistics', function()
    local src = source
    if not CheckAdminPermission(src) then
        return
    end
    
    serverStats = {
        totalSales = 0,
        totalRevenue = 0,
        salesByDrug = {},
        salesByArea = {},
        salesByHour = {},
        failedSales = 0,
        policeAlerts = 0,
        playerStats = {}
    }
    
    print("^2[INFO] Drug statistics reset by admin " .. GetPlayerName(src))
end)

-- Export functions for external use
exports('GetDrugStatistics', function()
    return serverStats
end)

exports('GetSupplyLevels', function()
    return GetSupplyLevels()
end)

exports('ResetDrugStatistics', function()
    serverStats = {
        totalSales = 0,
        totalRevenue = 0,
        salesByDrug = {},
        salesByArea = {},
        salesByHour = {},
        failedSales = 0,
        policeAlerts = 0,
        playerStats = {}
    }
    print("^2[INFO] Drug statistics reset by admin")
end)
