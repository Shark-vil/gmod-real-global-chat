RealGloabalChat.WebApi.Chat = RealGloabalChat.WebApi.Chat or {}
--
local _isfunction = isfunction
local _file_Exists = file.Exists
local _file_Read = file.Read
-- local _util_TableToJSON = util.TableToJSON

function RealGloabalChat.WebApi.Chat:MakeLongPollSession(callback)
	local content = RealGloabalChat:TableToJson({
		chat_room_name = RealGloabalChat.Api:GetChatRoom(),
	})

	RealGloabalChat.Http:Request({
			url = RealGloabalChat.WebApi:GetApiUrl('Chat/MakeLongPollSession'),
			request_type = 'POST',
			content = content,
			content_type = 'json',
		}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			if _isfunction(callback) then
				callback(nil, err)
			end
		end,
	})
end

function RealGloabalChat.WebApi.Chat:GetChatMessagessLongPoll(sessionId, start_message_id, callback)
	local paramsBuilder = RealGloabalChat.WebApi:GetUrlValuesBuilder()
	paramsBuilder:AddValue('sessionId', sessionId)
	paramsBuilder:AddValue('chatRoomName', RealGloabalChat.Api:GetChatRoom())
	paramsBuilder:AddValue('startMessageId', start_message_id)

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/GetChatMessagessLongPoll' .. paramsBuilder:GetResult()),
		request_type = 'GET',
		timeout = 120
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end


function RealGloabalChat.WebApi.Chat:SendToChat(ply, message_text, callback)
	local verified_token

	if _file_Exists('rgchat_data/verified.txt', 'DATA') then
		verified_token = _file_Read('rgchat_data/verified.txt', 'DATA')
	end

	local content = RealGloabalChat:TableToJson({
		steamid64 = ply:SteamID64(),
		username = ply:Nick(),
		message = message_text,
		chat_room_name = RealGloabalChat.Api:GetChatRoom(),
		verified_token = verified_token,
		random_id = os.time(),
		map = game.GetMap()
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/SendToChat'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			if _isfunction(callback) then
				callback(nil, err)
			end
		end,
	})
end

function RealGloabalChat.WebApi.Chat:GetChatMessages(start_message_id, callback)
	local paramsBuilder = RealGloabalChat.WebApi:GetUrlValuesBuilder()
	paramsBuilder:AddValue('chatRoomName', RealGloabalChat.Api:GetChatRoom())
	paramsBuilder:AddValue('startMessageId', start_message_id)

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/GetChatMessages' .. paramsBuilder:GetResult()),
		request_type = 'GET',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end

function RealGloabalChat.WebApi.Chat:UpdateOnline(ply, callback)
	local content = RealGloabalChat:TableToJson({
		steamid64 = ply:SteamID64(),
		username = ply:Nick(),
		chat_room_name = RealGloabalChat.Api:GetChatRoom(),
		map = game.GetMap(),
		map_wsid = RealGloabalChat.ActiveMapWsid,
		in_chat = RealGloabalChat.Api:PlayerChatIsActive() and 1 or 0
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/UpdateOnline'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			if _isfunction(callback) then
				callback(nil, err)
			end
		end,
	})
end

function RealGloabalChat.WebApi.Chat:GetOnline(callback)
	local paramsBuilder = RealGloabalChat.WebApi:GetUrlValuesBuilder()
	paramsBuilder:AddValue('chatRoomName', RealGloabalChat.Api:GetChatRoom())

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/GetOnline' .. paramsBuilder:GetResult()),
		request_type = 'GET',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			callback(nil, err)
		end,
	})
end