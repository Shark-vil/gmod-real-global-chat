local registred_cvars = {
	{ 'cl_rgc_status', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_filter', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_filter_strict', '0', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_country_mode', '0', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_ping_sound', '0', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_visible_player_map_name', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_download_model_size_limit', '100', FCVAR_ARCHIVE, '', 0, 2048 },
	{ 'cl_rgc_translator', '1', FCVAR_ARCHIVE, '', 0, 1 },
	{ 'cl_rgc_target_translate', '', FCVAR_ARCHIVE, '' },
	{ 'sv_rgc_sync_players', '1', FCVAR_ARCHIVE + FCVAR_REPLICATED, '', 0, 1 },
}

for _, v in ipairs(registred_cvars) do
	local name, value, flags, helpText, min, max = v[1], v[2], v[3], v[4], v[5], v[6]
	if (CLIENT and string.StartsWith(name, 'cl')) or (SERVER and string.StartsWith(name, 'sv')) then
		CreateConVar(name, value, flags, helpText, min, max)
	end
end

-- function RealGloabalChat:GetCvar(name)
-- 	if not RealGloabalChat.Values.Cvars[name] then
-- 		RealGloabalChat.Values.Cvars[name] = GetConVar(name)
-- 	end
-- 	return RealGloabalChat.Values.Cvars[name]
-- end

if CLIENT then
	concommand.Add('rgchat_switch', function()
		local lang = RealGloabalChat.Values.Language
		local status_value = GetConVar('cl_rgc_status'):GetInt() == 1 and 0 or 1

		if status_value == 0 then
			LocalPlayer():ChatPrint(lang['rgchat_off'])
		else
			LocalPlayer():ChatPrint(lang['rgchat_on'])
		end

		RunConsoleCommand('cl_rgc_status', status_value)
	end)
end

