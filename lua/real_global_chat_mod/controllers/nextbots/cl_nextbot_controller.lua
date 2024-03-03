local IsValid = IsValid
local LocalPlayer = LocalPlayer
local head_bone_name = 'ValveBiped.Bip01_Head'
local vector_0_0_5 = Vector(0, 0, 5)
local clr_1 = Color(255, 255, 255)
local clr_2 = Color(0, 0, 0)
local draw_SimpleTextOutlined = draw.SimpleTextOutlined
local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local ents_FindByClass = ents.FindByClass
local engine_GetAddons = engine.GetAddons
local game_MountGMA = game.MountGMA
local steamworks_DownloadUGC = steamworks.DownloadUGC
local util_IsValidModel = util.IsValidModel
local steamworks_FileInfo = steamworks.FileInfo
local cvar_cl_real_global_chat_download_model_size_limit = GetConVar('cl_real_global_chat_download_model_size_limit')

hook.Add('PostDrawOpaqueRenderables', 'RGCHat_NextBot_UserName_Draw', function()
	local bots = ents_FindByClass('rgchat_player_nextbot')

	for _, npc in ipairs(bots) do
		if not IsValid(npc) then continue end
		local text_username = npc:GetNWString('UserName', nil)
		if not text_username then continue end
		local local_player = LocalPlayer()
		local local_player_pos = local_player:GetPos()
		local local_player_eye_angles = local_player:EyeAngles()
		local_player_eye_angles:RotateAroundAxis(local_player_eye_angles:Forward(), 90)
		local_player_eye_angles:RotateAroundAxis(local_player_eye_angles:Right(), 90)
		local npc_pos = npc:GetPos()
		if npc_pos:Distance(local_player_pos) > 800 then continue end
		local upper_vector_pos = vector_0_0_5
		local start_pos = npc:LookupBone(head_bone_name)

		if start_pos then
			start_pos = start_pos + npc:GetForward() + npc:GetUp() * upper_vector_pos.z
		else
			start_pos = npc_pos + npc:GetForward() + npc:GetUp() * (npc:OBBMaxs().z + upper_vector_pos.z)
		end

		cam_Start3D2D(start_pos, local_player_eye_angles, 0.25)
		draw_SimpleTextOutlined(text_username, 'Trebuchet18', 0, -16, clr_1, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, clr_2)
		cam_End3D2D()
	end
end)

local size_limt_cache = {}

timer.Create('RgChat.CheckNextbotNewPmModels', 1, 0, function()
	local max_size = cvar_cl_real_global_chat_download_model_size_limit:GetInt()
	local bots = ents_FindByClass('rgchat_player_nextbot')

	for _, bot in ipairs(bots) do
		if not IsValid(bot) then continue end
		local model = bot:GetNWString('pmodel', nil)
		local wsid = bot:GetNWString('pmwsid', nil)
		local bot_model = bot:GetModel()

		if not model then
			model = 'models/player/kleiner.mdl'
		end

		if model == bot_model then continue end

		if bot_model ~= model and util_IsValidModel(model) then
			bot:SetModel(model)
			continue
		end

		if not wsid or RealGloabalChat.Values.AddonsModelsDownloadChecked[wsid] or max_size == 0 then continue end
		RealGloabalChat.Values.AddonsModelsDownloadChecked[wsid] = true
		local wsid_number = tonumber(wsid)
		if not wsid_number then continue end
		MsgN('[RGChat] Try download model - ' .. wsid .. ' : ' .. tostring(model) .. ' from ' .. tostring(bot))
		local has_next = false

		for _, v in ipairs(engine_GetAddons()) do
			if v.wsid == wsid_number and not v.mounted then
				local ok, _ = game_MountGMA(v.file)

				if ok and util_IsValidModel(model) then
					bot:SetModel(model)
					has_next = true
				end

				break
			end
		end

		if has_next then continue end
		notification.AddProgress('rgchatworkshop.' .. wsid, '[RGChat] Preparing download - ' .. wsid .. ' : ' .. model)
		local timer_name = 'rgchatworkshop.' .. wsid .. '.timeout'

		timer.Create(timer_name, 60, 1, function()
			notification.Kill('rgchatworkshop.' .. wsid)
		end)

		local function kill_progress_timer()
			timer.Remove(timer_name)
		end

		local function kill_progress()
			kill_progress_timer()
			notification.Kill('rgchatworkshop.' .. wsid)
		end

		steamworks_FileInfo(wsid, function(result)
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
					size_limt_cache[wsid] = mod_size
					notification.AddLegacy('[RGChat] The size of addon "' .. wsid .. ' : ' .. result.title .. '" is over ' .. max_size .. ' mb', NOTIFY_ERROR, 3)
					kill_progress()

					return
				end
			end

			steamworks_DownloadUGC(wsid, function(gma_path, gma_file)
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
						ok, _ = game_MountGMA('data/' .. gma_save_path)

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
					-- if file.Exists(gma_save_path, 'DATA') then
					-- 	file.Delete(gma_save_path)
					-- end

					kill_progress()
				end
			end)
		end)
	end
end)

cvars.AddChangeCallback('cl_real_global_chat_download_model_size_limit', function(_, _, new_value)
	local new_limit = tonumber(new_value)

	for wsid, size in pairs(size_limt_cache) do
		if wsid and size and size <= new_limit then
			RealGloabalChat.Values.AddonsModelsDownloadChecked[wsid] = nil
			size_limt_cache[wsid] = nil
		end
	end
end, 'on_change_cl_real_global_chat_download_model_size_limit')
--[[
concommand.Add('rgchat_gma_test', function()
	local wsid = '3170979277'
	steamworks_DownloadUGC(wsid, function(gma_path, gma_file)
		if not gma_path then
			notification.AddLegacy('[RGChat] Failed to download the model - "' .. wsid .. ' : ' .. result.title .. '"', NOTIFY_ERROR, 5)
			return
		end

		if not file.Exists('rgchat_data/cache', 'DATA') then
			file.CreateDir('rgchat_data/cache')
		end

		local gma_save_path = 'rgchat_data/cache/' .. wsid .. '_' .. os.time() .. '.gma.dat'
		local meta = RealGloabalChat
		local ok, gma_meta
		ok, gma_meta = xpcall(meta.ReadGma, debug.traceback, meta, gma_file)
		if ok and gma_meta then
			local new_gma_file = file.Open(gma_save_path, 'wb', 'DATA')
			ok = xpcall(meta.BuildGma, debug.traceback, meta, wsid, new_gma_file, gma_meta)
			new_gma_file:Close()
			if ok then
				game_MountGMA('data/' .. gma_save_path)
			end
		end
		if file.Exists(gma_save_path) then
			file.Delete(gma_save_path)
		end
	end)
end)
--]]