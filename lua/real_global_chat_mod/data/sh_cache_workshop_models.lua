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

hook.Add('OutfitApply', 'RGChat.UpdateCache', function(ply, model_name, download_info)
	if model_name and download_info and model_name ~= '' and download_info ~= '' then
		if not player_manager_TranslateToPlayerModelName(model_name) then return end
		RealGloabalChat.Values.AddonsModels[model_name] = download_info
		print('[RGChat] Register player model: ', model_name, download_info)
		net.Start('RealGlobalChatOnChangePlayerModel')
		net.WriteString(model_name)
		net.WriteUInt64(download_info)
		net.SendToServer()
	else
		net.Start('RealGlobalChatOnChangePlayerModel')
		net.WriteString('')
		net.WriteUInt64(0)
		net.SendToServer()
	end
end)

if SERVER then
	net.Receive('RealGlobalChatOnChangePlayerModel', function(_, ply)
		local model_name = net.ReadString()
		local download_info = net.ReadUInt64()
		if model_name == '' and download_info == 0 then
			ply.rgchat_outfitter_mdl = nil
			return
		end
		RealGloabalChat.Values.AddonsModels[model_name] = download_info
		ply.rgchat_outfitter_mdl = model_name
		print('[RGChat] Register player model: ', model_name, download_info, ply)
	end)
end

start_cache_models()