-- Functions
local _Handler, _RenderMessages, _SetLastMessageId, _IsNewMessageId, _SetPingByName
local ConVar = RealGloabalChat.ConVar
local Language = RealGloabalChat.Language
local _isnumber = isnumber
local _tonumber = tonumber
local _ipairs = ipairs
local _IsValid = IsValid
local _system_FlashWindow = system.FlashWindow
local _surface_PlaySound = surface.PlaySound
local _file_Exists = file.Exists
local _file_Read = file.Read
local _string_sub = string.sub
local _string_Trim = string.Trim
local _string_Explode = string.Explode
local _string_StartsWith = string.StartsWith
local _string_EndsWith = string.StartsWith
local _string_find = string.find
local _string_len = string.len
local _string_lower = string.lower
local _chat_AddText = chat.AddText
local _util_JSONToTable = util.JSONToTable
local _coroutine_wait = coroutine.wait
local _player_GetHumans = player.GetHumans
local _color_rgchat_tag = Color(207, 237, 73)
local _color_username = Color(255, 255, 104)
local _color_username_verified = Color(182, 255, 104)
local _color_message = Color(255, 255, 255)
local _color_message_command = Color(247, 173, 246)
local _color_message_filtred = Color(241, 137, 137)
local _color_message_google = Color(153, 176, 254)
local _sound_ping_sfx = Sound('real_global_chat_mod/ping_sfx.wav')
local _sound_new_message_sfx = Sound('real_global_chat_mod/new_message_sfx.wav')
local _table_insert = table.insert
local _isstring = isstring
local _last_message_id = nil
local _has_ping = false

-- Commands
local _chat_commands = {
	['ping'] = function(arguments, user_message, builder)
		local ping_caller_userid = arguments[1]
		local ping_caller_nick_name = arguments[2]
		local ping_userid = arguments[3]
		local ping_nick_name = arguments[4]
		local ping_message = arguments[5]
		local new_message

		if _tonumber(ping_userid) == RealGloabalChat.USER.id then
			new_message = ', [#' .. ping_caller_userid .. ']' .. ping_caller_nick_name .. ' ping you'
			if ping_message and _string_len(_string_Trim(ping_message)) ~= 0 then
				new_message = new_message .. ' and asks: ' .. ping_message
			end
			_has_ping = true
		else
			new_message = ', [#' .. ping_caller_userid .. '] ' .. ping_caller_nick_name .. ' ping the [#' .. ping_userid .. '] ' .. ping_nick_name
			ping_message = nil
		end

		builder:Delete('ping_nickname')
		builder:Delete('ping_nickname_color')
		builder:Delete('ping_prenickname')
		builder:Delete('ping_postnickname')
		builder:Delete('ping_postnickname_color_back')
		builder:Add(_color_message_command, 'color_message')
		builder:Add(new_message, 'message')
	end
}

function _SetPingByName(builder, result_message, self_nickname)
	local ping_by_coincidence = ConVar:GetBool('cl_rgc_ping_by_coincidence')
	local msg_parts = _string_Explode(',', result_message)
	local first_msg_part = msg_parts[1]
	local first_msg_part_len = #first_msg_part
	local nickname_len = #self_nickname
	local ping_nickname, ping_prenickname, ping_postnickname
	local result_color_message = _color_message
	if (_string_StartsWith(result_message, '#') and first_msg_part and _tonumber(_string_sub(first_msg_part, 2)) == RealGloabalChat.USER.id) or _string_StartsWith(result_message, self_nickname) or _string_EndsWith(result_message, self_nickname) then
		_has_ping = true
		ping_nickname = self_nickname
	elseif ping_by_coincidence and first_msg_part and (nickname_len <= first_msg_part_len or first_msg_part_len > 2) then
		local textStart, textEnd = _string_find(_string_lower(self_nickname), _string_lower(first_msg_part))
		if textStart and textEnd then
			_has_ping = true
			ping_prenickname = _string_sub(self_nickname, 1, textStart - 1)
			ping_nickname = _string_sub(self_nickname, textStart, textEnd)
			ping_postnickname = _string_sub(self_nickname, textEnd + 1)
		end
	end
	if ping_nickname then
		_has_ping = true
		builder:Delete('nickname')
		if ping_prenickname then
			builder:Add(ping_prenickname, 'ping_prenickname')
		end
		builder:Add(_color_message_command, 'ping_nickname_color')
		builder:Add(ping_nickname, 'ping_nickname')
		if ping_postnickname then
			builder:Add(result_color_message, 'ping_postnickname_color_back')
			builder:Add(ping_postnickname, 'ping_postnickname')
		end
	end
