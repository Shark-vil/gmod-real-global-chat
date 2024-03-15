local ipairs = ipairs
local engine_GetAddons = engine.GetAddons
local player_manager_TranslateToPlayerModelName = player_manager.TranslateToPlayerModelName

local function start_cache_models()
	for index, addon in ipairs(engine_GetAddons()) do
		if RealGloabalChat.Values.AddonsCacheComplete[addon.wsid] then
			continue
		end
		if addon.models ~= 0 then
			local model_list = RealGloabalChat:FoundModelsInWorkshopAddon(nil, addon.title)
			for _, model_path in ipairs(model_list) do
				if player_manager_TranslateToPlayerModelName(model_path) then
					RealGloabalChat.Values.AddonsModels[model_path] = addon.wsid
					-- print('[RGChat] Register player model: ', model_path, addon.wsid)
				end
			end
		end
		RealGloabalChat.Values.AddonsCacheComplete[addon.wsid] = true
	end
end

if CLIENT then
	timer.Create('RGChat.CheckOutfitter', 1, 0, function()
		local ply = LocalPlayer()
		if not ply.outfitter_mdl and ply.rgchat_outfitter then
			net.Start('RealGlobalChatOnChangePlayerModel')
			net.WriteString('')
			net.WriteUInt64(0)
			net.SendToServer()
			ply.rgchat_outfitter = false
			return
		end

		if not ply.outfitter_mdl then return end

		local ply_bodygroups = ''
		for _, v in ipairs(ply:GetBodyGroups()) do
			local bodygroup = ply:GetBodygroup(v.id)
			if ply.outfitter_bodygroups and ply.outfitter_bodygroups[v.name] then
				bodygroup = ply.outfitter_bodygroups[v.name]
			end
			ply_bodygroups = ply_bodygroups .. bodygroup
		end

		if (ply.outfitter_skin or 1) ~= ply.rgchat_outfitter_skin or ply_bodygroups ~= ply.rgchat_outfitter_bodygroups then
			ply.rgchat_outfitter_skin = ply.outfitter_skin or 1
			ply.rgchat_outfitter_bodygroups = ply_bodygroups

			net.Start('RealGlobalChatOnChangePlayerModel')
			net.WriteString(ply.outfitter_mdl)
			net.WriteUInt64(ply.outfitter_download_info)
			net.WriteInt(ply.rgchat_outfitter_skin, 16)
			net.WriteString(ply.rgchat_outfitter_bodygroups)
			net.SendToServer()
		end
	end)
end

hook.Add('OutfitApply', 'RGChat.UpdateCache', function(ply, model_name, download_info)
	print('OutfitApply', 'asdsad')
	if model_name and download_info and model_name ~= '' and download_info ~= '' then
		-- if not player_manager_TranslateToPlayerModelName(model_name) then return end
		RealGloabalChat.Values.AddonsModels[model_name] = download_info
		print('[RGChat] Register player model: ', model_name, download_info)

		ply.rgchat_outfitter = true

		local ply_bodygroups = ''
		for _, v in ipairs(ply:GetBodyGroups()) do
			local bodygroup = ply:GetBodygroup(v.id)
			if ply.outfitter_bodygroups and ply.outfitter_bodygroups[v.name] then
				bodygroup = ply.outfitter_bodygroups[v.name]
			end
			ply_bodygroups = ply_bodygroups .. bodygroup
		end

		ply.rgchat_outfitter_skin = ply.outfitter_skin or 1
		ply.rgchat_outfitter_bodygroups = ply_bodygroups

		net.Start('RealGlobalChatOnChangePlayerModel')
		net.WriteString(model_name)
		net.WriteUInt64(download_info)
		net.WriteInt(ply.rgchat_outfitter_skin, 16)
		net.WriteString(ply.rgchat_outfitter_bodygroups)
		net.SendToServer()
	else
		ply.rgchat_outfitter = false

		net.Start('RealGlobalChatOnChangePlayerModel')
		net.WriteString('')
		net.WriteUInt64(0)
		net.WriteInt(0, 16)
		net.WriteString('')
		net.SendToServer()
	end
end)

if SERVER then
	net.Receive('RealGlobalChatOnChangePlayerModel', function(_, ply)
		local model_name = net.ReadString()
		local download_info = net.ReadUInt64()
		local outfitter_skin = net.ReadInt(16)
		local outfitter_bodygroups = net.ReadString()

		if model_name == '' and download_info == 0 then
			ply.rgchat_outfitter_mdl = nil
			ply.rgchat_outfitter_skin = nil
			ply.rgchat_outfitter_bodygroups = nil
			return
		end

		ply.rgchat_outfitter_skin = outfitter_skin

		if outfitter_bodygroups and outfitter_bodygroups ~= '' then
			ply.rgchat_outfitter_bodygroups = outfitter_bodygroups
		else
			ply.rgchat_outfitter_bodygroups = nil
		end

		RealGloabalChat.Values.AddonsModels[model_name] = download_info
		ply.rgchat_outfitter_mdl = model_name
		print('[RGChat] Register player model: ', model_name, download_info, ply)
	end)
end

start_cache_models()