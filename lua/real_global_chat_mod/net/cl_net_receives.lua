local LocalPlayer = LocalPlayer
local IsValid = IsValid
local lang = RealGloabalChat.Values.Language
local cvar_cl_real_global_chat_status = GetConVar('cl_rgc_status')
local cvar_cl_real_global_chat_filter = GetConVar('cl_rgc_filter')
local cvar_cl_real_global_chat_filter_strict = GetConVar('cl_rgc_filter_strict')
local cvar_cl_real_global_chat_country_mode = GetConVar('cl_rgc_country_mode')
local cvar_cl_real_global_chat_ping_sound = GetConVar('cl_rgc_ping_sound')
local cvar_cl_real_global_chat_visible_player_map_name = GetConVar('cl_rgc_visible_player_map_name')

net.Receive('RealGlobalChatSetStatus', function()
	local status_value = net.ReadInt(3)

	if status_value == 0 then
		LocalPlayer():ChatPrint(lang['rgchat_off'])
	else
		LocalPlayer():ChatPrint(lang['rgchat_on'])
	end

	RunConsoleCommand('cl_rgc_status', status_value)
end)

net.Receive('RealGlobalChatSetPingSFX', function()
	local new_value = cvar_cl_real_global_chat_ping_sound:GetInt()

	if new_value ~= 0 then
		RunConsoleCommand('cl_rgc_ping_sound', 0)
		LocalPlayer():ChatPrint(lang['rgchat_ping_sfx_off'])
	else
		RunConsoleCommand('cl_rgc_ping_sound', 1)
		LocalPlayer():ChatPrint(lang['rgchat_ping_sfx_on'])
	end
end)

net.Receive('RealGlobalChatSetMapName', function()
	local new_value = cvar_cl_real_global_chat_visible_player_map_name:GetInt()

	if new_value ~= 0 then
		RunConsoleCommand('cl_rgc_visible_player_map_name', 0)
		LocalPlayer():ChatPrint(lang['rgchat_mapname_off'])
	else
		RunConsoleCommand('cl_rgc_visible_player_map_name', 1)
		LocalPlayer():ChatPrint(lang['rgchat_mapname_on'])
	end
end)

net.Receive('RealGlobalChatSetCountryMode', function()
	local new_value = cvar_cl_real_global_chat_country_mode:GetInt()

	if new_value ~= 0 then
		RunConsoleCommand('cl_rgc_country_mode', 0)
		LocalPlayer():ChatPrint(lang['rgchat_on_type_world'])
	else
		RunConsoleCommand('cl_rgc_country_mode', 1)
		LocalPlayer():ChatPrint(lang['rgchat_on_type_country'])
	end
end)

net.Receive('RealGlobalChatSetFilter', function()
	local filter_value = net.ReadInt(3)

	if filter_value == 0 then
		if cvar_cl_real_global_chat_filter:GetInt() ~= 0 then
			RunConsoleCommand('cl_rgc_filter', 0)
			LocalPlayer():ChatPrint(lang['rgchat_off_filter'])
		else
			RunConsoleCommand('cl_rgc_filter', 1)
			LocalPlayer():ChatPrint(lang['rgchat_on_filter'])
		end
	elseif filter_value == 1 then
		if cvar_cl_real_global_chat_filter_strict:GetInt() ~= 0 then
			RunConsoleCommand('cl_rgc_filter_strict', 0)
			LocalPlayer():ChatPrint(lang['rgchat_off_filter_strict'])
		else
			RunConsoleCommand('cl_rgc_filter_strict', 1)
			LocalPlayer():ChatPrint(lang['rgchat_on_filter_strict'])

			if cvar_cl_real_global_chat_filter:GetInt() == 0 then
				LocalPlayer():ChatPrint(lang['rgchat_filter_strict_warn'])
			end
		end
	end
end)

net.Receive('RealGlobalChatSendPlayer', function()
	local text_value = net.ReadString()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not cvar_cl_real_global_chat_status:GetBool() then return end
	RealGloabalChat:SendToChat(ply, text_value)
end)

net.Receive('RealGlobalChatMuteUser', function()
	local connect_id = net.ReadString()

	if not connect_id or #connect_id == 0 or not tonumber(connect_id) then
		LocalPlayer():ChatPrint('The second argument is missing or the argument is not a number.')

		return
	end

	RealGloabalChat:MuteUser(tonumber(connect_id))
end)