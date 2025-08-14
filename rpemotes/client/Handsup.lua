local function HandsUpLoop()
    CreateThread(function()
        while InHandsup do
            if Config.DisabledHandsupControls then
                for control, state in pairs(Config.DisabledHandsupControls) do
                    DisableControlAction(0, control, state)
                end
            end

            if IsPlayerAiming(PlayerId()) then
                ClearPedSecondaryTask(PlayerPedId())
                CreateThread(function()
                    Wait(350)
                    InHandsup = false
                end)
            end

            Wait(0)
        end
    end)
end

if Config.HandsupEnabled then
    -- Prop preservation monitoring thread for hands up
    CreateThread(function()
        local lastPropCount = 0
        local wasInHandsup = false
        local storedAnimOptions = nil
        local storedTextureVariation = nil
        
        while true do
            Wait(50) -- Check every 50ms
            
            local currentPropCount = #PlayerProps
            
            -- Store prop info when we start hands up with props
            if InHandsup and not wasInHandsup and currentPropCount > 0 and Config.KeepPropsWhenHandsUp then
                storedAnimOptions = CurrentAnimOptions
                storedTextureVariation = CurrentTextureVariation
                DebugPrint("Started hands up with " .. currentPropCount .. " props - storing info")
            end
            
            -- Detect if props were destroyed during hands up
            if InHandsup and Config.KeepPropsWhenHandsUp and lastPropCount > 0 and currentPropCount == 0 and storedAnimOptions and storedAnimOptions.Prop then
                DebugPrint("Props destroyed during hands up - recreating them")
                CurrentAnimOptions = storedAnimOptions
                CurrentTextureVariation = storedTextureVariation
                RecreateProps()
            end
            
            -- Clear stored info when we stop hands up
            if not InHandsup and wasInHandsup then
                storedAnimOptions = nil
                storedTextureVariation = nil
            end
            
            lastPropCount = currentPropCount
            wasInHandsup = InHandsup
        end
    end)

    local function ToggleHandsUp(commandType)
        RegisterCommand(commandType, function()
            if IsPedInAnyVehicle(PlayerPedId(), false) and not Config.HandsupInCar and not InHandsup then
                return
            end
            Handsup()
        end, false)
    end

    if Config.HoldToHandsUp then
        ToggleHandsUp('+handsup')
        ToggleHandsUp('-handsup')
    else
        ToggleHandsUp('handsup')
    end

    function Handsup()
        local playerPed = PlayerPedId()
        if not IsPedHuman(playerPed) then
            return
        end
        if IsInActionWithErrorMessage() then
            return
        end

        InHandsup = not InHandsup
        if InHandsup then
            LocalPlayer.state:set('currentEmote', 'handsup', true)
            
            -- Store prop information before potentially destroying them
            local hadProps = false
            local storedAnimOptions = nil
            local storedTextureVariation = nil
            
            if Config.KeepPropsWhenHandsUp and CurrentAnimOptions and CurrentAnimOptions.Prop then
                hadProps = true
                storedAnimOptions = CurrentAnimOptions
                storedTextureVariation = CurrentTextureVariation
                DebugPrint("Storing prop info for hands up - " .. storedAnimOptions.Prop)
            end
            
            if not Config.KeepPropsWhenHandsUp then
                DestroyAllProps()
            else
                DebugPrint("Hands up - keeping props due to KeepPropsWhenHandsUp config")
            end
            
            local dict = "random@mugging3"
            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Wait(0)
            end
            TaskPlayAnim(PlayerPedId(), dict, "handsup_standing_base", 3.0, 3.0, -1, 49, 0, false,
                IsThisModelABike(GetEntityModel(GetVehiclePedIsIn(PlayerPedId(), false))) and 4127 or false, false)
            HandsUpLoop()
            
            -- Recreate props if they were destroyed
            if Config.KeepPropsWhenHandsUp and hadProps then
                CreateThread(function()
                    Wait(100)
                    if #PlayerProps == 0 then
                        DebugPrint("Props were destroyed during hands up, recreating them")
                        CurrentAnimOptions = storedAnimOptions
                        CurrentTextureVariation = storedTextureVariation
                        RecreateProps()
                    end
                end)
            end
        else
            LocalPlayer.state:set('currentEmote', nil, true)
            ClearPedSecondaryTask(PlayerPedId())
            if Config.ReplayEmoteAfterHandsup and IsInAnimation then
                local emote = EmoteData[CurrentAnimationName]
                if not emote then
                    return
                end

                Wait(400)
                if not Config.KeepPropsWhenHandsUp then
                    DestroyAllProps()
                else
                    DebugPrint("Hands down - keeping props due to KeepPropsWhenHandsUp config")
                end
                OnEmotePlay(CurrentAnimationName, CurrentTextureVariation)
            end
        end
    end

    TriggerEvent('chat:addSuggestion', '/handsup', Translate('handsup'))

    if Config.HandsupKeybindEnabled then
        RegisterKeyMapping("handsup", Translate('register_handsup'), "keyboard", Config.HandsupKeybind)
    end

    CreateExport('IsPlayerInHandsUp', function()
        return InHandsup
    end)
end