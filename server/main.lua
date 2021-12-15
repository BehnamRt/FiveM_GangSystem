BR = nil
local Gangs = {}
local RegisteredGangs = {}
local TempGangs = {}

TriggerEvent('brt:getSharedObject', function(obj) BR = obj end)

function GetGang(gang)
	for i=1, #RegisteredGangs, 1 do
		if RegisteredGangs[i] == gang then
			local gn = {}
			gn.name = gang
			gn.account = 'gang_' .. string.lower(gn.name)
			return gn
		end
	end
end

MySQL.ready(function()
	local result = MySQL.Sync.fetchAll('SELECT name FROM gangs', {})

	for i=1, #result, 1 do
		print('Gang '.. result[i].name .. ' Load Shod')
		Gangs[result[i].name]        	= result[i]
		Gangs[result[i].name].grades 	= {}
		RegisteredGangs[i] 				= result[i].name
		Gangs[result[i].name].vehicles 	= {}
		exports.ghmattimysql:execute('SELECT vehicle FROM owned_vehicles WHERE owner = @owner',{
			['@owner'] = result[i].name
		}, function(vehResult)
			for j=1, #vehResult do
				Gangs[result[i].name].vehicles[j] = json.decode(vehResult[j].vehicle)
			end
		end)
	end

 	local result2 = MySQL.Sync.fetchAll('SELECT * FROM gang_grades', {})

 	for i=1, #result2, 1 do
		Gangs[result2[i].gang_name].grades[tonumber(result2[i].grade)] = result2[i]
	end
	
	local data = MySQL.Sync.fetchAll('SELECT gang_name, webhook, logpower, invite_access FROM gangs_data', {})
	for i=1, #data, 1 do
		Gangs[data[i].gang_name].webhook = data[i].webhook
		Gangs[data[i].gang_name].logpower = data[i].logpower
		Gangs[data[i].gang_name].invite_access = data[i].invite_access
	end
end)

