local _IsValid, _LocalPlayer, _head_bone_name, _vector_0_0_5, _clr_1, _clr_2, _draw_SimpleTextOutlined, _cam_Start3D2D, _cam_End3D2D, _ents_FindByClass, _game_MountGMA, _util_IsValidModel, _download_cached, _size_limit_cached, _has_start_loaded

_IsValid = IsValid
_LocalPlayer = LocalPlayer
_head_bone_name = 'ValveBiped.Bip01_Head'
_vector_0_0_5 = Vector(0, 0, 5)
_clr_1 = Color(255, 255, 255)
_clr_2 = Color(0, 0, 0)
_draw_SimpleTextOutlined = draw.SimpleTextOutlined
_cam_Start3D2D = cam.Start3D2D
_cam_End3D2D = cam.End3D2D
_ents_FindByClass = ents.FindByClass
_game_MountGMA = game.MountGMA
_util_IsValidModel = util.IsValidModel
_download_cached = {}
_size_limit_cached = {}
_has_start_loaded = false

hook.Add('PostDrawOpaqueRenderables', 'RGCHat_NextBot_UserName_Draw', function()
	local bots = _ents_FindByClass('rgchat_player_nextbot')

	for _, npc in ipairs(bots) do
		if not _IsValid(npc) then continue end
		local text_username = npc:GetNWString('UserName', nil)
		if not text_username then continue end
		local local_player = _LocalPlayer()
		local local_player_pos = local_player:GetPos()
		local local_player_eye_angles = local_player:EyeAngles()
		local_player_eye_angles:RotateAroundAxis(local_player_eye_angles:Forward(), 90)
		local_player_eye_angles:RotateAroundAxis(local_player_eye_angles:Right(), 90)
		local npc_pos = npc:GetPos()
		if npc_pos:Distance(local_player_pos) > 800 then continue end
		local upper_vector_pos = _vector_0_0_5
		local start_pos = npc:LookupBone(_head_bone_name)

		if start_pos then
			start_pos = start_pos + npc:GetForward() + npc:GetUp() * upper_vector_pos.z
		else
			start_pos = npc_pos + npc:GetForward() + npc:GetUp() * (npc:OBBMaxs().z + upper_vector_pos.z)
		end

		_cam_Start3D2D(start_pos, local_player_eye_angles, 0.25)
		_draw_SimpleTextOutlined(text_username, 'Trebuchet18', 0, -16, _clr_1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, _clr_2)
		_cam_End3D2D()
	end
end)

timer.Create('RgChat.CheckNextbotNewPmModels', 1, 0, function()
	local max_size = RealGloabalChat.ConVar:GetInt('cl_rgc_download_model_size_limit')
	local bots = _ents_FindByClass('rgchat_player_nextbot')

	for _, bot in ipairs(bots) do
		if not _IsValid(bot) then continue end
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

		if not wsid or _download_cached[wsid] or max_size == 0 then continue end
		_download_cached[wsid] = true

		local wsid_number = tonumber(wsid)
		if not wsid_number then continue end

		MsgN('[RGChat] Try download model - ' .. wsid .. ' : ' .. tostring(model) .. ' from ' .. tostring(bot))

		notification.AddProgress('rgchatworkshop.' .. wsid, '[RGChat] Preparing download - ' .. wsid .. ' : ' .. model)
		local timer_name = 'rgchatworkshop.' .. wsid .. '.timeout'

		timer.Create(timer_name, 60, 1, function()
			notification.Kill('rgchatworkshop.' .. wsid)
		end)

		local function kill_progress_timer()
			timer.Remove(timer_name)
		end

		local function kill_progress()
			_has_start_loaded = false
			kill_progress_timer()
			notification.Kill('rgchatworkshop.' .. wsid)
		end

		_has_start_loaded = true

		steamworks.FileInfo(wsid, function(result)
			if not result then
				notification.AddLegacy('[RGChat] Failed to retrieve information - ' .. wsid .. ' : ' .. model, NOTIFY_ERROR, 3)
				kill_progress()

				return
			end

			if result.banned or result.disabled then
				notification.AddLegacy('[RGChat] Addon is blocked or disabled - ' .. wsid .. ' : ' .. result.title, NOTIFY_ERROR, 3)
				kill_progress()

				return
			end

			if result.size and isnumber(result.size) then
				local mod_size = result.size / (2 ^ 20)

				if isnumber(mod_size) and isnumber(max_size) and mod_size > max_size then
					_size_limit_cached[wsid] = mod_size
					notification.AddLegacy('[RGChat] The size of addon "' .. wsid .. ' : ' .. result.title .. '" is over ' .. max_size .. ' mb', NOTIFY_ERROR, 3)
					kill_progress()

					return
				end
			end

			steamworks.DownloadUGC(wsid, function(gma_path, gma_file)
				kill_progress_timer()

				if not gma_path then
					notification.AddLegacy('[RGChat] Failed to download the model - "' .. wsid .. ' : ' .. result.title .. '"', NOTIFY_ERROR, 3)
					kill_progress()

					return
				end

				if not file.Exists('rgchat_data/cache', 'DATA') then
					file.CreateDir('rgchat_data/cache')
				end

				local gma_save_path = 'rgchat_data/cache/' .. wsid .. '_' .. os.time() .. '.gma.dat'
				local meta = RealGloabalChat
				local ok, gma_meta, mounted
				ok, gma_meta = xpcall(meta.ReadGma, debug.traceback, meta, gma_file)
				if ok and gma_meta then
					local new_gma_file = file.Open(gma_save_path, 'wb', 'DATA')
					ok = xpcall(meta.BuildGma, debug.traceback, meta, wsid, new_gma_file, gma_meta)
					new_gma_file:Close()

					if ok then
						ok, _ = _game_MountGMA('data/' .. gma_save_path)

						if ok then
							mounted = true
							notification.AddProgress('rgchatworkshop.' .. wsid, '[RGChat] Model successfully downloaded - "' .. wsid .. ' : ' .. result.title .. '"', 1)

							timer.Simple(3, function()
								kill_progress()
							end)
						else
							notification.AddLegacy('[RGChat] Failed to mount the model - "' .. wsid .. ' : ' .. result.title .. '"', NOTIFY_ERROR, 3)
						end
					end
				end

				if not mounted then
					if file.Exists(gma_save_path, 'DATA') then
						file.Delete(gma_save_path)
					end

					kill_progress()
				end
			end)
		end)
	end
end)

cvars.AddChangeCallback('cl_rgc_download_model_size_limit', function(_, _, new_value)
	local new_limit = tonumber(new_value)

	for wsid, size in pairs(_size_limit_cached) do
		if wsid and size and size <= new_limit then
			_download_cached[wsid] = nil
			_size_limit_cached[wsid] = nil
		end
	end
end, 'update_model_cache_size_limit')