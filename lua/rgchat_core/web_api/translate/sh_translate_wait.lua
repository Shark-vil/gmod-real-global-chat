-- Global variables
RealGloabalChat.WebApi.Translate = RealGloabalChat.WebApi.Translate or {}

function RealGloabalChat.WebApi.Translate:TranslateWait(lang, text)
	local wait = true
	local result = {}
	RealGloabalChat.WebApi.Translate:Translate(lang, text, function(code, response)
		if code and code == 200 then
			result = { code, response }
		end
		wait = false
	end)
	while wait do coroutine.yield() end
	return unpack(result)
end