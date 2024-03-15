local cvar_break_prop_replacer = GetConVar('breakprops_change_playerspawn_prop')
local wait_removed_delay = 0
local cvar_sv_rgc_sync_entities = GetConVar('sv_rgc_sync_entities')
local coroutine_wait = coroutine.wait
local coroutine_yield = coroutine.yield
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local pairs = pairs
local ipairs = ipairs
local player_GetAll = player.GetAll
local ents_GetAll = ents.GetAll
local CurTime = CurTime
local IsValid = IsValid
local table_Count = table.Count
local table_Copy = table.Copy
local table_insert = table.insert
local table_remove = table.remove
local isbool = isbool
local ents_Create = ents.Create
local xpcall = xpcall
local istable = istable
local isstring = isstring
local update_delay = 0
local cleanup_map_locked = false
local timer_Simple = timer.Simple
local timer_Create = timer.Create

local function isActiveEntsSync()
	if update_delay > CurTime() then return false end
	return cvar_sv_rgc_sync_entities:GetBool()
end

local function updateEntityNetData(ent, net_ent)
	ent.RgChatNetId = net_ent.net_id
	ent.RgChatOwnerEntIndex = net_ent.ent_index
	ent.RgChatHostSteamId64 =  net_ent.host_steamid64
	ent.RgChatNetData = net_ent
	ent:SetNWString('RgChatNetId', tostring(ent.RgChatNetId))
	ent:SetNWString('RgChatOwnerEntIndex', tostring(ent.RgChatOwnerEntIndex))
end

local function setEntityMotion(ent, motion)
	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) or phys:IsMotionEnabled() == motion then
		return
	end
	phys:EnableMotion(motion)
end

local function getEntityMotion(ent)
	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then return end
	return phys:IsMotionEnabled()
end

local function setEntityUndo(ent, net_ent)
	for _, ply in ipairs(player_GetAll()) do
		if net_ent.owner_steamid64 == ply:SteamID64() then
			ent.RgChatOwner = ply
			undo.Create(string.StartsWith(ent:GetClass(), 'prop_') and 'Prop' or 'Entity')
			undo.AddEntity(ent)
			undo.SetPlayer(ply)
			undo.Finish()
			break
		end
	end
end

local function createNetEntity(net_ent)
	if wait_removed_delay > CurTime() then return end

	local pos = RealGloabalChat:PosStringToVector(net_ent.pos)
	local ang = RealGloabalChat:PosStringToAngle(net_ent.ang)
	if not pos or not ang then return end

	local ent
	xpcall(function()
		ent = ents_Create(net_ent.class_name)
		ent:SetModel(net_ent.model)
	end, function(err)
		print('ERROR: ', err)
		ent = ents_Create('prop_physics')
		ent:SetModel('models/props_junk/TrafficCone001a.mdl')
	end)

	if ent ~= NULL then
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:Spawn()
		setEntityMotion(ent, false)
		updateEntityNetData(ent, net_ent)
		setEntityUndo(ent, net_ent)
	end
end

local function addNewEntitiesUpdate()
	while true do
		local players = player_GetAll()

		for i = #players, 1, -1 do
			local ply = players[i]

			if RealGloabalChat:ModIsActive(ply) then
				if ply.RgChatRemovedEntities and #ply.RgChatRemovedEntities ~= 0 then
					local wait_get_removed = true
					RealGloabalChat:CleanupEntities(ply, ply.RgChatRemovedEntities, function()
						wait_removed_delay = 0
						wait_get_removed = false
					end)
					ply.RgChatRemovedEntities = {}
					while wait_get_removed do
						coroutine_yield()
					end
				end

				if ply.RgChatSpawnedEntities and #ply.RgChatSpawnedEntities ~= 0 then
					local wait_get_entities = true
					local sended_entities = table_Copy(ply.RgChatSpawnedEntities)
					ply.RgChatSpawnedEntities = {}

					RealGloabalChat:AddEntities(ply, sended_entities, function(response)
						wait_get_entities = false

						if response and response.success == 1 then
							for _, net_ent in ipairs(response.entities) do
								for _, sended_ent in ipairs(sended_entities) do
									if IsValid(sended_ent) and sended_ent:EntIndex() == net_ent.ent_index then
										updateEntityNetData(sended_ent, net_ent)
									end
								end
							end
						end
					end)

					while wait_get_entities do
						coroutine_yield()
					end
				end
			else
				if ply.RgChatSpawnedEntities then
					ply.RgChatSpawnedEntities = nil
				end
			end

			coroutine_yield()
		end

		coroutine_wait(1)
	end
