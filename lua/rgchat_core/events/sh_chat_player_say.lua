local _chat_commands

_chat_commands = {
	['rgchat'] = function(ply)
		ply:ConCommand('rgchat_menu')
	end,
	['rgchatplayers'] = function(ply)
		local new_cvar = RealGloabalChat.ConVar:GetInt('sv_rgc_sync_players') == 1 and 0 or 1
		RunConsoleCommand('sv_rgc_sync_players', new_cvar)

		if new_cvar == 1 then
			RealGloabalChat:Print('ON - You will now see the other players', ply)
		else
			RealGloabalChat:Print('OFF - You will no longer see other players', ply)
		end
	end,
	['rgchatwslimit'] = function(ply, text, value)
		local new_size = value and tonumber(value) or 0

		if not new_size or new_size < 0 then
			new_size = 0
		end

		ply:ConCommand('cl_rgc_download_model_size_limit ' .. new_size)
		RealGloabalChat:Print('New workshop download limit: ' .. tostring(new_size) .. ' mb', ply)
	end,
	['rgchatmode'] = function(ply)
		net.Start('RGChat_SwitchCvarFromClient')
		net.WriteString('cl_rgc_country_mode')
		net.Send(ply)
	end,
	['rgchatfilter'] = function(ply)
		net.Start('RGChat_SwitchCvarFromClient')
		net.WriteString('cl_rgc_filter')
		net.Send(ply)
	end,
	['rgchatfilterstrict'] = function(ply)
		net.Start('RGChat_SwitchCvarFromClient')
		net.WriteString('cl_rgc_filter_strict')
		net.Send(ply)
	end,
	['rgchatmap'] = function(ply)
		net.Start('RGChat_SwitchCvarFromClient')
		net.WriteString('cl_rgc_visible_player_map_name')
		net.Send(ply)
	end,
	['rgchatoff'] = function(ply)
		ply:ConCommand('cl_rgc_status 0')
	end,
	['rgchaton'] = function(ply)
		ply:ConCommand('cl_rgc_status 1')
	end,
	['rgchatpingsfx'] = function(ply)
		net.Start('RGChat_SwitchCvarFromClient')
		net.WriteString('cl_rgc_ping_sound')
		net.Send(ply)
	end,
	['rgchatmute'] = function(ply, text, connect_id)
		if not connect_id or not isstring(connect_id) then return end

		if connect_id and isstring(connect_id) and #connect_id ~= 0 and string.sub(connect_id, 1, 1) == '#' then
			connect_id = string.sub(connect_id, 2)
		end

		if not connect_id or not isstring(connect_id) or #connect_id == 0 then return end

		net.Start('RGChat_MutePlayer')
		net.WriteString(connect_id)
		net.Send(ply)
	end,
	['rgchattranslateto'] = function(ply, text, lang_code)
		if not lang_code then lang_code = '' end

		ply:ConCommand('cl_rgc_target_translate "' .. lang_code .. '"')

		if lang_code and lang_code ~= '' then
			RealGloabalChat:Print('New target translate: ' .. tostring(lang_code), ply)
		else
			RealGloabalChat:Print('New target translate: default country', ply)
		end
	end,
	['ping'] = function(ply, text)
		net.Start('RGChat_PlayerSay')
		net.WriteString(text)
		net.Send(ply)
		return true
	end
}

if SERVER then
	hook.Add('PlayerSay', 'RGChatPlayerSayToChat', function(ply, text)
		local is_real_player = false
		for _, real_player in ipairs(player.GetHumans()) do
			if real_player == ply then
				is_real_player = true
				break
			end
		end

		if not is_real_player then return end

		text = string.Trim(text)
		if #text == 0 then return end
		local has_valid_command = false
		local command_text_lines = string.Split(string.Trim(string.lower(text)):gsub('%s+', ' '), ' ')

		if command_text_lines[1] then
			local command_name = string.sub(command_text_lines[1], 2)

			if _chat_commands[command_name] then
				local command_handler = _chat_commands[command_name]
				table.remove(command_text_lines, 1)
				local result = command_handler(ply, text, unpack(command_text_lines))
				if result then return end
				return ''
			end
		end

		-- Ignore possible commands
		if not has_valid_command and #text > 2 then
			local first_char = string.sub(text, 1, 1)
			if first_char == '/' or first_char == '!' or first_char == '?' then return end
		end

		-- Ignore the words of the magic wand mod.
		-- https://steamcommunity.com/sharedfiles/filedetails/?id=875498456
		if HpwRewrite and isfunction(HpwRewrite.GetPlayerSpell) then
			local weapon = ply:GetActiveWeapon()

			if IsValid(weapon) and weapon:GetClass() == 'weapon_hpwr_stick' and isfunction(weapon.GetWandCurrentSpell) and isfunction(weapon.CheckSpellUseable) and isfunction(weapon.EmptySpellAttack) then
				local spell_name = weapon:GetWandCurrentSpell()
				local current_spell = HpwRewrite:GetPlayerSpell(ply, spell_name)
				if current_spell and text == (current_spell.WhatToSay or spell_name) .. '!' then return end
			end
		end

		net.Start('RGChat_PlayerSay')
		net.WriteString(text)
		net.Send(ply)
	end)
else
	net.Receive('RGChat_PlayerSay', function()
		local text_value = net.ReadString()
		if not RealGloabalChat.ConVar:GetBool('cl_rgc_status') then return end
		RealGloabalChat.WebApi.Chat:SendToChat(LocalPlayer(), text_value)
	end)

	net.Receive('RGChat_MutePlayer', function()
		local connect_id = net.ReadString()
		RealGloabalChat.Api:MuteUser(connect_id)
	end)
end