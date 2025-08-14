local QBCore = exports['qb-core']:GetCoreObject()

-- Store active oxy runs
local activeRuns = {}

RegisterNetEvent('qb-oxyruns:server:Reward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- Markedbills reward (1000-10000)
        local markedBills = math.random(Config.MarkedBillsMin, Config.MarkedBillsMax)
        Player.Functions.AddItem('markedbills', markedBills, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['markedbills'], "add", markedBills)

        -- Oxy
        local oxy = math.random(100)
        if oxy <= Config.OxyChance then
            Player.Functions.AddItem(Config.OxyItem, 1, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.OxyItem], "add", 1)
        end
    end
end)

QBCore.Functions.CreateCallback('qb-oxyruns:server:StartOxy', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    -- Check if player already has an active run
    if activeRuns[src] then
        -- Player already has active run, just give them a new vehicle
        local vehicleModel = Config.VehicleModels[math.random(#Config.VehicleModels)]
        TriggerClientEvent('QBCore:Notify', src, "Getting you a new vehicle for your oxy run", "success", 3500)
        cb(true, vehicleModel)
    else
        -- New run, charge payment
        if Player.PlayerData.money.cash >= Config.StartOxyPayment then
            Player.Functions.RemoveMoney('cash', Config.StartOxyPayment, "oxy start")
            
            -- Select random vehicle model
            local vehicleModel = Config.VehicleModels[math.random(#Config.VehicleModels)]
            
            -- Store active run data
            activeRuns[src] = {
                vehicle = vehicleModel,
                started = os.time()
            }
            
            cb(true, vehicleModel)
        else
            TriggerClientEvent('QBCore:Notify', src, "You don't have enough money to start an oxyrun..", "error",  3500)
            cb(false)
        end
    end
end)

RegisterNetEvent('qb-oxyruns:server:EndRun', function(withRefund)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if activeRuns[src] then
        activeRuns[src] = nil
        
        if withRefund and Config.RefundOnReturn and Player then
            Player.Functions.AddMoney('cash', Config.RefundAmount, "oxy run refund")
            TriggerClientEvent('QBCore:Notify', src, "You have ended your oxy run and received your refund of $" .. Config.RefundAmount, "success", 3500)
        else
            TriggerClientEvent('QBCore:Notify', src, "You have ended your oxy run", "success", 3500)
        end
    end
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if activeRuns[src] then
        activeRuns[src] = nil
    end
end)

-- Export to check if player has active run
exports('HasActiveRun', function(src)
    return activeRuns[src] ~= nil
end)

-- Export to get player's registered vehicle
exports('GetPlayerOxyVehicle', function(src)
    if activeRuns[src] then
        return activeRuns[src].vehicle
    end
    return nil
end)
