BR = nil
local set                       = false
local cufftime                  = false
local PlayerData                = {}
local GUI                       = {}
local HasAlreadyEnteredMarker   = false
local LastStation               = nil
local LastPart                  = nil
local LastEntity                = nil
local CurrentAction             = nil
local CurrentActionMsg          = ''
local CurrentActionData         = {}
local IsBusy, isBusy            = false, false
local CopPed                    = 0
local allBlip                   = {}
local Data                      = {}
GUI.Time                        = 0

Citzen.CreateThread(function()
	while BR == nil do
		TriggerEvent('brt:getSharedObject', function(obj) BR = obj end)
		Citzen.Wait(0)
	end
end)


function OpenCloakroomMenu()
	local elements = {
		{label = "👔 Lebas Shahrvandi", value = 'citizen_wear'},
		{label = '☠️ Lebas Gang', value = 'gang_wear'}
	}

	BR.UI.Menu.CloseAll()

	BR.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = _U('cloakroom'),
		align    = 'top-right',
		elements = elements,
	}, function(data, menu)
		menu.close()
		BR.TriggerServerCallback('brt_skin:getGangSkin', function(skin, gangSkin)
			if data.current.value == 'citizen_wear' then
				TriggerEvent('skinchanger:loadSkin', skin)
				TriggerEvent('brt:restoreLoadout')
			elseif data.current.value == 'gang_wear' then
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, gangSkin.skin_male)
				else
					TriggerEvent('skinchanger:loadClothes', skin, gangSkin.skin_female)
				end
			end
		end)

		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end, function(data, menu)
		menu.close()
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end)
end

function OpenArmoryMenu(station)
	local station = station
	local elements = {
		{label = '💼 Inventory Gang', value = 'property_inventory'},
		{label = '👔 Armor Be Gheymat '..Data.vest_price.. '$',  value = 'get_armor'}
	}
	BR.UI.Menu.CloseAll()

	BR.UI.Menu.Open('default', GetCurrentResourceName(), 'armory', {
		title    = _U('armory'),
		align    = 'top-right',
		elements = elements,
	}, function(data, menu)
		if data.current.value == "property_inventory" then
			  if PlayerData.gang.grade >= Data.armory_access then
				menu.close()
				BR.TriggerServerCallback("gangs:getGangInventory", function(inventory)
					TriggerEvent("brt_inventoryhud:openGangInventory", inventory)
				end)
			else
				BR.ShowNotification("~h~Shoma Ejaze Dastresi Be Armory Nadarid")
			end
		elseif data.current.value == 'get_armor' then
			  if PlayerData.gang.grade >= Data.vest_access then
				local ped = PlayerPedId()
				local armor = GetPedArmour(ped)

					if armor >= Data.bulletproof then
						BR.ShowNotification("~g~Armor shoma por ast nemitavanid dobare armor kharidari konid!")
					else
					TriggerServerEvent("gangprop:setArmor", Data.vest_price)
				end
			  else
				BR.ShowNotification("~h~Shoma Ejaze Gereftan Armor Nadarid")
			end
		end
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	end)
end

function ListOwnedCarsMenu()
	local elements = {}
	table.insert(elements, {label = '| Pelak | Esm Mashin |'})

	BR.TriggerServerCallback('gangprop:getCars', function(ownedCars)
		if #ownedCars == 0 then
			BR.ShowNotification('Gang Shoma Hich VasileNaghlie Nadarad')
		else
			for _,v in pairs(ownedCars) do
				if v.stored then
					local hashVehicule = v.vehicle.model
					local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
					local vehicleName  = GetLabelText(aheadVehName)
					local plate        = v.plate
					local labelvehicle
					labelvehicle = '| '..plate..' | '..vehicleName..' |'
					table.insert(elements, {label = labelvehicle, value = v})          
						end
				  end
			end
		
			BR.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_owned_car', {
			title    = 'Gang Parking',
			align    = 'top-right',
			elements = elements
		}, function(data, menu)
			if data.current.value.stored then
				menu.close()
				Wait(math.random(0,500))
				BR.TriggerServerCallback('gangprop:carAvalible', function(avalibele)
					if avalibele then        
						SpawnVehicle(data.current.value.vehicle, data.current.value.plate)
					else
						BR.ShowNotification('In Mashin Qablan az Parking Dar amade ast')
					end
				end, data.current.value.plate)
			else
				BR.ShowNotification(_U('car_is_impounded'))
			end
		end, function(data, menu)
			  menu.close()
		end)
	end)
end

function OpenHeliMenu()
	local elements = {}

	if Data.heli_model1 ~= nil then
		local aheadVehName1 = GetDisplayNameFromVehicleModel(Data.heli_model1)
		local vehicleName1  = GetLabelText(aheadVehName1) 
		table.insert(elements, {label = 'Spawn ' .. vehicleName1 , value = 'get_veh1'})
	end
	if Data.heli_model2 ~= nil then
		local aheadVehName2 = GetDisplayNameFromVehicleModel(Data.heli_model2)
		local vehicleName2  = GetLabelText(aheadVehName2) 
		table.insert(elements, {label = 'Spawn ' .. vehicleName2 , value = 'get_veh2'})
	end

	BR.UI.Menu.CloseAll()

	BR.UI.Menu.Open('default', GetCurrentResourceName(), 'heli', {
		title    = "Daryaft Helicopter",
		align    = 'top-right',
		elements = elements,
	}, function(data, menu)
		if data.current.value == "get_veh1" then
			menu.close()
			HelicopterSpawner(Data.heli_model1)
		elseif data.current.value == "get_veh2" then
			menu.close()
			HelicopterSpawner(Data.heli_model2)
		end
	end, function(data, menu)
		menu.close()
	end)
end

-- Spawn Cars
function SpawnVehicle(vehicle, plate)
	local shokol = GetClosestVehicle(Data.vehspawn.x,  Data.vehspawn.y,  Data.vehspawn.z,  3.0,  0,  71)
	if not DoesEntityExist(shokol) then
		BR.Game.SpawnVehicle(vehicle.model, {
			x = Data.vehspawn.x,
			y = Data.vehspawn.y,
			z = Data.vehspawn.z + 1
		}, Data.vehspawn.a, function(callback_vehicle)
			BR.Game.SetVehicleProperties(callback_vehicle, vehicle)
			SetVehRadioStation(callback_vehicle, "OFF")
			TaskWarpPedIntoVehicle(PlayerPedId(), callback_vehicle, -1)
		end)
		TriggerServerEvent('brt_advancedgarage:setVehicleState', plate, false)
	else
		BR.ShowNotification('Mahale Spawn mashin ro Khali konid')
	end
end

function HelicopterSpawner(model)
	if BR.Game.IsSpawnPointClear({x = Data.helispawn.x, y = Data.helispawn.y, z = Data.helispawn.z}, 5.0) then
		local playerPed = PlayerPedId()
		BR.Game.SpawnVehicle(model,{
			x = Data.helispawn.x,
			y = Data.helispawn.y,
			z = Data.helispawn.z + 1
		}, Data.helispawn.a, function(vehicle)
			SetVehicleModKit(vehicle, 0)
			SetVehicleLivery(vehicle, 0)
			exports.BR_fuel:SetFuel(vehicle, 100.0)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		end)
	end
end

