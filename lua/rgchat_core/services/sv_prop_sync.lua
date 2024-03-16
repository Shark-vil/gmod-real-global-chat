-- Variables
local _spawn_entity_queue, _remove_entity_queue, _spawned_net_entities, _cleanup_net_entities
-- Functions
local _PlayerSpawnEntity, _PlayerRemoveEntity, _BackgroundWorker
-- Set Variables
_spawn_entity_queue = {}
_remove_entity_queue = {}
_spawned_net_entities = {}
_cleanup_net_entities = {}

function _BackgroundWorker()
	while true do
		if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then
			coroutine.wait(1)
		else
			for net_world_owner_steamid64, net_entities in pairs(_cleanup_net_entities) do
				if #net_entities ~= 0 then
					for _, ply in ipairs(player.GetHumans()) do
						if ply:SteamID64() == net_world_owner_steamid64 then
							RealGloabalChat.WebApi.GameInfo:CleanupEntitiesWait(ply, net_entities)
							break
						end
					end

					table.Empty(net_entities)
				end
			end

			for ply, entity_queue in pairs(_spawn_entity_queue) do
				if #entity_queue ~= 0 then
					local code, response = RealGloabalChat.WebApi.GameInfo:AddEntitiesWait(ply, entity_queue)

					if code and code == 200 and response and response.success and response.success == 1 and response.entities then
						for _, net_ent in ipairs(response.entities) do
							for _, ent in ipairs(entity_queue) do
								if net_ent.ent_index == ent:EntIndex() then
									ent.RgChatNetId = net_ent.net_id
									_spawned_net_entities[net_ent.net_id] = {
										world_owner_steamid64 = net_ent.world_owner_steamid64,
										ent = ent,
									}
									break
								end
							end
						end
					end

					table.Empty(entity_queue)
				end
			end

			for ply, entity_queue in pairs(_remove_entity_queue) do
				if #entity_queue ~= 0 then
					local code, response = RealGloabalChat.WebApi.GameInfo:CleanupEntitiesWait(ply, entity_queue)

					if code and code == 200 and response and response.success and response.success == 1 and response.entities then
						for _, net_ent in ipairs(response.entities) do
							_spawned_net_entities[net_ent.net_id] = nil
						end
					end

					table.Empty(entity_queue)
				end
			end

			for _, ply in ipairs(player.GetHumans()) do
				local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')

				if rgc_sync_target ~= '' then
					local code, response = RealGloabalChat.WebApi.GameInfo:GetEntitiesWait(ply, rgc_sync_target)

					if code and code == 200 and response and response.success and response.success == 1 and response.entities then
						for _, net_ent in ipairs(response.entities) do
							if _spawned_net_entities[net_ent.net_id] then
								local value = _spawned_net_entities[net_ent.net_id]
								local ent = value.ent
								if ent and IsValid(ent) and not ent.RgChatHostEntity then
									local pos = RealGloabalChat:PosStringToVector(net_ent.pos)
									local ang = RealGloabalChat:PosStringToAngle(net_ent.ang)
									ent:SetPos(pos)
									ent:SetAngles(ang)
									local phys = ent:GetPhysicsObject()
									if IsValid(phys) and phys:IsMotionEnabled() then
										phys:EnableMotion(false)
									end
								end
							else
								local ent

								xpcall(function()
									ent = ents.Create(net_ent.class_name)

									if util.IsValidModel(net_ent.model) then
										ent:SetModel(net_ent.model)
									end
								end, function(err)
									print('ERROR: ', err)
								end)

								if ent and ent ~= NULL then
									local pos = RealGloabalChat:PosStringToVector(net_ent.pos)
									local ang = RealGloabalChat:PosStringToAngle(net_ent.ang)
									ent:SetPos(pos)
									ent:SetAngles(ang)
									ent:Spawn()
									ent.RgChatNetId = net_ent.net_id
									local phys = ent:GetPhysicsObject()
									if IsValid(phys) and phys:IsMotionEnabled() then
										phys:EnableMotion(false)
									end
								end

								_spawned_net_entities[net_ent.net_id] = {
									world_owner_steamid64 = net_ent.world_owner_steamid64,
									ent = ent,
								}
							end
						end
					end
				end
			end

			coroutine.wait(1)
		end
	end
end

RealGloabalChat:AddBackgroundWorker('props_sync', _BackgroundWorker)

function _PlayerSpawnEntity(ply, ent)
	timer.Simple(0, function()
		if not IsValid(ply) or not IsValid(ent) then return end
		ent.RgChatOwner = ply
		ent.RgChatHostEntity = true
		_spawn_entity_queue[ply] = _spawn_entity_queue[ply] or {}
		table.insert(_spawn_entity_queue[ply], ent)
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

hook.Add('PlayerSpawnedProp', 'RGChat.EntSyncPlayerSpawnedProp', function(ply, model, ent)
	_PlayerSpawnEntity(ply, ent)
end)

hook.Add('PostCleanupMap', 'RgChat.EntSyncPostCleanupMap', function()
	if RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then
		for net_ent_id, value in pairs(_spawned_net_entities) do
			_cleanup_net_entities[value.world_owner_steamid64] = _cleanup_net_entities[value.world_owner_steamid64] or {}
			table.insert(_cleanup_net_entities[value.world_owner_steamid64], net_ent_id)
		end

		_spawned_net_entities = {}
	end

	_spawn_entity_queue = {}
	_remove_entity_queue = {}
end)

hook.Add('EntityRemoved', 'RgChat.EntSyncEntityRemoved', function(ent)
	if not ent.RgChatNetId then return end
	local ply = ent.RgChatOwner
	if not IsValid(ply) then return end

	for ply_spawner, entity_queue in pairs(_spawn_entity_queue) do
		for i = #entity_queue, 1, -1 do
			local value = entity_queue[i]

			if IsValid(value.ent) and value.ent == ent then
				table.remove(entity_queue, i)
				break
			end
		end
	end

	_remove_entity_queue[ply] = _remove_entity_queue[ply] or {}
	table.insert(_remove_entity_queue[ply], ent.RgChatNetId)
end)