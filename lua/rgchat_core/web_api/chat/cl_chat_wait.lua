RealGloabalChat.WebApi.Chat = RealGloabalChat.WebApi.Chat or {}

function RealGloabalChat.WebApi.Chat:SendToChatWait(ply, message_text)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:SendToChat(ply, message_text, function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Chat:GetChatMessagesWait(start_message_id)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:GetChatMessages(start_message_id, function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Chat:UpdateOnlineWait(ply)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:UpdateOnline(ply, function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Chat:GetOnlineWait()
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:GetOnline(function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end