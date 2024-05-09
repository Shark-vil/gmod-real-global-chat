-- Global variables
RealGloabalChat.WebApi.Verification = RealGloabalChat.WebApi.Verification or {}

function RealGloabalChat.WebApi.Verification:PreparationVerificationWait(ply)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Verification:PreparationVerification(ply, function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end

function RealGloabalChat.WebApi.Verification:CheckVerificationWait(ply, guid_address)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Verification:CheckVerification(ply, guid_address, function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end