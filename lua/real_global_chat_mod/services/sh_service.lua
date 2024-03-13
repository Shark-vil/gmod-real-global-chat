-- local string_Split = string.Split
-- local Vector = Vector
local tonumber = tonumber
local url_address = RealGloabalChat.Values.ApiUrl
local isnumber = isnumber
local string_lower = string.lower
local util_JSONToTable = function (data)
	local ok, result = xpcall(function()
		return RealGloabalChat.Module.Json.decode(data)
	end, function() end)
	if not ok then return end
	return result
end
local util_TableToJSON = function(data)
	local ok, result = xpcall(function()
		return RealGloabalChat.Module.Json.encode(data)
	end, function() end)
	if not ok then return end
	return result
end
local http_Post = http.Post
local http_Fetch = http.Fetch
local system_GetCountry = system.GetCountry
-- local isfunction = isfunction
local ipairs = ipairs
local tostring = tostring
-- local math_sqrt = math.sqrt
local string_GetExtensionFromFilename = string.GetExtensionFromFilename
local table_insert = table.insert
local game_GetMap = game.GetMap
-- local Angle = Angle
local color_rgchat_tag = Color(237, 204, 73)
local color_message = Color(255, 255, 255)
local cvar_cl_real_global_chat_country_mode = GetConVar('cl_rgc_country_mode')
-- local cvar_developer = GetConVar('developer')
local has_reading_muted_users = false
local IsValid = IsValid
-- local Color = Color
-- local string_Trim = string.Trim
local cvar_cl_real_global_chat_status
local HTTP = HTTP

local http_json_content_type = {
	['Content-Type'] = 'application/json; charset=utf-8'
}

local function http_Error(message)
	MsgN('[RGChat Error] ' .. message)
end

local function http_Warn(message)
	if CLIENT then
		chat.AddText(color_rgchat_tag, '[RGChat Warn] ', color_message, ': ' .. tostring(message))
	end

	MsgN('[RGChat Warn] ' .. message)
end

RealGloabalChat.http_Error = http_Error
RealGloabalChat.http_Warn = http_Warn
local verified_token, verified_token_is_checked

function RealGloabalChat:SendToChat(ply, messageText, attempts)
	if attempts then
		attempts = attempts + 1

		if attempts >= 5 then
			http_Warn('Message "' .. messageText .. '" not delivered')

			return
		end
	end

	local chatRoomName = 'world'

	if cvar_cl_real_global_chat_country_mode:GetBool() then
		chatRoomName = 'country.' .. string_lower(system_GetCountry())
	end

	if not verified_token_is_checked then
		verified_token_is_checked = true

		if file.Exists('rgchat_data/verified.txt', 'DATA') then
			verified_token = file.Read('rgchat_data/verified.txt', 'DATA')
		end
	end

	local content = util_TableToJSON({
		steamid64 = ply:SteamID64(),
		username = ply:Nick(),
		message = messageText,
		chat_room_name = chatRoomName,
		verified_token = verified_token,
	})

	HTTP({
		url = url_address .. 'Api/Chat/SendToChat',
		method = 'POST',
		headers = http_json_content_type,
		body = content,
		success = function(code, body, headers)
			local response = util_JSONToTable(body)

			if response and response.success then
				if response.success == 0 then
					http_Warn(response.message or response.error)
				end
			else
				http_Error(body)
			end
		end,
		failed = function(error_message)
			http_Error(error_message)

			timer.Simple(1.5, function()
				RealGloabalChat:SendToChat(ply, messageText, attempts or 0)
			end)
		end
	})
end

function RealGloabalChat:GetChatMessages(ply, start_message_id, callback)
	local get_params = ''

	if cvar_cl_real_global_chat_country_mode:GetBool() then
		get_params = '?chatRoomName=country.' .. string_lower(system_GetCountry())
	else
		get_params = '?chatRoomName=world'
	end

	if isnumber(start_message_id) then
		if #get_params == 0 then
			get_params = '?startMessageId=' .. start_message_id
		else
			get_params = get_params .. '&startMessageId=' .. start_message_id
		end
	end

	http_Fetch(url_address .. 'Api/Chat/GetChatMessages' .. get_params, function(body, length, headers, code)
		local response = util_JSONToTable(body)

		if response and response.success then
			if response.success == 1 then
				callback(response)

				return
			elseif response.success == 0 then
				if response.message then
					http_Warn(response.message)
				end

				if response.error then
					http_Error(response.error)
				end
			end
		else
			http_Error(body)
		end

		callback()
	end, function(error_message)
		http_Error(error_message)
		callback()
	end)
end

function RealGloabalChat:GetOnlineCount(callback)
	local get_params = ''

	if cvar_cl_real_global_chat_country_mode:GetBool() then
		get_params = '?chatRoomName=country.' .. string_lower(system_GetCountry())
	end

	http_Fetch(url_address .. 'Api/Chat/GetOnline' .. get_params, function(body, length, headers, code)
		if code == 200 then
			callback(body)
		else
			http_Error(body)
		end
	end, http_Error)
