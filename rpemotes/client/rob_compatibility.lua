-- Rob Compatibility for QB-Core
-- This handles the police:client:RobPlayer event if qb-policejob isn't handling it

local QBCore = exports['qb-core']:GetCoreObject()

-- Handle the rob player event
RegisterNetEvent('police:client:RobPlayer', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        local playerPed = GetPlayerPed(player)
        
        -- Check if target has hands up
        local targetHandsUp = Player(playerId).state.handsup
        if targetHandsUp == nil then
            targetHandsUp = IsEntityPlayingAnim(playerPed, "random@mugging3", "handsup_standing_base", 3)
        end
        
        if targetHandsUp then
            -- Start robbing animation
            local ped = PlayerPedId()
            QBCore.Functions.Progressbar("robbing", "Robbing...", 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = "random@shop_robbery",
                anim = "robbery_action_b",
                flags = 16,
            }, {}, {}, function() -- Done
                -- Notify server to handle the rob
                TriggerServerEvent('police:server:RobPlayer', playerId)
                ClearPedTasks(ped)
            end, function() -- Cancel
                QBCore.Functions.Notify("Robbery cancelled", "error")
                ClearPedTasks(ped)
            end)
        else
            QBCore.Functions.Notify("This person doesn't have their hands up!", "error")
        end
    else
        QBCore.Functions.Notify("No one nearby to rob!", "error")
    end
end)

-- Server-side handler for robbing
RegisterNetEvent('police:client:RobFinished', function(success, amount)
    if success then
        QBCore.Functions.Notify("You robbed $" .. amount, "success")
    else
        QBCore.Functions.Notify("This person has no cash!", "error")
    end
end)

-- Debug command to test rob functionality
RegisterCommand("testrob", function()
    print("Triggering rob event for testing...")
    TriggerEvent('police:client:RobPlayer')
end, false)