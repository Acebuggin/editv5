-- Test script to verify handsup exports
RegisterCommand("testhandsup", function()
    print("=== Testing Handsup Exports ===")
    
    -- Test rpemotes internal state
    print("InHandsup: " .. tostring(InHandsup))
    
    -- Test rpemotes exports
    print("rpemotes exports:")
    print("  getHandsup(): " .. tostring(exports['rpemotes']:getHandsup()))
    print("  handsup(): " .. tostring(exports['rpemotes']:handsup()))
    print("  isHandsup(): " .. tostring(exports['rpemotes']:isHandsup()))
    print("  IsPlayerInHandsUp(): " .. tostring(exports['rpemotes']:IsPlayerInHandsUp()))
    
    -- Test LocalPlayer state
    print("\nLocalPlayer.state.handsup: " .. tostring(LocalPlayer.state.handsup))
    
    -- Test if qb-smallresources bridge is working
    if GetResourceState('qb-smallresources') == 'started' then
        print("\nqb-smallresources exports (bridge):")
        local success, result = pcall(function()
            return exports['qb-smallresources']:getHandsup()
        end)
        if success then
            print("  getHandsup(): " .. tostring(result))
        else
            print("  getHandsup(): ERROR - " .. tostring(result))
        end
    end
    
    print("=== End of Test ===")
end, false)