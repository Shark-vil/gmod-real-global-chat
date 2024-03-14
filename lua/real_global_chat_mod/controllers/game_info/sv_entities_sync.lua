local cvar_break_prop_replacer = GetConVar('breakprops_change_playerspawn_prop')
local last_entity_removed = 0
local cvar_sv_rgc_sync_entities = GetConVar('sv_rgc_sync_entities')

local function isActiveEntsSync()
	return cvar_sv_rgc_sync_entities:GetBool()
end

local function updateEntityNetData(ent, net_ent)
	ent.RgChatNetId = net_ent.net_id
	ent.RgChatOwnerEntIndex = net_ent.ent_index
	ent.RgChatHostSteamId64 =  net_ent.host_steamid64
	ent.RgChatNetData = net_ent
	ent:SetNWString('RgChatNetId', tostring(ent.RgChatNetId))
	ent:SetNWString('RgChatOwnerEntIndex', tostring(ent.RgChatOwnerEntIndex))
end

local function addNewEntitiesUpdate()
	while true do
		local players = player.GetAll()

		for i = #players, 1, -1 do
			local ply = players[i]

			if RealGloabalChat:ModIsActive(ply) then
				if ply.RgChatRemovedEntities and #ply.RgChatRemovedEntities ~= 0 then
					RealGloabalChat:CleanupEntities(ply, ply.RgChatRemovedEntities)
					last_entity_removed = CurTime() + 1
					ply.RgChatRemovedEntities = {}
				end

				if ply.RgChatSpawnedEntities and #ply.RgChatSpawnedEntities ~= 0 then
					local wait_get_entities = true
					local sended_entities = table.Copy(ply.RgChatSpawnedEntities)
					ply.RgChatSpawnedEntities = {}

					RealGloabalChat:AddEntities(ply, sended_entities, function(response)
						wait_get_entities = false

						if response and response.success == 1 then
							for _, net_ent in ipairs(response.entities) do
								for _, sended_ent in ipairs(sended_entities) do
									if IsValid(sended_ent) and sended_ent:EntIndex() == net_ent.ent_index then
										updateEntityNetData(sended_ent, net_ent)
									end
								end
							end
						end
					end)

					while wait_get_entities do
						coroutine.yield()
					end
				end
			else
				if ply.RgChatSpawnedEntities then
					ply.RgChatSpawnedEntities = nil
				end
			end

			coroutine.yield()
		end

		coroutine.wait(1)
	end
end

local function updateEntityOptions(ent, net_ent)
	if ent.RgChatCanUpdateEnt then return end

	for _, ply in ipairs(player.GetAll()) do
		if ent.RgChatHostSteamId64 == ply:SteamID64() then return end
	end

	local pos = RealGloabalChat:PosStringToVector(net_ent.pos)
	local ang = RealGloabalChat:PosStringToAngle(net_ent.ang)

	if pos then ent:SetPos(pos) end
	if ang then ent:SetAngles(ang) end
end

local function getEntitiesFromOwnerUpdate()
	while true do
		for _, ply in ipairs(player.GetAll()) do
			local wait_get_entities = true
			local owner_steamid64 = ply:SteamID64()
			RealGloabalChat:GetEntities(owner_steamid64, function(response)
				wait_get_entities = false
				if response and response.success == 1 then
					local network_entities_count = #response.entities
					if network_entities_count == 0 then return end

					for _, ent in ipairs(ents.GetAll()) do
						if not ent.RgChatNetId then continue end
						for _, net_ent in ipairs(response.entities) do
							if ent.RgChatNetId == net_ent.net_id then
								updateEntityNetData(ent, net_ent)
								updateEntityOptions(ent, net_ent)
								break
							end
						end
					end
				end
			end)

			while wait_get_entities do
				coroutine.yield()
			end

			coroutine.yield()
		end

		coroutine.wait(1)
	end
end

