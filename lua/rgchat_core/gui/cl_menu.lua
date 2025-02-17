-- Variables
local _game_GetMap = game.GetMap
local _table_sort = table.sort
local _file_Exists = file.Exists
local _clr_current_map = Color(22, 255, 239)
local _clr_another_map = Color(255, 138, 29)
local _clr_download_map = Color(240, 114, 234)
local _material_boosty, _material_discord, _main_frame, _check_maps_list
-- Set variables
_material_boosty = Material('artist/shark_vil/boosty.png')
_material_discord = Material('artist/shark_vil/discord.png')
_material_verification = Material('rgchat/verification.png')
_check_maps_list = {}

local function openSettingsMenu()
	local Language = RealGloabalChat.Language
	local cvar_cl_swapskin_darkui_enabled = GetConVar('cl_swapskin_darkui_enabled')
	local cvar_cl_rgc_download_model_size_limit = RealGloabalChat.ConVar:GetInt('cl_rgc_download_model_size_limit')

	local function base_setup_element(element, dock_value, cvar_name, options)
		if (not options or not options.nosize) and isfunction(element.SizeToContents) then
			element:SizeToContents()
		end
		if (not options or not options.nodock) and isfunction(element.Dock) then
			element:Dock(TOP)
		end

		if isfunction(element.SetTextColor) then
			if isstring(cvar_name) then
				local cvar_object = GetConVar(cvar_name)
				local function get_color()
					if cvar_object:GetBool() then
						return Color(166, 255, 206)
					else
						return Color(255, 198, 198)
					end
				end
				element:SetTextColor(get_color())
				if string.StartsWith(cvar_name, 'sv') then
					local old_value = cvar_object:GetBool()
					local timer_name = 'RGChatMenuCheckCvar_' .. cvar_name
					timer.Create(timer_name, 1, 0, function()
						if not IsValid(element) then
							timer.Remove(timer_name)
							return
						end
						if old_value ~= cvar_object:GetBool() then
							element:SetTextColor(get_color())
							old_value = cvar_object:GetBool()
						end
					end)
				else
					cvars.AddChangeCallback(cvar_name, function()
						if not IsValid(element) then return end
						element:SetTextColor(get_color())
					end, 'menu_update_color')
				end
			else
				element:SetTextColor(Color(255, 255, 255))
			end
		end

		if isfunction(element.DockMargin) then
			if not dock_value then
				element:DockMargin(15, 0, 15, 15)
			elseif isnumber(dock_value) then
				element:DockMargin(dock_value, dock_value, dock_value, dock_value)
			elseif istable(dock_value) then
				element:DockMargin(dock_value[1], dock_value[2], dock_value[3], dock_value[4])
			end
		end

		if isfunction(element.SetWrap) then
			element:SetWrap(true)
		end
	end

	if IsValid(_main_frame) then
		_main_frame:Remove()
	end

	_main_frame = vgui.Create('DFrame')
	_main_frame:SetTitle('RGChat Menu')
	_main_frame:SetSize(700, 450)
	_main_frame:Center()
	_main_frame:SetSizable(true)
	_main_frame:SetDraggable(true)
	_main_frame:MakePopup()

	local _tab_menu = vgui.Create('DPropertySheet', _main_frame)
	_tab_menu:Dock(FILL)

	local _tab_settings = vgui.Create('DPanel', _tab_menu)
	local _tab_verify_settings = vgui.Create('DPanel', _tab_menu)
	local _tab_players_settings = vgui.Create('DPanel', _tab_menu)

	_tab_menu:AddSheet('Settings', _tab_settings, 'icon16/world_edit.png')
	_tab_menu:AddSheet('Verefication', _tab_verify_settings, 'icon16/tick.png')
	_tab_menu:AddSheet('Players', _tab_players_settings, 'icon16/user_suit.png')

	local verify_panel = vgui.Create('DPanel', _tab_verify_settings)
	verify_panel:Dock(FILL)
	verify_panel:SetBackgroundColor(Color(27, 27, 27))

	local verify_scroll_panel = vgui.Create('DScrollPanel', verify_panel)
	verify_scroll_panel:Dock(FILL)

	local verification_button = verify_scroll_panel:Add('DButton')
	verification_button:SetText('')
	verification_button:SetHeight(50)
	function verification_button:Paint(w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(_material_verification)
		surface.DrawTexturedRect(0, 0, w, h)
	end
	function verification_button:DoClick()
		local function verification_task()
			local code, response
			local ply = LocalPlayer()
			code, response = RealGloabalChat.WebApi.Verification:PreparationVerificationWait(ply)
			if code ~= 200 or not response or not response.success or response.success == 0 or not response.message then
				RealGloabalChat:PrintWarning('Something went wrong! Repeat the attempt later.')
				return
			end
			local guid_address = response.message
			gui.OpenURL('https://rgcgmod.vincy.ru/Verification/' .. ply:SteamID64())
			while IsValid(_main_frame) do
				code, response = RealGloabalChat.WebApi.Verification:CheckVerificationWait(ply, guid_address)
				if code == 200 and response and response.success and response.success == 1 and response.message then
					file.Write('rgchat_data/verified.txt', response.message)
					RealGloabalChat:Print('Verification was successful!')
					break
				end
				coroutine.yield()
			end
		end

		local co = coroutine.create(verification_task)
		hook.Add('Think', 'RGC_Start_Verification', function()
			if not coroutine.resume(co) then
				hook.Remove('Think', 'RGC_Start_Verification')
			end
		end)

		-- RealGloabalChat.WebApi.Verification:PreparationVerification(LocalPlayer(), function(code, response)
		-- 	print(code, response)
		-- end)

		-- gui.OpenURL('https://rgcgmod.vincy.ru/Chat/Verification/' + LocalPlayer():SteamID64())
	end
	verification_button:Dock(TOP)
	verification_button:DockMargin(15, 15, 15, 15)

	local label_verification = verify_scroll_panel:Add('DLabel')
	label_verification:SetText(Language:Get('menu_rgc_verification_desc'))
	label_verification:SetFont('CreditsText')
	label_verification:SetAutoStretchVertical(true)
	base_setup_element(label_verification)

	local main_panel = vgui.Create('DPanel', _tab_settings)
	main_panel:Dock(FILL)
	main_panel:SetBackgroundColor(Color(27, 27, 27))

	local scroll_panel = vgui.Create('DScrollPanel', main_panel)
	scroll_panel:Dock(FILL)

	local checkbox_modstate = scroll_panel:Add('DCheckBoxLabel')
	checkbox_modstate:SetConVar('cl_rgc_status')
	checkbox_modstate:SetText(Language:Get('menu_rgc_status'))
	checkbox_modstate:SetTooltip(Language:Get('menu_rgc_status_desc'))
	checkbox_modstate:SetFont('Trebuchet24')
	base_setup_element(checkbox_modstate, { 15, 15, 15, 0 }, 'cl_rgc_status')

	local label_modstate = scroll_panel:Add('DLabel')
	label_modstate:SetText(Language:Get('menu_rgc_status_desc'))
	label_modstate:SetFont('CreditsText')
	label_modstate:SetAutoStretchVertical(true)
	base_setup_element(label_modstate)

	local checkbox_longpoll_service = scroll_panel:Add('DCheckBoxLabel')
	checkbox_longpoll_service:SetConVar('cl_rgc_longpoll_service_beta')
	checkbox_longpoll_service:SetText(Language:Get('menu_rgc_longpoll_service'))
	checkbox_longpoll_service:SetTooltip(Language:Get('menu_rgc_longpoll_service_desc'))
	checkbox_longpoll_service:SetFont('Trebuchet24')
	base_setup_element(checkbox_longpoll_service, { 15, 15, 15, 0 }, 'cl_rgc_longpoll_service_beta')

	local label_longpoll_service = scroll_panel:Add('DLabel')
	label_longpoll_service:SetText(Language:Get('menu_rgc_longpoll_service_desc'))
	label_longpoll_service:SetFont('CreditsText')
	label_longpoll_service:SetAutoStretchVertical(true)
	base_setup_element(label_longpoll_service)

	local checkbox_translator = scroll_panel:Add('DCheckBoxLabel')
	checkbox_translator:SetConVar('cl_rgc_translator')
	checkbox_translator:SetText(Language:Get('menu_rgc_translator'))
	checkbox_translator:SetTooltip(Language:Get('menu_rgc_translator_desc'))
	checkbox_translator:SetFont('Trebuchet24')
	base_setup_element(checkbox_translator, { 15, 5, 15, 0 }, 'cl_rgc_translator')

	local label_translator = scroll_panel:Add('DLabel')
	label_translator:SetText(Language:Get('menu_rgc_translator_desc'))
	label_translator:SetFont('CreditsText')
	label_translator:SetAutoStretchVertical(true)
	base_setup_element(label_translator)

	local checkbox_country = scroll_panel:Add('DCheckBoxLabel')
	checkbox_country:SetConVar('cl_rgc_country_mode')
	checkbox_country:SetText(Language:Get('menu_rgc_country_mode'))
	checkbox_country:SetTooltip(Language:Get('menu_rgc_country_mode_desc'))
	checkbox_country:SetFont('Trebuchet24')
	base_setup_element(checkbox_country, { 15, 5, 15, 0 }, 'cl_rgc_country_mode')

	local label_country = scroll_panel:Add('DLabel')
	label_country:SetText(Language:Get('menu_rgc_country_mode_desc'))
	label_country:SetFont('CreditsText')
	label_country:SetAutoStretchVertical(true)
	base_setup_element(label_country)

	local checkbox_mapname = scroll_panel:Add('DCheckBoxLabel')
	checkbox_mapname:SetConVar('cl_rgc_visible_player_map_name')
	checkbox_mapname:SetText(Language:Get('menu_rgc_visible_player_map_name'))
	checkbox_mapname:SetTooltip(Language:Get('menu_rgc_visible_player_map_name_desc'))
	checkbox_mapname:SetFont('Trebuchet24')
	base_setup_element(checkbox_mapname, { 15, 5, 15, 0 }, 'cl_rgc_visible_player_map_name')

	local label_mapname = scroll_panel:Add('DLabel')
	label_mapname:SetText(Language:Get('menu_rgc_visible_player_map_name_desc'))
	label_mapname:SetFont('CreditsText')
	label_mapname:SetAutoStretchVertical(true)
	base_setup_element(label_mapname)

	local checkbox_rgctag = scroll_panel:Add('DCheckBoxLabel')
	checkbox_rgctag:SetConVar('cl_rgc_visible_rgc_prefix')
	checkbox_rgctag:SetText(Language:Get('menu_rgc_visible_rgc_prefix'))
	checkbox_rgctag:SetTooltip(Language:Get('menu_rgc_visible_rgc_prefix_desc'))
	checkbox_rgctag:SetFont('Trebuchet24')
	base_setup_element(checkbox_rgctag, { 15, 5, 15, 0 }, 'cl_rgc_visible_rgc_prefix')

	local label_rgctag = scroll_panel:Add('DLabel')
	label_rgctag:SetText(Language:Get('menu_rgc_visible_rgc_prefix_desc'))
	label_rgctag:SetFont('CreditsText')
	label_rgctag:SetAutoStretchVertical(true)
	base_setup_element(label_rgctag)

	local checkbox_chatname = scroll_panel:Add('DCheckBoxLabel')
	checkbox_chatname:SetConVar('cl_rgc_visible_chat_name')
	checkbox_chatname:SetText(Language:Get('menu_rgc_visible_chat_name'))
	checkbox_chatname:SetTooltip(Language:Get('menu_rgc_visible_chat_name_desc'))
	checkbox_chatname:SetFont('Trebuchet24')
	base_setup_element(checkbox_chatname, { 15, 5, 15, 0 }, 'cl_rgc_visible_chat_name')

	local label_chatname = scroll_panel:Add('DLabel')
	label_chatname:SetText(Language:Get('menu_rgc_visible_chat_name_desc'))
	label_chatname:SetFont('CreditsText')
	label_chatname:SetAutoStretchVertical(true)
	base_setup_element(label_chatname)

	local checkbox_playerid = scroll_panel:Add('DCheckBoxLabel')
	checkbox_playerid:SetConVar('cl_rgc_visible_player_id')
	checkbox_playerid:SetText(Language:Get('menu_rgc_visible_player_id'))
	checkbox_playerid:SetTooltip(Language:Get('menu_rgc_visible_player_id_desc'))
	checkbox_playerid:SetFont('Trebuchet24')
	base_setup_element(checkbox_playerid, { 15, 5, 15, 0 }, 'cl_rgc_visible_player_id')

	local label_playerid = scroll_panel:Add('DLabel')
	label_playerid:SetText(Language:Get('menu_rgc_visible_player_id_desc'))
	label_playerid:SetFont('CreditsText')
	label_playerid:SetAutoStretchVertical(true)
	base_setup_element(label_playerid)

	local checkbox_message_sfx = scroll_panel:Add('DCheckBoxLabel')
	checkbox_message_sfx:SetConVar('cl_rgc_new_message_sound')
	checkbox_message_sfx:SetText(Language:Get('menu_rgc_message_sound'))
	checkbox_message_sfx:SetTooltip(Language:Get('menu_rgc_message_sound_desc'))
	checkbox_message_sfx:SetFont('Trebuchet24')
	base_setup_element(checkbox_message_sfx, { 15, 5, 15, 0 }, 'cl_rgc_new_message_sound')

	local label_message_sfx = scroll_panel:Add('DLabel')
	label_message_sfx:SetText(Language:Get('menu_rgc_message_sound_desc'))
	label_message_sfx:SetFont('CreditsText')
	label_message_sfx:SetAutoStretchVertical(true)
	base_setup_element(label_message_sfx)

	local checkbox_ping = scroll_panel:Add('DCheckBoxLabel')
	checkbox_ping:SetConVar('cl_rgc_ping_sound')
	checkbox_ping:SetText(Language:Get('menu_rgc_ping_sound'))
	checkbox_ping:SetTooltip(Language:Get('menu_rgc_ping_sound_desc'))
	checkbox_ping:SetFont('Trebuchet24')
	base_setup_element(checkbox_ping, { 15, 5, 15, 0 }, 'cl_rgc_ping_sound')

	local label_ping = scroll_panel:Add('DLabel')
	label_ping:SetText(Language:Get('menu_rgc_ping_sound_desc'))
	label_ping:SetFont('CreditsText')
	label_ping:SetAutoStretchVertical(true)
	base_setup_element(label_ping)

	local checkbox_ping_by_coincidence = scroll_panel:Add('DCheckBoxLabel')
	checkbox_ping_by_coincidence:SetConVar('cl_rgc_ping_by_coincidence')
	checkbox_ping_by_coincidence:SetText(Language:Get('menu_rgc_ping_by_coincidence'))
	checkbox_ping_by_coincidence:SetTooltip(Language:Get('menu_rgc_ping_by_coincidence_desc'))
	checkbox_ping_by_coincidence:SetFont('Trebuchet24')
	base_setup_element(checkbox_ping_by_coincidence, { 15, 5, 15, 0 }, 'cl_rgc_ping_by_coincidence')

	local label_ping_by_coincidence = scroll_panel:Add('DLabel')
	label_ping_by_coincidence:SetText(Language:Get('menu_rgc_ping_by_coincidence_desc'))
	label_ping_by_coincidence:SetFont('CreditsText')
	label_ping_by_coincidence:SetAutoStretchVertical(true)
	base_setup_element(label_ping_by_coincidence)

	local checkbox_filter = scroll_panel:Add('DCheckBoxLabel')
	checkbox_filter:SetConVar('cl_rgc_filter')
	checkbox_filter:SetText(Language:Get('menu_rgc_filter'))
	checkbox_filter:SetTooltip(Language:Get('menu_rgc_filter_desc'))
	checkbox_filter:SetFont('Trebuchet24')
	base_setup_element(checkbox_filter, { 15, 5, 15, 0 }, 'cl_rgc_filter')

	local label_filter = scroll_panel:Add('DLabel')
	label_filter:SetText(Language:Get('menu_rgc_filter_desc'))
	label_filter:SetFont('CreditsText')
	label_filter:SetAutoStretchVertical(true)
	base_setup_element(label_filter)

	local checkbox_filter_strict = scroll_panel:Add('DCheckBoxLabel')
	checkbox_filter_strict:SetConVar('cl_rgc_filter_strict')
	checkbox_filter_strict:SetText(Language:Get('menu_rgc_filter_strict'))
	checkbox_filter_strict:SetTooltip(Language:Get('menu_rgc_filter_strict_desc'))
	checkbox_filter_strict:SetFont('Trebuchet24')
	base_setup_element(checkbox_filter_strict, { 15, 5, 15, 0 }, 'cl_rgc_filter_strict')

	local label_filter_strict = scroll_panel:Add('DLabel')
	label_filter_strict:SetText(Language:Get('menu_rgc_filter_strict_desc'))
	label_filter_strict:SetFont('CreditsText')
	label_filter_strict:SetAutoStretchVertical(true)
	base_setup_element(label_filter_strict)

	local checkbox_filter_family = scroll_panel:Add('DCheckBoxLabel')
	checkbox_filter_family:SetConVar('cl_rgc_filter_family')
	checkbox_filter_family:SetText(Language:Get('menu_rgc_filter_family'))
	checkbox_filter_family:SetTooltip(Language:Get('menu_rgc_filter_family_desc'))
	checkbox_filter_family:SetFont('Trebuchet24')
	base_setup_element(checkbox_filter_family, { 15, 5, 15, 0 }, 'cl_rgc_filter_family')

	local label_filter_family = scroll_panel:Add('DLabel')
	label_filter_family:SetText(Language:Get('menu_rgc_filter_family_desc'))
	label_filter_family:SetFont('CreditsText')
	label_filter_family:SetAutoStretchVertical(true)
	base_setup_element(label_filter_family)

	local checkbox_syncplayers = scroll_panel:Add('DCheckBoxLabel')
	checkbox_syncplayers:SetConVar('sv_rgc_sync_players')
	checkbox_syncplayers:SetText(Language:Get('menu_rgc_sync_players'))
	checkbox_syncplayers:SetTooltip(Language:Get('menu_rgc_sync_players_desc'))
	checkbox_syncplayers:SetFont('Trebuchet24')
	base_setup_element(checkbox_syncplayers, { 15, 5, 15, 0 }, 'sv_rgc_sync_players')

	local label_syncplayers = scroll_panel:Add('DLabel')
	label_syncplayers:SetText(Language:Get('menu_rgc_sync_players_desc'))
	label_syncplayers:SetFont('CreditsText')
	label_syncplayers:SetAutoStretchVertical(true)
	base_setup_element(label_syncplayers)

	local checkbox_syncprops = scroll_panel:Add('DCheckBoxLabel')
	checkbox_syncprops:SetConVar('sv_rgc_sync_entities')
	checkbox_syncprops:SetText(Language:Get('menu_rgc_sync_props'))
	checkbox_syncprops:SetTooltip(Language:Get('menu_rgc_sync_props_desc'))
	checkbox_syncprops:SetFont('Trebuchet24')
	base_setup_element(checkbox_syncprops, { 15, 5, 15, 0 }, 'sv_rgc_sync_entities')

	local label_syncprops = scroll_panel:Add('DLabel')
	label_syncprops:SetText(Language:Get('menu_rgc_sync_props_desc'))
	label_syncprops:SetFont('CreditsText')
	label_syncprops:SetAutoStretchVertical(true)
	base_setup_element(label_syncprops)

	local checkbox_syncprops_view_other = scroll_panel:Add('DCheckBoxLabel')
	checkbox_syncprops_view_other:SetConVar('sv_rgc_sync_entities_view_other')
	checkbox_syncprops_view_other:SetText(Language:Get('menu_rgc_sync_entities_view_other'))
	checkbox_syncprops_view_other:SetTooltip(Language:Get('menu_rgc_sync_entities_view_other_desc'))
	checkbox_syncprops_view_other:SetFont('Trebuchet24')
	base_setup_element(checkbox_syncprops_view_other, { 15, 5, 15, 0 }, 'sv_rgc_sync_entities_view_other')

	local label_syncprops_view_other = scroll_panel:Add('DLabel')
	label_syncprops_view_other:SetText(Language:Get('menu_rgc_sync_entities_view_other_desc'))
	label_syncprops_view_other:SetFont('CreditsText')
	label_syncprops_view_other:SetAutoStretchVertical(true)
	base_setup_element(label_syncprops_view_other)

	local checkbox_syncprops_spawn_other = scroll_panel:Add('DCheckBoxLabel')
	checkbox_syncprops_spawn_other:SetConVar('sv_rgc_sync_entities_spawn_other')
	checkbox_syncprops_spawn_other:SetText(Language:Get('menu_rgc_sync_entities_spawn_other'))
	checkbox_syncprops_spawn_other:SetTooltip(Language:Get('menu_rgc_sync_entities_spawn_other_desc'))
	checkbox_syncprops_spawn_other:SetFont('Trebuchet24')
	base_setup_element(checkbox_syncprops_spawn_other, { 15, 5, 15, 0 }, 'sv_rgc_sync_entities_spawn_other')

	local label_syncprops_spawn_other = scroll_panel:Add('DLabel')
	label_syncprops_spawn_other:SetText(Language:Get('menu_rgc_sync_entities_spawn_other_desc'))
	label_syncprops_spawn_other:SetFont('CreditsText')
	label_syncprops_spawn_other:SetAutoStretchVertical(true)
	base_setup_element(label_syncprops_spawn_other)

	local title_pmmodelsize = scroll_panel:Add('DLabel')
	title_pmmodelsize:SetText(Language:Get('menu_rgc_download_model_size_limit'))
	title_pmmodelsize:SetFont('Trebuchet24')
	title_pmmodelsize:SetAutoStretchVertical(true)
	base_setup_element(title_pmmodelsize, { 15, 5, 15, 10 })

	local panel_pmmodelsize = scroll_panel:Add('DPanel')
	panel_pmmodelsize:SetHeight(45)
	panel_pmmodelsize:SetBackgroundColor(Color(61, 61, 61))
	base_setup_element(panel_pmmodelsize)

	local slider_dark_mode = 0
	if cvar_cl_swapskin_darkui_enabled and cvar_cl_swapskin_darkui_enabled:GetBool() then
		slider_dark_mode = 1
	end

	local slider_pmmodelsize = vgui.Create('DNumSlider', panel_pmmodelsize)
	slider_pmmodelsize:SetMin(0)
	slider_pmmodelsize:SetMax(1024)
	slider_pmmodelsize:SetDecimals(0)
	slider_pmmodelsize:SetConVar('cl_rgc_download_model_size_limit')
	slider_pmmodelsize:SetText(Language:Get('menu_rgc_download_model_size_limit'))
	slider_pmmodelsize:SetTooltip(Language:Get('menu_rgc_download_model_size_limit_desc'))
	slider_pmmodelsize:SetDark(slider_dark_mode)
	function slider_pmmodelsize:OnValueChanged(new_value)
		local new_value_number = tonumber(new_value)
		timer.Create('RGChatMenuSetNewModelSizeLimit', 1, 1, function()
			if new_value_number and new_value_number == cvar_cl_rgc_download_model_size_limit then
				return
			end
			cvar_cl_rgc_download_model_size_limit = RealGloabalChat.ConVar:GetInt('cl_rgc_download_model_size_limit')
			if not new_value_number or new_value_number <= 0 then
				RunConsoleCommand('say', '/rgchatwslimit 0')
			else
				RunConsoleCommand('say', '/rgchatwslimit ' .. new_value_number)
			end
		end)
	end
	base_setup_element(slider_pmmodelsize, { 15, 5, 15, 0 })

	local label_pmmodelsize = scroll_panel:Add('DLabel')
	label_pmmodelsize:SetText(Language:Get('menu_rgc_download_model_size_limit_desc'))
	label_pmmodelsize:SetFont('CreditsText')
	label_pmmodelsize:SetAutoStretchVertical(true)
	base_setup_element(label_pmmodelsize)

	local title_chat_commands = scroll_panel:Add('DLabel')
	title_chat_commands:SetText('Chat commands')
	title_chat_commands:SetFont('Trebuchet24')
	title_chat_commands:SetAutoStretchVertical(true)
	base_setup_element(title_chat_commands, { 15, 5, 15, 0 })

	local label_help = scroll_panel:Add('DLabel')
	label_help:SetFont('CreditsText')
	label_help:SetText([[Open menu:
- /rgchat

Enable global chat mod:
- /rgchaton

Disable global chat mod:
- /rgchatoff

Change get messages mode:
- /rgchatlongpoll

Mute or unmute player:
- /rgchatmute ID
- Example: /rgchatmute #23 or rgchatmute 23

Ping player:
- /ping NICK or NICK, [any text]

Nextboot switch:
- /rgchatplayers

Leave the world of the player:
- /rgcleaveworld

Set player model limit:
- /rgchatwslimit NUMBER
- Example: /rgchatwslimit 150
- Disable: /rgchatwslimit 0

Country mode switch:
- /rgchatmode

Filter switch:
- /rgchatfilter

Strict filter switch:
- /rgchatfilterstrict

Family filter switch:
- /rgchatfilterfamily

Player map visibility switch:
- /rgchatmap

Ping SFX switch:
- /rgchatpingsfx

Set translation language
- /rgchattranslateto LANGUAGE_CODE
- Exanple: /rgchattranslateto en]])
	base_setup_element(label_help)

	-- local image_boosty = scroll_panel:Add('DButton')
	-- image_boosty:SetText('')
	-- image_boosty:SetHeight(135)
	-- function image_boosty:Paint(w, h)
	-- 	surface.SetDrawColor(255, 255, 255, 255)
	-- 	surface.SetMaterial(_material_boosty)
	-- 	surface.DrawTexturedRect(0, 0, w, h)
	-- end
	-- function image_boosty:DoClick()
	-- 	gui.OpenURL('https://boosty.to/shark_vil')
	-- end
	-- image_boosty:Dock(TOP)
	-- image_boosty:DockMargin(15, 15, 15, 15)

	local image_discord = scroll_panel:Add('DButton')
	image_discord:SetText('')
	image_discord:SetHeight(135)
	function image_discord:Paint(w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(_material_discord)
		surface.DrawTexturedRect(0, 0, w, h)
	end
	function image_discord:DoClick()
		gui.OpenURL('https://discord.gg/wZwtQTU')
	end
	image_discord:Dock(TOP)
	image_discord:DockMargin(15, 15, 15, 15)

	local space_element = scroll_panel:Add('DLabel')
	space_element:SetText('')
	space_element:SetHeight(20)
	base_setup_element(space_element)

	local players_panel = vgui.Create('DPanel', _tab_players_settings)
	players_panel:Dock(FILL)
	players_panel:SetBackgroundColor(Color(27, 27, 27))

	-- local label_players_scroll_panel_info = vgui.Create('DLabel', players_panel)
	-- label_players_scroll_panel_info:SetText('DEV: This menu is in development!')
	-- label_players_scroll_panel_info:SetFont('CreditsText')
	-- label_players_scroll_panel_info:SetAutoStretchVertical(true)
	-- base_setup_element(label_players_scroll_panel_info)

	local help_list_panel = vgui.Create('DIconLayout', players_panel)
	help_list_panel:Dock(TOP)
	help_list_panel:SetSpaceY(1)
	help_list_panel:SetSpaceX(6)

	do
		local clr_alpha = Color(0, 0, 0, 0)
		local clr_white = Color(255, 255, 255)

		local function add_help_block(text, color)
			local help_block_panel = help_list_panel:Add('DPanel')
			help_block_panel:SetSize(150, 40)
			help_block_panel.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, w, h, clr_alpha)
			end

			local color_block = vgui.Create('DPanel', help_block_panel)
			color_block:SetSize(20, 20)
			color_block:SetPos(15, 10)
			color_block.Paint = function(self, w, h)
				draw.RoundedBox(4, 0, 0, w, h, color)
			end

			local label_block = vgui.Create('DLabel', help_block_panel)
			label_block:SetText(text)
			label_block:SetFont('CreditsText')
			label_block:SetWrap(true)
			label_block:Dock(FILL)
			base_setup_element(label_block, { 40, 0, 0, 0}, nil, { nodock = true })
		end

		add_help_block('Current map', _clr_current_map)
		add_help_block('Is already uploaded', _clr_another_map)
		add_help_block('Will be downloaded', _clr_download_map)
		add_help_block('Invalid map', clr_white)
	end

	local connect_process = false
	local players_scroll_panel = vgui.Create('DScrollPanel', players_panel)
	players_scroll_panel:Dock(FILL)

	local function update_players_scroll_panel(arguments)
		if not IsValid(players_scroll_panel) or not IsValid(_main_frame) then
			timer.Remove('rgchat_players_scroll_panel')
			return
		end

		RealGloabalChat.WebApi.Chat:GetOnline(function(code, body)
			if not IsValid(players_scroll_panel) then return end
			if code ~= 200 or not body or not istable(body.players_on_world) or body.players_on_world_count == 0 then return end

			local old_scroll_pos = players_scroll_panel:GetVBar():GetScroll()

			players_scroll_panel:Remove()

			players_scroll_panel = vgui.Create('DScrollPanel', players_panel)
			players_scroll_panel:DockMargin(0, 10, 0, 0)
			players_scroll_panel:Dock(FILL)

			if body.players_on_world_count > 1 then
				local _isstring = isstring
				local current_map = _game_GetMap()
				_table_sort(body.players_on_world, function(a, b)
					-- Текущая карта вверху списка
					if a.map == current_map and b.map ~= current_map then return true end
					if b.map == current_map and a.map ~= current_map then return false end

					-- WEB пользователи в самом низу списка
					local a_isweb = a.map and a.map == 'web'
					local b_isweb = b.map and b.map == 'web'
					if a_isweb then return false end
					if b_isweb then return true end

					-- Карты без скачивания внизу списка, но выше чем WEB
					local a_invalid = not a.map_wsid or not a.map
					local b_invalid = not b.map_wsid or not b.map
					if a_invalid and not b_invalid then return false end
					if b_invalid and not a_invalid then return true end

					-- Сортировка по алфавиту
					return a.map < b.map
				end)
			end

			for _, item in ipairs(body.players_on_world) do
				if item.map and not _check_maps_list[item.map] then
					_check_maps_list[item.map] = {
						can_connect = item.map_wsid ~= nil or _file_Exists('maps/' .. item.map  .. '.bsp', 'GAME'),
						can_map_exists = _file_Exists('maps/' .. item.map  .. '.bsp', 'GAME')
					}
				end

				local can_connect = item.map and _check_maps_list[item.map] and _check_maps_list[item.map].can_connect
				local can_map_exists = item.map and _check_maps_list[item.map] and _check_maps_list[item.map].can_map_exists

				local connect_button = players_scroll_panel:Add('DButton')
				connect_button:SetHeight(40)
				if can_connect then
					connect_button:SetText('TELEPORT | ' .. item.username .. ' | ' .. item.map)
				else
					connect_button:SetText(item.username .. ' | ' .. item.map)
				end
				connect_button:SetFont('CreditsText')
				connect_button:Dock(TOP)

				if can_connect then
					if can_map_exists and _game_GetMap() == item.map then
						connect_button:SetColor(_clr_current_map)
					elseif can_map_exists and _game_GetMap() ~= item.map then
						connect_button:SetColor(_clr_another_map)
					elseif not can_map_exists then
						connect_button:SetColor(_clr_download_map)
					end
				end

				if can_connect then
					function connect_button:DoClick()
						if connect_process then return end
						connect_process = true

						if can_map_exists then
							if game.GetMap() ~= item.map then
								RunConsoleCommand('changelevel', item.map)
								return
							end
							net.Start('RGChat_TeleportToPlayer')
							net.WriteString(item.steamid64)
							net.SendToServer()
							connect_process = false
						elseif item.map_wsid ~= nil then
							steamworks.FileInfo(item.map_wsid, function(result)
								if not result or result.banned or result.disabled then
									return
								end

								steamworks.DownloadUGC(item.map_wsid, function(path)
									if not path then return end

									local ok, files = game.MountGMA(path)
									if not ok then return end

									for _, v in ipairs(files) do
										if v == 'maps/' .. item.map  .. '.bsp' then
											RunConsoleCommand('changelevel', item.map)
											break
										end
									end
								end)
							end)
						else
							connect_process = false
						end
					end
				end
			end

			if old_scroll_pos then
				timer.Simple(.01, function()
					if IsValid(players_scroll_panel) then
						players_scroll_panel:GetVBar():SetScroll(old_scroll_pos)
					end
				end)
			end
		end)
	end

	update_players_scroll_panel()

	timer.Create('rgchat_players_scroll_panel', 5, 0, update_players_scroll_panel)
end
concommand.Add('rgchat_menu', openSettingsMenu)