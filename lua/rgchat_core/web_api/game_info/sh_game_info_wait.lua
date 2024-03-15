RealGloabalChat.WebApi.GameInfo = RealGloabalChat.WebApi.GameInfo or {}

function RealGloabalChat.WebApi.GameInfo:UpdateGameInfoWait(ply, action_list)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.GameInfo:UpdateGameInfo(ply, action_list, function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.GameInfo:GetGameInfoWait(last_update)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.GameInfo:GetGameInfo(last_update, function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end
