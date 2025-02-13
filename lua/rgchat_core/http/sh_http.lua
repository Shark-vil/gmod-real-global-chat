local _isstring = isstring
local _istable = istable
local _isfunction = isfunction
local _string_lower = string.lower
local _pairs = pairs
local _tostring = tostring
local _isnumber = isnumber
local _ConVar = RealGloabalChat.ConVar
-- local CLIENT = CLIENT
-- local SERVER = SERVER

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
	local timeout = request_settings.timeout
	-- local ignore_code = request_settings.ignore_code
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

	http_data.headers = {
		['Accept'] = 'application/json,text/html,text/plain,*/*',
		['Accept-Language'] = 'en-US,en;q=0.9'
	}

	if _isstring(content_type) and RealGloabalChat.Http.ContentType[content_type] then
		http_data.headers['Content-Type'] = RealGloabalChat.Http.ContentType[content_type]
	end

	-- if (CLIENT and _ConVar:GetBool('cl_rgc_disable_ech')) or (SERVER and _ConVar:GetBool('sv_rgc_disable_ech')) then
	-- 	http_data.headers['TLS-Feature'] = 'no-ech'
	-- end

	if _isnumber(timeout) then
		http_data.timeout = timeout
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
		if _isfunction(success_func) then success_func(code, body, url) end
		-- if _isfunction(finally_func) then finally_func() end
		if RealGloabalChat:IsHttpDebug() then
			RealGloabalChat:Log('[RGChat HTTP] SUCCESS: ' .. url .. ': ', code, body)
		end
	end

	http_data.failed = function(error_message)
		if _isfunction(failed_func) then failed_func(error_message, url) end
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