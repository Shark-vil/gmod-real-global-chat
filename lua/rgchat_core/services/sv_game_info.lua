local _Handler
local _coroutine_wait = coroutine.wait
local _coroutine_yield = coroutine.yield
local _CurTime = CurTime
local _ipairs = ipairs
local _player_GetHumans = player.GetHumans
local _table_insert = table.insert
local _sync_delay = 1
local _sync_tickrate = .35
local _next_sync_time

function _Handler()
	while true do
		if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_players') then
			_coroutine_wait(1)
		else
			if not _next_sync_time then
				_next_sync_time = _CurTime() + _sync_delay
			end

			local can_sync = _next_sync_time < _CurTime()

			for _, ply in _ipairs(_player_GetHumans()) do
				if RealGloabalChat.Api:PlayerChatIsActive(ply) then
					if can_sync then
						if ply.RgChatSyncGameInfoActions then
							RealGloabalChat.WebApi.GameInfo:UpdateGameInfoWait(ply, ply.RgChatSyncGameInfoActions)
							ply.RgChatSyncGameInfoActions = {}
							_coroutine_wait(.1)
						end
					elseif not ply.RgChatLastSyncGameInfo or ply.RgChatLastSyncGameInfo < _CurTime() then
						ply.RgChatSyncGameInfoActions = ply.RgChatSyncGameInfoActions or {}
						_table_insert(ply.RgChatSyncGameInfoActions, RealGloabalChat.Api:GetPlayerAction(ply))
						ply.RgChatLastSyncGameInfo = _CurTime() + _sync_tickrate
					end
				else
					if ply.RgChatSyncGameInfoActions then
						ply.RgChatSyncGameInfoActions = nil
					end

					if ply.RgChatLastSyncGameInfo then
						ply.RgChatLastSyncGameInfo = nil
					end
				end

				_coroutine_yield()
			end

			if can_sync then
				_coroutine_wait(.1)
				_next_sync_time = _CurTime() + _sync_delay
			end

			_coroutine_wait(.1)
		end
	end
end

RealGloabalChat:AddBackgroundWorker('game_info_sync', _Handler)