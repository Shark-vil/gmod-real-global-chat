for index, addon in ipairs(engine.GetAddons()) do
	if addon.models == 0 then continue end
	local model_list = RealGloabalChat:FoundModelsInWorkshopAddon(nil, addon.title)
	for _, model_path in ipairs(model_list) do
		RealGloabalChat.Values.AddonsModels[model_path] = index
		RealGloabalChat.Values.Addons[index] = addon.wsid
	end
end

-- -- hook.Add('InitPostEntity', 'RGChat.ScanWorkshopModels', function()
-- -- 	for index, addon in ipairs(engine.GetAddons()) do
-- -- 		if addon.models == 0 then continue end
-- -- 		local model_list = RealGloabalChat:FoundModelsInWorkshopAddon(nil, addon.title)
-- -- 		for _, model_path in ipairs(model_list) do
-- -- 			RealGloabalChat.Values.AddonsModels[model_path] = index
-- -- 			RealGloabalChat.Values.Addons[index] = addon.wsid
-- -- 		end
-- -- 	end
-- -- 	timer.Simple(3, function()
-- -- 		PrintTable(RealGloabalChat.Values.AddonsModels)
-- -- 	end)
-- -- end)


-- do
-- 	local prefix = SERVER and 'sv' or 'cl'
-- 	local valid_models_path = 'rgchat_data/' .. prefix .. '_valid_models.json'
-- 	local banned_models_path = 'rgchat_data/' .. prefix .. '_banned_models.json'
-- 	local founded_nodels = {}
-- 	local banned_models = {}
-- 	local valid_models = {}

-- 	if file.Exists(banned_models_path, 'DATA') then
-- 		banned_models = util.JSONToTable(file.Read(banned_models_path, 'DATA'))
-- 	end

-- 	if file.Exists(valid_models_path, 'DATA') then
-- 		valid_models = util.JSONToTable(file.Read(valid_models_path, 'DATA'))
-- 	end

-- 	for index, addon in ipairs(engine.GetAddons()) do
-- 		if not banned_models[addon.wsid] and addon.mounted and addon.models ~= 0 then
-- 			local model_list = RealGloabalChat:FoundModelsInWorkshopAddon(nil, addon.title)
-- 			table.insert(founded_nodels, { index = index, wsid = addon.wsid, models = model_list })
-- 			-- for _, model_path in ipairs(model_list) do
-- 			-- 	RealGloabalChat.Values.AddonsModels[model_path] = index
-- 			-- 	RealGloabalChat.Values.Addons[index] = addon.wsid
-- 			-- end
-- 		end
-- 	end

-- 	for i = #founded_nodels, 1, -1 do
-- 		local value = founded_nodels[i]
-- 		MsgN('[RGChat] Check workshop addon - ' .. value.wsid)
-- 		if SERVER or valid_models[value.wsid] then
-- 			valid_models[value.wsid] = true
-- 			for _, model_path in ipairs(value.models) do
-- 				RealGloabalChat.Values.AddonsModels[model_path] = value.index
-- 				RealGloabalChat.Values.Addons[value.index] = value.wsid
-- 			end
-- 			table.remove(founded_nodels, i)
-- 		end
-- 	end

-- 	if #founded_nodels == 0 then
-- 		MsgN('[RGChat] All workshop addons checked!')
-- 		file.Write(banned_models_path, util.TableToJSON(banned_models))
-- 		file.Write(valid_models_path, util.TableToJSON(valid_models))
-- 	else
-- 		local function task()
-- 			while #founded_nodels ~= 0 do
-- 				local value = founded_nodels[1]
-- 				table.remove(founded_nodels, 1)
-- 				MsgN('[RGChat] Check workshop addon - ' .. value.wsid)
-- 				steamworks.FileInfo(value.wsid, function(result)
-- 					if not result or result.banned or result.disabled or not result.installed then
-- 						if result.banned then banned_models[value.wsid] = true end
-- 						return
-- 					end
-- 					valid_models[value.wsid] = true
-- 					for _, model_path in ipairs(value.models) do
-- 						RealGloabalChat.Values.AddonsModels[model_path] = value.index
-- 						RealGloabalChat.Values.Addons[value.index] = value.wsid
-- 					end
-- 				end)
-- 				coroutine.wait(1)
-- 			end
-- 			file.Write(banned_models_path, util.TableToJSON(banned_models))
-- 			file.Write(valid_models_path, util.TableToJSON(valid_models))
-- 			MsgN('[RGChat] All workshop addons checked!')
-- 		end

-- 		local co = coroutine.create(task)
-- 		hook.Add('Think', 'RealGlobalChat.WorkshopAddonCheck', function()
-- 			if not coroutine.resume(co) then
-- 				hook.Remove('Think', 'RealGlobalChat.WorkshopAddonCheck')
-- 			end
-- 		end)
-- 	end
-- end