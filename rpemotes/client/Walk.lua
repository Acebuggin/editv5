-- Walk System for QBCore with illenium-appearance fix

-- GLOBAL FUNCTION FOR EMOTES COMPATIBILITY - MUST BE FIRST
local canChange = true
local unable_message = "You are unable to change your walking style right now."

function WalkMenuStart(name, force)
    if not canChange and not force then
        EmoteChatMessage(unable_message)
        return
    end

    if not name or name == "" then
        ResetWalk()
        return
    end
    if not EmoteData[name] or type(EmoteData[name]) ~= "table" or EmoteData[name].category ~= Category.WALKS then
        EmoteChatMessage("'" .. tostring(name) .. "' is not a valid walk")
        return
    end

    local walk = EmoteData[name].anim
    assert(walk ~= nil)
    RequestWalking(walk)
    SetPedMovementClipset(PlayerPedId(), walk, 0.2)
    RemoveAnimSet(walk)

    if Config.PersistentWalk then SetResourceKvp("walkstyle", name) end
end

function ResetWalk()
    if not canChange then
        EmoteChatMessage(unable_message)
        return
    end
    ResetPedMovementClipset(PlayerPedId(), 0.0)
end

function WalksOnCommand()
    local WalksCommand = ""
    for name, data in PairsByKeys(EmoteData) do
        if type(data) == "table" and data.category == Category.WALKS then
            WalksCommand = WalksCommand .. string.lower(name) .. ", "
        end
    end
    EmoteChatMessage(WalksCommand)
    EmoteChatMessage("To reset do /walk reset")
end

function WalkCommandStart(name)
    if not canChange then
        EmoteChatMessage(unable_message)
        return
    end
    name = FirstToUpper(string.lower(name))

    if name == "Reset" then
        ResetPedMovementClipset(PlayerPedId(), 0.0)
        DeleteResourceKvp("walkstyle")
        return
    end

    WalkMenuStart(name, true)
end

if Config.WalkingStylesEnabled and Config.PersistentWalk then
    local function walkstyleExists(kvp)
        while not CONVERTED do
            Wait(0)
        end
        if not kvp or kvp == "" then
            return false
        end

        local walkstyle = EmoteData[kvp]
        return walkstyle and type(walkstyle) == "table" and walkstyle.category == Category.WALKS
    end

    local function handleWalkstyle()
        -- Wait a bit to ensure player is fully loaded
        Wait(2000)
        
        local kvp = GetResourceKvpString("walkstyle")
        if not kvp or kvp == "" then 
            if Config.DebugDisplay then
                print("^3[RPEmotes] No saved walk style found for player^7")
            end
            return 
        end
        
        if Config.DebugDisplay then
            print("^3[RPEmotes] Found saved walk style: " .. kvp .. "^7")
        end
        
        -- Wait for emotes to be fully loaded
        local attempts = 0
        while not CONVERTED and attempts < 50 do
            Wait(100)
            attempts = attempts + 1
        end
        
        if walkstyleExists(kvp) then
            if Config.DebugDisplay then
                print("^2[RPEmotes] Applying saved walk style: " .. kvp .. "^7")
            end
            WalkMenuStart(kvp, true)
        else
            if Config.DebugDisplay then
                print("^1[RPEmotes] Saved walk style no longer exists: " .. kvp .. "^7")
            end
            ResetPedMovementClipset(PlayerPedId(), 0.0)
            DeleteResourceKvp("walkstyle")
        end
    end

    -- Handle initial spawn
    AddEventHandler('playerSpawned', function()
        CreateThread(function()
            handleWalkstyle()
        end)
    end)

    -- QBCore specific event
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        CreateThread(function()
            handleWalkstyle()
        end)
    end)
    
    -- ESX specific event
    RegisterNetEvent('esx:playerLoaded', function()
        CreateThread(function()
            handleWalkstyle()
        end)
    end)

    -- Handle resource restart
    AddEventHandler('onResourceStart', function(resource)
        if resource == GetCurrentResourceName() then
            CreateThread(function()
                Wait(1000) -- Give time for everything to initialize
                handleWalkstyle()
            end)
        end
    end)
    
    -- Additional check when player is fully loaded
    CreateThread(function()
        -- Wait for game to be loaded
        while not NetworkIsPlayerActive(PlayerId()) do
            Wait(100)
        end
        
        -- Extra wait to ensure everything is ready
        Wait(5000)
        
        -- Check if walk style hasn't been applied yet
        local currentWalk = GetPedMovementClipset(PlayerPedId())
        local savedWalk = GetResourceKvpString("walkstyle")
        
        if savedWalk and savedWalk ~= "" and currentWalk == `move_p_m_one` then
            if Config.DebugDisplay then
                print("^3[RPEmotes] Applying walk style from backup check^7")
            end
            handleWalkstyle()
        end
    end)
end

if Config.WalkingStylesEnabled then
    RegisterCommand('walks', function() WalksOnCommand() end, false)
    RegisterCommand('walk', function(_, args, _) WalkCommandStart(tostring(args[1])) end, false)
    TriggerEvent('chat:addSuggestion', '/walk', 'Set your walkingstyle.', { { name = "style", help = "/walks for a list of valid styles" } })
    TriggerEvent('chat:addSuggestion', '/walks', 'List available walking styles.')
end

CreateExport('toggleWalkstyle', function(bool, message)
    canChange = bool
    if message then
        unable_message = message
    end
end)

CreateExport('getWalkstyle', function()
    return GetResourceKvpString("walkstyle")
end)

CreateExport('setWalkstyle', WalkMenuStart)

-- FIX FOR ILLENIUM-APPEARANCE SKIN RELOAD
RegisterNetEvent('illenium-appearance:client:reloadSkin', function()
    -- Wait for skin to fully load
    SetTimeout(1500, function()
        local savedWalkStyle = GetResourceKvpString("walkstyle")
        if savedWalkStyle and savedWalkStyle ~= "" then
            -- Check if the saved walk still exists in EmoteData
            if EmoteData and EmoteData[savedWalkStyle] and EmoteData[savedWalkStyle].category == Category.WALKS then
                local walk = EmoteData[savedWalkStyle].anim
                if walk then
                    RequestWalking(walk)
                    SetPedMovementClipset(PlayerPedId(), walk, 0.2)
                    RemoveAnimSet(walk)
                end
            end
        end
    end)
end)

-- Additional events that might be triggered by appearance scripts
RegisterNetEvent('illenium-appearance:client:onPlayerLoaded', function()
    CreateThread(function()
        Wait(1500)
        handleWalkstyle()
    end)
end)

RegisterNetEvent('illenium-appearance:client:loadSkin', function()
    CreateThread(function()
        Wait(1500)
        handleWalkstyle()
    end)
end)

-- Also handle clothing changes
RegisterNetEvent('qb-clothes:client:loadOutfit', function()
    CreateThread(function()
        Wait(1000)
        handleWalkstyle()
    end)
end)

RegisterNetEvent('qb-clothing:client:loadOutfit', function()
    CreateThread(function()
        Wait(1000)
        handleWalkstyle()
    end)
end)