function OpenGangActionsMenu()
	BR.UI.Menu.CloseAll()    
  
	local elements = {
		{label = "🔍 Search Kardan", value = 'search_player'},
		{label = "🔒 Zadan Dastband",        value = 'handcuff'},
		{label = "🔓 Baz Kardan Dastband",              value = 'uncuff'},
		{label = "✋ Darg/UnDrag Kardan",            value = 'drag'},
		{label = "🚗 Gozashtan Dar Mashin",  value = 'put_in_vehicle'},
		{label = "🚙 Biron Avordan Az Mashin", value = 'out_the_vehicle'},
		{label = '🔐 LockPick VasileNaghlie', value = 'hijack_vehicle'},
		{label = '👪 Invite Member', value = 'manage_user'},
	}
	
	BR.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
		title    = "Gang Menu",
		align    = 'top-right',
		elements = elements
	}, function(data2, menu2)
		local player, distance = BR.Game.GetClosestPlayer()

		if data2.current.value == 'hijack_vehicle' then
			if Data.lockpick == 1 then
				if PlayerData.gang.grade >= Data.lockpick_access  then 
					local playerPed = PlayerPedId()
					local vehicle   = BR.Game.GetVehicleInDirection()
					local coords    = GetEntityCoords(playerPed)

					if IsPedSittingInAnyVehicle(playerPed) then
						BR.ShowNotification("Yeki Dakhele VasileNaghlias")
						return
					end

					if DoesEntityExist(vehicle) then
						IsBusy = true
						TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
						SetVehicleAlarm(vehicle, 1)
						StartVehicleAlarm(vehicle)
						SetVehicleAlarmTimeLeft(vehicle, 40000)
						TriggerEvent('brt_customItems:checkVehicleDistance', vehicle)
						TriggerEvent("mythic_progbar:client:progress", {
							name = "hijack_vehicle",
							duration = 30000,
							label = "LockPick kardan mashin",
							useWhileDead = false,
							canCancel = true,
							controlDisables = {
								disableMovement = true,
								disableCarMovement = true,
								disableMouse = false,
								disableCombat = true,
							}
						}, function(status)
							if not status then
								SetVehiceleDoorsLocked(vehicle, 1)
								SetVehiceleDoorsLockedForAllPlayers(vehicle, false)
								ClearPedTasksImediately(playerPed)
								BR.ShowNotification(_U('vehicle_unlocked'))
								IsBusy = false
								TriggerEvent('brt_customItems:checkVehicleStatus', false)
							elseif status then
								IsBusy = false
								ClearPedTasksImediately(playerPed)
								TriggerEvent('brt_customItems:checkVehicleStatus', false)
							end
						end)
					else
						BR.ShowNotification(_U('no_vehicle_nearby'))
					end
				else
					BR.ShowNotification('Rank Shoma Ejaze LockPick Nadarad')
				end
			else
				BR.ShowNotification('Gang Shoma Ghabeliyat LockPick Nadarad')
			end
		end

		if distance ~= -1 and distance <= 3.0 then
			if data2.current.value == 'handcuff' then
				if cufftime then
					BR.ShowNotification('Lotfan Ta Cuff Badi 30 Saniye Sabr Konid!')
				else
					local target, distance = BR.Game.GetClosestPlayer()
					local target_id = GetPlayerServerId(target)
					exports.BR_jobs:cuffplayer(target_id, 2)
					cufftime = true            
					Citizen.SetTimeout(30000, function()
						cufftime = false
					end)
				end
			elseif data2.current.value == 'uncuff' then
				local target, distance = BR.Game.GetClosestPlayer()
				local target_id = GetPlayerServerId(target)
				exports.BR_jobs:uncuffplayer(target_id, 2)	
			elseif data2.current.value == 'drag' then
				local target, distance = BR.Game.GetClosestPlayer()
				local target_id = GetPlayerServerId(target)
				exports.BR_jobs:dragplayer(target_id)
			elseif data2.current.value == 'put_in_vehicle' then
				exports.BR_jobs:putinvehicle(GetPlayerServerId(player))
			elseif data2.current.value == 'out_the_vehicle' then
				exports.BR_jobs:putoutvehicle(GetPlayerServerId(player))
			elseif data2.current.value == "search_player" then
				if tonumber(Data.search) == 1 then
					if GetVehiclePedIsIn(GetPlayerPed(player), false) ~= 0 then BR.ShowNotification('Fard Savar VasileNaghlie Ast!') return end
					BR.TriggerServerCallback("brt:checkInjure", function(IsDead)
						if IsDead == false and IsDead ~= 'done' then
							BR.TriggerServerCallback("br_jobs:IsHandCuffed", function(IsCuffed)
								if IsEntityPlayingAnim(GetPlayerPed(player), "missminuteman_1ig_2", "handsup_enter", 3) or IsCuffed then
									OpenBodySearchMenu(player)
									TriggerServerEvent('brt_3dme:shareDisplay', string.gsub(PlayerData.name, "_", " ") .. ' Dast To Jib Fard Mikone')
								else
									BR.ShowNotification('Baraye ~r~Search ~s~Bayad Dast Haye Fard ~g~Bala ~s~Bashad Ya ~g~Dastband ~s~Khorde Bashad')
								end
							end, GetPlayerServerId(player))
						else
							OpenBodySearchMenu(player)
							TriggerServerEvent('brt_3dme:shareDisplay', string.gsub(PlayerData.name, "_", " ") .. ' Dast To Jib Fard Mikone')
						end
					end, GetPlayerServerId(player))
				else
					BR.ShowNotification('Gang Shoma Ghabeliyat Search Nadarad')
				end
			elseif data2.current.value == "manage_user" then
				if PlayerData.gang.grade >= Data.invite_access  then 
					TriggerEvent('gangs:openInviteF5', PlayerData.gang.name, function(data, menu)
						menu.close()
						CurrentAction     = 'menu_boss_actions'
						CurrentActionMsg  = _U('open_bossmenu')
						CurrentActionData = {}
					end)
				else
					BR.ShowNotification('Rank Shoma Ejaze Invite Member Nadarad')
				end
			end
		else
			BR.ShowNotification('Hich Playeri Nazdik Shoma Nist')
		end
	end, function(data2, menu2)
		menu2.close()
	end)
end


function OpenBodySearchMenu(player)
	BR.TriggerServerCallback('brt:getOtherPlayerDataCard', function(data)
		local elements = {}
		table.insert(elements, {label = '--- Pool Tamiz---', value = nil})
		table.insert(elements, {
			label    = "🟢 Bardasht $" .. BR.Math.GroupDigits(data.money),
			value    = 'money',
			itemType = 'item_money',
			amount   = data.money
		})
		table.insert(elements, {label = '--- Pool Kasif---', value = nil})
		table.insert(elements, {
			label    = "🔴 Bardasht $" .. BR.Math.GroupDigits(data.dirty_money),
			value    = 'dirty_money',
			itemType = 'item_dirty_money',
			amount   = data.dirty_money
		})

		table.insert(elements, {label = '--- Aslahe Ha ---', value = nil})
		for i=1, #data.weapons, 1 do
			table.insert(elements, {
				label          = "Bardasht " .. BR.GetWeaponLabel(data.weapons[i].name),
				value          = data.weapons[i].name,
				itemType       = 'item_weapon',
				amount         = data.ammo,
			})
		end

		table.insert(elements, {label = _U('inventory_label'), value = nil})
		for i=1, #data.inventory, 1 do
			if data.inventory[i].count > 0 then
				table.insert(elements, {
					label          = "Bardasht " .. data.inventory[i].count .. ' ' .. data.inventory[i].label,
					value          = data.inventory[i].name,
					itemType       = 'item_standard',
					amount         = data.inventory[i].count,
				})
			end
		end

		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'body_search', {
			title    = _U('search'),
			align    = 'top-right',
			elements = elements,
		}, function(data, menu)
			local itemType = data.current.itemType
			local itemName = data.current.value
			local amount   = data.current.amount

			if data.current.value ~= nil then
				local coords = GetEntityCoords(PlayerPedId())
				if GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(player)), coords.x, coords.y, coords.z, true) <= 3.0 then
					Wait(math.random(0, 500))
					TriggerServerEvent('brt:confiscatePlayerItem', GetPlayerServerId(player), itemType, itemName, amount)
					OpenBodySearchMenu(player)
				else
					menu.close()
				end
			end
		end, function(data, menu)
			menu.close()
		end)
	end, GetPlayerServerId(player))
end

RegisterNetEvent('brt:playerLoaded')
AddEventHandler('brt:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	local WWaiTT = true
	if PlayerData.gang.name ~= 'nogang' then
		BR.TriggerServerCallback('gangs:getGangData', function(data)
			if data ~= nil then
				Data.gang_name    = data.gang_name
				Data.blip         = json.decode(data.blip)
				blipManager(Data.blip)
				Data.armory         = json.decode(data.armory)
				Data.locker         = json.decode(data.locker)
				Data.boss           = json.decode(data.boss)
				Data.vehicles       = json.decode(data.vehicles)
				Data.veh            = json.decode(data.veh)
				Data.vehdel         = json.decode(data.vehdel)
				Data.vehspawn       = json.decode(data.vehspawn)
				Data.vehprop        = json.decode(data.vehprop)
				Data.helicopter     = data.helicopter
				Data.heli_model1    = data.heli_model1
				Data.heli_model2    = data.heli_model2
				Data.heli           = json.decode(data.heli)
				Data.helidel        = json.decode(data.helidel)
				Data.helispawn      = json.decode(data.helispawn)
				Data.search         = data.search
				Data.bulletproof    = data.bulletproof
				Data.garage_access  = data.garage_access
				Data.armory_access  = data.armory_access
				Data.heli_access    = data.heli_access
				Data.vest_access    = data.vest_access
				Data.vest_price     = data.vest_price
				Data.lockpick       = data.lockpick
				Data.lockpick_access = data.lockpick_access
				Data.invite_access  = data.invite_access
				Data.blip_sprite    = data.blip_sprite
				Data.blip_color     = data.blip_color
				BR.SetPlayerData('CanGangLog', data.logpower)
			else
				BR.ShowNotification('Gang Shoma Disable Shode Ast Lotfan Be Staff Morajee Konid!')
			end
			WWaiTT = false
		end, PlayerData.gang.name)
	end
end)

