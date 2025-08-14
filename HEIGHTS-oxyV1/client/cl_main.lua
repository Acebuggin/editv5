local QBCore = exports['qb-core']:GetCoreObject()

local started = false
local hasDropOff = false
local oxyPed = nil
local madeDeal = false
local dropOffBlip = nil
local oxyVehicle = nil
local vehiclePlate = nil
local dropOffArea = nil
local nearPed = false
local inReturnZone = false
local arrivedInOxyVehicle = false -- Track if player arrived in their oxy vehicle

local peds = {
	'a_m_y_stwhi_02',
	'a_m_y_stwhi_01',
	'a_f_y_genhot_01',
	'a_f_y_vinewood_04',
	'a_m_m_golfer_01',
	'a_m_m_soucent_04',
	'a_m_o_soucent_02',
	'a_m_y_epsilon_01',
	'a_m_y_epsilon_02',
	'a_m_y_mexthug_01'
}

-- Debug print function
local function debugPrint(message)
	if Config.Debug then
		print("^3[HEIGHTS-oxyV1 DEBUG] ^7" .. message)
	end
end

--- Creates a drop off blip at a given coordinate
--- @param coords vector4 - Coordinates of a location
local CreateLocationBlip = function(coords)
	debugPrint("Creating location blip at " .. coords.x .. ", " .. coords.y)
	dropOffBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(dropOffBlip, 1)
    SetBlipScale(dropOffBlip, 1.0)
    SetBlipColour(dropOffBlip, 5) -- Yellow
    SetBlipAsShortRange(dropOffBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Location")
    EndTextCommandSetBlipName(dropOffBlip)
	
	-- Add GPS route like in boosting script
	SetBlipRoute(dropOffBlip, true)
	SetBlipRouteColour(dropOffBlip, 5) -- Yellow route
end

--- Updates the blip to follow the ped
--- @param ped entity - The ped entity to attach blip to
local UpdateBlipToPed = function(ped)
	debugPrint("Updating blip to follow ped")
	-- Remove the location blip
	if dropOffBlip then
		RemoveBlip(dropOffBlip)
	end
	
	-- Create new blip attached to ped
	dropOffBlip = AddBlipForEntity(ped)
    SetBlipSprite(dropOffBlip, 480) -- Person icon
    SetBlipScale(dropOffBlip, 1.0)
    SetBlipColour(dropOffBlip, 2) -- Green
    SetBlipAsShortRange(dropOffBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Customer")
    EndTextCommandSetBlipName(dropOffBlip)
end

--- Creates a drop off ped at a given coordinate
--- @param coords vector4 - Coordinates of a location
local CreateDropOffPed = function(coords)
	if oxyPed ~= nil then return end
	debugPrint("Creating delivery ped at location")
	local model = peds[math.random(#peds)]
	local hash = GetHashKey(model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
	oxyPed = CreatePed(5, hash, coords.x, coords.y, coords.z-1, coords.w, true, true)
	while not DoesEntityExist(oxyPed) do Wait(10) end
	
	-- Set ped properties
    TaskSetBlockingOfNonTemporaryEvents(oxyPed, true)
    SetPedFleeAttributes(oxyPed, 0, 0)
    SetPedCombatAttributes(oxyPed, 17, 1)
    SetPedSeeingRange(oxyPed, 20.0)
    SetPedHearingRange(oxyPed, 20.0)
    SetPedAlertness(oxyPed, 0)
	SetPedKeepTask(oxyPed, true)
	
	-- Update blip to follow the ped
	UpdateBlipToPed(oxyPed)
	
	-- Make ped wander around naturally using native AI
	TaskWanderStandard(oxyPed, 10.0, 10)
	
	-- Create interaction zone using textui
	CreateThread(function()
		while DoesEntityExist(oxyPed) and not madeDeal do
			Wait(0)
			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)
			local oxyPedCoords = GetEntityCoords(oxyPed)
			local distance = #(pedCoords - oxyPedCoords)
			
			if distance < 3.0 and IsPedOnFoot(ped) and not inReturnZone then
				if not nearPed then
					nearPed = true
					debugPrint("Near ped, showing textUI. inReturnZone: " .. tostring(inReturnZone))
					exports.ox_lib:showTextUI('[E] Make Deal', {
						position = "left-center",
						icon = 'capsules'
					})
				end
				
				if IsControlJustPressed(0, 38) then -- E
					debugPrint("E pressed for delivery. inReturnZone: " .. tostring(inReturnZone))
					exports.ox_lib:hideTextUI()
					TriggerEvent('HEIGHTS-oxyV1:client:DeliverOxy')
					break
				end
			else
				if nearPed then
					nearPed = false
					exports.ox_lib:hideTextUI()
				end
			end
		end
		nearPed = false
	end)
end

--- Creates a random drop off location
local CreateDropOff = function()
	-- Only create dropoff if player is in registered vehicle
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)
	
	if vehicle == 0 or vehicle ~= oxyVehicle then
		debugPrint("Not in registered vehicle, skipping dropoff creation")
		return
	end
	
	hasDropOff = true
	arrivedInOxyVehicle = false -- Reset the flag
	local randomLoc = Config.Locations[math.random(#Config.Locations)]
	debugPrint("Creating dropoff at location index")
	
	-- Create location blip immediately
	CreateLocationBlip(randomLoc)
	QBCore.Functions.Notify("Make your way to the delivery location", "primary", 5000)
	
	-- PolyZone to spawn ped when nearby
	dropOffArea = CircleZone:Create(randomLoc.xyz, 85.0, {
		name = "dropOffArea",
		debugPoly = false
	})
	dropOffArea:onPlayerInOut(function(isPointInside, point)
		if isPointInside then
			debugPrint("Entered dropoff area")
			-- Check if player is in oxy vehicle when entering
			local playerPed = PlayerPedId()
			local currentVehicle = GetVehiclePedIsIn(playerPed, false)
			if currentVehicle == oxyVehicle then
				arrivedInOxyVehicle = true
				debugPrint("Player arrived in oxy vehicle")
			else
				debugPrint("Player arrived but NOT in oxy vehicle")
			end
			
			if oxyPed == nil then
				QBCore.Functions.Notify("Find the customer walking around", "primary", 5000)
				CreateDropOffPed(randomLoc)
			end
		else
			debugPrint("Left dropoff area")
		end
	end)
end

--- Start an oxy run after paying the initial payment
local StartOxyrun = function(vehicleModel)
	if started then return end
	started = true
	debugPrint("Starting oxy run with vehicle: " .. vehicleModel)
	
	-- Clean up any existing oxy vehicle first
	if oxyVehicle and DoesEntityExist(oxyVehicle) then
		debugPrint("Deleting existing oxy vehicle before spawning new one")
		QBCore.Functions.DeleteVehicle(oxyVehicle)
		oxyVehicle = nil
		Wait(500) -- Small delay to ensure deletion
	end
	
	-- Spawn vehicle at configured location
	local coords = Config.VehicleSpawnLocation
	QBCore.Functions.SpawnVehicle(vehicleModel, function(veh)
		oxyVehicle = veh
		vehiclePlate = QBCore.Functions.GetPlate(veh)
		SetVehicleNumberPlateText(veh, vehiclePlate)
		debugPrint("Vehicle spawned. Plate: " .. vehiclePlate)
		
		-- Give keys using event-based system (most compatible)
		TriggerEvent("vehiclekeys:client:SetOwner", vehiclePlate)
		TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', vehiclePlate)
		TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
		
		-- Warp player into vehicle
		TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
		SetVehicleEngineOn(veh, true, true)
	end, coords, true)
	
	QBCore.Functions.Notify("Get in your vehicle to receive delivery locations", "primary", 7000)
	
	-- Main loop
	CreateThread(function()
		while started do
			Wait(100)
			local ped = PlayerPedId()
			local vehicle = GetVehiclePedIsIn(ped, false)
			
			-- Check if in registered vehicle
			if vehicle ~= 0 and vehicle == oxyVehicle then
				if not hasDropOff then
					Wait(2000)
					CreateDropOff()
				end
			else
				-- Player is not in vehicle, keep the blip visible
				-- The blip stays whether it's location or ped blip
			end
		end
	end)
end

--- Deletes the oxy ped
local DeleteOxyped = function()
	debugPrint("Deleting oxy ped")
	nearPed = false
	exports.ox_lib:hideTextUI()
	FreezeEntityPosition(oxyPed, false)
	SetPedKeepTask(oxyPed, false)
	TaskSetBlockingOfNonTemporaryEvents(oxyPed, false)
	ClearPedTasks(oxyPed)
	TaskWanderStandard(oxyPed, 10.0, 10)
	SetPedAsNoLongerNeeded(oxyPed)
	Wait(20000)
	DeletePed(oxyPed)
	oxyPed = nil
end

--- Ends the oxy run and cleans up
local EndOxyRun = function(withRefund)
	debugPrint("Ending oxy run. withRefund: " .. tostring(withRefund))
	started = false
	hasDropOff = false
	nearPed = false
	
	-- Clean up vehicle
	if oxyVehicle and DoesEntityExist(oxyVehicle) then
		QBCore.Functions.DeleteVehicle(oxyVehicle)
	end
	oxyVehicle = nil
	vehiclePlate = nil
	
	-- Clean up blips
	if dropOffBlip then RemoveBlip(dropOffBlip) end
	dropOffBlip = nil
	
	-- Clean up zones with nil check
	if dropOffArea then
		dropOffArea:destroy()
		dropOffArea = nil
	end
	
	-- Hide textui if showing
	exports.ox_lib:hideTextUI()
	
	-- Notify server (with refund parameter)
	TriggerServerEvent('HEIGHTS-oxyV1:server:EndRun', withRefund)
end

RegisterNetEvent("HEIGHTS-oxyV1:client:StartOxy", function()
	-- Remove the check for started - let server handle it
	debugPrint("StartOxy event triggered")
	QBCore.Functions.TriggerCallback('HEIGHTS-oxyV1:server:StartOxy', function(canStart, vehicleModel)
		if canStart then
			-- If run is already started, just spawn new vehicle
			if started then
				debugPrint("Already have active run, spawning replacement vehicle")
				-- Clean up any existing oxy vehicle first
				if oxyVehicle and DoesEntityExist(oxyVehicle) then
					debugPrint("Deleting existing oxy vehicle before spawning new one")
					QBCore.Functions.DeleteVehicle(oxyVehicle)
					oxyVehicle = nil
					Wait(500) -- Small delay to ensure deletion
				end
				
				-- Spawn new vehicle
				local coords = Config.VehicleSpawnLocation
				QBCore.Functions.SpawnVehicle(vehicleModel, function(veh)
					oxyVehicle = veh
					vehiclePlate = QBCore.Functions.GetPlate(veh)
					SetVehicleNumberPlateText(veh, vehiclePlate)
					debugPrint("Replacement vehicle spawned. Plate: " .. vehiclePlate)
					
					-- Give keys using event-based system (most compatible)
					TriggerEvent("vehiclekeys:client:SetOwner", vehiclePlate)
					TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', vehiclePlate)
					TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
					
					-- Warp player into vehicle
					TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
					SetVehicleEngineOn(veh, true, true)
				end, coords, true)
			else
				-- Start new run
				StartOxyrun(vehicleModel)
			end
		end
	end)
end)

RegisterNetEvent('HEIGHTS-oxyV1:client:DeliverOxy', function()
	debugPrint("DeliverOxy event triggered. madeDeal: " .. tostring(madeDeal) .. ", inReturnZone: " .. tostring(inReturnZone))
	if madeDeal or inReturnZone then 
		debugPrint("Delivery blocked - madeDeal or inReturnZone")
		return 
	end
	local ped = PlayerPedId()
	if not IsPedOnFoot(ped) then 
		debugPrint("Delivery blocked - not on foot")
		return 
	end
	
	-- Check if player arrived in their oxy vehicle
	if not arrivedInOxyVehicle then
		debugPrint("Delivery blocked - did not arrive in oxy vehicle")
		QBCore.Functions.Notify("You must arrive at the location in your oxy vehicle!", "error", 5000)
		return
	end
	
	-- Check if player has been in their oxy vehicle recently
	local lastVehicle = GetVehiclePedIsIn(ped, true) -- true = last vehicle
	if lastVehicle ~= oxyVehicle then
		debugPrint("Delivery blocked - last vehicle was not the oxy vehicle")
		QBCore.Functions.Notify("You must use your oxy vehicle for deliveries!", "error", 5000)
		return
	end
	
	if oxyPed and #(GetEntityCoords(ped) - GetEntityCoords(oxyPed)) < 5.0 then
		debugPrint("Starting delivery animation sequence")
		-- Anti spam
		madeDeal = true
		nearPed = false
		exports.ox_lib:hideTextUI()

		-- Stop ped movement and face each other
		ClearPedTasks(oxyPed)
		TaskTurnPedToFaceEntity(oxyPed, ped, 1.0)
		TaskTurnPedToFaceEntity(ped, oxyPed, 1.0)
		Wait(1500)
		PlayAmbientSpeech1(oxyPed, "Generic_Hi", "Speech_Params_Force")
		Wait(1000)

		-- Playerped animation
		RequestAnimDict("mp_safehouselost@")
    	while not HasAnimDictLoaded("mp_safehouselost@") do Wait(10) end
    	TaskPlayAnim(ped, "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
		Wait(800)
		
		-- Oxyped animation
		PlayAmbientSpeech1(oxyPed, "Chat_State", "Speech_Params_Force")
		Wait(500)
		TaskPlayAnim(oxyPed, "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
		Wait(3000)

		-- Remove blip
		RemoveBlip(dropOffBlip)
		dropOffBlip = nil

		-- Reward
		debugPrint("Sending reward to server")
		TriggerServerEvent('HEIGHTS-oxyV1:server:Reward')

		-- Finishing up
		if dropOffArea then
			debugPrint("Destroying dropoff area")
			dropOffArea:destroy()
			dropOffArea = nil
		end
		Wait(2000)
		QBCore.Functions.Notify("Delivery complete! Get back in your vehicle for the next location or return it to end", "success", 10000)
		DeleteOxyped()
		hasDropOff = false
		madeDeal = false
		arrivedInOxyVehicle = false -- Reset for next delivery
		debugPrint("Delivery completed successfully")
	else
		debugPrint("Delivery failed - not close enough to ped")
	end
end)

-- Vehicle return zone with marker
CreateThread(function()
	local returnZone = CircleZone:Create(Config.VehicleSpawnLocation.xyz, 5.0, {
		name = "oxyReturnZone",
		debugPoly = false
	})
	
	-- Create return zone blip when oxy run is active
	local returnBlip = nil
	CreateThread(function()
		while true do
			Wait(1000)
			if started and oxyVehicle and DoesEntityExist(oxyVehicle) then
				if not returnBlip then
					returnBlip = AddBlipForCoord(Config.VehicleSpawnLocation.x, Config.VehicleSpawnLocation.y, Config.VehicleSpawnLocation.z)
					SetBlipSprite(returnBlip, 50) -- Garage icon
					SetBlipScale(returnBlip, 0.8)
					SetBlipColour(returnBlip, 3) -- Blue
					SetBlipAsShortRange(returnBlip, false)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString("Return Vehicle")
					EndTextCommandSetBlipName(returnBlip)
					debugPrint("Created return zone blip")
				end
			else
				if returnBlip then
					RemoveBlip(returnBlip)
					returnBlip = nil
					debugPrint("Removed return zone blip")
				end
			end
		end
	end)
	
	-- Draw marker thread
	CreateThread(function()
		while true do
			Wait(0)
			if started then
				local ped = PlayerPedId()
				local vehicle = GetVehiclePedIsIn(ped, false)
				local coords = Config.VehicleSpawnLocation
				
				-- Only draw marker if player is in the oxy vehicle
				if vehicle ~= 0 and vehicle == oxyVehicle then
					DrawMarker(
						Config.ReturnMarker.type,
						coords.x, coords.y, coords.z,
						0.0, 0.0, 0.0,
						0.0, 0.0, 0.0,
						Config.ReturnMarker.size.x, Config.ReturnMarker.size.y, Config.ReturnMarker.size.z,
						Config.ReturnMarker.color.r, Config.ReturnMarker.color.g, Config.ReturnMarker.color.b, Config.ReturnMarker.color.a,
						Config.ReturnMarker.bobUpAndDown,
						Config.ReturnMarker.faceCamera,
						2,
						Config.ReturnMarker.rotate,
						nil,
						nil,
						Config.ReturnMarker.drawOnEnts
					)
				end
			else
				Wait(1000)
			end
		end
	end)
	
	returnZone:onPlayerInOut(function(isPointInside)
		inReturnZone = isPointInside
		debugPrint("Return zone state changed. inReturnZone: " .. tostring(inReturnZone))
		if isPointInside and started then
			local ped = PlayerPedId()
			local vehicle = GetVehiclePedIsIn(ped, false)
			
			-- Must be in the oxy vehicle to return it
			if vehicle ~= 0 and vehicle == oxyVehicle then
				-- Check if near delivery ped - if so, don't show return UI
				local nearDeliveryPed = false
				if oxyPed and DoesEntityExist(oxyPed) then
					local distance = #(GetEntityCoords(ped) - GetEntityCoords(oxyPed))
					if distance < 10.0 then -- Within 10 meters of delivery ped
						nearDeliveryPed = true
						debugPrint("Near delivery ped, suppressing return zone UI")
					end
				end
				
				if not nearDeliveryPed then
					local text = '[E] Return Vehicle & End Run'
					if Config.RefundOnReturn then
						text = text .. ' (Refund: $' .. Config.RefundAmount .. ')'
					end
					
					debugPrint("Showing return vehicle textUI")
					exports.ox_lib:showTextUI(text, {
						position = "left-center",
						icon = 'car'
					})
					
					CreateThread(function()
						while inReturnZone and started do
							Wait(0)
							-- Double check we're actually in the return zone
							local playerCoords = GetEntityCoords(PlayerPedId())
							local returnCoords = Config.VehicleSpawnLocation
							local distanceToReturn = #(playerCoords - vector3(returnCoords.x, returnCoords.y, returnCoords.z))
							
							if distanceToReturn > 5.0 then
								-- Player moved too far from return zone
								exports.ox_lib:hideTextUI()
								debugPrint("Player left return zone - hiding UI")
								break
							end
							
							-- Must still be in vehicle
							local currentVeh = GetVehiclePedIsIn(PlayerPedId(), false)
							if currentVeh ~= oxyVehicle then
								exports.ox_lib:hideTextUI()
								break
							end
							
							-- Re-check if near delivery ped
							if oxyPed and DoesEntityExist(oxyPed) then
								local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(oxyPed))
								if dist < 10.0 then
									exports.ox_lib:hideTextUI()
									debugPrint("Hiding return UI - too close to delivery ped")
									break
								end
							end
							
							if IsControlJustPressed(0, 38) then -- E
								-- Triple check distance to return zone before allowing return
								local finalPlayerCoords = GetEntityCoords(PlayerPedId())
								local finalDistToReturn = #(finalPlayerCoords - vector3(returnCoords.x, returnCoords.y, returnCoords.z))
								
								if finalDistToReturn > 5.0 then
									debugPrint("E pressed but too far from return zone - ignoring")
									QBCore.Functions.Notify("You must be at the return location to return the vehicle", "error")
									break
								end
								
								-- Final check before ending run
								if oxyPed and DoesEntityExist(oxyPed) then
									local finalDist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(oxyPed))
									if finalDist < 10.0 then
										debugPrint("E pressed but near delivery ped - ignoring return command")
										break
									end
								end
								debugPrint("E pressed in return zone - ending run")
								exports.ox_lib:hideTextUI()
								EndOxyRun(true) -- true = with refund
								break
							end
						end
					end)
				end
			else
				-- Not in vehicle, show message
				if vehicle == 0 and oxyVehicle and DoesEntityExist(oxyVehicle) then
					exports.ox_lib:showTextUI('You must be in your oxy vehicle to return it', {
						position = "left-center",
						icon = 'car',
						style = {
							backgroundColor = '#8B0000',
						}
					})
					
					Wait(3000)
					exports.ox_lib:hideTextUI()
				end
			end
		else
			exports.ox_lib:hideTextUI()
		end
	end)
end)

-- Main starter zone
CreateThread(function()
	-- Create zone for starter location
	local starterZone = CircleZone:Create(Config.StartLocation.xyz, 2.5, {
		name = "oxyStarterZone",
		debugPoly = false
	})
	
	starterZone:onPlayerInOut(function(isPointInside)
		if isPointInside then
			-- Always show the prompt - let server decide what to do
			local promptText = '[E] Start Oxy Run ($'..Config.StartOxyPayment..')'
			if started then
				promptText = '[E] Get New Oxy Vehicle'
			end
			
			exports.ox_lib:showTextUI(promptText, {
				position = "left-center",
				icon = 'capsules'
			})
			
			CreateThread(function()
				while isPointInside do
					Wait(0)
					if IsControlJustPressed(0, 38) then -- E
						debugPrint("Starting/Getting new oxy vehicle from starter zone")
						exports.ox_lib:hideTextUI()
						TriggerEvent('HEIGHTS-oxyV1:client:StartOxy')
						break
					end
				end
			end)
		else
			exports.ox_lib:hideTextUI()
		end
	end)
	
	-- Starter ped with render distance management
	local pedModel = `g_m_m_chemwork_01`
	local starterPed = nil
	local pedSpawned = false
	
	-- Thread to manage ped spawning based on distance
	CreateThread(function()
		while true do
			Wait(1000) -- Check every second
			local playerCoords = GetEntityCoords(PlayerPedId())
			local distance = #(playerCoords - Config.StartLocation.xyz)
			
			if distance <= Config.StartPedRenderDistance then
				if not pedSpawned then
					debugPrint("Player within render distance, spawning starter ped")
					RequestModel(pedModel)
					while not HasModelLoaded(pedModel) do Wait(10) end
					starterPed = CreatePed(0, pedModel, Config.StartLocation.x, Config.StartLocation.y, Config.StartLocation.z-1.0, Config.StartLocation.w, false, false)
					TaskStartScenarioInPlace(starterPed, 'WORLD_HUMAN_CLIPBOARD', true)
					FreezeEntityPosition(starterPed, true)
					SetEntityInvincible(starterPed, true)
					SetBlockingOfNonTemporaryEvents(starterPed, true)
					pedSpawned = true
				end
			else
				if pedSpawned and starterPed then
					debugPrint("Player outside render distance, removing starter ped")
					DeletePed(starterPed)
					starterPed = nil
					pedSpawned = false
				end
			end
		end
	end)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then
		return
	end
	if started then
		EndOxyRun(false)
	end
	exports.ox_lib:hideTextUI()
end)

-- ========================================
-- EXPORT FUNCTIONS
-- ========================================

--- Export function to get the current oxy delivery ped
--- @return entity|nil - Returns the oxy ped entity or nil if none exists
exports('GetOxyDeliveryPed', function()
	return oxyPed
end)

--- Export function to check if a specific ped is the oxy delivery ped
--- @param ped entity - The ped entity to check
--- @return boolean - Returns true if the ped is the oxy delivery ped
exports('IsOxyDeliveryPed', function(ped)
	if not ped or not DoesEntityExist(ped) then
		return false
	end
	return ped == oxyPed
end)

--- Export function to get all active oxy delivery data
--- @return table - Returns table with delivery status and ped info
exports('GetOxyDeliveryData', function()
	return {
		isActive = started and hasDropOff,
		hasPed = oxyPed ~= nil and DoesEntityExist(oxyPed),
		ped = oxyPed,
		madeDeal = madeDeal
	}
end)