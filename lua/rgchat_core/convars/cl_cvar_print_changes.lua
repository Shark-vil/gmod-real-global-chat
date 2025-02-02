local _Language, _ConVar
_Language = RealGloabalChat.Language
_ConVar = RealGloabalChat.ConVar

cvars.AddChangeCallback('cl_rgc_status', function(_, _, new_value)
	local is_active = tostring(new_value) == '1'
	RealGloabalChat:Print(is_active and _Language:Get('rgchat_on') or _Language:Get('rgchat_off'))
end, 'print_changes')

cvars.AddChangeCallback('cl_rgc_longpoll_service', function(_, _, new_value)
	local is_active = tostring(new_value) == '1'
	RealGloabalChat:Print(is_active and _Language:Get('rgchat_on_longpoll_service') or _Language:Get('rgchat_off_longpoll_service'))
end, 'print_changes')

cvars.AddChangeCallback('cl_rgc_ping_sound', function(_, _, new_value)
	local is_active = tostring(new_value) == '1'
	RealGloabalChat:Print(is_active and _Language:Get('rgchat_ping_sfx_on') or _Language:Get('rgchat_ping_sfx_off'))
end, 'print_changes')

cvars.AddChangeCallback('cl_rgc_visible_player_map_name', function(_, _, new_value)
	local is_active = tostring(new_value) == '1'
	RealGloabalChat:Print(is_active and _Language:Get('rgchat_mapname_on') or _Language:Get('rgchat_mapname_off'))
end, 'print_changes')

cvars.AddChangeCallback('cl_rgc_country_mode', function(_, _, new_value)
	local is_active = tostring(new_value) == '1'
	RealGloabalChat:Print(is_active and _Language:Get('rgchat_on_type_country') or _Language:Get('rgchat_on_type_world'))
end, 'print_changes')

cvars.AddChangeCallback('cl_rgc_filter', function(_, _, new_value)
	local is_active = tostring(new_value) == '1'
	RealGloabalChat:Print(is_active and _Language:Get('rgchat_on_filter') or _Language:Get('rgchat_off_filter'))
end, 'print_changes')

cvars.AddChangeCallback('cl_rgc_filter_strict', function(_, _, new_value)
	local is_active = tostring(new_value) == '1'
	RealGloabalChat:Print(is_active and _Language:Get('rgchat_on_filter_strict') or _Language:Get('rgchat_off_filter_strict'))
	-- if is_active and not _ConVar:GetBool('cl_rgc_filter') then
	-- 	RealGloabalChat:Print(_Language:Get('rgchat_filter_strict_warn'))
	-- end
end, 'print_changes')

cvars.AddChangeCallback('cl_rgc_filter_family', function(_, _, new_value)
	local is_active = tostring(new_value) == '1'
	RealGloabalChat:Print(is_active and _Language:Get('rgchat_on_filter_family') or _Language:Get('rgchat_off_filter_family'))
end, 'print_changes')