local string_Split = string.Split
local Vector = Vector
local tonumber = tonumber
local url_address = RealGloabalChat.Values.ApiUrl
local isnumber = isnumber
local string_lower = string.lower
local util_JSONToTable = util.JSONToTable
local http_Post = http.Post
local http_Fetch = http.Fetch
local system_GetCountry = system.GetCountry
local isfunction = isfunction
local ipairs = ipairs
local tostring = tostring
local math_sqrt = math.sqrt
local string_GetExtensionFromFilename = string.GetExtensionFromFilename
local table_insert = table.insert
local game_GetMap = game.GetMap
local Angle = Angle
local color_rgchat_tag = Color(237, 204, 73)
local color_message = Color(255, 255, 255)
local cvar_cl_real_global_chat_country_mode = GetConVar('cl_real_global_chat_country_mode')
local has_reading_muted_users = false
local IsValid = IsValid

local function http_Error(message)
	MsgN('[RGChat Error] ' .. message)
end

local function http_Warn(message)
	chat.AddText(color_rgchat_tag, '[RGChat Warn] ', color_message, ': ' .. tostring(message))
	MsgN('[RGChat Warn] ' .. message)
end

local verified_token, verified_token_is_checked

function RealGloabalChat:SendToChat(ply, messageText, invoke_Action, attempts)
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

	http_Post(url_address .. 'Api/Chat/SendToChat', {
		steamId64 = ply:SteamID64(),
		userName = ply:Nick(),
		message = messageText,
		chatRoomName = chatRoomName,
		verifiedToken = verified_token
	}, function(body, length, headers, code)
		if code == 502 then
			http_Warn('The global chat server is currently unavailable.')

			return
		end

		local response = body

		if response and response == 'ok' then
			if invoke_Action and isfunction(invoke_Action) then
				invoke_Action(response)
			end
		elseif code == 400 then
			http_Warn(body)
		else
			http_Error(body)
		end
	end, function(error_message)
		http_Error(error_message)

		timer.Simple(1.5, function()
			RealGloabalChat:SendToChat(ply, messageText, invoke_Action, attempts or 0)
		end)
	end)
end

function RealGloabalChat:GetChatMessages(ply, start_message_id, invoke_Action)
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
		if code == 502 then return end
		local response = util_JSONToTable(body)

		if response then
			if invoke_Action and isfunction(invoke_Action) then
				invoke_Action(response)
			end
		else
			http_Error(body)
		end
	end, http_Error)
end

function RealGloabalChat:GetOnlineCount(invoke_Action)
	local get_params = ''

	if cvar_cl_real_global_chat_country_mode:GetBool() then
		get_params = '?chatRoomName=country.' .. string_lower(system_GetCountry())
	end

	http_Fetch(url_address .. 'Api/Chat/GetOnline' .. get_params, function(body, length, headers, code)
		if code == 502 then return end
		local response = body

		if response then
			if invoke_Action and isfunction(invoke_Action) then
				invoke_Action(response)
			end
		else
			http_Error(body)
		end
	end, http_Error)
end