end

local function updateEntityOptions(ent, net_ent)
	if ent.RgChatCanUpdateEnt then return end

	for _, ply in ipairs(player_GetAll()) do
		if ent.RgChatHostSteamId64 == ply:SteamID64() then
			if isbool(ent.RgChatLastMotion) then
				setEntityMotion(ent, ent.RgChatLastMotion)
				ent.RgChatLastMotion = nil
			end
			return
		end
	end

	if not isbool(ent.RgChatLastMotion ) then
		ent.RgChatLastMotion = getEntityMotion(ent)
	end

	local pos = RealGloabalChat:PosStringToVector(net_ent.pos)
	if ent:GetPos():DistToSqr(pos) > 25 then
		local ang = RealGloabalChat:PosStringToAngle(net_ent.ang)
		if pos then ent:SetPos(pos) end
		if ang then ent:SetAngles(ang) end
	end

	-- setEntityMotion(ent, net_ent.motion_enabled == 1)
	setEntityMotion(ent, false)
end

local function getEntitiesFromOwnerUpdate()
	while true do
		for _, ply in ipairs(player_GetAll()) do
			local wait_get_entities = true
			local owner_steamid64 = ply:SteamID64()

			local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')
			if rgc_sync_target ~= '' or rgc_sync_target == owner_steamid64 then continue end

			RealGloabalChat:GetEntities(owner_steamid64, function(response)
				wait_get_entities = false
				if not response or response.success == 0 then return end

				local network_entities_count = #response.entities
				if network_entities_count == 0 then return end

				for _, ent in ipairs(ents_GetAll()) do
					if not ent.RgChatNetId then continue end
					local is_valid = false

					for i = network_entities_count, 1, -1 do
						local net_ent = response.entities[i]
						if ent.RgChatNetId == net_ent.net_id then
							updateEntityNetData(ent, net_ent)
							updateEntityOptions(ent, net_ent)
							table_remove(response.entities, i)
							network_entities_count = network_entities_count - 1
							is_valid = true
							break
						end
					end

					if not is_valid then
						SafeRemoveEntity(ent)
					end
				end

				if network_entities_count == 0 then return end

				for _, net_ent in ipairs(response.entities) do
					createNetEntity(net_ent)
				end
			end)

			while wait_get_entities do
				coroutine_yield()
			end

			coroutine_yield()
		end

		coroutine_wait(1)
	end
end

local function entitiesUpdateState()
	while true do
		local valid_entities = {}

		for _, ent in ipairs(ents_GetAll()) do
			if not ent.RgChatNetId or not IsValid(ent.RgChatOwner) then continue end

			local is_external_owner = true
			for _, ply in ipairs(player_GetAll()) do
				if ent.RgChatHostSteamId64 == ply:SteamID64() then
					is_external_owner = false
					break
				end
			end

			if not is_external_owner then
				valid_entities[ent.RgChatOwner] = valid_entities[ent.RgChatOwner] or {}
				table_insert(valid_entities[ent.RgChatOwner], ent)
			end
		end

		if table_Count(valid_entities) == 0 then return end

		for ply, entities in pairs(valid_entities) do
			if IsValid(ply) then
				local wait_get_entities = true
				RealGloabalChat:UpdateEntities(ply, entities, function()
					wait_get_entities = false
				end)

				while wait_get_entities do
					coroutine_yield()
				end
			end
			coroutine_yield()
		end

		coroutine_wait(1)
	end
end

