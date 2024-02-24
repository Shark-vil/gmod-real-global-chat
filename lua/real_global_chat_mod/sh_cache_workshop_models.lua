for index, addon in ipairs(engine.GetAddons()) do
	if addon.models == 0 then continue end
	local model_list = RealGloabalChat:FoundModelsInWorkshopAddon(nil, addon.title)
	for _, model_path in ipairs(model_list) do
		RealGloabalChat.Values.AddonsModels[model_path] = index
		RealGloabalChat.Values.Addons[index] = addon.wsid
	end
end