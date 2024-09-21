local current_map = game.GetMap()

for index, addon in ipairs(engine.GetAddons()) do
	if not RealGloabalChat.ActiveMapWsid and file.Exists('maps/' .. current_map  .. '.bsp', addon.title) then
		RealGloabalChat.ActiveMapWsid = addon.wsid
	end
	if addon.models == 0 then continue end
	local model_list = RealGloabalChat:FoundModelsInWorkshopAddon(nil, addon.title)
	for _, model_path in ipairs(model_list) do
		if player_manager.TranslateToPlayerModelName(model_path) then
			RealGloabalChat:AddToStorage('AddonsModels', model_path, addon.wsid)
		end
	end
end