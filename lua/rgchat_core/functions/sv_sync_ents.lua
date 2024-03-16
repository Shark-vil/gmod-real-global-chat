function RealGloabalChat:WatchToPlayer(ply, target_steamid64)
	local current_target_id = ply:GetNWString('RGC_SYNC_TARGET', '')
	if not target_steamid64 or target_steamid64 == '' then
		ply:SetNWString('RGC_SYNC_TARGET', '')
		if current_target_id ~= '' then
			hook.Run('RGChat.StopWatchToPlayer', ply, current_target_id)
			ply:ChatPrint('[RGChat] Your props are no longer linked - ' .. current_target_id)
		else
			ply:ChatPrint('[RGChat] You\'re not watching anyone at the moment.')
		end
	elseif target_steamid64 ~= current_target_id then
		ply:SetNWString('RGC_SYNC_TARGET', target_steamid64)
		if current_target_id ~= '' then
			hook.Run('RGChat.StopWatchToPlayer', ply, current_target_id)
			ply:ChatPrint('[RGChat] Your props are no longer linked - ' .. current_target_id)
		end
		hook.Run('RGChat.StartWatchToPlayer', ply, target_steamid64)
		ply:ChatPrint('[RGChat] Now your props are linked - ' .. target_steamid64)
	end
end