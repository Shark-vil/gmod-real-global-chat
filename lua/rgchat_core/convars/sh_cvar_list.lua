local cvar_list = {
	{ 'cl_rgc_status', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_filter', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_filter_strict', '0', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_country_mode', '0', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_ping_sound', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_visible_player_map_name', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_download_model_size_limit', '50', FCVAR_ARCHIVE, '', 0, 2048 },
	{ 'cl_rgc_translator', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_target_translate', '', FCVAR_ARCHIVE, '' },
	{ 'sv_rgc_sync_players', '1', FCVAR_ARCHIVE + FCVAR_REPLICATED, '', 0, 1 },
	{ 'sv_rgc_sync_entities', '0', FCVAR_ARCHIVE + FCVAR_REPLICATED, '', 0, 1 },
}

for _, v in ipairs(cvar_list) do
	local name, value, flags, helpText, min, max = v[1], v[2], v[3], v[4], v[5], v[6]
	RealGloabalChat.ConVar:Register(name, value, flags, helpText, min, max)
end