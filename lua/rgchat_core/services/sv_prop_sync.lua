local _PlayerSpawnEntity, _BackgroundUpdateTransformWorker, _BackgroundActionsWorker, _BackgroundUpdateWorker, _PickupEntity, _DroppedEntity
local _pairs = pairs
local _ipairs = ipairs
local _table_Empty = table.Empty
local _coroutine_yield = coroutine.yield
local _coroutine_wait = coroutine.wait
local _player_GetHumans = player.GetHumans
local _ents_GetAll = ents.GetAll
local _table_Copy = table.Copy
local _SafeRemoveEntity = SafeRemoveEntity
local _util_IsValidModel = util.IsValidModel
local _util_JSONToTable = util.JSONToTable
local _util_TableToJSON = util.TableToJSON
local _table_remove = table.remove
local _table_insert = table.insert
local _ents_Create = ents.Create
local _timer_Simple = timer.Simple
local _FrameTime = FrameTime
local _RealTime = RealTime
local _os_time = os.time
local _CurTime = CurTime
local _util_SHA256 = util.SHA256
local _xpcall = xpcall
local _IsValid = IsValid
local _table_Merge = table.Merge
local _math_Round = math.Round
local _math_floor = math.floor

local _spawn_entity_queue = {}
local _remove_entity_queue = {}
local _spawned_net_entities = {}
local _claimed_entities = {}
local _cleanup_all = false
local _skip_hosted_entities = {}

local function _IsValidApiResponse(code, response)
	return code == 200 and response and response.success == 1
end

local _accept_settings_params = {
	['sent_streamradio'] = function(ent, data, is_first_spawn)
		if not data or not StreamRadioLib then return end
		if ent.RgcLastStreamRadioUrl and ent.RgcLastStreamRadioUrl == data.url then return end
		if ent.RgChatNextSettingsSetup and ent.RgChatNextSettingsSetup < _CurTime() then return end

		ent.RgChatNextSettingsSetup = _CurTime() + 1.5

		local phys = ent:GetPhysicsObject()
		if _IsValid(phys) then
			phys:EnableCollisions(not data.nocollide)
		end

		ent.Settings = data.settings
		ent.nocollide = data.nocollide
		StreamRadioLib.EditRadio(ent, data.settings)
		ent:SetToolURL(data.url, true)
		ent.RgcLastStreamRadioUrl = data.url
	end,

	['mediaplayer_tv'] = function(ent, data, is_first_spawn)
		if not data then return end
		if ent.RgcLastMediaPlayerHash and ent.RgcLastMediaPlayerHash == data.hash then return end
		if ent.RgChatNextSettingsSetup and ent.RgChatNextSettingsSetup < _CurTime() then return end

		ent.RgcLastMediaPlayerHash = data.hash
		ent.RgChatNextSettingsSetup = _CurTime() + 3

		local mp = ent:GetMediaPlayer()

		local function convertToMedia(data_media)
			local media = MediaPlayer.GetMediaForUrl(data_media['url'])
			media:SetMetadata(data_media['_metadata'], true)
			_table_Merge(media, data_media)
			if media['_StartTime'] then
				media['_StartTime'] = _RealTime() - (_os_time() - media['_StartTimeWorld'])
			end
			if media['_metadata'] and media['_metadata']['queueTime'] then
				media['_metadata']['queueTime'] = _RealTime() - (_os_time() - media['_metadata']['QueueTimeFix'])
			end
			return media
		end

		local current_media = mp:GetMedia()
		local current_queue = mp._Queue

		if data.media and (not current_media or current_media['_id'] ~= data.media['_id']) then
			local media = convertToMedia(data.media)
			mp:SetMedia(media)
			mp:SendMedia(media)
		end

		if data.queue and #data.queue ~= 0 then
			for _, queue_media in _ipairs(data.queue) do
				local is_exists = false

				if queue_media['_id'] == current_media['_id'] then
					is_exists = true
				else
					for _, current_queue_media in _ipairs(current_queue) do
						if current_queue_media['_id'] == queue_media['_id'] then
							is_exists = true
							break
						end
					end
				end

				if not is_exists then
					mp:AddMedia(convertToMedia(queue_media))
				end
			end
		end

		mp:QueueUpdated()
		mp:BroadcastUpdate()
	end
}

