local _last_update

local function _Handler()
	local code, response = RealGloabalChat.WebApi.GameInfo:GetGameInfoWait(_last_update)

	if code == 200 and response and response.success and response.success == 1 then
		local data = response.data
		local ignore_steamids = {}
		local valid_bots = {}
		local all_players_disable = true
		local bots

		for _, ply in ipairs(player.GetHumans()) do
			if RealGloabalChat.Api:PlayerChatIsActive(ply) then
				all_players_disable = false
				break
			end
		end

		bots = ents.FindByClass('rgchat_player_nextbot')

		if all_players_disable then
			for _, ent in ipairs(bots) do
				if IsValid(ent) then
					SafeRemoveEntity(ent)
				end
			end

			return
		end

		if not RealGloabalChat.ConVar:GetBool('developer') then
			for _, ply in ipairs(player.GetHumans()) do
				if IsValid(ply) then
					ignore_steamids[ply:SteamID64()] = true
				end
			end
		end

		for _, ent in ipairs(bots) do
			local is_valid = false

			for _, v in ipairs(data) do
				if v.steamid64 == ent.BotData.SteamId64 then
					is_valid = true
					break
				end
			end

			if not is_valid then
				ent:RgChatDisconnected()
				ent:Remove()
			else
				valid_bots[ent.BotData.SteamId64] = ent
			end
		end

		for _, v in ipairs(data) do
			if not v.username or not v.steamid64 or ignore_steamids[v.steamid64] or not v.actions or #v.actions == 0 then continue end

			table.sort(v.actions, function(a, b)
				return  a.last_update < b.last_update
			end)

			for _, action in ipairs(v.actions) do
				if not _last_update or _last_update < action.last_update then
					_last_update = action.last_update
				end
			end

			local ent = valid_bots[v.steamid64]

			if not ent or not IsValid(ent) then
				local first_action = v.actions[1]
				local spawn_pos

				if first_action and first_action.pos then
					spawn_pos = RealGloabalChat:PosStringToVector(first_action.pos)
				else
					local spawn_points = ents.FindByClass('info_player_start')
					spawn_pos = #spawn_points == 0 and Vector(0, 0, 0) or spawn_points[1]:GetPos()
				end

				ent = ents.Create('rgchat_player_nextbot')
				ent:SetPos(spawn_pos)
				ent:Spawn()
				ent:SetData(v)
			else
				ent:UpdateData(v)
			end
		end
	end

	coroutine.wait(1)
end

RealGloabalChat:AddBackgroundWorker('nextbots', _Handler)