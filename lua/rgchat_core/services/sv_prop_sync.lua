local _PlayerSpawnEntity, _PlayerRemoveEntity, _BackgroundActionsWorker, _BackgroundUpdateWorker, _PickupEntity, _DroppedEntity
local _pairs = pairs
local _ipairs = ipairs
local _table_Empty = table.Empty
local _coroutine_yield = coroutine.yield
local _coroutine_wait = coroutine.wait
local _player_GetHumans = player.GetHumans
local _ents_GetAll = ents.GetAll
local _SafeRemoveEntity = SafeRemoveEntity
local _util_IsValidModel = util.IsValidModel
local _util_JSONToTable = util.JSONToTable
local _table_remove = table.remove
local _table_insert = table.insert
local _ents_Create = ents.Create
local _timer_Simple = timer.Simple
local _xpcall = xpcall
local _IsValid = IsValid
local _spawn_entity_queue = {}
local _remove_entity_queue = {}
local _spawned_net_entities = {}
local _cleanup_net_entities = {}
local _claimed_entities = {}

function _BackgroundActionsWorker()
	while true do
		if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then
			_coroutine_wait(1)
		else
			for net_world_owner_steamid64, net_entities in _pairs(_cleanup_net_entities) do
				if #net_entities ~= 0 then
					for _, ply in _ipairs(_player_GetHumans()) do
						if ply:SteamID64() == net_world_owner_steamid64 then
							RealGloabalChat.WebApi.GameInfo:CleanupEntitiesWait(ply, net_entities)
							break
						end
					end

					_table_Empty(net_entities)
					_coroutine_yield()
				end
			end

			for ply, entity_queue in _pairs(_spawn_entity_queue) do
				if #entity_queue ~= 0 then
					local code, response = RealGloabalChat.WebApi.GameInfo:AddEntitiesWait(ply, entity_queue)

					if code and code == 200 and response and response.success and response.success == 1 and response.entities then
						for _, net_ent in _ipairs(response.entities) do
							for _, ent in _ipairs(entity_queue) do
								if net_ent.ent_index == ent:EntIndex() then
									ent.RgChatNetId = net_ent.net_id
									ent.RgChatNetOwner = net_ent.world_owner_steamid64
									ent.RgChatNetHost = net_ent.host_steamid64

									_spawned_net_entities[net_ent.net_id] = {
										world_owner_steamid64 = net_ent.world_owner_steamid64,
										ent = ent,
									}

									break
								end
							end
						end
					end

					_table_Empty(entity_queue)
					_coroutine_yield()
				end
			end

			for ply, entity_queue in _pairs(_remove_entity_queue) do
				if #entity_queue ~= 0 then
					local code, response = RealGloabalChat.WebApi.GameInfo:CleanupEntitiesWait(ply, entity_queue)

					if code and code == 200 and response and response.success and response.success == 1 and response.entities then
						for _, net_ent in _ipairs(response.entities) do
							_spawned_net_entities[net_ent.net_id] = nil
						end
					end

					_table_Empty(entity_queue)
					_coroutine_yield()
				end
			end

			for _, ply in _ipairs(_player_GetHumans()) do
				local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')

				if rgc_sync_target == '' then
					rgc_sync_target = ply:SteamID64()
				end

				if rgc_sync_target ~= '' then
					local code, response = RealGloabalChat.WebApi.GameInfo:GetEntitiesWait(rgc_sync_target)

					if code and code == 200 and response and response.success and response.success == 1 and response.entities then
						for _, ent in _ipairs(_ents_GetAll()) do
							if _IsValid(ent) and ent.RgChatNetId then
								local is_valid_network = false

								for _, net_ent in _ipairs(response.entities) do
									if net_ent.net_id == ent.RgChatNetId then
										is_valid_network = true
										break
									end
								end

								if not is_valid_network then
									_SafeRemoveEntity(ent)
								end
							end
						end

						for _, net_ent in _ipairs(response.entities) do
							if _spawned_net_entities[net_ent.net_id] then
								local value = _spawned_net_entities[net_ent.net_id]
								local ent = value.ent

								if ent and _IsValid(ent) then
									ent.RgChatNetHost = net_ent.host_steamid64
									local is_hosted_entity = false

									for _, check_player in _ipairs(_player_GetHumans()) do
										if check_player:SteamID64() == ent.RgChatNetHost then
											is_hosted_entity = true
											break
										end
									end

									if not is_hosted_entity then
										if ent:GetModel() ~= net_ent.model and _util_IsValidModel(net_ent.model) then
											ent:SetModel(net_ent.model)
										end

										local speed = 100
										local pos = RealGloabalChat:PosStringToVector(net_ent.pos)
										local ang = RealGloabalChat:PosStringToAngle(net_ent.ang)
										local phys = ent:GetPhysicsObject()

										if _IsValid(phys) and phys:IsMotionEnabled() then
											phys:EnableMotion(false)
										end

										while _IsValid(ent) and ent.RgChatNetHost == net_ent.host_steamid64 and ent:GetPos() ~= pos and ent:GetAngles() ~= ang do
											local new_pos = RealGloabalChat:MoveTowards(ent:GetPos(), pos, FrameTime() * (speed * 2))
											local new_ang = RealGloabalChat:MoveTowards(ent:GetAngles(), ang, FrameTime() * (speed * 2))
											if not new_pos or not new_ang then break end
											ent:SetPos(new_pos)
											ent:SetAngles(new_ang)
											_coroutine_yield()
										end
									end
								end
							else
								local ent

								_xpcall(function()
									ent = _ents_Create(net_ent.class_name)

									if _util_IsValidModel(net_ent.model) then
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
									ent:Activate()
									ent.RgChatNetId = net_ent.net_id
									ent.RgChatNetOwner = net_ent.world_owner_steamid64
									ent.RgChatNetHost = net_ent.host_steamid64
									local phys = ent:GetPhysicsObject()

									if _IsValid(phys) and phys:IsMotionEnabled() then
										phys:EnableMotion(false)
									end

									if StreamRadioLib and net_ent.class_name == 'sent_streamradio' then
										_timer_Simple(0, function()
											if not _IsValid(ent) then return end
											local data = _util_JSONToTable(net_ent.settings)
											if not data then return end

											if _IsValid(phys) then
												phys:EnableCollisions(not data.nocollide)
											end

											ent.Settings = data.settings
											ent.nocollide = data.nocollide
											StreamRadioLib.EditRadio(ent, data.settings)
											ent:SetToolURL(data.url, true)
										end)
									end
								end

								_spawned_net_entities[net_ent.net_id] = {
									world_owner_steamid64 = net_ent.world_owner_steamid64,
									ent = ent,
								}
							end
						end
					end

					_coroutine_yield()
				end
			end

			_coroutine_wait(1)
		end
	end
end

RealGloabalChat:AddBackgroundWorker('props_sync', _BackgroundActionsWorker)

function _BackgroundUpdateWorker()
	while true do
		local valid_claimed_entities = {}

		for i = #_claimed_entities, 1, -1 do
			local data = _claimed_entities[i]
			local ply = data.ply
			local ent = data.ent

			if _IsValid(ply) and _IsValid(ent) then
				valid_claimed_entities[ply] = valid_claimed_entities[ply] or {}
				_table_insert(valid_claimed_entities[ply], ent)
			end
		end

		_coroutine_yield()

		for ply, entities in _pairs(valid_claimed_entities) do
			local code, response = RealGloabalChat.WebApi.GameInfo:ClaimEntitiesWait(ply, entities)

			if code and code == 200 and response and response.success and response.success == 1 and response.entities then
				for _, net_ent in _ipairs(response.entities) do
					for _, ent in _ipairs(entities) do
						if _IsValid(ent) and net_ent.ent_index == ent:EntIndex() then
							ent.RgChatNetHost = ply:SteamID64()
							break
						end
					end
				end
			end

			_coroutine_yield()
		end

		local update_entities = {}

		for net_id, data in _pairs(_spawned_net_entities) do
			for _, ply in _ipairs(_player_GetHumans()) do
				local ent = data.ent

				if _IsValid(ent) and ent.RgChatNetHost == ply:SteamID64() then
					update_entities[ply] = update_entities[ply] or {}
					_table_insert(update_entities[ply], ent)
					break
				end
			end
		end

		for ply, entities in _pairs(update_entities) do
			RealGloabalChat.WebApi.GameInfo:UpdateEntitiesWait(ply, entities)
			_coroutine_yield()
		end

		_coroutine_wait(1)
	end
end

RealGloabalChat:AddBackgroundWorker('props_sync_update', _BackgroundUpdateWorker)

function _PlayerSpawnEntity(ply, ent)
	_timer_Simple(0, function()
		if not _IsValid(ply) or not _IsValid(ent) then return end
		ent.RgChatOwner = ply
		ent.RgChatHostEntity = true
		_spawn_entity_queue[ply] = _spawn_entity_queue[ply] or {}
		_table_insert(_spawn_entity_queue[ply], ent)
	end)
end

hook.Add('RGChat.StopWatchToPlayer', 'RGChatStopSyncProps', function(_, target_id)
	for _, ply in _ipairs(_player_GetHumans()) do
		if ply:SteamID64() == target_id then return end
	end

	for _, ent in _ipairs(_ents_GetAll()) do
		if ent.RgChatNetId and ent.RgChatNetOwner == target_id then
			_SafeRemoveEntity(ent)
		end
	end
end)

hook.Add('PlayerSpawnedProp', 'RGChat.EntSyncPlayerSpawnedProp', function(ply, model, ent)
	_PlayerSpawnEntity(ply, ent)
end)

hook.Add('OnEntityCreated', 'RGChat.SpecificOnEntityCreated', function(ent)
	if _IsValid(ent) and ent:GetClass() == 'sent_streamradio' then
		_timer_Simple(0, function()
			if not _IsValid(ent) or not _IsValid(ent.Owner) then return end

			ent.RgChatSettings = {
				settings = ent.Settings,
				nocollide = ent.nocollide,
				url = ent:GetToolURL(),
			}

			_PlayerSpawnEntity(ent.Owner, ent)
		end)
	end
end)

hook.Add('PostCleanupMap', 'RgChat.EntSyncPostCleanupMap', function()
	if RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then
		for net_ent_id, value in _pairs(_spawned_net_entities) do
			_cleanup_net_entities[value.world_owner_steamid64] = _cleanup_net_entities[value.world_owner_steamid64] or {}
			_table_insert(_cleanup_net_entities[value.world_owner_steamid64], net_ent_id)
		end

		_spawned_net_entities = {}
	end

	_spawn_entity_queue = {}
	_remove_entity_queue = {}
	_claimed_entities = {}
end)

hook.Add('EntityRemoved', 'RgChat.EntSyncEntityRemoved', function(ent)
	if not ent.RgChatNetId then return end
	local ply = ent.RgChatOwner
	if not _IsValid(ply) then return end

	for ply_spawner, entity_queue in _pairs(_spawn_entity_queue) do
		for i = #entity_queue, 1, -1 do
			local value = entity_queue[i]

			if _IsValid(value.ent) and value.ent == ent then
				_table_remove(entity_queue, i)
				break
			end
		end
	end

	_remove_entity_queue[ply] = _remove_entity_queue[ply] or {}
	_table_insert(_remove_entity_queue[ply], ent.RgChatNetId)
end)

function _PickupEntity(ply, ent)
	if not ent.RgChatNetId or ent.RgChatNetHost == ply:SteamID64() then return end

	_table_insert(_claimed_entities, {
		ply = ply,
		ent = ent
	})
end

function _DroppedEntity(ply, ent)
	for i = #_claimed_entities, 1, -1 do
		local data = _claimed_entities[i]
		local target_ent = data.ent

		if _IsValid(target_ent) and target_ent == ent then
			_table_remove(_claimed_entities, i)
			break
		end
	end
end

hook.Add('GravGunOnPickedUp', 'RgChat.GravGunOnPickedUp', _PickupEntity)
hook.Add('GravGunOnDropped', 'RgChat.GravGunOnDropped', _DroppedEntity)
hook.Add('OnPhysgunPickup', 'RgChat.OnPhysgunPickup', _PickupEntity)
hook.Add('PhysgunDrop', 'RgChat.PhysgunDrop', _DroppedEntity)