local _BuildAndMountGma, _ReadAndMountCacheGma, _ReadCacheWorkshopFiles, _UpdateCacheWorkshopFiles
local _ConVar = RealGloabalChat.ConVar
local _isValid = IsValid
local _iocalPlayer = LocalPlayer
local _draw_SimpleTextOutlined = draw.SimpleTextOutlined
local _cam_Start3D2D = cam.Start3D2D
local _cam_End3D2D = cam.End3D2D
local _ents_FindByClass = ents.FindByClass
local _game_MountGMA = game.MountGMA
local _util_IsValidModel = util.IsValidModel
local _file_Exists = file.Exists
local _file_Read = file.Read
local _file_Write = file.Write
local _file_CreateDir = file.CreateDir
local _file_Open = file.Open
local _file_Delete = file.Delete
local _util_JSONToTable = util.JSONToTable
local _util_TableToJSON = util.TableToJSON
local _steamworks_DownloadUGC = steamworks.DownloadUGC
local _steamworks_FileInfo = steamworks.FileInfo
local _os_time = os.time
local _xpcall = xpcall
local _MsgN = MsgN
local _isstring = isstring
local _tonumber = tonumber
local _tostring = tostring
local _isnumber = isnumber
local _debug_traceback = debug.traceback
local _timer_Remove = timer.Remove
local _timer_Create = timer.Create
local _timer_Simple = timer.Simple
local _ipairs = ipairs
local _notification_AddProgress = notification.AddProgress
local _notification_AddLegacy = notification.AddLegacy
local _notification_Kill = notification.Kill
local _head_bone_name = 'ValveBiped.Bip01_Head'
local _vector_0_0_5 = Vector(0, 0, 5)
local _clr_1 = Color(255, 255, 255)
local _clr_2 = Color(0, 0, 0)
local _clr_host = Color(244, 167, 52)
local _download_cached = {}
local _size_limit_cached = {}
local _has_start_loaded = false
local _has_readed_cache_workshop_files = false
local _cache_workshop_files = {}

function _ReadCacheWorkshopFiles()
	if not _file_Exists('rgchat_data/cache_workshop.json', 'DATA') then return end
	local json_data = _file_Read('rgchat_data/cache_workshop.json', 'DATA')

	if json_data then
		_cache_workshop_files = _util_JSONToTable(json_data)
	end
end

function _UpdateCacheWorkshopFiles()
	_file_Write('rgchat_data/cache_workshop.json', _util_TableToJSON(_cache_workshop_files))
end

function _BuildAndMountGma(wsid, gma_path, gma_file)
	if not _file_Exists('rgchat_data/cache', 'DATA') then
		_file_CreateDir('rgchat_data/cache')
	end

	if not _cache_workshop_files[wsid] then
		_cache_workshop_files[wsid] = gma_path
		_UpdateCacheWorkshopFiles()
	end

	local gma_save_path = 'rgchat_data/cache/' .. wsid .. '_' .. _os_time() .. '.gma.dat'
	local meta = RealGloabalChat
	local ok, gma_meta
	ok, gma_meta = _xpcall(meta.ReadGma, _debug_traceback, meta, gma_file)

	if ok and gma_meta then
		local new_gma_file = _file_Open(gma_save_path, 'wb', 'DATA')
		ok = _xpcall(meta.BuildGma, _debug_traceback, meta, wsid, new_gma_file, gma_meta)
		new_gma_file:Close()

		if ok then
			ok, _ = _game_MountGMA('data/' .. gma_save_path)
			if ok then return true end
		end
	end

	return false
end

function _ReadAndMountCacheGma(wsid)
	local result = false

	if _cache_workshop_files[wsid] then
		local gma_path = _cache_workshop_files[wsid]

		if _isstring(gma_path) then
			if _file_Exists(gma_path, 'GAME') then
				local gma_file = _file_Open(gma_path, 'rb', 'GAME')

				if gma_file then
					result = _BuildAndMountGma(wsid, gma_path, gma_file)
					gma_file:Close()
				end
			else
				_cache_workshop_files[wsid] = nil
				_UpdateCacheWorkshopFiles()
			end
		end
	end

	return result
