local _isfunction = isfunction
local _tostring = tostring
local _util_JSONToTable = util.JSONToTable

function RealGloabalChat.WebApi:HttpError(message)
	RealGloabalChat:LogError('[WEB] ' .. message)
end

function RealGloabalChat.WebApi:HttpWarning(message)
	RealGloabalChat:PrintWarning(message)
	RealGloabalChat:LogWarning('[WEB] ' .. message)
end

function RealGloabalChat.WebApi:GetApiUrl(url_path)
	local api_domain = RealGloabalChat.WEB_API_URL

	if (CLIENT and RealGloabalChat.ConVar:GetBool('cl_rgc_use_proxy_domain')) or (SERVER and RealGloabalChat.ConVar:GetBool('sv_rgc_use_proxy_domain')) then
		api_domain = RealGloabalChat.WEB_API_PROXY_URL
	end

	return api_domain .. url_path
end

function RealGloabalChat.WebApi:GetUrlValuesBuilder()
	local builder = {}
	local result_params = ''

	function builder:AddValue(key, value)
		if not isstring(key) or value == nil then return end

		if result_params == '' then
			result_params = '?' .. key .. '=' .. _tostring(value)
		else
			result_params = result_params .. '&' .. key .. '=' .. _tostring(value)
		end
	end

	function builder:GetResult()
		return result_params
	end

	return builder
end

function RealGloabalChat.WebApi:ResponseHandler(callback)
	return function(code, body)
		local response = _util_JSONToTable(body)

		-- if response and response.success then
		-- 	if response.success == 0 then
		-- 		if response.message then
		-- 			RealGloabalChat.WebApi:HttpWarning(response.message)
		-- 		elseif response.error then
		-- 			RealGloabalChat.WebApi:HttpError(response.error)
		-- 		end
		-- 	end
		-- else
		-- 	RealGloabalChat.WebApi:HttpError(body)
		-- end

		if response and response.success and response.success == 0 then
			if response.message then
				RealGloabalChat.WebApi:HttpWarning(response.message)
			elseif response.error then
				RealGloabalChat.WebApi:HttpError(response.error)
			end
		elseif code ~= 200 then
			RealGloabalChat.WebApi:HttpError(response or body)
		end

		if _isfunction(callback) then
			callback(code, response or body)
		end
	end
end