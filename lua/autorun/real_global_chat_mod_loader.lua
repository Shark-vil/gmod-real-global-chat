if SERVER then
	resource.AddWorkshop('3162234054')
end

-- RealGloabalChat = {
-- 	Values = {},
-- 	Enum = {},
-- }

-- RealGloabalChat.Values.ApiUrl = 'https://rgcgmod.vincy.ru/'
-- RealGloabalChat.Values.Version = '1.1.0'
-- -- Stores client settings on the server about whether chat is enabled or not
-- RealGloabalChat.Values.ModActive = {}
-- -- Tables for caching models from addons
-- RealGloabalChat.Values.Addons = {}
-- RealGloabalChat.Values.AddonsModels = {}
-- RealGloabalChat.Values.AddonsCacheComplete = {}
-- -- Tables for saving mod download progress states
-- RealGloabalChat.Values.AddonsDownloadedProgress = {}
-- RealGloabalChat.Values.AddonsModelsDownloadChecked = {}
-- -- Stores the state functions of nextbots
-- RealGloabalChat.Values.NextBotStates = {}
-- -- Stores a reference to the entity of all existing nexbots on the map
-- RealGloabalChat.Values.Nextbots = {}
-- -- Stores registered enumerations
-- RealGloabalChat.Values.Enum  = {}
-- RealGloabalChat.AllRegistredWeapons = {}
-- RealGloabalChat.Module = {}
-- -- RealGloabalChat.Values.Cvars = {}

-- if not file.Exists('rgchat_data', 'DATA') then
-- 	file.CreateDir('rgchat_data')
-- end

-- if not file.Exists('rgchat_data/verified.txt', 'DATA') then
-- 	file.Write('rgchat_data/verified.txt', '')
-- end

-- if file.Exists('rgchat_data/cache', 'DATA') then
-- 	local files, _ = file.Find('rgchat_data/cache/*.dat', 'DATA')
-- 	for _, file_name in ipairs(files) do
-- 		file.Delete('rgchat_data/cache/' .. file_name)
-- 	end
-- end

local mod_name = 'rgchat_core'

local function load(file_path)
	local file_name = string.GetFileFromFilename(file_path)
	local prefix = string.sub(file_name, 1, 2)

	if SERVER then
		if prefix == 'cl' or prefix == 'sh' then
			AddCSLuaFile(mod_name .. '/' .. file_path)
		end

		if prefix == 'sv' or prefix == 'sh' then
			include(mod_name .. '/' .. file_path)
			print('[RGChat] Load - ' .. mod_name .. '/' .. file_path)
		end
	elseif prefix == 'cl' or prefix == 'sh' then
		include(mod_name .. '/' .. file_path)
		print('[RGChat] Load - ' .. mod_name .. '/' .. file_path)
	end
end


load('sh_init.lua')
load('network/sv_register_net_messages.lua')
load('validators/sh_client_server.lua')
load('language/sh_lang.lua')
load('language/pack/sh_english.lua')
load('language/pack/sh_russian.lua')
load('language/pack/sh_polish.lua')
load('convars/sh_init.lua')
load('convars/sh_cvar_list.lua')
load('commands/cl_cmd_rgchat_switch.lua')
load('api/cl_chat.lua')
load('http/sh_http.lua')
load('web_api/sh_init.lua')
load('web_api/cl_chat.lua')
load('events/sh_mod_run.lua')
load('events/sh_sync_player_mod_status.lua')
load('services/cl_chat.lua')

-- load('sh_lang.lua')
-- load('sh_cvars.lua')

-- load('modules/sh_json.lua')
-- load('core/sh_run.lua')

-- load('services/sh_helper_service.lua')
-- load('services/sh_service.lua')
-- load('services/sh_translate_service.lua')
-- load('services/sh_workshop_service.lua')
-- load('services/sh_nextbot_service.lua')

-- load('data/sh_acts.lua')
-- load('data/sh_cache_workshop_models.lua')

-- load('net/sv_net_register.lua')
-- load('net/cl_net_receives.lua')

-- load('controllers/chat/sv_chat_controller.lua')
-- load('controllers/chat/cl_chat_controller.lua')
-- load('controllers/chat/cl_online.lua')
-- load('controllers/game_info/sv_game_info_controller.lua')
-- load('controllers/game_info/sv_entities_sync.lua')

-- load('controllers/nextbots/sv_nextbot_controller.lua')
-- load('controllers/nextbots/cl_nextbot_controller.lua')

-- load('override/sh_file.lua')

-- load('cl_menu.lua')