function RealGloabalChat:UpdateOnline(invoke_Action)
	local form_data = nil

	form_data = {
		chatRoomName = 'world'
	}

	if cvar_cl_real_global_chat_country_mode:GetBool() then
		form_data.chatRoomName = 'country.' .. string_lower(system_GetCountry())
	end

	http_Post(url_address .. 'Api/Chat/UpdateOnline', form_data, function(body, length, headers, code)
		if code == 502 then return end
		local response = body

		if response and response == 'ok' then
			if invoke_Action and isfunction(invoke_Action) then
				invoke_Action(response)
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

function RealGloabalChat:UpdateGameInfo(ply, invoke_Action)
	local ply_pos = ply:GetPos()
	local ply_ang = ply:GetAngles()
	local ply_eye_pos = ply:EyePos()
	local ply_eye_ang = ply:EyeAngles()
	local ply_weapon = ply:GetActiveWeapon()
	local ply_model = ply:GetModel()
	local ply_model_wsid = nil

	if ply_model and RealGloabalChat.Values.AddonsModels[ply_model] then
		local index = RealGloabalChat.Values.AddonsModels[ply_model]

		if index then
			ply_model_wsid = RealGloabalChat.Values.Addons[index]
		end
	end

	local ply_activity

	if IsValid(ply) and ply:Alive() then
		-- for gesture_id, _ in pairs(RealGloabalChat.Enum.ActGmodTaunt) do
		-- 	if ply:IsPlayingGesture(gesture_id) then
		-- 		ply_activity = gesture_id
		-- 		break
		-- 	end
		-- end
		-- if not ply_activity then
		ply_activity = ply:GetSequenceActivity(ply:GetSequence())
		-- end
	end

	local form_data = {
		SteamId64 = ply:SteamID64(),
		UserName = ply:Name(),
		PlayerModelWsid = ply_model_wsid and tostring(ply_model_wsid) or nil,
		PlayerModel = ply:GetModel(),
		PlayedMap = game_GetMap(),
		PlayerPos = ply_pos.x .. ',' .. ply_pos.y .. ',' .. ply_pos.z,
		PlayerAng = ply_ang.x .. ',' .. ply_ang.y .. ',' .. ply_ang.z,
		PlayerEyePos = ply_eye_pos.x .. ',' .. ply_eye_pos.y .. ',' .. ply_eye_pos.z,
		PlayerEyeAng = ply_eye_ang.x .. ',' .. ply_eye_ang.y .. ',' .. ply_eye_ang.z,
		PlayerIsTyping = tostring(ply:IsTyping() and 1 or 0),
		PlayerWalkSpeed = tostring(ply:GetWalkSpeed()),
		PlayerRunSpeed = tostring(ply:GetRunSpeed()),
		PlayerActivity = tostring(ply_activity),
		PlayerWeaponClass = IsValid(ply_weapon) and ply_weapon:GetClass() or nil
	}

	http_Post(url_address .. 'Api/GameInfo/UpdateGameInfo', form_data, function(body, length, headers, code)
		if code == 502 then return end
		local response = body

		if response and response == 'ok' then
			if invoke_Action and isfunction(invoke_Action) then
				invoke_Action(response)
			end
		else
			http_Error(body)
		end
	end, http_Error)
end

function RealGloabalChat:GetInfo(invoke_Action)
	http_Fetch(url_address .. 'Api/Info', function(body, length, headers, code)
		if code == 502 then return end
		local response = util_JSONToTable(body)

		if response then
			if invoke_Action and isfunction(invoke_Action) then
				invoke_Action(response)
			end
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
			RealGloabalChat.Values.MutedUsers = util.JSONToTable(file.Read('rgchat_data/muted_users.json', 'DATA'))
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
		muted_users = util.JSONToTable(file.Read('rgchat_data/muted_users.json', 'DATA'))
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

	file.Write('rgchat_data/muted_users.json', util.TableToJSON(muted_users))
	RealGloabalChat.Values.MutedUsers = muted_users
	has_reading_muted_users = true
end

function RealGloabalChat:GetGameInfo(invoke_Action)
	http_Fetch(url_address .. 'Api/GameInfo/GetGameInfo?mapName=' .. game_GetMap(), function(body, length, headers, code)
		if code == 502 then return end
		local response = util_JSONToTable(body)

		if response and response.success then
			if response.success == 1 and invoke_Action and isfunction(invoke_Action) then
				invoke_Action(response)
			end
		elseif code == 400 then
			http_Warn(body)
		else
			http_Error(body)
		end
	end, http_Error)
end

function RealGloabalChat:PosStringToVector(pos_string)
	if not pos_string then return end
	local vector_data = string_Split(pos_string, ',')
	if not vector_data[1] or not vector_data[2] or not vector_data[3] then return end

	return Vector(tonumber(vector_data[1]), tonumber(vector_data[2]), tonumber(vector_data[3]))
end

function RealGloabalChat:PosStringToAngle(ang_string)
	if not ang_string then return end
	local angle_data = string_Split(ang_string, ',')
	if not angle_data[1] or not angle_data[2] or not angle_data[3] then return end

	return Angle(tonumber(angle_data[1]), tonumber(angle_data[2]), tonumber(angle_data[3]))
end

function RealGloabalChat:Magnitude(vec)
	local magnitude = vec
	magnitude = magnitude.x ^ 2 + magnitude.y ^ 2 + magnitude.z ^ 2
	magnitude = math_sqrt(magnitude)

	return magnitude
end

function RealGloabalChat:MoveTowards(current_vector, target_vector, delta_time)
	local direction_vector = target_vector - current_vector
	local magnitude = self:Magnitude(direction_vector)
	if magnitude <= delta_time or magnitude == 0 then return target_vector end

	return current_vector + direction_vector / magnitude * delta_time
end