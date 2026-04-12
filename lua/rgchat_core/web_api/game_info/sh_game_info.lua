RealGloabalChat.WebApi.GameInfo = RealGloabalChat.WebApi.GameInfo or {}
--
local _isfunction = isfunction
local _game_GetMap = game.GetMap
local _ipairs = ipairs
local _IsValid = IsValid
local _table_insert = table.insert
local _isentity = isentity
local _isnumber = isnumber

-- PPM pony model paths (same list is used in cl_nextbots for client-side apply)
local _PPM_MODELS = {
	['models/ppm/player_default_base.mdl']         = true,
	['models/ppm/player_default_base_new.mdl']     = true,
	['models/ppm/player_default_base_new_nj.mdl']  = true,
	['models/ppm/player_default_base_nj.mdl']      = true,
	['models/cppm/player_default_base.mdl']        = true,
	['models/cppm/player_default_base_nj.mdl']     = true,
}

local function _SerializePPM2Skin(ply)
	if not PPM2 or not PPM2.NetworkedPonyData then return nil end
	local ok, pd = pcall(function() return ply:GetPonyData() end)
	if not ok or not pd then return nil end
	local function c(clr)
		if not clr then return nil end
		return {clr.r, clr.g, clr.b}
	end
	local ok2, result = pcall(util.TableToJSON, {
		_v  = 2,
		Ra  = pd:GetRace(),
		Ag  = pd:GetAge(),
		Ge  = pd:GetGender() and 1 or 0,
		We  = pd:GetWeight(),
		Ps  = pd:GetPonySize(),
		Mn  = pd:GetManeType(),
		Mn2 = pd:GetManeTypeNew(),
		Ml  = pd:GetManeTypeLower(),
		Tl  = pd:GetTailType(),
		Tl2 = pd:GetTailTypeNew(),
		Ts  = pd:GetTailSize(),
		Wi  = pd:GetWingsType(),
		El  = pd:GetEyelashType(),
		Fa  = pd:GetFangs() and 1 or 0,
		Bp  = pd:GetBatPonyEars() and 1 or 0,
		Hg  = pd:GetHornGlow() and 1 or 0,
		Hn  = pd:GetUseNewHorn() and 1 or 0,
		Ht  = pd:GetNewHornType(),
		Cm  = pd:GetCMark() and 1 or 0,
		Ct  = pd:GetCMarkType(),
		Cu  = pd:GetCMarkURL(),
		Sk  = pd:GetSocks() and 1 or 0,
		St  = pd:GetSocksTexture(),
		Su  = pd:GetSocksTextureURL(),
		Ch  = pd:GetHeadClothes(),
		Cn  = pd:GetNeckClothes(),
		Cb  = pd:GetBodyClothes(),
		Bc  = c(pd:GetBodyColor()),
		Ei  = c(pd:GetEyeIrisTop()),
		Eb  = c(pd:GetEyeIrisBottom()),
		Ee  = c(pd:GetEyeBackground()),
		Ec  = c(pd:GetEyelashesColor()),
		Hc  = c(pd:GetHornColor()),
		Wc  = c(pd:GetWingsColor()),
	})
	if not ok2 then return nil end
	return result
end

local function _SerializePPM1Skin(ply)
	if not PPM or not ply.ponydata then return nil end
	local pd = ply.ponydata
	local function v(vec)
		if not vec then return nil end
		return {vec.x, vec.y, vec.z}
	end
	local ok, result = pcall(util.TableToJSON, {
		_v = 1,
		ki = pd.kind,
		ag = pd.age,
		ge = pd.gender,
		ma = pd.mane,
		ml = pd.manel,
		ta = pd.tail,
		ts = pd.tailsize,
		el = pd.eyelash,
		cm = pd.cmark_enabled and 1 or 0,
		ck = pd.cmark,
		eh = pd.eyehaslines and 1 or 0,
		cc = v(pd.coatcolor),
		h1 = v(pd.haircolor1),
		h2 = v(pd.haircolor2),
		h3 = v(pd.haircolor3),
		h4 = v(pd.haircolor4),
		eb = v(pd.eyecolor_bg),
		ei = v(pd.eyecolor_iris),
		eg = v(pd.eyecolor_grad),
		e1 = v(pd.eyecolor_line1),
		e2 = v(pd.eyecolor_line2),
	})
	if not ok then return nil end
	return result
end

function RealGloabalChat.WebApi.GameInfo:UpdateGameInfo(ply, action_list, callback)
	local ply_model = ply.rgchat_outfitter_mdl or ply:GetModel()
	local ply_model_wsid = RealGloabalChat:GetFromStorage('AddonsModels', ply_model)

	-- Collect PPM skin once per update, not per action
	local ppm_skin = nil
	if _PPM_MODELS[ply_model] then
		ppm_skin = _SerializePPM2Skin(ply) or _SerializePPM1Skin(ply)
	end

	local content = RealGloabalChat:TableToJson({
		steamid64 = ply:SteamID64(),
		username = ply:Name(),
		model_wsid = ply_model_wsid,
		model = ply_model,
		played_map = _game_GetMap(),
		actions = action_list,
		ppm_skin = ppm_skin,
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/UpdateGameInfo'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = RealGloabalChat.WebApi:ResponseHandler(callback)
	})
