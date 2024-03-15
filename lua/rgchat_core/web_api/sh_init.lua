local http_Error, http_Warn

do
	local color_rgchat_tag = Color(237, 204, 73)
	local color_message = Color(255, 255, 255)

	function http_Error(message)
		print('[RGChat Error] ' .. message)
	end

	function http_Warn(message)
		if CLIENT then
			chat.AddText(color_rgchat_tag, '[RGChat Warn] ', color_message, ': ' .. tostring(message))
		end

		print('[RGChat Warn] ' .. message)
	end
end

function RealGloabalChat.WebApi:GetApiUrl(url_path)
	return 'https://rgcgmod.vincy.ru/Api/' .. url_path
end

function RealGloabalChat.WebApi:GetUrlValuesBuilder()
	local builder = {}
	local result_params = ''

	function builder:AddValue(key, value)
		if result_params == '' then
			result_params = '?' .. key .. '=' .. value
		else
			result_params = '%' .. key .. '=' .. value
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
					http_Warn(response.message)
				elseif response.error then
					http_Error(response.error)
				end
			end
		else
			http_Error(body)
		end
		if isfunction(callback) then
			callback(response, code, body)
		end
	end
end