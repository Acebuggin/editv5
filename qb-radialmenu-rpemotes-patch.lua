-- QB-Radialmenu patch for RPEmotes compatibility
-- This modifies the people menu to check rpemotes for handsup state

-- Add this to your qb-radialmenu config.lua or replace the existing rob entry

-- Find the 'stealplayer' entry in your config and replace it with this:
{
    id = 'stealplayer',
    title = 'Rob',
    icon = 'mask',
    type = 'client',
    event = 'police:client:RobPlayer',
    shouldClose = true,
    canOpen = function(itemData)
        local player, distance = QBCore.Functions.GetClosestPlayer()
        if player ~= -1 and distance < 2.5 then
            local playerId = GetPlayerServerId(player)
            local playerPed = GetPlayerPed(player)
            
            -- Check if the target player has hands up
            -- First try direct state check
            local targetHandsUp = Player(playerId).state.handsup
            
            -- If state is nil, try to check animation
            if targetHandsUp == nil then
                -- Check if player is doing hands up animation
                targetHandsUp = IsEntityPlayingAnim(playerPed, "random@mugging3", "handsup_standing_base", 3)
            end
            
            return targetHandsUp == true
        end
        return false
    end
}

-- Alternative: If the above doesn't work, you can also add this to qb-radialmenu/client/main.lua
-- This creates a function to check if a player has their hands up

function IsPlayerHandsup(targetPlayer)
    if not targetPlayer then return false end
    
    local playerId = GetPlayerServerId(targetPlayer)
    local playerPed = GetPlayerPed(targetPlayer)
    
    -- Method 1: Check player state
    local handsUpState = Player(playerId).state.handsup
    if handsUpState ~= nil then
        return handsUpState
    end
    
    -- Method 2: Check if playing hands up animation
    if IsEntityPlayingAnim(playerPed, "random@mugging3", "handsup_standing_base", 3) then
        return true
    end
    
    -- Method 3: Try to get from exports (if the target is local player)
    if targetPlayer == PlayerId() then
        if GetResourceState('rpemotes') == 'started' then
            return exports['rpemotes']:getHandsup()
        elseif GetResourceState('qb-smallresources') == 'started' then
            return exports['qb-smallresources']:getHandsup()
        end
    end
    
    return false
end