end

hook.Add('PostDrawOpaqueRenderables', 'RGCHat_NextBot_UserName_Draw', function()
	if not _ConVar:GetBool('sv_rgc_sync_players') then return end
	local bots = _ents_FindByClass('rgchat_player_nextbot')
	local text_align = TEXT_ALIGN_CENTER
	local text_font = 'Trebuchet18'
	local local_player = _iocalPlayer()
	local local_player_pos = local_player:GetPos()
	local local_player_eye_angles = local_player:EyeAngles()
	local_player_eye_angles:RotateAroundAxis(local_player_eye_angles:Forward(), 90)
	local_player_eye_angles:RotateAroundAxis(local_player_eye_angles:Right(), 90)

	local current_target_id = local_player:GetNWString('RGC_SYNC_TARGET', '')

	for _, npc in _ipairs(bots) do
		if not _isValid(npc) then continue end
		local text_username = npc:GetNWString('UserName', nil)
		if not text_username then continue end
		local npc_pos = npc:GetPos()
		if npc_pos:DistToSqr(local_player_pos) > 250000 then continue end
		local upper_vector_pos = _vector_0_0_5
		local start_pos = npc:LookupBone(_head_bone_name)
		local is_host = false

		if start_pos then
			start_pos = start_pos + npc:GetForward() + npc:GetUp() * upper_vector_pos.z
		else
			start_pos = npc_pos + npc:GetForward() + npc:GetUp() * (npc:OBBMaxs().z + upper_vector_pos.z)
		end

		if current_target_id and current_target_id ~= '' and current_target_id == npc:GetNWString('SteamId64', '') then
			is_host = true
		end

		_cam_Start3D2D(start_pos, local_player_eye_angles, 0.25)
		if is_host then
			_draw_SimpleTextOutlined('World Owner', text_font, 0, 0, _clr_host, text_align, text_align, 1, _clr_2)
		end
		_draw_SimpleTextOutlined(text_username, text_font, 0, -16, _clr_1, text_align, text_align, 1, _clr_2)
		_cam_End3D2D()
	end
end)

