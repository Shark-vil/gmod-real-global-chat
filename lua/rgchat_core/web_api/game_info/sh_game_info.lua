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