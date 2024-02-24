if CLIENT then
	CreateConVar('cl_real_global_chat_status', '1', FCVAR_ARCHIVE, '', 0, 1)
	CreateConVar('cl_real_global_chat_filter', '0', FCVAR_ARCHIVE, '', 0, 1)
	CreateConVar('cl_real_global_chat_filter_strict', '0', FCVAR_ARCHIVE, '', 0, 1)
	CreateConVar('cl_real_global_chat_country_mode', '0', FCVAR_ARCHIVE, '', 0, 1)
	CreateConVar('cl_real_global_chat_ping_sound', '1', FCVAR_ARCHIVE, '', 0, 1)
	CreateConVar('cl_real_global_chat_visible_player_map_name', '0', FCVAR_ARCHIVE, '', 0, 1)
	CreateConVar('cl_real_global_chat_download_model_size_limit', '100', FCVAR_ARCHIVE, '', 0)

	concommand.Add('rgchat_switch', function()
		local lang = RealGloabalChat.Values.Language
		local status_value = GetConVar('cl_real_global_chat_status'):GetInt() == 1 and 0 or 1
		if status_value == 0 then
			LocalPlayer():ChatPrint(lang['rgchat_off'])
		else
			LocalPlayer():ChatPrint(lang['rgchat_on'])
		end
		RunConsoleCommand('cl_real_global_chat_status', status_value)
	end)
else
	CreateConVar('sv_real_global_chat_sync_players', '0', FCVAR_ARCHIVE + FCVAR_REPLICATED, '', 0, 1)
end