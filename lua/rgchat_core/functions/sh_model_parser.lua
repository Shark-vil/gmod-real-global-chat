function RealGloabalChat:FoundModelsInWorkshopAddon(current_dir, file_type, models_list)
	current_dir = current_dir or 'models'
	models_list = models_list or {}
	local files, dirs = file.Find(current_dir .. '/*', file_type)

	for _, file_name in ipairs(files) do
		local file_ext = string.GetExtensionFromFilename(file_name)

		if file_ext == 'mdl' then
			table.insert(models_list, current_dir .. '/' .. file_name)
		end
	end

	for _, dir_name in ipairs(dirs) do
		local next_parse_dir = current_dir ~= '' and current_dir .. '/' .. dir_name or dir_name
		models_list = RealGloabalChat:FoundModelsInWorkshopAddon(next_parse_dir, file_type, models_list)
	end

	return models_list
end