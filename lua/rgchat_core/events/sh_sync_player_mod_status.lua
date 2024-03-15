if SERVER then
	net.Receive('RGChat_SendPlayerChatRoomActivity', function(_, ply)
		local active = net.ReadBool()
		RealGloabalChat:AddToStorage('ModActive', ply, active)
	end)
else
	hook.Add('RGchat.FirstStart', 'SendPlayerChatRoomActivity', function()
		net.Start('RGChat_SendPlayerChatRoomActivity')
		net.WriteBool(RealGloabalChat.ConVar:GetBool('cl_rgc_status'))
		net.SendToServer()
	end)
end