local function entitiesUpdateState()
	while true do
		local valid_entities = {}

		for _, ent in ipairs(ents.GetAll()) do
			if not ent.RgChatNetId or not IsValid(ent.RgChatOwner) then continue end

			local is_external_owner = true
			for _, ply in ipairs(player.GetAll()) do
				if ent.RgChatHostSteamId64 == ply:SteamID64() then
					is_external_owner = false
					break
				end
			end

			if not is_external_owner then
				valid_entities[ent.RgChatOwner] = valid_entities[ent.RgChatOwner] or {}
				table.insert(valid_entities[ent.RgChatOwner], ent)
			end
		end

		if table.Count(valid_entities) == 0 then return end

		for ply, entities in pairs(valid_entities) do
			if IsValid(ply) then
				local wait_get_entities = true
				RealGloabalChat:UpdateEntities(ply, entities, function()
					wait_get_entities = false
				end)

				while wait_get_entities do
					coroutine.yield()
				end
			end
			coroutine.yield()
		end

		coroutine.wait(1)
	end
end

local function getEntitiesUpdate()
	while true do
		local sync_target_list = {}

		for _, ply in ipairs(player.GetAll()) do
			if ply.RgChatRemovedEntities and #ply.RgChatRemovedEntities ~= 0 then continue end
			local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')
			if rgc_sync_target == '' then continue end
			sync_target_list[rgc_sync_target] = true
		end

		for target_steamid64, _ in pairs(sync_target_list) do
			local wait_get_entities = true

			RealGloabalChat:GetEntities(target_steamid64, function(response)
				wait_get_entities = false

				if last_entity_removed > CurTime() then
					return
				end

				if response and response.success == 1 then
					local network_entities_count = #response.entities
					if network_entities_count == 0 then return end

					for _, ent in ipairs(ents.GetAll()) do
						if not ent.RgChatNetId then continue end
						local is_valid = false
						local net_ent

						for i = #response.entities, 1, -1 do
							net_ent = response.entities[i]

							if net_ent.net_id == ent.RgChatNetId then
								is_valid = true
								table.remove(response.entities, i)
								break
							end
						end

						if not is_valid then
							ent:Remove()
						elseif net_ent then
							updateEntityNetData(ent, net_ent)
							updateEntityOptions(ent, net_ent)
						end
					end

					for _, net_ent in ipairs(response.entities) do
						local pos = RealGloabalChat:PosStringToVector(net_ent.pos)
						local ang = RealGloabalChat:PosStringToAngle(net_ent.ang)
						local ent = ents.Create(net_ent.class_name)
						ent:SetModel(net_ent.model)
						ent:SetPos(pos)
						ent:SetAngles(ang)
						ent:Spawn()
						updateEntityNetData(ent, net_ent)

						for _, ply in ipairs(player.GetAll()) do
							if net_ent.owner_steamid64 == ply:SteamID64() then
								ent.RgChatOwner = ply
								undo.Create(string.StartsWith(ent:GetClass(), 'prop_') and 'Prop' or 'Entity')
								undo.AddEntity(ent)
								undo.SetPlayer(ply)
								undo.Finish()
								break
							end
						end
					end
				end
			end)

			while wait_get_entities do
				coroutine.yield()
			end

			coroutine.yield()
		end

		coroutine.wait(1)
	end
end

do
	local co

	hook.Add('Think', 'RealGlobalChat.AddNewEntities', function()
		if not isActiveEntsSync() then return end
		if not co or not coroutine.resume(co) then
			co = coroutine.create(addNewEntitiesUpdate)
			coroutine.resume(co)
		end
	end)
end

do
	local co

	hook.Add('Think', 'RealGlobalChat.GetEntities', function()
		if not isActiveEntsSync() then return end
		if not co or not coroutine.resume(co) then
			co = coroutine.create(getEntitiesUpdate)
			coroutine.resume(co)
		end
	end)
end

do
	local co

	hook.Add('Think', 'RealGlobalChat.GetEntitiesFromOwner', function()
		if not isActiveEntsSync() then return end
		if not co or not coroutine.resume(co) then
			co = coroutine.create(getEntitiesFromOwnerUpdate)
			coroutine.resume(co)
		end
	end)
end

do
	local co

	hook.Add('Think', 'RealGlobalChat.UpdateEntitiesInfo', function()
		if not isActiveEntsSync() then return end
		if not co or not coroutine.resume(co) then
			co = coroutine.create(entitiesUpdateState)
			coroutine.resume(co)
		end
	end)
