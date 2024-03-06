local function open_menu()
	local lang = RealGloabalChat.Values.Language
	local cvar_rgc_download_model_size_limit = GetConVar('cl_rgc_download_model_size_limit')

	local function base_setup_element(element, dock_value, cvar_name)
		if isfunction(element.SizeToContents) then
			element:SizeToContents()
		end
		if isfunction(element.Dock) then
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

	local main_frame = vgui.Create('DFrame')
	main_frame:SetTitle('RGChat Menu')
	main_frame:SetSize(500, 450)
	main_frame:Center()
	main_frame:SetDraggable(true)
	main_frame:MakePopup()

	local main_panel = vgui.Create('DPanel', main_frame)
	main_panel:Dock(FILL)
	main_panel:SetBackgroundColor(Color(0, 0, 0))

	local scroll_panel = vgui.Create('DScrollPanel', main_panel)
	scroll_panel:Dock(FILL)

	local checkbox_modstate = scroll_panel:Add('DCheckBoxLabel')
	checkbox_modstate:SetConVar('cl_rgc_status')
	checkbox_modstate:SetText(lang['menu_rgc_status'])
	checkbox_modstate:SetTooltip(lang['menu_rgc_status_desc'])
	checkbox_modstate:SetFont('Trebuchet24')
	base_setup_element(checkbox_modstate, { 15, 15, 15, 0 }, 'cl_rgc_status')

	local label_modstate = scroll_panel:Add('DLabel')
	label_modstate:SetText(lang['menu_rgc_status_desc'])
	label_modstate:SetFont('GModToolHelp')
	label_modstate:SetAutoStretchVertical(true)
	base_setup_element(label_modstate)

	local checkbox_translator = scroll_panel:Add('DCheckBoxLabel')
	checkbox_translator:SetConVar('cl_rgc_translator')
	checkbox_translator:SetText(lang['menu_rgc_translator'])
	checkbox_translator:SetTooltip(lang['menu_rgc_translator_desc'])
	checkbox_translator:SetFont('Trebuchet24')
	base_setup_element(checkbox_translator, { 15, 5, 15, 0 }, 'cl_rgc_translator')

	local label_translator = scroll_panel:Add('DLabel')
	label_translator:SetText(lang['menu_rgc_translator_desc'])
	label_translator:SetFont('GModToolHelp')
	label_translator:SetAutoStretchVertical(true)
	base_setup_element(label_translator)

	local checkbox_country = scroll_panel:Add('DCheckBoxLabel')
	checkbox_country:SetConVar('cl_rgc_country_mode')
	checkbox_country:SetText(lang['menu_rgc_country_mode'])
	checkbox_country:SetTooltip(lang['menu_rgc_country_mode_desc'])
	checkbox_country:SetFont('Trebuchet24')
	base_setup_element(checkbox_country, { 15, 5, 15, 0 }, 'cl_rgc_country_mode')

	local label_country = scroll_panel:Add('DLabel')
	label_country:SetText(lang['menu_rgc_country_mode_desc'])
	label_country:SetFont('GModToolHelp')
	label_country:SetAutoStretchVertical(true)
	base_setup_element(label_country)

	local checkbox_mapname = scroll_panel:Add('DCheckBoxLabel')
	checkbox_mapname:SetConVar('cl_rgc_visible_player_map_name')
	checkbox_mapname:SetText(lang['menu_rgc_visible_player_map_name'])
	checkbox_mapname:SetTooltip(lang['menu_rgc_visible_player_map_name_desc'])
	checkbox_mapname:SetFont('Trebuchet24')
	base_setup_element(checkbox_mapname, { 15, 5, 15, 0 }, 'cl_rgc_visible_player_map_name')

	local label_mapname = scroll_panel:Add('DLabel')
	label_mapname:SetText(lang['menu_rgc_visible_player_map_name_desc'])
	label_mapname:SetFont('GModToolHelp')
	label_mapname:SetAutoStretchVertical(true)
	base_setup_element(label_mapname)

	local checkbox_ping = scroll_panel:Add('DCheckBoxLabel')
	checkbox_ping:SetConVar('cl_rgc_ping_sound')
	checkbox_ping:SetText(lang['menu_rgc_ping_sound'])
	checkbox_ping:SetTooltip(lang['menu_rgc_ping_sound_desc'])
	checkbox_ping:SetFont('Trebuchet24')
	base_setup_element(checkbox_ping, { 15, 5, 15, 0 }, 'cl_rgc_ping_sound')

	local label_ping = scroll_panel:Add('DLabel')
	label_ping:SetText(lang['menu_rgc_ping_sound_desc'])
	label_ping:SetFont('GModToolHelp')
	label_ping:SetAutoStretchVertical(true)
	base_setup_element(label_ping)

	local checkbox_filter = scroll_panel:Add('DCheckBoxLabel')
	checkbox_filter:SetConVar('cl_rgc_filter')
	checkbox_filter:SetText(lang['menu_rgc_filter'])
	checkbox_filter:SetTooltip(lang['menu_rgc_filter_desc'])
	checkbox_filter:SetFont('Trebuchet24')
	base_setup_element(checkbox_filter, { 15, 5, 15, 0 }, 'cl_rgc_filter')

	local label_filter = scroll_panel:Add('DLabel')
	label_filter:SetText(lang['menu_rgc_filter_desc'])
	label_filter:SetFont('GModToolHelp')
	label_filter:SetAutoStretchVertical(true)
	base_setup_element(label_filter)

	local checkbox_filter_strict = scroll_panel:Add('DCheckBoxLabel')
	checkbox_filter_strict:SetConVar('cl_rgc_filter_strict')
	checkbox_filter_strict:SetText(lang['menu_rgc_filter_strict'])
	checkbox_filter_strict:SetTooltip(lang['menu_rgc_filter_strict_desc'])
	checkbox_filter_strict:SetFont('Trebuchet24')
	base_setup_element(checkbox_filter_strict, { 15, 5, 15, 0 }, 'cl_rgc_filter_strict')

	local label_filter_strict = scroll_panel:Add('DLabel')
	label_filter_strict:SetText(lang['menu_rgc_filter_strict_desc'])
	label_filter_strict:SetFont('GModToolHelp')
	label_filter_strict:SetAutoStretchVertical(true)
	base_setup_element(label_filter_strict)

	local checkbox_syncplayers = scroll_panel:Add('DCheckBoxLabel')
	checkbox_syncplayers:SetConVar('sv_rgc_sync_players')
	checkbox_syncplayers:SetText(lang['menu_rgc_sync_players'])
	checkbox_syncplayers:SetTooltip(lang['menu_rgc_sync_players_desc'])
	checkbox_syncplayers:SetFont('Trebuchet24')
	base_setup_element(checkbox_syncplayers, { 15, 5, 15, 0 }, 'sv_rgc_sync_players')

	local label_syncplayers = scroll_panel:Add('DLabel')
	label_syncplayers:SetText(lang['menu_rgc_sync_players_desc'])
	label_syncplayers:SetFont('GModToolHelp')
	label_syncplayers:SetAutoStretchVertical(true)
	base_setup_element(label_syncplayers)

	local title_pmmodelsize = scroll_panel:Add('DLabel')
	title_pmmodelsize:SetText(lang['menu_rgc_download_model_size_limit'])
	title_pmmodelsize:SetFont('Trebuchet24')
	title_pmmodelsize:SetAutoStretchVertical(true)
	base_setup_element(title_pmmodelsize, { 15, 5, 15, 0 })

	local slider_pmmodelsize = scroll_panel:Add('DNumSlider')
	slider_pmmodelsize:SetMin(0)
	slider_pmmodelsize:SetMax(1024)
	slider_pmmodelsize:SetDecimals(0)
	slider_pmmodelsize:SetConVar('cl_rgc_download_model_size_limit')
	slider_pmmodelsize:SetText(lang['menu_rgc_download_model_size_limit'])
	slider_pmmodelsize:SetTooltip(lang['menu_rgc_download_model_size_limit_desc'])
	slider_pmmodelsize:SetDark(1)
	local pmmodelsize_old_value = cvar_rgc_download_model_size_limit:GetInt()
	function slider_pmmodelsize:OnValueChanged(new_value)
		local new_value_number = tonumber(new_value)
		timer.Create('RGChatMenuSetNewModelSizeLimit', 1, 1, function()
			if new_value_number and new_value_number == pmmodelsize_old_value then
				return
			end
			pmmodelsize_old_value = cvar_rgc_download_model_size_limit:GetInt()
			if not new_value_number or new_value_number <= 0 then
				RunConsoleCommand('say', '/rgchatwslimit 0')
			else
				RunConsoleCommand('say', '/rgchatwslimit ' .. new_value_number)
			end
		end)
	end
	base_setup_element(slider_pmmodelsize, { 15, 5, 15, 0 })

	local label_pmmodelsize = scroll_panel:Add('DLabel')
	label_pmmodelsize:SetText(lang['menu_rgc_download_model_size_limit_desc'])
	label_pmmodelsize:SetFont('GModToolHelp')
	label_pmmodelsize:SetAutoStretchVertical(true)
	base_setup_element(label_pmmodelsize)
end
concommand.Add('rgchat_menu', open_menu)