-- Bridge file to redirect qb-smallresources handsup export to rpemotes
-- Put this file in your qb-smallresources/client/ folder

-- Export the getHandsup function that qb-radialmenu expects
exports('getHandsup', function()
    -- Check if rpemotes is running and use its handsup state
    if GetResourceState('rpemotes') == 'started' then
        return exports['rpemotes']:getHandsup()
    end
    return false
end)

-- Also add the standard qb-smallresources exports for compatibility
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