end

function RealGloabalChat:UpdateOnline()
	local form_data = nil

	form_data = {
		chatRoomName = 'world'
	}

	if cvar_cl_real_global_chat_country_mode:GetBool() then
		form_data.chatRoomName = 'country.' .. string_lower(system_GetCountry())
	end

	http_Post(url_address .. 'Api/Chat/UpdateOnline', form_data, function(body, length, headers, code)
		local response = util_JSONToTable(body)

		if response and response.success then
			if response.success == 0 then
				if response.message then
					http_Warn(response.message)
				end

				if response.error then
					http_Error(response.error)
				end
			end
		else
			http_Error(body)
		end
	end, http_Error)
end

function RealGloabalChat:FoundModelsInWorkshopAddon(current_dir, file_type, models_list)
	current_dir = current_dir or 'models'
	models_list = models_list or {}
	local files, dirs = file.Find(current_dir .. '/*', file_type)

	for _, file_name in ipairs(files) do
		local file_ext = string_GetExtensionFromFilename(file_name)

		if file_ext == 'mdl' then
			table_insert(models_list, current_dir .. '/' .. file_name)
		end
	end

	for _, dir_name in ipairs(dirs) do
		local next_parse_dir = current_dir ~= '' and current_dir .. '/' .. dir_name or dir_name
		models_list = RealGloabalChat:FoundModelsInWorkshopAddon(next_parse_dir, file_type, models_list)
	end

	return models_list
end

function RealGloabalChat:UpdateGameInfo(ply, action_list)
	local ply_model = ply.rgchat_outfitter_mdl or ply:GetModel()
	local ply_model_wsid = nil

	if ply_model and RealGloabalChat.Values.AddonsModels[ply_model] then
		ply_model_wsid = RealGloabalChat.Values.AddonsModels[ply_model]
	end

	local content = util_TableToJSON({
		steamid64 = ply:SteamID64(),
		username = ply:Name(),
		model_wsid = ply_model_wsid,
		model = ply_model,
		played_map = game_GetMap(),
		actions = action_list
	})

	HTTP({
		url = url_address .. 'Api/GameInfo/UpdateGameInfo',
		method = 'POST',
		headers = http_json_content_type,
		body = content,
		success = function(code, body, headers)
			local response = util_JSONToTable(body)

			if response and response.success then
				if response.success == 0 then
					if response.message then
						http_Warn(response.message)
					end

					if response.error then
						http_Error(response.error)
					end
				end
			else
				http_Error(body)
			end
		end,
		failed = http_Error
	})
end

function RealGloabalChat:GetPlayerAction(ply)
	local ply_alive = ply:Alive()
	local ply_attacker = IsValid(ply.RGChatAttacker) and ply.RGChatAttacker:GetName() or nil
	local ply_inflictor = IsValid(ply.RGChatInflictor) and ply.RGChatInflictor:GetName() or nil
	local ply_sequence = ply_alive and ply:GetSequence() or nil
	local ply_velocity = ply_alive and ply:GetVelocity() or nil
	local ply_pos = ply_alive and ply:GetPos() or nil
	local ply_ang = ply_alive and ply:GetAngles() or nil
	local ply_eye_pos = ply_alive and ply:EyePos() or nil
	local ply_eye_ang = ply_alive and ply:EyeAngles() or nil
	local ply_weapon = ply_alive and ply:GetActiveWeapon() or nil
	local ply_color = ply_alive and ply:GetColor() or nil
	local ply_move_type = ply_alive and ply:GetMoveType() or nil
	local ply_activity, ply_gesture
	local ply_skin = ply:GetSkin()
	local ply_bodygroups = ''

	for _, v in ipairs(ply:GetBodyGroups()) do
		local bodygroup = ply:GetBodygroup(v.id)
		ply_bodygroups = ply_bodygroups .. bodygroup
	end

	if ply_pos and ply:InVehicle() then
		ply_pos = ply:GetVehicle():GetPos()
	end

	if IsValid(ply) and ply_alive then
		if ply.RgChatActiveGesture then
			ply_gesture = ply.RgChatActiveGesture
		else
			for gesture_id, _ in pairs(RealGloabalChat.Values.Enum.ActGmodTaunt) do
				if ply:IsPlayingGesture(gesture_id) then
					ply_gesture = gesture_id
					break
				end
			end
		end

		ply_activity = ply:GetSequenceActivity(ply_sequence)
	end

	local action_data = {
		pos = ply_pos and (ply_pos.x .. ',' .. ply_pos.y .. ',' .. ply_pos.z) or nil,
		ang = ply_ang and (ply_ang.x .. ',' .. ply_ang.y .. ',' .. ply_ang.z) or nil,
		eye_pos = ply_eye_pos and (ply_eye_pos.x .. ',' .. ply_eye_pos.y .. ',' .. ply_eye_pos.z) or nil,
		eye_ang = ply_eye_ang and (ply_eye_ang.x .. ',' .. ply_eye_ang.y .. ',' .. ply_eye_ang.z) or nil,
		is_typing = ply:IsTyping() and 1 or 0,
		walk_speed = ply:GetWalkSpeed(),
		run_speed = ply:GetRunSpeed(),
		activity = ply_activity and ply_activity or nil,
		sequence = ply_sequence and ply_sequence or nil,
		gesture = ply_gesture and ply_gesture or nil,
		weapon_class = IsValid(ply_weapon) and ply_weapon:GetClass() or nil,
		move_type = ply_move_type and ply_move_type or nil,
		alive = ply_alive and 1 or 0,
		attacker = ply_attacker and ply_attacker or nil,
		inflictor = ply_inflictor and ply_inflictor or nil,
		velocity = ply_velocity and (ply_velocity.x .. ',' .. ply_velocity.y .. ',' .. ply_velocity.z) or nil,
		color = ply_color and (ply_color.r .. ',' .. ply_color.g .. ',' .. ply_color.b .. ',' .. ply_color.a) or nil,
		skin = ply_skin,
		bodygroups = ply_bodygroups ~= '' and ply_bodygroups or nil,
	}

	if ply_attacker then
		ply.RGChatAttacker = nil
	end

	if ply_inflictor then
		ply.RGChatInflictor = nil
	end

	return action_data