local function getEntitiesUpdate()
	while true do
		local sync_target_list = {}

		for _, ply in ipairs(player_GetAll()) do
			if ply.RgChatRemovedEntities and #ply.RgChatRemovedEntities ~= 0 then continue end
			local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')
			if rgc_sync_target == '' then continue end
			sync_target_list[rgc_sync_target] = true
		end

		for target_steamid64, _ in pairs(sync_target_list) do
			local wait_get_entities = true

			RealGloabalChat:GetEntities(target_steamid64, function(response)
				wait_get_entities = false

				if response and response.success == 1 then
					local network_entities_count = #response.entities
					if network_entities_count == 0 then return end

					for _, ent in ipairs(ents_GetAll()) do
						if not ent.RgChatNetId then continue end
						local is_valid = false
						local net_ent

						for i = network_entities_count, 1, -1 do
							net_ent = response.entities[i]

							if net_ent.net_id == ent.RgChatNetId then
								is_valid = true
								table_remove(response.entities, i)
								network_entities_count = network_entities_count - 1
								break
							end
						end

						if not is_valid then
							SafeRemoveEntity(ent)
						elseif net_ent then
							updateEntityNetData(ent, net_ent)
							updateEntityOptions(ent, net_ent)
						end

						if network_entities_count == 0 then return end
					end

					for _, net_ent in ipairs(response.entities) do
						createNetEntity(net_ent)
					end
				end
			end)

			while wait_get_entities do
				coroutine_yield()
			end

			coroutine_yield()
		end

		coroutine_wait(1)
	end
end

do
	local co

	hook.Add('Think', 'RealGlobalChat.AddNewEntities', function()
		if not isActiveEntsSync() then return end
		if not co or not coroutine_resume(co) then
			co = coroutine_create(addNewEntitiesUpdate)
			coroutine_resume(co)
		end
	end)
end

do
	local co

	hook.Add('Think', 'RealGlobalChat.GetEntities', function()
		if not isActiveEntsSync() then return end
		if wait_removed_delay > CurTime() then return end
		if not co or not coroutine_resume(co) then
			co = coroutine_create(getEntitiesUpdate)
			coroutine_resume(co)
		end
	end)
end

do
	local co

	hook.Add('Think', 'RealGlobalChat.GetEntitiesFromOwner', function()
		if not isActiveEntsSync() then return end
		if wait_removed_delay > CurTime() then return end
		if not co or not coroutine_resume(co) then
			co = coroutine_create(getEntitiesFromOwnerUpdate)
			coroutine_resume(co)
		end
	end)
end

do
	local co

	hook.Add('Think', 'RealGlobalChat.UpdateEntitiesInfo', function()
		if not isActiveEntsSync() then return end
		if wait_removed_delay > CurTime() then return end
		if not co or not coroutine_resume(co) then
			co = coroutine_create(entitiesUpdateState)
			coroutine_resume(co)
		end
	end)
end

hook.Add('RGChat.StopWatchToPlayer', 'RGChatStopSyncProps', function(_, target_id)
	for _, ply in ipairs(player_GetAll()) do
		if ply:SteamID64() == target_id then return end
	end

	for _, ent in ipairs(ents_GetAll()) do
		if ent.RgChatNetId and ent.RgChatNetData.owner_steamid64 == target_id then
			SafeRemoveEntity(ent)
		end
	end
end)

local function spawnedEntityInitParams(ply, data, model)
	if cvar_break_prop_replacer and cvar_break_prop_replacer:GetBool() then
		timer_Simple(.1, function()
			local ent = data.ent

			if not IsValid(ent) and model then
				local entities = ents.FindInSphere(data.pos, 10)
				for _, v in ipairs(entities) do
					if v:GetPos():DistToSqr(v.pos) <= 25 then
						ent = v
						break
					end
				end
			end

			if not IsValid(ent) then return end

			ply.RgChatSpawnedEntities = ply.RgChatSpawnedEntities or {}
			ent.RgChatOwner = ply
			table_insert(ply.RgChatSpawnedEntities, ent)
		end)
	else
		local ent = data.ent
		ply.RgChatSpawnedEntities = ply.RgChatSpawnedEntities or {}
		ent.RgChatOwner = ply
		table_insert(ply.RgChatSpawnedEntities, ent)
	end
end

hook.Add('PlayerSpawnedProp', 'RGChat.EntSyncPlayerSpawnedProp', function(ply, model, ent)
	timer_Simple(0, function()
		if not IsValid(ply) or not IsValid(ent) then return end
		spawnedEntityInitParams(ply, { ent = ent, pos = ent:GetPos() }, model)
	end)
end)

