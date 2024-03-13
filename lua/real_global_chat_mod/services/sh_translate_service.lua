local cvar_developer = GetConVar('developer')
local string_Trim = string.Trim
local util_JSONToTable = util.JSONToTable
local string_lower = string.lower
local http_Post = http.Post

local translate_validate = {
	['en'] = true, -- английский
	['sq'] = true, -- Albanian
	['ar'] = true, -- арабский
	['az'] = true, -- азербайджанский
	['bn'] = true, -- Bengali
	['bg'] = true, -- Bulgarian
	['ca'] = true, -- Catalan
	['zh'] = true, -- китайский
	['zt'] = true, -- Chinese (traditional)
	['cs'] = true, -- чешский
	['da'] = true, -- датский
	['nl'] = true, -- голландский
	['eo'] = true, -- эсперанто
	['et'] = true, -- Estonian
	['fi'] = true, -- финский
	['fr'] = true, -- французский
	['de'] = true, -- немецкий
	['el'] = true, -- греческий
	['he'] = true, -- иврит
	['hi'] = true, -- хинди
	['hu'] = true, -- венгерский
	['id'] = true, -- индонезийский
	['ga'] = true, -- ирландский
	['it'] = true, -- итальянский
	['ja'] = true, -- японский
	['ko'] = true, -- корейский
	['lv'] = true, -- Latvian
	['lt'] = true, -- Lithuanian
	['ms'] = true, -- Malay
	['nb'] = true, -- Norwegian
	['fa'] = true, -- персидский
	['pl'] = true, -- польский
	['pt'] = true, -- португальский
	['ro'] = true, -- Romanian
	['ru'] = true, -- русский
	['sr'] = true, -- Serbian
	['sk'] = true, -- словацкий
	['sl'] = true, -- Slovenian
	['es'] = true, -- испанский
	['sv'] = true, -- шведский
	['tl'] = true, -- Tagalog
	['th'] = true, -- Thai
	['tr'] = true, -- турецкий
	['uk'] = true, -- Ukrainian
	['ur'] = true, -- Urdu
	['vi'] = true, -- вьетнамский
}

-- Thx ChatGPT
local country_language_codes = {
	['japan'] = 'ja',
	['romania'] = 'ro',
	['slovakia'] = 'sk',
	['azerbaijan'] = 'az',
	['israel'] = 'he',
	['india'] = 'hi',
	['finland'] = 'fi',
	['saudi arabia'] = 'ar',
	['bangladesh'] = 'bn',
	['spain'] = 'es',
	['hungary'] = 'hu',
	['malaysia'] = 'ms',
	['vietnam'] = 'vi',
	['albania'] = 'sq',
	['south africa'] = 'zt',
	['slovenia'] = 'sl',
	['pakistan'] = 'ur',
	['ukraine'] = 'uk',
	['poland'] = 'pl',
	['indonesia'] = 'id',
	['netherlands'] = 'nl',
	['norway'] = 'nb',
	['turkey'] = 'tr',
	['thailand'] = 'th',
	['philippines'] = 'tl',
	['sweden'] = 'sv',
	['serbia'] = 'sr',
	['united states'] = 'en',
	['russia'] = 'ru',
	['czech republic'] = 'cs',
	['greece'] = 'el',
	['italy'] = 'it',
	['iran'] = 'fa',
	['france'] = 'fr',
	['lithuania'] = 'lt',
	['estonia'] = 'et',
	['esperanto'] = 'eo',
	['south korea'] = 'ko',
	['china'] = 'zh',
	['canada'] = 'ca',
	['portugal'] = 'pt',
	['germany'] = 'de',
	['latvia'] = 'lv',
	['ireland'] = 'ga',
	['denmark'] = 'da',
	['bulgaria'] = 'bg',
	['urkaine'] = 'uk',
	['taiwan'] = 'zh',
}

-- Thx ChatGPT
local matching_country_and_lang_list = {
	['de'] = 'de', -- Germany
	['fr'] = 'fr', -- France
	['it'] = 'it', -- Italy
	['es'] = 'es', -- Spain
	['cn'] = 'zh', -- China
	['kr'] = 'ko', -- South Korea
	['in'] = 'hi', -- India
	['nl'] = 'nl', -- Netherlands
	['be'] = 'nl', -- Belgium
	['ch'] = 'de', -- Switzerland
	['at'] = 'de', -- Austria
	['pl'] = 'pl', -- Poland
	['pt'] = 'pt', -- Portugal
	['br'] = 'pt', -- Brazil
	['gr'] = 'el', -- Greece
	['cz'] = 'cs', -- Czech Republic
	['hu'] = 'hu', -- Hungary
	['se'] = 'sv', -- Sweden
	['dk'] = 'da', -- Denmark
	['no'] = 'no', -- Norway
	['fi'] = 'fi', -- Finland
	['ru'] = 'ru', -- Russia
	['il'] = 'he', -- Israel
	['tr'] = 'tr', -- Turkey
	['mx'] = 'es', -- Mexico
	['ca'] = 'en', -- Canada
	['au'] = 'en', -- Australia
	['nz'] = 'en', -- New Zealand
	['za'] = 'en', -- South Africa
	['us'] = 'en', -- United States
	['gb'] = 'en', -- United Kingdom
	['ie'] = 'en', -- Ireland
	['jp'] = 'ja', -- Japan
	['id'] = 'id', -- Indonesia
	['my'] = 'ms', -- Malaysia
	['ph'] = 'fil', -- Philippines
	['tw'] = 'zh', -- Taiwan
	['ua'] = 'uk', -- Ukrainian
	['by'] = 'ru', -- Belarus
}

function RealGloabalChat:Translate(lang, text, callback)
	lang = string_lower(lang)

	if cvar_developer:GetBool() then
		print('[RGChat]', lang, text)
	end

	if country_language_codes[lang] then
		lang = country_language_codes[lang]
	end

	if not translate_validate[lang] then
		if matching_country_and_lang_list[lang] then
			lang = matching_country_and_lang_list[lang]
		else
			lang = 'en'
		end
	end

	local form_data = {
		source = 'auto',
		target = lang,
		format = 'text',
		q = text
	}

	if cvar_developer:GetBool() then
		MsgN('[RGChat] Web send: https://translate.vincy.ru/translate')
		PrintTable(form_data)
	end

	http_Post('https://translate.vincy.ru/translate', form_data, function(body, size, headers, code)
		local response = util_JSONToTable(body)

		if cvar_developer:GetBool() then
			MsgN('[RGChat] Web response: https://translate.vincy.ru/translate')
			print(body)
		end

		if response and response['translatedText'] and response['detectedLanguage'] then
			local confidence = response['detectedLanguage']['confidence']

			if confidence and isnumber(confidence) and confidence >= 5 then
				local new_text = response['translatedText']

				if new_text then
					new_text = string_Trim(new_text)

					if #new_text ~= 0 then
						callback(new_text, code)

						return
					end
				end
			end
		end

		callback(text, code)
	end, function()
		callback(text, code)
	end)
end