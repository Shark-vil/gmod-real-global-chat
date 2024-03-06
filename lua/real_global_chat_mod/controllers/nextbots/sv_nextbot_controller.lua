local table_sort = table.sort
local ipairs = ipairs
local IsValid = IsValid
local ents_FindByClass = ents.FindByClass
local player_GetAll = player.GetAll
local cvar_sv_real_global_chat_sync_players = GetConVar('sv_rgc_sync_players')
local cvar_dev = GetConVar('developer')

local function http_Get_Game_Info(response)
	if not response.data then return end
	local data = response.data
	local ignore_steamids = {}
	local all_players_disable = true

	for ply, active in pairs(RealGloabalChat.Values.ModActive) do
		if IsValid(ply) and active then
			all_players_disable = false
			break
		end
	end

	local bots = ents_FindByClass('rgchat_player_nextbot')

	if all_players_disable then
		if #bots > 0 then
			for _, ent in ipairs(bots) do
				if IsValid(ent) then ent:Remove() end
			end
		end
		return
	end

	if not cvar_dev:GetBool() then
		for _, ply in ipairs(player_GetAll()) do
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
			ent:Remove()
		end
	end

	for _, v in ipairs(data) do
		if not v.username or not v.steamid64 or ignore_steamids[v.steamid64] or not v.actions or #v.actions == 0 then continue end

		table_sort(v.actions, function(a, b)
			return a.last_update < b.last_update
		end)

		local ent = RealGloabalChat.Values.Nextbots[v.steamid64]
		if not ent or not IsValid(ent) then
			local first_action = v.actions[1]
			local spawn_pos
			if first_action and first_action.pos then
				spawn_pos = RealGloabalChat:PosStringToVector(first_action.pos)
			else
				local spawn_points = ents_FindByClass('info_player_start')
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

hook.Add('RGchat.FirstStart', 'RGChat.StartNextBotService', function()
	local function game_Info_Check()
		if not cvar_sv_real_global_chat_sync_players:GetBool() then return end
		RealGloabalChat:GetGameInfo(http_Get_Game_Info)
	end

	timer.Create('RealGlobalChat.GameInfo.Check', 1, 0, game_Info_Check)
end)

hook.Add('OnEntityCreated', 'RGChatSpawnRelation', function(ent)
	if ent:IsNPC() and ent.AddEntityRelationship then
		for _, bot in ipairs(ents_FindByClass('rgchat_player_nextbot')) do
			ent:AddEntityRelationship(bot, D_NU, 99)
		end
	end
end)

cvars.AddChangeCallback('sv_rgc_sync_players', function(_, _, new_value)
	if tonumber(new_value) > 0 then return end

	timer.Simple(1.5, function()
		if GetConVar('sv_rgc_sync_players'):GetBool() then return end
		local bots = ents_FindByClass('rgchat_player_nextbot')

		for i = #bots, 1, -1 do
			local ent = bots[i]

			if IsValid(ent) then
				ent:Remove()
			end
		end
	end)
end, 'on_change_sv_real_global_chat_sync_players')