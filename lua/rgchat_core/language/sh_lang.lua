local _registred_languages = {}
local _cvar_cl_language = GetConVar('cl_language')

function RealGloabalChat.Language:Register(lang_code, lang_data)
	_registred_languages[lang_code] = lang_data
end

function RealGloabalChat.Language:Get(data_key, lang_code)
	if not lang_code and _cvar_cl_language then
		lang_code = _cvar_cl_language:GetString()
	end

	local lang_data = _registred_languages['english']

	if data_key then
		if _registred_languages[lang_code] and _registred_languages[lang_code][data_key] then
			return _registred_languages[lang_code][data_key]
		else
			return lang_data[data_key]
		end
	end

	if _registred_languages[lang_code] then
		return _registred_languages[lang_code]
	else
		return lang_data
	end
end