end

function _IsNewMessageId(user_message)
	if _isnumber(_last_message_id) and _last_message_id >= user_message.id then return false end
	if not _isnumber(_last_message_id) or _last_message_id < user_message.id then return true end

	return false
end

function _SetLastMessageId(response)
	for _, user_message in _ipairs(response.messages) do
		if not _IsNewMessageId(user_message) then continue end
		_last_message_id = user_message.id
	end
end

function _RenderMessages(response)
	local verified_token_exists = RealGloabalChat:IsExistsLocalVerifiedToken()
	local local_player = LocalPlayer()
	local local_steamid64 = local_player:SteamID64()
	local self_nickname = local_player:Nick()
	local skip_steamid64_list = {}

	_has_ping = false

	for _, ply in _ipairs(_player_GetHumans()) do
		if _IsValid(ply) then
			local steamid64 = ply:SteamID64()
			if _isstring(steamid64) and #steamid64 ~= 0 then
				skip_steamid64_list[steamid64] = true
			end
		end
	end

	local has_loaded_new_messages = false

	for _, user_message in _ipairs(response.messages) do
		if not _IsNewMessageId(user_message) then continue end
		_last_message_id = user_message.id
		if skip_steamid64_list[user_message.steamid64] then continue end
		local result_message = user_message.message
		local result_color_message = _color_message
		local translate_result_message
		local has_filtred = false
		local has_hidden = false
		local has_muted = RealGloabalChat.Api:HasMutedUser(user_message.connect_id)

		if not has_muted and ConVar:GetBool('cl_rgc_filter') then
			if ConVar:GetBool('cl_rgc_filter_family') and user_message.is_suspicious == 1 then
				has_filtred = true
			elseif user_message.message_filtred then
				if ConVar:GetBool('cl_rgc_filter_strict') then
					has_filtred = true
				else
					result_message = user_message.message_filtred
				end
			end
		end

		if has_muted or has_filtred then
			result_message = has_muted and ' <Muted>' or Language:Get('chat_filtered')
			result_color_message = _color_message_filtred
			has_hidden = true
		end

		local builder = RealGloabalChat:GetChatMessageBuilder()
		local world_type = ConVar:GetBool('cl_rgc_country_mode') and Language:Get('chat_type_country') or Language:Get('chat_type_world')
		local is_show_rgx_prefix = ConVar:GetBool('cl_rgc_visible_rgc_prefix')
		local is_show_chatname = ConVar:GetBool('cl_rgc_visible_chat_name')
		local is_show_player_id = ConVar:GetBool('cl_rgc_visible_player_id')
		local is_show_map_name = ConVar:GetBool('cl_rgc_visible_player_map_name')

		if is_show_rgx_prefix or is_show_chatname or is_show_player_id or (is_show_map_name and user_message.played_map) then
			builder:Add(_color_rgchat_tag)
			builder:Add('[')

			local prefix_text_list = {}

			if is_show_rgx_prefix then
				_table_insert(prefix_text_list, 'RGC')
			end

			if is_show_chatname then
				_table_insert(prefix_text_list, world_type)
			end

			if is_show_player_id then
				_table_insert(prefix_text_list, '#' .. user_message.connect_id)
			end

			if is_show_map_name and user_message.played_map then
				_table_insert(prefix_text_list, user_message.played_map)
			end

			if verified_token_exists and user_message.steamid64 == local_steamid64 and user_message.verified == 0 then
				_table_insert(prefix_text_list, 'FAKE')
			end

			local count = #prefix_text_list
			for i = 1, count do
				builder:Add(prefix_text_list[i] .. (i == count and '' or '|'))
			end

			builder:Add(']')
		end

		builder:Add(user_message.verified == 1 and _color_username_verified or _color_username)
		builder:Add(' ' .. user_message.username, 'nickname')

		if not _has_ping and user_message.message_type == 0 then
			_SetPingByName(builder, result_message, self_nickname)

			local check_result_message = result_message:gsub('[%p%c%s%d]', '')

			if #check_result_message > 3 and ConVar:GetBool('cl_rgc_translator') then
				local code, new_result_message = RealGloabalChat.WebApi.Translate:TranslateWait(RealGloabalChat.Api:GetLanguage(), result_message)

				if code and code == 200 and new_result_message ~= result_message then
					translate_result_message = new_result_message
					translate_result_message = _string_Trim(translate_result_message)

					if _string_sub(translate_result_message, 1, 1) == ',' then
						translate_result_message = _string_sub(translate_result_message, 2)
					end

					if translate_result_message:gsub('[%p%c%s%d]', ''):lower() == result_message:gsub('[%p%c%s%d]', ''):lower() then
						translate_result_message = nil
					end
				end
			end
		end

		builder:Add(result_color_message, 'color_message')
		builder:Add(', ' .. result_message, 'message')

		if not has_hidden then
			if translate_result_message then
				builder:Add(_color_message_google)
				builder:Add('\n[Translation] ')
				builder:Add(_color_message)
				builder:Add(translate_result_message)
			end

			if user_message.message_type == 1 then
				local system_message = _util_JSONToTable(user_message.message)

				if system_message and _chat_commands[system_message.command] then
					local command_handler = _chat_commands[system_message.command]
					command_handler(system_message.arguments, user_message, builder)
				end
			end
		end

		chat.AddText(builder:GetResult())

		if _has_ping then
			_system_FlashWindow()

			if ConVar:GetBool('cl_rgc_ping_sound') then
				_surface_PlaySound(_sound_ping_sfx)
			end
		end

		if not has_loaded_new_messages and not has_hidden then
			has_loaded_new_messages = true
		end
	end

	if not _has_ping and has_loaded_new_messages and ConVar:GetBool('cl_rgc_new_message_sound') then
		_surface_PlaySound(_sound_new_message_sfx)
	end
