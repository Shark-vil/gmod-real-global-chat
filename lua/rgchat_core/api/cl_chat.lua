local _muted_users

function RealGloabalChat.Api:GetChatRoom()
	-- local chatRoomName = 'world'

	-- if RealGloabalChat.ConVar:GetBool('cl_rgc_country_mode') then
	-- 	chatRoomName = 'country.' .. string.lower(system.GetCountry())
	-- end

	-- return chatRoomName

	return 'developer'
end

function RealGloabalChat.Api:PlayerChatIsActive(ply)
	if CLIENT then return RealGloabalChat.ConVar:GetBool('cl_rgc_status') end
	if not IsValid(ply) then return false end
	local active = RealGloabalChat:GetFromStorage('ModActive', ply)
	if not active then return false end
	return true
end

function RealGloabalChat.Api:HasMutedUser(connect_id)
	if not connect_id then return false end
	connect_id = tonumber(connect_id)
	if not connect_id then return false end

	if not _muted_users and file.Exists('rgchat_data/muted_users.json', 'DATA') then
		-- Update database
		if file.Time('rgchat_data/muted_users.json', 'DATA') < 1709625732 then
			file.Delete('rgchat_data/muted_users.json')
		else
			_muted_users = util.JSONToTable(file.Read('rgchat_data/muted_users.json', 'DATA'))
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
	_muted_users = muted_users
end

function RealGloabalChat.Api:GetLanguage()
	local target_translate =  RealGloabalChat.ConVar:GetString('cl_rgc_target_translate')
	if isstring(target_translate) then
		target_translate = string.Trim(target_translate)
		if target_translate == 'nil' then target_translate = nil end
	end
	if not target_translate or target_translate == '' then
		target_translate = system.GetCountry()
		if not target_translate or target_translate == '' then
			target_translate = RealGloabalChat.ConVar:GetString('cl_language')
		end
	end
	return target_translate
end