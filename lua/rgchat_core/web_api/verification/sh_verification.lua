RealGloabalChat.WebApi.Verification = RealGloabalChat.WebApi.Verification or {}
--
local _isfunction = isfunction
local _file_Exists = file.Exists
local _file_Read = file.Read
local _util_TableToJSON = util.TableToJSON

function RealGloabalChat.WebApi.Verification:PreparationVerification(ply, callback)
	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('SteamLogin/PreparationVerification/' .. ply:SteamID64()),
		request_type = 'POST',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			if _isfunction(callback) then
				callback(nil, err)
			end
		end,
	})
end

function RealGloabalChat.WebApi.Verification:CheckVerification(ply, guid_address, callback)
	RealGloabalChat.Http:Request({
		url = RealGloabalChat.WebApi:GetApiUrl('SteamLogin/CheckVerification/' .. guid_address .. '/' .. ply:SteamID64()),
		request_type = 'GET',
	}, {
		success = RealGloabalChat.WebApi:ResponseHandler(callback),
		failed = function(err)
			if _isfunction(callback) then
				callback(nil, err)
			end
		end,
	})
end