RegisterNetEvent('brt:setJob')
AddEventHandler('brt:setJob', function(job)
	PlayerData.job = job
end)

RegisterNetEvent('brt:setGang')
AddEventHandler('brt:setGang', function(gang)
	PlayerData.gang = gang
	Data = {}
	local WWaiTT = true
	if PlayerData.gang.name ~= 'nogang' then
		BR.TriggerServerCallback('gangs:getGangData', function(data)
			if data ~= nil then
				Data.blip         = json.decode(data.blip)
				blipManager(Data.blip)
				Data.gang_name      = data.gang_name
				Data.armory         = json.decode(data.armory)
				Data.locker         = json.decode(data.locker)
				Data.boss           = json.decode(data.boss)
				Data.vehicles       = json.decode(data.vehicles)
				Data.veh            = json.decode(data.veh)
				Data.vehdel         = json.decode(data.vehdel)
				Data.vehspawn       = json.decode(data.vehspawn)
				Data.vehprop        = json.decode(data.vehprop)
				Data.helicopter     = data.helicopter
				Data.heli_model1    = data.heli_model1
				Data.heli_model2    = data.heli_model2
				Data.heli           = json.decode(data.heli)
				Data.helidel        = json.decode(data.helidel)
				Data.helispawn      = json.decode(data.helispawn)
				Data.search         = data.search
				Data.bulletproof    = data.bulletproof
				Data.garage_access  = data.garage_access
				Data.armory_access  = data.armory_access
				Data.heli_access    = data.heli_access
				Data.vest_access    = data.vest_access
				Data.vest_price     = data.vest_price
				Data.lockpick       = data.lockpick
				Data.lockpick_access = data.lockpick_access
				Data.invite_access  = data.invite_access
				Data.blip_sprite    = data.blip_sprite
				Data.blip_color     = data.blip_color
				BR.SetPlayerData('CanGangLog', data.logpower)
			else
				BR.ShowNotification('Gang Shoma Disable Shode Ast Lotfan Be Staff Morajee Konid!')
			end
			WWaiTT = false
		end, PlayerData.gang.name)
	else
		for _, blip in pairs(allBlip) do
		  RemoveBlip(blip)
		end
		allBlip = {}
	end
end)

AddEventHandler("onKeyDown", function(key)
	if key == "f5" and not BR.UI.Menu.IsOpen("default", GetCurrentResourceName(), "citizen_interaction") and PlayerData.gang ~= nil and PlayerData.gang.name ~= 'nogang' then
        while BR == nil do
			Citzen.Wait(10)
		end
		if BR.GetPlayerData()['IsDead'] == 1 then return end
		if PlayerData.job.name == 'police' or PlayerData.job.name == 'offpolice' or PlayerData.job.name == 'sheriff' or PlayerData.job.name == 'offsheriff' then
			BR.ShowNotification('Shoma Nemitavanid Hengami Ke Police Ya Sheriff Hastid Az Menu Gang Estefade Konid')
		else
			OpenGangActionsMenu()
		end
	end
end)

-- Create blips
function blipManager(blip)
	for _, blip in pairs(allBlip) do
		RemoveBlip(blip)
	end
	allBlip = {}
	local blipCoord = AddBlipForCoord(blip.x, blip.y)
	table.insert(allBlip, blipCoord)
	
	local sprite
	local color
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		sprite  = data.blip_sprite
		color   = data.blip_color

		SetBlipSprite (blipCoord, sprite)
		SetBlipColour (blipCoord, color)
	end, PlayerData.gang.name)
	SetBlipDisplay(blipCoord, 4)
	SetBlipScale  (blipCoord, 1.2)
	SetBlipAsShortRange(blipCoord, true)
	Wait(5000)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(PlayerData.gang.name)
	EndTextCommandSetBlipName(blipCoord)

	-- Craft
	local blipCraft = AddBlipForCoord(2359.81, 3119.87)
	table.insert(allBlip, blipCraft)
	SetBlipSprite (blipCraft, 150)
	SetBlipColour (blipCraft, 47)
	SetBlipDisplay(blipCraft, 4)
	SetBlipScale  (blipCraft, 1.2)
	SetBlipAsShortRange(blipCraft, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('GunSazi')
	EndTextCommandSetBlipName(blipCraft)
end

AddEventHandler('gangprop:hasEnteredMarker', function(station, part)
	if part == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {station = station}
	end

	if part == 'Armory' then
		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	end

	if part == 'VehicleSpawner' then
		CurrentAction     = 'menu_vehicle_spawner'
		CurrentActionMsg  = _U('vehicle_spawner')
		CurrentActionData = {station = station}
	end

	if part == 'VehicleDeleter' then
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)
		if IsPedInAnyVehicle(playerPed,  false) then
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if DoesEntityExist(vehicle) then
				CurrentAction     = 'delete_vehicle'
				CurrentActionMsg  = _U('store_vehicle')
				CurrentActionData = {vehicle = vehicle, station = station}
			end
		end
	end

	if part == 'HelicopterSpawner' then
		CurrentAction     = 'heli_spawner'
		CurrentActionMsg  = _U('vehicle_spawner')
		CurrentActionData = {station = station}
	end

	if part == 'HelicopterDeleter' then
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)
		if IsPedInAnyVehicle(playerPed,  false) then
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if DoesEntityExist(vehicle) then
				CurrentAction     = 'delete_heli'
				CurrentActionMsg  = _U('store_vehicle')
				CurrentActionData = {vehicle = vehicle, station = station}
			end
		end
	end

	if part == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {station = station}
	end
end)

AddEventHandler('gangprop:hasExitedMarker', function(station, part)
	BR.UI.Menu.CloseAll()
	CurrentAction = nil
end)

