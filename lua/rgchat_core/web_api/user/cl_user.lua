RealGloabalChat.WebApi.User = RealGloabalChat.WebApi.User or {}
--

function RealGloabalChat.WebApi.User:MakeOrUpdate(callback)
	local ply = LocalPlayer()
	local content = RealGloabalChat:TableToJson({
		steamid64 = ply:SteamID64(),
		username = ply:Nick(),
		verified_token = RealGloabalChat:ReadLocalVerifiedToken()
	})

	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('User/MakeOrUpdate'),
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = RealGloabalChat.WebApi:ResponseHandler(callback)
	})
end