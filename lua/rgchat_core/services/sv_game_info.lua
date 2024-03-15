local _Handler, _next_sync_time, _sync_tickrate, _sync_delay
_sync_delay = 1
_sync_tickrate = .35

function _Handler()
	while true do
		if not _next_sync_time then
			_next_sync_time = CurTime() + _sync_delay
		end

		local can_sync = _next_sync_time < CurTime()

		for _, ply in ipairs(player.GetHumans()) do
			if RealGloabalChat.Api:PlayerChatIsActive(ply) then
				if can_sync then
					if ply.RgChatSyncGameInfoActions then
						RealGloabalChat.WebApi.GameInfo:UpdateGameInfoWait(ply, ply.RgChatSyncGameInfoActions)
						ply.RgChatSyncGameInfoActions = {}
						coroutine.wait(.1)
					end
				elseif not ply.RgChatLastSyncGameInfo or ply.RgChatLastSyncGameInfo < CurTime() then
					ply.RgChatSyncGameInfoActions = ply.RgChatSyncGameInfoActions or {}
					table.insert(ply.RgChatSyncGameInfoActions, RealGloabalChat.Api:GetPlayerAction(ply))
					ply.RgChatLastSyncGameInfo = CurTime() + _sync_tickrate
				end
			else
				if ply.RgChatSyncGameInfoActions then
					ply.RgChatSyncGameInfoActions = nil
				end

				if ply.RgChatLastSyncGameInfo then
					ply.RgChatLastSyncGameInfo = nil
				end
			end

			coroutine.yield()
		end

		if can_sync then
			coroutine.wait(.1)
			_next_sync_time = CurTime() + _sync_delay
		end

		coroutine.wait(.1)
	end
end

RealGloabalChat:AddBackgroundWorker('game_info_sync', _Handler)