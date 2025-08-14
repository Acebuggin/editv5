-- Test script to verify handsup exports
-- Run this in your server to test all the export methods

RegisterCommand("testhandsup", function()
    print("=== Testing Handsup Exports ===")
    
    -- Test rpemotes exports
    if GetResourceState('rpemotes') == 'started' then
        print("rpemotes exports:")
        print("  getHandsup(): " .. tostring(exports['rpemotes']:getHandsup()))
        print("  handsup(): " .. tostring(exports['rpemotes']:handsup()))
        print("  isHandsup(): " .. tostring(exports['rpemotes']:isHandsup()))
        print("  IsPlayerInHandsUp(): " .. tostring(exports['rpemotes']:IsPlayerInHandsUp()))
    else
        print("rpemotes is not running!")
    end
    
    -- Test qb-smallresources exports (through bridge)
    if GetResourceState('qb-smallresources') == 'started' then
        print("\nqb-smallresources exports (bridge):")
        print("  getHandsup(): " .. tostring(exports['qb-smallresources']:getHandsup()))
        print("  handsup(): " .. tostring(exports['qb-smallresources']:handsup()))
        print("  isHandsup(): " .. tostring(exports['qb-smallresources']:isHandsup()))
    else
        print("qb-smallresources is not running!")
    end
    
    -- Test LocalPlayer state
    print("\nLocalPlayer.state.handsup: " .. tostring(LocalPlayer.state.handsup))
    
    -- Test global variable (if exists)
    if handsUp ~= nil then
        print("Global handsUp variable: " .. tostring(handsUp))
    end
    
    print("=== End of Test ===")
end, false)

-- Monitor handsup state changes
CreateThread(function()
    local lastState = nil
    while true do
        local currentState = LocalPlayer.state.handsup
        if currentState ~= lastState then
            print("[Handsup Monitor] State changed from " .. tostring(lastState) .. " to " .. tostring(currentState))
            lastState = currentState
        end
        Wait(100)
    end
end)

print("^2Test script loaded! Use /testhandsup to test all exports^7")