end

hook.Add('RGChat.SetPlayerSyncTarget', 'RGChatUpdateSyncProps', function(_, target_id, enabled)
	local sync_exists = false

	for _, ply in ipairs(player.GetAll()) do
		local rgc_sync_target = ply:GetNWString('RGC_SYNC_TARGET', '')

		if ply:SteamID64() == target_id then
			return
		end

		if rgc_sync_target == target_id then
			sync_exists = true
			break
		end
	end

	if sync_exists then return end

	for _, ent in ipairs(ents.GetAll()) do
		if ent.RgChatNetId and ent.RgChatNetData.owner_steamid64 == target_id then
			SafeRemoveEntity(ent)
		end
	end
end)

local function spawned_entity(ply, data, model)
	if cvar_break_prop_replacer and cvar_break_prop_replacer:GetBool() then
		timer.Simple(.1, function()
			local ent = data.ent

			if not IsValid(ent) and model then
				local entities = ents.FindInSphere(data.pos, 10)
				for _, v in ipairs(entities) do
					if v:GetPos():DistToSqr(v.pos) <= 25 then
						ent = v
						break
					end
				end
			end

			if not IsValid(ent) then return end

			ply.RgChatSpawnedEntities = ply.RgChatSpawnedEntities or {}
			ent.RgChatOwner = ply
			table.insert(ply.RgChatSpawnedEntities, ent)
		end)
	else
		local ent = data.ent
		ply.RgChatSpawnedEntities = ply.RgChatSpawnedEntities or {}
		ent.RgChatOwner = ply
		table.insert(ply.RgChatSpawnedEntities, ent)
	end
end

hook.Add('PlayerSpawnedProp', 'RGChat.EntSyncPlayerSpawnedProp', function(ply, model, ent)
	spawned_entity(ply, { ent = ent, pos = ent:GetPos() }, model)
end)

hook.Add('PlayerSpawnedSENT', 'RGChat.EntSyncPlayerSpawnedSENT', function(ply, model, ent)
	spawned_entity(ply, { ent = ent, pos = ent:GetPos() })
end)

hook.Add('PlayerSpawnedNPC', 'RGChat.EntSyncPlayerSpawnedNPC', function(ply, ent)
	spawned_entity(ply, { ent = ent, pos = ent:GetPos() })
end)

hook.Add('PostCleanupMap', 'RgChat.EntSyncPostCleanupMap', function()
	for _, ply in ipairs(player.GetAll()) do
		ply.RgChatSpawnedEntities = {}
		ply.RgChatRemovedEntities = {}
		RealGloabalChat:CleanupEntities(ply)
	end
end)

hook.Add('EntityRemoved', 'RgChat.EntSyncEntityRemoved', function(ent)
	if not ent.RgChatNetId then return end
	local ply = ent.RgChatOwner
	if not IsValid(ply) then return end

	if ply.RgChatSpawnedEntities then
		for index, save_ent in ipairs(ply.RgChatSpawnedEntities) do
			if save_ent == ent then
				table.remove(ply.RgChatSpawnedEntities, index)
				break
			end
		end
	end

	if not isActiveEntsSync() then return end

	ply.RgChatRemovedEntities = ply.RgChatRemovedEntities or {}
	table.insert(ply.RgChatRemovedEntities, { net_id = ent.RgChatNetId })
	last_entity_removed = CurTime() + 1
end)

hook.Add('OnPhysgunPickup', 'RgChat.OnPhysgunPickup', function(ply, ent)
	if not isActiveEntsSync() then return end
	if not ent.RgChatNetId or ent.RgChatNetData.host_steamid64 == ply:SteamID64() then return end

	RealGloabalChat:UpdateEntities(ply, { ent }, function(response)
		if response and response.success == 1 then
			ent.RgChatCanUpdateEnt = true
			ent.RgChatHostSteamId64 = ply:SteamID64()
		end
	end)
end)

hook.Add('PhysgunDrop', 'RgChat.PhysgunDrop', function(ply, ent)
	if not ent.RgChatNetId or not ent.RgChatCanUpdateEnt then return end
	ent.RgChatCanUpdateEnt = false
end)