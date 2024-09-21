local cvar_list = {
	{ 'cl_rgc_status', '1', FCVAR_ARCHIVE, 'If the checkbox is active, you will see chat messages and other players on the map. They will also see you.', 0, 1 },
	{ 'cl_rgc_filter', '1', FCVAR_ARCHIVE, 'If active, questionable words will be hidden with asterisks. Only words from the prepared list will be hidden.', 0, 1 },
	{ 'cl_rgc_filter_strict', '0', FCVAR_ARCHIVE, 'If active, the message containing questionable words will be hidden completely. IMPORTANT: cl_rgc_filter must be active (cl_rgc_filter 1).', 0, 1 },
	{ 'cl_rgc_country_mode', '0', FCVAR_ARCHIVE, 'If this is active, you will connect to your country\'s chat room. IMPORTANT: you will not see a message from people in your country if they are in the world chat!', 0, 1 },
	{ 'cl_rgc_ping_sound', '1', FCVAR_ARCHIVE, 'If active, you will hear a ping sound every time someone mentions you.', 0, 1 },
	{ 'cl_rgc_visible_player_map_name', '1', FCVAR_ARCHIVE, 'If active, you will see in front of the player\'s nickname the name of the map where he is currently playing.', 0, 1 },
	{ 'cl_rgc_visible_player_id', '1', FCVAR_ARCHIVE, 'If active, you will see the player\'s ID. It\'s a number like this - #123.', 0, 1 },
	{ 'cl_rgc_visible_chat_name', '1', FCVAR_ARCHIVE, 'If enabled, the name of the chat room you are currently in will be shown before the nickname.', 0, 1 },
	{ 'cl_rgc_visible_rgc_prefix', '1', FCVAR_ARCHIVE, 'If enabled, there will be a prefix [RGC] in front of the nickname', 0, 1 },
	{ 'cl_rgc_download_model_size_limit', '50', FCVAR_ARCHIVE, 'Sets the maximum size that can be loaded to show player models on non-extbots. If you want to disable this, set the value to 0.', 0, 2048 },
	{ 'cl_rgc_translator', '1', FCVAR_ARCHIVE, 'Allows real-time translation of text into your language. If the text does not translate, try setting your language via the chat command. Example:\n/rgchattranslateto en', 0, 1 },
	{ 'cl_rgc_target_translate', '', FCVAR_ARCHIVE, 'Set translation language. Exanple: /rgchattranslateto en' },
	{ 'sv_rgc_sync_players', '1', FCVAR_ARCHIVE + FCVAR_REPLICATED, 'If active, you will see other players on the map via nexbots. You can kill bots, but real players will not take damage. At the moment, there are no interaction features yet. Nextbots have no collisions with you or your objects.', 0, 1 },
	{ 'sv_rgc_sync_entities', '0', FCVAR_ARCHIVE + FCVAR_REPLICATED, 'This option allows you to see and interact with other players\' objects. To enter the player\'s world, press E (Use) on the player\'s Nextboot.', 0, 1 },
	{ 'sv_rgc_sync_entities_view_other', '1', FCVAR_ARCHIVE + FCVAR_REPLICATED, 'If the option is enabled, you will see entities that spawn other players.', 0, 1 },
	{ 'sv_rgc_sync_entities_spawn_other', '1', FCVAR_ARCHIVE + FCVAR_REPLICATED, 'If enabled, you will spawn objects in the world of the player you connected to. IMPORTANT: YOUR ENTITIES WILL REMAIN IN THE OTHER PLAYER\'S WORLD.', 0, 1 },
	{ 'sv_rgc_http_debug', '0', FCVAR_ARCHIVE + FCVAR_REPLICATED, 'Debugging in the console for HTTP requests.', 0, 1 },
	{ 'cl_rgc_longpoll_service', '1', FCVAR_ARCHIVE + FCVAR_REPLICATED, 'The option reduces the load on the server', 0, 1 },
}

for _, v in ipairs(cvar_list) do
	local name, value, flags, helpText, min, max = v[1], v[2], v[3], v[4], v[5], v[6]
	RealGloabalChat.ConVar:Register(name, value, flags, helpText, min, max)
end