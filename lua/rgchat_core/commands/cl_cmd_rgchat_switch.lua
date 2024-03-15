concommand.Add('rgchat_switch', function()
	local lang = RealGloabalChat.Values.Language
	local status_value = RealGloabalChat.ConVar:GetInt('cl_rgc_status') == 1 and 0 or 1

	if status_value == 0 then
		LocalPlayer():ChatPrint(lang['rgchat_off'])
	else
		LocalPlayer():ChatPrint(lang['rgchat_on'])
	end

	RunConsoleCommand('cl_rgc_status', status_value)
end)