local _set_settings_params = {
	['sent_streamradio'] = function(ent)
		if ent.RgChatSettings and ent.RgChatSettings.url == ent:GetToolURL() then return end
		if ent.RgChatNextSettingsUpdate and ent.RgChatNextSettingsUpdate < _CurTime() then return end

		ent.RgChatNextSettingsUpdate = _CurTime() + 3
		ent.RgChatSettings = {
			settings = ent.Settings,
			nocollide = ent.nocollide,
			url = ent:GetToolURL(),
		}
	end,

	['mediaplayer_tv'] = function(ent)
		local mp = ent:GetMediaPlayer()
		local media = mp._Media and _table_Copy(mp._Media) or nil
		local queue = mp._Queue and _table_Copy(mp._Queue) or nil
		local hash_table = {}

		if media and media['_id'] then
			_table_insert(hash_table, media['_id'])
		end

		if queue and #queue ~= 0 then
			for _, queue_media in _ipairs(queue) do
				_table_insert(hash_table, queue_media['_id'])
			end
		end

		if ent.RgChatNextSettingsUpdate and ent.RgChatNextSettingsUpdate < _CurTime() then return end

		ent.RgChatNextSettingsUpdate = _CurTime() + 3

		local playlist_hash = _util_SHA256(_util_TableToJSON(hash_table))
		if ent.RgcLastMediaPlayerHash and ent.RgcLastMediaPlayerHash == playlist_hash then return end

		if ent.RgChatSettings then
			local is_exists_media = false
			local is_exists_queue = true

			if media and ent.RgChatSettings.media and media['_id'] == ent.RgChatSettings.media['_id'] then
				is_exists_media = true
			end

			if queue and ent.RgChatSettings.queue then
				for _, queue_media in _ipairs(queue) do
					local is_exists_current_queue = false

					for _, cache_queue_media in _ipairs(ent.RgChatSettings.queue) do
						if cache_queue_media['_id'] == queue_media['_id'] then
							is_exists_current_queue = true
							break
						end
					end

					if not is_exists_current_queue then
						is_exists_queue = false
						break
					end
				end
			end

			if is_exists_media and is_exists_queue then return end
		end

		if media and media['_StartTime'] then
			media['_Owner'] = nil
			media['_StartTimeFix'] = _math_Round(_RealTime() - media['_StartTime'])
			media['_StartTimeWorld'] = _math_floor(_os_time() - media['_StartTimeFix'])
			media['_metadata']['QueueTimeFix'] = _math_Round(_RealTime() - media['_metadata']['queueTime'])
			media['_metadata']['QueueTimeWorld'] = _math_floor(_os_time() - media['_metadata']['QueueTimeFix'])
		end

		if queue and #queue ~= 0 then
			for _, queue_media in _ipairs(queue) do
				queue_media['_Owner'] = nil
				queue_media['_metadata']['QueueTimeFix'] = _math_Round(_RealTime() - queue_media['_metadata']['queueTime'])
				queue_media['_metadata']['QueueTimeWorld'] = _math_floor(_os_time() - queue_media['_metadata']['QueueTimeFix'])
			end
		end

		ent.RgcLastMediaPlayerHash = playlist_hash
		ent.RgChatSettings = {
			media = media,
			queue = queue,
			hash = playlist_hash
		}
	end
}

-- Removes stale local entities that are no longer present in the network list
local function _RemoveStaleEntities(net_entities)
	for _, ent in _ipairs(_ents_GetAll()) do
		if not (_IsValid(ent) and ent.RgChatNetId) then continue end

		local is_valid_network = false
		for _, net_ent in _ipairs(net_entities) do
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

