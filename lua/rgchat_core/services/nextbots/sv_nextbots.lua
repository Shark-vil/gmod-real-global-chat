-- Variables
local _last_update, _ents_FindByClass, _ipairs, _IsValid, _table_sort
-- Functions
local _RemoveAllBots
--Set Variables
_ents_FindByClass = ents.FindByClass
_ipairs = ipairs
_IsValid = IsValid
_table_sort = table.sort

function _RemoveAllBots()
	for _, ent in _ipairs(_ents_FindByClass('rgchat_player_nextbot')) do
		if _IsValid(ent) then
			SafeRemoveEntity(ent)
		end
	end
end

local function _Handler()
	while true do
		if not RealGloabalChat.ConVar:GetBool('sv_rgc_sync_players') then
			_RemoveAllBots()
		else
			local code, response = RealGloabalChat.WebApi.GameInfo:GetGameInfoWait(_last_update)

			if code == 200 and response and response.success and response.success == 1 then
				local data = response.data
				local ignore_steamids = {}
				local valid_bots = {}
				local all_players_disable = true

				for _, ply in _ipairs(player.GetHumans()) do
					if RealGloabalChat.Api:PlayerChatIsActive(ply) then
						all_players_disable = false
						break
					end
				end

				if all_players_disable then
					_RemoveAllBots()

					return
				end

				if not RealGloabalChat.ConVar:GetBool('developer') then
					for _, ply in _ipairs(player.GetHumans()) do
						if _IsValid(ply) then
							ignore_steamids[ply:SteamID64()] = true
						end
					end
				end

				for _, ent in _ipairs(_ents_FindByClass('rgchat_player_nextbot')) do
					local is_valid = false

					for _, v in _ipairs(data) do
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

				for _, v in _ipairs(data) do
					if not v.username or not v.steamid64 or ignore_steamids[v.steamid64] or not v.actions or #v.actions == 0 then continue end

					_table_sort(v.actions, function(a, b)
						return a.last_update < b.last_update
					end)

					for _, action in _ipairs(v.actions) do
						if not _last_update or _last_update < action.last_update then
							_last_update = action.last_update
						end
					end

					local ent = valid_bots[v.steamid64]

					if not ent or not _IsValid(ent) then
						local first_action = v.actions[1]
						local spawn_pos

						if first_action and first_action.pos then
							spawn_pos = RealGloabalChat:PosStringToVector(first_action.pos)
						else
							local spawn_points = _ents_FindByClass('info_player_start')
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
		end

		coroutine.wait(1)
	end
end

RealGloabalChat:AddBackgroundWorker('nextbots', _Handler)