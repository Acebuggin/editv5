-- Ensure PlayerProps exists (it's defined in Emote.lua but we need it here)
PlayerProps = PlayerProps or {}
LastValidPropInfo = LastValidPropInfo or {}
CurrentAnimOptions = CurrentAnimOptions or nil
CurrentTextureVariation = CurrentTextureVariation or nil

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
            if Config.KeepPropsWhenHandsUp and PlayerProps and #PlayerProps > 0 then
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
            if Config.KeepPropsWhenHandsUp then
                CreateThread(function()
                    Wait(100) -- Give animation time to start
                    DebugPrint("Checking if props need recreation after hands up animation")
                    
                    -- Force recreation even if props exist, as they might be detached
                    for i = 1, 3 do
                        Wait(50 * i) -- Wait 50ms, 100ms, 150ms
                        
                        -- Check if props are attached to player
                        local propsAttached = false
                        if PlayerProps and #PlayerProps > 0 then
                            local firstProp = PlayerProps[1]
                            if firstProp and DoesEntityExist(firstProp) then
                                local attachedTo = GetEntityAttachedTo(firstProp)
                                propsAttached = (attachedTo == PlayerPedId())
                                DebugPrint("Attempt " .. i .. ": Prop exists, attached to: " .. tostring(attachedTo) .. ", player: " .. tostring(PlayerPedId()))
                            end
                        end
                        
                        if not propsAttached then
                            DebugPrint("Props not attached to player, recreating...")
                            
                            -- Destroy existing props first as they might be detached
                            if PlayerProps and #PlayerProps > 0 then
                                DebugPrint("Clearing existing detached props")
                                DestroyAllProps()
                                Wait(50)
                            end
                            
                            -- Now recreate them
                            if RecreateStoredProps then
                                RecreateStoredProps()
                            elseif LastValidPropInfo and LastValidPropInfo.AnimOptions then
                                DebugPrint("Using LastValidPropInfo for recreation")
                                -- Manually recreate using last valid info
                                CurrentAnimOptions = LastValidPropInfo.AnimOptions
                                CurrentTextureVariation = LastValidPropInfo.TextureVariation
                                if addProps then
                                    addProps(LastValidPropInfo.AnimOptions, LastValidPropInfo.TextureVariation, false)
                                end
                            end
                            Wait(50)
                            
                            if PlayerProps and #PlayerProps > 0 then
                                DebugPrint("Props recreated on attempt " .. i .. " (new count: " .. #PlayerProps .. ")")
                                break
                            end
                        else
                            DebugPrint("Props are properly attached, no recreation needed")
                            break
                        end
                    end
                end)
            end
        else
            DebugPrint("=== HANDS DOWN SEQUENCE START ===")
            LocalPlayer.state:set('currentEmote', nil, true)
            ClearPedSecondaryTask(PlayerPedId())
            if Config.ReplayEmoteAfterHandsup and IsInAnimation then
                local emote = EmoteData[CurrentAnimationName]
                if not emote then
                    DebugPrint("No emote data found for: " .. tostring(CurrentAnimationName))
                    return
                end

                DebugPrint("Will replay emote: " .. CurrentAnimationName)
                DebugPrint("Current prop count before replay: " .. (PlayerProps and #PlayerProps or 0))
                
                Wait(400)
                if not Config.KeepPropsWhenHandsUp then
                    DestroyAllProps()
                else
                    DebugPrint("Hands down - keeping props due to KeepPropsWhenHandsUp config")
                end
                
                -- Set flag to preserve props during replay
                if Config.KeepPropsWhenHandsUp and PreservingHandsUpProps ~= nil then
                    PreservingHandsUpProps = true
                    DebugPrint("Setting PreservingHandsUpProps = true for replay")
                end
                
                OnEmotePlay(CurrentAnimationName, CurrentTextureVariation)
                
                -- Clear flag after a delay
                if PreservingHandsUpProps ~= nil then
                    CreateThread(function()
                        Wait(1000)
                        PreservingHandsUpProps = false
                        DebugPrint("Cleared PreservingHandsUpProps flag")
                    end)
                end
                
                DebugPrint("=== HANDS DOWN SEQUENCE END ===")
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