end

function RealGloabalChat.WebApi.GameInfo:GetGameInfo(last_update, callback)
	local paramsBuilder = RealGloabalChat.WebApi:GetUrlValuesBuilder()
	paramsBuilder:AddValue('mapName', _game_GetMap())
	paramsBuilder:AddValue('lastUpdate', last_update)

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/GetGameInfo' .. paramsBuilder:GetResult()),
		request_type = 'GET',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = RealGloabalChat.WebApi:ResponseHandler(callback)
	})
end

function RealGloabalChat.WebApi.GameInfo:AddEntities(ply, entities, callback)
	local valid_entities = {}

	for _, ent in _ipairs(entities) do
		if not _IsValid(ent) then continue end
		local ent_pos = ent:GetPos()
		local ent_ang = ent:GetAngles()
		local ent_clr = ent:GetColor()
		local is_motion = 0
		local phys = ent:GetPhysicsObject()

		if _IsValid(phys) and phys:IsMotionEnabled() then
			is_motion = 1
		end

		_table_insert(valid_entities, {
			ent_index = ent:EntIndex(),
			model = ent:GetModel(),
			class_name = ent:GetClass(),
			pos = ent_pos.x .. ',' .. ent_pos.y .. ',' .. ent_pos.z,
			ang = ent_ang.x .. ',' .. ent_ang.y .. ',' .. ent_ang.z,
			is_npc = (ent:IsNPC() or ent:IsNextBot()) and 1 or 0,
			motion_enabled = is_motion,
			settings = ent.RgChatSettings and util.TableToJSON(ent.RgChatSettings) or nil,
			color = ent_clr.r .. ',' .. ent_clr.g .. ',' .. ent_clr.b .. ',' .. ent_clr.a,
			material = ent:GetMaterial(),
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
		failed = RealGloabalChat.WebApi:ResponseHandler(callback)
	})
end

function RealGloabalChat.WebApi.GameInfo:UpdateEntities(ply, entities, callback)
	local valid_entities = {}

	for _, ent in _ipairs(entities) do
		if not _IsValid(ent) then continue end
		local ent_pos = ent:GetPos()
		local ent_ang = ent:GetAngles()
		local ent_clr = ent:GetColor()
		local is_motion = 0
		local phys = ent:GetPhysicsObject()

		if _IsValid(phys) and phys:IsMotionEnabled() then
			is_motion = 1
		end

		_table_insert(valid_entities, {
			ent_index = ent:EntIndex(),
			model = ent:GetModel(),
			class_name = ent:GetClass(),
			pos = ent_pos.x .. ',' .. ent_pos.y .. ',' .. ent_pos.z,
			ang = ent_ang.x .. ',' .. ent_ang.y .. ',' .. ent_ang.z,
			is_npc = (ent:IsNPC() or ent:IsNextBot()) and 1 or 0,
			net_id = ent.RgChatNetId,
			motion_enabled = is_motion,
			settings = ent.RgChatSettings and util.TableToJSON(ent.RgChatSettings) or nil,
			color = ent_clr.r .. ',' .. ent_clr.g .. ',' .. ent_clr.b .. ',' .. ent_clr.a,
			material = ent:GetMaterial(),
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
		failed = RealGloabalChat.WebApi:ResponseHandler(callback)
	})
end

function RealGloabalChat.WebApi.GameInfo:CleanupEntities(ply, entities, callback)
	local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')

	if rgc_sync_target == '' then
		rgc_sync_target = ply:SteamID64()
	end

	local valid_entities = {}

	if entities then
		for _, ent in _ipairs(entities) do
			if _isentity(ent) and _IsValid(ent) then
				_table_insert(valid_entities, {
					net_id = ent.RgChatNetId
				})
			elseif _isnumber(ent) then
				_table_insert(valid_entities, {
					net_id = ent
				})
			end
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
		failed = RealGloabalChat.WebApi:ResponseHandler(callback)
	})
end

function RealGloabalChat.WebApi.GameInfo:ClaimEntities(ply, entities, callback)
	local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')

	if rgc_sync_target == '' then
		rgc_sync_target = ply:SteamID64()
	end

	local valid_entities = {}

	for _, ent in _ipairs(entities) do
		if _isentity(ent) and _IsValid(ent) then
			_table_insert(valid_entities, {
				net_id = ent.RgChatNetId
			})
		elseif _isnumber(ent) then
			_table_insert(valid_entities, {
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
		url = RealGloabalChat.WebApi:GetApiUrl('GameInfo/ClaimEntities'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = RealGloabalChat.WebApi:ResponseHandler(callback)
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
		failed = RealGloabalChat.WebApi:ResponseHandler(callback)
	})
end