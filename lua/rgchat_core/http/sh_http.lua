local _isstring = isstring
local _istable = istable
local _isfunction = isfunction
local _string_lower = string.lower
local _pairs = pairs
local _tostring = tostring

RealGloabalChat.Http.ContentType = {
	['html'] = 'text/html; charset=utf-8',
	['form-data'] = 'multipart/form-data; boundary=something; charset=utf-8',
	['json'] = 'application/json; charset=utf-8',
	['plain'] = 'text/plain; charset=utf-8',
	['form-url'] = 'application/x-www-form-urlencoded; charset=utf-8'
}

function RealGloabalChat.Http:Request(request_settings, callback_data)
	local url = request_settings.url
	local content = request_settings.content
	local content_type = request_settings.content_type
	local request_type = _string_lower(request_settings.request_type)
	local success_func = callback_data.success
	local failed_func = callback_data.failed
	-- local finally_func = callback_data.finally

	local http_data = {}
	if _isstring(url) then
		http_data.url = url
	end

	if _isstring(request_type) then
		http_data.method = request_type
	end

	if _isstring(content_type) and RealGloabalChat.Http.ContentType[content_type] then
		http_data.headers = {
			['Content-Type'] = RealGloabalChat.Http.ContentType[content_type]
		}
	end

	if _isstring(content) then
		http_data.body = content
	elseif _istable(content) and (request_type == 'get' or request_type == 'post' or request_type == 'head') then
		local parameters = {}
		for k, v in _pairs(content) do
			local string_key = _tostring(k)
			local string_value = _tostring(v)
			if string_key and string_value and string_key ~= '' then
				parameters[string_key] = string_value
			end
		end
		http_data.parameters = parameters
	end

	http_data.success = function(code, body, headers)
		if _isfunction(success_func) then success_func(code, body) end
		-- if _isfunction(finally_func) then finally_func() end
		if RealGloabalChat:IsHttpDebug() then
			RealGloabalChat:Log('[RGChat HTTP] SUCCESS: ' .. url .. ': ', code, body)
		end
	end

	http_data.failed = function(error_message)
		if _isfunction(failed_func) then failed_func(error_message) end
		-- if _isfunction(finally_func) then finally_func() end
		if RealGloabalChat:IsHttpDebug() then
			RealGloabalChat:LogError('[RGChat HTTP] ERROR: ' .. url .. ': ', error_message)
		end
	end

	if RealGloabalChat:IsHttpDebug() then
		PrintTable(http_data)
	end

	HTTP(http_data)
end