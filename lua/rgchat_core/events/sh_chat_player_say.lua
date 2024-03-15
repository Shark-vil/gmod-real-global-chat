if SERVER then
	hook.Add('PlayerSay', 'RGChatPlayerSayToChat', function(ply, text)
		text = string.Trim(text)
		if #text == 0 then return end
		net.Start('RGChat_PlayerSay')
		net.WriteString(text)
		net.Send(ply)
	end)
else
	net.Receive('RGChat_PlayerSay', function()
		local text_value = net.ReadString()
		if not RealGloabalChat.ConVar:GetBool('cl_rgc_status') then return end

		RealGloabalChat.WebApi.Chat:SendToChat(LocalPlayer(), text_value)
	end)
end