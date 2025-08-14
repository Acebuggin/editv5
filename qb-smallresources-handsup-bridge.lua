-- QB-Smallresources Handsup Bridge for RPEmotes
-- This file provides complete compatibility between rpemotes and scripts expecting qb-smallresources handsup
-- Place this file in qb-smallresources/client/ folder

-- Create a local variable to cache the handsup state
local cachedHandsupState = false

-- Update cache when rpemotes changes state
CreateThread(function()
    while true do
        if GetResourceState('rpemotes') == 'started' then
            -- Get the current state from rpemotes
            local rpemotesState = exports['rpemotes']:getHandsup()
            if rpemotesState ~= cachedHandsupState then
                cachedHandsupState = rpemotesState
                -- Trigger any events that other scripts might be listening to
                TriggerEvent('qb-smallresources:client:handsup:changed', cachedHandsupState)
            end
        end
        Wait(100) -- Check every 100ms for state changes
    end
end)

-- Primary export that qb-radialmenu uses
exports('getHandsup', function()
    if GetResourceState('rpemotes') == 'started' then
        return exports['rpemotes']:getHandsup()
    end
    return false
end)

-- Alternative export names for maximum compatibility
exports('handsup', function()
    if GetResourceState('rpemotes') == 'started' then
        return exports['rpemotes']:handsup()
    end
    return false
end)

exports('isHandsup', function()
    if GetResourceState('rpemotes') == 'started' then
        return exports['rpemotes']:isHandsup()
    end
    return false
end)

exports('IsPlayerInHandsUp', function()
    if GetResourceState('rpemotes') == 'started' then
        return exports['rpemotes']:IsPlayerInHandsUp()
    end
    return false
end)

-- Add a global variable that some older scripts might check
handsUp = false

-- Keep the global variable synchronized
CreateThread(function()
    while true do
        if GetResourceState('rpemotes') == 'started' then
            handsUp = exports['rpemotes']:getHandsup()
        else
            handsUp = false
        end
        Wait(50)
    end
end)

-- Also sync with LocalPlayer state for scripts that check statebags
CreateThread(function()
    while true do
        Wait(0)
        if LocalPlayer and LocalPlayer.state then
            local handsupState = LocalPlayer.state.handsup
            if handsupState ~= nil then
                cachedHandsupState = handsupState
                handsUp = handsupState
            end
        end
    end
end)

print("^2[QB-Smallresources]^7 Handsup bridge loaded - redirecting to rpemotes")