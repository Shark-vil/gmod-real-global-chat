local _isfunction = isfunction
local _tostring = tostring
local _util_JSONToTable = util.JSONToTable
local _string_find = string.find
local _string_match = string.match
local _tonumber = tonumber

function RealGloabalChat.WebApi:HttpError(message)
	RealGloabalChat:LogError('[WEB] ' .. message)
end

function RealGloabalChat.WebApi:HttpWarning(message)
	RealGloabalChat:PrintWarning(message)
	RealGloabalChat:LogWarning('[WEB] ' .. message)
end

function RealGloabalChat.WebApi:GetApiUrl(url_path)
	return RealGloabalChat.WEB_API_URL .. url_path
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
	return function(...)
		local args = { ... }
		local code, body, url
		if #args == 2 then
			code = _tonumber(_string_match(args[1], '%d+'))
			body = args[1]
			url = args[2]
		else
			code = args[1]
			body = args[2]
			url = args[3]
		end

		local is_not_error = false

		-- LongPoll timeout
		if code == 504 and _string_find(url, 'Chat/GetChatMessagesLongPoll') then
			is_not_error = true
		end

		local response = _util_JSONToTable(body)

		if response and response.success and response.success == 0 then
			if response.message then
				RealGloabalChat.WebApi:HttpWarning(url .. '\n' .. response.message)
			elseif response.error then
				RealGloabalChat.WebApi:HttpError(url .. '\n' .. response.error)
			end
		elseif not is_not_error and (not code or code ~= 200) then
			RealGloabalChat.WebApi:HttpError(url .. '\n' .. (istable(response) and table.ToString(response) or body))
		end

		if _isfunction(callback) then
			callback(code, response or body)
		end
	end
end