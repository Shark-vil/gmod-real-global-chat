local coroutine_resume = coroutine.resume
local coroutine_create = coroutine.create
local player_GetAll = player.GetAll
local IsValid = IsValid
local CurTime = CurTime
local coroutine_wait = coroutine.wait
local coroutine_yield = coroutine.yield
local table_insert = table.insert
local sync_tick = 1
local tick_time = .35
local current_time

local function task()
	current_time = CurTime() + sync_tick

	while true do
		local can_sync = current_time < CurTime()
		local players = player_GetAll()

		for i = #players, 1, -1 do
			local ply = players[i]

			if RealGloabalChat:ModIsActive(ply) then
				if can_sync then
					if ply.RgChatSyncGameInfoActions then
						RealGloabalChat:UpdateGameInfo(ply, ply.RgChatSyncGameInfoActions)
						ply.RgChatSyncGameInfoActions = {}
						coroutine_wait(.1)
					end
				elseif not ply.RgChatLastSyncGameInfo or ply.RgChatLastSyncGameInfo < CurTime() then
					ply.RgChatSyncGameInfoActions = ply.RgChatSyncGameInfoActions or {}
					table_insert(ply.RgChatSyncGameInfoActions, RealGloabalChat:GetPlayerAction(ply))
					ply.RgChatLastSyncGameInfo = CurTime() + tick_time
				end
			else
				if ply.RgChatSyncGameInfoActions then
					ply.RgChatSyncGameInfoActions = nil
				end

				if ply.RgChatLastSyncGameInfo then
					ply.RgChatLastSyncGameInfo = nil
				end
			end

			coroutine_yield()
		end

		if can_sync then
			coroutine_wait(.1)
			current_time = CurTime() + sync_tick
		end

		coroutine_wait(.1)
	end
end

hook.Add('RGchat.FirstStart', 'RGChat.StartGameInfoService', function()
	local co

	hook.Add('Think', 'RealGlobalChat.GameInfo.Check', function()
		if not co or not coroutine_resume(co) then
			co = coroutine_create(task)
			coroutine_resume(co)
		end
	end)
end)

hook.Add('PlayerDeath', 'RGChatDeathPlayerCheck', function(victim, inflictor, attacker)
	if not IsValid(victim) then return end
	victim.RGChatAttacker = attacker
	victim.RGChatInflictor = inflictor
end)