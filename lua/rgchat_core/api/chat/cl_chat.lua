local _tonumber = tonumber
local _isstring = isstring
local _isnumber = isnumber
local _file_Exists = file.Exists
local _util_JSONToTable = util.JSONToTable
local _util_TableToJSON = util.TableToJSON
local _file_Read = file.Read
local _file_Delete = file.Delete
local _file_Time = file.Time
local _file_Write = file.Write
local _string_lower = string.lower
local _string_Trim = string.Trim
local _string_sub = string.sub
local _system_GetCountry = system.GetCountry
local _table_remove = table.remove
local _table_insert = table.insert
local _muted_users

function RealGloabalChat.Api:GetChatRoom()
	local chatRoomName = 'world'

	if RealGloabalChat.ConVar:GetBool('cl_rgc_country_mode') then
		chatRoomName = 'country.' .. _string_lower(_system_GetCountry())
	end

	return chatRoomName
end

function RealGloabalChat.Api:HasMutedUser(connect_id)
	if not connect_id then return false end
	connect_id = _tonumber(connect_id)
	if not connect_id then return false end

	if not _muted_users and _file_Exists('rgchat_data/muted_users.json', 'DATA') then
		-- Change file data type
		if _file_Time('rgchat_data/muted_users.json', 'DATA') < 1738485490 then
			_file_Delete('rgchat_data/muted_users.json')
			RealGloabalChat:PrintWarning('The mute list has been reset due to a data update.')
		else
			_muted_users = _util_JSONToTable(_file_Read('rgchat_data/muted_users.json', 'DATA'))
		end
	end

	if not _muted_users then
		_muted_users = {}
	end

	for i = 1, #_muted_users do
		if _muted_users[i] == connect_id then return true end
	end

	return false
end

function RealGloabalChat.Api:MuteUser(connect_id)
	if _isstring(connect_id) and _string_sub(connect_id, 1, 1) == '#' then
		connect_id = _string_sub(connect_id, 2)
	end

	if not connect_id or not connect_id:match('^%d+$') then
		RealGloabalChat:PrintError('ID must be a number!')
		return
	end

	connect_id = tonumber(connect_id)
	if not connect_id then
		RealGloabalChat:PrintError('Failed to convert ID to number')
		return
	end

	local muted_users = {}

	if _file_Exists('rgchat_data/muted_users.json', 'DATA') then
		muted_users = _util_JSONToTable(_file_Read('rgchat_data/muted_users.json', 'DATA'))
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
		_table_remove(muted_users, exists_connect_id)
		RealGloabalChat:Print('You have removed the mute from user ID: ' .. connect_id)
	else
		_table_insert(muted_users, connect_id)
		RealGloabalChat:Print('User ID: ' .. connect_id .. ' was given a mute')
	end

	_file_Write('rgchat_data/muted_users.json', _util_TableToJSON(muted_users))
	_muted_users = muted_users
end

function RealGloabalChat.Api:GetLanguage()
	local target_translate = RealGloabalChat.ConVar:GetString('cl_rgc_target_translate')

	if _isstring(target_translate) then
		target_translate = _string_Trim(target_translate)

		if target_translate == 'nil' then
			target_translate = nil
		end
	end

	if not target_translate or target_translate == '' then
		target_translate = _system_GetCountry()

		if not target_translate or target_translate == '' then
			target_translate = RealGloabalChat.ConVar:GetString('cl_language')
		end
	end

	return target_translate
end