_timer_Create('RgChat.CheckNextbotNewPmModels', 1, 0, function()
	if not _ConVar:GetBool('sv_rgc_sync_players') then return end
	local max_size = _ConVar:GetInt('cl_rgc_download_model_size_limit')
	local bots = _ents_FindByClass('rgchat_player_nextbot')

	if not _has_readed_cache_workshop_files then
		_has_readed_cache_workshop_files = true
		_ReadCacheWorkshopFiles()
	end

	for _, bot in _ipairs(bots) do
		if not _isValid(bot) then continue end
		local model = bot:GetNWString('pmodel', nil)
		local wsid = bot:GetNWString('pmwsid', nil)
		local bot_model = bot:GetModel()

		if not model then
			model = 'models/player/kleiner.mdl'
		end

		if model == bot_model then continue end

		if bot_model ~= model and _util_IsValidModel(model) then
			bot:SetModel(model)
			continue
		end

		if _has_start_loaded then continue end
		if not wsid then continue end
		if _ReadAndMountCacheGma(wsid) then continue end
		if _download_cached[wsid] or max_size == 0 then continue end
		_download_cached[wsid] = true
		local wsid_number = _tonumber(wsid)
		if not wsid_number then continue end
		_MsgN('[RGChat] Try download model - ' .. wsid .. ' : ' .. _tostring(model) .. ' from ' .. _tostring(bot))
		_notification_AddProgress('rgchatworkshop.' .. wsid, '[RGChat] Preparing download - ' .. wsid .. ' : ' .. model)
		local timer_name = 'rgchatworkshop.' .. wsid .. '.timeout'

		_timer_Create(timer_name, 60, 1, function()
			_notification_Kill('rgchatworkshop.' .. wsid)
		end)

		local function kill_progress_timer()
			_timer_Remove(timer_name)
		end

		local function kill_progress()
			_has_start_loaded = false
			kill_progress_timer()
			_notification_Kill('rgchatworkshop.' .. wsid)
		end

		_has_start_loaded = true

		_steamworks_FileInfo(wsid, function(result)
			if not result then
				_notification_AddLegacy('[RGChat] Failed to retrieve information - ' .. wsid .. ' : ' .. model, NOTIFY_ERROR, 3)
				kill_progress()

				return
			end

			if result.banned or result.disabled then
				_notification_AddLegacy('[RGChat] Addon is blocked or disabled - ' .. wsid .. ' : ' .. result.title, NOTIFY_ERROR, 3)
				kill_progress()

				return
			end

			if result.size and _isnumber(result.size) then
				local mod_size = result.size / (2 ^ 20)

				if _isnumber(mod_size) and _isnumber(max_size) and mod_size > max_size then
					_size_limit_cached[wsid] = mod_size
					_notification_AddLegacy('[RGChat] The size of addon "' .. wsid .. ' : ' .. result.title .. '" is over ' .. max_size .. ' mb', NOTIFY_ERROR, 3)
					kill_progress()

					return
				end
			end

			_steamworks_DownloadUGC(wsid, function(gma_path, gma_file)
				kill_progress_timer()

				if not gma_path then
					_notification_AddLegacy('[RGChat] Failed to download the model - "' .. wsid .. ' : ' .. result.title .. '"', NOTIFY_ERROR, 3)
					kill_progress()

					return
				end

				local mounted = _BuildAndMountGma(wsid, gma_path, gma_file)

				if mounted then
					_notification_AddProgress('rgchatworkshop.' .. wsid, '[RGChat] Model successfully downloaded - "' .. wsid .. ' : ' .. result.title .. '"', 1)

					_timer_Simple(3, function()
						kill_progress()
					end)
				else
					_notification_AddLegacy('[RGChat] Failed to mount the model - "' .. wsid .. ' : ' .. result.title .. '"', NOTIFY_ERROR, 3)

					if _file_Exists(gma_save_path, 'DATA') then
						_file_Delete(gma_save_path)
					end

					kill_progress()
				end
			end)
		end)
	end
end)

concommand.Add('cl_rgc_test_workshop_download', function(ply, cma, args)
	if not RealGloabalChat:IsDeveloperMode() then return end
	local wsid = _tonumber(args[1])

	if not wsid then
		ErrorNoHalt('The argument has to be a number!')
	end

	if _ReadAndMountCacheGma(wsid) then
		_notification_AddLegacy('[RGChat] Model successfully cache mounted - "' .. wsid, NOTIFY_GENERIC, 3)

		return
	end

	_steamworks_DownloadUGC(wsid, function(gma_path, gma_file)
		if not gma_path then
			_notification_AddLegacy('[RGChat] Failed to download the model - "' .. wsid, NOTIFY_ERROR, 3)

			return
		end

		local mounted = _BuildAndMountGma(wsid, gma_path, gma_file)

		if mounted then
			_notification_AddLegacy('[RGChat] Model successfully downloaded - "' .. wsid, NOTIFY_GENERIC, 3)
		else
			_notification_AddLegacy('[RGChat] Failed to mount the model - "' .. wsid, NOTIFY_ERROR, 3)
		end
	end)
end)

cvars.AddChangeCallback('cl_rgc_download_model_size_limit', function(_, _, new_value)
	local new_limit = _tonumber(new_value)

	for wsid, size in pairs(_size_limit_cached) do
		if wsid and size and size <= new_limit then
			_download_cached[wsid] = nil
			_size_limit_cached[wsid] = nil
		end
	end
end, 'update_model_cache_size_limit')