-- Display markers
Citzen.CreateThread(function()
	while true do
		Wait(0)
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)
		local canSleep = true
		if Data.locker ~= nil then
			if GetDistanceBetweenCoords(coords,  Data.locker.x,  Data.locker.y,  Data.locker.z,  true) < Config.DrawDistance then
				canSleep = false
				DrawMarker(31, Data.locker.x,  Data.locker.y,  Data.locker.z+0.9, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
			end
		end

		if Data.armory ~= nil then
			if GetDistanceBetweenCoords(coords,  Data.armory.x,  Data.armory.y,  Data.armory.z,  true) < Config.DrawDistance then
				canSleep = false
				DrawMarker(42, Data.armory.x,  Data.armory.y,  Data.armory.z+0.8, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
			end
		end

		if Data.veh ~= nil then
			if GetDistanceBetweenCoords(coords,  Data.veh.x,  Data.veh.y,  Data.veh.z,  true) < Config.DrawDistance then
				canSleep = false
				DrawMarker(36, Data.veh.x,  Data.veh.y,  Data.veh.z+0.9, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
			end
		end

		if Data.vehdel ~= nil then
			if GetDistanceBetweenCoords(coords,   Data.vehdel.x,  Data.vehdel.y,  Data.vehdel.z,  true) < Config.DrawDistance then
				canSleep = false
				DrawMarker(Config.MarkerType, Data.vehdel.x,  Data.vehdel.y,  Data.vehdel.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x+1, Config.MarkerSize.y+1, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
			end
		end

		if Data.helicopter == 1 then
			if Data.heli ~= nil then
				if GetDistanceBetweenCoords(coords,  Data.heli.x,  Data.heli.y,  Data.heli.z,  true) < Config.DrawDistance then
					canSleep = false
					DrawMarker(34, Data.heli.x,  Data.heli.y,  Data.heli.z+0.9, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
				end
			end

			if Data.helidel ~= nil then
				if GetDistanceBetweenCoords(coords,   Data.helidel.x,  Data.helidel.y,  Data.helidel.z,  true) < Config.DrawDistance then
					canSleep = false
					DrawMarker(Config.MarkerType, Data.helidel.x,  Data.helidel.y,  Data.helidel.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x+3, Config.MarkerSize.y+3, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
				end
			end
		end

		if Data.boss ~= nil then
			if GetDistanceBetweenCoords(coords,  Data.boss.x,  Data.boss.y,  Data.boss.z,  true) < Config.DrawDistance then
				canSleep = false
				DrawMarker(22, Data.boss.x,  Data.boss.y,  Data.boss.z+1.1, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
			end
		end
		if canSleep then
			Citzen.Wait(500)
		end
	end
end)

-- Enter / Exit marker events
Citzen.CreateThread(function()
	while true do
		Wait(0)

		if PlayerData.gang ~= nil and PlayerData.gang ~= 'nogang' then
			local playerPed      = PlayerPedId()
			local coords         = GetEntityCoords(playerPed)
			local isInMarker     = false
			local currentStation = nil
			local currentPart    = nil
			local canSleep = true

			if Data.locker ~= nil then
				if GetDistanceBetweenCoords(coords,  Data.locker.x,  Data.locker.y,  Data.locker.z,  true) < Config.MarkerSize.x then
					canSleep = false
					isInMarker     = true
					currentStation = Data.gang_name
					currentPart    = 'Cloakroom'
				end
			end

			if Data.armory ~= nil then
				if GetDistanceBetweenCoords(coords,  Data.armory.x,  Data.armory.y,  Data.armory.z,  true) < Config.MarkerSize.x then
					canSleep = false
					isInMarker     = true
					currentStation = Data.gang_name
					currentPart    = 'Armory'
				end
			end

			if Data.veh ~= nil then
				if GetDistanceBetweenCoords(coords,  Data.veh.x,  Data.veh.y,  Data.veh.z,  true) < Config.MarkerSize.x then
					canSleep = false
					isInMarker     = true
					currentStation = Data.gang_name
					currentPart    = 'VehicleSpawner'
				end
			end

			if Data.vehspawn ~= nil then
				if GetDistanceBetweenCoords(coords,  Data.vehspawn.x,  Data.vehspawn.y,  Data.vehspawn.z,  true) < Config.MarkerSize.x then
					canSleep = false
					isInMarker     = true
					currentStation = Data.gang_name
					currentPart    = 'VehicleSpawnPoint'
				end
			end

			if Data.vehdel ~= nil then
				if GetDistanceBetweenCoords(coords,  Data.vehdel.x,  Data.vehdel.y,  Data.vehdel.z,  true) < Config.MarkerSize.x+1.0 then
					canSleep = false
					isInMarker     = true
					currentStation = Data.gang_name
					currentPart    = 'VehicleDeleter'
				end
			end

			if Data.helicopter == 1 then
				if Data.heli ~= nil then
					if GetDistanceBetweenCoords(coords,  Data.heli.x,  Data.heli.y,  Data.heli.z,  true) < Config.MarkerSize.x then
						canSleep = false
						isInMarker     = true
						currentStation = Data.gang_name
						currentPart    = 'HelicopterSpawner'
					end
				end

				if Data.helidel ~= nil then
					if GetDistanceBetweenCoords(coords,  Data.helidel.x,  Data.helidel.y,  Data.helidel.z,  true) < 4.0 then
						canSleep = false
						isInMarker     = true
						currentStation = Data.gang_name
						currentPart    = 'HelicopterDeleter'
					end
				end
			end

			if Data.boss ~= nil and PlayerData.gang ~= nil and PlayerData.gang.grade == 6 then
				if GetDistanceBetweenCoords(coords,   Data.boss.x,  Data.boss.y,  Data.boss.z,  true) < Config.MarkerSize.x then
					canSleep = false
					isInMarker     = true
					currentStation = Data.gang_name
					currentPart    = 'BossActions' 
				end
			end

			local hasExited = false
	
			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart)) then
				if (LastStation ~= nil and LastPart ~= nil) and (LastStation ~= currentStation or LastPart ~= currentPart) then
					TriggerEvent('gangprop:hasExitedMarker', LastStation, LastPart)
					hasExited = true
				end
				HasAlreadyEnteredMarker = true
				LastStation             = currentStation
				LastPart                = currentPart
				TriggerEvent('gangprop:hasEnteredMarker', currentStation, currentPart)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('gangprop:hasExitedMarker', LastStation, LastPart)
			end
			if canSleep then
				Citzen.Wait(500)
			end
		else
			Citzen.Wait(500)
		end
	end
end)


-- Key Controls
Citzen.CreateThread(function()
	while true do
		Citzen.Wait(0)
		if CurrentAction ~= nil then
			SetTextComponentFormat('STRING')
			AddTextComponentString(CurrentActionMsg)
			DisplayHelpTextFromStringLabel(0, 0, 1, -1)

			if IsControlPressed(0, 38) and PlayerData.gang ~= nil and PlayerData.gang.name == CurrentActionData.station and (GetGameTimer() - GUI.Time) > 150 then
				if CurrentAction == 'menu_cloakroom' then
					OpenCloakroomMenu()
				elseif CurrentAction == 'menu_armory' then
					OpenArmoryMenu(CurrentActionData.station)
				elseif CurrentAction == 'menu_vehicle_spawner' then
					if PlayerData.gang.grade >= Data.garage_access then
						ListOwnedCarsMenu()
					else
						BR.ShowNotification('Rank Shoma Ejaze Baz Kardan Garage Ra Nadarad')
					end
				elseif CurrentAction == 'heli_spawner' then
					if Data.helicopter == 1 then
						if PlayerData.gang.grade >= Data.heli_access then
							OpenHeliMenu()
						else
							BR.ShowNotification('Rank Shoma Ejaze Spawn Helicopter Ra Nadarad')
						end
					else
						BR.ShowNotification('Gang Shoma Helicopter Nadarad')
					end
				elseif CurrentAction == 'delete_heli' then
					local ped = PlayerPedId()
					if IsPedInAnyVehicle(ped) then
						TriggerEvent("mythic_progbar:client:progress", {
							name = "gang_heli_repair",
							duration = 900,
							label = "Dar hale tamir kardan helicopter",
							useWhileDead = false,
							canCancel = true,
							controlDisables = {
								disableMovement = true,
								disableCarMovement = true,
								disableMouse = false,
								disableCombat = true
							}
						}, function(status)
							if not status then
								local vehicle = GetVehiclePedIsUsing(ped)
								local model = GetEntityModel(vehicle)
								SetVehiceleFixed(vehicle)
								SetVehicleDirtLevel(vehicle, 0.0)
								BR.Game.DeleteVehicele(vehicle)
							end
						end)
					else
						BR.ShowNotification("Shoma savar hich helicopteri nistid!")
					end
				elseif CurrentAction == 'delete_vehicle' then
					StoreOwnedCarsMenu()
				elseif CurrentAction == 'menu_boss_actions' then
					BR.UI.Menu.CloseAll()
					TriggerEvent('gangs:openBossMenu', CurrentActionData.station, function(data, menu)
						menu.close()
						CurrentAction     = 'menu_boss_actions'
						CurrentActionMsg  = _U('open_bossmenu')
						CurrentActionData = {}
					end)
				end
				CurrentAction = nil
				GUI.Time      = GetGameTimer()
			end
		else
			Citzen.Wait(500)
		end
	end
end)

function StoreOwnedCarsMenu()
	local playerPed    = PlayerPedId()
	local coords       = GetEntityCoords(playerPed)
	local vehicle      = CurrentActionData.vehicle
	local vehicleProps = BR.Game.GetVehicleProperties(vehicle)
	local engineHealth = GetVehicleEngineHealth(vehicle)
	local plate        = vehicleProps.plate

	BR.TriggerServerCallback('brt_advancedgarage:storeVehicle', function(valid)
		if valid then
			--[[if engineHealth < 990 then
			  local apprasial = math.floor((1000 - engineHealth)/1000*1000*5)
			  reparation(apprasial, vehicle, vehicleProps)
			else
			  putaway(vehicle, vehicleProps)
			end	--]]
			  putaway(vehicle, vehicleProps)
		else
			BR.ShowNotification('In VasileNaghlie Baraye Gang Shoma Nist')
		end
	end, vehicleProps)
end

-- Repair Vehicles
function reparation(apprasial, vehicle, vehicleProps)
	  BR.UI.Menu.CloseAll()

	  local elements = {
		{label = 'Park kardane mashin va Pardakhte: ' .. ' ($'.. tonumber(apprasial)/2 .. ')', value = 'yes'},
		{label = 'Tamas Ba mechanic', value = 'no'}
	  }
	
	  BR.UI.Menu.Open('default', GetCurrentResourceName(), 'delete_menu', {
		title    = 'Mashine shoma Zarbe Khorde',
		align    = 'top-right',
		elements = elements
	  }, function(data, menu)
			menu.close()
			if data.current.value == 'yes' then
				  BR.TriggerServerCallback('brt_advancedgarage:checkRepairCost', function(hasEnoughMoney)
						if hasEnoughMoney then
					TriggerServerEvent('brt_advancedgarage:payhealth', tonumber(apprasial)/2)
					putaway(vehicle, vehicleProps)
						else
							  BR.ShowNotification('Shoma Poole Kafi nadarid')
						end
				  end, tonumber(apprasial))
			elseif data.current.value == 'no' then
				  BR.ShowNotification('Darkhaste Mechanic')
			end
	  end, function(data, menu)
			menu.close()
	  end)
end

-- Put Away Vehicles
function putaway(vehicle, vehicleProps)
	BR.Game.DeleteVehicele(vehicle)
	TriggerServerEvent('brt_advancedgarage:setVehicleState', vehicleProps.plate, true)
	BR.ShowNotification('Mashin dar Garage Park shod')
end

RegisterNetEvent("setArmorHandler")
AddEventHandler("setArmorHandler",function()
	local ped = PlayerPedId()
	SetArmour(ped, tonumber(Data.bulletproof)) 

	--[[TriggerEvent('skinchanger:getSkin', function(skin)
	  if skin.sex == 0 then
		local clothesSkin = {
		  ['bproof_1'] = 4,  ['bproof_2'] = 1,
		}
		TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
	  elseif skin.sex == 1 then
		local clothesSkin = {
		  ['bproof_1'] = 3,  ['bproof_2'] = 1,
		}
		TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
	  end
	end)--]]
end)

--[[RegisterNetEvent('gangaccount:setMoney')
AddEventHandler('gangaccount:setMoney', function(gang, money)
	if PlayerData.gang and PlayerData.gang.grade == 6 and 'gang_' .. PlayerData.gang.name == gang then
		UpdateSocietyMoneyHUDElement(money)
	end
end)--]]

RegisterNetEvent('gangs:inv')
AddEventHandler('gangs:inv', function(gang)
	BR.UI.Menu.CloseAll()
	BR.UI.Menu.Open('question', GetCurrentResourceName(), 'Aks_For_Join', {
		title 	 = 'Invite Az Taraf Gang',
		align    = 'center',
		question = 'Aya Shoma Mikhahid Vared Gang ('.. gang ..') Beshid?',
		elements = {
			{label = 'Bale', value = 'yes'},
			{label = 'Kheir', value = 'no'},
		}
	}, function(data, menu)
		if data.current.value == 'yes' then
			TriggerServerEvent("gangs:acceptinv")
			BR.UI.Menu.CloseAll()		
		elseif data.current.value == 'no' then
			menu.close()
            BR.UI.Menu.CloseAll()													
		end
	end)
end)

function OpenBossMenu(gang, close, options)
	local isBoss = nil
	local options  = options or {}
	local elements = {}
	local gangMoney = nil

	BR.TriggerServerCallback('gangs:getGangData', function(gangsdata)
		BR.TriggerServerCallback('gangs:isBoss', function(result)
			isBoss = result
		end, gang)

		while isBoss == nil do
			Citzen.Wait(100)
		end

		if not isBoss then
			return
		end

		while gangMoney == nil do
			Citzen.Wait(1)
			BR.TriggerServerCallback('gangs:getGangMoney', function(money)
				gangMoney = money
			end, PlayerData.gang.name)
		end

		local defaultOptions = {
			withdraw   = true,
			deposit    = true,
			wash       = false,
			employees  = true,
			grades     = true,
			gradesname = true,
			garage     = true,
			armory     = true,
			vest       = true,
			logo       = true,
			invite     = true,
			logpower   = true,
			blip       = true,
			gps_color  = true,
			blip_color = true,
			vehbuy     = true,
			heli       = true,
			craft      = true,
			lockpick   = true
		}

		for k,v in pairs(defaultOptions) do
			if options[k] == nil then
				options[k] = v
			end
		end

		if options.withdraw then
			local formattedMoney = _U('locale_currency', BR.Math.GroupDigits(gangMoney))
			table.insert(elements, {label = ('%s: <span style="color:green;">%s</span>'):format("Bodje", formattedMoney), value = 'withdraw_society_money'})
		end

		if options.employees then
			table.insert(elements, {label = "Modiriyat MemberHa", value = 'manage_employees'})
		end

		if options.grades then
			table.insert(elements, {label = "Modiriyat Hoghogh", value = 'manage_grades'})
		end
		
		if options.gradesname then
			if gangsdata.rank >= 2 then
				table.insert(elements, {label = "✔️ Taghir Esm Rank Ha", value = 'manage_gradesname'})
			else
				table.insert(elements, {label = "❌ Taghir Esm Rank Ha", value = 'manage_gradesname'})
			end
		end
		
		if options.garage then
			if gangsdata.rank >= 3 then
				table.insert(elements, {label = "✔️ Rank Dastresi Garage", value = 'manage_garage'})
			else
				table.insert(elements, {label = "❌ Rank Dastresi Garage", value = 'manage_garage'})
			end
		end
		
		if options.armory then
			if gangsdata.rank >= 4 then
				table.insert(elements, {label = "✔️ Rank Dastresi Armory", value = 'manage_armory'})
			else
				table.insert(elements, {label = "❌ Rank Dastresi Armory", value = 'manage_armory'})
			end
		end

		if options.craft then
			if gangsdata.rank >= 1 then
				table.insert(elements, {label = "✔️ Rank Dastresi Craft Aslahe", value = 'manage_craft'})
			else
				table.insert(elements, {label = "❌ Rank Dastresi Craft Aslahe", value = 'manage_craft'})
			end
		end
		
		if options.vest then
			if gangsdata.rank >= 4 then
				table.insert(elements, {label = "✔️ Rank Dastresi Vest", value = 'manage_vest'})
			else
				table.insert(elements, {label = "❌ Rank Dastresi Vest", value = 'manage_vest'})
			end
		end

		if options.vehbuy then
			if gangsdata.rank >= 7 then
				table.insert(elements, {label = "✔️ Rank Dastresi Kharid Mashin", value = 'manage_vehbuy'})
			else
				table.insert(elements, {label = "❌ Rank Dastresi Kharid Mashin", value = 'manage_vehbuy'})
			end
		end

		if options.heli then
			if gangsdata.rank >= 6 then
				table.insert(elements, {label = "✔️ Rank Dastresi Helicopter", value = 'manage_heli'})
			else
				table.insert(elements, {label = "❌ Rank Dastresi Helicopter", value = 'manage_heli'})
			end
		end
		
		if options.invite then
			if gangsdata.rank >= 10 then
				table.insert(elements, {label = "✔️ Rank Dastresi Invite", value = 'manage_invite'})
			else
				table.insert(elements, {label = "❌ Rank Dastresi Invite", value = 'manage_invite'})
			end
		end

		if options.lockpick then
			if gangsdata.rank >= 9 then
				table.insert(elements, {label = "✔️ Rank Dastresi LockPick", value = 'manage_lockpick'})
			else
				table.insert(elements, {label = "❌ Rank Dastresi LockPick", value = 'manage_lockpick'})
			end
		end

		if options.logpower then
			if BR.GetPlayerData()['CanGangLog'] == 1 or gangsdata.rank >= 5 then
				table.insert(elements, {label = "✔️ Set Webhook Log", value = 'set_webhook'})
			else
				table.insert(elements, {label = "❌ Set Webhook Log", value = 'set_webhook'})
			end
		end

		if options.blip then
			if gangsdata.rank >= 5 then
				table.insert(elements, {label = "✔️ Set Kardan Tarh Blip (Map)", value = 'set_blip'})
			else
				table.insert(elements, {label = "❌ Set Kardan Tarh Blip (Map)", value = 'set_blip'})
			end
		end

		if options.blip_color then
			if gangsdata.rank >= 6 then
				table.insert(elements, {label = "✔️ Set Kardan Rang Blip", value = 'set_blip_color'})
			else
				table.insert(elements, {label = "❌ Set Kardan Rang Blip", value = 'set_blip_color'})
			end
		end

		if options.gps_color then
			if gangsdata.rank >= 8 then
				table.insert(elements, {label = "✔️ Set Kardan Rang GPS", value = 'set_gps_color'})
			else
				table.insert(elements, {label = "❌ Set Kardan Rang GPS", value = 'set_gps_color'})
			end
		end
		
		if options.logo then
			if gangsdata.rank >= 10 then
				table.insert(elements, {label = "✔️ Set Kardan Logo Gang", value = 'set_logo'})
			else
				table.insert(elements, {label = "❌ Set Kardan Logo Gang", value = 'set_logo'})
			end
		end

		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'boss_actions_' .. gang, {
			title    = _U('boss_menu'),
			align    = 'top-right',
			elements = elements
		}, function(data, menu)
				if data.current.value == 'withdraw_society_money' then
					OpenMoneyMenu(gang)
				elseif data.current.value == 'manage_employees' then
					OpenManageEmployeesMenu(gang)
				elseif data.current.value == 'manage_grades' then
					OpenManageGradesMenu(gang)
				elseif data.current.value == 'manage_gradesname' then
					if gangsdata.rank >= 2 then
						OpenRenameGrade() -- Version Jadid
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Esm Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~2 ~s~ Beresanid")
					end
				elseif data.current.value == 'manage_garage' then
					if gangsdata.rank >= 3 then
						OpenGarageAccess(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank Garage Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~3 ~s~ Beresanid")
					end
				elseif data.current.value == 'manage_lockpick' then
					if gangsdata.rank >= 9 then
						OpenLockPickAccess(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank LockPick Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~9 ~s~ Beresanid")
					end
				elseif data.current.value == 'manage_armory' then
					if gangsdata.rank >= 4 then
						OpenArmoryAccess(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank Armory Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~4 ~s~ Beresanid")
					end
				elseif data.current.value == 'manage_craft' then
					if gangsdata.rank >= 1 then
						OpenCraftAccess(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank Armory Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~4 ~s~ Beresanid")
					end
				elseif data.current.value == 'manage_vest' then
					if gangsdata.rank >= 4 then
						OpenVestAccess(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank Vest Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~4 ~s~ Beresanid")
					end
				elseif data.current.value == 'set_webhook' then
					if BR.GetPlayerData()['CanGangLog'] == 1 or gangsdata.rank >= 5 then
						SetWebhook(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Log Nadarad, Jahat Kharid Be Shop Morajee Konid Ya Be Rank 5 Beresid")
					end
				elseif data.current.value == 'manage_heli' then
					if gangsdata.rank >= 6 then
						OpenHeliAccess(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank Heli Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~6 ~s~ Beresanid")
					end
				elseif data.current.value == 'manage_vehbuy' then
					if gangsdata.rank >= 7 then
						OpenVehBuyAccess(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank Kharid Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~7 ~s~ Beresanid")
					end
				elseif data.current.value == 'set_blip' then
					if gangsdata.rank >= 5 then
						SetBlip(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Blip Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~5 ~s~ Beresanid")
					end
				elseif data.current.value == 'set_blip_color' then
					if gangsdata.rank >= 6 then
						SetBlipColor(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank Blip Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~6 ~s~ Beresanid")
					end
				elseif data.current.value == 'set_gps_color' then
					if gangsdata.rank >= 8 then
						SetGpsColor(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank GPS Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~8 ~s~ Beresanid")
					end
				elseif data.current.value == 'set_logo' then
					if gangsdata.rank >= 10 then
						SetLogo(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Logo Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~10 ~s~ Beresanid")
					end
				elseif data.current.value == 'manage_invite' then
					if gangsdata.rank >= 10 then
						OpenInviteAccess(gang)
					else
						BR.ShowNotification("Gang Shoma Ghabeliyat Taghir Rank Invite Nadarad, Jahat Daryaft Rank Gang Khod Ra Be ~g~10 ~s~ Beresanid")
					end
				end
		end, function(data, menu)
			if close then
				close(data, menu)
			end
		end)
	end, PlayerData.gang.name)
end

function OpenRenameGrade()
	BR.TriggerServerCallback('gang:getGrades', function(grades)
		  local elements = {}
		  
			for k,v in pairs(grades) do
				table.insert(elements, {label = '(' .. k .. ') | ' .. v.label, grade = k})
			end

		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'show_grade_list', {
			title    = 'Gang Grades',
			align    = 'top-right',
			elements = elements
		}, function(data, menu)

			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'rename_grade', {
                title    = "Esm jadid rank ra vared konid",

			}, function(data2, menu2)
				
				if not data2.value then
					BR.ShowNotification("Shoma dar ghesmat esm jadid chizi vared nakardid!")
					return
				end
	
				if data2.value:match("[^%w%s]") or data2.value:match("%d") then
					BR.ShowNotification("~h~Shoma mojaz be vared kardan ~r~Special ~o~character ~w~ya ~r~adad ~w~nistid!")
					return
				end

				if string.len(BR.Math.Trim(data2.value)) >= 3 and string.len(BR.Math.Trim(data2.value)) <= 11 then
					BR.TriggerServerCallback('gangs:renameGrade', function(refresh)
						menu2.close()
						if refresh then
							menu.close()
							OpenRenameGrade()
						end
					end, data.current.grade, data2.value)
				else
					BR.ShowNotification("Tedad character esm grade bayad bishtar az ~g~3 ~w~0 va kamtar az ~g~11 ~o~character ~w~bashad!")
				end

            end, function (data2, menu2)
                menu2.close()
            end)
			
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenGarageAccess(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_garage_' .. gangname, {
		title    = "Rank Dastresi Be Garage",
		align    = 'top-right',
		elements = {
			   {label = "Rank Dastresi Alan: " .. data.garage_access .. " | Baraye Taghir Feshar Dahid", value = data.garage_access}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_garage_amount_' .. gangname, {
			   title = "Ranki Ke Mikhayd Dastresi Be Garage Az Oon Be Bad Bashad Ra Vared Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
			   	elseif amount > 6 then
				   	BR.ShowNotification("Rank Vared Shode Az Tedad Rank Haye Gang Bishtar Ast")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						OpenGarageAccess(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'garage')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function OpenLockPickAccess(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_lockpick_' .. gangname, {
		title    = "Rank Dastresi LockPick Mashin",
		align    = 'top-right',
		elements = {
			   {label = "Rank Dastresi Alan: " .. data.lockpick_access .. " | Baraye Taghir Feshar Dahid", value = data.lockpick_access}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_lockpick_amount_' .. gangname, {
			   title = "Ranki Ke Mikhayd Dastresi LockPick Az Oon Be Bad Bashad Ra Vared Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
			   	elseif amount > 6 then
				   	BR.ShowNotification("Rank Vared Shode Az Tedad Rank Haye Gang Bishtar Ast")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						OpenLockPickAccesss(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'lockpick')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function OpenArmoryAccess(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_armory_' .. gangname, {
		title    = "Rank Dastresi Be Armory",
		align    = 'top-right',
		elements = {
			   {label = "Rank Dastresi Alan: " .. data.armory_access .. " | Baraye Taghir Feshar Dahid", value = data.armory_access}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_armory_amount_' .. gangname, {
			   title = "Ranki Ke Mikhayd Dastresi Be Armory Az Oon Be Bad Bashad Ra Vared Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
			   	elseif amount > 6 then
				   	BR.ShowNotification("Rank Vared Shode Az Tedad Rank Haye Gang Bishtar Ast")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						OpenArmoryAccess(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'armory')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function OpenCraftAccess(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_craft_' .. gangname, {
		title    = "Rank Dastresi Be Craft Aslahe",
		align    = 'top-right',
		elements = {
			   {label = "Rank Dastresi Alan: " .. data.craft_access .. " | Baraye Taghir Feshar Dahid", value = data.craft_access}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_craft_amount_' .. gangname, {
			   title = "Ranki Ke Mikhayd Dastresi Craft Aslahe Az Oon Be Bad Bashad Ra Vared Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
			   	elseif amount > 6 then
				   	BR.ShowNotification("Rank Vared Shode Az Tedad Rank Haye Gang Bishtar Ast")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						OpenCraftAccess(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'craft')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function OpenVestAccess(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_vest_' .. gangname, {
		title    = "Rank Dastresi Be Vest",
		align    = 'top-right',
		elements = {
			   {label = "Rank Dastresi Alan: " .. data.vest_access .. " | Baraye Taghir Feshar Dahid", value = data.vest_access}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_vest_amount_' .. gangname, {
			   title = "Ranki Ke Mikhayd Dastresi Be Vest Az Oon Be Bad Bashad Ra Vared Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
			   	elseif amount > 6 then
				   	BR.ShowNotification("Rank Vared Shode Az Tedad Rank Haye Gang Bishtar Ast")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						OpenArmoryAccess(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'vest')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function SetWebhook(gangname)
	BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'set_log', {
        title    = "Link Web Hook Ra Vared Konid",

	}, function(data2, menu2)
				
	if not data2.value then
		BR.ShowNotification("Shoma Linki Vared Nakardid!")
		return
	end
	local link = data2.value
	if link:find('discord') then
		BR.TriggerServerCallback('gangs:setGangAccess', function()
			BR.ShowNotification("Web Hook Ba Movafaghiat Sabt Shod!")
		end, gangname, link, 'webhook')
		menu2.close()
	else
		BR.ShowNotification("Link Vared Shode Baraye Discord Nist")
		return
	end
    end, function (data2, menu2)
        menu2.close()
    end)
end

function OpenHeliAccess(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_heli_' .. gangname, {
		title    = "Rank Dastresi Be Helicopter",
		align    = 'top-right',
		elements = {
			   {label = "Rank Dastresi Alan: " .. data.heli_access .. " | Baraye Taghir Feshar Dahid", value = data.heli_access}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_heli_amount_' .. gangname, {
			   title = "Ranki Ke Mikhayd Dastresi Be Helicopter Az Oon Be Bad Bashad Ra Vared Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
			   	elseif amount > 6 then
				   	BR.ShowNotification("Rank Vared Shode Az Tedad Rank Haye Gang Bishtar Ast")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						OpenHeliAccess(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'heli')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function OpenVehBuyAccess(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_buy_' .. gangname, {
		title    = "Rank Dastresi Kharid Mashin",
		align    = 'top-right',
		elements = {
			   {label = "Rank Dastresi Alan: " .. data.buy_access .. " | Baraye Taghir Feshar Dahid", value = data.buy_access}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_buy_amount_' .. gangname, {
			   title = "Ranki Ke Mikhayd Dastresi Kharid Mashin Az Oon Be Bad Bashad Ra Vared Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
			   	elseif amount > 6 then
				   	BR.ShowNotification("Rank Vared Shode Az Tedad Rank Haye Gang Bishtar Ast")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						OpenVehBuyAccess(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'vehbuy')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function SetBlip(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'set_blip_sprite_' .. gangname, {
		title    = "Taghir Tarh Blip Map",
		align    = 'top-right',
		elements = {
			{label = "Tarh Alan: " .. data.blip_sprite .. " | Baraye Taghir Feshar Dahid", value = data.blip_sprite}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_heli_amount_' .. gangname, {
			   title = "Jahat Didan List Blip Ha Bakhsh Amoozesh Discord Server Ra Moshahede Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
				elseif amount > 670 then
					BR.ShowNotification("Kolan 669 Ta Blip Darim :||")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						SetBlip(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'blip_sprite')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function SetBlipColor(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'set_blip_color_' .. gangname, {
		title    = "Taghir Rang Blip",
		align    = 'top-right',
		elements = {
			{label = "Rang Blip Alan: " .. data.blip_color .. " | Baraye Taghir Feshar Dahid", value = data.blip_color}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'set_blip_color_amount_' .. gangname, {
			   title = "Jahat Didan List Rang Ha Bakhsh Amoozesh Discord Server Ra Moshahede Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
				elseif amount > 86 then
					BR.ShowNotification("Kolan 85 Ta Rang Darim :||")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						SetBlipColor(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'blip_color')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function SetGpsColor(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'set_gps_' .. gangname, {
		title    = "Taghir Rang GPS",
		align    = 'top-right',
		elements = {
			{label = "Rang GPS Alan: " .. data.gps_color .. " | Baraye Taghir Feshar Dahid", value = data.gps_color}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'set_gps_amount_' .. gangname, {
			   title = "Jahat Didan List Rang Ha Bakhsh Amoozesh Discord Server Ra Moshahede Konid"
		    }, function(data2, menu2)
				
				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
				elseif amount > 86 then
					BR.ShowNotification("Kolan 85 Ta Rang Darim :||")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						SetGpsColor(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'gps_color')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function SetLogo(gangname)
	BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'set_logo', {
        title    = "Link Axs Ra Vared Konid",
	}, function(data2, menu2)
		if not data2.value then
			BR.ShowNotification("Shoma Chizi Vared Nakardid!")
			return
		end
		local link = data2.value
		if link:find('http') then
		BR.TriggerServerCallback('gangs:setGangAccess', function()
			BR.ShowNotification("Web Hook Ba Movafaghiat Sabt Shod!")
		end, gangname, link, 'logo')
		menu2.close()
		 else
		  	BR.ShowNotification("Link Vared Shode Eshtebah Ast!")
			return
		end
    end, function (data2, menu2)
        menu2.close()
    end)
end

function OpenInviteAccess(gangname)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_invite_' .. gangname, {
		title    = "Rank Dastresi Be Menu Invite",
		align    = 'top-right',
		elements = {
			   {label = "Rank Dastresi Alan: " .. data.invite_access .. " | Baraye Taghir Feshar Dahid", value = data.invite_access}
		}
		}, function(data, menu)
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_invite_amount_' .. gangname, {
			   title = "Ranki Ke Mikhayd Dastresi Menu Invite Az Oon Be Bad Bashad Ra Vared Konid"
		    }, function(data2, menu2)

				local amount = tonumber(data2.value)
				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
			   	elseif amount > 6 then
				   	BR.ShowNotification("Rank Vared Shode Az Tedad Rank Haye Gang Bishtar Ast")
			   	else
				   	menu2.close()
					BR.TriggerServerCallback('gangs:setGangAccess', function()
						OpenInviteAccess(gangname)
						BR.ShowNotification("Taghirat Ba Movafaghiyat Anjam Shod")
					end, gangname, amount, 'invite')
			   	end
			end, function(data2, menu2)
				menu2.close()
		   	end)
		end, function(data, menu)
			menu.close()
		end)
	end, gangname)
end

function OpenManageEmployeesMenu(gang)
	BR.TriggerServerCallback('gangs:getEmployees', function(employees)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
	
	local tedadmember = 0
	for i=1, #employees, 1 do
		tedadmember = tedadmember + 1
	end
	
	local elements = {
		{label = "👪 List MemberHa", value = 'employee_list'},
		{label = "✉️ Invite",       value = 'recruit'},
		{label = "🔍 Slot: " .. tedadmember.."/"..data.slot,       value = 'slotsize'},
		{label = "👔 Vest: " .. data.bulletproof.."%",       value = 'vest'},
		{label = "🚘 Limit Garage: " .. data.garage_limit.." Mashin",  value = 'garagelimit'},
		{label = "📊 XP: " .. data.xp .." - Rank: " .. data.rank, value = 'xp_rank'},
	}
	if data.gps == 1 then
		table.insert(elements, {label = "GPS: ✔️", value = 'y_gps'})
	else
		table.insert(elements, {label = "GPS: ❌", value = 'n_gps'})
	end
	if data.helicopter == 1 then
		table.insert(elements, {label = "Helicopter: ✔️", value = 'y_heli'})
	else
		table.insert(elements, {label = "Helicopter: ❌", value = 'n_heli'})
	end
	if data.craft == 1 then
		table.insert(elements, {label = "Craft: ✔️", value = 'y_craft'})
	else
		table.insert(elements, {label = "Craft: ❌", value = 'n_craft'})
	end
	if data.lockpick == 1 then
		table.insert(elements, {label = "LockPick: ✔️", value = 'y_lockpick'})
	else
		table.insert(elements, {label = "LockPick: ❌", value = 'n_lockpick'})
	end

 	BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_employees_' .. gang, {
		title    = _U('employee_management'),
		align    = 'top-right',
		elements = elements
	}, function(data1, menu)
	
	
 		if data1.current.value == 'employee_list' then
			OpenEmployeeList(gang)
		end
		
 		if data1.current.value == 'recruit' then
			if tedadmember <= data.slot then
				OpenRecruitMenu(gang)
			else
			BR.ShowNotification('Slot Gang Shoma Poor Shode Ast, Jahat Afzayesh Be Shop Server Morajee Konid Ya Rank Up Shid')
			end
		end

 	end, function(data1, menu)
		menu.close()
	end)
	end, gang)
	end, gang)
end

function OpenManageEmployeesMenuF5(gang)
	BR.TriggerServerCallback('gangs:getEmployees', function(employees)
	BR.TriggerServerCallback('gangs:getGangData', function(data)
	
	local tedadmember = 0
	for i=1, #employees, 1 do
		tedadmember = tedadmember + 1
	end

 	BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_employees_f5_' .. gang, {
		title    = _U('employee_management'),
		align    = 'top-right',
		elements = {
			{label = "✉️ Invite",       value = 'recruit'},
			{label = "🔍 Slot: " .. tedadmember.."/"..data.slot,       value = 'slotsize'}
		}
	}, function(data1, menu)
	
		
 		if data1.current.value == 'recruit' then
			if tedadmember <= data.slot then
				OpenRecruitMenu(gang)
			else
				BR.ShowNotification('Slot Gang Shoma Poor Shode Ast, Jahat Afzayesh Be Shop Server Morajee Konid Ya Rank Up Shid')
			end
		end

 	end, function(data1, menu)
		menu.close()
	end)
	end, gang)
	end, gang)
end

function OpenMoneyMenu(gang)

	BR.UI.Menu.Open('default', GetCurrentResourceName(), 'money_manage_' .. gang, {
	   title    = _U('money_management'),
	   align    = 'top-right',
	   elements = {
		   {label = "Bardasht Bodje", 	value = 'withdraw_money'},
		   {label = "Gozashtan Bodje"	,  	value = 'deposit_money'}
	   }
   	}, function(data, menu)

		if data.current.value == 'withdraw_money' then
			
			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'withdraw_society_money_amount_' .. gang, {
				title = _U('withdraw_money')
			}, function(data, menu)

 				local amount = tonumber(data.value)

 				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
				else
					BR.UI.Menu.CloseAll()
					TriggerServerEvent('gangs:withdrawMoney', gang, amount)
					OpenBossMenu(gang, close, options)
				end

 			end, function(data, menu)
				menu.close()
			end)

		elseif data.current.value == 'deposit_money' then

			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'deposit_money_amount_' .. gang, {
				title = _U('deposit_money')
			}, function(data, menu)
 
				 local amount = tonumber(data.value)
 
				 if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
				else
					BR.UI.Menu.CloseAll()
					TriggerServerEvent('gangs:depositMoney', gang, amount)
					OpenBossMenu(gang, close, options)
				end
 
			 end, function(data, menu)
				menu.close()
			end)

	   	end

	end, function(data, menu)
	   menu.close()
   end)
end

function OpenEmployeeList(gang)

 	BR.TriggerServerCallback('gangs:getEmployees', function(employees)

 		local elements = {
			head = {_U('employee'), _U('grade'), _U('actions')},
			rows = {}
		}

 		for i=1, #employees, 1 do
			local gradeLabel = (employees[i].gang.grade_label == '' and employees[i].gang.label or employees[i].gang.grade_label)

 			table.insert(elements.rows, {
				data = employees[i],
				cols = {
					employees[i].name,
					gradeLabel,
					'{{' .. _U('promote') .. '|promote}} {{' .. _U('fire') .. '|fire}}'
				}
			})
		end

 		BR.UI.Menu.Open('list', GetCurrentResourceName(), 'employee_list_' .. gang, elements, function(data, menu)
			local employee = data.data

 			if data.value == 'promote' then
				menu.close()
				OpenPromoteMenu(gang, employee)
			elseif data.value == 'fire' then
				BR.ShowNotification(_U('you_have_fired', employee.name))

 				BR.TriggerServerCallback('gangs:setGang', function()
					OpenEmployeeList(gang)
				end, employee.identifier, 'nogang', 0, 'fire')
			end
		end, function(data, menu)
			menu.close()
			OpenManageEmployeesMenu(gang)
		end)

 	end, gang)

 end

function OpenRecruitMenu(gang)

 	BR.TriggerServerCallback('gangs:getOnlinePlayers', function(players)

 		local elements = {}

 		for i=1, #players, 1 do
			if players[i].gang.name ~= gang then
				table.insert(elements, {
					label = players[i].name,
					value = players[i].source,
					name = players[i].name,
					identifier = players[i].identifier
				})
			end
		end

 		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'recruit_' .. gang, {
			title    = _U('recruiting'),
			align    = 'top-right',
			elements = elements
		}, function(data, menu)

 			BR.UI.Menu.Open('default', GetCurrentResourceName(), 'recruit_confirm_' .. gang, {
				title    = _U('do_you_want_to_recruit', data.current.name),
				align    = 'top-right',
				elements = {
					{label = _U('no'),  value = 'no'},
					{label = _U('yes'), value = 'yes'}
				}
			}, function(data2, menu2)
				menu2.close()

 				if data2.current.value == 'yes' then
					BR.ShowNotification(_U('you_have_hired', data.current.name))

 					BR.TriggerServerCallback('gangs:setGang', function()
						OpenRecruitMenu(gang)
					end, data.current.identifier, gang, 1, 'hire')
				end
			end, function(data2, menu2)
				menu2.close()
			end)

 		end, function(data, menu)
			menu.close()
		end)

 	end)

end

function OpenPromoteMenu(gangname, employee)

 	BR.TriggerServerCallback('gangs:getGang', function(gang)

 		local elements = {}

 		for i=1, #gang.grades, 1 do
			local gradeLabel = (gang.grades[i].label == '' and gang.label or gang.grades[i].label)

 			table.insert(elements, {
				label = gradeLabel,
				value = gang.grades[i].grade,
				selected = (employee.gang.grade == gang.grades[i].grade)
			})
		end

 		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'promote_employee_' .. gangname, {
			title    = _U('promote_employee', employee.name),
			align    = 'top-right',
			elements = elements
		}, function(data, menu)
			menu.close()
			BR.ShowNotification(_U('you_have_promoted', employee.name, data.current.label))

 			BR.TriggerServerCallback('gangs:setGang', function()
				OpenEmployeeList(gangname)
			end, employee.identifier, gangname, data.current.value, 'promote')
		end, function(data, menu)
			menu.close()
			OpenEmployeeList(gangname)
		end)

 	end, gangname)

end


function OpenManageGradesMenu(gangname)

 	BR.TriggerServerCallback('gangs:getGang', function(gang)

 		local elements = {}

 		for i=1, #gang.grades, 1 do
			local gradeLabel = (gang.grades[i].label == '' and gang.label or gang.grades[i].label)

 			table.insert(elements, {
				label = ('%s - <span style="color:green;">%s</span>'):format(gradeLabel, _U('money_generic', BR.Math.GroupDigits(gang.grades[i].salary))),
				value = gang.grades[i].grade
			})
		end

 		BR.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_grades_' .. gang.name, {
			title    = _U('salary_management'),
			align    = 'top-right',
			elements = elements
		}, function(data, menu)

 			BR.UI.Menu.Open('dialog', GetCurrentResourceName(), 'manage_grades_amount_' .. gang.name, {
				title = _U('salary_amount')
			}, function(data2, menu2)

 				local amount = tonumber(data2.value)

 				if amount == nil then
					BR.ShowNotification(_U('invalid_amount'))
				elseif amount > Config.MaxSalary then
					BR.ShowNotification(_U('invalid_amount_max'))
				else
					menu2.close()

 					BR.TriggerServerCallback('gangs:setGangSalary', function()
						OpenManageGradesMenu(gangname)
					end, gang, data.current.value, amount)
				end

 			end, function(data2, menu2)
				menu2.close()
			end)

 		end, function(data, menu)
			menu.close()
		end)

 	end, gangname)

end

AddEventHandler('gangs:openBossMenu', function(gang, close, options)
	OpenBossMenu(gang, close, options)
end)

AddEventHandler('gangs:openInviteF5', function(gang, close, options)
	OpenManageEmployeesMenuF5(gang)
end)