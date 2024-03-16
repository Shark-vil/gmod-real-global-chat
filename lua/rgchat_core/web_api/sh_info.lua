RealGloabalChat.WebApi.Info = RealGloabalChat.WebApi.Info or {}

function RealGloabalChat.WebApi.Info:Get(callback)
	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('Info'),
		request_type = 'GET',
	}, {
		success = function(code, body)
			if code == 200 then
				local response = util.JSONToTable(body)
				if response then
					callback(code, response)
					return
				end
			end
			callback(code, body)
		end,
		failed = function(err) callback(nil, err) end,
	})
end