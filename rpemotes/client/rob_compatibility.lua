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
            
            -- Request animation dictionary
            RequestAnimDict("random@shop_robbery")
            while not HasAnimDictLoaded("random@shop_robbery") do
                Wait(10)
            end
            
            -- Use ox_lib progress circle
            if lib.progressCircle({
                duration = 5000,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                },
                anim = {
                    dict = 'random@shop_robbery',
                    clip = 'robbery_action_b'
                },
                label = 'Robbing...',
            }) then
                -- Success - notify server to handle the rob
                TriggerServerEvent('police:server:RobPlayer', playerId)
                ClearPedTasks(ped)
            else
                -- Cancelled
                lib.notify({
                    title = 'Robbery',
                    description = 'Robbery cancelled',
                    type = 'error'
                })
                ClearPedTasks(ped)
            end
        else
            lib.notify({
                title = 'Cannot Rob',
                description = "This person doesn't have their hands up!",
                type = 'error'
            })
        end
    else
        lib.notify({
            title = 'Cannot Rob',
            description = 'No one nearby to rob!',
            type = 'error'
        })
    end
end)

-- Server-side handler for robbing
RegisterNetEvent('police:client:RobFinished', function(success, amount)
    if success then
        lib.notify({
            title = 'Robbery Successful',
            description = 'You robbed $' .. amount,
            type = 'success'
        })
    else
        lib.notify({
            title = 'Robbery Failed', 
            description = 'This person has no cash!',
            type = 'error'
        })
    end
end)

-- Debug command to test rob functionality
RegisterCommand("testrob", function()
    print("Triggering rob event for testing...")
    TriggerEvent('police:client:RobPlayer')
end, false)