local function _ApplyNetEntityAppearance(ent, net_ent)
	if ent:GetModel() ~= net_ent.model and _util_IsValidModel(net_ent.model) then
		ent:SetModel(net_ent.model)
	end

	if net_ent.color then
		local color = RealGloabalChat:ColorStringToColor(net_ent.color)
		if color then ent:SetColor(color) end
	end

	if net_ent.material and net_ent.material ~= '' and ent:GetMaterial() ~= net_ent.material then
		ent:SetMaterial(net_ent.material)
	end
end

-- Updates an existing spawned entity with the latest network state
local function _UpdateExistingNetEntity(ent, net_ent)
	ent.RgChatNetHost = net_ent.host_steamid64

	local is_hosted = false
	for _, ply in _ipairs(_player_GetHumans()) do
		if ply:SteamID64() == ent.RgChatNetHost then
			is_hosted = true
			break
		end
	end
	ent.RgChatHostEntity = is_hosted

	if not is_hosted then
		_ApplyNetEntityAppearance(ent, net_ent)

		local phys = ent:GetPhysicsObject()
		if _IsValid(phys) and phys:IsMotionEnabled() then
			phys:EnableMotion(false)
		end

		ent.RgChatNextPos = RealGloabalChat:PosStringToVector(net_ent.pos)
		ent.RgChatNextAng = RealGloabalChat:PosStringToAngle(net_ent.ang)
	end

	if net_ent.settings and _accept_settings_params[net_ent.class_name] then
		_accept_settings_params[net_ent.class_name](ent, _util_JSONToTable(net_ent.settings), false)
	end
end

-- Spawns a new entity from a network entity descriptor
local function _SpawnNetEntity(net_ent)
	local ent

	_xpcall(function()
		ent = _ents_Create(net_ent.class_name)
		if _util_IsValidModel(net_ent.model) then
			ent:SetModel(net_ent.model)
		end
	end, function(err)
		RealGloabalChat:PrintError(err)
	end)

	if not ent or ent == NULL then return end

	ent:SetPos(RealGloabalChat:PosStringToVector(net_ent.pos))
	ent:SetAngles(RealGloabalChat:PosStringToAngle(net_ent.ang))
	ent:Spawn()
	ent:Activate()

	_ApplyNetEntityAppearance(ent, net_ent)

	ent.RgChatNetId = net_ent.net_id
	ent.RgChatNetOwner = net_ent.world_owner_steamid64
	ent.RgChatNetHost = net_ent.host_steamid64
	ent.RgChatHostEntity = false
	ent.RgChatClaimDelay = 0

	local phys = ent:GetPhysicsObject()
	if _IsValid(phys) and phys:IsMotionEnabled() then
		phys:EnableMotion(false)
	end

	if net_ent.settings then
		_timer_Simple(0, function()
			if not _IsValid(ent) then return end
			if _accept_settings_params[net_ent.class_name] then
				_accept_settings_params[net_ent.class_name](ent, _util_JSONToTable(net_ent.settings), true)
			end
		end)
	end

	_spawned_net_entities[net_ent.net_id] = {
		world_owner_steamid64 = net_ent.world_owner_steamid64,
		ent = ent,
	}
end

