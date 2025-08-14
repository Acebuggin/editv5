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
            -- Store props info FIRST before anything else
            local needToRecreateProp = false
            if Config.KeepPropsWhenHandsUp and #PlayerProps > 0 then
                if StorePropsInfo then
                    StorePropsInfo()
                    needToRecreateProp = true
                    DebugPrint("Storing props info before hands up - PlayerProps count: " .. #PlayerProps)
                end
            end
            
            LocalPlayer.state:set('currentEmote', 'handsup', true)
            
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
            
            -- Recreate props after animation starts with multiple attempts
            if needToRecreateProp and RecreateStoredProps then
                CreateThread(function()
                    -- Try multiple times to ensure props are recreated
                    for i = 1, 3 do
                        Wait(50 * i) -- Wait 50ms, 100ms, 150ms
                        if #PlayerProps == 0 then
                            DebugPrint("Attempt " .. i .. ": Props were destroyed by hands up animation, recreating")
                            RecreateStoredProps()
                            Wait(50)
                            if #PlayerProps > 0 then
                                DebugPrint("Props successfully recreated on attempt " .. i)
                                break
                            end
                        else
                            DebugPrint("Props still exist, no need to recreate")
                            break
                        end
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