end

local function _OnGetMessages(code, response)
	if code and code == 200 and response and response.success and response.success == 1 and response.messages then
		if not _isnumber(_last_message_id) then
			_SetLastMessageId(response)
		else
			_RenderMessages(response)
		end
	end
end

function _Handler()
	local code, response, session_id, world_name

	local function can_update_world_name()
		if not world_name then
			world_name = RealGloabalChat.Api:GetChatRoom()
			return true
		elseif world_name ~= RealGloabalChat.Api:GetChatRoom() then
			session_id, _last_message_id = nil, nil
			world_name = RealGloabalChat.Api:GetChatRoom()
			return true
		end
		return false
	end

	while true do
		if not RealGloabalChat.Api:PlayerChatIsActive() then
			_coroutine_wait(1)
			continue
		end

		if RealGloabalChat.ConVar:GetBool('cl_rgc_longpoll_service_beta') then
			can_update_world_name()
			if not session_id then
				code, session_id = RealGloabalChat.WebApi.Chat:MakeLongPollSessionWait()
			else
				if not _isnumber(_last_message_id) then
					code, response = RealGloabalChat.WebApi.Chat:GetChatMessagesWait(_last_message_id)
					if code and code == 200 and response and response.success and response.success == 1 and response.messages then
						_SetLastMessageId(response)
					end
				end
				if _last_message_id then
					code, response = RealGloabalChat.WebApi.Chat:GetChatMessagesLongPollWait(session_id, _last_message_id, can_update_world_name)
					if RealGloabalChat.Api:PlayerChatIsActive() then
						if not code or not response or code ~= 200 then
							session_id = nil
						elseif response.success and response.success == 1 and response.messages then
							_RenderMessages(response)
						end
					end
				end
			end
		else
			code, response = RealGloabalChat.WebApi.Chat:GetChatMessagesWait(_last_message_id)
			if code and code == 200 and response and response.success and response.success == 1 and response.messages then
				if not _isnumber(_last_message_id) then
					_SetLastMessageId(response)
				else
					_RenderMessages(response)
				end
			end
			_coroutine_wait(.5)
		end

		_coroutine_wait(1)
	end
end

RealGloabalChat:AddBackgroundWorker('chat', _Handler)