local _registred_languages = {}

function RealGloabalChat.Language:Register(lang_code, lang_data)
	_registred_languages[lang_code] = lang_data
end

function RealGloabalChat.Language:GetLanguage(lang_code, data_key)
	local lang_data = _registred_languages['english']
	if _registred_languages[lang_code] then
		lang_data = _registred_languages[lang_code]
	end
	return lang_data[data_key]
end