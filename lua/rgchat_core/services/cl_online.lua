local _color_rgchat_tag = Color(207, 237, 73)
local _color_message = Color(255, 255, 255)
local _last_players_count
local _PrintWelcomeMessage

timer.Create('RealGlobalChat.UpdateOnline', 30, 0, function()
	if not RealGloabalChat.Api:PlayerChatIsActive() then return end
	RealGloabalChat.WebApi.Chat:UpdateOnline(LocalPlayer())
end)

timer.Create('RealGlobalChat.CheckOnline', 300, 0, function()
	if not RealGloabalChat.Api:PlayerChatIsActive() then return end
	local Language = RealGloabalChat.Language

	RealGloabalChat.WebApi.Chat:GetOnline(function(code, body)
		if code ~= 200 then return end
		local count = tonumber(body)
		if not count then return end

		if not _last_players_count or _last_players_count ~= count then
			_last_players_count = count
			chat.AddText(_color_rgchat_tag, Language:Get('rgchat_info') .. ' ', _color_message, ': ' .. string.Replace(Language:Get('chat_online'), '%count%', count))
		end
	end)
end)

function _PrintWelcomeMessage()
	local Language = RealGloabalChat.Language

	if not RealGloabalChat.Api:PlayerChatIsActive() then
		chat.AddText(_color_rgchat_tag, Language:Get('rgchat_info') .. ' ', _color_message, ': ' .. Language:Get('chat_status_off'))
	else
		chat.AddText(_color_rgchat_tag, Language:Get('rgchat_info') .. ' ', _color_message, ': ' .. Language:Get('chat_status_on'))
	end

	chat.AddText(_color_rgchat_tag, Language:Get('rgchat_info') .. ' ', _color_message, ': ' .. Language:Get('chat_menu'))

	RealGloabalChat.WebApi.Chat:GetOnline(function(code, body)
		if code ~= 200 then return end
		local count = tonumber(body)
		if not count then return end
		_last_players_count = count
		chat.AddText(_color_rgchat_tag, Language:Get('rgchat_info') .. ' ', _color_message, ': ' .. string.Replace(Language:Get('chat_online'), '%count%', count))
	end)
end

hook.Add('RGchat.FirstStart', 'RealGlobalChat.WelcomeMessage', _PrintWelcomeMessage)