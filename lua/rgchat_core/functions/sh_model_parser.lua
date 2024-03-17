local _file_Find = file.Find
local _ipairs = ipairs
local _table_insert = table.insert
local _string_GetExtensionFromFilename = string.GetExtensionFromFilename

function RealGloabalChat:FoundModelsInWorkshopAddon(current_dir, file_type, models_list)
	current_dir = current_dir or 'models'
	models_list = models_list or {}
	local files, dirs = _file_Find(current_dir .. '/*', file_type)

	for _, file_name in _ipairs(files) do
		local file_ext = _string_GetExtensionFromFilename(file_name)

		if file_ext == 'mdl' then
			_table_insert(models_list, current_dir .. '/' .. file_name)
		end
	end

	for _, dir_name in _ipairs(dirs) do
		local next_parse_dir = current_dir ~= '' and current_dir .. '/' .. dir_name or dir_name
		models_list = RealGloabalChat:FoundModelsInWorkshopAddon(next_parse_dir, file_type, models_list)
	end

	return models_list
end