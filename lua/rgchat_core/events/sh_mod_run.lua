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
			net.Start('RGChat_Init')
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
	net.Receive('RGChat_Init', function()
		LocalPlayer().RGChatReady = true
		hook.Run('RGchat.FirstStart')
	end)
end