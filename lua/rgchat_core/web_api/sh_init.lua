-- Variables
local _color_rgchat_tag, _color_message
-- Set Variables
_color_rgchat_tag = Color(237, 204, 73)
_color_message = Color(255, 255, 255)

function RealGloabalChat.WebApi:HttpError(message)
	RealGloabalChat:LogError('[RGChat HTTP Error] ' .. message)
end

function RealGloabalChat.WebApi:HttpWarning(message)
	if CLIENT then
		chat.AddText(_color_rgchat_tag, '[RGChat Warning] ', _color_message, ': ' .. tostring(message))
	end

	RealGloabalChat:LogWarning('[RGChat HTTP Warning] ' .. message)
end

function RealGloabalChat.WebApi:GetApiUrl(url_path)
	return 'https://rgcgmod.vincy.ru/Api/' .. url_path
end

function RealGloabalChat.WebApi:GetUrlValuesBuilder()
	local builder = {}
	local result_params = ''

	function builder:AddValue(key, value)
		if not isstring(key) or value == nil then return end

		if result_params == '' then
			result_params = '?' .. key .. '=' .. tostring(value)
		else
			result_params = result_params .. '&' .. key .. '=' .. tostring(value)
		end
	end

	function builder:GetResult()
		return result_params
	end

	return builder
end

function RealGloabalChat.WebApi:ResponseHandler(callback)
	return function(code, body)
		local response = util.JSONToTable(body)

		if response and response.success then
			if response.success == 0 then
				if response.message then
					RealGloabalChat.WebApi:HttpWarning(response.message)
				elseif response.error then
					RealGloabalChat.WebApi:HttpWarning(response.error)
				end
			end
		else
			RealGloabalChat.WebApi:HttpError(body)
		end

		if isfunction(callback) then
			callback(code, response or body)
		end
	end
end