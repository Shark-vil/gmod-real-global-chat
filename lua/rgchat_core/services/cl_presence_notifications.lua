local _ConVar = RealGloabalChat.ConVar
local _coroutine_wait = coroutine.wait
local _ipairs = ipairs
local _pairs = pairs
local _IsValid = IsValid
local _surface_PlaySound = surface.PlaySound

local _color_tag = Color(207, 237, 73)
local _color_name = Color(255, 255, 104)
local _color_join = Color(130, 255, 130)
local _color_leave = Color(255, 130, 130)
local _color_mapchange = Color(130, 200, 255)
local _color_msg = Color(255, 255, 255)
local _color_map = Color(22, 255, 239)
local _sound_join = Sound('real_global_chat_mod/presence_join_sfx.wav')
local _sound_leave = Sound('real_global_chat_mod/presence_leave_sfx.wav')
local _sound_map = Sound('real_global_chat_mod/presence_map_sfx.wav')

local _cache = nil

local function _IsValidMap(map)
	return map and map ~= '' and map ~= 'web'
end

local function _Notify(sound, ...)
	_surface_PlaySound(sound)
	chat.AddText(...)
end

local function _Handler()
	local Language = RealGloabalChat.Language

	while true do
		_coroutine_wait(30)

		if not _IsValid(LocalPlayer()) then continue end
		if not RealGloabalChat.Api:PlayerChatIsActive() then continue end

		local code, body = RealGloabalChat.WebApi.Chat:GetOnlineWait()
		if code ~= 200 or not body or not body.players_on_world then continue end

		local local_steamid64 = LocalPlayer():SteamID64()
		local new_snapshot = {}

		for _, item in _ipairs(body.players_on_world) do
			if item.steamid64 and item.steamid64 ~= local_steamid64 then
				new_snapshot[item.steamid64] = {
					username = item.username or '?',
					map = item.map or ''
				}
			end
		end

		if not _cache then
			_cache = new_snapshot
			continue
		end

		if not _ConVar:GetBool('cl_rgc_presence_notifications') then
			_cache = new_snapshot
			continue
		end

		local tag = Language:Get('rgchat_info') .. ' '

		for steamid64, data in _pairs(new_snapshot) do
			local old = _cache[steamid64]
			if not old then
				if _IsValidMap(data.map) then
					_Notify(_sound_join,
						_color_tag, tag,
						_color_join, '▸ ',
						_color_name, data.username,
						_color_map, ' — ' .. data.map
					)
				else
					_Notify(_sound_join,
						_color_tag, tag,
						_color_join, '▸ ',
						_color_name, data.username
					)
				end
			elseif old.map ~= data.map and _IsValidMap(data.map) then
				_Notify(_sound_map,
					_color_tag, tag,
					_color_mapchange, '↺ ',
					_color_name, data.username,
					_color_msg, ' → ',
					_color_map, data.map
				)
			end
		end

		for steamid64, data in _pairs(_cache) do
			if not new_snapshot[steamid64] then
				_Notify(_sound_leave,
					_color_tag, tag,
					_color_leave, '◂ ',
					_color_name, data.username
				)
			end
		end

		_cache = new_snapshot
	end
end

RealGloabalChat:AddBackgroundWorker('presence_notifications', _Handler)

concommand.Add('cl_rgc_debug_presence', function()
	local Language = RealGloabalChat.Language
	local tag = Language:Get('rgchat_info') .. ' '
	_Notify(_sound_join,
		_color_tag, tag,
		_color_join, '▸ ',
		_color_name, 'TestPlayer',
		_color_map, ' — gm_flatgrass'
	)
	timer.Simple(0.7, function()
		_Notify(_sound_map,
			_color_tag, tag,
			_color_mapchange, '↺ ',
			_color_name, 'TestPlayer',
			_color_msg, ' → ',
			_color_map, 'gm_construct'
		)
	end)
	timer.Simple(1.4, function()
		_Notify(_sound_leave,
			_color_tag, tag,
			_color_leave, '◂ ',
			_color_name, 'TestPlayer'
		)
	end)
end)
