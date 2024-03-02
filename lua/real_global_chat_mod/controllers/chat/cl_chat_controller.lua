local RealGloabalChat = RealGloabalChat
local LocalPlayer = LocalPlayer
local IsValid = IsValid
local isnumber = isnumber
local table_insert = table.insert
local table_remove = table.remove
local skip_ids_table = {}
local color_rgchat_tag = Color(207, 237, 73)
local color_username = Color(255, 255, 104)
local color_username_verified = Color(182, 255, 104)
local color_message = Color(255, 255, 255)
local color_message_command = Color(247, 173, 246)
local color_message_filtred = Color(241, 137, 137)
local cvar_cl_real_global_chat_status = GetConVar('cl_real_global_chat_status')
local cvar_cl_real_global_chat_filter = GetConVar('cl_real_global_chat_filter')
local cvar_cl_real_global_chat_filter_strict = GetConVar('cl_real_global_chat_filter_strict')
local cvar_cl_real_global_chat_country_mode = GetConVar('cl_real_global_chat_country_mode')
local cvar_cl_real_global_chat_ping_sound = GetConVar('cl_real_global_chat_ping_sound')
local cvar_cl_real_global_chat_visible_player_map_name = GetConVar('cl_real_global_chat_visible_player_map_name')
local last_max_message_id = nil
local sql_is_inject = false
local has_print_outdated_version = false
local util_JSONToTable = util.JSONToTable
local string_StartsWith = string.StartsWith
local string_sub = string.sub
local sql_Query = sql.Query
local ipairs = ipairs
local player_GetHumans = player.GetHumans
local last_players_count
local lang = RealGloabalChat.Values.Language
local sound_ping_sfx = Sound('real_global_chat_mod/ping_sfx.wav')

