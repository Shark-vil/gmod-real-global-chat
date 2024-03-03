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
local Color = Color
local string_Trim = string.Trim
local cvar_cl_real_global_chat_status

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

function RealGloabalChat:GetChatMessagesCallback(ply, start_message_id, callback)
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
		callback(body, length, headers, code)
	end, function(err)
		callback()
		http_Error(err)
	end)
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
	local ply_model = ply.rgchat_outfitter_mdl or ply:GetModel()
	local ply_model_wsid = nil
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
	local ply_weapon_activity = IsValid(ply_weapon) and ply_weapon:GetActivity() or nil
	local ply_color = ply_alive and ply:GetColor() or nil
	local ply_move_type = ply_alive and ply:GetMoveType() or nil
	local ply_activity, ply_gesture

	if ply_model and RealGloabalChat.Values.AddonsModels[ply_model] then
		ply_model_wsid = RealGloabalChat.Values.AddonsModels[ply_model]
	end

	-- if ply_move_type and ply:InVehicle() then
	-- 	local mt = ply_move_type
	-- 	if mt == 4 or mt == 5 or mt == 8 or mt == 10 then
	-- 		ply_move_type = 0
	-- 	end
	-- end
	if ply_pos and ply:InVehicle() then
		ply_pos = ply:GetVehicle():GetPos()
	end

	if IsValid(ply) and ply_alive then
		if ply.RgChatActiveGesture then
			ply_gesture = ply.RgChatActiveGesture
		else
			for gesture_id, _ in pairs(RealGloabalChat.Enum.ActGmodTaunt) do
				if ply:IsPlayingGesture(gesture_id) then
					ply_gesture = gesture_id
					break
				end
			end
		end

		ply_activity = ply:GetSequenceActivity(ply_sequence)
	end

	local form_data = {
		SteamId64 = ply:SteamID64(),
		UserName = ply:Name(),
		ModelWsid = ply_model_wsid and tostring(ply_model_wsid) or nil,
		Model = ply_model,
		Map = game_GetMap(),
		Pos = ply_pos and (ply_pos.x .. ',' .. ply_pos.y .. ',' .. ply_pos.z) or nil,
		Ang = ply_ang and (ply_ang.x .. ',' .. ply_ang.y .. ',' .. ply_ang.z) or nil,
		EyePos = ply_eye_pos and (ply_eye_pos.x .. ',' .. ply_eye_pos.y .. ',' .. ply_eye_pos.z) or nil,
		EyeAng = ply_eye_ang and (ply_eye_ang.x .. ',' .. ply_eye_ang.y .. ',' .. ply_eye_ang.z) or nil,
		IsTyping = tostring(ply:IsTyping() and 1 or 0),
		WalkSpeed = tostring(ply:GetWalkSpeed()),
		RunSpeed = tostring(ply:GetRunSpeed()),
		Activity = ply_activity and tostring(ply_activity) or nil,
		Sequence = ply_sequence and tostring(ply_sequence) or nil,
		Gesture = ply_gesture and tostring(ply_gesture) or nil,
		WeaponClass = IsValid(ply_weapon) and ply_weapon:GetClass() or nil,
		WeaponActivity = tostring(ply_weapon_activity),
		MoveType = ply_move_type and tostring(ply_move_type) or nil,
		Alive = tostring(ply_alive and 1 or 0),
		Attacker = ply_attacker and tostring(ply_attacker) or nil,
		Inflictor = ply_inflictor and tostring(ply_inflictor) or nil,
		Velocity = ply_velocity and (ply_velocity.x .. ',' .. ply_velocity.y .. ',' .. ply_velocity.z) or nil,
		Color = ply_color and (ply_color.r .. ',' .. ply_color.g .. ',' .. ply_color.b .. ',' .. ply_color.a) or nil,
	}

	if ply_attacker then
		ply.RGChatAttacker = nil
	end

	if ply_inflictor then
		ply.RGChatInflictor = nil
	end

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

function RealGloabalChat:ColorStringToColor(col_string)
	if not col_string then return Color(255, 255, 255, 255) end
	local col_data = string_Split(col_string, ',')
	if not col_data[1] or not col_data[2] or not col_data[3] or not col_data[4] then return Color(255, 255, 255, 255) end

	return Color(tonumber(col_data[1]), tonumber(col_data[2]), tonumber(col_data[3]), tonumber(col_data[4]))
end

function RealGloabalChat:PosStringToVector(pos_string)
	if not pos_string then return Vector(0, 0, 0) end
	local vector_data = string_Split(pos_string, ',')
	if not vector_data[1] or not vector_data[2] or not vector_data[3] then return Vector(0, 0, 0) end

	return Vector(tonumber(vector_data[1]), tonumber(vector_data[2]), tonumber(vector_data[3]))
end

function RealGloabalChat:PosStringToAngle(ang_string)
	if not ang_string then return Angle(0, 0, 0) end
	local angle_data = string_Split(ang_string, ',')
	if not angle_data[1] or not angle_data[2] or not angle_data[3] then return Angle(0, 0, 0) end

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

function RealGloabalChat:ModIsActive(ply)
	if CLIENT then
		if not cvar_cl_real_global_chat_status then
			cvar_cl_real_global_chat_status = GetConVar('cl_real_global_chat_status')
		end

		return cvar_cl_real_global_chat_status:GetBool()
	end

	if not IsValid(ply) or not RealGloabalChat.Values.ModActive[ply] then return false end

	return true
end

