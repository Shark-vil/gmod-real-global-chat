RealGloabalChat.WebApi.GameInfo = RealGloabalChat.WebApi.GameInfo or {}

function RealGloabalChat.WebApi.GameInfo:UpdateGameInfo(ply, action_list, callback)
	local ply_model = ply.rgchat_outfitter_mdl or ply:GetModel()
	local ply_model_wsid = RealGloabalChat:GetFromStorage('AddonsModels', ply_model)

	local content = RealGloabalChat:TableToJson({
		steamid64 = ply:SteamID64(),
		username = ply:Name(),
		model_wsid = ply_model_wsid,
		model = ply_model,
		played_map = game.GetMap(),
		actions = action_list
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/UpdateGameInfo'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end

function RealGloabalChat.WebApi.GameInfo:GetGameInfo(last_update, callback)
	local paramsBuilder = RealGloabalChat.WebApi:GetUrlValuesBuilder()
	paramsBuilder:AddValue('mapName', game.GetMap())
	paramsBuilder:AddValue('lastUpdate', last_update)

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/GetGameInfo' .. paramsBuilder:GetResult()),
		request_type = 'GET',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end

function RealGloabalChat.WebApi.GameInfo:AddEntities(ply, entities, callback)
	local valid_entities = {}

	for _, ent in ipairs(entities) do
		if not IsValid(ent) then continue end
		local ent_pos = ent:GetPos()
		local ent_ang = ent:GetAngles()
		local is_motion = 0
		local phys = ent:GetPhysicsObject()

		if IsValid(phys) and phys:IsMotionEnabled() then
			is_motion = 1
		end

		table.insert(valid_entities, {
			ent_index = ent:EntIndex(),
			model = ent:GetModel(),
			class_name = ent:GetClass(),
			pos = ent_pos.x .. ',' .. ent_pos.y .. ',' .. ent_pos.z,
			ang = ent_ang.x .. ',' .. ent_ang.y .. ',' .. ent_ang.z,
			is_npc = (ent:IsNPC() or ent:IsNextBot()) and 1 or 0,
			motion_enabled = is_motion,
		})
	end

	local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')

	if rgc_sync_target == '' then
		rgc_sync_target = ply:SteamID64()
	end

	local content = RealGloabalChat:TableToJson({
		steamid64 = ply:SteamID64(),
		username = ply:Name(),
		entities = valid_entities,
		target_steamid64 = rgc_sync_target
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/AddEntities'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end

function RealGloabalChat.WebApi.GameInfo:UpdateEntities(ply, entities, callback)
	local valid_entities = {}

	for _, ent in ipairs(entities) do
		if not IsValid(ent) then continue end
		local ent_pos = ent:GetPos()
		local ent_ang = ent:GetAngles()
		local is_motion = 0
		local phys = ent:GetPhysicsObject()

		if IsValid(phys) and phys:IsMotionEnabled() then
			is_motion = 1
		end

		table.insert(valid_entities, {
			ent_index = ent:EntIndex(),
			model = ent:GetModel(),
			class_name = ent:GetClass(),
			pos = ent_pos.x .. ',' .. ent_pos.y .. ',' .. ent_pos.z,
			ang = ent_ang.x .. ',' .. ent_ang.y .. ',' .. ent_ang.z,
			is_npc = (ent:IsNPC() or ent:IsNextBot()) and 1 or 0,
			net_id = ent.RgChatNetId,
			motion_enabled = is_motion,
		})
	end

	local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')

	if rgc_sync_target == '' then
		rgc_sync_target = ply:SteamID64()
	end

	local content = RealGloabalChat:TableToJson({
		steamid64 = ply:SteamID64(),
		username = ply:Name(),
		entities = valid_entities,
		target_steamid64 = rgc_sync_target
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/UpdateEntities'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end

function RealGloabalChat.WebApi.GameInfo:CleanupEntities(ply, entities, callback)
	local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')

	if rgc_sync_target == '' then
		rgc_sync_target = ply:SteamID64()
	end

	local valid_entities = {}

	for _, ent in ipairs(entities) do
		if isentity(ent) and IsValid(ent) then
			table.insert(valid_entities, {
				net_id = ent.RgChatNetId
			})
		elseif isnumber(ent) then
			table.insert(valid_entities, {
				net_id = ent
			})
		end
	end

	local content = RealGloabalChat:TableToJson({
		steamid64 = ply:SteamID64(),
		username = ply:Name(),
		entities = valid_entities,
		target_steamid64 = rgc_sync_target
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/CleanupEntities'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end

function RealGloabalChat.WebApi.GameInfo:GetEntities(target_steamid64, callback)
	local paramsBuilder = RealGloabalChat.WebApi:GetUrlValuesBuilder()
	paramsBuilder:AddValue('steamId64', target_steamid64)

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/GetEntities' .. paramsBuilder:GetResult()),
		request_type = 'GET',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end