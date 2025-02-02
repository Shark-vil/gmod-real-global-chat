local _Load, _InitDataFiles

if SERVER then
	resource.AddWorkshop('3162234054')
end

function _Load(file_path)
	local mod_name = 'rgchat_core'
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

function _InitDataFiles()
	if not file.Exists('rgchat_data', 'DATA') then
		file.CreateDir('rgchat_data')
	end

	if not file.Exists('rgchat_data/verified.txt', 'DATA') then
		file.Write('rgchat_data/verified.txt', '')
	end

	if file.Exists('rgchat_data/cache', 'DATA') then
		local files, _ = file.Find('rgchat_data/cache/*.dat', 'DATA')

		for _, file_name in ipairs(files) do
			file.Delete('rgchat_data/cache/' .. file_name)
		end
	end
end

_InitDataFiles()
_Load('sh_init.lua')
_Load('modules/sh_json.lua')
_Load('override/sh_file.lua')
_Load('override/sh_player.lua')
_Load('network/sv_register_net_messages.lua')
_Load('validators/sh_client_server.lua')
_Load('language/sh_lang.lua')
_Load('language/pack/sh_english.lua')
_Load('language/pack/sh_russian.lua')
_Load('language/pack/sh_polish.lua')
_Load('convars/sh_init.lua')
_Load('convars/sh_cvar_list.lua')
_Load('convars/cl_cvar_print_changes.lua')
_Load('convars/cl_set_cvar_on_server.lua')
_Load('functions/sh_worker.lua')
_Load('functions/sh_storage.lua')
_Load('functions/cl_message_builder.lua')
_Load('functions/sh_developer.lua')
_Load('functions/sh_chat_print.lua')
_Load('functions/sh_model_parser.lua')
_Load('functions/sh_helpers.lua')
_Load('functions/sh_gma_builder.lua')
_Load('functions/sv_sync_ents.lua')
_Load('commands/cl_cmd_rgchat_switch.lua')
_Load('api/chat/cl_chat.lua')
_Load('api/chat/sh_chat.lua')
_Load('api/sv_game_info.lua')
_Load('http/sh_http.lua')
_Load('web_api/sh_init.lua')
_Load('web_api/sh_info.lua')
_Load('web_api/chat/cl_chat.lua')
_Load('web_api/chat/cl_chat_wait.lua')
_Load('web_api/translate/sh_translate.lua')
_Load('web_api/translate/sh_translate_wait.lua')
_Load('web_api/game_info/sh_game_info.lua')
_Load('web_api/game_info/sh_game_info_wait.lua')
_Load('web_api/verification/sh_verification.lua')
_Load('web_api/verification/sh_verification_wait.lua')
_Load('events/sh_mod_run.lua')
_Load('events/sh_sync_player_mod_status.lua')
_Load('events/sh_chat_player_say.lua')
_Load('events/sh_outfitter.lua')
_Load('events/sv_releport_to_player.lua')
_Load('services/cl_chat.lua')
_Load('services/sv_game_info.lua')
_Load('services/sv_prop_sync.lua')
_Load('services/nextbots/sv_nextbots.lua')
_Load('services/nextbots/cl_nextbots.lua')
_Load('services/sv_taunt.lua')
_Load('services/cl_online.lua')
_Load('gui/cl_menu.lua')
_Load('gui/cl_context.lua')
-- _Load('gui/sh_ru_warning_rkn.lua')
_Load('data/sh_color.lua')
_Load('data/sh_models.lua')
_Load('data/sh_acts.lua')
_Load('data/sh_nextbots_weapons.lua')
_Load('data/sh_nextbots_states.lua')