-- Server-side Rob Handler for QB-Core
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('police:server:RobPlayer', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not Player or not TargetPlayer then return end
    
    -- Check distance server-side for security
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)
    local dist = #(GetEntityCoords(ped) - GetEntityCoords(targetPed))
    
    if dist > 3.0 then
        return -- Too far away
    end
    
    -- Get cash from target
    local cash = TargetPlayer.PlayerData.money.cash
    
    if cash > 0 then
        -- Take random amount between 20-80% of their cash
        local percentage = math.random(20, 80) / 100
        local robAmount = math.floor(cash * percentage)
        
        -- Remove money from target
        TargetPlayer.Functions.RemoveMoney('cash', robAmount)
        
        -- Add money to robber
        Player.Functions.AddMoney('cash', robAmount)
        
        -- Notify both players
        TriggerClientEvent('police:client:RobFinished', src, true, robAmount)
        TriggerClientEvent('QBCore:Notify', targetId, 'You have been robbed of $' .. robAmount, 'error')
        
        -- Log the robbery
        TriggerEvent('qb-log:server:CreateLog', 'robbery', 'Player Robbed', 'red', 
            '**' .. GetPlayerName(src) .. '** (citizenid: *' .. Player.PlayerData.citizenid .. 
            '* | id: *' .. src .. '*) robbed **' .. GetPlayerName(targetId) .. '** (citizenid: *' .. 
            TargetPlayer.PlayerData.citizenid .. '* | id: *' .. targetId .. '*) for $' .. robAmount)
    else
        -- No cash to rob
        TriggerClientEvent('police:client:RobFinished', src, false, 0)
    end
end)