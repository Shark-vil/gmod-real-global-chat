-- Functions
local _Handler, _RenderMessages, _SetLastMessageId, _IsNewMessageId
local _isnumber = isnumber
local _ipairs = ipairs
local _IsValid = IsValid
local _string_StartsWith = string.StartsWith
local _system_FlashWindow = system.FlashWindow
local _surface_PlaySound = surface.PlaySound
local _file_Exists = file.Exists
local _file_Read = file.Read
local _string_sub = string.sub
local _string_Trim = string.Trim
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
local _table_insert = table.insert
local _isstring = isstring
local _last_message_id = nil

-- Commands
local _chat_commands = {
	['ping'] = function(arguments, user_message, builder)
		local ping_caller_nick_name = arguments[1]
		local ping_nick_name = arguments[2]
		local ping_steamid64 = arguments[3]
		local local_player = LocalPlayer()
		local new_message

		if (ping_nick_name and ping_nick_name == local_player:Nick()) or (ping_steamid64 and ping_steamid64 == local_player:SteamID64()) then
			new_message = ping_caller_nick_name .. ' PING TO YOU'
		else
			new_message = ping_caller_nick_name .. ' PING TO ' .. ping_nick_name
		end

		builder:Delete('ping_nickname')
		builder:Delete('ping_nickname_color')
		builder:Add(_color_message_command, 'color_message')
		builder:Add(new_message, 'message')
	end
}

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
	local verified_token_exists = false
	if _file_Exists('rgchat_data/verified.txt', 'DATA') then
		local verified_token = _file_Read('rgchat_data/verified.txt', 'DATA')
		verified_token_exists = #verified_token ~= 0
	end

	local ConVar = RealGloabalChat.ConVar
	local Language = RealGloabalChat.Language
	local local_player = LocalPlayer()
	local local_steamid64 = local_player:SteamID64()
	local self_nickname = local_player:Nick()
	local skip_steamid64_list = {}

	for _, ply in _ipairs(_player_GetHumans()) do
		if _IsValid(ply) then
			local steamid64 = ply:SteamID64()
			if _isstring(steamid64) and #steamid64 ~= 0 then
				skip_steamid64_list[steamid64] = true
			end
		end
	end

	for _, user_message in _ipairs(response.messages) do
		if not _IsNewMessageId(user_message) then continue end
		_last_message_id = user_message.id
		if skip_steamid64_list[user_message.steamid64] then continue end
		local result_message = user_message.message
		local result_color_message = _color_message
		local translate_result_message
		local has_ping = false
		local has_filtred = false
		local has_hidden = false
		local has_muted = RealGloabalChat.Api:HasMutedUser(user_message.connect_id)

		if not has_muted and ConVar:GetBool('cl_rgc_filter') and user_message.message_filtred then
			if ConVar:GetBool('cl_rgc_filter_strict') then
				has_filtred = true
			else
				result_message = user_message.message_filtred
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
		builder:Add(' ' .. user_message.username)

		if not has_hidden and user_message.message_type == 0 then
			local text_nickname, text_message, has_ping_by_nickname

			if _string_StartsWith(result_message, self_nickname) then
				text_nickname = _string_sub(result_message, 1, #self_nickname)
				text_message = _string_sub(result_message, #self_nickname + 1)

				if text_nickname == self_nickname then
					has_ping = true
					has_ping_by_nickname = true
					result_message = text_message
					builder:Add(_color_message_command, 'ping_nickname_color')
					builder:Add(text_nickname, 'ping_nickname')
				end
			end

			if not has_ping_by_nickname then
				result_message = ', ' .. result_message
			end

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
		builder:Add(result_message, 'message')

		if translate_result_message then
			builder:Add(_color_message_google)
			builder:Add('\n[Translation] ')
			builder:Add(_color_message)
			builder:Add(translate_result_message)
		end

		if not has_hidden and user_message.message_type == 1 then
			local system_message = _util_JSONToTable(user_message.message)

			if system_message and _chat_commands[system_message.command] then
				local command_handler = _chat_commands[system_message.command]
				command_handler(system_message.arguments, user_message, builder)
			end
		end

		chat.AddText(builder:GetResult())

		if has_ping then
			_system_FlashWindow()

			if ConVar:GetBool('cl_rgc_ping_sound') then
				_surface_PlaySound(sound_ping_sfx)
			end
		end
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
			session_id = nil
			world_name = RealGloabalChat.Api:GetChatRoom()
			return true
		end
		return false
	end

	while true do
		if RealGloabalChat.ConVar:GetBool('cl_rgc_longpoll_service') then
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
					code, response = RealGloabalChat.WebApi.Chat:GetChatMessagessLongPollWait(session_id, _last_message_id, can_update_world_name)
					if code then
						if code == 403 then
							session_id = nil
						elseif code == 200 and response and response.success and response.success == 1 and response.messages then
							_RenderMessages(response)
						end
					end
				end
			end
		else
			if RealGloabalChat.Api:PlayerChatIsActive() then
				code, response = RealGloabalChat.WebApi.Chat:GetChatMessagesWait(_last_message_id)
				if code and code == 200 and response and response.success and response.success == 1 and response.messages then
					if not _isnumber(_last_message_id) then
						_SetLastMessageId(response)
					else
						_RenderMessages(response)
					end
				end
			end
		end

		_coroutine_wait(1)
	end
end

RealGloabalChat:AddBackgroundWorker('chat', _Handler)