function RealGloabalChat:BuildGma(wsid, gma_file, gma_data)
	local skip_ext = {
		['lua'] = true,
		['wav'] = true,
		['mp3'] = true,
		['bsp'] = true,
		['png'] = true,
		['jpg'] = true,
		['jpeg'] = true,
		['png'] = true,
		['txt'] = true,
		['ttf'] = true,
		['html'] = true,
		['js'] = true,
		['css'] = true,
		['nav'] = true,
		['ain'] = true,
	}

	for i = #gma_data.files, 1, -1 do
		local file_meta = gma_data.files[i]

		if skip_ext[file_meta.ext:lower()] then
			table.remove(gma_data.files, i)
		end
	end

	local pos = 0

	local function add(n)
		pos = pos + n

		return pos
	end

	gma_file:Write('GMAD')
	add(4)
	gma_file:Write(string.char(gma_data.gma_version))
	add(1)
	gma_file:WriteULong(gma_data.steamid[1])
	gma_file:WriteULong(gma_data.steamid[2])
	add(8)
	gma_file:WriteULong(gma_data.timestamp[1])
	gma_file:WriteULong(gma_data.timestamp[2])
	add(8)

	if gma_data.gma_version > 1 then
		gma_file:Write('\0')
		add(1)
	end

	local name = (gma_data.name or '') .. '\0'
	gma_file:Write(name)
	add(#name)
	local desc = (gma_data.description and util.TableToJSON(gma_data.description) or '{"type":"model","tags":["fun"],"description":"description"}') .. '\0'
	gma_file:Write(desc)
	add(#desc)
	local author = (gma_data.author or '') .. '\0'
	gma_file:Write(author)
	add(#author)
	gma_file:WriteULong(gma_data.addon_version)
	add(4)
	local idx = 0

	for i, file_meta in pairs(gma_data.files) do
		idx = idx + 1
		gma_file:WriteLong(idx)
		add(4)
		assert(idx == i)
		gma_file:Write(file_meta.filename .. '\0')
		add(#file_meta.filename + 1)
		assert(file_meta.size < 2 ^ 30)
		gma_file:WriteULong(file_meta.size)
		gma_file:WriteULong(0)
		add(8)
		gma_file:WriteULong(file_meta.crc or 0)
		add(4)
	end

	gma_file:WriteLong(0)
	add(4)

	for _, file_meta in pairs(gma_data.files) do
		local fd = file_meta.fd or gma_data.fd
		fd:Seek(file_meta.offset)
		local data = fd:Read(file_meta.size)
		if not data or #data ~= file_meta.size then return end
		if no_crc ~= true and file_meta.crc and file_meta.crc ~= 0 and tostring(util.CRC(data)) ~= tostring(file_meta.crc) then return end
		file_meta.offset = gma_file:Tell()
		gma_file:Write(data)
		add(#data)
	end

	gma_file:Tell()
end

function RealGloabalChat:ReadGma(gma_file)
	if gma_file:Read(4) ~= 'GMAD' then return end

	local meta = {
		files = {},
		fd = gma_file
	}

	meta.gma_version = gma_file:ReadByte()
	if (meta.gma_version or math.huge) > 3 then return end

	meta.steamid = {gma_file:ReadULong(), gma_file:ReadULong()}

	meta.timestamp = {gma_file:ReadULong(), gma_file:ReadULong()}

	if meta.gma_version > 1 then
		meta.required_content = {}

		for i = 1, 2 ^ 14 do
			if i == 2 ^ 14 - 1 then return end
			str = gma_file:ReadString()
			if str and #str == 0 then break end
			if not str then return end
			table.insert(meta.required_content, str)
		end
	end

	meta.name = gma_file:ReadString()
	meta.description = util.JSONToTable(gma_file:ReadString())
	meta.author = gma_file:ReadString()
	meta.addon_version = gma_file:ReadULong()
	if not meta.addon_version then return end

	for n = 1, 2 ^ 14 do
		if n == 2 ^ 14 - 1 then return end
		local filenum = gma_file:ReadULong()
		if filenum == 0 then break end
		if filenum ~= n then return end
		local filename = gma_file:ReadString()
		local file_meta = {}
		file_meta.filename = filename
		file_meta.size = gma_file:ReadULong()
		if gma_file:ReadULong() ~= 0 then return end
		file_meta.crc = gma_file:ReadULong()
		file_meta.ext = string.GetExtensionFromFilename(filename)
		if file_meta.size <= 0 then return end
		if file_meta.size >= (2 ^ 30) - 1 then return end
		table.insert(meta.files, file_meta)
	end

	for _, file_meta in pairs(meta.files) do
		file_meta.offset = gma_file:Tell()
		gma_file:Skip(file_meta.size)
	end

	return meta
end

function RealGloabalChat:Translate(lang, text, callback)
	http_Post('https://translate.google.com/translate_a/single?client=at&dt=t&dt=rm&dj=1', {
		['sl'] = 'auto',
		['tl'] = lang:lower(),
		['q'] = text
	}, function(body, size, headers, code)
		if code ~= 200 then
			callback(text, code)

			return
		end

		local response = util_JSONToTable(body)

		if response and response['sentences'] and response['sentences'][1] and response['sentences'][1]['trans'] then
			local new_text = response['sentences'][1]['trans']

			if new_text then
				new_text = string_Trim(new_text)

				if #new_text ~= 0 then
					callback(new_text, code)

					return
				end
			end
		end

		callback(text, code)
	end, function()
		callback(text, code)
	end, {
		['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8',
		['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36'
	})
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