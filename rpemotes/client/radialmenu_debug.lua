-- Debug helper for radial menu rob option
-- This will help diagnose why the rob option isn't showing

RegisterCommand("debugrob", function()
    print("=== Radial Menu Rob Debug ===")
    
    -- Check closest player
    local QBCore = exports['qb-core']:GetCoreObject()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    
    if player ~= -1 then
        print("Closest player found:")
        print("  Player: " .. player)
        print("  Distance: " .. distance)
        print("  Server ID: " .. GetPlayerServerId(player))
        
        local playerPed = GetPlayerPed(player)
        local playerId = GetPlayerServerId(player)
        
        -- Check state
        local handsUpState = Player(playerId).state.handsup
        print("\nHandsup state check:")
        print("  Player.state.handsup: " .. tostring(handsUpState))
        
        -- Check animation
        local isPlayingAnim = IsEntityPlayingAnim(playerPed, "random@mugging3", "handsup_standing_base", 3)
        print("  Animation check: " .. tostring(isPlayingAnim))
        
        -- Test the canOpen function logic
        print("\nCanOpen function result:")
        local targetHandsUp = handsUpState
        if targetHandsUp == nil then
            targetHandsUp = isPlayingAnim
        end
        local canOpen = (distance < 2.5 and targetHandsUp == true)
        print("  Would show rob option: " .. tostring(canOpen))
        
        -- Additional checks
        print("\nAdditional info:")
        print("  Player ped exists: " .. tostring(DoesEntityExist(playerPed)))
        print("  Is ped human: " .. tostring(IsPedHuman(playerPed)))
        
        -- Check what animation they're actually playing
        for i = 0, 3 do
            if IsEntityPlayingAnim(playerPed, "random@mugging3", "handsup_standing_base", i) then
                print("  Animation playing with flag " .. i .. ": true")
            end
        end
    else
        print("No player nearby!")
    end
    
    print("=== End Debug ===")
end, false)

-- Also create a command to force refresh the radial menu
RegisterCommand("refreshradial", function()
    -- Force close and reopen to refresh
    ExecuteCommand('radialmenu')
    Wait(100)
    ExecuteCommand('radialmenu')
    print("Radial menu refreshed")
end, false)

print("^2Radial menu debug loaded! Commands: /debugrob and /refreshradial^7")