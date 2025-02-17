RealGloabalChat.WebApi.User = RealGloabalChat.WebApi.User or {}

function RealGloabalChat.WebApi.User:MakeOrUpdateWait()
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.User:MakeOrUpdate(function(code, response)
		result = { code, response }
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end