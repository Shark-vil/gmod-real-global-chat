RealGloabalChat.WebApi.Chat = RealGloabalChat.WebApi.Chat or {}

function RealGloabalChat.WebApi.Chat:SendToChat(ply, message_text, callback)
	local verified_token
	if file.Exists('rgchat_data/verified.txt', 'DATA') then
		verified_token = file.Read('rgchat_data/verified.txt', 'DATA')
	end

	local content = util.TableToJSON({
		steamid64 = ply:SteamID64(),
		username = ply:Nick(),
		message = messageText,
		chat_room_name = RealGloabalChat.Api:GetChatRoom(),
		verified_token = verified_token,
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/SendToChat'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		finally = callback
	})
end

function RealGloabalChat.WebApi.Chat:GetChatMessages(start_message_id, callback)
	local paramsBuilder = RealGloabalChat.WebApi:GetUrlValuesBuilder()
	paramsBuilder:AddValue('chatRoomName', RealGloabalChat.Api:GetChatRoom())

	if isnumber(start_message_id) then
		paramsBuilder:AddValue('startMessageId', start_message_id)
	end

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/GetChatMessages' .. paramsBuilder:GetResult()),
		request_type = 'GET',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		finally = callback
	})
end

function RealGloabalChat.WebApi.Chat:UpdateOnline(ply, callback)
	local content = util.TableToJSON({
		steamid64 = ply:SteamID64(),
		username = ply:Nick(),
		chat_room_name = RealGloabalChat.Api:GetChatRoom(),
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/UpdateOnline'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		finally = callback
	})
end

function RealGloabalChat.WebApi.Chat:GetOnline(callback)
	local paramsBuilder = RealGloabalChat.WebApi:GetUrlValuesBuilder()
	paramsBuilder:AddValue('chatRoomName', RealGloabalChat.Api:GetChatRoom())

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Chat/GetOnline' .. paramsBuilder:GetResult()),
		request_type = 'GET',
	}, {
		success = callback,
		finally = callback
	})
end