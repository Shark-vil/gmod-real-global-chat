-- Variables
local _last_message_id, _sound_ping_sfx, _chat_commands, _color_rgchat_tag, _color_username, _color_username_verified, _color_message, _color_message_command, _color_message_filtred, _color_message_google
-- Functions
local _Handler, _RenderMessages, _SetLastMessageId, _IsNewMessageId
-- Colors
_color_rgchat_tag = Color(207, 237, 73)
_color_username = Color(255, 255, 104)
_color_username_verified = Color(182, 255, 104)
_color_message = Color(255, 255, 255)
_color_message_command = Color(247, 173, 246)
_color_message_filtred = Color(241, 137, 137)
_color_message_google = Color(153, 176, 254)
-- Sound
_sound_ping_sfx = Sound('real_global_chat_mod/ping_sfx.wav')

-- Commands
_chat_commands = {
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
	if isnumber(_last_message_id) and _last_message_id >= user_message.random_id then return false end
	if not isnumber(_last_message_id) or _last_message_id < user_message.random_id then return true end

	return false
end

function _SetLastMessageId(response)
	for _, user_message in ipairs(response.messages) do
		if not _IsNewMessageId(user_message) then continue end
		_last_message_id = user_message.random_id
	end
end

function _RenderMessages(response)
	local ConVar = RealGloabalChat.ConVar
	local Language = RealGloabalChat.Language
	local self_nickname = LocalPlayer():Nick()
	local skip_steamid64_list = {}

	for _, ply in ipairs(player.GetHumans()) do
		if IsValid(ply) and ply:SteamID64() then
			skip_steamid64_list[ply:SteamID64()] = true
		end
	end

	for _, user_message in ipairs(response.messages) do
		if not _IsNewMessageId(user_message) then continue end
		_last_message_id = user_message.random_id
		-- if skip_steamid64_list[user_message.steamid64] then continue end
		local result_message = user_message.message
		local result_color_message = _color_message
		local translate_result_message
		local has_ping = false

		if ConVar:GetBool('cl_rgc_filter') and user_message.message_filtred then
			if ConVar:GetBool('cl_rgc_filter_strict') then
				result_message = Language:Get('chat_filtered')
				result_color_message = _color_message_filtred
			else
				result_message = user_message.message_filtred
			end
		end

		local builder = RealGloabalChat:GetChatMessageBuilder()
		local world_type = ConVar:GetBool('cl_rgc_country_mode') and Language:Get('chat_type_country') or Language:Get('chat_type_world')
		builder:Add(_color_rgchat_tag)
		builder:Add('[RGC|' .. world_type .. '|#' .. user_message.connect_id)

		if user_message.played_map and ConVar:GetBool('cl_rgc_visible_player_map_name') then
			builder:Add('|' .. user_message.played_map)
		end

		builder:Add(']')
		builder:Add((user_message.verified and user_message.verified == 1) and _color_username_verified or _color_username)
		builder:Add(' ' .. user_message.username)

		-- if user has muted
		-- ...
		-- else
		do
			local text_nickname, text_message, has_ping_by_nickname

			if string.StartsWith(result_message, self_nickname) then
				text_nickname = string.sub(result_message, 1, #self_nickname)
				text_message = string.sub(result_message, #self_nickname + 1)

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
		end

		if user_message.message_type == 0 then
			local check_result_message = result_message:gsub('[%p%c%s]', '')

			if #check_result_message > 3 and ConVar:GetBool('cl_rgc_translator') then
				local code, new_result_message = RealGloabalChat.WebApi.Translate:TranslateWait(RealGloabalChat.Api:GetLanguage(), result_message)

				if code and code == 200 and new_result_message ~= result_message then
					translate_result_message = new_result_message
					translate_result_message = string.Trim(translate_result_message)

					if string.sub(translate_result_message, 1, 1) == ',' then
						translate_result_message = string.sub(translate_result_message, 2)
					end

					if translate_result_message:gsub('[%p%c%s]', ''):lower() == result_message:gsub('[%p%c%s]', ''):lower() then
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

		if user_message.message_type == 1 then
			local system_message = util.JSONToTable(user_message.message)

			if system_message and _chat_commands[system_message.command] then
				local command_handler = _chat_commands[system_message.command]
				command_handler(system_message.arguments, user_message, builder)
			end
		end

		chat.AddText(builder:GetResult())

		if has_ping then
			system.FlashWindow()

			if ConVar:GetBool('cl_rgc_ping_sound') then
				surface.PlaySound(sound_ping_sfx)
			end
		end
	end
end

function _Handler()
	local code, response = RealGloabalChat.WebApi.Chat:GetChatMessagesWait(_last_message_id)

	if code and code == 200 and response and response.success and response.success == 1 then
		if not _last_message_id then
			_SetLastMessageId(response)
		else
			_RenderMessages(response)
		end
	end

	coroutine.wait(1)
end

RealGloabalChat:AddBackgroundWorker('chat', _Handler)