local function update_message_action(response)
	if not response or response.success == 0 then return end
	local skip_ids_count = #skip_ids_table

	if skip_ids_count + 1 > 250 then
		table_remove(skip_ids_table, 1)
		skip_ids_count = skip_ids_count - 1
	end

	local local_player = LocalPlayer()
	local self_nick_name = local_player:Nick()

	for _, user_msg in ipairs(response.messages) do
		local has_skip_msg = false

		for _, ply in ipairs(player_GetHumans()) do
			if IsValid(ply) and ply:SteamID64() == user_msg.steamid64 then
				has_skip_msg = true
				break
			end
		end

		if has_skip_msg then continue end
		if isnumber(last_max_message_id) and last_max_message_id >= user_msg.random_id then continue end

		if not isnumber(last_max_message_id) or last_max_message_id < user_msg.random_id then
			last_max_message_id = user_msg.random_id
		end

		sql_Query('UPDATE rgchat_data SET last_message_id=' .. last_max_message_id .. ' WHERE id=1;')
		local world_type

		if cvar_cl_real_global_chat_country_mode:GetBool() then
			world_type = lang['chat_type_country']
		else
			world_type = lang['chat_type_world']
		end

		local has_ping = false
		local result_message = user_msg.message
		local result_color_message = color_message

		if cvar_cl_real_global_chat_filter:GetBool() and user_msg.message_filtred then
			if cvar_cl_real_global_chat_filter_strict:GetBool() then
				result_message = lang['chat_filtered']
				result_color_message = color_message_filtred
			else
				result_message = user_msg.message_filtred
			end
		end

		-- System messages handler
		if user_msg.message_type == 1 then
			local system_message = util_JSONToTable(user_msg.message)

			if system_message then
				result_color_message = color_message_command

				if system_message.command == 'ping' then
					local ping_caller_nick_name = system_message.arguments[1]
					local ping_nick_name = system_message.arguments[2]
					local ping_steamid64 = system_message.arguments[3]

					if (ping_nick_name and ping_nick_name == local_player:Nick()) or (ping_steamid64 and ping_steamid64 == local_player:SteamID64()) then
						result_message = ping_caller_nick_name .. ' PING TO YOU'
					else
						result_message = ping_caller_nick_name .. ' PING TO ' .. ping_nick_name
					end
				end
			end
		end

		local text_constructor = {}

		local function AdditionText(value)
			table_insert(text_constructor, value)
		end

		AdditionText(color_rgchat_tag)
		AdditionText('[RGC|' .. world_type .. '|#' .. user_msg.connect_id)

		if user_msg.played_map and cvar_cl_real_global_chat_visible_player_map_name:GetBool() then
			AdditionText('|' .. user_msg.played_map)
		end

		AdditionText(']')
		AdditionText((user_msg.verified and user_msg.verified == 1) and color_username_verified or color_username)
		AdditionText(' ' .. user_msg.username)

		if RealGloabalChat:UserHasMute(user_msg.connect_id) then
			AdditionText(color_message_command)
			AdditionText(' <Muted>')
		else
			AdditionText(result_color_message)
			AdditionText(', ' .. result_message)
		end

		if not has_ping and string_StartsWith(result_message, self_nick_name) then
			local text_nickname = string_sub(result_message, 1, #self_nick_name)
			local text_message = string_sub(result_message, #self_nick_name + 1)

			if text_nickname == self_nick_name then
				text_constructor = {}
				AdditionText(color_rgchat_tag)
				AdditionText('[RGC|' .. world_type .. '|#' .. user_msg.connect_id)

				if user_msg.played_map and cvar_cl_real_global_chat_visible_player_map_name:GetBool() then
					AdditionText('|' .. user_msg.played_map)
				end

				AdditionText(']')
				AdditionText((user_msg.verified and user_msg.verified == 1) and color_username_verified or color_username)
				AdditionText(' ' .. user_msg.username)
				AdditionText(result_color_message)
				AdditionText(', ')
				AdditionText(color_message_command)
				AdditionText(text_nickname)

				if RealGloabalChat:UserHasMute(user_msg.connect_id) then
					AdditionText(color_message_command)
					AdditionText(' <Muted>')
				else
					AdditionText(result_color_message)
					AdditionText(text_message)
					has_ping = true
				end
			end
		end

		chat.AddText(unpack(text_constructor))

		if has_ping then
			system.FlashWindow()

			if cvar_cl_real_global_chat_ping_sound:GetBool() then
				surface.PlaySound(sound_ping_sfx)
			end
		end

		table_insert(skip_ids_table, user_msg.random_id)
	end
end

local function global_chat_Check()
	if not RealGloabalChat:ModIsActive() then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	if not sql_is_inject then
		sql_is_inject = true
		sql_Query('CREATE TABLE IF NOT EXISTS rgchat_data (id NUMBER PRIMARY KEY, last_message_id NUMBER);')
		sql_Query('INSERT OR IGNORE INTO rgchat_data(id, last_message_id) VALUES(1, 0);')
		local sql_response = sql_Query('SELECT last_message_id FROM rgchat_data WHERE id=1;')

		if not sql_response or not sql_response[1] or not sql_response[1]['last_message_id'] then
			ErrorNoHalt('Something went wrong when trying to initialize the SQL table.')
		end

		last_max_message_id = tonumber(sql_response[1]['last_message_id'])
	end

	RealGloabalChat:GetChatMessages(ply, last_max_message_id, update_message_action)
end

local function http_Handler_CheckInfo(data)
	if not data then
		chat.AddText(color_rgchat_tag, lang['rgchat_info'] .. ' ', color_message, ': ' .. lang['failed_check_info'])
	elseif not has_print_outdated_version and data.version ~= RealGloabalChat.Values.Version then
		chat.AddText(color_rgchat_tag, lang['rgchat_info'] .. ' ', color_message, ': ' .. lang['outdated_version'])
		has_print_outdated_version = true
	end
end

local function global_chat_CheckInfo()
	if not RealGloabalChat:ModIsActive() then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	RealGloabalChat:GetInfo(http_Handler_CheckInfo)
end

timer.Create('RealGlobalChat.CheckOnline', 20, 0, function()
	if not RealGloabalChat:ModIsActive() then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	RealGloabalChat:GetOnlineCount(function(count)
		if not last_players_count or last_players_count ~= count then
			last_players_count = count
			chat.AddText(color_rgchat_tag, lang['rgchat_info'] .. ' ', color_message, ': ' .. string.Replace(lang['chat_online'], '%count%', count))
		end
	end)
end)

timer.Create('RealGlobalChat.UpdateOnline', 30, 0, function()
	if not RealGloabalChat:ModIsActive() then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	RealGloabalChat:UpdateOnline()
end)

net.Receive('RealGlobalChatSpawnMessage', function()
	LocalPlayer().RGChatReady = true

	timer.Simple(.3, function()
		if not RealGloabalChat:ModIsActive() then
			chat.AddText(color_rgchat_tag, lang['rgchat_info'] .. ' ', color_message, ': ' .. lang['chat_status_off'])
		else
			chat.AddText(color_rgchat_tag, lang['rgchat_info'] .. ' ', color_message, ': ' .. lang['chat_status_on'])
		end

		RealGloabalChat:GetOnlineCount(function(count)
			last_players_count = count
			chat.AddText(color_rgchat_tag, lang['rgchat_info'] .. ' ', color_message, ': ' .. string.Replace(lang['chat_online'], '%count%', count))
		end)
	end)

	net.Start('RealGlobalChatServerSycnActive')
	net.WriteBool(cvar_cl_real_global_chat_status:GetBool())
	net.SendToServer()
	timer.Create('RealGlobalChat.Check', 1, 0, global_chat_Check)
	timer.Create('RealGlobalChat.CheckInfo', 10, 0, global_chat_CheckInfo)
	hook.Run('RGchat.FirstStart')
end)

cvars.AddChangeCallback('cl_real_global_chat_status', function(_, _, new_value)
	net.Start('RealGlobalChatServerSycnActive')
	net.WriteBool(tostring(new_value) == '1')
	net.SendToServer()
end, 'on_player_saync_cl_real_global_chat_status')