function _BackgroundActionsWorker()
	while true do
		if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then
			_coroutine_wait(1)
		else
			if _cleanup_all then
				for _, ply in _ipairs(_player_GetHumans()) do
					RealGloabalChat.WebApi.GameInfo:CleanupEntitiesWait(ply)
				end
				_coroutine_wait(1)
				_cleanup_all = false
			end

			for ply, entity_queue in _pairs(_spawn_entity_queue) do
				if #entity_queue ~= 0 then
					local code, response = RealGloabalChat.WebApi.GameInfo:AddEntitiesWait(ply, entity_queue)

					if _IsValidApiResponse(code, response) and response.entities then
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

					if _IsValidApiResponse(code, response) and response.entities then
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
				if rgc_sync_target == '' then continue end

				local code, response = RealGloabalChat.WebApi.GameInfo:GetEntitiesWait(rgc_sync_target)
				if not (_IsValidApiResponse(code, response) and response.entities) then continue end

				_RemoveStaleEntities(response.entities)

				for _, net_ent in _ipairs(response.entities) do
					local cached = _spawned_net_entities[net_ent.net_id]

					if cached then
						local ent = cached.ent
						if _IsValid(ent) and (not ent.RgChatClaimDelay or ent.RgChatClaimDelay < _CurTime()) then
							_UpdateExistingNetEntity(ent, net_ent)
						end
					elseif RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities_view_other') or net_ent.owner_steamid64 == rgc_sync_target then
						_SpawnNetEntity(net_ent)
					end
				end

				_coroutine_yield()
			end

			_coroutine_wait(1)
		end
	end
end

RealGloabalChat:AddBackgroundWorker('props_sync', _BackgroundActionsWorker)

function _BackgroundUpdateTransformWorker()
	local speed = 100

	while true do
		if _cleanup_all or not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then
			_coroutine_wait(1)
		else
			local spawned_entities_list = _table_Copy(_spawned_net_entities)
			_coroutine_yield()

			for _, data in _pairs(spawned_entities_list) do
				local ent = data.ent
				if not (_IsValid(ent) and not ent.RgChatHostEntity and ent.RgChatClaimDelay < _CurTime()) then continue end

				local pos = ent.RgChatNextPos
				local ang = ent.RgChatNextAng
				local step = _FrameTime() * (speed * 2)

				if pos and pos ~= ent:GetPos() then
					local new_pos = RealGloabalChat:MoveTowards(ent:GetPos(), pos, step)
					if new_pos then ent:SetPos(new_pos) end
				end

				if ang and ang ~= ent:GetAngles() then
					local new_ang = RealGloabalChat:MoveTowards(ent:GetAngles(), ang, step)
					if new_ang then ent:SetAngles(new_ang) end
				end
			end

			_coroutine_yield()
		end
	end
end

RealGloabalChat:AddBackgroundWorker('props_update_transform', _BackgroundUpdateTransformWorker)

function _BackgroundUpdateWorker()
	while true do
		if _cleanup_all or not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then
			_coroutine_wait(1)
		else
			local valid_claimed_entities = {}

			for i = #_claimed_entities, 1, -1 do
				local data = _claimed_entities[i]
				if _IsValid(data.ply) and _IsValid(data.ent) then
					valid_claimed_entities[data.ply] = valid_claimed_entities[data.ply] or {}
					_table_insert(valid_claimed_entities[data.ply], data.ent)
				end
			end

			_coroutine_yield()

			for ply, entities in _pairs(valid_claimed_entities) do
				local code, response = RealGloabalChat.WebApi.GameInfo:ClaimEntitiesWait(ply, entities)
				local is_valid_response = _IsValidApiResponse(code, response) and response.entities

				for _, ent in _ipairs(entities) do
					if _IsValid(ent) then
						if is_valid_response then
							for _, net_ent in _ipairs(response.entities) do
								if net_ent.ent_index == ent:EntIndex() then
									ent.RgChatNetHost = ply:SteamID64()
									ent.RgChatHostEntity = true
									break
								end
							end
						end

						ent.RgChatClaimDelay = 0
					end
				end

				_coroutine_yield()
			end

			local update_entities = {}

			for net_id, data in _pairs(_spawned_net_entities) do
				local ent = data.ent
				for _, ply in _ipairs(_player_GetHumans()) do
					if _IsValid(ent) and (ent.RgChatNetHost == ply:SteamID64() or _skip_hosted_entities[ent:GetClass()]) then
						update_entities[ply] = update_entities[ply] or {}

						local class_name = ent:GetClass()
						if _set_settings_params[class_name] then
							_set_settings_params[class_name](ent)
						end

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
end

