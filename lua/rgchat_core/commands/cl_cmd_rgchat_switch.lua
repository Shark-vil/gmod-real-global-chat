concommand.Add('rgchat_switch', function()
	local Language = RealGloabalChat.Language
	local status_value = RealGloabalChat.ConVar:GetInt('cl_rgc_status') == 1 and 0 or 1

	if status_value == 0 then
		RealGloabalChat:Print(Language:Get('rgchat_off'))
	else
		RealGloabalChat:Print(Language:Get('rgchat_on'))
	end

	RunConsoleCommand('cl_rgc_status', status_value)
end)