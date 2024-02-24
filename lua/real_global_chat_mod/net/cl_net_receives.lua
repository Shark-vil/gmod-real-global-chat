local LocalPlayer = LocalPlayer
local IsValid = IsValid
-- local engine_GetAddons = engine.GetAddons
-- local game_MountGMA = game.MountGMA
-- local steamworks_DownloadUGC = steamworks.DownloadUGC
-- local util_IsValidModel = util.IsValidModel
local lang = RealGloabalChat.Values.Language
local cvar_cl_real_global_chat_status = GetConVar('cl_real_global_chat_status')
local cvar_cl_real_global_chat_filter = GetConVar('cl_real_global_chat_filter')
local cvar_cl_real_global_chat_filter_strict = GetConVar('cl_real_global_chat_filter_strict')
local cvar_cl_real_global_chat_country_mode = GetConVar('cl_real_global_chat_country_mode')
local cvar_cl_real_global_chat_ping_sound = GetConVar('cl_real_global_chat_ping_sound')
local cvar_cl_real_global_chat_visible_player_map_name = GetConVar('cl_real_global_chat_visible_player_map_name')

net.Receive('RealGlobalChatSetStatus', function()
	local status_value = net.ReadInt(3)
	if status_value == 0 then
		LocalPlayer():ChatPrint(lang['rgchat_off'])
	else
		LocalPlayer():ChatPrint(lang['rgchat_on'])
	end
	RunConsoleCommand('cl_real_global_chat_status', status_value)
end)

net.Receive('RealGlobalChatSetPingSFX', function()
	local new_value = cvar_cl_real_global_chat_ping_sound:GetInt()
	if new_value ~= 0 then
		RunConsoleCommand('cl_real_global_chat_ping_sound', 0)
		LocalPlayer():ChatPrint(lang['rgchat_ping_sfx_off'])
	else
		RunConsoleCommand('cl_real_global_chat_ping_sound', 1)
		LocalPlayer():ChatPrint(lang['rgchat_ping_sfx_on'])
	end
end)

net.Receive('RealGlobalChatSetMapName', function()
	local new_value = cvar_cl_real_global_chat_visible_player_map_name:GetInt()
	if new_value ~= 0 then
		RunConsoleCommand('cl_real_global_chat_visible_player_map_name', 0)
		LocalPlayer():ChatPrint(lang['rgchat_mapname_off'])
	else
		RunConsoleCommand('cl_real_global_chat_visible_player_map_name', 1)
		LocalPlayer():ChatPrint(lang['rgchat_mapname_on'])
	end
end)

net.Receive('RealGlobalChatSetCountryMode', function()
	local new_value = cvar_cl_real_global_chat_country_mode:GetInt()
	if new_value ~= 0 then
		RunConsoleCommand('cl_real_global_chat_country_mode', 0)
		LocalPlayer():ChatPrint(lang['rgchat_on_type_world'])
	else
		RunConsoleCommand('cl_real_global_chat_country_mode', 1)
		LocalPlayer():ChatPrint(lang['rgchat_on_type_country'])
	end
end)

net.Receive('RealGlobalChatSetFilter', function()
	local filter_value = net.ReadInt(3)
	if filter_value == 0 then
		if cvar_cl_real_global_chat_filter:GetInt() ~= 0 then
			RunConsoleCommand('cl_real_global_chat_filter', 0)
			LocalPlayer():ChatPrint(lang['rgchat_off_filter'])
		else
			RunConsoleCommand('cl_real_global_chat_filter', 1)
			LocalPlayer():ChatPrint(lang['rgchat_on_filter'])
		end
	elseif filter_value == 1 then
		if cvar_cl_real_global_chat_filter_strict:GetInt() ~= 0 then
			RunConsoleCommand('cl_real_global_chat_filter_strict', 0)
			LocalPlayer():ChatPrint(lang['rgchat_off_filter_strict'])
		else
			RunConsoleCommand('cl_real_global_chat_filter_strict', 1)
			LocalPlayer():ChatPrint(lang['rgchat_on_filter_strict'])
			if cvar_cl_real_global_chat_filter:GetInt() == 0 then
				LocalPlayer():ChatPrint(lang['rgchat_filter_strict_warn'])
			end
		end
	end
end)

net.Receive('RealGlobalChatSendPlayer', function()
	local text_value = net.ReadString()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not cvar_cl_real_global_chat_status:GetBool() then return end
	RealGloabalChat:SendToChat(ply, text_value)
end)

net.Receive('RealGlobalChatMuteUser', function()
	local connect_id = net.ReadString()
	if not connect_id or #connect_id == 0 or not tonumber(connect_id) then
		LocalPlayer():ChatPrint('The second argument is missing or the argument is not a number.')
		return
	end
	RealGloabalChat:MuteUser(tonumber(connect_id))
end)

-- net.Receive('RealGlobalChatDownloadModel', function()
-- 	local wsid = net.ReadInt(32)
-- 	local bot = net.ReadEntity()
-- 	local model = net.ReadString()
-- 	MsgN('[RGChat] Try download model - ' .. tostring(wsid) .. ':' .. tostring(model) .. ' from ' .. tostring(bot))
-- 	if not IsValid(bot) or not model or not wsid then return end
-- 	if util_IsValidModel(model) then
-- 		bot:SetModel(model)
-- 		return
-- 	end
-- 	for _, v in ipairs(engine_GetAddons()) do
-- 		if v.wsid == wsid then return end
-- 	end
-- 	RealGloabalChat.Values.AddonsDownloadedProgress[wsid] = true
-- 	MsgN('[RGChat] Download model - ' .. tostring(wsid) .. ':' .. tostring(model) .. ' from ' .. tostring(bot))
-- 	steamworks_DownloadUGC(tostring(wsid), function(gma_path, gma_file)
-- 		if not gma_path then return end
-- 		game_MountGMA(gma_path)
-- 		if IsValid(bot) and util_IsValidModel(model) then
-- 			bot:SetModel(model)
-- 		end
-- 	end)
-- end)

-- hook.Add('WorkshopDownloadFile', 'RGChat.Workshop.StartDownload', function(id, imageID, title, size)
-- 	notification.AddLegacy('[RGChat|Model] - ' .. title, NOTIFY_GENERIC, 2)
-- end)

-- hook.Add('WorkshopDownloadProgress', 'RGChat.Workshop.DownloadProgress', function(id, imageID, title, downloaded, expected)
-- 	if not RealGloabalChat.Values.AddonsDownloadedProgress[id] then return end
-- 	notification.AddProgress('rgchatworkshop.' .. id, '[RGChat|Model] - ' .. title, (downloaded * (100 / expected)) / 100)
-- end)

-- hook.Add('WorkshopDownloadedFile', 'RGChat.Workshop.FinishDownload', function(id, title)
-- 	if not RealGloabalChat.Values.AddonsDownloadedProgress[id] then return end
-- 	RealGloabalChat.Values.AddonsDownloadedProgress[id] = nil
-- 	notification.Kill('rgchatworkshop.' .. id)
-- end)