RealGloabalChat.WebApi.Chat = RealGloabalChat.WebApi.Chat or {}

function RealGloabalChat.WebApi.Chat:MakeLongPollSessionWait()
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:MakeLongPollSession(function(code, response)
		result = { code, response }
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Chat:GetChatMessagesLongPollWait(sessionId, start_message_id, cancellation_token)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:GetChatMessagesLongPoll(sessionId, start_message_id, function(code, response)
		result = { code, response }
		wait = false
	end)
	while wait and (not cancellation_token or not cancellation_token()) do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Chat:SendToChatWait(ply, message_text)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:SendToChat(ply, message_text, function(code, response)
		result = { code, response }
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Chat:GetChatMessagesWait(start_message_id)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:GetChatMessages(start_message_id, function(code, response)
		result = { code, response }
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Chat:UpdateOnlineWait(ply)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:UpdateOnline(ply, function(code, response)
		result = { code, response }
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Chat:GetOnlineWait()
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Chat:GetOnline(function(code, response)
		result = { code, response }
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end