RegisterServerEvent('gangs:acceptinv')
AddEventHandler('gangs:acceptinv', function()
	local xPlayer = BR.GetPlayerFromId(source)
	xPlayer.setGang(xPlayer.get('ganginv'), 1)

	if Gangs[xPlayer.get('ganginv')].logpower ~= 0 then
		sendtodiscord(Gangs[xPlayer.get('ganginv')].webhook,'BR '..xPlayer.get('ganginv')..' Logger', 'Join Member', 'Esm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
	end
end)

AddEventHandler('gangs:registerGang', function(source, name, expire)
 	if not IsGangRegistered(name) then
		table.insert(TempGangs, {gang = name, expire = expire})
		TriggerClientEvent('brt:showNotification', source, gang)
	else
		TriggerClientEvent('brt:showNotification', source, 'This Gang Created Before!')
	end
end)

AddEventHandler('gangs:IsGangRegistered', function(gang, cb)
	cb(IsGangRegistered(gang))
end)

function IsGangRegistered(gang)
	for i=1, #RegisteredGangs, 1 do
		if string.lower(RegisteredGangs[i]) == string.lower(gang) then
			return true
		end
	end
	return false
end

AddEventHandler('gangs:saveGangs', function(source)
	for j=1, #TempGangs, 1 do
		table.insert(RegisteredGangs, TempGangs[j].gang)

		Gangs[TempGangs[j].gang] 			   = {}
		Gangs[TempGangs[j].gang].label         = 'gang'
		Gangs[TempGangs[j].gang].name      	   = TempGangs[j].gang
		Gangs[TempGangs[j].gang].grades 	   = {}
		Gangs[TempGangs[j].gang].vehicles  	   = {}
		Gangs[TempGangs[j].gang].logpower 	   = 1
		Gangs[TempGangs[j].gang].invite_access = 6

		TriggerEvent('brt_addoninventory:addGang', 	GetGang(TempGangs[j].gang).account)
		TriggerEvent('brt_datastore:addGang', 		GetGang(TempGangs[j].gang).account)
		
		local ranks = {'Thug','Hustler','Soldier','Trigger','Street Boss','Kingpin'}
		
		TriggerEvent('es_extended:addGang', TempGangs[j].gang, ranks)
		TriggerEvent('gangaccount:addGang', TempGangs[j].gang)

		MySQL.Async.execute('INSERT INTO `gangs` (`name`, `label`) VALUES (@name, @label)', {
			['@name'] 		= TempGangs[j].gang,
			['@label']    = 'gang',
		}, function(e)
		--log here
		end)
		for i=1, 6, 1 do
			Gangs[TempGangs[j].gang].grades[i] 				= {}
			Gangs[TempGangs[j].gang].grades[i].gang_name 	= TempGangs[j].gang
			Gangs[TempGangs[j].gang].grades[i].grade 		= i
			Gangs[TempGangs[j].gang].grades[i].name 		= 'Rank' .. i
			Gangs[TempGangs[j].gang].grades[i].label 		= ranks[i]
			Gangs[TempGangs[j].gang].grades[i].salary 		= 100 * i
			Gangs[TempGangs[j].gang].grades[i].skin_male 	= '[]'
			Gangs[TempGangs[j].gang].grades[i].skin_female 	= '[]'


			MySQL.Async.execute('INSERT INTO `gang_grades` (`gang_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (@gang_name, @grade, @name, @label, @salary, @skin_male, @skin_female)', {
				['@gang_name'] 	 = TempGangs[j].gang,
				['@grade']    	 = i,
				['@name'] 		 = 'Rank '..i,
				['@label']       = ranks[i],
				['@salary'] 	 = 100*i,
				['@skin_male']   = '[]',
				['@skin_female'] = '[]',
			}, function(e)
			--log here
			end)
		end
		MySQL.Async.execute('INSERT INTO `gang_account` (`name`, `label`, `shared`) VALUES (@name, @label, @shared)', {
			['@name'] 	  = 'gang_'..string.lower(TempGangs[j].gang),
			['@label']    = 'gang',
			['@shared']   = 1,
		}, function(e)
		--log here
		end)
		MySQL.Async.execute('INSERT INTO `gang_account_data` (`gang_name`, `money`, `dirty_money`, `owner`) VALUES (@gang_name, @money, @dirty_money, @owner)', {
			['@gang_name'] 	 = 'gang_'..string.lower(TempGangs[j].gang),
			['@money']    	 = 0,
			['@dirty_money'] = 0,
			['@owner']   	 = nil,
		}, function(e)
		--log here
		end)
		MySQL.Async.execute('INSERT INTO `datastore_data` (`name`, `owner`, `data`) VALUES (@name, @owner, @data)', {
			['@name'] 		= 'gang_'..string.lower(TempGangs[j].gang),
			['@owner']   	= nil,
			['@data'] 		= '[]'
		}, function(e)
		--log here
		end)
		MySQL.Async.execute('INSERT INTO `datastore` (`name`, `label`, `shared`) VALUES (@name, @label, @shared)', {
			['@name'] 		= 'gang_'..string.lower(TempGangs[j].gang),
			['@label']    	= 'gang',
			['@shared']   	= 1
		}, function(e)
		--log here
		end)
		MySQL.Async.execute('INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES (@name, @label, @shared)', {
			['@name'] 		= 'gang_'..string.lower(TempGangs[j].gang),
			['@label']    	= 'gang',
			['@shared']   	= 1
		}, function(e)
		--log here
		end)
		MySQL.Async.execute('INSERT INTO `gangs_data` (`gang_name`, `vehicles`, `vehprop`, `expire_time`) VALUES (@gang_name, @vehicles, @vehprop, (NOW() + INTERVAL @time DAY))', {
			['@gang_name'] 		= TempGangs[j].gang,
			['@vehicles']		= '[]',
			['@vehprop']		= '[]',
			['@time']			= TempGangs[j].expire
		}, function(e)
		--log here
		end)
		
		TriggerClientEvent('brt:showNotification', source, 'You Added ' .. TempGangs[j].gang .. ' Gang!')
	end
	TempGangs = {}
end)

AddEventHandler('gangs:changeGangData', function(name, data, pos, source)
	local gang = name
	local data = data

	if data == 'blip' then
		blip(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'armory' then
		armory(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'locker' then
		locker(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'boss' then
		boss(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'veh' then
		veh(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'vehdel' then
		vehdel(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'vehspawn' then
		vehspawn(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'heli' then
		heli(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'helidel' then
		helidel(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'helispawn' then
		helispawn(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'helicopter' then
		helicopter(name,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma Helicopter Gang '..gang..' '..callback..' Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
	    end)
	elseif data == 'helimodel1' then
		helimodel1(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma Model Helicopter Aval Gang '.. gang .. ' Be '..callback..' Taghir Dadid!')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'helimodel2' then
		helimodel2(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma Model Helicopter Dovom Gang '.. gang .. ' Be '..callback..' Taghir Dadid!')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'removeheli' then
		heliremove(name, pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma Model Helicopter '.. callback .. ' Gang '.. gang ..' Hazf Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'expire' then
		expire(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma '..data..' Gang '..gang..' Set Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'search' then
		search(name,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma Search Gang '.. gang .. ' '.. callback ..' Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'bulletproof' then
		bulletproof(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma %'.. callback .. ' Armor Be Gang '..gang..' Dadid!')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'gps' then
		gangsblip2(name,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma GPS Gang '..gang..' '..callback..' Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
	    end)
	elseif data == 'log' then
		tlog(name,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', _source, 'Shoma Ghabeliyat Log Gang '.. gang .. ' '..callback..' Kardid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'slot' then
		slot(name,pos,function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma Slot Gang '.. gang .. ' Be '..callback..' Taghir Dadid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(gang, GangMember.gang.grade)
					end
				end
			end
		end)
	elseif data == 'name' then
		name(name, pos, function(callback)
			if callback then
				TriggerClientEvent('brt:showNotification', source, 'Shoma Esm Gang '.. gang .. ' Be '..callback..' Taghir Dadid')
				local aPlayers = BR.GetPlayers()
				for i=1, #aPlayers, 1 do
					local GangMember = BR.GetPlayerFromId(aPlayers[i])
					if GangMember.gang.name == gang then
						GangMember.setGang(callback, GangMember.gang.grade)
					end
				end
			end
		end)
	end
	
end)

function blip(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET blip = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function armory(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET armory = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function locker(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET locker = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function boss(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET boss = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function veh(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET veh = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function vehdel(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET vehdel = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function vehspawn(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET vehspawn = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function heli(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET heli = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function helidel(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET helidel = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function helispawn(gang, pos, callback)
	MySQL.Async.execute('UPDATE gangs_data SET helispawn = @pos WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@pos']  			= json.encode(pos)
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function helicopter(gang, cb)
	exports.ghmattimysql:scalar("SELECT helicopter FROM gangs_data WHERE gang_name = @gang_name",{
		["gang_name"] = gang
	}, function(result)
		if tonumber(result) == 1 then
			exports.ghmattimysql:execute("UPDATE gangs_data SET helicopter = 0 WHERE gang_name = @gang_name",{
				["@gang_name"]	= gang
			})
		cb("GheyrFaal")
		else
			exports.ghmattimysql:execute("UPDATE gangs_data SET helicopter = 1 WHERE gang_name = @gang_name",{
				["@gang_name"]	= gang
			})
		cb("Faal")
		end
	end)
end

function helimodel1(gang, model, cb)
	exports.ghmattimysql:execute("UPDATE gangs_data SET heli_model1 = @model WHERE gang_name = @gang_name",{
		["@gang_name"]	= gang,
		["@model"]= model
	})
	cb(model)
end

function helimodel2(gang, model, cb)
	exports.ghmattimysql:execute("UPDATE gangs_data SET heli_model2 = @model WHERE gang_name = @gang_name",{
		["@gang_name"]	= gang,
		["@model"]= model
	})
	cb(model)
end

function heliremove(gang, model, cb)
	if tonumber(model) == 1 then
		exports.ghmattimysql:execute("UPDATE gangs_data SET heli_model1 = NULL WHERE gang_name = @gang_name",{
			["@gang_name"]	= gang
		})
		cb("Aval")
	elseif tonumber(model) == 2 then
		exports.ghmattimysql:execute("UPDATE gangs_data SET heli_model2 = NULL WHERE gang_name = @gang_name",{
			["@gang_name"]	= gang
		})
		cb("Dovom")
	end
end

function expire(gang, time, callback)
	MySQL.Async.execute('UPDATE gangs_data SET expire_time = (NOW() + INTERVAL @time DAY) WHERE gang_name = @gang_name', {
		['@gang_name']      = gang,
		['@time']			= time
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function search(gang, cb)
	exports.ghmattimysql:scalar("SELECT search FROM gangs_data WHERE gang_name = @gang_name",{
		["gang_name"] = gang
	}, function(result)
		if result then
			exports.ghmattimysql:execute("UPDATE gangs_data SET search = FALSE WHERE gang_name = @gang_name",{
				["@gang_name"]	= gang
			})
			cb("GheyrFaal")
		else
			exports.ghmattimysql:execute("UPDATE gangs_data SET search = TRUE WHERE gang_name = @gang_name",{
				["@gang_name"]	= gang
			})
			cb("Faal")
		end
	end)
end

function bulletproof(gang, value, cb)
	exports.ghmattimysql:execute("UPDATE gangs_data SET bulletproof = @bulletproof WHERE gang_name = @gang_name",{
		["@gang_name"]	= gang,
		["@bulletproof"]= value
	})
	cb(value)
end

function tlog(gang, cb)
	exports.ghmattimysql:scalar("SELECT logpower FROM gangs_data WHERE gang_name = @gang_name",{
		["gang_name"] = gang
	}, function(result)
		if tonumber(result) == 1 then
			exports.ghmattimysql:execute("UPDATE gangs_data SET logpower = 0 WHERE gang_name = @gang_name",{
				["@gang_name"]	= gang
			})
			Gangs[gang].logpower = 0
			cb("GheyrFaal")
		else
			exports.ghmattimysql:execute("UPDATE gangs_data SET logpower = 1 WHERE gang_name = @gang_name",{
				["@gang_name"]	= gang
			})
			Gangs[gang].logpower = 1
			cb("Faal")
		end
	end)
end

function gangsblip2(gang, cb)
	exports.ghmattimysql:scalar("SELECT gps FROM gangs_data WHERE gang_name = @gang_name",{
		["gang_name"] = gang
	}, function(result)
		if tonumber(result) == 1 then
			exports.ghmattimysql:execute("UPDATE gangs_data SET gps = 0 WHERE gang_name = @gang_name",{
				["@gang_name"]	= gang
			})
			cb("GheyrFaal")
		else
			exports.ghmattimysql:execute("UPDATE gangs_data SET gps = 1 WHERE gang_name = @gang_name",{
				["@gang_name"]	= gang
			})
			cb("Faal")
		end
	end)
end


function slot(gang, slot, cb)
	exports.ghmattimysql:execute("UPDATE gangs_data SET slot = @slot WHERE gang_name = @gang_name",{
		["@gang_name"]	= gang,
		["@slot"]= slot
	})
	cb(slot)
end

function name(gang, jadid, cb)
	--[[MySQL.Async.execute('UPDATE gangs_data SET xp = @xp, rank = @rank WHERE gang_name = @gang', {
        ['@gang'] = GangName,
        ['@xp'] = CurrentXP,
        ['@rank'] = CurrentRank
    }, function(result)
        local xPlayers, xPlayer = BR.GetPlayers(), nil
		for i=1, #xPlayers, 1 do
			xPlayer = BR.GetPlayerFromId(xPlayers[i])
			if xPlayer.gang.name == GangName then
                TriggerClientEvent("brt_gangxp:update", xPlayers[i], CurrentXP, CurrentRank)
			end
		end
    end)
	cb(slot)--]]
end


AddEventHandler('gangs:getGangs', function(cb)
	cb(RegisteredSocieties)
end)

AddEventHandler('gangs:getGang', function(name, cb)
	cb(GetGang(name))
end)

RegisterServerEvent('gangs:withdrawMoney')
AddEventHandler('gangs:withdrawMoney', function(gangName, amount)
	local xPlayer = BR.GetPlayerFromId(source)
	local gang = GetGang(gangName)
	amount = BR.Math.Round(tonumber(amount))

 	if xPlayer.gang.name ~= gang.name then
		print(('gangs: %s attempted to call withdrawMoney!'):format(xPlayer.identifier))
		return
	end

 	TriggerEvent('gangaccount:getGangAccount', gang.account, function(account)
		if amount > 0 and account.money >= amount then
			account.removeMoney(amount)
			xPlayer.addMoney(amount)
			TriggerClientEvent('brt:showNotification', xPlayer.source, _U('have_withdrawn', BR.Math.GroupDigits(amount)))

			bardashtArray = {
					{
						["color"] = "5020550",
						["title"] = "Bardasht Bodje",
						["description"] = "Player: **"..xPlayer.name.."**\nZaman: **"..os.date('%Y-%m-%d %H:%M:%S').."**",
						["fields"] = {
							{
								["name"] = "Meghdar: ",
								["value"] = "**"..BR.Math.GroupDigits(amount).."$**"
							},
							{
								["name"] = "Gang: ",
								["value"] = "**"..gangName.."**"
							}
						},
						["footer"] = {
						["text"] = "BR Log System",
						["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
						}
					}
				}
			TriggerEvent('brt_bot:SendLog', 'gangs', SystemName, bardashtArray, 'system', source, false, false)
	
			if Gangs[xPlayer.gang.name].logpower ~= 0 then
				sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gangName..' Logger','> Bardasht Bodje','Meghdar : '.. BR.Math.GroupDigits(amount) .. '$\nEsm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
			end
		else
			TriggerClientEvent('brt:showNotification', xPlayer.source, _U('invalid_amount'))
		end
	end)
end)

RegisterServerEvent('gangs:depositMoney')
AddEventHandler('gangs:depositMoney', function(gang, amount)
	local xPlayer = BR.GetPlayerFromId(source)
	local gang = GetGang(gang)
	amount = BR.Math.Round(tonumber(amount))

 	if xPlayer.gang.name ~= gang.name then
		print(('gangs: %s attempted to call depositMoney!'):format(xPlayer.identifier))
		return
	end

 	if amount > 0 and xPlayer.money >= amount then
		TriggerEvent('gangaccount:getGangAccount', gang.account, function(account)
			xPlayer.removeMoney(amount)
			account.addMoney(amount)
		end)
 		TriggerClientEvent('brt:showNotification', xPlayer.source, _U('have_deposited', BR.Math.GroupDigits(amount)))

		gozashtanArray = {
					{
						["color"] = "5020550",
						["title"] = "Gozashtan Bodje",
						["description"] = "Player: **"..xPlayer.name.."**\nZaman: **"..os.date('%Y-%m-%d %H:%M:%S').."**",
						["fields"] = {
							{
								["name"] = "Meghdar: ",
								["value"] = "**"..BR.Math.GroupDigits(amount).."$**"
							},
							{
								["name"] = "Gang: ",
								["value"] = "**"..gang.name.."**"
							}
						},
						["footer"] = {
						["text"] = "BR Log System",
						["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
						}
					}
				}
		TriggerEvent('brt_bot:SendLog', 'gangs', SystemName, gozashtanArray, 'system', source, false, false)
			
		if Gangs[xPlayer.gang.name].logpower ~= 0 then
				sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang.name..' Logger','> Gozashtan Bodje','Meghdar : '.. BR.Math.GroupDigits(amount) .. '$\nEsm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
			end
	else
		TriggerClientEvent('brt:showNotification', xPlayer.source, _U('invalid_amount'))
	end
end)

RegisterServerEvent('gangs:saveOutfit')
AddEventHandler('gangs:saveOutfit', function(grade, skin)
	local xPlayer = BR.GetPlayerFromId(source)
	
	if skin.sex == 0 then
		TriggerEvent('ChangeGangSkin', xPlayer.gang.name, grade, true, skin)
		exports.ghmattimysql:execute('UPDATE gang_grades SET skin_male = @skin WHERE (gang_name = @gang AND grade = @grade)',{
			['skin']  = json.encode(skin),
			['gang']  = xPlayer.gang.name,
			['grade'] = grade
		})
	else
		TriggerEvent('ChangeGangSkin', xPlayer.gang.name, grade, false, skin)
		exports.ghmattimysql:execute('UPDATE gang_grades SET skin_female = @skin WHERE (gang_name = @gang AND grade = @grade)',{
			['skin']  = json.encode(skin),
			['gang']  = xPlayer.gang.name,
			['grade'] = grade
		})
	end
end)

BR.RegisterServerCallback('gangs:getGangData', function(source, cb, gang)
	if BR.DoesGangExist(gang,6) then
		MySQL.Async.fetchAll(
			'SELECT * FROM gangs_data WHERE gang_name = @gang_name AND `expire_time` > NOW()',
			{
				['@gang_name'] = gang
			},
			function(data)
				cb(data[1])
			end
		)
	else
		cb(nil)
	end

end)

BR.RegisterServerCallback('gangs:getGangMoney', function(source, cb, gang)
	local gang = GetGang(gang)

 	if gang then
		TriggerEvent('gangaccount:getGangAccount', gang.account, function(account)
			cb(account.money)
		end)
	else
		cb(0)
	end
end)

BR.RegisterServerCallback('gangs:getGangInventory', function(source, cb)
	local xPlayer    = BR.GetPlayerFromId(source)
	local gangaccount = GetGang(xPlayer.gang.name)
	local dirty_money = 0
	local items      = {}
	local weapons    = {}

	TriggerEvent('gangaccount:getGangAccount', gangaccount.account, function(account)
		dirty_money = account.dirty_money
	end)

	TriggerEvent('brt_addoninventory:getSharedInventory', gangaccount.account, function(inventory)
		items = inventory.items
	end)

	TriggerEvent('brt_datastore:getSharedDataStore', gangaccount.account, function(store)
		weapons = store.get('weapons') or {}
	end)

	cb({
		dirty_money = dirty_money,
		items      = items,
		weapons    = weapons
	})
end)

RegisterServerEvent('gangs:getFromInventory')
AddEventHandler('gangs:getFromInventory', function(type, item, count)
	local _source      = source
	local xPlayer      = BR.GetPlayerFromId(_source)
	local gangaccount  = GetGang(xPlayer.gang.name)

	if type == 'item_standard' then

		local sourceItem = xPlayer.getInventoryItem(item)

		TriggerEvent('brt_addoninventory:getSharedInventory', gangaccount.account, function(inventory)
			local inventoryItem = inventory.getItem(item)

			if count > 0 and inventoryItem.count >= count then
			
				if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
					TriggerClientEvent('brt:showNotification', _source, _U('player_cannot_hold'))
				else
					inventory.removeItem(item, count)
					xPlayer.addInventoryItem(item, count)
					TriggerClientEvent('brt:showNotification', _source, _U('have_withdrawn', count, inventoryItem.label))

					bardashtArray = {
					{
						["color"] = "5020550",
						["title"] = "Bardasht Item",
						["description"] = "Player: **"..xPlayer.name.."**\nZaman: **"..os.date('%Y-%m-%d %H:%M:%S').."**",
						["fields"] = {
							{
								["name"] = "Item: ",
								["value"] = "**"..inventoryItem.label.."**"
							},
							{
								["name"] = "Meghdar: ",
								["value"] = "**"..count.."**"
							},
							{
								["name"] = "Gang: ",
								["value"] = "**"..gangaccount.name.."**"
							}
						},
						["footer"] = {
						["text"] = "BR Log System",
						["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
						}
					}
				}
			TriggerEvent('brt_bot:SendLog', 'gangs', SystemName, bardashtArray, 'system', source, false, false)
					
					if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gangaccount.name..' Logger','> Bardasht Item','Item : '..item..'('..count..')\nEsm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
					end
				end
			else
				TriggerClientEvent('brt:showNotification', _source, _U('not_enough_in_property'))
			end
		end)

	elseif type == 'item_dirty_money' then

			TriggerEvent('gangaccount:getGangAccount', gangaccount.account, function(account)
		
						if account.dirty_money >= count then
						account.removeDirty_Money(count)
						xPlayer.addDirty_Money(count)
	
						getdirtyArray = {
							{
								["color"] = "5020550",
								["title"] = "> Bardasht Pool Kasif Az Gang",
								["description"] = "Esm Player: **"..xPlayer.name.."**\nZaman: **"..os.date('%Y-%m-%d %H:%M:%S').."**",
								["fields"] = {
									{
										["name"] = "Meghdar: ",
										["value"] = "**"..count.."$**"
									},
									{
										["name"] = "Gang: ",
										["value"] = "**"..gangaccount.name.."**"
									}
								},
								["footer"] = {
								["text"] = "BR Log System",
								["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
								}
							}
						}
					TriggerEvent('brt_bot:SendLog', 'gangs', SystemName, getdirtyArray, 'system', source, false, false)
						
						if Gangs[xPlayer.gang.name].logpower ~= 0 then
						sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gangaccount.name..' Logger','> Bardasht Pool Kasif','Meghdar: $' ..count..'\nEsm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
						end
				else
					TriggerClientEvent('brt:showNotification', _source, _U('not_enough_in_property'))
				end
			end)

	elseif type == 'item_weapon' then
		if not xPlayer.hasWeapon(item) then
			TriggerEvent('brt_datastore:getSharedDataStore', gangaccount.account, function(store)
				local storeWeapons = store.get('weapons') or {}
				local weaponName   = nil
				local ammo         = 0
				local tint         = 0
				local comps        = {}
				for i=1, #storeWeapons, 1 do
					if storeWeapons[i].name == item then
						weaponName = storeWeapons[i].name
						ammo       = storeWeapons[i].ammo
						tint       = storeWeapons[i].tintIndex
						comps      = storeWeapons[i].components
						table.remove(storeWeapons, i)
						break
					end
				end

				store.set('weapons', storeWeapons)
				xPlayer.addWeapon(weaponName, ammo)
				SetTimeout(3500, function()
					xPlayer.setWeaponTint(weaponName, tint)
					for k,v in ipairs(comps) do
					  	xPlayer.addWeaponComponent(weaponName, v)
					end
				end)
				bardashtgArray = {
					{
						["color"] = "5020550",
						["title"] = "Bardasht Aslahe",
						["description"] = "Player: **"..xPlayer.name.."**\nZaman: **"..os.date('%Y-%m-%d %H:%M:%S').."**",
						["fields"] = {
							{
								["name"] = "Aslahe: ",
								["value"] = "**"..weaponName.."**"
							},
							{
								["name"] = "Tir: ",
								["value"] = "**"..ammo.."**"
							},
							{
								["name"] = "Gang: ",
								["value"] = "**"..gangaccount.name.."**"
							}
						},
						["footer"] = {
						["text"] = "BR Log System",
						["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
						}
					}
				}
			TriggerEvent('brt_bot:SendLog', 'gangs', SystemName, bardashtgArray, 'system', source, false, false)
			
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
				sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gangaccount.name..' Logger','> Bardasht Aslahe','Gun : '..weaponName..'('..ammo..')\nEsm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
				end
				Wait(3000)
				xPlayer.setWeaponTint(weaponName, tint)
				for k,v in ipairs(comps) do
					xPlayer.addWeaponComponent(weaponName, v)
				end
			end)
		else
			TriggerClientEvent('brt:showNotification', _source, 'Shoma Dar hale Hazer in Aslahe ro darid')			
		end

	end

end)

RegisterServerEvent('gangs:addToInventory')
AddEventHandler('gangs:addToInventory', function(type, item, count)
	local _source      = source
	local xPlayer      = BR.GetPlayerFromId(_source)
	local gangaccount  = GetGang(xPlayer.gang.name)

	if type == 'item_standard' then

		local playerItemCount = xPlayer.getInventoryItem(item).count

		if playerItemCount >= count and count > 0 then
			TriggerEvent('brt_addoninventory:getSharedInventory', gangaccount.account, function(inventory)
				xPlayer.removeInventoryItem(item, count)
				inventory.addItem(item, count)
				TriggerClientEvent('brt:showNotification', _source, 'Shoma '..count..' ta '.. inventory.getItem(item).label .. ' Dakhel Gang Gozashtid')
	
				gozashtanArray = {
					{
						["color"] = "5020550",
						["title"] = "Gozashtan Item",
						["description"] = "Player: **"..xPlayer.name.."**\nZaman: **"..os.date('%Y-%m-%d %H:%M:%S').."**",
						["fields"] = {
							{
								["name"] = "Item: ",
								["value"] = "**"..inventory.getItem(item).label.."**"
							},
							{
								["name"] = "Meghdar: ",
								["value"] = "**"..count.."**"
							},
							{
								["name"] = "Gang: ",
								["value"] = "**"..gangaccount.name.."**"
							}
						},
						["footer"] = {
						["text"] = "BR Log System",
						["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
						}
					}
				}
			TriggerEvent('brt_bot:SendLog', 'gangs', SystemName, gozashtanArray, 'system', source, false, false)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
				sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gangaccount.name..' Logger','> Gozashtan Item','Item : '..item..'('..count..')\nEsm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
				end
			end)
		else
			TriggerClientEvent('brt:showNotification', _source, _U('invalid_quantity'))
		end

	elseif type == 'item_dirty_money' then

		if xPlayer.dirty_money >= count and count > 0 then
				xPlayer.removeDirty_Money(count)
	
					TriggerEvent('gangaccount:getGangAccount', gangaccount.account, function(account)
					account.addDirty_Money(count)
				end)
						putdirtyArray = {
							{
								["color"] = "5020550",
								["title"] = "> Gozashtan Pool Kasif Dar Gang",
								["description"] = "Esm Player: **"..xPlayer.name.."**\nZaman: **"..os.date('%Y-%m-%d %H:%M:%S').."**",
								["fields"] = {
									{
										["name"] = "Meghdar: ",
										["value"] = "**"..count.."$**"
									},
									{
										["name"] = "Gang: ",
										["value"] = "**"..gangaccount.name.."**"
									}
								},
								["footer"] = {
								["text"] = "BR Log System",
								["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
								}
							}
						}
					TriggerEvent('brt_bot:SendLog', 'gangs', SystemName, putdirtyArray, 'system', source, false, false)
						
						if Gangs[xPlayer.gang.name].logpower ~= 0 then
						sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gangaccount.name..' Logger','> Gozashtan Pool Kasif','Meghdar: $' ..count..'\nEsm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
						end
				else
					TriggerClientEvent('brt:showNotification', _source, _U('invalid_quantity'))
				end

	elseif type == 'item_weapon' then
		if xPlayer.hasWeapon(item) then
			TriggerEvent('brt_datastore:getSharedDataStore', gangaccount.account, function(store)
				local storeWeapons = store.get('weapons') or {}
				local _, weapon = xPlayer.getWeapon(item)
				local comps = {}
				for k, component in ipairs(weapon.components) do
					if component ~= 'clip_default' then
						table.insert(comps, component)
					end
				end
				table.insert(storeWeapons, {
					name = item,
					ammo = weapon.ammo,
					tintIndex = weapon.tintIndex,
					components = comps
				})

				store.set('weapons', storeWeapons)
				xPlayer.removeWeapon(item)
	
				gozashtangArray = {
					{
						["color"] = "5020550",
						["title"] = "Gozashtan Aslahe",
						["description"] = "Player: **"..xPlayer.name.."**\nZaman: **"..os.date('%Y-%m-%d %H:%M:%S').."**",
						["fields"] = {
							{
								["name"] = "Aslahe: ",
								["value"] = "**"..item.."**"
							},
							{
								["name"] = "Tir: ",
								["value"] = "**"..weapon.ammo.."**"
							},
							{
								["name"] = "Gang: ",
								["value"] = "**"..gangaccount.name.."**"
							}
						},
						["footer"] = {
						["text"] = "BR Log System",
						["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
						}
					}
				}
			TriggerEvent('brt_bot:SendLog', 'gangs', SystemName, gozashtangArray, 'system', source, false, false)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
                sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gangaccount.name..' Logger','> Gozashtan Aslahe','Gun : '..item..'('..weapon.ammo..')\nEsm IC Player : '..xPlayer.name .. '\nEsm OOC Player : '.. GetPlayerName(xPlayer.source))
				end
			end)
		end
	end
end)

RegisterNetEvent('gangs:buy')
AddEventHandler('gangs:buy', function(weaponName, station)
	local _source = source
	local xPlayer = BR.GetPlayerFromId(_source)
	local gang = GetGang(station)
	local price = Config.SellableWeapon[weaponName]
	if xPlayer.gang.name ~= gang.name then
		print(('gangs: %s attempted to buy!'):format(xPlayer.identifier))
		return
	end

	if xPlayer.money < price then
		TriggerClientEvent('brt:showNotification', xPlayer.source, '~r~Be andaze Kafi Pool nadarid!')
		return
	end

	TriggerEvent('brt_datastore:getSharedDataStore', gang.account, function(store)
		local storeWeapons = store.get('weapons') or {}

		table.insert(storeWeapons, {
			name = weaponName,
			ammo = 255
		})

		store.set('weapons', storeWeapons)
		xPlayer.removeMoney(price)
		TriggerClientEvent('brt:showNotification', xPlayer.source, '~g~Aslahe Ba movafaqiyat be Armory Gang Ezafe shod.')

	end)

end)


BR.RegisterServerCallback('gangs:getEmployees', function(source, cb, gang)
	MySQL.Async.fetchAll('SELECT playerName, identifier, gang, gang_grade FROM users WHERE gang = @gang ORDER BY gang_grade DESC', {
		['@gang'] = gang
	}, function (result)
		local employees = {}

		for i=1, #result, 1 do
			table.insert(employees, {
				name       = result[i].playerName,
				identifier = result[i].identifier,
				gang = {
					name        = result[i].gang,
					label       = Gangs[result[i].gang].label,
					grade       = result[i].gang_grade,
					grade_name  = Gangs[result[i].gang].grades[tonumber(result[i].gang_grade)].name,
					grade_label = Gangs[result[i].gang].grades[tonumber(result[i].gang_grade)].label
				}
			})
		end

		cb(employees)
	end)
end)

BR.RegisterServerCallback('gangs:getGang', function(source, cb, gang)
	local gang    = json.decode(json.encode(Gangs[gang]))
	local grades = {}

 	for k,v in pairs(gang.grades) do
		table.insert(grades, v)
	end

 	table.sort(grades, function(a, b)
		return a.grade < b.grade
	end)

	gang.grades = grades

 	cb(gang)
end)


BR.RegisterServerCallback('gangs:setGang', function(source, cb, identifier, gang, grade, type)
	local xPlayer = BR.GetPlayerFromId(source)
	--local isBoss = xPlayer.gang.grade == 6 
	local isBoss = xPlayer.gang.grade >= Gangs[xPlayer.gang.name].invite_access
	
 	if isBoss then
		local xTarget = BR.GetPlayerFromIdentifier(identifier)

 		if xTarget then
 			if type == 'hire' then
				xTarget.set('ganginv', gang)
				TriggerClientEvent('gangs:inv', xTarget.source, gang)
			elseif type == 'promote' then
				TriggerClientEvent('brt:showNotification', xTarget.source, _U('you_have_been_promoted'))
				xTarget.setGang(gang, grade)
			elseif type == 'fire' then
				TriggerClientEvent('brt:showNotification', xTarget.source, _U('you_have_been_fired', xTarget.gang.label))
				xTarget.setGang(gang, grade)
			end

 			cb()
		else
			MySQL.Async.execute('UPDATE users SET gang = @gang, gang_grade = @gang_grade WHERE identifier = @identifier', {
				['@gang']        = gang,
				['@gang_grade']  = grade,
				['@identifier'] 	 = identifier
			}, function(rowsChanged)
				cb()
			end)
		end
	else
		print(('gangs: %s attempted to setGang'):format(xPlayer.identifier))
		cb()
	end
end)

RegisterCommand("ginvite", function(source, args)
	local xPlayer = BR.GetPlayerFromId(source)
	local isBoss = xPlayer.gang.grade >= Gangs[xPlayer.gang.name].invite_access

	if isBoss then
		if not args[1] then
            TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, " ^0Shoma dar ghesmat ID chizi vared nakardid!")
            return
        end
		if not tonumber(args[1]) then
			TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, " ^0Shoma dar ghesmat ID faghat mitavanid adad vared konid")
			return
		end
		local xTarget = BR.GetPlayerFromId(tonumber(args[1]))

		if xTarget then
			xTarget.set('ganginv', xPlayer.gang.name)
			TriggerClientEvent('gangs:inv', xTarget.source, xPlayer.gang.label)
        else
            TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, " ^0ID vared shode eshtebah ast")
        end
    else
        TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, " ^0Rank Shoma Dastresi Invite Nadarad!")
    end
end, false)

BR.RegisterServerCallback('gangs:setGangSalary', function(source, cb, gang, grade, salary)
	local isBoss = isPlayerBoss(source, gang)
	local identifier = GetPlayerIdentifier(source, 0)

 	if isBoss then
		if salary <= Config.MaxSalary then
			MySQL.Async.execute('UPDATE gang_grades SET salary = @salary WHERE gang_name = @gang_name AND grade = @grade', {
				['@salary']   = salary,
				['@gang_name'] = gang.name,
				['@grade']    = grade
			}, function(rowsChanged)
				Gangs[gang.name].grades[tonumber(grade)].salary = salary
				local xPlayers = BR.GetPlayers()

 				for i=1, #xPlayers, 1 do
					local xPlayer = BR.GetPlayerFromId(xPlayers[i])

 					if xPlayer.gang.name == gang.name and xPlayer.gang.grade == grade then
						xPlayer.setGang(gang, grade)
					end
				end

 				cb()
			end)
		else
			print(('gangs: %s attempted to setGangSalary over config limit!'):format(identifier))
			cb()
		end
	else
		print(('gangs: %s Talash Kard Ta Hoghogh Gang Ra Taghir Dahad'):format(identifier))
		cb()
	end
end)

BR.RegisterServerCallback('gangs:renameGrade', function(source, cb, grade, name)
	local _source, grade, name = source, grade, name
	local xPlayer = BR.GetPlayerFromId(_source)

	if xPlayer.gang.grade == 6 then
		if BR.SetGangGrade(xPlayer.gang.name, grade, name) then
			if Gangs[xPlayer.gang.name] then Gangs[xPlayer.gang.name].grades[grade].label = name end

			local xPlayers = BR.GetPlayers()

			for i=1, #xPlayers, 1 do
				local GangMember = BR.GetPlayerFromId(xPlayers[i])

				if GangMember.gang.name == xPlayer.gang.name and GangMember.gang.grade == grade then
					GangMember.setGang(xPlayer.gang.name, grade)
				end

			end

			cb(true)
		else
			cb(false)
			TriggerClientEvent('chatMessage', -1, "[SYSTEM]", {255, 0, 0}, " ^0Khatayi dar avaz kardan esm gang grade shoma pish amad be developer etelaa dahid!")
		end
	end

end)

BR.RegisterServerCallback('gangs:setGangAccess', function(source, cb, gang, value, name)
	local isBoss = isPlayerBoss(source, gang)
	local xPlayer = BR.GetPlayerFromId(source)

 	if isBoss then
		if name == 'garage' then
			MySQL.Async.execute('UPDATE gangs_data SET garage_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Permission Garage Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'heli' then
			MySQL.Async.execute('UPDATE gangs_data SET heli_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Permission Helicopter Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'lockpick' then
			MySQL.Async.execute('UPDATE gangs_data SET lockpick_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Permission LockPick Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'craft' then
			MySQL.Async.execute('UPDATE gangs_data SET craft_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Permission Sakht Aslahe Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'vehbuy' then
			MySQL.Async.execute('UPDATE gangs_data SET buy_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Permission Kharid Mashin Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'blip_sprite' then
			MySQL.Async.execute('UPDATE gangs_data SET blip_sprite = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Icon Roye Map Gang Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'blip_color' then
			MySQL.Async.execute('UPDATE gangs_data SET blip_color = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Rang Icon Roye Map Gang Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'gps_color' then
			MySQL.Async.execute('UPDATE gangs_data SET gps_color = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Rang GPS Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'logo' then
			MySQL.Async.execute('UPDATE gangs_data SET logo = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Axs Gang Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'invite' then
			MySQL.Async.execute('UPDATE gangs_data SET invite_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				Gangs[xPlayer.gang.name].invite_access = value
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Permission Invite Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'webhook' then
			MySQL.Async.execute('UPDATE gangs_data SET invite_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				Gangs[xPlayer.gang.name].webhook = value
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Web Hook Gang Set Shod','GangLogSys')
				end
				cb()
			end)
		elseif name == 'armory' then
			MySQL.Async.execute('UPDATE gangs_data SET armory_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Permission Garage Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		elseif name == 'vest' then
			MySQL.Async.execute('UPDATE gangs_data SET vest_access = @value WHERE gang_name = @gang_name', {
				['@value'] = value,
				['@gang_name'] = gang
			}, function(rowsChanged)
				if Gangs[xPlayer.gang.name].logpower ~= 0 then
					sendtodiscord(Gangs[xPlayer.gang.name].webhook,'BR '..gang..' Logger','Permission Garage Be '..tostring(value)..' Taghir Kard','GangLogSys')
				end
				cb()
			end)
		end

		local aPlayers = BR.GetPlayers()
		for i=1, #aPlayers, 1 do
			local GangMember = BR.GetPlayerFromId(aPlayers[i])
			if GangMember.gang.name == xPlayer.gang.name then
				GangMember.setGang(xPlayer.gang.name, GangMember.gang.grade)
			end
		end
	end
end)

BR.RegisterServerCallback('gangs:getOnlinePlayers', function(source, cb)
	local xPlayers = BR.GetPlayers()
	local players  = {}

 	for i=1, #xPlayers, 1 do
		local xPlayer = BR.GetPlayerFromId(xPlayers[i])
		table.insert(players, {
			source     = xPlayer.source,
			identifier = xPlayer.identifier,
			name       = xPlayer.name,
			gang       = xPlayer.gang
		})
	end

 	cb(players)
end)

BR.RegisterServerCallback('gangs:getVehiclesInGarage', function(source, cb, gangName)
	cb(Gangs[gangName].vehicles)
end)

BR.RegisterServerCallback('gangs:isBoss', function(source, cb, gang)
	cb(isPlayerBoss(source, gang))
end)

BR.RegisterServerCallback('gang:getGrades', function(source, cb, plate)
	local xPlayer = BR.GetPlayerFromId(source)
	  cb(Gangs[xPlayer.gang.name].grades)
end)

function isPlayerBoss(playerId, gang)
	local xPlayer = BR.GetPlayerFromId(playerId)

 	if xPlayer.gang.label == 'gang' and xPlayer.gang.grade == 6 then
		return true
	else
		print(('gangs: %s attempted open a gang boss menu!'):format(xPlayer.identifier))
		return false
	end
end

function sendtodiscord(hook,footer1,footer2,text)
    local embed = {}
    embed = {
        {
            ["color"] = 65280,
            ["title"] = footer2,
			["fields"] = {
					{
						["name"] = "Etelaat: ",
						["value"] = text
					}
				},
            ["footer"] = {
                ["text"] = "BR Log System",
				["icon_url"] = "https://cdn.discordapp.com/attachments/801538325600403466/802826232797331456/discordicon.png",
            },
        }
    }
    PerformHttpRequest(hook, 
    function(err, text, headers) end, 'POST', json.encode({username = footer1, embeds = embed, avatar_url = 'https://cdn.discordapp.com/attachments/801538325600403466/803958262905962506/645.jpg'}), { ['Content-Type'] = 'application/json' })					
end

BR.RegisterServerCallback('gangprop:getPlayerInventory', function(source, cb)
    local xPlayer = BR.GetPlayerFromId(source)
    local items   = xPlayer.inventory

    cb({
        items = items,
        dirty_money = xPlayer.dirty_money
    })
end)

RegisterServerEvent('gangprop:giveWeapon')
AddEventHandler('gangprop:giveWeapon', function(weapon, ammo)
    local xPlayer = BR.GetPlayerFromId(source)
    xPlayer.addWeapon(weapon, ammo)
end)

RegisterServerEvent("gangprop:setArmor")
AddEventHandler("gangprop:setArmor", function(price)
    local _source = source
    local xPlayer = BR.GetPlayerFromId(source)
    if xPlayer.money >= price then
        xPlayer.removeMoney(price)
        TriggerClientEvent('setArmorHandler', source)
        TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, "^0Shoma Ba Movafaghiat ^2$"..price.." ^0Pardakht Kardid Va ^1Armor ^0Poshidid!")
    elseif xPlayer.bank >= price then
        xPlayer.removeBank(price)
        TriggerClientEvent('setArmorHandler', source)
        TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, "^0Shoma Ba Movafaghiat ^2$"..price.." ^0Pardakht Kardid Va ^1Armor ^0Poshidid!")
    else
        TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, " ^0Shoma Pool Kafi Dar ^2Bank ^0Ya ^2Naghdi ^0Nadarid!")
    end
end)

BR.RegisterServerCallback('gangprop:carAvalible', function(source, cb, plate)
    exports.ghmattimysql:scalar('SELECT `stored` FROM `owned_vehicles` WHERE plate = @plate', {
        ['@plate']  = plate
    }, function(stored)
        cb(stored)
    end)
end)

BR.RegisterServerCallback('gangprop:getCars', function(source, cb)
    local ownedCars = {}
    local xPlayer = BR.GetPlayerFromId(source)

    MySQL.Async.fetchAll('SELECT * FROM `owned_vehicles` WHERE LOWER(owner) = @gang AND type = \'car\' AND @stored = @stored', {
        ['@player']  = xPlayer.identifier,
        ['@gang']    = string.lower(xPlayer.gang.name),
        ['@stored']  = true
    }, function(data)
        for _,v in pairs(data) do
            local vehicle = json.decode(v.vehicle)
            table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
        end
        cb(ownedCars)
    end)
end)