end

function RealGloabalChat:GetInfo(callback)
	http_Fetch(url_address .. 'Api/Info', function(body, length, headers, code)
		local response = util_JSONToTable(body)

		if code == 200 and response then
			callback(response)
		else
			http_Error(body)
		end
	end, http_Error)
end

function RealGloabalChat:UserHasMute(connect_id)
	if not connect_id then return false end
	connect_id = tonumber(connect_id)
	if not connect_id then return false end

	if not RealGloabalChat.Values.MutedUsers then
		RealGloabalChat.Values.MutedUsers = {}
	end

	if not has_reading_muted_users then
		if file.Exists('rgchat_data/muted_users.json', 'DATA') then
			-- Db update
			if file.Time('rgchat_data/muted_users.json', 'DATA') < 1709625732 then
				file.Delete('rgchat_data/muted_users.json')
			else
				RealGloabalChat.Values.MutedUsers = util_JSONToTable(file.Read('rgchat_data/muted_users.json', 'DATA'))
			end
		end

		has_reading_muted_users = true
	end

	for i = 1, #RealGloabalChat.Values.MutedUsers do
		if RealGloabalChat.Values.MutedUsers[i] == connect_id then return true end
	end

	return false
end

function RealGloabalChat:MuteUser(connect_id)
	local muted_users = {}

	if file.Exists('rgchat_data/muted_users.json', 'DATA') then
		muted_users = util_JSONToTable(file.Read('rgchat_data/muted_users.json', 'DATA'))
	end

	local exists_connect_id

	for i = 1, #muted_users do
		local user_connect_id = muted_users[i]

		if user_connect_id == connect_id then
			exists_connect_id = i
			break
		end
	end

	if exists_connect_id then
		table.remove(muted_users, exists_connect_id)
		LocalPlayer():ChatPrint('You have removed the mute from user ID: ' .. connect_id)
	else
		table.insert(muted_users, connect_id)
		LocalPlayer():ChatPrint('User ID: ' .. connect_id .. ' was given a mute')
	end

	file.Write('rgchat_data/muted_users.json', util_TableToJSON(muted_users))
	RealGloabalChat.Values.MutedUsers = muted_users
	has_reading_muted_users = true
end

function RealGloabalChat:GetGameInfo(last_update, callback)
	local get_params = '?mapName=' .. game_GetMap()

	if last_update then
		get_params = get_params .. '&lastUpdate=' .. last_update
	end

	http_Fetch(url_address .. 'Api/GameInfo/GetGameInfo' .. get_params, function(body, length, headers, code)
		local response = util_JSONToTable(body)

		if response and response.success then
			if response.success == 1 then
				callback(response)

				return
			elseif response.success == 0 then
				if response.message then
					http_Warn(response.message)
				end

				if response.error then
					http_Error(response.error)
				end
			end
		else
			http_Error(body)
		end
	end, http_Error)
end

function RealGloabalChat:ModIsActive(ply)
	if CLIENT then
		if not cvar_cl_real_global_chat_status then
			cvar_cl_real_global_chat_status = GetConVar('cl_rgc_status')
		end

		return cvar_cl_real_global_chat_status:GetBool()
	end

	if not IsValid(ply) or not RealGloabalChat.Values.ModActive[ply] then return false end

	return true
end

if SERVER then
	hook.Add('PlayerStartTaunt', 'RGChatPlayerStartTaunt', function(ply, act, length)
		ply.RgChatActiveGesture = act

		if length then
			timer.Create('RGChatPlayerStopTaunt.' .. ply:EntIndex(), length, 1, function()
				if not IsValid(ply) then return end
				ply.RgChatActiveGesture = nil
			end)
		end
	end)
end