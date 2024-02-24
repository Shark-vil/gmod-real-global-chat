hook.Add('PlayerSay', 'RealGlobalChat.PlayerSay', function(ply, text)
	text = string.Trim(text)
	if #text == 0 then return end

	local command_text_lines = string.Split(string.Trim(string.lower(text)):gsub('%s+', ' '), ' ')

	if command_text_lines[1] == '/rgchat' then
		ply:ConCommand('rgchat_menu')

		return ''
	end

	if command_text_lines[1] == '/rgchatplayers' then
		if ply:IsAdmin() or ply:IsSuperAdmin() then
			local new_cvar = GetConVar('sv_real_global_chat_sync_players'):GetInt() == 1 and 0 or 1
			RunConsoleCommand('sv_real_global_chat_sync_players', new_cvar)
			if new_cvar == 1 then
				ply:ChatPrint('ON - You will now see the other players')
			else
				ply:ChatPrint('OFF - You will no longer see other players')
			end
		end

		return ''
	end

	if command_text_lines[1] == '/rgchatwslimit' then
		local new_size = command_text_lines[2] and tonumber(command_text_lines[2]) or 100
		if new_size < 0 then new_size = 0 end
		ply:ConCommand('cl_real_global_chat_download_model_size_limit ' .. new_size)
		ply:ChatPrint('[RGChat] New workshop download limit: ' .. tostring(new_size) .. ' mb')
		return ''
	end

	if command_text_lines[1] == '/rgchatmode' then
		net.Start('RealGlobalChatSetCountryMode')
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatfilter' then
		net.Start('RealGlobalChatSetFilter')
		net.WriteInt(0, 3)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatfilterstrict' then
		net.Start('RealGlobalChatSetFilter')
		net.WriteInt(1, 3)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatmap' then
		net.Start('RealGlobalChatSetMapName')
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatoff' then
		net.Start('RealGlobalChatSetStatus')
		net.WriteInt(0, 3)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchaton' then
		net.Start('RealGlobalChatSetStatus')
		net.WriteInt(1, 3)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatpingsfx' then
		net.Start('RealGlobalChatSetPingSFX')
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatmute' then
		net.Start('RealGlobalChatMuteUser')
		net.WriteString(command_text_lines[2] or '')
		net.Send(ply)

		return ''
	end

	net.Start('RealGlobalChatSendPlayer')
	net.WriteString(text)
	net.Send(ply)
end)

do
	local load_queue = {}
	local first_start = false

	hook.Add('PlayerInitialSpawn', 'RealGlobalChat.PrintFirstMessage', function(ply)
		load_queue[ply] = true
	end)

	hook.Add('SetupMove', 'RealGlobalChat.PrintFirstMessage', function(ply, _, cmd)
		if load_queue[ply] and not cmd:IsForced() then
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
end