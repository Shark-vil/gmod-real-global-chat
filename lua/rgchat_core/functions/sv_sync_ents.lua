function RealGloabalChat:WatchToPlayer(ply, target_steamid64)
	local current_target_id = ply:GetNWString('RGC_SYNC_TARGET', '')
	if not target_steamid64 or target_steamid64 == '' then
		ply:SetNWString('RGC_SYNC_TARGET', '')
		if current_target_id ~= '' then
			hook.Run('RGChat.StopWatchToPlayer', ply, current_target_id)
			local bot = RealGloabalChat:GetBotBySteamId64(current_target_id)
			ply:RgcPrint('[LEAVE] You left the world of the player - ', bot and bot.BotData.NickName or current_target_id)
		else
			ply:RgcPrint('You\'re not watching anyone at the moment.')
		end
	elseif target_steamid64 ~= current_target_id then
		ply:SetNWString('RGC_SYNC_TARGET', target_steamid64)
		if current_target_id ~= '' then
			hook.Run('RGChat.StopWatchToPlayer', ply, current_target_id)
			local bot = RealGloabalChat:GetBotBySteamId64(current_target_id)
			ply:RgcPrint('[LEAVE] You left the world of the player - ', bot and bot.BotData.NickName or current_target_id)
		end
		hook.Run('RGChat.StartWatchToPlayer', ply, target_steamid64)
		local bot = RealGloabalChat:GetBotBySteamId64(target_steamid64)
		ply:RgcPrint('[JOIN] You entered the world of the player - ', bot and bot.BotData.NickName or target_steamid64)
	end
end