RealGloabalChat:AddBackgroundWorker('props_sync_update', _BackgroundUpdateWorker)

function _PlayerSpawnEntity(ply, ent)
	if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities_spawn_other') then
		local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')
		if rgc_sync_target ~= '' then return end
	end
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

	_spawned_net_entities = {}
	_spawn_entity_queue = {}
	_remove_entity_queue = {}
	_claimed_entities = {}
end)

hook.Add('PlayerSpawnedProp', 'RGChat.EntSyncPlayerSpawnedProp', function(ply, model, ent)
	if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then return end
	_PlayerSpawnEntity(ply, ent)
end)

hook.Add('OnEntityCreated', 'RGChat.SpecificOnEntityCreated', function(ent)
	if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then return end
	_timer_Simple(0, function()
		if not _IsValid(ent) then return end
		local class_name = ent:GetClass()
		local ent_owner

		if class_name == 'sent_streamradio' then
			if not _IsValid(ent.Owner) then return end
			if _set_settings_params[class_name] then
				_set_settings_params[class_name](ent)
			end
			ent_owner = ent.Owner
		elseif class_name == 'mediaplayer_tv' then
			if _set_settings_params[class_name] then
				_set_settings_params[class_name](ent)
			end
			local mp = ent:GetMediaPlayer()
			ent_owner = mp._Owner
		end

		if not IsValid(ent_owner) then return end
		_PlayerSpawnEntity(ent_owner, ent)
	end)
end)

hook.Add('PreCleanupMap', 'RgChat.EntSyncPostCleanupMap', function()
	if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then return end
	if RealGloabalChat:IsDeveloperMode() then return end
	_cleanup_all = true
end)

hook.Add('PostCleanupMap', 'RgChat.EntSyncPostCleanupMap', function()
	_spawned_net_entities = {}
	_spawn_entity_queue = {}
	_remove_entity_queue = {}
	_claimed_entities = {}
end)

hook.Add('EntityRemoved', 'RgChat.EntSyncEntityRemoved', function(ent)
	if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then return end
	if RealGloabalChat:IsDeveloperMode() then return end
	if _cleanup_all or not ent.RgChatNetId then return end

	local ply = ent.RgChatOwner
	if not _IsValid(ply) then return end

	for ply_spawner, entity_queue in _pairs(_spawn_entity_queue) do
		for i = #entity_queue, 1, -1 do
			if _IsValid(entity_queue[i].ent) and entity_queue[i].ent == ent then
				_table_remove(entity_queue, i)
				break
			end
		end
	end

	_remove_entity_queue[ply] = _remove_entity_queue[ply] or {}
	_table_insert(_remove_entity_queue[ply], ent.RgChatNetId)
end)

function _PickupEntity(ply, ent)
	if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then return end
	if not ent.RgChatNetId or ent.RgChatNetHost == ply:SteamID64() then return end

	ent.RgChatClaimDelay = _CurTime() + 5
	_table_insert(_claimed_entities, { ply = ply, ent = ent })
end

function _DroppedEntity(ply, ent)
	if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_entities') then return end

	for i = #_claimed_entities, 1, -1 do
		local target_ent = _claimed_entities[i].ent
		if _IsValid(target_ent) and target_ent == ent then
			ent.RgChatClaimDelay = 0
			_table_remove(_claimed_entities, i)
			break
		end
	end
end

hook.Add('GravGunOnPickedUp', 'RgChat.GravGunOnPickedUp', _PickupEntity)
hook.Add('GravGunOnDropped', 'RgChat.GravGunOnDropped', _DroppedEntity)
hook.Add('OnPhysgunPickup', 'RgChat.OnPhysgunPickup', _PickupEntity)
hook.Add('PhysgunDrop', 'RgChat.PhysgunDrop', _DroppedEntity)
