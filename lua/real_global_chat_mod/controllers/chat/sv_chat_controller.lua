local string_sub = string.sub
local string_Trim = string.Trim
local string_Split = string.Split
local string_lower = string.lower
local isfunction = isfunction
local IsValid = IsValid

hook.Add('PlayerSay', 'RealGlobalChat.PlayerSay', function(ply, text)
	text = string_Trim(text)
	if #text == 0 then return end
	local command_text_lines = string_Split(string_Trim(string_lower(text)):gsub('%s+', ' '), ' ')

	if command_text_lines[1] == '/rgchat' then
		ply:ConCommand('rgchat_menu')

		return ''
	end

	if command_text_lines[1] == '/rgchatplayers' then
		if ply:IsAdmin() or ply:IsSuperAdmin() then
			local new_cvar = GetConVar('sv_rgc_sync_players'):GetInt() == 1 and 0 or 1
			RunConsoleCommand('sv_rgc_sync_players', new_cvar)

			if new_cvar == 1 then
				ply:ChatPrint('ON - You will now see the other players')
			else
				ply:ChatPrint('OFF - You will no longer see other players')
			end
		end

		return ''
	end

	if command_text_lines[1] == '/rgchatwslimit' then
		local new_size = command_text_lines[2] and tonumber(command_text_lines[2]) or 100

		if new_size < 0 then
			new_size = 0
		end

		ply:ConCommand('cl_rgc_download_model_size_limit ' .. new_size)
		ply:ChatPrint('[RGChat] New workshop download limit: ' .. tostring(new_size) .. ' mb')

		return ''
	end

	if command_text_lines[1] == '/rgchatmode' then
		net.Start('RealGlobalChatSetCountryMode')
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatfilter' then
		net.Start('RealGlobalChatSetFilter')
		net.WriteInt(0, 3)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatfilterstrict' then
		net.Start('RealGlobalChatSetFilter')
		net.WriteInt(1, 3)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatmap' then
		net.Start('RealGlobalChatSetMapName')
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatoff' then
		net.Start('RealGlobalChatSetStatus')
		net.WriteInt(0, 3)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchaton' then
		net.Start('RealGlobalChatSetStatus')
		net.WriteInt(1, 3)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatpingsfx' then
		net.Start('RealGlobalChatSetPingSFX')
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchatmute' then
		local connect_id = command_text_lines[2] or ''

		if connect_id and #connect_id ~= 0 and string.sub(connect_id, 1, 1) == '#' then
			connect_id = string.sub(connect_id, 2)
		end

		net.Start('RealGlobalChatMuteUser')
		net.WriteString(connect_id)
		net.Send(ply)

		return ''
	end

	if command_text_lines[1] == '/rgchattranslateto' then
		ply:ConCommand('cl_rgc_target_translate "' .. tostring(command_text_lines[2]) .. '"')

		if command_text_lines[2] then
			ply:ChatPrint('[RGChat] New target translate: ' .. tostring(command_text_lines[2]))
		else
			ply:ChatPrint('[RGChat] New target translate: default country')
		end

		return ''
	end

	-- Ignore possible commands
	if command_text_lines[1] ~= 'ping' and #text > 2 then
		local first_char = string_sub(text, 1, 1)
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

	net.Start('RealGlobalChatSendPlayer')
	net.WriteString(text)
	net.Send(ply)
end)

do
	local load_queue = {}
	local first_start = false

	hook.Add('PlayerInitialSpawn', 'RealGlobalChat.PrintFirstMessage', function(ply)
		load_queue[ply] = true
	end)

	hook.Add('SetupMove', 'RealGlobalChat.PrintFirstMessage', function(ply, _, cmd)
		if load_queue[ply] and not cmd:IsForced() then
			load_queue[ply] = nil
			net.Start('RealGlobalChatSpawnMessage')
			net.Send(ply)

			if not first_start then
				hook.Run('RGchat.FirstStart')
				first_start = true
			end
		end
	end)

	hook.Add('PlayerDisconnected', 'RealGlobalChat.PrintFirstMessage', function(ply)
		if not load_queue[ply] then return end
		load_queue[ply] = nil
	end)
end