hook.Add('PlayerSpawnedSENT', 'RGChat.EntSyncPlayerSpawnedSENT', function(ply, model, ent)
	timer_Simple(0, function()
		if not IsValid(ply) or not IsValid(ent) then return end
		spawnedEntityInitParams(ply, { ent = ent, pos = ent:GetPos() })
	end)
end)

hook.Add('PlayerSpawnedNPC', 'RGChat.EntSyncPlayerSpawnedNPC', function(ply, ent)
	timer_Simple(0, function()
		if not IsValid(ply) or not IsValid(ent) then return end
		spawnedEntityInitParams(ply, { ent = ent, pos = ent:GetPos() })
	end)
end)

hook.Add('PreCleanupMap', 'RgChat.EntSyncPreCleanupMap', function()
	cleanup_map_locked = true
end)

hook.Add('PostCleanupMap', 'RgChat.EntSyncPostCleanupMap', function()
	local delay = 0
	for _, ply in ipairs(player_GetAll()) do
		timer_Create('RgChatSyncEntsPostCleanupMap.' .. ply:SteamID64(), delay, 1, function()
			if not IsValid(ply) then return end
			ply.RgChatSpawnedEntities = {}
			ply.RgChatRemovedEntities = {}
			RealGloabalChat:CleanupEntities(ply)
		end)
		delay = delay + .1
	end
	update_delay = CurTime() + 1 + delay
	cleanup_map_locked = false
end)

hook.Add('EntityRemoved', 'RgChat.EntSyncEntityRemoved', function(ent)
	if cleanup_map_locked then return end
	if not ent.RgChatNetId then return end
	local ply = ent.RgChatOwner
	if not IsValid(ply) then return end

	if ply.RgChatSpawnedEntities then
		for index, save_ent in ipairs(ply.RgChatSpawnedEntities) do
			if save_ent == ent then
				table_remove(ply.RgChatSpawnedEntities, index)
				break
			end
		end
	end

	if not isActiveEntsSync() then return end

	wait_removed_delay = CurTime() + 2
	ply.RgChatRemovedEntities = ply.RgChatRemovedEntities or {}
	table_insert(ply.RgChatRemovedEntities, { net_id = ent.RgChatNetId })
end)

hook.Add('OnPhysgunPickup', 'RgChat.OnPhysgunPickup', function(ply, ent)
	if not isActiveEntsSync() then return end
	if not ent.RgChatNetId or ent.RgChatNetData.host_steamid64 == ply:SteamID64() then return end

	ent.RgChatCanUpdateEnt = true
	ent.RgChatHostSteamId64 = ply:SteamID64()

	RealGloabalChat:UpdateEntities(ply, { ent }, function(response)
		if not IsValid(ent) then return end
		ent.RgChatCanUpdateEnt = false
		if not response or  response.success == 0 then return end
		if not response.entities or not istable(response.entities) or #response.entities == 0 then return end
		local net_ent = response.entities[1]
		if net_ent and isstring(net_ent.host_steamid64) and net_ent.host_steamid64 ~= ent.RgChatHostSteamId64 then
			ent.RgChatHostSteamId64 = net_ent.host_steamid64
		end
	end)
end)

hook.Add('PhysgunDrop', 'RgChat.PhysgunDrop', function(ply, ent)
	if not ent.RgChatNetId or not ent.RgChatCanUpdateEnt then return end
	ent.RgChatCanUpdateEnt = false
end)

hook.Add('OnNPCKilled', 'RgChat.EntsSyncOnNPCKilled', function(npc, attacker, inflictor)
	if not IsValid(npc) or not npc.RgChatNetId then return end
	if npc.RgChatOwner and IsValid(npc.RgChatOwner) then return end

	local ply
	if IsValid(attacker) and attacker:IsPlayer() then ply = attacker end

	if not ply then
		for _, ply_ent in ipairs(player_GetAll()) do
			if RealGloabalChat:ModIsActive(ply_ent) then
				ply = ply_ent
			end
		end
	end

	if not ply then return end

	wait_removed_delay = CurTime() + 3
	ply.RgChatRemovedEntities = ply.RgChatRemovedEntities or {}
	table_insert(ply.RgChatRemovedEntities, { net_id = npc.RgChatNetId })
end)