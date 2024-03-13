if SERVER then
	local load_queue = {}
	local first_start = false

	hook.Add('PlayerInitialSpawn', 'RealGlobalChat.PrintFirstMessage', function(ply)
		load_queue[ply] = true
	end)

	hook.Add('SetupMove', 'RealGlobalChat.PrintFirstMessage', function(ply, _, cmd)
		if load_queue[ply] and not cmd:IsForced() then
			ply.RGChatReady = true
			load_queue[ply] = nil
			net.Start('RealGlobalChatSpawnMessage')
			net.Send(ply)

			if not first_start then
				hook.Run('RGchat.FirstStart')
				first_start = true
			end
		end
	end)

	hook.Add('PlayerDisconnected', 'RealGlobalChat.PrintFirstMessage', function(ply)
		if not load_queue[ply] then return end
		load_queue[ply] = nil
	end)
else
	net.Receive('RealGlobalChatSpawnMessage', function()
		LocalPlayer().RGChatReady = true
		hook.Run('RGchat.FirstStart')

		net.Start('RealGlobalChatServerSycnActive')
		net.WriteBool(GetConVar('cl_rgc_status'):GetBool())
		net.SendToServer()
	end)
end