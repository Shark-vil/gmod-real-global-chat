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
	local request_type = request_settings.request_type
	local success_func = callback_data.success
	local failed_func = callback_data.failed
	local finally_func = callback_data.finally

	local http_data = {}
	if isstring(url) then
		http_data.url = url
	end

	if isstring(request_type) then
		http_data.method = request_type
	end

	if isstring(content_type) and RealGloabalChat.Http.ContentType[content_type] then
		http_data.headers = RealGloabalChat.Http.ContentType[content_type]
	end

	if isstring(content) then
		http_data.body = content
	end

	http_data.success = function(code, body, headers)
		if isfunction(success_func) then success_func(code, body) end
		if isfunction(finally_func) then finally_func() end
	end

	http_data.failed = function(error_message)
		if isfunction(failed_func) then failed_func(error_message) end
		if isfunction(finally_func) then finally_func() end
	end

	HTTP(http_data)
end