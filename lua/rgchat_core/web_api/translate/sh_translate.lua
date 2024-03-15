-- Global variables
RealGloabalChat.WebApi.Translate = RealGloabalChat.WebApi.Translate or {}
-- Variables
local _translate_validate, _country_language_codes, _matching_country_and_lang_list, _english_chars, _russain_chars
-- Set variables
_translate_validate = {
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
_country_language_codes = {
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
_matching_country_and_lang_list = {
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

_english_chars = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM'
_russain_chars = 'ёйцукенгшщзхъфывапролджэячсмитьбюЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ'

function RealGloabalChat.WebApi.Translate:Translate(lang, text, callback)
	if not lang then
		lang = 'en'
	else
		lang = string.lower(lang)

		if _country_language_codes[lang] then
			lang = _country_language_codes[lang]
		end

		if not _translate_validate[lang] then
			if _matching_country_and_lang_list[lang] then
				lang = _matching_country_and_lang_list[lang]
			else
				lang = 'en'
			end
		end
	end

	local eng_chars_count = 0
	local ru_chars_count = 0
	local stop_translate = false

	for _ in text:gmatch('[' .. _english_chars .. ']') do
		eng_chars_count = eng_chars_count + 1
	end

	for _ in text:gmatch('[' .. _russain_chars .. ']') do
		ru_chars_count = ru_chars_count + 1
	end

	if lang == 'en' and eng_chars_count > ru_chars_count then
		stop_translate = true
	elseif lang == 'ru' and ru_chars_count > eng_chars_count then
		stop_translate = true
	end

	if stop_translate then
		callback()
		return
	end

	-- if (lang == 'en' and text:match('[' .. _english_chars .. ']')) or (lang == 'ru' and text:match('[' .. _russain_chars .. ']')) then
	-- 	callback()
	-- 	return
	-- end

	local content = util.TableToJSON({
		source = 'auto',
		target = lang,
		format = 'text',
		q = text
	})

	RealGloabalChat.Http:Request({
		url = 'https://translate.vincy.ru/translate',
		request_type = 'POST',
		content = content,
		content_type = 'json',
	}, {
		success = function(code, body)
			local response = util.JSONToTable(body)

			if response and response['translatedText'] and response['detectedLanguage'] then
				local confidence = response['detectedLanguage']['confidence']

				if confidence and isnumber(confidence) and confidence >= 5 then
					local new_text = response['translatedText']

					if new_text then
						new_text = string.Trim(new_text)

						if #new_text ~= 0 then
							callback(code, new_text)
							return
						end
					end
				end
			end

			callback(code, nil)
		end,
		failed = function(err) callback(nil, err) end,
	})
end